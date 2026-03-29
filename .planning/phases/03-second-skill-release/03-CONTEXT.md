# Phase 3: Second Skill + Release - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Port the multi-model-code-review skill (2 files, 163 lines) into SpSk as the second skill proving platform capability. Add case studies with measurable impact. Cut v1.0.0 release with install.sh and plugin registry support. Build independent eval harness for code-review.

</domain>

<decisions>
## Implementation Decisions

### Code Review Port
- **D-37:** Port as a command (`commands/code-review.md`) — appears in `/help`, consistent with design-review pattern.
- **D-38:** Review guidelines go to `skills/code-review/references/review-guidelines.md` — mirrors design-review structure.
- **D-39:** 3-tier degradation same as design-review: Tier 1 (Claude + Codex + Gemini), Tier 2 (Claude + one CLI), Tier 3 (Claude-only). Report tier used in output.
- **D-40:** Use `shared/output.md` for branded output — signature line, symbols, footer. Proves shared patterns work across skills.
- **D-41:** Add code-review to `.claude-plugin/plugin.json` commands list.
- **D-42:** Source skill at `~/.claude/skills/multi-model-code-review/` (2 files: SKILL.md + review-guidelines.md).
- **D-43:** Replace hardcoded paths with `${CLAUDE_PLUGIN_ROOT}` during port.

### Eval Harness
- **D-44:** Structural validation: files exist, frontmatter valid, review-guidelines.md present, branded output reference present.
- **D-45:** Bundle a sample `.diff` fixture from a real PR (anonymized) for quality eval assertions.
- **D-46:** Range-based assertions, same pattern as design-review evals. Extend `evals/validate-structure.sh` with code-review checks.
- **D-47:** Independent quality eval assertions in `evals/assertions-code-review.json`.

### Case Studies
- **D-48:** 2 real case studies: (1) design-review before/after on a real project showing score improvement, (2) code-review catching real bugs in a PR.
- **D-49:** Case studies live in `docs/case-studies/` with measurable metrics (scores, bug counts, time savings).
- **D-50:** Case studies referenced from README.md.

### Release
- **D-51:** Simple `install.sh` bash script: clone repo, symlink to `~/.claude/plugins/spsk`.
- **D-52:** Update VERSION to 1.0.0, create git tag v1.0.0.
- **D-53:** Plugin installable via `claude /install-plugin spsk@felipemachado/spsk`.
- **D-54:** Update README with final install instructions, case study links, both skills documented.
- **D-55:** Update CHANGELOG.md with v1.0.0 release notes.

### Claude's Discretion
- Case study specific content and metrics (use realistic but representative numbers)
- install.sh error handling and messaging
- Code review command internal structure and agent orchestration details
- Eval fixture selection (which PR diff to bundle)

</decisions>

<canonical_refs>
## Canonical References

### Source Skill (port source)
- `~/.claude/skills/multi-model-code-review/SKILL.md` — 163 lines, main skill file
- `~/.claude/skills/multi-model-code-review/review-guidelines.md` — Review guidelines reference

### Existing Plugin (modify)
- `.claude-plugin/plugin.json` — Add code-review command
- `README.md` — Add code-review docs, case studies, final install instructions
- `CHANGELOG.md` — Add v1.0.0 release notes
- `VERSION` — Update to 1.0.0
- `evals/validate-structure.sh` — Add code-review structural checks
- `shared/output.md` — Already exists, reused by code-review

### Phase 1/2 Patterns
- `commands/design-review.md` — Reference for command structure and branding integration
- `config/scoring.json` — Reference for how design-review handles scoring (code-review uses confidence scores instead)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `shared/output.md` — Branding reference, ready for code-review to reference
- `evals/validate-structure.sh` — Structural validator, extend with Phase 3 checks
- `evals/run-evals.sh` — Eval orchestrator, extend with code-review layer
- Plugin structure established in Phase 1 — just add new command + skill files

### Established Patterns
- Commands in `commands/*.md` with YAML frontmatter
- References in `skills/<name>/references/` loaded via `@${CLAUDE_PLUGIN_ROOT}`
- Degradation tier detection via `which codex && which gemini`
- Branded output via `@${CLAUDE_PLUGIN_ROOT}/shared/output.md`

### Integration Points
- `plugin.json` needs new command entry
- `evals/validate-structure.sh` needs Phase 3 section
- README needs code-review documentation section
- CHANGELOG needs v1.0.0 entry

</code_context>

<specifics>
## Specific Ideas

- The code-review skill is much simpler than design-review (2 files vs 22) — port should be fast
- Case studies should show real numbers, not hypothetical ones
- The v1.0.0 release should feel like a milestone — CHANGELOG, tag, README all polished
- install.sh should work on a fresh machine with just git and Claude Code installed

</specifics>

<deferred>
## Deferred Ideas

- consensus-validation skill — deferred to v1.1.0 (still a good skill, just narrower audience)
- Plugin marketplace directory submission — post-v1.0.0
- CI/CD integration for design-review in GitHub Actions — v2

</deferred>

---

*Phase: 03-second-skill-release*
*Context gathered: 2026-03-29*
