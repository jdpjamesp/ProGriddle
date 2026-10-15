<#
.SYNOPSIS
    Drives the real Tetris window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-tetris.p under prowin with a throwaway settings file and a fixed seed, then
    plays: moving and turning the falling piece, key repeat (held movement keys repeat, a held turn
    or hard drop key fires once), soft and hard drops and the score, gravity, pause, the ghost piece,
    the Help screen, stacking up to a game over (a new best score), a new game with F2 and the start level picker, then
    the saved settings and a second run. It reads the score from the window title and the board from
    a screenshot: the picture is the "Lantern Glass" pixel canvas of TetrisPainter (272 x 320 pixels, 16 to
    a cell, shown 2 or 3 times as big). The board is found from the fill of the panel cards, and every cell is
    read at one pixel, 3 across and 3 down, which is tone 2 of the piece's colour row in every block, matched to
    src/ProGriddle/Games/Tetris/TetrisLook.cls and read as text, one letter per piece, : for the ghost (the
    hatch pixel at 2, 2) and . for the floor of the row. Screenshots go to build/screenshots.

    It sends real keystrokes and mouse clicks to the foreground window, so do not touch the
    keyboard or mouse while it runs (about 2 minutes). Exit code 0 when every check passes.
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
$settingsFile = Join-Path $root 'build\smoke-tetris-settings.json'
if (Test-Path $settingsFile) { Remove-Item $settingsFile }

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @'
using System; using System.Runtime.InteropServices;
public class Kbd {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
'@

$BOARD_W = 10
$BOARD_H = 20
# tone 2 of the colour row of each piece (TetrisLook:Tones), as a letter for each: I O T S Z J L
$LOOK = @(
    @('I', 0x6B, 0xD6, 0xC2), @('O', 0xF8, 0xD6, 0x7B), @('T', 0xB9, 0x97, 0xE6), @('S', 0xA3, 0xD7, 0x80),
    @('Z', 0xEC, 0x84, 0x76), @('J', 0x79, 0x9D, 0xE9), @('L', 0xF6, 0xAE, 0x74)
)
$GHOST_HATCH = @(0x22, 0x2F, 0x4A)
# the fill inside the cards of the panel, which is found on screen to place the board
$PANEL = @(0x0E, 0x14, 0x20)
# the floor of the first and the last row (TetrisLook Tint FloorTop and FloorBottom), which gets lighter by row
$FLOOR_TOP = @(0x0B, 0x11, 0x1B)
$FLOOR_BOTTOM = @(0x10, 0x1A, 0x2B)

# Starts the window. The seed makes the pieces the same every run.
function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-tetris.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-tetris-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Tetris*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Tetris*') { throw 'The Tetris window did not appear.' }
    Start-Sleep -Milliseconds 500
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Has-Text($p, [string]$text) { return ((Get-Title $p) -match [regex]::Escape($text)) }
function Get-Score($p) { if ((Get-Title $p) -match 'Score (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-Level($p) { if ((Get-Title $p) -match 'Level (\d+)') { [int]$Matches[1] } else { -1 } }

# Holds a key down for a number of repeats, as the keyboard does when a key is kept pressed, then lets go.
function Hold-Key([int]$vk, [int]$repeats, [bool]$extended = $false) {
    Ensure-Foreground
    $down = if ($extended) { 1 } else { 0 }
    for ($i = 0; $i -lt $repeats; $i++) { [Kbd]::keybd_event($vk, 0, $down, [UIntPtr]::Zero); Start-Sleep -Milliseconds 45 }
    [Kbd]::keybd_event($vk, 0, ($down -bor 2), [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 350
}

# Where the board is in a screenshot. The cards of the panel have a fill of their own, so a box round that
# fill runs from canvas pixel 178 to 269 across and 2 to 279 down (the NEXT card and the last card). That gives the
# scale of the picture, and from the scale the corner of the picture and the size of a cell (16 canvas pixels).
# CellW and CellH are kept apart but are the same.
function Get-Board($p, [string]$name) {
    $bmp = Take-Shot $p $name
    try {
        # the shot includes the window's shadow, where the desktop behind may have the same colour, so look inside the frame only
        # only the right hand part of the window, where the panel is: the floor of the well has this very colour in some rows
        $inset = 16; $top = 90; $bottom = 40; $left = [int]($bmp.Width * 0.63)
        $crop = $bmp.Clone((New-Object System.Drawing.Rectangle $left, $top, ($bmp.Width - $left - $inset), ($bmp.Height - $top - $bottom)), $bmp.PixelFormat)
        try { $box = [Native]::FindColour($crop, $PANEL[0], $PANEL[1], $PANEL[2], 0) } finally { $crop.Dispose() }
        if ($box[0] -lt 0) { return $null }
        $box = @(($box[0] + $left), ($box[1] + $top), ($box[2] + $left), ($box[3] + $top))
        $scale = ($box[2] - $box[0] + 1) / 92
        return [pscustomobject]@{ Left = $box[0] - 178 * $scale; Top = $box[1] - 2 * $scale; CellW = 16 * $scale; CellH = 16 * $scale }
    } finally { $bmp.Dispose() }
}

function Near($c, $rgb, [int]$tol = 3) { return ([math]::Abs($c.R - $rgb[0]) -le $tol -and [math]::Abs($c.G - $rgb[1]) -le $tol -and [math]::Abs($c.B - $rgb[2]) -le $tol) }

# The letter of a cell from its pixel 3, 3 (tone 2 of a block, the floor of the row otherwise) and its pixel 2, 2 (the
# hatch of a ghost, which has the floor showing at 3, 3).
function Letter-Of($c, $hatch, [int]$row) {
    foreach ($e in $LOOK) {
        if (Near $c @($e[1], $e[2], $e[3])) { return $e[0] }
    }
    $f = @(0, 1, 2 | ForEach-Object { [int][math]::Round($FLOOR_TOP[$_] + ($FLOOR_BOTTOM[$_] - $FLOOR_TOP[$_]) * $row / ($BOARD_H - 1)) })
    if (Near $c $f 2) {
        if ($hatch) { return ':' }
        return '.'
    }
    return '?'
}

# The board as 20 strings of 10 letters, read from a fresh screenshot.
function Read-Board($p, $board, [string]$name = 'smoke-tetris-read') {
    $bmp = Take-Shot $p $name
    try {
        $rows = @()
        for ($y = 0; $y -lt $BOARD_H; $y++) {
            $line = ''
            for ($x = 0; $x -lt $BOARD_W; $x++) {
                $px = [int]($board.Left + ($x + 3.5 / 16) * $board.CellW)
                $py = [int]($board.Top + ($y + 3.5 / 16) * $board.CellH)
                # the ghost's hatch (222F4A) is at 2, 2 and 6, 2 of the tile: look at a few pixels round them, since the scale is not a whole number
                $hatch = $false
                foreach ($hx in 2.5, 6.5) { foreach ($dy in -1, 0, 1) { foreach ($dx in -1, 0, 1) {
                    $px2 = [int]($board.Left + ($x + $hx / 16) * $board.CellW) + $dx
                    $py2 = [int]($board.Top + ($y + 2.5 / 16) * $board.CellH) + $dy
                    if (Near ($bmp.GetPixel($px2, $py2)) $GHOST_HATCH 2) { $hatch = $true }
                } } }
                $line += Letter-Of ($bmp.GetPixel($px, $py)) $hatch $y
            }
            $rows += $line
        }
        return $rows
    } finally { $bmp.Dispose() }
}

# The cells of pieces (not empty, not ghost) as "x,y" strings.
function Block-Cells($rows) {
    $cells = @()
    for ($y = 0; $y -lt $rows.Count; $y++) { for ($x = 0; $x -lt $rows[$y].Length; $x++) { if ('IOTSZJL'.Contains([string]$rows[$y][$x])) { $cells += , @($x, $y) } } }
    return , $cells
}
function Count-Of($rows, [string]$ch) { return @($rows | ForEach-Object { $_.ToCharArray() } | Where-Object { [string]$_ -ceq $ch }).Count }
function Count-Blocks($rows) { return (Block-Cells $rows).Count }
function Min-X($cells) { return ($cells | ForEach-Object { $_[0] } | Measure-Object -Minimum).Minimum }
function Max-X($cells) { return ($cells | ForEach-Object { $_[0] } | Measure-Object -Maximum).Maximum }
function Min-Y($cells) { return ($cells | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum }
# The shape of some cells wherever they are: moved to the top left corner and written out in order.
function Shape-Of($cells) {
    $mx = Min-X $cells; $my = Min-Y $cells
    return (($cells | ForEach-Object { "$($_[0] - $mx),$($_[1] - $my)" } | Sort-Object) -join ' ')
}
# True when two boards read the same, ignoring the rows a banner is drawn over (cells that read as unknown).
function Same-Board($a, $b) {
    for ($i = 0; $i -lt $a.Count; $i++) {
        if ($a[$i].Contains('?') -or $b[$i].Contains('?')) { continue }
        if ($a[$i] -ne $b[$i]) { return $false }
    }
    return $true
}
function Show-Rows($rows) { return ($rows -join '/') }

# The combo box of the window, found through UI Automation by its window class (WinForms controls all
# report as plain panes), so the start level picker can be clicked.
function Find-Picker($p) {
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($e in $all) { if ($e.Current.ClassName -like '*COMBOBOX*') { return $e } }
    return $null
}

function Read-Settings { if (Test-Path $settingsFile) { return (Get-Content $settingsFile -Raw | ConvertFrom-Json) } return $null }

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: a whole game'
    $proc = Start-Game
    Check 'the window opens on level 1 with no score' ((Has-Text $proc 'Score 0   Lines 0   Level 1') -and (Has-Text $proc 'Next ')) (Get-Title $proc)
    $board = Get-Board $proc 'smoke-tetris-1-start'
    Check 'the board is found on screen' ($null -ne $board -and $board.CellW -gt 8 -and $board.CellH -gt 8) "board=$($board | ConvertTo-Json -Compress)"
    $rows = Read-Board $proc $board
    $cells = Block-Cells $rows
    Check 'a piece of four cells is falling in the top rows' ($cells.Count -eq 4 -and (Min-Y $cells) -le 3) (Show-Rows $rows)
    Check 'the ghost piece shows where it will land, four cells' ((Count-Of $rows ':') -eq 4) (Show-Rows $rows)
    Check 'nothing unknown is drawn on the board' ((Count-Of $rows '?') -eq 0) (Show-Rows $rows)
    $firstPiece = [string]($rows | ForEach-Object { $_.ToCharArray() } | Where-Object { 'IOTSZJL'.Contains([string]$_) } | Select-Object -First 1)

    # moving
    $x0 = Min-X $cells
    Send-Keys '{LEFT}'
    $cells = Block-Cells (Read-Board $proc $board)
    Check 'Left moves the piece one cell left' ((Min-X $cells) -eq $x0 - 1) "min x $(Min-X $cells), was $x0"
    Send-Keys '{RIGHT}'
    $cells = Block-Cells (Read-Board $proc $board)
    Check 'Right moves it back' ((Min-X $cells) -eq $x0) "min x $(Min-X $cells), was $x0"
    Send-Keys 'a'
    $cells = Block-Cells (Read-Board $proc $board)
    Check 'A moves left as well' ((Min-X $cells) -eq $x0 - 1) "min x $(Min-X $cells)"
    Send-Keys 'd'

    # turning: about the piece's middle, so the shape changes and turning back restores it
    $cells = Block-Cells (Read-Board $proc $board)
    $shape0 = Shape-Of $cells
    if ($firstPiece -eq 'O') {
        Check 'the first piece is the square, which looks the same turned (not checked)' $true
    } else {
        Send-Keys '{UP}'
        $shape1 = Shape-Of (Block-Cells (Read-Board $proc $board))
        Check 'Up turns the piece clockwise' ($shape1 -ne $shape0) "$shape0 -> $shape1"
        Send-Keys 'z'
        $shape2 = Shape-Of (Block-Cells (Read-Board $proc $board))
        Check 'Z turns it back anticlockwise' ($shape2 -eq $shape0) "$shape0 -> $shape1 -> $shape2"
        Send-Keys 'x'
        $shape3 = Shape-Of (Block-Cells (Read-Board $proc $board))
        Check 'X turns it clockwise, like Up' ($shape3 -eq $shape1) "$shape1 vs $shape3"
        Send-Keys 'z'
    }

    # held movement keys repeat
    Hold-Key 0x25 12 $true
    $rows = Read-Board $proc $board 'smoke-tetris-2-held-left'
    Check 'holding Left repeats until the piece reaches the wall' ((Min-X (Block-Cells $rows)) -eq 0) (Show-Rows $rows)
    Hold-Key 0x27 14 $true
    $rows = Read-Board $proc $board 'smoke-tetris-3-held-right'
    Check 'holding Right repeats until the other wall' ((Max-X (Block-Cells $rows)) -eq 9) (Show-Rows $rows)
    Send-Keys '{LEFT}{LEFT}{LEFT}'

    # soft drop: a point for each row the key moves it. Gravity takes the piece down as well, and scores nothing
    $before = Get-Score $proc
    Send-Keys '{DOWN}'
    Check 'Down is a soft drop that scores a point' ((Get-Score $proc) -eq $before + 1) "score $(Get-Score $proc), was $before"
    Hold-Key 0x28 5 $true
    Check 'a held Down repeats and scores a point for each row' ((Get-Score $proc) -ge $before + 4) "score $(Get-Score $proc), was $before"

    # gravity: untouched, the piece falls by itself
    $y0 = Min-Y (Block-Cells (Read-Board $proc $board))
    Start-Sleep -Milliseconds 1700
    $rows = Read-Board $proc $board 'smoke-tetris-4-gravity'
    Check 'with no key pressed the piece falls by itself' ((Min-Y (Block-Cells $rows)) -gt $y0 -or (Count-Blocks $rows) -gt 4) "top row was $y0 $(Show-Rows $rows)"

    # the ghost
    Send-Keys 'g'
    $rows = Read-Board $proc $board 'smoke-tetris-5-ghost-off'
    Check 'G turns the ghost piece off' ((Count-Of $rows ':') -eq 0) (Show-Rows $rows)
    Send-Keys 'g'
    $rows = Read-Board $proc $board 'smoke-tetris-6-ghost-on'
    Check 'and on again' ((Count-Of $rows ':') -gt 0) (Show-Rows $rows)

    # pause: nothing moves, and P starts it again
    $rowsBeforePause = Read-Board $proc $board 'smoke-tetris-6b-before-pause'
    Send-Keys 'p'
    Start-Sleep -Milliseconds 700
    $rows1 = Read-Board $proc $board 'smoke-tetris-7-paused'
    $score1 = Get-Score $proc
    Send-Keys '{DOWN}{LEFT}'
    Start-Sleep -Milliseconds 1500
    $rows2 = Read-Board $proc $board
    Check 'the well is dimmed and the PAUSED plate is drawn over the board' ((Count-Of $rows1 '?') -gt 0) (Show-Rows $rows1)
    Check 'while paused neither gravity nor the keys move anything' (((Show-Rows $rows1) -eq (Show-Rows $rows2)) -and (Get-Score $proc) -eq $score1) "$(Show-Rows $rows1) vs $(Show-Rows $rows2)"
    $paused = Take-Shot $proc 'smoke-tetris-7b-paused-banner'; $paused.Dispose()
    Send-Keys 'p'
    Start-Sleep -Milliseconds 1700
    $rows3 = Read-Board $proc $board 'smoke-tetris-8-resumed'
    Check 'P starts it again and the piece falls' (-not (Same-Board $rows3 $rowsBeforePause) -and (Count-Of $rows3 '?') -eq 0) (Show-Rows $rows3)

    # hard drop, once per press. Start from a known board with one piece
    Send-Keys '{F2}'
    Check 'F2 starts a new game' ((Has-Text $proc 'Score 0   Lines 0   Level 1') -and (Count-Blocks (Read-Board $proc $board)) -eq 4) (Get-Title $proc)
    Send-Keys ' '
    $rows = Read-Board $proc $board 'smoke-tetris-9-hard-drop'
    Check 'Space drops the piece to the floor and the next one appears' ((Count-Blocks $rows) -eq 8 -and (Get-Score $proc) -ge 2) "score $(Get-Score $proc) $(Show-Rows $rows)"
    $dropped = Block-Cells $rows
    Check 'the dropped piece rests on the bottom row' (@($dropped | Where-Object { $_[1] -eq 19 }).Count -gt 0) (Show-Rows $rows)
    Hold-Key 0x20 6
    $rows = Read-Board $proc $board 'smoke-tetris-10-held-space'
    Check 'a held Space drops only one piece, not one per repeat' ((Count-Blocks $rows) -eq 12) "$(Count-Blocks $rows) cells: $(Show-Rows $rows)"
    Send-Keys ' '
    Check 'a new press of Space drops the next piece' ((Count-Blocks (Read-Board $proc $board)) -eq 16)

    # the Help screen
    Send-Keys 'h'
    $help = Take-Shot $proc 'smoke-tetris-11-help'; $help.Dispose()
    $rowsHelp = Read-Board $proc $board
    Send-Keys '{ESC}'
    Check 'the Help screen opens and closes' (Has-Text $proc 'Score')
    Send-Keys '{LEFT}'
    $rowsAfter = Read-Board $proc $board
    Check 'the game takes keys again once Help is closed' ((Show-Rows $rowsAfter) -ne (Show-Rows $rowsHelp))

    # stack the pieces in the middle until they reach the top
    $drops = 0
    while (-not (Has-Text $proc 'Game over') -and $drops -lt 40) { Send-Keys ' '; $drops++ }
    Check 'dropping piece after piece in the middle ends the game' (Has-Text $proc 'Game over') (Get-Title $proc)
    Check 'the game over score is a new best score' (Has-Text $proc 'New best score') (Get-Title $proc)
    $over = Take-Shot $proc 'smoke-tetris-12-game-over'; $over.Dispose()
    # the dead blocks fill the well in under a second and a half: let it finish before the board is read
    Start-Sleep -Milliseconds 2500
    $rowsOver = Read-Board $proc $board
    $scoreOver = Get-Score $proc
    Send-Keys '{LEFT}{DOWN}'
    Send-Keys ' '
    Check 'after the game is over the keys do nothing' ((Same-Board (Read-Board $proc $board) $rowsOver) -and (Get-Score $proc) -eq $scoreOver) (Get-Title $proc)
    Send-Keys '{F2}'
    Check 'F2 starts a new game after a game over' ((Has-Text $proc 'Score 0') -and -not (Has-Text $proc 'Game over')) (Get-Title $proc)
    Check 'the status line now shows the best score' ((Get-Title $proc) -match 'Best \d+') (Get-Title $proc)

    # the start level picker: click it open, then the keys pick (an open list takes the arrow keys)
    $picker = Find-Picker $proc
    Check 'the start level picker is found' ($null -ne $picker)
    if ($picker) {
        $r = $picker.Current.BoundingRectangle
        Click-Screen ([int]($r.X + $r.Width / 2)) ([int]($r.Y + $r.Height / 2))
        Send-Keys '{DOWN}{DOWN}{ENTER}'
        Check 'choosing level 3 starts a new game at level 3' ((Get-Level $proc) -eq 3 -and (Has-Text $proc 'Score 0')) (Get-Title $proc)
        $picked = Take-Shot $proc 'smoke-tetris-13-level-3'; $picked.Dispose()
    }
    # the ghost goes off for the next run
    Send-Keys 'g'
    Check 'the ghost is off' ((Count-Of (Read-Board $proc $board) ':') -eq 0)
    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings'
    $json = Read-Settings
    Check 'the start level was saved' ($json -and $json.values.'tetris.choice' -eq '3') ($json | ConvertTo-Json -Compress)
    Check 'the high score was saved' ($json -and $json.values.'tetris.scores' -match '^\d+:\d+$') ($json | ConvertTo-Json -Compress)
    Check 'the ghost setting was saved' ($json -and $json.values.'tetris.ghost' -eq $false) ($json | ConvertTo-Json -Compress)
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 300)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: the settings come back'
    $proc = Start-Game
    Check 'the saved start level is used' ((Get-Level $proc) -eq 3) (Get-Title $proc)
    Check 'the saved high score is shown as the best' ((Get-Title $proc) -match 'Best \d+') (Get-Title $proc)
    $board2 = Get-Board $proc 'smoke-tetris-14-second-run'
    $rows = Read-Board $proc $board2
    Check 'the saved ghost setting is used, so there is no ghost piece' ((Count-Of $rows ':') -eq 0 -and (Count-Blocks $rows) -eq 4) (Show-Rows $rows)
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
