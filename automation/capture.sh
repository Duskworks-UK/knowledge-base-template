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

stamp=$(date '+%Y-%m-%d-%H%M%S')
dest="$KB_INBOX/$stamp-capture.md"
n=1
while [ -e "$dest" ]; do n=$((n + 1)); dest="$KB_INBOX/$stamp-capture-$n.md"; done

# Write under a hidden name first, so the filer never sees half a note.
tmp="$KB_INBOX/.$(basename "$dest").tmp"
{
  echo "# Quick capture"
  echo
  echo "Captured: $(date '+%Y-%m-%d %H:%M %Z') ($(date '+%A'))"
  echo
  printf '%s\n' "$text"
} >"$tmp"
mv "$tmp" "$dest"
echo "Captured to wiki/inbox/$(basename "$dest")"
