#!/usr/bin/env bash
set -uo pipefail

# SpSk HTML Report Generator
# Reads flow-state.json and produces a self-contained HTML diagnostic report.
# Zero npm dependencies. Requires: jq, base64, sips (macOS) or convert (ImageMagick).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
usage() {
  cat <<'USAGE'
SpSk HTML Report Generator

Usage:
  generate-report.sh <flow-state.json> [output.html]

Arguments:
  flow-state.json   Path to the flow-state.json produced by /design-audit
  output.html       Output HTML path (default: same dir as input, report-{timestamp}.html)

Options:
  --help, -h        Show this help message

Examples:
  generate-report.sh /tmp/design-audit-abc/flow-state.json
  generate-report.sh flow-state.json report.html
USAGE
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || -z "${1:-}" ]]; then
  usage
fi

FLOW_STATE="$1"
if [[ ! -f "$FLOW_STATE" ]]; then
  echo "ERROR: File not found: $FLOW_STATE" >&2
  exit 1
fi

if ! jq empty "$FLOW_STATE" 2>/dev/null; then
  echo "ERROR: Invalid JSON: $FLOW_STATE" >&2
  exit 1
fi

SCREEN_COUNT=$(jq '.screens | length' "$FLOW_STATE")
if [[ "$SCREEN_COUNT" -lt 1 ]]; then
  echo "ERROR: No screens found in $FLOW_STATE" >&2
  exit 1
fi

# Output path
if [[ -n "${2:-}" ]]; then
  OUTPUT_HTML="$2"
else
  INPUT_DIR="$(cd "$(dirname "$FLOW_STATE")" && pwd)"
  TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
  OUTPUT_HTML="${INPUT_DIR}/report-${TIMESTAMP}.html"
fi

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
OS_TYPE=$(uname -s)
base64_encode() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    base64 < "$1"
  else
    base64 -w0 < "$1"
  fi
}

# ---------------------------------------------------------------------------
# Screenshot processing: PNG -> JPEG (80% quality, max 1200px) -> base64
# ---------------------------------------------------------------------------
MAX_REPORT_SIZE=4194304  # 4MB budget for images
JPEG_QUALITY=80
CUMULATIVE_SIZE=0

convert_screenshot() {
  local png_path="$1"
  local quality="${2:-$JPEG_QUALITY}"

  if [[ ! -f "$png_path" ]]; then
    echo ""
    return
  fi

  local tmp_jpg
  tmp_jpg=$(mktemp /tmp/spsk-report-XXXXXX.jpg)

  if [[ "$OS_TYPE" == "Darwin" ]] && command -v sips &>/dev/null; then
    # macOS: sips for resize + format conversion
    local tmp_copy
    tmp_copy=$(mktemp /tmp/spsk-report-src-XXXXXX.png)
    cp "$png_path" "$tmp_copy"
    sips --resampleWidth 1200 "$tmp_copy" --setProperty format jpeg --setProperty formatOptions "$quality" -o "$tmp_jpg" &>/dev/null 2>&1 || {
      # If resize fails (image smaller than 1200), just convert format
      sips --setProperty format jpeg --setProperty formatOptions "$quality" "$tmp_copy" -o "$tmp_jpg" &>/dev/null 2>&1 || cp "$png_path" "$tmp_jpg"
    }
    rm -f "$tmp_copy"
  elif command -v convert &>/dev/null; then
    # Linux: ImageMagick
    convert "$png_path" -resize '1200x>' -quality "$quality" "$tmp_jpg" 2>/dev/null || cp "$png_path" "$tmp_jpg"
  else
    # Fallback: use PNG directly
    cp "$png_path" "$tmp_jpg"
  fi

  local encoded
  encoded=$(base64_encode "$tmp_jpg")
  local size=${#encoded}
  CUMULATIVE_SIZE=$((CUMULATIVE_SIZE + size))
  rm -f "$tmp_jpg"

  echo "$encoded"
}

# ---------------------------------------------------------------------------
# Extract flow-state.json data
# ---------------------------------------------------------------------------
FLOW_INTENT=$(jq -r '.flow_intent // ""' "$FLOW_STATE")
FLOW_URL=$(jq -r '.url // ""' "$FLOW_STATE")
FLOW_MODE=$(jq -r '.mode // "intent"' "$FLOW_STATE")
FLOW_STATUS=$(jq -r '.status // "unknown"' "$FLOW_STATE")
STARTED_AT=$(jq -r '.started_at // ""' "$FLOW_STATE")
COMPLETED_AT=$(jq -r '.completed_at // ""' "$FLOW_STATE")

# Flow score (may not exist if reviews are incomplete)
HAS_FLOW_SCORE=$(jq 'has("flow_score")' "$FLOW_STATE")
if [[ "$HAS_FLOW_SCORE" == "true" ]]; then
  FLOW_WEIGHTED=$(jq -r '.flow_score.weighted_score // 0' "$FLOW_STATE")
  FLOW_DISPLAY=$(jq -r '.flow_score.display_score // 0' "$FLOW_STATE")
  FLOW_VERDICT=$(jq -r '.flow_score.verdict // "N/A"' "$FLOW_STATE")
  CONSISTENCY_PENALTY=$(jq -r '.flow_score.consistency_penalty // 0' "$FLOW_STATE")
  PRE_PENALTY_SCORE=$(jq -r '.flow_score.pre_penalty_score // 0' "$FLOW_STATE")
else
  FLOW_WEIGHTED="0"
  FLOW_DISPLAY="0"
  FLOW_VERDICT="N/A"
  CONSISTENCY_PENALTY="0"
  PRE_PENALTY_SCORE="0"
fi

TITLE="${FLOW_INTENT:-$FLOW_URL}"

# ---------------------------------------------------------------------------
# Process screenshots -- first pass at default quality
# ---------------------------------------------------------------------------
declare -a SCREEN_IMAGES=()
for i in $(seq 0 $((SCREEN_COUNT - 1))); do
  SCREENSHOT_PATH=$(jq -r ".screens[$i].screenshot_path // \"\"" "$FLOW_STATE")
  encoded=$(convert_screenshot "$SCREENSHOT_PATH" "$JPEG_QUALITY")
  SCREEN_IMAGES+=("$encoded")
done

# Re-compress at 60% if over budget
if [[ $CUMULATIVE_SIZE -gt $MAX_REPORT_SIZE ]]; then
  CUMULATIVE_SIZE=0
  SCREEN_IMAGES=()
  for i in $(seq 0 $((SCREEN_COUNT - 1))); do
    SCREENSHOT_PATH=$(jq -r ".screens[$i].screenshot_path // \"\"" "$FLOW_STATE")
    encoded=$(convert_screenshot "$SCREENSHOT_PATH" 60)
    SCREEN_IMAGES+=("$encoded")
  done
fi

# ---------------------------------------------------------------------------
# Build HTML -- helper functions
# ---------------------------------------------------------------------------

# Verdict color class
verdict_class() {
  case "$1" in
    SHIP) echo "verdict-ship" ;;
    CONDITIONAL) echo "verdict-conditional" ;;
    BLOCK) echo "verdict-block" ;;
    *) echo "verdict-na" ;;
  esac
}

