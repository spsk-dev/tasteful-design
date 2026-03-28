# SpSk — Simple Skill

GitHub showcase of polished AI skills for Claude Code. Design-review plugin is the flagship.

## Context

Read these files in order before starting any work:
1. `.context/plan.md` — Full 3-phase plan with 3-model strategy consensus
2. `.context/intent.md` — What SpSk is, who Felipe is, what this represents
3. `.context/gsd-research.md` — GSD formatting patterns to borrow for branded output
4. `.context/design-review-status.md` — Plugin v1.0.0 status (8.6/10 consensus, 22 files)

## Source Plugin

The design-review plugin to port lives at `~/.claude/plugins/design-review/` (22 files, v1.0.0).

## 3-Phase Plan (from consensus)

**Phase 1:** Repo scaffold + design-review port + evals as first-class + ARCHITECTURE.md
**Phase 2:** Init wizard + palette engine + branded output + demo GIF
**Phase 3:** 2nd skill (consensus-validation) + case studies + v1.0.0 release

## Branding

- Signature line: ` SpSk  design-review  v1.2.0  ───  8 specialists  ·  tier 1`
- Unicode boxes for checkpoints/results
- Symbol vocabulary: ✓ ✗ ◆ ○ ⚡ ⚠
- Progress bars: ████░░ for scores
- Footer with repo link on every output
- NOT big ASCII art — clean, compact, professional

## Key Decisions

- GSD to build it, standalone after shipping
- Design-review as flagship, consensus-validation as 2nd skill
- Claude Code plugin registry as primary distribution
- Evals are the crown jewel — make reproducible with run-evals.sh
- Show what DIDN'T work in CHANGELOG (v1 single-agent scored 40%)
- 30-second demo GIF in README
- Init wizard: 5 questions, under 2 minutes to first value

<!-- GSD:project-start source:PROJECT.md -->
## Project

**SpSk (Simple Skill)**

A GitHub portfolio project that publishes Felipe Machado's most polished AI agent skills as open-source Claude Code plugins. Design-review is the flagship skill (8 specialist agents, 10 scored dimensions, 8.6/10 consensus score). The repo serves as a professional showcase demonstrating deep understanding of AI agent architectures, harnesses, and their practical value for developers.

**Core Value:** The published skills must be immediately useful to other developers AND demonstrate architectural sophistication — the tool is the proof, the architecture is the CV.

### Constraints

