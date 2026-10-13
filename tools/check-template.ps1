<#
.SYNOPSIS
    Checks that the game template still works: it makes a game from it, runs that game's tests,
    and removes it again.
.DESCRIPTION
    The template in templates/game is only text until someone uses it, so it can fall behind the
    framework without anything noticing. This writes a game called TemplateCheck with
    tools/new-game.ps1, runs its tests with tools/run-tests.ps1 (which compiles it), checks that
    its run file has a Cookoff line and that the layering check still passes, then deletes every
    file it made, whether or not the checks passed. Exit code 0 when all of that holds.
.NOTES
    Run it after changing anything in templates/game, tools/new-game.ps1, or the framework
    interfaces a game implements (IGame, ISteppableGame, IGameInput and the controllers).
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc

$name = 'TemplateCheck'
$made = @(
    "src/ProGriddle/Games/$name",
    "tests/ProGriddle/Games/$name",
    'run/run-templatecheck.p',
    'docs/games/templatecheck.md'
)
$failures = 0
function Check([string]$what, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host "PASS  $what" } else { Write-Host "FAIL  $what  $detail" -ForegroundColor Red; $script:failures++ }
}

try {
    $clash = @($made | Where-Object { Test-Path $_ })
    if ($clash.Count -gt 0) { throw "These are in the way, remove them first: $($clash -join ', ')" }

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'new-game.ps1') -Name $name -Title 'Template check' -Blurb 'Made by tools/check-template.ps1.' | Out-Null
    Check 'new-game.ps1 writes the game, its tests, its run file and its page' ((@($made | Where-Object { Test-Path $_ })).Count -eq $made.Count)

    $runFile = Get-Content 'run/run-templatecheck.p' -Raw
    Check 'the run file has its Cookoff line' ($runFile -match '(?m)^\s*Arcade:\s*Template check\s*\|\s*Made by')
    $leftover = @(Get-ChildItem $made -Recurse -File | Where-Object { (Get-Content $_.FullName -Raw) -match '__(Name|name|Title|Blurb)__' })
    Check 'no placeholder is left in any generated file' ($leftover.Count -eq 0) (($leftover | ForEach-Object { $_.Name }) -join ', ')

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-tests.ps1') -Filter "$name*" | Out-Host
    Check 'the generated game compiles and all of its tests pass' ($LASTEXITCODE -eq 0)

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-layering.ps1') | Out-Null
    Check 'the generated game passes the layering check' ($LASTEXITCODE -eq 0)

    # the second call is meant to fail, and a failing native command must not stop this script
    $before = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $again = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'new-game.ps1') -Name $name 2>&1 | Out-String
    $code = $LASTEXITCODE
    $ErrorActionPreference = $before
    Check 'asking for the same game again refuses, and says why' ($code -ne 0 -and $again -match 'exist already')
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $failures++
}
finally {
    foreach ($path in $made) { if (Test-Path $path) { Remove-Item $path -Recurse -Force } }
}

Write-Host ''
if ($failures -eq 0) { Write-Host 'The game template works.' -ForegroundColor Green; exit 0 }
Write-Host "The game template has $failures problem(s)." -ForegroundColor Red
exit 1
