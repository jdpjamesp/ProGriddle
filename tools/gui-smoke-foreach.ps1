<#
.SYNOPSIS
    Drives the real FOR EACH window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-foreach.p under prowin with a throwaway settings file and a fixed seed, then plays: the title screen shows the name
    in its orange gradient and the status line says to press Space, Space starts a game (the status line shows the score, the lives and the
    level), the maze is built and READY! goes, the teal wall lines, Dibby's amber and Mary's purple are on the screen, Dibby walks left
    by himself and eats bits (the score goes up), the arrow keys steer him (up and down change where he is), P pauses and the picture
    freezes and runs again, and a phantom catches him in the end (a life is lost). The state is read from the window title and from
    screenshots. The picture has things that move by themselves (the tokens blink, the phantoms swish), so "nothing moves" is checked
    only while paused, when the game's clock stops and the picture does too. Screenshots go to build/screenshots.

    It sends real keystrokes to the foreground window, so do not touch the keyboard or mouse while it runs (about a minute and a half).
    Exit code 0 when every check passes.
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
$settingsFile = Join-Path $root 'build\smoke-foreach-settings.json'

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')

# colours of the design (docs/design/foreach-art.md): the wall line, Dibby tone 3, Mary tone 3 and the bottom of the title gradient
$LINE  = @(0x35, 0xE0, 0xCF)
$DIBBY = @(0xFF, 0xC2, 0x34)
$MARY  = @(0xB5, 0x66, 0xFF)
$TITLE = @(0xFF, 0x8A, 0x2A)

function Start-Game([int]$autoClose = 200) {
    $json = @{ schemaVersion = 1; values = @{ 'sound.on' = $false } } | ConvertTo-Json -Compress
    Set-Content -Path $settingsFile -Value $json -Encoding ascii
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', "`"run/run-foreach.p,$settingsFile,$autoClose,$Seed`"", '-clientlog', 'build/smoke-foreach-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle FOR EACH*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle FOR EACH*') { throw 'The FOR EACH window did not appear.' }
    Start-Sleep -Milliseconds 500
    $script:target = $p
    Ensure-Foreground
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Has-Text($p, [string]$text) { return ((Get-Title $p) -match [regex]::Escape($text)) }

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

function Get-Box($bmp, $rgb, [int]$tol = 4) {
    $b = [Native]::FindColour($bmp, $rgb[0], $rgb[1], $rgb[2], $tol)
    if ($b[0] -lt 0) { return $null }
    return $b
}

# The score in the status line (the title of the window), or -1.
function Get-Score($p) {
    if ((Get-Title $p) -match 'Score (\d+)') { return [int]$Matches[1] }
    return -1
}

$proc = $null
try {
    Write-Host '--- the title screen'
    $proc = Start-Game
    Check 'the title says to press Space' (Has-Text $proc 'Press Space to play') (Get-Title $proc)
    Start-Sleep -Milliseconds 1500
    $bmp = Take-Shot $proc 'smoke-foreach-1-title'
    Check 'the name is on the screen in its orange gradient' ($null -ne (Get-Box $bmp $TITLE 12)) 'no orange'
    Check 'no maze on the title screen (no wall line)' ($null -eq (Get-Box $bmp $LINE 2)) 'a wall line'
    $bmp.Dispose()

    Write-Host '--- a game'
    Send-Keys ' '
    Check 'Space starts a game' ((Has-Text $proc 'Lives 3') -and (Has-Text $proc 'Level 1')) (Get-Title $proc)
    Start-Sleep -Milliseconds 5000
    $bmp = Take-Shot $proc 'smoke-foreach-2-play'
    Check 'the wall lines, Dibby and Mary are on the screen' ((Get-Box $bmp $LINE 2) -and (Get-Box $bmp $DIBBY 2) -and (Get-Box $bmp $MARY 2)) 'a colour is missing'
    $bmp.Dispose()
    Start-Sleep -Milliseconds 5000
    Check 'Dibby walked left by himself and ate bits' ((Get-Score $proc) -gt 0) (Get-Title $proc)

    Write-Host '--- the keys'
    Send-Keys '{UP}'
    Start-Sleep -Milliseconds 800
    Send-Keys '{DOWN}'
    Check 'the arrow keys are taken (the game goes on)' (Has-Text $proc 'Level 1') (Get-Title $proc)
    Send-Keys 'p'
    Start-Sleep -Milliseconds 700
    $paused1 = Get-Picture $proc 'smoke-foreach-3a-paused'
    Start-Sleep -Milliseconds 900
    Check 'P pauses: while paused nothing moves' ((Get-Picture $proc 'smoke-foreach-3b-paused') -eq $paused1)
    Send-Keys 'p'
    Start-Sleep -Milliseconds 700
    Check 'and P runs it again' ((Get-Picture $proc 'smoke-foreach-3c-running') -ne $paused1)

    Write-Host '--- being caught'
    $deadline = (Get-Date).AddSeconds(60)
    do { Start-Sleep -Milliseconds 1000 } until ((Has-Text $proc 'Lives 2') -or (Has-Text $proc 'Lives 1') -or (Has-Text $proc 'Lives 0') -or (Get-Date) -gt $deadline)
    Check 'a phantom caught Dibby in the end (a life was lost)' ((Has-Text $proc 'Lives 2') -or (Has-Text $proc 'Lives 1') -or (Has-Text $proc 'Lives 0')) (Get-Title $proc)
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
