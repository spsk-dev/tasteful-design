#!/usr/bin/env bash
# SpSk Output Parser -- extracts scores and verdicts from design-review output
# Supports structured JSON (v1.2.0+) with regex fallback for pre-v1.2.0 output.
# Sourced by run-quality-evals.sh. Not run directly.

# ---------------------------------------------------------------------------
# JSON extraction helpers (v1.2.0+)
# Try structured JSON from <boss_output> tags first; callers fall back to regex.
# ---------------------------------------------------------------------------

# Extract raw JSON between <tag> and </tag> XML wrappers.
extract_json_block() {
  local output="$1"
  local tag="$2"
  echo "$output" | sed -n "/<${tag}>/,/<\/${tag}>/p" | sed '1d;$d'
}

# Extract verdict from <boss_output> JSON via jq.
extract_verdict_json() {
  local output="$1"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e '.verdict' &>/dev/null; then
    echo "$json" | jq -r '.verdict' | sed 's/CONDITIONAL SHIP/CONDITIONAL/'
  fi
}

# Extract weighted_score from <boss_output> JSON via jq.
extract_overall_json() {
  local output="$1"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e '.weighted_score' &>/dev/null; then
    echo "$json" | jq -r '.weighted_score'
  fi
}

# Extract per-specialist score from <boss_output> JSON via jq.
extract_score_json() {
  local dimension="$1"
  local output="$2"
  local json
  json=$(extract_json_block "$output" "boss_output")
  if [ -n "$json" ] && echo "$json" | jq -e ".scores.${dimension}" &>/dev/null; then
    echo "$json" | jq -r ".scores.${dimension}"
  fi
}

# ---------------------------------------------------------------------------
# Public API (JSON-first with regex fallback)
# ---------------------------------------------------------------------------

# Extract verdict from boss output.
# Tries JSON extraction first; falls back to regex for pre-v1.2.0 output.
extract_verdict() {
  local output="$1"

  # JSON-first: try structured <boss_output> extraction
  local result
  result=$(extract_verdict_json "$output")
  if [ -n "$result" ]; then
    echo "$result"
    return
  fi

  # Regex fallback: anchor to **Verdict: prefix
  local raw
  raw=$(echo "$output" | grep -oE '\*\*Verdict: (SHIP|CONDITIONAL SHIP|CONDITIONAL|BLOCK)' | head -1 | sed 's/\*\*Verdict: //')

  # Normalize: "CONDITIONAL SHIP" -> "CONDITIONAL"
  if [ "$raw" = "CONDITIONAL SHIP" ]; then
    echo "CONDITIONAL"
  else
    echo "$raw"
  fi
}

# Extract overall weighted score from boss output header.
# Tries JSON extraction first; falls back to regex for pre-v1.2.0 output.
extract_overall() {
  local output="$1"

  # JSON-first: try structured <boss_output> extraction
  local result
  result=$(extract_overall_json "$output")
  if [ -n "$result" ]; then
    echo "$result"
    return
  fi

  # Regex fallback: matches "**Score: X.XX/4.0**" or "Score: X.XX/4.0"
  echo "$output" | grep -oE '\*?\*?Score: [0-9]+\.[0-9]+/4\.0' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1
}

# Extract per-specialist score from the scores table.
# Tries JSON extraction first; falls back to regex table scraping for pre-v1.2.0.
# Example: extract_score "intent_match" "$output" -> "3"
extract_score() {
  local dimension="$1"
  local output="$2"

  # JSON-first: try structured <boss_output> extraction
  local result
  result=$(extract_score_json "$dimension" "$output")
  if [ -n "$result" ]; then
    echo "$result"
    return
  fi

  # Regex fallback: map dimension key to table label
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
