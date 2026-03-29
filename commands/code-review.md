---
name: code-review
description: >
  Multi-model PR code review -- uses Claude, Codex, and Gemini in parallel for higher coverage
  and fewer false negatives than single-model review. 7 agents with confidence scoring and
  3-tier degradation. Use this whenever you want to review a PR, check code for bugs, or
  get a thorough code review on a pull request.
allowed-tools: Bash(gh *), Bash(codex *), Bash(gemini *), Bash(which *), Bash(cd *), Bash(cp *), Bash(rm *)
---

@${CLAUDE_PLUGIN_ROOT}/shared/output.md

## Output Format

Use the branded output format from shared/output.md for all review output. Start with the signature line, use single-line Unicode boxes for sections, end with the footer.

**Signature line for code-review:**
```
 SpSk  code-review  v{version}  ───  {agent_count} agents  ·  tier {tier}
```

- **{version}**: read from `${CLAUDE_PLUGIN_ROOT}/VERSION`
- **{agent_count}**: `7` for Tier 1, `6` for Tier 2, `5` for Tier 3
- **{tier}**: from CLI availability detection (see Pre-flight below)

**Comment footer** (replaces plain "Generated with" line):
```
 SpSk  code-review  v{version}  ·  tier {tier}
github.com/felipemachado/spsk
```

---

# Code Review -- Multi-Model Agent Swarm

Provide a multi-model code review for the given pull request using Claude, Codex, and Gemini.

The PR number or URL comes from `$ARGUMENTS`. If no argument is provided, ask the user for the PR number.

## Multi-PR reviews

When multiple PR numbers are provided (e.g., `107 346`), or when the user provides cross-repo context, review each PR independently but include the cross-repo alignment context in each agent's prompt. Run all agents for all PRs in parallel. When posting comments, post to each PR's respective repo using `--repo OWNER/REPO`.

## Repo detection

Always determine the repo from:
1. The current git remote (`git remote get-url origin`)
2. A GitHub PR URL if provided
3. Explicit user context

Always pass `--repo OWNER/REPO` to all `gh pr` commands to avoid ambiguity, especially when reviewing PRs from different repos in the same session.

## Pre-flight: verify external CLIs

Before launching the external model agents, check that both CLIs are available:

```bash
which codex && which gemini
```

### Degradation Tiers

| Tier | Condition | Agents | Quality |
|------|-----------|--------|---------|
| 1 -- Full | Codex + Gemini available | 7 (5 Claude + Codex + Gemini) | Best -- cross-model consensus |
| 2 -- Partial | Only one CLI available | 6 (5 Claude + available CLI) | Good -- note missing model |
| 3 -- Claude-only | Neither CLI available | 5 (Claude Sonnet only) | Adequate -- no cross-model signal |

- If both are installed, proceed with all 7 agents (Tier 1).
- If only one is installed, proceed with 6 agents (Tier 2). Note in the final comment which model was unavailable.
- If neither is installed, fall back to the 5 Sonnet agents only (Tier 3) and note that Codex and Gemini were unavailable.

Always report the detected tier in the output signature line.

## Pre-flight: prepare local files for external CLIs

Both Codex and Gemini have sandbox/workspace restrictions that prevent them from accessing GitHub APIs or reading files outside the repo directory. To work around this:

1. **Save the PR diff to a local file in the repo root:**
   ```bash
   gh pr diff <PR_NUMBER> --repo <OWNER/REPO> > /tmp/pr<PR_NUMBER>.diff
   cp /tmp/pr<PR_NUMBER>.diff <REPO_ROOT>/pr<PR_NUMBER>.diff
   ```

2. **Copy the review guidelines into the repo root:**
   ```bash
   cp ${CLAUDE_PLUGIN_ROOT}/skills/code-review/references/review-guidelines.md <REPO_ROOT>/.review-guidelines.md
   ```

3. **After the review completes, clean up these temp files:**
   ```bash
   rm -f <REPO_ROOT>/pr<PR_NUMBER>.diff <REPO_ROOT>/.review-guidelines.md
   ```

### Known CLI constraints

