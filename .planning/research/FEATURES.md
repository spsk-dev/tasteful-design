# Feature Research: v1.2.0 Prompt Quality + Eval Credibility

**Domain:** Multi-agent design review -- prompt engineering overhaul, quality evaluation, structured output, interaction-before-scoring, specialist consolidation
**Researched:** 2026-03-29
**Confidence:** HIGH (Anthropic official docs + production multi-agent patterns + direct codebase analysis)

## Feature Landscape

### Table Stakes (Users Expect These)

Features that v1.2.0 must deliver. Without these, the "prompt quality" milestone claim is hollow.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| XML-structured specialist prompts | Anthropic's official best practice: "XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs." Current prompts use bare markdown with no structural separation between role, context, instructions, and output format. | MEDIUM | Wrap each specialist prompt in `<role>`, `<context>`, `<instructions>`, `<output_format>`, `<examples>` tags. This is the single highest-ROI change -- it eliminates ambiguity about what is an instruction vs what is context. |
| Few-shot examples in every specialist prompt | Anthropic: "Examples are one of the most reliable ways to steer Claude's output format, tone, and structure. A few well-crafted examples can dramatically improve accuracy and consistency." Current specialists have zero examples of what a good finding looks like vs a bad one. | HIGH | Each specialist needs 2-3 curated examples showing: (1) a well-written finding with specific evidence, (2) a poorly-written vague finding to avoid, (3) an edge case showing the correct score for a borderline situation. This is the most labor-intensive feature because each example must be hand-crafted per domain. |
| Explicit scoring rubric per specialist | Current prompts say "Score: Typography Quality 1-4" with no definition of what 1 vs 2 vs 3 vs 4 means. LLM-as-judge research is unambiguous: "LLM-as-judge performs better with a categorical integer scoring scale with very clear explanations of what each score category means." | MEDIUM | Define 4-level rubric for each specialist: 1 = broken/unusable (with concrete example), 2 = functional but mediocre, 3 = good/professional, 4 = excellent/distinctive. Rubrics go in reference files, not in the prompt itself (keeps prompt lean). |
| Structured JSON specialist output | Current specialists return free-form markdown. The improve loop, HTML report, and eval harness all need to parse this output. Free-form text parsing is fragile and breaks on format drift. | HIGH | Define a JSON schema per specialist: `{ score: number, findings: [{ severity, description, element, fix }], summary: string }`. Specialist prompts include the schema. Parse output with `JSON.parse()` + fallback regex extraction. Anthropic's structured outputs API is not available in Claude Code subagent context, so this must be prompt-enforced. |
| Layer 2 quality evals that actually run | Current Layer 2 evals are defined (12 assertions in assertions.json) but marked TODO -- they never execute. The run-evals.sh script prints "PENDING" for Layer 2. An eval harness that only validates file structure is not credible for a portfolio project claiming "evals are the crown jewel." | HIGH | Build a runner that: (1) serves each fixture HTML, (2) invokes the review pipeline, (3) extracts scores from structured JSON output, (4) asserts scores fall within ranges, (5) reports pass/fail/flaky. This is the feature that proves the prompts actually improved. |
| Copy specialist folded into Intent/Originality/UX | The Copy specialist (Haiku agent) evaluates text quality: spelling, grammar, accents, placeholder text, CTA quality, tone match. The Intent specialist already evaluates tone match, CTA visibility, and content-design alignment. There is 60%+ overlap in what they examine. Anthropic's own docs warn: "coordination overhead grows exponentially -- merge agents with similar responsibilities and keep agent count under 5." At 8 specialists, this system is above the recommended ceiling. | LOW | Move copy-specific checks (spelling, grammar, diacritics, placeholder text, terminology consistency) into the Intent specialist's review instructions as a new "Copy Quality" subsection. Drop the Copy specialist agent entirely. Update scoring.json: remove copy weight (1), redistribute to intent_match or create a copy_quality sub-dimension within intent. Update total_weight from 17 to 16. |

