# Phase 1: Scaffold + Port + Evals - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Port the existing design-review plugin (22 files at ~/.claude/plugins/design-review/) into a proper GitHub repo structure. Add reproducible eval harness and portfolio-grade documentation (ARCHITECTURE.md, CHANGELOG.md). The plugin must be installable from GitHub and produce the same quality reviews as the local version.

</domain>

<decisions>
## Implementation Decisions

### Plugin Structure
- **D-01:** Use standard `.claude-plugin/` directory with `plugin.json` manifest. Follow official Anthropic plugin conventions exactly.
- **D-02:** Preserve source directory structure: `commands/`, `config/`, `references/`, `hooks/`, `scripts/`. Do not reorganize — the current structure is already clean.
- **D-03:** Add `skills/design-review/SKILL.md` as a skill file (separate from commands). The existing monolithic SKILL.md should be evaluated for decomposition into agents during port.

### Port Strategy
- **D-04:** Copy files preserving structure, then grep-audit ALL files for hardcoded paths (`~/.claude`, `/Users/`, absolute paths). Replace with `${CLAUDE_PLUGIN_ROOT}` variable.
- **D-05:** Preserve the 3-tier degradation system as-is: Tier 1 (Claude + Gemini + Haiku), Tier 2 (Claude-only), Tier 3 (code analysis only). Do not simplify.
- **D-06:** The Gemini CLI dependency is acceptable — it's already handled by graceful degradation. Don't remove it, don't make it harder to use.
- **D-07:** Quick mode (`--quick`, 4 specialists) must work after port. Include in smoke test.

### Eval Harness
- **D-08:** Two eval layers: (1) structural validation — plugin.json valid, frontmatter correct, files in right places; (2) quality evals — range-based assertions on actual review output against bundled test fixtures.
- **D-09:** Use range-based assertions for quality evals (e.g., "score between 2.0 and 4.0"), NOT exact scores. AI evals are non-deterministic.
- **D-10:** Bundle test fixtures in the repo (HTML snippets or minimal pages). Evals must run on a clean clone without external dependencies.
- **D-11:** `run-evals.sh` is the single entry point for all evals. Exit 0 = all pass, exit 1 = failures.

### Documentation
- **D-12:** ARCHITECTURE.md is portfolio-grade: explain specialist roles (8 of them), boss synthesizer pattern, weighted scoring algorithm, degradation tiers, and WHY each decision was made. This is the CV document.
- **D-13:** CHANGELOG.md must show the failure story: v1 single-agent scored 40%, progression through iterations, v4 multi-agent achieved 100%. Transparency IS the differentiator.
- **D-14:** README.md includes install command, demo GIF placeholder (actual GIF is Phase 2), usage examples, and architecture overview.
- **D-15:** CLAUDE.md documents all available commands with usage for plugin users.

### Claude's Discretion
- Plugin name in `plugin.json` — Claude decides the exact naming/metadata
- Internal file organization within `references/` — preserve or reorganize as makes sense
- README structure and tone — professional but not corporate
- Eval assertion count and specific thresholds — whatever proves quality convincingly

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source Plugin (port source)
- `~/.claude/plugins/design-review/` — All 22 files. This is the source of truth for the port.
- `~/.claude/plugins/design-review/commands/design-review.md` — Core review command with specialist orchestration
- `~/.claude/plugins/design-review/commands/design.md` — Orchestrator/router command
- `~/.claude/plugins/design-review/config/scoring.json` — Scoring weights and thresholds
- `~/.claude/plugins/design-review/config/anti-slop.json` — AI pattern detection rules
- `~/.claude/plugins/design-review/hooks/hooks.json` — Hook definitions

### Project Context
- `.context/plan.md` — 3-model consensus strategy and key decisions
- `.context/intent.md` — What SpSk is and who Felipe is
- `.context/design-review-status.md` — Plugin v1.0.0 status and benchmark results

### Research
- `.planning/research/STACK.md` — Plugin format, file structure, distribution
- `.planning/research/ARCHITECTURE.md` — Component boundaries and build order
- `.planning/research/PITFALLS.md` — Critical risks (hardcoded paths, eval portability, token budgets)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Source plugin has 22 working files — this is a port, not a build from scratch
- 4 commands (design, design-review, design-improve, design-validate) already tested and working
- 4 config files (scoring.json, anti-slop.json, style-presets.json, design-system.example.json) ready to copy
- 8 reference files covering typography, color, layout, icons, motion, intent, visual rules, harness
- 1 hook (suggest-review.sh) with hooks.json
- CHANGELOG.md and README.md already exist (need adaptation for SpSk context)
- VERSION file with semver

### Established Patterns
- Commands use YAML frontmatter for Claude Code integration
- Config is JSON-based, separate from command logic
- References are markdown knowledge files loaded by specialists
- Degradation is built into the review flow (check for Gemini, fall back gracefully)

### Integration Points
- Plugin will be installed at `~/.claude/plugins/spsk/` (or whatever name)
- Commands register via `.claude-plugin/plugin.json`
- Hooks fire on PostToolUse events
- References are loaded by `@` syntax in skill/command files

</code_context>

<specifics>
## Specific Ideas

- The "40% to 100%" story is the headline — every doc should reinforce this narrative
- ARCHITECTURE.md should be readable by a hiring manager, not just developers
- The eval harness should be demo-able: `git clone && ./run-evals.sh` with clear output
- Don't over-polish at this stage — Phase 2 handles branding. Phase 1 is about correctness.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-scaffold-port-evals*
*Context gathered: 2026-03-28*
