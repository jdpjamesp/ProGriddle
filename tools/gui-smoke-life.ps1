<#
.SYNOPSIS
    Drives the real Life window like a user and checks what happens. A GUI smoke test.
.DESCRIPTION
    Launches run/run-life.p under prowin with a throwaway settings file, finds the board on
    screen, then clicks and types and reads the state back from the window title (which
    carries "Generation n   Alive n ... Speed n"). It also resizes the window, closes it,
    checks the process really exits, checks the saved settings and starts it again to see
    the settings come back. Screenshots go to build/screenshots.

    It sends real keystrokes and mouse clicks to the foreground window, so do not touch the
    keyboard or mouse while it runs (about 40 seconds). Exit code 0 when every check passes.
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
$settingsFile = Join-Path $root 'build\smoke-settings.json'
if (Test-Path $settingsFile) { Remove-Item $settingsFile }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, UIAutomationClient, UIAutomationTypes
Add-Type -ReferencedAssemblies System.Drawing @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public class Native {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint from, uint to, bool attach);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  /* The process that owns a window. An open drop-down list is a separate window of the same process. */
  public static uint PidOf(IntPtr h) { uint pid; GetWindowThreadProcessId(h, out pid); return pid; }
  /* Brings a window to the front without sending any keystrokes: Windows only lets the program that
     owns the foreground window hand it over, so this briefly shares its input queue. */
  public static bool Force(IntPtr h) {
    IntPtr fg = GetForegroundWindow();
    uint fgThread = GetWindowThreadProcessId(fg, IntPtr.Zero);
    uint me = GetCurrentThreadId();
    bool attached = (fgThread != 0 && fgThread != me) && AttachThreadInput(me, fgThread, true);
    ShowWindow(h, 9);
    BringWindowToTop(h);
    bool ok = SetForegroundWindow(h);
    if (attached) AttachThreadInput(me, fgThread, false);
    return ok;
  }
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hgt, bool repaint);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  public struct RECT { public int L, T, R, B; }
  /* Bounding box of pixels close to a colour, or -1s when none. Used to find the board's grid lines. */
  public static int[] FindColour(Bitmap bmp, int r, int g, int b, int tol) {
    BitmapData d = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1;
    byte[] row = new byte[d.Stride];
    for (int y = 0; y < bmp.Height; y++) {
      Marshal.Copy(new IntPtr(d.Scan0.ToInt64() + (long)y * d.Stride), row, 0, d.Stride);
      for (int x = 0; x < bmp.Width; x++) {
        int i = x * 4;
        if (Math.Abs(row[i + 2] - r) <= tol && Math.Abs(row[i + 1] - g) <= tol && Math.Abs(row[i] - b) <= tol) {
          if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
        }
      }
    }
    bmp.UnlockBits(d);
    return maxX < 0 ? new int[] { -1, -1, -1, -1 } : new int[] { minX, minY, maxX, maxY };
  }
}
'@
[Native]::SetProcessDPIAware() | Out-Null

$script:failures = 0
# The window the script is driving. Input is only ever sent while it is the foreground window,
# because keystrokes and clicks go to whatever is in front, which could be the editor.
$script:target = $null
function Ensure-Foreground {
    if ($null -eq $script:target) { return }
    $script:target.Refresh()
    $handle = $script:target.MainWindowHandle
    for ($i = 0; $i -lt 8; $i++) {
        # any window of the Life process will do: an open drop-down list is a window of its own
        if ([Native]::PidOf([Native]::GetForegroundWindow()) -eq $script:target.Id) { return }
        [void][Native]::Force($handle)
        Start-Sleep -Milliseconds 250
    }
    throw 'The Life window could not be brought to the front, so no input was sent. Close other windows that are stealing focus and run the test again.'
}

function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host "PASS  $name" } else { Write-Host "FAIL  $name  $detail" -ForegroundColor Red; $script:failures++ }
}

