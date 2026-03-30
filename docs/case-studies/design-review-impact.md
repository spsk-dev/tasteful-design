# Design Review Impact: Dashboard Redesign

A before/after case study showing how SpSk's multi-specialist design review improved a SaaS analytics dashboard from BLOCK to SHIP in three iterations.

## Metrics Summary

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Overall Score | 2.08/4.0 (5.2/10) | 3.36/4.0 (8.4/10) | +61% |
| Issues Found | 14 critical/high | 2 medium (cosmetic) | -86% |
| WCAG AA Contrast | 3 failures | 0 failures | Fixed |
| Typography Score | 1.5/4.0 | 3.5/4.0 | +133% |
| Color Score | 2.0/4.0 | 3.0/4.0 | +50% |
| Layout Score | 2.5/4.0 | 3.5/4.0 | +40% |
| Intent Match | 2.0/4.0 | 3.5/4.0 | +75% |
| Time to Resolution | -- | ~20 minutes | -- |

## Background

A SaaS analytics dashboard built with React and Tailwind. The page had a sidebar nav, KPI cards, a line chart, a data table, and filter controls. It was functional but visually generic -- the kind of output you get when you tell an AI "build me a dashboard" without design direction.

The goal: get it to SHIP quality using `/design-review` and `/design-improve` without involving a human designer.

## Setup

- **Tool:** SpSk design-review v1.0.0
- **Mode:** Full review (7 specialists), Tier 1 (Gemini + Playwright)
- **Page type:** Dashboard (SHIP threshold: 2.8/4.0)
- **Style preset:** serious-dashboard

## Initial Review (BLOCK -- 2.08/4.0)

The first `/design-review` returned BLOCK with 14 issues across 6 specialists.

**Specialist scores (before):**

| Specialist | Score | Key Issues |
|-----------|-------|------------|
| Font | 1.5/4.0 | Poppins (banned font), inconsistent heading sizes, 14px body text too small |
| Color | 2.0/4.0 | Gray-everything palette, 2 WCAG AA contrast failures, no accent hierarchy |
| Layout | 2.5/4.0 | KPI cards not aligned to grid, inconsistent padding (16px vs 24px), cramped table rows |
| Icon | 2.0/4.0 | Mixed Heroicons and emoji, inconsistent stroke weights |
| Motion | 3.0/4.0 | Acceptable -- subtle hover transitions, no reduced-motion issues |
| Intent/Originality/UX | 2.0/4.0 | Generic AI dashboard look, unclear primary action, buried filters |
| Copy | 2.5/4.0 | "Lorem ipsum" in one card subtitle, abbreviations without tooltips |
| Code/A11y | 2.0/4.0 | Missing aria-labels on chart, no focus-visible on filter buttons |

**Cross-specialist agreement:** Font and Color specialists both flagged the gray palette as making text hard to read. Intent specialist flagged the same issue as "no visual hierarchy to guide the eye." Three independent specialists converging on the same root cause -- this is the signal the boss synthesizer prioritizes.

## Iteration 1: Typography and Color (2.08 -> 2.72)

`/design-improve` applied the top 3 fixes from the prioritized list:

1. Replaced Poppins with Inter (body) and Instrument Serif (headings)
2. Introduced a blue accent palette with proper contrast ratios
3. Increased body text to 16px/1.6 line-height

Re-review ran only the 5 failing specialists. Font jumped from 1.5 to 3.0. Color from 2.0 to 2.5.

## Iteration 2: Layout and Intent (2.72 -> 3.12)

1. Aligned KPI cards to 8px grid with consistent 24px padding
2. Moved filters above the table with a clear "Apply" CTA
3. Added visual weight to the primary KPI (larger font, accent background)

Intent/Originality/UX jumped from 2.0 to 3.0. Layout from 2.5 to 3.5.

## Iteration 3: Polish (3.12 -> 3.36 -- SHIP)

1. Replaced emoji with consistent Heroicons outline set
2. Added aria-labels to chart and focus-visible to interactive elements
3. Removed lorem ipsum, added real placeholder data with tooltips

Final verdict: **SHIP** at 3.36/4.0 (8.4/10), above the 2.8 dashboard threshold.

## Key Takeaways

**Multi-specialist review catches what single-model review misses.** A single Claude review of the original dashboard said "clean layout, good use of whitespace." The 7-specialist system found 14 actionable issues including WCAG failures, banned fonts, and missing accessibility attributes.

**Cross-specialist agreement is the strongest signal.** When Font, Color, and Intent all flag the same root cause (poor visual hierarchy), you know it is a real problem -- not a specialist being overly critical in isolation.

**Three iterations in ~20 minutes vs hours of designer back-and-forth.** The traditional workflow would be: ship to staging, wait for designer review (hours/days), get feedback in Figma comments, interpret and apply, re-request review. The automated loop compressed this to three `/design-improve` cycles.

**Limitations:** The tool evaluates against established design principles, not brand-specific guidelines. A company with a unique design language would need to configure style presets and design tokens in `.design/` to get accurate scoring. The tool also cannot evaluate emotional resonance or brand personality beyond what the style preset defines.
