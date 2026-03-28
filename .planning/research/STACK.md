# Technology Stack

**Project:** SpSk (Simple Skill) -- Claude Code Plugin Showcase
**Researched:** 2026-03-28
**Overall Confidence:** HIGH (based on direct inspection of 20+ installed plugins and official plugin-dev reference)

## Recommended Stack

### Core: Claude Code Plugin Architecture

SpSk is not a web app or CLI tool. It is a **Claude Code plugin** -- a structured directory of markdown files, shell scripts, and JSON configs that Claude Code discovers and activates at session start. There is no build step, no runtime, no package manager dependency. The "stack" is the plugin file format itself.

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

```
spsk/
+-- .claude-plugin/
|   +-- plugin.json              # Plugin manifest (required)
+-- CLAUDE.md                    # Plugin context for Claude Code
+-- README.md                    # GitHub showcase (humans read this)
+-- LICENSE                      # MIT
+-- VERSION                      # "1.0.0"
+-- CHANGELOG.md                 # What worked, what didn't
+-- ARCHITECTURE.md              # Multi-agent design docs (portfolio piece)
|
+-- commands/                    # Slash commands
|   +-- design.md                # /design -- orchestrator/router
|   +-- design-review.md         # /design-review -- 8-specialist review
|   +-- design-improve.md        # /design-improve -- iterative loop
|   +-- design-validate.md       # /design-validate -- functional testing
|
+-- skills/
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
+-- config/                      # Data-driven configuration
|   +-- scoring.json             # Dimension weights, thresholds
|   +-- anti-slop.json           # Banned AI patterns
|   +-- style-presets.json       # 5 built-in presets
|   +-- design-system.example.json  # Template for user customization
|
+-- hooks/
|   +-- hooks.json               # Hook definitions
|   +-- scripts/
|       +-- suggest-review.sh    # PostToolUse: suggest after 3+ frontend edits
|
+-- scripts/                     # Shared utilities (if needed)
|   +-- (minimal)
|
+-- evals/                       # Evaluation harness (crown jewel)
    +-- run-evals.sh             # Reproducible benchmark runner
    +-- evals.json               # Assertion definitions (19+ assertions)
    +-- calibration-template.md  # Human calibration guide
    +-- results/                 # Benchmark results (committed)
        +-- v1.0.0-results.json
```

### Plugin Manifest (`plugin.json`)

```json
{
  "name": "spsk",
  "version": "1.0.0",
  "description": "Polished AI agent skills for Claude Code. Design-review: 8 specialists, weighted scoring, anti-slop detection.",
  "author": {
    "name": "Felipe Machado",
    "url": "https://github.com/felipemachado"
  },
  "homepage": "https://github.com/felipemachado/spsk",
  "repository": "https://github.com/felipemachado/spsk",
  "license": "MIT",
  "keywords": [
    "design-review",
    "multi-agent",
    "ui-quality",
    "frontend",
    "code-review",
    "design-system",
    "accessibility"
  ]
}
```

**Why this manifest shape:** Matches the "Recommended Plugin" pattern from Anthropic's official plugin-dev reference. Includes all fields the marketplace displays. `name` is kebab-case (required by validation regex `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`). `keywords` aid discoverability in `/plugin > Discover`.

### Command Frontmatter Reference

Every command `.md` file supports YAML frontmatter with these fields:

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

**Why plugin registry over npm:** Claude Code plugins are markdown + JSON + shell. There is no JavaScript to bundle, no dependencies to resolve, no build step. npm adds complexity without value. The plugin registry is purpose-built for this format.

### Evaluation Harness

| Component | Format | Purpose |
|-----------|--------|---------|
| `run-evals.sh` | Bash | Orchestrates eval runs: starts dev server, runs review, checks assertions |
| `evals.json` | JSON | 19+ assertions across 3+ test cases (admin panel, landing page, emotional page) |
| `calibration-template.md` | Markdown | Guide for humans to validate scoring weights against their own judgment |
| `results/` | JSON | Committed benchmark results for each version |

