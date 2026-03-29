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
| **Framework** | Bash scripts (validate-plugin.sh + run-evals.sh) |
| **Config file** | none — created during Phase 1 |
| **Quick run command** | `bash scripts/validate-plugin.sh` |
| **Full suite command** | `bash run-evals.sh` |
| **Estimated runtime** | ~10 seconds (structural), ~60s (quality evals) |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/validate-plugin.sh`
- **After every plan wave:** Run `bash run-evals.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | SCAF-01 | structural | `jq . .claude-plugin/plugin.json` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PORT-01..10 | smoke | `bash scripts/validate-plugin.sh` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | EVAL-01..05 | integration | `bash run-evals.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/validate-plugin.sh` — structural validation (plugin.json, frontmatter, file presence)
- [ ] `run-evals.sh` — quality eval orchestrator (created during execution, not upfront)

*Structural validation script is the Wave 0 deliverable. Quality evals depend on the port being complete.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Plugin install from GitHub | EVAL-05 | Requires clean Claude Code session | `claude /install-plugin spsk@felipemachado/spsk` in fresh session |
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
