# Phase 8: Prompt Extraction + Restructuring - Research

**Researched:** 2026-03-29
**Domain:** Prompt engineering, file extraction, XML structuring for Claude Code plugin specialist agents
**Confidence:** HIGH

## Summary

Phase 8 is a pure restructuring phase -- no new features, no behavioral changes. The work is extracting 8 specialist prompts plus the boss synthesizer from inline sections in `commands/design-review.md` (lines 319-548) into individual files under `skills/design-review/prompts/`, restructuring each with XML-tagged sections following Anthropic Claude 4.6 best practices, adding 4-level scoring rubrics with concrete anchors, removing over-aggressive directives, and wiring the command files to load prompts via `@` includes.

The critical finding is that the specialist prompts exist in ONLY ONE place: `commands/design-review.md`. The `commands/design-audit.md` does NOT duplicate them -- it references "per design-review.md Phase 2" at line 753. The `commands/design-improve.md` similarly delegates to `/design-review` for its review passes. This means extraction from `design-review.md` is the only source operation. The commands that reference these prompts need updated references to the new extracted files, but the prompts themselves are not duplicated across files.

**Primary recommendation:** Extract one prompt file per specialist to `skills/design-review/prompts/{name}.md`, restructure each with `<role>`, `<context>`, `<reference_knowledge>`, `<instructions>`, `<scoring_rubric>`, `<output_format>` XML tags, replace all aggressive directives with normal-case guidance, then replace the inline prompt blocks in design-review.md Phase 2 with `@` includes pointing to the extracted files.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None -- this is an infrastructure phase with all implementation choices at Claude's discretion.

### Claude's Discretion
All implementation choices are at Claude's discretion -- pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions. Key guidance from research:

- XML structure follows Anthropic's Claude 4.6 best practices: `<role>`, `<context>`, `<reference_knowledge>`, `<instructions>`, `<output_format>`
- Rubric levels: 1 (Poor), 2 (Below Average), 3 (Good), 4 (Excellent) with domain-specific anchors per specialist
- Directive cleanup: replace ALL-CAPS with normal case, replace "NEVER" with "avoid", replace "Find at least N" with "identify notable issues", replace "FLAG SPECIFICALLY" with guidance language
- Extract to: `skills/design-review/prompts/{specialist-name}.md` (font.md, color.md, layout.md, icons.md, motion.md, intent.md, copy.md, code-a11y.md, boss.md)
- Both design-review.md and design-audit.md must reference the same extracted prompts via `@` includes
- Preserve existing scoring weights and specialist behavior -- this is restructuring, not rewriting logic

### Deferred Ideas (OUT OF SCOPE)
- Few-shot examples per specialist (Phase 13 -- PRMT-04)
- Chain-of-thought separation (Phase 13 -- PRMT-05)
- Structured JSON output format (Phase 10 -- JSON-01..05)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRMT-01 | All specialist prompts use XML-structured sections (`<role>`, `<context>`, `<instructions>`, `<output_format>`, `<examples>`) | STACK.md Section 1 defines the exact template. Anthropic best practices doc confirms XML tags improve parsing. Each specialist prompt gets the same structural skeleton with domain-specific content. |
| PRMT-02 | Every specialist has a 4-level scoring rubric with concrete anchors per level | STACK.md Section 1 provides the rubric template (1=Poor, 2=Below Average, 3=Good, 4=Excellent). Each specialist needs domain-specific anchor descriptions per level. Current prompts use bare "Score 1-4" with no anchors. |
| PRMT-03 | Over-aggressive directives removed (ALL-CAPS emphasis, "FLAG SPECIFICALLY", "NEVER", "Find at least N") | Exact locations identified: 8 "FLAG SPECIFICALLY" blocks (lines 340, 369, 397, 423, 448, 490, 519, 544), 8 "Find at least N" directives (lines 342, 371, 399, 425, 450, 492, 521, 546), 1 "NEVER" in orchestrator context (line 128). Non-specialist "IMPORTANT" directives at lines 293, 627, 629 are orchestrator instructions and should remain. |
| PRMT-06 | Specialist prompts extracted to individual files (`skills/design-review/prompts/*.md`) with `@` includes from commands | Directory `skills/design-review/prompts/` does not exist yet. The `@${CLAUDE_PLUGIN_ROOT}/...` include pattern is established (used in 6+ existing command files). Extraction source is design-review.md lines 319-548. |
| PRMT-07 | Boss synthesizer prompt restructured with XML tags, explicit output schema, and cross-specialist reasoning instructions | Boss synthesizer is at design-review.md lines 552-648 (Phase 3). Currently it is orchestrator instructions, not a subagent prompt. Restructuring means extracting the synthesis logic into a prompt file that the orchestrator references. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code plugin system | N/A | `@` file includes, YAML frontmatter commands | This is the delivery mechanism -- prompts are `.md` files loaded via `@${CLAUDE_PLUGIN_ROOT}/...` |
| Anthropic Claude 4.6 XML tags | N/A | `<role>`, `<context>`, `<instructions>`, `<output_format>` | Official Anthropic best practice for structuring complex prompts. Claude was trained with XML tags. |
| bash (validate-structure.sh) | 5.x | Structural validation of extracted files | Existing Layer 1 eval framework that must be extended to check new prompt files |
| jq | 1.7+ | JSON validation in eval scripts | Already a prerequisite via validate-structure.sh |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Gemini CLI | latest | Color and Layout specialist execution | Specialists 2 and 3 are dispatched via Gemini -- their extracted prompts must work in both Claude and Gemini contexts |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Individual `.md` files per specialist | Single `prompts.md` with all specialists | Individual files enable isolated testing and smaller diffs per prompt change. Single file is simpler but defeats the isolation goal. Use individual files. |
| `@` includes from commands | Inline prompts with reference to extracted file via Read | `@` includes are the established pattern in this codebase. Read-based references would change the execution model. Use `@` includes. |
| XML tags for all structure | Markdown headers for specialist sections | XML tags are unambiguous to Claude and recommended by Anthropic. Markdown headers can be confused with content. Use XML tags. |

