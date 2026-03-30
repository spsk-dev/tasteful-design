# Phase 10: Structured JSON Output - Research

**Researched:** 2026-03-29
**Domain:** Prompt-enforced JSON output from LLM specialists + bash JSON parsing
**Confidence:** HIGH

## Summary

Phase 10 migrates all 9 specialist prompt files and the boss synthesizer from freeform text output to structured JSON wrapped in XML tags. The current state is well-understood: every `<output_format>` section in the 9 prompt files contains a single vague line like "Return: issues list with specific elements + score + one-line summary." The boss synthesizer outputs a markdown table that the eval parser scrapes with regex (grep for `**Verdict:`, grep for `| Label | N/4 |`). This is fragile -- the cached eval output shows the parser depends on exact markdown formatting that varies between runs.

The migration path is straightforward because Phase 8 already established XML-structured prompts with `<output_format>` sections ready for schema insertion. The key technique is the think-then-structure pattern: specialists reason freely in `<thinking>` tags, then emit structured JSON in `<specialist_output>` tags. This preserves reasoning quality (avoiding the 10-15% degradation documented in LLM literature when forcing pure JSON output) while giving consumers deterministic data. The eval parser (`parse-review-output.sh`) gains a JSON-first extraction path using `jq`, falling back to the existing regex for backward compatibility with pre-v1.2.0 output.

**Primary recommendation:** Update `<output_format>` in all 9 specialist prompts to specify a minimal JSON schema inside `<specialist_output>` tags. Update boss.md to emit `<boss_output>` JSON. Build dual-format extraction in parse-review-output.sh (JSON-first, regex fallback). Update design-improve.md to consume `top_fixes` array. Update generate-report.sh to read structured JSON from flow-state.json screen reviews. Run evals after each specialist migration to catch regressions.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None -- all implementation choices are at Claude's discretion (pure infrastructure phase).

### Claude's Discretion
- Use think-then-structure pattern: `<thinking>` free-form reasoning first, `<specialist_output>` structured JSON second (preserves reasoning quality)
- JSON schema: `{ "specialist": "name", "score": N, "findings": [...], "summary": "..." }` -- minimal, not over-constrained
- Boss output: `{ "scores": {...}, "weighted_score": N, "verdict": "SHIP|CONDITIONAL|BLOCK", "top_fixes": [...], "consensus_findings": [...] }`
- Validate JSON with `jq -e` in eval pipeline; retry once on parse failure
- Dual-format parser: try JSON extraction first, fall back to regex for pre-v1.2.0 output compatibility
- Migrate one specialist at a time, run evals after each to catch regressions
- Update `<output_format>` section in each extracted prompt file (from Phase 8)
- Gemini specialists (Color, Layout) need JSON output too -- test Gemini CLI compliance

### Deferred Ideas (OUT OF SCOPE)
- Per-specialist JSON schemas (one shared schema is sufficient)
- Schema versioning (v1.3+ if needed)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JSON-01 | All specialists emit structured JSON wrapped in `<specialist_output>` tags | Current `<output_format>` sections documented for all 9 prompts; JSON schema defined; think-then-structure pattern verified against Anthropic docs |
| JSON-02 | Boss synthesizer emits structured JSON wrapped in `<boss_output>` tags | Current boss output_format is markdown table; boss JSON schema defined with scores, verdict, top_fixes, consensus_findings |
| JSON-03 | Output parser supports dual-format (JSON-first with regex fallback) | parse-review-output.sh functions documented; JSON extraction via grep + jq pattern identified; regex functions preserved as fallback |
| JSON-04 | `/design-improve` consumes `top_fixes` array programmatically | design-improve.md Phase C currently reads "fix list from the review" as freeform text; structured `top_fixes` array enables deterministic extraction |
| JSON-05 | `generate-report.sh` reads structured JSON from flow-state.json | generate-report.sh already reads JSON via jq; screen review data structure needs `top_fixes` field to store boss structured output |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `jq` | 1.7+ | JSON parsing/validation in bash | Already used throughout eval pipeline and generate-report.sh; zero-dependency; installed via brew |
| `grep` | system | XML tag extraction (`<specialist_output>` to `</specialist_output>`) | Standard unix; first-pass extraction before jq validation |
| `sed` | system | Strip XML tags to get raw JSON | Standard unix; paired with grep for extraction |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `python3 -c` | Float comparison in assertions | Already used in parse-review-output.sh `float_in_range()` |
| `base64`, `sips` | Screenshot processing in generate-report.sh | Already used; no changes needed for JSON migration |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `jq` for JSON validation | `python3 -c json.loads()` | Works but adds indirection; jq is already the project standard |
| XML tag wrapping for JSON | Raw JSON in markdown code fences | Less reliable extraction; fences can appear in other output sections |
| Prompt-enforced JSON | Anthropic Structured Outputs API | API not available in Claude Code plugin context (confirmed out of scope in REQUIREMENTS.md) |

