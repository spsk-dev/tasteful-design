# Changelog

All notable changes to the SpSk design-review plugin.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-03-28

### What Works

- 8-specialist multi-agent review achieving 8.6/10 consensus score across 3-model validation
- Weighted scoring with 10 dimensions and SHIP/CONDITIONAL/BLOCK verdict
- 3-tier degradation: full (Gemini + Playwright), Claude-only, code-only
- Quick mode: 4 specialists, /13 weight divisor, ~40% fewer tokens
- Anti-slop detection: banned fonts, palettes, and AI layout patterns in config
- Intent-first evaluation: all specialists receive page brief with intent, audience, and primary action
- 5 style presets: serious-dashboard, fun-lighthearted, animation-heavy, minimal-editorial, startup-landing
- Design references: `--ref <url|file|figma>`, `--palette`, `--fonts`, `--direction`
- Figma integration: review Figma designs pre-build, check implementation fidelity
- `.design/` harness: persistent project design system (tokens, components, rules, review history)
- Targeted re-review: only re-run failing specialists, keep passing scores
- PostToolUse hook: suggests `/design-review` after 3+ frontend file edits

### Benchmark Results

- 100% assertion pass rate (20/20) vs 40% without the skill
- Improve loop: 2.53 -> 2.87 -> 3.0 SHIP in 3 iterations
- Tested on 4 page types + live dev server
- 3-model consensus score: 8.6/10 (Claude, Gemini, Codex evaluation)

---

## The Journey: What Didn't Work

Most projects hide their failures. We think the iteration story is more interesting than the final result. These version numbers represent design iterations, not semver releases -- they track the architectural evolution from a single agent that produced useless feedback to a multi-agent system that catches real design issues.

### v1 -- Single Agent (Score: ~40%)

One Claude instance tried to review everything: typography, color, layout, accessibility, intent, originality. All at once, no specialization, no reference knowledge.

**What happened:**
- Reviews were reliably positive. The agent praised mediocre work.
- Domain-specific issues went undetected -- wrong letter-spacing on all-caps text, poor WCAG contrast ratios, cliche AI color palettes.
- Feedback was generic: "The typography looks clean" instead of "Body text is set at 14px with 1.4 line-height, which is too tight for long-form reading. Increase to 16px/1.6 minimum."
- 40% pass rate on quality assertions. More than half of known design issues were missed.

**Lesson:** Generalists produce generalist feedback. A single agent cannot hold expertise in typography, color theory, accessibility standards, motion design, and UX flow simultaneously. It defaults to surface-level observations.

### v2 -- Specialist Agents Without Coordination

Split the review into domain specialists: one agent for fonts, one for color, one for layout, and so on. Each specialist had focused prompts and domain knowledge.

**What happened:**
- Individual specialist feedback improved dramatically -- the font agent caught issues the generalist missed.
- But specialists contradicted each other. The color agent wanted more contrast; the layout agent wanted softer boundaries. No one reconciled the conflict.
- No single score, no verdict. The user received 8 independent reports with no prioritization.
- Unclear what to fix first. Everything seemed equally important.

**Lesson:** Specialists need a boss. Distributed expertise without synthesis produces noise, not signal.

### v3 -- Boss + Specialists, Unweighted

Added a boss synthesizer to merge specialist findings, deduplicate issues, and produce a single score and verdict. All specialists weighted equally.

**What happened:**
- The boss successfully merged findings and produced coherent output.
- But equal weighting distorted the score. A minor icon inconsistency (Icons: 2/4) had the same impact on the final score as a fundamental intent mismatch (Intent: 2/4).
- Scores were misleading. A page with excellent intent match but poor icons scored the same as a page with poor intent match but excellent icons -- despite the former being far more usable.
- Threshold-based verdicts were unreliable because the score didn't reflect actual design quality.

**Lesson:** Not all dimensions are equally important. Intent match matters more than icon consistency. The scoring formula needs to reflect real design priorities.

### v4 -- Weighted Multi-Agent (Current)

8 specialists with weighted scoring. Intent Match and Originality at 3x weight. UX Flow, Typography, and Color at 2x. Everything else at 1x. Total weight divisor: 17. Context-aware thresholds by page type.

**What works now:**
- Specialists catch domain-specific issues that no generalist would find
- Weighted scoring reflects real priorities -- intent and originality matter most
- Cross-model diversity (Gemini for Color and Layout) reduces correlated blind spots
- Boss synthesizer merges findings with confidence scoring based on cross-specialist agreement
- SHIP/CONDITIONAL/BLOCK verdict with page-type-aware thresholds
- 100% pass rate on quality assertions (20/20), up from 40% in v1
- 3-model consensus score: 8.6/10

The delta from 40% to 100% is the architecture's proof. Not clever prompting -- structural design decisions about specialization, weighting, and synthesis.
