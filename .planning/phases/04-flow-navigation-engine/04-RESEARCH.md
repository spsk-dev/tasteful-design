# Phase 4: Flow Navigation Engine - Research

**Researched:** 2026-03-28
**Domain:** SPA flow navigation via Playwright MCP, screenshot capture, flow state management
**Confidence:** HIGH

## Summary

Phase 4 builds the `/design-audit` command that navigates multi-screen SPA flows using Playwright MCP tools, captures screenshots at each screen state change, and outputs a flow-state JSON contract for downstream phases (Phase 5: per-screen review, Phase 6: HTML report). The core challenge is detecting "new screen" in SPAs where navigation is invisible to traditional browser events -- `pushState` changes the URL without triggering load events, and in-page transitions (tabs, modals, wizard steps) change content without changing the URL at all.

The Playwright MCP server (`@playwright/mcp`) is available in this environment (v1.58.2) and provides 20+ core tools for stateful browser automation. The key tools for flow navigation are `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_take_screenshot`, `browser_wait_for`, and `browser_evaluate`. The MCP approach keeps the browser open between calls, enabling multi-step SPA navigation without writing throwaway scripts.

The flow state JSON (`/tmp/design-audit-{timestamp}/flow-state.json`) is the contract between Phase 4 (this phase) and Phases 5-6. Getting this data structure right is critical -- it carries screen names, screenshot paths, URLs, timestamps, and CTA metadata for each step.

