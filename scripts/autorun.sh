#!/bin/bash
# Works through docs/queue.md unattended: one fresh Claude session per task,
# the model picked from scripts/autorun-tiers.txt, sleeping through usage-limit resets.
#
#   scripts/autorun.sh            run until the queue is done or a task is held
#   scripts/autorun.sh --dry-run  show what would run, with which model
#   touch .autorun-stop           stop after the current task

set -u
cd "$(dirname "$0")/.." || exit 1

TIERS=scripts/autorun-tiers.txt
LOGS=logs/autorun
STOP=.autorun-stop
PERM=${AUTORUN_PERMISSION_MODE:-auto}
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
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

pending_tasks() {
  local id
  for id in $(grep -oE '^\| [A-Z0-9]+-[0-9]+ ' docs/queue.md | awk '{ print $2 }'); do
    git merge-base --is-ancestor "task/$id" main 2>/dev/null || echo "$id"
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

run_claude() {
  local model=$1 prompt=$2 sid=$3
  local args=(-p --model "$model" --fallback-model opus,sonnet --permission-mode "$PERM" --output-format json)
  [ -n "$sid" ] && args+=(--resume "$sid")
  claude "${args[@]}" "$prompt"
}

run_task() {
  local id=$1 tier model prompt sid="" out result status wait escalated=0
  tier=$(tier_of "$id")
  if [ "$tier" = heavy ]; then model=$(heavy_model); else model=sonnet; fi
  prompt="Do task $id. This is an unattended run started by scripts/autorun.sh; Mithun is not watching. \
Follow CLAUDE.md's task flow end to end. You have standing permission for step 5: when the task is done \
and the whole suite passes, merge it yourself (git switch main && git merge --no-ff task/$id && git push). \
Do not ask questions; if you are blocked, say so with Result: held or unclear. End with the summary block."

  git switch -q main || { say "$id: could not switch to main (uncommitted changes?)"; return 1; }
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
    if [ "$status" = done ] && git merge-base --is-ancestor "task/$id" main 2>/dev/null; then
      say "$id: done and merged"
      return 0
    fi

    if [ "$tier" = light ] && [ "$escalated" = 0 ] && [ -n "$sid" ]; then
      escalated=1
      model=$(heavy_model)
      say "$id: came back ${status:-without a result}; retrying on $model"
      prompt="You stopped before task $id was merged (result: ${status:-none}). You are now a stronger model. \
Work out what went wrong, finish the task and merge it, or explain why it cannot be done. End with the summary block."
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
    say "stopped by $STOP"
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
