# SpSk (Simple Skill)

## What This Is

A GitHub portfolio project that publishes Felipe Machado's most polished AI agent skills as open-source Claude Code plugins. Design-review is the flagship skill (8 specialist agents, 10 scored dimensions, 8.6/10 consensus score). The repo serves as a professional showcase demonstrating deep understanding of AI agent architectures, harnesses, and their practical value for developers.

## Core Value

The published skills must be immediately useful to other developers AND demonstrate architectural sophistication — the tool is the proof, the architecture is the CV.

## Requirements

### Validated

- ✓ Repo scaffold with proper plugin structure — v1.0.0 Phase 1
- ✓ Design-review plugin ported (22 files) — v1.0.0 Phase 1
- ✓ Reproducible evaluation harness (run-evals.sh) — v1.0.0 Phase 1
- ✓ ARCHITECTURE.md documenting multi-agent design — v1.0.0 Phase 1
- ✓ Init wizard with 5 questions + palette engine — v1.0.0 Phase 2
- ✓ Branded output system (shared/output.md) — v1.0.0 Phase 2
- ✓ Multi-model code-review skill (extracted to spsk-dev/code-review) — v1.0.0 Phase 3
- ✓ Case studies with measurable impact — v1.0.0 Phase 3
- ✓ v1.0.0 release + install.sh — v1.0.0 Phase 3
- ✓ `/design-audit` SPA flow navigation with per-screen review — v1.1.0 Phase 4-5
- ✓ HTML diagnostic report with embedded screenshots — v1.1.0 Phase 6
- ✓ Animation/transition detection between screen states — v1.1.0 Phase 5
- ✓ Demo GIF tape file + repo reference cleanup — v1.1.0 Phase 7

### Active

- [ ] Prompt overhaul — all specialist, boss, and flow audit prompts rewritten to best-practice standards
- [ ] Quality evals Layer 2 — assertions against real design-review output, not just structural checks
- [ ] Structured JSON specialist output — for tighter improve loop and report generation
- [ ] Anthropic aesthetics integration — generation.md from DISTILLED_AESTHETICS_PROMPT
- [ ] Playwright interaction before scoring — hover, click, scroll before specialist analysis
- [ ] Fold Copy into Intent — reduce 8→7 specialists
- [ ] Live validation on start.fusefinance.com

## Current Milestone: v1.2.0 Prompting Excellence + Eval Credibility

**Goal:** Upgrade all prompts to best-practice standards, make quality evals functional, and integrate Anthropic's proven patterns.

**Target features:**
- Review and rewrite ALL specialist prompts against prompting best practices (clear roles, constraints, few-shot examples, chain-of-thought, structured output schemas)
- Quality evals Layer 2 functional — real design-review output tested with range-based assertions
- Structured JSON output from specialists for tighter improve loop
- Anthropic's DISTILLED_AESTHETICS_PROMPT integrated as generation guidance
- Playwright page interaction before specialist scoring
- Copy specialist folded into Intent/Originality/UX (8→7)
- Full flow audit validation on start.fusefinance.com

### Out of Scope

- Framework/SDK for third-party skill creation — emerges naturally from 2nd/3rd skills, not built upfront
- npm package distribution — Claude Code plugin registry + GitHub is sufficient for v1
- Web UI or dashboard — this is a CLI/agent tool, not a web app
- Paid features or licensing — fully open source

## Context

- Felipe is VP of Engineering at Fuse Finance with deep experience across backend (NestJS), frontend (React/Svelte), AI/ML, and infrastructure
- Has a sophisticated agent harness with hooks, memory, observability across Claude Code, Codex, and Gemini
- Created GSD workflow, multi-model code review, consensus validation, and the design-review plugin
- The design-review plugin was built and validated to 8.6/10 in one session using 3-model consensus
- Source plugin lives at ~/.claude/plugins/design-review/ (22 files)
- 3-model consensus strategy confirmed: Opus (evals, show failures), Gemini (meta-cognition, specialist disagreements), Codex (case studies, measurable impact)

## Constraints

- **Distribution**: Claude Code plugin registry as primary (`claude /install-plugin design-review@felipemachado/spsk`) + install.sh for manual
- **Branding**: Clean and compact, NOT big ASCII art. Signature line format: ` SpSk  design-review  v1.2.0  ---  8 specialists  ·  tier 1`
- **Init wizard**: Exactly 5 questions with opinionated defaults (page type, vibe preset, light/dark, brand colors, font preference)
- **Quality bar**: Must show what DIDN'T work in CHANGELOG (v1 single-agent scored 40%) — transparency builds credibility

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| GSD to build, standalone after shipping | Structured approach for 3 phases, then maintain independently | -- Pending |
| Design-review as flagship, multi-model-code-review as 2nd | One plugin = one-off, two = platform. Code review has 100x audience reach vs consensus-validation | -- Pending |
| Evals as first-class citizen | "Evals are the crown jewel" — reproducible benchmarks prove quality claims | -- Pending |
| Show failures transparently | v1 single-agent scored 40%, multi-agent scored 8.6/10 — the delta IS the story | -- Pending |
| 3-phase build plan | Phase 1: scaffold+port, Phase 2: wizard+branding, Phase 3: 2nd skill+release | -- Pending |
| Swap consensus-validation for multi-model-code-review | Code review has wider audience, easier to demo, complementary domain (code quality vs visual quality). consensus-validation deferred to v1.1 | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-29 after starting milestone v1.2.0*
