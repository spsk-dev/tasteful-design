# Phase 2: Init Wizard + Branding + Demo - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the first-run experience (init wizard with 5 questions), branded output system for all commands, and a demo GIF for the README. This transforms SpSk from a working tool into a portfolio piece. No changes to the core review logic — only user-facing polish.

</domain>

<decisions>
## Implementation Decisions

### Init Wizard
- **D-16:** `/design init` command uses AskUserQuestion for each of the 5 questions, consistent with Claude Code's interactive pattern.
- **D-17:** The 5 questions are exactly: (1) Page type (landing/dashboard/admin/docs/portfolio), (2) Vibe preset (minimal/bold/editorial/corporate/playful), (3) Mode (light/dark/both), (4) Brand colors (hex values or skip), (5) Font preference (or skip for vibe-based suggestion).
- **D-18:** Creates `.design/tokens.json` (colors, fonts, mode) + `.design/config.json` (page type, vibe preset). Minimal JSON format.
- **D-19:** When user skips brand colors (Q4), trigger palette engine to suggest 3 named palettes contextual to page type.
- **D-20:** When user skips font preference (Q5), suggest font based on selected vibe preset.
- **D-21:** Target under 2 minutes from command invocation to `.design/` directory created.

### Palette Engine
- **D-22:** Palette engine suggests 3 palettes with Design Identity names (e.g., "Midnight Corporate", "Warm Craft", "Pacific Minimal").
- **D-23:** Palettes are contextual — different suggestions for dashboard vs landing page vs portfolio.
- **D-24:** Palette data lives in `config/palettes.json` — a static lookup table indexed by page type, each with 3 named palette options.
- **D-25:** Each palette includes: primary, secondary, accent, background, foreground, muted colors in hex.

### Branded Output
- **D-26:** Signature line format: ` SpSk  design-review  v1.0.0  ───  8 specialists  ·  tier 1` (dynamic version, specialist count, tier).
- **D-27:** Branding templates live in `shared/output.md` — a reference file loaded by all commands via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`.
- **D-28:** Score display: `████████░░ 8.0/10` — block characters with numeric value.
- **D-29:** Symbol vocabulary: ✓ (pass), ✗ (fail), ◆ (in-progress), ○ (pending), ⚡ (auto), ⚠ (warning).
- **D-30:** Unicode boxes for checkpoints and results (single-line borders, not double).
- **D-31:** Footer on every output: `github.com/felipemachado/spsk` — subtle, always present.
- **D-32:** All existing commands (design, design-review, design-improve, design-validate) must be updated to use shared branding.

### Demo GIF
- **D-33:** Shows a full `/design-review` run on a real page — specialists scoring, final verdict with branded output.
- **D-34:** Created with VHS tape file (charmbracelet/vhs) for reproducible terminal recording.
- **D-35:** Committed to `assets/demo.gif`, compressed with gifsicle to <5MB.
- **D-36:** README.md updated to embed the actual GIF replacing the placeholder.

### Claude's Discretion
- Exact palette names and color values — Claude designs these based on color theory
- VHS tape file configuration and timing
- shared/output.md internal structure and template format
- Unicode box style details (which border characters exactly)
- Order of branding integration across commands

</decisions>

<canonical_refs>
## Canonical References

### Source Files (modify)
- `commands/design.md` — add branded output
- `commands/design-review.md` — add branded output, score bars
- `commands/design-improve.md` — add branded output
- `commands/design-validate.md` — add branded output
- `README.md` — embed demo GIF
- `config/style-presets.json` — vibe presets referenced by init wizard

### New Files (create)
- `commands/design-init.md` — the init wizard command
- `shared/output.md` — branding reference file
- `config/palettes.json` — palette engine lookup table
- `assets/demo.tape` — VHS recording script
- `assets/demo.gif` — recorded demo

### Context
- `.context/plan.md` — original branding spec with symbol vocabulary
- `.context/gsd-research.md` — GSD formatting patterns to borrow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `config/style-presets.json` — already has 5 vibe presets with descriptions
- `commands/design.md` — orchestrator that routes to init/review/improve/validate
- Phase 1 created all 4 commands, README, CLAUDE.md — ready for branding overlay

### Established Patterns
- Commands use YAML frontmatter with `description:` and `argument-hint:` fields
- Config is JSON-based in `config/` directory
- References loaded via `@${CLAUDE_PLUGIN_ROOT}/path` syntax
- `design.md` is the router — `/design init` should route through it

### Integration Points
- `design.md` needs a new route for `init` subcommand
- All 4 commands need `@${CLAUDE_PLUGIN_ROOT}/shared/output.md` reference added
- `.design/` directory is user-project-level (created in CWD, not plugin directory)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-init-wizard-branding-demo*
*Context gathered: 2026-03-29*
