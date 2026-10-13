<#
.SYNOPSIS
    Drives the real Snake window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-snake.p under prowin with a throwaway settings file that asks for a 40 x 40 board
    (so the snake has room, because it sets off as soon as the window opens) and a fixed seed, then
    plays: the colours of src/ProGriddle/Games/Snake/SnakeLook.cls are on the screen, P pauses and the
    picture freezes, P runs it again and the snake moves, the arrow keys steer it (up, left, then two
    quick turns, up and right, which both have to be made), it crashes into a wall (GAME OVER, and the
    keys then do nothing), R starts a new game, and the settings are saved. A second run asks for a
    12 x 8 board and checks the board on screen has that shape. The snake is found in screenshots by its
    head colour and the state is read from the window title. Screenshots go to build/screenshots.

    It sends real keystrokes to the foreground window, so do not touch the keyboard or mouse while it
    runs (a minute or two). Exit code 0 when every check passes.
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
$settingsFile = Join-Path $root 'build\smoke-snake-settings.json'

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

# the palette of SnakeLook: empty, body, head, food
$EMPTY = @(0x1E, 0x24, 0x2B)
$BODY  = @(0x3F, 0xAE, 0x78)
$HEAD  = @(0x8E, 0xF0, 0xC0)
$FOOD  = @(0xE5, 0x53, 0x3D)

function Write-Settings([int]$width, [int]$height) {
    $json = @{ schemaVersion = 1; values = @{ 'snake.width' = $width; 'snake.height' = $height } } | ConvertTo-Json -Compress
    Set-Content -Path $settingsFile -Value $json -Encoding ascii
}

# Starts the window. The seed makes the food the same every run.
function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-p', 'tools/launch.p', '-param', "`"run/run-snake.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-snake-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Snake*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Snake*') { throw 'The Snake window did not appear.' }
    $script:target = $p
    Ensure-Foreground
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Has-Text($p, [string]$text) { return ((Get-Title $p) -match [regex]::Escape($text)) }
function Read-Settings { if (Test-Path $settingsFile) { return (Get-Content $settingsFile -Raw | ConvertFrom-Json) } return $null }

# A fingerprint of the window as it looks, to tell whether anything moved.
function Get-Picture($p, [string]$name) {
    $bmp = Take-Shot $p $name
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash($ms.ToArray()))
    $ms.Dispose()
    return $hash
}

# The box round the pixels of a colour in a screenshot, as x, y, right, bottom, or $null when there are none.
function Get-Box($bmp, $rgb, [int]$tol = 4) {
    $b = [Native]::FindColour($bmp, $rgb[0], $rgb[1], $rgb[2], $tol)
    if ($b[0] -lt 0) { return $null }
    return $b
}

