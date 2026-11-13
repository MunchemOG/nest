#!/bin/bash
# Double-click to open the Nest autorun panel in your browser.
cd "$(dirname "$0")/.." || exit 1
if ! lsof -i :8765 >/dev/null 2>&1; then
  mkdir -p logs/autorun
  nohup /usr/bin/python3 scripts/autorun-panel.py >> logs/autorun/panel.out 2>&1 &
  sleep 1
fi
open http://127.0.0.1:8765
osascript -e 'tell application "Terminal" to close (every window whose name contains "Autorun panel")' >/dev/null 2>&1 &
