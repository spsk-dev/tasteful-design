---
phase: 08-prompt-extraction-restructuring
plan: 02
subsystem: prompts
tags: [at-includes, wiring, structural-validation, prompt-extraction, eval-harness]

# Dependency graph
requires:
  - phase: 08-01
    provides: 9 specialist prompt files in skills/design-review/prompts/
provides:
  - design-review.md with @ includes replacing inline prompts (6 Claude + 2 Gemini read-and-construct)
  - boss synthesis via @ include instead of inline logic
  - 51 new structural validation checks in validate-structure.sh
  - 107/107 total eval checks passing
affects: [09-evals, 10-json-output, 13-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Claude specialist @ include: @${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/{name}.md"
    - "Gemini read-and-construct: orchestrator reads prompt file then injects into gemini -y -p command"
    - "Phase 8 eval section: prompt file existence, XML tag presence, rubric anchors, directive absence, wiring checks"

key-files:
  created: []
  modified:
    - commands/design-review.md
    - evals/validate-structure.sh

key-decisions:
  - "Gemini specialists use read-and-construct pattern (orchestrator reads prompt file, constructs CLI command) because @ includes are Claude Code-only"
  - "Boss synthesis replaced entirely with @ include -- no inline remnants to prevent double-application (Pitfall 4)"
  - "Rubric spot-checks validate 3 files (font, color, intent) for 1 (Poor) and 4 (Excellent) presence as proxy for all"

patterns-established:
  - "@ include wiring: specialist header + @ include + read instructions (screenshots/source files)"
  - "Gemini read-and-construct: Read prompt file, construct CLI command, include PAGE_BRIEF context"
  - "Eval Phase 8 structure: existence -> XML tags -> boss tags -> rubric anchors -> directive absence -> wiring"

requirements-completed: [PRMT-01, PRMT-02, PRMT-03, PRMT-06, PRMT-07]

# Metrics
duration: 4min
completed: 2026-03-30
---

# Phase 08 Plan 02: Prompt Wiring + Structural Validation Summary

**design-review.md wired to load all specialist prompts via @ includes (247 inline lines replaced), with 51 new eval assertions permanently catching structural regressions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T03:46:52Z
- **Completed:** 2026-03-30T03:51:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced 8 inline specialist prompt blocks (247 lines) in design-review.md with compact @ include references
- Wired boss synthesis (Phase 3) to single @ include of prompts/boss.md, removing all inline scoring/verdict logic
- Added 51 structural validation checks catching prompt file existence, XML tags, rubric anchors, aggressive directives, and wiring
- Full eval suite passes at 107/107 with zero regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace inline specialist prompts with @ includes** - `651c81e` (feat)
2. **Task 2: Extend validate-structure.sh with prompt structural checks** - `dc93e57` (feat)

## Files Modified
- `commands/design-review.md` - Replaced inline prompts with @ includes (738 -> 491 lines); cleaned "NEVER skip" and "Must find at least 2 issues" directives
- `evals/validate-structure.sh` - Added Phase 8 section with 51 new checks (56 -> 91 total checks before counting was 107 total)

## Decisions Made
- Gemini specialists (color, layout) cannot use @ includes (Claude Code-only feature), so the orchestrator instruction says "Read the prompt file and construct the Gemini CLI command" -- a read-and-construct pattern
- Layout specialist section now includes a note about the pre-copied `.layout-reference.md` (matching the color specialist's existing note), fixing an asymmetry in the original file
- Boss Phase 3 section reduced to 3 lines: header + scoring.json reference + @ include. All synthesis logic is in boss.md as single source of truth
- Rubric spot-checks use font.md, color.md, and intent.md as representative files (covers Claude and Gemini specialist types)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all wiring is complete and validated.

## Next Phase Readiness
- Phase 08 complete: all specialist prompts extracted (Plan 01) and wired (Plan 02)
- 107/107 structural checks passing as regression safety net
- Ready for Phase 09 (eval enhancement) which will test actual review output against these prompts
- Blocker to verify: `claude --print` can invoke plugin commands non-interactively (needed for Phase 09 Layer 2 evals)

## Self-Check: PASSED

All files verified on disk. Both task commits (651c81e, dc93e57) verified in git log.

---
*Phase: 08-prompt-extraction-restructuring*
*Completed: 2026-03-30*
