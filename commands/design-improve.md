---
name: design-improve
description: >
  Iterative design improvement loop — builds or takes a page, runs /design-review, applies fixes,
  re-reviews until SHIP or max iterations reached. Use this skill when the user wants to BUILD and
  IMPROVE a frontend page to high design quality, not just review it. Trigger on: "build and review",
  "make this look good", "improve the design", "design-improve", "iterate on the design",
  "keep improving until it ships", or when a /design-review returns BLOCK and the user wants fixes applied.
allowed-tools: Bash(gemini *), Bash(which *), Bash(npx *), Bash(python3 *), Bash(curl *), Bash(kill *), Bash(mkdir *), Bash(cp *), Bash(rm *), Bash(lsof *)
---

# Design Improve — Iterative Build→Review→Fix Loop

## Why This Exists

`/design-review` catches problems but doesn't fix them. This skill closes the loop: build a page, review it with 8 specialists, apply the top fixes, re-review only the failing dimensions, and repeat until the page ships. Each iteration produces measurably better output because the fixes come from domain-specialist critique, not Claude's own taste.

## How It Works

```
Build → Review → BLOCK? → Apply fixes → Re-review → Still BLOCK? → Fix again → ...→ SHIP
```

- Max iterations: 3 by default (`$ARGUMENTS` can override with `--max N`)
- Each iteration applies the top 3 fixes from the review's fix list
- Re-reviews only re-run specialists that scored ≤2 (Phase 5 of design-review)
- Score progression is tracked and displayed after each iteration
- User can interrupt between iterations to steer direction

## Phase A: Build or Receive the Page

**If building from scratch:** Build the page per the user's prompt. Write it as a single HTML+CSS+JS file.

**If improving an existing page:** The user provides a URL or file path. Read the source.

**Before building, read the style preset** at `${CLAUDE_PLUGIN_ROOT}/config/style-presets.json` (check `active_preset` or `--style` argument). If a preset is active, use its typography, colors, animations, and layout guidance as the starting point for the build — not generic defaults.

**Then read the anti-slop config at `${CLAUDE_PLUGIN_ROOT}/config/anti-slop.json`** for banned fonts, palettes, and patterns. If the file doesn't exist, use these defaults:
- Do NOT use: Dancing Script, Playfair Display, Poppins, Montserrat, or Inter
- Do NOT use: dark+gold, purple gradient, synthwave palette
- Do NOT use: emoji as icons — use Lucide SVGs or inline SVGs
- DO use: at most 2 font families (check `${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/typography.md` for good options)
- DO add: `prefers-reduced-motion` support, semantic HTML, aria-labels
- DO add: proper Spanish accents if the content is in Spanish

Users can customize `anti-slop.json` to add project-specific banned/recommended patterns.

## Phase B: First Review

Run `/design-review` on the page. This triggers the full 8-specialist pipeline:
1. Screenshots (Playwright)
2. Page classification (Haiku)
3. 8 specialist dispatch (Font, Color, Layout, Icon, Motion, Intent, Copy, Code)
4. Boss synthesis with weighted scoring

Read the verdict and score.

**If SHIP:** Done. Present the page and review to the user. Skip to Phase F.

**If BLOCK or CONDITIONAL SHIP:** Continue to Phase C.

## Phase C: Apply Fixes

Read the fix list from the review. Apply fixes in priority order:

1. All **[CRITICAL]** fixes (these block shipping no matter what)
2. Top 2-3 **[HIGH]** fixes
3. Stop — don't fix [MEDIUM] or [LOW] yet (diminishing returns per iteration)

**How to apply each fix:**
- The review provides file:line references — go to those exact locations
- For font changes: update the Google Fonts import URL and all `font-family` declarations
- For color changes: update CSS custom properties (usually in `:root {}`)
- For layout changes: modify the specific section's HTML/CSS structure
- For accessibility: add `aria-label`, semantic elements, `prefers-reduced-motion`
- For copy: fix spelling, accents, placeholder text

**After applying fixes, log what you changed:**
```
## Iteration N Fixes Applied
1. [CRITICAL] Fixed: {description} — changed {old} → {new}
2. [HIGH] Fixed: {description} — changed {old} → {new}
3. [HIGH] Fixed: {description} — changed {old} → {new}
```

## Phase D: Re-review (Targeted)

Run `/design-review` again. The skill's Phase 5 handles targeted re-review:
- New screenshots captured
- Only specialists that scored ≤2 are re-run
- Scores from passing specialists (≥3) are kept from the previous review
- Mixed scores produce a new weighted total

