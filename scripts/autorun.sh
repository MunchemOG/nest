#!/bin/bash
# Works through docs/queue.md unattended, one task at a time.
#
# - Every attempt is a fresh Claude session; sessions pass work on through a short handoff
#   note instead of resuming (resuming makes the next model reread the whole session).
# - The model comes from scripts/autorun-tiers.txt; a light task that comes back held is
#   retried once on the heavy model.
# - Usage limits: sleeps until the reset, then carries on. API hiccups: one retry.
# - Sessions test with unit tests only. Before merging, the runner checks for weakened
#   tests and hard-coded design values (no tokens spent), runs the whole suite (UI tests
#   only while the Mac is idle and unlocked), tags a restore point, then merges.
# - Logs the cost of every session to logs/autorun/costs.tsv.
# - Restarts itself between tasks when this file changes on main.
#
#   scripts/autorun.sh            run until the queue is done or a task is held
#   scripts/autorun.sh --dry-run  show what would run, with which model
#   touch .autorun-stop           stop after the current task

set -u
cd "$(dirname "$0")/.." || exit 1

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# Keep the Mac and its display awake for the whole run.
if [ "$DRY" = 0 ] && [ -z "${AUTORUN_AWAKE:-}" ]; then
  export AUTORUN_AWAKE=1
  exec caffeinate -dims "$0" "$@"
fi

SELF=scripts/autorun.sh
SELF_HASH=$(git hash-object "$SELF")
TIERS=scripts/autorun-tiers.txt
LOGS=logs/autorun
COSTS=$LOGS/costs.tsv
STOP=.autorun-stop
PERM=${AUTORUN_PERMISSION_MODE:-bypassPermissions}
IDLE_NEEDED=${AUTORUN_IDLE_SECONDS:-300}
FIX_TRIES=2
mkdir -p "$LOGS/handoff"

say() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$*" | tee -a "$LOGS/autorun.log"; }
notify() { osascript -e "display notification \"$1\" with title \"Nest autorun\"" >/dev/null 2>&1; }

# Settings the control panel (scripts/autorun-panel.py) writes. Not tracked by git.
PANEL=.autorun
EXTRA=$PANEL/tasks.json
SKIP=$PANEL/skip.txt
SCHEDULE=$PANEL/schedule.txt
CURRENT=$PANEL/current
mkdir -p "$PANEL"

tier_of() {
  local t
  t=$(cat "$PANEL/tiers.txt" "$TIERS" 2>/dev/null | awk -v id="$1" '$1 == id { print $2; exit }')
  echo "${t:-light}"
}

is_skipped() { [ -f "$SKIP" ] && grep -qx "$1" "$SKIP"; }

extra_field() { jq -r --arg id "$1" --arg f "$2" '.[] | select(.id == $id) | .[$f] // ""' "$EXTRA" 2>/dev/null; }

# Waits while the panel's schedule says the runner is off ("HH:MM HH:MM" on-window, or "always").
in_window() {
  local on off now
  [ -s "$SCHEDULE" ] || return 0
  read -r on off < "$SCHEDULE"
  [ "$on" = always ] || [ -z "${off:-}" ] && return 0
  now=$(date +%H%M); on=${on/:/}; off=${off/:/}
  if [ "$on" -le "$off" ]; then [ "$now" -ge "$on" ] && [ "$now" -lt "$off" ]
  else [ "$now" -ge "$on" ] || [ "$now" -lt "$off" ]; fi
}

wait_for_window() {
  local told=0
  while ! in_window; do
    [ -f "$STOP" ] && return 0
    if [ "$told" = 0 ]; then say "outside the schedule ($(cat "$SCHEDULE")); waiting"; told=1; fi
    echo "waiting for schedule" > "$CURRENT"
    sleep 60
  done
}

heavy_model() {
  local until
  until=$(awk '$1 == "fable-until" { print $2 }' "$TIERS")
  if [ -n "$until" ] && [[ ! "$(date +%F)" > "$until" ]]; then echo fable; else echo opus; fi
}

# A task is merged when its branch tip reached main through a merge. A fresh branch
# made from main sits on main's own line, so it does not count.
is_merged() {
  local tip
  tip=$(git rev-parse -q --verify "task/$1") || return 1
  git merge-base --is-ancestor "$tip" main || return 1
  ! git rev-list --first-parent main | grep -qx "$tip"
}

# Tasks added in the panel run first, then docs/queue.md in order. Skipped ones are left out.
pending_tasks() {
  local id
  for id in $(jq -r '.[].id' "$EXTRA" 2>/dev/null) $(grep -oE '^\| [A-Z0-9]+-[0-9]+ ' docs/queue.md | awk '{ print $2 }'); do
    is_skipped "$id" || is_merged "$id" || echo "$id"
  done
}

