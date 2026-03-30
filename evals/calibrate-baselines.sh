#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# SpSk Baseline Calibration Helper
#
# Runs design-review on a single fixture 3 times and reports score ranges.
# Use results to update assertions.json with calibrated min/max values.
#
# Usage:
#   bash evals/calibrate-baselines.sh admin-panel    # 3 runs on admin-panel
#   bash evals/calibrate-baselines.sh --all           # 3 runs on ALL fixtures (expensive!)
#
# After calibration, update evals/assertions.json with computed ranges:
#   min = floor(min_observed - 0.3)
#   max = ceil(max_observed + 0.3)
#
# Cost estimate:
#   1 fixture x 3 runs = ~15-45 min, ~300-600K tokens
#   4 fixtures x 3 runs = ~1-3 hours, ~1.2-2.4M tokens
#   Use --quick in run-quality-evals.sh for cheaper calibration runs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FIXTURE="${1:-}"

if [ -z "$FIXTURE" ]; then
  echo "SpSk Baseline Calibration Helper"
  echo ""
  echo "Usage: bash evals/calibrate-baselines.sh <fixture-name>"
  echo ""
  echo "  fixture-name: admin-panel, landing-page, emotional-page, gray-area"
  echo "  --all: run all fixtures (WARNING: expensive, ~12 full reviews)"
  echo ""
  echo "This runs 3 design-review evaluations per fixture and reports"
  echo "the observed score spread. Use results to update assertions.json"
  echo "ranges with: min = floor(min_observed - 0.3), max = ceil(max_observed + 0.3)"
  echo ""
  echo "Calibration process:"
  echo "  1. Run this script on each fixture (or --all)"
  echo "  2. Inspect evals/results/calibration-*.log files"
  echo "  3. Extract min/max overall scores from each run"
  echo "  4. Compute assertion range: [min - 0.3, max + 0.3]"
  echo "  5. Update evals/assertions.json with calibrated ranges"
  echo "  6. Commit the updated assertions.json"
  exit 1
fi

# Ensure results directory exists
mkdir -p "$SCRIPT_DIR/results"

# Use --quick mode for calibration to save tokens (research recommendation)
echo "[INFO] Calibration uses the runner in live mode (not --dry-run)"
echo "[INFO] For cheaper calibration, ensure the runner uses --quick mode"
echo "[INFO] Final calibration should verify ranges with full mode"
echo ""

FIXTURES=()
if [ "$FIXTURE" = "--all" ]; then
  FIXTURES=(admin-panel landing-page emotional-page gray-area)
else
  FIXTURES=("$FIXTURE")
fi

for fx in "${FIXTURES[@]}"; do
  echo "=== Calibrating: $fx ==="
  echo "[INFO] Running 3 reviews. This will take 15-45 minutes per fixture."
  echo ""

  for run in 1 2 3; do
    echo "--- Run $run/3 ---"
    LOG_FILE="$SCRIPT_DIR/results/calibration-${fx}-run${run}.log"
    bash "$SCRIPT_DIR/run-quality-evals.sh" --fixture "$fx" 2>&1 | tee "$LOG_FILE"
    echo ""
    echo "[INFO] Log saved: $LOG_FILE"
    echo ""
  done

  echo "[INFO] Review the 3 runs above and compute ranges:"
  echo "  min = floor(min_observed_score - 0.3)"
  echo "  max = ceil(max_observed_score + 0.3)"
  echo "  Update evals/assertions.json with computed ranges."
  echo ""
done

echo "=== Calibration Complete ==="
echo "Next: review logs in evals/results/calibration-*.log and update assertions.json"
