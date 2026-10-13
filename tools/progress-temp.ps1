<#
.SYNOPSIS
    Where ProGriddle's launches put their OpenEdge temp files. Dot-source it, then use
    Get-ProgressTempDir for the value of the -T startup parameter.
.DESCRIPTION
    Every prowin and _progres that the tools start gets "-T <folder>", so the session's temp
    files (the DBI and srt files) go to one folder of ours instead of the working directory. The
    folder is ProGriddle under the user's TEMP folder, or C:\temp when TEMP is not set, and is
    created when it is missing. Not a script to run on its own.
#>
function Get-ProgressTempDir {
    $base = $env:TEMP
    if (-not $base) { $base = 'C:\temp' }
    $dir = Join-Path $base 'ProGriddle'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    return $dir
}
