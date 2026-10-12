<#
.SYNOPSIS
    Shared helpers for the GUI smoke tests (tools/gui-smoke-*.ps1). Dot-source it after setting
    $Dlc and $shots. Not a test on its own.
.DESCRIPTION
    Sends real mouse clicks and keystrokes to a window, but only while that window is the
    foreground one, takes screenshots of it and keeps the pass and fail count.
#>
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
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
  public static uint PidOf(IntPtr h) { uint pid; GetWindowThreadProcessId(h, out pid); return pid; }
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
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  public struct RECT { public int L, T, R, B; }
  /* Bounding box of pixels close to a colour, or -1s when none. Used to find the board. */
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
        if ([Native]::PidOf([Native]::GetForegroundWindow()) -eq $script:target.Id) { return }
        [void][Native]::Force($handle)
        Start-Sleep -Milliseconds 250
    }
    throw 'The game window could not be brought to the front, so no input was sent. Close other windows that are stealing focus and run the test again.'
}

function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host "PASS  $name" } else { Write-Host "FAIL  $name  $detail" -ForegroundColor Red; $script:failures++ }
}

function Send-Keys([string]$keys) { Ensure-Foreground; [System.Windows.Forms.SendKeys]::SendWait($keys); Start-Sleep -Milliseconds 350 }

function Click-Screen([int]$x, [int]$y, [string]$button = 'left', [int]$pause = 300) {
    Ensure-Foreground
    [Native]::SetCursorPos($x, $y) | Out-Null; Start-Sleep -Milliseconds 60
    switch ($button) {
        'left'  { [Native]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero) }
        'right' { [Native]::mouse_event(8, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(16, 0, 0, 0, [UIntPtr]::Zero) }
        'middle' { [Native]::mouse_event(32, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(64, 0, 0, 0, [UIntPtr]::Zero) }
        # two quick left clicks on the same spot
        'double' {
            [Native]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 90
            [Native]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [Native]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
        }
        # both buttons held together, then released: the classic chord
        'both'  {
            [Native]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60
            [Native]::mouse_event(8, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60
            [Native]::mouse_event(16, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60
            [Native]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
        }
    }
    Start-Sleep -Milliseconds $pause
}

function Get-WindowRect($p) { $r = New-Object Native+RECT; [Native]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null; return $r }

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

function Close-Window($p) {
    [void]$p.CloseMainWindow()
    $exited = $p.WaitForExit(10000)
    if (-not $exited) { $p.Kill() }
    return $exited
}
