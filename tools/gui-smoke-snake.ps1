<#
.SYNOPSIS
    Drives the real Snake window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-snake.p under prowin with a throwaway settings file that asks for a 40 x 40 board
    (so the snake has room) and a fixed seed, then plays: a new game waits for the first arrow key and
    nothing moves until it comes, the colours of src/ProGriddle/Games/Snake/SnakeLook.cls are on the
    screen, the arrow keys steer the snake (up, left, then two quick turns, up and right, which both
    have to be made), P pauses and the picture freezes, the snake crashes into a wall (GAME OVER, and
    the keys then do nothing), R starts a new game that waits again, and the Board drop down list
    changes the size (the food is drawn bigger on a 10 x 10 board) and the choice is saved. A second run
    asks for a 12 x 8 board in the settings and checks the board on screen has that shape. The snake is
    found in screenshots by its head colour and the state is read from the window title. Screenshots go
    to build/screenshots.

    It sends real keystrokes and a mouse click to the foreground window, so do not touch the keyboard
    or mouse while it runs (a minute or two). Exit code 0 when every check passes.
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
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

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
    Start-Sleep -Milliseconds 500
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

# The size of a cell in pixels, from the food, which is exactly one cell and which the banner never covers
# (it is only in the middle of the board).
function Get-FoodCell($p, [string]$name) {
    $bmp = Take-Shot $p $name
    $b = Get-Box $bmp $FOOD
    $bmp.Dispose()
    if ($null -eq $b) { return 0 }
    return [Math]::Max($b[2] - $b[0], $b[3] - $b[1]) + 1
}

function Find-Picker($p) {
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($e in $all) { if ($e.Current.ClassName -like '*COMBOBOX*') { return $e } }
    return $null
}

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: a whole game on a 40 x 40 board'
    Write-Settings 40 40
    $proc = Start-Game
    Check 'the window opens with the score and length shown' ((Get-Title $proc) -match 'Score 0   Length 3   Level 1   Best 0') (Get-Title $proc)

    # a new game waits for the first arrow key
    $bmp = Take-Shot $proc 'smoke-snake-1-waiting'
    $boardBox = Get-Box $bmp $EMPTY
    $ratio = ($boardBox[2] - $boardBox[0]) / [Math]::Max(1, ($boardBox[3] - $boardBox[1]))
    Check 'a 40 x 40 board is square on the screen' ($ratio -gt 0.95 -and $ratio -lt 1.05) "ratio $ratio"
    $bmp.Dispose()
    $cell40 = Get-FoodCell $proc 'smoke-snake-1b-food'
    $still1 = Get-Picture $proc 'smoke-snake-1c-still'
    Start-Sleep -Milliseconds 1200
    Check 'a new game does not move until an arrow key is pressed' ((Get-Picture $proc 'smoke-snake-1d-still') -eq $still1)

    # the key for the way it is facing starts it
    Send-Keys '{RIGHT}'
    Start-Sleep -Milliseconds 300
    $bmp = Take-Shot $proc 'smoke-snake-2-running'
    Check 'the board, the body, the head and the food are drawn in their colours' ((Get-Box $bmp $EMPTY) -and (Get-Box $bmp $BODY) -and (Get-Box $bmp $HEAD) -and (Get-Box $bmp $FOOD)) 'a colour is missing'
    $bmp.Dispose()
    $head0 = Get-Head $proc 'smoke-snake-2b-head'
    Start-Sleep -Milliseconds 500
    $head1 = Get-Head $proc 'smoke-snake-3-running'
    $cell = $head0.Cell
    Check 'the arrow key starts the snake and it crawls to the right' ($head1 -and $head1.X -gt $head0.X + $cell -and [Math]::Abs($head1.Y - $head0.Y) -lt 2) "from $($head0.X),$($head0.Y) to $($head1.X),$($head1.Y)"

    # P pauses: the picture freezes, and P runs it again
    Send-Keys 'p'
    $paused1 = Get-Picture $proc 'smoke-snake-3b-paused'
    Start-Sleep -Milliseconds 900
    Check 'P pauses: while paused nothing moves' ((Get-Picture $proc 'smoke-snake-3c-paused') -eq $paused1)
    Send-Keys 'p'
    Start-Sleep -Milliseconds 500
    Check 'and P runs it again' ((Get-Picture $proc 'smoke-snake-3d-running') -ne $paused1)

    # steering: up
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

    # a new game waits again
    Send-Keys 'r'
    Check 'R starts a new game' ((Has-Text $proc 'Score 0   Length 3') -and -not (Has-Text $proc 'Game over')) (Get-Title $proc)
    $waiting1 = Get-Picture $proc 'smoke-snake-8a-new-game'
    Start-Sleep -Milliseconds 1000
    Check 'and the new game waits for an arrow key' ((Get-Picture $proc 'smoke-snake-8b-new-game') -eq $waiting1)
    Send-Keys '{UP}'
    Start-Sleep -Milliseconds 300
    $new0 = Get-Head $proc 'smoke-snake-8c-new-game-running'
    Start-Sleep -Milliseconds 600
    $new1 = Get-Head $proc 'smoke-snake-8d-new-game-running'
    Check 'then the new snake moves' ($new0 -and $new1 -and $new1.Y -lt $new0.Y) "from $($new0.Y) to $($new1.Y)"

    # the Board drop down list: click it open, then the keys pick the first item, 10 x 10
    $picker = Find-Picker $proc
    Check 'the Board drop down list is found' ($null -ne $picker)
    if ($picker) {
        $r = $picker.Current.BoundingRectangle
        Click-Screen ([int]($r.X + $r.Width / 2)) ([int]($r.Y + $r.Height / 2))
        Send-Keys '{HOME}{ENTER}'
        $small = Take-Shot $proc 'smoke-snake-9-ten-by-ten'
        $boardBox = Get-Box $small $EMPTY
        $ratio = if ($boardBox) { ($boardBox[2] - $boardBox[0]) / [Math]::Max(1, ($boardBox[3] - $boardBox[1])) } else { 0 }
        $small.Dispose()
        $cell10 = Get-FoodCell $proc 'smoke-snake-9b-food'
        Check 'choosing 10 x 10 gives a new, square board with bigger cells' ($ratio -gt 0.95 -and $ratio -lt 1.05 -and $cell10 -gt $cell40 * 2) "cells were $cell40, now $cell10, ratio $ratio"
        Check 'the new game on it waits for an arrow key' ((Get-Title $proc) -match 'Score 0   Length 3')
    }

    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings'
    $json = Read-Settings
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 200) ($json | ConvertTo-Json -Compress)
    Check 'the chosen board size was saved' ($json -and $json.values.'snake.size' -eq '10 x 10') ($json | ConvertTo-Json -Compress)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: a 12 x 8 board'
    Write-Settings 12 8
    $proc = Start-Game
    $bmp = Take-Shot $proc 'smoke-snake-10-small-board'
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
