# Phase 9: Layer 2 Eval Runner - Research

**Researched:** 2026-03-29
**Domain:** Bash eval orchestration, Claude Code CLI programmatic invocation, LLM output parsing, LLM-as-judge patterns
**Confidence:** HIGH (verified against official docs, CLI help output, and direct codebase analysis)

## Summary

Phase 9 builds the eval runner that turns 12 dormant assertions in `evals/assertions.json` into executable pass/fail checks against real design-review output. The core architecture is a bash orchestrator (`evals/run-quality-evals.sh`) that serves HTML fixtures via `python3 -m http.server`, invokes `/design-review` via `claude -p`, parses the terminal output for scores and verdicts, and asserts values fall within calibrated ranges.

The most critical research finding is about `claude --print` and plugin commands. The official Claude Code docs explicitly state: "User-invoked skills like /commit and built-in commands are only available in interactive mode. In -p mode, describe the task you want to accomplish instead." However, GitHub issue #837 was closed as COMPLETED, with an Anthropic collaborator confirming slash commands work via `claude -p /project:my-custom-command` syntax. The practical implication: the eval runner cannot invoke `/design-review` directly in -p mode. Instead, it must use `claude -p --plugin-dir /path/to/spsk "Run a design review on http://localhost:PORT"` (describing the task) or use `--system-prompt-file` to load the design-review command as a system prompt. A smoke test in the first task is essential to determine which invocation pattern actually works.

