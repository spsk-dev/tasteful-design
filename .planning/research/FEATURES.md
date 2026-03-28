# Feature Landscape

**Domain:** Claude Code AI Agent Skill Plugin (Design Quality)
**Researched:** 2026-03-28

## Table Stakes

Features users expect from a published Claude Code plugin. Missing = feels unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `/design-review` core command | This IS the product. 8 specialists, weighted scoring, SHIP/BLOCK verdict. | High (already built) | Port from ~/.claude/plugins/design-review/ |
| `/design` orchestrator | Single entry point for all design commands. Route by argument. | Med (already built) | Routes to review/improve/validate/ship. |
| `/design-improve` iterative loop | Build -> review -> fix -> re-review until SHIP. Core workflow. | Med (already built) | Anti-slop defaults, max iterations, score progression. |
| `/design-validate` functional tests | Buttons work, links resolve, forms validate. | Med (already built) | Uses Playwright MCP for functional checks. |
| Scoring with thresholds | Different page types need different quality bars. Admin != Landing. | Low | scoring.json with per-type thresholds (2.5-3.5 range). |
| Anti-slop detection | Reject AI-generic patterns (Poppins + blue gradient + rounded cards). | Low | anti-slop.json with banned patterns list. |
| Quick mode (`--quick`) | 4 specialists instead of 8. Saves ~40-50% tokens. | Low (already built) | Core: Font, Color, Layout, Intent. |
| Style presets | Opinionated defaults for common page types. | Low | style-presets.json with 5 built-in. |
| CLAUDE.md with usage docs | Users need to know what commands exist. | Low | Standard plugin convention. |
| README.md for GitHub | Humans discover via GitHub, not CLI. Must sell the tool. | Low | Demo GIF, install command, architecture overview. |
| LICENSE | Open source expectation. | Trivial | MIT. |

## Differentiators

Features that make SpSk a portfolio piece, not just another plugin.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Reproducible eval harness | Proves claims with numbers. "v1: 40%, v4: 100%" | Med | 19+ assertions, 3 test cases. Crown jewel. |
| Transparent failure history | CHANGELOG shows v1 single-agent scored 40%. | Low | Most repos hide failures. Builds credibility. |
| ARCHITECTURE.md as docs | Multi-agent design, specialist roles, boss synthesizer. | Med | "The tool is the proof; the architecture is the CV." |
| Branded terminal output | Unicode boxes, progress bars, signature line. Consistent vocabulary. | Med | Fixed-width banners. Not random emoji. |
| Degradation tiers | Tier 1 (full), Tier 2 (no Gemini), Tier 3 (code-only). | Low (built) | Reports which tier ran. Never fails silently. |
| Specialist disagreement visibility | Shows when specialists disagree and how boss resolved. | Med | "Visible meta-cognition" -- Gemini insight. |
| Reference-aware review | `--ref`, `--figma`, `--direction` flags. | Low (built) | Compare against Stripe, Figma, or creative briefs. |
| Score progression tracking | Shows improvement across iterations (2.53 -> 3.0 -> SHIP). | Low (built) | Visual proof the tool drives improvement. |
| 30-second demo GIF | README hook. Shows the tool in action without installing. | Med | Phase 2 deliverable. |

## Phase 2 Features (Init Wizard + Polish)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `/design init` wizard | 5 questions, under 2 minutes to first value. Creates .design/ config. | Med | Page type, vibe preset, light/dark, brand colors, font preference. |
| Palette engine | Suggest 3 color palettes based on vibe with Design Identity names. | Med | "Midnight Corporate", "Warm Craft", "Electric Minimal". |
| `.design/` harness | Cross-page design consistency. Tokens, palette, typography config. | Low-Med | Already partially built in v1.0.0. |

## Phase 3 Features (Platform Proof)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `consensus-validation` skill | Second skill proves SpSk is a platform, not a one-off. | High | New multi-agent skill for decision validation via model consensus. |
| Case studies | Before/after with real projects (mothers-day, harness-panel). | Med | Measurable impact is what hiring managers want. |
| v1.0.0 formal release | Marketplace submission, install instructions, full docs. | Low | After all features validated. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Framework/SDK for third-party skills | Premature abstraction. Emerges from 2nd/3rd skills. | Build two skills first, extract patterns after. |
| npm distribution | No JS to package. Adds complexity without value. | Plugin registry + GitHub. |
| Web dashboard | Not a web app. Terminal is the interface. | Branded Unicode output. |
| Per-project settings database | Over-scopes v1. Reviews are point-in-time. | Markdown results in .design-reviews/. |
| Auto-fix without review | Users need to see changes before applying. | /design-improve shows fixes, then applies. |
| AI-generated design | Wrong domain. SpSk evaluates, it does not generate. | Focus on review and critique. |
| Paid tier or licensing | Portfolio piece. Friction kills adoption. | Fully open source, MIT. |

## Feature Dependencies

```
Plugin scaffold (.claude-plugin/plugin.json)
  +-- All commands, skills, hooks depend on this

/design (orchestrator)
  +-- /design-review (needs scoring.json, anti-slop.json, style-presets.json)
  +-- /design-improve (needs /design-review for scoring loop)
  +-- /design-validate (independent, uses Playwright MCP)
  +-- /design ship (needs all three above)

Eval harness (evals/)
  +-- Needs /design-review to be functional
  +-- Needs test fixtures (HTML pages or dev server)

/design init (Phase 2)
  +-- Creates .design/ which /design-review reads
  +-- Palette engine feeds into init wizard

consensus-validation (Phase 3)
  +-- Independent skill with shared branding patterns
```

## MVP Recommendation (Phase 1)

Prioritize:
1. Plugin scaffold (plugin.json, CLAUDE.md, README.md)
2. Port all 4 commands from source plugin
3. Port config JSON (scoring, anti-slop, style-presets)
4. Port skill + references (SKILL.md + 7 reference files)
5. Port hooks (suggest-review.sh + hooks.json)
6. Eval harness (run-evals.sh + evals.json + calibration-template.md)
7. ARCHITECTURE.md documenting multi-agent design
8. CHANGELOG.md with transparent failure history

Defer:
- `/design init` wizard: Phase 2 (needs palette engine)
- Branded output polish: Phase 2 (function first, form second)
- Demo GIF: Phase 2 (record after branding done)
- consensus-validation: Phase 3 (second skill)
- Case studies: Phase 3 (needs real usage data)

## Sources

- Direct inspection of ~/.claude/plugins/design-review/ (22 files, v1.0.0)
- .context/plan.md (3-model consensus strategy)
- .context/design-review-status.md (feature list, benchmark results)
- .context/gsd-research.md (output formatting patterns)
- plugin-dev skill (marketplace-considerations.md, testing-strategies.md)
