---
phase: 13-few-shot-examples-polish
plan: 01
subsystem: prompts
tags: [few-shot, chain-of-thought, prompt-engineering, scoring-calibration]

requires:
  - phase: 08-prompt-extraction-restructuring
    provides: XML-structured prompt files with role/instructions/rubric/output_format
  - phase: 10-structured-json-output
    provides: specialist_output and boss_output JSON schemas in output_format sections
provides:
  - "<examples> sections with 2-3 curated few-shot examples per specialist prompt (17 total examples)"
  - "Enhanced chain-of-thought reasoning guidance for 3 complex specialists (Intent, Layout, Boss)"
  - "Score calibration anchors at multiple levels per specialist (score 1-4 coverage)"
affects: [design-review-quality, scoring-calibration, improve-loop-accuracy]

tech-stack:
  added: []
  patterns: ["few-shot examples in <examples> XML tags after </output_format>", "structured CoT reasoning steps in <thinking> instruction", "score-diverse example sets (low + high scores per specialist)"]

key-files:
  created: []
  modified:
    - skills/design-review/prompts/font.md
    - skills/design-review/prompts/color.md
    - skills/design-review/prompts/layout.md
    - skills/design-review/prompts/icons.md
    - skills/design-review/prompts/motion.md
    - skills/design-review/prompts/code-a11y.md
    - skills/design-review/prompts/intent.md
    - skills/design-review/prompts/boss.md

key-decisions:
  - "Simple specialists get examples-only (no CoT enhancement) -- reasoning is straightforward for single-score domains"
  - "Complex specialists get both enhanced CoT and examples -- multi-dimensional scoring benefits from explicit reasoning steps"
  - "Boss examples show abbreviated human-readable markdown (scores table + verdict + top fixes) to limit token growth while demonstrating dual-output format"
  - "All examples use 1-2 findings per example to keep token cost low while demonstrating format and calibration"

patterns-established:
  - "Few-shot example placement: <examples> section appended after </output_format> closing tag, never inside existing sections"
  - "Score-diverse examples: each specialist has examples at different score levels to anchor calibration (not all score-3)"
  - "CoT reasoning pattern: numbered sub-steps matching the specialist's evaluation dimensions"

requirements-completed: [PRMT-04, PRMT-05]

duration: 6min
completed: 2026-03-30
---

# Phase 13 Plan 01: Few-Shot Examples + Enhanced CoT Summary

**17 curated few-shot examples across all 8 specialist prompts with structured chain-of-thought reasoning for Intent, Layout, and Boss specialists**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-30T06:06:12Z
- **Completed:** 2026-03-30T06:12:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added 2-3 curated few-shot examples to all 8 specialist prompt files (17 total examples across the system)
- Enhanced chain-of-thought guidance for 3 complex specialists with explicit dimension-by-dimension reasoning steps
- Score calibration coverage: each specialist has examples at different score levels (1, 2, 3, or 4) to anchor the scoring rubric
- Zero structural regression: validate-structure.sh passes 107/107 checks

## Task Commits

Each task was committed atomically:

1. **Task 1: Add few-shot examples to 5 simple specialists** - `fd6eb84` (feat)
2. **Task 2: Add few-shot examples + enhanced CoT to 3 complex specialists** - `8148f67` (feat)

## Files Created/Modified
- `skills/design-review/prompts/font.md` - 2 examples: score 2 (Inter/no pairing) + score 4 (Instrument Serif/DM Sans editorial)
- `skills/design-review/prompts/color.md` - 2 examples: score 2 (pure black/generic blue) + score 3 (warm wellness palette)
- `skills/design-review/prompts/icons.md` - 2 examples: score 1 (mixed libraries/emoji) + score 3 (consistent Lucide)
- `skills/design-review/prompts/motion.md` - 2 examples: score 2 (bounce/linear easing) + score 3 (proper easing/durations)
- `skills/design-review/prompts/code-a11y.md` - 2 examples: score 2 (missing focus/color-only) + score 4 (full semantic/a11y)
- `skills/design-review/prompts/layout.md` - 2 examples: score 2 (inconsistent gaps/monotony) + score 4 (8px grid/fluid responsive) + enhanced CoT
- `skills/design-review/prompts/intent.md` - 3 examples: {2,2,2,2} (AI defaults) + {3,3,3,3} (good dashboard) + {4,2,3,3} (strong intent/weak originality) + enhanced CoT
- `skills/design-review/prompts/boss.md` - 2 examples: BLOCK 2.56/4.0 (template landing) + SHIP 3.19/4.0 (crafted marketing) + enhanced CoT

## Decisions Made
- Simple specialists (Font, Color, Icons, Motion, Code/A11y) received examples only -- their single-score evaluation does not benefit from additional CoT structure beyond the existing "analyze in thinking tags" instruction
- Boss examples show abbreviated markdown output (scores table + verdict + top fixes) rather than full review to keep token cost manageable while demonstrating the dual-output format
- Intent specialist received 3 examples (vs 2 for others) because its 4-dimension scoring needs more calibration coverage -- the {4,2,3,3} pattern demonstrates that sub-scores can diverge significantly
- All examples use 1-2 findings per example (not 5) to demonstrate format without inflating prompt token cost

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Known Stubs

None -- all examples contain complete, realistic JSON output matching their specialist schemas.

## Next Phase Readiness
- All 8 specialist prompts now have few-shot examples for output format guidance and scoring calibration
- Complex specialists have enhanced reasoning instructions that should improve multi-dimensional score consistency
- Ready for Plan 02 (generation.md reference + token measurement) to complete Phase 13

## Self-Check: PASSED

- All 8 modified prompt files: FOUND
- Commit fd6eb84 (Task 1): FOUND
- Commit 8148f67 (Task 2): FOUND
- 13-01-SUMMARY.md: FOUND

---
*Phase: 13-few-shot-examples-polish*
*Completed: 2026-03-30*
