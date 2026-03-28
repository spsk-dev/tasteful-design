# Phase 1: Scaffold + Port + Evals - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-28
**Phase:** 01-scaffold-port-evals
**Areas discussed:** Plugin structure, Port strategy, Eval harness design, Documentation scope
**Mode:** auto (all areas auto-selected with recommended defaults)

---

## Plugin Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Standard `.claude-plugin/` | Follow official Anthropic plugin conventions with commands/, config/, references/, hooks/, scripts/ | ✓ |
| Flat structure | All files at root, minimal directories | |
| Custom layout | Non-standard organization | |

**User's choice:** Standard `.claude-plugin/` (auto-selected: recommended default)
**Notes:** Research confirmed this is the canonical structure. Deviating would cause discovery failures.

---

## Port Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Copy and audit paths | Preserve working structure, grep-audit for hardcoded paths, replace with ${CLAUDE_PLUGIN_ROOT} | ✓ |
| Restructure during port | Reorganize files into a new architecture while porting | |
| Decompose monolith | Break apart the large SKILL.md into separate agent files | |

**User's choice:** Copy and audit paths (auto-selected: recommended default)
**Notes:** Restructuring during port risks introducing bugs. Monolith decomposition can happen incrementally after the port is verified working.

---

## Eval Harness Design

| Option | Description | Selected |
|--------|-------------|----------|
| Both structural + quality | Structural validation (plugin.json, frontmatter) plus range-based quality assertions on review output | ✓ |
| Structural only | Just validate plugin format and file structure | |
| Quality only | Just test review output quality | |

**User's choice:** Both structural + quality (auto-selected: recommended default)
**Notes:** Structural tests are cheap and catch porting mistakes. Quality evals are the portfolio story. Both needed.

---

## Documentation Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Portfolio-grade | Full specialist roles, boss pattern, scoring, degradation, rationale — readable by hiring managers | ✓ |
| Developer-focused | Technical docs only, no narrative | |
| Minimal | README + inline comments | |

**User's choice:** Portfolio-grade (auto-selected: recommended default)
**Notes:** ARCHITECTURE.md is explicitly called out as the CV document. Cutting corners here defeats the purpose of SpSk.

---

## Claude's Discretion

- Plugin naming/metadata in plugin.json
- Internal reference file organization
- README structure and tone
- Eval assertion count and specific thresholds

## Deferred Ideas

None — discussion stayed within phase scope