## Architecture Patterns

### Current Output Format (All 9 Specialist Prompts)

Every specialist prompt file has a vague `<output_format>` section:

| Prompt | Current `<output_format>` Content |
|--------|-----------------------------------|
| font.md | `Return: issues list with specific elements + score + one-line summary.` |
| color.md | `Return: issues list with specific colors/elements + score + one-line summary.` |
| layout.md | `Return: issues list with specific positions/measurements + score + one-line summary.` |
| icons.md | `Return: issues list with specific icons/components + score + one-line summary.` |
| motion.md | `Return: issues list with file:line references + score + one-line summary.` |
| intent.md | `Return three scores and findings: Intent Match, Originality, UX Flow (each score 1-4 + issues + one-line summary)` |
| copy.md | `Return: issues list with exact text quotes + score + one-line summary.` |
| code-a11y.md | `Return: issues list with file:line references + score + one-line summary.` |
| boss.md | Full markdown template with `## Design Review`, scores table, `### Top 5 Fixes`, etc. |

### Current Boss Output Format

The boss synthesizer (boss.md) outputs structured markdown:
```
## Design Review -- {page name}
**Verdict: SHIP / CONDITIONAL SHIP / BLOCK**
**Score: {weighted}/4.0**
...
### Scores
| Specialist | Score | Weight | Key Finding |
...
### Top 5 Fixes (priority order)
1. {fix} -- found by {specialists}
...
```

This is what `parse-review-output.sh` currently scrapes.

### Current Parse Functions (parse-review-output.sh)

Four functions using regex extraction:

1. **`extract_verdict()`** -- greps for `\*\*Verdict: (SHIP|CONDITIONAL SHIP|CONDITIONAL|BLOCK)`, normalizes CONDITIONAL SHIP to CONDITIONAL
2. **`extract_overall()`** -- greps for `\*?\*?Score: [0-9]+\.[0-9]+/4\.0`, returns float
3. **`extract_score(dimension)`** -- maps snake_case dimension to table label (e.g., `intent_match` -> `Intent Match`), greps for `| Label | N/4 |`
4. **`float_in_range(value, min, max)`** -- python3 float comparison

### Target: Specialist JSON Schema

```json
{
  "specialist": "typography",
  "score": 3,
  "findings": [
    {
      "element": "h1.hero-title",
      "issue": "Hero text uses Playfair Display (AI-overused serif)",
      "recommendation": "Replace with Instrument Serif or Newsreader"
    }
  ],
  "summary": "Thoughtful hierarchy with one AI-overused font choice"
}
```

**Intent specialist (3 scores):**
```json
{
  "specialist": "intent",
  "scores": {
    "intent_match": 3,
    "originality": 2,
    "ux_flow": 3
  },
  "findings": [
    {
      "dimension": "originality",
      "element": "overall layout",
      "issue": "Three-column icon grid is a common AI pattern",
      "recommendation": "Use asymmetric layout with featured card"
    }
  ],
  "summary": "Intent match is strong but originality suffers from template patterns"
}
```

### Target: Boss JSON Schema

