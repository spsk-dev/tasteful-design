# Phase 5: Per-Screen Review + Animation - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the existing 8-specialist review system into the flow audit pipeline. Each captured screen from Phase 4's flow-state.json gets reviewed. Smart weighting applies full review to first/last screens, quick mode to middle screens. Add cross-screen consistency analysis (flag visual drift between screens). Detect CSS animations/transitions and check prefers-reduced-motion compliance.

</domain>

<decisions>
## Implementation Decisions

### Per-Screen Review Integration
- **D-77:** The design-audit command orchestrates reviews by reading flow-state.json and invoking the existing specialist system for each screen's screenshot
- **D-78:** Smart weighting: first and last screens get full 8-specialist review, middle screens get quick mode (4 specialists: Font, Color, Layout, Intent)
- **D-79:** Per-screen scores stored back into flow-state.json with scores, issues, and specialist findings per screen
- **D-80:** Overall flow score = weighted average of per-screen scores (first/last screens weighted 1.5x)

### Cross-Screen Consistency
- **D-81:** New analysis pass after all per-screen reviews complete — compares visual properties across screens
- **D-82:** Flags: button style drift, color inconsistencies, spacing/padding changes, typography mismatches, component variant drift
- **D-83:** Consistency findings added to flow-state.json as a top-level `consistency` section
- **D-84:** Runs as a post-processing pass using the screenshots + specialist findings, not as a 9th specialist

### Animation Detection
- **D-85:** Use `browser_evaluate` to inject JS that queries `document.getAnimations()` and `getComputedStyle()` for transition properties
- **D-86:** Check `prefers-reduced-motion` compliance: any animation must respect the media query
- **D-87:** Animation findings added to each screen's specialist output in flow-state.json
- **D-88:** Animation detection runs between screen transitions (capture CSS state before and after CTA click)

### Reference Updates
- **D-89:** Add cross-screen consistency heuristics to `skills/design-review/references/flow.md`
- **D-90:** Add animation detection patterns to flow reference

### Claude's Discretion
- Exact consistency comparison thresholds (how much color drift is "drift"?)
- Animation quality scoring heuristics
- How to weight consistency findings in overall flow score
- Terminal output format for per-screen progress during review

</decisions>

<canonical_refs>
## Canonical References

### Phase 4 Output (consume)
- `commands/design-audit.md` — The command that produces flow-state.json
- `config/flow-scoring.json` — Scoring thresholds and smart weighting config

### Existing Specialists (reuse)
- `commands/design-review.md` — 8-specialist review system (reuse as-is for per-screen review)
- `config/scoring.json` — Design scoring weights
- `shared/output.md` — Branded output for progress display

### Research
- `.planning/research/FEATURES.md` — Cross-screen consistency is the killer differentiator
- `.planning/research/PITFALLS.md` — Token budget management, animation detection limits

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 8-specialist system in `commands/design-review.md` — invoked per-screen
- `--quick` mode already exists for 4-specialist subset
- `shared/output.md` for branded progress output
- `config/scoring.json` for dimension weights

### Integration Points
- `commands/design-audit.md` — extend with review orchestration after navigation completes
- `config/flow-scoring.json` — add smart weighting and consistency thresholds
- `skills/design-review/references/flow.md` — add consistency and animation patterns

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-per-screen-review-animation*
*Context gathered: 2026-03-30*
