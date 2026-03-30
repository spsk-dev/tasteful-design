# Phase 11: Specialist Consolidation - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Merge the Copy specialist into Intent/Originality/UX, reducing from 8 to 7 specialists. The merged Intent specialist produces 4 sub-scores: intent_match, originality, ux_flow, copy_quality. Update scoring.json atomically (total_weight 17→16, quick_mode recalculated). Add structural assertion in validate-structure.sh verifying sum of weights equals total_weight. Recalibrate eval assertions for 7-specialist architecture. All evals must pass after merge.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Key guidance from research:

- Copy specialist (prompts/copy.md) merged INTO intent.md — not a separate file
- Intent specialist already has 3 sub-scores (intent_match, originality, ux_flow) — add copy_quality as 4th
- Copy's checklist items (tone, voice, CTAs, microcopy, error messages) become part of intent.md instructions
- Copy's reference knowledge merges into intent.md reference_knowledge section
- scoring.json: Copy weight (1) redistributed — intent weight stays 3, copy_quality gets own weight of 1, total_weight: 17→16 (net: removed Copy standalone, added copy_quality to Intent)
- Actually: total_weight goes from 17 to 16 because Copy's standalone weight (1) is removed. The intent specialist's overall contribution stays at 3 (for the 3 original dimensions) + 1 (for copy_quality) = 4, but the copy_quality sub-score weight replaces the standalone Copy weight. Net: 17 - 1 = 16.
- Wait — let me reconsider. Current: I*3 + O*3 + UX*2 + T*2 + C*2 + L + Ic + M + Cp + Co = 17. After merge: I*3 + O*3 + UX*2 + T*2 + C*2 + L + Ic + M + CpQ*1 + Co = 16 (Cp removed, CpQ absorbed into Intent). Net: 17 - 1(Cp) = 16.
- quick_mode_total_weight: Copy was NOT in quick mode (quick mode = Font, Color, Layout, Intent). Recalculate: was /13, stays /13 if Copy was excluded. Verify during implementation.
- Delete prompts/copy.md after merging content into intent.md
- Update all references: design-review.md, design-audit.md, design-improve.md, shared/output.md, README.md
- validate-structure.sh: add assertion checking sum of weights equals total_weight in scoring.json

</decisions>

<canonical_refs>
## Canonical References

- `skills/design-review/prompts/intent.md` — Merge target
- `skills/design-review/prompts/copy.md` — Merge source (delete after)
- `config/scoring.json` — Weights to update atomically
- `commands/design-review.md` — Remove Copy specialist dispatch, update count references
- `commands/design-audit.md` — Update specialist count references
- `commands/design-improve.md` — Update specialist count references
- `shared/output.md` — Update "8 specialists" branding to "7 specialists"
- `evals/validate-structure.sh` — Add weight-sum assertion, update prompt file count
- `evals/assertions.json` — Recalibrate for 7-specialist scoring
- `README.md` — Update specialist count
- `CLAUDE.md` — Update specialist count
- `ARCHITECTURE.md` — Update specialist count and diagram

</canonical_refs>

<code_context>
## Existing Code Insights

### Current State
- 8 specialist prompts in skills/design-review/prompts/ (font, color, layout, icons, motion, intent, copy, code-a11y)
- Boss prompt in skills/design-review/prompts/boss.md
- Intent already has 3 sub-scores in JSON output: intent_match, originality, ux_flow
- Copy has its own prompt with tone/voice/CTA/microcopy review checklist

### Integration Points
- design-review.md Phase 0 dispatches 8 specialists — must dispatch 7
- Boss synthesizer receives 8 specialist outputs — must handle 7 with 4 Intent sub-scores
- Scoring formula in boss.md: `(I*3 + O*3 + UX*2 + T*2 + C*2 + L + Ic + M + Cp + Co) / 17`
- Quick mode selects 4 specialists — Copy was not one of them

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase.

</specifics>

<deferred>
## Deferred Ideas

None — merge is self-contained.

</deferred>

---

*Phase: 11-specialist-consolidation*
*Context gathered: 2026-03-29*