### Differentiators (Competitive Advantage)

Features that set v1.2.0 apart from "just better prompts." These make the portfolio case.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Anthropic DISTILLED_AESTHETICS_PROMPT as generation.md | Anthropic published their official frontend-design skill (277K+ installs) with a specific aesthetic philosophy: bold direction, distributional convergence avoidance, contextual creativity. Integrating this as a reference file makes `/design-improve` generate better starting points and `/design-review` evaluate against Anthropic's own standard. | LOW | Extract the aesthetics guidance from Anthropic's SKILL.md into `references/generation.md`. Feed it to the improve loop during build phase. The review specialists already have their domain references -- generation.md is for the BUILD side only. No scoring impact; pure quality-of-generation improvement. |
| Chain-of-thought scoring with `<thinking>` and `<answer>` tags | Anthropic's best practice: "Use structured tags like `<thinking>` and `<answer>` to cleanly separate reasoning from the final output." Current specialists jump straight to a score. Adding a thinking step forces the specialist to reason through evidence before committing to a number, reducing score drift and improving calibration. | LOW | Add to each specialist prompt: "First reason through your findings in `<thinking>` tags, then provide your structured output in `<answer>` tags." The orchestrator parses `<answer>` for the JSON output. The `<thinking>` content is available for debugging/transparency but not parsed. |
| Playwright page interaction before specialist scoring | Current specialists evaluate static screenshots + source code. But they never see hover states, focus rings, dropdown contents, scroll-triggered animations, or modal interiors. A human reviewer would interact with the page before scoring. | MEDIUM | Before specialist dispatch (after Phase 0 screenshots), run a Playwright interaction sequence: (1) hover all buttons/links to capture hover states, (2) focus form inputs to check focus rings, (3) scroll to trigger scroll-based animations, (4) click first dropdown/select to show options, (5) open first modal if present. Capture additional screenshots of these states. Pass the interaction screenshots to relevant specialists (hover -> Color/Layout, focus -> Code/A11y, scroll animations -> Motion). |
| Eval result snapshots with regression detection | Beyond just running evals, save results as JSON snapshots and compare across runs. When a prompt change causes a score regression, flag it. | MEDIUM | Each eval run saves `evals/results/YYYY-MM-DD-HHmmss.json` with fixture scores. The runner compares against the most recent previous snapshot. If any assertion that previously passed now fails, or if a score drops by more than 0.5 from the previous run, flag as regression. This is what makes evals credible in a portfolio -- showing the trajectory, not just the current state. |
| Context-aware specialist dispatch | Anthropic warns: "If your prompts previously encouraged the model to be more thorough, dial back that guidance. Claude 4.6 models are significantly more proactive and may overtrigger on instructions needed for previous models." Current prompts were written for Claude 3.5 Sonnet. They contain aggressive language ("FLAG SPECIFICALLY", "Find at least 2 issues", "NEVER") that may cause over-triggering on Claude 4.6. | LOW | Audit all specialist prompts for aggressive directives. Replace "CRITICAL:", "NEVER", "MUST" with normal language per Anthropic guidance: "Claude Opus 4.5 and Claude Opus 4.6 are more responsive to the system prompt -- where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting." |
| Eval fixtures with known-good and known-bad extremes | Current fixtures are: admin-panel (functional), landing-page (polished), emotional-page (intentionally bad). These test a narrow range. | LOW | Add 2 more fixtures: (1) a near-perfect page (high scores expected across all dimensions -- validates the top of the range), (2) a mediocre-but-not-terrible page (mid-range scores -- validates the middle). The 5-fixture set covers the full scoring spectrum and catches both false-positives and false-negatives. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Anthropic Structured Outputs API integration | "Why not use the API's guaranteed JSON schema compliance instead of prompt-enforced JSON?" | Claude Code subagents are spawned as agents, not raw API calls. The orchestrator does not control the API parameters of subagent invocations. Structured outputs require `output_config.format` in the API request, which is not exposed in Claude Code's agent/subagent spawning interface. | Prompt-enforced JSON with `<answer>` wrapper tags + fallback regex extraction. Include the JSON schema in the prompt itself. Test compliance in evals. |
| LLM-as-judge for eval scoring | "Use a judge LLM to evaluate whether specialist output is good instead of range-based assertions" | Adds a second layer of LLM non-determinism. The judge's assessment of "good" varies run-to-run just like the specialist's scores. You end up debugging the judge instead of the specialist. Research confirms: "even state-of-the-art judges exhibit fluctuations in correlation with human judgments." | Range-based assertions for scores (deterministic check). Structural assertions for output format (JSON schema compliance). Human review for calibration (spot-check a sample). The eval harness should be deterministic where possible. |
| Auto-tuning prompts based on eval results | "If Font specialist consistently scores too high, automatically adjust the prompt to be stricter" | Prompt-tuning feedback loops are unpredictable. A small change to one specialist's prompt can cascade through the boss synthesis. The system becomes opaque -- you cannot tell why a review changed. | Manual prompt iteration guided by eval results. Run evals, review results, adjust prompts, run evals again. The human is the feedback loop. Document what changed and why in CHANGELOG. |
| Per-specialist temperature tuning | "Set lower temperature for score-heavy specialists, higher for creative ones" | Claude Code subagents do not expose temperature controls. Even if they did, temperature does not meaningfully affect scoring consistency in practice -- prompt quality does. | Better rubrics and few-shot examples. Research shows: "rubric-based scoring with examples outperforms temperature tuning for evaluation consistency." |
| Visual regression testing (pixel-diff) of fixture screenshots | "Compare screenshot of fixture HTML across runs to detect rendering changes" | Fixture HTML is static. Rendering is deterministic (same Playwright, same Chromium). Pixel diffs would always pass unless Playwright/Chromium updates change rendering. This tests the browser, not the prompts. | Focus evals on score consistency and output format compliance, which are the actual non-deterministic outputs that need testing. |
| Separate JSON schema files per specialist | "Each specialist gets its own .schema.json file for clean separation" | Over-engineering for a 7-specialist system. Schema definitions are small (10-15 lines each). Putting them in separate files means 7 more files to maintain and keep in sync. | Define schemas inline in the specialist prompt templates or in a single `schemas.json` config file with a key per specialist. |
| Real-time eval dashboard | "A web UI showing eval results, score trends, pass/fail over time" | The eval harness runs infrequently (when prompts change). A dashboard for data that updates weekly is over-engineering. | JSON result files + a simple `evals/compare.sh` script that diffs the two most recent result snapshots and prints regressions. |

