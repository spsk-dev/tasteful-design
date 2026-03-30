# Roadmap: SpSk (Simple Skill)

## Milestones

- ✅ **v1.0.0 MVP** - Phases 1-3 (shipped 2026-03-29)
- 🚧 **v1.1.0 Flow Audit + Polish** - Phases 4-7 (in progress)

## Phases

<details>
<summary>✅ v1.0.0 MVP (Phases 1-3) - SHIPPED 2026-03-29</summary>

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

### 🚧 v1.1.0 Flow Audit + Polish (In Progress)

**Milestone Goal:** Add flow-level design audit that navigates SPAs screen-by-screen with 8 specialists, producing an HTML diagnostic report.

- [ ] **Phase 4: Flow Navigation Engine** - Playwright MCP-driven SPA navigation with intent-guided screen capture
- [ ] **Phase 5: Per-Screen Review + Animation** - 8-specialist review wired into flow context with cross-screen consistency and animation detection
- [ ] **Phase 6: HTML Diagnostic Report** - Self-contained HTML report with embedded screenshots, scores, and fix recommendations
- [ ] **Phase 7: Release Polish** - Demo GIF, docs updates, repo cleanup, and v1.1.0 release

## Phase Details

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
**Plans:** 3 plans

Plans:
- [x] 04-01-PLAN.md -- Foundation: flow config, navigation reference, plugin registration, router update
- [x] 04-02-PLAN.md -- Core design-audit.md command with intent and deterministic navigation modes
- [ ] 04-03-PLAN.md -- Test fixtures and end-to-end verification of auth flow and graceful stop

### Phase 5: Per-Screen Review + Animation
**Goal**: Each captured screen receives an 8-specialist design review with smart weighting, cross-screen consistency analysis flags visual drift between screens, and CSS animation/transition properties are detected and assessed
**Depends on**: Phase 4
**Requirements**: REVW-01, REVW-02, REVW-03, REVW-04, ANIM-01, ANIM-02, ANIM-03
**Success Criteria** (what must be TRUE):
  1. The first and last screens in a flow receive a full 8-specialist review, while middle screens receive a quick-mode 4-specialist review to manage token usage
  2. Cross-screen consistency analysis flags when button styles, colors, spacing, or typography drift between screens in the same flow
  3. Per-screen scores are aggregated into an overall flow score that reflects the entire navigation path
  4. CSS transition/animation properties are detected between screen states, `prefers-reduced-motion` compliance is checked, and animation findings appear in per-screen specialist output
**Plans**: TBD
**UI hint**: yes

### Phase 6: HTML Diagnostic Report
**Goal**: The flow audit produces a self-contained HTML file that a developer can open in any browser to see the full flow map, per-screen screenshots with specialist scores, and actionable fix recommendations -- shareable without any external dependencies
**Depends on**: Phase 5
**Requirements**: REPT-01, REPT-02, REPT-03, REPT-04, REPT-05, REPT-06, REPT-07
**Success Criteria** (what must be TRUE):
  1. Opening the generated HTML file shows a flow map (screen 1 -> 2 -> 3 -> ...) with base64-embedded JPEG screenshots and no external dependencies
  2. Each screen section shows the screenshot, 8-specialist scores, specific issues found, and fix recommendations, with specialist details collapsed by default and expandable on click
  3. The report includes an overall flow score summary with the top 5 priority fixes across all screens
  4. The report prints cleanly to PDF via browser print dialog (`@media print` styles), and total file size stays under 5MB
**Plans**: TBD
**UI hint**: yes

### Phase 7: Release Polish
**Goal**: v1.1.0 is documented, demoed, and tagged -- the README sells the flow audit feature, all repo references are consistent, and the release is installable
**Depends on**: Phase 6
**Requirements**: PLSH-01, PLSH-02, PLSH-03, PLSH-04, PLSH-05, PLSH-06
**Success Criteria** (what must be TRUE):
  1. A 30-second demo GIF in the README shows a real `/design-audit` flow run with the HTML report output
  2. README documents `/design-audit` usage with flow examples and report screenshots, ARCHITECTURE.md includes the flow audit component diagram
  3. All repo references use the spsk-dev org consistently, VERSION reads 1.1.0, and the repo has a v1.1.0 git tag

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 4 -> 5 -> 6 -> 7

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Scaffold + Port + Evals | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 2. Init Wizard + Branding + Demo | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 3. Second Skill + Release | v1.0.0 | 3/3 | Complete | 2026-03-29 |
| 4. Flow Navigation Engine | v1.1.0 | 0/3 | Planning complete | - |
| 5. Per-Screen Review + Animation | v1.1.0 | 0/? | Not started | - |
| 6. HTML Diagnostic Report | v1.1.0 | 0/? | Not started | - |
| 7. Release Polish | v1.1.0 | 0/? | Not started | - |
