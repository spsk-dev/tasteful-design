#!/usr/bin/env bash
set -uo pipefail
# Note: set -e intentionally omitted -- check() handles errors (same as validate-structure.sh)

# ==============================================================================
# SpSk Layer 2: Quality Eval Runner
#
# Serves HTML fixtures, invokes design-review via `claude -p`, parses output
# for verdicts and scores, and asserts values match calibrated ranges from
# assertions.json.
#
# Usage:
#   bash evals/run-quality-evals.sh                 # Run all fixtures
#   bash evals/run-quality-evals.sh --fixture admin-panel   # Single fixture
#   bash evals/run-quality-evals.sh --dry-run        # Use cached output (no claude)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the output parser
source "$SCRIPT_DIR/parse-review-output.sh"

# ==============================================================================
# Section 0: Pass/fail reporting (same pattern as validate-structure.sh)
# ==============================================================================

PASS=0
FAIL=0
SKIP=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

check_skip() {
  local label="$1"
  local reason="$2"
  echo "  [SKIP] $label ($reason)"
  SKIP=$((SKIP + 1))
}

# ==============================================================================
# Section 1: Dependency checks and argument parsing
# ==============================================================================

FIXTURE_FILTER=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture)
      FIXTURE_FILTER="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "[ERROR] Unknown flag: $1"
      echo "Usage: $0 [--fixture <name>] [--dry-run]"
      exit 2
      ;;
  esac
done

# Check jq
if ! command -v jq &>/dev/null; then
  echo "[FATAL] jq is required but not found"
  exit 2
fi

# Check python3
if ! command -v python3 &>/dev/null; then
  echo "[FATAL] python3 is required but not found"
  exit 2
fi

# Check claude CLI (only required for live runs)
CLAUDE_AVAILABLE=false
if command -v claude &>/dev/null; then
  CLAUDE_AVAILABLE=true
fi

if [ "$DRY_RUN" = false ] && [ "$CLAUDE_AVAILABLE" = false ]; then
  echo "[WARN] claude CLI not available -- skipping all live review invocations"
  echo "[INFO] Use --dry-run with cached results in evals/results/ or install claude CLI"
fi

# Verify assertions.json exists
ASSERTIONS_FILE="$REPO_ROOT/evals/assertions.json"
if [ ! -f "$ASSERTIONS_FILE" ]; then
  echo "[FATAL] assertions.json not found at $ASSERTIONS_FILE"
  exit 2
fi

ASSERTION_COUNT=$(jq '.assertions | length' "$ASSERTIONS_FILE")
echo ""
echo "=== Layer 2: Quality Eval Runner ==="
echo "  Assertions: $ASSERTION_COUNT"
echo "  Mode: $([ "$DRY_RUN" = true ] && echo "dry-run (cached output)" || echo "live (claude -p)")"
echo "  Claude CLI: $([ "$CLAUDE_AVAILABLE" = true ] && echo "available" || echo "not available")"
[ -n "$FIXTURE_FILTER" ] && echo "  Fixture filter: $FIXTURE_FILTER"
echo ""

# ==============================================================================
# Section 2: Fixture server lifecycle
# ==============================================================================

find_free_port() {
  python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()"
}

SERVER_PID=""

start_server() {
  PORT=$(find_free_port)
  python3 -m http.server "$PORT" --directory "$SCRIPT_DIR/fixtures" &>/dev/null &
  SERVER_PID=$!

  # Wait for server readiness (max 5 seconds)
  for i in $(seq 1 10); do
    curl -s "http://localhost:$PORT/" >/dev/null 2>&1 && break
    sleep 0.5
  done

  if ! curl -s "http://localhost:$PORT/" >/dev/null 2>&1; then
    echo "[FATAL] Fixture server failed to start on port $PORT"
    exit 2
  fi

  echo "[INFO] Fixture server running on port $PORT (PID: $SERVER_PID)"
}

cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
  fi
  # Clean up temp directory
  if [ -n "${TMPDIR_EVALS:-}" ] && [ -d "$TMPDIR_EVALS" ]; then
    rm -rf "$TMPDIR_EVALS"
  fi
}
trap cleanup EXIT

# Only start server for live runs
if [ "$DRY_RUN" = false ]; then
  start_server
fi

# ==============================================================================
# Section 3: Review invocation function
# ==============================================================================

# Ensure results directory exists for caching
mkdir -p "$SCRIPT_DIR/results"

run_review() {
  local fixture_file="$1"
  local output_file="$2"
  local fixture_name
  fixture_name=$(basename "$fixture_file" .html)

  # Dry-run mode: use cached output
  if [ "$DRY_RUN" = true ]; then
    local cache_file="$SCRIPT_DIR/results/cache-${fixture_name}.txt"
    if [ -f "$cache_file" ]; then
      cp "$cache_file" "$output_file"
      echo "[INFO] Using cached output for $fixture_name"
      return 0
    else
      echo "[WARN] No cached output for $fixture_name at $cache_file"
      return 1
    fi
  fi

  # Live mode: check claude availability
  if [ "$CLAUDE_AVAILABLE" = false ]; then
    echo "[SKIP] claude CLI not available -- cannot review $fixture_name"
    return 1
  fi

  local fixture_url="http://localhost:$PORT/$fixture_file"
  echo "[INFO] Invoking design-review on $fixture_url ..."
  echo "[INFO] This may take 5-15 minutes per fixture."

  # Strategy A (preferred): Task description with plugin-dir
  claude -p \
    --plugin-dir "$REPO_ROOT" \
    --dangerously-skip-permissions \
    --model sonnet \
    --max-turns 30 \
    --output-format text \
    "Run a full design review on $fixture_url. Use the /design-review command. Output the complete review with specialist scores table and verdict." \
    2>/dev/null > "$output_file"

  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "[WARN] claude -p exited with code $exit_code for $fixture_name"
  fi

  # Validate we got a real review (not empty or error)
  if [ ! -s "$output_file" ]; then
    echo "[ERROR] Empty output from claude -p for $fixture_name"
    return 1
  fi

  # Cache the output for future dry-run use
  cp "$output_file" "$SCRIPT_DIR/results/cache-${fixture_name}.txt"

  # Check for verdict presence as smoke test
  local verdict
  verdict=$(extract_verdict "$(cat "$output_file")")
  if [ -z "$verdict" ]; then
    echo "[WARN] No verdict found in output for $fixture_name. Review may have failed."
    echo "[DEBUG] First 500 chars of output:"
    head -c 500 "$output_file"
    echo ""
    return 1
  fi

  echo "[INFO] Review complete for $fixture_name. Verdict: $verdict"
  return 0
}