```json
{
  "page_name": "Landing Page",
  "page_type": "landing",
  "mode": "full",
  "tier": 1,
  "scores": {
    "intent_match": 3,
    "originality": 2,
    "ux_flow": 3,
    "typography": 3,
    "color": 2,
    "layout": 3,
    "icons": 2,
    "motion": 3,
    "copy": 3,
    "code_a11y": 2
  },
  "weighted_score": 2.65,
  "verdict": "CONDITIONAL",
  "consensus_findings": [
    {
      "issue": "AI-overused font (Playfair Display)",
      "specialists": ["typography", "intent"],
      "confidence": "HIGH"
    }
  ],
  "top_fixes": [
    {
      "priority": 1,
      "severity": "CRITICAL",
      "issue": "Replace Playfair Display with Instrument Serif",
      "file": "index.html",
      "line": 15,
      "specialists": ["typography", "intent"]
    }
  ],
  "what_works": ["Clear CTA above the fold", "Consistent color palette"],
  "gold_standard_gap": "For a landing page, the best sites (Vercel, Linear) would use more whitespace in the hero section."
}
```

### Think-Then-Structure Pattern

Each specialist prompt's `<output_format>` section will instruct:

```markdown
<output_format>
First, reason through your evaluation in <thinking> tags -- this is your workspace for analysis.
Then, output your structured findings in <specialist_output> tags as JSON:

<specialist_output>
{
  "specialist": "typography",
  "score": N,
  "findings": [
    {
      "element": "selector or description",
      "issue": "what is wrong",
      "recommendation": "what to do instead"
    }
  ],
  "summary": "one-line summary of your evaluation"
}
</specialist_output>

Rules:
- Score must be an integer 1-4 matching your rubric justification
- findings array must have 2-5 entries
- Each finding must reference a specific element, not generic observations
- summary must be one sentence
</output_format>
```

### Dual-Format Parser Strategy

The upgraded `parse-review-output.sh` adds JSON extraction functions that are tried first, falling back to existing regex:

```bash
# JSON-first extraction: try to find <boss_output> JSON block
extract_verdict_json() {
  local output="$1"
  local json_block
  json_block=$(echo "$output" | sed -n '/<boss_output>/,/<\/boss_output>/p' | sed '1d;$d')
  if [ -n "$json_block" ] && echo "$json_block" | jq -e '.verdict' &>/dev/null; then
    local raw
    raw=$(echo "$json_block" | jq -r '.verdict')
    # Normalize CONDITIONAL SHIP -> CONDITIONAL
    echo "$raw" | sed 's/CONDITIONAL SHIP/CONDITIONAL/'
  fi
}

# Upgraded extract_verdict: JSON-first, regex fallback
extract_verdict() {
  local output="$1"
  local result
  result=$(extract_verdict_json "$output")
  if [ -n "$result" ]; then
    echo "$result"
    return
  fi
  # Fallback to regex (existing code)
  local raw
  raw=$(echo "$output" | grep -oE '\*\*Verdict: (SHIP|CONDITIONAL SHIP|CONDITIONAL|BLOCK)' | head -1 | sed 's/\*\*Verdict: //')
  if [ "$raw" = "CONDITIONAL SHIP" ]; then echo "CONDITIONAL"; else echo "$raw"; fi
}
```

### flow-state.json Enhancement

The existing screen review structure in flow-state.json:
```json
{
  "review": {
    "scores": { "intent_match": 3.0, ... },
    "weighted_score": 2.85,
    "verdict": "CONDITIONAL",
    "findings": ["finding 1", "finding 2"],
    "cross_specialist_findings": ["cross-finding 1"]
  }
}
```

After Phase 10, structured specialist output is stored:
```json
{
  "review": {
    "scores": { "intent_match": 3.0, ... },
    "weighted_score": 2.85,
    "verdict": "CONDITIONAL",
    "findings": ["finding 1", "finding 2"],
    "cross_specialist_findings": ["cross-finding 1"],
    "top_fixes": [
      {
        "priority": 1,
        "severity": "CRITICAL",
        "issue": "...",
        "file": "index.html",
        "line": 15,
        "specialists": ["typography", "intent"]
      }
    ]
  }
}
```

The `top_fixes` array is what `design-improve.md` consumes programmatically (JSON-04) and what `generate-report.sh` reads for the priority fixes section (JSON-05).

### File Modification Map

