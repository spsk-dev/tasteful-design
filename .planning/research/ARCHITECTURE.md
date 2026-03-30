# Architecture Patterns: v1.2.0 Integration

**Domain:** Prompt engineering overhaul, quality evals, structured output, aesthetics integration, Playwright interaction, specialist consolidation for existing zero-dependency Claude Code plugin
**Researched:** 2026-03-29
**Confidence:** HIGH (based on direct codebase analysis + Anthropic official docs)

## Executive Summary

v1.2.0 adds six capabilities to an existing markdown-based plugin with zero npm dependencies. The architecture challenge is integrating these capabilities without breaking the zero-dependency principle, without bloating the 732-line design-review.md or 1274-line design-audit.md monoliths, and without invalidating the existing eval system.

The core insight: **all six changes are either prompt-level or config-level changes**. None require new runtime dependencies. The most structurally complex change (Layer 2 evals) needs only bash + jq + claude CLI, which are already prerequisites. The specialist merge (8 to 7) is the riskiest because it cascades through scoring.json, all command files, ARCHITECTURE.md, README.md, shared/output.md, and the eval assertions.

## Existing Architecture Summary

```
commands/
  design-review.md      732 lines — Phase 0-5 + 8 specialist prompts inline
  design-audit.md       1274 lines — Flow navigation + per-screen review
  design-improve.md     197 lines — Build/review/fix loop
  design-validate.md    ~200 lines — Functional testing
  design.md             160 lines — Router

config/
  scoring.json          Weights (17 total), thresholds, verdict rules
  flow-scoring.json     Flow navigation and scoring config
  anti-slop.json        Banned fonts/palettes/patterns
  style-presets.json    5 built-in style presets

skills/design-review/references/
  typography.md, color.md, layout.md, icons.md, motion.md, intent.md
  visual-design-rules.md, flow.md, animation.md, consistency.md

evals/
  validate-structure.sh   Layer 1 — file existence, JSON validity, semver
  run-evals.sh            Orchestrator — Layer 1 + placeholder Layer 2
  assertions.json         12 range-based assertions (never executed)
  fixtures/               3 HTML pages + flow-test + report-test

shared/output.md         Branded output format (signature line, score bars, boxes)
```

**Key constraint:** Everything is markdown prompts, JSON configs, and bash scripts. No node_modules, no build step, no package.json. This MUST be preserved.

---

## Integration 1: Prompt Restructuring for Testability

### Problem

Specialist prompts are embedded inline in design-review.md (lines 319-548) and design-audit.md (duplicated inline). This means:
- Prompts cannot be tested independently
- Changes require editing massive monolith files
- No version control granularity (a typo fix to the Font prompt shows as a change to all 732 lines)
- The improve loop in design-improve.md references the review command, not the prompts directly

### Recommended Architecture: Extract Prompts to Reference Files

Move each specialist's prompt to a dedicated file alongside its existing reference knowledge.

```
skills/design-review/
  references/
    typography.md          EXISTING — domain knowledge
    color.md               EXISTING — domain knowledge
    ...
  prompts/                 NEW — one file per specialist + boss
    specialist-font.md     Extracted from design-review.md lines 319-344
    specialist-color.md    Extracted from design-review.md lines 346-373
    specialist-layout.md   Extracted from design-review.md lines 375-400
    specialist-icon.md     Extracted from design-review.md lines 402-427
    specialist-motion.md   Extracted from design-review.md lines 429-452
    specialist-intent.md   Extracted from design-review.md lines 454-497
    specialist-copy.md     Extracted from design-review.md lines 499-523
    specialist-code.md     Extracted from design-review.md lines 525-548
    boss-synthesizer.md    Extracted from design-review.md Phase 3
    page-brief.md          Extracted from design-review.md Phase 1
  schemas/                 NEW — output format definitions
    specialist-output.md   JSON schema for specialist responses
    boss-output.md         JSON schema for boss synthesizer
```

**How design-review.md changes:**

```markdown
### Specialist 1: Font (Claude Sonnet Agent)
@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/specialist-font.md
```

The command file becomes orchestration-only: Phase 0 (screenshots), Phase 1 (brief), Phase 2 (dispatch with `@` includes), Phase 3 (synthesis with `@` include). Each specialist prompt is now a standalone testable artifact.

### Prompt Structure Standard

Every extracted prompt file follows this structure, aligned with Anthropic's official best practices:

```markdown
# {Specialist Name} Specialist

<role>
You are a {domain} specialist evaluating frontend design quality.
Your evaluation serves the page's intent — not generic standards.
</role>

<context>
PAGE CONTEXT (evaluate your domain in service of this intent):
{PAGE_BRIEF injection point}

{DESIGN_SYSTEM injection point — if .design/ exists}
{STYLE_PRESET injection point — if preset active}
{REFERENCE injection point — if --ref provided}
</context>

<reference_knowledge>
@${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/{domain}.md
</reference_knowledge>

<instructions>
REVIEW:
- {Dimension 1}: {specific criteria}
- {Dimension 2}: {specific criteria}
...

FLAG SPECIFICALLY: {concrete anti-patterns}

Find at least 2 issues. "Looks great" is not allowed.
</instructions>

<output_format>
Return your evaluation as JSON inside <specialist_output> tags:
{schema from schemas/specialist-output.md}
</output_format>

<examples>
{1-2 few-shot examples showing expected output quality}
</examples>
```