## Architecture Patterns

### Recommended Project Structure
```
skills/design-review/
  prompts/
    font.md              # Specialist 1: Typography
    color.md             # Specialist 2: Color (Gemini)
    layout.md            # Specialist 3: Layout (Gemini)
    icons.md             # Specialist 4: Icons
    motion.md            # Specialist 5: Motion
    intent.md            # Specialist 6: Intent/Originality/UX
    copy.md              # Specialist 7: Copy & Language
    code-a11y.md         # Specialist 8: Code & Accessibility
    boss.md              # Boss synthesizer
  references/            # Existing -- domain knowledge per specialist
    typography.md
    color.md
    layout.md
    icons.md
    motion.md
    intent.md
    flow.md
    visual-design-rules.md
```

### Pattern 1: Extracted Specialist Prompt Structure

**What:** Each specialist prompt file follows a consistent XML skeleton with domain-specific content.

**When to use:** Every specialist prompt file.

**Template:**
```markdown
<role>
You are a {domain} specialist evaluating frontend design quality.
You have deep expertise in {domain-specific areas}.
</role>

<context>
PAGE CONTEXT (evaluate your domain in service of this intent):
- Intent: {INTENT from PAGE_BRIEF}
- Audience: {AUDIENCE}
- Primary action: {PRIMARY_ACTION}
- What comes next: {NEXT_STEP}
- UX priorities: {UX_PRIORITIES}

{IF DESIGN_SYSTEM exists: project design system context}
{IF STYLE_PRESET: style preset context}
</context>

<reference_knowledge>
Read your reference file: ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/{domain}.md
</reference_knowledge>

<instructions>
Evaluate {domain quality dimension} for this page.

Process:
1. Read the reference knowledge above
2. Examine the screenshots and source files
3. Identify 2-5 specific issues (each must name the element, its current state, and what it should be)
4. Evaluate whether your domain serves the page intent -- not in isolation
5. Score using the rubric below

{Domain-specific review checklist -- converted from current inline prompts}
</instructions>

<scoring_rubric>
Score this dimension on a 1-4 scale:

- 1 (Poor): {domain-specific anchor -- what "poor" looks like in this domain}
- 2 (Below Average): {domain-specific anchor}
- 3 (Good): {domain-specific anchor}
- 4 (Excellent): {domain-specific anchor}

Each score must be justified by specific evidence from the page.
</scoring_rubric>

<output_format>
Return: issues list with specific elements + score + one-line summary.
</output_format>
```

**Source:** Anthropic Claude 4.6 Best Practices, STACK.md Section 1

### Pattern 2: Command File `@` Include Pattern

**What:** After extraction, design-review.md Phase 2 replaces inline prompts with `@` references.

