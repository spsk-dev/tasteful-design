# Roadmap: SpSk (Simple Skill)

## Milestones

- ✅ **v1.0.0 MVP** - Phases 1-3 (shipped 2026-03-29)
- ✅ **v1.1.0 Flow Audit + Polish** - Phases 4-7 (shipped 2026-03-29)
- 🚧 **v1.2.0 Prompting Excellence + Eval Credibility** - Phases 8-13 (in progress)

## Phases

<details>
<summary>v1.0.0 MVP (Phases 1-3) - SHIPPED 2026-03-29</summary>

- [x] **Phase 1: Scaffold + Port + Evals** - Working plugin installable from GitHub with reproducible benchmark proof (completed 2026-03-29)
- [x] **Phase 2: Init Wizard + Branding + Demo** - First-run experience, visual identity, and README that sells the tool
- [x] **Phase 3: Second Skill + Release** - Platform proof with multi-model-code-review, case studies, and v1.0.0

### Phase 1: Scaffold + Port + Evals
**Goal**: A developer can install the design-review plugin from GitHub and run a full 8-specialist review that produces the same quality as the local version, with reproducible eval results proving the claims
**Depends on**: Nothing (first phase)
**Requirements**: SCAF-01, SCAF-02, SCAF-03, SCAF-04, SCAF-05, SCAF-06, PORT-01, PORT-02, PORT-03, PORT-04, PORT-05, PORT-06, PORT-07, PORT-08, PORT-09, PORT-10, EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05
**Success Criteria** (what must be TRUE):
  1. A user can run `claude /install-plugin spsk@felipemachado/spsk` and get a working plugin with all 4 commands available (`/design-review`, `/design`, `/design-improve`, `/design-validate`)
  2. Running `/design-review` on a frontend page produces an 8-specialist weighted score with SHIP/BLOCK verdict, and the review degrades gracefully to Tier 2/3 when Gemini CLI is unavailable
  3. Running `run-evals.sh` on a clean clone produces passing results against bundled test fixtures with range-based assertions
  4. ARCHITECTURE.md explains the multi-agent design clearly enough that a developer unfamiliar with the project understands specialist roles, boss synthesizer pattern, scoring, and degradation tiers
  5. CHANGELOG.md shows the transparent failure history -- v1 single-agent at 40%, progression to v4 multi-agent at 100%
**Plans:** 3/3 complete

Plans:
- [x] 01-01-PLAN.md -- Scaffold repo structure, port all 22 plugin files, audit hardcoded paths, create README + CLAUDE.md
- [x] 01-02-PLAN.md -- Portfolio-grade ARCHITECTURE.md and transparent CHANGELOG.md
- [x] 01-03-PLAN.md -- Two-layer eval harness with bundled fixtures and range-based assertions

### Phase 2: Init Wizard + Branding + Demo
**Goal**: A new user goes from install to first configured review in under 2 minutes, with branded output that makes SpSk recognizable and a demo GIF that sells the tool from the README
**Depends on**: Phase 1
**Requirements**: INIT-01, INIT-02, INIT-03, INIT-04, INIT-05, INIT-06, INIT-07, INIT-08, PALT-01, PALT-02, PALT-03, BRND-01, BRND-02, BRND-03, BRND-04, BRND-05, BRND-06, DEMO-01, DEMO-02
**Success Criteria** (what must be TRUE):
  1. Running `/design init` walks through 5 questions with opinionated defaults and creates a `.design/` directory with configured tokens in under 2 minutes
  2. When a user skips brand colors during init, the palette engine suggests 3 named palettes contextual to their page type
  3. Every SpSk command output includes the branded signature line, unicode boxes for results, progress bars for scores, and a footer with the repo link
  4. The README contains an embedded 30-second demo GIF showing a real design-review run
**Plans:** 3/3 complete

Plans:
- [x] 02-01-PLAN.md -- Branding reference file, palette engine data, and eval validator updates
- [x] 02-02-PLAN.md -- Init wizard command with 5 questions and router update
- [x] 02-03-PLAN.md -- Branded output integration across commands, VHS demo tape, README GIF embed

### Phase 3: Second Skill + Release
**Goal**: SpSk ships as a two-skill platform with measurable impact evidence, installable from the plugin registry and ready for public use
**Depends on**: Phase 2
**Requirements**: CREV-01, CREV-02, CREV-03, REL-01, REL-02, REL-03, REL-04
**Success Criteria** (what must be TRUE):
  1. A user can run `/code-review` to review a PR with Claude + Codex + Gemini in parallel, producing confidence-scored findings with shared branded output
  2. Case studies show measurable before/after impact from real project usage
  3. The repo has a v1.0.0 tag, and the plugin installs via both `claude /install-plugin` and the manual `install.sh` script
  4. The multi-model-code-review skill has its own independent eval harness with passing results
