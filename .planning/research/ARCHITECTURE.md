# Architecture Patterns: Flow Audit Integration

**Domain:** SPA flow-level design audit integrated into existing 8-specialist review system
**Researched:** 2026-03-28
**Updated:** 2026-03-28 (v1.1.0 milestone research)

## Recommended Architecture

The flow audit (`/design-audit`) extends the existing `/design-review` architecture by adding a **flow navigator** layer upstream of the specialist dispatch. Instead of reviewing a single page's screenshots, the flow navigator walks through an SPA screen-by-screen, captures per-screen state, and feeds each screen through the existing 8-specialist pipeline. A **report generator** downstream collects all per-screen results into a single HTML diagnostic report.

The key architectural principle: **reuse the specialist system entirely, add orchestration around it.** The specialists do not change. What changes is how screens are discovered, captured, and how results are aggregated.

### High-Level Flow

```
User invokes /design-audit <url> --flow "sign up for a trial"
       |
       v
  Phase 0: Flow Planning
       |    Agent analyzes URL + flow description
       |    Produces ordered list of screens to visit
       |
       v
  Phase 1: Flow Navigation (NEW)
       |    playwright-cli navigates screen-by-screen
       |    Captures screenshots + snapshots at each screen
       |    Detects transitions/animations between screens
       |
       v
  Phase 2: Per-Screen Review (REUSED)
       |    For each screen:
       |      Phase 1 (Page Brief) -> Phase 2 (8 specialists) -> Phase 3 (Boss)
       |    Uses existing /design-review pipeline per screen
       |    Adds cross-screen consistency checks
       |
       v
  Phase 3: Flow Synthesis (NEW)
       |    Aggregates per-screen scores
       |    Identifies cross-screen issues (inconsistent nav, broken flow)
       |    Computes flow-level score
       |
       v
  Phase 4: HTML Report Generation (NEW)
       |    Embeds screenshots per screen
       |    Per-screen specialist breakdowns
       |    Flow-level summary with score progression
       |    Fix recommendations prioritized by impact
       |
       v
  HTML file written to disk + terminal summary
```

### Component Boundaries

| Component | Responsibility | Communicates With | New/Existing |
|-----------|---------------|-------------------|--------------|
| `/design-audit` command | Flow audit orchestrator. Parses URL + flow description, manages phases 0-4. | Flow navigator, per-screen review, report generator | **NEW** |
| `/design` router | Routes `/design audit` to `/design-audit` | `/design-audit` | **MODIFIED** (add route) |
| Flow planner | Analyzes URL + intent, produces ordered screen list | playwright-cli (initial page load) | **NEW** (within command) |
| Flow navigator | Drives playwright-cli through each screen, captures state | playwright-cli, screenshot storage | **NEW** (within command) |
| Per-screen review | Runs existing Phase 1 + Phase 2 + Phase 3 pipeline per screen | Existing specialists, scoring.json | **REUSED** (extracted as callable pattern) |
| Transition detector | Analyzes CSS/JS for animations between screen states | Source code, playwright-cli snapshots | **NEW** (within command) |
| Flow synthesizer | Cross-screen consistency, flow-level scoring, aggregation | Per-screen results | **NEW** (within command) |
| HTML report generator | Produces self-contained HTML with embedded screenshots | All phase outputs | **NEW** (template + generation logic) |
| `config/flow-scoring.json` | Flow-level weights, cross-screen consistency rules | Flow synthesizer | **NEW** config file |
| `skills/design-review/references/flow.md` | Flow-specific reference knowledge (navigation patterns, transitions, consistency) | Flow planner, transition detector | **NEW** reference file |

### New Files Required

```
spsk/
+-- commands/
|   +-- design-audit.md          # NEW: /design-audit command (flow orchestrator)
|   +-- design.md                # MODIFIED: add /design audit route
+-- config/
|   +-- flow-scoring.json        # NEW: flow-level scoring weights and thresholds
+-- skills/
|   +-- design-review/
|       +-- references/
|           +-- flow.md          # NEW: flow/navigation/transition reference knowledge
+-- templates/
|   +-- report.html              # NEW: HTML report template (self-contained)
+-- shared/
|   +-- flow-navigator.md        # NEW: reusable flow navigation instructions
|   +-- output.md                # EXISTING: branded output (used by report too)
```

