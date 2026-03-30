# Phase 8: Prompt Extraction + Restructuring - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Extract all 8 specialist prompts and the boss synthesizer from inline command files into individual prompt files under `skills/design-review/prompts/`. Restructure each with XML tags (`<role>`, `<context>`, `<instructions>`, `<output_format>`), add 4-level scoring rubrics with concrete anchors, remove over-aggressive directives (ALL-CAPS, "FLAG SPECIFICALLY", "NEVER", "Find at least N"). Record eval baselines before and after. Commands use `@` includes to reference extracted prompts.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions. Key guidance from research:

- XML structure follows Anthropic's Claude 4.6 best practices: `<role>`, `<context>`, `<reference_knowledge>`, `<instructions>`, `<output_format>`
- Rubric levels: 1 (Poor), 2 (Below Average), 3 (Good), 4 (Excellent) with domain-specific anchors per specialist
- Directive cleanup: replace ALL-CAPS with normal case, replace "NEVER" with "avoid", replace "Find at least N" with "identify notable issues", replace "FLAG SPECIFICALLY" with guidance language
- Extract to: `skills/design-review/prompts/{specialist-name}.md` (font.md, color.md, layout.md, icons.md, motion.md, intent.md, copy.md, code-a11y.md, boss.md)
- Both design-review.md and design-audit.md must reference the same extracted prompts via `@` includes
- Preserve existing scoring weights and specialist behavior — this is restructuring, not rewriting logic

</decisions>

<canonical_refs>
## Canonical References

- `commands/design-review.md` — Primary source of specialist prompts (732 lines)
- `commands/design-audit.md` — Also contains specialist prompts (1274 lines)
- `skills/design-review/references/` — Existing reference files (typography.md, color.md, layout.md, icons.md, motion.md, intent.md, visual-design-rules.md, flow.md)
- `config/scoring.json` — Scoring weights (do not modify in this phase)
- `evals/validate-structure.sh` — Layer 1 structural checks
- `evals/run-evals.sh` — Eval orchestrator
- `.planning/research/SUMMARY.md` — Research findings on XML structure and rubric patterns
- `.planning/research/STACK.md` — Anthropic Claude 4.6 prompting best practices details

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 7 reference files in `skills/design-review/references/` — domain knowledge for each specialist
- `config/scoring.json` — weights and thresholds (preserved, not modified)
- `shared/output.md` — branding reference (preserved)

### Established Patterns
- Commands use `@` file references for includes (e.g., `@shared/output.md`)
- Specialist prompts are currently inline in Phase 0 section of design-review.md
- Each specialist gets: role description, reference knowledge, scoring guidance, output format instructions
- Boss synthesizer merges findings with weighted formula

### Integration Points
- `design-review.md` Phase 0 dispatches specialists — must `@` include extracted prompts
- `design-audit.md` Section 7 dispatches specialists — must `@` include same extracted prompts
- `design-improve.md` re-runs failing specialists — must reference same prompts
- `evals/validate-structure.sh` may need new checks for prompt file existence

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Refer to ROADMAP phase description and success criteria.

</specifics>

<deferred>
## Deferred Ideas

- Few-shot examples per specialist (Phase 13 — PRMT-04)
- Chain-of-thought separation (Phase 13 — PRMT-05)
- Structured JSON output format (Phase 10 — JSON-01..05)

</deferred>

---

*Phase: 08-prompt-extraction-restructuring*
*Context gathered: 2026-03-29*