**Plans:** 3/3 complete

Plans:
- [x] 03-01-PLAN.md -- Port multi-model-code-review skill, create command and skill files, update plugin manifest
- [x] 03-02-PLAN.md -- Independent eval harness for code-review with structural checks, assertions, and sample diff fixture
- [x] 03-03-PLAN.md -- Case studies with measurable impact, install.sh, README/CHANGELOG/VERSION for v1.0.0 release

</details>

<details>
<summary>v1.1.0 Flow Audit + Polish (Phases 4-7) - SHIPPED 2026-03-29</summary>

- [x] **Phase 4: Flow Navigation Engine** - Playwright MCP-driven SPA navigation with intent-guided screen capture
- [x] **Phase 5: Per-Screen Review + Animation** - 8-specialist review wired into flow context with cross-screen consistency and animation detection
- [x] **Phase 6: HTML Diagnostic Report** - Self-contained HTML report with embedded screenshots, scores, and fix recommendations
- [x] **Phase 7: Release Polish** - Demo GIF, docs updates, repo cleanup, and v1.1.0 release

### Phase 4: Flow Navigation Engine
**Goal**: A user can run `/design-audit <url> --flow "checkout flow"` and watch the agent navigate through SPA screens, capturing a screenshot at each state change, with the flow stopping gracefully at completion or dead ends
**Depends on**: Phase 3 (v1.0.0 complete)
**Requirements**: FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05, FLOW-06, FLOW-07, FLOW-08
**Success Criteria** (what must be TRUE):
  1. User runs `/design-audit <url> --flow "sign up and complete onboarding"` and the agent navigates through multiple SPA screens by clicking CTAs that match the described intent
  2. A screenshot is captured at each detected screen state change, with screen detection based on DOM stability (not networkidle)
  3. Navigation stops after hitting the max screen limit (default 10) or when the agent detects flow completion / dead end
  4. User can provide `--steps url1,url2,url3` to force a deterministic navigation path instead of intent-guided exploration
  5. User can provide authentication credentials so the agent logs in before auditing a protected flow
**Plans:** 3/3 complete

Plans:
- [x] 04-01-PLAN.md -- Foundation: flow config, navigation reference, plugin registration, router update
- [x] 04-02-PLAN.md -- Core design-audit.md command with intent and deterministic navigation modes
- [x] 04-03-PLAN.md -- Test fixtures and end-to-end verification of auth flow and graceful stop

### Phase 5: Per-Screen Review + Animation
**Goal**: Each captured screen receives an 8-specialist design review with smart weighting, cross-screen consistency analysis flags visual drift between screens, and CSS animation/transition properties are detected and assessed
**Depends on**: Phase 4
**Requirements**: REVW-01, REVW-02, REVW-03, REVW-04, ANIM-01, ANIM-02, ANIM-03
**Success Criteria** (what must be TRUE):
  1. The first and last screens in a flow receive a full 8-specialist review, while middle screens receive a quick-mode 4-specialist review to manage token usage
  2. Cross-screen consistency analysis flags when button styles, colors, spacing, or typography drift between screens in the same flow
  3. Per-screen scores are aggregated into an overall flow score that reflects the entire navigation path
  4. CSS transition/animation properties are detected between screen states, `prefers-reduced-motion` compliance is checked, and animation findings appear in per-screen specialist output
**Plans:** 3/3 complete

Plans:
- [x] 05-01-PLAN.md -- Config and reference contracts: smart weighting, flow scoring, animation patterns, consistency heuristics
- [x] 05-02-PLAN.md -- Per-screen review dispatch with animation detection hooks and flow score aggregation
- [x] 05-03-PLAN.md -- Cross-screen consistency analysis with visual drift detection and score penalty

### Phase 6: HTML Diagnostic Report
**Goal**: The flow audit produces a self-contained HTML file that a developer can open in any browser to see the full flow map, per-screen screenshots with specialist scores, and actionable fix recommendations -- shareable without any external dependencies
**Depends on**: Phase 5
**Requirements**: REPT-01, REPT-02, REPT-03, REPT-04, REPT-05, REPT-06, REPT-07
**Success Criteria** (what must be TRUE):
  1. Opening the generated HTML file shows a flow map (screen 1 -> 2 -> 3 -> ...) with base64-embedded JPEG screenshots and no external dependencies
  2. Each screen section shows the screenshot, 8-specialist scores, specific issues found, and fix recommendations, with specialist details collapsed by default and expandable on click
  3. The report includes an overall flow score summary with the top 5 priority fixes across all screens
  4. The report prints cleanly to PDF via browser print dialog (`@media print` styles), and total file size stays under 5MB
**Plans:** 2/2 complete

