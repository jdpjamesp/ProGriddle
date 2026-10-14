<#
.SYNOPSIS
    Drives the real 2048 window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-2048.p under prowin with a throwaway settings file and a fixed seed, then
    plays: the tiles are drawn in the colours of src/ProGriddle/Games/2048/TilesLook.cls, the arrow
    keys and the letters W A S D move them, a game is played with the four arrow keys in turn until
    it is over (GAME OVER, and the keys then do nothing), F2 starts a new game, the best score is
    shown and saved, and a second run reads it back. The score and the state are read from the
    window title and the tiles from screenshots. Screenshots go to build/screenshots.

    It sends real keystrokes to the foreground window, so do not touch the keyboard or mouse while
    it runs (a minute or two). Exit code 0 when every check passes.
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
$settingsFile = Join-Path $root 'build\smoke-2048-settings.json'
if (Test-Path $settingsFile) { Remove-Item $settingsFile }

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

# Starts the window. The seed makes the new tiles the same every run.
function Start-Game([int]$autoClose = 300) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-2048.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-2048-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle 2048*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle 2048*') { throw 'The 2048 window did not appear.' }
    Start-Sleep -Milliseconds 500
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Has-Text($p, [string]$text) { return ((Get-Title $p) -match [regex]::Escape($text)) }
function Get-Score($p) { if ((Get-Title $p) -match 'Score (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-Best($p) { if ((Get-Title $p) -match 'Best (\d+)') { [int]$Matches[1] } else { -1 } }
function Read-Settings { if (Test-Path $settingsFile) { return (Get-Content $settingsFile -Raw | ConvertFrom-Json) } return $null }

# A fingerprint of the window as it looks, to tell whether a key changed the picture.
function Get-Picture($p, [string]$name) {
    $bmp = Take-Shot $p $name
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash($ms.ToArray()))
    $ms.Dispose()
    return $hash
}

# True when the screenshot has pixels of the colour (a tile of that power, or the empty cell colour).
function Has-Colour($bmp, [int]$r, [int]$g, [int]$b) { return (([Native]::FindColour($bmp, $r, $g, $b, 3))[0] -ge 0) }

$proc = $null
try {
    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 1: a whole game'
    $proc = Start-Game
    Check 'the window opens with a score of 0, a best of 0 and the game playing' ((Get-Title $proc) -match 'Score 0   Best 0   Biggest tile [24]   Playing') (Get-Title $proc)

    $bmp = Take-Shot $proc 'smoke-2048-1-new-game'
    Check 'the empty cells are drawn in the empty colour' (Has-Colour $bmp 0x2A 0x31 0x3A)
    Check 'the new tiles are drawn in the colour of a 2 or a 4' ((Has-Colour $bmp 0xEE 0xE4 0xDA) -or (Has-Colour $bmp 0xED 0xE0 0xC8))
    $bmp.Dispose()

    # the letters move the tiles like the arrows: at least two of the four change the picture
    $changed = 0
    foreach ($key in @('a', 'w', 'd', 's')) {
        $before = Get-Picture $proc 'smoke-2048-2-before'
        Send-Keys $key
        if ((Get-Picture $proc 'smoke-2048-2-after') -ne $before) { $changed++ }
    }
    Check 'the letters A W D S move the tiles' ($changed -ge 2) "$changed of 4 changed the board"

    Send-Keys '{F2}'
    Check 'F2 starts a new game' (Has-Text $proc 'Score 0') (Get-Title $proc)

    # a game played to the end: the four arrow keys in turn, over and over, until the board is stuck
    $rounds = 0
    while (-not (Has-Text $proc 'Game over') -and $rounds -lt 150) {
        Send-Keys '{LEFT}{UP}{RIGHT}{DOWN}{LEFT}{UP}{RIGHT}{DOWN}'
        $rounds++
    }
    Check 'the arrow keys score points and the game ends when the board is stuck' ((Has-Text $proc 'Game over') -and (Get-Score $proc) -gt 0) "$rounds rounds, $(Get-Title $proc)"
    $final = Get-Score $proc
    $over = Take-Shot $proc 'smoke-2048-3-game-over'; $over.Dispose()
    Check 'the best score is the score of the finished game' ((Get-Best $proc) -eq $final) (Get-Title $proc)

    $stuck = Get-Picture $proc 'smoke-2048-3b-stuck'
    Send-Keys '{LEFT}{UP}{RIGHT}{DOWN}'
    Check 'after the game is over the keys do nothing' (((Get-Picture $proc 'smoke-2048-3c-stuck-after') -eq $stuck) -and (Get-Score $proc) -eq $final) (Get-Title $proc)

    Send-Keys 'r'
    Check 'R starts a new game after a game over' ((Has-Text $proc 'Score 0') -and -not (Has-Text $proc 'Game over')) (Get-Title $proc)
    Check 'the best score is kept for the new game' ((Get-Best $proc) -eq $final) (Get-Title $proc)

    Check 'closing the window ends the process' (Close-Window $proc)

    Write-Host '--- settings'
    $json = Read-Settings
    Check 'the best score was saved' ($json -and $json.values.'2048.best' -eq $final) ($json | ConvertTo-Json -Compress)
    Check 'the window size was saved' ($json -and $json.values.'window.width' -gt 200)

    # ------------------------------------------------------------------------------------------
    Write-Host '--- run 2: the settings come back'
    $proc = Start-Game
    Check 'the saved best score is shown' ((Get-Best $proc) -eq $final -and (Get-Score $proc) -eq 0) (Get-Title $proc)
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
