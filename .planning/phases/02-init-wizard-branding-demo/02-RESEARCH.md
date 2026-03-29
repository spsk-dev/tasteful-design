# Phase 2: Init Wizard + Branding + Demo - Research

**Researched:** 2026-03-28
**Domain:** Claude Code plugin UX -- interactive wizard, branded terminal output, terminal GIF recording
**Confidence:** HIGH

## Summary

Phase 2 transforms SpSk from a working tool into a portfolio piece through three distinct workstreams: (1) an init wizard using AskUserQuestion for 5 interactive questions that creates `.design/tokens.json` and `.design/config.json`, (2) a branded output system via `shared/output.md` reference file consumed by all commands, and (3) a demo GIF recorded with VHS and compressed with gifsicle.

The implementation is entirely markdown/JSON authoring -- no compiled code, no runtime dependencies beyond what Phase 1 already established. The init wizard follows Claude Code's existing AskUserQuestion pattern (which works correctly in current versions after a prior bug fix). The branding system is a reference file that commands load via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`. The demo GIF requires installing VHS and gifsicle, neither of which is currently available on the machine.

**Primary recommendation:** Build in three waves -- (1) palette engine data + shared branding reference, (2) init wizard command + router update, (3) branding integration across existing commands + demo GIF. This ordering ensures the branding reference exists before commands try to consume it.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-16:** `/design init` command uses AskUserQuestion for each of the 5 questions, consistent with Claude Code's interactive pattern.
- **D-17:** The 5 questions are exactly: (1) Page type (landing/dashboard/admin/docs/portfolio), (2) Vibe preset (minimal/bold/editorial/corporate/playful), (3) Mode (light/dark/both), (4) Brand colors (hex values or skip), (5) Font preference (or skip for vibe-based suggestion).
- **D-18:** Creates `.design/tokens.json` (colors, fonts, mode) + `.design/config.json` (page type, vibe preset). Minimal JSON format.
- **D-19:** When user skips brand colors (Q4), trigger palette engine to suggest 3 named palettes contextual to page type.
- **D-20:** When user skips font preference (Q5), suggest font based on selected vibe preset.
- **D-21:** Target under 2 minutes from command invocation to `.design/` directory created.
- **D-22:** Palette engine suggests 3 palettes with Design Identity names (e.g., "Midnight Corporate", "Warm Craft", "Pacific Minimal").
- **D-23:** Palettes are contextual -- different suggestions for dashboard vs landing page vs portfolio.
- **D-24:** Palette data lives in `config/palettes.json` -- a static lookup table indexed by page type, each with 3 named palette options.
- **D-25:** Each palette includes: primary, secondary, accent, background, foreground, muted colors in hex.
- **D-26:** Signature line format: ` SpSk  design-review  v1.0.0  ---  8 specialists  ·  tier 1` (dynamic version, specialist count, tier).
- **D-27:** Branding templates live in `shared/output.md` -- a reference file loaded by all commands via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`.
- **D-28:** Score display: `████████░░ 8.0/10` -- block characters with numeric value.
- **D-29:** Symbol vocabulary: checkmark (pass), cross (fail), diamond (in-progress), circle (pending), lightning (auto), warning.
- **D-30:** Unicode boxes for checkpoints and results (single-line borders, not double).
- **D-31:** Footer on every output: `github.com/felipemachado/spsk` -- subtle, always present.
- **D-32:** All existing commands (design, design-review, design-improve, design-validate) must be updated to use shared branding.
- **D-33:** Shows a full `/design-review` run on a real page -- specialists scoring, final verdict with branded output.
- **D-34:** Created with VHS tape file (charmbracelet/vhs) for reproducible terminal recording.
- **D-35:** Committed to `assets/demo.gif`, compressed with gifsicle to <5MB.
- **D-36:** README.md updated to embed the actual GIF replacing the placeholder.

### Claude's Discretion
- Exact palette names and color values -- Claude designs these based on color theory
- VHS tape file configuration and timing
- shared/output.md internal structure and template format
- Unicode box style details (which border characters exactly)
- Order of branding integration across commands

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INIT-01 | `/design init` command -- 5 interactive questions with opinionated defaults | AskUserQuestion pattern research, command frontmatter pattern from existing commands |
| INIT-02 | Question 1: Page type (landing, dashboard, admin, etc.) | Palette engine contextual mapping, style-presets.json alignment |
| INIT-03 | Question 2: Vibe preset selection from built-in options | Existing `config/style-presets.json` has 5 presets ready to reference |
| INIT-04 | Question 3: Light/dark/both preference | tokens.json schema design |
| INIT-05 | Question 4: Brand colors (or skip for palette suggestions) | Palette engine research, `config/palettes.json` structure |
| INIT-06 | Question 5: Font preference (or skip for vibe-based suggestion) | style-presets.json already maps vibes to font families |
| INIT-07 | Creates `.design/` directory with configured tokens | `design-system.example.json` establishes the token schema |
| INIT-08 | Under 2 minutes from command to first value | 5 questions with AskUserQuestion is inherently fast |
| PALT-01 | Suggest 3 color palettes when user skips brand colors | Static `config/palettes.json` lookup table design |
| PALT-02 | Palettes have Design Identity names | Color theory research for naming conventions |
| PALT-03 | Palettes are contextual -- different for dashboard vs landing | Page-type-indexed JSON structure |
| BRND-01 | Signature line format with dynamic version, specialist count, tier | shared/output.md template with interpolation markers |
| BRND-02 | Unicode boxes for checkpoints and results | Single-line box drawing characters (not double) |
| BRND-03 | Symbol vocabulary: checkmark, cross, diamond, circle, lightning, warning | Consistent with GSD's existing vocabulary |
| BRND-04 | Progress bars for scores (block characters) | Block character bar generation pattern |
| BRND-05 | Footer with repo link on every review output | shared/output.md footer template |
| BRND-06 | Consistent formatting across all SpSk commands | All 4 commands load `@${CLAUDE_PLUGIN_ROOT}/shared/output.md` |
| DEMO-01 | 30-second demo GIF showing design-review in action | VHS tape file format, gifsicle compression |
| DEMO-02 | GIF embedded in README.md replacing placeholder | README already has placeholder comment at line 7-8 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code AskUserQuestion | Built-in | Interactive wizard questions | Native tool, no dependencies |
| VHS (charmbracelet/vhs) | Latest via brew | Reproducible terminal GIF recording | Industry standard for CLI demo GIFs |
| gifsicle | Latest via brew | GIF compression to <5MB | Standard GIF optimizer |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | Installed | JSON validation for new config files | Structural eval checks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| VHS | asciinema + agg | VHS is scriptable via tape files, making demos reproducible; asciinema is interactive-only |
| gifsicle | ffmpeg | gifsicle is purpose-built for GIF optimization; ffmpeg is overkill |

**Installation (demo GIF tools only):**
```bash
brew install vhs gifsicle
```

VHS also requires `ttyd` and `ffmpeg` which it installs as dependencies via Homebrew.

## Architecture Patterns

### New Files to Create
```
commands/
  design-init.md       # Init wizard command (new)
