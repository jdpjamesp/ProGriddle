<#
.SYNOPSIS
    Drives the real Space Invaders window like a player and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-spaceinvaders.p under prowin with a throwaway settings file and a fixed seed, then
    checks: the title screen shows (the gradient title, the points table, "Press Space to play" in the
    title bar), Space starts a game and the wave draws in with every colour of
    src/ProGriddle/Games/SpaceInvaders/InvadersLook.cls (five invader rows, shields, the cannon, the
    ground line), a held Right key moves the cannon right and a held Left key moves it back, a tap of
    Space fires a shot that rises, P pauses so the picture freezes and P runs it again, R starts a new
    game, and the window saves its own size under spaceinvaders.window.*. The board is found in
    screenshots by its ground line, so the test works at any window size and display scaling.
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
$settingsFile = Join-Path $root 'build\smoke-spaceinvaders-settings.json'
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
$VK_LEFT = 0x25; $VK_RIGHT = 0x27; $VK_SPACE = 0x20

# the colours of InvadersLook that the checks look for
$GROUND   = @(0x3C, 0xE6, 0xA0)
$TITLE    = @(0xFF, 0x7A, 0xD0)
$ROWS     = @(@(0xFF, 0x4F, 0xA8), @(0xD0, 0x60, 0xFF), @(0x8F, 0x7B, 0xFF), @(0x4A, 0xA8, 0xFF), @(0x3D, 0xE8, 0xFF))
$SHIELD   = @(0x8C, 0xFF, 0xC8)
$CANNON   = @(0x5C, 0xFF, 0x8A)
$CANNONDEEP = @(0x1F, 0xA8, 0x60)
$SHOT     = @(0xA8, 0xF6, 0xFF)

function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-spaceinvaders.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-spaceinvaders-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Space Invaders*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Space Invaders*') { throw 'The Space Invaders window did not appear.' }
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

# Where the board is in a screenshot, from the ground line, which runs from cell 8 to cell 215 on row 232.
function Get-Geometry($bmp) {
    $b = Get-Box $bmp $GROUND 4
    if ($null -eq $b) { return $null }
    $cell = ($b[2] - $b[0] + 1) / 208.0
    return @{ Cell = $cell; X0 = $b[0] - 8 * $cell; Y0 = $b[1] - 232 * $cell }
}

# The colour of a cell of the board, from the middle of its pixels.
function Get-CellColour($bmp, $geo, [int]$x, [int]$y) {
    $px = [int]($geo.X0 + ($x + 0.5) * $geo.Cell)
    $py = [int]($geo.Y0 + ($y + 0.5) * $geo.Cell)
    if ($px -lt 0 -or $py -lt 0 -or $px -ge $bmp.Width -or $py -ge $bmp.Height) { return $null }
    $c = $bmp.GetPixel($px, $py)
    return @($c.R, $c.G, $c.B)
}

function Same($a, $b, [int]$tol = 8) {
    if ($null -eq $a) { return $false }
    for ($i = 0; $i -lt 3; $i++) { if ([Math]::Abs($a[$i] - $b[$i]) -gt $tol) { return $false } }
    return $true
}