# Score to bar percentage (internal 1.0-4.0 -> display /10 -> percentage)
score_bar_pct() {
  local internal="$1"
  # display = internal * 2.5, percentage = display * 10
  echo "$internal" | awk '{printf "%.0f", $1 * 25}'
}

# Score to display value
score_display() {
  local internal="$1"
  echo "$internal" | awk '{printf "%.1f", $1 * 2.5}'
}

# Score to color class
score_color_class() {
  local display
  display=$(echo "$1" | awk '{printf "%.1f", $1 * 2.5}')
  echo "$display" | awk '{if ($1 >= 7.5) print "score-good"; else if ($1 >= 5.0) print "score-ok"; else print "score-bad"}'
}

# ---------------------------------------------------------------------------
# Generate flow map HTML
# ---------------------------------------------------------------------------
generate_flow_map() {
  echo '<section id="flow-map" class="flow-map">'
  echo '  <h2>Flow Map</h2>'
  echo '  <div class="flow-strip">'
  for i in $(seq 0 $((SCREEN_COUNT - 1))); do
    local name
    name=$(jq -r ".screens[$i].name // \"Screen $((i+1))\"" "$FLOW_STATE")
    local num=$((i + 1))
    local slug
    slug=$(jq -r ".screens[$i].slug // \"screen-$num\"" "$FLOW_STATE")
    local weighted_score
    weighted_score=$(jq -r ".screens[$i].review.weighted_score // 0" "$FLOW_STATE")
    local display_val
    display_val=$(score_display "$weighted_score")
    local color_cls
    color_cls=$(score_color_class "$weighted_score")
    local has_review
    has_review=$(jq ".screens[$i] | has(\"review\")" "$FLOW_STATE")

    echo "    <a href=\"#screen-${num}\" class=\"flow-thumb\">"
    if [[ -n "${SCREEN_IMAGES[$i]:-}" ]]; then
      echo "      <img src=\"data:image/jpeg;base64,${SCREEN_IMAGES[$i]}\" alt=\"${name}\" class=\"thumb-img\" />"
    else
      echo "      <div class=\"thumb-placeholder\">No screenshot</div>"
    fi
    if [[ "$has_review" == "true" ]]; then
      echo "      <span class=\"thumb-badge ${color_cls}\">${display_val}</span>"
    fi
    echo "      <span class=\"thumb-label\">${num}. ${name}</span>"
    echo "    </a>"
    if [[ $i -lt $((SCREEN_COUNT - 1)) ]]; then
      echo '    <span class="flow-arrow">&#x2192;</span>'
    fi
  done
  echo '  </div>'
  echo '</section>'
}

