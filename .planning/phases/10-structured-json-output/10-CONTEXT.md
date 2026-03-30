# Phase 10: Structured JSON Output - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Migrate all specialist prompts and the boss synthesizer to emit structured JSON output wrapped in XML tags. Specialists emit `<specialist_output>` JSON, boss emits `<boss_output>` JSON. Build a dual-format output parser (JSON-first with regex fallback). Update `/design-improve` to consume `top_fixes` array programmatically. Update `generate-report.sh` to read structured JSON from flow-state.json. All quality evals must still pass after migration.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Key guidance from research:

- Use think-then-structure pattern: `<thinking>` free-form reasoning first, `<specialist_output>` structured JSON second (preserves reasoning quality)
- JSON schema: `{ "specialist": "name", "score": N, "findings": [...], "summary": "..." }` — minimal, not over-constrained
- Boss output: `{ "scores": {...}, "weighted_score": N, "verdict": "SHIP|CONDITIONAL|BLOCK", "top_fixes": [...], "consensus_findings": [...] }`
- Validate JSON with `jq -e` in eval pipeline; retry once on parse failure
- Dual-format parser: try JSON extraction first, fall back to regex for pre-v1.2.0 output compatibility
- Migrate one specialist at a time, run evals after each to catch regressions
- Update `<output_format>` section in each extracted prompt file (from Phase 8)
- Gemini specialists (Color, Layout) need JSON output too — test Gemini CLI compliance

</decisions>

<canonical_refs>
## Canonical References

- `skills/design-review/prompts/*.md` — Extracted prompt files to update output format
- `skills/design-review/prompts/boss.md` — Boss synthesizer prompt to update
- `commands/design-review.md` — Orchestrator that consumes specialist output
- `commands/design-improve.md` — Consumes boss `top_fixes` for fix loop
- `commands/design-audit.md` — Also consumes specialist output for flow audit
- `scripts/generate-report.sh` — Reads flow-state.json for HTML report
- `evals/parse-review-output.sh` — Output parser to upgrade to JSON-first
- `evals/run-quality-evals.sh` — Must still pass after migration
- `config/scoring.json` — Scoring weights (preserved, not modified)
- `.planning/research/SUMMARY.md` — JSON output architecture recommendations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 9 extracted prompt files with `<output_format>` sections ready for JSON schema insertion
- `evals/parse-review-output.sh` — existing regex parser to extend with JSON-first path
- `evals/run-quality-evals.sh` — assertion pipeline that validates output quality

### Established Patterns
- XML tag wrapping for structured content (established in Phase 8)
- `jq` for JSON validation/extraction (used in validate-structure.sh and run-quality-evals.sh)
- Dual-format support pattern (Gemini CLI + Claude Code)

### Integration Points
- Specialist prompts → `<output_format>` sections define the JSON contract
- `design-review.md` Phase 2 → parses specialist output and passes to boss
- `design-improve.md` → reads `top_fixes` from boss output for fix application
- `generate-report.sh` → reads `flow-state.json` which contains specialist findings
- `parse-review-output.sh` → upgraded to JSON-first extraction

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase.

</specifics>

<deferred>
## Deferred Ideas

- Per-specialist JSON schemas (Out of Scope — one shared schema is sufficient)
- Schema versioning (v1.3+ if needed)

</deferred>

---

*Phase: 10-structured-json-output*
*Context gathered: 2026-03-29*
