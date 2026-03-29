# Phase 1: Scaffold + Port + Evals - Research

**Researched:** 2026-03-28
**Domain:** Claude Code plugin architecture, multi-agent design review, eval harness
**Confidence:** HIGH

## Summary

Phase 1 is a port operation, not a greenfield build. The source plugin exists at `~/.claude/plugins/design-review/` with 22 working files, 4 commands, 4 config files, 9 reference files, 1 hook, and supporting scripts. The primary technical challenge is making it portable (replacing hardcoded paths), structuring it as a proper `.claude-plugin/` package, and building a reproducible eval harness that proves the 40%-to-100% quality claim.

The "stack" is not a web stack -- it is the Claude Code plugin file format: markdown commands with YAML frontmatter, JSON config, bash scripts, and markdown reference files. There is no build step, no JavaScript, no package manager. The plugin manifest (`plugin.json`) and directory conventions are the entire architecture.

The eval harness is the highest-risk deliverable. It must run on a clean clone (`git clone && ./run-evals.sh`) and produce passing results. This requires bundled HTML fixtures (not references to local dev servers), range-based assertions (AI output is non-deterministic), and clear structural validation (JSON/YAML syntax, file existence, frontmatter correctness).

**Primary recommendation:** Port files preserving existing structure, grep-audit for hardcoded paths, build eval harness with two layers (structural validation via bash, quality evals via range assertions on bundled fixtures), write portfolio-grade ARCHITECTURE.md and transparent CHANGELOG.md.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use standard `.claude-plugin/` directory with `plugin.json` manifest. Follow official Anthropic plugin conventions exactly.
- **D-02:** Preserve source directory structure: `commands/`, `config/`, `references/`, `hooks/`, `scripts/`. Do not reorganize -- the current structure is already clean.
- **D-03:** Add `skills/design-review/SKILL.md` as a skill file (separate from commands). The existing monolithic SKILL.md should be evaluated for decomposition into agents during port.
- **D-04:** Copy files preserving structure, then grep-audit ALL files for hardcoded paths (`~/.claude`, `/Users/`, absolute paths). Replace with `${CLAUDE_PLUGIN_ROOT}` variable.
- **D-05:** Preserve the 3-tier degradation system as-is: Tier 1 (Claude + Gemini + Haiku), Tier 2 (Claude-only), Tier 3 (code analysis only). Do not simplify.
- **D-06:** The Gemini CLI dependency is acceptable -- it is already handled by graceful degradation. Don't remove it, don't make it harder to use.
- **D-07:** Quick mode (`--quick`, 4 specialists) must work after port. Include in smoke test.
- **D-08:** Two eval layers: (1) structural validation -- plugin.json valid, frontmatter correct, files in right places; (2) quality evals -- range-based assertions on actual review output against bundled test fixtures.
- **D-09:** Use range-based assertions for quality evals (e.g., "score between 2.0 and 4.0"), NOT exact scores. AI evals are non-deterministic.
- **D-10:** Bundle test fixtures in the repo (HTML snippets or minimal pages). Evals must run on a clean clone without external dependencies.
- **D-11:** `run-evals.sh` is the single entry point for all evals. Exit 0 = all pass, exit 1 = failures.
- **D-12:** ARCHITECTURE.md is portfolio-grade: explain specialist roles (8 of them), boss synthesizer pattern, weighted scoring algorithm, degradation tiers, and WHY each decision was made. This is the CV document.
- **D-13:** CHANGELOG.md must show the failure story: v1 single-agent scored 40%, progression through iterations, v4 multi-agent achieved 100%. Transparency IS the differentiator.
- **D-14:** README.md includes install command, demo GIF placeholder (actual GIF is Phase 2), usage examples, and architecture overview.
- **D-15:** CLAUDE.md documents all available commands with usage for plugin users.

