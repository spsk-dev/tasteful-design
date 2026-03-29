---
name: Code Review
description: Multi-model code review using Claude, Codex, and Gemini in parallel. Activates when reviewing PRs, checking code quality, or performing code review on pull requests.
---

# Code Review Skill

Multi-model PR code review using Claude + Codex + Gemini in parallel for higher coverage and fewer false negatives than any single model. 7 agents with confidence-scored findings and 3-tier degradation.

## When This Activates

- User asks to review a PR or pull request
- User mentions a PR number or GitHub PR URL
- User wants to check code for bugs or quality issues
- Discussion involves code review or PR feedback

## How It Works

1. **Pre-flight** -- Detect available CLIs (codex, gemini) to determine tier
2. **Eligibility** -- Check PR is open, not draft, not trivially simple
3. **7 Agents in Parallel** -- 5 Claude Sonnet + Codex + Gemini, each reviewing independently
4. **Confidence Scoring** -- Haiku agents score each finding 0-100
5. **Cross-model Agreement** -- Issues found by multiple models get extra weight
6. **Filter** -- Only findings scoring 80+ are reported
7. **Comment** -- Post branded review to the PR

## Commands

- `/code-review` -- Full multi-model PR review with confidence scoring

## References

Domain knowledge for review agents lives in `references/`:
- `review-guidelines.md` -- What to flag, what to skip, output format
