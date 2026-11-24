#!/bin/bash
# Shared helpers for the automation scripts. Source it; don't run it.
#
# Settings come from this clone's automation config, which install.sh writes to
# .git/kb-automation.conf (one per clone, never committed). Environment
# variables of the same name override it:
#   KB_COMMIT=1   commit wiki changes after automated runs and assistant replies
#   KB_PUSH=1     push after each commit
#   KB_BRIEF=1    write a morning brief with Claude (reminders run either way)
# With no config, nothing is committed or pushed.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

KB_REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
KB_WIKI="$KB_REPO/wiki"
KB_INBOX="$KB_WIKI/inbox"

kb_log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

kb_is_git() { git -C "$KB_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# Where per-clone state lives: inside .git when there is one.
kb_state_path() {
  if kb_is_git; then
    git -C "$KB_REPO" rev-parse --path-format=absolute --git-path "$1"
  else
    echo "$KB_REPO/.$1"
  fi
}

kb_load_config() {
  local conf line key value
  conf=$(kb_state_path kb-automation.conf)
  local commit=0 push=0 brief=0
  if [ -f "$conf" ]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^(KB_COMMIT|KB_PUSH|KB_BRIEF)=([01])$ ]] || continue
      key=${BASH_REMATCH[1]} value=${BASH_REMATCH[2]}
      case "$key" in
        KB_COMMIT) commit=$value ;;
        KB_PUSH) push=$value ;;
        KB_BRIEF) brief=$value ;;
      esac
    done <"$conf"
  fi
  KB_COMMIT=${KB_COMMIT:-$commit}
  KB_PUSH=${KB_PUSH:-$push}
  KB_BRIEF=${KB_BRIEF:-$brief}
}

# kb_lock NAME: take a lock or return 1 if another run holds it. Locks older
# than an hour are from runs that died. Released when the script exits.
kb_lock() {
  KB_LOCK=$(kb_state_path "$1.lock")
  [ -n "$(find "$KB_LOCK" -maxdepth 0 -mmin +60 2>/dev/null)" ] && rmdir "$KB_LOCK" 2>/dev/null
  mkdir "$KB_LOCK" 2>/dev/null || return 1
  trap 'rmdir "$KB_LOCK" 2>/dev/null' EXIT
}

# What automatic commits cover: wiki/, but never the inbox, even if inbox
# files were tracked before the inbox was ignored.
KB_COMMIT_PATHS=(wiki ':(exclude)wiki/inbox')

# kb_commit MESSAGE: commit changes under wiki/ (and push) if turned on.
kb_commit() {
  [ "$KB_COMMIT" = 1 ] || return 0
  kb_is_git || return 0
  local state lock
  for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
    [ -e "$(git -C "$KB_REPO" rev-parse --git-path "$state")" ] && { kb_log "git is mid-$state, so not committing"; return 0; }
  done
  lock=$(kb_state_path kb-commit.lock)
  [ -n "$(find "$lock" -maxdepth 0 -mmin +2 2>/dev/null)" ] && rmdir "$lock" 2>/dev/null
  mkdir "$lock" 2>/dev/null || return 0
  git -C "$KB_REPO" add -A -- "${KB_COMMIT_PATHS[@]}"
  if git -C "$KB_REPO" diff --cached --quiet -- "${KB_COMMIT_PATHS[@]}"; then
    rmdir "$lock"; return 0
  fi
  if git -C "$KB_REPO" commit -q -m "$1" -- "${KB_COMMIT_PATHS[@]}"; then
    kb_log "committed $(git -C "$KB_REPO" rev-parse --short HEAD): $1"
    if [ "$KB_PUSH" = 1 ]; then
      git -C "$KB_REPO" push -q 2>&1 && kb_log "pushed" || kb_log "push failed"
    fi
  else
    kb_log "commit failed"
  fi
  rmdir "$lock"
}

# kb_notify TITLE MESSAGE: a macOS notification, if possible.
kb_notify() {
  [ "${KB_NOTIFY:-1}" = 1 ] || return 0
  command -v osascript >/dev/null || return 0
  osascript -e 'on run argv' -e 'display notification (item 2 of argv) with title (item 1 of argv)' -e 'end run' "$1" "$2" >/dev/null 2>&1 || true
}

# Tools the headless agents may use: edits inside this repository, plus a few
# file commands. acceptEdits keeps Edit and Write inside the working directory.
KB_AGENT_TOOLS=("Read" "Edit" "Write" "Glob" "Grep" "Bash(ls:*)" "Bash(mv:*)" "Bash(mkdir:*)" "Bash(shasum:*)" "Bash(date:*)")