## Feature Dependencies

```
Structured JSON output schema
    |
    +--enables--> Layer 2 eval runner (parses JSON scores from specialist output)
    |                 |
    |                 +--enables--> Eval result snapshots + regression detection
    |
    +--enables--> Tighter /design-improve loop (parse findings programmatically)
    |
    +--enables--> HTML report generation (structured data instead of text parsing)

XML-structured prompts
    |
    +--enables--> Few-shot examples (examples go inside <examples> tags)
    |
    +--enables--> Chain-of-thought scoring (<thinking> + <answer> separation)
    |
    +--enables--> Scoring rubrics (rubric goes inside <scoring_rubric> tags)

Copy -> Intent consolidation
    |
    +--updates--> scoring.json (weight redistribution)
    |
    +--updates--> quick_mode_weights (no change -- Copy was already skipped in quick mode)
    |
    +--updates--> assertions.json (remove copy dimension assertions, add copy_quality sub-assertions under intent)

Playwright interaction before scoring
    |
    +--requires--> Existing Phase 0 screenshot infrastructure
    |
    +--feeds--> Additional screenshots to relevant specialists
    |
    +--independent of--> Prompt restructuring (can be done in parallel)

Anthropic aesthetics integration (generation.md)
    |
    +--feeds--> /design-improve build phase only
    |
    +--independent of--> All other features (no scoring impact)
```