- **Codex sandbox blocks network access**: Codex runs in a sandboxed environment that cannot reach `api.github.com`. It cannot run `gh` commands. Always pass the diff as a local file.
- **Gemini workspace restriction**: Gemini can only read files within the current workspace directory (the repo root). It cannot read files from outside the workspace. Copy any needed files into the repo root.
- **Codex recursive multi-model**: Codex may try to invoke Claude/Gemini from within its session. The prompt must explicitly tell it to review the diff itself, NOT to run other model CLIs.
- **Claude nested sessions**: If Codex tries to call `claude -p`, it will fail with "cannot be launched inside another Claude Code session". This is expected and harmless if Codex does its own review.
- **Both CLIs should be run from the repo directory**: Always `cd` to the repo root before invoking them, or use the `cwd` option.

## Steps

1. Use a Haiku agent to check if the pull request (a) is closed, (b) is a draft, (c) does not need a code review (eg. because it is an automated pull request, or is very simple and obviously ok), or (d) already has a code review from you from earlier. If so, do not proceed.
2. Use another Haiku agent to give you a list of file paths to (but not the contents of) any relevant CLAUDE.md files from the codebase: the root CLAUDE.md file (if one exists), as well as any CLAUDE.md files in the directories whose files the pull request modified.
3. Use a Haiku agent to view the pull request, and ask the agent to return a summary of the change.
4. Launch up to 7 parallel agents to independently code review the change. Agents #1-#5 are Sonnet agents, Agent #6 uses Codex, and Agent #7 uses Gemini (subject to CLI availability from pre-flight). Each agent returns a list of issues with the reason each was flagged (eg. CLAUDE.md adherence, bug, historical git context, external model finding, etc.):
   a. Agent #1: Audit the changes to make sure they comply with the CLAUDE.md. Note that CLAUDE.md is guidance for Claude as it writes code, so not all instructions will be applicable during code review.
   b. Agent #2: Read the file changes in the pull request, then do a shallow scan for obvious bugs. Avoid reading extra context beyond the changes, focusing just on the changes themselves. Focus on large bugs, and avoid small issues and nitpicks. Ignore likely false positives.
   c. Agent #3: Read the git blame and history of the code modified, to identify any bugs in light of that historical context.
   d. Agent #4: Read previous pull requests that touched these files, and check for any comments on those pull requests that may also apply to the current pull request.
   e. Agent #5: Read code comments in the modified files, and make sure the changes in the pull request comply with any guidance in the comments.
   f. Agent #6 (Codex): Run the Codex CLI in non-interactive exec mode from the repo directory to independently review the PR diff. The diff and guidelines must already be saved as local files (see "Pre-flight: prepare local files" above). Codex CANNOT access GitHub APIs from its sandbox -- never ask it to run `gh` commands. Substitute the actual PR number for `<PR_NUMBER>`:
      ```bash
      cd <REPO_ROOT> && codex exec --full-auto "Read the file .review-guidelines.md in the current directory for your review guidelines. Then read the file pr<PR_NUMBER>.diff in the current directory -- it contains the full diff of PR #<PR_NUMBER>. This PR is titled '<PR_TITLE>'. Review the diff according to the guidelines. Focus on bugs and logic errors only. Do NOT try to run other model CLIs (claude, gemini) -- you are the only reviewer. Return each issue with: file path, line reference, description, and severity. If no issues found, say so."
      ```
      Parse its output and return issues in the same format as the other agents.
   g. Agent #7 (Gemini): Run the Gemini CLI in non-interactive mode from the repo directory to independently review the PR diff. The diff and guidelines must already be saved as local files (see "Pre-flight: prepare local files" above). Gemini CANNOT read files outside the workspace directory. Substitute the actual PR number for `<PR_NUMBER>`:
      ```bash
      cd <REPO_ROOT> && gemini -y -p "Read the file .review-guidelines.md in the current directory for your review guidelines. Then read the file pr<PR_NUMBER>.diff in the current directory -- it contains the full diff of PR #<PR_NUMBER>. This PR is titled '<PR_TITLE>'. Review the diff according to the guidelines. Focus on bugs and logic errors only. Do NOT try to run other model CLIs (claude, codex) -- you are the only reviewer. Return each issue with: file path, line reference, description, and severity. If no issues found, say so."
      ```
      Parse its output and return issues in the same format as the other agents.
