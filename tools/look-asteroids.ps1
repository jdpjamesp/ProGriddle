<#
.SYNOPSIS
    Launches the Asteroids window with a fixed seed and saves a screenshot of the title screen.
.DESCRIPTION
    Uses a throwaway settings file, so the real saved window position is left alone. It sends no keys, but it
    brings the window to the front and copies the screen, so do not touch the keyboard or mouse for about
    ten seconds. It waits until the title has been traced and the hint lines are in (about five seconds at
    the starting speed). The picture goes to build/screenshots/<Name>.png.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$Seed = 5,
    [string]$Name = 'ast-title-fresh'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $PSScriptRoot 'progress-temp.ps1')
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null
$settingsFile = Join-Path $root 'build\look-asteroids-settings.json'
Remove-Item $settingsFile -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

$args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-asteroids.p,$settingsFile,60,$Seed`"")
$p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
$deadline = (Get-Date).AddSeconds(25)
do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Asteroids*' -or (Get-Date) -gt $deadline -or $p.HasExited)
if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Asteroids*') { throw 'The Asteroids window did not appear.' }
Start-Sleep -Milliseconds 5500
$script:target = $p
Ensure-Foreground
$bmp = Take-Shot $p $Name
Write-Host "Saved $shots\$Name.png ($($bmp.Width) x $($bmp.Height)), title: $($p.MainWindowTitle)"
$bmp.Dispose()
[void](Close-Window $p)
