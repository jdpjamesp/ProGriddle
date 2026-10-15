<#
.SYNOPSIS
    Plays each game for a moment and saves a picture of its window for the README and the game pages.
.DESCRIPTION
    For each game it starts the real window with a throwaway settings file and a fixed seed, sends the keys or clicks that get the game into a
    picture worth showing (a stack in Tetris, a random board running in Life, a title screen, and so on), and saves the window as a PNG in
    assets/screenshots, at most 960 pixels wide. Only the window itself is copied, without its shadow.

    It sends real keystrokes and mouse clicks to the foreground window and copies the screen, so do not touch the keyboard or mouse while it
    runs (about three minutes). Use -Only to take some of the pictures (a comma list of names), for example -Only tetris,snake.
.PARAMETER Only
    Names of the pictures to take: cookoff, life, tetris, snake, asteroids-title, asteroids, spaceinvaders-title, spaceinvaders, minesweeper,
    battleships, 2048. Default is all of them.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$Seed = 5,
    [string[]]$Only = @()
)

$ErrorActionPreference = 'Stop'
# a comma list given to powershell -File arrives as one string
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $PSScriptRoot 'progress-temp.ps1')
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null
$out = Join-Path $root 'assets\screenshots'
New-Item -ItemType Directory -Force $out | Out-Null

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public class Kbd2 {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
public class Dwm {
  public struct RECT { public int L, T, R, B; }
  [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
}
'@

$taken = @()
$problems = @()

# Starts a window and waits for it. The settings file is thrown away first so a saved window size or board does not change the picture.
function Start-App([string]$run, [string]$titleStart, [int]$autoClose = 120) {
    $settingsFile = Join-Path $root 'build\shots-settings.json'
    Remove-Item $settingsFile -ErrorAction SilentlyContinue
    $param = if ($run -like '*arcade*') { $run } else { "$run,$settingsFile,$autoClose,$Seed" }
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"$param`"")
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(30)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like "$titleStart*" -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike "$titleStart*") { throw "The $titleStart window did not appear." }
    Start-Sleep -Milliseconds 1200
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

# Holds a key down for a number of repeats, as the keyboard does when a key is kept pressed, then lets go.
function Hold-Key([int]$vk, [int]$repeats, [bool]$extended = $false) {
    Ensure-Foreground
    $down = if ($extended) { 1 } else { 0 }
    for ($i = 0; $i -lt $repeats; $i++) { [Kbd2]::keybd_event($vk, 0, $down, [UIntPtr]::Zero); Start-Sleep -Milliseconds 45 }
    [Kbd2]::keybd_event($vk, 0, ($down -bor 2), [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 200
}

# Saves the window as it looks, from its real edge (not the invisible border Windows adds), at most 960 pixels wide.
function Save-Window($p, [string]$name) {
    Ensure-Foreground
    Start-Sleep -Milliseconds 250
    $p.Refresh()
    $r = New-Object Dwm+RECT
    [void][Dwm]::DwmGetWindowAttribute($p.MainWindowHandle, 9, [ref]$r, 16)
    $w = $r.R - $r.L; $h = $r.B - $r.T
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
    $g.Dispose()
    $final = $bmp
    if ($w -gt 960) {
        $nh = [int][math]::Round($h * 960.0 / $w)
        $final = New-Object System.Drawing.Bitmap 960, $nh
        $g = [System.Drawing.Graphics]::FromImage($final)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($bmp, 0, 0, 960, $nh)
        $g.Dispose()
        $bmp.Dispose()
    }
    $file = Join-Path $out "$name.png"
    $final.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("Saved assets\screenshots\{0}.png ({1} x {2}, {3} KB)" -f $name, $final.Width, $final.Height, [int]((Get-Item $file).Length / 1024))
    $final.Dispose()
    $script:taken += $name
}

# Runs one picture: starts the window, runs the steps, saves, closes. A problem is reported and the next picture is still taken.
function Scene([string]$name, [scriptblock]$body) {
    if ($Only.Count -gt 0 -and $Only -notcontains $name) { return }
    Write-Host "--- $name"
    $p = $null
    try { $p = & $body } catch { Write-Host "PROBLEM  ${name}: $($_.Exception.Message)" -ForegroundColor Red; $script:problems += $name }
    finally { if ($p -and -not $p.HasExited) { [void](Close-Window $p) } }
    Start-Sleep -Milliseconds 600
}

# Taps Space until the title bar says the game is on (the title may not answer while it is still tracing itself in).
function Start-Play($p, [string]$needle) {
    for ($i = 0; $i -lt 8; $i++) {
        Hold-Key $VK_SPACE 3
        Start-Sleep -Milliseconds 500
        $p.Refresh()
        if ($p.MainWindowTitle -match $needle) { return }
    }
    throw "The game did not start: $($p.MainWindowTitle)"
}

# Sends a run of keys quickly, a little pause between each.
function Quick-Keys([string[]]$keys, [int]$pause = 90) {
    Ensure-Foreground
    foreach ($k in $keys) { [System.Windows.Forms.SendKeys]::SendWait($k); Start-Sleep -Milliseconds $pause }
}

# Clicks a place given as a fraction of the window (from the left and from the top), as it is in a picture of the window.
function Click-At($p, [double]$fx, [double]$fy, [string]$button = 'left') {
    $r = New-Object Dwm+RECT
    [void][Dwm]::DwmGetWindowAttribute($p.MainWindowHandle, 9, [ref]$r, 16)
    Click-Screen ([int]($r.L + ($r.R - $r.L) * $fx)) ([int]($r.T + ($r.B - $r.T) * $fy)) $button 250
}

# the virtual key codes used with Hold-Key
$VK_LEFT = 0x25; $VK_UP = 0x26; $VK_RIGHT = 0x27; $VK_DOWN = 0x28; $VK_SPACE = 0x20

Scene 'cookoff' {
    $p = Start-App 'run/run-arcade.p' 'ProGriddle Cookoff'
    Start-Sleep -Milliseconds 1500
    Save-Window $p 'cookoff'
    return $p
}

Scene 'life' {
    $p = Start-App 'run/run-life.p' 'ProGriddle Life'
    Send-Keys 'g'
    Send-Keys ' '
    Start-Sleep -Milliseconds 2500
    Save-Window $p 'life'
    return $p
}

Scene 'tetris' {
    $p = Start-App 'run/run-tetris.p' 'ProGriddle Tetris'
    # drop pieces in different places and turns to build a stack, then leave one in the air
    foreach ($keys in @('{LEFT}{LEFT}{LEFT}{LEFT} ', '{RIGHT}{RIGHT}{RIGHT} ', '{LEFT}{LEFT} ', '{UP}{RIGHT}{RIGHT}{RIGHT}{RIGHT} ', '{UP}{LEFT}{LEFT}{LEFT} ', '{RIGHT} ', '{UP}{LEFT} ', ' ', '{UP}{RIGHT}{RIGHT} ', '{LEFT}{LEFT}{LEFT}{LEFT} ')) {
        Send-Keys $keys
    }
    Start-Sleep -Milliseconds 400
    Save-Window $p 'tetris'
    return $p
}

Scene 'snake' {
    $p = Start-App 'run/run-snake.p' 'ProGriddle Snake'
    # a small square path round the middle, so the snake does not reach a wall
    Send-Keys '{RIGHT}'
    Send-Keys '{DOWN}'
    Send-Keys '{LEFT}'
    Send-Keys '{UP}'
    Start-Sleep -Milliseconds 150
    Save-Window $p 'snake'
    return $p
}

Scene 'asteroids-title' {
    $p = Start-App 'run/run-asteroids.p' 'ProGriddle Asteroids'
    # the title is traced and the hint lines come in over about five seconds
    Start-Sleep -Milliseconds 5500
    Save-Window $p 'asteroids-title'
    return $p
}

Scene 'asteroids' {
    $p = Start-App 'run/run-asteroids.p' 'ProGriddle Asteroids'
    Start-Sleep -Milliseconds 5500
    Start-Play $p 'Ships'
    Start-Sleep -Milliseconds 1200
    Hold-Key $VK_LEFT 5 $true
    Hold-Key $VK_UP 12 $true
    Hold-Key $VK_SPACE 40
    Hold-Key $VK_RIGHT 7 $true
    Hold-Key $VK_SPACE 25
    Start-Sleep -Milliseconds 150
    Save-Window $p 'asteroids'
    return $p
}

Scene 'spaceinvaders-title' {
    $p = Start-App 'run/run-spaceinvaders.p' 'ProGriddle Space Invaders'
    Start-Sleep -Milliseconds 5000
    Save-Window $p 'spaceinvaders-title'
    return $p
}

Scene 'spaceinvaders' {
    $p = Start-App 'run/run-spaceinvaders.p' 'ProGriddle Space Invaders'
    Start-Sleep -Milliseconds 5000
    Start-Play $p 'Lives'
    Start-Sleep -Milliseconds 3500
    Hold-Key $VK_LEFT 16 $true
    Hold-Key $VK_SPACE 40
    Hold-Key $VK_RIGHT 8 $true
    Hold-Key $VK_SPACE 40
    Start-Sleep -Milliseconds 150
    Save-Window $p 'spaceinvaders'
    return $p
}

Scene 'minesweeper' {
    $p = Start-App 'run/run-minesweeper.p' 'ProGriddle Minesweeper'
    # the board of a beginner game is 9 x 9 cells, from 0.153 to 0.845 of the width and from 0.090 to 0.964 of the height of the window
    function Cell([int]$c, [int]$r) { return @((0.153 + 0.692 * ($c + 0.5) / 9), (0.090 + 0.874 * ($r + 0.5) / 9)) }
    # the first click is always safe; then a few more cells, and flags on two
    foreach ($cr in @(@(0, 0), @(4, 4), @(2, 6), @(6, 2), @(8, 8))) { $f = Cell $cr[0] $cr[1]; Click-At $p $f[0] $f[1] }
    foreach ($cr in @(@(1, 7), @(7, 1))) { $f = Cell $cr[0] $cr[1]; Click-At $p $f[0] $f[1] 'right' }
    Start-Sleep -Milliseconds 400
    Save-Window $p 'minesweeper'
    return $p
}

Scene 'battleships' {
    $p = Start-App 'run/run-battleships.p' 'ProGriddle Battleships'
    # Random puts the whole fleet down, then a few shots at the enemy's waters on the LEFT board (10 x 10 cells from 0.006 to 0.475 of the width and 0.232 to 0.823 of the height)
    Click-At $p 0.206 0.065
    Start-Sleep -Milliseconds 800
    foreach ($cr in @(@(2, 2), @(5, 5), @(5, 6), @(7, 3), @(3, 7), @(8, 8), @(1, 5), @(6, 6), @(4, 4))) {
        Click-At $p (0.006 + 0.469 * ($cr[0] + 0.5) / 10) (0.232 + 0.591 * ($cr[1] + 0.5) / 10)
        Start-Sleep -Milliseconds 500
    }
    # let the message that fades over the middle of the boards go
    Start-Sleep -Milliseconds 4000
    Save-Window $p 'battleships'
    return $p
}

Scene '2048' {
    $p = Start-App 'run/run-2048.p' 'ProGriddle 2048'
    # keep the big tiles in a corner: mostly down and left, right now and then when it is stuck
    $moves = @()
    foreach ($i in 1..22) { $moves += '{DOWN}', '{LEFT}', '{DOWN}', '{RIGHT}' }
    Quick-Keys $moves 110
    Start-Sleep -Milliseconds 400
    Save-Window $p '2048'
    return $p
}

Write-Host ''
Write-Host "Taken: $($taken -join ', ')"
if ($problems.Count -gt 0) { Write-Host "Problems: $($problems -join ', ')" -ForegroundColor Red; exit 1 }
exit 0
