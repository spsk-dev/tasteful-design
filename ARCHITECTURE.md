# Architecture

How the design-review plugin works, why it works this way, and what happens when things degrade.

## Overview

The design-review plugin is a multi-agent system that evaluates visual design quality by dispatching 8 specialist agents in parallel, each focused on a single design dimension. A boss synthesizer merges their findings into a weighted score and delivers a SHIP, CONDITIONAL, or BLOCK verdict.

This architecture exists because single-agent review does not work. When one Claude instance tries to evaluate everything -- typography, color, layout, accessibility, intent -- it produces generic, reliably positive feedback that misses domain-specific issues. In benchmarks, single-agent review scored roughly 40% on quality assertions. The multi-agent approach with weighted specialists scores 100%.

The key insight: generalists produce generalist feedback. Specialists with domain-specific reference knowledge catch what a generalist misses -- the wrong letter-spacing on all-caps text, a synthwave purple gradient that screams "AI-generated," a buried call-to-action that kills conversion.

## System Architecture

```
                          User
                           |
                      /design-review
                           |
                    +--------------+
                    |  Phase 0     |
                    |  Screenshots |  Playwright: desktop, mobile, fold
                    +--------------+
                           |
                    +--------------+
                    |  Phase 1     |
                    |  Page Brief  |  Haiku agent classifies intent,
                    +--------------+  audience, design bar
                           |
          +----------------+----------------+
          |    |    |    |    |    |    |    |
         S1   S2   S3   S4   S5   S6   S7   S8
        Font Color Layout Icon Motion Intent Copy Code
          |    |    |    |    |    |    |    |
          +----------------+----------------+
                           |
                    +--------------+
                    |  Phase 3     |
                    |  Boss        |  Merge findings, deduplicate,
                    |  Synthesizer |  compute weighted score,
                    +--------------+  deliver verdict
                           |
                  SHIP / CONDITIONAL / BLOCK
```

Each specialist receives the full page brief from Phase 1 (intent, audience, primary action, UX priorities) so they evaluate their domain in service of the page's purpose -- not in a vacuum. A font specialist reviewing an admin dashboard applies different standards than one reviewing a personal love letter.

## The 8 Specialists

Each specialist is an independent agent with its own reference knowledge file. Specialists 1, 4-8 run as Claude agents that read files directly. Specialists 2 and 3 run via Gemini CLI for cross-model diversity (with Claude fallback if Gemini is unavailable).

| # | Specialist | Dimension | What It Evaluates | Weight | Agent |
|---|-----------|-----------|-------------------|--------|-------|
| 1 | Font | Typography | Font choices, pairing, hierarchy, line-height, letter-spacing, measure | 2x | Claude |
| 2 | Color | Color Quality | Palette cohesion (60/30/10), WCAG contrast, dark/light mode, color-mood match | 2x | Gemini |
| 3 | Layout | Layout Quality | Spacing consistency, responsive behavior, section rhythm, alignment, whitespace | 1x | Gemini |
| 4 | Icon | Icon Quality | Library consistency, sizing, stroke weight, filled vs outline, aria-labels | 1x | Claude |
| 5 | Motion | Motion Quality | Animation quality, performance, prefers-reduced-motion, timing curves | 1x | Claude |
| 6 | Intent/Originality/UX | Intent Match, Originality, UX Flow | Design-purpose alignment, creative distinctiveness, user flow and CTA clarity | 3x + 3x + 2x | Claude |
| 7 | Copy | Copy Quality | Spelling, grammar, placeholders, tone match, CTA quality | 1x | Claude |
| 8 | Code & A11y | Code Quality | Hardcoded values, missing states, responsive code, semantic HTML, ARIA, focus | 1x | Claude |

Specialist 6 is the most heavily weighted because it answers the hardest questions: does the design match its purpose, is it distinguishable from generic AI output, and can users actually accomplish what the page wants them to do? It returns three separate scores (Intent Match, Originality, UX Flow) that are weighted independently.

Every specialist must find at least 2 issues. "Looks great" is not allowed -- the entire point is honest, actionable feedback.

## Boss Synthesizer Pattern

After all 8 specialists return their findings and scores, the boss synthesizer (the orchestrator itself) merges the results. It does not re-evaluate the design -- it trusts the specialists and synthesizes.

The boss performs four operations:

1. **Cross-specialist agreement**: Issues found by 2+ specialists are flagged as HIGH confidence. These are the most reliable findings because independent agents with different expertise converged on the same problem.

2. **Deduplication**: The same issue reported by multiple specialists is merged into one entry, keeping the most specific description and noting which specialists found it.

3. **Weighted scoring**: Each specialist's score is multiplied by its weight and summed, then divided by the total weight to produce a single score on a 1.0-4.0 scale.

4. **Context-aware verdict**: The score is compared against a threshold that varies by page type. An admin panel has a lower bar (2.5) than a portfolio site (3.5), because template design is acceptable for settings pages but unacceptable when design IS the product.

