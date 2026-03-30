---
name: design
description: >
  Frontend design orchestrator — routes to review, validate, improve, or runs the full pipeline.
  Single entry point for all design quality commands. Use when the user says "design", "/design",
  "check the design", "ship this page", "full design check", "design pipeline", or any design-related
  request. Routes to the right sub-command based on arguments or asks what the user wants.
allowed-tools: Bash(gemini *), Bash(which *), Bash(npx *), Bash(python3 *), Bash(curl *), Bash(kill *), Bash(mkdir *), Bash(cp *), Bash(rm *), Bash(lsof *)
---

# Design — Frontend Quality Orchestrator

Single entry point for the design plugin. Routes to sub-commands or runs full pipelines.

@${CLAUDE_PLUGIN_ROOT}/shared/output.md

## Routing

Parse `$ARGUMENTS` and route:

| Command | Routes To | What It Does |
|---------|-----------|-------------|
| `/design init` | `/design-init` | Interactive setup wizard |
| `/design review` | `/design-review` | Visual review (7 specialists, supports --interact) |
| `/design review --quick` | `/design-review --quick` | Quick visual review (4 specialists) |
| `/design validate` | `/design-validate` | Functional validation (click, test, verify) |
| `/design improve "prompt"` | `/design-improve` | Build & iterate until SHIP |
| `/design ship` | Full pipeline | improve → review → validate → done |
| `/design check` | Review + validate | Visual review + functional validation |
| `/design audit` | `/design-audit` | Flow audit (navigate + capture) |
| `/design audit <url> --flow "desc"` | `/design-audit` | Intent-guided flow audit |
| `/design audit <url> --steps u1,u2` | `/design-audit` | Deterministic flow audit |
| `/design` (no args) | Ask user | Show available commands and ask what they want |

All flags pass through: `--ref`, `--figma`, `--compare`, `--direction`, `--palette`, `--fonts`, `--quick`, `--max N`, `--validate`, `--flow`, `--steps`, `--auth`, `--max-screens`, `--interact`.

## `/design ship` — Full Production Pipeline

The most thorough workflow. Runs everything in sequence:

```
Phase 1: Build (if prompt provided) or identify target page
  → Read source, detect dev server, or build from prompt
  → Apply anti-slop defaults from config/anti-slop.json

Phase 2: Improve Loop (/design-improve --validate)
  → Build → Review → Fix → Validate → Re-review → ... → SHIP
  → Runs up to --max iterations (default 3)
  → Each iteration: visual review + functional validation

Phase 3: Final Review (/design-review — full 7 specialists)
  → Even if improve loop reached SHIP, run a clean final review
  → This is the review of record

Phase 4: Final Validation (/design-validate)
  → Full functional check on the final page
  → Every button, link, form, interactive element

Phase 5: Ship Report
  → Score progression from improve loop
  → Final review summary
  → Validation status
  → Remaining items (if any)
  → Files produced
```

**Example:**
```
/design ship "Build a billing settings page for FlowMetrics" --ref https://stripe.com/billing --max 3
```

This will:
1. Build the page using Stripe billing as reference, avoiding anti-slop patterns
2. Run 3 iterations of review→fix→validate
3. Final 8-specialist review
4. Final functional validation
5. Ship report with score progression

## `/design check` — Quick Pre-merge Check

Lighter than `ship` — just reviews and validates the current page without building or iterating:

```
Phase 1: /design-review (full 7 specialists)
Phase 2: /design-validate (functional check)
Phase 3: Combined report
```

**Example:**
```
/design check http://localhost:3000/settings
```

## `/design` (no arguments) — Show Menu

If the user runs `/design` with no arguments, show this:

```
Design Plugin — Frontend Quality Framework

Commands:
  /design review       Visual review (7 specialists, weighted scoring)
  /design review --quick  Quick review (4 specialists)
  /design validate     Functional validation (buttons, links, forms, errors)
  /design improve      Build & iterate until SHIP
  /design audit        Flow audit (navigate SPA + capture per screen)
  /design check        Review + validate (pre-merge check)
  /design ship         Full pipeline (improve → review → validate)

Flags (work with any command):
  --ref <url|file|figma>   Compare against a reference
  --figma <url>            Review Figma design or check fidelity (add --compare)
  --direction "text"       Evaluate against a creative brief
  --palette "colors"       Enforce specific color palette
  --fonts "Font1,Font2"    Enforce specific fonts
  --quick                  Use 4 specialists instead of 8
  --max N                  Max iterations for improve/ship (default 3)
  --validate               Run functional validation each iteration
  --flow "description"     Flow intent for audit (what the user journey achieves)
  --steps u1,u2,u3         Deterministic URL sequence for audit
  --auth                   Authenticated flow (pause for manual login)
  --max-screens N          Max screens to capture in audit (default 10)
  --interact               Capture hover/focus/scroll states before review

What would you like to do?
```

## Parallel Execution

When running `ship` or `check`, some phases can run in parallel:

- **`/design check`**: Review and validate can run IN PARALLEL (they don't depend on each other). Dispatch both as background agents and merge results.
- **`/design ship`**: The improve loop is sequential (each iteration depends on the previous). But within each iteration, the review specialists run in parallel (they already do). Final review and final validation can run in parallel.

## Integration with Other Workflows

The design plugin can be called from other skills/workflows:

```
# From /design-improve after building
/design review --quick    # fast check during iteration
/design validate          # verify nothing broke

# From a ticket workflow
/design ship "implement the Figma design" --figma https://figma.com/...

# From a PR review
/design check             # pre-merge quality gate

# From a ralph loop
/design ship "build X" --max 5  # keep iterating
```

## Error Handling

- If no dev server and no HTML file found: ask user for a URL or file path
- If Playwright not installed: warn and offer to install (`npx playwright install chromium`)
- If Gemini unavailable: fall back to Tier 2 (Claude-only) — note in output
- If page intent unclear: ask user before proceeding (don't guess)
- If a sub-command fails: report which phase failed and why, suggest retry
