#!/bin/bash
# Parameter Extractor for Loopy
# Extracts task, completion promise, and max iterations from natural language
#
# Input: User text via stdin
# Output: JSON { task: string, completion_promise: string|null, max_iterations: number }

set -euo pipefail

# Read input text
TEXT=$(cat)
TEXT_LOWER=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]')

# Defaults
TASK=""
COMPLETION_PROMISE="null"
MAX_ITERATIONS=0

# Extract max iterations first (so we can remove it from text)
# Patterns: "max N iterations", "N iterations", "for N iterations"
if [[ "$TEXT_LOWER" =~ max[[:space:]]+([0-9]+)[[:space:]]+iterations ]]; then
  MAX_ITERATIONS="${BASH_REMATCH[1]}"
elif [[ "$TEXT_LOWER" =~ for[[:space:]]+([0-9]+)[[:space:]]+iterations ]]; then
  MAX_ITERATIONS="${BASH_REMATCH[1]}"
elif [[ "$TEXT_LOWER" =~ ([0-9]+)[[:space:]]+iterations ]]; then
  MAX_ITERATIONS="${BASH_REMATCH[1]}"
fi

# Extract completion promise (until/when [condition])
# Remove iterations clause first for cleaner extraction
CLEAN_TEXT="$TEXT_LOWER"
CLEAN_TEXT=$(echo "$CLEAN_TEXT" | sed -E 's/max[[:space:]]+[0-9]+[[:space:]]+iterations//g')
CLEAN_TEXT=$(echo "$CLEAN_TEXT" | sed -E 's/for[[:space:]]+[0-9]+[[:space:]]+iterations//g')
CLEAN_TEXT=$(echo "$CLEAN_TEXT" | sed -E 's/[0-9]+[[:space:]]+iterations//g')

if [[ "$CLEAN_TEXT" =~ until[[:space:]]+(.+)$ ]]; then
  COMPLETION_PROMISE="${BASH_REMATCH[1]}"
  # Trim whitespace
  COMPLETION_PROMISE=$(echo "$COMPLETION_PROMISE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
elif [[ "$CLEAN_TEXT" =~ when[[:space:]]+(.+)$ ]]; then
  COMPLETION_PROMISE="${BASH_REMATCH[1]}"
  COMPLETION_PROMISE=$(echo "$COMPLETION_PROMISE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# Extract task - patterns (use original case TEXT for extraction):
# "start a loopy to [task]"
# "begin loopy to [task]"
# "run loopy on [task]"
# "loopy on [task]"
# "let's loopy on [task]"

# Clean original text (preserve case) by removing iterations
TASK_TEXT_ORIG="$TEXT"
TASK_TEXT_ORIG=$(echo "$TASK_TEXT_ORIG" | sed -E 's/[Mm]ax[[:space:]]+[0-9]+[[:space:]]+[Ii]terations//g')
TASK_TEXT_ORIG=$(echo "$TASK_TEXT_ORIG" | sed -E 's/[Ff]or[[:space:]]+[0-9]+[[:space:]]+[Ii]terations//g')
TASK_TEXT_ORIG=$(echo "$TASK_TEXT_ORIG" | sed -E 's/[0-9]+[[:space:]]+[Ii]terations//g')

# Remove completion promise clause for task extraction
if [[ -n "$COMPLETION_PROMISE" && "$COMPLETION_PROMISE" != "null" ]]; then
  TASK_TEXT_ORIG=$(echo "$TASK_TEXT_ORIG" | sed -E 's/[Uu]ntil[[:space:]]+.*$//')
  TASK_TEXT_ORIG=$(echo "$TASK_TEXT_ORIG" | sed -E 's/[Ww]hen[[:space:]]+.*$//')
fi

# Use case-insensitive matching but extract from original text
TASK_TEXT_LOWER=$(echo "$TASK_TEXT_ORIG" | tr '[:upper:]' '[:lower:]')

# Extract task based on pattern (find position in lowercase, extract from original)
# "start a loopy to [task]", "start loopy to [task]", "begin loopy to [task]"
if [[ "$TASK_TEXT_LOWER" =~ (start|begin)[[:space:]]+(a[[:space:]]+)?loopy[[:space:]]+to[[:space:]]+ ]]; then
  PREFIX_LEN=${#BASH_REMATCH[0]}
  TASK="${TASK_TEXT_ORIG:$PREFIX_LEN}"
# "run loopy on [task]"
elif [[ "$TASK_TEXT_LOWER" =~ run[[:space:]]+loopy[[:space:]]+on[[:space:]]+ ]]; then
  PREFIX_LEN=${#BASH_REMATCH[0]}
  TASK="${TASK_TEXT_ORIG:$PREFIX_LEN}"
# "loopy on [task]"
elif [[ "$TASK_TEXT_LOWER" =~ ^loopy[[:space:]]+on[[:space:]]+ ]]; then
  PREFIX_LEN=${#BASH_REMATCH[0]}
  TASK="${TASK_TEXT_ORIG:$PREFIX_LEN}"
# "let's loopy on [task]"
elif [[ "$TASK_TEXT_LOWER" =~ let\'?s[[:space:]]+loopy[[:space:]]+on[[:space:]]+ ]]; then
  PREFIX_LEN=${#BASH_REMATCH[0]}
  TASK="${TASK_TEXT_ORIG:$PREFIX_LEN}"
fi

# Trim whitespace from task
TASK=$(echo "$TASK" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Quote completion_promise for JSON if not null
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_JSON="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_JSON="null"
fi

# Output JSON
jq -n \
  --arg task "$TASK" \
  --argjson promise "$COMPLETION_PROMISE_JSON" \
  --argjson max "$MAX_ITERATIONS" \
  '{ task: $task, completion_promise: $promise, max_iterations: $max }'
