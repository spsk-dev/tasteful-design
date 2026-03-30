---
phase: 05-per-screen-review-animation
plan: 02
subsystem: commands
tags: [design-audit, specialist-dispatch, animation-detection, flow-scoring, playwright-mcp, prefers-reduced-motion]

# Dependency graph
requires:
  - phase: 05-per-screen-review-animation/plan-01
    provides: flow-scoring.json smart_weighting, flow_score, animation, consistency config
  - phase: 04-flow-navigation-engine
    provides: design-audit.md Sections 1-9 (navigation, screenshot capture, flow-state.json)
provides:
  - Per-screen specialist review dispatch with full/quick smart weighting
  - Animation detection hooks injected into both navigation modes
  - Animation summary with duration/easing quality and PRM compliance
  - Flow score aggregation with position-weighted average (1.5x first/last)
  - Branded flow review summary output (Sections 10-13)
affects: [05-per-screen-review-animation/plan-03, 06-html-report]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Smart weighting: full 8-specialist review for first/last screens, quick 4-specialist for middle"
    - "Animation enrichment: Motion specialist receives runtime animation data from navigation"
    - "Sequential per-screen reviews to manage token budget"
    - "Flow score = weighted average with position weights from config"

key-files:
  created: []
  modified:
    - commands/design-audit.md

key-decisions:
  - "Per-screen reviews run sequentially, not in parallel, to manage token budget"
  - "Motion specialist receives animation data from navigation alongside source analysis"
  - "Flow score uses weighted average with 1.5x for first/last screens, not simple average"
  - "Consistency penalty deferred to Plan 03 (consistency_penalty: null in flow_score)"

patterns-established:
  - "Animation hooks pattern: inject listeners before click, capture state after stability, compare pre/post"
  - "Deterministic mode animation: current state + PRM only (no pre/post diff since no click)"
  - "Per-screen score storage with progressive persistence after each screen review"

requirements-completed: [REVW-01, REVW-02, REVW-04, ANIM-01, ANIM-02, ANIM-03]

# Metrics
duration: 4min
completed: 2026-03-30
---

# Phase 5 Plan 2: Per-Screen Review + Animation Summary

**Per-screen specialist review dispatch with full/quick smart weighting, runtime animation detection, and position-weighted flow score aggregation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T00:52:02Z
- **Completed:** 2026-03-30T00:56:58Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Animation detection hooks injected into both Intent Mode (Steps B2, E2) and Deterministic Mode (Step C2)
- Per-screen review dispatch (Section 10) with smart weighting: full 8-specialist for first/last, quick 4-specialist for middle screens
- Animation summary (Section 11) with duration quality, easing quality, transition coverage, and PRM compliance
- Flow score aggregation (Section 12) using weighted average with configurable position weights
- Branded flow review summary (Section 13) with per-screen score table, animation findings box, flow verdict box, and top 5 fixes

## Task Commits

Each task was committed atomically:

1. **Task 1: Add animation detection hooks to navigation loops** - `0b46207` (feat)
2. **Task 2: Add per-screen review dispatch and flow score aggregation sections** - `a5e53ae` (feat)

## Files Created/Modified
- `commands/design-audit.md` - Extended from 520 to 1039 lines: added animation detection hooks (Steps B2, E2, C2), per-screen review dispatch (Section 10), animation summary (Section 11), flow score aggregation (Section 12), branded flow review summary (Section 13). Updated allowed-tools and Key Constraints.

## Decisions Made
- Per-screen reviews are sequential (not parallel) to manage token budget -- each screen completes fully before the next starts
- Motion specialist (#5) receives runtime animation data from flow navigation alongside its normal source code analysis, enabling hybrid static+runtime animation assessment
- Flow score uses position-weighted average (1.5x for first/last screens) matching config/flow-scoring.json, not a simple average
- Consistency penalty field is null until Plan 03's consistency pass computes and fills it in
- Section 8 restructured: summary display moved to Section 13, Section 8 now only updates flow-state.json and shows transition message

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

- `flow_score.consistency_penalty: null` in flow-state.json -- intentional placeholder, will be computed by Plan 03 (consistency cross-screen pass)

## Next Phase Readiness
- design-audit.md now has complete Sections 1-13 covering navigation through scoring and summary
- Plan 03 (consistency cross-screen analysis) can read per-screen specialist findings from flow-state.json and compute consistency penalties
- Phase 6 (HTML report) can consume the complete flow-state.json including review scores, animation summary, and flow verdict

## Self-Check: PASSED

- FOUND: commands/design-audit.md
- FOUND: 05-02-SUMMARY.md
- FOUND: commit 0b46207 (Task 1)
- FOUND: commit a5e53ae (Task 2)

---
*Phase: 05-per-screen-review-animation*
*Completed: 2026-03-30*
