# Project Research Summary

**Project:** SpSk (Simple Skill) -- Claude Code Plugin Showcase
**Domain:** Claude Code plugin / AI agent skill / portfolio repo
**Researched:** 2026-03-28
**Confidence:** HIGH

## Executive Summary

SpSk is a Claude Code plugin that packages Felipe Machado's design-review skill as an open-source portfolio piece on GitHub. The entire "stack" is the Claude Code plugin format itself: markdown command files with YAML frontmatter, JSON configuration, shell scripts for hooks, and a `.claude-plugin/plugin.json` manifest. There is no JavaScript, no build step, no npm dependencies. The plugin is consumed as source files directly by Claude Code. This makes SpSk fundamentally different from typical software projects -- the "codebase" is prompt engineering in markdown, and the "test suite" is an eval harness that runs actual Claude Code reviews and checks assertions against outputs.

The design-review skill already exists and is validated at v1.0.0 (22 files, 8.6/10 consensus score from 3 independent AI models). The core architecture is an 8-specialist multi-agent pattern with a boss synthesizer, using multiple models (Claude Sonnet for code analysis, Gemini CLI for visual perception, Haiku for lightweight tasks). It features weighted scoring, degradation tiers for missing dependencies, and anti-slop detection. Phase 1 is primarily a porting exercise -- moving files from Felipe's local plugin directory to a proper GitHub repo with portable paths, plus building the reproducible eval harness that proves quality claims.

The key risks are mechanical, not architectural: hardcoded paths from the source plugin that will break on other machines, Gemini CLI as a hard dependency without graceful fallback (mitigation already built as degradation tiers -- must be ported faithfully), and eval fixtures that only work in Felipe's local environment. The differentiator is not technology but quality evidence: reproducible evals showing v1 single-agent scored 40% and v4 multi-agent scored 100%, transparent failure history in the CHANGELOG, and an ARCHITECTURE.md that documents the multi-agent design as a portfolio artifact. The tool is the proof; the architecture is the CV.

## Key Findings

### Recommended Stack

SpSk has no traditional technology stack. The plugin format IS the stack. All components are plain text files that Claude Code discovers and interprets at session start.

**Core technologies:**
- **Claude Code plugin format**: Markdown commands + JSON config + bash scripts -- the only "framework" needed. Well-documented via Anthropic's official plugin-dev reference.
- **Plugin registry**: Primary distribution via `claude /install-plugin spsk@felipemachado/spsk`. No npm, no build, no bundling.
- **Multi-model execution**: Gemini CLI for Color/Layout specialists (visual perception strength), Claude Sonnet for code analysis depth, Haiku for lightweight classification.
- **Bash eval harness**: `run-evals.sh` with 19+ assertions across 3 test cases. No Jest/Vitest -- there is no JavaScript to unit test.

**What NOT to build:** npm package, JavaScript CLI wrapper, web dashboard, database, Docker setup, monorepo tooling, framework for third-party skills. See STACK.md for full anti-pattern list.

### Expected Features

**Must have (table stakes):**
- `/design-review` -- 8 specialists, weighted scoring, SHIP/BLOCK verdict (already built, needs port)
- `/design` orchestrator -- single entry point routing to sub-commands (already built)
- `/design-improve` -- iterative build-review-fix loop (already built)
- `/design-validate` -- functional testing via Playwright MCP (already built)
- Scoring with per-page-type thresholds, anti-slop detection, quick mode, style presets
- CLAUDE.md, README.md, LICENSE (MIT)

**Should have (differentiators):**
- Reproducible eval harness with committed benchmark results (crown jewel)
- Transparent failure history in CHANGELOG (v1: 40%, v4: 100%)
- ARCHITECTURE.md as a portfolio-grade design document
- Branded terminal output with consistent Unicode vocabulary
- Degradation tiers with visible reporting (Tier 1/2/3)
- Specialist disagreement visibility (meta-cognition)

**Defer (v2+):**
- `/design init` wizard + palette engine (Phase 2)
- Demo GIF for README (Phase 2, after branding)
- `consensus-validation` second skill (Phase 3)
- Case studies with real projects (Phase 3)
- Marketplace submission (Phase 3)