Why this pattern instead of a single smart agent? Because the v1 single-agent approach scored 40% on quality assertions. It missed typography issues that a font specialist catches, color theory problems that a color specialist catches, and UX flow issues that a dedicated UX analyst catches. The boss pattern was chosen after three failed iterations (see CHANGELOG.md).

## Scoring Algorithm

The weighted scoring formula from `config/scoring.json`:

```
Score = (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2
         + Layout*1 + Icons*1 + Motion*1 + Copy*1 + Code*1) / 17
```

Each dimension is scored on a 1.0 to 4.0 scale. The total weight divisor is 17.

**Weight rationale:**
- Intent Match (3x) and Originality (3x): The most important questions -- does the design match its purpose, and is it distinguishable from generic AI output?
- UX Flow (2x), Typography (2x), Color (2x): High visual impact and direct effect on usability.
- Layout, Icons, Motion, Copy, Code (1x each): Important but less differentiating.

**Verdict thresholds** (from `config/scoring.json`):

| Page Type | SHIP Threshold | Rationale |
|-----------|---------------|-----------|
| Admin / settings / docs | >= 2.5 | Template design is acceptable |
| Dashboard / form / e-commerce | >= 2.8 | Usability matters more than novelty |
| Landing / marketing / SaaS | >= 3.0 | Creativity required to stand out |
| Portfolio / showcase | >= 3.5 | Design IS the product |
| Emotional / personal | >= 3.0 | Warmth and personality required |

**Verdict rules:**
- **SHIP**: Score >= threshold AND no critical issues
- **CONDITIONAL SHIP**: Score within 0.3 of threshold AND issues are fixable
- **BLOCK**: Score < threshold - 0.3 OR critical issues present

**Quick mode** (`--quick`): Runs 4 specialists instead of 8 -- Font, Color, Layout, and Intent/Originality/UX. Uses a reduced weight divisor of 13 instead of 17. Saves approximately 40-50% of tokens. Best for iterative fix cycles where fast feedback matters more than comprehensive coverage. Full mode should be used for final reviews before shipping.

Quick mode formula:
```
Score = (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout*1) / 13
```

**Score ranges in practice:** Real-world scores typically fall between 2.0 and 3.5. Scores below 2.0 indicate significant design problems across multiple dimensions. Scores above 3.5 are rare and represent exceptional design quality. The benchmark shows an improve loop progressing from 2.53 to 2.87 to 3.0 (SHIP) across 3 iterations.

## Degradation Tiers

The plugin adapts to the tools available on the user's machine. It never fails with an error -- it degrades gracefully and always reports which tier it ran at.

| Tier | Condition | Color/Layout Agent | Capability | What's Lost |
|------|-----------|-------------------|------------|-------------|
| Tier 1 -- Full | Gemini CLI + Playwright installed | Gemini CLI | Best quality: cross-model diversity for Color and Layout, visual screenshots for all specialists | Nothing |
| Tier 2 -- Claude-only | Playwright installed, no Gemini | Claude Sonnet (fallback) | Good quality: all specialists run, but Color and Layout have correlated blind spots with other Claude agents | Cross-model validation -- all agents share the same model biases |
| Tier 3 -- Code-only | No Playwright | N/A | Minimal: structural code analysis only, no visual review | Visual review entirely -- the core value proposition. User is warned and must confirm |

**Tier detection** happens at startup: the plugin checks for `gemini` CLI and `npx playwright` availability. If Gemini is rate-limited mid-review, it retries once after 10 seconds, then falls back to Claude Sonnet for that specialist.

**Why graceful degradation instead of hard requirements:** The tool should always work. A developer who installs the plugin and runs `/design-review` should get useful feedback immediately -- even without Gemini, even without Playwright. Hard requirements create friction that stops adoption. Degradation tiers let users get value on day one and upgrade their setup when they see the benefit.

## Anti-Slop System

The anti-slop system (`config/anti-slop.json`) detects and penalizes common patterns in AI-generated design output. AI models tend to converge on the same visual choices -- the same fonts, the same color palettes, the same layout structures. The anti-slop config codifies these patterns so specialists can flag them.

**What it tracks:**

- **Banned fonts**: Fonts that AI models overuse -- Dancing Script, Playfair Display, Poppins, Montserrat, Lobster, Pacifico. The config includes recommended alternatives by category (sans, serif, mono, display).
- **Banned palettes**: Cliche color combinations -- dark background + gold accents (crypto exchange aesthetic), purple-to-blue gradient heroes (AI SaaS default), synthwave purple + neon cyan/pink, all-gray palettes with no accent.
- **Banned patterns**: Layout anti-patterns that are AI fingerprints -- emoji used as icons instead of SVG icon libraries, the three-column icon grid (the most common AI layout), and the "badge-hero-features-steps-testimonials-CTA" landing page skeleton.
- **Required accessibility**: Non-negotiable checks enforced in every review -- prefers-reduced-motion support, semantic HTML, aria-labels, focus-visible styles, WCAG AA contrast ratios.

