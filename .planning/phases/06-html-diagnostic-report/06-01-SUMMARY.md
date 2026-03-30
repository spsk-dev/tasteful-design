---
phase: 06-html-diagnostic-report
plan: 01
subsystem: reporting
tags: [bash, html, css, jq, base64, sips, imagemagick]

requires:
  - phase: 05-per-screen-review-animation
    provides: flow-state.json with screens, scores, consistency, animation data
provides:
  - generate-report.sh consuming flow-state.json and outputting self-contained HTML
  - Test fixture with 3-screen mock flow-state.json and placeholder PNGs
  - Structural validation checks for report artifacts
affects: [06-02-PLAN, design-audit-integration]

tech-stack:
  added: []
  patterns: [bash-heredoc-html-generation, base64-screenshot-embedding, cross-platform-image-conversion]

key-files:
  created:
    - scripts/generate-report.sh
    - evals/fixtures/report-test/flow-state.json
    - evals/fixtures/report-test/screen-1-login.png
    - evals/fixtures/report-test/screen-2-dashboard.png
    - evals/fixtures/report-test/screen-3-settings.png
  modified:
    - evals/validate-structure.sh

key-decisions:
  - "Score bars as CSS percentage-width divs rather than SVG or Unicode blocks"
  - "sips primary with ImageMagick fallback for cross-platform JPEG conversion"
  - "4MB image budget with auto-recompress at 60% quality if exceeded"
  - "24 collapsible details elements matching specialist counts per screen"

patterns-established:
  - "HTML generation via bash heredoc + function composition for sections"
  - "Cross-platform base64: macOS no-flag vs Linux -w0"
  - "Test fixtures with minimal 1x1 PNGs for pipeline validation"

requirements-completed: [REPT-01, REPT-02, REPT-03, REPT-04, REPT-05, REPT-06, REPT-07]

duration: 15min
completed: 2026-03-30
---

# Phase 6 Plan 1: HTML Diagnostic Report Generator Summary

**Bash script generating self-contained HTML reports from flow-state.json with dark theme, flow map, per-screen specialist bars, collapsible details, and print-to-PDF support**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-30T01:16:21Z
- **Completed:** 2026-03-30T01:31:28Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created generate-report.sh (620 lines) that reads flow-state.json and outputs a self-contained HTML report with zero npm dependencies
- Dark theme HTML with flow map (scrollable thumbnail strip), per-screen sections with CSS score bars, expandable specialist details, consistency findings, and animation summary
- End-to-end validated with 3-screen fixture producing a 225KB report (well under 5MB limit)
- All 56 structural validation checks pass including 5 new report-specific checks

## Task Commits

Each task was committed atomically:

1. **Task 1: Create generate-report.sh with HTML template, screenshot embedding, and flow map** - `1cdfc86` (feat)
2. **Task 2: Verify report generation with a mock flow-state.json fixture** - `650c301` (test)

## Files Created/Modified

- `scripts/generate-report.sh` - HTML report generator: validates input, converts PNGs to base64 JPEGs, generates dark-themed HTML with flow map, summary, per-screen sections, consistency, animation, and print styles
- `evals/fixtures/report-test/flow-state.json` - 3-screen mock with realistic specialist scores, findings, consistency (typography mismatch, color drift), and animation data (PARTIAL PRM compliance)
- `evals/fixtures/report-test/screen-{1,2,3}-*.png` - Minimal 1x1 PNGs for base64 encoding pipeline validation
- `evals/validate-structure.sh` - Added 5 checks: script exists, is executable, fixture exists, fixture has 3 screens, flow-scoring.json is valid

## Decisions Made

- CSS percentage-width bars for scores rather than SVG or Unicode: renders cleanly in all browsers and print, no JS needed
- sips as primary image converter on macOS with ImageMagick convert as Linux fallback: sips is pre-installed on macOS, avoiding external dependencies
- 4MB cumulative image budget: if exceeded after first pass at 80% quality, re-encode all screenshots at 60%
- Specialist details as collapsible `<details>` with expand/collapse all toggle button: keeps report scannable while allowing deep inspection

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all sections render real data from flow-state.json. The specialist detail content shows a generic message ("Specialist assessment for {name}") when per-specialist breakdown isn't available in the flow-state data structure, but this is intentional: the full specialist analysis text is not stored in flow-state.json (findings are aggregated). Plan 06-02 may enrich this if the design-audit command writes per-specialist breakdowns.

## Next Phase Readiness

- generate-report.sh is ready for integration into design-audit.md (Plan 06-02 will wire the call)
- Test fixture provides a repeatable validation path for future report changes
- All brand elements (signature, footer, dark theme, score bars) match shared/output.md conventions

## Self-Check: PASSED

- scripts/generate-report.sh: FOUND (executable)
- evals/fixtures/report-test/flow-state.json: FOUND
- evals/fixtures/report-test/screen-{1,2,3}-*.png: FOUND (3 files)
- Commit 1cdfc86: FOUND
- Commit 650c301: FOUND

---
*Phase: 06-html-diagnostic-report*
*Completed: 2026-03-30*