### Dependency Notes

- **Structured JSON output must come before Layer 2 evals:** The eval runner needs to parse specialist scores from output. Without structured output, parsing is regex-based and fragile. Build JSON output first, then build evals that rely on it.
- **XML structure must come before few-shot examples:** Examples need `<example>` tags to be distinguishable from instructions. Restructuring prompts to XML first, then adding examples into the structure.
- **Copy consolidation is independent of prompt restructuring:** You can fold Copy into Intent before or after the XML/examples/rubric work. But doing it first reduces the number of specialist prompts to rewrite from 8 to 7.
- **Playwright interaction is fully independent:** Can be developed in parallel with prompt work. It adds screenshots, not prompt changes.
- **Aesthetics integration is fully independent:** It only touches the generation/build side, not the review/scoring side.

## MVP Definition

### Launch With (v1.2.0 Core)

- [x] XML-structured specialist prompts -- foundation for everything else
- [x] Explicit 4-level scoring rubric per specialist -- most impactful single change for score calibration
- [x] Structured JSON output from specialists -- enables evals and improve loop
- [x] Copy specialist folded into Intent (8->7) -- reduces prompt rewrite scope by 1
- [x] Layer 2 eval runner that actually executes -- proves the prompts improved
- [x] Context-aware prompt language (remove over-aggressive directives) -- align with Claude 4.6 best practices

### Add After Core Works (v1.2.x)

- [ ] Few-shot examples in every specialist -- labor-intensive, add after structure is stable
- [ ] Chain-of-thought `<thinking>` + `<answer>` separation -- add after JSON output is working
- [ ] Playwright page interaction before scoring -- add after core prompt work is validated by evals
- [ ] Eval result snapshots with regression detection -- add after the runner works
- [ ] Additional eval fixtures (near-perfect, mediocre) -- add after runner works on existing 3 fixtures

### Future Consideration (v1.3+)

- [ ] Anthropic aesthetics integration as generation.md -- useful but not urgent, /design-improve already has anti-slop.json
- [ ] Eval fixtures covering Figma reference mode, style preset mode, dark mode -- expand fixture coverage based on what the runner reveals as gaps

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| XML-structured prompts | HIGH | LOW | P1 |
| Scoring rubrics (4-level per specialist) | HIGH | MEDIUM | P1 |
| Structured JSON output | HIGH | HIGH | P1 |
| Copy -> Intent consolidation (8->7) | MEDIUM | LOW | P1 |
| Layer 2 eval runner | HIGH | HIGH | P1 |
| Context-aware prompt language | MEDIUM | LOW | P1 |
| Few-shot examples | HIGH | HIGH | P2 |
| Chain-of-thought scoring | MEDIUM | LOW | P2 |
| Playwright interaction before scoring | MEDIUM | MEDIUM | P2 |
| Eval result snapshots + regression | MEDIUM | MEDIUM | P2 |
| Additional eval fixtures | LOW | LOW | P2 |
| Anthropic aesthetics (generation.md) | LOW | LOW | P3 |

**Priority key:**
- P1: Must have -- defines the milestone. Without these, "prompt quality + eval credibility" is marketing, not reality.
- P2: Should have -- significantly improves the P1 features. Add when P1 is stable and validated.
- P3: Nice to have -- polishes the edges. Low effort, defer to avoid scope creep.

## Prompt Engineering Specifics (from Anthropic Official Docs)

This section captures the specific techniques from Anthropic's published guidance that directly apply to rewriting the specialist prompts.

### What Makes a Specialist Prompt Excellent vs Mediocre

