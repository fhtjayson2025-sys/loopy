#!/bin/bash
# Tests for prompt-submit-hook.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Path to the script under test
HOOK="$SCRIPT_DIR/../hooks/prompt-submit-hook.sh"

# Setup: ensure clean state
cleanup() {
  rm -f .claude/loopy-loop.local.md 2>/dev/null || true
}
trap cleanup EXIT
cleanup

echo "UserPromptSubmit Hook Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test: Detects start intent with complete params - creates state file
test_start "creates state file when params complete"
input='{"prompt": "start a loopy to build an API until done max 20 iterations"}'
result=$(echo "$input" | "$HOOK")
test -f .claude/loopy-loop.local.md
assert_eq "0" "$?" "state file should exist" && test_pass
cleanup

# Test: Missing params triggers clarification request
test_start "requests clarification when missing iterations and goal"
input='{"prompt": "start a loopy to build an API"}'
result=$(echo "$input" | "$HOOK")
assert_contains "$result" "needs_clarification" && test_pass
cleanup

# Test: Clarification includes question about iterations
test_start "clarification asks about iterations"
input='{"prompt": "start a loopy to fix bugs"}'
result=$(echo "$input" | "$HOOK")
assert_contains "$result" "iterations" && test_pass
cleanup

# Test: Clarification includes question about end goal
test_start "clarification asks about end goal"
input='{"prompt": "start a loopy to refactor code"}'
result=$(echo "$input" | "$HOOK")
assert_contains "$result" "goal" || assert_contains "$result" "done" && test_pass
cleanup

# Test: Having completion promise is sufficient (no clarification needed)
test_start "completion promise alone is sufficient"
input='{"prompt": "start a loopy to build API until tests pass"}'
result=$(echo "$input" | "$HOOK")
test -f .claude/loopy-loop.local.md
assert_eq "0" "$?" "state file should exist with just promise" && test_pass
cleanup

# Test: Having max iterations is sufficient (no clarification needed)
test_start "max iterations alone is sufficient"
input='{"prompt": "start a loopy to build API max 30 iterations"}'
result=$(echo "$input" | "$HOOK")
test -f .claude/loopy-loop.local.md
assert_eq "0" "$?" "state file should exist with just max_iterations" && test_pass
cleanup

# Test: State file contains correct task
test_start "state file contains the task prompt"
input='{"prompt": "start a loopy to build an API until done"}'
echo "$input" | "$HOOK" > /dev/null
content=$(cat .claude/loopy-loop.local.md 2>/dev/null || echo "")
assert_contains "$content" "build an API" && test_pass
cleanup

# Test: Returns visual banner message when started
test_start "returns visual banner in message"
input='{"prompt": "start a loopy to build API until done"}'
result=$(echo "$input" | "$HOOK")
assert_contains "$result" "LOOPY ACTIVE" && test_pass
cleanup

# Test: Cancel removes state file
test_start "cancel removes state file"
# First create a loop with complete params
echo '{"prompt": "start a loopy to test until done"}' | "$HOOK" > /dev/null
test -f .claude/loopy-loop.local.md
assert_eq "0" "$?" "state file should exist first" || true
# Then cancel
echo '{"prompt": "stop loopy"}' | "$HOOK" > /dev/null
test ! -f .claude/loopy-loop.local.md
assert_eq "0" "$?" "state file should be removed" && test_pass
cleanup

# Test: Cancel reports iteration count
test_start "cancel reports iteration count"
mkdir -p .claude
cat > .claude/loopy-loop.local.md <<'EOF'
---
active: true
iteration: 5
max_iterations: 50
completion_promise: null
---

test task
EOF
result=$(echo '{"prompt": "cancel loopy"}' | "$HOOK")
assert_contains "$result" "iteration 5" && test_pass
cleanup

# Test: Non-loopy prompt passes through
test_start "non-loopy prompt returns continue result"
input='{"prompt": "help me fix this bug"}'
result=$(echo "$input" | "$HOOK")
decision=$(echo "$result" | jq -r '.result // .decision // "continue"')
assert_eq "continue" "$decision" && test_pass

# Test: Shows task in banner
test_start "banner shows task description"
input='{"prompt": "begin loopy to implement auth until done"}'
result=$(echo "$input" | "$HOOK")
assert_contains "$result" "implement auth" && test_pass
cleanup

test_summary
