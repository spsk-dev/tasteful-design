# Stack Research: v1.2.0 Prompt Quality + Eval Credibility

**Domain:** Prompt engineering patterns, LLM quality evals, structured JSON output, Anthropic aesthetics integration, Playwright interaction-before-scoring
**Researched:** 2026-03-29
**Confidence:** HIGH (all findings verified against official Anthropic docs + Playwright MCP repo)

## Context

This is **additive research** for the v1.2.0 milestone. The existing plugin stack (markdown commands, JSON configs, bash scripts, Playwright CLI + MCP, Gemini CLI) is validated and unchanged. Zero-dependency constraint remains absolute. This document covers ONLY what is needed for the five new capability areas.

**Constraint reminder:** This is a Claude Code plugin distributed as flat files. No `npm install`, no `node_modules`, no build step. Everything must work via prompt engineering in `.md` files, configuration in `.json` files, and scripts in `.sh` files.

---

## 1. Prompt Engineering Patterns for Multi-Agent Specialists

### What Changed Since v1.0

Anthropic published definitive Claude 4.6 prompt engineering guidance that supersedes the patterns used in the current specialist prompts. The current prompts work but violate several now-documented best practices.

### Recommended Prompt Structure

Use this template for ALL specialist prompts. Based on Anthropic's official Claude 4.6 best practices doc.

| Element | Current State | Recommended State | Why |
|---------|--------------|-------------------|-----|
| XML tags for sections | Not used | `<role>`, `<context>`, `<instructions>`, `<output_format>`, `<examples>` | Claude 4.6 parses XML tags unambiguously. Reduces misinterpretation between instructions, context, and examples. |
| Role assignment | Inline ("You are a typography specialist") | System-level role in dedicated `<role>` tag | Focuses Claude's behavior and tone. Even a single sentence makes a difference per official docs. |
| Few-shot examples | None | 2-3 examples per specialist wrapped in `<examples>` tags | "Examples are one of the most reliable ways to steer output format, tone, and structure." 3-5 examples recommended. |
| Chain-of-thought | Implicit | Explicit `<thinking>` section before scoring | Claude 4.6 adaptive thinking calibrates reasoning depth per task. Guide it with "reflect on findings before scoring." |
| Output schema | Freeform text | JSON schema in `<output_format>` tag | Deterministic parsing for improve loop. Current freeform output is unparseable by the boss synthesizer. |
| Scoring rubric | "Score 1-4" with no anchors | Categorical rubric with explicit anchors per level | LLM-as-judge research shows categorical scales with clear descriptions per level outperform bare numeric scales. |
| Constraint specificity | "Find at least 2 issues" | "Find 2-5 issues. Each must reference a specific element, its current state, and what it should be." | Claude 4.6 responds to explicit constraints better than vague minimums. |
| Long-context placement | Mixed | Reference file content at TOP, instructions in MIDDLE, query/task at BOTTOM | Official guidance: "Put longform data at the top" -- improves response quality by up to 30% with complex multi-document inputs. |

### Specialist Prompt Template