| File | Change Type | What Changes |
|------|-------------|--------------|
| `skills/design-review/prompts/font.md` | Update `<output_format>` | Replace 1-line text with JSON schema + think-then-structure |
| `skills/design-review/prompts/color.md` | Update `<output_format>` | Same pattern |
| `skills/design-review/prompts/layout.md` | Update `<output_format>` | Same pattern |
| `skills/design-review/prompts/icons.md` | Update `<output_format>` | Same pattern |
| `skills/design-review/prompts/motion.md` | Update `<output_format>` | Same pattern |
| `skills/design-review/prompts/intent.md` | Update `<output_format>` | Multi-score variant with `scores` object |
| `skills/design-review/prompts/copy.md` | Update `<output_format>` | Same base pattern |
| `skills/design-review/prompts/code-a11y.md` | Update `<output_format>` | Same base pattern |
| `skills/design-review/prompts/boss.md` | Replace `<output_format>` | Markdown template -> `<boss_output>` JSON schema |
| `evals/parse-review-output.sh` | Major update | Add JSON extraction functions; keep regex as fallback |
| `commands/design-improve.md` | Update Phase C | Document programmatic `top_fixes` consumption |
| `commands/design-review.md` | Update Phase 2/3 | Document specialist_output and boss_output JSON handling |
| `commands/design-audit.md` | Update Section 10c | Store `top_fixes` in flow-state.json review entries |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON validation | Custom parse logic | `jq -e` | Already project standard; handles edge cases (trailing commas, missing fields) |
| XML tag extraction | Complex regex | `sed -n '/tag/,/\/tag/p'` | Standard sed range pattern; handles multiline JSON blocks |
| Float comparison | Bash arithmetic | `python3 -c` (existing `float_in_range`) | Bash cannot do native float comparison; already solved |
| JSON pretty-print | Manual formatting | `jq '.'` | Debugging during migration |

**Key insight:** The entire JSON extraction pipeline is `sed` (extract from XML tags) + `jq` (validate and query). No new dependencies needed. Both are already used in the project.

## Common Pitfalls

### Pitfall 1: JSON Reasoning Degradation
**What goes wrong:** Forcing structured JSON output can reduce specialist reasoning depth by 10-15% (documented in LLM literature). Specialists give shallow findings to fit the schema.
**Why it happens:** The model focuses on producing valid JSON instead of deep analysis.
**How to avoid:** Use think-then-structure pattern -- `<thinking>` for free-form reasoning first, `<specialist_output>` for structured JSON second. The thinking section preserves analytical depth.
**Warning signs:** Specialist findings become generic ("improve the colors") instead of specific ("Replace #800080 hero gradient with tinted neutral #2a1f3d").

### Pitfall 2: Gemini JSON Compliance
**What goes wrong:** Gemini CLI (`gemini -y -p "..."`) returns plain text, not API-structured JSON. JSON compliance in prompt-only mode may differ from Claude.
**Why it happens:** Gemini CLI is used for Color and Layout specialists (Tier 1). It does not expose structured output API through the CLI.
**How to avoid:** Test Gemini JSON output explicitly after updating color.md and layout.md. The Gemini CLI returns unstructured text -- the prompt must be strong enough to enforce JSON format. If Gemini fails to produce valid JSON, the fallback-to-Claude path already exists (Tier 2 degradation).
**Warning signs:** `jq -e` fails on Gemini specialist output; missing fields in JSON.

### Pitfall 3: Boss Output Dual-Format Transition
**What goes wrong:** During migration, some runs produce JSON boss output, some produce markdown. Eval assertions break because the parser expects one format.
**Why it happens:** Cached eval outputs (evals/results/cache-*.txt) still contain pre-JSON markdown. Dry-run mode uses these caches.
**How to avoid:** Update cached eval outputs after migration. The dual-format parser handles both, but assertions should be re-run live after migration to generate new caches.
**Warning signs:** Dry-run evals pass but live evals fail (or vice versa).

