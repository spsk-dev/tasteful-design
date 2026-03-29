# Stack Research: v1.1.0 Flow Audit Additions

**Domain:** SPA flow navigation, screenshot capture, HTML report generation, animation detection
**Researched:** 2026-03-28
**Confidence:** HIGH

## Context

This is an **additive research** for the v1.1.0 milestone. The existing plugin stack (markdown commands, JSON configs, bash scripts, Playwright CLI for screenshots) is validated and unchanged. This document covers ONLY the new capabilities needed for `/design-audit`.

## Recommended Stack Additions

### Core: Playwright MCP Server (SPA Flow Navigation)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@playwright/mcp` | latest | SPA flow navigation via MCP tools | Official Microsoft MCP server. Gives Claude persistent browser state, click/navigate/snapshot tools without writing throwaway scripts. Already used conceptually in `/design-validate`. |

**Install:**
```bash
claude mcp add playwright -- npx @playwright/mcp@latest
```

**Why Playwright MCP over Playwright CLI (`npx playwright screenshot`):**

The existing `/design-review` uses `npx playwright screenshot <url>` for static captures. For flow audit, we need **stateful multi-step navigation** -- click a button, wait for route change, screenshot the new state, click again, etc. The CLI approach would require writing a temporary `.mjs` script for every flow, which is fragile, hard to debug, and wastes tokens generating boilerplate.

Playwright MCP exposes individual tools (`browser_navigate`, `browser_click`, `browser_snapshot`, `browser_take_screenshot`, `browser_wait_for`, `browser_evaluate`) that Claude calls sequentially. The browser stays open between calls. This is the correct architecture for SPA flow navigation.

**Key tools for flow audit:**

| MCP Tool | Use in Flow Audit |
|----------|-------------------|
| `browser_navigate` | Initial page load |
| `browser_snapshot` | Accessibility tree for element discovery (find buttons, links, nav items) |
| `browser_click` | Navigate SPA by clicking route triggers |
| `browser_wait_for` | Wait for route transitions to complete |
| `browser_take_screenshot` | Capture each screen state as PNG |
| `browser_evaluate` | Run JS for animation detection, CSS analysis |
| `browser_console_messages` | Catch JS errors during navigation |
| `browser_tabs` | Manage browser session |
| `browser_close` | Cleanup |

**What we do NOT need from Playwright MCP:**
- Network mocking tools (browser_route, browser_unroute) -- not auditing network behavior
- Storage tools (cookies, localStorage) -- not testing auth flows in v1.1
- DevTools tracing/video -- not recording traces
- Coordinate-based mouse tools -- use accessibility-based clicks instead
- Testing/assertion tools -- we do our own scoring

### Screenshot Strategy: Base64 Inline in HTML Report

| Approach | Decision | Why |
|----------|----------|-----|
| **Base64 data URIs** | YES -- use this | Single self-contained HTML file. No external dependencies, no broken image links, works when opened from any location. Users can email, upload, or archive the report as one file. |
| File path references | NO | Breaks when moved, requires serving from correct directory, unusable as email attachment |
| Hosted images | NO | Requires upload service, adds network dependency, privacy concerns for unreleased designs |

**Implementation:** Screenshot PNGs from Playwright MCP -> read as binary -> base64 encode -> embed as `<img src="data:image/png;base64,{encoded}">` in report HTML.

**Size tradeoff:** Base64 adds ~33% overhead. A typical flow audit with 5 screens x 3 viewports = 15 screenshots. At ~200KB each compressed, that is ~4MB raw, ~5.3MB base64. Acceptable for a diagnostic report. If reports grow beyond 10MB, add a `--external-images` flag later -- but do not pre-optimize.

```bash
# In a shell script, encoding is trivial:
base64 < screenshot.png  # macOS
base64 -w 0 screenshot.png  # Linux (no line breaks)
```

### HTML Report: Template String in Shell Script

| Approach | Decision | Why |
|----------|----------|-----|
| **Bash heredoc template** | YES -- use this | Zero dependencies. A `generate-report.sh` script that takes a JSON manifest and screenshots directory, outputs a self-contained `.html` file. Matches the plugin's "no runtime" philosophy. |
| Node.js template engine (Handlebars, EJS) | NO | Adds `node_modules`, requires npm install. Violates the plugin's zero-dependency principle. |
| Python Jinja2 | NO | Same dependency problem. Python may not be available everywhere. |
| Markdown-to-HTML | NO | Markdown cannot express the visual richness needed (score bars, screenshot grids, expandable sections). |

**Report structure:**