```markdown
<role>
You are a {domain} specialist evaluating frontend design quality.
You have deep expertise in {domain-specific areas}.
</role>

<context>
PAGE INTENT: {intent from Phase 1}
AUDIENCE: {audience}
PRIMARY ACTION: {primary_action}
DESIGN BAR: {design_bar}
UX PRIORITIES: {ux_priorities}

{IF DESIGN_SYSTEM: project design system context}
{IF STYLE_PRESET: style preset context}
</context>

<reference_knowledge>
{Full content of references/{domain}.md -- placed at top per Anthropic guidance}
</reference_knowledge>

<instructions>
Evaluate {domain quality dimension} for this page.

PROCESS:
1. Read the reference knowledge above
2. Examine the screenshots and source files
3. Identify 2-5 specific issues (each must name the element, its current state, and what it should be)
4. Evaluate whether your domain SERVES the page intent -- not in isolation
5. Score using the rubric below

SCORING RUBRIC:
- 1 (Poor): Multiple fundamental violations. Domain actively harms the page intent. Would require significant rework.
- 2 (Below Average): Several notable issues. Domain underserves the intent. Fixable but needs attention.
- 3 (Good): Minor issues only. Domain supports the intent well. Polished with small improvements needed.
- 4 (Excellent): No significant issues. Domain elevates the page. Would impress a senior designer.

Each score MUST be justified by specific evidence from the page.
</instructions>

<output_format>
Return ONLY valid JSON matching this schema:
{
  "domain": "{domain_name}",
  "score": <number 1-4>,
  "summary": "<one sentence>",
  "issues": [
    {
      "severity": "critical|high|medium|low",
      "element": "<specific element or selector>",
      "current": "<what it is now>",
      "expected": "<what it should be>",
      "reference": "<which rule from reference knowledge>"
    }
  ],
  "praise": ["<genuinely exceptional thing, max 1>"]
}
</output_format>

<examples>
<example>
INPUT: A SaaS landing page using Dancing Script for the hero heading
OUTPUT:
{
  "domain": "typography",
  "score": 2,
  "summary": "AI-overused decorative font undermines SaaS credibility",
  "issues": [
    {
      "severity": "high",
      "element": "h1.hero-title",
      "current": "Dancing Script at 64px",
      "expected": "A distinctive sans-serif like Clash Display or DM Sans at 48-72px",
      "reference": "AI-Overused Fonts: Dancing Script is #1 AI cursive font"
    }
  ],
  "praise": []
}
</example>
</examples>
```

### Key Anthropic Guidance Applied

| Anthropic Principle | How Applied |
|---------------------|-------------|
| "Be clear and direct -- show your prompt to a colleague" | Explicit step-by-step PROCESS in instructions |
| "Add context to improve performance -- explain why" | Scoring rubric explains WHAT each level means, not just a number |
| "Use examples effectively -- relevant, diverse, structured" | `<example>` tags with realistic specialist output |
| "Structure prompts with XML tags" | All sections wrapped in semantic XML |
| "Give Claude a role" | `<role>` tag with domain expertise description |
| "Put longform data at the top" | Reference knowledge placed before instructions |
| "Queries at the end" | Output format and task at bottom of prompt |
| "Claude 4.6 is more responsive to system prompt" | Dial back aggressive language ("MUST", "CRITICAL", "NEVER") -- replaced with clear constraints |

### Anti-Patterns to Remove from Current Prompts

| Current Pattern | Problem | Fix |
|----------------|---------|-----|
| "FLAG SPECIFICALLY: ..." (long inline lists) | Duplicates reference file content, wastes tokens | Move to reference file, reference by name |
| "Find at least 2 issues" | No upper bound, no quality requirement per issue | "Find 2-5 issues. Each must reference a specific element." |
| All-caps emphasis ("NEVER", "MUST", "CRITICAL") | Claude 4.6 is more responsive to prompts -- aggressive language causes overtriggering | Use normal language with clear constraints |
| Freeform output format | Unparseable by boss synthesizer, inconsistent across runs | JSON schema |
| No examples | Claude guesses the output format | 2-3 realistic examples |
| Score with no rubric | "Score 1-4" means nothing without anchors | Categorical rubric with evidence requirements |

