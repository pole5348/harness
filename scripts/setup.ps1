<#
.SYNOPSIS
Link the harness repo to ~/.claude/ on Windows.

Directories use junction, files use hardlink (same volume required).
Runs without admin privileges.

.EXAMPLE
PS> cd <harness repo path>
PS> powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
#>
[CmdletBinding()]
param(
    [string]$HarnessRoot
)

$ErrorActionPreference = "Stop"

# Resolve harness root robustly across invocation styles
if (-not $HarnessRoot) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }
    if ($scriptPath) {
        $HarnessRoot = (Resolve-Path (Join-Path (Split-Path -Parent $scriptPath) "..")).Path
    }
}

if (-not $HarnessRoot -or -not (Test-Path (Join-Path $HarnessRoot "CLAUDE.md"))) {
    Write-Host "[error] Cannot determine harness root. Pass -HarnessRoot explicitly." -ForegroundColor Red
    Write-Host "Usage: powershell -ExecutionPolicy Bypass -File <path>\scripts\setup.ps1 -HarnessRoot <harness-repo-path>"
    exit 1
}

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "=== Linking harness to ~/.claude/ ===" -ForegroundColor Cyan
Write-Host "Harness Root: $HarnessRoot"
Write-Host "Claude Dir  : $ClaudeDir"
Write-Host ""

# 1. Ensure ~/.claude/ and subdirectories exist
$dirs = @(
    $ClaudeDir,
    (Join-Path $ClaudeDir "commands"),
    (Join-Path $ClaudeDir "hooks")
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "[mkdir] $d"
    }
}

# 2. Directory junctions
$junctions = @(
    @{ Link = (Join-Path $ClaudeDir "commands\harness");      Target = (Join-Path $HarnessRoot "commands\harness") },
    @{ Link = (Join-Path $ClaudeDir "commands\teacher"); Target = (Join-Path $HarnessRoot "commands\teacher") },
    @{ Link = (Join-Path $ClaudeDir "_harness");          Target = (Join-Path $HarnessRoot "_harness") },
    @{ Link = (Join-Path $ClaudeDir "rules");             Target = (Join-Path $HarnessRoot "rules") },
    @{ Link = (Join-Path $ClaudeDir "hooks\lib");        Target = (Join-Path $HarnessRoot "hooks\lib") }
)

foreach ($j in $junctions) {
    if (Test-Path $j.Link) {
        Write-Host "[skip] junction exists: $($j.Link)"
        continue
    }
    if (-not (Test-Path $j.Target)) {
        Write-Host "[warn] target missing: $($j.Target)" -ForegroundColor Yellow
        continue
    }
    cmd /c mklink /J "`"$($j.Link)`"" "`"$($j.Target)`"" | Out-Null
    Write-Host "[link] $($j.Link) -> $($j.Target)" -ForegroundColor Green
}

# 3. File hardlinks (same volume only)
$hardlinks = @(
    @{ Link = (Join-Path $ClaudeDir "CLAUDE.md");                  Target = (Join-Path $HarnessRoot "CLAUDE.md") },
    @{ Link = (Join-Path $ClaudeDir "hooks\model_switch.ps1");     Target = (Join-Path $HarnessRoot "hooks\model_switch.ps1") },
    @{ Link = (Join-Path $ClaudeDir "hooks\bash_safety.ps1");      Target = (Join-Path $HarnessRoot "hooks\bash_safety.ps1") },
    @{ Link = (Join-Path $ClaudeDir "hooks\stop_validate.ps1");    Target = (Join-Path $HarnessRoot "hooks\stop_validate.ps1") }
)

foreach ($h in $hardlinks) {
    if (Test-Path $h.Link) {
        Write-Host "[skip] hardlink exists: $($h.Link)"
        continue
    }
    if (-not (Test-Path $h.Target)) {
        Write-Host "[warn] target missing: $($h.Target)" -ForegroundColor Yellow
        continue
    }
    cmd /c mklink /H "`"$($h.Link)`"" "`"$($h.Target)`"" | Out-Null
    Write-Host "[link] $($h.Link) -> $($h.Target)" -ForegroundColor Green
}

# 4. settings.json hook registration (idempotent via static template)
# Note: PS 5.1 ConvertTo-Json flattens single-element arrays — unfit for hooks shape.
# We instead write a known-good JSON template if any required hook is missing.
$settingsPath = Join-Path $ClaudeDir "settings.json"

$psHooksAvailable = @{
    model_switch    = (Test-Path (Join-Path $ClaudeDir "hooks\model_switch.ps1"))
    bash_safety     = (Test-Path (Join-Path $ClaudeDir "hooks\bash_safety.ps1"))
    stop_validate   = (Test-Path (Join-Path $ClaudeDir "hooks\stop_validate.ps1"))
}

