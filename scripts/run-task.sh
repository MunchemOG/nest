#!/bin/bash
# The manual runner: one task from docs/queue.md becomes a tested branch while you watch.
# Makes or continues task/<id>, runs one Claude Code session on it, reads back the summary
# block, then runs the suite itself. It never merges.
#   scripts/run-task.sh S2-02        then the whole suite (UI tests take over the screen)
#   scripts/run-task.sh S2-02 unit   then every test except the UI tests

cd "$(dirname "$0")/.." || exit 1
swift build -q --package-path NestKit --product nest-run || exit 1
exec "$(swift build --package-path NestKit --show-bin-path)/nest-run" "$@"