**Mediocre prompt (current state of Specialist 1 -- Font):**
```
You are a typography specialist. Read skills/design-review/references/typography.md for your expert knowledge.

PAGE CONTEXT: {PAGE_BRIEF}

REVIEW:
- Font choices: are they AI-overused? (check the reference for the overused list)
- Pairing quality: max 2 families + optional mono, contrast not conflict
...

FLAG SPECIFICALLY: Dancing Script, Playfair+Poppins combos, 3+ families...

Find at least 2 issues. Score: Typography Quality 1-4.
Return: issues list with specific elements + score + one-line summary.
```

**Problems:**
1. No XML structure -- instructions, context, and output format are mixed together
2. No examples of what a good finding looks like
3. No scoring rubric -- "1-4" with no definition of each level
4. Aggressive directives ("FLAG SPECIFICALLY", "Find at least 2 issues") that may cause over-triggering on Claude 4.6
5. Output format is vague ("issues list + score + one-line summary")
6. No `<thinking>` step -- specialist jumps straight to conclusions

**Excellent prompt (target state):**
```xml
<role>
You are a typography specialist evaluating a web page's typographic quality.
</role>

<context>
{PAGE_BRIEF -- intent, audience, primary action, design bar}
{DESIGN_SYSTEM context if .design/ exists}
</context>

<reference>
{Contents of typography.md -- loaded inline, not as a file path}
</reference>

<instructions>
Evaluate the page's typography against the reference knowledge above and the page context. Focus on:
- Font selection: quality of choices relative to page type and audience
- Pairing: contrast without conflict, max 2 families + optional mono
- Hierarchy: size scale, weight distribution, visual clarity
- Metrics: line-height by size, letter-spacing for caps and display, measure (45-75ch)

Assess how well typography serves the page's specific intent, not generic standards.
</instructions>

<scoring_rubric>
1 = Poor: AI-default fonts (Inter/Poppins as sole choice), no hierarchy, metrics violations. A developer grabbed the first Google Font result.
2 = Functional: Acceptable font choice with basic hierarchy, but no personality. Works for admin/docs, insufficient for landing/portfolio.
3 = Good: Intentional font pairing with clear hierarchy, proper metrics, personality that fits the page type. A designer would approve.
4 = Excellent: Distinctive typography that elevates the design. Thoughtful pairing with purpose, refined metrics, appropriate for the highest-bar page types.
</scoring_rubric>

<output_format>
Reason through your evaluation in <thinking> tags, then provide your assessment in <answer> tags as JSON:

<answer>
{
  "score": 3,
  "findings": [
    {
      "severity": "high",
      "description": "Body text uses Inter as sole font -- functional but signals 'no typographic decision was made'",
      "element": "body { font-family: 'Inter', sans-serif }",
      "file_line": "src/styles/global.css:12",
      "fix": "Replace with a distinctive sans like DM Sans or Plus Jakarta Sans for body, pair with Instrument Serif for headings"
    }
  ],
  "summary": "Functional typography with no personality -- default choices that serve the content but don't elevate it"
}
</answer>
</output_format>

<examples>
<example type="good_finding">
{
  "severity": "high",
  "description": "Hero heading uses Playfair Display at 64px -- the #1 AI 'luxury serif' signal. Combined with Poppins body text, this is the most common AI font pairing in 2024-2025.",
  "element": "h1.hero-title { font-family: 'Playfair Display' }",
  "file_line": "src/components/Hero.tsx:15",
  "fix": "Replace with Fraunces (variable weight, distinctive personality) or Instrument Serif (clean, modern serif). Pair with DM Sans or Figtree for body."
}
</example>

<example type="bad_finding">
{
  "severity": "medium",
  "description": "Font could be better",
  "element": "heading",
  "fix": "Use a different font"
}
NOTE: This finding is too vague. No specific font named, no file reference, no evidence for why it's a problem, no concrete alternative suggested. Every finding must be specific and actionable.
</example>
</examples>
```

### Key Anthropic Techniques to Apply