### Architecture Approach

The architecture follows a multi-agent specialist pattern with boss synthesizer -- the same pattern Anthropic uses in their code-review plugin, applied to visual design assessment. User invokes `/design-review`, screenshots are captured (Phase 0), Haiku classifies the page type (Phase 1), 8 specialists run in parallel with domain-specific references (Phase 2), and the boss synthesizer resolves disagreements and renders a weighted verdict (Phase 3). If BLOCK, targeted re-review runs only failing dimensions (Phase 4).

**Major components:**
1. **Commands** (`commands/*.md`) -- 4 slash commands that ARE the product. The markdown IS the prompt. Quality of instructions directly determines quality of output.
2. **Skills** (`skills/design-review/`) -- SKILL.md with contextual trigger description + 7 reference files (typography, color, layout, icons, motion, intent, visual rules) loaded by specialists on demand.
3. **Config** (`config/*.json`) -- Scoring weights, thresholds, anti-slop patterns, style presets. Data-driven, tunable without editing prompts.
4. **Hooks** (`hooks/`) -- Single PostToolUse hook that suggests `/design-review` after 3+ frontend file edits. Minimal by design.
5. **Evals** (`evals/`) -- Reproducible benchmark runner with assertions, calibration guide, and committed results.

**Key patterns:** Plugin discovery via convention (standard directory names), `${CLAUDE_PLUGIN_ROOT}` for all path references, config as data not code, flat directory structure (no nesting).

### Critical Pitfalls

1. **Hardcoded paths from source plugin** -- The source at `~/.claude/plugins/design-review/` contains absolute paths that break on any other machine. Prevention: grep -r audit for `/Users/` and `~/.claude` after porting, replace all with `${CLAUDE_PLUGIN_ROOT}`.

2. **Gemini CLI dependency without fallback** -- Color and Layout specialists require Gemini. Prevention: port the existing 3-tier degradation system faithfully. Users must see which tier ran.

3. **Non-portable eval harness** -- `run-evals.sh` may reference local dev servers and fixtures. Prevention: bundle static HTML test fixtures in the repo, provide `--self-contained` mode.

4. **Plugin name collision** -- If old `design-review` plugin and new `spsk` plugin are both installed, command names collide. Prevention: use `name: "spsk"` in plugin.json, document uninstall step for the old plugin.

5. **Gemini reference file workspace restriction** -- Gemini CLI can only read files in workspace root. Prevention: port the reference-file-copy pattern that copies `.color-reference.md` and `.layout-reference.md` to workspace root before Gemini invocations.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Scaffold + Port + Evals
**Rationale:** Phase 1 is a mechanical port of 22 existing files into a proper plugin structure, plus creation of the eval harness. Low creative risk, high value. Gets the plugin installable from GitHub immediately. Everything else depends on a working plugin scaffold.
**Delivers:** A fully functional Claude Code plugin installable via `claude /install-plugin`. Reproducible eval harness with committed benchmark results. ARCHITECTURE.md and CHANGELOG.md as portfolio artifacts.
**Addresses:** All table-stakes features (4 commands, config files, skill + references, hooks). Eval harness (differentiator). ARCHITECTURE.md (differentiator).
**Avoids:** Hardcoded paths (Pitfall 1), plugin name collision (Pitfall 4), Gemini reference copy omission (Pitfall 5), premature framework building (Pitfall 10).

### Phase 2: Init Wizard + Branding + Demo
**Rationale:** Polish that transforms a working tool into a portfolio piece. Init wizard provides first-run experience. Branded output provides visual identity. Demo GIF is the README hook that sells the tool without installing. This phase requires a working plugin from Phase 1 to test against.
**Delivers:** `/design init` wizard (5 questions, <2 minutes to first value), palette engine, branded Unicode output system, `.design/` harness improvements, 30-second demo GIF.
**Addresses:** Phase 2 features from FEATURES.md (init wizard, palette engine, branded output, demo GIF).
**Avoids:** Inconsistent Unicode output (Pitfall 11). Over-engineering the README (Pitfall 9).

