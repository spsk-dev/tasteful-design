---
name: design-validate
description: >
  Functional validation of frontend pages — clicks every button, fills every form, navigates every
  link, checks for JS errors, verifies interactive elements work, tests responsive behavior by
  actually interacting. Use this skill after building frontend UI to verify it WORKS, not just looks
  good. Trigger on: "validate the page", "does it work", "test the interactions", "check the buttons",
  "functional test", "design-validate", or after /design-review when you want to verify functionality too.
allowed-tools: Bash(npx *), Bash(python3 *), Bash(curl *), Bash(kill *), Bash(lsof *)
---

# Design Validate — Functional Reachability Check

## Why This Exists

`/design-review` checks if a page LOOKS right. This skill checks if it WORKS right. A beautiful page with broken buttons, dead links, and JS errors is worse than an ugly page that functions.

This is automated QA for frontend pages — it interacts with the page as a user would and reports what's broken, unreachable, or incomplete.

## What It Checks

### 1. Reachability Audit
- **Every link (`<a>`)**: Does it navigate somewhere? Is it a dead link (#), placeholder (javascript:void), or valid target?
- **Every button**: Does clicking it produce a visible change? (modal, navigation, state change, form submission)
- **Every form**: Can it be filled and submitted? What happens on submit?
- **Every interactive element**: Do tabs switch? Do dropdowns open? Do toggles toggle? Do modals open AND close?
- **Navigation**: Can you reach every section of the page? Is there content hidden behind interactions that might never be discovered?

### 2. Error Audit
- **Console errors**: Capture all JS console errors/warnings during interaction
- **Network failures**: Any 404s, failed fetches, broken image/font/script loads?
- **Runtime exceptions**: Does clicking anything throw an uncaught error?

### 3. State Audit
- **Loading states**: Do async operations show loading indicators?
- **Empty states**: What happens with no data? Is there a meaningful empty state or does the UI break?
- **Error states**: What happens when something fails? Is there user-facing feedback?
- **Success states**: After a successful action, is there confirmation?

### 4. Responsive Interaction Audit
- **Mobile interactions**: Do touch targets meet 44px minimum? Can you tap every button on mobile viewport?
- **Responsive navigation**: Does the mobile nav work? Can you access all pages from mobile?
- **Overflow**: Does any content overflow its container or become unreachable on small screens?

## How It Works

### Phase 1: Discovery

Serve the page (same as design-review Phase 0) and use Playwright to build an interaction map:

```bash
# Use Playwright to snapshot the page and find all interactive elements
npx playwright screenshot "$DEV_URL" "$VALIDATE_DIR/initial.png" --viewport-size=1440,900
```

Read the source code and catalog:
- All `<a href="...">` links (group: internal nav, external, anchor, dead)
- All `<button>` elements and `onclick` handlers
- All `<form>` elements with their inputs and submit actions
- All elements with `role="button"`, `role="tab"`, `role="dialog"` triggers
- All elements with event listeners (click, submit, change, input)
- All CSS `:hover`, `:focus`, `:active` state changes

### Phase 2: Interaction Testing

Use Playwright's browser automation to interact with the page. For each element:

```
Test Plan:
1. LINKS: Navigate each link, verify destination loads (or anchor scrolls)
2. BUTTONS: Click each button, verify visible change occurs
3. FORMS: Fill with valid data, submit, verify response
4. TABS/TOGGLES: Click each tab/toggle, verify content switches
5. MODALS: Trigger open, verify content, test close (X, escape, click-outside)
6. DROPDOWNS: Open, select option, verify selection persists
7. ANIMATIONS: Trigger scroll-based animations, verify they fire
8. KEYBOARD: Tab through all interactive elements, verify focus order
```

**Preferred: Use Playwright MCP browser tools** (if available). These are the most reliable approach:

```
1. browser_navigate → go to the page URL
2. browser_snapshot → get accessibility tree of all interactive elements
3. browser_console_messages → capture any existing JS errors
4. For each button in the snapshot:
   → browser_click → click it
   → browser_snapshot → check what changed (new modal, navigation, state change)
   → browser_console_messages → check for new errors
5. For each link:
   → browser_click → verify navigation or anchor scroll
   → browser_navigate_back → return to the page
6. For each form:
   → browser_fill_form → fill with valid test data
   → browser_click submit → verify response
7. browser_resize → test mobile viewport (375x812)
   → browser_snapshot → verify elements are still reachable
```

**Fallback: Write a temp Playwright script** (if MCP browser tools unavailable):

```bash
cat > /tmp/design-validate-test.mjs << 'SCRIPT'
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
page.on('pageerror', err => errors.push(err.message));
await page.goto(process.env.DEV_URL);
const buttons = await page.locator('button:visible').all();
for (const btn of buttons) {
  try { await btn.click({ timeout: 2000 }); await page.waitForTimeout(300); } catch (e) { errors.push('Click failed: ' + e.message); }
}
const links = await page.locator('a[href]:visible').all();
for (const link of links) {
  const href = await link.getAttribute('href');
  if (href && !href.startsWith('#') && !href.startsWith('javascript:')) {
    errors.push('External link (not tested): ' + href);
  }
}
console.log(JSON.stringify({ errors, buttons_tested: buttons.length, links_found: links.length }));
await browser.close();
SCRIPT
DEV_URL="$DEV_URL" node /tmp/design-validate-test.mjs
```

Use whichever approach is available. MCP browser tools are preferred because they give you visual snapshots between interactions.

### Phase 3: Report

```
## Functional Validation — {page name}

**Status: {PASS / ISSUES FOUND / CRITICAL FAILURES}**
**Elements tested: {n} links, {n} buttons, {n} forms, {n} interactive**
**Console errors: {n}**
**Dead links: {n}**

### Working
- [x] {element} — {what it does correctly}

### Broken / Unreachable
- [ ] {element} — {what's wrong} — {how to fix}

### Not Testable (requires backend/API)
- [ ] {element} — {why it can't be tested statically}

### Console Errors
1. {error message} — triggered by {action}

### Missing States
- No loading indicator on {element}
- No error handling on {form}
- No empty state for {section}

### Mobile Issues
- {element} has {Npx} touch target (needs 44px min)
- {nav} is not accessible on mobile viewport
```

## When to Use

| Situation | Use |
|-----------|-----|
| Built a page, want to check it looks good | `/design-review` |
| Built a page, want to check it works | `/design-validate` |
| Want both visual + functional check | Run both (or `/design-review` then `/design-validate`) |
| Iterating until high quality | `/design-improve` (calls both internally) |

## Integration with /design-improve

When `/design-improve` runs its loop, it can optionally run `/design-validate` after each iteration to catch functional regressions introduced by design fixes. Enable with `--validate` flag on design-improve.

## Limitations

- **No backend testing**: Can only test client-side functionality. Form submissions to APIs, auth flows, and database operations are logged as "not testable."
- **Static HTML focus**: Works best on static pages. SPA navigation and client-side routing may need the dev server running.
- **No visual regression**: This skill doesn't compare screenshots — that's `/design-review`'s job.
