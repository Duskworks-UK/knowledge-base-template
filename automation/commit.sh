#!/bin/bash
# Commits changes under wiki/ (and pushes) if this clone has committing turned
# on. Claude Code runs it after each reply in this repository (the Stop hook in
# .claude/settings.json). Without the automation installed it does nothing.
# Automated runs set KB_COMMIT_MESSAGE so their commits say what they were.
set -u
source "$(dirname "$0")/lib.sh"
kb_load_config
[ -t 0 ] || cat >/dev/null  # the hook's input isn't needed
kb_commit "${KB_COMMIT_MESSAGE:-Update wiki}" >/dev/null
exit 0
