<#
.SYNOPSIS
    Drives the real arcade window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-arcade.p under prowin and checks that it has a button for every game in the
    run folder and none for itself. Then it clicks the Tetris button and checks that a Tetris window
    of its own opens, that the chip shows PLAYING in green, and that it
    goes back to normal once that window is closed. It does the same with Life. Only windows this script
    started are closed, so a game you already have open is left alone.

    The games it starts use your normal settings file (they are started the way the arcade starts
    them), so closing them saves their window size and position as usual.

    It sends real keystrokes and mouse clicks to the foreground window, so do not touch the
    keyboard or mouse while it runs (under a minute). Exit code 0 when every check passes.
#>
param(
    [string]$Dlc = $(if ($env:DLC) { $env:DLC } else { 'C:\Progress\OpenEdge' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:DLC = $Dlc
. (Join-Path $PSScriptRoot 'progress-temp.ps1')
$shots = Join-Path $root 'build\screenshots'
New-Item -ItemType Directory -Force $shots | Out-Null

. (Join-Path $PSScriptRoot 'gui-smoke-common.ps1')
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

# The games the run folder should offer, by the title on the button, in the order the Cookoff lists them
# (by title, ignoring case). The title is the Arcade line of the run file, or the file name with its first
# letter capitalised, and a run file that says "Arcade: hidden" (the Cookoff itself) is left out. Nothing
# here names a game, so adding a game does not change this test.
function Get-ExpectedTitle([System.IO.FileInfo]$file) {
    $line = Get-Content $file.FullName -TotalCount 60 | Where-Object { $_ -match '^\s*Arcade:' } | Select-Object -First 1
    if ($line) {
        $tag = ($line -replace '^\s*Arcade:\s*', '').Trim()
        if ($tag -eq 'hidden') { return $null }
        $title = ($tag -split '\|')[0].Trim()
        if ($title) { return $title }
    }
    $base = $file.BaseName.Substring(4)
    return $base.Substring(0, 1).ToUpper() + $base.Substring(1)
}
$expectedTitles = @(Get-ChildItem (Join-Path $root 'run') -Filter 'run-*.p' | ForEach-Object { Get-ExpectedTitle $_ } | Where-Object { $_ } | Sort-Object { $_.ToLower() })
$expected = $expectedTitles

# The buttons of the window, found through UI Automation by their window class (WinForms controls
# all report as plain panes). Each is its text, whether it is switched on, and its place on screen.
function Get-Buttons($p) {
    $rootEl = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    $all = $rootEl.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $list = @()
    foreach ($e in $all) {
        if ($e.Current.ClassName -like '*BUTTON*') {
            $list += [pscustomobject]@{ Text = $e.Current.Name; Enabled = $e.Current.IsEnabled; Rect = $e.Current.BoundingRectangle }
        }
    }
    # automation lists them in its own order, the window shows them two to a row, left to right then down
    return @($list | Sort-Object @{ Expression = { [int]$_.Rect.Y } }, @{ Expression = { [int]$_.Rect.X } })
}

function Find-Button($p, [string]$startsWith) {
    return @(Get-Buttons $p | Where-Object { $_.Text -like "$startsWith*" })[0]
}

# True when the chip shows the green PLAYING tag: green pixels in the right hand end of the chip's box in a
# screenshot. The coloured mark at the left may be green too, so the left of the chip is not looked at.
function Test-Playing($p, $b, [string]$shotName = 'smoke-arcade-probe') {
    $bmp = Take-Shot $p $shotName
    try {
        $r = Get-WindowRect $p
        $w = [int][math]::Min(90, $b.Rect.Width)
        $x = [int]($b.Rect.X - $r.L + $b.Rect.Width - $w); $y = [int]($b.Rect.Y - $r.T)
        $h = [int]$b.Rect.Height
        if ($x -lt 0 -or $y -lt 0 -or $x + $w -gt $bmp.Width -or $y + $h -gt $bmp.Height) { return $false }
        $crop = $bmp.Clone((New-Object System.Drawing.Rectangle $x, $y, $w, $h), $bmp.PixelFormat)
        try { return ([Native]::FindColour($crop, 61, 214, 140, 24))[0] -ge 0 } finally { $crop.Dispose() }
    } finally { $bmp.Dispose() }
}

function Click-Button($b) { Click-Screen ([int]($b.Rect.X + $b.Rect.Width / 2)) ([int]($b.Rect.Y + $b.Rect.Height / 2)) 'left' 600 }

# A prowin window that was not there before, with a title starting this way.
function Wait-NewWindow([int[]]$before, [string]$titleStart, [int]$seconds = 25) {
    $deadline = (Get-Date).AddSeconds($seconds)
    do {
        Start-Sleep -Milliseconds 400
        $found = @(Get-Process prowin -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id -and $_.MainWindowTitle -like "$titleStart*" })
        if ($found.Count -gt 0) { return $found[0] }
    } while ((Get-Date) -lt $deadline)
    return $null
}

# Waits until the chip is (or is not) showing PLAYING. Returns true when it got there in time.
function Wait-Playing($p, [string]$name, [bool]$want, [int]$seconds = 8) {
    $deadline = (Get-Date).AddSeconds($seconds)
    do {
        $b = Find-Button $p $name
        if ($b -and ((Test-Playing $p $b) -eq $want)) { return $true }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    return $false
}

$arcade = $null
$game = $null
try {
    Write-Host '--- the arcade'
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-l', '1024', '-p', 'tools/launch.p', '-param', '"run/run-arcade.p,200"', '-clientlog', 'build/smoke-arcade-client.log')
    $arcade = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $arcade.Refresh() } until ($arcade.MainWindowTitle -like 'ProGriddle Cookoff*' -or (Get-Date) -gt $deadline -or $arcade.HasExited)
    if ($arcade.HasExited -or $arcade.MainWindowTitle -notlike 'ProGriddle Cookoff*') { throw 'The arcade window did not appear.' }
    Start-Sleep -Milliseconds 700
    $script:target = $arcade
    Ensure-Foreground
    $shotStart = Take-Shot $arcade 'smoke-arcade-1-start'; $shotStart.Dispose()

    $buttons = @(Get-Buttons $arcade)
    Check "the arcade has a button for each of the $($expected.Count) games in the run folder" ($buttons.Count -eq $expected.Count) "buttons: $(($buttons | ForEach-Object { $_.Text }) -join ', ')"
    $titles = @($buttons | ForEach-Object { $_.Text })
    Check "the buttons are $($expectedTitles -join ', '), in that order" (($titles -join ',') -eq ($expectedTitles -join ',')) ($titles -join ',')
    Check 'the arcade does not list itself' (($titles | Where-Object { $_ -like '*Arcade*' }).Count -eq 0)
    Check 'no game is shown as playing' (@($buttons | Where-Object { Test-Playing $arcade $_ }).Count -eq 0)

    foreach ($game in @(@('Tetris', 'ProGriddle Tetris'), @('Life', 'ProGriddle'))) {
        $name = $game[0]
        $before = @(Get-Process prowin -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
        Write-Host "--- starting $name"
        Click-Button (Find-Button $arcade $name)
        $started = Wait-NewWindow $before $game[1]
        Check "clicking $name opens a $name window of its own" ($null -ne $started) "no new window titled $($game[1])*"
        if ($null -eq $started) { continue }
        Check "the $name chip shows PLAYING in green" (Wait-Playing $arcade $name $true)
        $others = @(Get-Buttons $arcade | Where-Object { $_.Text -notlike "$name*" -and (Test-Playing $arcade $_) })
        Check 'no other game is shown as playing' ($others.Count -eq 0)
        $shotRunning = Take-Shot $arcade "smoke-arcade-2-$($name.ToLower())-playing"; $shotRunning.Dispose()

        [void]$started.CloseMainWindow()
        $exited = $started.WaitForExit(10000)
        if (-not $exited) { $started.Kill() }
        Check "the $name window closes" $exited
        Check "the $name chip goes back to normal after the game closes" (Wait-Playing $arcade $name $false)
    }

    Check 'closing the arcade ends its process' (Close-Window $arcade)
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $script:failures++
}
finally {
    if ($arcade -and -not $arcade.HasExited) { $arcade.Kill() }
}

Write-Host ''
if ($script:failures -eq 0) { Write-Host 'GUI smoke test passed.' -ForegroundColor Green; exit 0 }
Write-Host "GUI smoke test: $($script:failures) problem(s). Screenshots are in build/screenshots." -ForegroundColor Red
exit 1
