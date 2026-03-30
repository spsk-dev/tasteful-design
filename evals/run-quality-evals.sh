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
# Section 0b: LLM-as-judge function (Claude Haiku via Anthropic API)
# ==============================================================================

llm_judge() {
  local review_output="$1"
  local rubric="$2"
  local api_key="${ANTHROPIC_API_KEY:-}"

  if [ -z "$api_key" ]; then
    echo "SKIP"
    return 2
  fi

  local response
  response=$(curl -s -w "\n%{http_code}" \
    "https://api.anthropic.com/v1/messages" \
    -H "content-type: application/json" \
    -H "x-api-key: $api_key" \
    -H "anthropic-version: 2023-06-01" \
    -d "$(jq -n \
      --arg content "Review output:\n$review_output\n\nRubric:\n$rubric\n\nDoes this review output pass the rubric? Answer exactly PASS or FAIL. Nothing else." \
      '{
        "model": "claude-haiku-4-5",
        "max_tokens": 10,
        "messages": [{"role": "user", "content": $content}]
      }'
    )")

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo "SKIP"
    return 2
  fi

  local verdict
  verdict=$(echo "$body" | jq -r '.content[0].text' | tr '[:lower:]' '[:upper:]' | grep -oE 'PASS|FAIL' | head -1)
  echo "${verdict:-SKIP}"
  [ "$verdict" = "PASS" ] && return 0 || return 1
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

echo "--- Score & Verdict Assertions ---"

# Filter to only score/verdict assertions (skip judge and ranking types -- handled in Section 5b/5c)
SCORE_ASSERTION_INDICES=$(jq '[.assertions | to_entries[] | select(.value.type // "score" | IN("judge","ranking") | not) | .key]' "$ASSERTIONS_FILE")
SCORE_ASSERTION_COUNT=$(echo "$SCORE_ASSERTION_INDICES" | jq 'length')

for idx in $(echo "$SCORE_ASSERTION_INDICES" | jq -r '.[]'); do
  i=$idx
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
    # Verdict assertion: compare expected verdict (supports also_accept array)
    expected=$(jq -r ".assertions[$i].expected" "$ASSERTIONS_FILE")
    actual=$(extract_verdict "$review_output")

    if [ -z "$actual" ]; then
      check_skip "$assertion_name" "no verdict extracted"
      continue
    fi

    # Check primary expected value
    verdict_passed=false
    if verdict_matches "$actual" "$expected"; then
      verdict_passed=true
    else
      # Check also_accept array if present
      also_accept_count=$(jq -r ".assertions[$i].also_accept // [] | length" "$ASSERTIONS_FILE")
      for ai in $(seq 0 $((also_accept_count - 1))); do
        alt=$(jq -r ".assertions[$i].also_accept[$ai]" "$ASSERTIONS_FILE")
        if verdict_matches "$actual" "$alt"; then
          verdict_passed=true
          break
        fi
      done
    fi

    check "$assertion_name (expected=$expected, actual=$actual)" [ "$verdict_passed" = "true" ]

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
# Section 5b: LLM-as-Judge Assertions
# ==============================================================================

echo ""
echo "--- LLM-as-Judge Assertions ---"

JUDGE_COUNT=$(jq '[.assertions[] | select(.type == "judge")] | length' "$ASSERTIONS_FILE")

