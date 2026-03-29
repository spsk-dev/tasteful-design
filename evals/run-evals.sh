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

echo "[INFO] Quality evals use range-based assertions against bundled fixtures."
echo "[INFO] Assertions defined in: evals/assertions.json"
echo "[INFO] Fixtures in: evals/fixtures/"
echo ""
echo "[TODO] Quality eval execution will be implemented when the plugin"
echo "       can be invoked programmatically. For now, Layer 1 validates"
echo "       structural correctness. Quality benchmarks are documented"
echo "       in evals/results/."
echo ""
echo "=== Results: Layer 1 PASSED, Layer 2 PENDING ==="
exit 0