**Primary recommendation:** Build `commands/design-audit.md` as a prompt-driven orchestrator that uses Playwright MCP tools directly (no shell scripts for navigation). The command does flow planning, incremental navigation, screenshot capture, and flow state persistence. Navigation uses `browser_snapshot` for element discovery + `browser_click` for actions + DOM stability heuristic for screen change detection.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-56:** New command `commands/design-audit.md` with frontmatter matching existing patterns
- **D-57:** Arguments: `<url> --flow "description"` (intent mode) or `<url> --steps url1,url2,url3` (deterministic mode)
- **D-58:** Optional `--auth` flag for authenticated flows -- prompts user for login credentials or expects pre-authenticated browser session
- **D-59:** Optional `--max-screens N` flag (default 10) to cap navigation depth
- **D-60:** Command registered in `.claude-plugin/plugin.json` and routed via `commands/design.md`
- **D-61:** Uses Playwright MCP (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_take_screenshot`) for stateful navigation
- **D-62:** Intent-driven navigation: agent reads `browser_snapshot` at each step, identifies CTA matching flow intent, clicks it
- **D-63:** Screen state change detection via DOM stability -- wait for mutations to stop (not `networkidle`), then confirm new screen via snapshot diff
- **D-64:** Flow completion detection: agent recognizes success states (confirmation pages, "done" messages) or dead ends (no matching CTAs)
- **D-65:** URL sequence mode (`--steps`): navigates to each URL in order, captures screenshot at each. No intent-driven clicking needed.
- **D-66:** Authenticated flow: navigate to URL first, if login prompt detected -> pause and instruct user to login in the browser, then resume audit
- **D-67:** Screenshots captured via `browser_take_screenshot` at each screen state
- **D-68:** Screenshots saved to a temp directory (`/tmp/design-audit-{timestamp}/`)
- **D-69:** Each screenshot named `screen-{N}-{slug}.png` where slug is derived from visible heading or URL path
- **D-70:** Screenshots converted to JPEG and compressed for report embedding (Phase 6)
- **D-71:** Internal flow state tracks: screen number, screenshot path, screen name (from content), timestamp, URL (if changed), CTA clicked
- **D-72:** Flow state persisted as JSON (`/tmp/design-audit-{timestamp}/flow-state.json`) for downstream phases to consume
- **D-73:** Terminal output shows progress: `Screen {N}: {name} -- captured checkmark` at each step
- **D-74:** Add `design-audit` route to `commands/design.md` orchestrator
- **D-75:** Add `skills/design-review/references/flow.md` -- navigation patterns, screen detection heuristics, flow intent mapping
- **D-76:** Add `config/flow-scoring.json` -- default flow scoring config (max screens, timeout, detection thresholds)

### Claude's Discretion
- Exact DOM stability heuristics (mutation observer timeout, diff threshold)
- Screenshot naming slug generation logic
- How to handle popups, modals, and overlays during navigation
- Playwright MCP timeout values
- Error recovery when navigation fails mid-flow

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOW-01 | `/design-audit <url> --flow "description"` command navigates a SPA guided by user's intent description | Playwright MCP `browser_navigate` + `browser_snapshot` + `browser_click` provide stateful SPA navigation. Command pattern follows existing `design-review.md` frontmatter format. |
| FLOW-02 | Agent uses Playwright MCP snapshots to identify and click CTAs matching the flow intent | `browser_snapshot` returns accessibility tree with element refs. Agent reads snapshot, matches CTA to flow intent, calls `browser_click` with ref. |
| FLOW-03 | Screenshot captured at each detected screen state change | `browser_take_screenshot` with `fullPage: true` or viewport-only. Save to `/tmp/design-audit-{timestamp}/screen-{N}-{slug}.png`. |
| FLOW-04 | Screen detection -- agent knows when a new "screen" has loaded (DOM stability, not networkidle) | `browser_evaluate` injects MutationObserver-based stability check. `browser_wait_for` with text detection as secondary signal. Never use networkidle. |
| FLOW-05 | Max screen limit (default 10) prevents runaway navigation | Simple counter in flow orchestration logic. Command argument `--max-screens N`. |
| FLOW-06 | URL sequence fallback via `--steps url1,url2,url3` for deterministic paths | Parse `--steps` argument, iterate URLs with `browser_navigate` for each. No intent-driven clicking needed. |
| FLOW-07 | Authenticated flow support -- can login first, then audit the protected flow | `--auth` flag: navigate to URL, if login form detected in snapshot, instruct user to log in via the headed browser, then `browser_snapshot` to confirm authenticated state before proceeding. Alternatively use `--storage-state` for pre-authenticated sessions. |
| FLOW-08 | Flow stops gracefully at completion/success state or dead end | Agent reads snapshot at each step. If it detects success patterns (confirmation copy, "done" headings) or no matching CTAs, it terminates the flow gracefully and writes partial flow-state. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Zero npm dependencies** -- plugin installs by file copy, no `node_modules`
- **Branded output** -- all terminal output uses `shared/output.md` format (signature line, Unicode boxes, score bars, footer)
- **Command pattern** -- YAML frontmatter with `name`, `description`, `allowed-tools`, then markdown body with `@${CLAUDE_PLUGIN_ROOT}/shared/output.md` import
- **Plugin registration** -- commands listed in `.claude-plugin/plugin.json`
- **GSD workflow** -- all work through GSD commands, no direct repo edits outside workflow

## Standard Stack

### Core

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| `@playwright/mcp` | latest (1.58.2 runtime) | Stateful SPA browser automation via MCP tools | Official Microsoft MCP server. Provides `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_take_screenshot`, `browser_wait_for`, `browser_evaluate` -- all needed for multi-step flow navigation. Already verified available in this environment. |
| Playwright Chromium | 1.58.2 (bundled) | Browser engine for rendering and screenshots | Bundled with Playwright. Auto-installed. Supports all modern CSS and Web APIs needed for detection. |

### Supporting

| Technology | Version | Purpose | When to Use |
|------------|---------|---------|-------------|
| `browser_evaluate` (MCP tool) | N/A | Run JS in page context for DOM stability detection, font readiness, animation catalog | Screen change detection heuristic, visual readiness checks before screenshots |
| `browser_wait_for` (MCP tool) | N/A | Wait for specific text to appear/disappear | Secondary signal for screen transitions (e.g., wait for new heading text) |
| `browser_resize` (MCP tool) | N/A | Change viewport dimensions | If capturing multiple viewport sizes per screen |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Playwright MCP | Temp `.mjs` scripts via Bash | Fallback if MCP not registered. Stateless -- must write full script per flow. Much more fragile. |
| `browser_snapshot` for element discovery | `browser_take_screenshot` + vision | Snapshot is text-based (accessibility tree), cheaper tokens, more reliable for button/link identification. Vision mode adds `--caps vision` complexity. |
| DOM stability heuristic | `browser_wait_for` text only | Text-only misses visual transitions where content stays the same but layout changes. DOM stability is more general. |

**Installation (for users who do not have Playwright MCP registered):**
```bash
claude mcp add playwright -- npx @playwright/mcp@latest
```

No npm install needed. The plugin itself has zero dependencies.

## Architecture Patterns

### Recommended File Structure

```
commands/
  design-audit.md          # NEW: /design-audit command (flow orchestrator)
  design.md                # MODIFIED: add /design audit route
config/
  flow-scoring.json        # NEW: flow-level config (max screens, timeouts, thresholds)
skills/design-review/references/
  flow.md                  # NEW: flow navigation reference knowledge
```

### Pattern 1: Prompt-Driven MCP Orchestration

**What:** The `design-audit.md` command is a prompt file that instructs the agent to call Playwright MCP tools in sequence. No shell scripts for navigation -- the agent IS the navigation engine.

**When to use:** Whenever the command needs stateful, multi-step browser interaction where each step depends on what the page shows.

**Why:** The agent can read `browser_snapshot` output (accessibility tree), reason about which element matches the flow intent, and decide what to click. This is the entire value proposition -- intent-driven navigation cannot be scripted because the click targets are unknown upfront.

**Flow per screen:**
```
1. browser_snapshot          -> read accessibility tree
2. Agent reasons: "The user wants to sign up. I see a 'Start Free Trial' button (ref: e42)"
3. browser_click ref="e42"   -> click the CTA
4. browser_evaluate           -> run DOM stability check (MutationObserver)
5. browser_wait_for text="..."  -> optional: wait for expected heading
6. browser_snapshot          -> confirm new screen loaded
7. browser_take_screenshot   -> capture the new screen state
8. Write to flow-state.json  -> persist screen metadata
9. Terminal output: "Screen 2: Sign Up Form -- captured checkmark"
```

### Pattern 2: Two Navigation Modes with Shared Capture

**What:** Intent mode (`--flow`) and deterministic mode (`--steps`) share the same screenshot capture and flow state logic but differ in how they navigate.

**When to use:** Always -- these are the two entry points specified in D-57.

**Intent mode:**
```
for each screen (up to --max-screens):
  snapshot -> reason about CTA -> click -> wait for stability -> capture
```

**Deterministic mode:**
```
for each URL in --steps:
  browser_navigate(url) -> wait for stability -> capture
```

Both modes produce the same flow-state.json format. Downstream phases (5, 6) do not know or care which mode was used.

### Pattern 3: Progressive Flow State Writing

**What:** Write flow-state.json after EACH screen, not at the end. If the flow fails on screen 5, screens 1-4 are preserved.

**When to use:** Always. Mid-flow failures are common (element not found, timeout, unexpected page state).

**Implementation:** After each screen capture, overwrite the JSON file with all screens captured so far. Include a `"status": "in_progress"` or `"status": "complete"` field.

### Pattern 4: Headed Browser for Auth Flows

**What:** For `--auth` flows, Playwright MCP runs in headed mode (default). The agent navigates to the URL, detects a login form via snapshot, then pauses and instructs the user to complete login in the visible browser window. After user confirms, the agent resumes with the authenticated session.

**When to use:** FLOW-07 authenticated flow support.

**Why not automated login:** Automated credential entry is a security risk, and many sites have CAPTCHAs, 2FA, or anti-bot measures that prevent it. Having the user log in manually in the headed browser is simpler and more reliable.

**Alternative:** Playwright MCP supports `--storage-state <path>` to load pre-authenticated cookies/localStorage. The command could accept `--storage-state` as an advanced option for CI/automated flows.

### Anti-Patterns to Avoid

- **Using `networkidle` for screen detection:** SPAs with analytics, WebSockets, or polling never reach network idle. Use DOM stability instead. (Pitfall #1 from PITFALLS.md)
- **Using `waitForNavigation()` for SPA transitions:** SPAs use `pushState`/`replaceState` which do not trigger navigation events. Use `browser_wait_for` with text or `browser_evaluate` with DOM observation. (Pitfall #3)
- **Screenshots before visual readiness:** Font loading, CSS transitions, and layout shifts can produce misleading screenshots. Wait for `document.fonts.ready` and DOM stability before capturing. (Pitfall #2)
- **Monolithic command file:** Do not inline specialist dispatch logic. Phase 4 is navigation + capture only. Phase 5 handles review dispatch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser automation | Custom Playwright scripts per flow | Playwright MCP tools (`browser_*`) | Stateful session, element refs, no script generation overhead |
| Element discovery | CSS selectors or XPath | `browser_snapshot` accessibility tree | Returns semantic element refs (e42, e15) that are stable within a snapshot. Agent reads roles, names, and text. |
| Screenshot capture | Manual Playwright API calls | `browser_take_screenshot` MCP tool | Handles viewport, full-page, element selection. Returns file path. |
| DOM readiness | Custom JS injection framework | `browser_evaluate` with inline JS | One-shot JS execution in page context. Returns result directly. |
| Wait for text | Polling loops | `browser_wait_for` with `text` param | Built-in MCP tool with timeout handling |

**Key insight:** The Playwright MCP server is the entire automation layer. The command file is pure orchestration logic (flow planning, screen detection, state tracking) -- it delegates ALL browser interaction to MCP tools.

## Common Pitfalls

### Pitfall 1: networkidle Hangs on Real SPAs
**What goes wrong:** Agent waits for zero network connections after a click. SPAs with analytics pings, WebSockets, or SSE streams never reach idle. Flow hangs until timeout.
**Why it happens:** `networkidle` is the intuitive "wait for page to finish" but SPAs have persistent background connections.
**How to avoid:** Use DOM stability detection via `browser_evaluate` with a MutationObserver pattern. Wait for mutations to stop for 500ms-1000ms. Combine with `browser_wait_for` text as secondary signal.
**Warning signs:** Flow works on simple test pages but hangs on production SPAs with Google Analytics, Intercom, or chat widgets.

### Pitfall 2: Screenshots Before Fonts/Animations Settle
**What goes wrong:** Screenshot captured immediately after DOM stability, but custom fonts have not loaded yet (showing fallback fonts) or CSS transitions are mid-animation.
**Why it happens:** DOM stability != visual readiness. Font loading is async. CSS transitions take time.
**How to avoid:** After DOM stability, run `browser_evaluate` with `document.fonts.ready` (5s timeout). Consider injecting `animation-duration: 0s !important; transition-duration: 0s !important` for screenshot capture, but catalog animations BEFORE disabling them (for Phase 5's Motion specialist).
**Warning signs:** Screenshots show system fonts when the real app uses custom fonts. Elements appear mid-fade.

### Pitfall 3: SPA pushState Invisible to Navigation Events
**What goes wrong:** Agent clicks a React Router link. URL changes via pushState but Playwright does not detect a "navigation." Agent either hangs waiting for navigation or proceeds before the new screen renders.
**Why it happens:** pushState/replaceState do not trigger browser navigation lifecycle events.
**How to avoid:** Do NOT rely on navigation events. After clicking, use `browser_evaluate` to check if URL changed, then use DOM stability heuristic to detect when new content has rendered. `browser_wait_for` with expected text is a good secondary signal.
**Warning signs:** Works on static sites, breaks on React/Vue/Svelte SPAs with client-side routing.

### Pitfall 4: Flow Description Ambiguity
**What goes wrong:** User says `--flow "complete the checkout"` but there are multiple checkout paths (guest vs logged-in), multiple "Next" buttons, or conditional screens.
**Why it happens:** Natural language flow descriptions are inherently ambiguous.
**How to avoid:** At each step, the agent should report what it sees and what it will click (terminal output). If ambiguous (multiple matching CTAs), take the most prominent one and note the choice. The `--steps` fallback exists for when intent mode picks the wrong path. The agent should also check for dead ends and report them clearly.
**Warning signs:** Flow takes an unexpected path. Agent clicks a different "Submit" than the user intended.

### Pitfall 5: Stale Element Refs After Navigation
**What goes wrong:** Agent gets a snapshot, identifies element ref `e42`, but by the time it calls `browser_click(ref=e42)`, the page has changed (SPA re-render, animation) and `e42` no longer exists.
**Why it happens:** Playwright MCP element refs are tied to a specific snapshot. DOM changes invalidate them.
**How to avoid:** Always take a fresh `browser_snapshot` immediately before clicking. Do not cache element refs across multiple operations. The pattern is: snapshot -> identify -> click (all in sequence, no other operations between snapshot and click).
**Warning signs:** "Element not found" errors after what seemed like a stable page.

### Pitfall 6: Flow State Lost on Mid-Flow Error
**What goes wrong:** Flow is on screen 5 of 8 when a timeout or element-not-found error occurs. All progress is lost.
**Why it happens:** No progressive persistence -- flow state only written at the end.
**How to avoid:** Write flow-state.json after EACH screen capture (Pattern 3). On error, capture a screenshot of the current state, log the error in the flow state, and terminate gracefully with `"status": "error"` and `"error_at_screen": 5`.
**Warning signs:** Users wait 3+ minutes for a flow audit that fails and produces nothing.

## Code Examples

### DOM Stability Detection (for browser_evaluate)

```javascript
// Source: Derived from Playwright docs and PITFALLS.md recommendations
// Run via browser_evaluate after a click/navigation
(function() {
  return new Promise((resolve) => {
    let timer = null;
    const observer = new MutationObserver(() => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        observer.disconnect();
        resolve({ stable: true, waited: true });
      }, 800); // 800ms of no mutations = stable
    });
    observer.observe(document.body, {
      childList: true, subtree: true, attributes: true, characterData: true
    });
    // Fallback: if no mutations at all within 2s, page is already stable
    timer = setTimeout(() => {
      observer.disconnect();
      resolve({ stable: true, waited: false });
    }, 2000);
  });
})()
```

### Font Readiness Check (for browser_evaluate)

```javascript
// Source: MDN document.fonts.ready + Playwright bug #35972 workaround
(function() {
  return Promise.race([
    document.fonts.ready.then(() => ({ fontsReady: true })),
    new Promise(resolve => setTimeout(() => resolve({ fontsReady: false, timeout: true }), 5000))
  ]);
})()
```

### Flow State JSON Schema

```json
{
  "version": "1.0",
  "status": "complete",
  "flow_intent": "complete the client onboarding",
  "url": "https://start.fusefinance.com",
  "mode": "intent",
  "max_screens": 10,
  "started_at": "2026-03-28T14:30:00Z",
  "completed_at": "2026-03-28T14:33:45Z",
  "screens": [
    {
      "number": 1,
      "name": "Welcome",
      "slug": "welcome",
      "url": "https://start.fusefinance.com/",
      "screenshot_path": "/tmp/design-audit-20260328-143000/screen-1-welcome.png",
      "timestamp": "2026-03-28T14:30:05Z",
      "cta_clicked": "Get Started",
      "cta_ref": "e42"
    },
    {
      "number": 2,
      "name": "Company Information",
      "slug": "company-information",
      "url": "https://start.fusefinance.com/onboarding/company",
      "screenshot_path": "/tmp/design-audit-20260328-143000/screen-2-company-information.png",
      "timestamp": "2026-03-28T14:30:18Z",
      "cta_clicked": "Continue",
      "cta_ref": "e67"
    }
  ],
  "error": null
}
```

### Slug Generation Logic (discretion area)

```
1. Read browser_snapshot at current screen
2. Find first <h1> or <h2> heading text
3. If no heading: extract last URL path segment
4. If no URL change: use "screen-{N}"
5. Slugify: lowercase, replace spaces with hyphens, strip non-alphanumeric except hyphens
6. Truncate to 40 chars
```

### Command Frontmatter Pattern (matching existing commands)

```yaml
---
name: design-audit
description: >
  Flow-level design audit -- navigates multi-screen SPA flows using Playwright MCP,
  captures screenshots at each state change, and produces flow state for downstream
  review and reporting. Use when the user says "audit the flow", "design audit",
  "walk through the onboarding", "/design audit", or wants to evaluate a multi-screen
  user journey.