**Primary recommendation:** Build the eval runner with a two-tier invocation strategy. Primary: `claude -p --plugin-dir . --dangerously-skip-permissions --output-format json "Review the design at URL"` with `--json-schema` for structured score extraction. Fallback: `claude -p --plugin-dir . --dangerously-skip-permissions "Run /design-review URL"` with regex parsing of terminal output. The smoke test in Wave 0 determines which path works. Either way, verdict assertions (SHIP/BLOCK/CONDITIONAL) are the primary gate because they are the most deterministic output element.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Implementation Decisions (Claude's Discretion)
All implementation choices are at Claude's discretion -- pure infrastructure phase. Key guidance from research:

- Eval runner: `evals/run-quality-evals.sh` -- bash orchestrator
- Output parser: `evals/parse-review-output.sh` -- extracts scores and verdicts from terminal output
- Fixture serving: `python3 -m http.server` on random port, killed after eval
- Invocation: `claude --print` for non-interactive plugin command execution (needs smoke test first -- may not work, fallback TBD)
- Verdict assertions as primary gate: bad page -> BLOCK, good page -> SHIP, gray -> CONDITIONAL
- Score range assertions as secondary: calibrated from 3 baseline runs + 0.3 buffer
- LLM-as-judge: `curl` to Anthropic Messages API with Haiku, binary rubric (pass/fail), requires ANTHROPIC_API_KEY
- Snapshots: `evals/results/` directory with timestamped JSON files
- Gray-area fixture: mediocre page (some good, some bad) that should score CONDITIONAL
- Existing fixtures: `evals/fixtures/admin-panel.html`, `evals/fixtures/landing-page.html`, `evals/fixtures/emotional-page.html`

### Deferred Ideas (OUT OF SCOPE)
- JSON-first parsing (Phase 10 -- JSON-03)
- Eval fixtures for Figma mode, style presets, dark mode (v1.3+)
- Auto-tuning prompts based on eval results (v1.3+)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVAL-01 | Layer 2 eval runner executes all assertions against real design-review output | Invocation strategy via `claude -p` with `--plugin-dir`, output parsing via regex on terminal output, structured JSON extraction via `--output-format json` |
| EVAL-02 | Assertion ranges calibrated from 3 baseline runs per fixture with observed spread + buffer | Calibration script pattern: run 3 times, capture scores, compute min/max + 0.3 buffer, write back to assertions.json |
| EVAL-03 | Verdict-level assertions (binary: bad page gets BLOCK, good page gets SHIP) as primary gate | Verdict regex: match `SHIP`, `CONDITIONAL`, `BLOCK` from boss output. Most deterministic assertion type. |
| EVAL-04 | At least one gray-area fixture added (mediocre page that should get CONDITIONAL) | New fixture: mediocre page with mixed quality signals. See Gray-Area Fixture Design section. |
| EVAL-05 | LLM-as-judge binary rubric assertions using Claude Haiku (requires ANTHROPIC_API_KEY) | `curl` to Anthropic Messages API with `claude-haiku-4-5` model. Binary pass/fail rubric. Graceful skip when no API key. |
| EVAL-06 | Eval result snapshots with per-specialist scores stored for regression detection | JSON snapshots in `evals/results/YYYY-MM-DD-HHmmss.json`. Regression = previously passing assertion now fails or score drops > 0.5 from prior snapshot. |
</phase_requirements>

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `claude` CLI | 2.1.87 | Invoke design-review non-interactively | The only way to execute plugin commands programmatically from bash |
| `jq` | 1.7.1 | Parse JSON output from `claude -p --output-format json` and assertions.json | Already a project dependency (validate-structure.sh uses it) |
| `python3` | 3.14.3 | HTTP server for fixture serving (`python3 -m http.server`) | Stdlib, zero deps, already planned in CONTEXT.md |
| `curl` | 8.7.1 | Anthropic Messages API for LLM-as-judge (Haiku) | Zero-dependency HTTP client, universal availability |
| `bash` | system | Orchestrator shell, check() pattern from validate-structure.sh | Established project pattern |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `bc` | system | Floating-point arithmetic for score comparisons in bash | Score range assertions (bash cannot do float comparison natively) |
| `mktemp` | system | Temporary file for captured review output | Each eval run captures output before parsing |
| `lsof` / `kill` | system | Port management for fixture server | Detect port conflicts, clean up server after eval |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `python3 -m http.server` | `npx serve` | npx is slower to start, adds node dependency at runtime |
| `bc` for float math | `python3 -c "..."` | python3 is available and cleaner for complex math, but bc is lighter for simple comparisons |
| `claude -p` for invocation | Claude Agent SDK (TypeScript/Python) | SDK gives structured output natively but adds a runtime dependency; bash keeps zero-dep constraint |

## Architecture Patterns

### Recommended Project Structure

```
evals/
  run-evals.sh              # Orchestrator (existing -- calls Layer 1 + Layer 2)
  validate-structure.sh     # Layer 1 (existing -- 107+ assertions)
  run-quality-evals.sh      # Layer 2 (NEW -- quality eval runner)
  parse-review-output.sh    # NEW -- output parser (scores + verdict extraction)
  calibrate-baselines.sh    # NEW -- runs 3 baseline runs, computes ranges
  assertions.json           # Existing -- 12 assertions (ranges updated by calibration)
  fixtures/
    admin-panel.html        # Existing -- functional admin UI (mid-range)
    landing-page.html       # Existing -- polished landing page (high scores)
    emotional-page.html     # Existing -- intentionally bad (low scores, BLOCK)
    gray-area.html          # NEW -- mediocre page (CONDITIONAL expected)
    flow-test/              # Existing -- SPA flow test (not used in Layer 2)
    report-test/            # Existing -- report fixture (not used in Layer 2)
  results/
    .gitkeep                # Existing
    YYYY-MM-DD-HHmmss.json  # NEW -- eval snapshots (gitignored or committed)
```

### Pattern 1: Invocation Strategy (Critical Path)

**What:** How to invoke `/design-review` programmatically from a bash script.
**When to use:** Every quality eval assertion requires a design-review run.

The eval runner MUST work without an interactive terminal. Three invocation strategies, tested in order during smoke test:

**Strategy A (preferred): Describe the task**
```bash
REVIEW_OUTPUT=$(claude -p \
  --plugin-dir "$REPO_ROOT" \
  --dangerously-skip-permissions \
  --model sonnet \
  --max-turns 30 \
  --output-format text \
  "Run a full design review on $FIXTURE_URL. Use the /design-review command." \
  2>/dev/null)
```

**Strategy B: Structured JSON extraction**
```bash
REVIEW_OUTPUT=$(claude -p \
  --plugin-dir "$REPO_ROOT" \
  --dangerously-skip-permissions \
  --model sonnet \
  --max-turns 30 \
  --output-format json \
  "Run a full design review on $FIXTURE_URL" \
  2>/dev/null)

# Extract the text result
REVIEW_TEXT=$(echo "$REVIEW_OUTPUT" | jq -r '.result')
```

**Strategy C (fallback): System prompt injection**
```bash
REVIEW_OUTPUT=$(claude -p \
  --system-prompt-file "$REPO_ROOT/commands/design-review.md" \
  --dangerously-skip-permissions \
  --model sonnet \
  --max-turns 30 \
  "Review the design at $FIXTURE_URL" \
  2>/dev/null)
```

**Key flags:**
- `--dangerously-skip-permissions` -- eval runner cannot prompt for permission
- `--plugin-dir "$REPO_ROOT"` -- loads the plugin so Claude sees the commands
- `--model sonnet` -- sonnet is faster and cheaper than opus for eval runs
- `--max-turns 30` -- prevents runaway sessions; a review takes ~15-20 turns
- `--output-format json` -- if using Strategy B, wraps result in parseable JSON

### Pattern 2: Output Parsing (Regex-Based, Pre-JSON Migration)

**What:** Extract specialist scores and verdict from terminal output.
**When to use:** Before Phase 10 (structured JSON). Also serves as fallback after Phase 10.

The boss synthesizer outputs a table with this structure:
```
| Specialist | Score | Weight | Key Finding |
|-----------|-------|--------|-------------|
| Intent Match | 3/4 | 3x | ... |
| Typography | 2/4 | 2x | ... |
```

And a verdict line:
```
**Verdict: BLOCK**
**Score: 2.35/4.0**
```

Parser extracts using these patterns:
```bash
# Extract verdict (most reliable)
VERDICT=$(echo "$OUTPUT" | grep -oE '(SHIP|CONDITIONAL SHIP|CONDITIONAL|BLOCK)' | head -1)

# Extract overall score
OVERALL=$(echo "$OUTPUT" | grep -oE 'Score: ([0-9.]+)/4\.0' | head -1 | grep -oE '[0-9.]+' | head -1)

# Extract per-specialist score (e.g., Typography)
TYPO_SCORE=$(echo "$OUTPUT" | grep -i 'Typography' | grep -oE '[0-9.]+/4' | head -1 | grep -oE '^[0-9.]+')

# Extract by dimension name from the scores table
extract_score() {
  local dimension="$1"
  local output="$2"
  echo "$output" | grep -i "$dimension" | grep -oE '[0-9.]+/4' | head -1 | grep -oE '^[0-9.]+'
}
```

### Pattern 3: check() Function (From validate-structure.sh)

**What:** Reusable pass/fail reporting with counters.
**When to use:** Every assertion in the eval runner.

```bash
PASS=0
FAIL=0
SKIP=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "[PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

check_skip() {
  local label="$1"
  local reason="$2"
  echo "[SKIP] $label ($reason)"
  SKIP=$((SKIP + 1))
}
```

### Pattern 4: Float Comparison in Bash

**What:** Compare floating-point scores against ranges.
**When to use:** Score range assertions (bash native only supports integer comparison).

```bash
# Returns 0 (true) if value is within [min, max], 1 (false) otherwise
float_in_range() {
  local value="$1" min="$2" max="$3"
  python3 -c "import sys; v,lo,hi=float('$value'),float('$min'),float('$max'); sys.exit(0 if lo<=v<=hi else 1)"
}

# Usage in assertion
check "Admin panel overall score in range [2.0, 3.2]" \
  float_in_range "$ADMIN_OVERALL" "2.0" "3.2"
```

### Pattern 5: Fixture Server Lifecycle

**What:** Serve HTML fixtures and clean up reliably.
**When to use:** Every eval run.

```bash
# Find available port
find_free_port() {
  python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()"
}

PORT=$(find_free_port)
FIXTURE_DIR="$REPO_ROOT/evals/fixtures"

# Start server
python3 -m http.server "$PORT" --directory "$FIXTURE_DIR" &>/dev/null &
SERVER_PID=$!

# Wait for server to be ready
for i in $(seq 1 10); do
  curl -s "http://localhost:$PORT/" >/dev/null 2>&1 && break
  sleep 0.5
done

# ... run evals ...

# Cleanup (trap ensures it runs even on error)
cleanup() {
  kill "$SERVER_PID" 2>/dev/null
  wait "$SERVER_PID" 2>/dev/null
}
trap cleanup EXIT
```

### Anti-Patterns to Avoid

- **Parsing scores with `awk` on Unicode box-drawing output:** The branded output uses Unicode box characters (`┌─┐│└┘` and score bars `████░░░`). Regex must target the markdown table inside the output, not the box art.
- **Hardcoding port numbers:** Always use a random available port. Hardcoded ports conflict with dev servers.
- **Running evals without `--dangerously-skip-permissions`:** The review command invokes Playwright, reads files, runs bash. Without skip-permissions, the eval blocks waiting for user input.
- **Expecting deterministic scores:** LLM scores are stochastic. Assertions MUST use ranges, never exact values.
- **Killing the server before capturing output:** Use `trap cleanup EXIT` so the server dies on any exit path.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Float comparison | Custom awk/bc scripts | `python3 -c` one-liner | Python is available, handles edge cases, cleaner |
| HTTP fixture server | Custom Node.js server | `python3 -m http.server` | Zero deps, stdlib, one line |
| JSON parsing in bash | sed/awk JSON extraction | `jq` | Already a project dependency, handles all edge cases |
| Random port selection | Hardcoded port + retry | `python3 socket.bind(('',0))` | OS assigns guaranteed-free port |
| Process cleanup | Manual kill at end | `trap cleanup EXIT` | Handles errors, signals, early exits |
| Anthropic API client | curl wrapper library | Raw `curl` | Single endpoint, one request pattern, no abstraction needed |

## Common Pitfalls

### Pitfall 1: `claude -p` Cannot Invoke Slash Commands Directly

**What goes wrong:** Running `claude -p "/design-review URL"` fails because slash commands are interactive-mode only.
**Why it happens:** The official docs explicitly state: "User-invoked skills like /commit and built-in commands are only available in interactive mode." GitHub issue #837 was resolved with a `/project:command` syntax, but this applies to project-scoped commands, not plugin commands.
**How to avoid:** Use task-description invocation: `claude -p "Run a design review on URL"` with `--plugin-dir` to load the plugin. The LLM sees the plugin's commands in its context and will invoke them naturally.
**Warning signs:** Empty output, "command not found" errors, Claude responding with generic text instead of a review.

### Pitfall 2: Stochastic Scores Causing Flaky Assertions

**What goes wrong:** An assertion with range [2.5, 3.0] fails 30% of the time because the LLM gives the same page 2.3 or 3.2 on different runs.
**Why it happens:** LLM scoring has inherent variance. The same input produces different scores due to sampling.
**How to avoid:** Calibrate ranges from 3 actual runs. Use `min(observed) - 0.3` and `max(observed) + 0.3` as bounds. Verdict assertions (SHIP/BLOCK) are more stable than score ranges -- make them the primary gate.
**Warning signs:** Same assertion flipping between PASS and FAIL across runs with no prompt changes.

### Pitfall 3: Fixture Server Not Ready When Review Starts

**What goes wrong:** Claude starts the review before the HTTP server is listening, gets connection refused, and produces a broken review.
**Why it happens:** `python3 -m http.server &` returns immediately but the server takes 0.5-1s to bind.
**How to avoid:** Poll with curl in a loop (max 10 attempts, 0.5s sleep) before proceeding. The `find_free_port` + wait pattern above handles this.
**Warning signs:** "Connection refused" in review output, empty screenshots, Tier 3 fallback when Playwright is actually available.

### Pitfall 4: Review Output Includes Orchestrator Noise

**What goes wrong:** The parser extracts the wrong "BLOCK" from a debug message instead of the verdict.
**Why it happens:** `claude -p` output includes tool calls, thinking, and debug text alongside the actual review output.
**How to avoid:** Use `--output-format json` and extract `.result` with jq. This isolates the final response from tool execution noise. If using text mode, anchor regex to the verdict section: look for `**Verdict:` prefix, not bare `BLOCK`.
**Warning signs:** Verdict extraction returns multiple matches, scores parsed from non-table lines.

### Pitfall 5: LLM-as-Judge Haiku Calls Failing Silently

**What goes wrong:** ANTHROPIC_API_KEY is unset or invalid, curl returns an error, the assertion is silently skipped instead of reported.
**Why it happens:** The runner does not check the HTTP status code or parse the error response.
**How to avoid:** Check API key existence before attempting judge calls. Check curl exit code and HTTP status. Parse response for `"error"` key. Report as SKIP (not FAIL) when API is unavailable.
**Warning signs:** All LLM-as-judge assertions show SKIP, API cost is zero when judge assertions exist.

### Pitfall 6: Eval Runner Token Cost Spiral

**What goes wrong:** Running 3 baseline runs per fixture (4 fixtures x 3 runs = 12 full reviews) costs $15-30 in API tokens.
**Why it happens:** Each full design review uses ~100-200K tokens across 8 specialists + boss.
**How to avoid:** Use `--model sonnet` (not opus) for eval runs. Use `--quick` mode for calibration runs (4 specialists, ~40% fewer tokens). Budget 3 full-mode runs per fixture for final calibration only. Add `--max-budget-usd` to prevent runaway costs.
**Warning signs:** Eval run takes over 30 minutes, API billing spikes.

## Code Examples

### LLM-as-Judge via Anthropic Messages API

```bash
# Source: Anthropic Messages API docs (https://platform.claude.com/docs/en/api/messages)
llm_judge() {
  local review_output="$1"
  local rubric="$2"
  local api_key="${ANTHROPIC_API_KEY:-}"

  if [ -z "$api_key" ]; then
    echo "SKIP"
    return 2  # Distinct exit code for skip
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
```

### Eval Result Snapshot Format

```json
{
  "timestamp": "2026-03-29T14:30:00Z",
  "runner_version": "1.0.0",
  "model": "claude-sonnet-4-6",
  "mode": "full",
  "fixtures": {
    "admin-panel": {
      "scores": {
        "overall": 2.65,
        "intent_match": 3.0,
        "originality": 2.0,
        "ux_flow": 3.0,
        "typography": 2.5,
        "color": 2.5,
        "layout": 3.0,
        "icons": 2.0,
        "motion": 2.0,
        "copy": 2.5,
        "code_a11y": 2.5
      },
      "verdict": "BLOCK",
      "review_output_hash": "sha256:abc123..."
    },
    "landing-page": { "..." : "..." },
    "emotional-page": { "..." : "..." },
    "gray-area": { "..." : "..." }
  },
  "assertions": {
    "total": 15,
    "passed": 12,
    "failed": 2,
    "skipped": 1
  }
}
```

### Regression Detection

```bash
compare_snapshots() {
  local current="$1"
  local previous="$2"
  local regressions=0

  if [ ! -f "$previous" ]; then
    echo "[INFO] No previous snapshot -- skipping regression check"
    return 0
  fi

  # Check each fixture's overall score
  for fixture in $(jq -r '.fixtures | keys[]' "$current"); do
    local curr_score prev_score
    curr_score=$(jq -r ".fixtures[\"$fixture\"].scores.overall // 0" "$current")
    prev_score=$(jq -r ".fixtures[\"$fixture\"].scores.overall // 0" "$previous")

    local dropped
    dropped=$(python3 -c "print('yes' if $prev_score - $curr_score > 0.5 else 'no')")

    if [ "$dropped" = "yes" ]; then
      echo "[REGRESSION] $fixture: $prev_score -> $curr_score (dropped > 0.5)"
      regressions=$((regressions + 1))
    fi
  done

  return "$regressions"
}
```

## Gray-Area Fixture Design

A good gray-area fixture has mixed signals that should produce a CONDITIONAL verdict (score near threshold, some good some bad). Design principles:

**What makes a gray-area page:**
- Typography is decent (system fonts, basic hierarchy) -- score ~2.5
- Color palette is acceptable but generic (blue + gray) -- score ~2.5
- Layout works but is template-like (nothing interesting) -- score ~2.5
- Intent match is mediocre (unclear audience, weak CTA) -- score ~2.0
- Code is clean but no a11y extras -- score ~2.5

**What to avoid in gray-area fixture:**
- Obviously broken elements (that makes it a bad page)
- Obviously excellent elements (that makes it a good page)
- Controversial design choices that could swing wildly between runs

**Template: SaaS pricing page with decent execution but no spark:**
- Clean layout, readable fonts, proper spacing
- But: generic stock-photo-like copy, no personality, template feel
- CTA exists but is not compelling
- Expected overall: ~2.4-2.6 on 1-4 scale
- SaaS threshold is 3.0 -> this should get CONDITIONAL or BLOCK

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `claude-3-haiku-20240307` for judge | `claude-haiku-4-5` | Oct 2025 | Claude 3 Haiku is deprecated (retirement: April 19, 2026). Must use Haiku 4.5 for judge calls. |
| `claude -p "/command"` for invocation | `claude -p "describe task" --plugin-dir` | May 2025 (issue #837) | Slash commands in -p mode have known issues (#1048, #1339). Task-description invocation is more reliable. |
| `--output-format text` default | `--output-format json` available | Current | JSON output wraps result with metadata (session_id, usage). Extract `.result` with jq for clean text. |
| `--json-schema` for guaranteed structure | Available but not guaranteed | Current | Schema validation is best-effort by the LLM. Do not rely on it for score extraction -- still need parser fallback. |

**Deprecated/outdated:**
- `claude-3-haiku-20240307`: Deprecated, retiring April 19, 2026. Use `claude-haiku-4-5` instead.
- `CLAUDE_SESSION` environment variable: The current `run-evals.sh` checks this, but it is not a documented or reliable way to detect Claude Code availability. Use `command -v claude` instead.

## Open Questions

1. **Does `claude -p --plugin-dir . "Run a design review on URL"` actually trigger the design-review command?**
   - What we know: The docs say slash commands are interactive-only, but `--plugin-dir` loads plugin context (commands, skills, agents). Claude should "see" the design-review command in its context and use it.
   - What's unclear: Whether Claude will reliably invoke the full 8-specialist review pipeline or produce a simplified response.
   - Recommendation: First task in the plan must be a smoke test. Run a minimal invocation and verify the output contains specialist scores and a verdict.

2. **How long does a single `claude -p` design-review run take?**
   - What we know: Interactive reviews take 8-10 minutes. Print mode skips UI rendering but may be slower due to sequential processing.
   - What's unclear: Whether print mode parallelizes specialist dispatch the same way interactive mode does.
   - Recommendation: Time the smoke test. If > 15 minutes per fixture, calibration (3 runs x 4 fixtures = 12 runs) needs `--quick` mode to stay under 2 hours.

3. **Will the `--bare` flag break plugin loading?**
   - What we know: Bare mode "skips auto-discovery of hooks, skills, plugins, MCP servers." But the docs say "Skills still resolve via /skill-name" and `--plugin-dir` explicitly loads plugins.
   - What's unclear: Whether `--bare` + `--plugin-dir` loads the plugin's commands correctly.
   - Recommendation: Test `--bare` in the smoke test. If it works, use it (faster startup). If not, omit it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `claude` CLI | Review invocation | Yes | 2.1.87 | None -- blocks execution |
| `jq` | JSON parsing | Yes | 1.7.1 | None -- already required by Layer 1 |
| `python3` | Fixture serving + float math | Yes | 3.14.3 | None -- stdlib HTTP server |
| `curl` | LLM-as-judge API calls | Yes | 8.7.1 | Graceful skip (EVAL-05 only) |
| `ANTHROPIC_API_KEY` | LLM-as-judge | Unknown | -- | Graceful skip with SKIP status |
| Playwright + Chromium | Screenshots in review | Unknown at eval time | -- | Review degrades to Tier 3 (code-only) |
| Gemini CLI | Color + Layout specialists | Unknown at eval time | -- | Review degrades to Tier 2 |

**Missing dependencies with no fallback:**
- `claude` CLI -- required for all Layer 2 evals. Already verified available.

**Missing dependencies with fallback:**
- `ANTHROPIC_API_KEY` -- only needed for EVAL-05 (LLM-as-judge). Graceful skip when absent.
- Playwright/Gemini -- affect review quality tier but not eval runner functionality. Tier should be captured in snapshot metadata.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash (custom check() function pattern from validate-structure.sh) |
| Config file | `evals/assertions.json` (assertion definitions) |
| Quick run command | `bash evals/run-quality-evals.sh --fixture admin-panel` |
| Full suite command | `bash evals/run-quality-evals.sh` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | Runner executes all assertions | smoke + integration | `bash evals/run-quality-evals.sh` | No -- Wave 0 |
| EVAL-02 | Ranges calibrated from 3 runs | manual calibration | `bash evals/calibrate-baselines.sh` | No -- Wave 0 |
| EVAL-03 | Verdict assertions work | integration | `bash evals/run-quality-evals.sh --fixture emotional-page` | No -- Wave 0 |
| EVAL-04 | Gray-area fixture added | structural | `test -f evals/fixtures/gray-area.html` | No -- Wave 0 |
| EVAL-05 | LLM-as-judge works with Haiku | integration | `ANTHROPIC_API_KEY=test bash evals/run-quality-evals.sh --judge-only` | No -- Wave 0 |
| EVAL-06 | Snapshots stored for regression | integration | `bash evals/run-quality-evals.sh && test -f evals/results/*.json` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `bash evals/validate-structure.sh` (Layer 1 only -- Layer 2 is too expensive per commit)
- **Per wave merge:** `bash evals/run-quality-evals.sh --fixture emotional-page` (single fixture sanity check)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `evals/run-quality-evals.sh` -- entire Layer 2 runner (EVAL-01)
- [ ] `evals/parse-review-output.sh` -- output parser (EVAL-01)
- [ ] `evals/calibrate-baselines.sh` -- calibration helper (EVAL-02)
- [ ] `evals/fixtures/gray-area.html` -- gray-area fixture (EVAL-04)

## Fixture Inventory Discrepancy

The CONTEXT.md mentions `good-page.html` and `bad-page.html` but these do not exist. The actual fixtures are:

| File | Purpose | Expected Behavior |
|------|---------|-------------------|
| `admin-panel.html` | Functional but unpolished admin UI | Mid-range scores, BLOCK or CONDITIONAL verdict |
| `landing-page.html` | Polished SaaS landing page | Higher scores, closest to SHIP |
| `emotional-page.html` | Intentionally terrible design | Very low scores, always BLOCK |
| `gray-area.html` (NEW) | Mediocre page, mixed signals | CONDITIONAL expected |

The assertions.json correctly references the actual filenames. No code change needed -- just correcting the documentation in CONTEXT.md.

## Assertions Architecture

The 12 existing assertions in `assertions.json` break down as:

| Fixture | Assertion Count | Types |
|---------|----------------|-------|
| admin-panel | 4 | overall range, layout range, typography range, verdict |
| landing-page | 3 | overall range, color range, intent range |
| emotional-page | 5 | overall range, typography range, color range, code_a11y range, verdict |

**Missing assertions to add:**
- landing-page verdict assertion (should be SHIP or CONDITIONAL)
- gray-area fixture assertions (overall range, verdict = CONDITIONAL)
- Cross-fixture ranking assertion (emotional < admin < landing in overall score)

**LLM-as-judge assertions to add (EVAL-05):**
- "Does the review identify specific CSS selectors or file:line references?" (evidence specificity)
- "Does the review mention the page type and evaluate against appropriate standards?" (context awareness)
- "Are the top fixes actionable with concrete alternatives?" (fix quality)

## Sources

### Primary (HIGH confidence)
- [Claude Code CLI Reference](https://code.claude.com/docs/en/cli-reference) -- All CLI flags including --print, --plugin-dir, --output-format, --json-schema, --bare, --dangerously-skip-permissions
- [Claude Code Headless/Programmatic Mode](https://code.claude.com/docs/en/headless) -- Explicit note that "User-invoked skills are only available in interactive mode. In -p mode, describe the task."
- [Anthropic Models Overview](https://platform.claude.com/docs/en/about-claude/models/overview) -- claude-haiku-4-5 model ID, pricing ($1/MTok input, $5/MTok output), Claude 3 Haiku deprecation
- [GitHub Issue #837: Slash commands in print mode](https://github.com/anthropics/claude-code/issues/837) -- Closed as completed, confirmed working with caveats, known issues #1048 and #1339
- Direct codebase analysis: `evals/run-evals.sh`, `evals/validate-structure.sh`, `evals/assertions.json`, `config/scoring.json`, `commands/design-review.md`, `shared/output.md`, `skills/design-review/prompts/boss.md`

### Secondary (MEDIUM confidence)
- [Claude Code Eval Loop Pattern](https://www.mager.co/blog/2026-03-08-claude-code-eval-loop/) -- Uses `claude -p <query>` for each test case, streams JSON output for detection
- [cc-plugin-eval Framework](https://github.com/sjnims/cc-plugin-eval) -- 4-stage eval framework using Agent SDK with tool capture hooks
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin directory structure, command resolution

### Tertiary (LOW confidence -- needs validation via smoke test)
- Whether `claude -p --plugin-dir . "Run a design review"` reliably triggers the full 8-specialist pipeline
- Whether `--bare` + `--plugin-dir` correctly loads plugin commands
- Whether `--output-format json` captures the full review output including scores table

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools verified available on machine with correct versions
- Architecture: HIGH -- patterns derived from existing Layer 1 code and official CLI docs
- Invocation strategy: MEDIUM -- the critical `claude -p` + plugin question requires a smoke test; the docs are ambiguous
- Output parsing: HIGH -- boss output format is well-defined in prompts/boss.md with clear regex targets
- LLM-as-judge: HIGH -- Anthropic Messages API is well-documented, curl pattern is standard
- Pitfalls: HIGH -- derived from official docs, known GitHub issues, and stochastic eval literature

**Research date:** 2026-03-29
**Valid until:** 2026-04-15 (CLI flags and model names are stable; invocation behavior may change with Claude Code updates)

---
*Phase: 09-layer-2-eval-runner*
*Research completed: 2026-03-29*
