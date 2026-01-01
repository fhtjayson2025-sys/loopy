#!/bin/bash

# Loopy Setup Script
# Creates state file for in-session Loopy loop

set -eo pipefail

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Loopy - Natural language iterative development loops

USAGE:
  /loopy [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop

OPTIONS:
  --max-iterations <n>           Maximum iterations (default: ask user)
  --completion-promise '<text>'  Promise phrase for completion
  -h, --help                     Show this help message

EXAMPLES:
  /loopy Build a todo API --completion-promise 'DONE' --max-iterations 20
  /loopy --max-iterations 10 Fix the auth bug
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires text" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join prompt parts (handle empty array safely)
if [[ ${#PROMPT_PARTS[@]} -gt 0 ]]; then
  PROMPT="${PROMPT_PARTS[*]}"
else
  PROMPT=""
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
