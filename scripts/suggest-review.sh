#!/bin/bash
# PostToolUse hook — suggests /design-review after frontend file edits
# Non-blocking: just adds a system message suggestion, doesn't auto-trigger

# Read the tool input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // ""' 2>/dev/null)

# Extract session_id for stable counter scoping (falls back to date-based key)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -z "$SESSION_ID" ]; then
  SESSION_ID="design-review-$(date +%Y%m%d)"
fi

# Check if the file is a frontend file worth reviewing
if echo "$FILE_PATH" | grep -qE '\.(tsx|jsx|svelte|html|css|scss|vue)$'; then
  # Count how many frontend files have been edited in this session
  # Only suggest after 3+ frontend file edits to avoid noise
  STATE_FILE="/tmp/design-review-edit-count-${SESSION_ID}"
  COUNT=0
  if [ -f "$STATE_FILE" ]; then
    COUNT=$(cat "$STATE_FILE")
  fi
  COUNT=$((COUNT + 1))
  echo "$COUNT" > "$STATE_FILE"

  if [ "$COUNT" -eq 3 ]; then
    echo '{"message": "You have edited 3+ frontend files. Consider running /design-review to check visual quality before shipping."}'
  fi
fi