- **Distribution**: Claude Code plugin registry as primary (`claude /install-plugin design-review@felipemachado/spsk`) + install.sh for manual
- **Branding**: Clean and compact, NOT big ASCII art. Signature line format: ` SpSk  design-review  v1.2.0  ---  8 specialists  ·  tier 1`
- **Init wizard**: Exactly 5 questions with opinionated defaults (page type, vibe preset, light/dark, brand colors, font preference)
- **Quality bar**: Must show what DIDN'T work in CHANGELOG (v1 single-agent scored 40%) — transparency builds credibility
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core: Claude Code Plugin Architecture
| Component | Format | Purpose | Why |
|-----------|--------|---------|-----|
| `.claude-plugin/plugin.json` | JSON | Plugin manifest (identity, metadata, paths) | Required by Claude Code for plugin recognition. Validated on load. |
| `commands/*.md` | Markdown + YAML frontmatter | Slash commands (`/design`, `/design-review`, etc.) | Standard plugin entry point. Users invoke via `/command`. |
| `skills/*/SKILL.md` | Markdown + YAML frontmatter | Background knowledge loaded contextually | Auto-activated when task context matches skill description. |
| `agents/*.md` | Markdown + YAML frontmatter | Specialist agent definitions | For multi-agent orchestration (design-review's 8 specialists). |
| `hooks/hooks.json` | JSON | Lifecycle event handlers | PostToolUse suggest-review hook, potential SessionStart hooks. |
| `scripts/*.sh` | Bash | Hook implementations, utility scripts | Shell scripts invoked by hooks or commands via `${CLAUDE_PLUGIN_ROOT}`. |
| `config/*.json` | JSON | Scoring weights, anti-slop patterns, style presets | Data-driven configuration separate from logic. |
| `references/*.md` | Markdown | Domain knowledge (typography, color, layout rules) | Loaded by specialists during review. Keeps SKILL.md focused. |
| `CLAUDE.md` | Markdown | Plugin-level context for Claude Code | Auto-read by Claude Code when plugin is active. Documents commands and usage. |
| `VERSION` | Plain text | Semver version string | Simple, no build tooling needed. Read by hooks for staleness detection. |
| `CHANGELOG.md` | Markdown | Version history with what changed (and what failed) | Portfolio differentiator: shows v1 scored 40%, multi-agent scored 8.6/10. |
### File Structure (Recommended)
|   +-- plugin.json              # Plugin manifest (required)
|
|   +-- design.md                # /design -- orchestrator/router
|   +-- design-review.md         # /design-review -- 8-specialist review
|   +-- design-improve.md        # /design-improve -- iterative loop
|   +-- design-validate.md       # /design-validate -- functional testing
|
|   +-- design-review/           # Skill: design review knowledge
|       +-- SKILL.md             # When/how to use design review
|       +-- references/          # Domain knowledge
|           +-- typography.md
|           +-- color.md
|           +-- layout.md
|           +-- icons.md
|           +-- motion.md
|           +-- intent.md
|           +-- visual-design-rules.md
|
|   +-- scoring.json             # Dimension weights, thresholds
|   +-- anti-slop.json           # Banned AI patterns
|   +-- style-presets.json       # 5 built-in presets
|   +-- design-system.example.json  # Template for user customization
|
|   +-- hooks.json               # Hook definitions
|   +-- scripts/
|       +-- suggest-review.sh    # PostToolUse: suggest after 3+ frontend edits
|
|   +-- (minimal)
|
### Plugin Manifest (`plugin.json`)
### Command Frontmatter Reference
| Field | Type | Purpose | SpSk Usage |
|-------|------|---------|------------|
| `description` | String (<60 chars) | Shows in `/help` output | All 4 commands |
| `allowed-tools` | String/Array | Restrict tool access | `Bash(gemini *)`, `Bash(npx *)` etc. for /design |
| `model` | `sonnet`/`opus`/`haiku` | Model selection per command | Default (inherit) for most; potentially `opus` for boss synthesizer |
| `argument-hint` | String | Document expected args | `[page-url] [--quick] [--ref url]` |
| `disable-model-invocation` | Boolean | Prevent programmatic invocation | Not needed (commands should be invocable by other commands) |
| `hide-from-slash-command-tool` | String | Hide from autocomplete | Potentially for internal sub-commands |
### Distribution
| Method | Command | When |
|--------|---------|------|
| **Plugin registry** (primary) | `claude /install-plugin spsk@felipemachado/spsk` | Standard Claude Code install. Requires marketplace listing via [clau.de/plugin-directory-submission](https://clau.de/plugin-directory-submission). |
| **Direct GitHub** | `claude /install-plugin spsk@github:felipemachado/spsk` | Works without marketplace listing. Users need to trust the source. |
| **Manual clone** | `git clone` + symlink to `~/.claude/plugins/spsk` | Fallback for users who want to inspect before installing. |
### Evaluation Harness
| Component | Format | Purpose |
|-----------|--------|---------|
| `run-evals.sh` | Bash | Orchestrates eval runs: starts dev server, runs review, checks assertions |
| `evals.json` | JSON | 19+ assertions across 3+ test cases (admin panel, landing page, emotional page) |
| `calibration-template.md` | Markdown | Guide for humans to validate scoring weights against their own judgment |
| `results/` | JSON | Committed benchmark results for each version |
### Branded Output System
| Element | Pattern | Example |
|---------|---------|---------|
| Stage banner | Full-width line + prefix | ` SpSk > REVIEWING` between rule lines |
| Result box | Double-line Unicode borders | Score display with dimension breakdown |
| Progress bars | Block characters | `|||||||| ` 8.0/10 |
| Status symbols | Unicode vocabulary | Pass, fail, in-progress, pending, auto, warning |
| Signature line | Compact metadata | ` SpSk  design-review  v1.0.0  ---  8 specialists  ·  tier 1` |
### Testing Approach
| Level | What | How |
|-------|------|-----|
| **Structure validation** | YAML frontmatter, file locations, plugin.json | `scripts/validate-plugin.sh` (bash, <50 lines) |
| **Eval assertions** | Review scores match expected ranges | `evals/run-evals.sh` -- runs actual reviews, checks 19+ assertions |
| **Manual smoke test** | Commands appear in `/help`, execute without errors | Documented test matrix in evals/calibration-template.md |
| **CI validation** | Frontmatter syntax, no TODOs, structure intact | GitHub Actions workflow (`.github/workflows/validate.yml`) |
## Alternatives Considered
| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Distribution | Plugin registry | npm package | No JS to bundle. npm adds package.json, node_modules, build step for zero benefit. |
| Config format | JSON | YAML | Claude Code plugin system uses JSON natively (plugin.json, hooks.json, .mcp.json). Consistency. |
| Branding | Inline Unicode in command .md | Template engine | No runtime to execute templates. Claude reads markdown and follows instructions. |
| Testing | Bash eval harness | Jest/Vitest | No JS code. Eval harness tests actual product output, not internal functions. |
| CLI tooling | None (v1) | `spsk-tools.cjs` | Over-engineering. Design-review has no state management needs. Revisit for skill #2. |
| Build system | None | Rollup/esbuild | Nothing to compile. Plugin is consumed as source files. |
| Type checking | None | TypeScript | No JavaScript in the plugin. |
## What NOT to Build
| Anti-Pattern | Why Avoid | What to Do Instead |
|-------------|-----------|-------------------|
| npm package with package.json | Signals "this is a JS project" when it is not. | plugin.json as the only manifest. |
| JavaScript CLI wrapper | Adds runtime dependency for no reason. | commands/*.md as the interface. |
| Database for review history | Over-scopes v1. Reviews are point-in-time. | Markdown result files in .design-reviews/. |
| Web dashboard | Not a web app. Terminal output IS the interface. | Branded Unicode output. |
| Monorepo tooling | Single plugin, nothing to coordinate. | Flat directory structure. |
| Docker/container setup | No runtime to containerize. | Plugin installs by copying files. |
| CI/CD deploy pipeline | Plugin consumed from GitHub directly. | GitHub Actions for validation only. |
| Framework for third-party skills | Premature. Emerges from building 2nd/3rd skills. | Build two skills first, extract later. |
## GitHub Actions (Validation Only)
# .github/workflows/validate.yml
## Variable References
# In hooks.json
# In shell scripts
## Sources
- **HIGH confidence:** Direct file inspection of `~/.claude/plugins/` -- 20+ installed plugins examined
- **HIGH confidence:** `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/` -- Anthropic's official plugin development reference (manifest-reference.md, component-patterns.md, frontmatter-reference.md, testing-strategies.md, marketplace-considerations.md)
- **HIGH confidence:** `~/.claude/plugins/marketplaces/claude-plugins-official/README.md` -- Official marketplace structure and install syntax
- **HIGH confidence:** `~/.claude/plugins/design-review/` -- Source plugin to port (22 files, v1.0.0)
- **MEDIUM confidence:** `.context/gsd-research.md` -- GSD patterns analysis (verified against actual GSD plugin files)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