| Technique | Anthropic Source | Application to Specialist Prompts |
|-----------|-----------------|-----------------------------------|
| XML structure | "XML tags help Claude parse complex prompts unambiguously" | Wrap role, context, instructions, output format, examples in separate XML tags |
| Few-shot examples | "Include 3-5 examples for best results" | 2-3 examples per specialist: one good finding, one bad finding, one edge case |
| Roles in system prompt | "Setting a role focuses behavior and tone" | Each specialist gets a clear role definition in `<role>` tags |
| Clarity over aggression | "Claude Opus 4.5/4.6 are more responsive -- where you said 'CRITICAL: You MUST', use normal prompting" | Remove "FLAG SPECIFICALLY", "NEVER", "Find at least N issues". Use descriptive language instead. |
| Context with motivation | "Providing context or motivation behind instructions helps Claude understand your goals" | Instead of "Score 1-4" -- explain WHY each score level exists and what it means for the page |
| Long context: data at top | "Place long documents and inputs near the top of your prompt, above your query" | Reference file contents go above instructions, not after them |
| Match prompt style to output | "The formatting style used in your prompt may influence Claude's response style" | If we want JSON output, the prompt itself should demonstrate JSON (in examples) |
| Ground in quotes | "Ask Claude to quote relevant parts first before carrying out its task" | The `<thinking>` step asks the specialist to identify specific evidence before scoring |

### Structured JSON Output Strategy

**Context constraint:** Claude Code subagents cannot use Anthropic's Structured Outputs API (`output_config.format`). The API parameter is set at the request level, not controllable from within a Claude Code session.

**Strategy: Prompt-enforced JSON with wrapper tags.**

1. Define the schema in the prompt (inside `<output_format>`)
2. Specialist reasons in `<thinking>`, outputs JSON in `<answer>`
3. Orchestrator extracts content between `<answer>` tags
4. Parse with `JSON.parse()` -- if it fails, fall back to regex extraction of key fields
5. Validate required fields exist (score, findings array, summary)

**Schema per specialist type:**

```json
// Single-score specialist (Font, Color, Layout, Icon, Motion, Code/A11y)
{
  "score": 3,
  "findings": [
    {
      "severity": "critical|high|medium|low",
      "description": "string -- specific, evidence-based",
      "element": "string -- CSS selector, component name, or quoted text",
      "file_line": "string -- file:line reference or null",
      "fix": "string -- concrete, actionable fix"
    }
  ],
  "summary": "string -- one-line domain assessment"
}

// Multi-score specialist (Intent/Originality/UX -- now includes Copy)
{
  "intent_match": 3,
  "originality": 2,
  "ux_flow": 3,
  "copy_quality": 2,
  "findings": [
    {
      "dimension": "intent|originality|ux|copy",
      "severity": "critical|high|medium|low",
      "description": "string",
      "element": "string",
      "file_line": "string|null",
      "fix": "string"
    }
  ],
  "summary_intent": "string",
  "summary_originality": "string",
  "summary_ux": "string",
  "summary_copy": "string"
}
```

**Error recovery:** If JSON extraction fails:
1. Try extracting `<answer>...</answer>` content
2. Try extracting `{...}` JSON block from full output
3. Try regex for `"score": N` and build a minimal result
4. If all fail, log the raw output and assign score 0 (forces manual review)

### Eval Runner Design

**What "Layer 2 evals actually run" means in practice:**

1. Serve fixture HTML on a local port (reuse existing Phase 0 server logic)
2. Invoke the design-review pipeline against the fixture URL
3. Extract structured JSON output from each specialist
4. Assert scores fall within defined ranges (from assertions.json)
5. Assert verdict matches expected verdict
6. Save results to `evals/results/` as timestamped JSON
7. Compare against previous run for regressions

