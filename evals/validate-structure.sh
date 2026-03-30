#!/usr/bin/env bash
set -uo pipefail

# SpSk Structural Validator (Layer 1)
# Validates plugin structure without requiring Claude Code.
# Note: set -e is intentionally omitted -- the check() function handles errors.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "[PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

# 1. Plugin manifest exists and is valid JSON with required fields
check "plugin.json exists" test -f .claude-plugin/plugin.json
check "plugin.json is valid JSON" jq empty .claude-plugin/plugin.json
check "plugin.json has name field" jq -e '.name' .claude-plugin/plugin.json
check "plugin.json has version field" jq -e '.version' .claude-plugin/plugin.json
check "plugin.json has description field" jq -e '.description' .claude-plugin/plugin.json

# 2. Command files exist
for cmd in design.md design-review.md design-improve.md design-validate.md; do
  check "commands/$cmd exists" test -f "commands/$cmd"
done

# 3-4. Command frontmatter with description
for cmd in design.md design-review.md design-improve.md design-validate.md; do
  check "commands/$cmd has frontmatter" bash -c "head -1 'commands/$cmd' | grep -q '^---'"
  check "commands/$cmd has description field" grep -q '^description:' "commands/$cmd"
done

# 5. Config JSON files valid
for cfg in scoring.json anti-slop.json style-presets.json; do
  check "config/$cfg is valid JSON" jq empty "config/$cfg"
done

# 6. Hooks valid and contains PostToolUse
check "hooks/hooks.json is valid JSON" jq empty hooks/hooks.json
check "hooks/hooks.json contains PostToolUse" jq -e '.hooks.PostToolUse' hooks/hooks.json

# 7. Skill file exists with frontmatter
check "skills/design-review/SKILL.md exists" test -f skills/design-review/SKILL.md
check "skills/design-review/SKILL.md has frontmatter" bash -c "head -1 skills/design-review/SKILL.md | grep -q '^---'"

