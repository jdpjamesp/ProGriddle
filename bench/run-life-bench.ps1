<#
.SYNOPSIS
    Phase 7 performance check: the real Life engines on a 500 x 500 board for 100 generations.
.DESCRIPTION
    Runs bench/life-bench.p once for each case in its own _progres process, so every case starts
    clean, and prints a table. The results are also written to build/bench-life.txt. A case that
    runs longer than -TimeoutSec is stopped and reported as a timeout. This is a measurement, not
    a pass or fail check: the numbers depend on the machine.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$Side = 500,
    [int]$Gens = 100,
    [int]$TimeoutSec = 900
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $root 'tools\progress-temp.ps1')
New-Item -ItemType Directory -Force 'build' | Out-Null

# the cases: engine, how much of the board starts alive
$cases = @(
    @('dense', '0.30'),
    @('dense', '0.10'),
    @('dense', '0.03'),
    @('sparse', '0.03'),
    @('sparse', '0.01'),
    @('sparse', '0.003')
)

$rows = @()
foreach ($c in $cases) {
    $mode = $c[0]; $dens = $c[1]
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $Dlc 'bin\_progres.exe'
    $psi.Arguments = "-b -T `"$(Get-ProgressTempDir)`" -p tools/launch.p -param `"bench/life-bench.p,$mode,$Side,$dens,$Gens`""
    $psi.WorkingDirectory = $root
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    Write-Host "running $mode at $dens of a $Side x $Side board for $Gens generations ..."
    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync()
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        $p.Kill()
        $rows += [pscustomobject]@{ Engine = $mode; Start = $dens; Result = "stopped after $TimeoutSec s" }
        continue
    }
    $line = ($out.Result -split "`r?`n" | Where-Object { $_ -match "^$mode " } | Select-Object -Last 1)
    if (-not $line) { $rows += [pscustomobject]@{ Engine = $mode; Start = $dens; Result = 'no result' }; continue }
    $f = $line -split ' '
    $rows += [pscustomobject]@{
        Engine = $f[0]; Start = $f[2]; Generations = [int]$f[3]; BuildMs = [int]$f[4]; RunMs = [int]$f[5]
        MsPerGeneration = [int]$f[6]; AliveAtStart = [int]$f[7]; AliveAtEnd = [int]$f[8]
    }
}

$table = $rows | Format-Table -AutoSize | Out-String
Write-Host $table
$table | Set-Content 'build/bench-life.txt' -Encoding ascii
