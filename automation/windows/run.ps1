# Started by the scheduled tasks that install.ps1 creates. Runs one of the
# automation scripts with Git Bash, hidden, logging to %LOCALAPPDATA%\knowledge-base.
#   run.ps1 -Script process-inbox.sh    (every minute; returns at once if the inbox is empty)
#   run.ps1 -Script morning.sh          (once a day)
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('process-inbox.sh', 'morning.sh')]
    [string]$Script
)
. (Join-Path $PSScriptRoot 'common.ps1')

if ($Script -eq 'process-inbox.sh' -and -not (Test-KbPending)) { exit 0 }

try {
    exit (Invoke-KbScript $Script)
} catch {
    $log = Get-KbLog
    New-Item -ItemType Directory -Force -Path (Split-Path $log -Parent) | Out-Null
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message
    [System.IO.File]::AppendAllText($log, "$line`n")
    exit 1
}
