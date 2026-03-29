# Phase 4: Flow Navigation Engine - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the `/design-audit` command that navigates SPA flows using Playwright MCP. The command accepts a URL and flow intent description, navigates screen-by-screen by identifying and clicking CTAs, captures screenshots at each state change, and stops at flow completion or dead ends. Supports deterministic URL sequence fallback and authenticated flows.

</domain>

<decisions>
## Implementation Decisions

### Command Structure
- **D-56:** New command `commands/design-audit.md` with frontmatter matching existing patterns
- **D-57:** Arguments: `<url> --flow "description"` (intent mode) or `<url> --steps url1,url2,url3` (deterministic mode)
- **D-58:** Optional `--auth` flag for authenticated flows — prompts user for login credentials or expects pre-authenticated browser session
- **D-59:** Optional `--max-screens N` flag (default 10) to cap navigation depth
- **D-60:** Command registered in `.claude-plugin/plugin.json` and routed via `commands/design.md`

### Navigation Engine
- **D-61:** Uses Playwright MCP (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_take_screenshot`) for stateful navigation
- **D-62:** Intent-driven navigation: agent reads `browser_snapshot` at each step, identifies CTA matching flow intent, clicks it
- **D-63:** Screen state change detection via DOM stability — wait for mutations to stop (not `networkidle`), then confirm new screen via snapshot diff
- **D-64:** Flow completion detection: agent recognizes success states (confirmation pages, "done" messages) or dead ends (no matching CTAs)
- **D-65:** URL sequence mode (`--steps`): navigates to each URL in order, captures screenshot at each. No intent-driven clicking needed.
- **D-66:** Authenticated flow: navigate to URL first, if login prompt detected → pause and instruct user to login in the browser, then resume audit

### Screenshot Management
- **D-67:** Screenshots captured via `browser_take_screenshot` at each screen state
- **D-68:** Screenshots saved to a temp directory (`/tmp/design-audit-{timestamp}/`)
- **D-69:** Each screenshot named `screen-{N}-{slug}.png` where slug is derived from visible heading or URL path
- **D-70:** Screenshots converted to JPEG and compressed for report embedding (Phase 6)

### Flow State Tracking
- **D-71:** Internal flow state tracks: screen number, screenshot path, screen name (from content), timestamp, URL (if changed), CTA clicked
- **D-72:** Flow state persisted as JSON (`/tmp/design-audit-{timestamp}/flow-state.json`) for downstream phases to consume
- **D-73:** Terminal output shows progress: `Screen {N}: {name} — captured ✓` at each step

### Integration
- **D-74:** Add `design-audit` route to `commands/design.md` orchestrator
- **D-75:** Add `skills/design-review/references/flow.md` — navigation patterns, screen detection heuristics, flow intent mapping
- **D-76:** Add `config/flow-scoring.json` — default flow scoring config (max screens, timeout, detection thresholds)

### Claude's Discretion
- Exact DOM stability heuristics (mutation observer timeout, diff threshold)
- Screenshot naming slug generation logic
- How to handle popups, modals, and overlays during navigation
- Playwright MCP timeout values
- Error recovery when navigation fails mid-flow

</decisions>

<canonical_refs>
## Canonical References

### Existing Plugin (extend)
- `commands/design.md` — Router, add audit route
- `.claude-plugin/plugin.json` — Add design-audit command
- `shared/output.md` — Branded output for progress display

### Research
- `.planning/research/STACK.md` — Playwright MCP integration patterns
- `.planning/research/ARCHITECTURE.md` — Component boundaries and data flow
- `.planning/research/PITFALLS.md` — SPA navigation pitfalls (networkidle, pushState, screenshot timing)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `shared/output.md` — Branded progress output
- `commands/design.md` — Router pattern for subcommands
- Playwright MCP already available as MCP server

### Established Patterns
- Commands in `commands/*.md` with YAML frontmatter
- Config in `config/*.json`
- References in `skills/design-review/references/*.md`
- Branded output via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`

### Integration Points
- `commands/design.md` — add `audit` route
- `plugin.json` — add `design-audit` command
- New reference file for flow navigation knowledge

</code_context>

<specifics>
## Specific Ideas

- Primary test target: start.fusefinance.com (client onboarding flow)
- The flow description "complete the client onboarding" should be enough for the agent to navigate the entire flow
- Progress output should feel like watching the agent work — show each screen as it's captured
- The flow state JSON is the contract between Phase 4 (navigation) and Phase 5 (review) — get this right

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-flow-navigation-engine*
*Context gathered: 2026-03-29*
