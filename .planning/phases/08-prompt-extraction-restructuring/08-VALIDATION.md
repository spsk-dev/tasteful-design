---
phase: 8
slug: prompt-extraction-restructuring
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-29
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash (validate-structure.sh + run-evals.sh) |
| **Config file** | evals/validate-structure.sh (Layer 1), evals/run-evals.sh (orchestrator) |
| **Quick run command** | `bash evals/validate-structure.sh` |
| **Full suite command** | `bash evals/run-evals.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash evals/validate-structure.sh`
- **After every plan wave:** Run `bash evals/run-evals.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | PRMT-01, PRMT-02, PRMT-03, PRMT-06 | structural | `for f in font color layout icons motion intent copy code-a11y; do test -f skills/design-review/prompts/$f.md && grep -q '<role>' skills/design-review/prompts/$f.md; done` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | PRMT-07 | structural | `test -f skills/design-review/prompts/boss.md && grep -q '<scoring_formula>' skills/design-review/prompts/boss.md` | ❌ W0 | ⬜ pending |
| 08-02-01 | 02 | 2 | PRMT-06 | structural | `grep -c '@skills/design-review/prompts/' commands/design-review.md` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 2 | PRMT-01, PRMT-02, PRMT-03 | structural | `bash evals/validate-structure.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `evals/validate-structure.sh` with prompt file existence checks (9 files)
- [ ] Extend `evals/validate-structure.sh` with XML tag presence checks (`<role>`, `<instructions>`, `<scoring_rubric>`, `<output_format>`)
- [ ] Extend `evals/validate-structure.sh` with aggressive directive absence checks (`FLAG SPECIFICALLY`, `Find at least`, `NEVER`)
- [ ] Extend `evals/validate-structure.sh` with 4-level rubric presence check (grep for score level markers)

*Existing bash eval infrastructure is sufficient — no new test framework needed.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
