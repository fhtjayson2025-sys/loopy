#!/bin/bash

# Loopy Setup Script
# Creates state file for in-session Loopy loop

set -eo pipefail

# Read prompt from stdin (heredoc-safe, avoids shell quoting issues)
PROMPT=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

# Read from stdin
if [[ ! -t 0 ]]; then
  PROMPT=$(cat)
fi

# Parse options from the prompt text (--max-iterations N, --completion-promise 'TEXT')
if [[ -n "$PROMPT" ]]; then
  # Extract --max-iterations
  if [[ "$PROMPT" =~ --max-iterations[[:space:]]+([0-9]+) ]]; then
    MAX_ITERATIONS="${BASH_REMATCH[1]}"
    PROMPT="${PROMPT/--max-iterations ${BASH_REMATCH[1]}/}"
  fi

  # Extract --completion-promise (single or double quoted)
  if [[ "$PROMPT" =~ --completion-promise[[:space:]]+[\'\"]([^\'\"]+)[\'\"] ]]; then
    COMPLETION_PROMISE="${BASH_REMATCH[1]}"
    PROMPT="${PROMPT/--completion-promise [\'\"]*[\'\"]/}"
  elif [[ "$PROMPT" =~ --completion-promise[[:space:]]+([^[:space:]]+) ]]; then
    COMPLETION_PROMISE="${BASH_REMATCH[1]}"
    PROMPT="${PROMPT/--completion-promise ${BASH_REMATCH[1]}/}"
  fi

  # Trim whitespace
  PROMPT=$(echo "$PROMPT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# If no prompt, tell Claude to ask
if [[ -z "$PROMPT" ]]; then
  echo "NEEDS_INPUT=true"
  echo ""
  echo "No task provided. Use AskUserQuestion to ask:"
  echo "- What task should the loop work on?"
  echo "- How many iterations maximum?"
  echo "- What signals completion?"
  exit 0
fi

# If missing stop conditions, tell Claude to ask
if [[ "$MAX_ITERATIONS" -eq 0 ]] && [[ "$COMPLETION_PROMISE" == "null" ]]; then
  echo "NEEDS_CLARIFICATION=true"
  echo "TASK=$PROMPT"
  echo ""
  echo "Task received but missing stop conditions."
  echo "Use AskUserQuestion to ask:"
  echo "- How many iterations maximum? (e.g., 10, 20, 50)"
  echo "- What signals completion? (e.g., tests pass, build succeeds)"
  exit 0
fi

# Create state file for stop hook
mkdir -p .claude

# Quote completion promise for YAML
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

cat > .claude/loopy-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

# Output setup message
MAX_DISPLAY=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
STOP_DISPLAY=$(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/}"; else echo "max iterations"; fi)

cat <<EOF
+-------------------------------------+
|  LOOPY LOOP ACTIVE                  |
+-------------------------------------+
Task: $PROMPT
Iteration: 1/$MAX_DISPLAY
Stop when: $STOP_DISPLAY
+-------------------------------------+

$PROMPT
EOF
