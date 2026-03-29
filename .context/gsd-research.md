# GSD Plugin Research for SpSk Framework

Research date: 2026-03-28
GSD version analyzed: 1.28.0

---

## 1. Architecture Overview

GSD is a comprehensive project management framework for Claude Code. It operates as a **plugin** installed via `npx get-shit-done-cc@latest` and distributes files across:

- `~/.claude/get-shit-done/` -- Core runtime (bin/, templates/, references/, workflows/)
- `~/.claude/agents/gsd-*.md` -- 15 specialist subagents
- `~/.claude/hooks/gsd-*.js` -- 5 lifecycle hooks
- `~/.claude/commands/gsd/` -- Slash command definitions
- `~/.claude/cache/gsd-*.json` -- Update check cache

### File Counts
- **Workflows:** ~56 `.md` files (one per slash command)
- **Templates:** ~35 `.md` files (scaffolding for project artifacts)
- **References:** ~15 `.md` files (conventions, patterns, guides)
- **Bin/lib:** ~18 `.cjs` modules (CLI tooling)
- **Agents:** 15 specialist agent definitions
- **Hooks:** 5 JS hooks

---

## 2. Branded Output Patterns

### 2.1 Stage Banners

GSD uses a distinctive branded banner for major transitions. From `references/ui-brand.md`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► {STAGE NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Stage names are always uppercase:
- `QUESTIONING`, `RESEARCHING`, `DEFINING REQUIREMENTS`
- `CREATING ROADMAP`, `PLANNING PHASE {N}`, `EXECUTING WAVE {N}`
- `VERIFYING`, `PHASE {N} COMPLETE`, `MILESTONE COMPLETE`

**SpSk idea:** Similar banner but design-focused:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SpSk ► {STAGE NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2.2 Checkpoint Boxes

62-character fixed width, double-line Unicode borders:

```
╔══════════════════════════════════════════════════════════════╗
║  CHECKPOINT: {Type}                                          ║
╚══════════════════════════════════════════════════════════════╝

{Content}

──────────────────────────────────────────────────────────────
→ {ACTION PROMPT}
──────────────────────────────────────────────────────────────
```

Types: `Verification Required`, `Decision Required`, `Action Required`

### 2.3 Error Boxes

Same double-line border, but with `ERROR` header:

```
╔══════════════════════════════════════════════════════════════╗
║  ERROR                                                       ║
╚══════════════════════════════════════════════════════════════╝

{Error description}

**To fix:** {Resolution steps}
```

### 2.4 Update Success Box

```
╔═══════════════════════════════════════════════════════════╗
║  GSD Updated: v1.5.10 → v1.5.15                           ║
╚═══════════════════════════════════════════════════════════╝
```

### 2.5 Status Symbols (Consistent Vocabulary)

```
✓  Complete / Passed / Verified
✗  Failed / Missing / Blocked
◆  In Progress
○  Pending
⚡ Auto-approved
⚠  Warning
```

### 2.6 Progress Bars

```
Progress: ████████░░ 80%
Tasks: 2/4 complete
Plans: 3/5 complete
```

### 2.7 Spawning Indicators

```
◆ Spawning researcher...

◆ Spawning 4 researchers in parallel...
  → Stack research
  → Features research
  → Architecture research
  → Pitfalls research

✓ Researcher complete: STACK.md written
```

### 2.8 Next Up Block (Always at End of Major Steps)

```
───────────────────────────────────────────────────────────────

## ▶ Next Up

**{Identifier}: {Name}** — {one-line description}

`{copy-paste command}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────

**Also available:**
- `/gsd:alternative-1` — description
- `/gsd:alternative-2` — description

───────────────────────────────────────────────────────────────
```

### 2.9 Anti-Patterns (Explicitly Documented)

- Varying box/banner widths
- Mixing banner styles (`===`, `---`, `***`)
- Skipping `GSD ►` prefix in banners
- Random emoji (rocket, sparkles, star)
- Missing Next Up block after completions

---

## 3. Init/Setup Pattern (New Project Wizard)

### 3.1 Flow Structure

```
/gsd:new-project → questioning → research (optional) → requirements → roadmap
```

The init flow is a **single command** that:
1. Runs `gsd-tools.cjs init new-project` to gather project state
2. Checks for brownfield (existing code) and offers codebase mapping
3. Enters deep questioning mode (conversational, not checklist)
4. Creates PROJECT.md from answers
5. Asks config questions (mode, granularity, git tracking, model profiles)
6. Creates `.planning/config.json` with all settings
7. Defines requirements and roadmap

### 3.2 Config Collection Pattern

Uses `AskUserQuestion` with structured options in **rounds**:

**Round 1 -- Core settings (3 questions):**
- Granularity (Coarse/Standard/Fine)
- Execution (Parallel/Sequential)
- Git Tracking (Yes/No)

**Round 2 -- Workflow agents (4 questions):**
- Research before planning? (Yes/No)
- Plan checking? (Yes/No)
- Verification after phases? (Yes/No)
- AI model profile? (Quality/Balanced/Budget/Inherit)

Each option has a label + description, and one is marked `(Recommended)`.

### 3.3 Questioning Philosophy

From `references/questioning.md`:

> "Project initialization is dream extraction, not requirements gathering."
> "You are a thinking partner, not an interviewer."

Key principles:
- **Start open** -- "What do you want to build?"
- **Follow energy** -- Dig into what they emphasized
- **Challenge vagueness** -- Never accept fuzzy answers
- **Make abstract concrete** -- "Walk me through using this"
- **Know when to stop** -- When you understand what/why/who/done

Anti-patterns:
- Checklist walking
- Canned questions
- Interrogation
- Rushing
- Shallow acceptance
- Premature constraints

**SpSk idea:** The design-review skill doesn't need this level of questioning since it operates on existing UI, but `/spsk:new-project` or `/spsk:init` could use a simpler version asking about design context (brand guidelines, target audience, design system in use).

---

## 4. State Management Pattern

### 4.1 Directory Structure

```
.planning/
├── PROJECT.md            -- Project vision
├── ROADMAP.md            -- Phase breakdown
├── STATE.md              -- Living memory (cross-session)
├── REQUIREMENTS.md       -- Scoped requirements
├── RETROSPECTIVE.md      -- Per-milestone retro
├── config.json           -- All settings
├── todos/pending/        -- Captured tasks
├── todos/done/           -- Completed tasks
├── debug/                -- Active debug sessions
├── debug/resolved/       -- Archived issues
├── milestones/           -- Archived milestone data
├── codebase/             -- Codebase map (7 docs)
├── phases/               -- Phase plans and summaries
│   ├── 01-foundation/
│   │   ├── 01-01-PLAN.md
│   │   └── 01-01-SUMMARY.md
│   └── 02-core-features/
└── reports/              -- Session reports
```

### 4.2 STATE.md as Living Memory

STATE.md tracks across sessions:
- Current position (phase/plan/status)
- Progress bar
- Performance metrics (velocity, avg duration)
- Accumulated decisions
- Pending todos
- Blockers/concerns
- Session continuity (last session, stopped-at, resume file)

### 4.3 Config.json Structure

```json
{
  "mode": "interactive|yolo",
  "granularity": "coarse|standard|fine",
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "auto_advance": false,
    "discuss_mode": "discuss",
    "research_before_questions": false
  },
  "planning": {
    "commit_docs": true,
    "search_gitignored": false
  },
  "parallelization": { "enabled": true, "max_concurrent_agents": 3 },
  "gates": { "confirm_project": true, "confirm_phases": true, ... },
  "safety": { "always_confirm_destructive": true },
  "hooks": { "context_warnings": true }
}
```

### 4.4 CLI Tool Pattern (gsd-tools.cjs)

All state operations go through a single CLI entrypoint:
```bash
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" <command> [args] [--raw]
```

Commands are organized as atomic operations + compound init operations.

Atomic: `state load`, `state update`, `state patch`, `resolve-model`, `find-phase`, `commit`, etc.
Compound: `init execute-phase <N>`, `init plan-phase <N>`, `init new-project`, etc.

The compound `init` commands gather ALL context a workflow needs in one call, returning structured JSON. This avoids multiple shell calls and reduces orchestrator token usage.

**SpSk idea:** A single `spsk-tools.cjs` that provides:
- `spsk-tools.cjs init review` -- Context for design review
- `spsk-tools.cjs state load` -- Load design review state
- `spsk-tools.cjs config get <key>` -- Get settings

---

## 5. Help Command Formatting

The `/gsd:help` command outputs a massive reference document (600+ lines) organized as:

1. Quick Start (3-line flow)
2. Core Workflow sections with command signatures
3. Each command with: description, bullet points of what it does, usage examples
4. Files & Structure (ASCII tree)
5. Workflow Modes explanation
6. Common Workflows (copy-paste command sequences)
7. Getting Help section

**SpSk idea:** Keep help much shorter. SpSk has far fewer commands. A compact help that fits on one screen:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SpSk ► HELP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/spsk:review <screenshot>    Review a UI design
/spsk:improve <page>         Build + iterate to quality
/spsk:help                   This reference

Files: .design-reviews/
```

---

## 6. Hook Patterns

### 6.1 Statusline Hook

`gsd-statusline.js` -- Reads session JSON from stdin, outputs formatted status:
```
[update indicator] | model | current task | directory | context bar
```

Features:
- Context window usage as colored progress bar (green < 50%, yellow < 65%, orange < 80%, red+blinking >= 80%)
- Writes bridge file for context monitor
- GSD update available indicator
- Current task from todos

### 6.2 Context Monitor (PostToolUse)

Reads context metrics from statusline bridge file, injects agent-facing warnings:
- WARNING at 35% remaining: "Wrap up current task"
- CRITICAL at 25% remaining: "Stop immediately, save state"
- Debounce: 5 tool uses between warnings
- Severity escalation bypasses debounce

### 6.3 Workflow Guard (PreToolUse)

Soft guard that detects file edits outside GSD workflow context:
- Advisory only (never blocks)
- Suggests `/gsd:fast` or `/gsd:quick`
- Skips .planning/ files, .gitignore, .env, CLAUDE.md
- Only active when `hooks.workflow_guard: true` in config

### 6.4 Prompt Injection Guard (PreToolUse)

Scans content being written to `.planning/` for injection patterns:
- Checks for "ignore previous instructions", role overrides, invisible Unicode
- Advisory only (does not block)
- Defense-in-depth layer

### 6.5 Update Check (SessionStart)

Background npm check for new versions:
- Spawns detached child process
- Writes result to cache file
- Statusline reads cache to show update indicator
- Also checks for stale hooks (version mismatch)

---

## 7. Specialist Agent Pattern

### 7.1 Agent Definitions

Each agent is a `.md` file in `~/.claude/agents/` with YAML frontmatter:

```yaml
---
name: gsd-planner
description: Creates executable phase plans with task breakdown...
tools: Read, Write, Bash, Glob, Grep, WebFetch, mcp__context7__*
color: green
---
```

### 7.2 Model Profile System

Three profiles that map each agent to a model tier:

| Agent | Quality | Balanced | Budget |
|-------|---------|----------|--------|
| gsd-planner | opus | opus | sonnet |
| gsd-executor | opus | sonnet | sonnet |
| gsd-researcher | opus | sonnet | haiku |
| gsd-verifier | sonnet | sonnet | haiku |

**SpSk analogy:** Design review already has 8 specialist agents. Could add model profiles:
- Quality: opus for all specialists
- Balanced: opus for boss/synthesizer, sonnet for specialists
- Budget: sonnet everywhere

### 7.3 Agent Responsibilities

15 agents, each with a narrow scope:
- `gsd-planner` -- Create execution plans
- `gsd-executor` -- Execute plans with atomic commits
- `gsd-verifier` -- Verify deliverables
- `gsd-plan-checker` -- Check plan quality before execution
- `gsd-phase-researcher` -- Research before planning
- `gsd-project-researcher` -- Research project domain
- `gsd-research-synthesizer` -- Synthesize research findings
- `gsd-debugger` -- Systematic debugging
- `gsd-codebase-mapper` -- Map existing codebases
- `gsd-integration-checker` -- Cross-phase wiring checks
- `gsd-nyquist-auditor` -- Validation auditing
- `gsd-ui-researcher` -- UI-specific research
- `gsd-ui-checker` -- UI quality checking
- `gsd-ui-auditor` -- Visual audit
- `gsd-roadmapper` -- Roadmap creation
- `gsd-advisor-researcher` -- Advisory research
- `gsd-user-profiler` -- Developer profiling
- `gsd-assumptions-analyzer` -- Assumption surfacing

---

## 8. What SpSk Should BORROW from GSD

### 8.1 Branded Output System
- Fixed-width stage banners with `SpSk ►` prefix
- Consistent status symbols vocabulary
- Error/checkpoint box patterns
- "Next Up" block after completions
- Anti-pattern documentation to keep output consistent

### 8.2 CLI Tool Pattern
- Single entrypoint (`spsk-tools.cjs`) for all operations
- Compound `init` commands that gather all context in one call
- JSON output for structured data, `--raw` for simple values
- `@file:` prefix for large outputs that exceed buffer limits

### 8.3 Hook Patterns
- Statusline integration showing current review state
- Context monitor for long review sessions
- Session-start update check (if distributed as npm package)

### 8.4 Config as JSON
- `.design-reviews/config.json` for review preferences
- Layered defaults (hardcoded -> user defaults -> project settings)
- Config validation with key suggestions for typos

### 8.5 Version Tracking
- Simple VERSION file
- Hook version headers for stale detection
- Background update checks

### 8.6 Model Profiles
- Quality/balanced/budget tiers for specialist agents
- Configurable per-project

---

## 9. What SpSk Should Do DIFFERENTLY

### 9.1 Scope (Smaller)
GSD manages entire project lifecycles (requirements -> roadmap -> phases -> execution -> verification -> milestones). SpSk should be **single-purpose**: design quality assessment and improvement. No project management, no roadmaps, no milestones.

### 9.2 State (Lighter)
GSD has 10+ state files (PROJECT.md, ROADMAP.md, STATE.md, REQUIREMENTS.md, etc.). SpSk needs at most:
- `.design-reviews/config.json` -- Settings
- `.design-reviews/{timestamp}-{page}.md` -- Review results
- No STATE.md equivalent needed (reviews are point-in-time, not ongoing)

### 9.3 Questioning (None)
GSD has an elaborate questioning philosophy for project init. SpSk should skip this entirely -- it operates on existing UI, not fuzzy ideas. The input is a screenshot or running page, not a dream to extract.

### 9.4 Workflow Complexity (Minimal)
GSD has ~56 workflow files. SpSk should have ~3-5:
- `review.md` -- Run a design review
- `improve.md` -- Build + iterate loop
- `help.md` -- Command reference
- Maybe `settings.md` -- Configure preferences

### 9.5 Specialist Pattern (Keep but Streamline)
GSD has 15 agents. SpSk already has 8 review specialists which is the right number. But SpSk specialists should be more focused -- they evaluate rather than create.

### 9.6 Checkpoint Pattern (Simplify)
GSD has elaborate checkpoint types (human-verify, decision, action) with auto-mode bypasses. SpSk checkpoints are simpler: "Here's the review. Want to iterate?"

### 9.7 Git Integration (Optional)
GSD commits planning docs to git, manages branches per phase. SpSk reviews don't need git integration -- they're ephemeral assessment artifacts. Maybe optionally save to git but don't make it core.

### 9.8 Session Management (Not Needed)
GSD has pause-work, resume-work, session-report, continue-here patterns. SpSk reviews complete in one session -- no need for cross-session continuity.

### 9.9 Update Mechanism (Simpler)
GSD has elaborate update detection with npm checks, version comparison, changelog display. SpSk is a Claude Code skill, not an npm package -- updates come from pulling the skill repo, not npm.

---

## 10. Concrete SpSk Output Formatting Proposal

### Banner
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SpSk ► REVIEWING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Specialist Spawning
```
◆ Spawning 8 design specialists in parallel...
  → Font specialist
  → Color specialist
  → Layout specialist
  → Icon specialist
  → Motion specialist
  → Intent specialist
  → Copy specialist
  → Code specialist

✓ Font specialist complete: 1 critical, 2 minor issues
✓ Color specialist complete: 0 issues
...
```

### Review Score Box
```
╔══════════════════════════════════════════════════════════════╗
║  DESIGN REVIEW: {Page Name}                                  ║
╚══════════════════════════════════════════════════════════════╝

Score: ████████░░ 7.2/10  →  ITERATE

  Font:   ████████░░ 8.0    Color:  █████████░ 9.0
  Layout: ███████░░░ 7.0    Icon:   ████████░░ 8.0
  Motion: █████░░░░░ 5.0    Intent: ████████░░ 8.0
  Copy:   ████████░░ 8.0    Code:   ██████░░░░ 6.0
```

### Verdict
```
──────────────────────────────────────────────────────────────

## ▶ Verdict: ITERATE

**3 critical issues found:**
1. Motion: No loading states or transitions
2. Code: Missing aria labels on interactive elements
3. Layout: Content reflow at 768px breakpoint

`/spsk:improve` to auto-fix and re-review

──────────────────────────────────────────────────────────────
```

### Status Symbols (Reuse GSD Vocabulary)
```
SHIP    — Ready to ship (8.5+/10)
ITERATE — Needs work (6.0-8.4/10)
STOP    — Major issues (below 6.0/10)
```

---

## 11. Key Patterns Summary Table

| Pattern | GSD Approach | SpSk Recommendation |
|---------|-------------|---------------------|
| Branding | `GSD ►` prefix in banners | `SpSk ►` prefix in banners |
| Boxes | 62-char double-line Unicode | Same pattern, same width |
| Progress | `████████░░ 80%` | Per-dimension score bars |
| Status symbols | 6 Unicode symbols | Reuse same set |
| CLI tooling | `gsd-tools.cjs` monolith | `spsk-tools.cjs` (much smaller) |
| State dir | `.planning/` (10+ files) | `.design-reviews/` (config + results) |
| Config | JSON with layered defaults | Same pattern, fewer keys |
| Agents | 15 specialists with model profiles | 8 specialists (already defined) |
| Hooks | 5 lifecycle hooks | 1-2 at most (statusline, maybe context monitor) |
| Workflows | 56 workflow files | 3-5 workflow files |
| Questioning | Deep dream extraction | None (operates on existing UI) |
| Sessions | Pause/resume/report | Single-session (no continuity needed) |
| Updates | npm + background check + changelog | Git pull (skill, not npm package) |
| Git | Branch management, atomic commits | Optional (reviews are ephemeral) |
| Help | 600-line reference | One-screen compact reference |
