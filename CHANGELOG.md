# Changelog

All notable changes to the SpSk design-review plugin.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.3.0] - 2026-03-31

### Added

- **Design contract autodetection** (Phase 0.6): Extracts buttons, typography, colors, and spacing from the live page via `browser_evaluate`. Creates a structured JSON design contract that specialists use to flag `[SPEC_MISMATCH]` deviations — catches inconsistent button radii, mixed fonts, and spacing drift within a single page.
- **Narrative assessment**: Boss synthesizer now writes a 2-3 sentence human-readable verdict for non-designer stakeholders. Answers: what does this page look and feel like, what effect would it have, and what single fix matters most.
- **Universal HTML report**: `generate-report.sh` now handles both single-page reviews (`review-state.json`) and flow audits (`flow-state.json`). Single-page reports include: narrative blockquote, side-by-side screenshots, design contract summary, expandable per-specialist results, consensus findings, and prioritized fix list. Self-contained, emailable, printable.
- **Consistent output schema**: `<boss_output>` JSON now includes `narrative`, `spec_mismatches`, and `design_contract` fields. Every review produces the same structure regardless of mode.
- **Phase 3.5 (Save Review State)**: Writes `review-state.json` after boss synthesis for report consumption.
- **Phase 3.6 (Generate Report)**: Automatically generates HTML report after every review, not just flow audits.

### Changed

- Specialist context prefix now includes the design contract alongside PAGE_BRIEF — specialists compare actual page patterns against the autodetected spec.
- `generate-report.sh` detects input type (`"type": "single_page"` vs flow) and renders the appropriate layout.
- Phase 4 cleanup no longer deletes `$REVIEW_DIR` — preserves screenshots and report for the user.

## [1.2.1] - 2026-03-31

### Fixed

