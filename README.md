# SpSk -- Simple Skill

AI-powered design review plugin for Claude Code. 8 specialist agents evaluate your UI across typography, color, layout, icons, motion, intent, copy, and accessibility -- then a boss synthesizer delivers a weighted SHIP/BLOCK verdict.

Built because AI models are terrible self-critics of visual output. They "reliably skew positive" and praise mediocre work. This plugin fixes that with independent specialist critique.

<!-- Demo GIF will be added in Phase 2 -->
*30-second demo coming soon.*

## Install

```bash
claude /install-plugin spsk@felipemachado/spsk
```

## Quick Start

```bash
# Review the page you're working on
/design-review

# Get a fast check with 4 specialists instead of 8
/design-review --quick

# Review against a reference site
/design-review --ref https://stripe.com/billing

# Build a page and iterate until it passes
/design-improve "Build a billing settings page"

# Verify everything actually works (clicks buttons, fills forms)
/design-validate
```

A full review takes ~8 minutes and produces a structured verdict with scores per dimension, a prioritized fix list, and a gold-standard gap analysis.

## Commands

| Command | What It Does | Key Flags |
|---------|-------------|-----------|
| `/design-review` | Full 8-specialist visual review | `--quick`, `--ref <url>`, `--figma <url>`, `--direction "brief"` |
| `/design-improve` | Build and iterate until SHIP | `--max N`, `--ref <url>`, `--validate`, `--style <preset>` |
| `/design-validate` | Functional validation (Playwright) | URL or auto-detect |
| `/design` | Orchestrator -- routes to sub-commands | `review`, `improve`, `validate`, `check`, `ship` |

## Architecture

The review pipeline runs in 5 phases:

1. **Screenshots** -- Playwright captures desktop (1440x900), mobile (375x812), and above-the-fold views
2. **Page Classification** -- Haiku agent classifies page type and sets the design bar
3. **8 Specialists** -- Dispatched in parallel, each with curated domain knowledge:
   - **Font** (Claude) -- typography quality, AI-overused fonts, hierarchy
   - **Color** (Gemini) -- palette cohesion, WCAG contrast, dark mode
   - **Layout** (Gemini) -- spacing, responsive behavior, section rhythm
   - **Icon** (Claude) -- library consistency, sizing, accessibility
   - **Motion** (Claude) -- animation quality, performance, reduced-motion
   - **Intent, Originality & UX** (Claude) -- purpose match, AI slop detection, user flow
   - **Copy** (Claude) -- spelling, accents, tone, placeholder text
   - **Code & A11y** (Claude) -- semantic HTML, ARIA, focus management
4. **Boss Synthesis** -- Cross-specialist consensus, weighted scoring, SHIP/CONDITIONAL/BLOCK verdict
5. **Fix List** -- Prioritized fixes with `[CRITICAL]`/`[HIGH]`/`[MEDIUM]` tags and file:line references

Intent and Originality carry 3x weight. Typography and Color carry 2x. The formula: `(Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout + Icons + Motion + Copy + Code) / 17`

For the full technical breakdown, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Degradation Tiers

The plugin adapts to your environment:

| Tier | Condition | Color/Layout Via | Quality |
|------|-----------|-----------------|---------|
| Tier 1 -- Full | Gemini + Playwright | Gemini CLI | Best -- cross-model consensus |
| Tier 2 -- No Gemini | Playwright only | Claude Sonnet | Good -- note correlated blind spots |
| Tier 3 -- Code Only | No Playwright | N/A | Minimal -- warns user |

Gemini provides cross-model diversity for Color and Layout (different model = different blind spots). If unavailable, Claude handles everything with a note in the output.

## The Story

v1 was a single-agent review. One model, one pass, generic praise. It scored **40%** on our eval assertions -- barely better than no review at all.

v2 added specialist prompts but kept a single agent. Marginal improvement.

v3 split into parallel agents but lacked intent context. Specialists evaluated in a vacuum.

v4 added intent-first architecture: every specialist receives the full page brief (audience, purpose, primary action) before evaluating their domain. The Font specialist doesn't just check "is this a good font" -- it checks "is this the right font for a dog love letter to its mother."

v4 scores **100%** on the same eval assertions. The delta is the architecture, not prompt engineering.

See [CHANGELOG.md](CHANGELOG.md) for the full progression.

## Evals

The eval harness proves the quality claims are reproducible:

```bash
./evals/run-evals.sh
```

Two layers:
1. **Structural validation** -- plugin.json valid, frontmatter correct, files exist, no hardcoded paths
2. **Quality assertions** -- range-based checks on actual review output against bundled test fixtures

Evals run on a clean clone. No external dependencies beyond Claude Code.

## Configuration

| File | What It Controls |
|------|-----------------|
| `config/scoring.json` | Specialist weights, page-type thresholds, verdict rules |
| `config/anti-slop.json` | Banned fonts, palettes, and AI patterns |
| `config/style-presets.json` | 5 built-in style presets (dashboard, playful, cinematic, editorial, startup) |
| `config/design-system.example.json` | Template for project-level design tokens |

## Requirements

- **Claude Code** -- plugin host
- **Playwright** -- for screenshots (`npx playwright install chromium`)
- **Gemini CLI** (optional) -- for Tier 1 cross-model review. Falls back gracefully if unavailable.

## License

MIT -- see [LICENSE](LICENSE).