### Claude's Discretion
- Plugin name in `plugin.json` -- Claude decides the exact naming/metadata
- Internal file organization within `references/` -- preserve or reorganize as makes sense
- README structure and tone -- professional but not corporate
- Eval assertion count and specific thresholds -- whatever proves quality convincingly

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCAF-01 | Plugin manifest (`.claude-plugin/plugin.json`) with correct metadata, version, description | Manifest format verified from official plugin-dev reference + 3 real plugin.json examples inspected |
| SCAF-02 | README.md with install command, demo GIF placeholder, architecture overview, usage guide | Source README.md exists (9.4KB), needs adaptation for SpSk context. Install syntax verified from marketplace docs. |
| SCAF-03 | CLAUDE.md with command documentation and usage instructions | Source plugin has no CLAUDE.md -- needs creation. Pattern: document all 4 commands, arguments, presets. |
| SCAF-04 | LICENSE (MIT) | Trivial -- standard MIT text |
| SCAF-05 | CHANGELOG.md with transparent failure history (v1 40%, v4 100%) | Source CHANGELOG.md exists with v1.0.0 entry. Needs expansion with failure narrative per D-13. |
| SCAF-06 | ARCHITECTURE.md documenting multi-agent design | New file. Architecture patterns fully documented in research/ARCHITECTURE.md. Specialist roster, scoring formula, degradation tiers all captured. |
| PORT-01 | `/design-review` command ported | Source: commands/design-review.md. Longest command file (~400+ lines). Uses `${CLAUDE_PLUGIN_ROOT}` already in some places. |
| PORT-02 | `/design` orchestrator ported | Source: commands/design.md. Routes to sub-commands. Uses `${CLAUDE_PLUGIN_ROOT}` for config reads. |
| PORT-03 | `/design-improve` iterative loop ported | Source: commands/design-improve.md. References `${CLAUDE_PLUGIN_ROOT}` for style-presets and anti-slop config. |
| PORT-04 | `/design-validate` functional tests ported | Source: commands/design-validate.md. Playwright MCP integration. |
| PORT-05 | Configuration files ported | Source: 4 JSON files in config/. No hardcoded paths found in config files. |
| PORT-06 | Skill file and references ported with `${CLAUDE_PLUGIN_ROOT}` paths | Source: 9 reference files in references/. Need restructure to skills/design-review/references/. |
| PORT-07 | Hooks ported | Source: hooks/hooks.json + scripts/suggest-review.sh. Already uses `${CLAUDE_PLUGIN_ROOT}`. |
| PORT-08 | All hardcoded paths replaced | Grep audit found 1 hardcoded path in README.md. Full audit needed post-copy. |
| PORT-09 | Degradation tiers working | Built into design-review.md command logic. Port preserves as-is per D-05. |
| PORT-10 | Quick mode working | Built into design-review.md. Quick formula uses /13 weights. |
| EVAL-01 | run-evals.sh executes all eval assertions | New file. Two-layer design per D-08. |
| EVAL-02 | Eval fixtures bundled in repo | New: HTML test pages for admin, landing, emotional page types. |
| EVAL-03 | Range-based assertions | Design pattern: `score >= 2.0 && score <= 4.0` style checks. |
| EVAL-04 | Eval results documented with benchmarks | Results committed to evals/results/. README references benchmark numbers. |
| EVAL-05 | Clean-machine install test passes | run-evals.sh structural layer must pass without Claude Code. Quality layer needs Claude Code session. |
</phase_requirements>

## Standard Stack

### Core: Claude Code Plugin Format

This is not a software project with dependencies. It is a structured directory of files consumed by Claude Code.

| Component | Format | Purpose | Why Standard |
|-----------|--------|---------|--------------|
| `.claude-plugin/plugin.json` | JSON | Plugin manifest | Required by Claude Code. Validated on load. Official spec at plugin-dev reference. |
| `commands/*.md` | Markdown + YAML frontmatter | Slash commands | Standard plugin entry point. 4 commands: design, design-review, design-improve, design-validate |
| `skills/design-review/SKILL.md` | Markdown + YAML frontmatter | Contextual knowledge | Auto-activated when task matches description |
| `config/*.json` | JSON | Scoring, anti-slop, presets | Data-driven config separate from prompts |
| `hooks/hooks.json` | JSON | Lifecycle events | PostToolUse hook for suggest-review |
| `scripts/*.sh` | Bash | Hook implementations | suggest-review.sh (count frontend edits) |
| `references/*.md` | Markdown | Domain knowledge | 9 files: typography, color, layout, icons, motion, intent, visual-design-rules, harness, workflows |
| `evals/run-evals.sh` | Bash | Eval harness | Single entry point for all validation |

