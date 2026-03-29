---
name: design-review
description: >
  Multi-agent visual design review — 8 specialist agents + boss synthesizer evaluate UI quality
  across font, color, layout, icon, motion, intent, copy, and code dimensions. Use this skill
  whenever you've built or modified frontend UI and want honest design feedback. Also use when:
  the user says "review the design", "how does this look", "check the UI", "design review",
  "evaluate the visuals", "is this good enough to ship", or after completing any frontend task
  where visual quality matters. Trigger on /design-review or when user asks for visual evaluation.
allowed-tools: Bash(gemini *), Bash(which *), Bash(npx *), Bash(python3 *), Bash(curl *), Bash(kill *), Bash(mkdir *), Bash(cp *), Bash(rm *), Bash(lsof *)
---

@${CLAUDE_PLUGIN_ROOT}/shared/output.md

## Output Format

Use the branded output format from shared/output.md for all review output. Start with the signature line, use single-line Unicode boxes for sections, end with the footer. Display each specialist score using the score bar format: ████████░░ 8.0/10. Wrap each specialist section in a single-line Unicode box with the specialist name as header. Use the symbol vocabulary for status indicators (✓ pass, ✗ fail, ⚠ warning).

# Design Review v4 — 8-Specialist Agent Swarm

## Why This Exists

AI models are terrible self-critics of visual output. They "reliably skew positive" and "confidently praise the work — even when the quality is obviously mediocre." This skill fixes it by dispatching 8 specialist agents in parallel, each focused on one design dimension with domain expertise from reference files. A boss synthesizer merges findings with cross-specialist confidence scoring.

## Pre-flight: Environment & Mode

### Tool check

```bash
GEMINI_AVAILABLE=false; PLAYWRIGHT_AVAILABLE=false
which gemini 2>/dev/null && GEMINI_AVAILABLE=true
npx playwright --version 2>/dev/null && PLAYWRIGHT_AVAILABLE=true
echo "Gemini: $GEMINI_AVAILABLE | Playwright: $PLAYWRIGHT_AVAILABLE"
```

### Review tier (never fail silently — always report which tier ran)

| Tier | Condition | Color/Layout via | Quality |
|------|-----------|-----------------|---------|
| 1 — Full | Gemini + Playwright | Gemini CLI | Best — cross-model consensus |
| 2 — No Gemini | Playwright only | Claude Sonnet agents | Good — note correlated blind spots |
| 3 — Code-only | No Playwright | N/A | Minimal — ⚠️ warn user |

If Tier 3: warn that visual review is impossible, recommend `npx playwright install chromium`. Proceed code-only only if user confirms.

### Mode (parse `$ARGUMENTS`)

- **`--quick`**: 4 core specialists (Font, Color, Layout, Intent/Originality). For iterative fix cycles.
- **Default (full)**: All 8 specialists. For final review before shipping.

