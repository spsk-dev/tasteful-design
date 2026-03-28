# Domain Pitfalls

**Domain:** Claude Code plugin / AI agent skill showcase (portfolio repo)
**Researched:** 2026-03-28

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Hardcoded Paths from Source Plugin
**What goes wrong:** The source plugin at `~/.claude/plugins/design-review/` contains paths, session IDs, and state file locations that reference Felipe's local machine. Porting without scrubbing produces a plugin that only works on one machine.
**Why it happens:** Copy-paste from working local plugin without auditing every file reference.
**Consequences:** Plugin silently fails on other machines. `suggest-review.sh` writes to `/tmp/design-review-edit-count-${SESSION_ID}` -- this is fine, but any reference to `~/.claude/plugins/design-review/` or `~/.claude/skills/design-review/` must be replaced with `${CLAUDE_PLUGIN_ROOT}`.
**Prevention:** After porting, grep the entire repo for `/Users/`, `~/.claude/`, and any absolute path. Replace all with `${CLAUDE_PLUGIN_ROOT}` or relative paths.
**Detection:** Run `grep -r '/Users/' .` and `grep -r '~/.claude' .` on the repo.

### Pitfall 2: Gemini CLI Dependency Without Fallback
**What goes wrong:** Two specialists (Color, Layout) use Gemini CLI for visual analysis. Users who don't have Gemini installed get a broken review with 2/8 specialists failing.
**Why it happens:** Multi-model design is a strength but also a hard dependency.
**Consequences:** Review produces incomplete scores. Users blame the plugin instead of their missing Gemini install.
**Prevention:** The v1.0.0 plugin already has degradation tiers (Tier 1: full, Tier 2: no Gemini, Tier 3: code-only). Port this faithfully. Ensure the degradation reporting is visible -- users must know which tier ran.
**Detection:** Test installation without Gemini CLI available. Verify Tier 2 activates cleanly.

### Pitfall 3: Eval Harness That Only Works Locally
**What goes wrong:** `run-evals.sh` references local dev servers, specific port numbers, or test fixtures that exist only in Felipe's environment. Others clone the repo and evals fail.
**Why it happens:** Evals were built for local validation, not portable reproduction.
**Consequences:** The "crown jewel" is broken. Credibility of benchmark claims collapses.
**Prevention:** Include test fixtures in the repo (static HTML pages for eval test cases). Document exact prerequisites (dev server URL, Playwright installed). Provide a `--local` flag for Felipe's setup and a `--self-contained` mode using bundled fixtures.
**Detection:** Clone to a clean directory. Run `evals/run-evals.sh` with no prior setup. It should either work or give clear instructions.

### Pitfall 4: Plugin Name Collision
**What goes wrong:** If `plugin.json` uses `name: "design-review"` (matching an existing plugin) or a generic name, Claude Code may conflict with other installed plugins.
**Why it happens:** The existing plugin at `~/.claude/plugins/design-review/` already registers commands. The new SpSk plugin registering the same command names causes conflicts.
**Consequences:** "Name conflicts cause errors" (from Claude Code component discovery documentation). Plugin fails to load.
**Prevention:** Use `name: "spsk"` in plugin.json. This is the plugin name, not the skill name. Commands are still `/design-review` etc. -- command names come from the file name, not the plugin name. But if both old and new plugins are installed simultaneously, commands will collide. Document: "Uninstall the local design-review plugin before installing SpSk."
**Detection:** Install SpSk while old plugin is still active. Check for registration errors in debug logs.

## Moderate Pitfalls

### Pitfall 5: Gemini Reference File Workspace Restriction
**What goes wrong:** Gemini CLI can only read files in the current workspace root. The design-review v1.0.0 copies reference files to repo root before Gemini invocations. If this copy step is missed in the port, Gemini specialists silently produce worse results (they lack reference context).
**Prevention:** Port the reference-file-copy pattern faithfully. Document it in ARCHITECTURE.md so future contributors understand why `.color-reference.md` and `.layout-reference.md` appear at workspace root.

### Pitfall 6: Screenshot Phase Brittleness
**What goes wrong:** Phase 0 (screenshots) requires either a running dev server or static HTML files. If neither exists, the review cannot start. Playwright needs to be installed.
**Prevention:** Clear error messages in Phase 0: "No dev server detected at localhost:3000-3100. Provide a URL or an HTML file path." Check for Playwright: `npx playwright install chromium` if missing. Document in CLAUDE.md.