# ---------------------------------------------------------------------------
# Generate summary section
# ---------------------------------------------------------------------------
generate_summary() {
  echo '<section id="summary" class="summary-section">'
  echo '  <h2>Flow Score Summary</h2>'

  if [[ "$HAS_FLOW_SCORE" != "true" ]]; then
    echo '  <p class="text-muted">Flow score not available (reviews may be incomplete).</p>'
    echo '</section>'
    return
  fi

  local pct
  pct=$(score_bar_pct "$FLOW_WEIGHTED")
  local display_val
  display_val=$(score_display "$FLOW_WEIGHTED")
  local v_cls
  v_cls=$(verdict_class "$FLOW_VERDICT")

  echo '  <div class="score-hero">'
  echo "    <div class=\"score-bar-track\"><div class=\"score-bar-fill ${v_cls}\" style=\"width:${pct}%\"></div></div>"
  echo "    <div class=\"score-value\">${display_val}/10</div>"
  echo "    <span class=\"verdict-badge ${v_cls}\">${FLOW_VERDICT}</span>"
  echo '  </div>'

  echo '  <div class="flow-meta">'
  echo "    <div class=\"meta-item\"><strong>Screens:</strong> ${SCREEN_COUNT}</div>"
  echo "    <div class=\"meta-item\"><strong>Mode:</strong> ${FLOW_MODE}</div>"
  if [[ -n "$FLOW_INTENT" ]]; then
    echo "    <div class=\"meta-item\"><strong>Intent:</strong> ${FLOW_INTENT}</div>"
  fi
  echo "    <div class=\"meta-item\"><strong>URL:</strong> ${FLOW_URL}</div>"
  if [[ -n "$STARTED_AT" ]]; then
    echo "    <div class=\"meta-item\"><strong>Started:</strong> ${STARTED_AT}</div>"
  fi
  if [[ -n "$COMPLETED_AT" ]]; then
    echo "    <div class=\"meta-item\"><strong>Completed:</strong> ${COMPLETED_AT}</div>"
  fi
  if [[ "$CONSISTENCY_PENALTY" != "0" ]]; then
    local pre_display
    pre_display=$(score_display "$PRE_PENALTY_SCORE")
    echo "    <div class=\"meta-item\"><strong>Pre-penalty score:</strong> ${pre_display}/10 (consistency penalty: -${CONSISTENCY_PENALTY})</div>"
  fi
  echo '  </div>'

  # Top 5 priority fixes -- gather all findings sorted by screen importance
  echo '  <div class="priority-fixes">'
  echo '    <h3>Top Priority Fixes</h3>'
  echo '    <ol class="fix-list">'

  # Collect findings across all screens with screen context
  local fix_count=0
  for i in $(seq 0 $((SCREEN_COUNT - 1))); do
    local findings_count
    findings_count=$(jq -r ".screens[$i].review.findings | length // 0" "$FLOW_STATE" 2>/dev/null)
    if [[ "$findings_count" -gt 0 ]]; then
      local sname
      sname=$(jq -r ".screens[$i].name // \"Screen $((i+1))\"" "$FLOW_STATE")
      for j in $(seq 0 $((findings_count - 1))); do
        if [[ $fix_count -ge 5 ]]; then break 2; fi
        local finding
        finding=$(jq -r ".screens[$i].review.findings[$j]" "$FLOW_STATE")
        echo "      <li><strong>${sname}:</strong> ${finding}</li>"
        fix_count=$((fix_count + 1))
      done
    fi
  done

  # Also pull cross-specialist findings
  for i in $(seq 0 $((SCREEN_COUNT - 1))); do
    if [[ $fix_count -ge 5 ]]; then break; fi
    local cross_count
    cross_count=$(jq -r ".screens[$i].review.cross_specialist_findings | length // 0" "$FLOW_STATE" 2>/dev/null)
    if [[ "$cross_count" -gt 0 ]]; then
      local sname
      sname=$(jq -r ".screens[$i].name // \"Screen $((i+1))\"" "$FLOW_STATE")
      for j in $(seq 0 $((cross_count - 1))); do
        if [[ $fix_count -ge 5 ]]; then break 2; fi
        local finding
        finding=$(jq -r ".screens[$i].review.cross_specialist_findings[$j]" "$FLOW_STATE")
        echo "      <li><strong>${sname}:</strong> ${finding}</li>"
        fix_count=$((fix_count + 1))
      done
    fi
  done

  if [[ $fix_count -eq 0 ]]; then
    echo '      <li class="text-muted">No issues found -- looking good!</li>'
  fi

  echo '    </ol>'
  echo '  </div>'

  # Consistency summary line
  local consistency_count
  consistency_count=$(jq '.consistency.findings | length // 0' "$FLOW_STATE" 2>/dev/null)
  if [[ "$consistency_count" -gt 0 ]]; then
    echo "  <p class=\"summary-line\">Consistency: ${consistency_count} cross-screen findings</p>"
  fi

  # Animation compliance line
  local prm_overall
  prm_overall=$(jq -r '.animation_summary.prefers_reduced_motion.overall // ""' "$FLOW_STATE" 2>/dev/null)
  if [[ -n "$prm_overall" ]]; then
    echo "  <p class=\"summary-line\">Animation (prefers-reduced-motion): ${prm_overall}</p>"
  fi

  echo '</section>'
}