**Why this structure:**
- `<role>` sets the specialist identity (Anthropic best practice: "Give Claude a role")
- `<context>` separates dynamic inputs from static instructions (Anthropic: "Structure prompts with XML tags")
- `<reference_knowledge>` via `@` include loads domain expertise without bloating the prompt file
- `<instructions>` provides clear sequential criteria (Anthropic: "Be clear and direct")
- `<output_format>` constrains output to parseable JSON (see Integration 3)
- `<examples>` provides few-shot examples (Anthropic: "Include 3-5 examples for best results" -- 1-2 is pragmatic for token budget)

### Impact on design-audit.md

design-audit.md currently has its own per-screen specialist dispatch (Section 10) that duplicates the specialist prompts from design-review.md with minor modifications (flow context injection). After extraction, both commands `@` include the same prompt files and inject their respective contexts:

```markdown
## Per-Screen Specialist Dispatch

For each screen, inject flow context then dispatch:

FLOW CONTEXT INJECTION:
- Screen {N} of {total} in "{flow_intent}" flow
- Previous: {previous screen summary}
- Next: {expected next screen}

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/specialist-font.md
```

### Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `skills/design-review/prompts/*.md` | NEW (10 files) | Extracted specialist + boss + brief prompts |
| `skills/design-review/schemas/specialist-output.md` | NEW | JSON output schema definition |
| `skills/design-review/schemas/boss-output.md` | NEW | Boss synthesizer output schema |
| `commands/design-review.md` | MODIFIED | Replace inline prompts with `@` includes |
| `commands/design-audit.md` | MODIFIED | Replace inline prompts with `@` includes |

### Build Dependency

None -- this is pure file reorganization. Can be done first because all other changes depend on well-structured prompts.

---

## Integration 2: Layer 2 Quality Evals

### Problem

Layer 2 evals exist as a concept (assertions.json has 12 assertions, run-evals.sh has a placeholder) but have never been executed. The current run-evals.sh prints `[TODO] Quality eval execution will be implemented when plugins can be invoked programmatically` and exits.

The challenge: how to run `/design-review` against fixture HTML pages and assert on the output -- all in bash, with zero dependencies, and without requiring interactive Claude Code sessions.

### Recommended Architecture: claude CLI as Eval Runner