# Prints seconds to wait if the run stopped on a usage limit; fails otherwise.
limit_wait() {
  local text epoch wait
  text=$1
  echo "$text" | grep -qE '^[[:space:]]*Result:' && return 1
  echo "$text" | grep -qiE 'limit' || return 1
  echo "$text" | grep -qiE 'reset|reached|exceeded|rate' || return 1
  epoch=$(echo "$text" | grep -oE '\|[0-9]{10}' | head -1 | tr -d '|')
  if [ -n "$epoch" ]; then
    wait=$((epoch - $(date +%s) + 120))
    [ "$wait" -lt 120 ] && wait=120
  else
    wait=1800
  fi
  echo "$wait"
}

idle_seconds() { ioreg -c IOHIDSystem | awk '/HIDIdleTime/ { print int($NF / 1000000000); exit }'; }
screen_locked() { ioreg -n Root -d1 -a | grep -A1 CGSSessionScreenIsLocked | grep -q true; }

# UI tests take over the mouse and keyboard, so wait until nobody is using the Mac.
wait_until_idle() {
  local told=0
  while [ "$(idle_seconds)" -lt "$IDLE_NEEDED" ] || screen_locked; do
    if [ "$told" = 0 ]; then
      say "$1: waiting for the Mac to be idle and unlocked to run the UI tests"
      told=1
    fi
    sleep 60
  done
}

# Checks that cost no tokens. Prints each problem found on task/<id>.
guard_problems() {
  local id=$1 base before after added
  base=$(git merge-base main "task/$id")
  before=$(git grep -hE '@Test|func test' "$base" -- '*Tests/*.swift' | wc -l)
  after=$(git grep -hE '@Test|func test' "task/$id" -- '*Tests/*.swift' | wc -l)
  [ "$after" -lt "$before" ] && echo "The number of tests dropped from $before to $after."
  added=$(git diff "$base" "task/$id" -- '*.swift' | grep '^+' | grep -v '^+++')
  echo "$added" | grep -qE '\.disabled|XCTSkip|withKnownIssue' && echo "A test was disabled or skipped."
  git diff "$base" "task/$id" -- '*.swift' ':(exclude)*Tokens/*' ':(exclude)*Tests/*' \
    | grep '^+' | grep -v '^+++' \
    | grep -qE '#[0-9A-Fa-f]{6}|Color\(red:|NSColor\(red:|\.system\(size: *[0-9]|cornerRadius: *[0-9]' \
    && echo "A colour, font size or radius is hard-coded instead of coming from the tokens."
  return 0
}

log_cost() {
  local id=$1 model=$2 out=$3 cost
  cost=$(echo "$out" | jq -r '.total_cost_usd // 0' 2>/dev/null)
  [ -s "$COSTS" ] || printf 'time\ttask\tmodel\tusd\n' > "$COSTS"
  printf '%s\t%s\t%s\t%s\n' "$(date '+%F %T')" "$id" "$model" "${cost:-0}" >> "$COSTS"
}

task_cost() { awk -F'\t' -v id="$1" '$2 == id { s += $4 } END { printf "%.2f", s }' "$COSTS"; }

run_claude() {
  claude -p --model "$1" --fallback-model opus,sonnet --permission-mode "$PERM" --output-format json "$2"
}

merge_task() {
  git switch -q main \
    && git tag -f "restore/$1" main >/dev/null \
    && git merge -q --no-ff "task/$1" -m "Merge branch 'task/$1'" \
    && git push -q
}

