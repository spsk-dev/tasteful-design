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

# Layer 2: Quality Evals
echo "--- Layer 2: Quality Evals ---"
echo ""

# Layer 2a: Design-Review Quality Evals
echo "--- Layer 2a: Design-Review Quality Evals ---"
if "$SCRIPT_DIR/run-quality-evals.sh" "$@"; then
  echo ""
  echo "[PASS] Layer 2a: Design-review quality evals passed"
  L2A_STATUS="PASSED"
else
  echo ""
  echo "[FAIL] Layer 2a: Design-review quality evals had failures"
  L2A_STATUS="FAILED"
fi

echo ""

# Layer 2b: Code-Review Quality Evals (not yet implemented)
echo "--- Layer 2b: Code-Review Quality Evals ---"
CR_ASSERTIONS=$(jq '.assertions | length' "$REPO_ROOT/evals/assertions-code-review.json" 2>/dev/null || echo 0)
echo "[SKIP] Layer 2b: Code-review quality evals not yet implemented ($CR_ASSERTIONS assertions defined)"
L2B_STATUS="SKIPPED"

echo ""
echo "=== Summary ==="
echo "  Layer 1 (structural):           PASSED"
echo "  Layer 2a (design-review):        $L2A_STATUS"
echo "  Layer 2b (code-review):          $L2B_STATUS"

# Exit with failure if Layer 2a failed
[ "$L2A_STATUS" = "PASSED" ] || [ "$L2A_STATUS" = "SKIPPED" ]