### Pitfall 7: Token Budget Explosion
**What goes wrong:** Full 8-specialist review costs ~84K tokens baseline, ~200K+ with all references loaded. Users on lower-tier plans hit context limits.
**Prevention:** Quick mode (`--quick`) exists for budget-conscious users. Document expected token usage prominently. Consider a `--budget` flag that uses Haiku for all specialists.
**Detection:** Monitor token usage across different review types. Add token estimates to command descriptions.

### Pitfall 8: Stale Screenshots in Workspace
**What goes wrong:** Previous review's screenshots remain in the workspace. New review picks up old screenshots, producing incorrect results.
**Prevention:** Clean stale screenshots at the start of every review (Phase 0). This is documented as a known limitation in v1.0.0 -- port the cleanup step.

### Pitfall 9: Over-Engineering the README
**What goes wrong:** README becomes a wall of text that nobody reads. The portfolio value is lost because visitors bounce.
**Prevention:** Lead with the demo GIF (30 seconds). Then: install command (one line). Then: what it does (3 bullets). Architecture and details go in ARCHITECTURE.md, not README. README sells; ARCHITECTURE.md explains.
**Detection:** Can a stranger understand what SpSk does in 10 seconds? If not, README is too long.

### Pitfall 10: Building the Framework Before the Second Skill
**What goes wrong:** Phase 1 includes "shared utilities", "plugin SDK", "skill template system" that are never validated by actual usage. When consensus-validation is built in Phase 3, the framework doesn't fit.
**Prevention:** Build design-review as a standalone plugin (Phase 1). Build consensus-validation as a standalone skill (Phase 3). THEN extract shared patterns. Premature abstraction is the root of all evil in portfolio repos.
**Detection:** If you're writing code that no current feature uses, stop.

## Minor Pitfalls

### Pitfall 11: Inconsistent Unicode Output
**What goes wrong:** Different command files use different box-drawing characters, progress bar widths, or symbol meanings. Output looks unprofessional.
**Prevention:** Document the branding vocabulary once (in a reference file or CLAUDE.md) and reference it from all commands. Status symbols, box widths, and banner format must be identical everywhere.

### Pitfall 12: Missing `.gitignore` for Generated Files
**What goes wrong:** `.design-reviews/` results, screenshots, `.color-reference.md` copies, and other generated files get committed.
**Prevention:** Include a `.gitignore` that excludes generated artifacts. Or document which files are expected to be committed (eval results) vs. ephemeral (screenshots).

### Pitfall 13: VERSION File Drift
**What goes wrong:** VERSION file says "1.0.0" but plugin.json says "0.9.0". CHANGELOG references different versions.
**Prevention:** Single source of truth for version. CI validation checks that VERSION, plugin.json version, and CHANGELOG latest entry match.

### Pitfall 14: Forgetting `allowed-tools` in Commands
**What goes wrong:** The `/design` orchestrator needs Bash access for Gemini CLI, Playwright screenshots, and file operations. Without `allowed-tools`, Claude Code may block these operations.
**Prevention:** Port the `allowed-tools` frontmatter exactly from the source plugin. The `/design` command has: `Bash(gemini *)`, `Bash(which *)`, `Bash(npx *)`, `Bash(python3 *)`, `Bash(curl *)`, `Bash(kill *)`, `Bash(mkdir *)`, `Bash(cp *)`, `Bash(rm *)`, `Bash(lsof *)`.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: Port | Hardcoded paths (#1) | grep -r audit after port |
| Phase 1: Port | Plugin name collision (#4) | Use "spsk" as plugin name, doc uninstall step |
| Phase 1: Port | Gemini reference copy (#5) | Port workspace copy pattern faithfully |
| Phase 1: Evals | Non-portable evals (#3) | Bundle test fixtures, document prerequisites |
| Phase 2: Branding | Inconsistent Unicode (#11) | Create branding reference file first |
| Phase 2: Init wizard | Over-engineering config | 5 questions, opinionated defaults, no more |
| Phase 3: 2nd skill | Premature framework (#10) | Build standalone, extract patterns after |
| Phase 3: Release | Version drift (#13) | CI validation of version consistency |

## Sources

- .context/design-review-status.md (known limitations section)
- Direct inspection of suggest-review.sh (hardcoded paths, session state)
- plugin-dev/skills/command-development/references/marketplace-considerations.md (cross-platform, dependencies)
- plugin-dev/skills/plugin-structure/references/component-patterns.md (name conflicts, discovery order)
- plugin-dev/skills/command-development/references/testing-strategies.md (testing levels)
- .context/gsd-research.md (what SpSk should do differently from GSD)