shared/
  output.md            # Branding reference file (new)
config/
  palettes.json        # Palette engine lookup table (new)
assets/
  demo.tape            # VHS recording script (new)
  demo.gif             # Recorded/compressed demo (new)
```

### Modified Files
```
commands/
  design.md            # Add route for `init` subcommand
  design-review.md     # Add @shared/output.md reference
  design-improve.md    # Add @shared/output.md reference
  design-validate.md   # Add @shared/output.md reference
README.md              # Replace demo GIF placeholder with actual GIF
evals/validate-structure.sh  # Add checks for new files
```

### Pattern 1: Init Wizard Command (design-init.md)

**What:** A command markdown file with YAML frontmatter that uses AskUserQuestion 5 times sequentially, then writes two JSON files to `.design/` in the user's project.

**When to use:** When user runs `/design init` for the first time in a project.

**Structure:**
```markdown
---
name: design-init
description: >
  Interactive setup wizard -- 5 questions to configure design tokens for your project.
  Creates .design/ directory with tokens.json and config.json. Use when starting a new
  project or reconfiguring design preferences.
allowed-tools: Read, Write, Bash(mkdir *)
---

# Design Init -- Project Setup Wizard

## Flow

1. Ask page type (AskUserQuestion with 5 options)
2. Ask vibe preset (AskUserQuestion with 5 options)
3. Ask mode preference (AskUserQuestion with 3 options)
4. Ask brand colors (AskUserQuestion -- hex or skip)
5. If skipped: present 3 palettes from config/palettes.json for the page type
6. Ask font preference (AskUserQuestion -- name or skip)
7. If skipped: suggest font from style-presets.json based on vibe
8. Create .design/tokens.json and .design/config.json
```

**Key detail:** AskUserQuestion does NOT go in `allowed-tools` frontmatter. The bug where AskUserQuestion silently auto-completes when listed in allowed-tools was fixed, but the safest pattern is to omit it since it is always available by default.

### Pattern 2: Branding Reference File (shared/output.md)

**What:** A markdown reference file that all commands load via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`. Contains the branded output templates, symbol vocabulary, box-drawing patterns, and footer format.