### Supporting Tools (for eval harness only)

| Tool | Purpose | Required? |
|------|---------|-----------|
| `jq` | JSON validation in structural evals | Yes (available: jq-1.7.1) |
| `bash` | Script execution | Yes (standard) |
| `grep` | Hardcoded path detection, frontmatter validation | Yes (standard) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bash eval harness | Jest/Vitest | No JavaScript to test. Evals test product output, not functions. |
| JSON config | YAML config | Claude Code uses JSON natively (plugin.json, hooks.json). Consistency wins. |
| npm package | Plugin registry | No JS to bundle. npm adds complexity for zero value. |

**No installation command.** There are no npm/pip/cargo dependencies. The plugin is plain files.

## Architecture Patterns

### Recommended Project Structure

```
spsk/
+-- .claude-plugin/
|   +-- plugin.json              # Plugin manifest (required)
+-- CLAUDE.md                    # Plugin context for Claude Code users
+-- README.md                    # GitHub showcase (humans)
+-- LICENSE                      # MIT
+-- VERSION                      # "1.0.0"
+-- CHANGELOG.md                 # Failure story + version history
+-- ARCHITECTURE.md              # Portfolio-grade design docs
+-- .gitignore                   # Exclude generated files
|
+-- commands/                    # Slash commands (4 files)
|   +-- design.md                # /design -- orchestrator/router
|   +-- design-review.md         # /design-review -- 8-specialist review
|   +-- design-improve.md        # /design-improve -- iterative loop
|   +-- design-validate.md       # /design-validate -- functional testing
|
+-- skills/
|   +-- design-review/           # Skill directory
|       +-- SKILL.md             # Contextual knowledge trigger
|       +-- references/          # Domain knowledge (7 files)
|           +-- typography.md
|           +-- color.md
|           +-- layout.md
|           +-- icons.md
|           +-- motion.md
|           +-- intent.md
|           +-- visual-design-rules.md
|
+-- config/                      # Data-driven configuration (4 files)
|   +-- scoring.json             # Dimension weights + thresholds
|   +-- anti-slop.json           # Banned AI patterns
|   +-- style-presets.json       # 5 built-in presets
|   +-- design-system.example.json  # Template for customization
|
+-- hooks/
|   +-- hooks.json               # Hook definitions
|   +-- scripts/
|       +-- suggest-review.sh    # PostToolUse: suggest after 3+ frontend edits
|
+-- evals/                       # Evaluation harness
|   +-- run-evals.sh             # Single entry point (exit 0/1)
|   +-- fixtures/                # Bundled test HTML pages
|   |   +-- admin-panel.html
|   |   +-- landing-page.html
|   |   +-- emotional-page.html
|   +-- assertions.json          # Range-based eval definitions
|   +-- results/                 # Committed benchmark results
|       +-- v1.0.0-results.json
```

### Pattern 1: Plugin Discovery via Convention

**What:** Claude Code scans standard directories at startup. `.claude-plugin/plugin.json` must exist or the plugin is invisible. Default directories (`commands/`, `skills/`, `hooks/`) are scanned automatically.
**When to use:** Always -- this is how the plugin loads.
**Key detail:** Do NOT nest commands in subdirectories like `src/commands/`. Use `commands/` directly. Custom paths in plugin.json supplement defaults but add unnecessary configuration.

### Pattern 2: Command as Prompt, Not Code

**What:** Each `.md` file in `commands/` IS the implementation. Claude reads the markdown and executes the workflow described. There is no handler function.
**When to use:** All 4 commands.
**Key detail:** Quality of the command markdown directly determines quality of the tool. The `.md` files are the codebase.

### Pattern 3: ${CLAUDE_PLUGIN_ROOT} for Portability

