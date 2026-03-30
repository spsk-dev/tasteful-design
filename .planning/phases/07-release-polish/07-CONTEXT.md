# Phase 7: Release Polish - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Final release phase: record demo GIF, update README with /design-audit documentation and flow examples, update ARCHITECTURE.md with flow audit component diagram, update CHANGELOG with v1.1.0 notes, ensure all repo references use spsk-dev org, bump VERSION to 1.1.0, tag v1.1.0.

</domain>

<decisions>
## Implementation Decisions

### Demo GIF
- **D-109:** Record using VHS tape file (assets/demo.tape already exists from Phase 2)
- **D-110:** Show a real /design-review run with branded output (not /design-audit — the review is more visually impressive in 30 seconds)
- **D-111:** If VHS not installed, create placeholder instructions in README instead of blocking release

### Documentation Updates
- **D-112:** README gets new sections: /design-audit usage with flow examples, report screenshots, updated command table
- **D-113:** ARCHITECTURE.md gets flow audit component diagram (navigation engine → per-screen review → consistency analysis → report generator)
- **D-114:** CHANGELOG.md gets v1.1.0 release notes covering all 4 new phases

### Repo References
- **D-115:** Grep all files for stale references (felipemachado/spsk, spsk-dev/spsk) and replace with spsk-dev/tasteful-design
- **D-116:** Verify install command uses `tasteful-design@spsk-dev/tasteful-design`

### Release
- **D-117:** VERSION bumped from 1.0.0 to 1.1.0
- **D-118:** Git tag v1.1.0 created after all checks pass
- **D-119:** Push to GitHub after tagging

### Claude's Discretion
- VHS tape timing and content for demo GIF
- README structure for flow audit section
- ARCHITECTURE.md diagram format (ASCII vs description)
- CHANGELOG grouping and formatting

</decisions>

<canonical_refs>
## Canonical References

- `README.md` — Update with flow audit docs
- `ARCHITECTURE.md` — Add flow audit diagram
- `CHANGELOG.md` — v1.1.0 release notes
- `VERSION` — Bump to 1.1.0
- `assets/demo.tape` — VHS tape for demo GIF
- `shared/output.md` — Verify footer references
- `install.sh` — Verify repo references

</canonical_refs>

<code_context>
## Existing Code Insights

- assets/demo.tape already exists from Phase 2
- README already has design-review docs, needs flow audit section added
- ARCHITECTURE.md has design-review architecture, needs flow audit extension
- CHANGELOG.md has v1.0.0 entry, needs v1.1.0 added above it

</code_context>

<deferred>
## Deferred Ideas

- Anthropic harness design article evaluation (post-release task, noted by user)
- Benchmark against other agent tools (post-release task, noted by user)
- Agent question-surfacing capability (future skill improvement)

</deferred>

---

*Phase: 07-release-polish*
*Context gathered: 2026-03-30*
