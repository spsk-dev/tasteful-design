---
phase: 12-playwright-interaction
plan: 01
subsystem: ui
tags: [playwright, mcp, interaction, hover, focus, scroll, design-review]

# Dependency graph
requires:
  - phase: 08-prompt-overhaul
    provides: Extracted specialist prompts in prompts/ directory
  - phase: 11-specialist-merge
    provides: 7-specialist architecture with Intent/Copy merge
provides:
  - "--interact flag for opt-in Playwright MCP interaction capture"
  - "Phase 0.5i baseline-interact-reset interaction protocol"
  - "Interaction screenshot dispatch to Motion, Code/A11y, Color, Layout specialists"
  - "Structural validation checks for interaction protocol"
affects: [12-02-PLAN, design-review, design-audit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "baseline-interact-reset: clean screenshot -> interact -> reload -> review on clean DOM"
    - "budget-capped interactions: max 8 per review, prioritized by design relevance"
    - "selective specialist context: interaction screenshots only to affected specialists (Motion, Code/A11y, Color, Layout)"

key-files:
  created: []
  modified:
    - commands/design-review.md
    - commands/design.md
    - evals/validate-structure.sh

key-decisions:
  - "Interaction screenshots go to 4 of 7 specialists (Motion, Code/A11y, Color, Layout) -- Font, Icon, Intent excluded as not affected by hover/focus/scroll"
  - "Phase 0.5i placed between Phase 0 (screenshots) and Phase 0.5 (design context) to capture interactions early without polluting baseline"
  - "browser_close called after interactions to release MCP session before standard review phases"

patterns-established:
  - "baseline-interact-reset: capture clean state, interact, reload page, review on clean DOM"
  - "8-interaction budget cap with prioritized element selection (CTAs > nav > forms > cards > scroll)"

requirements-completed: [INTR-01, INTR-02, INTR-03]

# Metrics
duration: 2min
completed: 2026-03-30
---

# Phase 12 Plan 01: Playwright Interaction Protocol Summary

**Opt-in --interact flag with 5-step baseline-interact-reset protocol (navigate, snapshot, hover/focus/scroll up to 8 elements, reload, close) passing interaction screenshots to Motion, Code/A11y, Color, and Layout specialists**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-30T05:46:10Z
- **Completed:** 2026-03-30T05:48:30Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `--interact` flag to design-review with Tier 3 graceful degradation (warns and skips if no Playwright)
- Implemented Phase 0.5i interaction protocol with 5 sub-steps: MCP session launch, element discovery via accessibility tree, interaction execution (hover/focus/scroll), page reset via reload + DOM stability check, context storage
- Updated Phase 2 specialist dispatch to conditionally pass interaction screenshots to relevant specialists only
- Added `--interact` to design.md router passthrough and help menu
- Added 4 Phase 12 structural validation checks (107/107 total pass)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add --interact flag parsing and Phase 0.5i interaction protocol** - `022cd20` (feat)
2. **Task 2: Update router passthrough and add structural validation checks** - `6ecc90e` (feat)

## Files Created/Modified
- `commands/design-review.md` - Added --interact flag parsing, Phase 0.5i interaction protocol (5 sub-steps), interaction context dispatch to specialists
- `commands/design.md` - Added --interact to flag passthrough list, help menu, and review route description
- `evals/validate-structure.sh` - Added 4 Phase 12 structural checks for interaction protocol presence

## Decisions Made
- Interaction screenshots dispatched selectively: Motion, Code/A11y, Color, Layout receive them; Font, Icon, Intent do not (their domains are unaffected by hover/focus/scroll states)
- Phase 0.5i positioned between Phase 0 (screenshots) and Phase 0.5 (design context) -- captures interaction state early without affecting baseline
- MCP session closed after interactions via browser_close before standard review phases begin
- DOM stability check uses same MutationObserver pattern as design-audit.md (800ms quiet period, 2s timeout)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 0.5i protocol is wired end-to-end: flag parsing -> interaction capture -> specialist dispatch
- Ready for Plan 02 (end-to-end validation on start.fusefinance.com)
- The `--interact` flag requires Playwright MCP registration (`claude mcp add playwright -- npx @playwright/mcp@latest`)

## Self-Check: PASSED

All files exist, all commits verified.

---
*Phase: 12-playwright-interaction*
*Completed: 2026-03-30*
