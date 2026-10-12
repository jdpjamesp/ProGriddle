<#
.SYNOPSIS
    Compiles every source file under src and run with prowin -b and lists any errors.
.DESCRIPTION
    Faster feedback than running the tests: one pass shows every compile problem in the
    project, including the WinForms classes that _progres cannot compile. Test classes are
    compiled too unless -SourceOnly is given. Exit code 0 when everything compiles.
.PARAMETER SourceOnly
    Skip tests/.
#>
param(
    [switch]$SourceOnly,
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
New-Item -ItemType Directory -Force 'build' | Out-Null

# PROPATH relative names: classes are named from their folder under src or tests.
$list = New-Object System.Collections.Generic.List[string]
foreach ($area in @('src', 'tests')) {
    if ($SourceOnly -and $area -eq 'tests') { continue }
    $base = Join-Path $root $area
    if (-not (Test-Path $base)) { continue }
    Get-ChildItem $base -Recurse -Include *.cls, *.p -File | ForEach-Object {
        $list.Add($_.FullName.Substring($base.Length + 1).Replace('\', '/'))
    }
}
Get-ChildItem (Join-Path $root 'run') -Filter *.p -File -ErrorAction SilentlyContinue | ForEach-Object { $list.Add('run/' + $_.Name) }
$list | Set-Content 'build/compile-list.txt' -Encoding ascii

Remove-Item 'build/compile-errors.txt' -ErrorAction SilentlyContinue
$prowin = Join-Path $Dlc 'bin\prowin.exe'
$p = Start-Process -FilePath $prowin -ArgumentList @('-b', '-p', 'tools/launch.p', '-param', 'tools/compile.p') -NoNewWindow -Wait -PassThru

if (-not (Test-Path 'build/compile-errors.txt')) {
    Write-Host 'The compile run wrote no report.'
    exit 2
}
$lines = Get-Content 'build/compile-errors.txt'
$problems = @($lines | Where-Object { $_ -notmatch '^SUMMARY' })
$problems | ForEach-Object { Write-Host $_ }
Write-Host ($lines | Where-Object { $_ -match '^SUMMARY' })
if ($problems.Count -gt 0) { exit 1 }
exit 0
