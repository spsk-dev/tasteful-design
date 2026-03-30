---
phase: 05-per-screen-review-animation
plan: 01
subsystem: config
tags: [animation, consistency, scoring, web-animations-api, prefers-reduced-motion, flow-audit]

# Dependency graph
requires:
  - phase: 04-flow-navigation-engine
    provides: flow-scoring.json base config, flow.md Sections 1-8
provides:
  - Smart weighting config for full/quick specialist review by screen position
  - Flow score aggregation formula with 1.5x weighting for first/last screens
  - Consistency thresholds (color Delta E, spacing, typography tolerances)
  - Animation detection config (duration ranges, easing quality levels)
  - Injectable JS snippets for runtime animation capture via browser_evaluate
  - prefers-reduced-motion compliance check pattern
  - Cross-screen consistency heuristics (5 checks with severity and penalty formula)
affects: [05-02-PLAN, 05-03-PLAN, design-audit-command]

# Tech tracking
tech-stack:
  added: []
  patterns: [runtime-animation-detection, pre-post-click-comparison, event-listener-injection, consistency-post-processing]

key-files:
  created: []
  modified:
    - config/flow-scoring.json
    - skills/design-review/references/flow.md

key-decisions:
  - "Delta E threshold of 10 for color drift detection (noticeable to non-designers)"
  - "4px spacing tolerance and 2px font size tolerance for consistency checks"
  - "Hybrid animation detection: pre/post snapshot comparison + event listeners"
  - "Consistency is a post-processing pass, not a 9th specialist"
  - "Penalty formula: max 15% flow score reduction from consistency findings"

patterns-established:
  - "Pre-click/post-stable capture pattern: inject listeners before click, collect after DOM stability"
  - "Consistency severity levels: drift (warning), mismatch (issue), conflict (critical)"
  - "Config-driven thresholds: all numeric values in flow-scoring.json, not hardcoded in references"

requirements-completed: [REVW-02, REVW-04, ANIM-01, ANIM-02]

# Metrics
duration: 4min
completed: 2026-03-30
---

# Phase 5 Plan 1: Config + Reference Contracts Summary

**Smart weighting, flow scoring, animation detection JS snippets, and 5-check cross-screen consistency heuristics for the design-audit command**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T00:45:22Z
- **Completed:** 2026-03-30T00:49:08Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Extended flow-scoring.json from 6 to 10 top-level keys with smart weighting, flow score formula, consistency thresholds, and animation detection config
- Added 3 new sections (250 lines) to flow.md with injectable JS snippets for animation capture, prefers-reduced-motion compliance, and consistency heuristics
- Established config-driven contracts that Plans 02 and 03 will consume at runtime

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend flow-scoring.json with smart weighting, consistency, animation, and flow score config** - `27583d9` (feat)
2. **Task 2: Add animation detection and consistency heuristics to flow.md reference** - `9ad6b85` (feat)

## Files Created/Modified
- `config/flow-scoring.json` - Added smart_weighting, flow_score, consistency, animation sections (4 new top-level keys)
- `skills/design-review/references/flow.md` - Added Sections 9 (animation detection), 10 (prefers-reduced-motion), 11 (cross-screen consistency)

## Decisions Made
- Delta E threshold of 10 for color drift -- perceptible to non-designers, avoids false positives from minor rendering differences
- Hybrid animation detection approach (pre/post snapshots + event listeners) -- covers both CSS-declared and JS-triggered animations per PITFALLS.md Pitfall 6
- Consistency as post-processing pass, not a 9th specialist -- reads existing specialist findings without adding another review step
- Penalty formula caps at 15% flow score reduction -- prevents consistency issues from dominating the score while still penalizing meaningfully

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all config values are production-ready numeric thresholds and the JS snippets are complete and injectable.

## Next Phase Readiness
- Plans 02 and 03 can read `config/flow-scoring.json` for all thresholds without defining their own constants
- Plans 02 and 03 can reference `flow.md` Sections 9-11 for animation detection snippets and consistency heuristics
- All contracts are established: config values, JS snippets, heuristic definitions, output format

## Self-Check: PASSED

- config/flow-scoring.json: FOUND
- skills/design-review/references/flow.md: FOUND
- 05-01-SUMMARY.md: FOUND
- Commit 27583d9: FOUND
- Commit 9ad6b85: FOUND

---
*Phase: 05-per-screen-review-animation*
*Completed: 2026-03-30*
