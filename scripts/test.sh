#!/bin/bash
# Runs the test suite.
#   scripts/test.sh unit   every test except the UI tests; nothing takes over the screen
#   scripts/test.sh all    the whole suite, UI tests included (they drive the Mac's mouse and keyboard)

set -o pipefail
cd "$(dirname "$0")/../NestApp" || exit 1

args=(test -scheme NestApp -destination 'platform=macOS')
case "${1:-}" in
  unit) args+=(-skip-testing:NestAppUITests) ;;
  all) ;;
  *) echo "usage: scripts/test.sh unit|all" >&2; exit 2 ;;
esac

xcodebuild "${args[@]}" 2>&1 | tail -40