### Pitfall 4: Intent Specialist Multi-Score Schema
**What goes wrong:** Intent specialist returns 3 separate scores (intent_match, originality, ux_flow). Using the same schema as single-score specialists loses the multi-score structure.
**Why it happens:** Intent is unique -- it has a `scores` object instead of a single `score` field.
**How to avoid:** Intent specialist uses a variant schema with `"scores": { "intent_match": N, "originality": N, "ux_flow": N }` instead of `"score": N`. The parser must handle both shapes.
**Warning signs:** Intent scores collapse into a single number; per-dimension eval assertions fail.

### Pitfall 5: Boss Still Needs Human-Readable Output
**What goes wrong:** Boss produces only JSON -- the terminal review experience degrades. Users see raw JSON instead of the formatted review.
**Why it happens:** Boss output is displayed directly to users in `/design-review`. Pure JSON is not user-friendly.
**How to avoid:** Boss produces BOTH: (1) the human-readable markdown review (for terminal display) and (2) the `<boss_output>` JSON block (for programmatic consumption). The orchestrator in design-review.md displays the markdown portion; consumers extract the JSON portion. This is the same think-then-structure pattern: markdown is the "thinking", JSON is the "output".
**Warning signs:** Users report unreadable review output.

### Pitfall 6: Specialist Prompt Token Budget
**What goes wrong:** Adding JSON schema + examples + think-then-structure instructions to each specialist prompt increases token count, slowing reviews.
**Why it happens:** Each specialist prompt grows by ~200-300 tokens from the output_format changes.
**How to avoid:** Keep the JSON schema minimal (no nested types, no enum constraints, no additionalProperties enforcement). The schema is documentation for the LLM, not API validation. Total prompt growth across all specialists should be under 2500 tokens (~8% of a typical review).
**Warning signs:** Review time increases by more than 10%.

## Code Examples

### Specialist Output Format (font.md pattern)

```markdown
<output_format>
First, analyze the typography in <thinking> tags -- examine fonts, hierarchy, sizing, spacing.

Then output your structured evaluation:

<specialist_output>
{
  "specialist": "typography",
  "score": 3,
  "findings": [
    {
      "element": "h1.hero-title",
      "issue": "Hero uses Playfair Display -- #1 AI luxury serif",
      "recommendation": "Replace with Instrument Serif or Newsreader"
    },
    {
      "element": "body p",
      "issue": "Line-height 1.5 at 16px is acceptable but not refined",
      "recommendation": "Use 1.6 for body text under 20px"
    }
  ],
  "summary": "Clear hierarchy with one AI-overused font undermining originality"
}
</specialist_output>

Requirements:
- score: integer 1-4, must match your rubric justification
- findings: array of 2-5 objects, each with element/issue/recommendation
- summary: one sentence
</output_format>
```

### Intent Specialist Variant (multi-score)

```markdown
<output_format>
First, analyze intent match, originality, and UX flow in <thinking> tags.

Then output your structured evaluation:

<specialist_output>
{
  "specialist": "intent",
  "scores": {
    "intent_match": 3,
    "originality": 2,
    "ux_flow": 3
  },
  "findings": [
    {
      "dimension": "originality",
      "element": "hero section",
      "issue": "Three-column icon grid is the most common AI layout pattern",
      "recommendation": "Use asymmetric bento grid or featured card layout"
    }
  ],
  "summary": "Strong intent alignment undercut by template-like originality"
}
</specialist_output>

Requirements:
- scores: object with intent_match, originality, ux_flow (each integer 1-4)
- findings: array of 2-5 objects, each with dimension/element/issue/recommendation
- summary: one sentence
</output_format>
```

### Boss Output Format