**When to use:** The specialist dispatch section of design-review.md.

**Example:**
```markdown
### Specialist 1: Font (Claude Sonnet Agent)

Reads: screenshots (Read the PNG files) + source files + reference knowledge

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/font.md
```

The context prefix (PAGE_BRIEF, design system context) remains in design-review.md because it is dynamic and constructed by the orchestrator. The specialist prompt file contains the static instructions, rubric, and output format.

### Pattern 3: Directive Cleanup Mapping

**What:** Systematic replacement of aggressive directives with clear, normal-case guidance.

| Current Pattern | Replacement |
|----------------|-------------|
| `FLAG SPECIFICALLY: Dancing Script, Playfair+Poppins combos, ...` | Move items to `<instructions>` checklist: "Check for these known issues: Dancing Script usage, Playfair+Poppins combinations, ..." |
| `Find at least 2 issues.` | "Identify 2-5 specific issues. Each must reference a specific element, its current state, and what it should be." |
| `Find at least 3 issues (1+ per dimension).` | "Identify 3-5 issues across your three dimensions. Cover each dimension." |
| `NEVER skip them without explicit user confirmation.` | "Do not skip screenshots without explicit user confirmation." (This is orchestrator text, not specialist prompt -- keep but rephrase.) |
| `Must find at least 2 issues (no "looks great" allowed)` | "Identify 2-5 issues per specialist." (Move to extracted prompt.) |
| `Score: Typography Quality 1-4.` | Full rubric with anchors in `<scoring_rubric>` section. |

### Pattern 4: Boss Synthesizer Extraction

**What:** The boss synthesizer logic (design-review.md lines 552-648) is orchestrator instructions, not a subagent prompt. Extract the synthesis rules (weighting, deduplication, verdict logic) into `prompts/boss.md` as a structured reference the orchestrator follows.

**Key distinction:** The boss is NOT dispatched as a separate agent -- the orchestrator IS the boss. The extracted file contains the synthesis protocol in XML format for clarity, but the orchestrator reads and follows it directly.

```markdown
<role>
You are the boss designer synthesizer. You do NOT re-evaluate. You trust the specialists and merge their findings.
</role>

<instructions>
After all specialists return:

1. Cross-specialist agreement: Issues found by 2+ specialists get HIGH confidence. Flag these prominently.
2. Deduplicate: Same issue from multiple specialists -- merge into one, keep the most specific description, note which specialists found it.
3. Compute weighted score using config/scoring.json weights.
4. Apply context-aware verdict using page-type thresholds.
</instructions>

<scoring_formula>
Full mode: (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout + Icons + Motion + Copy + Code) / 17
Quick mode: (Intent*3 + Originality*3 + UX_Flow*2 + Typography*2 + Color*2 + Layout) / 13

Read weights from config/scoring.json if available.
</scoring_formula>

<verdict_rules>
{threshold table by page type}
{SHIP/CONDITIONAL/BLOCK logic}
</verdict_rules>

<output_format>
{existing Phase 3e presentation format}
</output_format>
```

### Anti-Patterns to Avoid

- **Changing specialist behavior while restructuring:** This phase is extraction + restructuring only. Do not add new review criteria, change scoring weights, or modify what specialists look for. Behavioral changes come in later phases.
- **Breaking the Gemini specialist prompts:** Specialists 2 (Color) and 3 (Layout) are dispatched via Gemini CLI. Their extracted prompt files must contain only the prompt text -- no Claude-specific XML that Gemini cannot parse. Verify Gemini compatibility by noting that the color and layout prompts are passed as a `-p "..."` string argument.
- **Moving dynamic context into static prompt files:** The PAGE_BRIEF, DESIGN_SYSTEM context, STYLE_PRESET context, and reference screenshots are dynamic per-review. These must remain in the orchestrator (design-review.md). Only static instructions, rubrics, and output format go into the extracted files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File include mechanism | Custom template system | `@${CLAUDE_PLUGIN_ROOT}/...` includes | Already built into Claude Code plugin system. Used in 6+ files in this codebase. |
| Scoring rubric format | Ad-hoc per-specialist rubric structure | Consistent XML `<scoring_rubric>` template | Consistency across specialists enables future automated validation. |
| Prompt validation | Manual review of each prompt | Extended `validate-structure.sh` checks | Layer 1 evals already exist. Add checks for prompt file existence, XML tag presence, and directive absence. |
| Directive cleanup verification | Manual grep | Automated structural assertion in validate-structure.sh | A grep check for "FLAG SPECIFICALLY\|Find at least\|NEVER" in prompt files catches regressions permanently. |

