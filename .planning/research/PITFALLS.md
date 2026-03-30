# Pitfalls Research

**Domain:** Prompt engineering overhaul, LLM quality evals, structured JSON output, agent role consolidation, Playwright interaction-before-scoring, and external prompt pattern integration -- for an existing multi-agent design review Claude Code plugin
**Researched:** 2026-03-29
**Milestone:** v1.2.0 Prompting Excellence + Eval Credibility
**Confidence:** HIGH (pitfalls 1-5, 7-8), MEDIUM (pitfalls 6, 9-12)

---

## Critical Pitfalls

### Pitfall 1: Prompt Rewrite Regression -- Improving One Specialist Degrades Another

**What goes wrong:**
The prompts in design-review.md are 732 lines of interconnected instructions. Rewriting Specialist 6 (Intent/Originality/UX) to add XML tags and few-shot examples changes its output structure. The Boss Synthesizer in Phase 3 parses specialist outputs by looking for "Score: X/4" and issue lists. The rewritten specialist outputs `<score>3</score>` instead. Phase 3 fails to extract the score, produces NaN, and the weighted verdict breaks. Or: rewriting the Color specialist prompt to be more structured causes it to stop flagging "AI purple gradient" because the new structured format constrains its reasoning too much.

**Why it happens:**
The 8 specialists + boss form a pipeline where downstream consumers (Boss Synthesizer, /design-improve fix applicator, re-review targeting) depend on implicit output contracts. The current prompts work because the Boss knows how specialists format their output -- it was written to parse THAT format. Rewriting prompts without updating all consumers creates silent format mismatches.

Research confirms this is the top risk: "a 2% overall dip can mask a 15% collapse in a single category" when rewriting prompts, and "overall averages hide regressions" (Anup.io prompt regression testing). Category-level tracking is essential.

**How to avoid:**
1. **Baseline BEFORE rewriting.** Run the current prompts against all 3 eval fixtures (admin-panel.html, landing-page.html, emotional-page.html) and record exact scores per specialist per fixture. This is the regression baseline.
2. **Rewrite one specialist at a time.** After each rewrite, re-run the same 3 fixtures and compare per-specialist scores. If any specialist deviates by more than 0.5 from baseline, investigate before proceeding.
3. **Define explicit output contracts.** Before rewriting, document exactly what format each specialist MUST output (score format, issue list format, summary format) and what Phase 3 expects to parse. The contract is the handshake -- prompts can change, contracts cannot (until the parser changes too).
4. **A/B test within the same review.** For the first pass, run old and new prompts side-by-side on the same screenshots and compare outputs. This catches reasoning regressions that score ranges alone miss.

