---
phase: 04-flow-navigation-engine
plan: 02
subsystem: commands
tags: [playwright-mcp, spa-navigation, flow-audit, intent-navigation, deterministic-navigation, screenshot-capture, flow-state]

# Dependency graph
requires:
  - phase: 04-01
    provides: config/flow-scoring.json (max_screens, DOM stability thresholds, screenshot viewport) and references/flow.md (navigation knowledge)
provides:
  - commands/design-audit.md -- 519-line prompt-driven MCP orchestrator for SPA flow navigation with intent + deterministic modes
affects: [04-03, phase-05, phase-06]

# Tech tracking
tech-stack:
  added: []
  patterns: [prompt-driven MCP orchestration, intent-based CTA matching from accessibility tree, progressive flow-state.json persistence]

key-files:
  created:
    - commands/design-audit.md
  modified: []

key-decisions:
  - "Snapshot-before-click pattern enforced as critical constraint (stale ref protection)"
  - "Click failure handled with single retry using fresh snapshot before terminating"
  - "Deterministic mode continues to next URL on navigation failure rather than terminating entire flow"

patterns-established:
  - "Intent mode loop: snapshot -> reason about CTA -> click -> DOM stability -> font readiness -> confirm new screen -> capture -> persist state"
  - "Deterministic mode loop: navigate -> DOM stability -> font readiness -> capture -> persist state"
  - "Auth gate pattern: snapshot for login form detection -> user checkpoint -> re-snapshot to verify"

requirements-completed: [FLOW-01, FLOW-02, FLOW-03, FLOW-06]

# Metrics
duration: 3min
completed: 2026-03-30
---

# Phase 04 Plan 02: Design Audit Command Summary

**519-line design-audit.md with intent-driven CTA navigation and deterministic URL sequence modes, Playwright MCP orchestration, progressive flow-state.json persistence, and auth/cookie handling**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-30T00:26:52Z
- **Completed:** 2026-03-30T00:29:42Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created the core design-audit command (519 lines) -- the main deliverable of Phase 4
- Intent mode navigation loop: snapshot -> reason about CTA matching flow intent -> click -> DOM stability (800ms quiet) -> font readiness -> confirm screen change -> capture screenshot -> update flow-state.json
- Deterministic mode navigation: navigate to each URL in sequence -> stability -> readiness -> capture -> persist
- Progressive flow-state.json writing after each screen ensures partial results survive mid-flow failures
- Auth handling with login form detection via accessibility tree and user checkpoint
- Cookie/popup dismissal before navigation loop starts
- Comprehensive error handling: click retry with fresh snapshot, navigation fallback for deterministic mode, stability timeout tolerance, max screens limit

## Task Commits

Each task was committed atomically:

1. **Task 1: Create design-audit.md command -- core navigation engine** - `62f5e04` (feat)

## Files Created/Modified
- `commands/design-audit.md` - Flow navigation engine: 9 sections covering argument parsing, setup, MCP verification, auth handling, cookie dismissal, intent mode loop, deterministic mode loop, flow completion, and error handling

## Decisions Made
- Snapshot-before-click enforced as critical constraint in both the intent mode loop and the key constraints section -- prevents stale element ref failures (Pitfall 5)
- Click failure handled with single retry using fresh snapshot, then graceful termination with error screenshot and partial flow-state preserved
- Deterministic mode continues to next URL on navigation failure rather than terminating the entire flow -- maximizes data collection even with partial failures
- Cookie/popup dismissal happens once before the navigation loop, not at each screen -- reduces noise and avoids re-triggering banners

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- design-audit.md is the complete navigation + capture engine, ready for Phase 5 (per-screen specialist review dispatch)
- Flow-state.json contract matches the schema from RESEARCH.md exactly -- Phase 5/6 can consume it
- Plugin manifest and router already wired in 04-01 -- the command is ready to use via `/design audit`
- Playwright MCP registration still needed before real usage (noted in STATE.md blockers)

## Self-Check: PASSED

---
*Phase: 04-flow-navigation-engine*
*Completed: 2026-03-30*