if [ "$JUDGE_COUNT" -gt 0 ]; then
  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "[INFO] ANTHROPIC_API_KEY not set -- skipping $JUDGE_COUNT judge assertions"
    for ji in $(seq 0 $((JUDGE_COUNT - 1))); do
      JUDGE_NAME=$(jq -r "[.assertions[] | select(.type == \"judge\")][$ji].name" "$ASSERTIONS_FILE")
      check_skip "$JUDGE_NAME" "no ANTHROPIC_API_KEY"
    done
  else
    # Run each judge assertion
    for ji in $(seq 0 $((JUDGE_COUNT - 1))); do
      JUDGE_ASSERTION=$(jq -c "[.assertions[] | select(.type == \"judge\")][$ji]" "$ASSERTIONS_FILE")
      JUDGE_NAME=$(echo "$JUDGE_ASSERTION" | jq -r '.name')
      RUBRIC=$(echo "$JUDGE_ASSERTION" | jq -r '.rubric')
      FIXTURE_KEY=$(echo "$JUDGE_ASSERTION" | jq -r '.fixture' | sed 's|fixtures/||; s|\.html||')

      # Get the cached output for this fixture
      judge_output_file="$TMPDIR_EVALS/${FIXTURE_KEY}.txt"
      if [ ! -f "$judge_output_file" ] || [ ! -s "$judge_output_file" ]; then
        check_skip "$JUDGE_NAME" "no review output for $FIXTURE_KEY"
        continue
      fi

      REVIEW_TEXT=$(cat "$judge_output_file")
      RESULT=$(llm_judge "$REVIEW_TEXT" "$RUBRIC")
      EXIT_CODE=$?

      if [ $EXIT_CODE -eq 2 ]; then
        check_skip "$JUDGE_NAME" "API unavailable"
      elif [ $EXIT_CODE -eq 0 ]; then
        check "$JUDGE_NAME" true
      else
        check "$JUDGE_NAME" false
      fi
    done
  fi
else
  echo "[INFO] No judge assertions defined"
fi

# ==============================================================================
# Section 5c: Ranking Assertions
# ==============================================================================

echo ""
echo "--- Ranking Assertions ---"

RANKING_COUNT=$(jq '[.assertions[] | select(.type == "ranking")] | length' "$ASSERTIONS_FILE")

