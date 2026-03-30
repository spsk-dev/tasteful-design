---
phase: 09-layer-2-eval-runner
plan: 01
subsystem: testing
tags: [bash, eval, claude-cli, assertions, scoring, fixtures]

requires:
  - phase: 08-prompt-extraction
    provides: Extracted specialist prompts with boss output format to parse
provides:
  - Layer 2 quality eval runner (run-quality-evals.sh)
  - Review output parser (parse-review-output.sh)
  - Gray-area fixture for CONDITIONAL verdict testing
  - End-to-end assertion pipeline (verdict + score range)
affects: [09-02-calibration, 10-structured-json, eval-regression-detection]

tech-stack:
  added: []
  patterns:
    - "claude -p --plugin-dir for non-interactive plugin invocation"
    - "check()/check_skip() pattern with PASS/FAIL/SKIP counters"
    - "python3 -m http.server on random port with trap cleanup"
    - "float_in_range via python3 one-liner for bash float comparison"
    - "dimension-to-label mapping for boss output table parsing"

key-files:
  created:
    - evals/fixtures/gray-area.html
    - evals/parse-review-output.sh
    - evals/run-quality-evals.sh
  modified: []

key-decisions:
  - "Output parser normalizes CONDITIONAL SHIP to CONDITIONAL for assertion matching"
  - "Strategy A (task description with --plugin-dir) as primary invocation, no --bare flag"
  - "Dry-run mode caches to evals/results/cache-{fixture}.txt for development iteration"
  - "python3 for float comparison instead of bc (cleaner, already required for http server)"

patterns-established:
  - "Layer 2 evals source parse-review-output.sh for extraction functions"
  - "Assertions read dynamically from assertions.json via jq (not hardcoded)"
  - "--fixture and --dry-run flags for targeted and offline testing"

requirements-completed: [EVAL-01, EVAL-03, EVAL-04]

duration: 3min
completed: 2026-03-30
---

# Phase 09 Plan 01: Layer 2 Eval Runner Core Summary

**Quality eval runner with gray-area fixture, output parser for verdict/score extraction, and assertion pipeline against assertions.json ranges**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-30T04:14:08Z
- **Completed:** 2026-03-30T04:17:47Z
- **Tasks:** 2
- **Files created:** 3

## Accomplishments
- Gray-area fixture (mediocre SaaS pricing page) targeting CONDITIONAL verdict with mixed quality signals
- Output parser with 4 extraction functions (verdict, overall, per-specialist, float range) plus verdict normalization
- Full eval runner orchestrating: dependency check -> fixture server -> review invocation -> assertion execution -> summary
- End-to-end verified with mock cached output: all 5 emotional-page assertions pass correctly

## Task Commits

Each task was committed atomically:

1. **Task 1: Gray-area fixture + output parser** - `7cf63f6` (feat)
2. **Task 2: Core eval runner with assertions** - `9a9e5e0` (feat)

## Files Created/Modified
- `evals/fixtures/gray-area.html` - Mediocre SaaS pricing page (3-tier grid, system fonts, blue-gray palette, generic copy, no a11y extras)
- `evals/parse-review-output.sh` - Sourced parser: extract_verdict, extract_overall, extract_score (10 dimensions), float_in_range, verdict_matches
- `evals/run-quality-evals.sh` - Layer 2 orchestrator: serves fixtures, invokes claude -p, reads assertions.json, reports PASS/FAIL/SKIP

## Decisions Made
- Used `verdict_matches()` helper with normalization instead of raw string comparison (handles "CONDITIONAL SHIP" vs "CONDITIONAL" discrepancy)
- Chose Strategy A (task description with `--plugin-dir`) as the primary invocation path per research recommendation -- no `--bare` flag
- Cached review output automatically to `evals/results/cache-{name}.txt` on live runs for future `--dry-run` reuse
- Used `python3 -c` for float comparison (already required for http.server, cleaner than bc)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Runner is ready for Plan 02 (calibration from baseline runs and gray-area assertion wiring)
- Parser handles all 10 scored dimensions from the boss output format
- Smoke test of `claude -p` invocation still needed with real review (deferred to calibration phase where 3 baseline runs will validate the invocation path)
- Layer 1 structural checks still pass (107/107)

## Self-Check: PASSED

---
*Phase: 09-layer-2-eval-runner*
*Completed: 2026-03-30*