Plans:
- [x] 06-01-PLAN.md -- Report generator script with HTML template, screenshot embedding, flow map, and test fixture
- [x] 06-02-PLAN.md -- Wire report generation into design-audit.md Section 15, visual checkpoint

### Phase 7: Release Polish
**Goal**: v1.1.0 is documented, demoed, and tagged -- the README sells the flow audit feature, all repo references are consistent, and the release is installable
**Depends on**: Phase 6
**Requirements**: PLSH-01, PLSH-02, PLSH-03, PLSH-04, PLSH-05, PLSH-06
**Success Criteria** (what must be TRUE):
  1. A 30-second demo GIF in the README shows a real `/design-audit` flow run with the HTML report output
  2. README documents `/design-audit` usage with flow examples and report screenshots, ARCHITECTURE.md includes the flow audit component diagram
  3. All repo references use the spsk-dev org consistently, VERSION reads 1.1.0, and the repo has a v1.1.0 git tag
**Plans:** 2/2 complete

Plans:
- [x] 07-01-PLAN.md -- Docs update (README, ARCHITECTURE, CHANGELOG) and stale reference cleanup
- [x] 07-02-PLAN.md -- Demo tape update, VERSION bump, plugin.json update, git tag v1.1.0

</details>

### v1.2.0 Prompting Excellence + Eval Credibility (In Progress)

**Milestone Goal:** Upgrade all prompts to best-practice standards, make quality evals functional, migrate specialists to structured JSON output, consolidate 8 to 7 specialists, and add Playwright interaction capture.

- [ ] **Phase 8: Prompt Extraction + Restructuring** - Specialist prompts extracted to individual files, restructured with XML tags, aggressive directives removed, baselines recorded
- [ ] **Phase 9: Layer 2 Eval Runner** - Quality eval runner executes real assertions against design-review output with calibrated ranges and verdict gates
- [ ] **Phase 10: Structured JSON Output** - All specialists and boss emit structured JSON for deterministic parsing by evals, improve loop, and report generator
- [ ] **Phase 11: Specialist Consolidation** - Copy folded into Intent/Originality/UX, scoring weights atomically updated, 8 to 7 specialists
- [ ] **Phase 12: Playwright Interaction** - Opt-in hover/focus/scroll capture before specialist scoring with baseline-interact-reset pattern
- [ ] **Phase 13: Few-Shot Examples + Polish** - Curated examples per specialist, chain-of-thought separation, Anthropic aesthetics integration

## Phase Details

### Phase 8: Prompt Extraction + Restructuring
**Goal**: Every specialist prompt lives in its own file, follows XML best-practice structure, and has a recorded eval baseline -- enabling isolated testing and safe iteration on prompt quality
**Depends on**: Phase 7 (v1.1.0 complete)
**Requirements**: PRMT-01, PRMT-02, PRMT-03, PRMT-06, PRMT-07
**Success Criteria** (what must be TRUE):
  1. Running `/design-review` loads specialist prompts via `@` includes from `skills/design-review/prompts/*.md` -- each of the 8 specialists and the boss synthesizer has its own prompt file
  2. Every specialist prompt uses XML-structured sections (`<role>`, `<context>`, `<instructions>`, `<output_format>`) and includes a 4-level scoring rubric with concrete anchors per level
  3. No specialist prompt contains ALL-CAPS emphasis, "FLAG SPECIFICALLY", "NEVER", or "Find at least N" directives
  4. Running the existing `run-evals.sh` against the restructured prompts produces passing results (no regression from extraction)
**Plans**: TBD

### Phase 9: Layer 2 Eval Runner
**Goal**: A developer can run `run-quality-evals.sh` and get pass/fail results for every quality assertion against real design-review output -- the measurement instrument that validates all subsequent prompt changes
**Depends on**: Phase 8
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, EVAL-06
**Success Criteria** (what must be TRUE):
  1. Running `run-quality-evals.sh` serves test fixtures via python3, invokes `/design-review` via `claude --print`, and reports pass/fail per assertion with a final summary
  2. Verdict-level assertions work as the primary gate: a known-bad fixture gets BLOCK, a known-good fixture gets SHIP, and a gray-area fixture gets CONDITIONAL
  3. Range-based score assertions are calibrated from 3 baseline runs per fixture with observed spread + 0.3 buffer, and eval result snapshots are stored for regression detection
  4. LLM-as-judge assertions using Claude Haiku evaluate specialist output quality against binary rubrics (requires ANTHROPIC_API_KEY, skipped gracefully when absent)
**Plans**: TBD