# ---------------------------------------------------------------------------
# Generate per-screen sections
# ---------------------------------------------------------------------------
generate_screen_sections() {
  echo '<section id="screens">'

  for i in $(seq 0 $((SCREEN_COUNT - 1))); do
    local num=$((i + 1))
    local name
    name=$(jq -r ".screens[$i].name // \"Screen ${num}\"" "$FLOW_STATE")
    local url
    url=$(jq -r ".screens[$i].url // \"\"" "$FLOW_STATE")
    local review_mode
    review_mode=$(jq -r ".screens[$i].review.mode // \"\"" "$FLOW_STATE")
    local weighted_score
    weighted_score=$(jq -r ".screens[$i].review.weighted_score // 0" "$FLOW_STATE")
    local verdict
    verdict=$(jq -r ".screens[$i].review.verdict // \"N/A\"" "$FLOW_STATE")
    local has_review
    has_review=$(jq ".screens[$i] | has(\"review\")" "$FLOW_STATE")

    echo "  <div id=\"screen-${num}\" class=\"screen-section\">"
    echo "    <h2>${num}. ${name}</h2>"
    if [[ -n "$url" ]]; then
      echo "    <p class=\"screen-url\">${url}</p>"
    fi

    # Screenshot
    if [[ -n "${SCREEN_IMAGES[$i]:-}" ]]; then
      echo "    <div class=\"screenshot-container\">"
      echo "      <img src=\"data:image/jpeg;base64,${SCREEN_IMAGES[$i]}\" alt=\"Screenshot of ${name}\" class=\"screenshot\" />"
      echo "    </div>"
    else
      echo "    <div class=\"screenshot-placeholder\">Screenshot not available</div>"
    fi

    if [[ "$has_review" != "true" ]]; then
      echo "    <p class=\"text-muted\">Review data not available for this screen.</p>"
      echo "  </div>"
      continue
    fi

    # Overall screen score bar + verdict
    local pct
    pct=$(score_bar_pct "$weighted_score")
    local display_val
    display_val=$(score_display "$weighted_score")
    local v_cls
    v_cls=$(verdict_class "$verdict")

    echo '    <div class="screen-score-row">'
    echo "      <div class=\"score-bar-track\"><div class=\"score-bar-fill ${v_cls}\" style=\"width:${pct}%\"></div></div>"
    echo "      <span class=\"score-value\">${display_val}/10</span>"
    echo "      <span class=\"verdict-badge ${v_cls}\">${verdict}</span>"
    if [[ -n "$review_mode" ]]; then
      echo "      <span class=\"mode-badge\">${review_mode} review</span>"
    fi
    echo '    </div>'

    # Specialist score bars
    echo '    <div class="specialist-scores">'
    echo '      <h3>Specialist Scores</h3>'

    # Build list of specialist keys from the scores object
    local specialists
    specialists=$(jq -r ".screens[$i].review.scores | keys[]" "$FLOW_STATE" 2>/dev/null)
    for specialist in $specialists; do
      local sp_score
      sp_score=$(jq -r ".screens[$i].review.scores.${specialist} // 0" "$FLOW_STATE")
      local sp_pct
      sp_pct=$(score_bar_pct "$sp_score")
      local sp_display
      sp_display=$(score_display "$sp_score")
      local sp_color
      sp_color=$(score_color_class "$sp_score")
      local sp_label
      sp_label=$(echo "$specialist" | tr '_' ' ')

      echo "      <div class=\"specialist-bar\">"
      echo "        <span class=\"sp-label\">${sp_label}</span>"
      echo "        <div class=\"score-bar-track sp-track\"><div class=\"score-bar-fill ${sp_color}\" style=\"width:${sp_pct}%\"></div></div>"
      echo "        <span class=\"sp-value\">${sp_display}/10</span>"
      echo "      </div>"
    done
    echo '    </div>'

    # Specialist details (collapsed)
    echo '    <div class="specialist-details">'
    for specialist in $specialists; do
      local sp_score
      sp_score=$(jq -r ".screens[$i].review.scores.${specialist} // 0" "$FLOW_STATE")
      local sp_display
      sp_display=$(score_display "$sp_score")
      local sp_color
      sp_color=$(score_color_class "$sp_score")
      local sp_label
      sp_label=$(echo "$specialist" | tr '_' ' ')

      echo "      <details class=\"specialist-detail\">"
      echo "        <summary class=\"${sp_color}\"><span class=\"sp-label\">${sp_label}</span> <span class=\"sp-value\">${sp_display}/10</span></summary>"
      echo "        <div class=\"detail-content\">"

      # Pull specialist-specific findings if available (from findings array mentioning this specialist)
      # For now, list any findings that reference the specialist domain
      echo "          <p class=\"text-muted\">Specialist assessment for ${sp_label}.</p>"
      echo "        </div>"
      echo "      </details>"
    done
    echo '    </div>'

    # Screen findings / issues
    local findings_count
    findings_count=$(jq ".screens[$i].review.findings | length // 0" "$FLOW_STATE" 2>/dev/null)
    if [[ "$findings_count" -gt 0 ]]; then
      echo '    <div class="screen-issues">'
      echo '      <h3>Issues</h3>'
      echo '      <ul>'
      for j in $(seq 0 $((findings_count - 1))); do
        local finding
        finding=$(jq -r ".screens[$i].review.findings[$j]" "$FLOW_STATE")
        echo "        <li>${finding}</li>"
      done
      echo '      </ul>'
      echo '    </div>'
    fi

    # Cross-specialist findings
    local cross_count
    cross_count=$(jq ".screens[$i].review.cross_specialist_findings | length // 0" "$FLOW_STATE" 2>/dev/null)
    if [[ "$cross_count" -gt 0 ]]; then
      echo '    <div class="screen-issues">'
      echo '      <h3>Cross-Specialist Findings</h3>'
      echo '      <ul>'
      for j in $(seq 0 $((cross_count - 1))); do
        local finding
        finding=$(jq -r ".screens[$i].review.cross_specialist_findings[$j]" "$FLOW_STATE")
        echo "        <li>${finding}</li>"
      done
      echo '      </ul>'
      echo '    </div>'
    fi

    echo "  </div>"
  done

  echo '</section>'
}

