# Phase 13: Few-Shot Examples + Polish - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add 2-3 curated few-shot examples per specialist in `<examples>` tags showing ideal output format and scoring calibration at different score levels. Add `<thinking>` + `<answer>` chain-of-thought separation for complex specialists (Intent, Layout, Boss). Create `references/generation.md` from Anthropic's DISTILLED_AESTHETICS_PROMPT adapted for `/design-improve` build phase. Cap token increase at 30% vs Phase 8 baseline.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — additive polish phase. Key guidance from research:

- Few-shot examples curated from ideal review outputs — not randomly generated
- Each example should show a different score level (e.g., score 2 example, score 3 example, score 4 example)
- Examples placed in `<examples>` XML tags at the end of each prompt file
- Chain-of-thought: `<thinking>` section shows reasoning process, `<answer>` section contains the structured JSON output
- Only complex specialists get CoT: Intent (4 dimensions), Layout (spatial reasoning), Boss (cross-specialist synthesis)
- Simple specialists (Font, Color, Icons, Motion, Code/A11y) get examples only (no CoT — reasoning is straightforward)
- `references/generation.md`: Anthropic's aesthetics prompt adapted for build context, NOT evaluation
- generation.md referenced by `/design-improve` during page generation, NOT by `/design-review`
- Token budget: measure before adding examples, cap total increase at 30%
- Anthropic aesthetics covers: typography (quality font selection, hierarchy), color (cohesive palettes, contrast), motion (purposeful transitions, not gratuitous), backgrounds (gradient quality, texture)
- Resolve Playfair Display conflict: Anthropic recommends it for editorial; our anti-slop flags it. Resolution: acceptable in genuine editorial contexts, flagged for SaaS/landing

</decisions>

<canonical_refs>
## Canonical References

- `skills/design-review/prompts/*.md` — All 8 prompt files (7 specialists + boss) to add examples
- `skills/design-review/references/` — Reference files directory for generation.md
- `commands/design-improve.md` — Reference generation.md during build phase
- `config/anti-slop.json` — Resolve Playfair Display context rule
- `.planning/research/STACK.md` — Anthropic DISTILLED_AESTHETICS_PROMPT text
- `.planning/research/FEATURES.md` — Few-shot example patterns and approaches

</canonical_refs>

<code_context>
## Existing Code Insights

### Current State
- 8 prompt files (7 specialists + boss) with XML structure, JSON output, and scoring rubrics (from Phase 8+10)
- Intent prompt already has 4 sub-scores with detailed rubrics
- Boss prompt has full scoring formula and verdict rules
- No examples currently in any prompt file
- No `<thinking>` separation currently in any prompt

### Integration Points
- Examples added to end of each prompt file — no structural changes to orchestrator
- CoT separation: specialists wrap reasoning in `<thinking>`, output in `<specialist_output>` (already exists)
- generation.md: new file, referenced by design-improve.md only
- Token measurement: compare total prompt size before/after

</code_context>

<specifics>
## Specific Ideas

No specific requirements — additive polish phase.

</specifics>

<deferred>
## Deferred Ideas

- Auto-generated examples from eval runs (v1.3+)
- Context-dependent anti-slop rules based on page type (v1.3+)

</deferred>

---

*Phase: 13-few-shot-examples-polish*
*Context gathered: 2026-03-29*
