<#
.SYNOPSIS
    Scans the source for the rules of CLAUDE.md that a script can check. Needs no OpenEdge.
.DESCRIPTION
    Looks at every class under src and reports:

      - a class without a header comment (every class says what it is for)
      - a class or enum without BLOCK-LEVEL ON ERROR UNDO, THROW. (interfaces do not need it)
      - a USING that is not the wildcard form (a .NET type FROM ASSEMBLY may be named)
      - a MEMPTR in a file that never uses SET-SIZE, so cannot be freeing it
      - a public method or property whose name no test, run file or tool mentions
      - an include file under src that holds a list of &GLOBAL-DEFINE or &SCOPED-DEFINE constants (two or
        more): named values are an ENUM in a file of its own, see CLAUDE.md
      - a dash character (the long and the medium one) in code, tests, docs, scripts or run files

    The last check is the rule about no em dashes. The "name no test mentions" check is a net with
    wide holes (a name that a test mentions in passing counts), but it catches a public method that
    nothing exercises at all. Exit code 0 when nothing is reported.
.NOTES
    Part of the Phase 7 review (docs/framework/review.md). Run it before a pull request next to
    tools/check-layering.ps1.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$problems = New-Object System.Collections.Generic.List[string]
function Report([string]$kind, [string]$where) { $script:problems.Add("$kind : $where") }

$dash1 = [string][char]0x2014
$dash2 = [string][char]0x2013

# everything a test, a run file or a tool might mention a method by
$usage = ''
foreach ($f in @(Get-ChildItem tests -Recurse -Filter *.cls) + @(Get-ChildItem run -Filter *.p) + @(Get-ChildItem tools -Include *.p, *.ps1 -Recurse) + @(Get-ChildItem bench -Filter *.p -ErrorAction SilentlyContinue)) {
    $usage += (Get-Content $f.FullName -Raw) + "`n"
}

# a list of constants in an include is an enum waiting to happen (an include of shared code, such as a temp-table
# definition, has no such lines and is fine)
foreach ($f in Get-ChildItem src -Recurse -Filter *.i) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $defines = @(Select-String -Path $f.FullName -Pattern '^\s*&(GLOBAL|SCOPED)-DEFINE\s').Count
    if ($defines -ge 2) { Report 'include holds a list of constants, make it an ENUM' "$rel ($defines definitions)" }
}

foreach ($f in Get-ChildItem src -Recurse -Filter *.cls) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $text = Get-Content $f.FullName -Raw
    $lines = $text -split "`r?`n"

    if (-not $text.TrimStart().StartsWith('/*')) { Report 'no header comment' $rel }

    $isInterface = $text -match '(?m)^\s*INTERFACE\s'
    if (-not $isInterface -and $text -notmatch 'BLOCK-LEVEL ON ERROR UNDO, THROW\.' -and $text -notmatch '(?m)^\s*ENUM\s') {
        Report 'no BLOCK-LEVEL' $rel
    }

    foreach ($ln in $lines) {
        if ($ln -match '^\s*USING\s+[\w\.]+\s*\.\s*$' -and $ln -notmatch '\*\.\s*$') { Report 'USING is not the wildcard form' "$rel : $($ln.Trim())" }
    }

    if ($text -match 'AS\s+MEMPTR' -and $text -notmatch 'SET-SIZE') { Report 'MEMPTR but no SET-SIZE' $rel }

    foreach ($m in [regex]::Matches($text, '(?m)^\s*(?:METHOD\s+PUBLIC\s+(?:STATIC\s+|OVERRIDE\s+|FINAL\s+|ABSTRACT\s+)*[\w\.]+\s+(\w+)\s*\(|DEFINE\s+PUBLIC\s+PROPERTY\s+(\w+)\s)')) {
        $name = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        if ($usage -notmatch "(?i)\b$([regex]::Escape($name))\b") { Report 'public member no test mentions' "$rel : $name" }
    }
}

$dashed = @(Get-ChildItem src, tests, tools, run, docs, templates -Recurse -File -ErrorAction SilentlyContinue) + @(Get-Item README.md, CONTRIBUTING.md, CLAUDE.md, cookoff.bat)
foreach ($f in $dashed) {
    if ($f.Extension -in '.png', '.ico', '.json') { continue }
    $t = Get-Content $f.FullName -Raw -Encoding UTF8
    if ($t.Contains($dash1) -or $t.Contains($dash2)) { Report 'dash character' $f.FullName.Substring($root.Length + 1).Replace('\', '/') }
}

if ($problems.Count -eq 0) { Write-Host 'Conventions audit passed.' -ForegroundColor Green; exit 0 }
$problems | Sort-Object | ForEach-Object { Write-Host $_ -ForegroundColor Red }
Write-Host "Conventions audit: $($problems.Count) problem(s)." -ForegroundColor Red
exit 1
