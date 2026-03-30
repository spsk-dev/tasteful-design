# Phase 6: HTML Diagnostic Report - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the HTML report generator that consumes flow-state.json (screenshots, per-screen scores, consistency findings, animation data) and produces a self-contained HTML diagnostic file. The report includes a flow map, per-screen sections with embedded screenshots, expandable specialist details, overall flow score with top 5 fixes, and print-to-PDF support.

</domain>

<decisions>
## Implementation Decisions

### Report Generator
- **D-91:** Report generation is a bash script (`scripts/generate-report.sh`) using heredoc templates — zero npm dependencies
- **D-92:** Triggered at the end of `/design-audit` after all reviews complete, reading flow-state.json
- **D-93:** Output file: `{project}/.design-audit/report-{timestamp}.html`
- **D-94:** Self-contained: base64-embedded JPEG screenshots, inline CSS, no external resources

### Report Structure
- **D-95:** Flow map at top showing screen progression (screen 1 → 2 → 3 with thumbnails)
- **D-96:** Per-screen sections: full screenshot, 8 (or 4) specialist scores with bar charts, specific issues with file/line references, fix recommendations
- **D-97:** Specialist details collapsed by default using `<details>` elements, expand on click
- **D-98:** Overall flow score section: weighted average, top 5 priority fixes across all screens, consistency findings summary, animation compliance
- **D-99:** SHIP/REVIEW/BLOCK verdict based on flow score thresholds from flow-scoring.json

### Visual Design
- **D-100:** Dark theme matching SpSk brand — zinc/neutral palette, one accent color
- **D-101:** Score bars using CSS (not Unicode) — proper visual rendering in browsers
- **D-102:** SpSk signature in header and footer
- **D-103:** Responsive layout — readable on desktop and mobile

### Technical
- **D-104:** Screenshots converted to JPEG at 80% quality, max 1200px width before base64 encoding
- **D-105:** Total report size under 5MB (compress screenshots if over budget)
- **D-106:** `@media print` styles for clean PDF export (hide expandable controls, show all details)

### Integration
- **D-107:** Section 14 of design-audit.md calls the report generator script
- **D-108:** Report path printed to terminal with branded output

### Claude's Discretion
- Exact CSS styling and color values
- Flow map visual design (thumbnails vs icons vs numbered circles)
- Report template structure beyond the required sections
- Error handling for missing screenshots or incomplete flow-state.json

</decisions>

<canonical_refs>
## Canonical References

### Phase 4-5 Output (consume)
- `commands/design-audit.md` — Produces flow-state.json with screenshots + reviews
- `config/flow-scoring.json` — Score thresholds and weighting
- `shared/output.md` — Brand colors, symbols, signature format

### Research
- `.planning/research/STACK.md` — HTML report approach (heredoc + base64)
- `.planning/research/PITFALLS.md` — Report size management

</canonical_refs>

<code_context>
## Existing Code Insights

### Integration Points
- `commands/design-audit.md` Section 14 — add report generator call
- `scripts/` directory — home for generate-report.sh
- `evals/validate-structure.sh` — add report-related checks

</code_context>

<deferred>
## Deferred Ideas

None

</deferred>

---

*Phase: 06-html-diagnostic-report*
*Context gathered: 2026-03-30*