run_task() {
  local id=$1 tier model rules prompt out result status wait problems suite
  local escalated=0 fixes=0 hiccups=0 handoff="$LOGS/handoff/$id.md"
  tier=$(tier_of "$id")
  if [ "$tier" = heavy ]; then model=$(heavy_model); else model=sonnet; fi
  rules="This is an unattended run started by scripts/autorun.sh; Mithun is not watching. \
Follow CLAUDE.md's task flow, with these changes. Test with scripts/test.sh unit, never the UI tests \
(they take over Mithun's screen). Do not merge: commit on task/$id and stop; the runner checks for \
weakened tests and hard-coded design values, runs the whole suite and merges. Before you finish, \
overwrite $handoff with at most 15 lines for whoever continues: what is done, what is left, anything \
surprising. Do not ask questions; if you are blocked, say so with Result: held or unclear. \
End with the summary block."
  prompt="Do task $id. If files from an interrupted earlier attempt are in the working tree, continue from them. $rules"
  if [ -n "$(extra_field "$id" goal)" ]; then
    prompt="Do task $id. It is not in docs/queue.md; Mithun added it from the autorun panel. \
Goal: $(extra_field "$id" goal). Done means: $(extra_field "$id" done_means). Treat that as its queue row \
(no needs). If files from an interrupted earlier attempt are in the working tree, continue from them. $rules"
  fi
  echo "$id $model" > "$CURRENT"

  if [ "$(git branch --show-current)" != "task/$id" ]; then
    git switch -q main || { say "$id: could not switch to main (uncommitted changes?)"; return 1; }
  fi
  say "$id: starting on $model ($tier)"

  while true; do
    out=$(run_claude "$model" "$prompt")
    echo "$out" >> "$LOGS/$id.json"
    log_cost "$id" "$model" "$out"
    result=$(echo "$out" | jq -r '.result // empty' 2>/dev/null)
    [ -z "$result" ] && result=$out

    if wait=$(limit_wait "$result"); then
      say "$id: usage limit, sleeping $((wait / 60)) min"
      sleep "$wait"
      prompt="Continue task $id on task/$id; the last session was cut off by a usage limit. \
Read $handoff first if it exists, then git log main..task/$id and git status. $rules"
      continue
    fi

    status=$(echo "$result" | grep -oE '^[[:space:]]*Result:[[:space:]]*[a-z]+' | head -1 | awk '{ print $NF }')

    if [ -z "$status" ] && [ "$hiccups" = 0 ]; then
      hiccups=1
      say "$id: no result from the session; retrying in 5 min"
      sleep 300
      prompt="Continue task $id on task/$id; the last session ended without a result. \
Read $handoff first if it exists, then git log main..task/$id and git status. $rules"
      continue
    fi

    if [ "$status" = done ] && git rev-parse -q --verify "task/$id" >/dev/null; then
      git switch -q "task/$id" || { say "$id: could not switch to task/$id"; return 1; }
      problems=$(guard_problems "$id")
      if [ -z "$problems" ]; then
        wait_until_idle "$id"
        say "$id: running the whole suite"
        if suite=$(scripts/test.sh all); then
          echo "$suite" > "$LOGS/$id-suite.log"
          merge_task "$id" || { say "$id: merge or push failed"; return 1; }
          say "$id: done, suite green, merged (\$$(task_cost "$id"))"
          return 0
        fi
        echo "$suite" > "$LOGS/$id-suite.log"
        problems="The whole suite failed. The end of the output:
$(echo "$suite" | tail -25)"
      fi
      if [ "$fixes" -lt "$FIX_TRIES" ]; then
        fixes=$((fixes + 1))
        say "$id: not ready to merge; sending it back (try $fixes): $(echo "$problems" | head -1)"
        prompt="Continue task $id on task/$id. The runner would not merge it: $problems
Read $handoff first. Fix the cause and commit. You may run one failing UI test class with -only-testing \
if you must. Never weaken or skip a test. $rules"
        continue
      fi
      say "$id: still not ready after $FIX_TRIES fixes. See $LOGS/$id-suite.log"
      return 1
    fi

    if [ "$tier" = light ] && [ "$escalated" = 0 ]; then
      escalated=1
      model=$(heavy_model)
      echo "$id $model" > "$CURRENT"
      say "$id: came back ${status:-without a result}; retrying on $model"
      prompt="Continue task $id on task/$id. A smaller model stopped before finishing (result: ${status:-none}); \
its summary was: $(echo "$result" | tail -12)
Read $handoff first if it exists, then git log main..task/$id and git status. Work out what went wrong \
and finish, or explain why it cannot be done. $rules"
      continue
    fi

    say "$id: stopped (${status:-no result}). See $LOGS/$id.json"
    return 1
  done
}

if [ "$DRY" = 1 ]; then
  for id in $(pending_tasks); do
    tier=$(tier_of "$id")
    if [ "$tier" = heavy ]; then echo "$id  heavy  $(heavy_model)"; elif [ "$tier" = manual ]; then echo "$id  manual  (stop)"; else echo "$id  light  sonnet"; fi
  done
  exit 0
fi

trap 'rm -f "$CURRENT"' EXIT
say "runner started"
while true; do
  wait_for_window
  if [ -f "$STOP" ]; then
    rm -f "$STOP"
    say "stopped by request"
    notify "Stopped"
    exit 0
  fi
  # Re-read each time: the panel can add, skip or reorder tasks while the runner works.
  id=$(pending_tasks | head -1)
  if [ -z "$id" ]; then
    say "queue empty"
    notify "Queue done"
    exit 0
  fi
  if [ "$(tier_of "$id")" = manual ]; then
    say "$id needs you; stopping"
    notify "$id needs you"
    exit 0
  fi
  if ! run_task "$id"; then
    notify "$id was held; see the autorun panel"
    exit 1
  fi
  if [ "$(git hash-object "$SELF")" != "$SELF_HASH" ]; then
    say "runner updated; restarting"
    exec "$SELF"
  fi
done
