---
phase: 09-layer-2-eval-runner
plan: 02
subsystem: testing
tags: [bash, eval, anthropic-api, haiku, assertions, snapshots, regression, calibration]

requires:
  - phase: 09-01-PLAN
    provides: Layer 2 eval runner core (run-quality-evals.sh, parse-review-output.sh, gray-area fixture)
provides:
  - LLM-as-judge assertions via Claude Haiku 4.5 API
  - Eval result snapshots (timestamped JSON in evals/results/)
  - Regression detection comparing current vs previous snapshot
  - Calibration helper documenting 3-run baseline process
  - Complete assertion set (19 assertions: score, verdict, judge, ranking)
  - Orchestrator wiring (run-evals.sh calls run-quality-evals.sh)
affects: [10-structured-json, eval-calibration, prompt-tuning-feedback]

tech-stack:
  added: []
  patterns:
    - "llm_judge() via curl to api.anthropic.com/v1/messages with claude-haiku-4-5"
    - "Graceful SKIP (exit code 2) when ANTHROPIC_API_KEY absent"
    - "Timestamped JSON snapshots with per-fixture scores and assertion tallies"
    - "Regression detection: flag score drops > 0.5 vs previous snapshot"
    - "also_accept array in verdict assertions for flexible matching"
    - "jq-based assertion type filtering (score/verdict vs judge/ranking)"

key-files:
  created:
    - evals/calibrate-baselines.sh
  modified:
    - evals/run-quality-evals.sh
    - evals/assertions.json
    - evals/run-evals.sh

key-decisions:
  - "LLM-as-judge uses claude-haiku-4-5 (not deprecated Claude 3 Haiku) for cost-efficient binary rubric evaluation"
  - "Judge assertions gracefully SKIP (not FAIL) when ANTHROPIC_API_KEY is absent -- no false failures in CI"
  - "Verdict assertions support also_accept array for flexible matching (e.g., CONDITIONAL also accepts BLOCK)"
  - "Snapshots saved per-run with all specialist scores, enabling trend analysis across prompt changes"
  - "Regression threshold set at 0.5 score drop -- detects meaningful degradation without false alarms"
  - "Ranking assertions verify cross-fixture ordering (emotional < admin < landing) with lenient <= comparison"

patterns-established:
  - "Section 5b/5c/5d/5e pattern: typed assertion loops after score assertions"
  - "Snapshot-then-compare pattern for regression detection"
  - "Calibration via documented helper (not fully automated -- too expensive)"

requirements-completed: [EVAL-02, EVAL-05, EVAL-06]

duration: 4min
completed: 2026-03-30
---

# Phase 09 Plan 02: LLM-as-Judge + Snapshots + Regression Detection Summary

**LLM-as-judge via Haiku API with graceful skip, timestamped JSON snapshots, regression detection (0.5 threshold), 19 assertions covering 4 fixtures, and Layer 2 wired into orchestrator**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T04:19:52Z
- **Completed:** 2026-03-30T04:23:52Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- LLM-as-judge function calls Claude Haiku 4.5 with binary rubrics, returns PASS/FAIL/SKIP with graceful degradation
- Eval snapshots written to evals/results/ as timestamped JSON with per-fixture scores and assertion tallies
- Regression detection compares current snapshot to previous, flags score drops > 0.5
- assertions.json expanded from 12 to 19 assertions (gray-area, landing verdict, ranking, 3 judge rubrics)
- run-evals.sh now calls run-quality-evals.sh as Layer 2a (TODO stub replaced)
- Calibration helper documents the 3-run baseline process with cost estimates

## Task Commits

Each task was committed atomically:

1. **Task 1: LLM-as-judge + snapshots + regression in runner** - `8b7b977` (feat)
2. **Task 2: Expand assertions + calibration helper + wire orchestrator** - `4dd93b3` (feat)

## Files Created/Modified
- `evals/run-quality-evals.sh` - Added llm_judge(), Section 5b (judge assertions), 5c (ranking), 5d (snapshots), 5e (regression), also_accept verdict handling
- `evals/assertions.json` - Expanded 12 -> 19 assertions, version 1.1.0, added gray-area, landing verdict, ranking, 3 judge rubric assertions
- `evals/calibrate-baselines.sh` - New helper documenting 3-run calibration process with cost estimates
- `evals/run-evals.sh` - Replaced TODO stub with run-quality-evals.sh invocation, reports L2A_STATUS

## Decisions Made
- Used claude-haiku-4-5 (not deprecated Claude 3 Haiku) -- avoids April 2026 retirement
- Graceful SKIP when ANTHROPIC_API_KEY absent -- no false failures, safe for CI environments
- Verdict assertions support also_accept array -- needed for gray-area (CONDITIONAL or BLOCK) and landing (CONDITIONAL or SHIP)
- Regression threshold at 0.5 -- balances sensitivity with tolerance for LLM stochasticity
- Ranking uses lenient <= comparison (not strict <) -- admin and gray-area may overlap in middle
- Calibration helper is documented workflow, not fully automated (3x4 full reviews = $15-30, too expensive to automate)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - ANTHROPIC_API_KEY is optional (judge assertions skip gracefully when absent).

## Next Phase Readiness
- Phase 09 complete: Layer 2 eval runner fully functional with judge, snapshots, regression
- 19 assertions covering all 4 fixtures with score, verdict, judge, and ranking types
- Calibration can be run via calibrate-baselines.sh when ready to tune assertion ranges
- Layer 1 structural checks still pass (107/107)
- Orchestrator (run-evals.sh) runs both layers end-to-end

## Self-Check: PASSED

---
*Phase: 09-layer-2-eval-runner*
*Completed: 2026-03-30*
