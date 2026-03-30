#!/usr/bin/env bash
# SpSk Output Parser -- extracts scores and verdicts from design-review terminal output
# Sourced by run-quality-evals.sh. Not run directly.

# Extract verdict from boss output.
# Matches "**Verdict: SHIP", "**Verdict: CONDITIONAL SHIP", "**Verdict: BLOCK"
# Also handles "Verdict: CONDITIONAL" without "SHIP" suffix.
extract_verdict() {
  local output="$1"
  local raw
  # Anchor to the **Verdict: prefix to avoid matching stray words in review text
  raw=$(echo "$output" | grep -oE '\*\*Verdict: (SHIP|CONDITIONAL SHIP|CONDITIONAL|BLOCK)' | head -1 | sed 's/\*\*Verdict: //')

  # Normalize: "CONDITIONAL SHIP" -> "CONDITIONAL"
  if [ "$raw" = "CONDITIONAL SHIP" ]; then
    echo "CONDITIONAL"
  else
    echo "$raw"
  fi
}

# Extract overall weighted score from boss output header.
# Matches "**Score: X.XX/4.0**" or "Score: X.XX/4.0"
extract_overall() {
  local output="$1"
  echo "$output" | grep -oE '\*?\*?Score: [0-9]+\.[0-9]+/4\.0' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1
}

# Extract per-specialist score from the scores table.
# Maps dimension keys (snake_case from assertions.json) to boss output table labels.
# Example: extract_score "intent_match" "$output" -> "3"
extract_score() {
  local dimension="$1"
  local output="$2"
  local label

  case "$dimension" in
    intent_match)  label="Intent Match" ;;
    originality)   label="Originality" ;;
    ux_flow)       label="UX Flow" ;;
    typography)    label="Typography" ;;
    color)         label="Color" ;;
    layout)        label="Layout" ;;
    icons)         label="Icons" ;;
    motion)        label="Motion" ;;
    copy)          label="Copy" ;;
    code_a11y)     label="Code" ;;
    *)             label="$dimension" ;;
  esac

  # Extract N from "| Label | N/4 | Wx |" in the scores table
  echo "$output" | grep -i "| $label " | grep -oE '[0-9]+\.?[0-9]*/4' | head -1 | grep -oE '^[0-9]+\.?[0-9]*'
}

# Float comparison: returns 0 (true) if value is within [min, max], 1 (false) otherwise.
# Uses python3 because bash cannot do native float comparison.
float_in_range() {
  local value="$1" min="$2" max="$3"

  if [ -z "$value" ]; then
    return 1
  fi

  python3 -c "import sys; v,lo,hi=float('$value'),float('$min'),float('$max'); sys.exit(0 if lo<=v<=hi else 1)"
}

# Compare verdicts with normalization.
# Handles: "CONDITIONAL SHIP" == "CONDITIONAL", "BLOCK" == "BLOCK", "SHIP" == "SHIP"
verdict_matches() {
  local actual="$1"
  local expected="$2"

  # Normalize both sides
  actual=$(echo "$actual" | sed 's/CONDITIONAL SHIP/CONDITIONAL/')
  expected=$(echo "$expected" | sed 's/CONDITIONAL SHIP/CONDITIONAL/')

  [ "$actual" = "$expected" ]
}
