---
phase: 2
slug: init-wizard-branding-demo
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash scripts (evals/validate-structure.sh extended) |
| **Config file** | none — uses existing eval infrastructure from Phase 1 |
| **Quick run command** | `bash evals/validate-structure.sh` |
| **Full suite command** | `bash evals/validate-structure.sh && test -f shared/output.md` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash evals/validate-structure.sh`
- **After every plan wave:** Verify all new files exist and are non-empty
- **Before `/gsd:verify-work`:** Full structural suite must pass
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | INIT-01..08 | structural | `test -f commands/design-init.md` | No W0 | pending |
| TBD | TBD | TBD | PALT-01..03 | structural | `jq . config/palettes.json` | No W0 | pending |
| TBD | TBD | TBD | BRND-01..06 | structural | `test -f shared/output.md` | No W0 | pending |
| TBD | TBD | TBD | DEMO-01..02 | manual | Visual inspection of GIF | No | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] None — Phase 1 eval infrastructure carries over

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Init wizard UX flow | INIT-01..08 | Requires interactive Claude Code session | Run `/design init`, answer 5 questions, verify .design/ created |
| Palette suggestions quality | PALT-01..03 | Subjective design quality | Skip brand colors during init, verify 3 named palettes appear with sensible colors |
| Demo GIF quality | DEMO-01..02 | Visual media | Open assets/demo.gif, verify 30-second design-review run is visible |
| Branded output rendering | BRND-01..06 | Terminal rendering varies | Run `/design-review`, verify signature line, progress bars, footer |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