### Confidence: HIGH
Source: [Anthropic Claude 4.6 Best Practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices), [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

---

## 2. Quality Eval Framework (Layer 2)

### Current State

Layer 1 (structural) works: `validate-structure.sh` runs 56+ checks. Layer 2 (quality) is defined but not executed -- `assertions.json` has 12 range-based assertions but `run-evals.sh` prints `[TODO]` and exits.

### Recommended Approach: LLM-as-Judge via Bash + Claude API

Use the LLM-as-judge pattern. A bash eval runner serves fixture HTML, runs `/design-review` against it, captures the output, then calls the Claude API with a judge prompt to score whether the output meets quality criteria. No npm dependencies required.

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Eval runner | Bash script (`run-quality-evals.sh`) | Orchestrates: serve fixture, invoke review, capture output, call judge |
| Fixture serving | `python3 -m http.server` | Serve static HTML fixtures on localhost -- already used in design-review |
| Review invocation | Claude Code CLI (`claude -p "run /design-review on localhost:8787"`) | Run the actual plugin against fixtures |
| Judge invocation | `curl` to Anthropic Messages API | Score the captured output against rubric criteria |
| Assertion format | JSON in `assertions.json` | Range-based assertions with rubric criteria per dimension |
| Results | JSON + terminal output | Machine-parseable results for CI, human-readable summary |

### Eval Architecture

```
run-quality-evals.sh
  |
  +--> For each fixture in evals/fixtures/*.html:
  |      1. Start python3 HTTP server on port 8787
  |      2. Run claude -p "/design-review http://localhost:8787" > captured_output.txt
  |      3. Kill server
  |      4. For each assertion matching this fixture:
  |           a. Extract relevant dimension score from captured_output.txt
  |           b. If range assertion: check score is within [min, max]
  |           c. If verdict assertion: check verdict matches expected
  |           d. If quality assertion: call judge API with rubric prompt
  |      5. Record pass/fail for each assertion
  |
  +--> Output results summary
```

### Enhanced Assertion Schema

Extend the existing `assertions.json` format to support three assertion types:

```json
{
  "assertions": [
    {
      "type": "range",
      "fixture": "fixtures/admin-panel.html",
      "name": "Admin panel layout is decent",
      "dimension": "layout",
      "min": 2.5,
      "max": 3.5
    },
    {
      "type": "verdict",
      "fixture": "fixtures/emotional-page.html",
      "name": "Bad page always gets BLOCK",
      "dimension": "verdict",
      "expected": "BLOCK"
    },
    {
      "type": "quality",
      "fixture": "fixtures/landing-page.html",
      "name": "Landing page review mentions CTA visibility",
      "rubric": "The review output mentions call-to-action visibility, button prominence, or above-the-fold action. Score 1 if mentioned with specific element references, 0 if not mentioned or only generic.",
      "threshold": 1
    }
  ]
}
```

**Type `range`** -- deterministic. Parse score from output, check bounds. Zero API cost.
**Type `verdict`** -- deterministic. Parse verdict string from output. Zero API cost.
**Type `quality`** -- LLM-as-judge. Send output + rubric to Claude API, get categorical score. Costs one API call per assertion.

### Judge Prompt Template

```bash
curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-haiku-4-5-20250929",
    "max_tokens": 256,
    "messages": [{
      "role": "user",
      "content": "RUBRIC: '"$RUBRIC"'\n\nREVIEW OUTPUT:\n'"$CAPTURED_OUTPUT"'\n\nScore this review output against the rubric. Return ONLY a JSON object: {\"score\": 0 or 1, \"reason\": \"brief explanation\"}"
    }]
  }' | jq -r '.content[0].text'
```

Use Haiku for judge calls -- fast, cheap, sufficient for binary rubric evaluation.

### Scoring Rubric Best Practices (from research)

| Practice | Implementation |
|----------|---------------|
| Use categorical integer scales, not floats | Binary (0/1) for quality assertions, integer ranges for dimension scores |
| Explicit description per score level | Each rubric criterion describes exactly what qualifies for score 0 vs 1 |
| Chain-of-thought in judge | Judge returns `reason` field showing its reasoning |
| Calibrate against known-good | Include 2-3 "golden" fixtures with manually verified expected outputs |
| Avoid float scoring for judges | Float scores from LLM judges are unreliable. Binary pass/fail per criterion is more stable. |

### Confidence: HIGH
Sources: [LLM-as-Judge Best Practices](https://www.montecarlodata.com/blog-llm-as-judge/), [Promptfoo LLM Rubric](https://www.promptfoo.dev/docs/configuration/expected-outputs/model-graded/llm-rubric/), [Anthropic Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)

---

## 3. Structured JSON Output from Specialists

### The Problem

Current specialists return freeform text. The boss synthesizer must regex-parse scores, guess issue boundaries, and hope for consistency. The `/design-improve` loop cannot reliably extract the "top 3 fixes" because there is no machine-parseable fix list. This is the #1 source of fragility in the review pipeline.

### Recommended Approach: Prompt-Enforced JSON Schemas

Since this is a Claude Code plugin (not an API integration), we cannot use the API's `output_config.format` constrained decoding. Instead, we enforce JSON through prompt engineering -- which is reliable with Claude 4.6's improved instruction following.

| Approach | Decision | Why |
|----------|----------|-----|
| **Prompt-enforced JSON with schema in `<output_format>` tag** | YES -- use this | Works in Claude Code plugin context. Claude 4.6 reliably follows JSON schemas when shown in examples. Zero dependencies. |
| API structured outputs (`output_config.format`) | NOT APPLICABLE | Plugins invoke subagents via prompt, not API calls. No access to `output_config`. |
| Post-processing regex extraction | NO -- remove this | Fragile, fails on edge cases, wastes tokens on retry. |
| Dedicated output parser script | NO | Adding a script to parse freeform text is a band-aid. Fix the source. |

### JSON Schemas Per Specialist

**Individual specialist output (all 7 specialists):**

```json
{
  "type": "object",
  "properties": {
    "domain": { "type": "string", "enum": ["typography", "color", "layout", "icons", "motion", "intent_originality_ux", "code_a11y"] },
    "scores": {
      "type": "object",
      "description": "One score per dimension this specialist evaluates",
      "additionalProperties": {
        "type": "number",
        "minimum": 1,
        "maximum": 4
      }
    },
    "summary": { "type": "string", "maxLength": 120 },
    "issues": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "severity": { "type": "string", "enum": ["critical", "high", "medium", "low"] },
          "element": { "type": "string" },
          "current": { "type": "string" },
          "expected": { "type": "string" },
          "file_line": { "type": "string" },
          "reference_rule": { "type": "string" }
        },
        "required": ["severity", "element", "current", "expected"]
      },
      "minItems": 2,
      "maxItems": 5
    },
    "praise": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 1
    }
  },
  "required": ["domain", "scores", "summary", "issues"]
}
```

**Intent/Originality/UX specialist (3 scores instead of 1):**

```json
{
  "scores": {
    "intent_match": 3,
    "originality": 2,
    "ux_flow": 3
  }
}
```

**Boss synthesizer input (aggregated):**

The orchestrator collects all specialist JSON outputs and constructs the synthesis input. No parsing ambiguity -- just `jq` the scores.

### Validation Strategy

Since we cannot use API-level schema enforcement, validate in the orchestrator:

```bash
# After specialist returns, validate JSON structure
echo "$SPECIALIST_OUTPUT" | jq -e '.domain and .scores and .issues' >/dev/null 2>&1
if [ $? -ne 0 ]; then
  # Retry once with explicit correction prompt
  # "Your output was not valid JSON. Return ONLY the JSON object matching the schema."
fi
```

One retry on malformed JSON. If still failing, log the raw output and proceed with degraded scoring (the orchestrator assigns a default mid-range score and flags it).

### Gemini CLI Specialists

Gemini specialists (Color, Layout) also return JSON. The Gemini CLI (`gemini -y -p "..."`) outputs plain text. Parse the JSON from the output the same way. Gemini is reliable with JSON when the schema is shown in the prompt and examples are provided.

### Confidence: HIGH
Source: [Anthropic Structured Outputs docs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs), [Claude 4.6 Best Practices -- format control](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)

---

## 4. Anthropic DISTILLED_AESTHETICS_PROMPT Integration

### What It Is

The `DISTILLED_AESTHETICS_PROMPT` is an official Anthropic prompt snippet published in their cookbook and now embedded in the Claude 4.6 best practices documentation. It addresses the "AI slop" aesthetic problem by steering Claude away from generic, on-distribution frontend output.

### Full Prompt Text (verified from official source)

```
<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this creates
what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends that
surprise and delight. Focus on:

Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like
Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics.

Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors
with sharp accents outperform timid, evenly-distributed palettes. Draw from IDE themes and
cultural aesthetics for inspiration.

Motion: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML.
Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated
page load with staggered reveals (animation-delay) creates more delight than scattered
micro-interactions.

Backgrounds: Create atmosphere and depth rather than defaulting to solid colors. Layer CSS
gradients, use geometric patterns, or add contextual effects that match the overall aesthetic.

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Cliched color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Interpret creatively and make unexpected choices that feel genuinely designed for the context.
Vary between light and dark themes, different fonts, different aesthetics. You still tend to
converge on common choices (Space Grotesk, for example) across generations. Avoid this: it is
critical that you think outside the box!
</frontend_aesthetics>
```

### How to Integrate

| Integration Point | How | Purpose |
|-------------------|-----|---------|
| `references/generation.md` | NEW file containing the aesthetics prompt + SpSk-specific extensions | Used by `/design-improve` when BUILDING pages |
| `references/intent.md` | MERGE overlapping anti-patterns | Used by Intent specialist when REVIEWING pages |
| `config/anti-slop.json` | SYNC banned fonts/palettes with Anthropic's list | Ensure our anti-slop config matches official guidance |
| `commands/design-improve.md` | REFERENCE `generation.md` in build phase | Apply aesthetics guidance during page generation |

### What SpSk Already Has vs What Anthropic Adds

| Dimension | SpSk coverage | Anthropic adds | Action |
|-----------|--------------|----------------|--------|
| Typography anti-patterns | Strong (our list is more specific) | "Space Grotesk" convergence warning | Add Space Grotesk to anti-slop, keep our fuller list |
| Color anti-patterns | Strong (5 named patterns) | "Purple gradients on white backgrounds" general warning | Already covered by our "Synthwave SaaS" pattern |
| Motion guidance | Moderate (CSS focus) | "One well-orchestrated page load with staggered reveals" | Integrate -- this is more specific than our current motion ref |
| Backgrounds | Minimal | "Layer CSS gradients, geometric patterns, contextual effects" | NEW -- add to generation.md and layout reference |
| Layout creativity | Strong | "Asymmetry, overlap, diagonal flow, grid-breaking elements" | Merge with our layout.md |
| Variation enforcement | Absent | "Vary between light/dark themes, different fonts, different aesthetics" | NEW -- add as a design-improve constraint |

### Typography-Only Variant (from Anthropic cookbook)

The cookbook includes a typography-focused variant with specific font recommendations by category:

| Category | Anthropic Recommends | SpSk Already Recommends | Delta |
|----------|---------------------|------------------------|-------|
| Code | JetBrains Mono, Fira Code, Space Grotesk | JetBrains Mono, Fira Code, Geist Mono, IBM Plex Mono | Add Space Grotesk for code only (acceptable there) |
| Editorial | Playfair Display, Crimson Pro, Fraunces | Newsreader, Fraunces, Literata, Source Serif 4 | Note: Anthropic recommends Playfair -- we flag it. Keep our position but note the disagreement. |
| Startup | Clash Display, Satoshi, Cabinet Grotesk | Not listed | Add these -- legitimate distinctive choices |
| Technical | IBM Plex, Source Sans 3 | IBM Plex Mono (mono only) | Add Source Sans 3 for technical sans |
| Distinctive | Bricolage Grotesque, Obviously, Newsreader | Newsreader already listed | Add Bricolage Grotesque, Obviously |

**Note on Playfair Display conflict:** Anthropic recommends it for editorial use; our typography.md flags it as "#1 AI luxury serif." Resolution: keep our flag but add a note that Playfair is acceptable IF used in a genuinely editorial context (long-form articles, magazine layouts) and NOT for SaaS/landing page hero text.

### Confidence: HIGH
Source: [Anthropic Cookbook - Prompting for Frontend Aesthetics](https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics), [Claude 4.6 Best Practices -- Frontend Design section](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)

---

## 5. Playwright Interaction Before Scoring

### The Problem

Current `/design-review` takes static screenshots and reviews them. This misses:
- Hover states (dropdowns, tooltips, button color changes)
- Click states (active buttons, expanded sections, modals)
- Scroll-triggered animations (parallax, sticky headers, reveal-on-scroll)
- Focus states (form input styling, keyboard navigation highlights)
- Loading/transition states (skeleton screens, spinners)

These are critical design dimensions that specialists currently cannot evaluate.

### Available Playwright MCP Interaction Tools

From the official Microsoft `@playwright/mcp` server (verified against repo).

| Tool | Parameters | Use for Design Review |
|------|-----------|----------------------|
| `browser_hover` | `element: string` (accessibility ref), `ref: string` | Trigger hover states on buttons, links, cards before screenshot |
| `browser_click` | `element: string`, `ref: string` | Trigger modals, dropdowns, accordion expansion before screenshot |
| `browser_press_key` | `key: string` | Tab through focusable elements to capture focus ring styling |
| `browser_snapshot` | (none) | Get accessibility tree to discover interactive elements |
| `browser_take_screenshot` | `ref?: string`, `fullPage?: boolean` | Capture state after interaction |
| `browser_wait_for` | `text?: string`, `timeout?: number` | Wait for animations/transitions to complete before screenshot |
| `browser_evaluate` | `expression: string` | Run JS to detect scroll position, trigger scroll events, read computed styles |
| `browser_mouse_wheel` | `x: number`, `y: number`, `deltaX: number`, `deltaY: number` | Scroll to trigger scroll-based animations (vision mode) |
| `browser_navigate` | `url: string` | Load the page |
| `browser_console_messages` | (none) | Check for JS errors during interaction |

### Interaction-Before-Scoring Protocol

Add a new Phase 0.5b between screenshots (Phase 0) and specialist dispatch (Phase 2).

```
Phase 0: Static screenshots (desktop, mobile, fold) -- UNCHANGED
Phase 0.5a: Load design context -- UNCHANGED
Phase 0.5b: Interactive state capture -- NEW
  1. browser_snapshot to discover interactive elements
  2. For each discoverable interactive element type:
     a. Hover: browser_hover -> browser_take_screenshot -> save as {element}-hover.png
     b. Click (if safe): browser_click -> browser_take_screenshot -> save as {element}-click.png
     c. Undo click: browser_navigate_back or browser_click again
  3. Scroll: browser_evaluate("window.scrollTo(0, document.body.scrollHeight)") -> screenshot scroll state
  4. Tab-focus: browser_press_key("Tab") x 5 -> screenshot focus states
  5. Collect all interaction screenshots alongside static ones
Phase 1: Page analysis -- UNCHANGED
Phase 2: Specialist dispatch with BOTH static AND interaction screenshots
```

### What to Interact With (Discovery via Accessibility Snapshot)

Use `browser_snapshot` to get the accessibility tree, then selectively interact:

| Element Type | Interaction | Why |
|-------------|------------|-----|
| Buttons | Hover + screenshot | Hover state design is a critical differentiator |
| Links in nav | Hover + screenshot | Navigation hover feedback matters |
| Form inputs | Click (focus) + screenshot | Focus ring styling is often missing |
| Cards with hover effects | Hover + screenshot | Card hover transforms are common design patterns |
| Dropdown triggers | Click + screenshot | Dropdown menu design quality |
| Accordion/collapse | Click + screenshot | Expanded content layout |

### What NOT to Interact With

| Skip | Why |
|------|-----|
| External links | Navigating away loses page state |
| Delete/destructive buttons | Could modify the page |
| Login/logout | Changes auth state |
| Form submit | Side effects |
| More than 8 interactions per page | Diminishing returns, each interaction costs time |

### Interaction Budget

Cap at 8 interactions per review. Prioritize by element prominence:
1. Primary CTA button hover (always)
2. Navigation links hover (always)
3. First form input focus (if forms exist)
4. First card/interactive element hover (if exists)
5. Scroll to trigger scroll-based animations (always)
6. Any dropdown/accordion triggers (if exist, max 2)

### Passing Interaction Data to Specialists

Extend the specialist prompt context:

```markdown
<interaction_states>
The following interaction screenshots capture hover, focus, and active states.
Evaluate whether interactive states are well-designed, consistent, and serve the page intent.

Available states:
- {element}-hover.png: {description}
- {element}-focus.png: {description}
- scroll-bottom.png: Page scrolled to bottom
</interaction_states>
```

The Motion specialist and Code/A11y specialist benefit most from interaction screenshots. Typography and Color specialists primarily use static screenshots.

### Scroll Detection via browser_evaluate

Since the official Playwright MCP does not have a dedicated scroll tool (no `browser_scroll`), use `browser_evaluate` to trigger scrolling:

```javascript
// Scroll to bottom
window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });

// Scroll to specific percentage
window.scrollTo({ top: document.body.scrollHeight * 0.5, behavior: 'smooth' });
```

Alternatively, in vision mode, use `browser_mouse_wheel` for more natural scroll simulation.

### Confidence: HIGH
Sources: [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp), [Simon Willison - Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code)

---

## New Files for v1.2.0

| File | Type | Purpose |
|------|------|---------|
| `references/generation.md` | Reference | Anthropic aesthetics prompt + SpSk extensions for `/design-improve` build phase |
| `evals/run-quality-evals.sh` | Bash | Layer 2 eval runner -- fixture serving, review invocation, judge scoring |
| `evals/judge-prompt.txt` | Text | Reusable judge prompt template for quality assertions |

### Existing Files Modified

| File | Change |
|------|--------|
| `commands/design-review.md` | Restructure all specialist prompts to XML template; add interaction phase; JSON output format |
| `commands/design-improve.md` | Reference generation.md; parse JSON specialist output for fix extraction |
| `references/intent.md` | Merge Anthropic backgrounds guidance; add variation enforcement |
| `references/typography.md` | Add Space Grotesk to flagged fonts; add Clash Display, Satoshi, Cabinet Grotesk to recommendations |
| `config/anti-slop.json` | Sync with Anthropic list; add Space Grotesk, add backgrounds guidance |
| `config/scoring.json` | Update weights for 7 specialists (Copy folded into Intent); update total_weight from 17 to 16 |
| `evals/assertions.json` | Add `type` field to existing assertions; add quality-type assertions |
| `evals/run-evals.sh` | Call run-quality-evals.sh for Layer 2 |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| promptfoo | npm dependency. Overkill for 12-20 assertions. Our bash eval runner is simpler and zero-dependency. | `run-quality-evals.sh` + `curl` to Claude API |
| DeepEval / OpenEvals | Python frameworks. Wrong ecosystem for a Claude Code plugin. | Bash + curl judge |
| Zod / JSON Schema validators | npm dependency. `jq -e` validates JSON structure sufficiently. | `jq` for JSON validation |
| LangChain / LangSmith | SDK-heavy, wrong abstraction. We do not build LangChain apps. | Direct curl to Messages API |
| Anthropic SDK (`anthropic` npm package) | npm dependency. curl works. | `curl` to Messages API |
| promptfoo CLI | While npx-able, adds Node.js runtime requirement to eval flow. | Pure bash eval runner |
| Playwright test runner (`@playwright/test`) | We are not running tests. Interaction capture is browser automation, not test execution. | Playwright MCP tools |
| Vision-mode Playwright MCP | Coordinate-based clicking is less reliable than accessibility-ref-based clicking for design review. | Default snapshot mode |
| Separate interaction specialist agent | Adding a 9th specialist for interaction states over-fragments the review. | Pass interaction screenshots to existing specialists. |

---

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|-------------------------|
| Prompt structure | XML-tagged sections | Markdown headers | If XML feels over-engineered for simple specialists. Use XML for complex prompts (Intent), markdown for simple ones (Icon). |
| JSON enforcement | Prompt-based with `<output_format>` + retry | Freeform text with regex parsing | Never. The current regex approach is the problem being solved. |
| Eval judge | Claude Haiku via curl | Claude Sonnet via curl | If Haiku produces unreliable judge scores. Sonnet costs 10x more but may be needed for nuanced quality criteria. Start with Haiku. |
| Scoring rubric | 4-point categorical (1-4) | Binary (pass/fail) | For quality eval assertions, binary is better. For specialist scoring, keep 4-point scale. |
| Interaction capture | Selective (8 interaction budget) | Comprehensive (all interactive elements) | Never. Comprehensive interaction wastes time and tokens. Budget approach covers the important states. |
| Aesthetics integration | Merge into existing references + new generation.md | Wholesale replace anti-slop.json | No. Our anti-slop is more specific than Anthropic's general guidance. Merge, do not replace. |

---

## Version Compatibility

| Component | Requires | Notes |
|-----------|----------|-------|
| Claude 4.6 prompt patterns | Claude Code with Opus 4.6 or Sonnet 4.6 | XML tags, adaptive thinking, improved instruction following |
| JSON output from prompts | Claude 4.5+ | Reliable JSON from prompt engineering requires 4.5+ models |
| `jq` for JSON validation | macOS (built-in) or Linux (`apt install jq`) | Used by orchestrator to validate specialist JSON output |
| `curl` for API calls | Universal | Used by eval judge to call Anthropic Messages API |
| `ANTHROPIC_API_KEY` env var | Required for Layer 2 quality evals only | Not required for normal plugin usage -- only for running evals |
| Playwright MCP interaction tools | `@playwright/mcp@latest` via npx | Already required by v1.1.0 for flow audit |
| `browser_hover`, `browser_click` | Playwright MCP core tools | Available in default snapshot mode |
| `browser_evaluate` for scrolling | Playwright MCP core tool | No vision mode required for JS-based scroll |

---

## Installation

**No new installations required for plugin users.** All changes are prompt engineering (`.md` files), configuration (`.json` files), and eval scripts (`.sh` files).

For running Layer 2 quality evals (developers/contributors only):

```bash
# Required: Anthropic API key for judge calls
export ANTHROPIC_API_KEY="sk-ant-..."

# Required: jq for JSON parsing
# macOS: brew install jq (usually pre-installed)
# Linux: apt install jq

# Run evals
./evals/run-evals.sh
```

---

## Sources

- [Anthropic Claude 4.6 Prompting Best Practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices) -- Comprehensive guide covering XML tags, roles, examples, structured output, agentic systems (HIGH confidence)
- [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) -- Context as finite resource, sub-agent architectures, few-shot patterns (HIGH confidence)
- [Anthropic Cookbook: Prompting for Frontend Aesthetics](https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics) -- Full DISTILLED_AESTHETICS_PROMPT text and variants (HIGH confidence)
- [Anthropic Frontend Design Skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) -- Official design skill structure and philosophy (HIGH confidence)
- [Anthropic Structured Outputs Documentation](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) -- JSON schema enforcement via API and prompt-based approaches (HIGH confidence)
- [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp) -- Official tool list: browser_hover, browser_click, browser_evaluate, browser_snapshot, browser_take_screenshot (HIGH confidence)
- [Simon Willison: Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) -- Real-world usage patterns and tips (MEDIUM confidence)
- [LLM-as-Judge Best Practices](https://www.montecarlodata.com/blog-llm-as-judge/) -- Categorical scales, rubric design, bias avoidance (MEDIUM confidence)
- [Promptfoo LLM Rubric](https://www.promptfoo.dev/docs/configuration/expected-outputs/model-graded/llm-rubric/) -- Rubric assertion format and scoring (MEDIUM confidence)
- [G-Eval (Liu et al., EMNLP 2023)](https://arxiv.org/html/2603.00077v1) -- Chain-of-thought evaluation steps from rubric criteria (MEDIUM confidence)

---
*Stack research for: v1.2.0 Prompt Quality + Eval Credibility milestone*
*Researched: 2026-03-29*