## Data Flow: URL to Final HTML Report

### Stage 1: Flow Planning (agent reasoning, no tools)

```
Input:  URL + --flow "description of user goal"
Agent:  Analyzes the URL, loads the page, reads navigation structure
Output: FLOW_PLAN = [
  { screen: "landing", url: "/", action: "click 'Start Free Trial'" },
  { screen: "signup-form", url: "/signup", action: "fill form, click submit" },
  { screen: "onboarding", url: "/onboarding", action: "complete wizard" },
  { screen: "dashboard", url: "/dashboard", action: null }
]
```

The flow plan is an ordered list of screens with the action that transitions to the next screen. The agent generates this by:
1. Loading the initial URL with `playwright-cli open <url>`
2. Taking a snapshot to understand the page structure
3. Reading the flow description to determine which screens need visiting
4. Planning the navigation sequence

If the agent cannot determine the full flow from the initial page, it navigates incrementally -- visit each screen, snapshot, decide next step. This handles SPAs where routes are not visible upfront.

### Stage 2: Flow Navigation (playwright-cli)

For each screen in FLOW_PLAN:

```bash
# Navigate to screen (or perform action from previous screen)
playwright-cli goto "$SCREEN_URL"    # OR
playwright-cli click e42             # action from previous screen

# Wait for navigation/transition to settle
playwright-cli snapshot --filename "$AUDIT_DIR/snapshots/screen-$N.yaml"

# Capture screenshots (3 viewports, matching /design-review pattern)
playwright-cli screenshot --filename "$AUDIT_DIR/screenshots/screen-$N-desktop.png"
# Resize viewport for mobile
playwright-cli screenshot --filename "$AUDIT_DIR/screenshots/screen-$N-mobile.png"
```

**Transition detection** happens between screens:
- Before performing the action that transitions to the next screen, snapshot the current state
- Perform the action
- Monitor for CSS transitions/animations (check computed styles for `transition`, `animation` properties)
- Capture the intermediate state if animation is detected
- This feeds into the Motion specialist for cross-screen transition evaluation

**Storage structure:**
```
/tmp/design-audit-YYYYMMDD-HHMMSS/
+-- flow-plan.json               # The planned flow
+-- screenshots/
|   +-- screen-1-desktop.png
|   +-- screen-1-mobile.png
|   +-- screen-1-fold.png
|   +-- screen-2-desktop.png
|   +-- ...
+-- snapshots/
|   +-- screen-1.yaml            # playwright-cli DOM snapshot
|   +-- screen-2.yaml
|   +-- ...
+-- transitions/
|   +-- screen-1-to-2.json       # Transition metadata (CSS props, duration)
|   +-- screen-2-to-3.json
+-- results/
|   +-- screen-1-review.json     # Per-screen specialist results
|   +-- screen-2-review.json
|   +-- flow-synthesis.json      # Cross-screen aggregation
+-- report.html                  # Final HTML report
```

### Stage 3: Per-Screen Review (reuses existing pipeline)

For each captured screen, run the existing `/design-review` pipeline. This is the critical reuse point. The per-screen review is **not** a new specialist system -- it is the same 8-specialist dispatch, boss synthesis, and weighted scoring.

**How to extract the review pipeline as callable:**

The existing `/design-review` command does Phase 0 (screenshots) + Phase 1 (page brief) + Phase 2 (dispatch) + Phase 3 (synthesis). For flow audit, Phase 0 is already done (flow navigator captured screenshots). The command needs to accept pre-captured screenshots instead of capturing its own.

Two approaches:

**Option A: Pass screenshots directory to /design-review** (recommended)
Add a `--screenshots <dir>` flag to `/design-review` that skips Phase 0 and reads from the given directory. This keeps the specialist pipeline in one place. `/design-audit` calls `/design-review --screenshots $AUDIT_DIR/screenshots/screen-$N/ --quick` for each screen (quick mode for speed, full mode for key screens).