allowed-tools: Bash(npx *), Bash(mkdir *), Bash(cp *), Bash(rm *)
---
```

Note: MCP tools (`browser_*`) do not need to be listed in `allowed-tools` -- they are available via the registered MCP server.

### Design Router Addition (for commands/design.md)

Add this row to the routing table:

```markdown
| `/design audit` | `/design-audit` | Flow audit (navigate + capture + review) |
```

And add `--flow`, `--steps`, `--auth`, `--max-screens` to the pass-through flags list.

## Playwright MCP Tool Reference (Phase 4 subset)

The full MCP server exposes 75+ tools. Phase 4 uses only these core tools:

| Tool | Phase 4 Usage | Key Parameters |
|------|---------------|----------------|
| `browser_navigate` | Initial page load, deterministic `--steps` mode | `url` |
| `browser_snapshot` | Element discovery (find CTAs, headings, forms) | Returns accessibility tree with refs |
| `browser_click` | Click identified CTA to navigate to next screen | `ref` (from snapshot) |
| `browser_take_screenshot` | Capture screen state as PNG | `filename`, `fullPage` (boolean) |
| `browser_evaluate` | DOM stability check, font readiness, URL detection | `function` (JS string) |
| `browser_wait_for` | Wait for specific text to appear after navigation | `text`, `time` |
| `browser_resize` | Set viewport before screenshots (if multi-viewport) | `width`, `height` |
| `browser_close` | Cleanup at end of flow | (none) |

**Not used in Phase 4** (but relevant in other phases):
- `browser_fill_form`, `browser_type` -- Phase 4 navigates, does not fill forms (unless flow requires it)
- `browser_console_messages` -- Phase 5 could use for error detection
- `browser_handle_dialog` -- only if dialogs block navigation
- Cookie/storage tools -- only with `--caps storage` flag, not default

### Playwright MCP Configuration for Flow Audit

Recommended MCP registration:
```bash
claude mcp add playwright -- npx @playwright/mcp@latest --viewport-size 1440x900
```

For authenticated flows with pre-saved state:
```bash
claude mcp add playwright -- npx @playwright/mcp@latest --storage-state ./auth-state.json
```

Default timeouts (from `--help`):
- Action timeout: 5000ms (adequate for clicks)
- Navigation timeout: 60000ms (adequate for page loads)

**Discretion recommendation for custom timeouts:** Keep defaults. The DOM stability heuristic (800ms quiet period) provides the actual "is the screen ready" signal. Playwright's built-in timeouts are safety nets, not precision tools.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `waitForNavigation()` | `waitForURL()` + DOM stability | Playwright docs updated 2025 | SPAs no longer hang on pushState navigations |
| `networkidle` for "page loaded" | DOM mutation observation | Community consensus ~2024 | Eliminates hangs from analytics/WebSocket connections |
| Playwright CLI scripts per flow | Playwright MCP stateful session | MCP server released 2025 | No script generation, browser stays open, element refs are stable within snapshots |
| Screenshot immediately after click | Font ready + DOM stable + animation-free screenshot | Ongoing best practice | Eliminates flaky screenshots with fallback fonts or mid-animation captures |

**Deprecated/outdated:**
- `page.waitForLoadState('networkidle')` -- officially discouraged by Playwright for SPAs
- `page.waitForNavigation()` for SPA transitions -- does not detect pushState
- Writing temp Playwright scripts for each flow step -- replaced by MCP stateful tools

## Open Questions

1. **Multi-viewport screenshots per screen**
   - What we know: Existing `/design-review` captures desktop (1440x900), mobile (375x812), and fold (375x667) viewports
   - What's unclear: Should Phase 4 capture all three viewports per screen, or just desktop? Multi-viewport triples screenshot count and flow time.
   - Recommendation: Desktop only in Phase 4. Phase 5 can re-capture specific screens at other viewports if needed. This keeps flow navigation fast.

2. **Cookie consent banner handling**
   - What we know: Many sites show cookie consent on first visit, blocking the actual content
   - What's unclear: How aggressive should auto-dismissal be? Common selectors exist but are fragile.
   - Recommendation: After initial `browser_navigate`, check snapshot for common cookie banner patterns. If found, attempt to click "Accept" / "Accept All". If not found or click fails, proceed without dismissing -- user can handle it in headed browser. Log the attempt in flow state.

3. **Popup/modal handling during navigation**
   - What we know: SPAs frequently use modals for confirmations, tooltips for onboarding, overlays for promotions
   - What's unclear: Should the agent dismiss modals that are not part of the flow? What if a modal IS a flow step?
   - Recommendation: Agent reads snapshot. If modal content matches flow intent (e.g., "Confirm your email" in an onboarding flow), treat it as a screen. If modal is unrelated (cookie banner, promotion), try to dismiss. Log either way.

4. **Playwright MCP `--headless` vs headed mode**
   - What we know: MCP defaults to headed (visible browser). Headless is faster but user cannot see what is happening or intervene for auth.
   - What's unclear: Should `--auth` force headed and non-auth default to headless?
   - Recommendation: Always use headed mode (default). The terminal progress output tells the user what is happening, and they can watch the browser navigate. Auth flows require headed. The visual feedback is worth the minor performance cost.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@playwright/mcp` | Flow navigation (FLOW-01 through FLOW-08) | Yes | 1.58.2 (latest) | Temp Playwright scripts (degraded) |
