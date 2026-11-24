#!/bin/bash
# Drops a note into wiki/inbox for the filer to sort out.
#
#   automation/capture.sh "Remind me to book the MOT next Friday"
#   echo "Chose the blue tiles for the kitchen" | automation/capture.sh
#
# Works from an Apple Shortcut ("Run Shell Script", input as stdin), Raycast,
# Alfred, or a terminal. The note records when it was captured, so relative
# dates like "next Friday" are read from that moment, not from when it's filed.
set -eu
source "$(dirname "$0")/lib.sh"

if [ $# -gt 0 ]; then text="$*"; else text=$(cat); fi
[ -n "${text//[[:space:]]/}" ] || { echo "Nothing to capture."; exit 1; }

# Write to a hidden temporary file first, so the filer never sees half a note.
tmp=$(mktemp "$KB_INBOX/.capture.XXXXXX")
trap 'rm -f "$tmp"' EXIT
{
  echo "# Quick capture"
  echo
  echo "Captured: $(date '+%Y-%m-%d %H:%M %Z') ($(date '+%A'))"
  echo
  printf '%s\n' "$text"
} >"$tmp"

# Claim a free name atomically: ln fails if the name already exists, so two
# captures in the same second can't take the same name or overwrite each other.
stamp=$(date '+%Y-%m-%d-%H%M%S')
dest="$KB_INBOX/$stamp-capture.md"
n=1
until ln "$tmp" "$dest" 2>/dev/null; do
  n=$((n + 1))
  [ "$n" -le 100 ] || { echo "Couldn't find a free name in wiki/inbox."; exit 1; }
  dest="$KB_INBOX/$stamp-capture-$n.md"
done
echo "Captured to wiki/inbox/$(basename "$dest")"