**Option B: Inline the specialist dispatch in /design-audit**
Copy the specialist dispatch logic into the audit command. This duplicates code but avoids modifying the existing command.

**Recommendation: Option A.** Adding `--screenshots` is a small, backwards-compatible change to `/design-review` that enables composition. It follows the existing pattern where flags modify behavior (`--quick`, `--ref`, `--figma`). The flow audit command becomes a thin orchestrator that calls the review command per screen.

**Per-screen context enrichment:**
Each screen's review gets additional context beyond the standard page brief:

```
FLOW CONTEXT: This is screen {N} of {total} in a {flow_description} flow.
Previous screen: {screen N-1 summary}
Next expected screen: {screen N+1 description}
User's goal at this point: {action description}

Evaluate this screen both on its own merit AND as part of this flow:
- Does it make sense as step {N} of {total}?
- Is the path to the next step obvious?
- Is there visual continuity with the previous screen?
```

### Stage 4: Flow Synthesis

After all per-screen reviews complete, the flow synthesizer performs four operations:

1. **Cross-screen consistency check**: Compare design tokens across screens.
   - Same nav bar on all screens? Same color palette? Same typography?
   - Flag inconsistencies as FLOW-level issues (not per-screen)

2. **Flow coherence**: Does the sequence of screens tell a coherent story?
   - Does the visual weight shift appropriately (landing = emotional, form = functional, dashboard = informational)?
   - Are transitions smooth or jarring?

3. **Aggregate scoring**: Flow score = weighted combination of per-screen scores + flow-specific dimensions.
   ```
   Flow Score = (avg_screen_scores * 0.7) + (flow_consistency * 0.15) + (transition_quality * 0.15)
   ```

4. **Priority ranking of fixes**: Issues that affect multiple screens rank higher. A broken nav bar across 4 screens is more critical than a font issue on one screen.

### Stage 5: HTML Report Generation

The report is a self-contained HTML file with embedded screenshots (base64) and inline CSS. No external dependencies -- it opens in any browser.

**Report structure:**
```html
<!-- Flow overview: score progression chart across screens -->
<!-- For each screen: -->
<!--   Screenshot (desktop) -->
<!--   Per-specialist score bars (same branded format) -->
<!--   Top 3 issues for this screen -->
<!--   Transition to next screen (if applicable) -->
<!-- Flow-level findings (cross-screen consistency) -->
<!-- Priority fix list (sorted by impact across all screens) -->
<!-- Metadata: URL, flow description, timestamp, tier, specialist count -->
```

**Why HTML and not markdown?**
- Screenshots need to be embedded (base64 in `<img>` tags)
- Score bars render better with inline CSS than markdown
- The report is shareable -- send to a designer, open in browser, no tooling needed
- Markdown with embedded images is unwieldy and not universally rendered

**Template approach:** Store a `templates/report.html` file with mustache-style placeholders. The command reads the template, injects data, writes the final file. This keeps the report format tuneable without editing the command.

## Integration with Existing Specialist System

### What Does NOT Change

- **8 specialist agents**: Same prompts, same references, same dispatch
- **Boss synthesizer**: Same weighted scoring, same deduplication, same verdicts
- **Scoring config**: Same `scoring.json` weights and thresholds per page type
- **Anti-slop system**: Same banned patterns, same detection
- **Style presets**: Same preset system, applied per screen
- **Degradation tiers**: Same Tier 1/2/3 degradation
- **Reference files**: Same domain knowledge files

### What Changes Minimally

- **`/design-review`**: Add `--screenshots <dir>` flag to skip Phase 0 and read pre-captured screenshots. Add `--flow-context <json>` flag to inject flow context into specialist prompts. Both are additive, non-breaking.
- **`/design` router**: Add `/design audit` route pointing to `/design-audit`

### What Is New

