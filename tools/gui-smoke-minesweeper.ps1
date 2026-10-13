<#
.SYNOPSIS
    Drives the real Minesweeper window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-minesweeper.p under prowin with a throwaway settings file and a fixed seed,
    asks tools/minesweeper-layout.p where the mines are, then plays: flags, question marks, the
    timer, a chord with both mouse buttons, a whole winning game, a loss, the New game key, the
    level picker and the saved settings. It reads the state back from the window title, which
    carries the status line ("Beginner 9 x 9   Mines 010   Time 000   Ready ..."), and from the
    colour of cells in a screenshot. Screenshots go to build/screenshots.

    It sends real keystrokes and mouse clicks to the foreground window, so do not touch the
    keyboard or mouse while it runs (about 2 minutes). Exit code 0 when every check passes.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' }),
    [int]$Seed = 7
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $PSScriptRoot 'progress-temp.ps1')
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null
$settingsFile = Join-Path $root 'build\smoke-ms-settings.json'
$layoutFile = Join-Path $root 'build\smoke-ms-layout.txt'
if (Test-Path $settingsFile) { Remove-Item $settingsFile }

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

$HIDDEN = @(62, 76, 97)   # 3E4C61, a closed cell
$OPEN = @(22, 26, 32)     # 161A20, an open cell



# Starts the game window. $extra is the settings file entries after the program: seed.
function Start-Game([int]$autoClose = 240) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-p', 'tools/launch.p', '-param', "`"run/run-minesweeper.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-ms-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Minesweeper*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Minesweeper*') { throw 'The Minesweeper window did not appear.' }
    Start-Sleep -Milliseconds 800
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Get-Mines($p) { if ((Get-Title $p) -match 'Mines (-?\d+)') { [int]$Matches[1] } else { -999 } }
function Get-Time($p)  { if ((Get-Title $p) -match 'Time (\d+)') { [int]$Matches[1] } else { -1 } }
function Has-State($p, [string]$state) { return ((Get-Title $p) -match [regex]::Escape($state)) }





# The box around the closed cells in a fresh game, which is the board. Cells are Width / cols wide.
function Get-Board($p, [string]$name, [int]$cols, [int]$rows) {
    $bmp = Take-Shot $p $name
    try {
        $box = [Native]::FindColour($bmp, $HIDDEN[0], $HIDDEN[1], $HIDDEN[2], 1)
        $r = Get-WindowRect $p
        if ($box[0] -lt 0) { return $null }
        $w = $box[2] - $box[0] + 1
        $h = $box[3] - $box[1] + 1
        return [pscustomobject]@{ Left = $r.L + $box[0]; Top = $r.T + $box[1]; Cell = ($w + 1) / $cols; Width = $w; Height = $h; Cols = $cols; Rows = $rows }
    } finally { $bmp.Dispose() }
}

function Cell-Centre($board, [int]$cx, [int]$cy) {
    return @([int]($board.Left + ($cx + 0.5) * $board.Cell), [int]($board.Top + ($cy + 0.5) * $board.Cell))
}

function Click-Cell($board, [int]$cx, [int]$cy, [string]$button = 'left', [int]$pause = 300) {
    $c = Cell-Centre $board $cx $cy
    Click-Screen $c[0] $c[1] $button $pause
}

# True when the cell is drawn as open (dark) in the screenshot, false when closed (blue grey). The
# pixel is near the cell's top left corner so a glyph in the middle does not get in the way.
function Cell-IsOpen($bmp, $p, $board, [int]$cx, [int]$cy) {
    $r = Get-WindowRect $p
    $px = [int]($board.Left - $r.L + ($cx + 0.25) * $board.Cell)
    $py = [int]($board.Top - $r.T + ($cy + 0.25) * $board.Cell)
    $c = $bmp.GetPixel($px, $py)
    return ([math]::Abs($c.R - $OPEN[0]) -le 3 -and [math]::Abs($c.G - $OPEN[1]) -le 3 -and [math]::Abs($c.B - $OPEN[2]) -le 3)
}

