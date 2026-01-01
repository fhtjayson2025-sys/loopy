# Loopy

Natural language iterative development loops for Claude Code. Say "start a loopy" instead of typing slash commands.

## Installation

```bash
claude plugins install github:fhtjayson2025-sys/loopy
```

## Usage

Just talk naturally:

```
"Start a loopy to build a REST API"
"Begin a loopy on fixing auth bugs until tests pass"
"Run loopy to refactor this module, max 10 iterations"
```

Loopy will ask clarifying questions if you don't specify:
- **Max iterations** - How many times to retry
- **End goal** - What signals completion

### Cancel

```
"Stop loopy"
"Cancel the loop"
```

## How It Works

1. You describe your task in natural language
2. Loopy detects intent and extracts parameters
3. Creates a persistent loop that keeps working until done
4. Stop hook intercepts exit attempts and re-feeds the prompt
5. Loop continues until completion promise detected or max iterations reached

### Visual Feedback

When active, you'll see:
```
+-------------------------------------+
|  LOOPY LOOP ACTIVE                  |
|  Task: Build REST API               |
|  Iteration: 1/50                    |
|  Stop when: tests pass              |
+-------------------------------------+
```

## Examples

### Build a Feature
```
"Start a loopy to implement user authentication with JWT tokens, stop when all tests pass"
```

### Fix Bugs
```
"Run loopy on fixing the database connection issues, max 20 iterations"
```

### Refactor Code
```
"Begin a loopy to refactor the API handlers into separate modules"
```

## Philosophy

Based on the Ralph Wiggum technique by Geoffrey Huntley - persistent iteration until success. The loop handles retry logic automatically while you step away.

**Good for:**
- Well-defined tasks with clear success criteria
- Tasks requiring iteration (getting tests to pass)
- Greenfield projects
- Tasks with automatic verification

**Not good for:**
- Tasks requiring human judgment
- One-shot operations
- Unclear success criteria

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Fork of: [ralph-wiggum plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-wiggum)
