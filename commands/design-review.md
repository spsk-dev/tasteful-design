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

Screenshots are the backbone. **Do not skip screenshots without explicit user confirmation.** If Playwright is unavailable (Tier 3), warn the user and ask — only proceed code-only if they confirm. A code-only review misses visual issues that are the whole point of this skill.

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

Reads: screenshots (Read the PNG files) + source files + reference knowledge

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/font.md

Read these screenshots visually: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png, {REVIEW_DIR}/fold.png
Read the source files: {file list}

### Specialist 2: Color (Gemini CLI)

Reads: screenshots only. If Gemini unavailable, use Claude Sonnet agent reading screenshots.

Read the specialist prompt from `${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/color.md`. Construct the Gemini CLI command using this prompt content plus the PAGE_BRIEF context. The prompt file contains the role, review checklist, scoring rubric, and output format.

```bash
cd "$(pwd)" && gemini -y -p "{PAGE_BRIEF context} + {content from prompts/color.md}"
```

*(Color reference was already copied to `.color-reference.md` in the pre-dispatch step above.)*

### Specialist 3: Layout (Gemini CLI)

Reads: screenshots only. If Gemini unavailable, use Claude Sonnet agent reading screenshots.

Read the specialist prompt from `${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/layout.md`. Construct the Gemini CLI command using this prompt content plus the PAGE_BRIEF context. The prompt file contains the role, review checklist, scoring rubric, and output format.

```bash
cd "$(pwd)" && gemini -y -p "{PAGE_BRIEF context} + {content from prompts/layout.md}"
```

*(Layout reference was already copied to `.layout-reference.md` in the pre-dispatch step above.)*

### Specialist 4: Icon (Claude Sonnet Agent)

Reads: screenshots + source files

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/icons.md

Read these screenshots visually: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png
Read the source files: {file list}

### Specialist 5: Motion (Claude Sonnet Agent)

Reads: source code only (cannot see animations in screenshots)

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/motion.md

Read the source files: {file list}

### Specialist 6: Intent, Originality & UX (Claude Sonnet Agent)

Reads: screenshots + source + PAGE_BRIEF + reference knowledge. This is the most important specialist (3x weight) because it answers the hardest questions: does this LOOK like what it's trying to BE, and can users actually DO what the page wants them to?

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/intent.md

Read these screenshots visually: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png, {REVIEW_DIR}/fold.png
Read the source files: {file list}

### Specialist 7: Copy & Language (Claude Haiku Agent)

Reads: source code (extracts visible text)

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/copy.md

Read the source files: {file list}

### Specialist 8: Code & Accessibility (Claude Sonnet Agent)

Reads: source code only

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/code-a11y.md

Read the source files: {file list}

---

## Phase 3: Boss Designer Synthesis

Read the scoring configuration from `${CLAUDE_PLUGIN_ROOT}/config/scoring.json` for weights and thresholds. If the file doesn't exist, use the defaults in the boss prompt below.

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/boss.md

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