### Phase 10: Structured JSON Output
**Goal**: Every specialist and the boss synthesizer emit structured JSON that the eval runner, improve loop, and report generator can parse deterministically -- ending regex-based output scraping
**Depends on**: Phase 9
**Requirements**: JSON-01, JSON-02, JSON-03, JSON-04, JSON-05
**Success Criteria** (what must be TRUE):
  1. All specialists emit JSON wrapped in `<specialist_output>` tags and the boss emits JSON wrapped in `<boss_output>` tags, parseable by `jq` after tag extraction
  2. The output parser (`parse-review-output.sh`) tries JSON-first and falls back to regex for backward compatibility with pre-v1.2.0 output
  3. `/design-improve` reads the `top_fixes` array from structured boss output programmatically instead of scraping fix text from terminal output
  4. `generate-report.sh` reads structured JSON from `flow-state.json` for deterministic report generation without regex parsing
  5. Running `run-quality-evals.sh` passes with structured JSON output (no regression from the migration)
**Plans**: TBD

### Phase 11: Specialist Consolidation
**Goal**: The Copy specialist is merged into Intent/Originality/UX as a fourth sub-score, scoring weights are atomically correct, and the system runs cleanly as 7 specialists
**Depends on**: Phase 10
**Requirements**: SPEC-01, SPEC-02, SPEC-03
**Success Criteria** (what must be TRUE):
  1. Running `/design-review` dispatches 7 specialists (not 8), with Intent/Originality/UX producing 4 sub-scores: intent_match, originality, ux_flow, copy_quality
  2. `scoring.json` reads total_weight: 16 (not 17), quick_mode weights are recalculated, and `validate-structure.sh` includes an assertion verifying sum of individual weights equals total_weight
  3. Running `run-quality-evals.sh` passes with 7 specialists -- all assertion ranges recalibrated for the merged architecture
**Plans**: TBD

### Phase 12: Playwright Interaction
**Goal**: Users can opt into hover/focus/scroll interaction capture before specialist scoring, giving specialists richer state information without mutating the page they review
**Depends on**: Phase 8 (stable prompts)
**Requirements**: INTR-01, INTR-02, INTR-03, TEST-01
**Success Criteria** (what must be TRUE):
  1. Running `/design-review <url> --interact` triggers Playwright hover, focus, and scroll interactions before specialist analysis, with interaction screenshots passed to relevant specialists (Motion, Code/A11y, Color/Layout)
  2. The baseline-interact-reset pattern is followed: screenshot clean state first, perform interactions, reload page, then run the standard review -- specialists never see interaction-mutated DOM as the baseline
  3. No more than 8 interactions are performed per review (budget cap enforced)
  4. Running `/design-audit` on start.fusefinance.com completes a full flow audit with real SPA navigation, validating the complete pipeline end-to-end
**Plans**: TBD

### Phase 13: Few-Shot Examples + Polish
**Goal**: Specialists produce better-calibrated scores through curated examples and chain-of-thought reasoning, and the build phase benefits from Anthropic's proven aesthetics guidance
**Depends on**: Phase 10 (stable structured output)
**Requirements**: PRMT-04, PRMT-05, GNRT-01
**Success Criteria** (what must be TRUE):
  1. Every specialist prompt includes 2-3 curated few-shot examples in `<examples>` tags showing ideal output format and scoring calibration at different score levels
  2. Complex specialists (Intent, Layout, Boss) use `<thinking>` + `<answer>` separation, with reasoning visible in the thinking block and structured output in the answer block
  3. `references/generation.md` exists with Anthropic's DISTILLED_AESTHETICS_PROMPT adapted for the `/design-improve` build phase, and `/design-improve` references it during page generation
  4. Token usage per full review increases by no more than 30% compared to Phase 8 baseline (measured before and after)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 8 -> 9 -> 10 -> 11 -> 12 -> 13
(Phase 12 depends on Phase 8 not Phase 11 -- can start after prompts stabilize, but sequenced after Phase 11 for simplicity)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Scaffold + Port + Evals | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 2. Init Wizard + Branding + Demo | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 3. Second Skill + Release | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 4. Flow Navigation Engine | v1.1.0 | 3/3 | Complete | 2026-03-30 |
| 5. Per-Screen Review + Animation | v1.1.0 | 3/3 | Complete | 2026-03-29 |
| 6. HTML Diagnostic Report | v1.1.0 | 2/2 | Complete | 2026-03-29 |
| 7. Release Polish | v1.1.0 | 2/2 | Complete | 2026-03-29 |
| 8. Prompt Extraction + Restructuring | v1.2.0 | 0/? | Not started | - |
| 9. Layer 2 Eval Runner | v1.2.0 | 0/? | Not started | - |
| 10. Structured JSON Output | v1.2.0 | 0/? | Not started | - |
| 11. Specialist Consolidation | v1.2.0 | 0/? | Not started | - |
| 12. Playwright Interaction | v1.2.0 | 0/? | Not started | - |
| 13. Few-Shot Examples + Polish | v1.2.0 | 0/? | Not started | - |
