#!/bin/bash
# Double-click to start the Nest queue runner. It keeps going after you close this window.
cd "$(dirname "$0")/.." || exit 1
mkdir -p logs/autorun
if pgrep -f scripts/autorun.sh >/dev/null; then
  echo "Autorun is already running."
else
  rm -f .autorun-stop
  nohup scripts/autorun.sh >> logs/autorun/nohup.out 2>&1 &
  echo "Autorun started. You can close this window."
fi
