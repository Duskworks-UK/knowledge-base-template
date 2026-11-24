# Shared helpers for the Windows automation. Dot-source it; don't run it.
# The automation itself is the bash scripts in automation/, run with Git Bash
# from Git for Windows. These PowerShell files only schedule and start them.
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads UTF-8 without a BOM.

$ErrorActionPreference = 'Stop'

$KbRepo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$KbInbox = Join-Path $KbRepo 'wiki\inbox'

# A readable name for this knowledge base: its folder name plus a hash of its
# full path, so two knowledge bases in folders with the same name stay apart.
function Get-KbName {
    $leaf = (Split-Path $KbRepo -Leaf) -replace '[^A-Za-z0-9.-]', '-'
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($KbRepo))
    $hash = -join ($bytes[0..3] | ForEach-Object { $_.ToString('x2') })
    return "$($leaf.TrimEnd('-'))-$hash"
}

function Get-KbLog {
    return Join-Path $env:LOCALAPPDATA "knowledge-base\$(Get-KbName).log"
}

# Git Bash: the path Claude Code is told to use, then next to git.exe, then
# the default install folder.
function Find-KbBash {
    $candidates = @()
    if ($env:CLAUDE_CODE_GIT_BASH_PATH) { $candidates += $env:CLAUDE_CODE_GIT_BASH_PATH }
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        $gitDir = Split-Path (Split-Path $git.Source -Parent) -Parent
        $candidates += (Join-Path $gitDir 'bin\bash.exe')
        $candidates += (Join-Path (Split-Path $gitDir -Parent) 'bin\bash.exe')
    }
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Git\bin\bash.exe') }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return $c }
    }
    return $null
}

# Is anything waiting in the inbox? Checked here so bash only starts when needed.
function Test-KbPending {
    if (-not (Test-Path -LiteralPath $KbInbox)) { return $false }
    $items = Get-ChildItem -LiteralPath $KbInbox -File -Force |
        Where-Object { -not $_.Name.StartsWith('.') }
    return [bool]$items
}

# Run one of the bash scripts in automation/, appending its output to the log.
function Invoke-KbScript([string]$Script) {
    $bash = Find-KbBash
    if (-not $bash) { throw 'Git Bash was not found. Install Git for Windows, or set CLAUDE_CODE_GIT_BASH_PATH.' }
    $runner = (Join-Path $PSScriptRoot 'run-logged.sh') -replace '\\', '/'
    $target = (Join-Path $KbRepo "automation\$Script") -replace '\\', '/'
    $log = (Get-KbLog) -replace '\\', '/'
    & $bash $runner $target $log
    return $LASTEXITCODE
}
