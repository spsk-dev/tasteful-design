# SpSk -- Design Review Plugin

AI-powered design review using 7 independent specialist agents. Each specialist evaluates one domain (typography, color, layout, icons, motion, intent/originality/UX/copy, code/accessibility) against curated reference knowledge. A boss synthesizer merges findings with cross-specialist confidence scoring and delivers a weighted SHIP/BLOCK verdict.

## Available Commands

### `/design` -- Orchestrator

Routes to the right sub-command based on arguments.

```bash
/design                    # Show available commands
/design review             # Full visual review
/design review --quick     # Quick review (4 specialists)
/design validate           # Functional validation
/design improve "prompt"   # Build and iterate until SHIP
/design check              # Review + validate (pre-merge)
/design ship "prompt"      # Full pipeline: improve -> review -> validate
```

All flags pass through to sub-commands: `--ref`, `--figma`, `--direction`, `--palette`, `--fonts`, `--quick`, `--max N`, `--validate`, `--style`, `--interact`.

### `/design-review` -- Visual Design Review

Full 7-specialist review with weighted scoring and SHIP/CONDITIONAL/BLOCK verdict. Supports `--interact` for hover/focus/scroll state capture.

```bash
/design-review                              # Review current page (auto-detects dev server)
/design-review http://localhost:3000/page   # Review specific URL
/design-review --quick                      # 4 specialists instead of 8 (~40% fewer tokens)
/design-review --ref https://stripe.com     # Compare against a reference site
/design-review --ref ./design-spec.md       # Compare against a design spec file
/design-review --figma https://figma.com/design/abc/...          # Review a Figma design
/design-review --figma https://figma.com/design/abc/... --compare # Check implementation vs Figma
/design-review --direction "warm, playful"  # Evaluate against a creative brief
/design-review --palette "#1a1a2e,#f5f0eb"  # Enforce specific color palette
/design-review --fonts "DM Sans,Instrument Serif"  # Enforce specific fonts
/design-review --style serious-dashboard    # Apply a style preset
/design-review --interact                  # Capture hover/focus/scroll states before review
/design-review --interact --quick           # Quick review with interaction capture
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Run 4 core specialists instead of 7. Uses `/13` weights instead of `/16`. Saves ~40% tokens. |
| `--ref <url\|file\|figma>` | Compare against a reference instead of generic gold standards |
| `--figma <url>` | Review a Figma design before building. Add `--compare` to check implementation fidelity |
| `--direction "<text>"` | Evaluate against a text creative brief |
| `--palette "<colors>"` | Override color evaluation with specific palette |
| `--fonts "<fonts>"` | Override font evaluation with specific fonts |
| `--style <preset>` | Apply a style preset (see Configuration) |
| `--interact` | Capture hover/focus/scroll states via Playwright MCP before specialist review. Opt-in. |

**Output:** Scores per specialist, cross-specialist consensus findings, weighted verdict, prioritized fix list with file:line references.

**Duration:** ~8-10 min full, ~5 min quick.

### `/design-improve` -- Iterative Build and Fix Loop

Builds or takes a page, reviews it, applies fixes, re-reviews until SHIP or max iterations.

```bash
/design-improve "Build a landing page"                  # Build from scratch and iterate
/design-improve --ref https://splice.com "music page"   # Build to match a reference
/design-improve --max 5 "admin panel"                   # Up to 5 iterations (default 3)
/design-improve --quick "dashboard"                     # Quick mode for intermediate reviews
/design-improve --validate "billing page"               # Run functional validation each iteration
/design-improve --style animation-heavy "landing page"  # Apply style preset to build + review
/design-improve --palette "#faf5f0,#8b6f47" --fonts "Newsreader,Figtree" "mothers day page"
```

**How it works:**
1. Build the page (or receive existing page)
2. Run `/design-review`
3. If BLOCK: apply top 3 fixes from the fix list
4. Re-review (only re-runs failing specialists)
5. Repeat until SHIP or max iterations

Re-reviews only re-run specialists that scored <=2. Passing specialists keep their scores. Each iteration targets different issues.

### `/design-validate` -- Functional Validation

Clicks every button, fills every form, navigates every link, checks console for JS errors. Reports broken, unreachable, or incomplete functionality.

```bash
/design-validate                              # Validate current page
/design-validate http://localhost:3000/page   # Validate specific URL
```

**What it checks:**
- Links: dead links, placeholder hrefs, broken navigation
- Buttons: click handlers, visible state changes
- Forms: fillable inputs, submit behavior
- Interactive elements: tabs, toggles, modals, dropdowns
- Console errors and network failures
- Mobile touch targets (44px minimum)
- Loading, empty, error, and success states

**Requires:** Playwright (`npx playwright install chromium`)

## Configuration

### `config/scoring.json`

Controls specialist weights and page-type thresholds.

- `weights`: how much each specialist affects the final score (Intent: 3x, Typography: 2x, Icons: 1x, etc.)
- `thresholds`: minimum score to SHIP by page type (admin: 2.5, landing: 3.0, portfolio: 3.5)
- `verdict_rules`: SHIP/CONDITIONAL/BLOCK logic
- `scale`: scoring range (1.0 to 4.0)

### `config/anti-slop.json`

Banned fonts, palettes, and AI patterns. The `/design-improve` command reads this during build phase to avoid common AI output patterns.

- `banned_fonts`: fonts flagged on sight (Dancing Script, Playfair Display, Poppins, etc.)
- `recommended_fonts`: good alternatives by category (sans, serif, mono, display)
- `banned_palettes`: cliche color combinations (synthwave, dark+gold, gray-everything)
- `banned_patterns`: layout anti-patterns (emoji-as-icons, three-column-icon-grid)
- `required_accessibility`: a11y requirements checked in every review

Edit this file to add project-specific rules.

### `config/style-presets.json`

5 built-in style presets that set the design direction for all reviews and builds:

| Preset | Vibe | References |
|--------|------|-----------|
| `serious-dashboard` | Data-dense, functional | Linear, Grafana, Vercel |
| `fun-lighthearted` | Playful, warm, personality | Notion, Figma, Slack |
| `animation-heavy` | Cinematic, immersive | Apple, Stripe, Vercel |
| `minimal-editorial` | Typography-driven, quiet | Medium, iA Writer |
| `startup-landing` | Bold, conversion-focused | Vercel, Linear, Raycast |

Set `"active_preset": "serious-dashboard"` to apply globally, or use `--style <name>` per command. Add custom presets by editing the JSON.

## Degradation Behavior

The plugin adapts to available tools:

- **Tier 1** (Gemini + Playwright): Best quality. Color and Layout use Gemini for cross-model diversity.
- **Tier 2** (Playwright only): Claude handles all specialists. Works well but has correlated blind spots.
- **Tier 3** (No Playwright): Code-only analysis. Warns user that visual review is impossible. Recommends `npx playwright install chromium`.

Gemini rate limits are handled with retry + fallback. The tier is always reported in review output.

## Quick Mode

`--quick` runs 4 core specialists instead of 7:
- Font, Color, Layout, Intent/Originality/UX
- Skips: Icon, Motion, Code/A11y
- Uses `/13` weight divisor instead of `/16`
- Saves ~40-50% tokens
- Best for: iterative fix cycles where you want fast feedback

Use full mode for final reviews before shipping.

<!-- GSD:project-start source:PROJECT.md -->
## Project

**SpSk (Simple Skill)**

A GitHub portfolio project that publishes Felipe Machado's most polished AI agent skills as open-source Claude Code plugins. Design-review is the flagship skill (7 specialist agents, 9 scored dimensions, 8.6/10 consensus score). The repo serves as a professional showcase demonstrating deep understanding of AI agent architectures, harnesses, and their practical value for developers.

**Core Value:** The published skills must be immediately useful to other developers AND demonstrate architectural sophistication — the tool is the proof, the architecture is the CV.

### Constraints

- **Distribution**: Claude Code plugin registry as primary (`claude /install-plugin tasteful-design@spsk-dev/tasteful-design`) + install.sh for manual
- **Branding**: Clean and compact, NOT big ASCII art. Signature line format: ` SpSk  design-review  v1.2.0  ---  7 specialists  ·  tier 1`
- **Init wizard**: Exactly 5 questions with opinionated defaults (page type, vibe preset, light/dark, brand colors, font preference)
- **Quality bar**: Must show what DIDN'T work in CHANGELOG (v1 single-agent scored 40%) — transparency builds credibility
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Context
## Recommended Stack Additions
### Core: Playwright MCP Server (SPA Flow Navigation)
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@playwright/mcp` | latest | SPA flow navigation via MCP tools | Official Microsoft MCP server. Gives Claude persistent browser state, click/navigate/snapshot tools without writing throwaway scripts. Already used conceptually in `/design-validate`. |
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
# In a shell script, encoding is trivial:
### HTML Report: Template String in Shell Script
| Approach | Decision | Why |
|----------|----------|-----|
| **Bash heredoc template** | YES -- use this | Zero dependencies. A `generate-report.sh` script that takes a JSON manifest and screenshots directory, outputs a self-contained `.html` file. Matches the plugin's "no runtime" philosophy. |
| Node.js template engine (Handlebars, EJS) | NO | Adds `node_modules`, requires npm install. Violates the plugin's zero-dependency principle. |
| Python Jinja2 | NO | Same dependency problem. Python may not be available everywhere. |
| Markdown-to-HTML | NO | Markdown cannot express the visual richness needed (score bars, screenshot grids, expandable sections). |
- CSS Grid for screenshot comparison layouts
- `<details>` elements for expandable specialist findings
- Inline SVG for score visualizations (progress bars)
- `@media print` styles for PDF export via browser print
- Dark/light mode via `prefers-color-scheme`
### Animation/Transition Detection: page.evaluate with Web Animations API
| Technology | Purpose | Why |
|------------|---------|-----|
| `Element.getAnimations()` | Detect active CSS animations and transitions on any element | Web standard (Web Animations API). Works in all Chromium browsers. Returns animation objects with timing, duration, playState. |
| `getComputedStyle()` | Read CSS transition/animation properties from stylesheets | Standard DOM API. Detects declared (not necessarily running) animation properties. |
| CSS `transition` / `animation` property parsing | Catalog what elements HAVE animation declarations | Static analysis of computed styles reveals design intent even when animations are not currently playing. |
- Shared transitions (page-level route animations)
- Screen-specific animations (loading spinners, entrance effects)
- Missing animations (screens that feel "dead" compared to others)
## Supporting Scripts
### New Files for v1.1.0
| File | Type | Purpose |
|------|------|---------|
| `commands/design-audit.md` | Command | `/design-audit` slash command -- flow navigation orchestrator |
| `scripts/generate-report.sh` | Bash | HTML report generator (template + base64 embedding) |
| `skills/design-review/references/flow.md` | Reference | Flow navigation domain knowledge for specialists |
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
## Installation for Users
# One-time setup (add to /design init wizard or README)
## Sources
- [Playwright MCP GitHub](https://github.com/microsoft/playwright-mcp) -- Official repo, tool list, install instructions (HIGH confidence)
- [Playwright Screenshots docs](https://playwright.dev/docs/screenshots) -- Screenshot API reference (HIGH confidence)
- [Playwright Page API](https://playwright.dev/docs/api/class-page) -- page.evaluate, navigation (HIGH confidence)
- [Web Animations API - getAnimations()](https://developer.mozilla.org/en-US/docs/Web/API/Element/getAnimations) -- Standard API for animation detection (HIGH confidence)
- [Automating Animation Testing with Playwright](https://www.thegreenreport.blog/articles/automating-animation-testing-with-playwright-a-practical-guide/automating-animation-testing-with-playwright-a-practical-guide.html) -- Practical animation detection patterns (MEDIUM confidence)
- [Base64 encoding images in Node.js](https://www.fourkitchens.com/blog/article/base64-encoding-images-nodejs/) -- Data URI approach for embedded images (HIGH confidence)
- [Simon Willison on Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) -- Real-world usage patterns (MEDIUM confidence)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
