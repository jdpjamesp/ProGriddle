<#
.SYNOPSIS
    Runs one Phase 0 storage benchmark case in its own _progres process and
    reports the result line plus peak working set in MB.
.EXAMPLE
    ./bench/run-bench.ps1 -Mode mem -Width 1000 -Height 1000 -Density 0.1 -Gens 3
#>
param(
    [Parameter(Mandatory)][ValidateSet('ext', 'extf', 'mem', 'memf', 'tt', 'sparse', 'rowclear')][string]$Mode,
    [int]$Width = 100,
    [int]$Height = 100,
    [double]$Density = 0.1,
    [int]$Gens = 10,
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$TimeoutSec = 600
)

$root = Split-Path -Parent $PSScriptRoot
$env:DLC = $Dlc
$d = $Density.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = Join-Path $Dlc 'bin\_progres.exe'
$psi.Arguments = "-b -p bench/phase0-storage.p -param `"$Mode,$Width,$Height,$d,$Gens`""
$psi.WorkingDirectory = $root
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$outTask = $p.StandardOutput.ReadToEndAsync()
$errTask = $p.StandardError.ReadToEndAsync()
$peak = 0
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while (-not $p.HasExited) {
    try { $p.Refresh(); if ($p.WorkingSet64 -gt $peak) { $peak = $p.WorkingSet64 } } catch {}
    if ($sw.Elapsed.TotalSeconds -gt $TimeoutSec) { $p.Kill(); Write-Output "TIMEOUT after $TimeoutSec s"; break }
    Start-Sleep -Milliseconds 25
}
$p.WaitForExit()
$text = ($outTask.Result + $errTask.Result).Trim()
Write-Output ("{0} peak_mb={1:N0}" -f $text, ($peak / 1MB))
