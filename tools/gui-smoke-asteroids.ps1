<#
.SYNOPSIS
    Drives the real Asteroids window like a player and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-asteroids.p under prowin with a throwaway settings file and a fixed seed, then
    checks: the title screen shows (the traced title, the rule, the hint lines, the dim rocks behind
    it, "Press Space to play" in the title bar), Space starts a game, the ship and the rocks of
    src/ProGriddle/Games/Asteroids/AsteroidsLook.cls are drawn, a held Left key turns the ship, a held
    Up key puts the flame out behind it, Space fires a shot, P pauses so the picture freezes and
    dims and P runs it again, R starts a new game, and the window saves its position under
    asteroids.window.*. Screenshots go to build/screenshots.

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
$settingsFile = Join-Path $root 'build\smoke-asteroids-settings.json'
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
$VK_LEFT = 0x25; $VK_UP = 0x26; $VK_SPACE = 0x20

# the colours of AsteroidsLook that the checks look for
$SHIP      = @(0xFF, 0xF4, 0xDC)
$FLAME     = @(0xFF, 0xC2, 0x4D)
$SHOT      = @(0xFF, 0xFF, 0xFF)
$ROCK      = @(0x7F, 0x8E, 0xA3)
$TITLE     = @(0xF4, 0xF7, 0xFB)
$RULE      = @(0x1C, 0x2B, 0x44)
$ATTRACT   = @(0x4A, 0x55, 0x66)
$HINT      = @(0x8F, 0xA0, 0xB8)

function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-asteroids.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-asteroids-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Asteroids*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Asteroids*') { throw 'The Asteroids window did not appear.' }
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
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1'
    $proc = Start-Game
    Check 'the title bar invites you to play' ((Get-Title $proc) -match 'Press Space to play') (Get-Title $proc)

    # the title is traced over about two seconds at the starting speed, and the hint lines are in by about four
    Start-Sleep -Milliseconds 5500
    $bmp = Take-Shot $proc 'smoke-ast-1-title'
    $t = Get-Box $bmp $TITLE 6
    Check 'the traced title is on the screen' ($null -ne $t) 'no title colour'
    $rule = Get-Box $bmp $RULE 4
    Check 'the rule under the title is drawn' ($null -ne $rule -and ($rule[2] - $rule[0]) -gt $bmp.Width * 0.5) 'no rule'
    Check 'the dim rocks drift behind the title' ($null -ne (Get-Box $bmp $ATTRACT 4)) 'no attract rock colour'
    Check 'the hint lines are drawn' ($null -ne (Get-Box $bmp $HINT 6)) 'no hint colour'
    $bmp.Dispose()

    # the title waits: a tap of Space starts a game
    Hold-Key $VK_SPACE 120
    Start-Sleep -Milliseconds 400
    Check 'Space starts a game' ((Get-Title $proc) -match 'Score 0   Hi \d+   Ships 3   Wave 1') (Get-Title $proc)

    # the rocks come after half a second and the ship's shield ends after a second and a half more
    Start-Sleep -Milliseconds 3200
    $bmp = Take-Shot $proc 'smoke-ast-2-play'
    $ship0 = Get-Box $bmp $SHIP 6
    Check 'the ship is drawn' ($null -ne $ship0) 'no ship colour'
    Check 'the rocks are drawn' ($null -ne (Get-Box $bmp $ROCK 6)) 'no rock colour'
    $bmp.Dispose()

    # steering: a held Left key turns the ship, so its outline has another shape
    Hold-Key $VK_LEFT 450
    $bmp = Take-Shot $proc 'smoke-ast-3-turned'
    $ship1 = Get-Box $bmp $SHIP 6
    $bmp.Dispose()
    $same = ($null -ne $ship0 -and $null -ne $ship1 -and ($ship0[2] - $ship0[0]) -eq ($ship1[2] - $ship1[0]) -and ($ship0[3] - $ship0[1]) -eq ($ship1[3] - $ship1[1]))
    Check 'a held Left key turns the ship' ($null -ne $ship1 -and -not $same) "from $($ship0 -join ',') to $($ship1 -join ',')"

    # thrust: hold Up and look for the flame straight away
    Ensure-Foreground
    [HeldKey]::Down($VK_UP)
    Start-Sleep -Milliseconds 200
    $bmp = Take-Shot $proc 'smoke-ast-4-thrust'
    [HeldKey]::Up($VK_UP)
    Check 'a held Up key puts the flame out behind the ship' ($null -ne (Get-Box $bmp $FLAME 6)) 'no flame colour'
    $bmp.Dispose()

    # a shot: hold Space and look for it straight away
    Ensure-Foreground
    [HeldKey]::Down($VK_SPACE)
    Start-Sleep -Milliseconds 90
    $bmp = Take-Shot $proc 'smoke-ast-5-shot'
    [HeldKey]::Up($VK_SPACE)
    Check 'Space fires a shot' ($null -ne (Get-Box $bmp $SHOT 8)) 'no shot colour'
    $bmp.Dispose()

    # P pauses: the picture is dimmed and nothing moves, and P runs it again
    Start-Sleep -Milliseconds 1500
    Send-Keys 'p'
    $frozen = Get-Picture $proc 'smoke-ast-6-paused'
    Start-Sleep -Milliseconds 800
    Check 'P pauses: while paused nothing moves' ((Get-Picture $proc 'smoke-ast-6b-paused') -eq $frozen)
    $bmp = Take-Shot $proc 'smoke-ast-6c-dim'
    Check 'the paused picture is dimmed: no ship colour is left' ($null -eq (Get-Box $bmp $SHIP 6)) 'the ship colour is still there'
    $bmp.Dispose()
    Send-Keys 'p'
    Start-Sleep -Milliseconds 800
    Check 'P runs it again' ((Get-Picture $proc 'smoke-ast-6d-running') -ne $frozen)

    # R starts a new game
    Send-Keys 'r'
    Start-Sleep -Milliseconds 600
    Check 'R starts a new game' ((Get-Title $proc) -match 'Score 0   Hi \d+   Ships 3   Wave 1|Press Space to play') (Get-Title $proc)

    # closing saves the window's position
    $closed = Close-Window $proc
    Check 'the window closes by itself' $closed
    $proc = $null
    $saved = Get-Content $settingsFile -Raw | ConvertFrom-Json
    $names = @($saved.values.PSObject.Properties.Name | Where-Object { $_ -like 'asteroids.window.*' })
    Check 'the window position is saved under asteroids.window' ($names.Count -gt 0) 'keys missing'

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: the window fits the screen'
    $proc = Start-Game
    $r1 = Get-WindowRect $proc
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    Check 'the window opens at a size that fits the screen' (($r1.B - $r1.T) -le $wa.Height -and ($r1.R - $r1.L) -le $wa.Width -and ($r1.B - $r1.T) -gt 300) "$($r1.R - $r1.L) x $($r1.B - $r1.T)"
    [void](Close-Window $proc)
    $proc = $null
}
catch {
    Write-Host "ERROR  $($_.Exception.Message)" -ForegroundColor Red
    $script:failures++
}
finally {
    [HeldKey]::Up($VK_SPACE); [HeldKey]::Up($VK_LEFT); [HeldKey]::Up($VK_UP)
    if ($null -ne $proc -and -not $proc.HasExited) { $proc.Kill() }
}

if ($script:failures -gt 0) { Write-Host "$script:failures check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All checks passed'
exit 0
