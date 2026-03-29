# Domain Pitfalls

**Domain:** SPA Flow Audit — Playwright browser automation, multi-step navigation, HTML report generation
**Researched:** 2026-03-28
**Milestone:** v1.1.0 Flow Audit + Polish

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Using `networkidle` for SPA Navigation Detection

**What goes wrong:** The agent calls `page.waitForLoadState('networkidle')` after triggering a navigation in an SPA. The SPA has analytics pings, WebSocket connections, polling, or SSE streams. Playwright waits for zero network connections for 500ms — which never happens. The entire flow audit hangs until timeout.
**Why it happens:** `networkidle` is the intuitive choice ("wait until the page is done loading") and works for traditional multi-page apps. SPAs have persistent background connections that prevent network idle from ever being reached.
**Consequences:** Flow audit hangs for 30s+ on every screen transition, then fails. Users think the tool is broken. Worse: it works on simple SPAs (no analytics/sockets) and fails on real production apps — inconsistent behavior destroys trust.
**Prevention:** Never use `networkidle` as the primary wait strategy. Instead:
1. Wait for a **specific UI element** that signals the new screen is ready: `await page.waitForSelector('[data-screen="checkout"]')` or `await page.getByRole('heading', { name: /checkout/i }).waitFor()`
2. Wait for a **specific API response** that the screen depends on: `await page.waitForResponse(resp => resp.url().includes('/api/cart'))`
3. Use **`waitForURL()`** when SPA navigation changes the URL (most modern SPAs do): `await page.waitForURL('**/checkout')`
4. As a **fallback heuristic**: wait for DOM stability (no mutations for 500ms) using `waitForFunction` with a MutationObserver pattern
**Detection:** Test against any SPA with Google Analytics, Intercom, or a chat widget. If the flow hangs, you hit this.
**Confidence:** HIGH — [Playwright docs officially discourage networkidle](https://playwright.dev/docs/api/class-page#page-wait-for-load-state), and [GitHub issue #19835](https://github.com/microsoft/playwright/issues/19835) documents infinite waits.

### Pitfall 2: Screenshots Captured Before Visual Readiness

**What goes wrong:** Screenshot is taken the moment Playwright considers the DOM "ready" — but custom fonts haven't loaded, images are still lazy-loading, CSS transitions are mid-animation, or a layout shift hasn't settled. The screenshot shows fallback fonts, missing images, or elements in transit.
**Why it happens:** DOM readiness != visual readiness. Playwright's `page.screenshot()` waits for fonts by default, but this can hang if fonts fail to load (CSP errors, network issues). And it does NOT wait for: CSS animations to complete, lazy-loaded images below the fold, or layout shifts to settle.
**Consequences:** Design specialists review a screenshot that doesn't match what the user sees. Font specialist flags "system font usage" when the real app uses Inter. Layout specialist flags "element overlap" that was a transient layout shift. Reviews are wrong, users lose trust.
**Prevention:**
1. **Font loading**: Use `await page.waitForFunction(() => document.fonts.ready)` with a 5s timeout. If it times out, take screenshot anyway but flag "fonts may not be loaded" in the report.
2. **Animations**: Disable CSS animations for screenshot capture: `await page.addStyleTag({ content: '*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; }' })` — BUT preserve the animation info separately for the Motion specialist.
3. **Layout stability**: Wait for no layout shifts: `await page.waitForFunction(() => { return new Promise(resolve => { new PerformanceObserver((list) => { /* check for CLS entries */ }).observe({ type: 'layout-shift', buffered: true }); setTimeout(resolve, 1000); }); })`
4. **Lazy images**: Scroll the viewport to trigger lazy loading, wait, then scroll back before screenshot. Or use `page.evaluate(() => document.querySelectorAll('img[loading=lazy]').forEach(img => img.loading = 'eager'))`.
**Detection:** Compare a screenshot taken at 100ms vs 3s after navigation. If they differ significantly, your timing is wrong.
**Confidence:** HIGH — [Playwright bug #35972](https://github.com/microsoft/playwright/issues/35972) and [turntrout's 428-day battle with flaky screenshots](https://turntrout.com/playwright-tips) document these issues extensively.

### Pitfall 3: SPA Navigation That Doesn't Trigger Playwright's Navigation Events

**What goes wrong:** User clicks a link or button in a React/Vue/Svelte SPA. The URL changes (via `pushState` or `replaceState`), the content updates, but Playwright's `waitForNavigation()` never resolves because no actual page load occurred. The flow audit either hangs or moves to the next step before the new screen renders.
**Why it happens:** SPAs update the DOM in-place without triggering the browser's navigation lifecycle. Playwright's navigation detection is based on the browser's navigation events (load, DOMContentLoaded), not `pushState`.
**Consequences:** Flow gets stuck on step 1, or races ahead taking screenshots of half-rendered screens. Multi-step flows (onboarding, checkout, wizard) are the core use case — if this breaks, the entire feature is useless.
**Prevention:**
1. **Do NOT use `waitForNavigation()`** for SPA transitions. It's for full page loads only.
2. **Use `waitForURL(pattern)`** — this DOES detect pushState changes: `await page.waitForURL('**/step-2')`
3. **When URL doesn't change** (tab switches, accordion opens, modal flow): wait for the new content element: `await page.waitForSelector('.step-2-content')`
4. **Build a generic "screen changed" detector**: compare the DOM before and after the action. If >30% of visible text changed, the screen transitioned.
**Detection:** Test against a React Router or Next.js app with client-side navigation. If `waitForNavigation` hangs, you have this bug.
**Confidence:** HIGH — [Playwright navigation docs](https://playwright.dev/docs/navigations) explicitly state SPAs don't trigger navigation events.

### Pitfall 4: HTML Report with Embedded Base64 Screenshots Becomes Unusable

**What goes wrong:** Each full-page screenshot is 200-500KB as PNG. Base64 encoding adds 33% overhead. A 10-screen flow audit produces 3-7MB of base64 image data embedded in a single HTML file. The report takes 5+ seconds to open, browsers lag when scrolling, and email/Slack previews break.
**Why it happens:** Embedding base64 is the simplest way to make a self-contained HTML report (no external files to manage). It works fine for 1-2 screenshots but doesn't scale to multi-screen flows.
**Consequences:** Report is technically correct but practically unusable. Users on slower machines or mobile can't open it. If they try to share it (email, Slack), it gets rejected for size. The "diagnostic report" becomes a diagnostic problem.
**Prevention:**
1. **Compress screenshots to JPEG at 80% quality** before embedding — reduces each from ~400KB to ~80KB. Use Playwright's `screenshot({ type: 'jpeg', quality: 80 })`.
2. **Resize to max 1200px width** — full resolution is unnecessary for a diagnostic report. `screenshot({ clip: { ... } })` or resize after capture.
3. **Lazy load images in the HTML**: `<img loading="lazy" src="data:image/jpeg;base64,...">` — browser only decodes images as user scrolls.
4. **Implement a size budget**: if total embedded images > 5MB, switch to a directory-based report (HTML + /screenshots/ folder) and warn the user.
5. **Consider thumbnail + expand pattern**: show small thumbnails inline, click to expand full-size in a modal (all still self-contained HTML + JS).
**Detection:** Generate a report for a 10+ screen flow. Open it. If it takes more than 2s to load or scrolling is janky, the report is too heavy.
**Confidence:** HIGH — [DebugBear documents base64 overhead](https://www.debugbear.com/blog/base64-data-urls-html-css), [bunny.net explains why base64 is almost always bad for large images](https://bunny.net/blog/why-optimizing-your-images-with-base64-is-almost-always-a-bad-idea/).

## Moderate Pitfalls

### Pitfall 5: Flow Description Ambiguity Causes Wrong Navigation Path

**What goes wrong:** User says `--flow "complete the checkout"` but the agent navigates to a different checkout variant (guest vs logged-in), clicks the wrong "Next" button (there are two), or takes a path the user didn't intend.
**Why it happens:** Natural language flow descriptions are ambiguous. The agent must infer which buttons to click, which form fields to fill, and which path to take. Without explicit step-by-step instructions, it guesses.
**Prevention:**
1. **Support both modes**: `--flow "description"` (agent infers) AND `--steps "click Login > fill email > click Next > ..."` (explicit)
2. **Confirm the plan before executing**: agent describes the steps it will take, user approves or corrects
3. **At each step, snapshot and report what was clicked** — even if the path is wrong, the user can see where it diverged
4. **Fall back to step-by-step mode** when ambiguous: "I found 2 'Submit' buttons. Which one?"

### Pitfall 6: Animation Detection That Only Reads CSS Source Code

**What goes wrong:** The Motion specialist reads CSS source files looking for `animation` and `transition` properties. It finds them and reports "animations present." But: (a) the animations may be conditionally applied by JS and never fire on this screen, (b) the CSS may be from a library (Tailwind, Framer Motion) where the actual animation depends on runtime state, (c) CSS-in-JS animations (styled-components, Emotion) won't appear in static CSS files at all.
**Why it happens:** Static code analysis is easier than runtime detection. The existing v1.0.0 Motion specialist only reads source code.
**Prevention:**
1. **Runtime animation detection**: Use Playwright to inject a script that listens for `animationstart`, `animationend`, `transitionstart`, `transitionend` events during the screen transition. Report which elements actually animated and for how long.
2. **Computed style comparison**: Capture `getComputedStyle` snapshots before and after navigation. Diff them to find elements that changed `opacity`, `transform`, `height`, etc.
3. **Performance API**: Use `performance.getEntriesByType('paint')` and the Animation API (`document.getAnimations()`) to detect active animations.
4. **Hybrid approach**: Static analysis for what SHOULD animate + runtime detection for what ACTUALLY animated. Flag discrepancies.
**Confidence:** MEDIUM — runtime detection approach is sound but [Playwright's animation support](https://github.com/microsoft/playwright/issues/4055) is still evolving (no native `waitForAnimation`).

### Pitfall 7: Playwright Browser Not Installed or Wrong Version

**What goes wrong:** User runs `/design-audit` and gets a cryptic error: `browserType.launch: Executable doesn't exist at /path/to/chromium`. Or worse: an old Chromium version that doesn't support modern CSS features, producing screenshots that look different from what the user sees in their browser.
**Why it happens:** Playwright bundles its own Chromium, but `npx playwright install chromium` must be run at least once. Users who install the plugin don't expect to also install a browser. Version mismatches happen when Playwright is updated but browsers aren't re-installed.
**Prevention:**
1. **Check browser availability at flow start**: `const browsers = require('playwright-core').registry; // check installed`
2. **Auto-install with user consent**: "Chromium not found. Run `npx playwright install chromium` (~150MB)? [Y/n]"
3. **Pin Playwright version** in the plugin's package.json or document the expected version
4. **Graceful error message**: "Design audit requires Playwright with Chromium. Run: npx playwright install chromium"
**Detection:** Run on a clean machine without prior Playwright installation.

### Pitfall 8: Flow State Lost on Error Mid-Navigation

**What goes wrong:** The flow audit is on screen 5 of 8 when a Playwright error occurs (element not found, timeout, network error). The entire audit fails with no results. The user waited 2 minutes for nothing.
**Why it happens:** No checkpoint/resume mechanism. Each screen is processed in sequence, and a failure at any point discards all prior work.
**Prevention:**
1. **Write results progressively**: after each screen completes, append to the report. If the flow fails on screen 5, screens 1-4 are already captured.
2. **Error recovery per screen**: if a screen fails, log the error, take a screenshot of the current state, and try to continue to the next screen.
3. **Partial report on failure**: generate whatever was captured with a clear "Flow incomplete — failed at screen 5/8" banner.
4. **Save flow state**: write a `.design-audit-progress.json` so the user could theoretically `--resume` (future feature, not MVP).

### Pitfall 9: Dev Server Detection Races and Port Conflicts

**What goes wrong:** The flow audit checks `localhost:3000` and gets a response — but it's from a different project's dev server, not the one the user intended. Or the dev server is still starting up (responds with 500/blank page) and the audit proceeds with a broken page.
**Why it happens:** Port scanning is unreliable. Multiple developers run multiple dev servers. Hot-reload causes brief unavailability windows.
**Prevention:**
1. **Require explicit URL**: `--url http://localhost:3000` rather than auto-detecting. Auto-detection is a convenience fallback, not the primary mode.
2. **Verify the page is the expected one**: after navigating, check the page title or a known element before proceeding.
3. **Health check with retry**: hit the URL, wait for 200 status AND non-empty body. Retry 3 times with 2s intervals before giving up.
4. **Show what was found**: "Found server at localhost:3000 serving 'My App'. Is this correct?"

### Pitfall 10: Agent Token Budget Explosion on Long Flows

**What goes wrong:** Each screen in the flow gets a full 8-specialist review (~84K tokens). A 10-screen flow costs 840K+ tokens — blowing through context limits and costing significant money. The agent hits context window limits mid-flow and produces degraded results for later screens.
**Why it happens:** Applying the full single-screen review process to every screen without adaptation.
**Prevention:**
1. **Quick mode for flow screens**: use `--quick` (4 specialists) for individual screens, reserve full 8-specialist for the summary/worst-scoring screen.
2. **Incremental context**: don't re-analyze the full page structure for each screen. Carry forward the design system assessment (fonts, colors, spacing) and only analyze what changed.
3. **Token budget flag**: `--budget low|medium|high` controlling specialist count and reference depth per screen.
4. **Summary-first architecture**: run lightweight checks per screen (scoring only), then deep-dive only the 2-3 worst screens.

## Minor Pitfalls

### Pitfall 11: Screenshot Viewport Inconsistency Across Screens

**What goes wrong:** Screen 1 is captured at 1440x900, screen 3 triggers a scroll that changes the viewport state, screen 5 has a sticky header that shifts content. Screenshots have inconsistent framing, making the report look sloppy and specialist comparisons unreliable.
**Prevention:** Reset viewport state before each screenshot: `await page.setViewportSize({ width: 1440, height: 900 }); await page.evaluate(() => window.scrollTo(0, 0));`. Use full-page screenshots (`fullPage: true`) consistently OR viewport-only consistently — don't mix.

### Pitfall 12: Stale Page State from Previous Screen's Interactions

**What goes wrong:** Screen 2 opens a modal. The flow navigates to screen 3, but the modal overlay is still visible (SPA didn't clean it up). Screen 3's screenshot includes screen 2's modal. Specialists review the wrong content.
**Prevention:** After each navigation, verify the expected screen state: check that modals are closed, overlays are gone, and the main content area has updated. If stale elements persist, log a warning in the report ("Possible state leak from previous screen").

### Pitfall 13: Report HTML Not Self-Contained

**What goes wrong:** Report references external CSS/JS (CDN links for styling, chart library for score visualizations). User opens the report offline or the CDN changes — report breaks.
**Prevention:** Inline ALL CSS and JS in the HTML file. No external dependencies. The report must work when opened from a local file system with no internet connection. Use simple CSS for styling — no framework needed for a diagnostic report.

### Pitfall 14: Ignoring Cookie Consent / Auth Modals

**What goes wrong:** The flow audit navigates to the first screen and is immediately blocked by a cookie consent banner, login modal, or age verification gate. The screenshots show the banner, not the actual content. The flow can't proceed.
**Prevention:**
1. **Cookie banner dismissal**: try common patterns (`[data-testid="cookie-accept"]`, `.cookie-banner button`, text match "Accept") before starting the flow.
2. **Auth handling**: if a login screen is detected, prompt the user for credentials or ask them to provide a pre-authenticated browser state (cookies/localStorage).
3. **`--skip-overlays` flag**: inject CSS to hide common overlay patterns during screenshots (but note this in the report).

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Flow navigation engine | networkidle hang (#1) | Use waitForURL + element waits, never networkidle |
| Flow navigation engine | SPA pushState detection (#3) | waitForURL for URL changes, element waits for in-page transitions |
| Screenshot capture | Visual readiness timing (#2) | Font wait + animation disable + layout stability check |
| Screenshot capture | Viewport inconsistency (#11) | Reset viewport and scroll position before each capture |
| HTML report generation | Base64 size explosion (#4) | JPEG compression, lazy loading, size budget with fallback |
| HTML report generation | Not self-contained (#13) | Inline all CSS/JS, zero external dependencies |
| Flow description parsing | Ambiguous navigation (#5) | Support explicit steps mode, confirm plan before executing |
| Animation detection | Static-only analysis (#6) | Runtime event listeners + computed style diffs |
| Error handling | Lost progress on failure (#8) | Progressive report writing, partial results on error |
| Token management | Budget explosion on long flows (#10) | Quick mode per screen, deep-dive worst screens only |
| Setup / DX | Browser not installed (#7) | Check + auto-install prompt at flow start |
| Real-world SPAs | Cookie/auth blockers (#14) | Banner dismissal heuristics, pre-auth support |

## Sources

- [Playwright Navigation Docs](https://playwright.dev/docs/navigations) — SPA navigation patterns, waitForURL
- [Playwright Auto-waiting](https://playwright.dev/docs/actionability) — actionability checks, what Playwright waits for
- [Playwright Bug #19835](https://github.com/microsoft/playwright/issues/19835) — networkidle infinite wait
- [Playwright Bug #35972](https://github.com/microsoft/playwright/issues/35972) — screenshot fails on font load errors
- [Playwright Feature #4055](https://github.com/microsoft/playwright/issues/4055) — waitForAnimation request (still open)
- [428-Day Battle Against Flaky Screenshots](https://turntrout.com/playwright-tips) — real-world screenshot timing issues
- [DebugBear: Base64 Data URLs](https://www.debugbear.com/blog/base64-data-urls-html-css) — size overhead documentation
- [bunny.net: Base64 Is Almost Always Bad](https://bunny.net/blog/why-optimizing-your-images-with-base64-is-almost-always-a-bad-idea/) — why embedded images don't scale
- [BrowserStack: Playwright Flaky Tests 2026](https://www.browserstack.com/guide/playwright-flaky-tests) — detection and avoidance strategies
- [Better Stack: Playwright Best Practices](https://betterstack.com/community/guides/testing/playwright-best-practices/) — 9 best practices and pitfalls
- [The Green Report: Automating Animation Testing](https://www.thegreenreport.blog/articles/automating-animation-testing-with-playwright-a-practical-guide/automating-animation-testing-with-playwright-a-practical-guide.html) — animation detection patterns
- [Momentic: Playwright Pitfalls](https://momentic.ai/blog/playwright-pitfalls) — common mistakes with screenshots and waits
- Existing v1.0.0 design-review plugin at ~/.claude/plugins/design-review/ (known limitations, Phase 0 patterns)
