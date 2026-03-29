# Requirements: SpSk v1.1.0 — Flow Audit + Polish

**Defined:** 2026-03-29
**Core Value:** Published skills must be immediately useful AND demonstrate architectural sophistication

## v1.1.0 Requirements

### Flow Navigation

- [ ] **FLOW-01**: `/design-audit <url> --flow "description"` command navigates a SPA guided by user's intent description
- [ ] **FLOW-02**: Agent uses Playwright MCP snapshots to identify and click CTAs matching the flow intent
- [ ] **FLOW-03**: Screenshot captured at each detected screen state change
- [ ] **FLOW-04**: Screen detection — agent knows when a new "screen" has loaded (DOM stability, not networkidle)
- [ ] **FLOW-05**: Max screen limit (default 10) prevents runaway navigation
- [ ] **FLOW-06**: URL sequence fallback via `--steps url1,url2,url3` for deterministic paths
- [ ] **FLOW-07**: Authenticated flow support — can login first, then audit the protected flow
- [ ] **FLOW-08**: Flow stops gracefully at completion/success state or dead end

### Per-Screen Review

- [ ] **REVW-01**: Each captured screen is reviewed by the existing 8-specialist system
- [ ] **REVW-02**: Smart weighting — full 8-specialist review on first and last screens, quick mode (4 specialists) on middle screens
- [ ] **REVW-03**: Cross-screen consistency analysis — flag when button styles, colors, spacing, or typography drift between screens
- [ ] **REVW-04**: Per-screen scores aggregated into overall flow score

### HTML Report

- [ ] **REPT-01**: Self-contained HTML file with base64-embedded JPEG screenshots (no external dependencies)
- [ ] **REPT-02**: Flow map showing screen progression (screen 1 → 2 → 3 → ...)
- [ ] **REPT-03**: Per-screen section with screenshot, 8-specialist scores, specific issues, and fix recommendations
- [ ] **REPT-04**: Overall flow score and summary with top 5 priority fixes
- [ ] **REPT-05**: Expandable specialist details (collapsed by default, expand on click)
- [ ] **REPT-06**: Print-to-PDF support via `@media print` styles
- [ ] **REPT-07**: Report file size under 5MB (JPEG compression, max 1200px width screenshots)

### Animation Detection

- [ ] **ANIM-01**: CSS transition/animation property detection between screen states
- [ ] **ANIM-02**: `prefers-reduced-motion` compliance check
- [ ] **ANIM-03**: Animation findings included in per-screen specialist output

### Polish

- [ ] **PLSH-01**: Demo GIF recorded via VHS tape file (deferred from v1.0.0)
- [ ] **PLSH-02**: README updated with /design-audit documentation, flow examples, report screenshots
- [ ] **PLSH-03**: ARCHITECTURE.md updated with flow audit component diagram
- [ ] **PLSH-04**: CHANGELOG.md updated with v1.1.0 release notes
- [ ] **PLSH-05**: All repo references use spsk-dev org consistently
- [ ] **PLSH-06**: VERSION bumped to 1.1.0, git tag v1.1.0

## Out of Scope

| Feature | Reason |
|---------|--------|
| Video recording of flows | Massive complexity, screenshots + CSS analysis cover 90% of value |
| Runtime animation frame analysis | Web Animations API source analysis is sufficient for v1.1 |
| Multi-browser testing | Chromium-only via Playwright is sufficient |
| Automatic fix application | Report recommends fixes, user/agent applies them separately |
| Real-time collaboration on reports | Static HTML file is the output format |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FLOW-01 | Phase 4 | Pending |
| FLOW-02 | Phase 4 | Pending |
| FLOW-03 | Phase 4 | Pending |
| FLOW-04 | Phase 4 | Pending |
| FLOW-05 | Phase 4 | Pending |
| FLOW-06 | Phase 4 | Pending |
| FLOW-07 | Phase 4 | Pending |
| FLOW-08 | Phase 4 | Pending |
| REVW-01 | Phase 5 | Pending |
| REVW-02 | Phase 5 | Pending |
| REVW-03 | Phase 5 | Pending |
| REVW-04 | Phase 5 | Pending |
| REPT-01 | Phase 6 | Pending |
| REPT-02 | Phase 6 | Pending |
| REPT-03 | Phase 6 | Pending |
| REPT-04 | Phase 6 | Pending |
| REPT-05 | Phase 6 | Pending |
| REPT-06 | Phase 6 | Pending |
| REPT-07 | Phase 6 | Pending |
| ANIM-01 | Phase 5 | Pending |
| ANIM-02 | Phase 5 | Pending |
| ANIM-03 | Phase 5 | Pending |
| PLSH-01 | Phase 7 | Pending |
| PLSH-02 | Phase 7 | Pending |
| PLSH-03 | Phase 7 | Pending |
| PLSH-04 | Phase 7 | Pending |
| PLSH-05 | Phase 7 | Pending |
| PLSH-06 | Phase 7 | Pending |

**Coverage:**
- v1.1.0 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0

---
*Requirements defined: 2026-03-29*
*Last updated: 2026-03-28 after roadmap creation*