| Playwright Chromium | Screenshot capture | Yes | Bundled with 1.58.2 | `npx playwright install chromium` |
| Node.js | MCP server runtime | Yes | 18+ (required) | None (blocking) |
| `mkdir`, `cp`, `rm` | Temp directory management | Yes | Built-in | None |

**Missing dependencies with no fallback:** None -- all required tools are available.

**Missing dependencies with fallback:** None.

**Note from STATE.md:** "Playwright MCP not yet registered in this environment -- needs `claude mcp add` before Phase 4 execution." The MCP server binary is available (`npx @playwright/mcp@latest` works) but may not be registered as an MCP server in Claude Code. Phase 4's first task should verify MCP registration and add it if missing.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual validation via real SPA navigation |
| Config file | None -- no automated test framework for plugin commands |
| Quick run command | `/design-audit http://localhost:3000 --flow "navigate to settings" --max-screens 3` |
| Full suite command | Run against 3 test targets: static HTML, React SPA, production site |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOW-01 | Command accepts URL + flow description | smoke | `/design-audit http://localhost:3000 --flow "sign up"` | No -- Wave 0 |
| FLOW-02 | Agent identifies and clicks CTAs from snapshots | integration | Run against multi-page SPA, verify flow-state.json has >1 screen | No -- Wave 0 |
| FLOW-03 | Screenshot at each screen change | integration | Check `/tmp/design-audit-*/screen-*.png` files exist | No -- Wave 0 |
| FLOW-04 | DOM stability detection (not networkidle) | integration | Run against SPA with analytics, verify no timeouts | No -- Wave 0 |
| FLOW-05 | Max screen limit respected | unit-like | `--max-screens 2` on a 5-screen flow, verify only 2 screenshots | No -- Wave 0 |
| FLOW-06 | URL sequence fallback | smoke | `--steps http://a.com,http://b.com`, verify 2 screenshots | No -- Wave 0 |
| FLOW-07 | Authenticated flow support | manual-only | Requires real login page. Manual: run with `--auth`, complete login, verify flow continues | N/A |
| FLOW-08 | Graceful stop at completion/dead end | integration | Run against a flow that ends at a "Thank you" page, verify `status: complete` in JSON | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Manual smoke test against a localhost dev server
- **Per wave merge:** Run all 3 test targets (static, SPA, production)
- **Phase gate:** All 8 FLOW requirements verified before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Simple multi-page HTML test fixture (3 pages linked together) for FLOW-01/02/03/05/06
- [ ] Verify Playwright MCP is registered (`claude mcp list` or equivalent)
- [ ] Create `/tmp/design-audit-test/` directory structure for output verification