## Common Pitfalls

### Pitfall 1: Gemini Prompt Compatibility
**What goes wrong:** Gemini CLI specialists (Color, Layout) receive prompts with XML tags that Gemini interprets differently than Claude.
**Why it happens:** The prompts are written for Claude's XML understanding. Gemini may or may not handle XML tags the same way.
**How to avoid:** For Color and Layout prompts, keep XML tags as structural markers but ensure the prompt reads naturally even if tags are ignored. Test by reading the prompt text aloud -- if it makes sense without tags, it works for Gemini. The current prompts are passed as `-p "..."` strings to Gemini CLI, so the prompt content must be a single self-contained string.
**Warning signs:** Gemini specialists returning garbled output, ignoring instructions, or failing to score.

### Pitfall 2: Dynamic Context Placement After Extraction
**What goes wrong:** The extracted prompt file is included via `@`, but the dynamic context (PAGE_BRIEF) must be injected BEFORE the prompt instructions. If the orchestrator appends context after the `@` include, the prompt structure is inverted (instructions before context).
**Why it happens:** `@` includes inject file content at the include point. The orchestrator must build the prompt in the right order: context first, then specialist instructions.
**How to avoid:** The orchestrator constructs each specialist's full prompt as: (1) dynamic context prefix (PAGE_BRIEF, design system, style preset), (2) `@` include of the specialist prompt file. The specialist prompt file starts with `<role>` and `<reference_knowledge>`, then `<instructions>`, then `<scoring_rubric>`, then `<output_format>`. The `<context>` section is either in the prompt file as a template placeholder that the orchestrator fills, or the orchestrator provides context separately before the include.
**Warning signs:** Specialists ignoring page context, scoring in a vacuum, generic findings not tailored to page type.

### Pitfall 3: Accidentally Changing Specialist Behavior
**What goes wrong:** While restructuring the prompt text, the meaning subtly changes. For example, "FLAG SPECIFICALLY" was a hard requirement but the replacement "Check for these known issues" is softer, causing the specialist to miss patterns it used to catch.
**Why it happens:** Directive cleanup is necessary but the replacement language must preserve the same detection behavior.
**How to avoid:** For each "FLAG SPECIFICALLY" block, convert items to an explicit checklist in the `<instructions>` section. Use "Check for and flag:" as the header -- this preserves the detection requirement without the aggressive language. Compare before/after prompts side by side to verify nothing was dropped.
**Warning signs:** Eval scores dropping on fixtures that previously triggered specific flags.

### Pitfall 4: Missing Boss Synthesizer Math
**What goes wrong:** The boss synthesizer scoring formula and verdict logic are extracted to boss.md but the orchestrator still tries to follow the old inline instructions, producing duplicate or conflicting behavior.
**Why it happens:** The orchestrator IS the boss -- it reads design-review.md. If design-review.md still contains remnants of the synthesis logic alongside the `@` include, the orchestrator may double-apply rules.
**How to avoid:** When replacing the boss synthesis section with an `@` include, remove ALL inline synthesis instructions from design-review.md Phase 3. The `@` include IS the complete replacement.
**Warning signs:** Scoring formula being applied twice, inconsistent verdict logic.

### Pitfall 5: Structural Validation Gaps
**What goes wrong:** Extracted prompt files pass Layer 1 checks but have structural issues (missing XML tags, leftover aggressive directives) that only surface during reviews.
**How to avoid:** Add specific validation checks to `validate-structure.sh`: (a) all 9 prompt files exist, (b) each contains `<role>`, `<instructions>`, `<scoring_rubric>`, `<output_format>` tags, (c) none contains "FLAG SPECIFICALLY", "Find at least", or ALL-CAPS directives (excluding legitimate uses like "ALL CAPS" when referring to CSS text-transform). This catches regressions on every eval run.
**Warning signs:** validate-structure.sh passing but reviews producing poorly structured output.

## Code Examples

### Example 1: Extracted Font Specialist Prompt (font.md)

Derived from design-review.md lines 319-343, restructured with XML tags and rubric.