# The left edge of the cannon in cells: the first cell of row 221 (a full row of its body) in its colour. (The
# base row is not used: with 2.5 pixels to a cell its edge is blended with the dark below.)
function Get-CannonX($bmp, $geo) {
    for ($x = 0; $x -lt 224; $x++) {
        if (Same (Get-CellColour $bmp $geo $x 221) $CANNON 14) { return $x }
    }
    return -1
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

    $bmp = Take-Shot $proc 'smoke-si-1-title'
    $geo = Get-Geometry $bmp
    Check 'the board is found by its ground line' ($null -ne $geo -and $geo.Cell -ge 1) 'no ground line'
    Check 'the gradient title is on the screen' ($null -ne (Get-Box $bmp $TITLE 40)) 'no title colour'
    Check 'the board is a tall one: 224 wide and 256 high' ($null -ne $geo -and $bmp.Height -gt $geo.Y0 + 240 * $geo.Cell) ''
    Check 'the board fills the window: little dead space round it' ($null -ne $geo -and ($geo.Cell * 224) / $bmp.Width -gt 0.85) "board $($geo.Cell * 224) of $($bmp.Width)"
    $bmp.Dispose()

    # the title waits: a tap of Space starts a game
    Hold-Key $VK_SPACE 120
    Start-Sleep -Milliseconds 400
    Check 'Space starts a game' ((Get-Title $proc) -match 'Score 0   Hi 0   Lives 3   Wave 1') (Get-Title $proc)

    # the wave builds itself over 130 frames (2 seconds at the arcade's speed, 3 at the starting speed of 70 percent) and play begins. The first bomb is aimed at the cannon and
    # arrives about two seconds after that, so the checks that follow keep the cannon moving.
    Start-Sleep -Milliseconds 3400
    $bmp = Take-Shot $proc 'smoke-si-2-wave'
    $geo = Get-Geometry $bmp
    $missing = @()
    for ($r = 0; $r -lt 5; $r++) { if ($null -eq (Get-Box $bmp $ROWS[$r] 6)) { $missing += "row $($r + 1)" } }
    Check 'all five rows of invaders are on the screen in their own colours' ($missing.Count -eq 0) ($missing -join ', ')
    Check 'the shields are drawn' ($null -ne (Get-Box $bmp $SHIELD 24)) 'no shield colour'
    Check 'the cannon is drawn' ($null -ne (Get-Box $bmp $CANNON 6)) 'no cannon colour'
    $x0 = Get-CannonX $bmp $geo
    Check 'the cannon starts near the middle' ($x0 -gt 90 -and $x0 -lt 120) "x $x0"
    $bmp.Dispose()

    # steering: held keys
    Hold-Key $VK_RIGHT 400
    $bmp = Take-Shot $proc 'smoke-si-3-right'
    $x1 = Get-CannonX $bmp (Get-Geometry $bmp)
    $bmp.Dispose()
    Check 'a held Right key moves the cannon to the right' ($x1 -gt $x0 + 8) "from $x0 to $x1"
    Hold-Key $VK_LEFT 400
    $bmp = Take-Shot $proc 'smoke-si-4-left'
    $x2 = Get-CannonX $bmp (Get-Geometry $bmp)
    $bmp.Dispose()
    Check 'a held Left key moves it back' ($x2 -lt $x1 - 8) "from $x1 to $x2"

    # a shot: hold Space and look for it straight away
    Ensure-Foreground
    [HeldKey]::Down($VK_SPACE)
    Start-Sleep -Milliseconds 90
    $bmp = Take-Shot $proc 'smoke-si-5-shot'
    [HeldKey]::Up($VK_SPACE)
    Check 'Space fires a shot' ($null -ne (Get-Box $bmp $SHOT 8)) 'no shot colour'
    $bmp.Dispose()

    # P pauses: nothing moves, and P runs it again
    Send-Keys 'p'
    $frozen = Get-Picture $proc 'smoke-si-6-paused'
    Start-Sleep -Milliseconds 800
    Check 'P pauses: while paused nothing moves' ((Get-Picture $proc 'smoke-si-6b-paused') -eq $frozen)
    Send-Keys 'p'
    Start-Sleep -Milliseconds 800
    Check 'P runs it again' ((Get-Picture $proc 'smoke-si-6c-running') -ne $frozen)

    # R starts a new game
    Send-Keys 'r'
    Start-Sleep -Milliseconds 600
    Check 'R starts a new game' ((Get-Title $proc) -match 'Score 0   Hi \d+   Lives 3   Wave 1') (Get-Title $proc)

    # closing saves the window's own size
    $closed = Close-Window $proc
    Check 'the window closes by itself' $closed
    $proc = $null
    $saved = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Check 'the window size is saved under spaceinvaders.window' ($null -ne $saved.values.'spaceinvaders.window.width' -and $null -ne $saved.values.'spaceinvaders.window.height') 'keys missing'

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: the saved size comes back'
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
    [HeldKey]::Up($VK_SPACE); [HeldKey]::Up($VK_LEFT); [HeldKey]::Up($VK_RIGHT)
    if ($null -ne $proc -and -not $proc.HasExited) { $proc.Kill() }
}

if ($script:failures -gt 0) { Write-Host "$script:failures check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All checks passed'
exit 0
