# Requirements: SpSk v1.2.0 — Prompting Excellence + Eval Credibility

**Defined:** 2026-03-29
**Core Value:** Published skills must be immediately useful AND demonstrate architectural sophistication

## v1.2.0 Requirements

### Prompt Engineering

- [x] **PRMT-01**: All specialist prompts use XML-structured sections (`<role>`, `<context>`, `<instructions>`, `<output_format>`, `<examples>`)
- [x] **PRMT-02**: Every specialist has a 4-level scoring rubric with concrete anchors per level (not bare "Score 1-4")
- [x] **PRMT-03**: Over-aggressive directives removed (ALL-CAPS emphasis, "FLAG SPECIFICALLY", "NEVER", "Find at least N")
- [ ] **PRMT-04**: 2-3 curated few-shot examples per specialist showing ideal output format and scoring calibration
- [ ] **PRMT-05**: Chain-of-thought `<thinking>` + `<answer>` separation in complex specialists (Intent, Layout, Boss)
- [x] **PRMT-06**: Specialist prompts extracted to individual files (`skills/design-review/prompts/*.md`) with `@` includes from commands
- [x] **PRMT-07**: Boss synthesizer prompt restructured with XML tags, explicit output schema, and cross-specialist reasoning instructions

### Eval Credibility

- [x] **EVAL-01**: Layer 2 eval runner (`run-quality-evals.sh`) executes all assertions against real design-review output
- [x] **EVAL-02**: Assertion ranges calibrated from 3 baseline runs per fixture with observed spread + buffer
- [x] **EVAL-03**: Verdict-level assertions (binary: bad page gets BLOCK, good page gets SHIP) as primary gate
- [x] **EVAL-04**: At least one gray-area fixture added (mediocre page that should get CONDITIONAL)
- [x] **EVAL-05**: LLM-as-judge binary rubric assertions using Claude Haiku for quality checks (requires ANTHROPIC_API_KEY)
- [x] **EVAL-06**: Eval result snapshots with per-specialist scores stored for regression detection across runs

### Structured Output

- [x] **JSON-01**: All specialists emit structured JSON wrapped in `<specialist_output>` tags
- [x] **JSON-02**: Boss synthesizer emits structured JSON wrapped in `<boss_output>` tags
- [x] **JSON-03**: Output parser supports dual-format (JSON-first with regex fallback for backward compatibility)
- [x] **JSON-04**: `/design-improve` consumes `top_fixes` array programmatically from structured JSON
- [x] **JSON-05**: `generate-report.sh` reads structured JSON from flow-state.json for deterministic report generation

### Specialist Architecture

- [x] **SPEC-01**: Copy specialist folded into Intent/Originality/UX with 4 sub-scores (intent, originality, ux_flow, copy_quality)
- [x] **SPEC-02**: `scoring.json` updated atomically: total_weight 17→16, quick_mode recalculated
- [x] **SPEC-03**: Structural assertion in `validate-structure.sh` verifying sum of weights equals total_weight

### Generation & Interaction

- [ ] **GNRT-01**: `references/generation.md` created from Anthropic's DISTILLED_AESTHETICS_PROMPT adapted for /design-improve build phase
- [x] **INTR-01**: Opt-in `--interact` flag for Playwright page interaction (hover, focus, scroll) before specialist scoring
- [x] **INTR-02**: Baseline-interact-reset pattern: screenshot clean state, interact, reload, then review
- [x] **INTR-03**: Interaction budget capped at 8 interactions per review
- [ ] **TEST-01**: Full flow audit validated on start.fusefinance.com with real SPA navigation

## Future Requirements (v1.3+)

- Eval fixtures covering Figma reference mode, style preset mode, dark mode
- Auto-tuning prompts based on eval results
- Vision-mode Playwright coordinate-based clicking
- Real-time eval dashboard
- Context-aware specialist dispatch (skip Motion on static pages)

## Out of Scope

- **Anthropic Structured Outputs API** — not exposed in Claude Code plugin context; prompt-enforced JSON is the path
- **LLM-as-judge for scoring** (replacing specialists) — specialists ARE the judges; Haiku is for eval validation only
- **Temperature tuning** — Claude Code does not expose temperature controls to plugins
- **Pixel-diff screenshot comparison** — ImageMagick dependency violates zero-dependency constraint
- **Per-specialist JSON schemas** — one shared schema with specialist-specific fields is sufficient

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRMT-01 | Phase 8 | Complete |
| PRMT-02 | Phase 8 | Complete |
| PRMT-03 | Phase 8 | Complete |
| PRMT-04 | Phase 13 | Pending |
| PRMT-05 | Phase 13 | Pending |
| PRMT-06 | Phase 8 | Complete |
| PRMT-07 | Phase 8 | Complete |
| EVAL-01 | Phase 9 | Complete |
| EVAL-02 | Phase 9 | Complete |
| EVAL-03 | Phase 9 | Complete |
| EVAL-04 | Phase 9 | Complete |
| EVAL-05 | Phase 9 | Complete |
| EVAL-06 | Phase 9 | Complete |
| JSON-01 | Phase 10 | Complete |
| JSON-02 | Phase 10 | Complete |
| JSON-03 | Phase 10 | Complete |
| JSON-04 | Phase 10 | Complete |
| JSON-05 | Phase 10 | Complete |
| SPEC-01 | Phase 11 | Complete |
| SPEC-02 | Phase 11 | Complete |
| SPEC-03 | Phase 11 | Complete |
| GNRT-01 | Phase 13 | Pending |
| INTR-01 | Phase 12 | Complete |
| INTR-02 | Phase 12 | Complete |
| INTR-03 | Phase 12 | Complete |
| TEST-01 | Phase 12 | Pending |

---
*Defined: 2026-03-29*
*Previous milestone requirements (v1.1.0): archived -- all 28 requirements completed*