The `/design-improve` command reads anti-slop.json during its build phase to avoid generating these patterns in the first place. The `/design-review` command uses it during evaluation to flag them in existing designs.

## Command Architecture

The plugin provides 4 commands that compose into workflows:

| Command | Role | When to Use |
|---------|------|-------------|
| `/design` | Router/orchestrator | Entry point. Routes to sub-commands, supports pipeline modes (`ship`, `check`) |
| `/design-review` | Core review engine | Full 8-specialist review with scoring and verdict. The main command. |
| `/design-improve` | Iterative build-fix loop | Builds a page, reviews it, applies top fixes, re-reviews until SHIP or max iterations |
| `/design-validate` | Functional testing | Clicks buttons, fills forms, checks console errors via Playwright. Catches broken functionality. |

**How they compose:**
- `/design review` runs a standalone review
- `/design improve "prompt"` builds, reviews, fixes, re-reviews (loop)
- `/design check` runs review + validate (pre-merge quality gate)
- `/design ship "prompt"` runs the full pipeline: improve -> review -> validate

All flags (`--ref`, `--figma`, `--direction`, `--palette`, `--fonts`, `--quick`, `--style`) pass through from `/design` to sub-commands.

## Design Decisions

| Decision | Alternative | Why This Way |
|----------|------------|--------------|
| Multi-agent (8 specialists) over single-agent | One agent reviews everything | Single-agent scored 40% on quality assertions. Specialists with domain knowledge catch issues a generalist misses -- typography rules, color theory, accessibility requirements. |
| Markdown commands over JavaScript | npm package with JS entry points | No build step, no dependencies, no package manager. Commands ARE prompts -- the markdown file is both the documentation and the implementation. Instant portability. |
| JSON config over hardcoded values | Embed weights and rules in command prompts | Tunable without editing prompts. Users can adjust scoring weights, add banned fonts, change thresholds per page type. Separation of data from logic. |
| Weighted scoring over simple average | All dimensions weighted equally | Not all dimensions matter equally. Intent Match (does it serve its purpose?) matters 3x more than Icon consistency. Weighting reflects real design priorities and prevents minor issues from dominating the score. |
| Graceful degradation over hard requirements | Require Gemini + Playwright | The tool should work on day one. Hard requirements create adoption friction. Users get value immediately and upgrade incrementally. |
| Cross-model specialists (Gemini for Color/Layout) | All Claude agents | Same-model agents share blind spots. Gemini catches color and layout issues that Claude consistently misses, providing genuine cross-model validation. |
| Intent-first evaluation over generic standards | Evaluate against universal design principles | An admin panel and a love letter need completely different design standards. Phase 1 classifies intent so specialists evaluate in context, not in a vacuum. |
| Mandatory minimum issues (2+) over optional praise | Allow "looks great" responses | AI models are terrible self-critics. Requiring minimum issues forces honest feedback. Earned praise is limited to 2 items maximum in the final output. |

## File Map

```
spsk/
+-- .claude-plugin/
|   +-- plugin.json          # Plugin manifest (name, version, description)
+-- commands/
|   +-- design.md            # /design -- router and orchestrator
|   +-- design-review.md     # /design-review -- core 8-specialist review
|   +-- design-improve.md    # /design-improve -- iterative build-fix loop
|   +-- design-validate.md   # /design-validate -- functional testing
+-- config/
|   +-- scoring.json         # Specialist weights, thresholds, verdict rules
|   +-- anti-slop.json       # Banned fonts, palettes, patterns
|   +-- style-presets.json   # 5 built-in style presets
|   +-- design-system.example.json  # Template for .design/ system file
+-- skills/
|   +-- design-review/
|       +-- SKILL.md          # Skill activation and description
|       +-- references/       # Domain knowledge for specialists
|           +-- typography.md # Font specialist reference
|           +-- color.md      # Color specialist reference
|           +-- layout.md     # Layout specialist reference
|           +-- icons.md      # Icon specialist reference
|           +-- motion.md     # Motion specialist reference
|           +-- intent.md     # Intent/Originality/UX reference
|           +-- visual-design-rules.md  # Cross-cutting visual rules
+-- hooks/
|   +-- hooks.json            # PostToolUse hook definitions
+-- scripts/
|   +-- suggest-review.sh     # Suggests /design-review after 3+ frontend edits
+-- ARCHITECTURE.md           # This file
+-- CHANGELOG.md              # Version history with failure transparency
+-- README.md                 # Install, usage, quick start
+-- CLAUDE.md                 # Command reference for plugin users
+-- LICENSE                   # MIT
+-- VERSION                   # Semver (1.0.0)
```
