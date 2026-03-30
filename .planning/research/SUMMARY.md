# Project Research Summary

**Project:** SpSk design-review plugin — v1.2.0 Prompt Quality + Eval Credibility
**Domain:** Multi-agent design review system — prompt engineering overhaul, LLM quality evaluation, structured JSON output, specialist consolidation
**Researched:** 2026-03-29
**Confidence:** HIGH

## Executive Summary

The v1.2.0 milestone for the design-review plugin is a quality consolidation release, not a feature expansion. The existing architecture — 8 specialist agents, bash orchestration, zero npm dependencies, Playwright for screenshots — is validated and sound. What is broken is the signal quality: specialist prompts were written for earlier Claude models, use aggressive directives that misfire on Claude 4.6, return freeform text that nothing can reliably parse, and the eval system has 12 assertions defined but never executed. The milestone is credible only if evals actually run and demonstrate measurable improvement.

The recommended approach is sequential and disciplined: restructure prompts first (establishing testable baselines), build the eval runner second (to validate changes), then migrate specialists to structured JSON output (which both the eval parser and improve loop depend on), then fold the Copy specialist into Intent (reducing agents from 8 to 7), and finally add Playwright interaction capture as an opt-in flag. The order is not arbitrary — each phase is a prerequisite for the next. Prompt baselines must exist before JSON migration, evals must run before the merge, and structured output must land before eval assertion parsing becomes reliable.

The dominant risk is silent regression: rewriting one specialist prompt changes output format and the boss synthesizer produces wrong verdicts with no error. Prevention requires maintaining explicit output contracts and running per-specialist eval baselines before and after every prompt change. The secondary risk is eval flakiness making the quality story unconvincing — assertions need to be calibrated against 3 runs of the actual pipeline to set ranges that catch real regressions without producing noise.

## Key Findings

### Recommended Stack

The existing stack (markdown commands, JSON configs, bash scripts, Playwright CLI + MCP, Gemini CLI) is unchanged and correct. The zero-dependency constraint remains absolute — nothing added to node_modules. All v1.2.0 changes are prompt-level (.md files), configuration-level (.json), or eval-script-level (.sh).

The only new infrastructure needed: `jq` for JSON parsing in bash (already a prerequisite via validate-structure.sh), `curl` to the Anthropic Messages API for Layer 2 judge calls (requires ANTHROPIC_API_KEY, contributor-only), and `python3 -m http.server` for fixture serving during evals (standard Python stdlib). Claude Haiku is recommended for eval judge calls — fast, cheap, sufficient for binary rubric evaluation.

**Core technologies:**
- Claude 4.6 (Sonnet/Opus): Primary specialist runtime — XML-structured prompts and improved instruction following unlock most v1.2.0 improvements
- Playwright MCP (`@playwright/mcp`): Interaction-before-scoring capture — hover, focus, scroll states passed to specialists as additional screenshots
- `jq`: JSON parsing in bash — validates specialist output and enables deterministic score extraction in eval assertions
- `curl` + Anthropic Messages API: LLM-as-judge eval scoring — Claude Haiku for binary pass/fail rubric evaluation, no npm SDK required
- `python3 -m http.server`: Fixture serving during evals — serves static HTML fixtures without any new dependencies

### Expected Features

**Must have (table stakes — without these, the milestone claim is hollow):**
- XML-structured specialist prompts using `<role>`, `<context>`, `<instructions>`, `<output_format>`, `<examples>` tags
- Explicit 4-level scoring rubric per specialist with concrete anchors per level (not just "Score 1-4")
- Structured JSON output from specialists using `<specialist_output>` XML-wrapped JSON
- Layer 2 eval runner that actually executes assertions (not `[TODO]`)
- Removal of over-aggressive directives ("FLAG SPECIFICALLY", "NEVER", "Find at least N issues") misaligned with Claude 4.6 behavior
- Copy specialist folded into Intent/Originality/UX (8 to 7 specialists) with atomic weight update in scoring.json

**Should have (competitive differentiation):**
- Few-shot examples in every specialist prompt (2-3 per specialist, curated from real review outputs)
- Chain-of-thought `<thinking>` + `<answer>` separation in specialist prompts
- Playwright page interaction before specialist scoring (hover, focus, scroll capture as opt-in `--interact` flag)
- Eval result snapshots with regression detection (compare consecutive runs, flag score drops)
- Gray area eval fixtures — add "mediocre but not terrible" and "near-perfect" alongside existing extremes
- Anthropic DISTILLED_AESTHETICS_PROMPT integrated as `references/generation.md` for the build phase only

