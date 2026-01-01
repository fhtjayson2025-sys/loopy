#!/bin/bash
# Tests for intent-classifier.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-utils.sh"

# Path to the script under test
CLASSIFIER="$SCRIPT_DIR/../scripts/intent-classifier.sh"

echo "Intent Classifier Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test: Detects "start a loopy" as start intent
test_start "detects 'start a loopy' as start intent"
result=$(echo "start a loopy to build an API" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "begin loopy" as start intent
test_start "detects 'begin loopy' as start intent"
result=$(echo "begin loopy on this task" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "run loopy" as start intent
test_start "detects 'run loopy' as start intent"
result=$(echo "run loopy until tests pass" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "loopy on" as start intent
test_start "detects 'loopy on this' as start intent"
result=$(echo "loopy on this feature until done" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "start loopy" (without "a") as start intent
test_start "detects 'start loopy' as start intent"
result=$(echo "start loopy to fix bugs" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "let's loopy" as start intent
test_start "detects 'let's loopy' as start intent"
result=$(echo "let's loopy on this task" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

# Test: Detects "stop loopy" as cancel intent
test_start "detects 'stop loopy' as cancel intent"
result=$(echo "stop loopy" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "cancel_loopy" "$intent" && test_pass

# Test: Detects "cancel loopy" as cancel intent
test_start "detects 'cancel loopy' as cancel intent"
result=$(echo "cancel loopy" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "cancel_loopy" "$intent" && test_pass

# Test: Detects "exit loopy" as cancel intent
test_start "detects 'exit loopy' as cancel intent"
result=$(echo "exit loopy" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "cancel_loopy" "$intent" && test_pass

# Test: Regular prompts return none
test_start "regular prompts return 'none' intent"
result=$(echo "help me fix this bug" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "none" "$intent" && test_pass

# Test: Returns original text
test_start "returns original text in output"
result=$(echo "start a loopy to build API" | "$CLASSIFIER")
text=$(echo "$result" | jq -r '.text')
assert_eq "start a loopy to build API" "$text" && test_pass

# Test: Case insensitive
test_start "handles case insensitivity"
result=$(echo "START A LOOPY now" | "$CLASSIFIER")
intent=$(echo "$result" | jq -r '.intent')
assert_eq "start_loopy" "$intent" && test_pass

test_summary