# ---------------------------------------------------------------------------
# Generate consistency section
# ---------------------------------------------------------------------------
generate_consistency() {
  local count
  count=$(jq '.consistency.findings | length // 0' "$FLOW_STATE" 2>/dev/null)
  if [[ "$count" -lt 1 ]]; then
    return
  fi

  echo '<section id="consistency" class="consistency-section">'
  echo '  <h2>Cross-Screen Consistency</h2>'

  local total
  total=$(jq -r '.consistency.summary.total_findings // 0' "$FLOW_STATE")
  local penalty_pts
  penalty_pts=$(jq -r '.consistency.summary.penalty_points // 0' "$FLOW_STATE")
  local score_adj
  score_adj=$(jq -r '.consistency.summary.score_adjustment // 0' "$FLOW_STATE")

  echo "  <p class=\"consistency-meta\">${total} findings | Penalty points: ${penalty_pts} | Score adjustment: ${score_adj}</p>"

  for j in $(seq 0 $((count - 1))); do
    local check
    check=$(jq -r ".consistency.findings[$j].check // \"\"" "$FLOW_STATE")
    local severity
    severity=$(jq -r ".consistency.findings[$j].severity // \"warning\"" "$FLOW_STATE")
    local description
    description=$(jq -r ".consistency.findings[$j].description // \"\"" "$FLOW_STATE")
    local affected
    affected=$(jq -r ".consistency.findings[$j].screens_affected // \"\"" "$FLOW_STATE")
    local reference
    reference=$(jq -r ".consistency.findings[$j].screens_reference // \"\"" "$FLOW_STATE")

    local sev_cls="severity-warning"
    case "$severity" in
      critical|conflict) sev_cls="severity-critical" ;;
      mismatch|issue) sev_cls="severity-issue" ;;
      drift|warning) sev_cls="severity-warning" ;;
    esac

    echo "    <div class=\"consistency-card ${sev_cls}\">"
    echo "      <div class=\"card-header\">"
    echo "        <span class=\"check-name\">${check}</span>"
    echo "        <span class=\"severity-tag ${sev_cls}\">${severity}</span>"
    echo "      </div>"
    echo "      <p>${description}</p>"
    if [[ -n "$affected" && "$affected" != "null" ]]; then
      echo "      <p class=\"text-muted\">Affected: ${affected} | Reference: ${reference}</p>"
    fi
    echo "    </div>"
  done

  echo '</section>'
}

# ---------------------------------------------------------------------------
# Generate animation section
# ---------------------------------------------------------------------------
generate_animation() {
  local has_anim
  has_anim=$(jq 'has("animation_summary")' "$FLOW_STATE")
  if [[ "$has_anim" != "true" ]]; then
    return
  fi

  echo '<section id="animation" class="animation-section">'
  echo '  <h2>Animation Summary</h2>'

  local total_transitions
  total_transitions=$(jq -r '.animation_summary.total_transitions_detected // 0' "$FLOW_STATE")
  local total_events
  total_events=$(jq -r '.animation_summary.total_animation_events // 0' "$FLOW_STATE")
  local prm_overall
  prm_overall=$(jq -r '.animation_summary.prefers_reduced_motion.overall // "N/A"' "$FLOW_STATE")

  local prm_cls="prm-pass"
  case "$prm_overall" in
    PASS) prm_cls="prm-pass" ;;
    PARTIAL) prm_cls="prm-partial" ;;
    FAIL) prm_cls="prm-fail" ;;
  esac

  echo "  <div class=\"anim-meta\">"
  echo "    <span class=\"prm-badge ${prm_cls}\">prefers-reduced-motion: ${prm_overall}</span>"
  echo "    <span class=\"meta-item\">Transitions: ${total_transitions}</span>"
  echo "    <span class=\"meta-item\">Animation events: ${total_events}</span>"
  echo "  </div>"

  # Findings
  local findings_count
  findings_count=$(jq '.animation_summary.findings | length // 0' "$FLOW_STATE" 2>/dev/null)
  if [[ "$findings_count" -gt 0 ]]; then
    echo '  <ul class="anim-findings">'
    for j in $(seq 0 $((findings_count - 1))); do
      local finding
      finding=$(jq -r ".animation_summary.findings[$j]" "$FLOW_STATE")
      echo "    <li>${finding}</li>"
    done
    echo '  </ul>'
  fi

  # Duration findings
  local dur_count
  dur_count=$(jq '.animation_summary.duration_findings | length // 0' "$FLOW_STATE" 2>/dev/null)
  if [[ "$dur_count" -gt 0 ]]; then
    echo '  <h3>Duration Quality</h3>'
    echo '  <ul>'
    for j in $(seq 0 $((dur_count - 1))); do
      local finding
      finding=$(jq -r ".animation_summary.duration_findings[$j]" "$FLOW_STATE")
      echo "    <li>${finding}</li>"
    done
    echo '  </ul>'
  fi

  # Easing findings
  local ease_count
  ease_count=$(jq '.animation_summary.easing_findings | length // 0' "$FLOW_STATE" 2>/dev/null)
  if [[ "$ease_count" -gt 0 ]]; then
    echo '  <h3>Easing Quality</h3>'
    echo '  <ul>'
    for j in $(seq 0 $((ease_count - 1))); do
      local finding
      finding=$(jq -r ".animation_summary.easing_findings[$j]" "$FLOW_STATE")
      echo "    <li>${finding}</li>"
    done
    echo '  </ul>'
  fi

  echo '</section>'
}

