---
description: "Start a Loopy iterative development loop"
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT]"
---

# Loopy Command

Run the setup script:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-loopy.sh" <<'LOOPY_ARGS'
$ARGUMENTS
LOOPY_ARGS
```

Check the output above:

1. **If NEEDS_INPUT=true**: Use AskUserQuestion to ask what task to work on, max iterations, and completion signal. Then run `/loopy` again with the answers.

2. **If NEEDS_CLARIFICATION=true**: Use AskUserQuestion to ask about max iterations and completion signal. Then run `/loopy` again with the task and answers.

3. **If LOOPY LOOP ACTIVE**: The loop is started. Work on the task shown. When you try to exit, the stop hook will feed the same prompt back for the next iteration.

CRITICAL: If a completion promise is set, you may ONLY output `<promise>TEXT</promise>` when the statement is completely TRUE.