**Warning signs:**
- Phase 3 produces NaN or null scores after a prompt rewrite
- /design-improve stops applying fixes (it can't parse the new issue format)
- Scores on the "emotional-page.html" fixture (intentionally bad design) rise above 2.0 after rewrites
- Quick mode (`--quick`) produces different relative ranking than full mode for the same page

**Phase to address:**
Phase 1 (Prompt Overhaul) -- this is the first and most dangerous change. Must have baseline evals running BEFORE any prompt changes begin.

---

### Pitfall 2: Quality Evals That Pass on Accident and Fail on Accident -- Flakiness

**What goes wrong:**
The current assertions.json has 12 assertions with ranges like `min: 2.0, max: 3.2` for "Admin panel overall score." LLM scoring is inherently stochastic -- the same prompt on the same fixture can produce scores varying by 0.5-1.0 across runs. An assertion with range 2.0-3.2 passes 70% of the time, fails 30%. The eval suite becomes a coin flip that nobody trusts. Developers ignore failures ("it's just flaky") and miss real regressions.

**Why it happens:**
LLMs produce different outputs even with identical inputs due to sampling temperature and model state. A score of 2.9 on one run becomes 3.4 on the next. Range-based assertions that are too tight catch noise; ranges that are too wide catch nothing. The 2025-2026 eval research consistently identifies this as the hardest problem: "LLMs are inherently stochastic, producing different outputs even with the same input on different runs" (Confident AI).

Additionally, the current run-evals.sh has Layer 2 as `[TODO]` -- it counts assertions but doesn't actually execute them. The gap between "assertions defined" and "assertions executed" is where false confidence lives.

**How to avoid:**
1. **Run each fixture 3 times to calibrate ranges.** Before setting min/max, run the full review 3 times on each fixture. Use the observed min-0.3 and observed max+0.3 as the assertion range. This accounts for stochastic variance.
2. **Use binary verdict assertions as the primary eval, score ranges as secondary.** "emotional-page.html always gets BLOCK" is a deterministic, meaningful assertion. "Admin panel scores between 2.0 and 3.2" is noise-prone. Prioritize verdict-level assertions.
3. **Track flake rate.** If an assertion fails >20% of runs but passes >50%, it's flaky -- widen the range or restructure the assertion. If it fails >80%, it's a real regression.
4. **Separate structural evals from quality evals.** Structural: "output contains exactly 10 scored dimensions" (deterministic). Quality: "typography score for bad-design fixture is below 2.0" (stochastic). Different tolerance for each.
5. **Use LLM-as-judge for output quality, not score comparison.** Instead of asserting score ranges, assert output properties: "specialist identified at least one issue from the banned-fonts list" or "verdict explanation references the page type." These are deterministic checks on non-deterministic output.

**Warning signs:**
- Same eval suite produces different pass/fail results on consecutive runs with no code changes
- Developers stop running evals because "they're flaky anyway"
- An actual regression ships because the eval that would catch it was already marked as "known flaky"
- All assertions pass on every run (ranges are too wide to catch anything)

**Phase to address:**
Phase 2 (Quality Evals Layer 2) -- must be addressed before prompt rewrites are validated, since the evals ARE the validation.

---

### Pitfall 3: Structured JSON Output Degrades Specialist Reasoning Quality

**What goes wrong:**
Specialists currently output free-form text: findings, a score, and a summary. Switching to structured JSON (`{"score": 3, "issues": [{"severity": "high", "description": "..."}]}`) constrains the model's reasoning pathway. Research shows "forcing an LLM to output JSON can degrade its reasoning by 10-15%" (Agenta.ai). The Typography specialist stops noticing subtle pairing issues because the JSON schema forces it to categorize findings into predefined severity buckets, and "interesting but not clearly high/medium/low" observations get dropped.

**Why it happens:**
Structured output forces the model to commit to a schema before completing its analysis. Free-form text allows the model to "think out loud," discover connections mid-response, and surface unexpected findings. JSON schemas create premature commitment -- the model decides the structure before finishing the thought. This is especially damaging for the Intent/Originality/UX specialist (weight 3x), which does nuanced, comparative reasoning.

Additionally, schema evolution becomes a maintenance burden. Every consumer of specialist output (Boss Synthesizer, /design-improve, re-review, generate-report.sh, HTML report template) must be updated when the schema changes. With free-form text, the Boss could adapt. With JSON, a missing field crashes the pipeline.

**How to avoid:**
1. **Think-then-structure pattern.** Let specialists reason in free-form text first, then produce a structured summary at the end. The prompt should say: "First, analyze thoroughly in a <reasoning> block. Then, produce your final assessment as JSON in a <output> block." This preserves reasoning quality while giving structured output for machine consumption.
2. **Minimal schema, not maximal.** Only structure what downstream consumers actually need: score, issue list with severity, and one-line summary. Do NOT structure the reasoning process itself (don't demand `{"observations": [{"area": "...", "finding": "..."}]}`).
3. **Schema versioning from day one.** Put `"schema_version": "1.0"` in the output. When the schema changes, increment. Consumers check the version and adapt. This costs nothing upfront and saves the v1.3.0 migration.
4. **Keep backward-compatible parsing.** The Boss Synthesizer should accept BOTH the old free-form format and the new JSON format during the transition. Hard-switching all 8 specialists at once is high-risk. Switch one at a time and verify.
5. **Zero npm dependencies constraint.** JSON parsing in bash (via `jq`) is sufficient. Do not add a JSON schema validator. The `jq` commands in validate-structure.sh already demonstrate this pattern works.

**Warning signs:**
- Specialist outputs become shorter after JSON conversion (reasoning was suppressed)
- Intent/Originality specialist scores cluster toward the middle (2.5-3.0) instead of the current wider distribution
- /design-improve fix applicator can't find specific enough information in the structured output to know WHAT to fix
- The Boss Synthesizer's cross-specialist agreement detection breaks (it currently does text matching for similar findings across specialists)

**Phase to address:**
Phase 3 (Structured JSON Output) -- must come AFTER prompt rewrites (Phase 1) and eval calibration (Phase 2) so the baseline is clean.

---

### Pitfall 4: Copy-to-Intent Merge Creates a Bloated Three-Headed Prompt

**What goes wrong:**
Specialist 6 (Intent/Originality/UX) already produces 3 scores from one prompt and is the most complex specialist at 37 lines. Adding Copy review responsibilities creates a prompt that asks for 4+ dimensions from one agent. The prompt balloons to 50+ lines, the agent's attention is split across too many concerns, and the quality of each dimension degrades. The Intent score (3x weight) drops because the specialist is spending tokens on copy review instead of deep intent analysis.

**Why it happens:**
Copy (Specialist 7) and Intent (Specialist 6) seem related -- "copy supports intent." But they require fundamentally different analytical modes. Copy review is close-reading: grammar, spelling, diacritics, placeholder text, generic labels. Intent review is holistic: does the visual design match the page's purpose? These are zoom-in vs. zoom-out tasks. Combining them in one prompt forces the model to constantly switch analytical modes, degrading both.

The scoring weights compound the problem. Currently: Intent 3x + Originality 3x + UX 2x + Copy 1x = 9 weight points from 4 scored dimensions. The total weight changes from /17 to /16 (removing Copy's standalone 1x). But does Copy get its own score within the merged specialist, or does it fold into one of the three existing scores? Either way, the math changes, the thresholds shift, and every existing eval assertion is invalidated.

**How to avoid:**
1. **Merge scoring ONLY, not analysis.** Keep Copy as a separate analysis section within the specialist's prompt, with its own clear instructions and its own score. The merged specialist produces 4 scores: Intent, Originality, UX Flow, and Copy Quality. This preserves the analytical separation while reducing agent count.
2. **Update scoring weights atomically.** The moment Copy is merged, update scoring.json: change `total_weight` from 17 to 16, adjust `quick_mode_total_weight`, and recalibrate all assertions. Do NOT merge the specialist without updating the math -- a single run with wrong weights produces garbage verdicts.
3. **Test the merged specialist against Copy-specific fixtures.** Create a test fixture with intentional copy issues (lorem ipsum, missing Spanish accents, generic "Submit" buttons). Verify the merged specialist catches them at the same rate as the standalone Copy specialist.
4. **Set a token/line budget for the merged prompt.** If the combined prompt exceeds 45 lines of instruction, it's too long. Either trim or keep them separate. Research on multi-task prompts shows degradation when instruction complexity exceeds the model's "attention budget."

**Warning signs:**
- Intent/Originality scores drop after the merge (the specialist is distracted by copy concerns)
- Copy issues go undetected that the standalone specialist would have caught
- The merged specialist's output is significantly longer but scores are the same or lower
- Quick mode (which already uses this specialist for 3 scores) becomes unreliable

**Phase to address:**
Phase 4 (Specialist Consolidation) -- must come AFTER prompt rewrites and eval calibration. The merge is the lowest-priority change and should be cut if the prompt overhaul + evals take longer than expected.

---

### Pitfall 5: Playwright Interaction Before Scoring Mutates the Page State That Gets Scored

**What goes wrong:**
The plan is to hover, click, and scroll before specialist analysis to trigger interactive states (hover effects, dropdown menus, tooltips, scroll animations). But interaction mutates the DOM. A hover on a navigation menu opens a dropdown that covers 30% of the page. A click on an accordion expands it, pushing content below the fold. A scroll triggers lazy-loading that changes the layout. The screenshot taken AFTER interaction shows a page state the user never normally sees (dropdown open + accordion expanded + lazy images loaded simultaneously). Specialists review an artificial composite state, not any real user experience.

**Why it happens:**
Browser interactions are stateful and cumulative. There's no "undo hover" in Playwright. Each interaction changes the page permanently for that browser session. The intent is to discover interactive behaviors, but the side effect is that the page is no longer in its default state for the main review.

Playwright's docs confirm: "afterEach hooks change the states of the page, and after their execution, the issue is no longer visible" -- the same principle applies here in reverse. Your pre-scoring interactions leave state artifacts that contaminate the review.

**How to avoid:**
1. **Interaction-then-reset pattern.** Take a baseline screenshot FIRST (clean page state). Then interact to discover behaviors. Then navigate to the same URL again (full page reload, not SPA navigation) to reset DOM state. Take the review screenshot on the clean reload. Specialists get the clean screenshot; interaction findings are passed as metadata.
2. **Separate interaction audit from design review.** Don't merge these into one pass. The design review scores the page's visual design. A separate "interaction report" documents what happens on hover/click/scroll. This avoids the state contamination entirely and aligns with the existing `/design-validate` command's domain.
3. **If interaction MUST happen before review:** Use Playwright's `page.screenshot()` at each step: (a) clean state, (b) after hover, (c) after click, (d) after scroll. Pass ALL screenshots to specialists with labels. But accept the token cost: 4 screenshots per interaction point is expensive.
4. **Playwright MCP constraint.** The design-audit command already uses Playwright MCP (`browser_navigate`, `browser_snapshot`, `browser_click`). For design-review, interaction means adding MCP dependency to a command that currently only uses CLI screenshots. This is a significant dependency escalation. Consider making interaction opt-in: `--interact` flag rather than default.

**Warning signs:**
- Specialists report issues with elements that are in hover/expanded state but shouldn't be
- Screenshots show multiple interactive elements open simultaneously (impossible in normal usage)
- Motion specialist reports "no animations" because the page was already in its post-animation state when screenshotted
- Page reload between interaction and review adds 2-5 seconds per review, slowing the pipeline significantly

**Phase to address:**
Phase 5 (Playwright Interaction) -- the latest phase, and should be opt-in. The highest-value version is interaction CATALOG (what interactive states exist) rather than interaction SCORING (judging the page while in interactive states).

---

### Pitfall 6: Anthropic Aesthetics Prompt Conflicts with Existing Specialist Prompts

**What goes wrong:**
Anthropic's DISTILLED_AESTHETICS_PROMPT (from the frontend-design skill) tells Claude: "Avoid generic fonts like Arial and Inter; opt instead for distinctive choices." The existing Typography specialist's reference file (typography.md) has its own banned fonts list: "Dancing Script, Playfair Display, Poppins." The Color specialist's reference says "avoid AI purple gradients." The anti-slop.json has yet another banned list. Three overlapping-but-different sources of truth for "what looks bad" create conflicts: the aesthetics prompt bans Inter, the typography reference bans Poppins, and anti-slop.json bans Montserrat. Which list wins? What happens when they contradict (aesthetics prompt recommends a font that typography.md flags)?

**Why it happens:**
The Anthropic aesthetics prompt was designed as a GENERATION prompt (telling Claude what to build). The specialist prompts are EVALUATION prompts (telling Claude what to judge). Generation and evaluation have different needs. A generation prompt says "be creative, use distinctive fonts." An evaluation prompt says "check if the fonts are appropriate for the page type." Bolting a generation prompt onto an evaluation system creates role confusion.

**How to avoid:**
1. **Adapt, don't copy-paste.** Extract the PRINCIPLES from the aesthetics prompt (variety over defaults, cohesive themes, motion for delight) and weave them into the existing evaluation prompts. Do NOT append the raw aesthetics prompt to specialist instructions.
2. **Single source of truth per concern.** Fonts: typography.md is the authority. Colors: color.md is the authority. Anti-patterns: anti-slop.json is the authority. The aesthetics prompt's content should be MERGED into these existing files, not added as a fourth source. Conflicts must be resolved at merge time, not at runtime.
3. **Generation vs. evaluation split.** The aesthetics prompt goes into /design-improve (generation context, where it helps Claude BUILD better pages). The evaluation prompts in /design-review stay focused on JUDGING what exists. These are different jobs requiring different instructions.
4. **Test for contradictions.** After integration, review a page that uses Inter (banned by aesthetics prompt, not banned by current specialists). Does the score change? It should only change if the typography specialist's criteria actually changed.

**Warning signs:**
- Typography specialist starts flagging fonts it didn't flag before, without explicit prompt changes to that specialist
- /design-improve and /design-review give contradictory guidance ("improve said use X font, review then flagged X font")
- Specialist prompts exceed 50 lines after aesthetics integration (prompt bloat)
- The anti-slop.json, typography.md, and aesthetics prompt have 3 different banned font lists

**Phase to address:**
Phase 1 (Prompt Overhaul) -- aesthetics integration must happen during the prompt rewrite, not as a separate bolt-on. This ensures conflicts are resolved in one pass.

---

### Pitfall 7: Eval Fixtures That Game the Eval Instead of Testing the System

**What goes wrong:**
The current fixtures are designed to be obviously good (landing-page.html) or obviously bad (emotional-page.html with Comic Sans + Papyrus + neon colors). The evals test extremes. A prompt rewrite that makes all specialists more generous (scoring 0.5 higher across the board) still passes every assertion because the ranges accommodate it. The eval harness becomes a confidence theater that proves nothing about prompt quality.

Goodhart's law applies directly: "When a measure becomes a target, it ceases to be a good measure." If prompt rewrites are validated only against these 3 fixtures, the prompts will be optimized for these 3 fixtures, not for real-world design quality assessment.

**Why it happens:**
Building eval fixtures is tedious. Creating a page that scores exactly 2.5 (mediocre but not terrible) is harder than creating one that scores 1.0 (obviously garbage) or 3.5 (obviously good). The middle of the range is where real design quality decisions happen, but it's the hardest to test.

**How to avoid:**
1. **Add "gray area" fixtures.** Create 2-3 fixtures that represent real-world design ambiguity: a page with good typography but terrible color, a page with strong intent but weak execution, a page that's competent but generic (should not SHIP for a portfolio page but should SHIP for admin). These test the specialists' ability to discriminate, not just detect extremes.
2. **Cross-fixture assertions.** "Landing page intent score > admin panel intent score" tests relative ranking, which is more stable across runs than absolute scores. If a prompt rewrite breaks the ranking, it broke something meaningful.
3. **Live validation on start.fusefinance.com.** This is already in the PROJECT.md requirements. Running the review on a real, complex production page is the ultimate eval. Record the results as a "golden run" and compare subsequent reviews against it.
4. **Assertion on reasoning, not just scores.** "Typography specialist mentions 'font pairing' in its analysis" tests whether the specialist is actually performing its function, regardless of what score it gives.

**Warning signs:**
- All assertions pass after a prompt rewrite, but running on a real page produces noticeably different results
- Score distributions narrow (everything scores 2.5-3.0) instead of the expected wide distribution
- No assertion ever fails in CI -- the ranges are too generous to catch anything

**Phase to address:**
Phase 2 (Quality Evals) -- gray area fixtures should be created alongside the eval infrastructure, not after.

---

### Pitfall 8: Prompt Engineering Cargo Cult -- Applying Patterns Without Understanding Why

**What goes wrong:**
Anthropic's best practices say "use XML tags for structure" and "give Claude a role." The developer wraps every instruction in `<instructions>` tags and adds "You are an expert typography specialist" to every prompt. But the CURRENT prompts already work because they give clear, direct instructions without XML tags. Adding XML structure to a prompt that was already clear doesn't improve it -- it adds noise. Worse: XML tags that wrap the WRONG boundaries (e.g., wrapping the entire specialist prompt in one `<instructions>` tag instead of separating `<context>`, `<criteria>`, and `<output_format>`) make the prompt LESS clear than the original.

**Why it happens:**
Best practices are contextual. Anthropic's docs say "XML tags help Claude parse complex prompts unambiguously, ESPECIALLY WHEN your prompt mixes instructions, context, examples, and variable inputs." The specialist prompts DO mix these -- but the current structure uses whitespace and headers effectively. Adding XML without restructuring the content is cosmetic, not structural.

The biggest risk is few-shot examples. Adding examples of "good specialist output" to each prompt costs tokens (~500-800 per example per specialist, x8 specialists = 4000-6400 additional tokens per review). If the examples are low quality or unrepresentative, they anchor the specialist to bad patterns. Good few-shot examples require careful curation from real review outputs, not fabrication.

**How to avoid:**
1. **Audit what's actually broken before "improving."** Read each specialist prompt and identify specific failure modes: does the Typography specialist miss tracking on ALL CAPS? Does the Color specialist give 4/4 to objectively bad palettes? Fix THOSE problems with targeted prompt edits, not wholesale rewrites.
2. **Apply the Anthropic pattern checklist selectively:**
   - XML tags: Only add where the boundary between context, criteria, and output format is genuinely ambiguous. If whitespace already clarifies it, leave it.
   - Few-shot examples: Only add for specialists whose OUTPUT FORMAT is inconsistent across runs. If scores are consistent but issue descriptions vary, examples help format. If scores themselves vary, examples won't help -- the criteria need tightening.
   - Chain-of-thought: Only add for the Intent specialist (complex multi-dimensional analysis). The Typography specialist's review is straightforward -- CoT adds tokens without improving quality.
   - Role assignment: Already present in every specialist prompt ("You are a typography specialist"). Do not add more role context unless the specialist is consistently off-domain.
3. **Budget per specialist.** Each specialist prompt should fit on one screen (~40 lines max). If adding XML + examples + CoT pushes it past that, something must be cut. Longer prompts do not equal better prompts.

**Warning signs:**
- Prompts doubled in length but scores didn't change
- Token usage per review increased by >30% without measurable quality improvement
- All specialists produce identical output formatting (over-constrained by examples)
- The developer can't explain WHY each XML tag boundary was placed where it is

**Phase to address:**
Phase 1 (Prompt Overhaul) -- the audit-first approach must be established as the methodology before any rewrites begin. Every prompt change needs a "before" measurement and a hypothesis for what should improve.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode expected JSON structure in Boss Synthesizer | Fast to implement, works now | Schema changes require Boss rewrite, no versioning | Never -- use schema version field from day one |
| Wide assertion ranges (min:1.0, max:4.0) to avoid flakiness | All evals pass | Evals catch nothing, false confidence | During initial calibration only (tighten within 2 runs) |
| Copy raw DISTILLED_AESTHETICS_PROMPT into specialist prompts | Quick integration, "Anthropic approved" | Conflicts with existing reference files, generation/evaluation confusion | Never -- adapt principles, don't copy-paste |
| Skip baseline recording before prompt rewrites | Save time, start rewriting immediately | No way to detect regressions, every comparison is against nothing | Never -- baseline is the cheapest and most valuable investment |
| Merge Copy into Intent without updating scoring.json weights | One less specialist, simpler code | Wrong weighted scores, invalidated thresholds, eval failures | Never -- scoring update must be atomic with the merge |
| Add Playwright MCP as required dependency for design-review | Access to interaction before scoring | Plugin breaks for users without MCP setup, degrades the clean CLI-only Tier 2/3 | Only as opt-in flag (`--interact`), never as default |

## Integration Gotchas

Common mistakes when connecting the v1.2.0 features to the existing system.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Structured JSON + Boss Synthesizer | Boss looks for "Score: X/4" in free text, new JSON uses `"score": X` | Update Boss parsing to handle both formats during transition. Add a format-detection step: if output starts with `{`, parse JSON; otherwise, regex extract. |
| Prompt rewrites + /design-improve | Improve reads specialist fix lists to know what to change. New structured output changes the fix list format. | Define the fix list schema in the output contract. Improve reads from the structured `issues` array, not from free-text parsing. |
| Scoring weight changes + assertions.json | Merging Copy into Intent changes total_weight from 17 to 16. All existing assertions assume /17 math. | Bump assertions.json version. Recalibrate every range assertion after the weight change. Add a structural assertion: "total_weight in scoring.json equals sum of individual weights." |
| Aesthetics prompt + anti-slop.json | Both contain banned patterns. Changes to one don't propagate to the other. | Merge all "what to avoid" lists into anti-slop.json as the single source. Specialist prompts reference anti-slop.json, not inline banned lists. |
| Playwright interaction + screenshot timing | Interaction triggers animations. Screenshot captures mid-animation state. | Wait for animation completion after interaction: `await page.waitForFunction(() => document.getAnimations().every(a => a.playState === 'finished'))`. Or disable animations for screenshots and catalog them separately. |
| Quick mode + merged specialist | Quick mode runs 4 specialists. If Copy is merged into Intent, quick mode already includes Copy concerns. But quick mode's weight divisor (/13) may need updating. | Recalculate quick_mode_total_weight after the merge. Verify quick mode still produces proportional scores to full mode. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Few-shot examples in every specialist prompt | +4000-6400 tokens per review, 30-50% token increase | Only add examples to specialists with inconsistent output format. Others get clear criteria only. | When token-constrained users hit context limits on full 8-specialist reviews |
| Running all 12+ assertions with 3 retries each for flake mitigation | Eval suite takes 30+ minutes, costs $10+ per run | Use verdict assertions (fast, deterministic) as gate. Only run score-range assertions when verdict assertions pass. | When evals are run on every PR and developers skip them for being slow |
| Structured JSON parsing in Boss Synthesizer via string manipulation | Works for simple schemas, produces garbage on edge cases (escaped quotes, nested arrays) | Use `jq` for all JSON parsing in bash. Already used in validate-structure.sh. | When specialist output contains quotes, newlines, or unicode in issue descriptions |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Prompt rewrite:** Prompts look better formatted -- verify scores didn't shift by running the 3-fixture eval suite before AND after. A rewrite without before/after comparison is not validated.
- [ ] **Quality evals "work":** run-evals.sh exits 0 -- verify Layer 2 actually EXECUTES assertions, not just counts them. The current script says `[TODO]` for Layer 2 execution. A passing script that skips all quality checks is false confidence.
- [ ] **Structured JSON output:** Specialists produce valid JSON -- verify the Boss Synthesizer, /design-improve, re-review targeting, and generate-report.sh all parse it correctly. JSON output is useless if consumers can't read it.
- [ ] **Copy merged into Intent:** 7 specialists work -- verify scoring.json weights sum correctly, quick mode weights are updated, assertions.json is recalibrated, and the /design-review presentation table shows the right number of rows.
- [ ] **Playwright interaction:** Interactions trigger and screenshots capture -- verify the page is in CLEAN state for the actual review, not in an artifact state from prior interactions. Run a review with and without `--interact` and compare scores.
- [ ] **Aesthetics integration:** generation.md file created -- verify /design-improve reads it (generation context) and /design-review does NOT read it (evaluation context stays clean). If review prompts reference generation guidance, the separation is broken.
- [ ] **Eval assertions pass:** All 12 assertions green -- verify at least one assertion would FAIL if you deliberately break something. If deliberately scoring a bad page high still passes all assertions, the ranges are too wide.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Prompt rewrite regression (#1) | LOW | Git revert the single specialist prompt that regressed. Re-run evals to confirm recovery. Apply a more targeted edit. |
| Flaky evals (#2) | MEDIUM | Run each assertion 5 times, record min/max. Widen ranges to observed spread + 0.3 buffer. Add more verdict-level assertions which are deterministic. |
| JSON degrades reasoning (#3) | LOW | Switch affected specialist back to free-form output. Keep think-then-structure for specialists that benefit. Mixed formats are fine during transition. |
| Bloated merged specialist (#4) | LOW | Undo the merge. Keep Copy as a standalone Haiku agent (lightweight, fast). The 8-specialist architecture was validated at 8.6/10 -- changing it without evidence of improvement is unnecessary. |
| State mutation from interaction (#5) | MEDIUM | Add page reload before review screenshots. Accept the 2-5s latency. Or: make interaction opt-in via `--interact` flag instead of default. |
| Aesthetics prompt conflicts (#6) | LOW | Remove the raw aesthetics prompt from evaluation prompts. Consolidate "avoid" lists into anti-slop.json. Keep aesthetics as generation-only guidance in /design-improve. |
| Eval gaming / fixture overfitting (#7) | HIGH | Create 3+ new "gray area" fixtures. Add cross-fixture ranking assertions. Run against a live page (start.fusefinance.com) as the ultimate validation. |
| Cargo-culted prompt patterns (#8) | MEDIUM | Audit each XML tag, example, and CoT addition. For each one, verify it improved a measurable outcome. Remove additions that increased tokens without improving scores. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Prompt rewrite regression (#1) | Phase 1 (Prompt Overhaul) | Before/after 3-fixture eval comparison. Per-specialist score delta < 0.5. |
| Flaky evals (#2) | Phase 2 (Quality Evals) | Run full eval suite 3 times consecutively. Same pass/fail result all 3 times. |
| JSON reasoning degradation (#3) | Phase 3 (Structured Output) | Compare free-form vs JSON specialist output on the same fixture. Issue count and specificity must not decrease. |
| Bloated merged specialist (#4) | Phase 4 (Consolidation) | Merged specialist's 4 scores on 3 fixtures match standalone specialists' scores within 0.5. |
| State mutation from interaction (#5) | Phase 5 (Playwright Interaction) | Review with `--interact` produces same verdict as review without it on a static page. |
| Aesthetics prompt conflicts (#6) | Phase 1 (Prompt Overhaul) | Single source of truth per concern. grep for banned fonts returns results only in anti-slop.json and typography.md (merged, not duplicated). |
| Eval fixture gaming (#7) | Phase 2 (Quality Evals) | At least one "gray area" fixture exists. At least one cross-fixture ranking assertion exists. |
| Cargo-culted patterns (#8) | Phase 1 (Prompt Overhaul) | Every prompt change has a documented hypothesis and measured outcome. Token increase per review < 30%. |
| Scoring weight miscalculation (#4 sub) | Phase 4 (Consolidation) | Structural assertion in validate-structure.sh: sum of weights in scoring.json equals total_weight field. |
| Output contract breakage (#1 sub) | Phase 1 (Prompt Overhaul) | Document output contracts in a new file (e.g., output-contracts.md). Boss Synthesizer tests parse every specialist's output without errors. |
| Eval execution gap (#2 sub) | Phase 2 (Quality Evals) | run-evals.sh Layer 2 actually runs assertions and reports pass/fail per assertion. No `[TODO]` or `[SKIP]` for quality evals. |
| Token budget explosion from examples (#8 sub) | Phase 1 (Prompt Overhaul) | Measure tokens per full review before and after prompt overhaul. If increase > 30%, trim examples. |

## Sources

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- XML tags, few-shot examples, role assignment, structured output (HIGH confidence)
- [Anthropic Frontend Design Skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) -- DISTILLED_AESTHETICS_PROMPT source (HIGH confidence)
- [Ship Prompts Like Software: Regression Testing for LLMs](https://www.anup.io/ship-prompts-like-software-regression-testing-for-llms/) -- before/after methodology, category-level tracking (HIGH confidence)
- [Avoiding Common Pitfalls in LLM Evaluation](https://www.honeyhive.ai/post/avoiding-common-pitfalls-in-llm-evaluation) -- flakiness, single-metric traps, LLM-as-judge limitations (HIGH confidence)
- [Why Most LLM Benchmarks Are Misleading](https://dasroot.net/posts/2026/02/llm-benchmark-misleading-accurate-evaluation/) -- Goodhart's law, data contamination (HIGH confidence)
- [LLM Evaluation: Frameworks, Metrics, and Best Practices (2026)](https://futureagi.substack.com/p/llm-evaluation-frameworks-metrics) -- traceability, versioning (MEDIUM confidence)
- [Statistical LLM Evaluations - Confidence Scoring](https://medium.com/@sulbha.jindal/statistical-llm-evaluations-confidence-scoring-caa6c9d57656) -- confidence intervals, non-deterministic scoring (MEDIUM confidence)
- [The Guide to Structured Outputs and Function Calling with LLMs](https://agenta.ai/blog/the-guide-to-structured-outputs-and-function-calling-with-llms) -- JSON reasoning degradation, schema complexity (MEDIUM confidence)
- [LLM Structured Output in 2026](https://dev.to/pockit_tools/llm-structured-output-in-2026-stop-parsing-json-with-regex-and-do-it-right-34pk) -- field renaming, schema evolution (MEDIUM confidence)
- [Braintrust: A/B Testing LLM Prompts](https://www.braintrust.dev/articles/ab-testing-llm-prompts) -- regression detection, golden datasets (MEDIUM confidence)
- [Promptfoo](https://github.com/promptfoo/promptfoo) -- prompt regression testing framework reference (HIGH confidence)
- [Playwright Navigation Docs](https://playwright.dev/docs/navigations) -- SPA state management (HIGH confidence)
- Existing v1.0.0 and v1.1.0 research PITFALLS.md in this repo -- prior pitfall analysis for build context
- Direct inspection of commands/design-review.md (732 lines), evals/assertions.json (12 assertions), config/scoring.json (weight math), evals/run-evals.sh (Layer 2 TODO gap)

---
*Pitfalls research for: v1.2.0 Prompting Excellence + Eval Credibility*
*Researched: 2026-03-29*
