#!/bin/bash
# Double-click to see what the Nest queue runner is doing. Close the window when you are done.
cd "$(dirname "$0")/.." || exit 1
if pgrep -f scripts/autorun.sh >/dev/null; then echo "Autorun is running."; else echo "Autorun is not running."; fi
echo
touch logs/autorun/autorun.log 2>/dev/null || { mkdir -p logs/autorun; touch logs/autorun/autorun.log; }
tail -n 30 -f logs/autorun/autorun.log
