#!/bin/bash
# The morning run, started by launchd at the time chosen in install.sh:
# 1. a notification for tasks due today or overdue (no Claude needed);
# 2. if the brief is turned on, the assistant writes today's brief into the
#    journal, and the wiki is committed if committing is turned on.
set -u
source "$(dirname "$0")/lib.sh"
kb_load_config
cd "$KB_REPO" || exit 1

"$KB_REPO/automation/remind.sh"

[ "$KB_BRIEF" = 1 ] || exit 0
[ -d "$KB_WIKI/journal" ] || { kb_log "no wiki/journal folder, so no brief (is personal mode set up?)"; exit 0; }
command -v claude >/dev/null || { kb_log "claude isn't on PATH, so no brief"; exit 1; }
kb_lock kb-brief || exit 0

today=$(date '+%Y-%m-%d')
kb_log "writing the morning brief for $today"
if KB_COMMIT_MESSAGE="Morning brief for $today" claude -p --agent assistant "Write today's morning brief, following the Morning brief section of your instructions." \
    --permission-mode acceptEdits --allowedTools "${KB_AGENT_TOOLS[@]}" </dev/null >/dev/null; then
  kb_notify "Morning brief" "Today's brief is in journal/$today.md"
else
  kb_log "the assistant exited with an error"
fi
kb_commit "Morning brief for $today"