# Where the head is: the centre of its box, and the size of a cell (the head is exactly one cell).
function Get-Head($p, [string]$name) {
    $bmp = Take-Shot $p $name
    $b = Get-Box $bmp $HEAD
    $bmp.Dispose()
    if ($null -eq $b) { return $null }
    return @{ X = ($b[0] + $b[2]) / 2.0; Y = ($b[1] + $b[3]) / 2.0; Cell = [Math]::Max($b[2] - $b[0], $b[3] - $b[1]) + 1 }
}

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: a whole game on a 40 x 40 board'
    Write-Settings 40 40
    $proc = Start-Game
    Send-Keys 'p'
    Check 'the window opens with the score and length shown' ((Get-Title $proc) -match 'Score 0   Length 3   Level 1   Best 0') (Get-Title $proc)

    $bmp = Take-Shot $proc 'smoke-snake-1-paused'
    Check 'the board, the body, the head and the food are drawn in their colours' ((Get-Box $bmp $EMPTY) -and (Get-Box $bmp $BODY) -and (Get-Box $bmp $HEAD) -and (Get-Box $bmp $FOOD)) 'a colour is missing'
    $boardBox = Get-Box $bmp $EMPTY
    $ratio = ($boardBox[2] - $boardBox[0]) / [Math]::Max(1, ($boardBox[3] - $boardBox[1]))
    Check 'a 40 x 40 board is square on the screen' ($ratio -gt 0.95 -and $ratio -lt 1.05) "ratio $ratio"
    $bmp.Dispose()

    # P pauses: the picture freezes
    $still1 = Get-Picture $proc 'smoke-snake-2a-still'
    Start-Sleep -Milliseconds 900
    Check 'while paused nothing moves' ((Get-Picture $proc 'smoke-snake-2b-still') -eq $still1)
    $head0 = Get-Head $proc 'smoke-snake-2c-head'
    Send-Keys 'p'
    Start-Sleep -Milliseconds 700
    $head1 = Get-Head $proc 'smoke-snake-3-running'
    Check 'P runs it again and the snake crawls to the right' ($head1 -and $head1.X -gt $head0.X + $head0.Cell -and [Math]::Abs($head1.Y - $head0.Y) -lt 2) "from $($head0.X),$($head0.Y) to $($head1.X),$($head1.Y)"

    # steering: up
    $cell = $head0.Cell
    Send-Keys '{UP}'
    Start-Sleep -Milliseconds 500
    $a = Get-Head $proc 'smoke-snake-4a-up'
    Start-Sleep -Milliseconds 500
    $b = Get-Head $proc 'smoke-snake-4b-up'
    Check 'Up turns the snake upwards: it climbs and its column stays the same' ($a -and $b -and $b.Y -lt $a.Y - $cell / 2 -and [Math]::Abs($b.X - $a.X) -lt $cell / 2) "from $($a.X),$($a.Y) to $($b.X),$($b.Y)"

    # steering: left
    Send-Keys '{LEFT}'
    Start-Sleep -Milliseconds 400
    $a = Get-Head $proc 'smoke-snake-5a-left'
    Start-Sleep -Milliseconds 500
    $b = Get-Head $proc 'smoke-snake-5b-left'
    Check 'Left turns it to the left: its row stays the same' ($a -and $b -and $b.X -lt $a.X - $cell / 2 -and [Math]::Abs($b.Y - $a.Y) -lt $cell / 2) "from $($a.X),$($a.Y) to $($b.X),$($b.Y)"

    # two quick turns: both have to be made, so it ends up above and to the right of where it was
    $a = Get-Head $proc 'smoke-snake-6a-before-two-turns'
    Send-Keys '{UP}{RIGHT}'
    Start-Sleep -Milliseconds 100
    $b = Get-Head $proc 'smoke-snake-6b-after-two-turns'
    Start-Sleep -Milliseconds 600
    $c = Get-Head $proc 'smoke-snake-6c-after-two-turns'
    Check 'two quick key presses (up, then right) are both made' ($c -and $c.Y -lt $a.Y - $cell / 2 -and $c.X -gt $b.X) "start $($a.X),$($a.Y) now $($c.X),$($c.Y)"

    # the snake is heading right: it runs into the right wall in the end
    $waited = 0
    while (-not (Has-Text $proc 'Game over') -and $waited -lt 20) { Start-Sleep -Seconds 1; $waited++ }
    Check 'the snake crashes into the wall and the game is over' (Has-Text $proc 'Game over') (Get-Title $proc)
    $over = Take-Shot $proc 'smoke-snake-7-game-over'; $over.Dispose()
    $stuck = Get-Picture $proc 'smoke-snake-7b-stuck'
    Send-Keys '{DOWN}{LEFT}{UP}'
    Start-Sleep -Milliseconds 600
    Check 'after the game is over the keys do nothing' ((Get-Picture $proc 'smoke-snake-7c-stuck-after') -eq $stuck) (Get-Title $proc)

    Send-Keys 'r'
    Check 'R starts a new game' ((Has-Text $proc 'Score 0   Length 3') -and -not (Has-Text $proc 'Game over')) (Get-Title $proc)
    Send-Keys 'p'
    $new0 = Get-Head $proc 'smoke-snake-8a-new-game'
    Send-Keys 'p'
    Start-Sleep -Milliseconds 600
    $new1 = Get-Head $proc 'smoke-snake-8b-new-game-running'
    Check 'and the new snake moves' ($new0 -and $new1 -and $new1.X -gt $new0.X) "from $($new0.X) to $($new1.X)"

    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings'
    $json = Read-Settings
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 200) ($json | ConvertTo-Json -Compress)
    Check 'the board size is still in the file' ($json -and $json.values.'snake.width' -eq 40) ($json | ConvertTo-Json -Compress)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: a 12 x 8 board'
    Write-Settings 12 8
    $proc = Start-Game
    Send-Keys 'p'
    $bmp = Take-Shot $proc 'smoke-snake-9-small-board'
    $boardBox = Get-Box $bmp $EMPTY
    $ratio = if ($boardBox) { ($boardBox[2] - $boardBox[0]) / [Math]::Max(1, ($boardBox[3] - $boardBox[1])) } else { 0 }
    $bmp.Dispose()
    Check 'the board size from the settings is used: 12 x 8 is one and a half times as wide as high' ($ratio -gt 1.4 -and $ratio -lt 1.6) "ratio $ratio"
    Check 'the second window exits cleanly' (Close-Window $proc)
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $script:failures++
}
finally {
    if ($proc -and -not $proc.HasExited) { $proc.Kill() }
}

Write-Host ''
if ($script:failures -eq 0) { Write-Host 'GUI smoke test passed.' -ForegroundColor Green; exit 0 }
Write-Host "GUI smoke test: $($script:failures) problem(s). Screenshots are in build/screenshots." -ForegroundColor Red
exit 1
