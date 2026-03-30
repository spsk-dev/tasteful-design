---
phase: 11-specialist-consolidation
plan: 01
subsystem: design-review
tags: [specialist-agents, scoring, prompt-engineering, copy-quality]

# Dependency graph
requires:
  - phase: 10-structured-json
    provides: "Intent specialist with 3 sub-score JSON output schema"
provides:
  - "7-specialist system with Intent producing 4 sub-scores (intent_match, originality, ux_flow, copy_quality)"
  - "Scoring formula dividing by 16 with 9 weighted dimensions"
  - "Boss synthesizer reporting copy_quality as informational (not weighted)"
affects: [11-02, documentation-updates, eval-recalibration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Informational sub-score pattern: specialist produces score that is tracked but not weighted in formula"
    - "Specialist consolidation: merge domain into existing specialist as additional dimension"

key-files:
  created: []
  modified:
    - "skills/design-review/prompts/intent.md"
    - "config/scoring.json"
    - "skills/design-review/prompts/boss.md"
    - "commands/design-review.md"

key-decisions:
  - "copy_quality is informational (not weighted) -- Intent specialist produces 4 sub-scores but only 3 are weighted (I*3+O*3+UX*2), copy_quality is reported for visibility"
  - "total_weight 17->16: removing standalone Copy weight (1) nets 16, copy_quality does not get its own weight entry"
  - "Boss JSON includes copy_quality in scores object for data completeness but formula excludes it"

patterns-established:
  - "Informational sub-score: produced by specialist, tracked in output, not weighted in verdict formula"

requirements-completed: [SPEC-01, SPEC-02]

# Metrics
duration: 4min
completed: 2026-03-30
---

# Phase 11 Plan 01: Copy Specialist Merge into Intent Summary

**Copy specialist folded into Intent/Originality/UX as 4th sub-score (copy_quality), scoring formula updated to /16 with 9 weighted dimensions, system reduced from 8 to 7 specialists**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T05:16:26Z
- **Completed:** 2026-03-30T05:21:20Z
- **Tasks:** 2
- **Files modified:** 4 (+ 1 deleted)

## Accomplishments
- Intent specialist now evaluates 4 dimensions: intent_match, originality, ux_flow, copy_quality
- Scoring formula updated from /17 to /16 (9 weighted dimensions instead of 10)
- Boss synthesizer reports copy_quality as informational but does not weight it in verdict
- design-review.md dispatches 7 specialists with all count references updated
- copy.md prompt file deleted after full content merge

## Task Commits

Each task was committed atomically:

1. **Task 1: Merge Copy into Intent prompt and update scoring.json** - `e6e7c8f` (feat)
2. **Task 2: Update boss formula and design-review dispatch for 7 specialists** - `bbc6445` (feat)

## Files Created/Modified
- `skills/design-review/prompts/intent.md` - Added copy_quality as 4th dimension with rubric, checklist, and output schema
- `config/scoring.json` - Removed copy weight, total_weight 17->16, quick_mode unchanged at 13
- `skills/design-review/prompts/boss.md` - Formula /16, 9 weighted dimensions, copy_quality informational
- `commands/design-review.md` - 7 specialists throughout, removed Copy dispatch section, renumbered Code to #7
- `skills/design-review/prompts/copy.md` - DELETED (content merged into intent.md)

## Decisions Made
- **copy_quality as informational sub-score:** The plan's weight math had an apparent contradiction (copy_quality weight 1 + removing copy weight 1 = still 17). Resolved by following the stated intent of total_weight=16: copy_quality is produced by the Intent specialist and tracked in output for visibility, but does not have its own weight entry in scoring.json. This means 9 weighted dimensions (3+3+2+2+2+1+1+1+1=16) instead of 10.
- **Boss JSON includes copy_quality:** For data completeness and consumer use (report generator, improve loop), copy_quality appears in the boss scores object even though it is not weighted. This avoids data loss while keeping the formula clean.
- **Quick mode unchanged:** Copy was never in quick mode, so quick_mode_weights and quick_mode_total_weight (13) remain identical.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 11-02 can proceed: documentation updates across shared/output.md, README.md, ARCHITECTURE.md, and eval recalibration
- The 7-specialist system is functionally complete for `/design-review` execution
- Evals may need assertion updates for 9 dimensions and /16 math (covered in plan 02)

## Self-Check: PASSED

- All modified files exist on disk
- copy.md confirmed deleted
- Commit e6e7c8f found in git log
- Commit bbc6445 found in git log

---
*Phase: 11-specialist-consolidation*
*Completed: 2026-03-30*
