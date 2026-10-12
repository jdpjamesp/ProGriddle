<#
.SYNOPSIS
    Runs the ABLUnit tests in batch mode (_progres -b).
.PARAMETER Filter
    Optional wildcard on test class file names, for example "Grid*".
.PARAMETER Dlc
    OpenEdge install directory. Defaults to $env:DLC, then C:\Progress\OpenEdge.
#>
param(
    [string]$Filter = '*Tests.cls',
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:DLC = $Dlc
$progres = Join-Path $Dlc 'bin\_progres.exe'
if (-not (Test-Path $progres)) { throw "_progres.exe not found at $progres" }

$testRoot = Join-Path $root 'tests'
$classes = Get-ChildItem $testRoot -Recurse -Filter $Filter -File |
    ForEach-Object { $_.FullName.Substring($testRoot.Length + 1).Replace('\', '/') }
if (-not $classes) { Write-Host 'No test classes found.'; exit 0 }

$out = Join-Path $root 'build\test-results'
New-Item -ItemType Directory -Force $out | Out-Null

$cfg = @{
    tests   = @($classes | ForEach-Object { @{ test = $_ } })
    options = @{
        output           = @{ location = 'build/test-results'; format = 'xml' }
        quitOnEnd        = $true
        writeLog         = $true
        showErrorMessage = $true
        throwError       = $true
    }
}
$cfgFile = Join-Path $root 'build\ablunit.json'
$cfg | ConvertTo-Json -Depth 5 | Set-Content $cfgFile -Encoding ascii

$resultsFile = Join-Path $out 'results.xml'
Remove-Item $resultsFile -ErrorAction SilentlyContinue

& $progres -b -p tools/run-tests.p -param "CFG=build/ablunit.json"
$code = $LASTEXITCODE

# ABLUnit returns exit code 0 even when tests fail, so judge by the results file.
if (-not (Test-Path $resultsFile)) {
    Write-Host "No results file written (_progres exit code $code)."
    exit 2
}
$suites = ([xml](Get-Content $resultsFile -Raw)).testsuites
Write-Host ("Tests: {0}, failures: {1}, errors: {2}. Results: build/test-results/results.xml" -f $suites.tests, $suites.failures, $suites.errors)
if ($code -ne 0 -or [int]$suites.failures -gt 0 -or [int]$suites.errors -gt 0) { exit 1 }
exit 0
