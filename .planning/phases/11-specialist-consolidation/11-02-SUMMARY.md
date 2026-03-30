---
phase: 11-specialist-consolidation
plan: 02
subsystem: evals, docs
tags: [scoring, weight-assertion, specialist-count, eval-parser]

# Dependency graph
requires:
  - phase: 11-01
    provides: 7-specialist core system (scoring.json, boss.md, intent.md, design-review.md)
provides:
  - Weight-sum structural assertion in validate-structure.sh
  - All ecosystem files consistent with 7-specialist architecture
  - Eval parser updated for copy_quality dimension mapping
  - Assertions.json version bumped to 1.2.0
affects: [12-playwright-interaction, 13-polish-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Weight-sum assertion pattern: jq sum of weights array equals total_weight field"

key-files:
  created: []
  modified:
    - evals/validate-structure.sh
    - evals/parse-review-output.sh
    - evals/assertions.json
    - evals/fixtures/report-test/flow-state.json
    - commands/design-audit.md
    - commands/design-improve.md
    - commands/design.md
    - shared/output.md
    - README.md
    - ARCHITECTURE.md
    - CLAUDE.md
    - .claude-plugin/plugin.json
    - skills/design-review/SKILL.md
    - evals/INSTALL-TEST.md
    - docs/case-studies/design-review-impact.md

key-decisions:
  - "CHANGELOG.md v1.0.0 entry preserved as historical record (documents original 8-specialist architecture)"
  - "assertions.json score ranges kept unchanged -- /16 vs /17 shift absorbed by existing wide ranges"

patterns-established:
  - "Weight-sum structural assertion: validate-structure.sh enforces sum of scoring.json weights equals total_weight"

requirements-completed: [SPEC-02, SPEC-03]

# Metrics
duration: 7min
completed: 2026-03-30
---

# Phase 11 Plan 02: Ecosystem Update Summary

**Weight-sum assertion added and all 15 ecosystem files updated from 8 to 7 specialists with /16 scoring formula**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-30T05:23:48Z
- **Completed:** 2026-03-30T05:30:48Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments
- Added weight-sum structural assertion in validate-structure.sh that prevents future drift between individual weights and total_weight (SPEC-03)
- Updated all 15 ecosystem files to consistently reference 7 specialists and /16 scoring formula
- Updated eval parser to map copy_quality dimension correctly for boss output parsing
- Repo-wide sweep confirmed zero "8 specialist" references remain in active files

## Task Commits

Each task was committed atomically:

1. **Task 1: Add weight-sum assertion and update evals for 7 specialists** - `24da78a` (feat)
2. **Task 2: Update all docs and commands for 7-specialist count** - `ab9e501` (docs)
3. **Task 2 (extended): Update remaining 8-specialist references repo-wide** - `71e8620` (fix)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `evals/validate-structure.sh` - Added Phase 11 weight-sum assertion, removed copy.md from prompt loops
- `evals/parse-review-output.sh` - Replaced copy->Copy mapping with copy_quality->Copy Quality
- `evals/assertions.json` - Bumped version to 1.2.0
- `evals/fixtures/report-test/flow-state.json` - Renamed copy key to copy_quality in score objects
- `commands/design-audit.md` - Updated specialist count, specialist list, JSON examples, formula divisor
- `commands/design-improve.md` - Updated specialist count, removed Copy from dispatch list
- `commands/design.md` - Updated router table and pipeline descriptions
- `shared/output.md` - Updated specialist_count default from 8 to 7
- `README.md` - Updated specialist count, formula, specialist list, alt text
- `ARCHITECTURE.md` - Updated specialist count, diagram, table, formula, weight rationale
- `CLAUDE.md` - Updated project description, branding, quick mode text
- `.claude-plugin/plugin.json` - Updated plugin description metadata
- `skills/design-review/SKILL.md` - Updated skill description
- `evals/INSTALL-TEST.md` - Updated expected output description
- `docs/case-studies/design-review-impact.md` - Updated setup mode description

## Decisions Made
- CHANGELOG.md v1.0.0 entry preserved as historical record -- it accurately describes the original 8-specialist architecture at that version
- assertions.json score ranges kept unchanged -- the /16 vs /17 shift (approx +0.15) is absorbed by existing wide ranges with 0.3+ buffer

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Consistency] Updated 5 additional files not listed in plan**
- **Found during:** Task 2 (repo-wide verification sweep)
- **Issue:** Plan listed 6 files for Task 2 but grep found "8 specialist" in 5 additional active files: commands/design.md, .claude-plugin/plugin.json, skills/design-review/SKILL.md, evals/INSTALL-TEST.md, docs/case-studies/design-review-impact.md
- **Fix:** Updated all 5 files to reference 7 specialists
- **Files modified:** commands/design.md, .claude-plugin/plugin.json, skills/design-review/SKILL.md, evals/INSTALL-TEST.md, docs/case-studies/design-review-impact.md
- **Verification:** Repo-wide grep returns zero results for "8 specialist" in active files
- **Committed in:** 71e8620

---

**Total deviations:** 1 auto-fixed (1 consistency)
**Impact on plan:** Essential for complete consistency. The plan's acceptance criteria required "repository-wide grep for '8 specialist' returns zero results in active files" -- these 5 files would have failed that check.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all changes are complete string replacements with no placeholder values.

## Next Phase Readiness
- Phase 11 (Specialist Consolidation) is fully complete
- All scoring, eval, docs, and command files are consistent with 7-specialist, /16 formula architecture
- Weight-sum assertion will catch any future weight drift automatically
- Ready for Phase 12 (Playwright Interaction) or Phase 13 (Polish & Validation)

## Self-Check: PASSED

- All 15 modified files exist on disk
- All 3 task commits verified in git log (24da78a, ab9e501, 71e8620)
- validate-structure.sh: 103/103 checks pass
- Repo-wide "8 specialist" grep: 0 results in active files

---
*Phase: 11-specialist-consolidation*
*Completed: 2026-03-30*
