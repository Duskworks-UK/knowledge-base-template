# Turns on the automation for this knowledge base on Windows. Safe to re-run
# to change settings; each run replaces the previous choices. Run it from the
# repository root in PowerShell:
#
#   powershell -ExecutionPolicy Bypass -File automation\windows\install.ps1
#
# Options (combine as needed):
#   -Push              also push each commit
#   -NoCommit          leave committing to you
#   -Brief             also write a morning brief with Claude
#   -RemindAt 07:30    change the morning time (default 08:00)
#   -NoReminders       no morning task at all
#   -Uninstall         turn everything off
#
# It creates up to two scheduled tasks for you in Task Scheduler, in the
# \KnowledgeBase\ folder, and writes this clone's settings to
# .git\kb-automation.conf. It doesn't need administrator rights and doesn't
# change Claude Code's own settings. Needs Git for Windows (for Git Bash).
param(
    [switch]$Push,
    [switch]$NoCommit,
    [switch]$Brief,
    [string]$RemindAt = '08:00',
    [switch]$NoReminders,
    [switch]$Uninstall
)
. (Join-Path $PSScriptRoot 'common.ps1')

$name = Get-KbName
$taskPath = '\KnowledgeBase\'
$filerTask = "$name filer"
$morningTask = "$name morning"

function Remove-KbTask([string]$TaskName) {
    $existing = Get-ScheduledTask -TaskPath $taskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existing) { Unregister-ScheduledTask -TaskPath $taskPath -TaskName $TaskName -Confirm:$false }
}

# Same place lib.sh reads its settings from: inside .git when there is one.
$isGit = $false
$conf = Join-Path $KbRepo '.kb-automation.conf'
if (Get-Command git.exe -ErrorAction SilentlyContinue) {
    $gitPath = & git.exe -C $KbRepo rev-parse --path-format=absolute --git-path kb-automation.conf 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitPath) { $isGit = $true; $conf = $gitPath -replace '/', '\' }
}

if ($Uninstall) {
    Remove-KbTask $filerTask
    Remove-KbTask $morningTask
    if (Test-Path -LiteralPath $conf) { Remove-Item -LiteralPath $conf }
    Write-Output "Automation turned off for $KbRepo."
    exit 0
}

if ($RemindAt -notmatch '^([01][0-9]|2[0-3]):[0-5][0-9]$') { throw '-RemindAt needs a time like 08:00.' }
if ($Push -and $NoCommit) { throw '-Push needs committing on; drop -NoCommit.' }
if ($Brief -and $NoReminders) { throw '-Brief runs with the morning task; drop -NoReminders.' }

$bash = Find-KbBash
if (-not $bash) { throw 'Git Bash was not found. Install Git for Windows (https://git-scm.com/download/win), or set CLAUDE_CODE_GIT_BASH_PATH to bash.exe, then run this again.' }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude Code (claude) isn't on PATH in this window. Filing and the brief need it; reminders don't."
}
if (-not $isGit -and -not $NoCommit) { Write-Output "Note: this folder isn't a Git repository, so nothing will be committed." }

# Older copies may have committed inbox files before the inbox was ignored.
if ($isGit) {
    $tracked = & git.exe -C $KbRepo ls-files -- wiki/inbox | Where-Object { $_ -ne 'wiki/inbox/.gitkeep' }
    if ($tracked) {
        Write-Warning 'Git is tracking files in wiki/inbox, which should stay out of the repository:'
        $tracked | ForEach-Object { Write-Output "  $_" }
        Write-Output 'Automatic commits will leave them out. To stop tracking them while keeping the files, run:'
        Write-Output "  git rm -r --cached -- wiki/inbox; git add wiki/inbox/.gitkeep; git commit -m 'Stop tracking the inbox'"
        Write-Output 'Files committed before stay in the history; if they hold anything private, clean the history before pushing.'
    }
}

# Settings for lib.sh: UTF-8 without a BOM and Unix line endings, so bash reads them.
$commit = if ($NoCommit) { 0 } else { 1 }
$pushOn = if ($Push) { 1 } else { 0 }
$briefOn = if ($Brief) { 1 } else { 0 }
New-Item -ItemType Directory -Force -Path (Split-Path $conf -Parent) | Out-Null
[System.IO.File]::WriteAllText($conf, "KB_COMMIT=$commit`nKB_PUSH=$pushOn`nKB_BRIEF=$briefOn`n", (New-Object System.Text.UTF8Encoding $false))

# conhost --headless runs the task without flashing a window.
$runner = Join-Path $PSScriptRoot 'run.ps1'
function New-KbAction([string]$Script) {
    $arguments = "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$runner`" -Script $Script"
    return New-ScheduledTaskAction -Execute (Join-Path $env:WINDIR 'System32\conhost.exe') -Argument $arguments -WorkingDirectory $KbRepo
}
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1)

# Filing: checks the inbox every minute and returns at once when it's empty.
$everyMinute = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskPath $taskPath -TaskName $filerTask -Action (New-KbAction 'process-inbox.sh') `
    -Trigger $everyMinute -Settings $settings -Force `
    -Description "Files wiki\inbox for the knowledge base in $KbRepo" | Out-Null

if (-not $NoReminders) {
    $at = [datetime]::ParseExact($RemindAt, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
    $daily = New-ScheduledTaskTrigger -Daily -At $at
    Register-ScheduledTask -TaskPath $taskPath -TaskName $morningTask -Action (New-KbAction 'morning.sh') `
        -Trigger $daily -Settings $settings -Force `
        -Description "Morning reminders for the knowledge base in $KbRepo" | Out-Null
} else {
    Remove-KbTask $morningTask
}

function OnOff([int]$Value) { if ($Value -eq 1) { 'on' } else { 'off' } }
Write-Output "Automation is on for $KbRepo"
Write-Output '  Filing the inbox: on (checked every minute)'
Write-Output "  Commit: $(OnOff $commit). Push: $(OnOff $pushOn)."
$morning = if ($NoReminders) { 'off' } else { "at $RemindAt" }
Write-Output "  Morning reminders: $morning. Brief: $(OnOff $briefOn)."
Write-Output "  Log: $(Get-KbLog)"
Write-Output "  Tasks: Task Scheduler > Task Scheduler Library > KnowledgeBase"