# ==============================================================================
# Section 4: Run reviews for each fixture
# ==============================================================================

FIXTURES=(
  "admin-panel.html"
  "landing-page.html"
  "emotional-page.html"
  "gray-area.html"
)

TMPDIR_EVALS=$(mktemp -d)

# Determine which fixtures to run
declare -A FIXTURE_OUTPUT
declare -A FIXTURE_STATUS

for fixture in "${FIXTURES[@]}"; do
  fixture_name=$(basename "$fixture" .html)

  # Apply fixture filter if set
  if [ -n "$FIXTURE_FILTER" ] && [ "$fixture_name" != "$FIXTURE_FILTER" ]; then
    continue
  fi

  echo "--- Reviewing: $fixture_name ---"
  output_file="$TMPDIR_EVALS/$fixture_name.txt"

  if run_review "$fixture" "$output_file"; then
    FIXTURE_STATUS[$fixture_name]="reviewed"
    FIXTURE_OUTPUT[$fixture_name]="$output_file"
  else
    FIXTURE_STATUS[$fixture_name]="failed"
    FIXTURE_OUTPUT[$fixture_name]=""
  fi
  echo ""
done

# ==============================================================================
# Section 5: Execute assertions from assertions.json
# ==============================================================================

echo "--- Assertion Results ---"

TOTAL_ASSERTIONS=$(jq '.assertions | length' "$ASSERTIONS_FILE")

for i in $(seq 0 $((TOTAL_ASSERTIONS - 1))); do
  # Read assertion fields
  assertion_name=$(jq -r ".assertions[$i].name" "$ASSERTIONS_FILE")
  fixture_path=$(jq -r ".assertions[$i].fixture" "$ASSERTIONS_FILE")
  dimension=$(jq -r ".assertions[$i].dimension" "$ASSERTIONS_FILE")

  # Extract fixture name from path (e.g., "fixtures/admin-panel.html" -> "admin-panel")
  fixture_name=$(basename "$fixture_path" .html)

  # Skip if fixture filter is active and this fixture doesn't match
  if [ -n "$FIXTURE_FILTER" ] && [ "$fixture_name" != "$FIXTURE_FILTER" ]; then
    continue
  fi

  # Check if fixture was reviewed successfully
  status="${FIXTURE_STATUS[$fixture_name]:-unreviewed}"
  output_file="${FIXTURE_OUTPUT[$fixture_name]:-}"

  if [ "$status" != "reviewed" ] || [ -z "$output_file" ] || [ ! -f "$output_file" ]; then
    if [ "$CLAUDE_AVAILABLE" = false ] && [ "$DRY_RUN" = false ]; then
      check_skip "$assertion_name" "claude CLI not available"
    else
      check_skip "$assertion_name" "fixture $fixture_name not reviewed"
    fi
    continue
  fi

  # Load the review output
  review_output=$(cat "$output_file")

  # Route by dimension type
  if [ "$dimension" = "verdict" ]; then
    # Verdict assertion: compare expected verdict
    expected=$(jq -r ".assertions[$i].expected" "$ASSERTIONS_FILE")
    actual=$(extract_verdict "$review_output")

    if [ -z "$actual" ]; then
      check_skip "$assertion_name" "no verdict extracted"
      continue
    fi

    check "$assertion_name (expected=$expected, actual=$actual)" verdict_matches "$actual" "$expected"

  elif [ "$dimension" = "overall" ]; then
    # Overall score range assertion
    min_val=$(jq -r ".assertions[$i].min" "$ASSERTIONS_FILE")
    max_val=$(jq -r ".assertions[$i].max" "$ASSERTIONS_FILE")
    actual=$(extract_overall "$review_output")

    if [ -z "$actual" ]; then
      check_skip "$assertion_name" "no overall score extracted"
      continue
    fi

    check "$assertion_name (score=$actual, range=[$min_val, $max_val])" float_in_range "$actual" "$min_val" "$max_val"

  else
    # Per-specialist score range assertion
    min_val=$(jq -r ".assertions[$i].min" "$ASSERTIONS_FILE")
    max_val=$(jq -r ".assertions[$i].max" "$ASSERTIONS_FILE")
    actual=$(extract_score "$dimension" "$review_output")

    if [ -z "$actual" ]; then
      check_skip "$assertion_name" "no $dimension score extracted"
      continue
    fi

    check "$assertion_name ($dimension=$actual, range=[$min_val, $max_val])" float_in_range "$actual" "$min_val" "$max_val"
  fi
done

# ==============================================================================
# Section 6: Summary
# ==============================================================================

TOTAL=$((PASS + FAIL + SKIP))
echo ""
echo "=== Layer 2 Quality Eval Results ==="
echo "  PASSED:  $PASS"
echo "  FAILED:  $FAIL"
echo "  SKIPPED: $SKIP"
echo "  TOTAL:   $TOTAL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
