#!/bin/bash
# Runs the filer agent (.claude/agents/filer.md) headless with Claude Code when
# something is waiting in wiki/inbox, then commits the wiki if turned on.
#
# launchd runs this whenever the inbox changes (see automation/install.sh). You
# can also run it by hand: automation/process-inbox.sh
# KB_WAIT sets how many seconds to let a note finish being written (default 15).
set -u
source "$(dirname "$0")/lib.sh"
kb_load_config

pending() { find "$KB_INBOX" -maxdepth 1 -type f ! -name '.*' | wc -l | tr -d ' '; }

cd "$KB_REPO" || exit 1
command -v claude >/dev/null || { kb_log "claude isn't on PATH, so nothing was filed"; exit 1; }
kb_lock kb-filer || exit 0

# The filer moving notes out of the inbox also wakes this script; that run stops here.
[ "$(pending)" -gt 0 ] || exit 0
sleep "${KB_WAIT:-15}"

# A second pass catches notes that landed after the filer's last look.
for pass in 1 2; do
  n=$(pending)
  [ "$n" -gt 0 ] || break
  kb_log "filing $n item(s), pass $pass"
  KB_COMMIT_MESSAGE="File inbox items" claude -p --agent filer "File every note in wiki/inbox." \
    --permission-mode acceptEdits --allowedTools "${KB_AGENT_TOOLS[@]}" </dev/null \
    || kb_log "the filer exited with an error"
  [ "$(pending)" -lt "$n" ] || { kb_log "the inbox didn't shrink, so stopping until the next change"; break; }
done

kb_commit "File inbox items"
