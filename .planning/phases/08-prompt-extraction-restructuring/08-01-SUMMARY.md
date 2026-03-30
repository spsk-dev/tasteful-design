---
phase: 08-prompt-extraction-restructuring
plan: 01
subsystem: prompts
tags: [xml-tags, scoring-rubric, specialist-prompts, prompt-engineering, claude-best-practices]

# Dependency graph
requires: []
provides:
  - 9 specialist prompt files in skills/design-review/prompts/
  - XML-structured prompts with role, instructions, scoring_rubric, output_format sections
  - 4-level scoring rubrics with domain-specific anchors per specialist
  - Boss synthesizer protocol with scoring formula and verdict rules
affects: [08-02, 09-evals, 10-json-output, 13-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "XML-tagged prompt sections: <role>, <reference_knowledge>, <instructions>, <scoring_rubric>, <output_format>"
    - "4-level rubric pattern: 1 (Poor), 2 (Below Average), 3 (Good), 4 (Excellent) with concrete domain anchors"
    - "Gemini workspace reference pattern: .color-reference.md / .layout-reference.md instead of ${CLAUDE_PLUGIN_ROOT}"
    - "Boss synthesizer as orchestrator protocol, not subagent prompt"

key-files:
  created:
    - skills/design-review/prompts/font.md
    - skills/design-review/prompts/color.md
    - skills/design-review/prompts/layout.md
    - skills/design-review/prompts/icons.md
    - skills/design-review/prompts/motion.md
    - skills/design-review/prompts/intent.md
    - skills/design-review/prompts/copy.md
    - skills/design-review/prompts/code-a11y.md
    - skills/design-review/prompts/boss.md
  modified: []

key-decisions:
  - "Gemini prompts (color, layout) reference workspace copies (.color-reference.md, .layout-reference.md) not plugin paths"
  - "Copy and code-a11y prompts omit reference_knowledge tag since no reference files exist for these specialists"
  - "Boss synthesizer structured as orchestrator protocol with scoring_formula and verdict_rules XML sections instead of scoring_rubric"

patterns-established:
  - "Specialist prompt XML skeleton: role -> reference_knowledge -> instructions -> scoring_rubric -> output_format"
  - "Directive cleanup: 'FLAG SPECIFICALLY' -> 'Check for and flag:', 'Find at least N' -> process step with 2-5 range"
  - "Intent specialist three-score pattern with separate rubric anchors per dimension"

requirements-completed: [PRMT-01, PRMT-02, PRMT-03, PRMT-06, PRMT-07]

# Metrics
duration: 4min
completed: 2026-03-30
---

# Phase 08 Plan 01: Prompt Extraction + Restructuring Summary

**9 specialist prompt files extracted with XML structure, 4-level domain-specific rubrics, and cleaned directives -- ready for @ includes in Phase 08-02**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-30T03:40:32Z
- **Completed:** 2026-03-30T03:44:44Z
- **Tasks:** 2
- **Files created:** 9

## Accomplishments
- Extracted all 8 specialist prompts from inline blocks in design-review.md into individual files under skills/design-review/prompts/
- Added concrete 4-level scoring rubrics with domain-specific anchors for every specialist (replacing bare "Score 1-4")
- Created boss synthesizer protocol with scoring formula, verdict rules, and output format
- Cleaned all aggressive directives: "FLAG SPECIFICALLY" -> "Check for and flag:", "Find at least N" -> "Identify 2-5 specific issues"
- Intent specialist prompt defines three separate scoring dimensions (Intent Match, Originality, UX Flow) with independent rubric anchors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create 8 specialist prompt files** - `ad77a00` (feat)
2. **Task 2: Create boss synthesizer prompt** - `693f378` (feat)

## Files Created
- `skills/design-review/prompts/font.md` - Typography specialist with reference to typography.md
- `skills/design-review/prompts/color.md` - Color specialist (Gemini-compatible, references .color-reference.md)
- `skills/design-review/prompts/layout.md` - Layout specialist (Gemini-compatible, references .layout-reference.md)
- `skills/design-review/prompts/icons.md` - Icons specialist with reference to icons.md
- `skills/design-review/prompts/motion.md` - Motion specialist (code-only analysis, references motion.md)
- `skills/design-review/prompts/intent.md` - Intent/Originality/UX specialist with 3 sub-scores and independent rubrics
- `skills/design-review/prompts/copy.md` - Copy specialist (no reference file, omits reference_knowledge)
- `skills/design-review/prompts/code-a11y.md` - Code/A11y specialist (no reference file, omits reference_knowledge)
- `skills/design-review/prompts/boss.md` - Boss synthesizer protocol with scoring formula (/ 17 and / 13) and verdict rules

## Decisions Made
- Gemini specialists (color, layout) reference workspace copies (.color-reference.md, .layout-reference.md) because Gemini cannot access ${CLAUDE_PLUGIN_ROOT} paths
- Copy and code-a11y prompts omit the reference_knowledge tag entirely since no reference files exist for these domains
- Boss synthesizer uses scoring_formula and verdict_rules XML tags instead of scoring_rubric, reflecting its role as orchestrator protocol not specialist evaluation
- Motion specialist role explicitly states code-only analysis capability (cannot see animations in screenshots)
- All "IMPORTANT:" emphasis in boss prompt converted to normal-case clarifications within their respective sections

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all 9 prompt files are complete with full content.

## Next Phase Readiness
- All 9 prompt files ready for @ includes from commands/design-review.md (Plan 08-02)
- The inline prompts in design-review.md still exist -- Plan 08-02 will replace them with @ references to these extracted files
- Structural validation checks for prompt files will be added in Plan 08-02 or Phase 09

## Self-Check: PASSED

All 9 prompt files verified on disk. Both task commits (ad77a00, 693f378) verified in git log.

---
*Phase: 08-prompt-extraction-restructuring*
*Completed: 2026-03-30*
