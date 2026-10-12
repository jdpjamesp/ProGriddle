<#
.SYNOPSIS
    Runs the ABLUnit tests in batch mode.
.DESCRIPTION
    Tests under tests/**/UI/WinForms need the .NET bridge, so they run under prowin -b.
    Everything else runs under _progres -b. By default only the plain tests run.
      (no switch)  plain tests, results in build/test-results/results.xml
      -Gui         WinForms tests only, results in build/test-results/gui/results.xml
      -All         plain tests, then WinForms tests, exit code 0 only when both pass
.PARAMETER Filter
    Optional wildcard on test class file names, for example "Grid*".
.PARAMETER Dlc
    OpenEdge install directory. Defaults to $env:DLC, then C:\Progress\OpenEdge.
#>
param(
    [string]$Filter = '*Tests.cls',
    [switch]$Gui,
    [switch]$All,
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
$testRoot = Join-Path $root 'tests'
$out = Join-Path $root 'build\test-results'
New-Item -ItemType Directory -Force $out | Out-Null

# Runs one set of test classes with one executable and returns 0 (pass), 1 (failures) or 2 (no results).
function Invoke-Suite([string]$Name, [string[]]$Classes, [string]$Exe, [string[]]$ExeArgs, [string]$ResultsSubDir) {
    if (-not $Classes) { Write-Host "${Name}: no test classes found."; return 0 }

    $cfg = @{
        tests   = @($Classes | ForEach-Object { @{ test = $_ } })
        options = @{
            output           = @{ location = ('build/test-results' + $(if ($ResultsSubDir) { "/$ResultsSubDir" } else { '' })); format = 'xml' }
            quitOnEnd        = $true
            writeLog         = $true
            showErrorMessage = $true
            throwError       = $true
        }
    }
    $tag = $(if ($ResultsSubDir) { $ResultsSubDir } else { 'plain' })
    $cfgFile = Join-Path $root "build\ablunit-$tag.json"
    $cfg | ConvertTo-Json -Depth 5 | Set-Content $cfgFile -Encoding ascii

    $resultsDir = Join-Path $out $ResultsSubDir
    New-Item -ItemType Directory -Force $resultsDir | Out-Null
    $resultsFile = Join-Path $resultsDir 'results.xml'
    Remove-Item $resultsFile -ErrorAction SilentlyContinue

    $logFile = Join-Path $root "build\client-$tag.log"
    Remove-Item $logFile -ErrorAction SilentlyContinue
    $allArgs = $ExeArgs + @('-p', 'tools/run-tests.p', '-param', "CFG=build/ablunit-$tag.json", '-clientlog', "build/client-$tag.log")
    $p = Start-Process -FilePath $Exe -ArgumentList $allArgs -NoNewWindow -Wait -PassThru
    $code = $p.ExitCode

    # ABLUnit returns exit code 0 even when tests fail, so judge by the results file.
    if (-not (Test-Path $resultsFile)) {
        Write-Host "${Name}: no results file written (exit code $code). Client log:"
        if (Test-Path $logFile) {
            Get-Content $logFile | Where-Object { $_ -notmatch 'Logging level set|Log file closed' } | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
        }
        return 2
    }
    $suites = ([xml](Get-Content $resultsFile -Raw)).testsuites
    Write-Host ("{0}: Tests: {1}, failures: {2}, errors: {3}. Results: build/test-results/{4}results.xml" -f $Name, $suites.tests, $suites.failures, $suites.errors, $(if ($ResultsSubDir) { "$ResultsSubDir/" } else { '' }))
    if ($code -ne 0 -or [int]$suites.failures -gt 0 -or [int]$suites.errors -gt 0) { return 1 }
    return 0
}

$everything = Get-ChildItem $testRoot -Recurse -Filter $Filter -File |
    ForEach-Object { $_.FullName.Substring($testRoot.Length + 1).Replace('\', '/') }
$guiClasses = @($everything | Where-Object { $_ -match '/UI/WinForms/' })
$plainClasses = @($everything | Where-Object { $_ -notmatch '/UI/WinForms/' })

$progres = Join-Path $Dlc 'bin\_progres.exe'
$prowin = Join-Path $Dlc 'bin\prowin.exe'
$result = 0

if ($Gui -or $All) {
    if (-not (Test-Path $prowin)) { throw "prowin.exe not found at $prowin" }
}
if (-not $Gui) {
    if (-not (Test-Path $progres)) { throw "_progres.exe not found at $progres" }
    $r = Invoke-Suite 'plain' $plainClasses $progres @('-b') ''
    if ($r -gt $result) { $result = $r }
}
if ($Gui -or $All) {
    $r = Invoke-Suite 'gui' $guiClasses $prowin @('-b') 'gui'
    if ($r -gt $result) { $result = $r }
}
exit $result
