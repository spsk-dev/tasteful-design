---
name: design-audit
description: >
  Flow-level design audit -- navigates multi-screen SPA flows using Playwright MCP,
  captures screenshots at each state change, and produces flow state for downstream
  review and reporting. Use when the user says "audit the flow", "design audit",
  "walk through the onboarding", "/design audit", or wants to evaluate a multi-screen
  user journey.
allowed-tools: Bash(mkdir *), Bash(cp *), Bash(rm *), Bash(cat *), Bash(npx *), Bash(gemini *), Bash(which *), Bash(kill *), Bash(lsof *)
---

@${CLAUDE_PLUGIN_ROOT}/shared/output.md
@${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/flow.md

# Design Audit -- Flow Navigation Engine

Read `@${CLAUDE_PLUGIN_ROOT}/config/flow-scoring.json` for default values (max_screens, dom_stability, screenshot viewport, navigation timeouts).

## 1. Argument Parsing

Parse `$ARGUMENTS` for the following:

**Required:**
- **URL** -- the starting URL for the flow audit (first positional argument or explicit URL)

**Mode (mutually exclusive -- exactly one required):**
- `--flow "description"` -- Intent mode. The description guides which CTAs to click at each step. Example: `--flow "complete the onboarding"`
- `--steps url1,url2,url3` -- Deterministic mode. Comma-separated URLs to visit in order. No CTA clicking needed.

**Optional:**
- `--auth` -- Authenticated flow mode. After initial navigation, pause for user to complete login if a login form is detected.
- `--max-screens N` -- Override the max screen limit (default: 10 from config/flow-scoring.json)

**Validation:**
- If no URL provided, ask the user for one.
- If neither `--flow` nor `--steps` provided, ask the user:
  ```
  Which navigation mode should I use?

  1. Intent mode (--flow "description") -- I navigate by clicking CTAs that match your description
  2. Deterministic mode (--steps url1,url2,url3) -- I visit each URL in order

  Provide --flow with a description or --steps with a URL list.
  ```
- If both `--flow` and `--steps` provided, show an error: "Cannot use --flow and --steps together. Pick one mode."

Store parsed values:
- `FLOW_URL` -- starting URL
- `FLOW_MODE` -- "intent" or "deterministic"
- `FLOW_INTENT` -- the flow description (intent mode only)
- `FLOW_STEPS` -- array of URLs (deterministic mode only)
- `FLOW_AUTH` -- boolean
- `MAX_SCREENS` -- integer (default 10)

## 2. Setup

### 2a. Create output directory

Generate a timestamped output directory:
```
AUDIT_DIR="/tmp/design-audit-{YYYYMMDD-HHMMSS}/"
```

Create it:
```bash
mkdir -p /tmp/design-audit-{timestamp}
```

### 2b. Initialize flow-state.json

Write the initial flow state file at `{AUDIT_DIR}/flow-state.json`:
```json
{
  "version": "1.0",
  "status": "in_progress",
  "flow_intent": "{FLOW_INTENT or null}",
  "url": "{FLOW_URL}",
  "mode": "{FLOW_MODE}",
  "max_screens": {MAX_SCREENS},
  "started_at": "{ISO 8601 timestamp}",
  "completed_at": null,
  "screens": [],
  "error": null
}
```

### 2c. Show branded header

Display the signature line using shared/output.md format:
```
 SpSk  design-audit  v1.1.0  ───  flow navigation engine
```

Then show the configuration:
```
┌─ CONFIGURATION ─────────────────────────────────────────────┐
│  URL:         {FLOW_URL}                                     │
│  Mode:        {intent | deterministic}                       │
│  Intent:      {FLOW_INTENT or "N/A"}                         │
│  Auth:        {yes | no}                                     │
│  Max screens: {MAX_SCREENS}                                  │
│  Output:      {AUDIT_DIR}                                    │
└──────────────────────────────────────────────────────────────┘
```

## 3. Playwright MCP Verification

### 3a. Navigate to starting URL

Call `browser_navigate` with `FLOW_URL`.

**If the MCP tool is not available** (tool call fails or is unrecognized), show this error and stop:
```
┌─ ERROR ─────────────────────────────────────────────────────┐
│  ✗ Playwright MCP not registered                             │
│                                                               │
│  Run this command to register it:                            │
│  claude mcp add playwright -- npx @playwright/mcp@latest     │
│                                                               │
│  Then retry the audit.                                       │
└──────────────────────────────────────────────────────────────┘
```

Update flow-state.json with `"status": "error"` and `"error": "Playwright MCP not registered"`. Stop execution.

### 3b. Set viewport

After successful navigation, call `browser_resize` to set the viewport:
- Width: 1440
- Height: 900

These values come from `config/flow-scoring.json` under `screenshot.viewport`.

## 4. Authentication Handling

**Only runs when `--auth` flag is present.**

### 4a. Check for login form

Call `browser_snapshot` to read the current page's accessibility tree.

Scan the snapshot for login form indicators:
- `input[type=password]` or password field in the accessibility tree
- Text matching: "Sign In", "Log In", "Login", "Sign in to", "Enter your password", "Username", "Email and password"
- Form elements grouped with a submit button labeled "Sign In", "Log In", "Submit", "Continue"

### 4b. If login form detected

Display a checkpoint message:
```
┌─ AUTH REQUIRED ─────────────────────────────────────────────┐
│  ⚠ Login form detected at {FLOW_URL}                        │
│                                                               │
│  Please complete login in the browser window.                │
│  The browser is visible -- fill in your credentials there.   │
│                                                               │
│  Type 'continue' when you have logged in.                    │
└──────────────────────────────────────────────────────────────┘
```

Wait for user to confirm. After confirmation:
1. Call `browser_snapshot` again to verify the page has changed (no more login form)
2. If login form is still present, warn: "Login form still detected. Try again or proceed anyway?"
3. Once confirmed past login, continue to navigation

### 4c. If no login form detected

Proceed normally. If `--auth` was provided but no login is needed (already authenticated or public page), show:
```
✓ No login required -- proceeding with audit
```

## 5. Cookie/Popup Dismissal

Before starting the navigation loop, handle common interruptions per references/flow.md Section 6.

1. Call `browser_snapshot` on the current page
2. Look for cookie consent banners -- buttons labeled: "Accept", "Accept All", "I Agree", "Got it", "OK" within a banner/dialog context
3. If found, call `browser_click` on the accept/dismiss button
4. Look for promotional modals/overlays -- dismiss buttons: "X", "Close", "No thanks", "Maybe later", "Skip"
5. If found and the content does NOT match the flow intent, dismiss it
6. If the popup content matches the flow intent, treat it as a flow screen instead

Log any dismissals:
```
✓ Dismissed cookie consent banner
```

## 6. Navigation -- Intent Mode

**Runs when `FLOW_MODE` is "intent".**

For each screen (up to `MAX_SCREENS`):

### Step A: Take fresh snapshot

Call `browser_snapshot` to read the current page's accessibility tree.

**CRITICAL:** Always take a fresh snapshot immediately before identifying a CTA. Never use cached/stale element refs -- they may be invalidated by DOM changes (Pitfall 5 from RESEARCH.md).

### Step B: Reason about CTA

Read the accessibility tree and identify which CTA matches the flow intent (`FLOW_INTENT`).

**CTA identification priority** (from references/flow.md Section 2):
1. Primary buttons (larger, higher contrast, prominent position) -- "Get Started", "Continue", "Next"
2. Links styled as buttons -- same visual weight as buttons
3. Navigation links matching the flow intent -- "Sign Up" in a nav bar
4. Form submit buttons -- "Submit", "Save", "Create Account"

**Matching strategy:**
- Match CTA text against the flow intent semantically
- If multiple CTAs match, prefer: (a) main content area over sidebar/nav, (b) larger visual prominence, (c) flow-advancing over skipping ("Continue" over "Skip")
- Record the chosen CTA text and its element ref

**Check for terminal states:**
- **Success state** (references/flow.md Section 5): Look for "Thank you", "Success", "Complete", "Confirmed", "All done", "Congratulations", checkmark icons, progress bar at 100%, "Step X of X" at final step
- **Dead end** (references/flow.md Section 4): No matching CTAs, error page content ("404", "Something went wrong"), blank page, or returning to a previously visited URL (loop detection)

If success state detected:
- Capture the success screen (go to Step G)
- Set flow status to "complete"
- Report: `✓ Flow complete at Screen {N}: {success indicator}`
- Jump to Section 8 (Flow Completion)

If dead end detected:
- Capture the dead-end screen (go to Step G)
- Set flow status to "dead_end" with reason in flow state
- Report: `✗ Dead end at Screen {N}: {reason}`
- Jump to Section 8 (Flow Completion)

### Step B2: Inject animation listeners

Before clicking, inject the animation event listener (from references/flow.md Section 9c) via `browser_evaluate` to capture transition/animation events triggered by the click:

```javascript
(function() {
  window.__spsk_anim_events = [];
  const handler = (e) => window.__spsk_anim_events.push({
    type: e.type,
    element: e.target.tagName + (e.target.className ? '.' + String(e.target.className).split(' ')[0] : ''),
    animation: e.animationName || e.propertyName || '',
    elapsed: e.elapsedTime,
    timestamp: Date.now()
  });
  ['animationstart','animationend','transitionstart','transitionend','transitionrun'].forEach(
    evt => document.addEventListener(evt, handler, true)
  );
  return { listening: true };
})()
```

Also capture the pre-click animation state (from references/flow.md Section 9a) via `browser_evaluate`:

```javascript
(function() {
  const animations = document.getAnimations().map(a => ({
    element: a.effect?.target?.tagName + (a.effect?.target?.className ? '.' + a.effect.target.className.split(' ')[0] : ''),
    name: a.animationName || 'transition',
    duration: a.effect?.getTiming?.()?.duration || 0,
    state: a.playState
  }));
  const transitions = Array.from(document.querySelectorAll('*')).slice(0, 200).reduce((acc, el) => {
    const cs = getComputedStyle(el);
    if (cs.transitionProperty !== 'all' && cs.transitionProperty !== 'none' && cs.transitionDuration !== '0s') {
      acc.push({
        element: el.tagName + (el.className ? '.' + String(el.className).split(' ')[0] : ''),
        property: cs.transitionProperty,
        duration: cs.transitionDuration,
        timing: cs.transitionTimingFunction
      });
    }
    return acc;
  }, []);
  return { animations, transitions, timestamp: Date.now() };
})()
```

Store both results as `PRE_CLICK_ANIM_STATE` for this screen.

### Step C: Click the CTA

Report the action:
```
Screen {N}: {screen_name} -- clicking "{CTA text}" (ref: {element_ref})
```

Call `browser_click` with `ref="{element_ref}"`.

**If click fails** (element not found or not clickable):
1. Take a fresh `browser_snapshot` (the DOM may have changed)
2. Re-identify the CTA in the new snapshot
3. Retry `browser_click` with the new ref
4. If still fails: capture an error screenshot, log the error in flow state, set status to "error", terminate gracefully

### Step D: DOM stability check

Wait 300ms (post_click_settle_ms from config/flow-scoring.json), then run the DOM stability check via `browser_evaluate`:

```javascript
(function() {
  return new Promise((resolve) => {
    let timer = null;
    const observer = new MutationObserver(() => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        observer.disconnect();
        resolve({ stable: true, waited: true });
      }, 800);
    });
    observer.observe(document.body, {
      childList: true, subtree: true, attributes: true, characterData: true
    });
    timer = setTimeout(() => {
      observer.disconnect();
      resolve({ stable: true, waited: false });
    }, 2000);
  });
})()
```

This waits for 800ms of mutation silence (from config `dom_stability.mutation_quiet_ms`), with a 2s fallback (from config `dom_stability.fallback_timeout_ms`).

**If stability times out** (takes longer than fallback): Proceed anyway. The screen may still be usable. Note `"stability_timeout": true` in the screen entry of flow-state.json.

### Step E: Font readiness check

After DOM stability, run the font readiness check via `browser_evaluate`:

```javascript
(function() {
  return Promise.race([
    document.fonts.ready.then(() => ({ fontsReady: true })),
    new Promise(resolve => setTimeout(() => resolve({ fontsReady: false, timeout: true }), 5000))
  ]);
})()
```

This waits for all fonts to load with a 5s timeout (from config `font_readiness_timeout_ms`).

**If font readiness times out:** Proceed with capture anyway. Note `"fonts_timeout": true` in the screen entry.

### Step E2: Capture post-transition animation state

After DOM stability and font readiness, capture the post-stable animation state (references/flow.md Section 9b) via `browser_evaluate`:

```javascript
(function() {
  const animations = document.getAnimations().map(a => ({
    element: a.effect?.target?.tagName + (a.effect?.target?.className ? '.' + a.effect.target.className.split(' ')[0] : ''),
    name: a.animationName || 'transition',
    duration: a.effect?.getTiming?.()?.duration || 0,
    state: a.playState
  }));
  const transitions = Array.from(document.querySelectorAll('*')).slice(0, 200).reduce((acc, el) => {
    const cs = getComputedStyle(el);
    if (cs.transitionProperty !== 'all' && cs.transitionProperty !== 'none' && cs.transitionDuration !== '0s') {
      acc.push({
        element: el.tagName + (el.className ? '.' + String(el.className).split(' ')[0] : ''),
        property: cs.transitionProperty,
        duration: cs.transitionDuration,
        timing: cs.transitionTimingFunction
      });
    }
    return acc;
  }, []);
  return { animations, transitions, timestamp: Date.now() };
})()
```

Also collect the animation events that fired during the transition via `browser_evaluate`:

```javascript
(function() { return window.__spsk_anim_events || []; })()
```

Run the prefers-reduced-motion compliance check (references/flow.md Section 10) via `browser_evaluate`:

```javascript
(function() {
  const sheets = Array.from(document.styleSheets);
  let hasReducedMotion = false;
  let animationCount = 0;
  sheets.forEach(sheet => {
    try {
      Array.from(sheet.cssRules || []).forEach(rule => {
        if (rule.type === CSSRule.MEDIA_RULE && rule.conditionText?.includes('prefers-reduced-motion')) {
          hasReducedMotion = true;
        }
        if (rule.style) {
          if (rule.style.animationName && rule.style.animationName !== 'none') animationCount++;
          if (rule.style.transitionProperty && rule.style.transitionProperty !== 'none') animationCount++;
        }
      });
    } catch(e) { /* cross-origin stylesheet, skip */ }
  });
  const docAnimations = document.getAnimations().length;
  return {
    has_prefers_reduced_motion: hasReducedMotion,
    css_animation_count: animationCount,
    active_animations: docAnimations,
    compliant: hasReducedMotion || (animationCount === 0 && docAnimations === 0),
    verdict: hasReducedMotion ? 'PASS' : (animationCount > 0 || docAnimations > 0) ? 'FAIL -- animations without reduced-motion support' : 'PASS -- no animations detected'
  };
})()
```

Store all results as `POST_STABLE_ANIM_STATE`, `ANIM_EVENTS`, and `PRM_CHECK` for this screen.

### Step F: Confirm new screen

Call `browser_snapshot` to get the post-navigation accessibility tree.

Compare to the pre-click snapshot:
- Is there a new heading (h1/h2)?
- Has the URL changed? Check via `browser_evaluate`: `window.location.href`
- Is the content substantially different?

If the page appears unchanged after clicking:
- The click may not have triggered navigation
- Check if a modal or overlay appeared instead
- If truly unchanged, note it and try the next matching CTA or report dead end

### Step G: Capture screenshot

Generate the screenshot filename using slug generation (references/flow.md Section 8):
1. Use the first `<h1>` heading text from the snapshot
2. If no h1, use the first `<h2>` heading text
3. If no heading, use the last segment of the URL path
4. Fallback: `screen-{N}`

Slugify: lowercase, replace spaces/underscores with hyphens, strip non-alphanumeric (except hyphens), collapse consecutive hyphens, trim leading/trailing hyphens, truncate to 40 characters at a word boundary.

Call `browser_take_screenshot` to capture the viewport to:
```
{AUDIT_DIR}/screen-{N}-{slug}.png
```

Screenshot parameters (from config/flow-scoring.json):
- Viewport: 1440x900 (already set in Step 3b)
- Full page: false (viewport only)
- Format: PNG

### Step H: Update flow-state.json

Append a screen entry to the `screens` array and overwrite the file (progressive persistence -- Pattern 3):

```json
{
  "number": {N},
  "name": "{screen_name from heading or URL}",
  "slug": "{slug}",
  "url": "{current URL}",
  "screenshot_path": "{AUDIT_DIR}/screen-{N}-{slug}.png",
  "timestamp": "{ISO 8601}",
  "cta_clicked": "{CTA text}",
  "cta_ref": "{element_ref}",
  "animation": {
    "pre_click": {
      "animations": [PRE_CLICK_ANIM_STATE.animations],
      "transitions": [PRE_CLICK_ANIM_STATE.transitions]
    },
    "post_stable": {
      "animations": [POST_STABLE_ANIM_STATE.animations],
      "transitions": [POST_STABLE_ANIM_STATE.transitions]
    },
    "events": [ANIM_EVENTS],
    "prefers_reduced_motion": {
      "has_support": PRM_CHECK.has_prefers_reduced_motion,
      "css_animation_count": PRM_CHECK.css_animation_count,
      "active_animations": PRM_CHECK.active_animations,
      "compliant": PRM_CHECK.compliant,
      "verdict": PRM_CHECK.verdict
    }
  }
}
```

Write the updated flow-state.json immediately. This ensures partial results survive if the flow fails on a later screen.

### Step I: Terminal progress

Display branded progress:
```
✓ Screen {N}: {screen_name} -- captured
```

### Step J: Max screens check

If `N >= MAX_SCREENS`:
- Set flow status to "max_screens_reached"
- Show warning:
  ```
  ⚠ Max screens reached ({MAX_SCREENS}). Flow terminated.
  ```
- Jump to Section 8 (Flow Completion)

Otherwise, increment N and loop back to Step A.

## 7. Navigation -- Deterministic Mode

**Runs when `FLOW_MODE` is "deterministic".**

For each URL in `FLOW_STEPS` (index 1 to length):

### Step A: Navigate to URL

Call `browser_navigate` with the current URL from the steps list.

If navigation fails (timeout, DNS error, HTTP error), capture an error screenshot if possible, log the error, and continue to the next URL.

### Step B: DOM stability check

Run the same DOM stability check as Intent Mode Step D via `browser_evaluate`.

### Step C: Font readiness check

Run the same font readiness check as Intent Mode Step E via `browser_evaluate`.

### Step C2: Capture animation state

In deterministic mode there is no CTA click, so only capture the current animation state and prefers-reduced-motion compliance -- no pre/post diff needed.

Capture the current animation state (references/flow.md Section 9a) via `browser_evaluate`:

```javascript
(function() {
  const animations = document.getAnimations().map(a => ({
    element: a.effect?.target?.tagName + (a.effect?.target?.className ? '.' + a.effect.target.className.split(' ')[0] : ''),
    name: a.animationName || 'transition',
    duration: a.effect?.getTiming?.()?.duration || 0,
    state: a.playState
  }));
  const transitions = Array.from(document.querySelectorAll('*')).slice(0, 200).reduce((acc, el) => {
    const cs = getComputedStyle(el);
    if (cs.transitionProperty !== 'all' && cs.transitionProperty !== 'none' && cs.transitionDuration !== '0s') {
      acc.push({
        element: el.tagName + (el.className ? '.' + String(el.className).split(' ')[0] : ''),
        property: cs.transitionProperty,
        duration: cs.transitionDuration,
        timing: cs.transitionTimingFunction
      });
    }
    return acc;
  }, []);
  return { animations, transitions, timestamp: Date.now() };
})()
```

Run the prefers-reduced-motion compliance check (references/flow.md Section 10) via `browser_evaluate`:

```javascript
(function() {
  const sheets = Array.from(document.styleSheets);
  let hasReducedMotion = false;
  let animationCount = 0;
  sheets.forEach(sheet => {
    try {
      Array.from(sheet.cssRules || []).forEach(rule => {
        if (rule.type === CSSRule.MEDIA_RULE && rule.conditionText?.includes('prefers-reduced-motion')) {
          hasReducedMotion = true;
        }
        if (rule.style) {
          if (rule.style.animationName && rule.style.animationName !== 'none') animationCount++;
          if (rule.style.transitionProperty && rule.style.transitionProperty !== 'none') animationCount++;
        }
      });
    } catch(e) { /* cross-origin stylesheet, skip */ }
  });
  const docAnimations = document.getAnimations().length;
  return {
    has_prefers_reduced_motion: hasReducedMotion,
    css_animation_count: animationCount,
    active_animations: docAnimations,
    compliant: hasReducedMotion || (animationCount === 0 && docAnimations === 0),
    verdict: hasReducedMotion ? 'PASS' : (animationCount > 0 || docAnimations > 0) ? 'FAIL -- animations without reduced-motion support' : 'PASS -- no animations detected'
  };
})()
```

Store as `SCREEN_ANIM_STATE` and `PRM_CHECK`.

### Step D: Capture screenshot

Generate slug from the page heading or URL path (same logic as Intent Mode Step G).

Call `browser_take_screenshot`:
```
{AUDIT_DIR}/screen-{N}-{slug}.png
```

### Step E: Update flow-state.json

Append screen entry (same format as Intent Mode Step H, but with `"cta_clicked": null` and `"cta_ref": null` since no CTA clicking occurs, and `"pre_click": null` and `"events": []` since no click animation diff is captured):

```json
{
  "number": {N},
  "name": "{screen_name}",
  "slug": "{slug}",
  "url": "{current URL from steps list}",
  "screenshot_path": "{AUDIT_DIR}/screen-{N}-{slug}.png",
  "timestamp": "{ISO 8601}",
  "cta_clicked": null,
  "cta_ref": null,
  "animation": {
    "pre_click": null,
    "post_stable": {
      "animations": [SCREEN_ANIM_STATE.animations],
      "transitions": [SCREEN_ANIM_STATE.transitions]
    },
    "events": [],
    "prefers_reduced_motion": {
      "has_support": PRM_CHECK.has_prefers_reduced_motion,
      "css_animation_count": PRM_CHECK.css_animation_count,
      "active_animations": PRM_CHECK.active_animations,
      "compliant": PRM_CHECK.compliant,
      "verdict": PRM_CHECK.verdict
    }
  }
}
```

### Step F: Terminal progress

```
✓ Screen {N}: {screen_name} -- captured
```

Continue to next URL in the steps list.

## 8. Flow Completion

### 8a. Update flow-state.json

Set the final status and timestamp:
```json
{
  "status": "{complete | dead_end | max_screens_reached | error}",
  "completed_at": "{ISO 8601 timestamp}"
}
```

If an error occurred, also set:
```json
{
  "error": "{error description}",
  "error_at_screen": {screen_number_where_error_occurred}
}
```

### 8b. Transition to per-screen review

Display a brief transition message:
```
✓ Navigation complete -- {N} screens captured. Starting per-screen review...
```

If status is "error" and fewer than 2 screens were captured, skip review and jump to Section 14 (error summary). Otherwise proceed to Section 10.

## 9. Error Handling

### Click failure (Intent Mode)

If `browser_click` fails:
1. Take a fresh `browser_snapshot` (DOM may have changed)
2. Re-identify the target CTA in the new snapshot
3. Retry `browser_click` with the updated ref
4. If still fails: capture error screenshot at `{AUDIT_DIR}/screen-{N}-error.png`
5. Update flow-state.json with `"status": "error"`, `"error": "Click failed on '{CTA text}' at screen {N}"`, `"error_at_screen": {N}`
6. Terminate gracefully -- show the summary with screens captured so far

### Navigation failure (Deterministic Mode)

If `browser_navigate` fails for a URL:
1. Log the error in flow-state.json screen entry: `"error": "Navigation failed: {reason}"`
2. Continue to the next URL in the steps list (do not terminate the entire flow)
3. If ALL URLs fail, set status to "error"

### DOM stability timeout

If the DOM stability check exceeds the 2s fallback:
- Proceed with screenshot capture anyway
- Note `"stability_timeout": true` in the screen entry
- The screenshot may catch mid-transition content, but partial results are better than no results

### Max screens reached

When screen count equals `MAX_SCREENS`:
- Set status to "max_screens_reached"
- Show warning: `Max screens reached ({MAX_SCREENS}). Increase with --max-screens N.`
- Terminate normally (this is not an error)

### Unexpected page state

If `browser_snapshot` returns an empty or minimal accessibility tree:
- The page may be loading, blank, or crashed
- Wait 2 seconds and retry the snapshot
- If still empty, capture a screenshot of whatever is visible, log it, and terminate

## Key Constraints

- **Every browser interaction uses Playwright MCP tools.** Never write shell scripts for navigation.
- **Always take a fresh `browser_snapshot` immediately before `browser_click`.** Stale element refs cause failures (Pitfall 5).
- **Never use `networkidle`.** SPAs with analytics/WebSockets never reach idle (Pitfall 1).
- **Progressive persistence.** Write flow-state.json after each screen capture, after each screen review, after consistency analysis, and after flow score computation. Mid-flow failures must preserve partial results.
- **The flow-state.json is the contract** between navigation (Sections 1-9), review (Sections 10-11), consistency (Section 12), scoring (Section 13), and reporting (Section 15). Match the schema exactly.
- **Sections 10-14 run only after navigation completes.** If navigation errors with <2 screens, skip review and show error summary.
- **Per-screen reviews run sequentially, not in parallel.** Each screen's review must complete before the next starts. This manages token budget (Pitfall 10 from PITFALLS.md).
- **Consistency analysis runs AFTER all per-screen reviews.** It is a post-processing pass, not a 9th specialist (per D-84). It reads specialist findings from all screens and compares them.
- **The animation detection hooks must NOT disrupt the navigation loop.** If browser_evaluate fails for animation injection, log the error and proceed without animation data for that screen.
- **Section 15 runs after Section 14 even if some reviews had errors.** The report shows whatever data is available. Report generation failure is non-blocking -- the terminal summary from Section 14 already shows results.

---

## 10. Per-Screen Review Dispatch

After navigation completes with status "complete", "dead_end", or "max_screens_reached", dispatch specialist reviews for each captured screen.

**Skip review if** status is "error" and fewer than 2 screens were captured -- not enough data for meaningful review. Jump to Section 14 (error summary).

### 10a. Determine review mode per screen

Read `smart_weighting` from config/flow-scoring.json.

For each screen in flow-state.json `screens` array:
- If screen.number === 1 (first) OR screen.number === total_screens (last): **FULL mode** (8 specialists)
- Otherwise: **QUICK mode** (4 specialists: Font, Color, Layout, Intent)

Display the plan:
```
┌─ REVIEW PLAN ───────────────────────────────────────────────┐
│  Screen 1: {name} ── full (8 specialists)                    │
│  Screen 2: {name} ── quick (4 specialists)                   │
│  Screen 3: {name} ── quick (4 specialists)                   │
│  Screen 4: {name} ── full (8 specialists)                    │
└──────────────────────────────────────────────────────────────┘
```

**Edge cases:**
- If only 1 screen captured, it is both first AND last -- run full mode.
- If only 2 screens captured, both are first/last -- both get full mode.

### 10b. Dispatch per-screen reviews

For each screen, follow the design-review.md workflow adapted for flow context. Reviews are sequential -- each screen completes fully before the next starts.

**Phase 1 (Page Analysis):** Instead of running the Haiku agent fresh, provide the flow-level PAGE_BRIEF:
- Page TYPE: derive from the screen's content (the flow intent provides context)
- PAGE INTENT: "{flow_intent} -- Screen {N}: {screen_name}"
- The flow intent enriches per-screen intent -- Screen 1's intent is "entry point for {flow}", last screen's is "completion of {flow}"

**Phase 2 (Specialist Dispatch):** Run specialists per design-review.md Phase 2.
- Full mode: all 8 specialists (Font, Color, Layout, Icon, Motion, Intent/Originality/UX, Copy, Code/A11y)
- Quick mode: specialists 1 (Font), 2 (Color), 3 (Layout), 6 (Intent/Originality/UX)
- Each specialist receives: the screen's screenshot (from screenshot_path), source code access via the browser, and the PAGE_BRIEF with flow context

**Animation enrichment (per ANIM-03):** For the Motion specialist (#5, full mode only), append the screen's animation data from flow-state.json to the prompt:

```
ANIMATION DATA FROM FLOW NAVIGATION:
- Pre-click state: {animation.pre_click}
- Post-stable state: {animation.post_stable}
- Events during transition: {animation.events}
- prefers-reduced-motion: {animation.prefers_reduced_motion.verdict}

Evaluate animation QUALITY using this runtime data alongside your source code analysis.
Flag any animations that lack prefers-reduced-motion support.
Assess transition timing against the ranges in config/flow-scoring.json:
  - Micro-interaction: 150-300ms
  - Layout change: 300-500ms
  - Page transition: 300-800ms
  - Sluggish threshold: >500ms for single elements

Easing quality:
  - Good: ease-in-out, cubic-bezier(...)
  - Acceptable: ease, ease-out
  - Poor: linear (flag on UI elements, acceptable for progress bars)
```

**Phase 3 (Boss Synthesis):** Run the boss synthesizer per design-review.md Phase 3.
- Use weights from config/scoring.json (full mode: /17, quick mode: /13)
- Produce per-screen score, findings, and verdict

### 10c. Store per-screen results

After each screen's review completes, update that screen's entry in flow-state.json:

```json
{
  "number": 1,
  "name": "...",
  "review": {
    "mode": "full|quick",
    "specialist_count": 8,
    "scores": {
      "intent_match": 3.0,
      "originality": 2.5,
      "ux_flow": 3.0,
      "typography": 3.5,
      "color": 2.0,
      "layout": 3.0,
      "icons": 2.5,
      "motion": 3.0,
      "copy": 3.0,
      "code_a11y": 2.5
    },
    "weighted_score": 2.85,
    "verdict": "CONDITIONAL",
    "findings": ["finding 1", "finding 2"],
    "cross_specialist_findings": ["cross-finding 1"],
    "top_fixes": [
      {
        "priority": 1,
        "severity": "CRITICAL",
        "issue": "Replace Playfair Display with Instrument Serif",
        "file": "index.html",
        "line": 15,
        "specialists": ["typography", "intent"]
      }
    ]
  }
}
```

When the boss produces `<boss_output>` JSON, extract the `top_fixes` array and store it in the screen review entry. This enables `generate-report.sh` to read fixes programmatically from flow-state.json. If no `<boss_output>` JSON is found, store an empty array for `top_fixes`.

For quick mode screens, only the 4 specialist scores (mapped to the 6 scored dimensions from design-review.md quick mode) are present. Missing dimensions are null:
```json
{
  "scores": {
    "intent_match": 3.0,
    "originality": 2.5,
    "ux_flow": 3.0,
    "typography": 3.5,
    "color": 2.0,
    "layout": 3.0,
    "icons": null,
    "motion": null,
    "copy": null,
    "code_a11y": null
  }
}
```

Write flow-state.json after EACH screen review completes (progressive persistence).

### 10d. Display per-screen progress

After each screen review, show branded output (score converted to /10 display scale per shared/output.md: internal * 2.5):
```
✓ Screen {N}: {name} ── {display_score}/10 ({verdict}) ── {mode} mode
```

---

## 11. Animation Summary

After all per-screen reviews complete, summarize animation findings across the flow.

### 11a. Compile animation data

Read the `animation` field from each screen in flow-state.json.

### 11b. Animation quality assessment

For each screen, evaluate:
1. **Transition coverage:** Did interactive elements (buttons, links, form fields) have CSS transitions? List elements with and without.
2. **Duration quality:** Compare detected durations against config/flow-scoring.json `animation.duration_ranges_ms`. Flag durations outside expected ranges:
   - Micro-interaction (150-300ms): button hover, toggle, checkbox
   - Layout change (300-500ms): accordion, tab switch, sidebar
   - Page transition (300-800ms): route change, modal, full-page swap
   - Sluggish (>500ms for single element): flag as too slow
3. **Easing quality:** Compare detected timing functions against config `animation.easing_quality`. Flag `linear` easing on UI elements (acceptable for progress bars).
4. **Cross-screen transition events:** How many animation/transition events fired during each screen transition? Zero events on a navigation = missing page transitions (flag as finding).

### 11c. prefers-reduced-motion summary

Compile PRM results across all screens:
- How many screens passed PRM check?
- Which screens have animations without PRM support?
- Overall PRM compliance: PASS (all screens) / PARTIAL (some) / FAIL (none)

### 11d. Store animation summary

Add a top-level `animation_summary` to flow-state.json:

```json
{
  "animation_summary": {
    "total_transitions_detected": 12,
    "total_animation_events": 8,
    "screens_with_animations": [1, 3, 4],
    "screens_without_transitions": [2],
    "duration_findings": [
      "Screen 3: button hover at 800ms exceeds micro-interaction range (150-300ms)"
    ],
    "easing_findings": [
      "Screen 3: linear easing on button hover (use ease-in-out)"
    ],
    "prefers_reduced_motion": {
      "compliant_screens": 3,
      "non_compliant_screens": 1,
      "overall": "PARTIAL"
    },
    "findings": [
      "Screen 2 has no transition events -- navigation feels abrupt",
      "Screen 3: linear easing on button hover (use ease-in-out)",
      "Screen 4: animations lack prefers-reduced-motion support"
    ]
  }
}
```

---

## 12. Cross-Screen Consistency Analysis

**Runs after all per-screen reviews complete (Section 10) and animation summary (Section 11).**

This is a POST-PROCESSING pass (per D-84), not a 9th specialist. It reads the per-screen specialist findings from flow-state.json and compares visual properties across all screens.

**Skip if** fewer than 2 screens have reviews (nothing to compare).

### 12a. Extract comparable properties from specialist findings

For each screen, extract design properties from the specialist findings and scores:

**From Font specialist (#1) findings:**
- Body text font family and size
- Heading font family, size, and weight
- Line-height values

**From Color specialist (#2) findings:**
- Primary color (most dominant non-white/non-black)
- Secondary/accent colors
- Background colors
- Button colors

**From Layout specialist (#3) findings:**
- Section padding values
- Card/component gap values
- Content max-width
- Grid column counts

**From specialist findings text (pattern matching):**
- Button border-radius, background-color, padding, font-weight mentions
- Component descriptions (card style, nav pattern, input style)

If a finding mentions a specific CSS value (e.g., "16px body text", "#3B82F6 primary", "24px gap"), extract it as a comparable property.

### 12b. Compare across screens

Read `consistency.thresholds` from config/flow-scoring.json.

For each consistency check in `consistency.checks` (`button_style`, `color_palette`, `spacing`, `typography`, `component_variants`):

**button_style -- Button style drift:**
Compare button-related properties across screens. Flag when:
- Border-radius differs between screens (e.g., rounded-lg on screen 1, rounded on screen 3)
- Button background colors differ for primary CTAs
- Button padding or font-weight differs

**color_palette -- Color palette consistency:**
Compare extracted colors across screens. Flag when:
- Primary color varies between screens (Delta E > `color_drift_delta_e` threshold, default 10)
- New accent colors appear on some screens but not others
- Background color changes unexpectedly between screens

**spacing -- Spacing/padding patterns:**
Compare spacing values. Flag when:
- Section padding differs by more than `spacing_tolerance_px` (default 4px) between screens
- Card/component gaps are inconsistent
- Content max-width changes between screens

**typography -- Typography consistency:**
Compare font properties. Flag when:
- Body text size differs by more than `font_size_tolerance_px` (default 2px) between screens
- Font family changes between screens (e.g., Inter on screen 1, Poppins on screen 3)
- Heading hierarchy breaks (h1 size on screen 2 < h1 size on screen 1)

**component_variants -- Component variant drift:**
Compare how repeated components are described across screens. Flag when:
- Cards have different styling on different screens
- Navigation looks different between screens
- Form inputs have different styling

### 12c. Classify severity

For each finding, assign severity from `consistency.severity_levels` in config/flow-scoring.json:

- **drift (warning):** Subtle variation that might be intentional (e.g., 2px spacing difference)
- **mismatch (issue):** Clear inconsistency that looks unintentional (e.g., different font family on one screen)
- **conflict (critical):** Contradictory styles that break visual coherence (e.g., rounded buttons on 3 screens, square on 1)

### 12d. Store consistency results

Add a top-level `consistency` section to flow-state.json (per D-83):
```json
{
  "consistency": {
    "findings": [
      {
        "check": "typography",
        "severity": "mismatch",
        "description": "Body text is 16px on Screens 1, 3, 4 but 14px on Screen 2",
        "screens_affected": [2],
        "screens_reference": [1, 3, 4]
      },
      {
        "check": "color_palette",
        "severity": "drift",
        "description": "Primary blue shifts from #3B82F6 (Screen 1) to #2563EB (Screen 2-4)",
        "screens_affected": [2, 3, 4],
        "screens_reference": [1]
      },
      {
        "check": "spacing",
        "severity": "conflict",
        "description": "Section padding is 64px on Screens 1, 4 but 32px on Screens 2, 3",
        "screens_affected": [2, 3],
        "screens_reference": [1, 4]
      }
    ],
    "summary": {
      "total_findings": 3,
      "by_severity": { "drift": 1, "mismatch": 1, "conflict": 1 },
      "penalty_points": 6,
      "penalty_factor": 0.30,
      "score_adjustment": -0.045
    }
  }
}
```

### 12e. Apply consistency penalty to flow score

Read `flow_score.consistency_penalty_weight` from config (0.15).

Compute penalty using severity weights from references/flow.md Section 11:
```
critical_count = number of "conflict" severity findings
issue_count = number of "mismatch" severity findings
warning_count = number of "drift" severity findings

penalty_points = critical_count * 3 + issue_count * 2 + warning_count * 1
penalty_ratio = min(1.0, penalty_points / 20)
consistency_penalty = penalty_ratio * consistency_penalty_weight
```

The penalty is applied in Section 13 (Flow Score Aggregation):
```
final_flow_score = weighted_flow_score * (1 - consistency_penalty)
```

Update `flow_score.consistency_penalty` in flow-state.json with the computed penalty value (replacing null).

### 12f. Display consistency findings

```
┌─ CONSISTENCY ───────────────────────────────────────────────┐
│  {total} findings: {critical} critical · {issues} issues · {warnings} warnings
│                                                               │
│  ✗ {critical finding 1}                                       │
│  ⚠ {issue finding 1}                                         │
│  ○ {warning finding 1}                                        │
│                                                               │
│  Score penalty: -{penalty_percentage}%                        │
└──────────────────────────────────────────────────────────────┘
```

If no consistency findings: show `✓ No cross-screen consistency issues detected` and skip the penalty.

---

## 13. Flow Score Aggregation

### 13a. Compute weighted flow score

Read `flow_score` config from flow-scoring.json.

For each screen:
- Get the screen's weighted_score (from review.weighted_score)
- Get the position weight: first=1.5, last=1.5, middle=1.0

Formula:
```
flow_score = sum(screen_score * position_weight) / sum(position_weight)
```

Example with 4 screens:
```
Screen 1 (first): 3.0 * 1.5 = 4.5
Screen 2 (middle): 2.5 * 1.0 = 2.5
Screen 3 (middle): 2.8 * 1.0 = 2.8
Screen 4 (last): 3.2 * 1.5 = 4.8
Total weighted = 14.6, total weights = 5.0
flow_score = 14.6 / 5.0 = 2.92
```

**Consistency penalty:** After computing the weighted average, apply the consistency penalty from Section 12:
```
final_flow_score = weighted_flow_score * (1 - consistency_penalty)
```

If consistency_penalty is 0 (no findings), the final score equals the weighted average. The penalty reduces the score by up to 15% (when consistency issues are severe).

### 13b. Determine flow verdict

Use the page type from the first screen's PAGE_BRIEF and the thresholds from config/scoring.json:
- **SHIP:** flow_score >= threshold AND no critical cross-screen issues
- **CONDITIONAL:** flow_score within 0.3 of threshold AND issues are fixable
- **BLOCK:** flow_score < threshold - 0.3 OR critical issues found

### 13c. Store flow score

Add to flow-state.json top level:

```json
{
  "flow_score": {
    "weighted_score": 2.92,
    "display_score": 7.3,
    "verdict": "CONDITIONAL",
    "position_weights_applied": { "1": 1.5, "2": 1.0, "3": 1.0, "4": 1.5 },
    "page_type": "landing",
    "threshold": 3.0,
    "consistency_penalty": 0.045,
    "pre_penalty_score": 2.92
  }
}
```

The `display_score` is `final_flow_score * 2.5` (per shared/output.md conversion). The `consistency_penalty` is computed by Section 12 -- it is 0 when no consistency issues are found. The `pre_penalty_score` preserves the weighted average before penalty application.

---

## 14. Flow Review Summary

Display the complete flow audit results using branded output from shared/output.md.

### 14a. Per-screen score table

```
┌─ FLOW REVIEW ───────────────────────────────────────────────┐
│                                                               │
│  Screen 1: {name}                                             │
│  {score_bar} {display_score}/10  ·  {verdict}  ·  full        │
│  Top finding: {highest priority finding}                      │
│                                                               │
│  Screen 2: {name}                                             │
│  {score_bar} {display_score}/10  ·  {verdict}  ·  quick       │
│  Top finding: {highest priority finding}                      │
│                                                               │
│  Screen 3: {name}                                             │
│  {score_bar} {display_score}/10  ·  {verdict}  ·  quick       │
│  Top finding: {highest priority finding}                      │
│                                                               │
│  Screen 4: {name}                                             │
│  {score_bar} {display_score}/10  ·  {verdict}  ·  full        │
│  Top finding: {highest priority finding}                      │
└──────────────────────────────────────────────────────────────┘
```

Score bars follow shared/output.md format: `{filled}{empty} {display}/10` where filled=round(internal*2.5) blocks of `█`, empty blocks of `░`, total 10.

### 14b. Animation findings box

```
┌─ ANIMATION ─────────────────────────────────────────────────┐
│  Transitions: {total} detected across {N} screens            │
│  Events: {total} animation/transition events captured         │
│  prefers-reduced-motion: {PASS|PARTIAL|FAIL}                 │
│                                                               │
│  {finding 1}                                                  │
│  {finding 2}                                                  │
└──────────────────────────────────────────────────────────────┘
```

### 14c. Consistency findings box

```
┌─ CONSISTENCY ───────────────────────────────────────────────┐
│  {total} findings: {critical} critical · {issues} issues · {warnings} warnings
│                                                               │
│  ✗ {critical finding description}                             │
│  ⚠ {issue finding description}                               │
│  ○ {warning finding description}                              │
│                                                               │
│  Score penalty: -{penalty_percentage}%                        │
└──────────────────────────────────────────────────────────────┘
```

If no consistency findings were detected:
```
┌─ CONSISTENCY ───────────────────────────────────────────────┐
│  ✓ No cross-screen consistency issues detected               │
└──────────────────────────────────────────────────────────────┘
```

### 14d. Flow verdict box

```
┌─ FLOW VERDICT ──────────────────────────────────────────────┐
│  {score_bar} {display_score}/10  ·  {verdict}                │
│                                                               │
│  {N} screens  ·  {full_count} full  ·  {quick_count} quick   │
│  Weakest: Screen {N} ({name}) at {score}/10                  │
│  Strongest: Screen {N} ({name}) at {score}/10                │
└──────────────────────────────────────────────────────────────┘
```

### 14e. Top 5 flow-wide fixes

Aggregate findings across all screens AND consistency findings, deduplicate, and rank by:
1. Consistency conflicts rank highest (cross-screen issues affect every user)
2. Cross-specialist agreement (found by 2+ specialists across screens)
3. Severity (critical > high > medium)
4. Frequency (appears on multiple screens)

Consistency findings with "conflict" severity should rank above single-screen issues. A consistency "mismatch" ranks alongside cross-specialist agreements.

```
### Top 5 Fixes
1. {fix} -- Screen(s) {N, M} -- {specialist(s)}
2. {fix} -- Screen(s) {N} -- {specialist(s)}
3. {fix} -- Screen(s) {N, M, P} -- {specialist(s)}
4. {fix} -- Screen(s) {N} -- {specialist(s)}
5. {fix} -- Screen(s) {N, M} -- {specialist(s)}
```

### 14f. Next step hint

```
Next: Generating HTML diagnostic report...
```

### 14g. Footer

```
github.com/spsk-dev/tasteful-design
```

---

## 15. Generate HTML Diagnostic Report

After the flow review summary (Section 14), generate the self-contained HTML report.

### 15a. Call report generator

Run the report generator script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh" "${AUDIT_DIR}/flow-state.json" "${AUDIT_DIR}/report-$(date -u +%Y%m%dT%H%M%SZ).html"
```

Store the output path as `REPORT_PATH`.

**If the script fails** (non-zero exit):
- Show warning: `Warning: HTML report generation failed. Flow results are still available in flow-state.json.`
- Do NOT fail the entire audit -- the terminal summary from Section 14 already shows results
- Log the error to flow-state.json: `"report_error": "{error message}"`

### 15b. Update flow-state.json

Add the report path to flow-state.json:
```json
{
  "report_path": "{REPORT_PATH}"
}
```

### 15c. Display report path

Show branded output:
```
┌─ REPORT ──────────────────────────────────────────────────┐
│  ✓ HTML report generated                                   │
│  Path: {REPORT_PATH}                                       │
│                                                             │
│  Open in browser to view full diagnostic with screenshots  │
└────────────────────────────────────────────────────────────┘
```

<!-- design-audit.md: 15 sections — navigation (1-9), review (10), animation (11), consistency (12), scoring (13), summary (14), report (15) -->