**What:** All path references within scripts and hooks use `${CLAUDE_PLUGIN_ROOT}` which resolves to the installed location.
**When to use:** Every reference to a file within the plugin from scripts or hook definitions.
**Example (from hooks.json -- already correct in source):**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/suggest-review.sh"
      }]
    }]
  }
}
```

### Pattern 4: Config as Data, Not Code

**What:** Scoring weights, thresholds, banned patterns, and presets live in JSON config files separate from command prompts.
**When to use:** Any behavior that should be tunable without editing command prompts.
**Key detail:** Users can fork and tune scoring without understanding the review prompts.

### Pattern 5: Skill References for Token Efficiency

**What:** SKILL.md is an overview/trigger. Detailed domain knowledge lives in `references/` subdirectory. Specialists load only the references they need.
**When to use:** Always. A monolithic 5000-line skill wastes tokens.
**Key detail:** The source plugin has references at `references/` (top level). Per D-03, restructure to `skills/design-review/references/` during port.

### Pattern 6: Two-Layer Eval Architecture

**What:** Layer 1 (structural) validates file format, JSON syntax, frontmatter, and directory structure -- runs without Claude Code. Layer 2 (quality) runs actual reviews against bundled fixtures and checks range-based assertions -- requires Claude Code session.
**When to use:** `run-evals.sh` runs both layers sequentially.
**Key detail:** Layer 1 is the CI gate (GitHub Actions). Layer 2 is the "crown jewel" proving quality claims.

### Anti-Patterns to Avoid

- **Hardcoded paths:** Using `/Users/felipemachado/` or `~/.claude/plugins/design-review/` anywhere. Use `${CLAUDE_PLUGIN_ROOT}`.
- **JavaScript wrappers:** No Node.js CLI for a non-JS project. Commands are markdown.
- **Monolithic SKILL.md:** Don't dump all domain knowledge in one file. Use references.
- **State management:** Reviews are point-in-time. No cross-session state needed.
- **Pre-building a framework:** Build design-review standalone. Framework emerges from 2nd skill.
- **Mixing directories:** Don't put eval scripts in hooks/ or config in commands/. Clean separation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plugin manifest format | Custom manifest schema | Official `.claude-plugin/plugin.json` spec | Claude Code validates this on load. Deviations break silently. |
| Frontmatter parsing | Custom YAML parser in bash | `head -n 50 | grep -c "^---"` pattern | Official testing-strategies reference uses this exact pattern. |
| JSON validation | Custom JSON validator | `jq empty file.json` | Standard tool, already available (jq-1.7.1). |
| Path portability | Manual path rewriting at runtime | `${CLAUDE_PLUGIN_ROOT}` built-in variable | Claude Code resolves this automatically for all installed plugins. |
| Hook lifecycle | Custom event system | `hooks/hooks.json` standard format | Claude Code handles event dispatch. Just declare matchers. |

**Key insight:** The plugin format IS the framework. Claude Code provides discovery, lifecycle hooks, path resolution, and command registration. Building custom infrastructure on top is pure overhead.

## Common Pitfalls

### Pitfall 1: Hardcoded Paths from Source Plugin
**What goes wrong:** Source plugin contains references to Felipe's local paths. Plugin fails on other machines.
**Why it happens:** Copy-paste without grep audit.
**How to avoid:** After copying all files, run: `grep -rn '/Users/' . && grep -rn '~/.claude/plugins/design-review' . && grep -rn '~/.claude/skills' .`. Current audit found 1 hit in README.md. Full audit post-copy will likely find more in command files.
**Warning signs:** Any absolute path in any file.

### Pitfall 2: Source Plugin References Structure Mismatch
**What goes wrong:** Source has `references/` at top level. Target needs `skills/design-review/references/`. Command files still reference old paths.
**Why it happens:** D-02 says preserve structure but D-03 adds skills directory. Commands reference `${CLAUDE_PLUGIN_ROOT}/references/` which won't exist at the new location.
**How to avoid:** Two options: (a) keep references at root AND symlink/copy to skills/, or (b) update all command references. Since commands use `@` syntax and `${CLAUDE_PLUGIN_ROOT}`, update the path in commands. But verify: some references may be loaded by Claude's auto-discovery (skills directory), others explicitly by commands. Map each reference to its loader before moving.
**Warning signs:** References not found during review execution.

### Pitfall 3: Eval Harness Only Works Locally
**What goes wrong:** `run-evals.sh` references local dev servers or fixtures that exist only on Felipe's machine.
**Why it happens:** Evals built for local validation, not portable reproduction.
**How to avoid:** Bundle 3 minimal HTML fixtures in `evals/fixtures/`. Structural evals (Layer 1) run with just bash+jq. Quality evals (Layer 2) document prerequisites clearly and fail gracefully if Claude Code isn't available.
**Warning signs:** `run-evals.sh` exits non-zero on a clean clone.

### Pitfall 4: Plugin Name Collision
**What goes wrong:** New SpSk plugin registers same command names as existing `~/.claude/plugins/design-review/`. Both load, commands collide.
**Why it happens:** User has old local plugin installed alongside new one.
**How to avoid:** Use `name: "spsk"` in plugin.json (different from source's implicit name). Document in README: "Uninstall the local design-review plugin before installing SpSk." Commands (`/design-review`, etc.) come from filename, not plugin name.
**Warning signs:** "Name conflict" errors in Claude Code debug logs.

### Pitfall 5: Gemini Reference File Workspace Restriction
**What goes wrong:** Gemini CLI can only read files in current workspace root. Design-review v1.0.0 copies `.color-reference.md` and `.layout-reference.md` to repo root before Gemini invocations. If this copy step is missed, Gemini specialists produce worse results.
**Why it happens:** Invisible side-effect in the review flow, easy to miss during port.
**How to avoid:** Port the reference-file-copy pattern faithfully. Document it in ARCHITECTURE.md.
**Warning signs:** Color and Layout specialists produce generic, less-informed scores.

### Pitfall 6: Token Budget Explosion
**What goes wrong:** Full 8-specialist review costs ~84K tokens baseline, ~200K+ with all references loaded. Users on lower-tier plans hit context limits.
**Why it happens:** 8 parallel agents each loading references + screenshots.
**How to avoid:** Quick mode (`--quick`) already exists. Document expected token usage in README. This is a documentation issue, not a code issue.
**Warning signs:** Users reporting context window errors.

### Pitfall 7: VERSION / plugin.json / CHANGELOG Version Drift
**What goes wrong:** VERSION file, plugin.json version field, and CHANGELOG latest entry reference different versions.
**Why it happens:** Multiple files tracking the same value with no single source of truth.
**How to avoid:** Structural eval (Layer 1) validates version consistency across all three files. CI workflow also checks this.
**Warning signs:** Eval failure on version check.

## Code Examples

### plugin.json Manifest (verified against 3 installed plugins + official spec)

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

Source: Manifest schema from `plugin-dev/skills/plugin-structure/references/manifest-reference.md`. Name validation regex: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`.