**Defer (v1.3+):**
- Eval fixtures covering Figma reference mode, style preset mode, dark mode
- Auto-tuning prompts based on eval results (unpredictable cascade risks)
- Vision-mode Playwright coordinate-based clicking (accessibility-ref mode is more reliable)
- Real-time eval dashboard (evals run weekly at most; a dashboard is over-engineering)

### Architecture Approach

The architectural shift is from monolithic inline prompts to extracted modular prompt files. All 8 specialist prompts and the boss synthesizer are currently embedded in design-review.md (732 lines) and duplicated in design-audit.md (1274 lines). Extracting them to `skills/design-review/prompts/*.md` makes each prompt independently testable, reduces diff noise, and enables `@` includes from both commands. Output schemas live in `skills/design-review/schemas/`. The command files become orchestration-only.

**Major components:**
1. Extracted specialist prompts (`skills/design-review/prompts/`) — one file per specialist + boss + page-brief, following the XML structure standard with `<role>`, `<context>`, `<reference_knowledge>`, `<instructions>`, `<output_format>`, `<examples>` tags
2. Output schemas (`skills/design-review/schemas/`) — `specialist-output.md` and `boss-output.md` defining the JSON contracts that all consumers depend on
3. Layer 2 eval runner (`evals/run-quality-evals.sh`) — bash orchestrator: serve fixture via python3 HTTP server, invoke review via `claude --print`, parse output with `parse-review-output.sh`, assert ranges, report pass/fail per assertion
4. Output parser (`evals/parse-review-output.sh`) — extracts scores and verdicts from review output, supporting both structured JSON (v1.2.0+) and legacy terminal table format for backward compatibility
5. Generation reference (`skills/design-review/references/generation.md`) — Anthropic aesthetics prompt adapted for the build phase (design-improve only, not design-review — generation vs evaluation are different operations)
6. Updated scoring config — scoring.json with total_weight: 16 after Copy merge, recalibrated thresholds and assertions

### Critical Pitfalls

1. **Prompt rewrite regression without baseline** — rewriting a specialist changes output format; boss synthesizer parses the old format and produces NaN scores silently. Prevention: run all 3 eval fixtures before any prompt changes to record per-specialist baselines; rewrite one specialist at a time; re-run evals after each; accept only deviations under 0.5.

2. **Flaky evals masking real regressions** — range assertions (min: 2.0, max: 3.2) on LLM scores produce false failures ~30% of the time due to sampling variance. Prevention: calibrate ranges by running each fixture 3 times and using observed spread + 0.3 buffer; use verdict-level assertions (deterministic) as the primary gate.

3. **JSON output suppressing specialist reasoning quality** — forcing structured output can reduce reasoning depth by 10-15% (LLM literature). Prevention: use think-then-structure pattern (`<thinking>` free-form reasoning first, `<answer>` structured JSON second); keep schema minimal (score, findings, summary only).

4. **Copy-to-Intent merge without atomic weight update** — merging specialists while leaving total_weight: 17 produces silently wrong verdicts. Prevention: treat merge and scoring.json update as a single atomic commit; add a structural assertion in validate-structure.sh verifying sum of weights equals total_weight.

5. **Playwright interaction mutating page state before review** — hovering, clicking, scrolling leaves DOM artifacts that specialists then review as if it's the normal page state. Prevention: use baseline-interact-reset pattern (screenshot clean, interact, reload, take review screenshots); make interaction opt-in via `--interact` flag.

## Implications for Roadmap

The dependency graph from research prescribes the phase order. Each phase unblocks the next.