- **IIFE→arrow function conversion** — All `browser_evaluate` JavaScript snippets in `design-audit.md`, `design-review.md`, and `flow.md` converted from IIFE `(function(){})()` to arrow functions `() => {}`. IIFEs cause `TypeError: result is not a function` in Playwright MCP's evaluate, which was a contributing factor to flow audit hangs.
- **DOM stability on animated pages** — Root-caused the `browser_evaluate` hang on start.fusefinance.com screen 7: two perpetually animated SVGs (115 `<g>` elements, ~326 DOM mutations/sec) prevented the MutationObserver quiet timer from ever firing. The simple 2s `setTimeout` primary approach now works correctly; the MutationObserver fallback uses a 5s `HARD_TIMEOUT` that resolves reliably.
- **Stale version references** — Fixed `v1.1.0` → `v1.2.0` in `design-audit.md` signature and `generate-report.sh`
- **Missing harness.md** — Created `skills/design-review/references/harness.md` (was referenced by `design-review.md` but didn't exist)
- **README accuracy** — Fixed scoring formula description, updated Playwright MCP install command to `@playwright/mcp@latest`, updated structural eval count (32→106), added missing blank line before Flow Audit section
- **Stale version comment** — Removed hardcoded "currently 1.0.0" from `shared/output.md`

## [1.2.0] - 2026-03-30

### Added

- Extracted specialist prompts to individual files (`skills/design-review/prompts/*.md`) for isolated testing and iteration
- XML-structured prompts following Anthropic Claude 4.6 best practices (`<role>`, `<instructions>`, `<scoring_rubric>`, `<output_format>`)
- 4-level scoring rubrics with concrete domain-specific anchors per specialist (replacing bare "Score 1-4")
- Structured JSON output from all specialists (`<specialist_output>`) and boss (`<boss_output>`) with think-then-structure pattern
- Dual-format output parser (JSON-first with regex fallback for backward compatibility)
- Layer 2 quality eval runner (`run-quality-evals.sh`) executing assertions against real design-review output
- LLM-as-judge binary rubric assertions via Claude Haiku (graceful skip without API key)
- Eval result snapshots with timestamped JSON and regression detection (0.5 threshold)
- Gray-area test fixture (mediocre SaaS pricing page) for CONDITIONAL verdict testing
- Calibration helper script (`calibrate-baselines.sh`) for assertion range tuning
- 2-3 curated few-shot examples per specialist showing ideal output at different score levels
- Chain-of-thought `<thinking>` + `<answer>` separation for complex specialists (Intent, Layout, Boss)
- `references/generation.md` from Anthropic's DISTILLED_AESTHETICS_PROMPT for `/design-improve` build guidance
- Opt-in `--interact` flag for Playwright page interaction (hover, focus, scroll) before specialist scoring
- Baseline-interact-reset pattern preventing DOM mutation during reviews
- Weight-sum structural assertion in `validate-structure.sh` verifying scoring integrity

### Changed

- Specialist count reduced from 8 to 7: Copy merged into Intent/Originality/UX with 4 sub-scores (intent_match, originality, ux_flow, copy_quality)
- Scoring formula updated: total_weight 17→16, Copy weight absorbed into Intent
- Over-aggressive directives removed from all prompts (ALL-CAPS, "FLAG SPECIFICALLY", "NEVER", "Find at least N")
- `/design-improve` now reads `top_fixes` array programmatically from structured boss output
- `generate-report.sh` consumes structured JSON from flow-state.json
- Playfair Display moved from flat-banned to context-conditional (editorial OK, SaaS flagged)
- `design-review.md` reduced from 738 to ~500 lines via `@` includes to extracted prompt files
- Structural validation expanded from 56 to 107+ checks

### The Prompt Engineering Journey

v1.0 specialist prompts were written ad-hoc — "Score 1-4, find issues, report them." They worked, but v1.2 rewrites them to Anthropic's 2026 best practices: XML structure, concrete rubrics, few-shot calibration, chain-of-thought reasoning. The eval runner proves the improvement is real, not just theoretical.

## [1.1.0] - 2026-03-30

### Added

- Flow-level SPA design audit (`/design-audit` command) with intent-guided and deterministic navigation modes
- Playwright MCP integration for stateful browser navigation with DOM stability detection
- Per-screen 8-specialist review with smart weighting (full review on first/last, quick on middle screens)
- Cross-screen consistency analysis detecting visual drift in colors, spacing, typography, buttons, and components
- Animation detection with CSS transition/property analysis and `prefers-reduced-motion` compliance checking
- Self-contained HTML diagnostic report with base64-embedded JPEG screenshots, flow map, expandable specialist details, and print-to-PDF support
- Flow score aggregation with position-weighted averaging (1.5x for first and last screens)
- Consistency penalty system (up to 15% score reduction for cross-screen drift)
- Authentication gate for auditing protected flows (`--auth` flag)
- Static HTML test fixtures for flow navigation smoke testing
- Report generation test fixtures with mock flow state

### Changed

- Plugin manifest updated with `design-audit` command
- Score bars in HTML report use CSS percentage-width divs (not Unicode blocks)
- Report generation is non-blocking -- terminal summary is the primary output, HTML report is a bonus

## [1.0.0] - 2026-03-29

### Added

- Multi-model code review skill (`/code-review` command) with Claude, Codex, and Gemini consensus
- Confidence-scored findings with cross-model agreement detection
- 3-tier model degradation (3 models -> 2 models -> single model)
- Case studies: [design-review impact](docs/case-studies/design-review-impact.md), [code-review bugs caught](docs/case-studies/code-review-bugs-caught.md)
- `install.sh` manual installer (clone + symlink)
- Branded output with signature line, unicode boxes, and progress bars across both skills
- Init wizard (`/design-init`) with 5 interactive questions for first-time setup
- Palette engine with 15 design identity palettes (3 per page type)

### Changed

- Plugin manifest now lists all commands: design, design-review, design-improve, design-validate, design-init, code-review
- README expanded with code-review documentation, case study links, and dual install methods
- Plugin name `spsk` supports multi-skill expansion beyond design-review

---

## [0.9.0] - 2026-03-28

### What Works (Design Review)

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
