#!/bin/bash
# Turns on the automation for this knowledge base on macOS. Safe to re-run to
# change settings; each run replaces the previous choices.
#
#   automation/install.sh                     file the inbox, commit, remind at 08:00
#   automation/install.sh --push              also push each commit
#   automation/install.sh --no-commit         leave committing to you
#   automation/install.sh --brief             also write a morning brief with Claude
#   automation/install.sh --remind-at 07:30   change the morning time
#   automation/install.sh --no-reminders      no morning job at all
#   automation/install.sh --uninstall         turn everything off
#
# It installs up to two launchd jobs, named after this folder and its path, and writes this
# clone's settings to .git/kb-automation.conf. It doesn't change Claude Code's
# own settings.
set -eu

[ "$(uname)" = Darwin ] || { echo "This installer is for macOS (launchd)."; exit 1; }
source "$(dirname "$0")/lib.sh"

# The folder name keeps job names readable; a hash of the full path keeps two
# knowledge bases in folders with the same name apart.
name=$(basename "$KB_REPO" | tr -c 'A-Za-z0-9.-' '-' | sed 's/-*$//')-$(printf '%s' "$KB_REPO" | shasum | cut -c1-8)
agents="$HOME/Library/LaunchAgents"
logfile="$HOME/Library/Logs/knowledge-base-$name.log"
domain="gui/$(id -u)"
filer_label="local.knowledge-base.$name.filer"
morning_label="local.knowledge-base.$name.morning"
conf=$(kb_state_path kb-automation.conf)

unload() {
  launchctl bootout "$domain/$1" 2>/dev/null || true
  rm -f "$agents/$1.plist"
}

commit=1 push=0 brief=0 reminders=1 at=08:00
while [ $# -gt 0 ]; do
  case "$1" in
    --push) push=1 ;;
    --no-commit) commit=0 ;;
    --brief) brief=1 ;;
    --no-reminders) reminders=0 ;;
    --remind-at)
      shift
      [[ "${1:-}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || { echo "--remind-at needs a time like 08:00"; exit 1; }
      at=$1 ;;
    --uninstall)
      unload "$filer_label"; unload "$morning_label"; rm -f "$conf"
      echo "Automation turned off for $KB_REPO."
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done
[ "$push" = 1 ] && [ "$commit" = 0 ] && { echo "--push needs committing on; drop --no-commit."; exit 1; }
[ "$brief" = 1 ] && [ "$reminders" = 0 ] && { echo "--brief runs with the morning job; drop --no-reminders."; exit 1; }
kb_is_git || { [ "$commit" = 0 ] || echo "Note: this folder isn't a Git repository, so nothing will be committed."; }

xml() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<<"$1"; }

# write_plist LABEL SCRIPT TRIGGER_XML
write_plist() {
  local dest="$agents/$1.plist"
  cat >"$dest" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Written by $(xml "$KB_REPO")/automation/install.sh -->
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$1</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$(xml "$KB_REPO/automation/$2")</string>
  </array>
$3
  <key>StandardOutPath</key>
  <string>$(xml "$logfile")</string>
  <key>StandardErrorPath</key>
  <string>$(xml "$logfile")</string>
</dict>
</plist>
EOF
  plutil -lint "$dest" >/dev/null
  launchctl bootout "$domain/$1" 2>/dev/null || true
  launchctl bootstrap "$domain" "$dest"
}

mkdir -p "$agents" "$HOME/Library/Logs"
printf 'KB_COMMIT=%s\nKB_PUSH=%s\nKB_BRIEF=%s\n' "$commit" "$push" "$brief" >"$conf"

write_plist "$filer_label" process-inbox.sh "  <key>WatchPaths</key>
  <array>
    <string>$(xml "$KB_INBOX")</string>
  </array>
  <key>RunAtLoad</key>
  <true/>"

if [ "$reminders" = 1 ]; then
  write_plist "$morning_label" morning.sh "  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$((10#${at%%:*}))</integer>
    <key>Minute</key>
    <integer>$((10#${at##*:}))</integer>
  </dict>"
else
  unload "$morning_label"
fi

onoff() { [ "$1" = 1 ] && echo on || echo off; }
echo "Automation is on for $KB_REPO"
echo "  Filing the inbox: on"
echo "  Commit: $(onoff $commit). Push: $(onoff $push)."
echo "  Morning reminders: $([ $reminders = 1 ] && echo "at $at" || echo off). Brief: $(onoff $brief)."
echo "  Log: $logfile"