Read the new verdict and score.

## Phase D.5: Functional Validation (if `--validate` flag or final iteration)

Run `/design-validate` to verify interactive elements actually work:
- Click every button — does something happen?
- Test every link — does it go somewhere?
- Fill every form — can it submit?
- Check console for JS errors
- Verify mobile touch targets

**When to run:** On every iteration if `--validate` flag is set. Otherwise, only on the final iteration (when SHIP or max iterations reached). Validation catches functional regressions from design fixes (e.g., fixing layout broke a button's click handler).

**If validation finds broken functionality:** Fix those BEFORE re-running design review. Functional bugs take priority over visual polish.

## Phase E: Iterate or Ship

**If SHIP AND validation passes:** Done. Continue to Phase F.

**If SHIP BUT validation fails:** Fix functional issues, re-validate. Don't re-run design review unless the functional fix changed the visual design.

**If BLOCK or CONDITIONAL SHIP and iterations < max:**
- Log the score delta
- Go back to Phase C with the new fix list
- Each iteration should target different issues (don't re-apply the same fix)

**If max iterations reached and still not SHIP:**
- Present the final state with full score history
- List remaining fixes the user could apply manually
- Be honest: "After N iterations, the score improved from X to Y. Remaining gap: Z."

## Phase F: Final Report

Present the full iteration history:

```
## Design Improvement Report — {page name}

### Score Progression
| Iteration | Score | Verdict | Fixes Applied |
|-----------|-------|---------|---------------|
| 0 (initial) | 2.2/4.0 | BLOCK | — |
| 1 | 2.7/4.0 | CONDITIONAL | fonts, palette, accents |
| 2 | 3.1/4.0 | SHIP | layout, motion, icons |

### What Changed
- Iteration 1: Replaced Dancing Script → Instrument Serif, dark+gold → warm cream+terracotta, added Spanish accents
- Iteration 2: Broke wall-of-cards with featured card, added prefers-reduced-motion, replaced emoji with Lucide SVGs

### Remaining Items (not blocking)
- [MEDIUM] ...
- [LOW] ...

### Files
- Final page: {path}
- Review history: {paths}
```

## Configuration

Parse `$ARGUMENTS`:
- `--max N`: Maximum iterations (default 3)
- `--quick`: Use `/design-review --quick` (4 specialists) for iterations 1+, full review only on final
- `--ref <url>`: Reference website — screenshot it and compare every iteration against it
- `--ref <file.md>`: Design spec file — fonts, colors, spacing rules to follow
- `--ref <figma-url>`: Figma design — pull via MCP as the gold standard
- `--palette "#hex1,#hex2,..."`: Specific colors the page must use
- `--fonts "Font1,Font2"`: Specific fonts the page must use
- `--style <preset-name>`: Apply a style preset (serious-dashboard, fun-lighthearted, animation-heavy, minimal-editorial, startup-landing). Sets the design direction for building AND reviewing. Persists via `${CLAUDE_PLUGIN_ROOT}/config/style-presets.json`.
- `--validate`: Run `/design-validate` each iteration (not just final)
- Path or URL: page to improve (if not building from scratch)

**References are the most powerful feature.** When a user provides a reference, the specialists stop comparing against imagined gold standards and compare against the actual target. This means:
- Phase A (Build): Use the reference's fonts, colors, and structure as a starting point
- Phase B-D (Review/Fix): Specialists score how close the page is to the reference
- Fixes are directed toward matching the reference, not generic "improvement"

This turns the loop from "make it generically better" into "make it match this specific vision."

## When to Use This vs /design-review

| Situation | Use |
|-----------|-----|
| Built a page, want honest critique | `/design-review` |
| Want to build AND iterate to high quality | `/design-improve` |
| Got a BLOCK, want to fix and re-review | `/design-improve` (pass the page path) |
| Quick check during development | `/design-review --quick` |
| Final review before shipping | `/design-review` (full 8 specialists) |

## Important: Design Limitations Still Apply

This skill makes Claude's output measurably better by using specialist critique to guide fixes. But it cannot make Claude a designer. The ceiling is "competent implementation that avoids common mistakes" — not "award-winning original design."

For truly distinctive design:
1. Design in Figma/Lovable/Pencil (they have real design rules)
2. Run `/design-improve` on the implementation to catch implementation issues
3. Or: build with Claude, run `/design-improve`, then hand to a designer for the creative layer