```
generate-report.sh
  Input:  .design-audit/flow-manifest.json  (screens, scores, findings)
          .design-audit/screenshots/*.png
  Output: .design-audit/report.html         (self-contained)
```

The script reads the manifest JSON, loops through screens, base64-encodes each screenshot, and injects them into an HTML template with inline CSS. The HTML uses:
- CSS Grid for screenshot comparison layouts
- `<details>` elements for expandable specialist findings
- Inline SVG for score visualizations (progress bars)
- `@media print` styles for PDF export via browser print
- Dark/light mode via `prefers-color-scheme`

**Why not Claude-generated HTML:** The report must be deterministic and consistently formatted. Claude generating HTML on every run means inconsistent layouts, forgotten styles, and wasted tokens. A template script is cheaper, faster, and reproducible.

### Animation/Transition Detection: page.evaluate with Web Animations API

| Technology | Purpose | Why |
|------------|---------|-----|
| `Element.getAnimations()` | Detect active CSS animations and transitions on any element | Web standard (Web Animations API). Works in all Chromium browsers. Returns animation objects with timing, duration, playState. |
| `getComputedStyle()` | Read CSS transition/animation properties from stylesheets | Standard DOM API. Detects declared (not necessarily running) animation properties. |
| CSS `transition` / `animation` property parsing | Catalog what elements HAVE animation declarations | Static analysis of computed styles reveals design intent even when animations are not currently playing. |

**Detection approach (run via `browser_evaluate`):**

```javascript
// 1. Find all elements with animation/transition declarations
const allElements = document.querySelectorAll('*');
const animated = [];
for (const el of allElements) {
  const style = getComputedStyle(el);
  const transition = style.transition;
  const animation = style.animationName;
  const hasTransition = transition && transition !== 'all 0s ease 0s' && transition !== 'none';
  const hasAnimation = animation && animation !== 'none';
  if (hasTransition || hasAnimation) {
    animated.push({
      selector: el.tagName + (el.id ? '#' + el.id : '') + (el.className ? '.' + el.className.split(' ')[0] : ''),
      transition: hasTransition ? transition : null,
      animation: hasAnimation ? animation : null,
      duration: style.animationDuration || style.transitionDuration
    });
  }
}

// 2. Check for actively running animations
const running = document.getAnimations().map(a => ({
  name: a.animationName || 'transition',
  duration: a.effect?.getTiming()?.duration,
  playState: a.playState,
  target: a.effect?.target?.tagName
}));

return { declared: animated, running };
```

**Between-screen detection:** After each navigation step, run this detection. Compare the animation inventory between screens to identify:
- Shared transitions (page-level route animations)
- Screen-specific animations (loading spinners, entrance effects)
- Missing animations (screens that feel "dead" compared to others)

**No external library needed.** The Web Animations API and `getComputedStyle` are built into Chromium. Playwright's `browser_evaluate` runs arbitrary JS in the page context.

## Supporting Scripts

### New Files for v1.1.0

| File | Type | Purpose |
|------|------|---------|
| `commands/design-audit.md` | Command | `/design-audit` slash command -- flow navigation orchestrator |
| `scripts/generate-report.sh` | Bash | HTML report generator (template + base64 embedding) |
| `scripts/detect-animations.js` | JS snippet | Animation detection code (injected via browser_evaluate) |
| `config/report-template.html` | HTML | Report template with CSS (referenced by generate-report.sh) |
| `skills/design-review/references/flow-audit.md` | Reference | Flow audit domain knowledge for specialists |

### Existing Files Modified

| File | Change |
|------|--------|
| `commands/design.md` | Add `/design audit` route |
| `config/scoring.json` | Add flow-level scoring (cross-screen consistency weight) |

## What NOT to Add

