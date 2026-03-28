# Architecture Patterns

**Domain:** Multi-agent Claude Code plugin for design quality review
**Researched:** 2026-03-28

## Recommended Architecture

SpSk uses a **multi-agent specialist pattern with boss synthesizer** -- the same pattern used by Anthropic's own code-review plugin but applied to visual design assessment.

### High-Level Flow

```
User invokes /design-review
       |
       v
  Phase 0: Screenshots (mandatory)
       |
       v
  Phase 1: Haiku classifies page type -> sets creativity bar
       |
       v
  Phase 2: 8 specialists run IN PARALLEL
       |    (each reads screenshots + relevant source + domain references)
       |
       v
  Phase 3: Boss synthesizes with weighted scoring
       |    (resolves disagreements, applies thresholds, renders verdict)
       |
       v
  SHIP / CONDITIONAL SHIP / BLOCK
       |
       v
  Phase 4 (if BLOCK): Targeted re-review of failing dimensions only
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `/design` command | Orchestrator/router. Parses args, dispatches to sub-commands. | All sub-commands |
| `/design-review` command | Core review. Manages phases 0-4. Spawns specialists. | Specialists (parallel), scoring.json, anti-slop.json |
| `/design-improve` command | Iterative loop. Build -> review -> fix -> re-review. | /design-review (for scoring each iteration) |
| `/design-validate` command | Functional testing. Clicks, forms, links. | Playwright MCP |
| `skills/design-review/SKILL.md` | Background knowledge. Loaded contextually when design review is relevant. | References/* (loaded on demand) |
| `config/scoring.json` | Dimension weights and per-type thresholds. | Boss synthesizer reads this |
| `config/anti-slop.json` | Banned AI patterns (fonts, colors, layouts). | All visual specialists check against this |
| `config/style-presets.json` | 5 built-in style presets. | /design init, /design-review |
| `hooks/hooks.json` | PostToolUse trigger after frontend edits. | suggest-review.sh |
| `evals/` | Reproducible benchmark runner. | /design-review (runs actual reviews) |

### Specialist Roster (8 Agents)

| # | Specialist | Model | Reads | Weight |
|---|-----------|-------|-------|--------|
| 1 | Font | Claude Sonnet | screenshots + source + references/typography.md | 2 |
| 2 | Color | Gemini CLI | screenshots + .color-reference.md | 2 |
| 3 | Layout | Gemini CLI | screenshots + .layout-reference.md | 1 |
| 4 | Icon | Claude Sonnet | screenshots + source + references/icons.md | 1 |
| 5 | Motion | Claude Sonnet | source only + references/motion.md | 1 |
| 6 | Intent | Claude Sonnet | screenshots + source + references/intent.md | 3 |
| 7 | Copy | Claude Haiku | source only | 1 |
| 8 | Code/A11y | Claude Sonnet | source only | 1 |

**Why multi-model:** Color and Layout use Gemini because it has demonstrated stronger visual perception for spatial relationships and color harmony. Other specialists use Claude Sonnet for code analysis depth. Copy uses Haiku for speed (low complexity task).

### Scoring Formula

```
Score = (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout + Icons + Motion + Copy + Code) / 17
```

Quick mode (4 specialists):
```
Score = (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout) / 13
```

### Data Flow

```
1. User runs /design-review [url]
2. Command takes screenshots via Playwright or static HTML serving
3. Haiku classifies page type (admin/landing/emotional/etc.)
4. Page type selects threshold from scoring.json
5. 8 specialists spawn in parallel, each:
   a. Reads screenshots
   b. Reads relevant source files
   c. Reads domain reference file
   d. Checks against anti-slop.json
   e. Returns: dimension score (1-4) + issues list + rationale
6. Boss synthesizer:
   a. Collects all specialist outputs
   b. Applies weighted formula
   c. Compares against page-type threshold
   d. Resolves specialist disagreements (documented)
   e. Renders verdict: SHIP / CONDITIONAL SHIP / BLOCK
7. If BLOCK: Phase 4 re-runs only failing specialists after fixes
```

## Patterns to Follow

### Pattern 1: Plugin Discovery via Convention

**What:** Claude Code discovers plugin components by scanning standard directories at startup.
**When:** Always. This is how the plugin loads.

The discovery order is:
1. `.claude-plugin/plugin.json` -- must exist or plugin is invisible
2. Default directories scanned: `commands/`, `agents/`, `skills/`, `hooks/hooks.json`, `.mcp.json`
3. Custom paths from manifest scanned (supplements, does not replace defaults)
4. All discovered components register (name conflicts cause errors)

**Implication for SpSk:** Use default directory names. Do not put commands in `src/commands/` or `cli/commands/`. Use `commands/` directly. Custom paths add configuration burden for zero benefit.

### Pattern 2: Command as Prompt, Not Code

**What:** Commands are markdown files with instructions for Claude, not executable programs.
**When:** All slash commands.

```markdown
---
description: Review UI design quality with 8 specialists
argument-hint: [page-url] [--quick] [--ref url]
allowed-tools: Bash(gemini *), Bash(npx *), Bash(curl *)
---

# Design Review

[Instructions that Claude follows when user invokes /design-review]
```

The command `.md` file IS the prompt. Claude reads it and executes the workflow described. There is no JavaScript handler, no express route, no function to call. The "implementation" is prompt engineering.

**Implication for SpSk:** Quality of the command markdown directly determines quality of the tool. Invest in clear, unambiguous instructions. Test with different inputs. The .md files are the codebase.

### Pattern 3: Skill as Contextual Knowledge

**What:** SKILL.md files are loaded when Claude detects a matching task context.
**When:** Claude decides based on the skill's `description` field in frontmatter.

```yaml
---
name: design-review
description: Use when reviewing UI designs, checking visual quality,
  evaluating typography, color, layout, or accessibility. Provides
  domain knowledge about design principles and anti-patterns.