# ---------------------------------------------------------------------------
# Assemble the full HTML document
# ---------------------------------------------------------------------------
{
cat <<'HTML_HEAD'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
HTML_HEAD

echo "  <title>SpSk Flow Audit -- ${TITLE}</title>"

cat <<'STYLE_BLOCK'
  <style>
    :root {
      --bg: #18181b;
      --surface: #27272a;
      --border: #3f3f46;
      --text: #e4e4e7;
      --text-muted: #a1a1aa;
      --accent: #3b82f6;
      --good: #22c55e;
      --ok: #eab308;
      --bad: #ef4444;
      --radius: 8px;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      max-width: 1200px;
      margin: 0 auto;
      padding: 24px 16px;
    }

    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }

    h2 {
      font-size: 1.25rem;
      margin-bottom: 16px;
      color: var(--text);
      border-bottom: 1px solid var(--border);
      padding-bottom: 8px;
    }

    h3 {
      font-size: 1rem;
      margin: 16px 0 8px;
      color: var(--text-muted);
    }

    /* -- Header -- */
    .report-header {
      text-align: center;
      padding: 32px 0 24px;
      border-bottom: 1px solid var(--border);
      margin-bottom: 32px;
    }
    .signature {
      font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
      font-size: 0.875rem;
      color: var(--text-muted);
      letter-spacing: 0.05em;
    }
    .report-title {
      font-size: 1.5rem;
      margin-top: 12px;
      color: var(--text);
    }

    /* -- Flow Map -- */
    .flow-map {
      margin-bottom: 32px;
      overflow-x: auto;
      padding-bottom: 8px;
    }
    .flow-strip {
      display: flex;
      align-items: center;
      gap: 8px;
      min-width: min-content;
      padding: 16px 0;
    }
    .flow-thumb {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-decoration: none;
      width: 120px;
      flex-shrink: 0;
      position: relative;
    }
    .thumb-img {
      width: 120px;
      height: 75px;
      object-fit: cover;
      border-radius: var(--radius);
      border: 1px solid var(--border);
    }
    .thumb-placeholder {
      width: 120px;
      height: 75px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 0.625rem;
      color: var(--text-muted);
    }
    .thumb-badge {
      position: absolute;
      top: -8px;
      right: -4px;
      font-size: 0.6875rem;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 4px;
      color: var(--bg);
    }
    .thumb-badge.score-good { background: var(--good); }
    .thumb-badge.score-ok { background: var(--ok); }
    .thumb-badge.score-bad { background: var(--bad); }
    .thumb-label {
      font-size: 0.75rem;
      margin-top: 6px;
      text-align: center;
      color: var(--text-muted);
      max-width: 120px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .flow-arrow {
      color: var(--text-muted);
      font-size: 1.25rem;
      flex-shrink: 0;
    }

    /* -- Score components -- */
    .score-bar-track {
      height: 12px;
      background: var(--border);
      border-radius: 6px;
      overflow: hidden;
      flex: 1;
    }
    .score-bar-fill {
      height: 100%;
      border-radius: 6px;
      transition: width 0.3s ease;
    }
    .score-bar-fill.verdict-ship, .score-bar-fill.score-good { background: var(--good); }
    .score-bar-fill.verdict-conditional, .score-bar-fill.score-ok { background: var(--ok); }
    .score-bar-fill.verdict-block, .score-bar-fill.score-bad { background: var(--bad); }
    .score-bar-fill.verdict-na { background: var(--text-muted); }

    .score-value {
      font-weight: 700;
      font-size: 1.125rem;
      min-width: 60px;
      text-align: right;
    }

    .verdict-badge {
      font-size: 0.75rem;
      font-weight: 700;
      padding: 2px 10px;
      border-radius: 4px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .verdict-badge.verdict-ship { background: var(--good); color: var(--bg); }
    .verdict-badge.verdict-conditional { background: var(--ok); color: var(--bg); }
    .verdict-badge.verdict-block { background: var(--bad); color: #fff; }
    .verdict-badge.verdict-na { background: var(--border); color: var(--text-muted); }

    .mode-badge {
      font-size: 0.6875rem;
      padding: 2px 8px;
      border-radius: 4px;
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text-muted);
    }

    /* -- Summary section -- */
    .summary-section {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
      margin-bottom: 32px;
    }
    .score-hero {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 20px;
    }
    .flow-meta {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 8px;
      margin-bottom: 20px;
      font-size: 0.875rem;
    }
    .meta-item { color: var(--text-muted); }
    .meta-item strong { color: var(--text); }

    .priority-fixes {
      border-top: 1px solid var(--border);
      padding-top: 16px;
    }
    .fix-list {
      padding-left: 24px;
      font-size: 0.875rem;
    }
    .fix-list li {
      margin-bottom: 8px;
      color: var(--text);
    }
    .fix-list li strong { color: var(--accent); }

    .summary-line {
      font-size: 0.875rem;
      color: var(--text-muted);
      margin-top: 8px;
    }

    /* -- Screen sections -- */
    .screen-section {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
      margin-bottom: 24px;
    }
    .screen-url {
      font-size: 0.8125rem;
      color: var(--text-muted);
      margin-bottom: 16px;
      word-break: break-all;
    }
    .screenshot-container {
      margin-bottom: 20px;
      border-radius: var(--radius);
      overflow: hidden;
      border: 1px solid var(--border);
    }
    .screenshot {
      width: 100%;
      height: auto;
      display: block;
    }
    .screenshot-placeholder {
      width: 100%;
      height: 200px;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-muted);
      font-size: 0.875rem;
      margin-bottom: 20px;
    }
    .screen-score-row {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 20px;
    }

    /* -- Specialist scores -- */
    .specialist-scores { margin-bottom: 16px; }
    .specialist-bar {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 6px;
      font-size: 0.8125rem;
    }
    .sp-label {
      width: 120px;
      text-transform: capitalize;
      color: var(--text-muted);
      flex-shrink: 0;
    }
    .sp-track { max-width: 300px; }
    .sp-value {
      min-width: 50px;
      text-align: right;
      font-weight: 600;
      font-size: 0.8125rem;
    }

    /* -- Specialist details (collapsed) -- */
    .specialist-details { margin-bottom: 16px; }
    .specialist-detail {
      border: 1px solid var(--border);
      border-radius: var(--radius);
      margin-bottom: 4px;
    }
    .specialist-detail summary {
      padding: 8px 12px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 0.8125rem;
      background: var(--bg);
      border-radius: var(--radius);
    }
    .specialist-detail summary:hover { background: var(--border); }
    .specialist-detail[open] summary { border-radius: var(--radius) var(--radius) 0 0; }
    .specialist-detail .detail-content {
      padding: 12px;
      font-size: 0.8125rem;
      border-top: 1px solid var(--border);
    }

    summary .sp-label { width: auto; }
    summary.score-good .sp-value { color: var(--good); }
    summary.score-ok .sp-value { color: var(--ok); }
    summary.score-bad .sp-value { color: var(--bad); }

    /* -- Issues -- */
    .screen-issues { margin-bottom: 12px; }
    .screen-issues ul {
      padding-left: 20px;
      font-size: 0.8125rem;
    }
    .screen-issues li {
      margin-bottom: 4px;
      color: var(--text);
    }

    /* -- Consistency section -- */
    .consistency-section {
      margin-bottom: 32px;
    }
    .consistency-meta {
      font-size: 0.875rem;
      color: var(--text-muted);
      margin-bottom: 16px;
    }
    .consistency-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 16px;
      margin-bottom: 12px;
      border-left: 4px solid var(--border);
    }
    .consistency-card.severity-critical { border-left-color: var(--bad); }
    .consistency-card.severity-issue { border-left-color: var(--ok); }
    .consistency-card.severity-warning { border-left-color: var(--accent); }
    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .check-name {
      font-weight: 600;
      text-transform: capitalize;
    }
    .severity-tag {
      font-size: 0.6875rem;
      padding: 2px 8px;
      border-radius: 4px;
      font-weight: 600;
      text-transform: uppercase;
    }
    .severity-tag.severity-critical { background: var(--bad); color: #fff; }
    .severity-tag.severity-issue { background: var(--ok); color: var(--bg); }
    .severity-tag.severity-warning { background: var(--accent); color: #fff; }
    .consistency-card p { font-size: 0.875rem; }

    /* -- Animation section -- */
    .animation-section { margin-bottom: 32px; }
    .anim-meta {
      display: flex;
      gap: 16px;
      align-items: center;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }
    .prm-badge {
      font-size: 0.75rem;
      font-weight: 700;
      padding: 4px 12px;
      border-radius: 4px;
    }
    .prm-badge.prm-pass { background: var(--good); color: var(--bg); }
    .prm-badge.prm-partial { background: var(--ok); color: var(--bg); }
    .prm-badge.prm-fail { background: var(--bad); color: #fff; }
    .anim-findings {
      padding-left: 20px;
      font-size: 0.875rem;
    }
    .anim-findings li { margin-bottom: 4px; }

    /* -- Footer -- */
    .report-footer {
      text-align: center;
      padding: 24px 0;
      border-top: 1px solid var(--border);
      margin-top: 32px;
      font-size: 0.8125rem;
      color: var(--text-muted);
    }
    .report-footer a { color: var(--text-muted); }

    /* -- Expand/Collapse controls -- */
    .controls {
      display: flex;
      justify-content: flex-end;
      margin-bottom: 12px;
    }
    .controls button {
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 6px 14px;
      border-radius: var(--radius);
      cursor: pointer;
      font-size: 0.8125rem;
    }
    .controls button:hover {
      background: var(--border);
      color: var(--text);
    }

    .text-muted { color: var(--text-muted); }

    /* -- Responsive -- */
    @media (max-width: 768px) {
      body { padding: 12px 8px; }
      .score-hero { flex-direction: column; align-items: flex-start; }
      .flow-meta { grid-template-columns: 1fr; }
      .screen-score-row { flex-wrap: wrap; }
      .specialist-bar { flex-wrap: wrap; }
      .sp-label { width: 100%; }
      .sp-track { max-width: 100%; }
      .anim-meta { flex-direction: column; align-items: flex-start; }
    }

    /* -- Print styles -- */
    @media print {
      :root {
        --bg: #ffffff;
        --surface: #f9fafb;
        --border: #d1d5db;
        --text: #111827;
        --text-muted: #6b7280;
      }
      body {
        background: white;
        color: black;
        max-width: 100%;
        padding: 0;
      }
      details { display: block !important; }
      details > summary { display: none !important; }
      details .detail-content { display: block !important; border-top: none; }
      .flow-map { page-break-after: always; }
      .screen-section { page-break-inside: avoid; }
      .no-print { display: none !important; }
      .controls { display: none !important; }
      .flow-thumb { width: 90px; }
      .thumb-img { width: 90px; height: 56px; }
      .score-bar-fill.verdict-ship, .score-bar-fill.score-good { background: #16a34a !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .score-bar-fill.verdict-conditional, .score-bar-fill.score-ok { background: #ca8a04 !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .score-bar-fill.verdict-block, .score-bar-fill.score-bad { background: #dc2626 !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .score-bar-track { background: #e5e7eb !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .verdict-badge { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
STYLE_BLOCK

# Header
echo '  <header class="report-header">'
echo '    <div class="signature">SpSk  design-audit  v1.1.0  &#x2500;&#x2500;&#x2500;  flow diagnostic report</div>'
echo "    <h1 class=\"report-title\">Flow Audit: ${TITLE}</h1>"
echo '  </header>'

# Expand/Collapse controls
echo '  <div class="controls no-print">'
echo '    <button id="toggle-all" onclick="toggleAll()">Expand all details</button>'
echo '  </div>'

# Flow map
generate_flow_map

# Summary
generate_summary

# Per-screen sections
generate_screen_sections

# Consistency
generate_consistency

# Animation
generate_animation

# Footer
echo '  <footer class="report-footer">'
echo '    <a href="https://github.com/spsk-dev/tasteful-design">github.com/spsk-dev/tasteful-design</a>'
echo '  </footer>'

# Inline JavaScript (minimal)
cat <<'JS_BLOCK'
  <script>
    // Smooth scroll for flow map
    document.querySelectorAll('.flow-thumb').forEach(function(thumb) {
      thumb.addEventListener('click', function(e) {
        e.preventDefault();
        var target = document.querySelector(this.getAttribute('href'));
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });

    // Expand all / Collapse all toggle
    var allExpanded = false;
    function toggleAll() {
      allExpanded = !allExpanded;
      document.querySelectorAll('details.specialist-detail').forEach(function(d) {
        d.open = allExpanded;
      });
      document.getElementById('toggle-all').textContent =
        allExpanded ? 'Collapse all details' : 'Expand all details';
    }
  </script>
JS_BLOCK

echo '</body>'
echo '</html>'

} > "$OUTPUT_HTML"

# ---------------------------------------------------------------------------
# Report result
# ---------------------------------------------------------------------------
FILE_SIZE=$(wc -c < "$OUTPUT_HTML" | tr -d ' ')
FILE_SIZE_KB=$((FILE_SIZE / 1024))

echo ""
echo "SpSk  generate-report  v1.1.0"
echo "Report generated: ${OUTPUT_HTML}"
echo "Size: ${FILE_SIZE_KB}KB (${SCREEN_COUNT} screens)"
echo ""

if [[ $FILE_SIZE -gt 5242880 ]]; then
  echo "WARNING: Report exceeds 5MB (${FILE_SIZE_KB}KB). Consider reducing screenshot quality." >&2
fi