if [ "$RANKING_COUNT" -gt 0 ]; then
  for ri in $(seq 0 $((RANKING_COUNT - 1))); do
    RANKING_ASSERTION=$(jq -c "[.assertions[] | select(.type == \"ranking\")][$ri]" "$ASSERTIONS_FILE")
    RANKING_NAME=$(echo "$RANKING_ASSERTION" | jq -r '.name')
    RANKING_DIM=$(echo "$RANKING_ASSERTION" | jq -r '.dimension // "overall"')
    ORDER_COUNT=$(echo "$RANKING_ASSERTION" | jq '.order | length')

    # Collect scores for ordered fixtures
    ranking_skip=false
    scores=()
    fixture_labels=()
    for oi in $(seq 0 $((ORDER_COUNT - 1))); do
      rank_fixture=$(echo "$RANKING_ASSERTION" | jq -r ".order[$oi]")
      fixture_labels+=("$rank_fixture")
      rank_output_file="$TMPDIR_EVALS/${rank_fixture}.txt"
      if [ ! -f "$rank_output_file" ] || [ ! -s "$rank_output_file" ]; then
        check_skip "$RANKING_NAME" "missing review output for $rank_fixture"
        ranking_skip=true
        break
      fi

      rank_output=$(cat "$rank_output_file")
      if [ "$RANKING_DIM" = "overall" ]; then
        rank_score=$(extract_overall "$rank_output")
      else
        rank_score=$(extract_score "$RANKING_DIM" "$rank_output")
      fi

      if [ -z "$rank_score" ]; then
        check_skip "$RANKING_NAME" "no $RANKING_DIM score for $rank_fixture"
        ranking_skip=true
        break
      fi

      scores+=("$rank_score")
    done

    if [ "$ranking_skip" = true ]; then
      continue
    fi

    # Verify ordering: score[0] <= score[1] <= ... <= score[N]
    ranking_valid=true
    for oi in $(seq 1 $((${#scores[@]} - 1))); do
      prev_idx=$((oi - 1))
      is_ordered=$(python3 -c "print('yes' if float('${scores[$prev_idx]}') <= float('${scores[$oi]}') else 'no')")
      if [ "$is_ordered" != "yes" ]; then
        ranking_valid=false
        echo "  [DEBUG] ${fixture_labels[$prev_idx]}=${scores[$prev_idx]} > ${fixture_labels[$oi]}=${scores[$oi]}"
      fi
    done

    scores_display=$(printf "%s=%s " $(paste -d= <(printf '%s\n' "${fixture_labels[@]}") <(printf '%s\n' "${scores[@]}")) 2>/dev/null || true)
    check "$RANKING_NAME ($scores_display)" [ "$ranking_valid" = "true" ]
  done
else
  echo "[INFO] No ranking assertions defined"
fi

# ==============================================================================
# Section 5d: Save Eval Snapshot
# ==============================================================================

echo ""
echo "--- Saving Eval Snapshot ---"

SNAPSHOT_DIR="$SCRIPT_DIR/results"
mkdir -p "$SNAPSHOT_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%S")
SNAPSHOT_FILE="$SNAPSHOT_DIR/${TIMESTAMP}.json"

# Build snapshot JSON with fixture scores and assertion results
SNAPSHOT=$(jq -n \
  --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg version "1.0.0" \
  --arg model "claude-sonnet-4-6" \
  --argjson pass "$PASS" \
  --argjson fail "$FAIL" \
  --argjson skip "$SKIP" \
  '{
    timestamp: $ts,
    runner_version: $version,
    model: $model,
    mode: "full",
    fixtures: {},
    assertions: { total: ($pass + $fail + $skip), passed: $pass, failed: $fail, skipped: $skip }
  }')

# Add per-fixture score data
for fixture_file in "$TMPDIR_EVALS"/*.txt; do
  [ -f "$fixture_file" ] || continue
  FIXTURE_KEY=$(basename "$fixture_file" .txt)
  OUTPUT=$(cat "$fixture_file")

  VERDICT=$(extract_verdict "$OUTPUT")
  OVERALL=$(extract_overall "$OUTPUT")

  # Extract all specialist scores
  SCORES_JSON="{}"
  SCORES_JSON=$(echo "$SCORES_JSON" | jq --arg v "${OVERALL:-0}" '. + {overall: ($v | tonumber)}')
  for dim in intent_match originality ux_flow typography color layout icons motion copy code_a11y; do
    SCORE=$(extract_score "$dim" "$OUTPUT")
    SCORES_JSON=$(echo "$SCORES_JSON" | jq --arg k "$dim" --arg v "${SCORE:-0}" '. + {($k): ($v | tonumber)}')
  done

  SNAPSHOT=$(echo "$SNAPSHOT" | jq \
    --arg key "$FIXTURE_KEY" \
    --argjson scores "$SCORES_JSON" \
    --arg verdict "${VERDICT:-unknown}" \
    '.fixtures[$key] = {scores: $scores, verdict: $verdict}')
done

echo "$SNAPSHOT" | jq '.' > "$SNAPSHOT_FILE"
echo "[INFO] Snapshot saved: $SNAPSHOT_FILE"

# ==============================================================================
# Section 5e: Regression Detection
# ==============================================================================

PREV_SNAPSHOT=$(ls -t "$SNAPSHOT_DIR"/*.json 2>/dev/null | grep -v "$(basename "$SNAPSHOT_FILE")" | head -1)

if [ -n "$PREV_SNAPSHOT" ] && [ -f "$PREV_SNAPSHOT" ]; then
  echo ""
  echo "--- Regression Detection (vs $(basename "$PREV_SNAPSHOT")) ---"
  REGRESSIONS=0

  for fixture in $(jq -r '.fixtures | keys[]' "$SNAPSHOT_FILE"); do
    CURR=$(jq -r ".fixtures[\"$fixture\"].scores.overall // 0" "$SNAPSHOT_FILE")
    PREV=$(jq -r ".fixtures[\"$fixture\"].scores.overall // 0" "$PREV_SNAPSHOT")

    DROPPED=$(python3 -c "print('yes' if float('$PREV') - float('$CURR') > 0.5 else 'no')")
    if [ "$DROPPED" = "yes" ]; then
      echo "  [REGRESSION] $fixture: $PREV -> $CURR (dropped > 0.5)"
      REGRESSIONS=$((REGRESSIONS + 1))
    else
      echo "  [OK] $fixture: $PREV -> $CURR"
    fi
  done

  if [ "$REGRESSIONS" -gt 0 ]; then
    echo "[WARN] $REGRESSIONS regression(s) detected"
  else
    echo "[INFO] No regressions detected"
  fi
else
  echo ""
  echo "[INFO] No previous snapshot for regression comparison"
fi

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
