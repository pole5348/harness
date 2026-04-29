<#
.SYNOPSIS
Stop hook - Auto-validate project at session end.

Detects project type from CWD markers and runs appropriate validation.
Skips if no git changes since session start. Output goes to stderr (Claude UI).
Always exits 0 (informational, non-blocking).

Detection matrix:
  package.json  -> npm run lint && build && test (--if-present)
  pyproject.toml-> pytest -q (if installed)
  Cargo.toml    -> cargo check && test
  go.mod        -> go build && test
  (none)        -> skip
#>

$ErrorActionPreference = "Continue"

# Discard stdin (Stop hook context not used)
try { [Console]::In.ReadToEnd() | Out-Null } catch {}

$cwd = (Get-Location).Path

function Test-HasGitChanges {
    param([string]$Path)
    if (-not (Test-Path (Join-Path $Path ".git"))) { return $true }
    try {
        $null = & git -C "$Path" diff --quiet 2>$null
        return ($LASTEXITCODE -ne 0)
    } catch {
        return $true
    }
}

function Invoke-Cmd {
    param([string]$Cmd, [string[]]$Args, [string]$Path)
    try {
        $output = & $Cmd @Args 2>&1 | Out-String
        $code = $LASTEXITCODE
        $lines = ($output -split "`r?`n") | Where-Object { $_ -ne "" }
        if ($lines.Count -gt 20) { $lines = $lines[-20..-1] }
        return @{ Code = $code; Output = ($lines -join "`n") }
    } catch {
        return @{ Code = 127; Output = "(command not found or failed: $_)" }
    }
}

if (-not (Test-HasGitChanges -Path $cwd)) {
    Write-Output '{"decision":"continue"}'
    exit 0
}

$results = @()

if (Test-Path (Join-Path $cwd "package.json")) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $stages = @(
            @{ Label = "npm lint";  Args = @("run", "lint", "--if-present", "--silent") },
            @{ Label = "npm build"; Args = @("run", "build", "--if-present", "--silent") },
            @{ Label = "npm test";  Args = @("test", "--if-present", "--silent") }
        )
        foreach ($s in $stages) {
            $r = Invoke-Cmd -Cmd "npm" -Args $s.Args -Path $cwd
            $results += [PSCustomObject]@{ Label = $s.Label; Code = $r.Code; Output = $r.Output }
            if ($r.Code -ne 0) { break }
        }
    }
} elseif (Test-Path (Join-Path $cwd "pyproject.toml")) {
    if (Get-Command pytest -ErrorAction SilentlyContinue) {
        $r = Invoke-Cmd -Cmd "pytest" -Args @("-q") -Path $cwd
        $results += [PSCustomObject]@{ Label = "pytest"; Code = $r.Code; Output = $r.Output }
    }
} elseif (Test-Path (Join-Path $cwd "Cargo.toml")) {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        $r = Invoke-Cmd -Cmd "cargo" -Args @("check", "--quiet") -Path $cwd
        $results += [PSCustomObject]@{ Label = "cargo check"; Code = $r.Code; Output = $r.Output }
        if ($r.Code -eq 0) {
            $r2 = Invoke-Cmd -Cmd "cargo" -Args @("test", "--quiet") -Path $cwd
            $results += [PSCustomObject]@{ Label = "cargo test"; Code = $r2.Code; Output = $r2.Output }
        }
    }
} elseif (Test-Path (Join-Path $cwd "go.mod")) {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $r = Invoke-Cmd -Cmd "go" -Args @("build", "./...") -Path $cwd
        $results += [PSCustomObject]@{ Label = "go build"; Code = $r.Code; Output = $r.Output }
        if ($r.Code -eq 0) {
            $r2 = Invoke-Cmd -Cmd "go" -Args @("test", "./...") -Path $cwd
            $results += [PSCustomObject]@{ Label = "go test"; Code = $r2.Code; Output = $r2.Output }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Output '{"decision":"continue"}'
    exit 0
}

$lines = @("[stop_validate]")
foreach ($r in $results) {
    $tag = if ($r.Code -eq 0) { "OK  " } else { "FAIL" }
    $lines += "  [$tag] $($r.Label) (exit $($r.Code))"
    if ($r.Code -ne 0 -and $r.Output) {
        $lines += "  --- output (last 20 lines) ---"
        foreach ($ln in ($r.Output -split "`n")) {
            $lines += "    $ln"
        }
    }
}

# Output to stderr -> Claude UI
[Console]::Error.WriteLine(($lines -join "`n"))

Write-Output '{"decision":"continue"}'
