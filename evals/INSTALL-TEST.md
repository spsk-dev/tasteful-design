# Clean-Machine Install Test

Manual test protocol to verify SpSk installs and works from a fresh environment.

## Prerequisites

- Claude Code installed and authenticated
- Git installed
- `jq` installed (used by structural evals)
- No prior SpSk installation (clean session)

## Test Steps

### 1. Install the Plugin

Open a fresh Claude Code session and run:

```bash
claude /install-plugin tasteful-design@spsk-dev/tasteful-design
```

**Expected:** Plugin installs without errors. Claude Code confirms successful installation.

### 2. Verify Commands Register

```bash
/design
```

**Expected:** Shows available sub-commands (review, improve, validate, check, ship). No errors.

### 3. Run a Design Review

Create a test HTML file or use any local HTML, then:

```bash
/design-review path/to/test.html
```

**Expected:**
- 7 specialist scores appear in output (Font, Color, Layout, Icon, Motion, Intent/Originality/UX, Code/A11y)
- Weighted overall score is calculated
- SHIP, CONDITIONAL, or BLOCK verdict is displayed
- Prioritized fix list with severity tags

### 4. Test Quick Mode

```bash
/design-review --quick path/to/test.html
```

**Expected:** 4 specialist scores (Font, Color, Layout, Intent). Faster execution (~5 min vs ~8 min).

### 5. Run Structural Evals

From the installed plugin directory:

```bash
./evals/run-evals.sh
```

**Expected:** All structural checks pass (`[PASS]` for each). Layer 2 quality evals skip gracefully if not in Claude Code session context.

### 6. Verify Hooks

Edit any `.html`, `.css`, `.tsx`, or `.jsx` file in your project. After the edit:

**Expected:** A suggestion to run `/design-review` appears (PostToolUse hook fires on Write/Edit for frontend files).

## Failure Modes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Plugin not found" on install | Repo not published / wrong path | Verify `spsk-dev/tasteful-design` exists on GitHub |
| `/design-review` not recognized | Plugin didn't register commands | Re-install, check `.claude-plugin/plugin.json` |
| "jq: command not found" | Missing dependency | `brew install jq` (macOS) or `apt install jq` (Linux) |
| Playwright errors | Chromium not installed | `npx playwright install chromium` |
| "Gemini not available" | No Gemini CLI | Normal -- falls back to Tier 2 (Claude only) |
| Structural eval fails | Files missing or modified | Re-clone and check `git status` |

## Cleanup

To uninstall:

```bash
claude /uninstall-plugin spsk
```

Verify removal:
```bash
/design
```

**Expected:** Command not recognized after uninstall.
