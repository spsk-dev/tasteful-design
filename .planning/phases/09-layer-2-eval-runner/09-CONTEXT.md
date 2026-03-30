# Phase 9: Layer 2 Eval Runner - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Build the Layer 2 quality eval runner that actually executes assertions against real design-review output. The runner serves HTML fixtures via python3 HTTP server, invokes `/design-review` via `claude --print`, parses output (regex for now, JSON-first after Phase 10), and asserts score ranges and verdict-level gates. Calibrate assertion ranges from 3 baseline runs per fixture. Add at least one gray-area fixture. Add LLM-as-judge binary rubric assertions via Claude Haiku (graceful skip when no API key). Store eval result snapshots for regression detection.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Key guidance from research:

- Eval runner: `evals/run-quality-evals.sh` — bash orchestrator
- Output parser: `evals/parse-review-output.sh` — extracts scores and verdicts from terminal output
- Fixture serving: `python3 -m http.server` on random port, killed after eval
- Invocation: `claude --print` for non-interactive plugin command execution (needs smoke test first — may not work, fallback TBD)
- Verdict assertions as primary gate: bad page → BLOCK, good page → SHIP, gray → CONDITIONAL
- Score range assertions as secondary: calibrated from 3 baseline runs + 0.3 buffer
- LLM-as-judge: `curl` to Anthropic Messages API with Haiku, binary rubric (pass/fail), requires ANTHROPIC_API_KEY
- Snapshots: `evals/results/` directory with timestamped JSON files
- Gray-area fixture: mediocre page (some good, some bad) that should score CONDITIONAL
- Existing fixtures: `evals/fixtures/good-page.html`, `evals/fixtures/bad-page.html`, `evals/fixtures/flow-test/`

</decisions>

<canonical_refs>
## Canonical References

- `evals/run-evals.sh` — Current eval orchestrator (Layer 1 only, Layer 2 is TODO)
- `evals/validate-structure.sh` — Layer 1 structural checks (107 assertions)
- `evals/assertions.json` — 12 range-based quality assertions (defined but not executed)
- `evals/fixtures/` — HTML test pages (good-page.html, bad-page.html, flow-test/)
- `config/scoring.json` — Scoring weights and thresholds
- `commands/design-review.md` — The command being evaluated
- `.planning/research/SUMMARY.md` — Eval architecture recommendations
- `.planning/research/FEATURES.md` — Eval patterns and anti-patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `evals/assertions.json` — 12 assertions already defined with min/max ranges
- `evals/fixtures/good-page.html` and `bad-page.html` — existing test pages
- `evals/run-evals.sh` — orchestrator shell with Layer 1 working, Layer 2 stubbed

### Established Patterns
- Bash eval scripts with `check()` function pattern (from validate-structure.sh)
- JSON configs parsed with `jq`
- PASS/FAIL reporting with counters

### Integration Points
- `run-quality-evals.sh` called from `run-evals.sh` as Layer 2
- `parse-review-output.sh` used by both eval runner and future report generator
- `evals/results/` consumed by regression detection

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Refer to ROADMAP phase description and success criteria.

</specifics>

<deferred>
## Deferred Ideas

- JSON-first parsing (Phase 10 — JSON-03)
- Eval fixtures for Figma mode, style presets, dark mode (v1.3+)
- Auto-tuning prompts based on eval results (v1.3+)

</deferred>

---

*Phase: 09-layer-2-eval-runner*
*Context gathered: 2026-03-29*