| Avoid | Why | What to Do Instead |
|-------|-----|-------------------|
| Puppeteer | Playwright is already the standard here and in the plugin. Adding a second browser automation tool is confusion, not value. | Playwright MCP |
| Cypress | E2E testing framework, not a browser automation tool for agent use. No MCP integration. | Playwright MCP |
| `playwright-report` (built-in HTML reporter) | Designed for test results, not design audits. Wrong data model (pass/fail assertions vs. specialist scores). | Custom `generate-report.sh` |
| React/Vue for the report | The report is a static artifact, not an app. Adding a JS framework to render a report is absurd over-engineering. | Plain HTML + inline CSS |
| `juice` or CSS inliner libraries | Only needed for email HTML. Browser-opened HTML files read `<style>` tags fine. | Inline `<style>` block in the template |
| `sharp` or image processing | Screenshots are already PNGs from Playwright. No resizing/cropping needed. Base64 encoding is built into `base64` CLI. | `base64` command |
| npm dependencies of any kind | The plugin has zero npm dependencies today. Adding any for report generation breaks the "no runtime" principle that makes it installable by file copy. | Shell scripts + built-in browser APIs |
| `chart.js` or charting libraries | Score visualizations are simple progress bars. CSS can do this. Adding a JS charting library to a static report is overkill. | CSS `width` percentage bars or inline SVG `<rect>` |
| Playwright test runner (`@playwright/test`) | We are not running tests. We are using Playwright as a browser automation layer. The test runner adds assertions, fixtures, and reporting we do not need. | `@playwright/mcp` for MCP tools, `npx playwright screenshot` for CLI fallback |

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|-------------------------|
| Browser automation | Playwright MCP | Temp `.mjs` scripts via Bash | If MCP server is unavailable (user has not run `claude mcp add`). The command should detect MCP availability and fall back to script generation. |
| Screenshot format | PNG (Playwright default) | JPEG | If report size becomes a problem. JPEG is ~60% smaller but lossy. Add `--jpeg` flag if needed later. |
| Report format | Self-contained HTML | Markdown | If user prefers text-only output. Add `--markdown` flag that outputs to terminal like existing `/design-review`. HTML is the default because screenshots cannot be shown in markdown terminal output. |
| Animation detection | Web Animations API via evaluate | Source code static analysis | Always do both. Static analysis catches CSS declarations in source files. Runtime detection catches dynamically applied animations. The command should run browser_evaluate AND read source files. |

## Version Compatibility

| Component | Requires | Notes |
|-----------|----------|-------|
| `@playwright/mcp` | Node.js 18+ | Uses `npx`, no global install needed |
| Playwright browsers | Chromium (auto-installed by MCP) | `npx playwright install chromium` as fallback |
| `Element.getAnimations()` | Chromium 84+ | Standard API, no polyfill needed |
| `document.getAnimations()` | Chromium 84+ | Returns all page animations |
| Base64 CLI | macOS `base64` or Linux `base64` | Different flags: macOS has no `-w`, Linux needs `-w 0` |
| HTML `<details>` element | All modern browsers | Used for expandable specialist sections in report |

## Playwright MCP vs CLI Decision Matrix

| Scenario | Use MCP | Use CLI |
|----------|---------|---------|
| Multi-step SPA flow navigation | YES | No (stateless) |
| Single static page screenshot | Either | YES (simpler) |
| Clicking buttons, filling forms | YES | No (requires script) |
| Waiting for route transitions | YES | No (requires script) |
| Animation detection via evaluate | YES | Possible but clunky |
| Existing `/design-review` screenshots | Keep CLI | Not needed |

**Recommendation:** `/design-audit` uses Playwright MCP as primary, with CLI script fallback. Existing `/design-review` keeps using CLI (`npx playwright screenshot`) -- no changes needed there.

## Installation for Users

No new npm install needed. Users who already have Playwright (required for `/design-review`) just need to register the MCP server once:

```bash
# One-time setup (add to /design init wizard or README)
claude mcp add playwright -- npx @playwright/mcp@latest
```

If MCP is not registered, the `/design-audit` command detects this and either:
1. Offers to register it automatically (`claude mcp add ...`)
2. Falls back to generating a temporary Playwright script

## Sources

- [Playwright MCP GitHub](https://github.com/microsoft/playwright-mcp) -- Official repo, tool list, install instructions (HIGH confidence)
- [Playwright Screenshots docs](https://playwright.dev/docs/screenshots) -- Screenshot API reference (HIGH confidence)
- [Playwright Page API](https://playwright.dev/docs/api/class-page) -- page.evaluate, navigation (HIGH confidence)
- [Web Animations API - getAnimations()](https://developer.mozilla.org/en-US/docs/Web/API/Element/getAnimations) -- Standard API for animation detection (HIGH confidence)
- [Automating Animation Testing with Playwright](https://www.thegreenreport.blog/articles/automating-animation-testing-with-playwright-a-practical-guide/automating-animation-testing-with-playwright-a-practical-guide.html) -- Practical animation detection patterns (MEDIUM confidence)
- [Base64 encoding images in Node.js](https://www.fourkitchens.com/blog/article/base64-encoding-images-nodejs/) -- Data URI approach for embedded images (HIGH confidence)
- [Simon Willison on Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) -- Real-world usage patterns (MEDIUM confidence)

---
*Stack research for: v1.1.0 Flow Audit milestone*
*Researched: 2026-03-28*