function Start-Life([int]$autoClose = 150) {
    $args = @('-T', "`"$(Get-ProgressTempDir)`"", '-p', 'tools/launch.p', '-param', "`"run/run-life.p,$settingsFile,$autoClose`"", '-clientlog', 'build/smoke-client.log')
    $p = Start-Process "$Dlc\bin\prowin.exe" -ArgumentList $args -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    do { Start-Sleep -Milliseconds 300; $p.Refresh() } until ($p.MainWindowTitle -like 'ProGriddle Life*' -or (Get-Date) -gt $deadline -or $p.HasExited)
    if ($p.HasExited -or $p.MainWindowTitle -notlike 'ProGriddle Life*') { throw 'The Life window did not appear.' }
    Start-Sleep -Milliseconds 800
    $script:target = $p
    Ensure-Foreground
    Start-Sleep -Milliseconds 300
    return $p
}

function Get-Title($p) { $p.Refresh(); return $p.MainWindowTitle }
function Get-Gen($p)   { if ((Get-Title $p) -match 'Generation (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-Alive($p) { if ((Get-Title $p) -match 'Alive (\d+)') { [int]$Matches[1] } else { -1 } }
function Get-Speed($p) { if ((Get-Title $p) -match 'Speed (\d+)') { [int]$Matches[1] } else { -1 } }

function Send-Keys([string]$keys) { Ensure-Foreground; [System.Windows.Forms.SendKeys]::SendWait($keys); Start-Sleep -Milliseconds 350 }

function Click-Screen([int]$x, [int]$y, [string]$button = 'left') {
    Ensure-Foreground
    [Native]::SetCursorPos($x, $y) | Out-Null; Start-Sleep -Milliseconds 80
    if ($button -eq 'left') { [Native]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero) }
    else { [Native]::mouse_event(8, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(16, 0, 0, 0, [UIntPtr]::Zero) }
    Start-Sleep -Milliseconds 350
}

# The lists in the toolbar, found through UI Automation by their window class (WinForms controls all
# report as plain panes), in reading order: the pattern, the rules, the board size. The toolbar may
# wrap onto a second row, so they are put in order by row first and then left to right.
function Get-Combos($p) {
    $rootEl = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    $all = $rootEl.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $list = @()
    foreach ($e in $all) { if ($e.Current.ClassName -like '*COMBOBOX*') { $list += $e.Current.BoundingRectangle } }
    return @($list | Sort-Object @{ Expression = { [math]::Round($_.Y / 25) } }, @{ Expression = { [int]$_.X } })
}

# Opens list number n (0 is the pattern list), goes to the first item, down to the one wanted (counted
# from 0) and presses Enter. Typing a name would not do: a drop down only jumps by first letter.
function Choose-Item($p, [int]$n, [int]$index) {
    $combos = Get-Combos $p
    if ($combos.Count -le $n) { throw "The toolbar has only $($combos.Count) lists, so list $n cannot be found." }
    $r = $combos[$n]
    Click-Screen ([int]($r.X + $r.Width / 2)) ([int]($r.Y + $r.Height / 2))
    Send-Keys ('{HOME}' + ('{DOWN}' * $index) + '{ENTER}')
}

function Get-WindowRect($p) { $r = New-Object Native+RECT; [Native]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null; return $r }

# Screenshot of the window, returned as a Bitmap and saved. The caller disposes the Bitmap.
function Take-Shot($p, [string]$name) {
    Ensure-Foreground
    $r = Get-WindowRect $p
    $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
    $g.Dispose()
    $bmp.Save((Join-Path $shots "$name.png"))
    return $bmp
}

# Where the board is on screen: the box around the dead cell colour (1B1F24), which fills every
# board whether or not grid lines are drawn. The control behind the board is a slightly darker
# colour (181C20), so the two can be told apart with a tolerance of 1.
function Get-Board($p, [string]$name, [int]$cols, [int]$rows) {
    $bmp = Take-Shot $p $name
    try {
        $box = [Native]::FindColour($bmp, 27, 31, 36, 1)
        $r = Get-WindowRect $p
        if ($box[0] -lt 0) { return $null }
        $w = $box[2] - $box[0] + 1
        $h = $box[3] - $box[1] + 1
        $cell = $w / $cols
        return [pscustomobject]@{ Left = $r.L + $box[0]; Top = $r.T + $box[1]; Cell = $cell; Width = $w; Height = $h }
    } finally { $bmp.Dispose() }
}

function Cell-Centre($board, [int]$cx, [int]$cy) {
    return @([int]($board.Left + ($cx + 0.5) * $board.Cell), [int]($board.Top + ($cy + 0.5) * $board.Cell))
}

$proc = $null
try {
    Write-Host '--- first run'
    $proc = Start-Life
    Check 'window appears with the starting board' ((Get-Gen $proc) -eq 0 -and (Get-Alive $proc) -eq 36) (Get-Title $proc)
    Check 'status shows default speed 3' ((Get-Speed $proc) -eq 3) (Get-Title $proc)

    $board = Get-Board $proc 'smoke-1-start' 100 70
    Check 'the board can be found on screen' ($board -ne $null)
    Check 'board is 100 x 70 cells of equal size' ($board.Cell -gt 4 -and [math]::Abs($board.Height / 70 - $board.Cell) -lt 1.5) "cell=$($board.Cell) h=$($board.Height)"

    # left click toggles a cell
    $c = Cell-Centre $board 50 40
    Click-Screen $c[0] $c[1]
    Check 'left click adds a live cell' ((Get-Alive $proc) -eq 37) (Get-Title $proc)
    Click-Screen $c[0] $c[1]
    Check 'left click again removes it' ((Get-Alive $proc) -eq 36) (Get-Title $proc)
    Click-Screen $c[0] $c[1]

    # step
    Send-Keys 's'
    Check 'S steps one generation' ((Get-Gen $proc) -eq 1) (Get-Title $proc)

    # run and pause
    Send-Keys ' '
    Start-Sleep -Milliseconds 2200
    $running = Get-Gen $proc
    Check 'Space starts it running' ($running -ge 4) "generation $running"
    $shotRun = Take-Shot $proc 'smoke-2-running'; $shotRun.Dispose()
    Send-Keys ' '
    $paused = Get-Gen $proc
    Start-Sleep -Milliseconds 1200
    Check 'Space again pauses it' ((Get-Gen $proc) -eq $paused) "generation moved from $paused to $(Get-Gen $proc)"

    # reset
    Send-Keys 'r'
    Check 'R resets to generation 0 with the board as it was at the first step' ((Get-Gen $proc) -eq 0 -and (Get-Alive $proc) -eq 37) (Get-Title $proc)

    # random and clear
    Send-Keys 'g'
    $alive = Get-Alive $proc
    Check 'G fills the board at random' ((Get-Gen $proc) -eq 0 -and $alive -gt 1200 -and $alive -lt 2400) "alive $alive"
    $shotRandom = Take-Shot $proc 'smoke-3-random'; $shotRandom.Dispose()
    Send-Keys 'c'
    Check 'C clears the board' ((Get-Alive $proc) -eq 0) (Get-Title $proc)

    # right click places the chosen pattern (a glider at the start)
    $c = Cell-Centre $board 30 30
    Click-Screen $c[0] $c[1] 'right'
    Check 'right click places the chosen pattern' ((Get-Alive $proc) -eq 5) (Get-Title $proc)
    Send-Keys 's'
    Send-Keys 's'
    Send-Keys 's'
    Send-Keys 's'
    Check 'the glider survives four steps' ((Get-Alive $proc) -eq 5 -and (Get-Gen $proc) -eq 4) (Get-Title $proc)

    # the pattern list: open it, choose Blinker, and the next right click places a Blinker (3 cells,
    # not the default Glider's 5). The offsets are where the list sits in the toolbar at the default
    # window size, so a change to the toolbar layout will show up here.
    Send-Keys 'c'
    Check 'the toolbar has three lists: the pattern, the rules and the board size' ((Get-Combos $proc).Count -eq 3) "lists: $((Get-Combos $proc).Count)"
    Choose-Item $proc 0 2    # Block, Beehive, Blinker
    $c = Cell-Centre $board 60 20
    Click-Screen $c[0] $c[1] 'right'
    Check 'choosing Blinker in the list makes the next right click place a Blinker' ((Get-Alive $proc) -eq 3) (Get-Title $proc)
    Send-Keys 'c'
    Check 'keys work again straight after using the list' ((Get-Alive $proc) -eq 0) (Get-Title $proc)
    # back to the glider for the rest of the run
    Choose-Item $proc 0 5    # Toad, Beacon, Glider
    $c = Cell-Centre $board 30 30
    Click-Screen $c[0] $c[1] 'right'
    Check 'choosing Glider again places a glider' ((Get-Alive $proc) -eq 5) (Get-Title $proc)

    # the rules list: HighLife replaces Conway's rules and the glider stays where it is
    Check 'the rules start as Conway B3/S23' ((Get-Title $proc) -match 'Rules B3/S23') (Get-Title $proc)
    Choose-Item $proc 1 1    # Conway, HighLife
    Check 'choosing HighLife in the rules list changes the rules to B36/S23' ((Get-Title $proc) -match 'Rules B36/S23') (Get-Title $proc)
    Check 'and keeps the live cells and the generation' ((Get-Alive $proc) -eq 5 -and (Get-Gen $proc) -eq 0) (Get-Title $proc)
    Send-Keys 's'
    Check 'keys work again after the rules list and the game steps by the new rules' ((Get-Gen $proc) -eq 1 -and (Get-Alive $proc) -eq 5) (Get-Title $proc)
    Send-Keys 'r'
    Choose-Item $proc 1 2    # Seeds
    Check 'Seeds is B2/S' ((Get-Title $proc) -match 'Rules B2/S ') (Get-Title $proc)
    Choose-Item $proc 1 0    # Conway
    Check 'choosing Conway puts the rules back to B3/S23' ((Get-Title $proc) -match 'Rules B3/S23') (Get-Title $proc)
    Choose-Item $proc 1 1    # HighLife again, for the settings

    # the board list: a bigger board keeps the glider and starts again at generation 0
    $before = (Get-Board $proc 'smoke-3a-before-size' 100 70).Cell
    Choose-Item $proc 2 3    # 50, 75, 100, 150
    Check 'choosing 150 x 100 in the board list makes the board 150 x 100' ((Get-Title $proc) -match '150 x 100 bounded') (Get-Title $proc)
    Check 'the live cells carry across to the bigger board and the generation is 0' ((Get-Alive $proc) -eq 5 -and (Get-Gen $proc) -eq 0) (Get-Title $proc)
    $bigBoard = Get-Board $proc 'smoke-3b-bigger-board' 150 100
    Check 'the bigger board is drawn with smaller cells' ($bigBoard -ne $null -and $bigBoard.Cell -lt $before) "before $before after $(if ($bigBoard) { $bigBoard.Cell })"
    Choose-Item $proc 2 0    # 50 x 35
    Check 'choosing 50 x 35 gives a smaller board' ((Get-Title $proc) -match '50 x 35 bounded') (Get-Title $proc)
    Choose-Item $proc 2 2    # 100 x 70
    Check 'choosing 100 x 70 goes back to the usual board' ((Get-Title $proc) -match '100 x 70 bounded') (Get-Title $proc)

    # speed keys
    Send-Keys '{ADD}'
    Send-Keys '{ADD}'
    Check 'plus raises the speed' ((Get-Speed $proc) -eq 5) (Get-Title $proc)
    Send-Keys '-'
    Check 'minus lowers the speed' ((Get-Speed $proc) -eq 4) (Get-Title $proc)
    Send-Keys '{ADD}'

    # a still life stays still and the glider moves while running at speed 5
    Send-Keys ' '
    Start-Sleep -Milliseconds 1500
    Send-Keys ' '
    Check 'running at a higher speed gets further' ((Get-Gen $proc) -gt 12) (Get-Title $proc)
    $shotGlider = Take-Shot $proc 'smoke-4-glider'; $shotGlider.Dispose()

    # resizing rescales the cells
    $r = Get-WindowRect $proc
    $before = (Get-Board $proc 'smoke-5-before-resize' 100 70).Cell
    [Native]::MoveWindow($proc.MainWindowHandle, $r.L, $r.T, 900, 700, $true) | Out-Null
    Start-Sleep -Milliseconds 800
    $afterBoard = Get-Board $proc 'smoke-6-after-resize' 100 70
    Check 'making the window smaller shrinks the cells' ($afterBoard -ne $null -and $afterBoard.Cell -lt $before) "before $before after $($afterBoard.Cell)"
    $c = Cell-Centre $afterBoard 10 10
    $aliveBefore = Get-Alive $proc
    Click-Screen $c[0] $c[1]
    Check 'clicks still land on the right cell after a resize' ((Get-Alive $proc) -eq $aliveBefore + 1) (Get-Title $proc)

    # close like the X button and make sure the process really goes away
    $sizeBeforeClose = Get-WindowRect $proc
    [void]$proc.CloseMainWindow()
    $exited = $proc.WaitForExit(10000)
    Check 'closing the window ends the process' $exited
    if (-not $exited) { $proc.Kill() }

    Write-Host '--- settings'
    Check 'a settings file was written' (Test-Path $settingsFile)
    $json = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { $null }
    Check 'it records the speed' ($json -and $json.values.'life.speed' -eq 5) ($json | ConvertTo-Json -Compress)
    Check 'it records the chosen pattern' ($json -and $json.values.'life.choice' -eq 'Glider')
    Check 'it records the chosen rules' ($json -and $json.values.'life.ruleset' -eq 'HighLife') ($json | ConvertTo-Json -Compress)
    Check 'it records the chosen board size' ($json -and $json.values.'life.size' -eq '100 x 70') ($json | ConvertTo-Json -Compress)
    Check 'it records the window size' ($json -and $json.values.'window.width' -gt 300 -and $json.values.'window.height' -gt 300)

    Write-Host '--- second run: settings come back'
    $proc = Start-Life 20
    Check 'speed is restored' ((Get-Speed $proc) -eq 5) (Get-Title $proc)
    Check 'the rules are restored' ((Get-Title $proc) -match 'Rules B36/S23') (Get-Title $proc)
    $r2 = Get-WindowRect $proc
    Check 'window size is restored' ([math]::Abs(($r2.R - $r2.L) - ($sizeBeforeClose.R - $sizeBeforeClose.L)) -le 4 -and [math]::Abs(($r2.B - $r2.T) - ($sizeBeforeClose.B - $sizeBeforeClose.T)) -le 4) "now $($r2.R-$r2.L)x$($r2.B-$r2.T), was $($sizeBeforeClose.R-$sizeBeforeClose.L)x$($sizeBeforeClose.B-$sizeBeforeClose.T)"
    $shotAgain = Take-Shot $proc 'smoke-7-second-run'; $shotAgain.Dispose()
    [void]$proc.CloseMainWindow()
    Check 'the second window also exits cleanly' ($proc.WaitForExit(10000))
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
