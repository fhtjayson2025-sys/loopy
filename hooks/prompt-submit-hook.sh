#!/bin/bash
# UserPromptSubmit Hook for Loopy
# Detects natural language intent to start/cancel loopy loops
# Requests clarification if params are incomplete
#
# Input: JSON { prompt: string, ... }
# Output: JSON { result: "continue", message?: string, needs_clarification?: bool }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLASSIFIER="$SCRIPT_DIR/../scripts/intent-classifier.sh"
EXTRACTOR="$SCRIPT_DIR/../scripts/param-extractor.sh"
STATE_FILE=".claude/loopy-loop.local.md"

# Read hook input
HOOK_INPUT=$(cat)

# Extract user prompt
PROMPT=$(echo "$HOOK_INPUT" | jq -r '.prompt // ""')

if [[ -z "$PROMPT" ]]; then
  # No prompt, pass through
  jq -n '{ result: "continue" }'
  exit 0
fi

# Classify intent
INTENT_RESULT=$(echo "$PROMPT" | "$CLASSIFIER")
INTENT=$(echo "$INTENT_RESULT" | jq -r '.intent')

case "$INTENT" in
  start_loopy)
    # Extract parameters
    PARAMS=$(echo "$PROMPT" | "$EXTRACTOR")
    TASK=$(echo "$PARAMS" | jq -r '.task')
    PROMISE=$(echo "$PARAMS" | jq -r '.completion_promise // "null"')
    MAX_ITER=$(echo "$PARAMS" | jq -r '.max_iterations // 0')

    # Check if we have sufficient params (either max_iterations > 0 OR completion_promise set)
    if [[ "$MAX_ITER" -eq 0 ]] && [[ "$PROMISE" == "null" ]]; then
      # Need clarification - output message for Claude to ask questions
      CLARIFY_MSG="Starting Loopy - I need a bit more info first!

You want to: $TASK

Please use AskUserQuestion to ask the user:

1. How many iterations? (Options: 10, 25, 50, Unlimited)
2. What is the end goal? (When should the loop stop? e.g. tests pass, build complete, no errors)

Once you have answers, create the state file to start the loop."

      jq -n \
        --arg msg "$CLARIFY_MSG" \
        --arg task "$TASK" \
        '{result: "continue", message: $msg, needs_clarification: true, task: $task}'
      exit 0
    fi

    # Params complete - create state file
    mkdir -p .claude

    # Format completion promise for YAML
    if [[ "$PROMISE" != "null" ]]; then
      PROMISE_YAML="\"$PROMISE\""
    else
      PROMISE_YAML="null"
    fi

    cat > "$STATE_FILE" <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITER
completion_promise: $PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$TASK
EOF

    # Build visual banner
    if [[ $MAX_ITER -gt 0 ]]; then
      ITER_DISPLAY="1/$MAX_ITER"
    else
      ITER_DISPLAY="1 (unlimited)"
    fi

    if [[ "$PROMISE" != "null" ]]; then
      EXIT_DISPLAY="<promise>$PROMISE</promise>"
    else
      EXIT_DISPLAY="No completion promise (will use max iterations)"
    fi

    BANNER=$(cat <<EOF
╔══════════════════════════════════════════════════════════════╗
║  🔄 LOOPY ACTIVE                                             ║
╠══════════════════════════════════════════════════════════════╣
║  Task: $TASK
║  Iteration: $ITER_DISPLAY
║  Exit: $EXIT_DISPLAY
╚══════════════════════════════════════════════════════════════╝

The Stop hook will intercept your exit and re-feed the same task.
To cancel manually: say "stop loopy" or "cancel loopy"
EOF
)

    jq -n \
      --arg msg "$BANNER" \
      '{ result: "continue", message: $msg }'
    ;;

  cancel_loopy)
    if [[ -f "$STATE_FILE" ]]; then
      # Read current iteration
      ITERATION=$(grep '^iteration:' "$STATE_FILE" | sed 's/iteration: *//' || echo "unknown")
      rm -f "$STATE_FILE"

      MESSAGE="🛑 Loopy cancelled at iteration $ITERATION"
    else
      MESSAGE="ℹ️  No active Loopy to cancel"
    fi

    jq -n \
      --arg msg "$MESSAGE" \
      '{ result: "continue", message: $msg }'
    ;;

  none|*)
    # Not a loopy command, pass through
    jq -n '{ result: "continue" }'
    ;;
esac
