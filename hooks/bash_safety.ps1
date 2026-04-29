<#
.SYNOPSIS
PreToolUse hook - Block dangerous Bash patterns before execution.

Reads stdin JSON (Claude Code standard).
Loads patterns from hooks/lib/bash_patterns.json (L4_block only).
Returns {"decision":"block","reason":"..."} on match, {"decision":"continue"} otherwise.
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PatternsPath = Join-Path $ScriptDir "lib\bash_patterns.json"

$inputJson = [Console]::In.ReadToEnd()

try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    Write-Output '{"decision":"continue"}'
    exit 0
}

if (-not $data -or $data.tool_name -ne "Bash") {
    Write-Output '{"decision":"continue"}'
    exit 0
}

$command = $data.tool_input.command
if (-not $command) {
    Write-Output '{"decision":"continue"}'
    exit 0
}

# Load patterns
$patterns = @()
if (Test-Path $PatternsPath) {
    try {
        $cfg = Get-Content $PatternsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $patterns = $cfg.L4_block
    } catch {
        $patterns = @()
    }
}

foreach ($entry in $patterns) {
    $pattern = $entry.pattern
    $reason = $entry.reason
    if (-not $pattern) { continue }

    try {
        if ($command -match $pattern) {
            $msg = "[bash_safety L4 block] $reason`n- pattern: $pattern`n- command: $command`nIf intentional, confirm with user and split or rewrite the command."
            $response = [ordered]@{
                decision = "block"
                reason   = $msg
            }
            Write-Output ($response | ConvertTo-Json -Compress)
            exit 0
        }
    } catch {
        continue
    }
}

Write-Output '{"decision":"continue"}'
