#!/bin/bash
# Works through docs/queue.md unattended: one fresh Claude session per task,
# the model picked from scripts/autorun-tiers.txt, sleeping through usage-limit resets.
# Sessions test with unit tests only; the runner runs the whole suite (UI tests take over
# the screen, so only while the Mac is idle and unlocked) and merges on green.
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

TIERS=scripts/autorun-tiers.txt
LOGS=logs/autorun
STOP=.autorun-stop
PERM=${AUTORUN_PERMISSION_MODE:-bypassPermissions}
IDLE_NEEDED=${AUTORUN_IDLE_SECONDS:-300}
FIX_TRIES=2
mkdir -p "$LOGS"

say() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$*" | tee -a "$LOGS/autorun.log"; }
notify() { osascript -e "display notification \"$1\" with title \"Nest autorun\"" >/dev/null 2>&1; }

tier_of() {
  local t
  t=$(awk -v id="$1" '$1 == id { print $2 }' "$TIERS" | head -1)
  echo "${t:-light}"
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

pending_tasks() {
  local id
  for id in $(grep -oE '^\| [A-Z0-9]+-[0-9]+ ' docs/queue.md | awk '{ print $2 }'); do
    is_merged "$id" || echo "$id"
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

run_claude() {
  local model=$1 prompt=$2 sid=$3
  local args=(-p --model "$model" --fallback-model opus,sonnet --permission-mode "$PERM" --output-format json)
  [ -n "$sid" ] && args+=(--resume "$sid")
  claude "${args[@]}" "$prompt"
}

merge_task() {
  git switch -q main && git merge -q --no-ff "task/$1" -m "Merge branch 'task/$1'" && git push -q
}

run_task() {
  local id=$1 tier model prompt sid="" out result status wait escalated=0 fixes=0 suite
  tier=$(tier_of "$id")
  if [ "$tier" = heavy ]; then model=$(heavy_model); else model=sonnet; fi
  prompt="Do task $id. This is an unattended run started by scripts/autorun.sh; Mithun is not watching. \
Follow CLAUDE.md's task flow, with two changes for this run. Test with scripts/test.sh unit, never the UI tests \
(they take over Mithun's screen). Do not merge: commit on task/$id and stop; the runner runs the whole suite \
and merges. If files from an interrupted earlier attempt at this task are in the working tree, continue from them. \
Do not ask questions; if you are blocked, say so with Result: held or unclear. End with the summary block."

  if [ "$(git branch --show-current)" != "task/$id" ]; then
    git switch -q main || { say "$id: could not switch to main (uncommitted changes?)"; return 1; }
  fi
  say "$id: starting on $model ($tier)"

  while true; do
    out=$(run_claude "$model" "$prompt" "$sid")
    echo "$out" >> "$LOGS/$id.json"
    sid=$(echo "$out" | jq -r '.session_id // empty' 2>/dev/null)
    result=$(echo "$out" | jq -r '.result // empty' 2>/dev/null)
    [ -z "$result" ] && result=$out

    if wait=$(limit_wait "$result"); then
      say "$id: usage limit, sleeping $((wait / 60)) min"
      sleep "$wait"
      prompt="Continue task $id where you left off, then end with the summary block."
      continue
    fi

    status=$(echo "$result" | grep -oE '^[[:space:]]*Result:[[:space:]]*[a-z]+' | head -1 | awk '{ print $NF }')

    if [ "$status" = done ] && git rev-parse -q --verify "task/$id" >/dev/null; then
      git switch -q "task/$id" || { say "$id: could not switch to task/$id"; return 1; }
      wait_until_idle "$id"
      say "$id: running the whole suite"
      if suite=$(scripts/test.sh all); then
        echo "$suite" > "$LOGS/$id-suite.log"
        merge_task "$id" || { say "$id: merge or push failed"; return 1; }
        say "$id: done, suite green, merged"
        return 0
      fi
      echo "$suite" > "$LOGS/$id-suite.log"
      if [ "$fixes" -lt "$FIX_TRIES" ] && [ -n "$sid" ]; then
        fixes=$((fixes + 1))
        say "$id: whole suite failed; sending it back (try $fixes)"
        prompt="The runner ran the whole suite on task/$id and it failed. The end of the output: \
$(echo "$suite" | tail -25) \
Fix the cause and commit. You may run one failing UI test class with -only-testing if you must. \
Never weaken or skip a test. End with the summary block."
        continue
      fi
      say "$id: whole suite still failing. See $LOGS/$id-suite.log"
      return 1
    fi

    if [ "$tier" = light ] && [ "$escalated" = 0 ] && [ -n "$sid" ]; then
      escalated=1
      model=$(heavy_model)
      say "$id: came back ${status:-without a result}; retrying on $model"
      prompt="You stopped before task $id was finished (result: ${status:-none}). You are now a stronger model. \
Work out what went wrong and finish the task on task/$id, or explain why it cannot be done. End with the summary block."
      continue
    fi

    say "$id: stopped (${status:-no result}). See $LOGS/$id.json"
    return 1
  done
}

for id in $(pending_tasks); do
  tier=$(tier_of "$id")
  if [ "$DRY" = 1 ]; then
    if [ "$tier" = heavy ]; then echo "$id  heavy  $(heavy_model)"; elif [ "$tier" = manual ]; then echo "$id  manual  (stop)"; else echo "$id  light  sonnet"; fi
    continue
  fi
  if [ -f "$STOP" ]; then
    rm -f "$STOP"
    say "stopped by request"
    notify "Stopped"
    exit 0
  fi
  if [ "$tier" = manual ]; then
    say "$id needs you; stopping"
    notify "$id needs you"
    exit 0
  fi
  if ! run_task "$id"; then
    notify "$id was held; see logs/autorun"
    exit 1
  fi
done
[ "$DRY" = 0 ] && say "queue empty" && notify "Queue done"
exit 0
