#!/bin/bash
# Tests for param-extractor.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Path to the script under test
EXTRACTOR="$SCRIPT_DIR/../scripts/param-extractor.sh"

echo "Parameter Extractor Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test: Extracts task from "start a loopy to [task]"
test_start "extracts task from 'start a loopy to build API'"
result=$(echo "start a loopy to build an API" | "$EXTRACTOR")
task=$(echo "$result" | jq -r '.task')
assert_eq "build an API" "$task" && test_pass

# Test: Extracts task from "run loopy on [task]"
test_start "extracts task from 'run loopy on fixing bugs'"
result=$(echo "run loopy on fixing bugs" | "$EXTRACTOR")
task=$(echo "$result" | jq -r '.task')
assert_eq "fixing bugs" "$task" && test_pass

# Test: Extracts task from "loopy on [task]"
test_start "extracts task from 'loopy on this feature'"
result=$(echo "loopy on this feature" | "$EXTRACTOR")
task=$(echo "$result" | jq -r '.task')
assert_eq "this feature" "$task" && test_pass

# Test: Extracts completion promise from "until [condition]"
test_start "extracts completion promise from 'until tests pass'"
result=$(echo "start a loopy to build API until tests pass" | "$EXTRACTOR")
promise=$(echo "$result" | jq -r '.completion_promise')
assert_eq "tests pass" "$promise" && test_pass

# Test: Extracts completion promise from "when [condition]"
test_start "extracts completion promise from 'when done'"
result=$(echo "run loopy on refactoring when done" | "$EXTRACTOR")
promise=$(echo "$result" | jq -r '.completion_promise')
assert_eq "done" "$promise" && test_pass

# Test: Extracts max iterations from "max N iterations"
test_start "extracts max iterations from 'max 20 iterations'"
result=$(echo "start a loopy to build API max 20 iterations" | "$EXTRACTOR")
max=$(echo "$result" | jq -r '.max_iterations')
assert_eq "20" "$max" && test_pass

# Test: Extracts max iterations from "N iterations"
test_start "extracts max iterations from '50 iterations'"
result=$(echo "run loopy on this task for 50 iterations" | "$EXTRACTOR")
max=$(echo "$result" | jq -r '.max_iterations')
assert_eq "50" "$max" && test_pass

# Test: Default max_iterations is 0 (unlimited)
test_start "default max_iterations is 0"
result=$(echo "start a loopy to build API" | "$EXTRACTOR")
max=$(echo "$result" | jq -r '.max_iterations')
assert_eq "0" "$max" && test_pass

# Test: Default completion_promise is null
test_start "default completion_promise is null when not specified"
result=$(echo "start a loopy to build API" | "$EXTRACTOR")
promise=$(echo "$result" | jq -r '.completion_promise')
assert_eq "null" "$promise" && test_pass

# Test: Complex sentence extraction
test_start "handles complex sentence with all params"
result=$(echo "begin loopy to implement auth feature until all tests green max 30 iterations" | "$EXTRACTOR")
task=$(echo "$result" | jq -r '.task')
promise=$(echo "$result" | jq -r '.completion_promise')
max=$(echo "$result" | jq -r '.max_iterations')
assert_eq "implement auth feature" "$task" && \
assert_eq "all tests green" "$promise" && \
assert_eq "30" "$max" && test_pass

# Test: "let's loopy on [task] until [condition]"
test_start "handles 'let's loopy on X until Y'"
result=$(echo "let's loopy on the bug fix until it's resolved" | "$EXTRACTOR")
task=$(echo "$result" | jq -r '.task')
promise=$(echo "$result" | jq -r '.completion_promise')
assert_eq "the bug fix" "$task" && \
assert_eq "it's resolved" "$promise" && test_pass

test_summary