5. For each issue found in step 4 (across all agents), launch a parallel Haiku agent that takes the PR, issue description, and list of CLAUDE.md files (from step 2), and returns a confidence score. For issues flagged due to CLAUDE.md instructions, the agent should double check that the CLAUDE.md actually calls out that issue specifically. The scale is (give this rubric to the agent verbatim):
   a. 0: Not confident at all. This is a false positive that doesn't stand up to light scrutiny, or is a pre-existing issue.
   b. 25: Somewhat confident. This might be a real issue, but may also be a false positive. The agent wasn't able to verify that it's a real issue. If the issue is stylistic, it is one that was not explicitly called out in the relevant CLAUDE.md.
   c. 50: Moderately confident. The agent was able to verify this is a real issue, but it might be a nitpick or not happen very often in practice. Relative to the rest of the PR, it's not very important.
   d. 75: Highly confident. The agent double checked the issue, and verified that it is very likely it is a real issue that will be hit in practice. The existing approach in the PR is insufficient. The issue is very important and will directly impact the code's functionality, or it is an issue that is directly mentioned in the relevant CLAUDE.md.
   e. 100: Absolutely certain. The agent double checked the issue, and confirmed that it is definitely a real issue, that will happen frequently in practice. The evidence directly confirms this.
6. Filter out any issues with a score less than 80. If there are no issues that meet this criteria, do not proceed.
7. Use a Haiku agent to repeat the eligibility check from step 1, to make sure that the pull request is still eligible for code review.
8. Finally, use the gh bash command to comment back on the pull request with the result.

### Comment formatting

When writing the comment, keep in mind:
- Keep your output brief
- Avoid emojis
- Link and cite relevant code, files, and URLs

**Branded comment format** (for issues found):

```
### Code review

 SpSk  code-review  v{version}  ·  tier {tier}

Found {N} issues:

1. {brief description of bug} (CLAUDE.md says "{...}")

{link to file and line with full sha1 + line range}

2. {brief description of bug}

{link to file and line with full sha1 + line range}

---
github.com/felipemachado/spsk

<sub>- If this code review was useful, please react with a thumbs up. Otherwise, react with a thumbs down.</sub>
```

**Branded comment format** (no issues):

```
### Code review

 SpSk  code-review  v{version}  ·  tier {tier}

No issues found. Checked for bugs and CLAUDE.md compliance.

---
github.com/felipemachado/spsk
```

When linking to code, follow this format precisely, otherwise the Markdown preview won't render correctly: `https://github.com/owner/repo/blob/<full-sha>/path/file.ext#L10-L15`
- Requires full git sha
- You must provide the full sha. Commands like `$(git rev-parse HEAD)` will not work since the comment is rendered as Markdown.
- Repo name must match the repo you're code reviewing
- `#` sign after the file name
- Line range format is `L[start]-L[end]`
- Provide at least 1 line of context before and after

## False positive guidance (for steps 4 and 5)

- Pre-existing issues
- Something that looks like a bug but is not actually a bug
- Pedantic nitpicks that a senior engineer wouldn't call out
- Issues that a linter, typechecker, or compiler would catch (eg. missing or incorrect imports, type errors, broken tests, formatting issues, pedantic style issues like newlines). No need to run these build steps yourself -- it is safe to assume that they will be run separately as part of CI.
- General code quality issues (eg. lack of test coverage, general security issues, poor documentation), unless explicitly required in CLAUDE.md
- Issues that are called out in CLAUDE.md, but explicitly silenced in the code (eg. due to a lint ignore comment)
- Changes in functionality that are likely intentional or are directly related to the broader change
- Real issues, but on lines that the user did not modify in their pull request

## Notes

- Do not check build signal or attempt to build or typecheck the app. These will run separately, and are not relevant to your code review.
- Use `gh` to interact with Github (eg. to fetch a pull request, or to create inline comments), rather than web fetch
- Make a todo list first
- You must cite and link each bug (eg. if referring to a CLAUDE.md, you must link it)
- Issues found by Codex or Gemini that also overlap with issues found by Sonnet agents should be given extra weight -- cross-model agreement is a strong signal.