### Phase 1: Prompt Extraction and Restructuring
**Rationale:** Everything else depends on having well-structured, independently testable prompts. This phase establishes the measurement baseline before any quality changes. Cannot validate improvements without a baseline to compare against.
**Delivers:** 10 extracted prompt files, 2 schema files, commands reduced to orchestration-only via `@` includes, per-specialist eval baseline recorded (3 fixture runs), all over-aggressive directives removed, output contracts documented.
**Addresses:** XML-structured prompts, context-aware prompt language, output contract definition.
**Avoids:** Prompt rewrite regression (#1) and cargo-culted patterns (#8) — audit-first, identify what's broken before applying XML structure.

### Phase 2: Layer 2 Eval Runner
**Rationale:** Evals validate all subsequent prompt changes. Building the runner before JSON migration means it uses regex parsing initially and upgrades to JSON parsing after Phase 3. Getting evals working before prompt quality changes provides the measurement instrument.
**Delivers:** `run-quality-evals.sh` executing all assertions, `parse-review-output.sh` with dual-format support, calibrated assertion ranges (from 3-run calibration), verdict-level assertions as primary gate, at least one gray-area fixture added.
**Addresses:** Layer 2 evals that actually run, eval result snapshots with regression detection.
**Avoids:** Eval flakiness (#2) and fixture gaming (#7) — calibrate from actual runs, add cross-fixture ranking assertions.

### Phase 3: Structured JSON Output
**Rationale:** JSON output enables reliable eval parsing, tighter improve loop, and deterministic report generation. Must come after Phase 1 (prompts need the `<output_format>` schema) and after Phase 2 (evals validate that JSON migration didn't regress quality).
**Delivers:** `<specialist_output>` JSON from all specialists, `<boss_output>` from synthesizer, updated design-improve.md consuming `top_fixes` array programmatically, eval parser upgraded to JSON-first parsing, generate-report.sh reading structured JSON from flow-state.json.
**Addresses:** Structured JSON specialist output, tighter /design-improve fix extraction.
**Avoids:** JSON reasoning degradation (#3) — use think-then-structure pattern, migrate one specialist at a time with eval verification.

### Phase 4: Specialist Consolidation (8 to 7)
**Rationale:** The merge is lowest-risk architecturally but highest-risk in scoring math. Doing it after evals are working and JSON output is stable means the impact can be measured precisely. Most likely phase to cut if earlier phases take longer than expected.
**Delivers:** Copy merged into Intent/Originality/UX (4 scores: intent_match, originality, ux_flow, copy_quality), scoring.json at total_weight: 16, quick_mode_total_weight updated, all eval assertions recalibrated, structural weight-sum assertion added to validate-structure.sh.
**Addresses:** Copy specialist consolidation, scoring weight update.
**Avoids:** Bloated merged prompt (#4) — keep prompt under 45 lines; test against copy-specific fixtures.

### Phase 5: Playwright Interaction Before Scoring (opt-in)
**Rationale:** Latest phase because it requires stable prompts (adds screenshots to specialists), adds MCP dependency to design-review (currently CLI-only), and state mutation risk is highest. Must be opt-in to preserve Tier 2/3 degradation behavior.
**Delivers:** `--interact` flag for hover/focus/scroll state capture, interaction screenshots passed to relevant specialists (Motion, Code/A11y, Color/Layout), baseline-interact-reset pattern, 8-interaction budget cap.
**Addresses:** Playwright interaction before scoring as a portfolio differentiator.
**Avoids:** Page state mutation (#5) — reload between interaction and review; never make interaction the default.

### Phase 6: Few-Shot Examples and Polish
**Rationale:** Labor-intensive (hand-curated examples per specialist) and additive — can be done incrementally after structure is stable. Chain-of-thought adds prompt length — must check token budget after Phases 1-4 stabilize.
**Delivers:** 2-3 curated examples per specialist in `<examples>` tags, `<thinking>` + `<answer>` separation for complex specialists (Intent, Layout), `references/generation.md` from Anthropic DISTILLED_AESTHETICS_PROMPT adapted for build phase, anti-slop.json synced with Anthropic's banned list.
**Addresses:** Few-shot examples, chain-of-thought scoring, aesthetics integration.
**Avoids:** Token budget explosion — measure review token count before and after; cap increase at 30%.

### Phase Ordering Rationale

- Phases 1-3 are a strict dependency chain: extraction enables isolation, evals enable measurement, JSON output enables reliable measurement parsing.
- Phase 4 benefits from evals being in place to catch weight-math errors, but is logically independent.
- Phase 5 must not be added while prompts are in flux — add only once baseline is stable.
- Phase 6 is purely additive polish — safe to do incrementally or defer to v1.2.x without blocking the milestone claim.
- The pitfall-to-phase mapping in PITFALLS.md confirms this ordering: the two most critical pitfalls (regression #1, flaky evals #2) are addressed in Phases 1 and 2 respectively.

### Research Flags

Phases needing careful design decisions before implementation:
- **Phase 3 (Structured JSON):** The dual-format parsing strategy for boss synthesizer during migration needs a concrete decision before coding. Which specialist gets migrated first must be decided.
- **Phase 4 (Specialist Consolidation):** The exact weight redistribution when Copy folds into Intent needs a decision — does copy_quality get its own weight in scoring.json, or does it fold into intent_match? This affects all assertion recalibration.
- **Phase 5 (Playwright Interaction):** The `--interact` flag UX needs design — how are interaction findings presented differently from static review findings in the output?

Phases with well-documented patterns (standard implementation):
- **Phase 1 (Prompt Extraction):** Pure file reorganization + prompt formatting — Anthropic docs are explicit and directly applicable.
- **Phase 2 (Eval Runner):** bash + python3 + claude CLI pattern; existing validate-structure.sh demonstrates the approach.
- **Phase 6 (Few-Shot + Aesthetics):** Additive changes with clear source material (Anthropic cookbook + real review outputs).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings verified against official Anthropic docs and Playwright MCP repo. Zero-dependency constraint is absolute and consistently verified. |
| Features | HIGH | Direct codebase analysis of existing commands, configs, and eval files. Feature gaps identified by comparing current state to Anthropic official best practices with specific line references. |
| Architecture | HIGH | Based on direct inspection of all 22 plugin files. Integration points are concrete — file names, line numbers, parser patterns, and schema definitions are all specified. |
| Pitfalls | HIGH (pitfalls 1-5, 7-8), MEDIUM (pitfall 6) | Critical pitfalls backed by Anthropic docs and LLM eval literature. Pitfall #6 (aesthetics conflicts) is MEDIUM because specific conflicts depend on which content is merged during Phase 1. |

**Overall confidence:** HIGH

### Gaps to Address

- **Current token count per full review:** Research documents the risk of token increase from few-shot examples but the current baseline count is unknown. Measure at the start of Phase 6 before adding examples.
- **`claude --print` non-interactive eval invocation:** The eval runner architecture assumes `claude --print` can invoke plugin commands non-interactively. Validate with a minimal smoke test before committing to this architecture in Phase 2.
- **Playfair Display position:** Anthropic cookbook recommends it for editorial use; typography.md flags it as the "#1 AI luxury serif." The context-dependent resolution (acceptable in genuine editorial contexts, flagged for SaaS/landing) needs to be written explicitly into typography.md during Phase 1.
- **Quick mode weight divisor after Copy merge:** quick_mode_total_weight must be recalculated after Phase 4. The exact value depends on whether Copy was included in quick mode — verify before implementing the merge.

## Sources

### Primary (HIGH confidence)
- [Anthropic Claude 4.6 Prompting Best Practices](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices) — XML structure, roles, examples, agentic systems, structured output
- [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — sub-agent architectures, few-shot patterns, context placement rules
- [Anthropic Cookbook: Prompting for Frontend Aesthetics](https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics) — full DISTILLED_AESTHETICS_PROMPT text
- [Anthropic Structured Outputs Documentation](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) — JSON schema enforcement via prompt-based approach in plugin context
- [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp) — browser_hover, browser_click, browser_evaluate, browser_snapshot tool specifications
- [Anthropic Frontend Design Skill (SKILL.md)](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) — official design skill philosophy and aesthetics approach
- Direct codebase analysis: commands/design-review.md (732 lines), commands/design-audit.md (1274 lines), config/scoring.json, evals/assertions.json, evals/run-evals.sh, all reference files in skills/design-review/references/

### Secondary (MEDIUM confidence)
- [LLM-as-Judge Best Practices (Monte Carlo)](https://www.montecarlodata.com/blog-llm-as-judge/) — categorical scales, rubric design, bias avoidance
- [Ship Prompts Like Software (Anup.io)](https://www.anup.io/ship-prompts-like-software-regression-testing-for-llms/) — before/after baseline methodology, category-level regression tracking
- [Avoiding Common Pitfalls in LLM Evaluation (HoneyHive)](https://www.honeyhive.ai/post/avoiding-common-pitfalls-in-llm-evaluation) — flakiness, single-metric traps, LLM-as-judge limitations
- [Structured Outputs and Function Calling (Agenta.ai)](https://agenta.ai/blog/the-guide-to-structured-outputs-and-function-calling-with-llms) — JSON reasoning degradation (10-15%) finding
- [Designing Effective Multi-Agent Architectures (O'Reilly)](https://www.oreilly.com/radar/designing-effective-multi-agent-architectures/) — coordination overhead, agent count ceiling recommendations
- [Simon Willison: Playwright MCP + Claude Code](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) — real-world usage patterns

### Tertiary (LOW confidence / needs validation)
- `claude --print` non-interactive invocation for eval runner — assumed to work based on CLI docs, must be smoke-tested before committing to eval architecture in Phase 2

---
*Research completed: 2026-03-29*
*Ready for roadmap: yes*