**Key design decisions:**
- Evals run inside a Claude Code session (they invoke the plugin as a command)
- Each fixture run is a full pipeline execution (Phase 0-3)
- Results are non-deterministic -- ranges must be wide enough to avoid flaky failures but narrow enough to catch real problems
- A "passing" eval means all assertions within range. A "regression" means a previously-passing assertion now fails or a score dropped significantly.

**Run frequency:** After each prompt rewrite. Not on every commit (too expensive in tokens).

## Competitor Feature Analysis

| Feature | Anthropic frontend-design Plugin | Vercel v0 | This Plugin (SpSk design-review) |
|---------|----------------------------------|-----------|----------------------------------|
| Prompt quality | ~400 tokens, pure aesthetic direction, no scoring | Not applicable (generation only) | 8 specialist prompts, 6 reference files, weighted scoring. Needs XML structure and rubrics. |
| Output structure | Free text (generates code) | Free text (generates code) | Moving to structured JSON per specialist. Unique differentiator for eval-driven quality. |
| Evaluation | None -- visual before/after comparison | None | Range-based assertions with regression detection. The strongest eval story in the design-agent space. |
| Design philosophy | "Bold aesthetic direction, distributional convergence avoidance" | "Code generation from prompts" | "Domain-expert critique against curated references with weighted consensus." Complementary, not competing. |
| Interaction testing | None | None | Playwright interaction before scoring (hover, focus, scroll, dropdown). Novel in design review tools. |

## Sources

- [Anthropic Prompting Best Practices (Claude 4.x)](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices) -- PRIMARY source. Covers XML structure, examples, roles, thinking, agentic systems. HIGH confidence.
- [Anthropic Prompt Engineering Overview](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/overview) -- Structure of the documentation. HIGH confidence.
- [Anthropic Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) -- JSON schema compliance via API. HIGH confidence. (Not directly usable in Claude Code subagents, but informs schema design.)
- [Anthropic Frontend Design Skill (SKILL.md)](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) -- Official 400-token design skill. HIGH confidence.
- [Improving Frontend Design Through Skills (Anthropic Blog)](https://claude.com/blog/improving-frontend-design-through-skills) -- Distributional convergence, altitude calibration. MEDIUM confidence.
- [LLM-As-Judge: 7 Best Practices & Evaluation Templates](https://www.montecarlodata.com/blog-llm-as-judge/) -- Rubric design, scoring scale guidance. MEDIUM confidence.
- [LLM-as-a-Judge Simply Explained (Confident AI)](https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method) -- Categorical scoring outperforms float scoring. MEDIUM confidence.
- [A Pragmatic Guide to LLM Evals for Devs](https://newsletter.pragmaticengineer.com/p/evals) -- Range-based assertions, non-determinism handling. MEDIUM confidence.
- [Designing Effective Multi-Agent Architectures (O'Reilly)](https://www.oreilly.com/radar/designing-effective-multi-agent-architectures/) -- Coordination tax, agent count recommendations. MEDIUM confidence.
- [Choosing the Right Multi-Agent Architecture (LangChain)](https://blog.langchain.com/choosing-the-right-multi-agent-architecture/) -- When to consolidate vs keep separate. MEDIUM confidence.
- [Multi-Agent Collaboration in Practice (BetterLink)](https://eastondev.com/blog/en/posts/ai/20260325-multi-agent-system/) -- Hybrid control models, latency scaling. MEDIUM confidence.
- [Playwright Actions](https://playwright.dev/docs/input) -- Hover, click, focus, scroll interaction APIs. HIGH confidence.
- [Playwright Visual Testing](https://www.chromatic.com/blog/how-to-visual-test-ui-using-playwright/) -- State capture patterns. MEDIUM confidence.
- Direct analysis of existing codebase: `commands/design-review.md`, `config/scoring.json`, `evals/assertions.json`, `evals/run-evals.sh`, specialist reference files. HIGH confidence.

---
*Feature research for: v1.2.0 Prompt Quality + Eval Credibility*
*Researched: 2026-03-29*