**Structure concept:**
```markdown
# SpSk Branded Output Reference

## Signature Line
 SpSk  {command}  v{version}  ---  {specialist_count} specialists  ·  tier {tier}

Read version from ${CLAUDE_PLUGIN_ROOT}/VERSION.
Read specialist count from the review mode (8 for full, 4 for quick).
Read tier from the environment detection result.

## Score Bar
Format scores as block character bars:
- Each full block = 1 point on a 10-point display scale
- Score/4.0 mapped to 10 blocks: score * 2.5 = filled blocks
- Example: 3.2/4.0 = 8 filled blocks = ████████░░ 3.2/4.0

## Symbol Vocabulary
- Pass/complete: ✓
- Fail/missing: ✗
- In progress: ◆
- Pending: ○
- Auto-approved: ⚡
- Warning: ⚠

## Box Drawing (single-line borders)
Use these characters for boxes:
┌─────────────────────────────────┐
│  Content here                   │
└─────────────────────────────────┘

NOT double-line (D-30 specifies single-line):
WRONG: ╔═══╗ ║ ╚═══╝

## Footer
Every output ends with:
github.com/felipemachado/spsk
```

**Important distinction from GSD:** GSD uses double-line Unicode borders (see `.context/gsd-research.md` sections 2.2-2.4). SpSk uses single-line borders per D-30. This is an intentional differentiation.

### Pattern 3: Router Update (design.md)

**What:** Add `init` to the routing table in `design.md`.

**Change:**
```markdown
| `/design init` | `/design-init` | Interactive setup wizard |
```

### Pattern 4: Palette Engine (config/palettes.json)

**What:** Static JSON lookup table indexed by page type, each with 3 named palette options. No runtime code -- the init wizard command reads this file and presents options.

**Structure:**
```json
{
  "landing": [
    {
      "name": "Pacific Minimal",
      "primary": "#0F172A",
      "secondary": "#334155",
      "accent": "#3B82F6",
      "background": "#FFFFFF",
      "foreground": "#0F172A",
      "muted": "#94A3B8"
    },
    { "name": "Warm Craft", ... },
    { "name": "Bold Gradient", ... }
  ],
  "dashboard": [ ... ],
  "admin": [ ... ],
  "docs": [ ... ],
  "portfolio": [ ... ]
}
```

### Anti-Patterns to Avoid
- **Do NOT use double-line Unicode borders** -- D-30 explicitly says single-line. GSD uses double-line; SpSk differentiates.
- **Do NOT hardcode version in branding** -- Read from `${CLAUDE_PLUGIN_ROOT}/VERSION` dynamically.
- **Do NOT put AskUserQuestion in allowed-tools** -- It is always available; listing it can cause issues with permission evaluation.
- **Do NOT create `.design/` in the plugin directory** -- It goes in the user's project CWD, not in `${CLAUDE_PLUGIN_ROOT}`.
- **Do NOT make palette engine dynamic/computed** -- D-24 says static lookup table. Keep it simple.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Terminal GIF recording | Custom screenshot-to-GIF pipeline | VHS tape files | Reproducible, scriptable, community standard |
| GIF compression | Custom frame-dropping logic | gifsicle | Handles optimization, lossy compression, size targets |
| Interactive prompts | Custom input parsing | AskUserQuestion (built-in) | Native Claude Code tool, handles UI rendering |
| Color palette generation | Runtime color-theory algorithm | Static `config/palettes.json` | D-24 explicitly locked this as a static lookup |
| Version reading | Hardcoded string | Read `VERSION` file | Single source of truth already exists |

