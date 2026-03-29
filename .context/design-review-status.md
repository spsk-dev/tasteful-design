---
name: design-review skill — architecture and status (2026-03-28)
description: Multi-agent design review skill with 8 specialists + boss synthesizer. Built to solve Claude's inability to self-evaluate visual design quality. Located at ~/.claude/skills/design-review/
type: project
---

## What It Is
`/design-review` skill at `~/.claude/skills/design-review/SKILL.md` (553 lines, v4)
8 specialist agents + boss synthesizer, modeled after multi-model-code-review pattern.

**Architecture:**
- Phase 0: Screenshots (mandatory — serve static HTML if no dev server)
- Phase 1: Haiku classifies page type → sets creativity bar
- Phase 2: 8 specialists in parallel (Font, Color/Gemini, Layout/Gemini, Icon, Motion, Intent, Copy, Code)
- Phase 3: Boss synthesizes with weighted scoring, context-aware SHIP/BLOCK threshold

**Specialist roster:**
| # | Agent | Model | Reads |
|---|-------|-------|-------|
| 1 | Font | Claude Sonnet | screenshots + source + references/typography.md |
| 2 | Color | Gemini CLI | screenshots + .color-reference.md |
| 3 | Layout | Gemini CLI | screenshots + .layout-reference.md |
| 4 | Icon | Claude Sonnet | screenshots + source + references/icons.md |
| 5 | Motion | Claude Sonnet | source only + references/motion.md |
| 6 | Intent | Claude Sonnet | screenshots + source + references/intent.md |
| 7 | Copy | Claude Haiku | source only |
| 8 | Code | Claude Sonnet | source only |

**Scoring:** (Intent*3 + Originality*3 + Typography*2 + Color*2 + Layout + Icons + Motion + Copy + Code) / 15

**Thresholds:** Admin ≥2.5, Dashboard ≥2.8, Landing ≥3.0, Portfolio ≥3.5, Emotional ≥3.0

## Test Results (2026-03-28)
- Admin panel: SHIP at ~3.1 (correctly recognized template design as appropriate)
- Landing page: BLOCK at 1.93 (correctly demanded creativity, flagged AI slop)
- Mother's Day: CONDITIONAL SHIP at 2.53 (correctly demanded warmth)

## Reference Files
6 files at `~/.claude/skills/design-review/references/`:
- typography.md (AI-overused fonts list, pairing rules, hierarchy)
- color.md (WCAG ratios, AI palette anti-patterns, dark/light mode)
- layout.md (spacing grid, monotony detection, responsive)
- icons.md (library tiers, sizing, consistency)
- motion.md (duration guidelines, performance tiers, anti-patterns)
- intent.md (when template is correct vs creativity required, AI slop detection)

## v4 Additions (2026-03-28)
1. **Quick mode** (`--quick`): 4 core specialists (Font, Color, Layout, Intent) instead of 8. Saves ~40-50% tokens.
2. **Gemini retry + fallback**: Retry once after 10s on rate limit. Fall back to Claude Sonnet if still failing.
3. **Degradation tiers**: Tier 1 (full), Tier 2 (no Gemini), Tier 3 (code-only). Never fails silently — always reports which tier ran.
4. **Phase 5: targeted re-review**: After BLOCK/CONDITIONAL, outputs prioritized fix list with file:line refs. Re-review only runs failing specialists (scored ≤2), keeps passing scores. Tracks iteration deltas.
5. **Quantitative eval assertions**: 19 assertions across 3 test cases in evals.json.
6. **Calibration template**: `evals/calibration-template.md` for Felipe to validate scoring weights against his own judgment.
7. **Design references**: `--ref <url|file|figma>`, `--palette`, `--fonts` for external design targets.
8. **Figma modes**: `--figma <url>` reviews Figma designs pre-build, `--figma <url> --compare` checks impl fidelity.
9. **Direction mode**: `--direction "text"` evaluates against a creative brief.
10. **New `/design-improve` skill**: iterative build→review→fix→re-review loop with anti-slop defaults and max iterations.

## Benchmark Results (v4, 2026-03-28)
- With skill: 100% assertion pass rate (20/20) across 3 evals
- Without skill: 40% pass rate (8/20)
- Token cost: ~84K per full review, ~50K baseline
- Tested on live dev server (harness-panel): CONDITIONAL SHIP at 2.53/4.0

## Plugin v1.0.0 Complete (2026-03-28)
Published at `~/.claude/plugins/design-review/`. 22 files, 4 commands.

**Commands:** `/design` (orchestrator), `/design-review` (8 specialists), `/design-improve` (iterative loop), `/design-validate` (functional testing)

**Features validated (12 test runs, 8/8 features passing):**
- Full 8-specialist review (5 runs), improve loop (2.53→3.0), quick mode (/13), style presets, /design-validate (Playwright MCP), .design/ harness (5/5 deviations), --ref URL comparison, /design ship pipeline

**Consensus scores (3 models):**
- v1: 5.5/10 → v2 (bugs fixed): 7.8/10 → v3 (all features tested): **8.6/10**
- Opus 8, Codex 8.6, Gemini 9.2 — all agree: production-ready

**Configs:** scoring.json (weights/thresholds), anti-slop.json (banned patterns), style-presets.json (5 built-in), design-system.example.json

**Path to 9+:** automated eval suite, token budget awareness, uniform-score detection, Figma e2e, non-happy-path coverage

## Next: SpSk (Simple Skill) — GitHub Portfolio
Felipe wants to publish skills as portfolio pieces on GitHub (github.com/felipemachado/SpSk). Design-review is the first skill. Needs:
- Branded output (SpSk ASCII art, consistent formatting)
- `/design init` — interactive setup wizard (taste, colors, animation level, dark/light)
- Swatch suggestions based on vibe
- Standardized output like GSD prints its letters
- Easy to use for others — this is Felipe's CV

## Known Limitations
1. Orchestrator must run all Bash (screenshots, Gemini CLI) — subagents can't
2. Token-heavy (~200K+ for full 8-specialist review, ~120K for quick mode)
3. Must clean stale screenshots from workspace before each run
4. Gemini reference files must be copied to repo root (workspace restriction)
5. Only tested on static HTML so far — needs dev server testing

## Origin
Built from Felipe's frustration that Claude always says "looks great" when self-evaluating UI. Confirmed by Anthropic's generator-evaluator research. Conversation started from a Slack thread with Eze about design quality.

**Why:** Felipe was up until 11pm iterating on design that Claude kept approving. The skill ensures honest, structured critique from domain specialists instead of sycophantic self-evaluation.

**How to apply:** Run `/design-review` after any frontend UI work. The orchestrator handles screenshots and Gemini dispatch; specialists just read files.
