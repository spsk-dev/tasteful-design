# Phase 12: Playwright Interaction - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add opt-in `--interact` flag to `/design-review` that triggers Playwright MCP page interaction (hover, focus, scroll) before specialist scoring. Follow baseline-interact-reset pattern: screenshot clean state, perform interactions, reload page, then run standard review. Cap at 8 interactions per review. Also validate the full pipeline end-to-end by running `/design-audit` on start.fusefinance.com.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — infrastructure phase. Key guidance from research:

- `--interact` flag is OPT-IN — default behavior remains screenshot-only (preserves Tier 2/3 degradation)
- Interaction protocol: discover elements via `browser_snapshot` (accessibility tree), then `browser_hover`, `browser_click`, `browser_evaluate` (for scroll)
- Baseline-interact-reset pattern: (1) screenshot clean state, (2) interact with up to 8 elements, (3) capture interaction screenshots, (4) reload page, (5) run standard review on clean DOM
- Interaction screenshots passed to relevant specialists (Motion, Code/A11y, Color/Layout) as additional context
- Budget cap: 8 interactions max — prevent runaway interaction loops
- Playwright MCP tools used: `browser_navigate`, `browser_snapshot`, `browser_hover`, `browser_click`, `browser_evaluate`, `browser_take_screenshot`, `browser_close`
- No `browser_fill_form` or `browser_drag` — those are for `/design-validate`, not review
- TEST-01: Run `/design-audit` on start.fusefinance.com as end-to-end validation

</decisions>

<canonical_refs>
## Canonical References

- `commands/design-review.md` — Add --interact flag handling
- `commands/design-audit.md` — Already uses Playwright MCP for navigation
- `skills/design-review/references/flow.md` — Flow audit patterns (Playwright MCP usage)
- `config/flow-scoring.json` — Flow audit config
- `.planning/research/SUMMARY.md` — Interaction architecture recommendations
- `.planning/research/STACK.md` — Playwright MCP tool list

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `design-audit.md` already uses Playwright MCP extensively — established patterns for navigate, snapshot, click, screenshot
- `browser_snapshot` accessibility tree pattern for element discovery
- `browser_evaluate` for running JS (scroll, animation detection)
- DOM stability detection via MutationObserver (from flow audit)

### Integration Points
- `design-review.md` Phase 0 — add --interact flag parsing
- `design-review.md` Phase 1 — insert interaction step between screenshot and specialist dispatch
- Specialist prompts receive additional interaction screenshots as context
- Interaction findings tagged separately from static review findings

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase.

</specifics>

<deferred>
## Deferred Ideas

- Vision-mode coordinate-based clicking (v1.3+)
- Interaction replay recording (v1.3+)

</deferred>

---

*Phase: 12-playwright-interaction*
*Context gathered: 2026-03-29*
