# Feature Landscape: Flow-Level Design Audit

**Domain:** SPA flow navigation with per-screen multi-agent design review
**Researched:** 2026-03-28
**Milestone:** v1.1.0 Flow Audit + Polish

## Table Stakes

Features users expect from a flow audit tool. Missing = the tool feels like a gimmick, not a real flow auditor.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Intent-driven navigation | User describes the flow goal ("sign up for a trial"), agent figures out what to click | Med | Core differentiator over manual screenshot tools. Playwright MCP or scripted clicks. Without this, user has to manually list every URL/action. |
| Per-screen screenshots | Capture desktop + mobile at each step in the flow | Low | Reuse existing Phase 0 screenshot logic from `/design-review`. 3 viewports per screen (desktop, mobile, fold). |
| Per-screen specialist review | Run the 8-specialist swarm on each screen independently | Med | This IS the product. Each screen gets its own PAGE_BRIEF, scores, and verdict. Quick mode (`--quick`) for intermediate screens, full mode for key screens. |
| Cross-screen consistency report | Flag when typography, colors, spacing, or component patterns change between screens | High | The single biggest thing a per-page review misses. Same button styled differently on screen 3 vs screen 1 = broken experience. Must compare tokens/patterns across all captured screens. |
| Flow-level summary with per-screen scores | One report showing the whole flow: screen names, scores, verdict, and overall flow score | Med | Users need the forest AND the trees. Per-screen detail is noise without a summary. Overall flow score = weighted average of screen scores. |
| HTML diagnostic report | Standalone HTML file with embedded screenshots, scores, and fix recommendations | High | Terminal output alone does not cut it for flow audits with 5+ screens. Need a shareable, scrollable artifact. Inline base64 images so the file is self-contained. |
| Explicit flow definition | `--flow "description"` flag to tell the agent what journey to walk | Low | Without this, the agent guesses. Bad guesses poison everything. The flow description drives navigation decisions AND sets per-screen intent context. |
| Screen naming and ordering | Each screen labeled with a meaningful name and step number | Low | "Step 3: Payment form" not "screenshot-003.png". Names come from intent extraction (Phase 1 per screen) or from the navigation action that led there. |

## Differentiators

