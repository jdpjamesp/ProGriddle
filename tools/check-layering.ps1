<#
.SYNOPSIS
    Fails if source files break the ProGriddle layering rules. Needs no OpenEdge install.
.DESCRIPTION
    Layers (a layer may only use the layers listed):
      Core            -> (nothing)
      Engine          -> Core
      UI.Text         -> Core, Engine
      UI.Audio        -> Core, Engine (the Windows sound player; no game may use it)
      UI.WinForms     -> Core, Engine, UI.Text, and .NET (the only layer allowed to use .NET)
      Games.<Name>    -> Core, Engine, itself. Never UI.WinForms, .NET UI types or another game.
    Progress.* (except Progress.Windows) and OpenEdge.* are always allowed.
    Every USING statement is checked, and so is any fully qualified use of a
    forbidden ProGriddle or .NET namespace elsewhere in a file.
#>
param([string]$SourceRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'src'))

$ErrorActionPreference = 'Stop'
$progriddle = Join-Path $SourceRoot 'ProGriddle'
$violations = New-Object System.Collections.Generic.List[string]

function Get-Layer([string]$relative) {
    $parts = $relative -split '[\\/]'
    switch ($parts[0]) {
        'Core'   { return 'Core' }
        'Engine' { return 'Engine' }
        'UI'     { return 'UI.' + $parts[1] }
        'Games'  { return 'Games.' + $parts[1] }
        default  { return $null }
    }
}

function Get-Allowed([string]$layer) {
    switch -Wildcard ($layer) {
        'Core'        { return @('ProGriddle.Core') }
        'Engine'      { return @('ProGriddle.Core', 'ProGriddle.Engine') }
        'UI.Text'     { return @('ProGriddle.Core', 'ProGriddle.Engine', 'ProGriddle.UI.Text') }
        'UI.Audio'    { return @('ProGriddle.Core', 'ProGriddle.Engine', 'ProGriddle.UI.Audio') }
        'UI.WinForms' { return @('ProGriddle.Core', 'ProGriddle.Engine', 'ProGriddle.UI.Text', 'ProGriddle.UI.WinForms') }
        'Games.*'     { return @('ProGriddle.Core', 'ProGriddle.Engine', ('ProGriddle.Games.' + $layer.Substring(6))) }
        default       { return @() }
    }
}

function Test-Under([string]$ns, [string]$prefix) {
    return ($ns -eq $prefix) -or $ns.StartsWith($prefix + '.')
}

$files = if (Test-Path $progriddle) { Get-ChildItem $progriddle -Recurse -Include *.cls, *.p, *.i -File } else { @() }
foreach ($file in $files) {
    $relative = $file.FullName.Substring($progriddle.Length + 1)
    $layer = Get-Layer $relative
    if (-not $layer) { continue }
    $isDotNetLayer = ($layer -eq 'UI.WinForms')
    $allowed = Get-Allowed $layer
    $lineNo = 0
    foreach ($line in Get-Content $file.FullName) {
        $lineNo++
        $code = ($line -replace '/\*.*?\*/', '') -replace '//.*$', ''
        $where = "{0}:{1}" -f $relative, $lineNo

        if ($code -match '^\s*USING\s+([A-Za-z0-9_.]+?)(\.\*)?\s*(FROM\s+(\S+))?\s*\.?\s*$') {
            $ns = $Matches[1]
            $from = $Matches[4]
            if ($from -match '^ASSEMBLY' -and -not $isDotNetLayer) {
                $violations.Add("$where  [$layer] USING from an assembly (.NET) is only allowed in UI.WinForms: $($line.Trim())")
                continue
            }
            if (Test-Under $ns 'ProGriddle') {
                # The ProGriddle root namespace on its own is not a layer.
                $ok = $false
                foreach ($a in $allowed) { if (Test-Under $ns $a) { $ok = $true } }
                if (-not $ok) { $violations.Add("$where  [$layer] may not use '$ns': $($line.Trim())") }
            }
            elseif (-not $isDotNetLayer -and ((Test-Under $ns 'System') -or (Test-Under $ns 'Progress.Windows') -or (Test-Under $ns 'Microsoft'))) {
                $violations.Add("$where  [$layer] .NET namespace '$ns' is only allowed in UI.WinForms: $($line.Trim())")
            }
            continue
        }

        if (-not $isDotNetLayer -and $code -match '\b(System\.Windows|System\.Drawing|Progress\.Windows)\.') {
            $violations.Add("$where  [$layer] .NET UI type referenced outside UI.WinForms: $($line.Trim())")
        }
        foreach ($m in [regex]::Matches($code, '\bProGriddle\.(Core|Engine|UI\.Text|UI\.Audio|UI\.WinForms|Games\.[A-Za-z0-9_]+)\b')) {
            $ns = $m.Value
            $ok = $false
            foreach ($a in $allowed) { if (Test-Under $ns $a) { $ok = $true } }
            # Declarations such as "CLASS ProGriddle.Games.Life.LifeGame:" name the file's own type.
            if (-not $ok -and $code -notmatch '^\s*(USING\s|(ROUTINE-LEVEL.*)?CLASS\s|INTERFACE\s|ENUM\s)') {
                $violations.Add("$where  [$layer] may not reference '$ns': $($line.Trim())")
            }
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "Layering check FAILED with $($violations.Count) violation(s):" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "Layering check passed ($($files.Count) files checked)."
exit 0
