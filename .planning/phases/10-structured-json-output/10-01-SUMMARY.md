---
phase: 10-structured-json-output
plan: 01
subsystem: prompts
tags: [json, structured-output, xml-tags, think-then-structure, specialist-prompts]

# Dependency graph
requires:
  - phase: 08-prompt-overhaul
    provides: "Extracted specialist prompts with <output_format> sections ready for schema insertion"
provides:
  - "All 9 specialist prompts emit structured JSON in <specialist_output> or <boss_output> XML tags"
  - "Intent specialist uses multi-score schema with scores object"
  - "Boss synthesizer dual-output: human-readable markdown + trailing JSON block"
  - "Think-then-structure pattern in all prompts (reasoning before structured output)"
affects: [10-02-parse-and-consume, design-improve, design-audit, generate-report]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Think-then-structure: <thinking> for free-form reasoning, <specialist_output> for JSON"
    - "Dual-output for boss: markdown for terminal, <boss_output> JSON for programmatic consumption"
    - "Multi-score schema variant for intent specialist (scores object vs single score)"

key-files:
  created: []
  modified:
    - skills/design-review/prompts/font.md
    - skills/design-review/prompts/color.md
    - skills/design-review/prompts/layout.md
    - skills/design-review/prompts/icons.md
    - skills/design-review/prompts/motion.md
    - skills/design-review/prompts/copy.md
    - skills/design-review/prompts/code-a11y.md
    - skills/design-review/prompts/intent.md
    - skills/design-review/prompts/boss.md

key-decisions:
  - "Minimal JSON schema -- no nested type constraints, no enum validation. Schema is documentation for the LLM, not API validation."
  - "Boss retains full human-readable markdown review before JSON block -- dual output preserves terminal UX."
  - "Intent specialist uses scores object with 3 keys instead of single score field."

patterns-established:
  - "specialist_output tag: all single-score and multi-score specialists wrap JSON in <specialist_output> tags"
  - "boss_output tag: boss synthesizer wraps JSON in <boss_output> tags after markdown"
  - "Domain-specific thinking instructions: each specialist gets a unique thinking prompt tuned to its domain"

requirements-completed: [JSON-01, JSON-02]

# Metrics
duration: 2min
completed: 2026-03-30
---

# Phase 10 Plan 01: Structured JSON Output Summary

**All 9 specialist prompts migrated to think-then-structure JSON output with XML wrapper tags for deterministic parsing**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-30T04:54:06Z
- **Completed:** 2026-03-30T04:56:33Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- All 7 single-score specialists (typography, color, layout, icons, motion, copy, code_a11y) now emit JSON in `<specialist_output>` tags
- Intent specialist emits multi-score JSON with `scores.intent_match`, `scores.originality`, `scores.ux_flow`
- Boss synthesizer preserves human-readable markdown review AND adds `<boss_output>` JSON block with scores, verdict, top_fixes, consensus_findings
- Think-then-structure pattern in all 9 prompts preserves reasoning quality

## Task Commits

Each task was committed atomically:

1. **Task 1: Update all 7 single-score specialist prompts to JSON output format** - `1c59e65` (feat)
2. **Task 2: Update intent specialist (multi-score) and boss synthesizer prompts to JSON output format** - `5350f9f` (feat)

## Files Modified
- `skills/design-review/prompts/font.md` - Typography specialist with JSON output format
- `skills/design-review/prompts/color.md` - Color specialist with JSON output format
- `skills/design-review/prompts/layout.md` - Layout specialist with JSON output format
- `skills/design-review/prompts/icons.md` - Icon specialist with JSON output format
- `skills/design-review/prompts/motion.md` - Motion specialist with JSON output format
- `skills/design-review/prompts/copy.md` - Copy specialist with JSON output format
- `skills/design-review/prompts/code-a11y.md` - Code/A11y specialist with JSON output format
- `skills/design-review/prompts/intent.md` - Intent specialist with multi-score JSON output format
- `skills/design-review/prompts/boss.md` - Boss synthesizer with dual markdown + JSON output format

## Decisions Made
- Minimal JSON schema -- no nested type constraints, no enum validation. The schema is documentation for the LLM, not API validation. Keeps prompt token growth under 300 tokens per specialist.
- Boss retains full human-readable markdown review before JSON block. Users see the formatted review in terminal; programmatic consumers extract the trailing JSON.
- Intent specialist uses `scores` object with 3 named keys instead of single `score` field, with `dimension` field in findings for per-dimension tracking.

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- All 9 prompts ready for Plan 02 (parse-review-output.sh dual-format parser, design-improve top_fixes consumption)
- Structural validation passes (107/107 checks)
- Cached eval outputs will need regeneration after Plan 02 parser migration (dry-run caches still contain pre-JSON output)

## Self-Check: PASSED

All 9 modified files exist. Both task commits verified (1c59e65, 5350f9f). SUMMARY.md created.

---
*Phase: 10-structured-json-output*
*Completed: 2026-03-30*
