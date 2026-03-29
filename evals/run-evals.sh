#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== SpSk Eval Harness ==="
echo ""

# Layer 1: Structural Validation
echo "--- Layer 1: Structural Validation ---"
if "$SCRIPT_DIR/validate-structure.sh"; then
  echo ""
  echo "[PASS] Layer 1: All structural checks passed"
else
  echo ""
  echo "[FAIL] Layer 1: Structural validation failed"
  exit 1
fi

echo ""

# Layer 2: Quality Evals (requires Claude Code session)
echo "--- Layer 2: Quality Evals ---"
if [ -z "${CLAUDE_SESSION:-}" ] && ! command -v claude &>/dev/null; then
  echo "[SKIP] Layer 2: Claude Code not available"
  echo "       Quality evals require an active Claude Code session."
  echo "       Run this script from within Claude Code to execute quality evals."
  echo ""
  echo "=== Results: Layer 1 PASSED, Layer 2 SKIPPED ==="
  exit 0
fi

# Layer 2a: Design-Review Quality Evals
echo "--- Layer 2a: Design-Review Quality Evals ---"
DR_ASSERTIONS=$(jq '.assertions | length' "$REPO_ROOT/evals/assertions.json" 2>/dev/null || echo 0)
echo "[INFO] Assertions defined in: evals/assertions.json ($DR_ASSERTIONS assertions)"
echo "[INFO] Fixtures in: evals/fixtures/*.html"
echo ""

# Layer 2b: Code-Review Quality Evals
echo "--- Layer 2b: Code-Review Quality Evals ---"
CR_ASSERTIONS=$(jq '.assertions | length' "$REPO_ROOT/evals/assertions-code-review.json" 2>/dev/null || echo 0)
echo "[INFO] Assertions defined in: evals/assertions-code-review.json ($CR_ASSERTIONS assertions)"
echo "[INFO] Fixtures in: evals/fixtures/sample-pr.diff"
echo ""

if [ -z "${CLAUDE_SESSION:-}" ] && ! command -v claude &>/dev/null; then
  echo "[SKIP] Layer 2: Claude Code not available"
  echo "       Quality evals require an active Claude Code session."
  echo "       Run this script from within Claude Code to execute quality evals."
  echo ""
  echo "=== Summary ==="
  echo "  Layer 1 (structural):           PASSED"
  echo "  Layer 2a (design-review):        SKIPPED ($DR_ASSERTIONS assertions defined)"
  echo "  Layer 2b (code-review):          SKIPPED ($CR_ASSERTIONS assertions defined)"
  exit 0
fi

echo "[TODO] Quality eval execution will be implemented when plugins"
echo "       can be invoked programmatically. For now, Layer 1 validates"
echo "       structural correctness. Quality benchmarks are documented"
echo "       in evals/results/."
echo ""
echo "=== Summary ==="
echo "  Layer 1 (structural):           PASSED"
echo "  Layer 2a (design-review):        PENDING ($DR_ASSERTIONS assertions defined)"
echo "  Layer 2b (code-review):          PENDING ($CR_ASSERTIONS assertions defined)"
exit 0