# Read raw JSON for idempotency check (string-level, not parsed)
$settingsRaw = ""
if (Test-Path $settingsPath) {
    $settingsRaw = Get-Content $settingsPath -Raw -Encoding UTF8
}

$needsUpdate = $false
foreach ($key in $psHooksAvailable.Keys) {
    if ($psHooksAvailable[$key] -and -not ($settingsRaw -match "$key\.ps1")) {
        $needsUpdate = $true
        break
    }
}

# Also detect malformed shape (single object instead of array under hooks events)
if (-not $needsUpdate -and $settingsRaw -match '"UserPromptSubmit"\s*:\s*\{') {
    $needsUpdate = $true
    Write-Host "[fix] settings.json hook events are flattened — rebuilding" -ForegroundColor Yellow
}

if ($needsUpdate) {
    # Preserve existing model field if present (other top-level fields may be lost — we warn user)
    $existingModel = "claude-opus-4-7"
    if ($settingsRaw -match '"model"\s*:\s*"([^"]+)"') {
        $existingModel = $Matches[1]
    }

    # JSON escape: backslash -> \\ for paths inside JSON strings
    $cdEsc = $ClaudeDir.Replace("\", "\\")

    function New-HookCmdString {
        param([string]$ScriptName, [string]$ClaudeDirEsc)
        # Path may contain spaces/Korean — wrap in JSON-escaped double quotes (\")
        return "powershell -NonInteractive -ExecutionPolicy Bypass -File \`"$ClaudeDirEsc\\hooks\\$ScriptName\`""
    }

    $hookBlocks = @()
    if ($psHooksAvailable["model_switch"]) {
        $cmd = New-HookCmdString -ScriptName "model_switch.ps1" -ClaudeDirEsc $cdEsc
        $hookBlocks += @"
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "$cmd" }
        ]
      }
    ]
"@
    }
    if ($psHooksAvailable["bash_safety"]) {
        $cmd = New-HookCmdString -ScriptName "bash_safety.ps1" -ClaudeDirEsc $cdEsc
        $hookBlocks += @"
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$cmd" }
        ]
      }
    ]
"@
    }
    if ($psHooksAvailable["stop_validate"]) {
        $cmd = New-HookCmdString -ScriptName "stop_validate.ps1" -ClaudeDirEsc $cdEsc
        $hookBlocks += @"
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "$cmd" }
        ]
      }
    ]
"@
    }

    $hooksSection = $hookBlocks -join ",`n"
    $settingsContent = @"
{
  "model": "$existingModel",
  "hooks": {
$hooksSection
  }
}
"@
    # Backup existing if present
    if ($settingsRaw) {
        $backup = "$settingsPath.bak"
        Set-Content $backup -Value $settingsRaw -Encoding UTF8
        Write-Host "[backup] $backup" -ForegroundColor Yellow
    }
    Set-Content $settingsPath -Value $settingsContent -Encoding UTF8
    Write-Host "[update] settings.json rewritten with all available hooks" -ForegroundColor Green
} else {
    Write-Host "[skip] settings.json already has all hooks registered"
}

Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
$checks = @(
    @{ Label = "CLAUDE.md";                                   Path = (Join-Path $ClaudeDir "CLAUDE.md") },
    @{ Label = "commands/harness/plan.md";                    Path = (Join-Path $ClaudeDir "commands\harness\plan.md") },
    @{ Label = "commands/harness/auto.md";                    Path = (Join-Path $ClaudeDir "commands\harness\auto.md") },
    @{ Label = "_harness/security_engineer/docs/templates/ADR.md"; Path = (Join-Path $ClaudeDir "_harness\security_engineer\docs\templates\ADR.md") },
    @{ Label = "hooks/bash_safety.ps1";                       Path = (Join-Path $ClaudeDir "hooks\bash_safety.ps1") },
    @{ Label = "hooks/stop_validate.ps1";                     Path = (Join-Path $ClaudeDir "hooks\stop_validate.ps1") },
    @{ Label = "_harness/security_engineer/01_plan.md";       Path = (Join-Path $ClaudeDir "_harness\security_engineer\01_plan.md") },
    @{ Label = "rules/common/karpathy_guidelines.md";         Path = (Join-Path $ClaudeDir "rules\common\karpathy_guidelines.md") },
    @{ Label = "hooks/model_switch.ps1";                      Path = (Join-Path $ClaudeDir "hooks\model_switch.ps1") }
)
foreach ($c in $checks) {
    $exists = Test-Path $c.Path
    $tag = if ($exists) { "[ok]  " } else { "[fail]" }
    Write-Host "$tag ~/.claude/$($c.Label)"
}

Write-Host ""
Write-Host "Done. Open a new Claude Code session and try /harness:plan." -ForegroundColor Cyan
