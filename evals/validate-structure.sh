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
check "shared/output.md contains footer" grep -q "github.com/felipemachado/spsk" "shared/output.md"

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

echo ""
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL checks passed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