```markdown
<role>
You are a typography specialist evaluating frontend design quality.
You have deep expertise in font selection, pairing, hierarchy, sizing, spacing, and readability.
</role>

<reference_knowledge>
Read: ${CLAUDE_PLUGIN_ROOT}/skills/design-review/references/typography.md
</reference_knowledge>

<instructions>
Evaluate typography quality for this page.

Process:
1. Read the typography reference knowledge above
2. Examine the screenshots and source files
3. Identify 2-5 specific issues (each must name the element, its current state, and what it should be)
4. Evaluate whether typography serves the page intent -- not in isolation
5. Score using the rubric below

Review checklist:
- Font choices: are they AI-overused? (check the reference for the overused list)
- Pairing quality: max 2 families + optional mono, contrast not conflict
- Hierarchy: size scale, weight distribution (4-weight system), visual clarity
- Line-height by size: decreases as size increases (reference has exact values)
- Letter-spacing: uppercase text should have +0.05em tracking, display text needs negative tracking
- Measure: 45-75 chars per line, 65ch ideal

Check for and flag:
- Dancing Script, Playfair+Poppins combos, 3+ font families
- No tracking on uppercase text, hero text under 48px
- Centered body paragraphs, light (300) weight body text
</instructions>

<scoring_rubric>
Score typography on a 1-4 scale:

- 1 (Poor): AI-overused fonts (Dancing Script, Poppins as primary), no hierarchy, missing letter-spacing on uppercase. Multiple fundamental violations requiring significant rework.
- 2 (Below Average): Default/generic fonts (Inter, system fonts) with basic hierarchy. Functional but no craft. Missing fine typography details (line-height scaling, tracking).
- 3 (Good): Thoughtful font selection with clear hierarchy. Minor issues only -- perhaps one missing detail (letter-spacing, measure width). Polished with small improvements.
- 4 (Excellent): Distinctive, well-paired fonts with refined hierarchy. Correct line-height scaling, proper tracking, appropriate measure. Would impress a senior designer.

Each score must be justified by specific evidence from the page.
</scoring_rubric>

<output_format>
Return: issues list with specific elements + score + one-line summary.
</output_format>
```

### Example 2: Design-review.md After Extraction (Phase 2 Specialist 1)

```markdown
### Specialist 1: Font (Claude Sonnet Agent)

Reads: screenshots (Read the PNG files) + source files + reference knowledge

@${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/font.md

Read these screenshots visually: {REVIEW_DIR}/desktop.png, {REVIEW_DIR}/mobile.png, {REVIEW_DIR}/fold.png
Read the source files: {file list}
```

### Example 3: validate-structure.sh Extension

```bash
# Phase 8: Extracted specialist prompts
PROMPT_DIR="skills/design-review/prompts"
for prompt in font.md color.md layout.md icons.md motion.md intent.md copy.md code-a11y.md boss.md; do
  check "$PROMPT_DIR/$prompt exists" test -f "$PROMPT_DIR/$prompt"
done

# Check for required XML tags in specialist prompts (not boss)
for prompt in font.md color.md layout.md icons.md motion.md intent.md copy.md code-a11y.md; do
  check "$prompt has <role> tag" grep -q '<role>' "$PROMPT_DIR/$prompt"
  check "$prompt has <instructions> tag" grep -q '<instructions>' "$PROMPT_DIR/$prompt"
  check "$prompt has <scoring_rubric> tag" grep -q '<scoring_rubric>' "$PROMPT_DIR/$prompt"
  check "$prompt has <output_format> tag" grep -q '<output_format>' "$PROMPT_DIR/$prompt"
done

# Check for removed aggressive directives
AGGRESSIVE=$(grep -rn 'FLAG SPECIFICALLY\|Find at least [0-9]' "$PROMPT_DIR/" 2>/dev/null || true)
check "No aggressive directives in prompts" test -z "$AGGRESSIVE"
```

## Specialist-by-Specialist Extraction Inventory

Precise line ranges from `commands/design-review.md` and content to extract:

