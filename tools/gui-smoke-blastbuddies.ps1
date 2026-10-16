<#
.SYNOPSIS
    Drives the real Blast Buddies window like a player and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-blastbuddies.p under prowin with a throwaway settings file and a fixed seed, then
    checks: the title screen shows (the gradient name in the colours of BuddiesLook, "Press Space to play" in
    the title bar), Space starts the match and the buddies arrive (the parachutes are orange and white), the
    first turn is announced in the title bar with the wind and the clock, a held Right key and a held Space
    key then a release fire a rocket (its white body is on the screen), P pauses so the picture freezes and
    P runs it again, R goes back to the title, and the window saves its own size under blastbuddies.window.*.
    Screenshots go to build/screenshots.

    It sends real keystrokes to the foreground window, so do not touch the keyboard or mouse while it
    runs (about a minute). Exit code 0 when every check passes.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$Seed = 5
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $PSScriptRoot 'progress-temp.ps1')
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null
$settingsFile = Join-Path $root 'build\smoke-blastbuddies-settings.json'
Remove-Item $settingsFile -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

# a key that stays down for as long as the test wants, which SendKeys cannot do
Add-Type @'
using System; using System.Runtime.InteropServices;
public class HeldKey {
  [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  public static void Down(byte vk) { keybd_event(vk, 0, 0, UIntPtr.Zero); }
  public static void Up(byte vk) { keybd_event(vk, 0, 2, UIntPtr.Zero); }
}
'@
$VK_RIGHT = 0x27; $VK_SPACE = 0x20

# the colours of BuddiesLook that the checks look for
$TITLETOP = @(0xFF, 0xF2, 0xA0)
$CHUTE    = @(0xFF, 0x8A, 0x1E)
$ROCKET   = @(0xF4, 0xF4, 0xF0)
$ACCENT   = @(0xFF, 0x9A, 0x3C)

function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-blastbuddies.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-blastbuddies-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Blast Buddies*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Blast Buddies*') { throw 'The Blast Buddies window did not appear.' }
    Start-Sleep -Milliseconds 800
    $script:target = $p
    Ensure-Foreground
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }

function Get-Box($bmp, $rgb, [int]$tol = 6) {
    $b = [Native]::FindColour($bmp, $rgb[0], $rgb[1], $rgb[2], $tol)
    if ($b[0] -lt 0) { return $null }
    return $b
}

function Get-Picture($p, [string]$name) {
    $bmp = Take-Shot $p $name
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash($ms.ToArray()))
    $ms.Dispose()
    return $hash
}

function Hold-Key([byte]$vk, [int]$ms) {
    Ensure-Foreground
    [HeldKey]::Down($vk)
    Start-Sleep -Milliseconds $ms
    [HeldKey]::Up($vk)
    Start-Sleep -Milliseconds 120
}

$proc = $null
try {
    Write-Host '--- run 1'
    $proc = Start-Game
    Check 'the title bar invites you to play' ((Get-Title $proc) -match 'Press Space to play') (Get-Title $proc)
    $bmp = Take-Shot $proc 'smoke-bb-1-title'
    Check 'the gradient name is on the title screen' ($null -ne (Get-Box $bmp $TITLETOP 24)) 'no title colour'
    $bmp.Dispose()

    # Space starts the match and the buddies float down
    Hold-Key $VK_SPACE 120
    Start-Sleep -Milliseconds 900
    Check 'Space starts the match' ((Get-Title $proc) -match 'Here they come') (Get-Title $proc)
    $bmp = Take-Shot $proc 'smoke-bb-2-arrival'
    Check 'a parachute is on the screen' ($null -ne (Get-Box $bmp $CHUTE 24)) 'no parachute colour'
    $bmp.Dispose()

    # five seconds of arrival and the banner, then the first turn
    Start-Sleep -Milliseconds 6500
    Check 'the first turn is under way with the wind and the clock in the title bar' ((Get-Title $proc) -match '\(team 1\)   Wind -?\d+   Time \d+') (Get-Title $proc)

    # walk, then charge and fire
    Hold-Key $VK_RIGHT 300
    Ensure-Foreground
    [HeldKey]::Down($VK_SPACE)
    Start-Sleep -Milliseconds 600
    Check 'holding Space builds power' ((Get-Title $proc) -notmatch 'Power 0%') (Get-Title $proc)
    [HeldKey]::Up($VK_SPACE)
    Start-Sleep -Milliseconds 250
    $bmp = Take-Shot $proc 'smoke-bb-3-rocket'
    Check 'letting go fires a rocket' ($null -ne (Get-Box $bmp $ROCKET 8)) 'no rocket colour'
    $bmp.Dispose()

    # P pauses: nothing moves, and P runs it again
    Send-Keys 'p'
    $frozen = Get-Picture $proc 'smoke-bb-4-paused'
    Start-Sleep -Milliseconds 800
    Check 'P pauses: while paused nothing moves' ((Get-Picture $proc 'smoke-bb-4b-paused') -eq $frozen)
    $bmp = Take-Shot $proc 'smoke-bb-4c-band'
    Check 'a paused game shows its band' ($null -ne (Get-Box $bmp $ACCENT 8)) 'no accent colour'
    $bmp.Dispose()
    Send-Keys 'p'
    Start-Sleep -Milliseconds 800

    # R goes back to the title
    Send-Keys 'r'
    Start-Sleep -Milliseconds 600
    Check 'R starts again at the title' ((Get-Title $proc) -match 'Press Space to play') (Get-Title $proc)

    $closed = Close-Window $proc
    Check 'the window closes by itself' $closed
    $proc = $null
    $saved = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Check 'the window size is saved under blastbuddies.window' ($null -ne $saved.values.'blastbuddies.window.width' -and $null -ne $saved.values.'blastbuddies.window.height') 'keys missing'
}
catch {
    Write-Host "ERROR  $($_.Exception.Message)" -ForegroundColor Red
    $script:failures++
}
finally {
    [HeldKey]::Up($VK_SPACE); [HeldKey]::Up($VK_RIGHT)
    if ($null -ne $proc -and -not $proc.HasExited) { $proc.Kill() }
}

if ($script:failures -gt 0) { Write-Host "$script:failures check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All checks passed'
exit 0