- **`/design-audit` command**: The flow orchestrator. About 60% of its content is orchestration logic (planning, navigation, synthesis, reporting). The remaining 40% delegates to `/design-review`.
- **`config/flow-scoring.json`**: Flow-level scoring weights (consistency, transitions)
- **`skills/design-review/references/flow.md`**: Reference knowledge about navigation patterns, flow UX, transition design
- **`templates/report.html`**: HTML report template
- **`shared/flow-navigator.md`**: Reusable playwright-cli navigation instructions (could be shared with `/design-validate`)

## Patterns to Follow

### Pattern 1: Composition Over Duplication

**What:** `/design-audit` calls `/design-review` per screen rather than reimplementing the specialist dispatch.
**When:** Any time a new command needs specialist reviews.
**Why:** One source of truth for specialist logic. When specialists improve (e.g., better prompts, new references), flow audit gets the improvements for free.

```
/design-audit
  |-- for each screen:
  |     /design-review --screenshots $DIR --flow-context $CTX [--quick]
  |-- flow synthesis
  |-- report generation
```

### Pattern 2: Progressive Detail

**What:** Use `--quick` mode for most screens, `--full` for key screens (first, last, and any screen the flow synthesizer flags).
**When:** Flows with 3+ screens where running full 8-specialist reviews on every screen would be expensive.
**Why:** A 5-screen flow with full reviews dispatches 40 specialist agents. Quick mode (4 specialists per screen) dispatches 20. Running full mode on first/last screens and quick on middle screens dispatches 24 -- a good balance of depth and cost.

**Decision logic:**
```
if total_screens <= 2:
  run full mode on all screens
elif total_screens <= 4:
  run full mode on first and last, quick on middle
else:
  run full mode on first, last, and any flagged screen
  run quick on everything else
```

### Pattern 3: Incremental Navigation

**What:** Navigate the flow incrementally, deciding the next step after each screen, rather than planning the entire flow upfront.
**When:** SPAs where the route structure is not visible from the initial page (client-side routing, dynamic content).
**Why:** A rigid upfront plan breaks on SPAs with conditional screens (e.g., "if user selects 'business', show extra form"). Incremental navigation adapts to what the app actually shows.

**Fallback:** If the agent cannot determine next steps after 3 attempts at a screen, ask the user for guidance. Do not loop.

### Pattern 4: Screenshot Reuse

**What:** Capture screenshots once during navigation, pass them to all downstream consumers (specialists, report, flow synthesis).
**When:** Always. Screenshots are expensive (Playwright launch, render, capture).
**Why:** The existing `/design-review` captures screenshots per invocation. If we call it 5 times for 5 screens without pre-captured screenshots, we launch Playwright 5 times. With `--screenshots`, we navigate once, capture everything, and pass directories.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Monolithic Audit Command

**What:** Putting all specialist dispatch logic, scoring, and synthesis inside `/design-audit`.
**Why bad:** Duplicates the entire specialist system. When specialist prompts improve, audit command is stale. Two codebases to maintain for the same functionality.
**Instead:** Delegate per-screen reviews to `/design-review` via the `--screenshots` flag.

### Anti-Pattern 2: Full Review on Every Screen

**What:** Running all 8 specialists on every screen in a flow.
**Why bad:** A 5-screen flow dispatches 40 specialist agents (8 x 5). Token costs are very high, and diminishing returns on middle screens where the navigation pattern is already established.
**Instead:** Use progressive detail (Pattern 2). Quick mode for middle screens, full mode for key screens.

### Anti-Pattern 3: Rigid Flow Plans

**What:** Requiring the user to specify every screen and action upfront.
**Why bad:** Users describe flows in intent terms ("sign up for a trial"), not in click-by-click terms. The agent should figure out the clicks.
**Instead:** Accept flow descriptions as intent ("sign up for a trial") and let the agent navigate incrementally.

### Anti-Pattern 4: Streaming Screenshots to LLM

**What:** Capturing screenshots inline during specialist dispatch and passing them as base64 in prompts.
**Why bad:** Token explosion. A single full-page screenshot can be 2-4MB base64. With 5 screens x 3 viewports = 15 screenshots, that is 30-60MB of base64 in context.
**Instead:** Save screenshots to disk. Specialists `Read` the PNG files (Claude handles images natively). Gemini agents read from the workspace directory.