The `claude` CLI (Claude Code's command-line interface) can be invoked non-interactively:

```bash
claude --print "Run /design-review on this page: http://localhost:8787/admin-panel.html"
```

This runs the entire plugin pipeline (screenshots, specialists, boss synthesis) and captures the output. The eval script then parses the output for scores and verdicts.

**Eval execution flow:**

```
evals/run-quality-evals.sh
  |
  +-- Start HTTP server for fixtures
  |     python3 -m http.server 8787 --directory evals/fixtures/
  |
  +-- For each assertion in assertions.json:
  |     |
  |     +-- Run claude --print "Run /design-review ..."
  |     +-- Capture output to evals/results/{fixture}-{timestamp}.txt
  |     +-- Parse output with bash/jq:
  |     |     - Extract weighted score (regex: "Score: X.X/4.0")
  |     |     - Extract per-dimension scores (regex: "| {Dimension} | {score}/4")
  |     |     - Extract verdict (regex: "Verdict: SHIP|CONDITIONAL|BLOCK")
  |     +-- Compare against assertion ranges (jq arithmetic)
  |     +-- Report PASS/FAIL per assertion
  |
  +-- Stop HTTP server
  +-- Write results summary to evals/results/quality-{timestamp}.json
```

### New Files

```
evals/
  run-quality-evals.sh    NEW — Layer 2 eval runner (bash)
  parse-review-output.sh  NEW — Extract scores/verdicts from review text
  assertions.json         MODIFIED — add structured output parsing support
  results/                EXISTING — eval output directory
```

### parse-review-output.sh Design

This is the critical component. It must extract structured data from the review's terminal output. With structured JSON output from specialists (Integration 3), this becomes more reliable:

```bash
#!/usr/bin/env bash
# Parse design-review output and extract scores

INPUT_FILE="$1"

# Strategy 1: Parse JSON blocks if present (v1.2.0+ structured output)
# Look for <specialist_output> or <boss_output> JSON blocks
JSON_BLOCKS=$(grep -Pzo '<specialist_output>.*?</specialist_output>' "$INPUT_FILE" 2>/dev/null || true)
if [ -n "$JSON_BLOCKS" ]; then
  # Parse structured output -- most reliable
  echo "$JSON_BLOCKS" | jq -s '...'
  exit 0
fi

# Strategy 2: Parse terminal table output (v1.0/v1.1 format)
# Match: "| Typography | 3.0/4 | 2x | ..."
SCORES=$(grep -E '^\| .+ \| [0-9.]+/4 \|' "$INPUT_FILE" | awk -F'|' '{
  gsub(/^[ \t]+|[ \t]+$/, "", $2);
  gsub(/^[ \t]+|[ \t]+$/, "", $3);
  gsub(/\/4/, "", $3);
  print "\"" $2 "\": " $3
}')

VERDICT=$(grep -oE 'Verdict: (SHIP|CONDITIONAL SHIP|BLOCK)' "$INPUT_FILE" | head -1 | cut -d: -f2 | xargs)
OVERALL=$(grep -oE 'Score: [0-9.]+/4.0' "$INPUT_FILE" | head -1 | grep -oE '[0-9.]+' | head -1)

jq -n --arg verdict "$VERDICT" --arg overall "$OVERALL" \
  "{verdict: \$verdict, overall: (\$overall | tonumber), dimensions: {$SCORES}}"
```

### Assertions.json Enhancement

The existing assertions.json already has the right structure (fixture, dimension, min/max ranges). Add a `parse_mode` field to handle both old and new output formats:

```json
{
  "version": "2.0.0",
  "parse_mode": "structured",
  "assertions": [
    {
      "fixture": "fixtures/admin-panel.html",
      "name": "Admin panel gets mid-range overall score",
      "dimension": "overall",
      "min": 2.0,
      "max": 3.2
    }
  ]
}
```

### Eval Reliability Considerations

LLM output is non-deterministic. Mitigation:
1. **Wide ranges** in assertions (already present -- e.g., min 2.0, max 3.2)
2. **Run each assertion 3 times**, take median score (configurable via `--runs N`)
3. **JSON output mode** (Integration 3) makes parsing reliable
4. **Fixture design** -- make fixtures clearly good or clearly bad, not borderline

### Build Dependency

Depends on: Integration 3 (structured output) for reliable parsing. Can use regex-based parsing initially, upgrade to JSON parsing after structured output lands.

---

## Integration 3: Structured JSON Output from Specialists

### Problem

Specialists currently return free-text findings. The improve loop in design-improve.md must regex-parse "fix lists" from this text. The eval system must regex-parse scores from terminal tables. The report generator (generate-report.sh) reads flow-state.json which is manually constructed by the orchestrator interpreting free-text.

### Recommended Architecture: XML-Wrapped JSON in Specialist Prompts

Since this is a Claude Code plugin (markdown prompts executed by Claude), we cannot use the Anthropic API's `structured_outputs` feature (that requires API-level schema enforcement). Instead, use Anthropic's recommended prompt-level technique: XML tags wrapping JSON output.

**Specialist output schema** (new file: `skills/design-review/schemas/specialist-output.md`):

```markdown
# Specialist Output Schema

Return your evaluation inside <specialist_output> tags as valid JSON:

<specialist_output>
{
  "specialist": "{specialist_name}",
  "dimension": "{primary_dimension}",
  "score": {1.0-4.0},
  "scores": {
    "{dimension_1}": {1.0-4.0},
    "{dimension_2}": {1.0-4.0}
  },
  "findings": [
    {
      "severity": "critical|high|medium|low",
      "description": "{what is wrong}",
      "element": "{CSS selector or component name}",
      "file_line": "{file:line or null}",
      "fix": "{specific action to take}",
      "specialists_agree": []
    }
  ],
  "summary": "{one-line assessment}"
}
</specialist_output>

IMPORTANT: The JSON must be valid. Do not include comments or trailing commas.
Do not wrap in markdown code fences. Just the raw JSON inside the XML tags.
```

**Boss synthesizer output schema** (new file: `skills/design-review/schemas/boss-output.md`):

```markdown
# Boss Synthesizer Output Schema

After merging all specialist findings, return inside <boss_output> tags:

<boss_output>
{
  "scores": {
    "intent_match": {1.0-4.0},
    "originality": {1.0-4.0},
    "ux_flow": {1.0-4.0},
    "typography": {1.0-4.0},
    "color": {1.0-4.0},
    "layout": {1.0-4.0},
    "icons": {1.0-4.0},
    "motion": {1.0-4.0},
    "copy": {1.0-4.0},
    "code_a11y": {1.0-4.0}
  },
  "weighted_score": {1.0-4.0},
  "display_score": {2.5-10.0},
  "verdict": "SHIP|CONDITIONAL|BLOCK",
  "page_type": "{type}",
  "threshold": {threshold},
  "cross_specialist_findings": [
    {
      "description": "{merged finding}",
      "specialists": ["{specialist1}", "{specialist2}"],
      "confidence": "HIGH",
      "severity": "critical|high|medium"
    }
  ],
  "top_fixes": [
    {
      "priority": 1,
      "severity": "critical|high|medium",
      "description": "{what to fix}",
      "file_line": "{file:line or null}",
      "specialists": ["{who found it}"]
    }
  ],
  "what_works": ["{earned praise 1}", "{earned praise 2}"]
}
</boss_output>
```

### How This Integrates with Existing Flow

The orchestrator (design-review.md) currently reads specialist responses as free text and manually extracts scores. With structured output:

1. Each specialist returns `<specialist_output>` JSON
2. The orchestrator collects all specialist JSON blocks
3. The boss synthesizer receives the raw JSON (not free text) for merging
4. The boss returns `<boss_output>` JSON
5. The orchestrator renders the branded terminal output from the JSON (score bars, boxes, verdicts)
6. The `<boss_output>` JSON is also available to:
   - `design-improve.md` for programmatic fix list consumption
   - `parse-review-output.sh` for eval assertion checking
   - `generate-report.sh` for report data (via flow-state.json enrichment)

### Backward Compatibility

The branded terminal output (score bars, boxes from shared/output.md) is STILL rendered. The JSON is the machine-readable layer underneath. Users see the same formatted output. Downstream tools get parseable JSON.

The design-review.md orchestrator does both:
```markdown
After collecting all specialist outputs:
1. Parse <specialist_output> JSON blocks from each specialist response
2. Feed parsed JSON to boss synthesizer
3. Render branded terminal output using shared/output.md format from boss JSON
4. The <boss_output> JSON is available for downstream tools
```

### Impact on design-improve.md

Currently, design-improve.md reads the "Top 5 Fixes" section from the review output as text. With structured output, it reads the `top_fixes` array from `<boss_output>`:

```markdown
## Phase C: Apply Fixes

Read the <boss_output> JSON from the previous review.
Apply fixes from the top_fixes array in priority order:
1. All fixes with severity "critical"
2. Top 2-3 fixes with severity "high"

Each fix includes file_line and description -- go to the exact location.
```

### Impact on generate-report.sh

The report generator currently reads flow-state.json which the design-audit.md orchestrator populates by interpreting free-text specialist output. With structured output, the orchestrator writes the specialist JSON directly into flow-state.json:

```json
{
  "screens": [
    {
      "number": 1,
      "review": {
        "specialist_outputs": [...],
        "boss_output": {...}
      }
    }
  ]
}
```

generate-report.sh then uses jq to extract scores, findings, and fixes from the structured JSON instead of attempting to parse free text.

### Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `skills/design-review/schemas/specialist-output.md` | NEW | Specialist JSON schema |
| `skills/design-review/schemas/boss-output.md` | NEW | Boss synthesizer JSON schema |
| `skills/design-review/prompts/*.md` | MODIFIED | Add `<output_format>` section with schema |
| `commands/design-review.md` | MODIFIED | Parse JSON, render from JSON |
| `commands/design-improve.md` | MODIFIED | Consume top_fixes array |
| `commands/design-audit.md` | MODIFIED | Write specialist JSON to flow-state.json |

### Build Dependency

Depends on: Integration 1 (prompt extraction) -- schemas are referenced from extracted prompt files. Should be built alongside prompt extraction since the output format is part of the prompt.

---

## Integration 4: Anthropic Aesthetics Generation Prompt

### Problem

The `/design-improve` command builds pages that look AI-generated. Anthropic's official `frontend-design` plugin (277K+ installs) has a proven DISTILLED_AESTHETICS_PROMPT that steers Claude toward distinctive design choices. This prompt needs to be integrated as generation guidance, not review criteria.

### Key Distinction: Generation vs Evaluation

The aesthetics prompt is for **building pages** (design-improve.md). It is NOT for reviewing pages (design-review.md). These are different operations with different prompts:

| Concern | Generation (improve) | Evaluation (review) |
|---------|---------------------|---------------------|
| Goal | Build distinctive pages | Score existing pages honestly |
| Prompt style | Prescriptive ("DO use...") | Diagnostic ("CHECK for...") |
| Anti-slop role | Avoid generating patterns | Detect patterns in output |
| Aesthetics prompt | Full generation guidance | Partial -- only as detection criteria |

### Recommended Architecture: Generation Reference File

Create a new reference file that distills the Anthropic aesthetics prompt into generation-time guidance, adapted for the design-review plugin context:

```
skills/design-review/references/
  generation.md     NEW — Aesthetics generation guidance
```

**generation.md content structure:**

```markdown
# Generation Aesthetics Reference

This reference is loaded by /design-improve during page building (Phase A).
It is NOT for review evaluation — the review specialists have their own criteria.

## Design Thinking (Before Coding)

Before writing any HTML/CSS:
1. What is this page's PURPOSE? (from user prompt)
2. What TONE fits? Pick one: {brutalist, maximalist, retro-futuristic, organic,
   luxury, playful, editorial, art-deco, industrial, etc.}
3. What makes this UNFORGETTABLE? One distinctive element to remember.

## Typography
- Choose fonts that are beautiful, unique, and interesting
- Avoid: Inter, Roboto, Arial, system fonts, Space Grotesk
- Pair a distinctive display font with a refined body font
- Source from Google Fonts: {curated list of underused fonts}

## Color & Theme
- Commit to a cohesive aesthetic with CSS variables
- Dominant color + sharp accents > timid even distribution
- Draw from IDE themes, cultural aesthetics, period design

## Motion
- Focus on high-impact moments: one well-orchestrated page load
- Staggered reveals via animation-delay create more delight than scattered micro-interactions
- Scroll-triggering and hover states that surprise

## Spatial Composition
- Unexpected layouts: asymmetry, overlap, diagonal flow, grid-breaking
- Generous negative space OR controlled density — never bland middle

## Backgrounds & Atmosphere
- Create depth: gradient meshes, noise textures, geometric patterns
- Layered transparencies, dramatic shadows, grain overlays
- NEVER default to solid white or solid dark background
```

### How design-improve.md Integrates

Currently, Phase A of design-improve.md reads anti-slop.json and style-presets.json before building. Add the generation reference:

```markdown
## Phase A: Build or Receive the Page

Before building, read these in order:
1. Style preset: ${CLAUDE_PLUGIN_ROOT}/config/style-presets.json
2. Anti-slop rules: ${CLAUDE_PLUGIN_ROOT}/config/anti-slop.json
3. Generation aesthetics: ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/generation.md

Apply generation aesthetics FIRST (the creative vision), then constrain with
anti-slop (what to avoid), then align with style preset (if active).
```

### Selective Backport to Review Specialists

Some aesthetics criteria are also relevant for evaluation. The Intent/Originality specialist already checks for "AI slop" — the generation.md patterns can strengthen its detection criteria. This is a PARTIAL backport, not a wholesale import:

Add to `references/intent.md` under "AI Slop Detection":
```markdown
## Additional AI Convergence Patterns (from Anthropic research)
- Space Grotesk as default display font across generations
- Solid white/dark backgrounds with no atmosphere or depth
- Timid, evenly-distributed palettes instead of dominant + accent
- Uniform border-radius and padding across all elements
- Missing scroll-triggered interactions on long pages
```

### Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `skills/design-review/references/generation.md` | NEW | Aesthetics generation guidance |
| `commands/design-improve.md` | MODIFIED | Add generation.md read in Phase A |
| `skills/design-review/references/intent.md` | MODIFIED | Add convergence pattern detection |

### Build Dependency

Independent -- can be built in parallel with other integrations. No structural dependencies.

---

## Integration 5: Playwright Interaction Before Scoring

### Problem

Specialists currently evaluate from static screenshots (desktop, mobile, fold). They cannot see hover states, dropdown menus, focus rings, transition animations, loading states, or scroll-triggered effects. The Motion specialist evaluates code-only. This misses runtime visual behavior.

### Recommended Architecture: Interaction Phase Between Screenshots and Specialist Dispatch

Insert a new Phase 0.5 (or extend Phase 0) that uses Playwright MCP to interact with the page and capture interaction-state screenshots:

```
Phase 0:   Static screenshots (desktop, mobile, fold) — EXISTING
Phase 0.7: Interaction screenshots (hover, focus, scroll) — NEW
Phase 1:   Page brief — EXISTING
Phase 2:   Specialist dispatch (receives ALL screenshots) — MODIFIED
```

### Interaction Capture Protocol

```markdown
## Phase 0.7: Interaction Screenshots

After static screenshots, interact with the page to capture dynamic states.
Use Playwright MCP tools (browser_navigate already done in Phase 0).

### 0.7a. Hover states
- Identify primary CTA button via browser_snapshot
- browser_hover on the CTA
- browser_take_screenshot -> {REVIEW_DIR}/hover-cta.png

### 0.7b. Focus states
- browser_click on first input field (if form present)
- browser_take_screenshot -> {REVIEW_DIR}/focus-input.png

### 0.7c. Scroll state
- browser_evaluate: window.scrollTo(0, document.body.scrollHeight * 0.5)
- Wait 500ms for scroll-triggered animations
- browser_take_screenshot -> {REVIEW_DIR}/scroll-mid.png

### 0.7d. Mobile menu (if present)
- browser_evaluate: set viewport to 375x812
- browser_snapshot to find hamburger menu
- If found: browser_click hamburger, browser_take_screenshot -> {REVIEW_DIR}/mobile-menu.png

### 0.7e. Animation runtime capture
- browser_evaluate: document.getAnimations() snapshot
- browser_evaluate: getComputedStyle transition detection
- Store as interaction-state.json in REVIEW_DIR
```

### Specialist Prompt Changes

Specialists that benefit from interaction screenshots:

| Specialist | New Screenshots | What They Evaluate |
|-----------|----------------|-------------------|
| Font | focus-input.png | Font rendering in focused input states |
| Color | hover-cta.png | Hover color transitions, focus ring colors |
| Layout | scroll-mid.png, mobile-menu.png | Scroll behavior, mobile nav layout |
| Icon | mobile-menu.png | Icon visibility in mobile nav |
| Motion | interaction-state.json | Runtime animation quality (not just code) |
| Intent/UX | hover-cta.png, mobile-menu.png | CTA discoverability, mobile UX |
| Code/A11y | focus-input.png | Focus ring visibility, keyboard navigation |

### Degradation Behavior

- **Tier 1 (Playwright MCP available):** Full interaction capture
- **Tier 2 (Playwright CLI only, no MCP):** Skip interaction phase, static screenshots only. Note in output: "Interaction states not captured (Playwright MCP not registered)"
- **Tier 3 (No Playwright):** Code-only, no screenshots at all

This means Tier 1 now requires Playwright MCP (`claude mcp add playwright`) in addition to Playwright CLI. The existing Tier 1 definition (Gemini + Playwright) expands to (Gemini + Playwright MCP).

### design-review.md Changes

```markdown
## Phase 0.7: Interaction Screenshots (Tier 1 only)

If Playwright MCP tools are available (test by calling browser_snapshot):

{interaction capture protocol}

Pass ALL screenshots (static + interaction) to specialist prompts:
- Static: desktop.png, mobile.png, fold.png
- Interaction: hover-cta.png, focus-input.png, scroll-mid.png, mobile-menu.png
- Runtime: interaction-state.json

If Playwright MCP is not available, skip this phase.
Specialists work with static screenshots only (same as v1.0/v1.1).
```

### Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `commands/design-review.md` | MODIFIED | Add Phase 0.7 interaction capture |
| `skills/design-review/prompts/specialist-motion.md` | MODIFIED | Read interaction-state.json for runtime data |
| `skills/design-review/prompts/specialist-code.md` | MODIFIED | Evaluate focus-input.png for a11y |
| `commands/design-audit.md` | NO CHANGE | Already uses Playwright MCP for navigation; interaction screenshots per-screen are a future enhancement |

### Build Dependency

Independent of prompt extraction (Integration 1) -- can be added to the command directly. However, better to build AFTER prompt extraction so the new screenshot references go into the extracted prompt files rather than the monolith.

---

## Integration 6: Copy-to-Intent Specialist Merge (8 to 7)

### Problem

The Copy specialist (Specialist 7) evaluates spelling, grammar, placeholders, tone match, and CTA quality. Several of these overlap with the Intent/Originality/UX specialist: CTA quality, tone match, and consistency. The Copy specialist also runs as Haiku (cheapest tier) and is the least impactful on scoring (1x weight). Merging it into Intent reduces agent count, token cost, and cross-specialist redundancy.

### Recommended Architecture: Fold Copy Criteria into Intent Specialist

The Intent/Originality/UX specialist becomes **Intent/Originality/UX/Copy** and its prompt gains the Copy-specific checks. The specialist still returns 3 scores (Intent Match, Originality, UX Flow) with Copy quality folded into Intent Match (tone/copy is part of intent alignment) and UX Flow (CTA copy quality is a UX concern).

### Scoring Changes

**Before (10 dimensions, divisor 17):**
```
Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout*1 + Icons*1 + Motion*1 + Copy*1 + Code*1 = /17
```

**After (9 dimensions, divisor 16):**
```
Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout*1 + Icons*1 + Motion*1 + Code*1 = /16
```

**Quick mode before (6 dimensions, divisor 13):**
```
Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout*1 = /13
```

**Quick mode after (same -- Copy was already excluded from quick mode):**
```
Intent*3 + Originality*3 + UX*2 + Typography*2 + Color*2 + Layout*1 = /13
```

Quick mode is unaffected because Copy was already skipped.

### Cascade of Changes

This merge touches many files:

| File | Change | Impact |
|------|--------|--------|
| `config/scoring.json` | Remove `copy` weight, change `total_weight` from 17 to 16 | Scores shift slightly upward (higher divisor removed) |
| `commands/design-review.md` | Remove Specialist 7 section, update Phase 3 formula | Structural simplification |
| `commands/design-audit.md` | Update specialist count references | Minor text changes |
| `commands/design-improve.md` | Update specialist count in comments | Minor |
| `commands/design.md` | No change (routes only) | None |
| `shared/output.md` | Update "8 specialists" to "7 specialists" in examples | Branding |
| `ARCHITECTURE.md` | Update specialist table, scoring formula | Documentation |
| `README.md` | Update specialist count throughout | Documentation |
| `CLAUDE.md` | Update "8 specialist agents" references | Documentation |
| `.claude-plugin/plugin.json` | Update description if it mentions 8 | Metadata |
| `evals/assertions.json` | Recalibrate overall score ranges (divisor change) | Eval accuracy |
| `evals/validate-structure.sh` | No change (doesn't count specialists) | None |
| `VERSION` | Bump to 1.2.0 | Version |
| `skills/design-review/prompts/specialist-intent.md` | Add Copy evaluation criteria | Prompt enhancement |
| `skills/design-review/prompts/specialist-copy.md` | DELETE | Removed |

### Score Impact Analysis

Removing Copy (weight 1) from a divisor of 17 to get 16 changes scores:

For a page where all dimensions score 3.0:
- Before: `(3*3 + 3*3 + 3*2 + 3*2 + 3*2 + 3*1 + 3*1 + 3*1 + 3*1 + 3*1) / 17 = 51/17 = 3.0`
- After: `(3*3 + 3*3 + 3*2 + 3*2 + 3*2 + 3*1 + 3*1 + 3*1 + 3*1) / 16 = 48/16 = 3.0`

Equal scores produce equal results. But for unequal scores, the removed Copy dimension changes the weighted average. If Copy was the lowest scorer (common for non-English content or placeholder text), removing it RAISES the overall score. If Copy was the highest scorer (rare), removing it lowers the score.

**Practical impact:** assertions.json ranges should be widened slightly to account for the scoring shift. The emotional-page.html fixture (intentionally bad) might score slightly higher without a Copy penalty. The landing-page.html might score slightly lower if Copy was scoring well.

### Intent Specialist Prompt Enhancement

Add to the Intent specialist:

```markdown
4. COPY & LANGUAGE: Does the copy serve the page's intent?
   - Spelling and grammar accuracy
   - Missing accents/diacritics (especially Spanish: corazon -> corazon, anos -> anos)
   - Placeholder text still present (lorem ipsum, "Your text here", TODO)
   - CTA specificity: "Submit"/"OK" is generic; specific CTAs convert better
   - Tone match: corporate language on a personal page, casual on enterprise
   - Consistency: same concept described differently in different places

FLAG: lorem ipsum, missing Spanish accents, generic CTAs ("Learn More"),
tone mismatches, inconsistent terminology.

Score Copy quality as part of Intent Match (tone/copy alignment) and
UX Flow (CTA copy quality affects conversion).
```

### Build Dependency

This is the RISKIEST change because it cascades across the most files. Build it LAST after all other integrations are stable. The eval system (Integration 2) should be running before this change so you can verify scores before and after the merge.

---

## Suggested Build Order

Based on dependency analysis and risk assessment:

```
Phase 1 (Foundation):
  1. Extract prompts to files (Integration 1)
  2. Add output schemas (Integration 3)
  These are coupled -- do together.

Phase 2 (Generation):
  3. Aesthetics generation prompt (Integration 4)
  Independent, low risk, high visible impact.

Phase 3 (Interaction):
  4. Playwright interaction layer (Integration 5)
  Independent of prompt extraction but benefits from it.

Phase 4 (Eval):
  5. Layer 2 quality evals (Integration 2)
  Depends on structured output for reliable parsing.
  Must be running before the specialist merge.

Phase 5 (Consolidation):
  6. Copy-to-Intent merge (Integration 6)
  Highest risk, most cascade. Do last with eval safety net.
```

### Parallel Opportunities

- Integrations 1+3 (prompts + schemas) are one logical unit
- Integration 4 (aesthetics) is fully independent, can run in parallel with 1+3
- Integration 5 (interaction) is independent, can run in parallel with 4

```
Phase 1:  [1+3: Prompt extraction + schemas]  ||  [4: Aesthetics prompt]
Phase 2:  [5: Playwright interaction]
Phase 3:  [2: Layer 2 evals]
Phase 4:  [6: Copy-to-Intent merge]
```

This gives 4 sequential phases with 2 parallel tracks in Phase 1.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Adding npm Dependencies for JSON Parsing

**What:** Installing a JSON schema validator or template engine for structured output parsing.
**Why bad:** Violates the zero-dependency principle. The plugin installs by file copy.
**Instead:** Use `jq` for JSON parsing (already a dependency of generate-report.sh and validate-structure.sh). Use XML tags + prompt engineering for output format enforcement.

### Anti-Pattern 2: Separate Prompt Files Without @include

**What:** Extracting prompts to files but requiring the orchestrator to Read them at runtime.
**Why bad:** Adds tool calls and latency. The `@${CLAUDE_PLUGIN_ROOT}/...` include mechanism loads files at command parse time, not runtime.
**Instead:** Use `@` includes which are resolved when the command file is loaded.

### Anti-Pattern 3: Strict JSON Schema Enforcement

**What:** Requiring perfect JSON from every specialist response and failing if malformed.
**Why bad:** LLM output is non-deterministic. A specialist might occasionally produce slightly malformed JSON (trailing comma, comment). Hard failure breaks the review.
**Instead:** Parse with `jq` and fall back to regex extraction if JSON parsing fails. The branded terminal output remains the primary user-facing output.

### Anti-Pattern 4: Aesthetics Prompt in Review Evaluation

**What:** Using the generation aesthetics prompt as evaluation criteria for all reviews.
**Why bad:** The aesthetics prompt says "use unusual fonts, bold choices." A review that penalizes standard font choices on an admin panel misapplies the guidance. Generation and evaluation are different operations.
**Instead:** The aesthetics prompt lives in `references/generation.md` and is read ONLY by design-improve.md Phase A. Review specialists have their own criteria that respect page type context.

### Anti-Pattern 5: Changing Specialist Count Without Eval Baseline

**What:** Merging specialists before having Layer 2 evals running.
**Why bad:** No way to verify that scores remain calibrated after the merge. Assertion ranges in assertions.json might need adjustment, but you cannot tell without before/after comparison.
**Instead:** Get Layer 2 evals running first (even imperfectly). Run evals, record baseline. Then merge specialists. Run evals again. Compare.

---

## Component Boundary Summary

### New Components

| Component | Type | Files | Purpose |
|-----------|------|-------|---------|
| Prompt library | Markdown files | `skills/design-review/prompts/*.md` (10 files) | Testable, reusable specialist prompts |
| Output schemas | Markdown files | `skills/design-review/schemas/*.md` (2 files) | JSON output format definitions |
| Generation reference | Markdown file | `skills/design-review/references/generation.md` | Aesthetics guidance for improve command |
| Quality eval runner | Bash script | `evals/run-quality-evals.sh` | Layer 2 eval execution |
| Output parser | Bash script | `evals/parse-review-output.sh` | Score/verdict extraction from review output |

### Modified Components

| Component | Files | What Changes |
|-----------|-------|-------------|
| design-review.md | `commands/design-review.md` | Replace inline prompts with `@` includes, add Phase 0.7, parse JSON output |
| design-audit.md | `commands/design-audit.md` | Replace inline prompts with `@` includes, write JSON to flow-state |
| design-improve.md | `commands/design-improve.md` | Read generation.md, consume structured fix list |
| scoring.json | `config/scoring.json` | Remove copy weight, total_weight 17 to 16 |
| assertions.json | `evals/assertions.json` | Recalibrate ranges, add parse_mode |
| run-evals.sh | `evals/run-evals.sh` | Call run-quality-evals.sh for Layer 2 |
| intent.md | `skills/design-review/references/intent.md` | Add AI convergence patterns |
| output.md | `shared/output.md` | Update specialist count 8 to 7 |

### Deleted Components

| Component | File | Reason |
|-----------|------|--------|
| Copy specialist | `skills/design-review/prompts/specialist-copy.md` | Merged into Intent |

---

## Data Flow: v1.2.0 Review Pipeline

```
User: /design-review http://localhost:3000

Phase 0: Static screenshots
  -> desktop.png, mobile.png, fold.png

Phase 0.5: Load design context (.design/ if exists)

Phase 0.7: Interaction screenshots (Playwright MCP, Tier 1 only)
  -> hover-cta.png, focus-input.png, scroll-mid.png, mobile-menu.png
  -> interaction-state.json

Phase 1: Page brief (Haiku)
  @prompts/page-brief.md
  -> PAGE_BRIEF JSON

Phase 2: Specialist dispatch (7 agents in parallel)
  Each specialist:
    @prompts/specialist-{name}.md  (includes @schemas/specialist-output.md)
    + screenshots (static + interaction)
    + PAGE_BRIEF
    + reference knowledge file
    -> <specialist_output>{JSON}</specialist_output>

Phase 3: Boss synthesis
  @prompts/boss-synthesizer.md  (includes @schemas/boss-output.md)
  + all specialist JSONs
  + scoring.json weights
  -> <boss_output>{JSON}</boss_output>

Phase 3.5: Render branded output
  Read <boss_output> JSON
  Render via shared/output.md format (score bars, boxes, verdict)
  -> Terminal output (what user sees)

Phase 4: Cleanup
Phase 4.5: Update .design/ harness
Phase 5: Fix list (from boss JSON top_fixes array)
```

---

## Sources

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- Official prompt engineering guide, XML tags, few-shot, role assignment (HIGH confidence)
- [Anthropic XML Tags Guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags) -- XML structuring for complex prompts (HIGH confidence)
- [Anthropic Frontend Design Skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) -- Official DISTILLED_AESTHETICS_PROMPT source (HIGH confidence)
- [Anthropic Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) -- API-level JSON schema enforcement (not applicable to plugin context, but informs prompt-level approach) (HIGH confidence)
- [Anthropic Frontend Aesthetics Cookbook](https://github.com/anthropics/claude-cookbooks/blob/main/coding/prompting_for_frontend_aesthetics.ipynb) -- Detailed aesthetics prompting patterns (HIGH confidence)
- [LLM-as-Judge evaluation methodology](https://www.evidentlyai.com/llm-guide/llm-as-a-judge) -- Evaluation technique using structured JSON output from judges (MEDIUM confidence)
- [Claude Code Plugin frontend-design](https://claude.com/plugins/frontend-design) -- Marketplace listing, 277K installs validates approach (HIGH confidence)
- Existing SpSk codebase analysis -- direct reading of all command files, configs, evals, references (HIGH confidence -- primary source)