### Structural Eval Pattern (Layer 1)

```bash
#!/bin/bash
# evals/run-evals.sh — structural validation layer
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

echo "=== Layer 1: Structural Validation ==="

# 1. plugin.json exists and is valid JSON
echo -n "  plugin.json valid... "
if jq empty "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"; ((ERRORS++))
fi

# 2. plugin.json has required fields
echo -n "  plugin.json has name... "
if jq -e '.name' "$PLUGIN_ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1; then
  echo "PASS"
else
  echo "FAIL"; ((ERRORS++))
fi

# 3. All command files have valid frontmatter
for cmd in "$PLUGIN_ROOT"/commands/*.md; do
  echo -n "  $(basename "$cmd") frontmatter... "
  MARKERS=$(head -n 50 "$cmd" | grep -c "^---" || true)
  if [ "$MARKERS" -eq 2 ]; then
    echo "PASS"
  else
    echo "FAIL (found $MARKERS markers, expected 2)"; ((ERRORS++))
  fi
done

# 4. Version consistency
VERSION_FILE=$(cat "$PLUGIN_ROOT/VERSION" | tr -d '[:space:]')
VERSION_JSON=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
echo -n "  Version consistency (VERSION=$VERSION_FILE, plugin.json=$VERSION_JSON)... "
if [ "$VERSION_FILE" = "$VERSION_JSON" ]; then
  echo "PASS"
else
  echo "FAIL"; ((ERRORS++))
fi

# 5. No hardcoded paths
echo -n "  No hardcoded paths... "
if grep -rq '/Users/' "$PLUGIN_ROOT" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null; then
  echo "FAIL (found /Users/ references)"; ((ERRORS++))
else
  echo "PASS"
fi

# 6. Config JSON files valid
for cfg in "$PLUGIN_ROOT"/config/*.json; do
  echo -n "  $(basename "$cfg") valid JSON... "
  if jq empty "$cfg" 2>/dev/null; then
    echo "PASS"
  else
    echo "FAIL"; ((ERRORS++))
  fi
done

# 7. hooks.json valid
echo -n "  hooks.json valid... "
if jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"; ((ERRORS++))
fi

# Summary
echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== All structural checks passed ==="
  exit 0
else
  echo "=== $ERRORS structural check(s) FAILED ==="
  exit 1
fi
```