| Specialist | Line Range | Model | Reference File | Key Directive Cleanup |
|-----------|------------|-------|----------------|----------------------|
| Font (#1) | 319-343 | Claude Sonnet | typography.md | "FLAG SPECIFICALLY" L340, "Find at least 2" L342 |
| Color (#2) | 348-372 | Gemini CLI | color.md | "FLAG SPECIFICALLY" L369, "Find at least 2" L371 |
| Layout (#3) | 376-399 | Gemini CLI | layout.md | "FLAG SPECIFICALLY" L397, "Find at least 2" L399 |
| Icons (#4) | 403-427 | Claude Sonnet | icons.md | "FLAG SPECIFICALLY" L423, "Find at least 2" L425 |
| Motion (#5) | 430-452 | Claude Sonnet | motion.md | "FLAG SPECIFICALLY" L448, "Find at least 2" L450 |
| Intent (#6) | 455-497 | Claude Sonnet | intent.md | "FLAG SPECIFICALLY" L490, "Find at least 3" L492 |
| Copy (#7) | 499-523 | Claude Haiku | none | "FLAG SPECIFICALLY" L519, "Find at least 2" L521 |
| Code (#8) | 525-548 | Claude Sonnet | none | "FLAG SPECIFICALLY" L544, "Find at least 2" L546 |
| Boss | 552-648 | Orchestrator | scoring.json | "IMPORTANT" L627, L629 (keep as orchestrator instructions) |

**Context prefix** (shared by all specialists): Lines 274-291. This stays in design-review.md as the orchestrator constructs it dynamically per review.

**Pre-dispatch setup** (Gemini file copy): Lines 293-315. This stays in design-review.md as orchestrator infrastructure.

## Domain-Specific Rubric Anchors

Each specialist needs concrete anchors per score level. These are derived from the reference files and current prompt language.

### Font Rubric Anchors
- **1 (Poor):** AI-overused fonts (Dancing Script, Playfair as hero serif), no hierarchy, missing letter-spacing on uppercase, 3+ font families, hero text under 48px
- **2 (Below Average):** Default/generic fonts (Inter, system fonts), basic but undistinguished hierarchy, missing fine details (line-height scaling, tracking)
- **3 (Good):** Thoughtful font selection, clear hierarchy, minor issues (one missing detail), well-paired families
- **4 (Excellent):** Distinctive typeface with pairing rationale, refined hierarchy, correct line-height, proper tracking, appropriate measure

### Color Rubric Anchors
- **1 (Poor):** AI palette anti-patterns (synthwave purple, dark+gold), WCAG contrast failures on body text, no color system, clashing hues
- **2 (Below Average):** Generic palette with no personality, some contrast issues, no clear 60/30/10 structure, pure black/white without tinting
- **3 (Good):** Cohesive palette matching page mood, WCAG AA compliant, clear accent usage, minor issues (one contrast edge case, slightly generic neutral)
- **4 (Excellent):** Distinctive, intentional palette with tinted neutrals, consistent saturation, WCAG AAA on body text, clear color hierarchy

### Layout Rubric Anchors
- **1 (Poor):** No responsive behavior, inconsistent spacing (non-4px-grid values), wall-of-cards monotony, elements overflow on mobile
- **2 (Below Average):** Basic responsive breakpoints but no fluid units, some spacing inconsistency, monotonous section rhythm, adequate but unrefined
- **3 (Good):** Consistent spacing system, responsive with fluid sizing, varied section rhythm, minor issues (one cramped area, slightly wide text measure)
- **4 (Excellent):** 8px-grid spacing throughout, fluid responsive with clamp/auto-fit, varied section rhythm with visual breaks, generous whitespace appropriate to page type

### Icons Rubric Anchors
- **1 (Poor):** Mixed icon libraries, emoji as functional icons, inconsistent sizing, missing aria-labels on icon-only buttons
- **2 (Below Average):** Single library but inconsistent sizing or mixed filled/outline styles without meaning, basic touch targets
- **3 (Good):** Consistent library and sizing, proper filled/outline semantics, minor issues (one missing aria-label, slight size variation)
- **4 (Excellent):** Single library with consistent stroke weight, proper semantic filled/outline, all accessibility labels present, correct touch targets

### Motion Rubric Anchors
- **1 (Poor):** Animate-bounce on UI elements, no prefers-reduced-motion, F-tier property animation (width/height), transform clobbering
- **2 (Below Average):** Basic transitions exist but linear easing, some missing reduced-motion support, one or two F-tier animations
- **3 (Good):** Appropriate durations with proper easing, reduced-motion supported, GPU-composited properties, minor issues (one slightly long duration)
- **4 (Excellent):** Purposeful animations with premium easing curves, proper will-change usage, full reduced-motion support, meaningful state feedback

### Intent/Originality/UX Rubric Anchors (3 scores)
- **Intent Match:** 1=design fights content purpose, 2=generic/template doesn't fit context, 3=design supports intent with minor mismatches, 4=design amplifies and serves the specific intent
- **Originality:** 1=every AI default present (Inter, purple gradient, three-column icons), 2=some AI patterns but attempts at distinction, 3=mostly original with one or two generic elements, 4=distinctly designed, would not be mistaken for AI output
- **UX Flow:** 1=primary action buried or unclear, broken flow, 2=CTA visible but competing elements, unclear next step, 3=clear action hierarchy with minor flow gaps, 4=single-minded flow, clear CTA, obvious next step, good mobile UX

### Copy Rubric Anchors
- **1 (Poor):** Placeholder text (lorem ipsum), spelling errors, missing diacritics, generic labels ("Submit", "Click Here"), tone mismatch
- **2 (Below Average):** No placeholders but generic copy ("Build the future"), some inconsistent terminology, CTAs not compelling
- **3 (Good):** Clear, correct copy with appropriate tone, specific CTAs, minor issues (one generic phrase, slight inconsistency)
- **4 (Excellent):** Specific, compelling copy matching page voice, perfect grammar/diacritics, consistent terminology, CTAs that drive action

### Code/A11y Rubric Anchors
- **1 (Poor):** Missing alt text, no aria-labels, inline styles throughout, no responsive breakpoints, no semantic HTML
- **2 (Below Average):** Some accessibility but gaps (missing focus styles, color-only indicators), basic responsive, mix of CSS approaches
- **3 (Good):** Semantic HTML, most accessibility covered, CSS variables for theming, responsive breakpoints, minor gaps (one missing alt text)
- **4 (Excellent):** Full semantic HTML, complete accessibility (focus management, skip links, aria), CSS custom properties, mobile-first responsive, no hardcoded values

## Gemini Specialist Considerations

Specialists 2 (Color) and 3 (Layout) are dispatched via `gemini -y -p "..."` where the entire prompt is passed as a single string argument. After extraction:

1. The orchestrator must READ the extracted prompt file content and construct the full Gemini CLI command with it.
2. The `@` include mechanism does NOT work with Gemini CLI -- it is a Claude Code plugin feature. The orchestrator must manually compose the Gemini prompt by reading the extracted file.
3. XML tags in Gemini prompts are acceptable -- Gemini processes XML as structural markers similarly to Claude. However, the prompt must read naturally even without tag parsing.
4. The Gemini prompt currently includes both the specialist instructions AND a reference to the pre-copied workspace file (`.color-reference.md`, `.layout-reference.md`). After extraction, the orchestrator reads the prompt file and inserts its content into the Gemini CLI command string.

**Implementation approach:** The orchestrator section for Gemini specialists changes from inline prompt text to: "Read `${CLAUDE_PLUGIN_ROOT}/skills/design-review/prompts/color.md` for the specialist instructions. Construct the Gemini CLI command using this content plus the dynamic context (PAGE_BRIEF)."

## Integration Points

### Files Modified

| File | Change | Lines Affected |
|------|--------|----------------|
| `commands/design-review.md` | Replace inline specialist prompts (Phase 2) with `@` includes. Replace inline boss synthesis (Phase 3) with `@` include. Remove "Must find at least 2 issues" from Phase 2 header (line 270). | Lines 265-648 (major restructuring) |
| `evals/validate-structure.sh` | Add checks for 9 prompt files, XML tag presence, and aggressive directive absence | Append ~20 new checks |

### Files Created

| File | Content |
|------|---------|
| `skills/design-review/prompts/font.md` | Typography specialist prompt |
| `skills/design-review/prompts/color.md` | Color specialist prompt |
| `skills/design-review/prompts/layout.md` | Layout specialist prompt |
| `skills/design-review/prompts/icons.md` | Icons specialist prompt |
| `skills/design-review/prompts/motion.md` | Motion specialist prompt |
| `skills/design-review/prompts/intent.md` | Intent/Originality/UX specialist prompt |
| `skills/design-review/prompts/copy.md` | Copy & Language specialist prompt |
| `skills/design-review/prompts/code-a11y.md` | Code & Accessibility specialist prompt |
| `skills/design-review/prompts/boss.md` | Boss synthesizer protocol |

### Files NOT Modified

| File | Why |
|------|-----|
| `commands/design-audit.md` | Already references "per design-review.md Phase 2" -- no inline prompts to extract. When design-review.md changes to `@` includes, design-audit's reference still works because it delegates to design-review's workflow, which now loads from extracted files. |
| `commands/design-improve.md` | Delegates review to `/design-review` -- no prompt changes needed. |
| `config/scoring.json` | Weights and thresholds preserved exactly. This phase does not modify scoring. |
| `skills/design-review/references/*.md` | Reference files are read by specialists, not modified. |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash (validate-structure.sh + run-evals.sh) |
| Config file | evals/validate-structure.sh (Layer 1), evals/run-evals.sh (orchestrator) |
| Quick run command | `bash evals/validate-structure.sh` |
| Full suite command | `bash evals/run-evals.sh` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRMT-06 | 9 prompt files exist in skills/design-review/prompts/ | structural | `bash evals/validate-structure.sh` (after adding checks) | Needs extension |
| PRMT-01 | Each specialist prompt has `<role>`, `<instructions>`, `<scoring_rubric>`, `<output_format>` XML tags | structural | `bash evals/validate-structure.sh` (after adding checks) | Needs extension |
| PRMT-02 | Each specialist prompt has 4-level scoring rubric (grep for "1 (Poor)" etc.) | structural | `bash evals/validate-structure.sh` (after adding checks) | Needs extension |
| PRMT-03 | No aggressive directives in prompt files | structural | `grep -rn "FLAG SPECIFICALLY\|Find at least [0-9]" skills/design-review/prompts/` returns empty | Needs extension |
| PRMT-07 | Boss synthesizer prompt exists with XML tags and scoring formula | structural | `bash evals/validate-structure.sh` (after adding checks) | Needs extension |

### Sampling Rate
- **Per task commit:** `bash evals/validate-structure.sh`
- **Per wave merge:** `bash evals/run-evals.sh`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Extend `evals/validate-structure.sh` with prompt file existence checks, XML tag presence checks, and aggressive directive absence checks (~20 new assertions)
- No new test framework needed -- existing bash eval infrastructure is sufficient

## Open Questions

1. **`@` include behavior with dynamic context**
   - What we know: `@` includes inject file content at the include point. The orchestrator constructs specialist prompts by combining dynamic context + static prompt file.
   - What's unclear: The exact rendering order when an `@` include appears mid-prompt alongside other orchestrator text. Does Claude Code load the include before or after the surrounding markdown?
   - Recommendation: Place the `@` include as the last element in each specialist section, after all dynamic context. This ensures the include content is rendered after the context, matching the intended prompt order. Test with one specialist first.

2. **Gemini prompt file reading mechanism**
   - What we know: Gemini CLI receives prompts as `-p "..."` string arguments. `@` includes are a Claude Code feature.
   - What's unclear: Whether the orchestrator (Claude) can read a prompt file and dynamically inject its content into a Gemini CLI command string.
   - Recommendation: The orchestrator instruction becomes "Read the prompt file at X, then construct the Gemini CLI command using its content." Claude Code can Read files and use content in Bash commands. This is the existing pattern for reference files (`.color-reference.md` is already copied to workspace for Gemini). Test with Color specialist first.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis: `commands/design-review.md` (738 lines -- full specialist prompts at lines 319-548, boss at 552-648)
- Direct codebase analysis: `commands/design-audit.md` (1274 lines -- delegates to design-review.md Phase 2 at line 753, no duplicate prompts)
- Direct codebase analysis: `evals/validate-structure.sh` (150 lines -- existing structural validation framework)
- Direct codebase analysis: All 7 reference files in `skills/design-review/references/` (domain knowledge backing each specialist)
- `.planning/research/STACK.md` -- Anthropic Claude 4.6 prompting best practices (XML tags, roles, rubrics, directive language)
- `.planning/research/SUMMARY.md` -- Milestone-level research with pitfall analysis

### Secondary (MEDIUM confidence)
- [Anthropic Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- XML tag usage, role assignment, constraint specificity
- [Anthropic XML Tags Documentation](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags) -- XML tag structuring for complex prompts

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- this is file extraction and restructuring with established patterns in the codebase. No new dependencies.
- Architecture: HIGH -- prompt file structure is directly prescribed by Anthropic docs and validated against existing codebase patterns.
- Pitfalls: HIGH -- all pitfalls identified from direct codebase analysis (Gemini compatibility, dynamic context placement, directive cleanup fidelity).
- Rubric anchors: HIGH -- derived directly from existing reference files and current prompt language. Domain-specific content is already written.

**Research date:** 2026-03-29
**Valid until:** 2026-04-28 (30 days -- stable domain, no external dependencies changing)
