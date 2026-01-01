#!/bin/bash
# Run all tests for ralphloop

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    RALPHLOOP TEST SUITE                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

FAILED=0

# Run each test file
for test_file in "$SCRIPT_DIR"/*.test.sh; do
  if [[ -f "$test_file" ]]; then
    echo ""
    if ! "$test_file"; then
      FAILED=1
    fi
  fi
done

echo ""
echo "══════════════════════════════════════════════════════════════"
if [[ $FAILED -eq 0 ]]; then
  echo "✅ All test suites passed"
else
  echo "❌ Some tests failed"
fi
echo "══════════════════════════════════════════════════════════════"

exit $FAILED
