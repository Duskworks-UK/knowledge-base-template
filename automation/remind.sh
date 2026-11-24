#!/bin/bash
# Shows a notification for open tasks in wiki/tasks.md that are due today or
# overdue. A plain script: it doesn't run Claude, so it costs nothing.
#
#   automation/remind.sh           notify (and print the list)
#   automation/remind.sh --print   print the list only
set -u
source "$(dirname "$0")/lib.sh"

tasks="$KB_WIKI/tasks.md"
[ -f "$tasks" ] || exit 0
today=$(date '+%Y-%m-%d')

# Open tasks with a due date on or before today, as "date<TAB>description".
due=$(awk -v today="$today" '
  /^[[:space:]]*- \[ \] / && match($0, /📅 [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) {
    date = substr($0, RSTART + RLENGTH - 10, 10)
    if (date > today) next
    text = $0
    sub(/^[[:space:]]*- \[ \] /, "", text)
    sub(/[[:space:]]*(📅|🔁|⏳|🛫|✅).*$/, "", text)
    gsub(/\[([^]]*)\]\([^)]*\)/, "", text)       # drop Markdown links
    gsub(/[[:space:]]*\(\)[[:space:]]*/, " ", text)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
    print date "\t" text
  }' "$tasks" | sort)

[ -n "$due" ] || exit 0

overdue=$(awk -F'\t' -v t="$today" '$1 < t' <<<"$due" | wc -l | tr -d ' ')
today_n=$(awk -F'\t' -v t="$today" '$1 == t' <<<"$due" | wc -l | tr -d ' ')
summary=""
[ "$today_n" -gt 0 ] && summary="$today_n due today"
[ "$overdue" -gt 0 ] && summary="${summary:+$summary, }$overdue overdue"

awk -F'\t' -v t="$today" '{ print ($1 < t ? "Overdue since " $1 : "Due today") ": " $2 }' <<<"$due"

[ "${1:-}" = --print ] && exit 0
first=$(head -n 1 <<<"$due" | cut -f2)
more=$(( $(wc -l <<<"$due") - 1 ))
message="$first"
[ "$more" -gt 0 ] && message="$message, and $more more"
kb_notify "Tasks: $summary" "$message"