## Sources

### Primary (HIGH confidence)
- [Playwright MCP GitHub README](https://github.com/microsoft/playwright-mcp) -- Full tool inventory (75+ tools), configuration options, installation
- [Playwright MCP `--help` output](local) -- Verified CLI options: `--viewport-size`, `--storage-state`, `--headless`, timeouts
- [Playwright Navigation Docs](https://playwright.dev/docs/navigations) -- SPA navigation patterns, waitForURL for pushState detection
- [Playwright Screenshots Docs](https://playwright.dev/docs/screenshots) -- Screenshot API: fullPage, type (png/jpeg), quality

### Secondary (MEDIUM confidence)
- [Playwright Bug #19835](https://github.com/microsoft/playwright/issues/19835) -- networkidle infinite wait documentation
- [Playwright Bug #35972](https://github.com/microsoft/playwright/issues/35972) -- Screenshot font loading race conditions
- [Simon Willison: Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) -- Real-world MCP usage patterns

### Tertiary (LOW confidence)
- None -- all findings verified against primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Playwright MCP verified installed, tools documented, patterns established
- Architecture: HIGH -- follows existing plugin command patterns, data flow is clear
- Pitfalls: HIGH -- all documented in PITFALLS.md with multiple source verification
- Flow state contract: MEDIUM -- JSON schema is reasonable but untested against downstream Phase 5/6 consumers

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (Playwright MCP is stable, unlikely to change significantly)
