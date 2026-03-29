# SpSk -- Design Review Plugin

AI-powered design review using 8 independent specialist agents. Each specialist evaluates one domain (typography, color, layout, icons, motion, intent/originality/UX, copy, code/accessibility) against curated reference knowledge. A boss synthesizer merges findings with cross-specialist confidence scoring and delivers a weighted SHIP/BLOCK verdict.

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

All flags pass through to sub-commands: `--ref`, `--figma`, `--direction`, `--palette`, `--fonts`, `--quick`, `--max N`, `--validate`, `--style`.

### `/design-review` -- Visual Design Review

Full 8-specialist review with weighted scoring and SHIP/CONDITIONAL/BLOCK verdict.

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
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Run 4 core specialists instead of 8. Uses `/13` weights instead of `/17`. Saves ~40% tokens. |
| `--ref <url\|file\|figma>` | Compare against a reference instead of generic gold standards |
| `--figma <url>` | Review a Figma design before building. Add `--compare` to check implementation fidelity |
| `--direction "<text>"` | Evaluate against a text creative brief |
| `--palette "<colors>"` | Override color evaluation with specific palette |
| `--fonts "<fonts>"` | Override font evaluation with specific fonts |
| `--style <preset>` | Apply a style preset (see Configuration) |

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

`--quick` runs 4 core specialists instead of 8:
- Font, Color, Layout, Intent/Originality/UX
- Skips: Icon, Motion, Copy, Code/A11y
- Uses `/13` weight divisor instead of `/17`
- Saves ~40-50% tokens
- Best for: iterative fix cycles where you want fast feedback

Use full mode for final reviews before shipping.