```markdown
<output_format>
Present the full human-readable review (scores table, findings, fixes, gold-standard gap)
as you do currently -- this is what the user sees in the terminal.

Then, at the end, output the structured data for programmatic consumption:

<boss_output>
{
  "page_name": "Landing Page",
  "page_type": "landing",
  "mode": "full",
  "tier": 1,
  "scores": {
    "intent_match": 3,
    "originality": 2,
    "ux_flow": 3,
    "typography": 3,
    "color": 2,
    "layout": 3,
    "icons": 2,
    "motion": 3,
    "copy": 3,
    "code_a11y": 2
  },
  "weighted_score": 2.65,
  "verdict": "CONDITIONAL",
  "consensus_findings": [
    {
      "issue": "AI-overused font (Playfair Display)",
      "specialists": ["typography", "intent"],
      "confidence": "HIGH"
    }
  ],
  "top_fixes": [
    {
      "priority": 1,
      "severity": "CRITICAL",
      "issue": "Replace Playfair Display with Instrument Serif",
      "file": "index.html",
      "line": 15,
      "specialists": ["typography", "intent"]
    }
  ],
  "what_works": ["Clear CTA above the fold"],
  "gold_standard_gap": "For a landing page, sites like Vercel use more generous whitespace."
}
</boss_output>

Requirements:
- scores: all 10 dimensions (6 in quick mode, null for skipped)
- weighted_score: float matching the explicit calculation
- verdict: exactly SHIP, CONDITIONAL, or BLOCK
- top_fixes: array of up to 5, ordered by priority
- consensus_findings: issues found by 2+ specialists
</output_format>
```

### JSON Extraction in parse-review-output.sh