### Range-Based Assertion Pattern (Layer 2 concept)

```json
{
  "eval_cases": [
    {
      "name": "admin-panel",
      "fixture": "fixtures/admin-panel.html",
      "page_type": "admin",
      "assertions": [
        { "field": "overall_score", "min": 2.0, "max": 4.0 },
        { "field": "verdict", "one_of": ["SHIP", "CONDITIONAL SHIP"] },
        { "field": "specialist_count", "equals": 8 },
        { "field": "tier", "equals": 1 }
      ]
    },
    {
      "name": "landing-page-slop",
      "fixture": "fixtures/landing-page.html",
      "page_type": "landing",
      "assertions": [
        { "field": "overall_score", "min": 1.0, "max": 3.0 },
        { "field": "verdict", "one_of": ["BLOCK", "CONDITIONAL SHIP"] }
      ]
    }
  ]
}
```

Note: Quality evals (Layer 2) require a Claude Code session to run actual `/design-review` commands. They are NOT automated CI -- they are developer-run benchmarks. Layer 1 (structural) is the CI gate.

### .gitignore Pattern

```gitignore
# Generated during reviews
.design-reviews/
.color-reference.md
.layout-reference.md
screenshots/
*.png
!evals/fixtures/**

# OS
.DS_Store

# Planning (dev only)
.planning/
.context/
.memsearch/
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-agent review | 8-specialist multi-agent | v4 (2026-03-28) | Pass rate: 40% to 100% |
| Exact score assertions | Range-based assertions | v4 (2026-03-28) | Evals tolerate AI non-determinism |
| Manual plugin install (clone+symlink) | `claude /install-plugin name@owner/repo` | Plugin registry launch | One-command install |
| Monolithic skill file | SKILL.md + references/ directory | v3 (2026-03-28) | Token efficiency, specialist focus |

**Source plugin is already at v1.0.0 (v4 architecture).** The port should preserve this, not downgrade.

## Open Questions

1. **Reference file location after restructure**
   - What we know: Source has `references/` at plugin root. D-03 wants `skills/design-review/references/`. Commands use `${CLAUDE_PLUGIN_ROOT}/references/` paths.
   - What's unclear: Whether to keep both locations, use symlinks, or update all command references.
   - Recommendation: Move references to `skills/design-review/references/` and update command paths. The source references also include `harness.md` and `workflows.md` which are operational docs, not domain knowledge -- these could stay at root or move to a `docs/` directory.

2. **Quality eval execution model**
   - What we know: Quality evals need to run actual Claude Code reviews against HTML fixtures.
   - What's unclear: How to invoke `/design-review` programmatically from a bash script. Claude Code commands are interactive.
   - Recommendation: Layer 2 evals may need to be documented as "run manually in a Claude Code session" rather than fully automated. The structural layer (Layer 1) is the automated gate. Consider a `calibration-template.md` that guides manual eval execution.

3. **Plugin name for install command**
   - What we know: D-01 says use standard plugin conventions. STACK research suggests `spsk` as plugin name.
   - What's unclear: Whether the install command should be `spsk@felipemachado/spsk` or `design-review@felipemachado/spsk`.
   - Recommendation: Use `spsk` as the plugin name. The repo name IS spsk. The install becomes `claude /install-plugin spsk@felipemachado/spsk`. This avoids collision with any future `design-review` plugin from others.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Eval harness, hooks | Yes | standard | -- |
| jq | Structural eval JSON validation | Yes | 1.7.1 | -- |
| node | N/A (not used by plugin) | Yes | 22.19.0 | -- |
| Gemini CLI | Tier 1 reviews (Color, Layout specialists) | Yes | 0.34.0 | Tier 2 degradation (Claude-only) |
| Playwright | Screenshots for reviews | Yes | 1.58.2 | Static HTML serving |
| grep | Hardcoded path audit | Yes | standard | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None -- all tools available on this machine. However, the plugin MUST work without Gemini (Tier 2) and without Playwright (Tier 3) on user machines. This is already handled by the degradation system.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash eval harness (no JS test framework) |
| Config file | `evals/run-evals.sh` (created in Wave 0) |
| Quick run command | `bash evals/run-evals.sh --structural` |
| Full suite command | `bash evals/run-evals.sh` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCAF-01 | plugin.json valid with required fields | structural | `jq -e '.name and .version' .claude-plugin/plugin.json` | Wave 0 |
| SCAF-02 | README.md exists | structural | `test -f README.md` | Wave 0 |
| SCAF-03 | CLAUDE.md exists with command docs | structural | `test -f CLAUDE.md && grep -q '/design-review' CLAUDE.md` | Wave 0 |
| SCAF-04 | LICENSE exists | structural | `test -f LICENSE` | Wave 0 |
| SCAF-05 | CHANGELOG.md exists with failure story | structural | `test -f CHANGELOG.md && grep -q '40%' CHANGELOG.md` | Wave 0 |
| SCAF-06 | ARCHITECTURE.md exists with specialist docs | structural | `test -f ARCHITECTURE.md && grep -q 'specialist' ARCHITECTURE.md` | Wave 0 |
| PORT-01 | design-review.md has valid frontmatter | structural | `head -50 commands/design-review.md \| grep -c '^---'` (expect 2) | Wave 0 |
| PORT-02 | design.md has valid frontmatter | structural | Same frontmatter check | Wave 0 |
| PORT-03 | design-improve.md has valid frontmatter | structural | Same frontmatter check | Wave 0 |
| PORT-04 | design-validate.md has valid frontmatter | structural | Same frontmatter check | Wave 0 |
| PORT-05 | Config JSON files valid | structural | `jq empty config/*.json` | Wave 0 |
| PORT-06 | SKILL.md exists with frontmatter | structural | `test -f skills/design-review/SKILL.md` | Wave 0 |
| PORT-07 | hooks.json valid | structural | `jq empty hooks/hooks.json` | Wave 0 |
| PORT-08 | No hardcoded paths | structural | `grep -r '/Users/' --include='*.md' --include='*.json' --include='*.sh'` (expect 0) | Wave 0 |
| PORT-09 | Degradation tier logic present | structural | `grep -q 'Tier' commands/design-review.md` | Wave 0 |
| PORT-10 | Quick mode logic present | structural | `grep -q 'quick' commands/design-review.md` | Wave 0 |
| EVAL-01 | run-evals.sh exists and is executable | structural | `test -x evals/run-evals.sh` | Wave 0 |
| EVAL-02 | Fixtures bundled | structural | `ls evals/fixtures/*.html \| wc -l` (expect >= 3) | Wave 0 |
| EVAL-03 | Assertions use ranges | structural | `grep -q 'min\|max' evals/assertions.json` | Wave 0 |
| EVAL-04 | Results directory exists | structural | `test -d evals/results` | Wave 0 |
| EVAL-05 | Structural evals pass on clean clone | smoke | `bash evals/run-evals.sh --structural` (exit 0) | Wave 0 |

### Sampling Rate
- **Per task commit:** `bash evals/run-evals.sh --structural` (Layer 1 only, < 5 seconds)
- **Per wave merge:** `bash evals/run-evals.sh` (both layers if Claude Code session available)
- **Phase gate:** Full structural pass + documented manual quality eval results

### Wave 0 Gaps
- [ ] `evals/run-evals.sh` -- eval harness script (covers EVAL-01, EVAL-05)
- [ ] `evals/fixtures/` directory with 3 HTML test pages (covers EVAL-02)
- [ ] `evals/assertions.json` -- assertion definitions (covers EVAL-03)
- [ ] `.claude-plugin/plugin.json` -- manifest (covers SCAF-01)

## Source File Inventory

Complete inventory of files to port from `~/.claude/plugins/design-review/`:

| Source File | Target Location | Action |
|-------------|-----------------|--------|
| `commands/design.md` | `commands/design.md` | Copy, audit paths |
| `commands/design-review.md` | `commands/design-review.md` | Copy, audit paths |
| `commands/design-improve.md` | `commands/design-improve.md` | Copy, audit paths |
| `commands/design-validate.md` | `commands/design-validate.md` | Copy, audit paths |
| `config/scoring.json` | `config/scoring.json` | Copy (no paths) |
| `config/anti-slop.json` | `config/anti-slop.json` | Copy (no paths) |
| `config/style-presets.json` | `config/style-presets.json` | Copy (no paths) |
| `config/design-system.example.json` | `config/design-system.example.json` | Copy (no paths) |
| `references/typography.md` | `skills/design-review/references/typography.md` | Copy, update command refs |
| `references/color.md` | `skills/design-review/references/color.md` | Copy, update command refs |
| `references/layout.md` | `skills/design-review/references/layout.md` | Copy, update command refs |
| `references/icons.md` | `skills/design-review/references/icons.md` | Copy, update command refs |
| `references/motion.md` | `skills/design-review/references/motion.md` | Copy, update command refs |
| `references/intent.md` | `skills/design-review/references/intent.md` | Copy, update command refs |
| `references/visual-design-rules.md` | `skills/design-review/references/visual-design-rules.md` | Copy, update command refs |
| `references/harness.md` | `skills/design-review/references/harness.md` | Copy (operational doc) |
| `references/workflows.md` | `skills/design-review/references/workflows.md` | Copy (operational doc) |
| `hooks/hooks.json` | `hooks/hooks.json` | Copy (already uses ${CLAUDE_PLUGIN_ROOT}) |
| `scripts/suggest-review.sh` | `hooks/scripts/suggest-review.sh` | Copy (uses /tmp, no plugin paths) |
| `VERSION` | `VERSION` | Copy |
| `CHANGELOG.md` | `CHANGELOG.md` | Adapt for SpSk context, expand failure narrative |
| `README.md` | `README.md` | Rewrite for SpSk context |
| (new) | `.claude-plugin/plugin.json` | Create |
| (new) | `CLAUDE.md` | Create |
| (new) | `ARCHITECTURE.md` | Create |
| (new) | `LICENSE` | Create |
| (new) | `.gitignore` | Create |
| (new) | `skills/design-review/SKILL.md` | Create from design-review.md frontmatter knowledge |
| (new) | `evals/run-evals.sh` | Create |
| (new) | `evals/assertions.json` | Create |
| (new) | `evals/fixtures/*.html` | Create (3 test pages) |
| (new) | `evals/results/` | Create directory |

**Total: 22 files to port + 10 new files = 32 files in final repo.**

## Project Constraints (from CLAUDE.md)

- GSD workflow enforced -- use `/gsd:execute-phase` for planned work
- Design-review as flagship, consensus-validation as 2nd skill (Phase 3)
- Plugin registry as primary distribution
- Evals are the crown jewel -- make reproducible with run-evals.sh
- Show what DIDN'T work in CHANGELOG
- Phase 1 is about correctness, not polish (Phase 2 handles branding)

## Sources

### Primary (HIGH confidence)
- Direct inspection of `~/.claude/plugins/design-review/` -- all 22 source files examined
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md` -- official plugin.json spec
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/plugin-structure/examples/standard-plugin.md` -- standard plugin structure example
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/command-development/references/testing-strategies.md` -- eval patterns
- 3 real installed plugin.json files inspected (memsearch, claude-hud, cartographer) -- verified manifest field patterns

### Secondary (MEDIUM confidence)
- `.planning/research/STACK.md` -- technology stack research (cross-verified with direct plugin inspection)
- `.planning/research/ARCHITECTURE.md` -- architecture patterns (cross-verified with source plugin files)
- `.planning/research/PITFALLS.md` -- domain pitfalls (verified against actual source code)
- `.context/design-review-status.md` -- plugin v1.0.0 status and benchmark results

### Tertiary (LOW confidence)
- Quality eval execution model -- unclear how to invoke `/design-review` programmatically from bash. May require manual execution rather than full automation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- directly inspected 20+ plugins and official reference docs
- Architecture: HIGH -- source plugin is working v1.0.0, patterns verified
- Pitfalls: HIGH -- hardcoded path audit done, eval portability risks documented
- Eval harness design: MEDIUM -- structural layer is straightforward, quality layer execution model has open questions

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable domain, plugin format unlikely to change rapidly)
