<#
.SYNOPSIS
    Drives the real Battleships window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-battleships.p under prowin with a throwaway settings file and a fixed seed,
    asks tools/battleships-layout.p where the computer's ships are, then plays: placing the fleet
    with the mouse (a refused placement, rotating, taking a ship back), firing, a repeat shot,
    marking water with a right click and with the Water command, the rules screen, sinking a
    ship, winning, a new game, the board size picker and the saved settings. It reads the state
    back from the window title, which carries the status line, and from cell colours in a
    screenshot. Screenshots go to build/screenshots.

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
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null
$settingsFile = Join-Path $root 'build\smoke-bs-settings.json'
$layoutFile = Join-Path $root 'build\smoke-bs-layout.txt'
if (Test-Path $settingsFile) { Remove-Item $settingsFile }

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

$WATER = @(46, 79, 110)   # 2E4F6E, unshot water on the computer's board (and a marked cell)

# Starts the window. The seed makes the computer's fleet the one the layout helper reports.
function Start-Game([int]$autoClose = 300) {
    $args = @('-p', 'tools/launch.p', '-param', "`"run/run-battleships.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-bs-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Battleships*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Battleships*') { throw 'The Battleships window did not appear.' }
    Start-Sleep -Milliseconds 800
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Has-Text($p, [string]$text) { return ((Get-Title $p) -match [regex]::Escape($text)) }
function Get-ToPlace($p) { if ((Get-Title $p) -match 'Ships to place (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-Shots($p)   { if ((Get-Title $p) -match 'Shots (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-EnemyLeft($p) { if ((Get-Title $p) -match 'Enemy ships left (\d+) of') { [int]$Matches[1] } else { -1 } }

# The box around the computer's unshot water in a fresh game: that is the computer's board. A cell
# is Width / cols wide, and your own board starts 11 cells further right (10 across plus the divider).
function Get-Board($p, [string]$name, [int]$side) {
    $bmp = Take-Shot $p $name
    try {
        $box = [Native]::FindColour($bmp, $WATER[0], $WATER[1], $WATER[2], 1)
        $r = Get-WindowRect $p
        if ($box[0] -lt 0) { return $null }
        $w = $box[2] - $box[0] + 1
        $h = $box[3] - $box[1] + 1
        return [pscustomobject]@{ Left = $r.L + $box[0]; Top = $r.T + $box[1]; Cell = ($w + 1) / $side; Width = $w; Height = $h; Side = $side }
    } finally { $bmp.Dispose() }
}

# (x, y) on the computer's board, or on your own board when $own is set.
function Click-Cell($board, [int]$cx, [int]$cy, [string]$button = 'left', [bool]$own = $false, [int]$pause = 300) {
    $col = if ($own) { $board.Side + 1 + $cx } else { $cx }
    $px = [int]($board.Left + ($col + 0.5) * $board.Cell)
    $py = [int]($board.Top + ($cy + 0.5) * $board.Cell)
    Click-Screen $px $py $button $pause
}

# The colour of a cell in a screenshot, sampled near its top left corner so a glyph does not get in the way.
function Cell-Colour($bmp, $p, $board, [int]$cx, [int]$cy, [bool]$own = $false) {
    $r = Get-WindowRect $p
    $col = if ($own) { $board.Side + 1 + $cx } else { $cx }
    $px = [int]($board.Left - $r.L + ($col + 0.25) * $board.Cell)
    $py = [int]($board.Top - $r.T + ($cy + 0.25) * $board.Cell)
    return $bmp.GetPixel($px, $py)
}

function Near($c, [int[]]$rgb, [int]$tol = 4) {
    return ([math]::Abs($c.R - $rgb[0]) -le $tol -and [math]::Abs($c.G - $rgb[1]) -le $tol -and [math]::Abs($c.B - $rgb[2]) -le $tol)
}

# The computer's ships for a seed: a 2D array [y][x] of ship numbers, 0 for water.
function Get-Layout([int]$restarts, [string]$size = 'Classic') {
    if (Test-Path $layoutFile) { Remove-Item $layoutFile }
    $args = @('-b', '-p', 'tools/launch.p', '-param', "`"tools/battleships-layout.p,$Seed,$restarts,$layoutFile,$size`"")
    Start-Process "$Dlc\bin\_progres.exe" -ArgumentList $args -PassThru -Wait -WindowStyle Hidden | Out-Null
    if (-not (Test-Path $layoutFile)) { throw 'Could not get the ship layout from tools/battleships-layout.p.' }
    $layout = @()
    foreach ($line in @(Get-Content $layoutFile)) { $layout += , @($line.ToCharArray() | ForEach-Object { if ($_ -eq '.') { 0 } else { [int][string]$_ } }) }
    return $layout
}

function Cells-Of($layout, [int]$ship) {
    $cells = @()
    for ($y = 0; $y -lt $layout.Count; $y++) { for ($x = 0; $x -lt $layout[0].Count; $x++) { if ($layout[$y][$x] -eq $ship) { $cells += , @($x, $y) } } }
    return $cells
}

function Read-Settings { if (Test-Path $settingsFile) { return (Get-Content $settingsFile -Raw | ConvertFrom-Json) } return $null }

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: a whole game'
    # the window starts a new game once when it applies the saved (here the default) size
    $layout = Get-Layout 1
    $shipIds = @($layout | ForEach-Object { $_ } | Where-Object { $_ -ne 0 } | Sort-Object -Unique)
    $shipCells = @($layout | ForEach-Object { $_ } | Where-Object { $_ -ne 0 }).Count
    Check 'the layout helper found five ships and 17 ship cells on a 10 x 10 board' ($layout.Count -eq 10 -and $shipIds.Count -eq 5 -and $shipCells -eq 17) "ships=$($shipIds.Count) cells=$shipCells"

    $proc = Start-Game
    Check 'the window opens on a Classic game asking for the first ship' ((Has-Text $proc 'Classic 10 x 10') -and (Has-Text $proc 'Place your 5-cell ship, horizontal') -and (Get-ToPlace $proc) -eq 5) (Get-Title $proc)
    $board = Get-Board $proc 'smoke-bs-1-start' 10
    Check 'the computer board is found on screen, ten cells across' ($null -ne $board -and [math]::Abs($board.Width - $board.Height) -le 2) "board=$($board | ConvertTo-Json -Compress)"

    # firing before the fleet is placed does nothing
    $water = $null
    for ($y = 0; $y -lt 10 -and -not $water; $y++) { for ($x = 0; $x -lt 10 -and -not $water; $x++) { if ($layout[$y][$x] -eq 0) { $water = @($x, $y) } } }
    Click-Cell $board $water[0] $water[1] 'left'
    Check 'firing before the fleet is placed does nothing' ((Get-Shots $proc) -eq -1 -and (Get-ToPlace $proc) -eq 5) (Get-Title $proc)

    # placing: the 5-ship across the top, then a touching ship is refused
    Click-Cell $board 0 0 'left' $true
    Check 'a left click on your board places the first ship' ((Get-ToPlace $proc) -eq 4 -and (Has-Text $proc 'Place your 4-cell ship')) (Get-Title $proc)
    Click-Cell $board 0 1 'left' $true
    Check 'a ship that would touch the first is refused' ((Get-ToPlace $proc) -eq 4) (Get-Title $proc)
    Click-Cell $board 5 1 'left' $true
    Check 'so is one that touches at a corner' ((Get-ToPlace $proc) -eq 4) (Get-Title $proc)
    $shotRefused = Take-Shot $proc 'smoke-bs-2-refused'; $shotRefused.Dispose()

    # rotating: the 4-ship goes down the right-hand side
    Send-Keys 'o'
    Check 'O turns the next ship vertical' (Has-Text $proc 'vertical') (Get-Title $proc)
    Click-Cell $board 9 0 'left' $true
    Check 'a vertical ship is placed' ((Get-ToPlace $proc) -eq 3) (Get-Title $proc)
    Send-Keys 'o'
    Check 'O turns it back to horizontal' (Has-Text $proc 'horizontal') (Get-Title $proc)

    # the rest go in rows two apart
    Click-Cell $board 0 2 'left' $true
    Click-Cell $board 0 4 'left' $true
    Click-Cell $board 0 6 'left' $true
    Check 'all five ships are placed and the game says the fleet is ready' ((Has-Text $proc 'Fleet ready') -and (Get-ToPlace $proc) -eq -1) (Get-Title $proc)
    $shotReady = Take-Shot $proc 'smoke-bs-3-ready'; $shotReady.Dispose()

    # a right click on your own ship takes it back
    Click-Cell $board 1 6 'right' $true
    Check 'a right click on your own ship takes it back' ((Get-ToPlace $proc) -eq 1 -and (Has-Text $proc 'Place your 2-cell ship')) (Get-Title $proc)
    Click-Cell $board 0 6 'left' $true
    Check 'and it can be placed again' (Has-Text $proc 'Fleet ready') (Get-Title $proc)

    # the Random command replaces the fleet, Clear takes it off, and it is placed by hand again
    Send-Keys 'f'
    Check 'F places the whole fleet at random' (Has-Text $proc 'Fleet ready') (Get-Title $proc)
    Send-Keys 'c'
    Check 'C takes the whole fleet off' ((Get-ToPlace $proc) -eq 5) (Get-Title $proc)
    Click-Cell $board 0 0 'left' $true
    Send-Keys 'o'
    Click-Cell $board 9 0 'left' $true
    Send-Keys 'o'
    Click-Cell $board 0 2 'left' $true
    Click-Cell $board 0 4 'left' $true
    Click-Cell $board 0 6 'left' $true
    Check 'the fleet is placed by hand again' (Has-Text $proc 'Fleet ready') (Get-Title $proc)

    # the rules screen
    Send-Keys 'h'
    $shotRules = Take-Shot $proc 'smoke-bs-4-rules'; $shotRules.Dispose()
    Click-Cell $board $water[0] $water[1] 'left'
    Check 'while the rules are open the board does not react' ((Get-Shots $proc) -eq -1) (Get-Title $proc)
    Send-Keys '{ESC}'

    # the first shot: water
    Click-Cell $board $water[0] $water[1] 'left'
    Check 'a shot at water is a miss and the computer fires back' ((Get-Shots $proc) -eq 1 -and (Has-Text $proc 'You missed. Computer ')) (Get-Title $proc)
    $shot = Take-Shot $proc 'smoke-bs-5-first-shot'
    try { Check 'the missed cell is drawn as a miss' (-not (Near (Cell-Colour $shot $proc $board $water[0] $water[1]) $WATER)) } finally { $shot.Dispose() }
    Click-Cell $board $water[0] $water[1] 'left'
    Check 'firing at the same cell again does nothing' ((Get-Shots $proc) -eq 1) (Get-Title $proc)

    # a hit
    $ship1 = Cells-Of $layout $shipIds[0]
    Click-Cell $board $ship1[0][0] $ship1[0][1] 'left'
    Check 'a shot at a ship is a hit' ((Get-Shots $proc) -eq 2 -and (Has-Text $proc 'You hit a ship')) (Get-Title $proc)

    # marking water: by hand with a right click, and the corners of the hit with W
    $mark = $null
    for ($y = 0; $y -lt 10 -and -not $mark; $y++) { for ($x = 0; $x -lt 10 -and -not $mark; $x++) { if ($layout[$y][$x] -eq 0 -and "$x,$y" -ne "$($water[0]),$($water[1])" -and [math]::Abs($x - $ship1[0][0]) -gt 2) { $mark = @($x, $y) } } }
    Click-Cell $board $mark[0] $mark[1] 'right'
    Click-Cell $board $mark[0] $mark[1] 'left'
    Check 'a cell marked as water cannot be fired at' ((Get-Shots $proc) -eq 2) (Get-Title $proc)
    Click-Cell $board $mark[0] $mark[1] 'right'
    Send-Keys 'w'
    $corner = $null
    foreach ($d in @(@(1, 1), @(-1, 1), @(1, -1), @(-1, -1))) {
        $cx = $ship1[0][0] + $d[0]; $cy = $ship1[0][1] + $d[1]
        if ($cx -ge 0 -and $cx -lt 10 -and $cy -ge 0 -and $cy -lt 10 -and $layout[$cy][$cx] -eq 0) { $corner = @($cx, $cy); break }
    }
    Click-Cell $board $corner[0] $corner[1] 'left'
    Check 'W marks the corners of a hit as water, so they cannot be fired at' ((Get-Shots $proc) -eq 2) (Get-Title $proc)
    $shotWater = Take-Shot $proc 'smoke-bs-6-water'; $shotWater.Dispose()

    # sink the first ship
    for ($i = 1; $i -lt $ship1.Count; $i++) { Click-Cell $board $ship1[$i][0] $ship1[$i][1] 'left' }
    Check 'hitting every cell of a ship sinks it' ((Has-Text $proc "You sank a $($ship1.Count)-cell ship") -and (Get-EnemyLeft $proc) -eq 4) (Get-Title $proc)
    Send-Keys 'w'
    $shotSunk = Take-Shot $proc 'smoke-bs-7-sunk'; $shotSunk.Dispose()

    # win: sink the rest
    for ($k = 1; $k -lt $shipIds.Count; $k++) { foreach ($c in (Cells-Of $layout $shipIds[$k])) { if (-not (Has-Text $proc 'You win')) { Click-Cell $board $c[0] $c[1] 'left' 150 } } }
    Start-Sleep -Milliseconds 400
    Check 'sinking every ship wins the game' (Has-Text $proc 'You win in') (Get-Title $proc)
    $shotWin = Take-Shot $proc 'smoke-bs-8-won'; $shotWin.Dispose()
    $shotsAtWin = Get-Shots $proc

    # new game
    Send-Keys '{F2}'
    Check 'F2 starts a new game that asks for a fleet again' ((Has-Text $proc 'Place your 5-cell ship') -and (Get-ToPlace $proc) -eq 5) (Get-Title $proc)

    # the board size picker: Tab reaches it from the board and the arrow keys change it
    Send-Keys '{TAB}'
    Send-Keys '{DOWN}'
    Check 'the picker changes the board to Large with its bigger fleet' ((Has-Text $proc 'Large 12 x 12') -and (Get-ToPlace $proc) -eq 7) (Get-Title $proc)
    $shotLarge = Take-Shot $proc 'smoke-bs-9-large'; $shotLarge.Dispose()
    Send-Keys '{UP}'
    Send-Keys '{UP}'
    Check 'and a smaller one, Small, with fewer ships' ((Has-Text $proc 'Small 8 x 8') -and (Get-ToPlace $proc) -eq 4) (Get-Title $proc)
    $shotSmall = Take-Shot $proc 'smoke-bs-10-small'; $shotSmall.Dispose()
    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings'
    $json = Read-Settings
    Check 'the board size was saved' ($json -and $json.values.'battleships.choice' -eq 'Small') ($json | ConvertTo-Json -Compress)
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 300)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: the size comes back'
    $proc = Start-Game
    Check 'the saved size is Small, 8 x 8 with four ships' ((Has-Text $proc 'Small 8 x 8') -and (Get-ToPlace $proc) -eq 4) (Get-Title $proc)
    Send-Keys 'f'
    $board2 = Get-Board $proc 'smoke-bs-11-second-run' 8
    Check 'a random fleet on the small board is ready to play' (Has-Text $proc 'Fleet ready') (Get-Title $proc)
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
