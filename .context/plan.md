---
name: SpSk (Simple Skill) — GitHub portfolio project (2026-03-28)
description: GitHub showcase of polished AI skills. Design-review is flagship. Consensus-validation is 2nd skill. 3-phase GSD plan ready. All research at /tmp/spsk-research.md and /tmp/spsk-intent.md.
type: project
---

## What Is SpSk
GitHub project (github.com/felipemachado/spsk) to publish Felipe's most polished AI skills as portfolio pieces. This is his CV — demonstrates deep understanding of AI agent architectures, harnesses, and their practical value.

**Why:** Felipe built a design-review plugin that went from 0 to 8.6/10 in one session. Wants to publish it professionally as a showcase.

## 3-Model Strategy Consensus (2026-03-28)

### Build approach: GSD for 3 phases, then standalone
- Phase 1: Repo scaffold + design-review port + evals + ARCHITECTURE.md
- Phase 2: Init wizard + palette engine + branded output + demo GIF
- Phase 3: 2nd skill (consensus-validation) + case studies + v1.0.0 release

### Scope: Showcase repo, NOT a framework
Flagship plugin (design-review) + shared utilities (branded output, palette helper). Framework emerges from 2nd/3rd skills, not before.

### Init wizard: 5 questions, opinionated defaults
1. What are you building? (page type)
2. Pick a vibe (preset)
3. Light/dark/both
4. Brand colors (or skip → 3 palette suggestions with Design Identity names)
5. Font preference (or skip → suggest based on vibe)

Creates .design/ with configured tokens. Under 2 minutes to first value.

### Branding: Clean, compact, not ASCII art
- Signature line: ` SpSk  design-review  v1.2.0  ───  8 specialists  ·  tier 1`
- Unicode boxes for checkpoints/results
- Symbol vocabulary: ✓ ✗ ◆ ○ ⚡ ⚠
- Progress bars: ████░░ for scores
- Footer with repo link on every review output
- GSD research at /tmp/spsk-research.md (formatting patterns, stage banners, templates)

### Distribution: Claude Code plugin registry + GitHub
`claude /install-plugin design-review@felipemachado/spsk` + install.sh for manual

### What makes it 10/10 (killer insights from 3 models)
1. **Evals are the crown jewel** — run-evals.sh, reproducible benchmarks (Opus)
2. **Show what DIDN'T work** — v1 single-agent scored 40%, show rejected approaches (Opus)
3. **"The tool is the proof; the architecture is the CV"** (Gemini)
4. **Visible meta-cognition** — show specialist disagreements and how boss resolved them (Gemini)
5. **Case studies with measurable impact** — mothers-day before/after, harness panel review (Codex)
6. **30-second demo GIF** in README (all 3)
7. **Add consensus-validation as 2nd skill** — one plugin = one-off, two = platform (Opus)

## Design-Review Plugin Status
At ~/.claude/plugins/design-review/ — 22 files, v1.0.0, 8.6/10 consensus score.
Ready to port to SpSk repo.

## How to apply
Start with `/gsd:new-project` in a fresh session. The plan above is the roadmap.
Read /tmp/spsk-research.md for GSD formatting patterns.
Read /tmp/spsk-intent.md for full context.