### Phase 3: Second Skill + Release
**Rationale:** Proves SpSk is a platform (two skills) not a one-off. The `consensus-validation` skill validates that shared patterns emerge naturally from building a second skill rather than being pre-designed. Case studies with real projects provide measurable impact evidence. Marketplace submission is the final step after everything is validated.
**Delivers:** `consensus-validation` skill, case studies (before/after with real projects), v1.0.0 formal release, marketplace submission.
**Addresses:** Phase 3 features from FEATURES.md (second skill, case studies, release).
**Avoids:** Premature framework extraction (Pitfall 10), version drift (Pitfall 13).

### Phase Ordering Rationale

- Phase 1 must come first because all other phases depend on a working plugin scaffold. The eval harness must exist before any polish work so quality can be measured.
- Phase 2 before Phase 3 because branding patterns established in Phase 2 will inform the shared patterns extracted when building the second skill in Phase 3. If you build skill 2 before establishing branding, you retrofit twice.
- The dependency chain is clear: scaffold -> commands -> evals -> branding -> init wizard -> second skill -> release. Each phase builds on the previous.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** Palette engine needs design research (color theory, vibe-to-palette mapping). Init wizard UX needs thought on the 5 questions and opinionated defaults.
- **Phase 3:** `consensus-validation` is a new skill with no existing implementation. Needs its own research phase for multi-model consensus patterns, voting mechanisms, and disagreement resolution.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Port is mechanical. Plugin structure patterns are well-documented by Anthropic's plugin-dev reference. Eval harness is bash + JSON assertions. No unknowns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct inspection of 20+ installed plugins + Anthropic's official plugin-dev reference. Plugin format is mature and well-documented. |
| Features | HIGH | Source plugin already built and validated at v1.0.0 (22 files, 8.6/10 consensus). Feature list is known, not speculative. |
| Architecture | HIGH | Multi-agent pattern directly inspected from source. Component patterns verified against official plugin structure docs. |
| Pitfalls | HIGH | Derived from source plugin inspection, official marketplace guidelines, and known v1.0.0 limitations. Pitfalls are concrete, not hypothetical. |

**Overall confidence:** HIGH

### Gaps to Address

- **Marketplace submission process:** The exact flow via clau.de/plugin-directory-submission was not tested. May have requirements beyond plugin.json fields. Address during Phase 3 planning.
- **Eval portability:** How exactly to bundle test fixtures (static HTML pages) for eval runs on clean machines. Needs validation during Phase 1 implementation -- try a clean-directory clone test.
- **Palette engine design:** Color theory and vibe-to-palette mapping not researched. Phase 2 needs a research spike before implementation.
- **consensus-validation architecture:** New skill not yet designed. Phase 3 needs full research into multi-model consensus patterns, which is a different domain than design review.
- **GitHub username verification:** Project docs reference `felipemachado/spsk` but actual GitHub username needs verification before plugin.json and README are finalized.
- **Token budget documentation:** Full review costs ~200K+ tokens. Quick mode costs less but exact numbers are not documented. Phase 1 should measure and document expected token usage per review type.

## Sources

### Primary (HIGH confidence)
- Direct file inspection of `~/.claude/plugins/` -- 20+ installed plugins examined for patterns
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/` -- Anthropic's official plugin development reference (manifest, components, frontmatter, testing, marketplace)
- `~/.claude/plugins/design-review/` -- Source plugin to port (22 files, v1.0.0)
- `.context/plan.md` -- 3-model consensus strategy (Claude, Gemini, Codex agreed on approach)
- `.context/design-review-status.md` -- Feature list, specialist roster, benchmark results

### Secondary (MEDIUM confidence)
- `.context/gsd-research.md` -- GSD formatting patterns analysis (verified against actual GSD plugin files)
- `.context/intent.md` -- Project intent and portfolio positioning

---
*Research completed: 2026-03-28*
*Ready for roadmap: yes*
