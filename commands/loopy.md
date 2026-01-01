---
description: "Start a Loopy iterative development loop"
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-loopy.sh)"]
hide-from-slash-command-tool: "true"
---

# Loopy Command

Execute the setup script to initialize the Loopy loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-loopy.sh" $ARGUMENTS

# Extract and display completion promise if set
if [ -f .claude/loopy-loop.local.md ]; then
  PROMISE=$(grep '^completion_promise:' .claude/loopy-loop.local.md | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
  if [ -n "$PROMISE" ] && [ "$PROMISE" != "null" ]; then
    echo ""
    echo "To complete this loop, output: <promise>$PROMISE</promise>"
    echo "ONLY output this when the statement is TRUE."
  fi
fi
```

Work on the task. When you try to exit, the Loopy loop will feed the SAME PROMPT back to you for the next iteration. You'll see your previous work in files and git history, allowing you to iterate and improve.

CRITICAL: If a completion promise is set, you may ONLY output it when the statement is completely TRUE. Do not output false promises to escape the loop.
