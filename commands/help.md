---
description: "Explain Loopy technique and available commands"
---

# Loopy Plugin Help

Please explain the following to the user:

## What is Loopy?

Loopy is an iterative development methodology based on continuous AI loops. The same prompt is fed repeatedly, with Claude seeing its own previous work in files and git history.

**Two ways to invoke:**

1. **Natural language**: "Start a loopy to build a REST API"
2. **Slash command**: `/loopy Build a REST API --max-iterations 20`

## Available Commands

### /loopy <PROMPT> [OPTIONS]

Start a Loopy loop in your current session.

**Usage:**
```
/loopy "Refactor the cache layer" --max-iterations 20
/loopy "Add tests" --completion-promise "TESTS COMPLETE"
```

**Options:**
- `--max-iterations <n>` - Max iterations before auto-stop
- `--completion-promise <text>` - Promise phrase to signal completion

### /cancel-loopy

Cancel an active Loopy loop.

**Usage:**
```
/cancel-loopy
```

## Natural Language Invocation

Just say:
- "Start a loopy to [task]"
- "Begin a loopy on [task] until [condition]"
- "Run loopy to [task], max 10 iterations"

To cancel:
- "Stop loopy"
- "Cancel the loop"

## Completion Promises

To signal completion, output a `<promise>` tag:

```
<promise>TASK COMPLETE</promise>
```

The stop hook looks for this tag. Without it (or `--max-iterations`), Loopy runs infinitely.

## When to Use Loopy

**Good for:**
- Well-defined tasks with clear success criteria
- Tasks requiring iteration and refinement
- Iterative development with self-correction
- Greenfield projects

**Not good for:**
- Tasks requiring human judgment
- One-shot operations
- Tasks with unclear success criteria

## Learn More

- Based on: https://ghuntley.com/ralph/
