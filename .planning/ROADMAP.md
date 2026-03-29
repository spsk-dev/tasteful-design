# Roadmap: SpSk (Simple Skill)

## Overview

SpSk goes from a proven local plugin to a published GitHub portfolio piece in three phases. Phase 1 ports the working design-review plugin into a proper repo structure with reproducible evals that prove quality claims. Phase 2 adds the user-facing polish -- init wizard, palette engine, branded output, and a demo GIF that sells the tool without installing it. Phase 3 proves SpSk is a platform by shipping a second skill, collecting case studies, and cutting the v1.0.0 release.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Scaffold + Port + Evals** - Working plugin installable from GitHub with reproducible benchmark proof (completed 2026-03-29)
- [ ] **Phase 2: Init Wizard + Branding + Demo** - First-run experience, visual identity, and README that sells the tool
- [ ] **Phase 3: Second Skill + Release** - Platform proof with multi-model-code-review, case studies, and v1.0.0

## Phase Details

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
**Plans:** 3 plans

Plans:
- [x] 01-01-PLAN.md -- Scaffold repo structure, port all 22 plugin files, audit hardcoded paths, create README + CLAUDE.md
- [ ] 01-02-PLAN.md -- Portfolio-grade ARCHITECTURE.md and transparent CHANGELOG.md
- [ ] 01-03-PLAN.md -- Two-layer eval harness with bundled fixtures and range-based assertions

### Phase 2: Init Wizard + Branding + Demo
**Goal**: A new user goes from install to first configured review in under 2 minutes, with branded output that makes SpSk recognizable and a demo GIF that sells the tool from the README
**Depends on**: Phase 1
**Requirements**: INIT-01, INIT-02, INIT-03, INIT-04, INIT-05, INIT-06, INIT-07, INIT-08, PALT-01, PALT-02, PALT-03, BRND-01, BRND-02, BRND-03, BRND-04, BRND-05, BRND-06, DEMO-01, DEMO-02
**Success Criteria** (what must be TRUE):
  1. Running `/design init` walks through 5 questions with opinionated defaults and creates a `.design/` directory with configured tokens in under 2 minutes
  2. When a user skips brand colors during init, the palette engine suggests 3 named palettes contextual to their page type (e.g., different palettes for dashboard vs landing page)
  3. Every SpSk command output includes the branded signature line, unicode boxes for results, progress bars for scores, and a footer with the repo link
  4. The README contains an embedded 30-second demo GIF showing a real design-review run
**Plans:** 3 plans
**UI hint**: yes

Plans:
- [x] 02-01-PLAN.md -- Branding reference file, palette engine data, and eval validator updates
- [x] 02-02-PLAN.md -- Init wizard command with 5 questions and router update
- [ ] 02-03-PLAN.md -- Branded output integration across commands, VHS demo tape, README GIF embed

### Phase 3: Second Skill + Release
**Goal**: SpSk ships as a two-skill platform with measurable impact evidence, installable from the plugin registry and ready for public use
**Depends on**: Phase 2
**Requirements**: CREV-01, CREV-02, CREV-03, REL-01, REL-02, REL-03, REL-04
**Success Criteria** (what must be TRUE):
  1. A user can run `/code-review` to review a PR with Claude + Codex + Gemini in parallel, producing confidence-scored findings with shared branded output
  2. Case studies show measurable before/after impact (e.g., review score improvements, bugs caught, time savings) from real project usage
  3. The repo has a v1.0.0 tag, and the plugin installs via both `claude /install-plugin` and the manual `install.sh` script
  4. The multi-model-code-review skill has its own independent eval harness with passing results
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Scaffold + Port + Evals | 3/3 | Complete | 2026-03-29 |
| 2. Init Wizard + Branding + Demo | 0/3 | Not started | - |
| 3. Second Skill + Release | 0/2 | Not started | - |
