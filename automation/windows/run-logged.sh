#!/bin/bash
# Used by the Windows scheduled tasks (through run.ps1): runs one automation
# script with Git Bash and appends everything it prints to the log.
#   run-logged.sh <script> <log>
script=$1
log=$2
mkdir -p "$(dirname "$log")"
exec bash "$script" >>"$log" 2>&1