**Key insight:** This entire phase is markdown and JSON authoring. There is no compiled code to write. The "palette engine" is just a JSON file. The "branding system" is a markdown reference file. The complexity is in the content design, not the code.

## Common Pitfalls

### Pitfall 1: AskUserQuestion Empty Response
**What goes wrong:** AskUserQuestion silently returns empty when listed in a command's `allowed-tools` frontmatter.
**Why it happens:** Permission evaluator early-return bug (fixed in Claude Code 2.1.63+, issue #29547).
**How to avoid:** Do NOT list AskUserQuestion in the `allowed-tools` field of `design-init.md`. It is always available by default.
**Warning signs:** Wizard skips questions or proceeds with empty/default values without user interaction.

### Pitfall 2: Double vs Single Line Unicode Borders
**What goes wrong:** Using GSD-style double-line borders (the examples in `.context/gsd-research.md` all use double-line).
**Why it happens:** GSD research shows double-line as the pattern; easy to copy-paste.
**How to avoid:** D-30 explicitly says single-line. Use `┌─┐│└─┘` not `╔═╗║╚═╝`.
**Warning signs:** Review the shared/output.md file for any double-line characters.

### Pitfall 3: VHS/gifsicle Not Installed
**What goes wrong:** Demo GIF creation fails silently or produces poor quality output.
**Why it happens:** Neither VHS nor gifsicle is currently installed on this machine.
**How to avoid:** First task in the demo wave must be `brew install vhs gifsicle`. VHS also pulls in ttyd and ffmpeg as dependencies.
**Warning signs:** `command -v vhs` returns nothing.

### Pitfall 4: Vibe Preset Name Mismatch
**What goes wrong:** Init wizard Q2 offers vibe names that don't match `config/style-presets.json` keys.
**Why it happens:** D-17 lists vibes as "minimal/bold/editorial/corporate/playful" but style-presets.json has "serious-dashboard/fun-lighthearted/animation-heavy/minimal-editorial/startup-landing".
**How to avoid:** Map the human-friendly names to preset keys. Q2 should present the preset descriptions and map to the JSON keys internally.
**Warning signs:** Selected vibe doesn't resolve to a valid preset when used later.

### Pitfall 5: Score Bar Scale Confusion
**What goes wrong:** Inconsistent score display -- the review scores on 1-4 scale but the branded bar needs to render on a visual 10-block scale.
**Why it happens:** D-28 shows `████████░░ 8.0/10` but the actual scoring system uses 1.0-4.0.
**How to avoid:** Define the mapping clearly in shared/output.md: score/4.0 mapped to 10 blocks. A score of 3.2 = 8 filled blocks = `████████░░ 3.2/4.0`. The bar uses 10 blocks for visual clarity but the numeric value stays on the 4.0 scale.
**Warning signs:** Score bars that show `/10` instead of `/4.0`, or bars that don't match the numeric value.

### Pitfall 6: Demo GIF Size
**What goes wrong:** GIF exceeds 5MB limit (D-35) because a full design-review run produces extensive terminal output.
**Why it happens:** 8 specialist outputs + synthesis = a lot of text scrolling.
**How to avoid:** Use VHS `Hide`/`Show` commands to skip boring parts. Use `Set PlaybackSpeed` to speed up waiting. Use gifsicle `--lossy=80 --optimize=3 --colors 64` for aggressive compression. Target 720px width, not 1440px.
**Warning signs:** Raw GIF > 10MB before compression.

## Code Examples

### design-init.md Frontmatter Pattern
```markdown
---
name: design-init
description: >
  Interactive setup wizard for design tokens. Creates .design/ directory with
  tokens.json (colors, fonts, mode) and config.json (page type, vibe preset).
  Run once per project. Takes under 2 minutes.
allowed-tools: Read, Write, Bash(mkdir *)
---
```

Note: AskUserQuestion intentionally omitted from allowed-tools (always available by default).

### tokens.json Output Schema
```json
{
  "colors": {
    "primary": "#0F172A",
    "secondary": "#334155",
    "accent": "#3B82F6",
    "background": "#FFFFFF",
    "foreground": "#0F172A",
    "muted": "#94A3B8"
  },
  "fonts": {
    "primary": "Geist",
    "secondary": "Instrument Serif",
    "mono": "Geist Mono"
  },
  "mode": "dark"
}
```

### config.json Output Schema
```json
{
  "page_type": "landing",
  "vibe_preset": "startup-landing",
  "initialized": "2026-03-28T12:00:00Z"
}
```

### VHS Tape File Example (assets/demo.tape)
```
# SpSk Demo Recording
Output assets/demo.gif

Require claude

Set Shell bash
Set FontSize 14
Set FontFamily "Geist Mono"
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set TypingSpeed 50ms
Set Padding 20

# Show the command being typed
Type "claude '/design-review http://localhost:3000'"
Sleep 500ms
Enter

# Wait for output to appear (adjust timing based on actual run)
Sleep 30s

# Capture final state
Sleep 3s
```

### gifsicle Compression Command
```bash
gifsicle --lossy=80 --optimize=3 --colors 64 -o assets/demo.gif assets/demo-raw.gif
```

### Score Bar Rendering Logic (for shared/output.md)
```
Score bar format:
- 10 blocks total (filled + empty)
- Filled blocks: round(score / 4.0 * 10)
- Filled char: █  Empty char: ░
- Example: score 3.2 → 8 filled → ████████░░ 3.2/4.0
- Example: score 2.0 → 5 filled → █████░░░░░ 2.0/4.0
- Example: score 1.0 → 3 filled → ██░░░░░░░░ 1.0/4.0 (minimum 2-3 visible)
```

### Single-Line Unicode Box Pattern
```
┌──────────────────────────────────────────────────────────────┐
│  DESIGN REVIEW: Landing Page                                 │
└──────────────────────────────────────────────────────────────┘
```

### Signature Line Pattern
```
 SpSk  design-review  v1.0.0  ───  8 specialists  ·  tier 1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GSD double-line borders | SpSk single-line borders | Phase 2 decision (D-30) | Visual differentiation from GSD |
| No branding | Consistent branded output | Phase 2 | Every command output recognizably SpSk |
| No init wizard | 5-question setup | Phase 2 | Under 2 minutes to first configured review |
| README placeholder | Actual demo GIF | Phase 2 | README sells the tool visually |

**Deprecated/outdated:**
- AskUserQuestion bug (allowed-tools silent empty): Fixed in Claude Code 2.1.63+. No workaround needed in current versions.

## Open Questions

1. **VHS recording of actual Claude Code session**
   - What we know: VHS records terminal sessions with scriptable commands. D-33 says "shows a full /design-review run."
   - What's unclear: A real `/design-review` takes 8-10 minutes and requires a running dev server + Playwright + possibly Gemini. This cannot be captured in a 30-second GIF without significant time compression or a pre-recorded output.
   - Recommendation: Record the terminal output of a completed review (not a live run). Use VHS to simulate typing the command, then paste/type the pre-captured output with fast typing speed. Alternatively, use `Set PlaybackSpeed 10` to speed through a real run and trim with gifsicle. The tape file is the creative challenge here -- Claude should design the optimal approach.

2. **Vibe preset name mapping (D-17 vs style-presets.json)**
   - What we know: D-17 says "minimal/bold/editorial/corporate/playful" but style-presets.json uses "serious-dashboard/fun-lighthearted/animation-heavy/minimal-editorial/startup-landing".
   - What's unclear: Whether Q2 should show the human-friendly labels and map internally, or whether the preset keys should be renamed.
   - Recommendation: Show human-friendly labels in the wizard with descriptions, map to existing preset keys internally. Do not rename the preset keys (they are already used in Phase 1 commands).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Claude Code | All commands | Yes (assumed) | -- | -- |
| AskUserQuestion | Init wizard | Yes (built-in) | -- | -- |
| jq | Eval validation | Yes | -- | -- |
| VHS | Demo GIF recording | No | -- | Install via `brew install vhs` |
| gifsicle | Demo GIF compression | No | -- | Install via `brew install gifsicle` |
| ttyd | VHS dependency | Unknown | -- | Installed as VHS brew dependency |
| ffmpeg | VHS dependency | Unknown | -- | Installed as VHS brew dependency |

**Missing dependencies with no fallback:**
- VHS and gifsicle are required for DEMO-01/DEMO-02. Must be installed before the demo wave.

**Missing dependencies with fallback:**
- None. All other work (init wizard, branding, palette engine) is pure markdown/JSON authoring.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash + jq (structural validation via validate-structure.sh) |
| Config file | `evals/validate-structure.sh` |
| Quick run command | `./evals/validate-structure.sh` |
| Full suite command | `./evals/run-evals.sh` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INIT-01 | design-init.md exists with frontmatter | structural | `./evals/validate-structure.sh` (after adding check) | Needs Wave 0 |
| INIT-07 | .design/ directory structure | manual | Run `/design init` in test project | Manual only |
| INIT-08 | Under 2 minutes completion | manual | Time a real wizard run | Manual only |
| PALT-01 | config/palettes.json valid JSON with structure | structural | `jq empty config/palettes.json` | Needs Wave 0 |
| PALT-02 | Palettes have name field | structural | `jq -e '.[].[]|.name' config/palettes.json` | Needs Wave 0 |
| PALT-03 | Palettes indexed by page type | structural | `jq -e '.landing,.dashboard,.admin,.docs,.portfolio' config/palettes.json` | Needs Wave 0 |
| BRND-01 | shared/output.md exists | structural | `test -f shared/output.md` | Needs Wave 0 |
| BRND-06 | All commands reference shared/output.md | structural | `grep -l 'shared/output.md' commands/*.md` | Needs Wave 0 |
| DEMO-01 | assets/demo.gif exists and <5MB | structural | `test -f assets/demo.gif && [ $(stat -f%z assets/demo.gif) -lt 5242880 ]` | Needs Wave 0 |
| DEMO-02 | README.md contains GIF embed | structural | `grep -q 'demo.gif' README.md` | Needs Wave 0 |

### Sampling Rate
- **Per task commit:** `./evals/validate-structure.sh`
- **Per wave merge:** `./evals/validate-structure.sh` (same -- single structural test)
- **Phase gate:** Full structural validation green + manual wizard run confirms <2 minute flow

### Wave 0 Gaps
- [ ] Add `design-init.md` existence check to `validate-structure.sh`
- [ ] Add `shared/output.md` existence check to `validate-structure.sh`
- [ ] Add `config/palettes.json` validity check to `validate-structure.sh`
- [ ] Add `assets/demo.gif` existence + size check to `validate-structure.sh`
- [ ] Add `shared/output.md` reference check across all commands to `validate-structure.sh`

## Sources

### Primary (HIGH confidence)
- Project codebase: All existing commands, configs, and patterns read directly from `/Users/felipemachado/Sites/spsk/`
- `.context/gsd-research.md` -- GSD branded output patterns (sections 2.1-2.9)
- `.context/plan.md` -- 3-model consensus on branding approach
- `02-CONTEXT.md` -- All locked decisions D-16 through D-36

### Secondary (MEDIUM confidence)
- [VHS GitHub README](https://github.com/charmbracelet/vhs/blob/main/README.md) -- Tape file syntax, installation, settings
- [AskUserQuestion bug issue #29547](https://github.com/anthropics/claude-code/issues/29547) -- Confirmed fixed, explains the allowed-tools pitfall

### Tertiary (LOW confidence)
- Color palette design research (web search) -- Used for general guidance on palette structure, but actual palette values are Claude's discretion per CONTEXT.md

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no external libraries needed beyond VHS/gifsicle for demo
- Architecture: HIGH -- all patterns follow established Phase 1 conventions (markdown commands, JSON config, YAML frontmatter)
- Pitfalls: HIGH -- AskUserQuestion bug is documented with issue number, border style difference is explicitly called out in decisions
- Palette engine: MEDIUM -- the structure is locked (static JSON lookup), but the actual color values and names are Claude's discretion

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable -- no fast-moving dependencies)
