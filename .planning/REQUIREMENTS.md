# Requirements: SpSk (Simple Skill)

**Defined:** 2026-03-28
**Core Value:** Published skills must be immediately useful AND demonstrate architectural sophistication

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Scaffold

- [x] **SCAF-01**: Plugin manifest (`.claude-plugin/plugin.json`) with correct metadata, version, description
- [x] **SCAF-02**: README.md with install command, demo GIF placeholder, architecture overview, usage guide
- [x] **SCAF-03**: CLAUDE.md with command documentation and usage instructions
- [x] **SCAF-04**: LICENSE (MIT)
- [x] **SCAF-05**: CHANGELOG.md with transparent failure history (v1 single-agent 40%, v4 multi-agent 100%)
- [x] **SCAF-06**: ARCHITECTURE.md documenting multi-agent design, specialist roles, boss synthesizer, scoring, degradation tiers

### Design-Review Port

- [x] **PORT-01**: `/design-review` command ported — 8 specialists, weighted scoring, SHIP/BLOCK verdict
- [x] **PORT-02**: `/design` orchestrator ported — routes to review/improve/validate/ship
- [x] **PORT-03**: `/design-improve` iterative loop ported — build/review/fix cycle with score progression
- [x] **PORT-04**: `/design-validate` functional tests ported — Playwright MCP integration
- [x] **PORT-05**: Configuration files ported — scoring.json, anti-slop.json, style-presets.json
- [x] **PORT-06**: Skill file (SKILL.md) and reference files ported with `${CLAUDE_PLUGIN_ROOT}` paths
- [x] **PORT-07**: Hooks ported — suggest-review.sh + hooks.json
- [x] **PORT-08**: All hardcoded paths replaced with `${CLAUDE_PLUGIN_ROOT}` variable
- [x] **PORT-09**: Degradation tiers working — Tier 1 (full), Tier 2 (no Gemini), Tier 3 (code-only)
- [x] **PORT-10**: Quick mode (`--quick`) working — 4 specialists instead of 8

### Evaluation Harness

- [x] **EVAL-01**: run-evals.sh script that executes all eval assertions reproducibly
- [x] **EVAL-02**: Eval fixtures — test HTML pages or references bundled in repo
- [x] **EVAL-03**: Range-based assertions (not exact scores) for AI eval non-determinism
- [x] **EVAL-04**: Eval results documented with benchmark numbers in README
- [x] **EVAL-05**: Clean-machine install test passes (fresh Claude Code session)

### Init Wizard

- [ ] **INIT-01**: `/design init` command — 5 interactive questions with opinionated defaults
- [ ] **INIT-02**: Question 1: Page type (landing, dashboard, admin, etc.)
- [ ] **INIT-03**: Question 2: Vibe preset selection from built-in options
- [ ] **INIT-04**: Question 3: Light/dark/both preference
- [ ] **INIT-05**: Question 4: Brand colors (or skip for palette suggestions)
- [ ] **INIT-06**: Question 5: Font preference (or skip for vibe-based suggestion)
- [ ] **INIT-07**: Creates `.design/` directory with configured tokens
- [ ] **INIT-08**: Under 2 minutes from command to first value

### Palette Engine

- [ ] **PALT-01**: Suggest 3 color palettes when user skips brand colors
- [ ] **PALT-02**: Palettes have Design Identity names ("Midnight Corporate", "Warm Craft", etc.)
- [ ] **PALT-03**: Palettes are contextual — different suggestions for dashboard vs landing page

### Branded Output

- [ ] **BRND-01**: Signature line format: ` SpSk  design-review  v1.2.0  ---  8 specialists  ·  tier 1`
- [ ] **BRND-02**: Unicode boxes for checkpoints and results
- [ ] **BRND-03**: Symbol vocabulary: checkmark, cross, diamond, circle, lightning, warning
- [ ] **BRND-04**: Progress bars for scores (block characters)
- [ ] **BRND-05**: Footer with repo link on every review output
- [ ] **BRND-06**: Consistent formatting across all SpSk commands

### Demo

- [ ] **DEMO-01**: 30-second demo GIF showing design-review in action
- [ ] **DEMO-02**: GIF embedded in README.md replacing placeholder

### Second Skill

