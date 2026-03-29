---
phase: 1
slug: scaffold-port-evals
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash scripts (evals/validate-structure.sh + evals/run-evals.sh) |
| **Config file** | none — created during Phase 1 |
| **Quick run command** | `bash evals/validate-structure.sh` |
| **Full suite command** | `bash evals/run-evals.sh` |
| **Estimated runtime** | ~10 seconds (structural), ~60s (quality evals) |

---

## Sampling Rate

- **After every task commit:** Run `bash evals/validate-structure.sh`
- **After every plan wave:** Run `bash evals/run-evals.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | SCAF-01 | structural | `jq . .claude-plugin/plugin.json` | No W0 | pending |
| TBD | TBD | TBD | PORT-01..10 | smoke | `bash evals/validate-structure.sh` | No W0 | pending |
| TBD | TBD | TBD | EVAL-01..05 | integration | `bash evals/run-evals.sh` | No W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `evals/validate-structure.sh` — structural validation (plugin.json, frontmatter, file presence)
- [ ] `evals/run-evals.sh` — quality eval orchestrator (created during execution, not upfront)

*Structural validation script is the Wave 0 deliverable. Quality evals depend on the port being complete.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Plugin install from GitHub | EVAL-05 | Requires clean Claude Code session | See `evals/INSTALL-TEST.md` for full procedure |
| 8-specialist review quality | PORT-01 | Requires AI model invocation | Run `/design-review` on test page, verify 8 scores |
| Degradation to Tier 2/3 | PORT-09 | Requires removing Gemini CLI | Unset Gemini path, run review, verify Tier 2 output |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
