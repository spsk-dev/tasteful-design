# Flow Navigation Reference -- Flow Audit Specialist

Agent-consumable knowledge for navigating multi-screen SPA flows, detecting screen transitions, and capturing screenshots at each stable state.

## 1. Screen Detection Heuristics

A "new screen" in a SPA means the user-visible content has meaningfully changed. Do NOT rely on `networkidle` -- SPAs with analytics, WebSockets, or chat widgets never reach network idle.

**Primary signal: DOM stability via MutationObserver**

After clicking a CTA or navigating, inject this via `browser_evaluate`:

```javascript
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

**Secondary signal: Font readiness**

After DOM stability, check fonts before capturing a screenshot:

```javascript
(function() {
  return Promise.race([
    document.fonts.ready.then(() => ({ fontsReady: true })),
    new Promise(resolve => setTimeout(() => resolve({ fontsReady: false, timeout: true }), 5000))
  ]);
})()
```

**Never use `networkidle`** -- it will hang on production SPAs with Google Analytics, Intercom, Hotjar, or any WebSocket connection.

## 2. Flow Intent Mapping

When the user provides `--flow "complete the onboarding"`, you must match that intent to visible CTAs at each step.

**CTA identification priority:**
1. Primary buttons (larger, higher contrast, prominent position) -- e.g., "Get Started", "Continue", "Next"
2. Links styled as buttons -- same visual weight as buttons
3. Navigation links matching the flow intent -- e.g., "Sign Up" in a nav bar
4. Form submit buttons -- "Submit", "Save", "Create Account"

**Matching strategy:**
- Read `browser_snapshot` accessibility tree for buttons, links, and form elements
- Match CTA text against the flow intent semantically -- "complete onboarding" matches "Get Started", "Continue", "Next Step"
- If multiple CTAs match, prefer: (a) the one below the fold in the main content area, (b) the one with larger visual prominence, (c) the one that appears to advance the flow (not "Skip" or "Later")
- If NO CTA matches the intent, check if you have reached a success state (Section 5) or a dead end (Section 4)

**At each step, report:**
```
Screen {N}: {name} -- clicking "{CTA text}" (ref: {element_ref})
```

## 3. SPA Navigation Patterns

SPAs change content without traditional page loads. Detect these patterns:

**pushState / replaceState navigation:**
- URL changes in the address bar but no page load event fires
- After clicking, check if URL changed via `browser_evaluate`:
  ```javascript
  window.location.href
  ```
- A URL change + DOM mutations = new screen

**In-page transitions (no URL change):**
- Tabs: content area changes but URL stays the same
- Wizard steps: step indicator advances, form content swaps
- Modals: overlay appears with new content
- Accordions: content expands/collapses
- These count as new screens IF the visible content is substantially different

**How to confirm a new screen loaded:**
1. Click the CTA
2. Wait 300ms (post-click settle time from config)
3. Run DOM stability check (Section 1)
4. Take a fresh `browser_snapshot`
5. Compare: new heading text? New URL? Substantially different content?
6. If yes -> new screen detected, capture screenshot
7. If no -> the click may not have triggered navigation. Try again or report dead end.

## 4. Dead End Detection

A dead end means the flow cannot proceed. Detect and handle gracefully:

**No matching CTAs:**
- `browser_snapshot` shows no buttons, links, or form submits that match the flow intent
- All visible CTAs are unrelated to the flow (e.g., social media links on a 404 page)

**Error pages:**
- HTTP 4xx/5xx status (check page content for error messages)
- "Page not found", "404", "Something went wrong", "Error"
- Blank pages or pages with only a header/footer

**Infinite redirect loops:**
- Same URL or same content appearing after navigation (compare to previous screen)
- Track visited URLs -- if you return to a previously visited URL, the flow is looping

**What to do at a dead end:**
1. Capture a screenshot of the dead-end state
2. Log the dead end in flow-state.json with `"dead_end": true` and reason
3. Set flow status to `"status": "dead_end"`
4. Report to user: `Dead end at Screen {N}: {reason}`

## 5. Success State Detection

A success state means the flow completed its goal. Detect these patterns:

**Confirmation messages:**
- Text containing: "Thank you", "Success", "Complete", "Confirmed", "All done", "Congratulations"
- Order/submission confirmation with a reference number
- Email confirmation messages ("Check your inbox")

**Post-flow redirects:**
- Redirect to dashboard, home page, or account page after completing a form flow
- URL changes to a known "done" path (e.g., `/dashboard`, `/welcome`, `/confirmation`)

**Visual indicators:**
- Checkmark icons or success illustrations
- Progress bar at 100%
- "Step X of X" showing final step completed

**What to do at success:**
1. Capture the success screen
2. Set flow status to `"status": "complete"`
3. Report: `Flow complete at Screen {N}: {success indicator}`

## 6. Cookie/Popup Handling

Many sites show interruptions that are NOT part of the flow. Handle them before proceeding:

**Cookie consent banners:**
- After initial `browser_navigate`, check the snapshot for cookie banner patterns
- Look for: "Accept", "Accept All", "I Agree", "Got it" buttons within a banner/dialog
- Click the accept button to dismiss
- If not found or click fails, proceed -- the user can dismiss manually in headed mode

**Promotional modals/overlays:**
- Dismiss buttons: "X", "Close", "No thanks", "Maybe later", "Skip"
- If the modal content matches the flow intent, treat it as a flow screen instead
- If unrelated, dismiss and continue

**Onboarding tooltips:**
- Often appear as step-by-step tours on first visit
- Dismiss via "Skip tour", "Got it", "Next" (if short) or click the backdrop
- These are NOT flow screens

**How to distinguish flow-relevant modals from interruptions:**
- Flow-relevant: content matches the user's flow intent (e.g., "Confirm your email" during onboarding)
- Interruption: content is about cookies, promotions, newsletters, app store downloads, chat widgets

## 7. Screenshot Timing

Capture screenshots only when the page is visually stable and complete.

**Capture sequence (in order):**
1. Wait for DOM stability (Section 1 -- MutationObserver, 800ms quiet)
2. Wait for fonts to load (Section 1 -- `document.fonts.ready`, 5s timeout)
3. Dismiss any popups/banners that appeared (Section 6)
4. Take screenshot via `browser_take_screenshot`

**Screenshot parameters:**
- Viewport: 1440x900 (from config `screenshot.viewport`)
- Format: PNG (from config `screenshot.format`)
- Full page: false (from config `screenshot.full_page`) -- capture only the viewport

**Naming:** `screen-{N}-{slug}.png` where N is the 1-indexed screen number and slug is generated per Section 8.

## 8. Slug Generation

Generate a URL-safe slug for each screen's screenshot filename.

**Priority order:**
1. First `<h1>` heading text from the page
2. First `<h2>` heading text (if no h1)
3. Last segment of the URL path (e.g., `/onboarding/company` -> `company`)
4. Fallback: `screen-{N}` (e.g., `screen-3`)

**Slugify rules:**
- Lowercase the text
- Replace spaces and underscores with hyphens
- Strip all characters that are not alphanumeric or hyphens
- Collapse consecutive hyphens into one
- Trim leading/trailing hyphens
- Truncate to 40 characters
- If truncation breaks mid-word, truncate at the last complete word

**Examples:**
- "Welcome to Fuse" -> `welcome-to-fuse`
- "Company Information" -> `company-information`
- "Step 3: Upload Documents" -> `step-3-upload-documents`
- "" (no heading, URL `/settings/billing`) -> `billing`
- "" (no heading, no URL change) -> `screen-4`