function Cell-IsHidden($bmp, $p, $board, [int]$cx, [int]$cy) {
    $r = Get-WindowRect $p
    $px = [int]($board.Left - $r.L + ($cx + 0.25) * $board.Cell)
    $py = [int]($board.Top - $r.T + ($cy + 0.25) * $board.Cell)
    $c = $bmp.GetPixel($px, $py)
    return ([math]::Abs($c.R - $HIDDEN[0]) -le 3 -and [math]::Abs($c.G - $HIDDEN[1]) -le 3 -and [math]::Abs($c.B - $HIDDEN[2]) -le 3)
}

# Where the mines are for a seed: a 2D array of booleans, [y][x]. $restarts is how many times the
# window starts the game again after building it (a saved level does that once).
function Get-Layout([int]$restarts, [string]$level = 'Beginner') {
    if (Test-Path $layoutFile) { Remove-Item $layoutFile }
    $args = @('-b', '-T', "`"$(Get-ProgressTempDir)`"", '-p', 'tools/launch.p', '-param', "`"tools/minesweeper-layout.p,$Seed,$restarts,$layoutFile,$level`"")
    $proc = Start-Process "$Dlc\bin\_progres.exe" -ArgumentList $args -PassThru -Wait -WindowStyle Hidden
    if (-not (Test-Path $layoutFile)) { throw 'Could not get the mine layout from tools/minesweeper-layout.p.' }
    $rows = @(Get-Content $layoutFile)
    $layout = @()
    foreach ($line in $rows) { $layout += , @($line.ToCharArray() | ForEach-Object { $_ -eq '*' }) }
    return $layout
}

function Neighbours($layout, [int]$x, [int]$y) {
    $list = @()
    for ($dy = -1; $dy -le 1; $dy++) { for ($dx = -1; $dx -le 1; $dx++) {
        if ($dx -eq 0 -and $dy -eq 0) { continue }
        $nx = $x + $dx; $ny = $y + $dy
        if ($ny -ge 0 -and $ny -lt $layout.Count -and $nx -ge 0 -and $nx -lt $layout[0].Count) { $list += , @($nx, $ny) }
    } }
    return $list
}

function Adjacent($layout, [int]$x, [int]$y) {
    $n = 0
    foreach ($nb in (Neighbours $layout $x $y)) { if ($layout[$nb[1]][$nb[0]]) { $n++ } }
    return $n
}

# Picks a number cell with a closed safe neighbour, flags its mines, opens it, chords it the way
# $mode says ('both' buttons or a 'double' click) and checks the neighbour opened.
function Test-Chord($p, $layout, $board, [string]$mode, [string]$label, [int]$shotNo) {
    $shot = Take-Shot $p "smoke-ms-$shotNo-before-chord-$mode"
    $chord = $null
    try {
        for ($y = 0; $y -lt 9 -and -not $chord; $y++) { for ($x = 0; $x -lt 9 -and -not $chord; $x++) {
            if ($layout[$y][$x] -or (Adjacent $layout $x $y) -eq 0) { continue }
            foreach ($nb in (Neighbours $layout $x $y)) {
                if (-not $layout[$nb[1]][$nb[0]] -and (Cell-IsHidden $shot $p $board $nb[0] $nb[1])) { $chord = @($x, $y, $nb[0], $nb[1]); break }
            }
        } }
    } finally { $shot.Dispose() }
    Check "there is a number cell with a closed safe neighbour to chord ($label)" ($null -ne $chord)
    if (-not $chord) { return }
    $script:flagged = @()
    foreach ($nb in (Neighbours $layout $chord[0] $chord[1])) { if ($layout[$nb[1]][$nb[0]]) { Click-Cell $board $nb[0] $nb[1] 'right'; $script:flagged += "$($nb[0]),$($nb[1])" } }
    $shot = Take-Shot $p "smoke-ms-$shotNo-chord-cell-$mode"
    $needsOpen = Cell-IsHidden $shot $p $board $chord[0] $chord[1]
    $shot.Dispose()
    if ($needsOpen) { Click-Cell $board $chord[0] $chord[1] 'left' }
    $shot = Take-Shot $p "smoke-ms-$shotNo-chord-ready-$mode"
    try { Check "the neighbour is still closed before the chord ($label)" (Cell-IsHidden $shot $p $board $chord[2] $chord[3]) "neighbour ($($chord[2]),$($chord[3]))" } finally { $shot.Dispose() }
    Click-Cell $board $chord[0] $chord[1] $mode 500
    $shot = Take-Shot $p "smoke-ms-$shotNo-after-chord-$mode"
    try {
        Check "$label on a number with enough flags opens the closed neighbours" (Cell-IsOpen $shot $p $board $chord[2] $chord[3]) "neighbour ($($chord[2]),$($chord[3]))"
        Check "and the game goes on ($label)" (-not (Has-State $p 'Game over')) (Get-Title $p)
    } finally { $shot.Dispose() }
}


function Read-Settings { if (Test-Path $settingsFile) { return (Get-Content $settingsFile -Raw | ConvertFrom-Json) } return $null }

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: playing a whole game'
    # the window always starts the game once more when it applies the saved (or default) level
    $layout = Get-Layout 1
    $cols = $layout[0].Count; $rows = $layout.Count
    $mineCount = ($layout | ForEach-Object { $_ } | Where-Object { $_ }).Count
    Check 'the layout helper found 10 mines on a 9 x 9 board' ($cols -eq 9 -and $rows -eq 9 -and $mineCount -eq 10) "cols=$cols rows=$rows mines=$mineCount"

    $proc = Start-Game
    Check 'the window opens on a Beginner game, ready, with ten mines' ((Has-State $proc 'Beginner 9 x 9') -and (Get-Mines $proc) -eq 10 -and (Get-Time $proc) -eq 0 -and (Has-State $proc 'Ready')) (Get-Title $proc)
    $board = Get-Board $proc 'smoke-ms-1-start' 9 9
    Check 'the board is found on screen, 9 cells wide and tall' ($board -ne $null -and [math]::Abs($board.Width - $board.Height) -le 2) "board=$($board | ConvertTo-Json -Compress)"

    # a mine, a safe cell and a safe cell with no mines around it
    $mine = $null; $safe = $null; $blank = $null
    for ($y = 0; $y -lt 9; $y++) { for ($x = 0; $x -lt 9; $x++) {
        if ($layout[$y][$x]) { if (-not $mine) { $mine = @($x, $y) } }
        else {
            if (-not $safe) { $safe = @($x, $y) }
            if (-not $blank -and (Adjacent $layout $x $y) -eq 0) { $blank = @($x, $y) }
        }
    } }

    # flags: right click flags, again makes a question mark, a third time clears it
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'a right click flags a cell and the counter drops' ((Get-Mines $proc) -eq 9) (Get-Title $proc)
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'a second right click makes a question mark and the counter comes back' ((Get-Mines $proc) -eq 10) (Get-Title $proc)
    $shotMark = Take-Shot $proc 'smoke-ms-2-question'; $shotMark.Dispose()
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'a third right click clears it' ((Get-Mines $proc) -eq 10) (Get-Title $proc)

    # a flagged cell cannot be opened, and flagging does not start the timer
    Click-Cell $board $safe[0] $safe[1] 'right'
    Check 'flagging a safe cell drops the counter' ((Get-Mines $proc) -eq 9) (Get-Title $proc)
    Click-Cell $board $safe[0] $safe[1] 'left'
    $shot = Take-Shot $proc 'smoke-ms-3-flag-left-click'
    try { Check 'a left click on a flagged cell leaves it closed and the game not started' ((Cell-IsHidden $shot $proc $board $safe[0] $safe[1]) -and (Has-State $proc 'Ready') -and (Get-Time $proc) -eq 0) (Get-Title $proc) } finally { $shot.Dispose() }
    Click-Cell $board $safe[0] $safe[1] 'right'
    Click-Cell $board $safe[0] $safe[1] 'right'
    Check 'the flag and its question mark are cleared again' ((Get-Mines $proc) -eq 10) (Get-Title $proc)

    # the first click starts the timer, and a blank cell floods
    $first = if ($blank) { $blank } else { $safe }
    Click-Cell $board $first[0] $first[1] 'left'
    Check 'the first click starts the game with the timer at 1' ((Has-State $proc 'Playing') -and (Get-Time $proc) -ge 1) (Get-Title $proc)
    $shot = Take-Shot $proc 'smoke-ms-4-first-click'
    try {
        Check 'the clicked cell is open' (Cell-IsOpen $shot $proc $board $first[0] $first[1])
        if ($blank) {
            $nb = (Neighbours $layout $blank[0] $blank[1])[0]
            Check 'a blank cell opens its neighbours' (Cell-IsOpen $shot $proc $board $nb[0] $nb[1])
        }
    } finally { $shot.Dispose() }
    Start-Sleep -Milliseconds 2200
    Check 'the timer counts seconds' ((Get-Time $proc) -ge 3) (Get-Title $proc)

    Test-Chord $proc $layout $board 'both' 'both buttons' 5

    # win: open every safe cell. Flags on the mines are fine.
    for ($y = 0; $y -lt 9; $y++) { for ($x = 0; $x -lt 9; $x++) { if (-not $layout[$y][$x]) { Click-Cell $board $x $y 'left' 110 } } }
    Start-Sleep -Milliseconds 400
    $winTime = Get-Time $proc
    Check 'opening every safe cell wins the game' ((Has-State $proc 'You win!') -and (Get-Mines $proc) -eq 0) (Get-Title $proc)
    Check 'the title shows a best time for Beginner' ((Get-Title $proc) -match 'Best \d+s') (Get-Title $proc)
    $shotWin = Take-Shot $proc 'smoke-ms-7-won'; $shotWin.Dispose()
    Start-Sleep -Milliseconds 2200
    Check 'the timer stops when the game is won' ((Get-Time $proc) -eq $winTime) "was $winTime now $(Get-Time $proc)"

    # new game with F2
    Send-Keys '{F2}'
    Check 'F2 starts a new game: ready, timer at 0, ten mines' ((Has-State $proc 'Ready') -and (Get-Time $proc) -eq 0 -and (Get-Mines $proc) -eq 10) (Get-Title $proc)
    $shot = Take-Shot $proc 'smoke-ms-8-new-game'
    try { Check 'the new board is all closed' (Cell-IsHidden $shot $proc $board 4 4) } finally { $shot.Dispose() }
    Click-Cell $board 4 4 'left'
    Check 'the first click of a new game is always safe' ((Has-State $proc 'Playing') -and -not (Has-State $proc 'Game over')) (Get-Title $proc)

    # the level picker: Tab reaches it from the board and the arrow keys change the level
    Send-Keys '{TAB}'
    Send-Keys '{DOWN}'
    Check 'the picker changes the level to Intermediate and starts a new game' ((Has-State $proc 'Intermediate 16 x 16') -and (Get-Mines $proc) -eq 40 -and (Has-State $proc 'Ready')) (Get-Title $proc)
    $shotLevel = Take-Shot $proc 'smoke-ms-9-intermediate'; $shotLevel.Dispose()
    Send-Keys '{UP}'
    Check 'and back to Beginner' ((Has-State $proc 'Beginner 9 x 9') -and (Get-Mines $proc) -eq 10) (Get-Title $proc)

    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings after run 1'
    $json = Read-Settings
    Check 'the winning time was saved in the Beginner high score list' ($json -and ([string]$json.values.'minesweeper.scores.beginner') -match '^\d+(,\d+)*$') ($json | ConvertTo-Json -Compress)
    Check 'the level was saved' ($json -and $json.values.'minesweeper.choice' -eq 'Beginner')
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 300)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: a loss'
    $layout = Get-Layout 1
    $proc = Start-Game
    Check 'the saved best time is shown' ((Get-Title $proc) -match 'Best \d+s') (Get-Title $proc)
    $board = Get-Board $proc 'smoke-ms-10-second-run' 9 9
    $mine = $null; $safe = $null
    for ($y = 0; $y -lt 9; $y++) { for ($x = 0; $x -lt 9; $x++) {
        if ($layout[$y][$x]) { if (-not $mine) { $mine = @($x, $y) } }
        elseif (-not $safe -and (Adjacent $layout $x $y) -gt 0) { $safe = @($x, $y) }
    } }
    # the high scores screen: H opens it, it blocks the board while it is open, Escape closes it
    Send-Keys 'h'
    $shotScores = Take-Shot $proc 'smoke-ms-10b-scores'; $shotScores.Dispose()
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'while the scores screen is open the board does not react' ((Get-Mines $proc) -eq 10) (Get-Title $proc)
    Send-Keys '{ESC}'
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'Escape closes the scores screen and the board answers again' ((Get-Mines $proc) -eq 9) (Get-Title $proc)
    Click-Cell $board $mine[0] $mine[1] 'right'
    Click-Cell $board $mine[0] $mine[1] 'right'
    Check 'the flag cycle is back to nothing' ((Get-Mines $proc) -eq 10) (Get-Title $proc)

    Click-Cell $board $safe[0] $safe[1] 'left'
    Check 'a safe first click starts the game' (Has-State $proc 'Playing') (Get-Title $proc)

    # a double click on a number with all its mines flagged opens everything round it
    Test-Chord $proc $layout $board 'double' 'double click' 10

    # open a mine that the chord test did not flag
    for ($y = 0; $y -lt 9; $y++) { for ($x = 0; $x -lt 9; $x++) {
        if ($layout[$y][$x] -and ($script:flagged -notcontains "$x,$y")) { $mine = @($x, $y) }
    } }
    Click-Cell $board $mine[0] $mine[1] 'left'
    Check 'opening a mine ends the game' (Has-State $proc 'Game over') (Get-Title $proc)
    $lostTime = Get-Time $proc
    $shotLost = Take-Shot $proc 'smoke-ms-11-lost'
    try {
        $r = Get-WindowRect $proc
        $px = [int]($board.Left - $r.L + ($mine[0] + 0.25) * $board.Cell); $py = [int]($board.Top - $r.T + ($mine[1] + 0.25) * $board.Cell)
        $c = $shotLost.GetPixel($px, $py)
        Check 'the mine that was opened is drawn red' ($c.R -gt 150 -and $c.G -lt 80) "pixel $($c.R),$($c.G),$($c.B)"
    } finally { $shotLost.Dispose() }
    Start-Sleep -Milliseconds 2200
    Check 'the timer stops when the game is lost' ((Get-Time $proc) -eq $lostTime) "was $lostTime now $(Get-Time $proc)"
    $minesAtEnd = Get-Mines $proc
    Click-Cell $board $safe[0] $safe[1] 'right'
    Check 'a flag cannot be placed after the game is over' ((Get-Mines $proc) -eq $minesAtEnd) (Get-Title $proc)
    Send-Keys 'r'
    Check 'R also starts a new game' ((Has-State $proc 'Ready') -and (Get-Time $proc) -eq 0) (Get-Title $proc)
    Check 'the second window exits cleanly' (Close-Window $proc)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 3: Expert from the settings'
    Set-Content -Path $settingsFile -Value '{ "schemaVersion": 1, "values": { "minesweeper.choice": "Expert", "window.width": 1000, "window.height": 700 } }'
    $proc = Start-Game
    Check 'the saved level is Expert, 30 x 16 with 99 mines' ((Has-State $proc 'Expert 30 x 16') -and (Get-Mines $proc) -eq 99) (Get-Title $proc)
    $bigBoard = Get-Board $proc 'smoke-ms-12-expert' 30 16
    Check 'the board is drawn 30 cells wide and 16 high' ($bigBoard -ne $null -and [math]::Abs($bigBoard.Width / $bigBoard.Height - 30 / 16) -lt 0.08) "board=$($bigBoard | ConvertTo-Json -Compress)"
    Click-Cell $bigBoard 15 8 'left'
    $shotBig = Take-Shot $proc 'smoke-ms-13-expert-playing'; $shotBig.Dispose()
    Check 'a click on an Expert board starts the game' (Has-State $proc 'Playing') (Get-Title $proc)
    Check 'the third window exits cleanly' (Close-Window $proc)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 4: Custom from the settings'
    Set-Content -Path $settingsFile -Value '{ "schemaVersion": 1, "values": { "minesweeper.choice": "Custom", "minesweeper.customWidth": 20, "minesweeper.customHeight": 12, "minesweeper.customMines": 30, "minesweeper.marks": false } }'
    $proc = Start-Game
    Check 'the Custom level is 20 x 12 with 30 mines' ((Has-State $proc 'Custom 20 x 12') -and (Get-Mines $proc) -eq 30) (Get-Title $proc)
    Check 'the question mark setting is read' (Has-State $proc 'Marks off') (Get-Title $proc)
    Check 'the fourth window exits cleanly' (Close-Window $proc)
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
