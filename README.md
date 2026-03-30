# SpSk -- Simple Skill

AI-powered design review and multi-model code review for Claude Code. Two skills, one plugin:

- **`/design-review`** -- 7 specialist agents evaluate your UI across typography, color, layout, icons, motion, intent/originality/UX, and accessibility. A boss synthesizer delivers a weighted SHIP/BLOCK verdict.
- **`/code-review`** -- 3 models (Claude, Codex, Gemini) review your PR in parallel with confidence-scored findings and cross-model agreement detection.

Built because AI models are terrible self-critics. They "reliably skew positive" on visual output and miss concurrency bugs in code. These skills fix that with independent specialist critique and multi-model consensus.

<p align="center">
  <img src="assets/demo.gif" alt="SpSk design-review demo -- 7 specialists scoring a landing page" width="720">
</p>

## Install

**Plugin registry (recommended):**

```bash
claude /install-plugin tasteful-design@spsk-dev/tasteful-design
```

**Manual (clone + symlink):**

```bash
git clone https://github.com/spsk-dev/tasteful-design.git
cd spsk && bash install.sh
```

## Quick Start

```bash
# Review the page you're working on
/design-review

# Get a fast check with 4 specialists instead of 7
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
| `/design-review` | Full 7-specialist visual review | `--quick`, `--ref <url>`, `--figma <url>`, `--direction "brief"` |
| `/design-improve` | Build and iterate until SHIP | `--max N`, `--ref <url>`, `--validate`, `--style <preset>` |
| `/design-validate` | Functional validation (Playwright) | URL or auto-detect |
| `/design` | Orchestrator -- routes to sub-commands | `review`, `improve`, `validate`, `check`, `ship` |
| `/design-audit` | Flow-level SPA design audit | `--flow "desc"`, `--steps url1,url2`, `--auth`, `--max N` |
| `/code-review` | Multi-model PR review with confidence scoring | `--model <name>`, PR number or URL |

## Code Review

Multi-model PR review with confidence scoring. Dispatches your PR to up to 3 models (Claude, Codex, Gemini) in parallel, merges findings, and highlights cross-model agreement as the highest-confidence signal.

```bash
# Review a PR by number
/code-review 123

# Review by URL
/code-review https://github.com/owner/repo/pull/123

# Single-model mode (faster, lower cost)
/code-review 123 --model claude
```

**How it works:**
1. Fetches the PR diff and metadata
2. Dispatches to available models in parallel
3. Each model reviews independently with structured output
4. Findings are merged, deduplicated, and confidence-scored
5. Cross-model agreement (2+ models flag the same issue) gets the highest confidence

**3-tier degradation:** All 3 models available (best), 2 models (good), single model (baseline). The system adapts to whatever models are accessible.

See the [code-review case study](docs/case-studies/code-review-bugs-caught.md) for a real-world example where 3-model consensus caught a race condition that single-model review missed.

## Flow Audit

Multi-screen SPA design audit. Navigates through your app screen-by-screen, runs 7-specialist review on each screen, checks cross-screen consistency, and generates a self-contained HTML diagnostic report.

```bash
# Audit a checkout flow (intent-guided navigation)
/design-audit http://localhost:3000 --flow "complete the checkout"

# Audit with explicit URL steps (deterministic)
/design-audit http://localhost:3000 --steps /login,/dashboard,/settings

# Audit a protected flow (authenticates first)
/design-audit http://localhost:3000 --flow "onboarding" --auth
```

**How it works:**
1. Navigates SPA screens by clicking CTAs that match your flow description (or follows --steps URLs)
2. Captures a screenshot at each screen state change (DOM stability detection)
3. First and last screens get full 7-specialist review; middle screens get quick 4-specialist review
4. Cross-screen consistency analysis flags visual drift (color, spacing, typography, button styles)
5. Generates a self-contained HTML report with embedded screenshots, scores, and fix recommendations

**Smart weighting:** The flow score uses position-weighted averaging -- first and last screens count 1.5x because they're the user's first impression and final experience.

For the technical architecture, see [ARCHITECTURE.md](ARCHITECTURE.md#flow-audit).

## Case Studies

- [Design Review Impact: Dashboard Redesign](docs/case-studies/design-review-impact.md) -- From 5.2/10 to 8.4/10 in 3 iterations, ~20 minutes
- [Code Review: Multi-Model Bug Detection](docs/case-studies/code-review-bugs-caught.md) -- 3 models caught 5 high-confidence issues; single-model caught 2

## Architecture

The review pipeline runs in 5 phases:

1. **Screenshots** -- Playwright captures desktop (1440x900), mobile (375x812), and above-the-fold views
2. **Page Classification** -- Haiku agent classifies page type and sets the design bar
3. **7 Specialists** -- Dispatched in parallel, each with curated domain knowledge:
   - **Font** (Claude) -- typography quality, AI-overused fonts, hierarchy
   - **Color** (Gemini) -- palette cohesion, WCAG contrast, dark mode
   - **Layout** (Gemini) -- spacing, responsive behavior, section rhythm
   - **Icon** (Claude) -- library consistency, sizing, accessibility
   - **Motion** (Claude) -- animation quality, performance, reduced-motion
   - **Intent, Originality, UX & Copy** (Claude) -- purpose match, AI slop detection, user flow, copy quality
   - **Code & A11y** (Claude) -- semantic HTML, ARIA, focus management
4. **Boss Synthesis** -- Cross-specialist consensus, weighted scoring, SHIP/CONDITIONAL/BLOCK verdict
5. **Fix List** -- Prioritized fixes with `[CRITICAL]`/`[HIGH]`/`[MEDIUM]` tags and file:line references

Intent and Originality carry 3x weight. Typography and Color carry 2x. The formula: `(Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout + Icons + Motion + Code) / 16`

The flow audit pipeline (`/design-audit`) extends this to multi-screen flows -- navigating SPAs, running per-screen reviews with smart weighting, detecting cross-screen consistency drift, and generating HTML diagnostic reports.

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
- **Playwright MCP** -- for flow audit navigation (`npx @anthropic/mcp-server-playwright`)
- **Gemini CLI** (optional) -- for Tier 1 cross-model review. Falls back gracefully if unavailable.

## Benchmarks

The eval harness validates plugin quality with two layers:

**Layer 1 -- Structural Validation** runs anywhere (no Claude Code required). Checks plugin manifest, command frontmatter, config validity, hook setup, reference files, hardcoded paths, and required root files.

**Layer 2 -- Quality Assertions** runs within Claude Code. Range-based checks against bundled HTML test fixtures that account for AI non-determinism. Three fixture scenarios cover admin panels, marketing landing pages, and intentionally problematic designs.

```bash
# Run the full eval suite
./evals/run-evals.sh
```

Example structural validation output:

```
[PASS] plugin.json is valid JSON
[PASS] commands/design-review.md has frontmatter
[PASS] config/scoring.json is valid JSON
[PASS] No hardcoded user paths
...
32/32 checks passed
```

Quality assertion definitions: [`evals/assertions.json`](evals/assertions.json)

Benchmark results: [`evals/results/`](evals/results/) (populated after quality eval runs)

Structural evals run on any machine with `bash` and `jq`. Quality evals require an active Claude Code session with the plugin installed.

## License

MIT -- see [LICENSE](LICENSE).
