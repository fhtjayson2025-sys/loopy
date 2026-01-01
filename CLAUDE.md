# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Vision

**ralphloop** is a fork of the ralph-wiggum plugin with one key enhancement: **natural language invocation**. Instead of requiring `/ralph-loop` slash commands, users should be able to say things like:

- "Start a ralph loop to build a REST API"
- "Run ralph on this task until tests pass"
- "Begin iterating on this feature"

When invoked, the loop status must display **clearly and prominently** in the Claude Code chat.

## Architecture

```
ralphloop/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                 # Slash command definitions
│   ├── ralph-loop.md        # /ralph-loop command
│   ├── cancel-ralph.md      # /cancel-ralph command
│   └── help.md              # /help command
├── hooks/
│   ├── hooks.json           # Hook registration
│   └── stop-hook.sh         # Core: intercepts exit, re-feeds prompt
├── scripts/
│   └── setup-ralph-loop.sh  # Creates state file, validates args
└── tests/                   # Test suite (to be created)
```

### Core Flow

1. User invokes loop (slash command OR natural language)
2. `setup-ralph-loop.sh` creates `.claude/ralph-loop.local.md` state file
3. Claude works on task, tries to exit
4. `stop-hook.sh` intercepts Stop event, checks state file
5. If active: blocks exit, re-feeds same prompt with iteration count
6. Loop continues until completion promise detected or max iterations

### State File Format

`.claude/ralph-loop.local.md`:
```yaml
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "DONE"
started_at: "2025-01-01T00:00:00Z"
---

<prompt text here>
```

## Development Standards

### File Size
Every file must be **under 500 lines**. If a file grows beyond this:
- Split into logical modules
- Use imports/requires to compose

### Testing
Every module requires a corresponding test file:
- `hooks/stop-hook.sh` → `tests/stop-hook.test.sh`
- `scripts/setup-ralph-loop.sh` → `tests/setup-ralph-loop.test.sh`

Test commands:
```bash
# Run all tests
./tests/run-all.sh

# Run single test
./tests/stop-hook.test.sh
```

### Natural Language Detection (To Build)

The key differentiator is detecting ralph invocation from natural language. This requires:

1. **UserPromptSubmit hook** - Intercepts user messages before processing
2. **Intent classifier** - Detects phrases like "start ralph", "run loop", "iterate on"
3. **Parameter extraction** - Pulls task description, iteration limits from natural text
4. **Visual feedback** - Displays clear loop status banner in chat

Example flow:
```
User: "Start a ralph loop to fix auth bugs, stop when tests pass"
         ↓
UserPromptSubmit hook detects intent
         ↓
Extracts: task="fix auth bugs", promise="tests pass"
         ↓
Creates state file, displays:
╔══════════════════════════════════════╗
║  🔄 RALPH LOOP ACTIVE                ║
║  Task: fix auth bugs                 ║
║  Iteration: 1                        ║
║  Stop when: tests pass               ║
╚══════════════════════════════════════╝
```

## Commands

```bash
# Build/validate (no build step currently - shell scripts)
shellcheck hooks/*.sh scripts/*.sh

# Run tests
./tests/run-all.sh

# Lint markdown
npx markdownlint-cli2 "**/*.md"
```

## Key Files to Understand

1. **hooks/stop-hook.sh** - The heart of Ralph. Reads transcript, checks completion promise, blocks exit and re-feeds prompt.

2. **scripts/setup-ralph-loop.sh** - Argument parsing, state file creation, validation.

3. **hooks/hooks.json** - Registers the Stop hook with Claude Code.

## Specs: Natural Language Invocation

### Detection Patterns

Must recognize variations:
- "start ralph loop", "begin ralph", "run ralph"
- "iterate on [task]", "loop until [condition]"
- "keep working on this until [done]"

### Required Visual Feedback

When loop is active, every response should show:
```
┌─────────────────────────────────────┐
│ 🔄 Ralph Loop: Iteration 3/50       │
│ Task: Build REST API                │
│ Exit: <promise>COMPLETE</promise>   │
└─────────────────────────────────────┘
```

### Cancel Detection

Also detect natural language cancellation:
- "stop ralph", "cancel the loop", "exit ralph mode"
