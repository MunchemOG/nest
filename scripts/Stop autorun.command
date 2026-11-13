#!/bin/bash
# Double-click to stop the Nest queue runner once the task it is on is finished.
cd "$(dirname "$0")/.." || exit 1
if pgrep -f scripts/autorun.sh >/dev/null; then
  touch .autorun-stop
  echo "Autorun will stop after the current task. You can close this window."
else
  echo "Autorun is not running."
fi
