#!/bin/bash
# Intent Classifier for Loopy
# Detects natural language intent to start/stop loopy loops
#
# Input: User text via stdin
# Output: JSON { intent: "start_loopy"|"cancel_loopy"|"none", text: "original" }

set -euo pipefail

# Read input text
TEXT=$(cat)
TEXT_LOWER=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]')

# Default intent
INTENT="none"

# Start loopy patterns
# "start a loopy", "start loopy", "begin loopy", "run loopy"
if [[ "$TEXT_LOWER" =~ (start|begin|run)[[:space:]]+(a[[:space:]]+)?loopy ]]; then
  INTENT="start_loopy"
# "loopy on [task]"
elif [[ "$TEXT_LOWER" =~ loopy[[:space:]]+on ]]; then
  INTENT="start_loopy"
# "let's loopy"
elif [[ "$TEXT_LOWER" =~ let\'?s[[:space:]]+loopy ]]; then
  INTENT="start_loopy"
fi

# Cancel loopy patterns
if [[ "$TEXT_LOWER" =~ (stop|cancel|exit)[[:space:]]+(the[[:space:]]+)?loopy ]]; then
  INTENT="cancel_loopy"
fi

# Output JSON
jq -n \
  --arg intent "$INTENT" \
  --arg text "$TEXT" \
  '{ intent: $intent, text: $text }'