## playwright-cli as Flow Navigator

The existing `/design-review` uses `npx playwright screenshot` for simple captures. The flow audit needs interactive navigation -- clicking buttons, filling forms, waiting for transitions. `playwright-cli` (Microsoft's AI-agent-optimized CLI) is the right tool.

**Why playwright-cli over raw Playwright scripts:**
- Designed for AI agent interaction (snapshot-based element references)
- Token-efficient (saves to disk, returns paths)
- Stateful session (browser stays open across commands)
- Element references (`e15`, `e42`) are stable within a snapshot
- Video recording for demo/debug

**Session lifecycle for flow audit:**
```bash
# 1. Open browser
playwright-cli open "$URL" --viewport 1440x900

# 2. For each screen:
playwright-cli snapshot                                    # get element refs
playwright-cli screenshot --filename "$DIR/screen-$N.png"  # capture desktop
# ... resize for mobile, capture again ...

# 3. Navigate to next screen:
playwright-cli click e42    # or fill, select, etc.
# ... wait for navigation ...

# 4. After all screens:
playwright-cli close
```

**Fallback:** If `playwright-cli` is not installed, fall back to `npx playwright` for basic screenshot-only audit (no interactive navigation). Warn the user that flow navigation requires `playwright-cli`. This follows the existing degradation tier pattern.

## Scalability Considerations

| Concern | 2 screens | 5 screens | 10+ screens |
|---------|-----------|-----------|-------------|
| Specialist agents | 16 (full) or 8 (quick) | 24 (progressive) | 28-36 (progressive) |
| Token cost | ~120K tokens | ~300K tokens | ~500K+ tokens |
| Wall time | ~3 min | ~8 min | ~15 min |
| Report size | ~500KB HTML | ~2MB HTML | ~5MB+ HTML |
| Strategy | Full mode all | Progressive detail | Progressive + parallel batching |

For 10+ screen flows, consider batching screens into groups of 3 and running reviews in parallel batches to reduce wall time.

## Suggested Build Order

Based on dependencies and risk:

1. **Add `--screenshots` flag to `/design-review`** -- Smallest change, highest reuse value. Enables flow audit to delegate per-screen reviews. Also useful independently (pre-captured screenshots from CI, etc.).

2. **Create `config/flow-scoring.json`** -- Define flow-level scoring dimensions before building the command. Clear contract.

3. **Create `skills/design-review/references/flow.md`** -- Flow-specific reference knowledge. Informs the flow planner and transition detector prompts.

4. **Create `/design-audit` command** -- Core orchestrator. Start with flow planning + navigation + per-screen review delegation. No report generation yet -- just terminal output.

5. **Add transition detection** -- CSS animation/transition analysis between screens. Feeds into Motion specialist and flow synthesis.

6. **Create `templates/report.html` + report generator** -- HTML report with embedded screenshots. This is the final output format.

7. **Update `/design` router** -- Add `/design audit` route. Trivial change, do last.

8. **Create evals for flow audit** -- Test fixtures with multi-screen HTML pages. Assert on flow-level scoring, cross-screen consistency detection, report generation.

## Sources

- [Microsoft playwright-cli](https://github.com/microsoft/playwright-cli) -- AI agent CLI for browser automation
- [playwright-cli SKILL.md](https://github.com/microsoft/playwright-cli/blob/main/skills/playwright-cli/SKILL.md) -- Command reference with snapshot/navigation API
- [Playwright CLI deep dive (TestDino)](https://testdino.com/blog/playwright-cli/) -- Token efficiency comparison (4x reduction vs MCP)
- [Playwright screenshots docs](https://playwright.dev/docs/screenshots) -- Standard Playwright screenshot API
- Existing SpSk ARCHITECTURE.md -- v1.0.0 specialist system documentation
- Existing design-review.md command -- Specialist dispatch, Phase 0-3 pipeline