**Why evals are first-class:** From the 3-model consensus: "Evals are the crown jewel." The delta between v1 single-agent (40% pass rate) and v4 multi-agent (100% pass rate) IS the portfolio story. Reproducible benchmarks prove quality claims.

### Branded Output System

No external library needed. Branded output is implemented entirely in the command markdown files using Unicode characters. This is a design pattern, not a technology dependency.

| Element | Pattern | Example |
|---------|---------|---------|
| Stage banner | Full-width line + prefix | ` SpSk > REVIEWING` between rule lines |
| Result box | Double-line Unicode borders | Score display with dimension breakdown |
| Progress bars | Block characters | `|||||||| ` 8.0/10 |
| Status symbols | Unicode vocabulary | Pass, fail, in-progress, pending, auto, warning |
| Signature line | Compact metadata | ` SpSk  design-review  v1.0.0  ---  8 specialists  ·  tier 1` |

**Why no templating engine:** The output is rendered by Claude itself interpreting the command markdown. There is no terminal renderer to template. Consistency comes from documenting the format clearly in the command files.

### Testing Approach

| Level | What | How |
|-------|------|-----|
| **Structure validation** | YAML frontmatter, file locations, plugin.json | `scripts/validate-plugin.sh` (bash, <50 lines) |
| **Eval assertions** | Review scores match expected ranges | `evals/run-evals.sh` -- runs actual reviews, checks 19+ assertions |
| **Manual smoke test** | Commands appear in `/help`, execute without errors | Documented test matrix in evals/calibration-template.md |
| **CI validation** | Frontmatter syntax, no TODOs, structure intact | GitHub Actions workflow (`.github/workflows/validate.yml`) |

**Why no Jest/Vitest:** There is no JavaScript to unit test. The "application" is markdown files that Claude interprets. Testing means running actual Claude Code reviews and checking outputs. The eval harness (`run-evals.sh`) is the test framework for this domain.

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

```yaml
# .github/workflows/validate.yml
name: Validate Plugin
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate plugin.json
        run: |
          jq empty .claude-plugin/plugin.json
          jq -e '.name' .claude-plugin/plugin.json
      - name: Validate command frontmatter
        run: |
          for cmd in commands/*.md; do
            MARKERS=$(head -n 50 "$cmd" | grep -c "^---")
            if [ "$MARKERS" -ne 0 ] && [ "$MARKERS" -ne 2 ]; then
              echo "ERROR: Invalid frontmatter in $cmd"
              exit 1
            fi
          done
      - name: Validate hooks.json
        run: jq empty hooks/hooks.json
      - name: Validate config JSON
        run: |
          for f in config/*.json; do
            jq empty "$f"
          done
      - name: Check VERSION
        run: |
          VERSION=$(cat VERSION)
          echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'
```

## Variable References

Claude Code provides `${CLAUDE_PLUGIN_ROOT}` for path references within plugin scripts and hook commands. This resolves to the plugin's installed location regardless of where it was cloned or installed.

```bash
# In hooks.json
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/suggest-review.sh"

# In shell scripts
source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"
```

**Why this matters:** Users install plugins to `~/.claude/plugins/cache/<marketplace>/<name>/<version>/`. Hardcoded paths break on every machine. `${CLAUDE_PLUGIN_ROOT}` is the only portable path reference.

## Sources

- **HIGH confidence:** Direct file inspection of `~/.claude/plugins/` -- 20+ installed plugins examined
- **HIGH confidence:** `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/` -- Anthropic's official plugin development reference (manifest-reference.md, component-patterns.md, frontmatter-reference.md, testing-strategies.md, marketplace-considerations.md)
- **HIGH confidence:** `~/.claude/plugins/marketplaces/claude-plugins-official/README.md` -- Official marketplace structure and install syntax
- **HIGH confidence:** `~/.claude/plugins/design-review/` -- Source plugin to port (22 files, v1.0.0)
- **MEDIUM confidence:** `.context/gsd-research.md` -- GSD patterns analysis (verified against actual GSD plugin files)