- [ ] **CREV-01**: multi-model-code-review skill — PR review via Claude + Codex + Gemini in parallel with confidence-scored findings
- [ ] **CREV-02**: Shared branded output patterns between design-review and code-review
- [ ] **CREV-03**: Independent eval harness for multi-model-code-review

### Release

- [ ] **REL-01**: Case studies with measurable before/after impact
- [ ] **REL-02**: v1.0.0 tag with proper semver
- [ ] **REL-03**: Install via `claude /install-plugin design-review@felipemachado/spsk`
- [ ] **REL-04**: install.sh for manual installation

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Platform

- **PLAT-01**: Shared utility extraction — patterns that emerged from 2+ skills formalized
- **PLAT-02**: Contribution guide for third-party skill authors
- **PLAT-03**: Plugin marketplace directory submission

### Consensus Validation (deferred from v1)

- **CONS-01**: consensus-validation skill — multi-model validation via Claude + Codex + Gemini
- **CONS-02**: Shared branded output patterns with existing skills
- **CONS-03**: Independent eval harness for consensus-validation

### Advanced Features

- **ADV-01**: Figma integration for reference-aware reviews
- **ADV-02**: CI/CD integration — run design-review in GitHub Actions
- **ADV-03**: Custom specialist authoring — users define their own review dimensions

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Framework/SDK for third-party skills | Premature abstraction — emerges from 2nd/3rd skills naturally |
| npm package distribution | No JS to package, plugin registry is the right channel |
| Web UI or dashboard | Terminal is the interface, not a browser |
| AI-generated design | SpSk evaluates design, it does not generate it |
| Per-project settings database | Over-scopes v1, reviews are point-in-time |
| Auto-fix without review | Users need to see changes before applying |
| Paid features or licensing | Portfolio piece, friction kills adoption |
| Big ASCII art branding | Clean and compact, not attention-seeking |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCAF-01 | Phase 1 | Complete |
| SCAF-02 | Phase 1 | Complete |
| SCAF-03 | Phase 1 | Complete |
| SCAF-04 | Phase 1 | Complete |
| SCAF-05 | Phase 1 | Complete |
| SCAF-06 | Phase 1 | Complete |
| PORT-01 | Phase 1 | Complete |
| PORT-02 | Phase 1 | Complete |
| PORT-03 | Phase 1 | Complete |
| PORT-04 | Phase 1 | Complete |
| PORT-05 | Phase 1 | Complete |
| PORT-06 | Phase 1 | Complete |
| PORT-07 | Phase 1 | Complete |
| PORT-08 | Phase 1 | Complete |
| PORT-09 | Phase 1 | Complete |
| PORT-10 | Phase 1 | Complete |
| EVAL-01 | Phase 1 | Complete |
| EVAL-02 | Phase 1 | Complete |
| EVAL-03 | Phase 1 | Complete |
| EVAL-04 | Phase 1 | Complete |
| EVAL-05 | Phase 1 | Complete |
| INIT-01 | Phase 2 | Pending |
| INIT-02 | Phase 2 | Pending |
| INIT-03 | Phase 2 | Pending |
| INIT-04 | Phase 2 | Pending |
| INIT-05 | Phase 2 | Pending |
| INIT-06 | Phase 2 | Pending |
| INIT-07 | Phase 2 | Pending |
| INIT-08 | Phase 2 | Pending |
| PALT-01 | Phase 2 | Pending |
| PALT-02 | Phase 2 | Pending |
| PALT-03 | Phase 2 | Pending |
| BRND-01 | Phase 2 | Pending |
| BRND-02 | Phase 2 | Pending |
| BRND-03 | Phase 2 | Pending |
| BRND-04 | Phase 2 | Pending |
| BRND-05 | Phase 2 | Pending |
| BRND-06 | Phase 2 | Pending |
| DEMO-01 | Phase 2 | Pending |
| DEMO-02 | Phase 2 | Pending |
| CREV-01 | Phase 3 | Pending |
| CREV-02 | Phase 3 | Pending |
| CREV-03 | Phase 3 | Pending |
| REL-01 | Phase 3 | Pending |
| REL-02 | Phase 3 | Pending |
| REL-03 | Phase 3 | Pending |
| REL-04 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 46 total
- Mapped to phases: 46
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-28*
*Last updated: 2026-03-29 after swapping consensus-validation for multi-model-code-review*