tools: Read, Glob, Grep, Bash
---
```

The skill is NOT invoked by the user. Claude auto-loads it when the task matches. This means the `description` field is critical -- it is the trigger mechanism.

**Implication for SpSk:** Write skill descriptions that match natural language users would use: "check the design", "review this page", "is this ready to ship", "look at the UI".

### Pattern 4: Config as Data, Not Code

**What:** Scoring weights, thresholds, banned patterns, and presets live in JSON config files.
**When:** Any behavior that should be tunable without editing command prompts.

```json
// config/scoring.json
{
  "weights": { "intent_match": 3, "typography": 2, "color": 2 },
  "thresholds": { "admin": 2.5, "landing": 3.0, "portfolio": 3.5 }
}
```

**Implication for SpSk:** Users can fork the repo and tune scoring without understanding the review prompts. Separation of data and logic.

### Pattern 5: Hooks as Lightweight Triggers

**What:** hooks.json registers shell scripts that fire on Claude Code lifecycle events.
**When:** Non-blocking suggestions, context injection, or validation.

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

The suggest-review.sh hook counts frontend file edits and suggests `/design-review` after 3+. Non-blocking -- just a system message.

**Implication for SpSk:** Keep hooks minimal. One hook for v1 (suggest-review). Do not build elaborate hook chains.

### Pattern 6: ${CLAUDE_PLUGIN_ROOT} for Portability

**What:** All path references in hooks, scripts, and commands use `${CLAUDE_PLUGIN_ROOT}`.
**When:** Any reference to a file within the plugin.

Users install to `~/.claude/plugins/cache/<marketplace>/<name>/<version>/`. The path is unpredictable. `${CLAUDE_PLUGIN_ROOT}` resolves to wherever the plugin was installed.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoded Paths
**What:** Using `/Users/felipemachado/.claude/plugins/design-review/` in commands or hooks.
**Why bad:** Breaks on every other machine.
**Instead:** Use `${CLAUDE_PLUGIN_ROOT}/path/to/file`.

### Anti-Pattern 2: JavaScript Runtime for Non-JS Work
**What:** Writing a Node.js CLI wrapper to orchestrate markdown-based commands.
**Why bad:** Adds node_modules, package.json, build step. Claude Code already orchestrates everything.
**Instead:** Let command markdown files drive the workflow.

### Anti-Pattern 3: Over-Nested Directory Structure
**What:** `src/plugins/design-review/commands/core/review/index.md`
**Why bad:** Claude Code scans `commands/` by default. Nesting requires custom paths in plugin.json and slows discovery.
**Instead:** Flat `commands/` directory with descriptive file names.

### Anti-Pattern 4: State Management for Stateless Operations
**What:** Building STATE.md, session persistence, pause/resume for design reviews.
**Why bad:** Reviews are point-in-time assessments. They complete in one session.
**Instead:** Write results to `.design-reviews/` if persistence is needed. No cross-session state.

### Anti-Pattern 5: Monolithic SKILL.md
**What:** Putting all domain knowledge (typography, color, layout, icons, motion, intent, copy) in one SKILL.md.
**Why bad:** SKILL.md is loaded contextually. A 5000-line skill wastes tokens when only color knowledge is needed.
**Instead:** Keep SKILL.md as an overview. Put detailed knowledge in `references/` subdirectory. Specialists load only the references they need.

### Anti-Pattern 6: Mixing Plugin Concerns
**What:** Putting eval harness scripts in `hooks/`, or config files in `commands/`.
**Why bad:** Claude Code scans specific directories for specific component types. Wrong placement causes confusing behavior.
**Instead:** Keep clean boundaries: commands/ for commands, config/ for data, evals/ for testing, hooks/ for lifecycle.

## Scalability Considerations

| Concern | 1 Skill (Phase 1) | 2 Skills (Phase 3) | 3+ Skills (Future) |
|---------|-------------------|--------------------|--------------------|
| Command namespace | `/design-*` | `/design-*` + `/consensus-*` | Consider `/spsk:` namespace prefix |
| Config location | `config/` flat | `config/design/` + `config/consensus/` | Per-skill config directories |
| References | `skills/design-review/references/` | Separate reference dirs per skill | Shared references if overlap |
| Hooks | 1 hook (suggest-review) | Separate hooks per skill | Combined hooks.json with multiple matchers |
| Branding | Inline in commands | Extract to `lib/branding.md` reference | Shared branding reference file |

**Key insight:** The transition from 1 to 2 skills is where shared patterns emerge naturally. Do NOT pre-build a framework. Build design-review, build consensus-validation, then extract what is common.

## Sources

- Direct inspection of ~/.claude/plugins/design-review/ (22 files, architecture)
- .context/design-review-status.md (specialist roster, scoring formula, test results)
- plugin-dev/skills/plugin-structure/ (component-patterns.md, standard-plugin.md, manifest-reference.md)
- plugin-dev/skills/command-development/ (frontmatter-reference.md)
- plugin-dev/skills/hook-development/ (hook patterns, lifecycle events)
- .context/gsd-research.md (specialist agent pattern, model profiles)
- Official marketplace README.md (plugin structure reference)