Features that elevate this from "screenshots with scores" to a portfolio-quality tool.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Transition/animation CSS analysis | Detect and evaluate CSS transitions, View Transitions API usage, and animation quality between screen states | Med | Motion specialist already reviews per-page animation code. Extend to detect: (1) transitions triggered by navigation, (2) View Transitions API usage, (3) missing transitions where expected (e.g., modal open with no animation). Source-code analysis, not runtime capture. |
| Consistency deviation heatmap | Visual indicator in HTML report showing which screens deviate from established patterns | High | Makes the cross-screen consistency check tangible. "Screen 4 uses 14px body text while screens 1-3 use 16px" with visual annotation. Color-coded severity. |
| Flow friction detection | Identify UX bottlenecks: dead ends, unclear next steps, missing back navigation, broken breadcrumbs | Med | UX specialist (#6) already evaluates single-page flow. Extend to cross-screen: does each screen's "next step" actually lead where it claims? Are there dead ends? Is back-navigation possible? |
| Smart screen importance weighting | Entry screen and conversion screen get full 8-specialist review; intermediate screens get quick mode automatically | Low | Saves tokens (5-screen flow with full review on all = 400K+ tokens). Auto-classify: first screen = entry (full), last screen = conversion (full), middle = navigation (quick). User can override. |
| Before/after flow comparison | Run audit, make fixes, re-run. Show per-screen score deltas across the whole flow | Med | Score progression already exists for single-page re-review. Extend to flow level: "Screen 2 improved from 2.1 to 3.2, Screen 4 regressed from 3.0 to 2.8". |
| Flow diagram in report | ASCII or SVG flow diagram showing screen sequence with pass/fail indicators | Med | `[Login] ---> [Dashboard] ---> [Settings] ---> [Billing]` with color-coded scores beneath each node. Makes the report scannable. |
| Branded HTML report | SpSk branding in the HTML output: signature line, Unicode symbols, progress bars, footer | Low | Extends existing branded terminal output to HTML. Consistent visual identity across CLI and report artifacts. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Runtime animation capture (video/GIF) | Massively complex. Requires headless browser video recording, frame analysis, and temporal comparison. Way beyond scope. | Analyze CSS/JS source for transition declarations. Flag missing `transition` properties, bad easing, no `prefers-reduced-motion`. Source analysis is 90% of the value at 10% of the cost. |
| Automated flow discovery | "Crawl the app and find all flows" sounds amazing but produces noise. Which flows matter? How deep to go? When to stop? | User provides the flow intent. Agent navigates that specific flow. Explicit is better than magic. |
| Real user analytics integration | Connecting to Hotjar/FullStory/Mixpanel to find real friction points | Out of scope. This is a developer tool for design quality, not a product analytics platform. The user knows their flows. |
| Cross-browser visual testing | Comparing renders across Chrome/Firefox/Safari | Playwright supports multiple browsers but the design review is about design quality, not browser compatibility. Use dedicated visual regression tools (Chromatic, Percy) for that. |
| Interactive HTML report | Filters, toggles, JavaScript-driven UI in the report | YAGNI. Static HTML with anchor links and a TOC is sufficient. Interactive reports need maintenance, testing, and add no design-review value. |
| PDF export | Adds a rendering dependency (puppeteer/wkhtmltopdf) for marginal value | HTML opens in any browser. Users can Cmd+P to PDF if they want. |
| Parallel multi-flow audit | "Audit the signup flow AND the checkout flow at once" | Audit one flow at a time. User can run twice. Parallel flows multiply complexity (shared state, navigation conflicts) without proportional value. |
| Screenshot diffing between screens | Pixel-level comparison between screen states | This is visual regression testing, not design review. The specialists compare design quality, not pixel differences. |

## Feature Dependencies

```
Existing /design-review (v1.0.0)
  |
  +-- Per-screen specialist dispatch (reuses Phase 1-3 per screen)
  |     +-- Screenshot capture (reuses Phase 0)
  |     +-- PAGE_BRIEF extraction (reuses Phase 1)
  |     +-- 8 specialists in parallel (reuses Phase 2)
  |     +-- Boss synthesis (reuses Phase 3)
  |
  +-- /design-audit (NEW command)
        |
        +-- Flow intent parsing (--flow flag)
        |     +-- Drives navigation decisions
        |     +-- Sets per-screen context
        |
        +-- SPA navigation engine
        |     +-- Playwright click-through or URL sequence
        |     +-- Wait-for-stable strategies (not networkidle)
        |     +-- Screen boundary detection
        |
        +-- Cross-screen consistency analysis (NEW)
        |     +-- Compares tokens/patterns across all screens
        |     +-- Feeds into per-screen specialist prompts
        |     +-- Requires all screens captured first
        |
        +-- Flow-level summary + scoring (NEW)
        |     +-- Aggregates per-screen scores
        |     +-- Identifies weakest screen
        |     +-- Overall flow verdict
        |
        +-- HTML report generator (NEW)
        |     +-- Embeds screenshots (base64)
        |     +-- Per-screen score tables
        |     +-- Cross-screen findings
        |     +-- Flow diagram
        |     +-- SpSk branding
        |
        +-- Transition/animation analysis (extends Motion specialist)
              +-- Detects navigation-triggered transitions
              +-- View Transitions API usage
              +-- Cross-screen motion continuity
```

## Flow Navigation Patterns

Based on research, three patterns for navigating SPA flows:

### Pattern 1: Intent-Driven (Recommended)
User provides a goal: `--flow "Complete the signup flow from landing page to dashboard"`. Agent uses Playwright MCP to interact with the page — clicking buttons, filling forms, following the natural path. Screenshots captured at each "stable state" (new route, modal open, significant DOM change).

**Pros:** Most natural, matches how users think about flows.
**Cons:** Non-deterministic. Agent might take a wrong path. Need retry/correction logic.

### Pattern 2: URL Sequence
User provides explicit URLs: `--screens "/login,/signup,/onboarding,/dashboard"`. Agent navigates to each URL directly.

**Pros:** Deterministic, reproducible. Good for known flows.
**Cons:** Misses transitions between screens. Does not test real navigation paths. SPAs with dynamic routes may not have stable URLs for every state.

### Pattern 3: Action Script
User provides a sequence of actions: `--steps "click Sign Up, fill email, click Next, select plan, click Continue"`. Agent executes each step and captures screenshots.

**Pros:** Reproducible AND captures transitions. Middle ground.
**Cons:** Brittle if UI changes. User needs to know exact button labels.

**Recommendation:** Support Pattern 1 as primary (most impressive for portfolio, most useful in practice). Support Pattern 2 as fallback for deterministic flows. Skip Pattern 3 — it is the worst of both worlds (manual like Pattern 2, fragile like Pattern 1).

## Report Format Expectations

Based on research into UX audit report formats:

### Structure (layered information)
1. **Executive summary** — Flow name, overall score, verdict, screen count, one-line per screen
2. **Flow diagram** — Visual screen sequence with scores
3. **Per-screen detail** — Expandable sections with full specialist scores, screenshots, findings
4. **Cross-screen findings** — Consistency issues, flow friction, transition analysis
5. **Fix list** — Prioritized, actionable, with screen + specialist attribution

### Report must be:
- **Self-contained** — Single HTML file, no external dependencies, base64-encoded images
- **Shareable** — Meaningful without the terminal session that generated it
- **Scannable** — Executive summary for managers, detail for developers
- **Branded** — SpSk signature, consistent with terminal output identity

## Animation/Transition Assessment Scope

What the Motion specialist should evaluate for flow-level audits:

### In Scope (source code analysis)
| Check | How | Why |
|-------|-----|-----|
| CSS `transition` declarations on interactive elements | Parse stylesheets for `transition:` properties | Buttons, links, form elements should have hover/focus transitions |
| View Transitions API usage | Search for `document.startViewTransition` or `view-transition-name` CSS | Modern SPAs should use this for page-level transitions |
| `prefers-reduced-motion` support | Search for `@media (prefers-reduced-motion)` | Mandatory accessibility requirement for any animation |
| Animation duration ranges | Parse `transition-duration` and `animation-duration` values | 150-300ms for micro-interactions, 300-500ms for layout changes, >500ms = sluggish |
| Easing function quality | Check for `linear` vs `ease-in-out` / `cubic-bezier` | `linear` feels robotic on UI elements |
| Loading/skeleton states | Search for loading indicators, skeleton screens between navigations | Flow transitions without feedback feel broken |
| Route transition patterns | Check for page-level transition wrappers (Framer Motion, Vue transitions, Svelte transitions) | Framework-specific patterns for SPA navigation animation |

### Out of Scope (would require runtime capture)
| Check | Why Skip |
|-------|----------|
| Actual rendered animation smoothness | Requires video capture + frame analysis |
| Animation jank / frame drops | Requires Chrome Performance API integration |
| Animation timing in context | 300ms might feel right or wrong depending on content |
| Interaction-triggered animations | Cannot trigger clicks from source analysis alone |

## MVP Recommendation

Build in this order:

1. **SPA navigation engine** — Playwright-based click-through with intent-driven navigation. This is the foundation everything else depends on.
2. **Per-screen specialist review** — Reuse existing 8-specialist swarm per screen with smart importance weighting (full on entry/exit, quick on middle screens).
3. **Cross-screen consistency check** — New analysis pass comparing design tokens and patterns across all captured screens. Feed findings into per-screen reports AND a dedicated consistency section.
4. **Flow-level summary** — Aggregate scores, identify weakest screen, compute flow verdict.
5. **HTML report generator** — Self-contained HTML with embedded screenshots, per-screen scores, cross-screen findings, flow diagram, and fix list.
6. **Transition/animation analysis** — Extend Motion specialist to evaluate cross-screen transitions.

Defer:
- **Before/after flow comparison**: Nice to have, build after core flow audit works. Can reuse existing score-progression tracking from `/design-review`.
- **Consistency deviation heatmap**: Visual complexity for the HTML report. Start with a text-based consistency section, add visual annotations later.
- **Demo GIF**: Record after the feature is polished and stable.

## Sources

- Direct inspection of `~/.claude/plugins/design-review/commands/` (4 command files, v1.0.0)
- `.context/design-review-status.md` (specialist roster, scoring formula, benchmark results)
- [Lighthouse User Flows](https://web.dev/lighthouse-user-flows/) — Multi-mode page audit (navigation, snapshot, timespan)
- [Playwright Navigation](https://playwright.dev/docs/navigations) — SPA navigation handling, wait strategies
- [Playwright Visual Testing](https://playwright.dev/docs/test-snapshots) — Screenshot capture patterns
- [Playwright MCP for Documentation Screenshots](https://dev.to/debs_obrien/automate-your-screenshot-documentation-with-playwright-mcp-3gk4) — AI-driven screenshot workflows
- [CSS View Transitions Guide](https://devtoolbox.dedyn.io/blog/css-view-transitions-complete-guide) — View Transitions API for SPA animations
- [Chrome DevTools Animation Inspection](https://developer.chrome.com/docs/devtools/css/animations) — CSS transition/animation debugging capabilities
- [UX Audit Report Best Practices](https://www.eleken.co/blog-posts/top-three-ux-audit-report-examples-and-how-to-pick-the-right-one) — Report structure and layered information
- [Design Consistency in Systems](https://www.uxpin.com/studio/blog/color-consistency-design-systems/) — Cross-screen consistency patterns
- [Soft Navigations API for SPA Auditing](https://salt.agency/blog/why-the-soft-navigations-api-enables-better-spa-core-web-vitals-auditing/) — SPA-aware performance auditing