# 8. Reference files (at least 5)
REF_COUNT=$(find skills/design-review/references -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
check "At least 5 reference files in skills/design-review/references/ (found $REF_COUNT)" test "$REF_COUNT" -ge 5

# 9. No hardcoded paths (exclude this script and evals/ from the search)
PATTERN_A="/Users/"
PATTERN_B="$HOME/.claude/plugins/design-review"
HARDCODED=$(grep -rn "$PATTERN_A\|$PATTERN_B" \
  --include='*.md' --include='*.json' --include='*.sh' \
  --exclude-dir=.git --exclude-dir=.planning --exclude-dir=.context --exclude-dir=evals --exclude-dir=.memsearch --exclude-dir=.claude . 2>/dev/null || true)
check "No hardcoded user paths" test -z "$HARDCODED"

# 10. VERSION file with semver
check "VERSION file exists" test -f VERSION
check "VERSION matches semver pattern" bash -c "grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION"

# 11. Required root files
for f in README.md CLAUDE.md LICENSE; do
  check "$f exists" test -f "$f"
done
# ARCHITECTURE.md and CHANGELOG.md are created by plan 01-02 (parallel wave)
# Check if they exist but don't fail the whole suite if missing
if [ -f ARCHITECTURE.md ]; then
  check "ARCHITECTURE.md exists" test -f ARCHITECTURE.md
else
  echo "[SKIP] ARCHITECTURE.md (created by plan 01-02)"
fi
if [ -f CHANGELOG.md ]; then
  check "CHANGELOG.md exists" test -f CHANGELOG.md
else
  echo "[SKIP] CHANGELOG.md (created by plan 01-02)"
fi

# 12. Hook script executable
check "scripts/suggest-review.sh is executable" test -x scripts/suggest-review.sh

# Phase 2: Init wizard + branding + demo

# design-init.md
check "commands/design-init.md exists" test -f "commands/design-init.md"
check "commands/design-init.md has frontmatter" bash -c "head -1 'commands/design-init.md' | grep -q '^---'"
check "commands/design-init.md has description field" grep -q '^description:' "commands/design-init.md"

# shared/output.md
check "shared/output.md exists" test -f "shared/output.md"
check "shared/output.md contains signature line" grep -q "SpSk" "shared/output.md"
check "shared/output.md contains footer" grep -q "github.com/spsk-dev/tasteful-design" "shared/output.md"

# config/palettes.json
check "config/palettes.json is valid JSON" jq empty "config/palettes.json"
check "config/palettes.json has all 5 page types" jq -e '.landing and .dashboard and .admin and .docs and .portfolio' "config/palettes.json"
check "Each page type has 3 palettes" jq -e '[.landing, .dashboard, .admin, .docs, .portfolio | length == 3] | all' "config/palettes.json"

# Branding reference in all commands
check "design-review.md references shared/output.md" grep -q "shared/output.md" "commands/design-review.md"
check "design-improve.md references shared/output.md" grep -q "shared/output.md" "commands/design-improve.md"
check "design-validate.md references shared/output.md" grep -q "shared/output.md" "commands/design-validate.md"
check "design.md references shared/output.md" grep -q "shared/output.md" "commands/design.md"

# Demo GIF
if [ -f assets/demo.gif ]; then
  check "assets/demo.gif under 5MB" bash -c '[ $(stat -f%z assets/demo.gif) -lt 5242880 ]'
else
  echo "[SKIP] assets/demo.gif (created by demo recording)"
fi
check "README.md embeds demo GIF" grep -q "demo.gif" "README.md"

# Router includes init
check "design.md routes to design-init" grep -q "design-init" "commands/design.md"

# Release artifacts
check "install.sh is executable" test -x install.sh

# CHANGELOG.md contains 1.0.0
check "CHANGELOG.md contains 1.0.0" grep -q "1.0.0" "CHANGELOG.md"

# Phase 6: HTML diagnostic report
check "scripts/generate-report.sh exists" test -f "scripts/generate-report.sh"
check "scripts/generate-report.sh is executable" test -x "scripts/generate-report.sh"
check "report test fixture exists" test -f "evals/fixtures/report-test/flow-state.json"
check "report fixture has 3 screens" bash -c "jq '.screens | length' evals/fixtures/report-test/flow-state.json | grep -q '^3$'"

# flow-scoring.json (required by report)
check "config/flow-scoring.json is valid JSON" jq empty "config/flow-scoring.json"

# Phase 8: Extracted specialist prompts
PROMPT_DIR="skills/design-review/prompts"

# 8.1 Prompt file existence (9 checks)
for prompt in font.md color.md layout.md icons.md motion.md intent.md code-a11y.md boss.md; do
  check "$PROMPT_DIR/$prompt exists" test -f "$PROMPT_DIR/$prompt"
done

# 8.2 Required XML tags in specialist prompts (4 checks per file, 8 files = 32 checks)
for prompt in font.md color.md layout.md icons.md motion.md intent.md code-a11y.md; do
  check "$prompt has <role> tag" grep -q '<role>' "$PROMPT_DIR/$prompt"
  check "$prompt has <instructions> tag" grep -q '<instructions>' "$PROMPT_DIR/$prompt"
  check "$prompt has <scoring_rubric> tag" grep -q '<scoring_rubric>' "$PROMPT_DIR/$prompt"
  check "$prompt has <output_format> tag" grep -q '<output_format>' "$PROMPT_DIR/$prompt"
done

# 8.3 Boss synthesizer has different required tags (5 checks)
check "boss.md has <role> tag" grep -q '<role>' "$PROMPT_DIR/boss.md"
check "boss.md has <instructions> tag" grep -q '<instructions>' "$PROMPT_DIR/boss.md"
check "boss.md has <scoring_formula> tag" grep -q '<scoring_formula>' "$PROMPT_DIR/boss.md"
check "boss.md has <verdict_rules> tag" grep -q '<verdict_rules>' "$PROMPT_DIR/boss.md"
check "boss.md has <output_format> tag" grep -q '<output_format>' "$PROMPT_DIR/boss.md"

# 8.4 Scoring rubrics have concrete anchors -- spot-check (2 checks)
check "Specialist prompts have 4-level rubrics" bash -c "grep -l '1 (Poor)' $PROMPT_DIR/font.md $PROMPT_DIR/color.md $PROMPT_DIR/intent.md | wc -l | tr -d ' ' | grep -q '^3$'"
check "Rubrics have Excellent level" bash -c "grep -l '4 (Excellent)' $PROMPT_DIR/font.md $PROMPT_DIR/color.md $PROMPT_DIR/intent.md | wc -l | tr -d ' ' | grep -q '^3$'"

# 8.5 No aggressive directives in prompt files (1 check)
AGGRESSIVE=$(grep -rn 'FLAG SPECIFICALLY\|Find at least [0-9]' "$PROMPT_DIR/" 2>/dev/null || true)
check "No aggressive directives in prompts" test -z "$AGGRESSIVE"

# 8.6 design-review.md references extracted prompts (2 checks)
check "design-review.md includes font.md prompt" grep -q 'prompts/font.md' commands/design-review.md
check "design-review.md includes boss.md prompt" grep -q 'prompts/boss.md' commands/design-review.md

# Phase 11: Weight-sum integrity
WEIGHT_SUM=$(jq '[.weights[]] | add' config/scoring.json)
TOTAL_WEIGHT=$(jq '.total_weight' config/scoring.json)
check "Sum of individual weights ($WEIGHT_SUM) equals total_weight ($TOTAL_WEIGHT)" test "$WEIGHT_SUM" -eq "$TOTAL_WEIGHT"

# Phase 12: Playwright interaction protocol
check "Phase 12: design-review.md contains --interact flag" grep -q '\-\-interact' "commands/design-review.md"
check "Phase 12: design-review.md contains Phase 0.5i interaction protocol" grep -q 'Phase 0.5i' "commands/design-review.md"
check "Phase 12: design-review.md uses browser_hover for Playwright MCP hover" grep -q 'browser_hover' "commands/design-review.md"
check "Phase 12: design-review.md contains INTERACT_MODE flag state variable" grep -q 'INTERACT_MODE' "commands/design-review.md"

echo ""
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL checks passed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
