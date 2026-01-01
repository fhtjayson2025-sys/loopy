#!/bin/bash
# Test utilities for ralphloop

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Start a test
test_start() {
  CURRENT_TEST="$1"
  ((TESTS_RUN++))
  printf "  Testing: %s... " "$1"
}

# Assert equality
assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"

  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "    Expected: '$expected'"
    echo "    Actual:   '$actual'"
    [[ -n "$msg" ]] && echo "    Message:  $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Assert contains substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "    Expected to contain: '$needle'"
    echo "    Actual: '$haystack'"
    [[ -n "$msg" ]] && echo "    Message: $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Assert not empty
assert_not_empty() {
  local value="$1"
  local msg="${2:-}"

  if [[ -n "$value" ]]; then
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "    Expected non-empty value"
    [[ -n "$msg" ]] && echo "    Message: $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Assert empty
assert_empty() {
  local value="$1"
  local msg="${2:-}"

  if [[ -z "$value" ]]; then
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "    Expected empty, got: '$value'"
    [[ -n "$msg" ]] && echo "    Message: $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Assert exit code
assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"

  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    echo "    Expected exit code: $expected"
    echo "    Actual exit code:   $actual"
    [[ -n "$msg" ]] && echo "    Message: $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Mark test as passed (call after assertions)
test_pass() {
  echo -e "${GREEN}PASS${NC}"
  ((TESTS_PASSED++))
}

# Print test summary
test_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All $TESTS_RUN tests passed${NC}"
  else
    echo -e "${RED}$TESTS_FAILED of $TESTS_RUN tests failed${NC}"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  return $TESTS_FAILED
}
