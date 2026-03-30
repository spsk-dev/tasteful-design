---
name: design-audit
description: >
  Flow-level design audit -- navigates multi-screen SPA flows using Playwright MCP,
  captures screenshots at each state change, and produces flow state for downstream
  review and reporting. Use when the user says "audit the flow", "design audit",
  "walk through the onboarding", "/design audit", or wants to evaluate a multi-screen
  user journey.
allowed-tools: Bash(mkdir *), Bash(cp *), Bash(rm *), Bash(cat *), Bash(npx *)
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
  "cta_ref": "{element_ref}"
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

### Step D: Capture screenshot

Generate slug from the page heading or URL path (same logic as Intent Mode Step G).

Call `browser_take_screenshot`:
```
{AUDIT_DIR}/screen-{N}-{slug}.png
```

### Step E: Update flow-state.json

Append screen entry (same format as Intent Mode Step H, but with `"cta_clicked": null` and `"cta_ref": null` since no CTA clicking occurs):

```json
{
  "number": {N},
  "name": "{screen_name}",
  "slug": "{slug}",
  "url": "{current URL from steps list}",
  "screenshot_path": "{AUDIT_DIR}/screen-{N}-{slug}.png",
  "timestamp": "{ISO 8601}",
  "cta_clicked": null,
  "cta_ref": null
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

### 8b. Show branded summary

```
┌─ FLOW COMPLETE ─────────────────────────────────────────────┐
│  Status:      {complete | dead_end | max_screens_reached}    │
│  Screens:     {N} captured                                   │
│  Duration:    {elapsed time}                                 │
│  Screenshots: {AUDIT_DIR}/                                   │
│  Flow state:  {AUDIT_DIR}/flow-state.json                    │
└──────────────────────────────────────────────────────────────┘
```

List each captured screen:
```
  1. {screen_name} -- {screenshot_filename}
  2. {screen_name} -- {screenshot_filename}
  ...
```

### 8c. Next step hint

```
Next: Run Phase 5 review to analyze captured screens
```

### 8d. Footer

```
github.com/spsk-dev/tasteful-design
```

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

- **Phase 4 is navigation + capture only.** Do NOT import or dispatch specialist reviews -- that is Phase 5.
- **Do NOT generate HTML reports.** That is Phase 6.
- **Every browser interaction uses Playwright MCP tools.** Never write shell scripts for navigation.
- **Always take a fresh `browser_snapshot` immediately before `browser_click`.** Stale element refs cause failures (Pitfall 5).
- **Never use `networkidle`.** SPAs with analytics/WebSockets never reach idle (Pitfall 1).
- **Progressive persistence.** Write flow-state.json after every screen capture. Mid-flow failures must preserve partial results.
- **The flow-state.json is the contract** between Phase 4 and Phases 5/6. Match the schema exactly.