```bash
# Extract JSON block between XML tags
extract_json_block() {
  local output="$1"
  local tag="$2"
  echo "$output" | sed -n "/<${tag}>/,/<\/${tag}>/p" | sed "1d;\$d"
}

# JSON-first verdict extraction
extract_verdict_json() {
  local output="$1"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e '.verdict' &>/dev/null; then
    echo "$json" | jq -r '.verdict' | sed 's/CONDITIONAL SHIP/CONDITIONAL/'
  fi
}

# JSON-first overall score extraction
extract_overall_json() {
  local output="$1"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e '.weighted_score' &>/dev/null; then
    echo "$json" | jq -r '.weighted_score'
  fi
}

# JSON-first per-specialist score extraction
extract_score_json() {
  local dimension="$1"
  local output="$2"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e ".scores.${dimension}" &>/dev/null; then
    echo "$json" | jq -r ".scores.${dimension}"
  fi
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Freeform text specialist output | Prompt-enforced JSON in XML tags | v1.2.0 (this phase) | Deterministic parsing, no regex scraping |
| Regex-based output parsing | JSON-first with regex fallback | v1.2.0 (this phase) | Reliable score extraction; backward compatible |
| Boss markdown table scraping | `<boss_output>` JSON block | v1.2.0 (this phase) | Programmatic access to all review data |
| design-improve reads freeform fixes | design-improve reads `top_fixes` array | v1.2.0 (this phase) | Fix application becomes deterministic |
| Prefill-based JSON enforcement | Prompt-based JSON enforcement | Claude 4.6 (2025) | Prefills deprecated in Claude 4.6; prompt enforcement is the official path |

**Deprecated/outdated:**
- **Prefilled responses for JSON:** Claude 4.6 no longer supports prefilled responses on the last assistant turn. The migration path is prompt-based enforcement with XML tag wrappers.
- **Anthropic Structured Outputs API in plugins:** Not available in Claude Code plugin context. Prompt-enforced JSON is the only path for this architecture.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash assertions via run-quality-evals.sh |
| Config file | evals/assertions.json |
| Quick run command | `bash evals/run-quality-evals.sh --dry-run` |
| Full suite command | `bash evals/run-quality-evals.sh` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JSON-01 | Specialist output contains valid JSON in `<specialist_output>` tags | unit (parser) | `bash evals/run-quality-evals.sh --dry-run` (after cache update) | Partial -- parse functions exist, JSON path needs adding |
| JSON-02 | Boss output contains valid JSON in `<boss_output>` tags | unit (parser) | `bash evals/run-quality-evals.sh --dry-run` | Partial -- same |
| JSON-03 | Dual-format parser extracts from both JSON and regex formats | unit | Inline test in parse-review-output.sh or separate test script | No -- Wave 0 |
| JSON-04 | `top_fixes` array extractable from boss JSON | integration | `bash evals/run-quality-evals.sh` (live run, check top_fixes presence) | No -- needs assertion |
| JSON-05 | generate-report.sh reads `top_fixes` from flow-state.json | smoke | `bash scripts/generate-report.sh <test-flow-state.json>` | No -- needs test fixture |

### Sampling Rate
- **Per specialist migration:** `bash evals/run-quality-evals.sh --dry-run` (after updating cache with new format output)
- **Per wave merge:** `bash evals/run-quality-evals.sh` (full live run)
- **Phase gate:** Full suite green + manual spot-check of JSON validity

### Wave 0 Gaps
- [ ] Add JSON extraction test cases to parse-review-output.sh (or create evals/test-parser.sh)
- [ ] Add `top_fixes` presence assertion to assertions.json
- [ ] Create a test flow-state.json fixture with `top_fixes` for generate-report.sh smoke test
- [ ] Re-cache eval outputs after first specialist migration (evals/results/cache-*.txt)

## Open Questions

1. **Boss output: inline markdown + trailing JSON, or JSON-only?**
   - What we know: Users see boss output in terminal. Pure JSON would degrade the experience.
   - Recommendation: Boss emits both -- human-readable markdown review followed by `<boss_output>` JSON block. The orchestrator displays everything; programmatic consumers extract only the JSON. This is settled by CONTEXT.md guidance.

2. **Migration order for specialists?**
   - What we know: CONTEXT.md says "migrate one at a time, run evals after each." But no specific order.
   - Recommendation: Start with font.md (simplest single-score specialist, Claude-only). Then color.md (Gemini -- tests cross-model compliance). Then intent.md (multi-score variant). Then boss.md. Then remaining specialists in any order. This front-loads the risk.

3. **Cached eval outputs after migration?**
   - What we know: Dry-run mode uses evals/results/cache-*.txt. Currently only cache-emotional-page.txt exists.
   - Recommendation: After migrating all specialists + boss, run one full live eval pass to regenerate all caches. Until then, dry-run mode may produce misleading results.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `jq` | JSON parsing throughout | Yes | 1.7.1-apple | -- |
| `python3` | Float comparison in parser | Yes | 3.14.3 | -- |
| `sed` | XML tag extraction | Yes (system) | -- | -- |
| `grep` | Regex fallback | Yes (system) | -- | -- |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Sources

### Primary (HIGH confidence)
- [Anthropic Structured Outputs Documentation](https://platform.claude.com/docs/en/docs/build-with-claude/structured-outputs) -- Confirms prompt-enforced JSON as valid approach; API structured outputs not available in plugin context
- [Anthropic Claude 4.6 Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- XML tag structure guidance, think-then-structure pattern, prefill deprecation in Claude 4.6
- Direct codebase analysis: all 9 prompt files (`skills/design-review/prompts/*.md`), `evals/parse-review-output.sh`, `evals/run-quality-evals.sh`, `evals/assertions.json`, `scripts/generate-report.sh`, `commands/design-review.md`, `commands/design-improve.md`, `commands/design-audit.md`

### Secondary (MEDIUM confidence)
- [Gemini CLI Headless Mode](https://geminicli.com/docs/cli/headless/) -- Gemini CLI returns plain text in `-y -p` mode; no structured output API through CLI
- [Structured Outputs and Function Calling guide (Agenta.ai)](https://agenta.ai/blog/the-guide-to-structured-outputs-and-function-calling-with-llms) -- JSON reasoning degradation (10-15%) finding supporting think-then-structure approach
- Cached eval output (evals/results/cache-emotional-page.txt) -- Current output format with markdown table and `**Verdict:` pattern

### Tertiary (LOW confidence)
- Gemini CLI JSON compliance rate for prompt-enforced schemas -- not empirically tested yet, only assumed to work based on Gemini's instruction following. Needs validation during Phase 10 execution.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- jq, sed, grep are already used throughout; no new dependencies
- Architecture: HIGH -- all files read, current output formats documented, JSON schemas defined from CONTEXT.md guidance, extraction pattern (sed + jq) is standard
- Pitfalls: HIGH -- reasoning degradation documented in literature; Gemini compliance is the only MEDIUM-confidence risk (mitigated by existing Tier 2 fallback)

**Research date:** 2026-03-29
**Valid until:** 2026-04-28 (stable domain -- bash JSON processing is not fast-moving)