Quick mode formula: `(Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout) / 13`
Quick mode runs: Font (#1), Color (#2), Layout (#3), Intent/Originality/UX (#6) — 4 agents, 6 scored dimensions.
Quick mode skips: Icon (#4), Motion (#5), Copy (#7), Code (#8). Saves ~40-50% tokens.
If `--quick` AND Tier 3: run Intent + Code only (minimal useful review). Warn user.

### Style preset (parse `$ARGUMENTS` or config)

Read `${CLAUDE_PLUGIN_ROOT}/config/style-presets.json`. Check `active_preset` field — if set, load that preset. Can also be overridden with `--style <preset-name>` in arguments.

```
/design-review --style fun-lighthearted
/design-review --style serious-dashboard
/design-improve --style animation-heavy "build a landing page"
```

**When a style preset is active**, append to every specialist prompt:
```
STYLE PRESET: "{preset_name}" — {description}
Evaluate this page against this style direction:
- Tone: {tone}
- Animations: {animations}
- Colors: {colors}
- Typography: {typography}
- Layout: {layout}
Reference sites: {reference_sites}

Score based on how well the page matches THIS style, not generic standards.
```

The style preset also overrides Phase 1's page classification — instead of the Haiku agent deciding what the design bar should be, the preset IS the design bar.

Presets are stored in the config and persist across sessions. Set once, applies to all reviews in the project. Built-in presets: `serious-dashboard`, `fun-lighthearted`, `animation-heavy`, `minimal-editorial`, `startup-landing`. Add custom presets by editing the JSON.

### Design references (parse `$ARGUMENTS`)

External references replace the generic gold-standard comparison with a specific design target.

- **`--ref <url>`**: Screenshot the reference URL with Playwright (same 3 viewports). Pass reference screenshots alongside the page screenshots to ALL visual specialists. Specialists compare the page against the reference instead of imagined gold standards.
- **`--ref <file.md>`**: Read the file as a design spec. Expected format: fonts, colors (hex), spacing rules, layout notes. Pass the content to all specialists as "the design system to follow."
- **`--ref <figma-url>`**: Use the Figma MCP (`get_design_context` or `get_screenshot`) to pull the design. Pass Figma screenshot + code hints to specialists as the gold standard.
- **`--palette "#hex1,#hex2,#hex3,..."`**: Override color evaluation — the Color specialist checks whether the page uses these colors correctly instead of judging the palette choice itself.
- **`--fonts "Font1,Font2"`**: Override font evaluation — the Font specialist checks usage/hierarchy of these fonts instead of judging font choice.

**Reference screenshot capture** (for `--ref <url>`):
```bash
REF_DIR="$REVIEW_DIR/reference"
mkdir -p "$REF_DIR"
npx playwright screenshot "$REF_URL" "$REF_DIR/ref-desktop.png" --viewport-size=1440,900 --full-page
npx playwright screenshot "$REF_URL" "$REF_DIR/ref-mobile.png" --viewport-size=375,812 --full-page
```

**How references change specialist prompts:** When a reference is provided, append to each specialist prompt:
```
REFERENCE: The user provided a design reference. Compare the page against this reference — it is the standard, not generic gold-standard sites. Focus on: where does the page deviate from the reference? What does the reference do better? What should be carried over?
```

For `--ref <url>`: specialists also read the reference screenshots.
For `--ref <file.md>`: specialists read the spec file alongside their domain reference.
For `--palette` / `--fonts`: only the relevant specialist gets the override.

### Figma and direction modes (parse `$ARGUMENTS`)

- **`--figma <figma-url>`**: Review a Figma design *before building it*. Use the Figma MCP to pull `get_screenshot` and `get_design_context`. Specialists review the Figma screenshots as if they were the page. No implementation needed — this catches design issues at the design stage. Skip Code/A11y specialist (no code to review). Phase 0 uses Figma screenshots instead of Playwright.

- **`--figma <figma-url> --compare`**: Fidelity check — compare an *implemented page* against its Figma source. Pull Figma screenshots + take page screenshots. Each specialist gets both and scores: "How faithfully does the implementation match the design?" Focus shifts from "is this good design?" to "does this match the design?" Append to each specialist prompt:
  ```
  FIDELITY CHECK: Compare the implementation (page screenshots) against the Figma design (reference screenshots). Score how closely the implementation matches. Flag: wrong fonts, wrong colors, missing elements, spacing deviations, layout differences, missing states.
  ```

- **`--direction "<text>"`**: Evaluate against a text brief instead of gold standards. The direction string replaces the Phase 1 page classification — instead of the Haiku agent deciding the design bar, the user's direction IS the design bar. Pass the direction to all specialists as the context they evaluate against. Example: `--direction "warm, playful, dog-themed — think Paperless Post but for pets"`.

These modes compose: `--figma <url> --direction "playful and warm"` reviews a Figma design against a specific creative direction.

---

## Phase 0: Screenshots (Non-Negotiable)

Screenshots are the backbone. **NEVER skip them without explicit user confirmation.** If Playwright is unavailable (Tier 3), warn the user and ask — only proceed code-only if they confirm. A code-only review misses visual issues that are the whole point of this skill.

### 0a. Find or start a server

```bash
DEV_URL=""
for PORT in 3000 5173 5174 8080 4321 3001 8000; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "304" ]; then
    DEV_URL="http://localhost:$PORT"
    break
  fi
done

if [ -z "$DEV_URL" ]; then
  HTML_FILE=$(find . -maxdepth 3 -name "index.html" -not -path "*/node_modules/*" | head -1)
  if [ -n "$HTML_FILE" ]; then
    HTML_DIR=$(dirname "$HTML_FILE")
    python3 -m http.server 8787 --directory "$HTML_DIR" &
    SERVER_PID=$!
    sleep 1
    DEV_URL="http://localhost:8787"
  fi
fi
```

If `$ARGUMENTS` contains a URL, use that directly. If it contains a file path, serve that directory.

### 0b. Capture screenshots

```bash
REVIEW_DIR="/tmp/design-review-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REVIEW_DIR"

# Desktop full-page
npx playwright screenshot "$DEV_URL" "$REVIEW_DIR/desktop.png" \
  --viewport-size=1440,900 --full-page 2>/dev/null

# Mobile full-page
npx playwright screenshot "$DEV_URL" "$REVIEW_DIR/mobile.png" \
  --viewport-size=375,812 --full-page 2>/dev/null

# Above-the-fold (no --full-page)
npx playwright screenshot "$DEV_URL" "$REVIEW_DIR/fold.png" \
  --viewport-size=1440,900 2>/dev/null
```

**If Playwright fails:**
```bash
npx playwright install chromium 2>/dev/null
# Then retry screenshots
```

### 0c. Verify

```bash
ls -la "$REVIEW_DIR"/*.png
```

If no screenshots: tell the user to run `npx playwright install chromium`. Do NOT proceed without them.

---

## Phase 0.5: Load Project Design Context

The design plugin maintains a `.design/` directory in the project root — like GSD's `.planning/`. This directory persists across sessions and pages, building up project-level design knowledge.

```bash
DESIGN_DIR="./.design"
if [ ! -d "$DESIGN_DIR" ]; then
  echo "No .design/ directory found. Will create after first review."
fi
```

Read `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/harness.md` for the full `.design/` directory spec, file formats, and lifecycle.

**Quick summary:** `.design/` contains `system.json` (tokens), `components.json` (patterns), `rules.md` (project rules), `decisions.md` (log), and `pages/` (review history per page).

**Loading:** Read `system.json` + `components.json` + `rules.md` → pass to ALL specialists as design system context. Read `pages/{page}.md` → show previous review to specialists for this page.

**If `.design/` exists**, prefix every specialist prompt with:
```
PROJECT DESIGN SYSTEM: This project has established patterns.
Check both domain quality AND consistency with {system.json + components.json + rules.md}.
Flag deviations as [CONSISTENCY] issues.
```

**If `.design/` doesn't exist:** First review — proceed normally, create `.design/` in Phase 4.5.

---

## Phase 1: Page Analysis + Intent Extraction (Haiku Agent — Quick)

Spawn a Haiku agent to classify the page AND extract its intent. It reads the source files only (fast). The output drives every specialist — they evaluate their domain *in service of this intent*, not in isolation.

```
Identify from these source files:

1. Page TYPE: emotional/personal, landing, dashboard, e-commerce, portfolio, SaaS, docs, admin, form, other
2. PAGE INTENT: What is this page trying to achieve? What should the user feel, understand, or do?
   - Example: "Convince indie musicians to sign up for a free trial by making them feel this is built for creators like them"
   - Example: "Let an admin configure notification preferences efficiently with zero confusion"
   - Example: "Make a dog's mother cry with love and recognition"
3. TARGET AUDIENCE: Who is this for? What do they care about? What's their context when they arrive?
4. PRIMARY ACTION: What is the single most important thing the user should do on this page?
5. WHAT COMES NEXT: After the primary action, where does the user go? What's the next step in the journey?
6. DESIGN BAR:
   - Admin/settings/docs: template design is fine, focus on usability
   - Landing/marketing: creativity required, must stand out
   - Portfolio/showcase: design IS the product, highest bar
   - Emotional/personal: warmth and personality required
7. GOLD STANDARDS: 2-3 reference sites that nail this intent.
8. UX PRIORITIES: Top 3 things that matter most for this page's success (e.g., "CTA visibility", "scan speed", "emotional warmth").

Return a structured brief. This brief goes to ALL specialists — they evaluate their domain in service of this intent.
```

Save the output as `PAGE_BRIEF`. It includes: `PAGE_TYPE`, `INTENT`, `AUDIENCE`, `PRIMARY_ACTION`, `NEXT_STEP`, `DESIGN_BAR`, `REFERENCES`, `UX_PRIORITIES`.

**Every specialist gets the full PAGE_BRIEF.** This is how the Font specialist knows to evaluate warmth (for a dog love letter) vs scan speed (for an admin panel). Without intent context, specialists evaluate in a vacuum.

**If intent is unclear: ASK the user.** If the Haiku agent cannot determine the page's intent, audience, or primary action from the source code alone (e.g., it's a generic component, a blank template, or an ambiguous layout), STOP and ask the user:

```
I can't confidently determine the page's intent from the source code.
Before I run the 8 specialists, I need to know:
1. What is this page trying to achieve?
2. Who is the target audience?
3. What's the primary action a user should take?

This matters because a "settings page" and a "landing page" are held to completely different standards.
```

Do NOT guess and proceed — a wrong intent classification poisons all 8 specialist evaluations. Better to ask than to review against the wrong standard.

---

## Phase 2: Specialist Dispatch (8 Agents in Parallel)

Launch ALL 8 in the SAME turn. Each specialist:
- Gets screenshots + source files + the **full `PAGE_BRIEF`** (intent, audience, primary action, next step)
- Reads their reference file from `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/`
- Must find at least 2 issues (no "looks great" allowed)
- **Evaluates their domain IN SERVICE OF the page intent** — not in a vacuum
- Returns: findings list + single domain score 1-4

**Context prefix for EVERY specialist prompt:**
```
PAGE CONTEXT (evaluate your domain in service of this intent):
- Intent: {INTENT from PAGE_BRIEF}
- Audience: {AUDIENCE}
- Primary action: {PRIMARY_ACTION}
- What comes next: {NEXT_STEP}
- UX priorities: {UX_PRIORITIES}

{IF DESIGN_SYSTEM exists:}
PROJECT DESIGN SYSTEM: This project has established design patterns (see below).
Check whether this page FOLLOWS these patterns. Flag deviations as consistency issues.
Buttons should use border-radius: {buttons.border_radius}, colors: {tokens.colors.*}, fonts: {tokens.typography.*}, etc.
{contents of .design/system.json + .design/components.json + .design/rules.md}
{END IF}

Given this context, evaluate {your domain}. A choice that's wrong for a dashboard might be right for a love letter. Score based on how well your domain SERVES this specific intent AND follows the established design system (if one exists).
```

**IMPORTANT — Orchestrator responsibilities** (subagents cannot run Bash):
1. YOU (the orchestrator) take all screenshots in Phase 0
2. YOU copy files to the workspace for Gemini in Phase 2
3. YOU run the Gemini CLI commands for Color and Layout
4. Specialists 1, 4-8 are Claude agents that Read files — they need no Bash

**Before dispatching, clean stale files and copy fresh ones for Gemini:**
```bash
# Clean stale files from previous runs (prevents contamination)
rm -f ./desktop-review.png ./mobile-review.png ./fold-review.png 2>/dev/null
rm -f ./.color-reference.md ./.layout-reference.md ./.icons-reference.md ./.intent-reference.md 2>/dev/null

# Copy fresh screenshots
cp "$REVIEW_DIR/desktop.png" ./desktop-review.png
cp "$REVIEW_DIR/mobile.png" ./mobile-review.png
cp "$REVIEW_DIR/fold.png" ./fold-review.png

# Copy reference files Gemini needs (it can only read workspace files)
cp ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/color.md ./.color-reference.md 2>/dev/null
cp ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/layout.md ./.layout-reference.md 2>/dev/null
```

**Gemini retry protocol** (Specialists 2 & 3): Run `gemini -y -p "..."`. If output contains "exhausted your capacity" or "rate limit", wait 10s and retry once. If still failing, dispatch a Claude Sonnet agent with the same prompt reading the screenshot PNGs + reference file instead. Note the fallback in the final review: "Color/Layout reviewed by Claude Sonnet (Gemini unavailable)."

**Quick mode**: If `--quick`, dispatch only Specialists 1, 2, 3, 6. Skip 4, 5, 7, 8.

### Specialist 1: Font (Claude Sonnet Agent)

Reads: screenshots (Read the PNG files) + source files + `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/typography.md`

```
You are a typography specialist. Read skills/design-review/references/typography.md for your expert knowledge.

PAGE CONTEXT: {PAGE_BRIEF}

Read these screenshots visually: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png, {REVIEW_DIR}/fold.png
Read the source files: {file list}
Read: ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/typography.md

REVIEW:
- Font choices: are they AI-overused? (check the reference for the overused list)
- Pairing quality: max 2 families + optional mono, contrast not conflict
- Hierarchy: size scale, weight distribution (4-weight system), visual clarity
- Line-height by size: decreases as size increases (reference has exact values)
- Letter-spacing: ALL CAPS must have +0.05em tracking, display text needs negative tracking
- Measure: 45-75 chars per line, 65ch ideal

FLAG SPECIFICALLY: Dancing Script, Playfair+Poppins combos, 3+ families, no tracking on ALLCAPS, hero text under 48px, centered body paragraphs, light (300) weight body text.

Find at least 2 issues. Score: Typography Quality 1-4.
Return: issues list with specific elements + score + one-line summary.
```

### Specialist 2: Color (Gemini CLI)

Reads: screenshots only. If Gemini unavailable, use Claude Sonnet agent reading screenshots.

```bash
cd "$(pwd)" && gemini -y -p "You are a color specialist.

PAGE CONTEXT: {PAGE_BRIEF}

Read these images in the current directory:
- desktop-review.png
- mobile-review.png
- fold-review.png

Also read the file: .color-reference.md

REVIEW:
- Palette cohesion: does it follow 60/30/10 rule?
- WCAG contrast: measure text-on-background ratios (reference has common failures)
- Dark/light mode execution: pure #000/#FFF? Tinted darks? Elevation by lightness?
- Color-mood match: does the palette fit the page type?
- Accent usage: one gradient per view, 1-2 accent hues max

FLAG SPECIFICALLY: AI purple gradients (synthwave SaaS), dark+gold cliche, low-contrast text, pure #000 or #FFF backgrounds, oversaturated gradient buttons, gray-everything palettes.

Find at least 2 issues. Score: Color Quality 1-4.
Return: issues list with specific colors/elements + score + one-line summary."
```

*(Color reference was already copied to `.color-reference.md` in the pre-dispatch step above.)*

### Specialist 3: Layout (Gemini CLI)

Reads: screenshots only. If Gemini unavailable, use Claude Sonnet agent.

```bash
cd "$(pwd)" && gemini -y -p "You are a layout specialist.

PAGE CONTEXT: {PAGE_BRIEF}

Read these images: desktop-review.png, mobile-review.png, fold-review.png
Also read: .layout-reference.md (your expert knowledge on layout)

REVIEW:
- Spacing consistency: are gaps between similar elements equal?
- Responsive behavior: compare desktop vs mobile — what changes, what breaks?
- Section rhythm: do sections vary in layout or is it monotonous repetition?
- Alignment: are elements on a grid? Any orphaned elements?
- Whitespace: breathing room or cramped? Content width reasonable?
- Content measure: text blocks too wide (>80ch)?

FLAG SPECIFICALLY: wall-of-cards, monotonous card repetition, inconsistent gaps, no responsive breakpoints, elements that overflow/overlap on mobile, cramped sections.

Find at least 2 issues. Score: Layout Quality 1-4.
Return: issues list with specific positions/measurements + score + one-line summary."
```

### Specialist 4: Icon (Claude Sonnet Agent)

Reads: screenshots + source files.

```
You are an icon specialist.

PAGE CONTEXT: {PAGE_BRIEF}

Read screenshots: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png
Read source files: {file list}

REVIEW:
- Icon library: Lucide/Phosphor = good, mixed sets = bad. Which library(ies)?
- Sizing consistency: are all icons the same size in similar contexts?
- Stroke weight: consistent across all icons?
- Filled vs outline: consistent style or mixed?
- Icon-text alignment: vertically centered with adjacent text?
- Accessibility: aria-labels on icon-only buttons?

FLAG SPECIFICALLY: mixed icon libraries, emoji-as-icons, malformed SVGs, inconsistent sizes within same context, missing aria-labels on icon-only actions.

Find at least 2 issues. Score: Icon Quality 1-4.
Return: issues list with specific icons/components + score + one-line summary.
```

### Specialist 5: Motion (Claude Sonnet Agent)

Reads: source code ONLY (cannot see animations in screenshots).

```
You are a motion/animation specialist.

PAGE CONTEXT: {PAGE_BRIEF}

Read source files: {file list}

REVIEW (code-only — you cannot see the running animations):
- Animation quality: keyframe definitions, transition timing functions
- Performance: will-change usage, GPU-composited properties (transform, opacity)
- prefers-reduced-motion: is it supported? Must be present for any animation.
- CSS bugs: transform property clobbering (multiple transforms override each other), duplicate declarations
- Infinite animations: do they have cleanup? Are they appropriate?
- Timing: easing curves (linear = robotic, ease-in-out = natural), duration (150-300ms for micro, 300-500ms for layout)

FLAG SPECIFICALLY: animate-bounce on functional UI elements, animations without reduced-motion support, transform overrides clobbering earlier transforms, excessive animation (too many things moving).

Find at least 2 issues. Score: Motion Quality 1-4.
Return: issues list with file:line references + score + one-line summary.
```

### Specialist 6: Intent, Originality & UX (Claude Sonnet Agent)

Reads: screenshots + source + PAGE_BRIEF + `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/intent.md`. This is the most important specialist (3x weight) because it answers the hardest questions: does this LOOK like what it's trying to BE, and can users actually DO what the page wants them to?

```
You are a design intent, originality, and UX specialist.

PAGE CONTEXT: {full PAGE_BRIEF — intent, audience, primary action, next step, UX priorities}
Gold-standard references: {REFERENCES from Phase 1}

Read screenshots: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png, {REVIEW_DIR}/fold.png
Read source files: {file list}
Read reference: ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/intent.md

REVIEW THREE DIMENSIONS:

1. INTENT MATCH: Does the visual design match the page's purpose?
   - Does the design's emotional tone match the content's tone?
   - A love letter should feel warm, not corporate. An admin panel should feel functional, not decorative.
   - Does the design SERVE the content or fight it?
   - Would the target audience ({AUDIENCE}) feel "this was made for me"?

2. ORIGINALITY: Is this creative when it should be? Template-appropriate when that's correct?
   - Compare against the gold-standard references: what would they do differently?
   - "Would a real designer be proud of this, or does it look like every other AI output?"
   - Does it have a distinct visual identity or is it interchangeable with any other page?

3. UX & FLOW: Can the user accomplish the PRIMARY ACTION ({PRIMARY_ACTION})?
   - Is the CTA visible above the fold? Is the action hierarchy clear?
   - Does the page guide the user toward the primary action or distract?
   - After the primary action, is the NEXT STEP ({NEXT_STEP}) clear?
   - Information architecture: is content organized in the order the user needs it?
   - Affordances: do interactive elements look interactive? Are inputs discoverable?
   - Mobile UX: can you complete the primary action on mobile without frustration?
   - Error/empty states: what happens when things go wrong or there's no data?

FLAG SPECIFICALLY: "AI slop" patterns, designs that fight their content's intent, broken user flows, buried CTAs, unclear next steps, missing states.

Find at least 3 issues (1+ per dimension). THREE scores:
- Intent Match: 1-4
- Originality: 1-4
- UX Flow: 1-4
Return: issues list + all 3 scores + one-line summary each.
```

### Specialist 7: Copy & Language (Claude Haiku Agent)

Reads: source code (extracts visible text).

```
You are a copy and language specialist.

PAGE CONTEXT: {PAGE_BRIEF}

Read source files: {file list}

Extract ALL user-visible text from the source. Then review:
- Spelling and grammar errors
- Missing accents/diacritics (especially Spanish: corazon→corazón, anos→años, dia→día, mama→mamá)
- Placeholder text still present (lorem ipsum, "Your text here", TODO)
- Generic labels: "Submit", "OK", "Click Here", "Learn More" without context
- Tone match: does the copy tone fit the page type?
- CTA quality: are calls-to-action specific and compelling?
- Consistency: same concept described differently in different places?

FLAG SPECIFICALLY: missing Spanish accents, lorem ipsum, "Submit"/"OK"/"Click Here", tone mismatches (corporate language on a personal page), inconsistent terminology.

Find at least 2 issues. Score: Copy Quality 1-4.
Return: issues list with exact text quotes + score + one-line summary.
```

### Specialist 8: Code & Accessibility (Claude Sonnet Agent)

Reads: source code only.

```
You are a code quality and accessibility specialist for frontend.

PAGE CONTEXT: {PAGE_BRIEF}

Read source files: {file list}

REVIEW:
- Hardcoded values: hex colors instead of CSS variables, magic px/rem numbers
- Missing states: loading, empty, error, hover, focus, disabled — which are absent?
- Responsive code: breakpoints present? max-width constraints? Mobile-first or desktop-first?
- Accessibility: alt text on images, aria-labels on interactive elements, semantic HTML (nav, main, section, article), color-only indicators (needs icon/text too), focus management, skip links
- SEO: meta title, description, og:image, canonical URL
- Code patterns: inline styles vs classes, component reusability

FLAG SPECIFICALLY: missing alt text, missing aria-labels on buttons/links, no focus styles, color-only status indicators, no meta tags, all inline styles, no responsive breakpoints.

Find at least 2 issues. Score: Code Quality 1-4.
Return: issues list with file:line references + score + one-line summary.
```

---

## Phase 3: Boss Designer Synthesis

Read the scoring configuration from `${CLAUDE_PLUGIN_ROOT}/config/scoring.json` for weights and thresholds. If the file doesn't exist, use the defaults below.

After all 8 specialists return, YOU (the orchestrator) synthesize. You do NOT re-evaluate. You trust the specialists and merge.

### 3a. Cross-specialist agreement

Issues found by 2+ specialists get **HIGH confidence**. Flag these prominently.

### 3b. Deduplicate

Same issue from multiple specialists: merge into one, keep the most specific description, note which specialists found it.

### 3c. Compute weighted score

| Specialist | Weight | Rationale |
|-----------|--------|-----------|
| Intent Match | 3x | Does it match its purpose? Most important. |
| Originality | 3x | Creative vs generic? Equally critical. |
| UX Flow | 2x | Can the user DO what the page wants? CTA clarity, flow, next steps. |
| Typography | 2x | Biggest visual impact after intent. |
| Color | 2x | Second biggest visual impact. |
| Layout | 1x | |
| Icons | 1x | |
| Motion | 1x | |
| Copy & Language | 1x | |
| Code & A11y | 1x | |

**Formula**: (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout + Icons + Motion + Copy + Code) / 17

Read weights from `${CLAUDE_PLUGIN_ROOT}/config/scoring.json` if available.

Scale: 1.0 to 4.0

### 3d. Context-aware verdict

The SHIP threshold depends on page type from Phase 1:

| Page Type | Threshold | Rationale |
|----------|-----------|-----------|
| Admin / settings / docs | >= 2.5 | Template design is fine |
| Dashboard / form / e-commerce | >= 2.8 | Usability matters more than wow |
| Landing / marketing / SaaS | >= 3.0 | Creativity required |
| Portfolio / showcase | >= 3.5 | Design IS the product |
| Emotional / personal | >= 3.0 | Warmth and personality required |

- Score >= threshold AND no critical issues: **SHIP**
- Score within 0.3 of threshold AND fixable issues: **CONDITIONAL SHIP**
- Score < threshold - 0.3 OR critical issues: **BLOCK**

### 3e. Present the review

```
## Design Review — {page name}

**Verdict: SHIP / CONDITIONAL SHIP / BLOCK**
**Score: {weighted}/4.0**
**Page Type: {type} — Creativity {required/appropriate/template-ok}**
**Mode: {Full (8/8) | Quick (4/8)} — Tier {1|2|3}**

### Scores
| Specialist | Score | Weight | Key Finding |
|-----------|-------|--------|-------------|
| Intent Match | {n}/4 | 3x | {one-line} |
| Originality | {n}/4 | 3x | {one-line} |
| UX Flow | {n}/4 | 2x | {one-line} |
| Typography | {n}/4 | 2x | {one-line} |
| Color | {n}/4 | 2x | {one-line} |
| Layout | {n}/4 | 1x | {one-line} |
| Icons | {n}/4 | 1x | {one-line} |
| Motion | {n}/4 | 1x | {one-line} |
| Copy & Language | {n}/4 | 1x | {one-line} |
| Code & A11y | {n}/4 | 1x | {one-line} |

**IMPORTANT: Specialist 6 returns THREE scores (Intent, Originality, UX Flow). Each gets its own row in the table. The formula divides by 17, not 15. Do not merge UX Flow into Intent.**

**IMPORTANT: The Score in the header MUST equal the calculated weighted score. Show the calculation explicitly: `(I*3 + O*3 + UX*2 + T*2 + C*2 + L + Ic + M + Cp + Co) / 17 = N/17 = X.XX/4.0`. Do not round or approximate the header differently from the calculation.**

### Cross-Specialist Findings (2+ agree — highest confidence)
{merged issues with specialist sources}

### Top 5 Fixes (priority order)
1. {fix} — found by {specialists}
2. ...
3. ...
4. ...
5. ...

### What Works (max 2 — earned praise only)
{genuinely exceptional things, not filler}

### Gold-Standard Gap
"For a {page_type}, the best sites ({references}) would do X differently. The biggest gap is Y."
```

---

## Phase 4: Cleanup

```bash
# Remove all workspace files (screenshots + reference copies)
rm -f ./desktop-review.png ./mobile-review.png ./fold-review.png 2>/dev/null
rm -f ./.color-reference.md ./.layout-reference.md 2>/dev/null
rm -rf "$REVIEW_DIR" 2>/dev/null
[ -n "$SERVER_PID" ] && kill $SERVER_PID 2>/dev/null
```

---

## Phase 4.5: Update Design Harness

See `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/harness.md` for full file specs.

**First review** (no `.design/`):
```bash
mkdir -p .design/pages .design/validate
```
Extract tokens from CSS custom properties → `system.json`. Extract component patterns → `components.json`. Create `rules.md` from key design decisions. Save page review to `pages/{name}.md`. Tell user: "Created `.design/` — future reviews enforce these patterns."

**Subsequent reviews:**
1. Save review to `pages/{name}.md`
2. If new patterns found: ask "Update design system or flag as inconsistency?"
3. Append decisions to `decisions.md`
4. Deviations flagged as `[CONSISTENCY]` issues on future reviews

---

## Phase 5: Fix List & Targeted Re-review

### 5a. After BLOCK or CONDITIONAL SHIP

Output a concrete, prioritized fix list with file:line references where possible:

```
### Fix List (priority order)
1. [CRITICAL] {issue} — {file:line} — flagged by {specialists}
2. [HIGH] {issue} — {file:line} — flagged by {specialists}
3. [MEDIUM] {issue} — flagged by {specialist}
```

### 5b. Targeted re-review

When user says "re-review", "check again", or runs `/design-review` again on the same page:

1. Take NEW screenshots (repeat Phase 0)
2. Re-run ONLY specialists that scored ≤2 or flagged critical issues in the previous review
3. Keep scores from passing specialists (≥3) — don't re-run what already passed
4. Recompute weighted score mixing kept (old) and fresh (new) scores
5. Label output: "Re-review iteration N — re-ran {list} ({n} of 8)"
6. Use numbered dirs: `/tmp/design-review-iter-1/`, `-iter-2/`, etc.

### 5c. Score comparison table

Include in every re-review output:

```
| Specialist | Prev | Now | Delta |
|-----------|------|-----|-------|
| Typography | 2/4 | 3/4 | +1 ↑ |
| Color | 1/4 | 3/4 | +2 ↑ |
| Intent | 3/4 | — | kept |
```

---

## Edge Cases & Fallbacks

- **Gemini rate-limited**: Retry once after 10s. If still failing, Claude Sonnet reads screenshots + reference file. Note: "Color/Layout reviewed by Claude (Gemini unavailable)."
- **Playwright not installed**: Tier 3 — warn user, recommend `npx playwright install chromium`. Code-only review if user confirms.
- **User provides Figma reference**: Pass to Intent specialist as gold standard. Highest-quality review mode.
- **User provides URL in `$ARGUMENTS`**: Use that URL directly, skip server detection.
- **User disagrees with verdict**: User's judgment overrides. Skill surfaces issues; user decides.
- **`--quick` mode**: Dispatch Specialists 1, 2, 3, 6 only. Report "Quick review (4/8 specialists)."

## Reference Files

At `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/`. Claude agents read directly; Gemini gets workspace copies.

| File | Specialist | Reader |
|------|-----------|--------|
| typography.md | Font (#1) | Claude |
| color.md | Color (#2) | Gemini → `.color-reference.md` |
| layout.md | Layout (#3) | Gemini → `.layout-reference.md` |
| icons.md | Icon (#4) | Claude |
| motion.md | Motion (#5) | Claude |
| intent.md | Intent (#6) | Claude |
