<#
.SYNOPSIS
    Turns the designer's Blast Buddies art file into ABL classes. Needs no OpenEdge install.
.DESCRIPTION
    Reads docs/design/blast-buddies-art.md and writes, under src/ProGriddle/Games/BlastBuddies:
      BuddiesArt.cls     every sprite: its rows, size, origin, legend and tone row, by name
      BuddiesLook.cls    the tone rows and the named colours
      BuddyTint.cls      an enum with one member for each named colour
      ThemeKey.cls       an enum with one member for each key of the terrain themes
      TerrainThemes.cls  the colours of the three themes (Meadow, Canyon, Candy) by key
    The files are generated: change the design file and run this again, never edit them by hand.
    The sprite blocks are the "#### name (W x H, origin (x, y))" headings, each followed by a Legend line and a fenced block of rows.
.PARAMETER Check
    Writes nothing and fails if the files on disk are not what the design file would generate.
#>
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$design = Join-Path $root 'docs\design\blast-buddies-art.md'
$outDir = Join-Path $root 'src\ProGriddle\Games\BlastBuddies'
$lines = [IO.File]::ReadAllLines($design)

function Get-Hex([string]$text) { return $text.Trim('`', ' ').ToUpperInvariant() }

# CamelCase for an enum member: "Lens Shade" and "sky_top" become LensShade and SkyTop
function Get-Member([string]$text) {
    $parts = $text -split '[\s_]+' | Where-Object { $_ -ne '' }
    return (($parts | ForEach-Object { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) }) -join '')
}

# ---- sprites ----
$sprites = New-Object System.Collections.Generic.List[object]
$i = 0
while ($i -lt $lines.Length) {
    if ($lines[$i] -match '^#### (\S+) \((\d+) x (\d+), origin \((-?\d+), (-?\d+)\)\)') {
        $name = $Matches[1]; $w = [int]$Matches[2]; $h = [int]$Matches[3]; $ox = [int]$Matches[4]; $oy = [int]$Matches[5]
        $j = $i + 1
        while ($j -lt $lines.Length -and $lines[$j] -notmatch '^Legend:' -and $lines[$j] -notmatch '^#') { $j++ }
        if ($j -ge $lines.Length -or $lines[$j] -notmatch '^Legend:') { throw "Sprite $name has no Legend line" }
        $legendLine = $lines[$j]
        $tone = ''
        if ($legendLine -match '\*\*(\w+)\*\*') { $tone = $Matches[1] }
        $pairs = New-Object System.Collections.Generic.List[string]
        foreach ($m in [regex]::Matches($legendLine, '`([A-Z])`[^`]*`([0-9A-Fa-f]{6})`')) {
            $pairs.Add($m.Groups[1].Value + '=' + $m.Groups[2].Value.ToUpperInvariant())
        }
        while ($j -lt $lines.Length -and $lines[$j] -ne '```') { $j++ }
        $j++
        $rows = New-Object System.Collections.Generic.List[string]
        while ($j -lt $lines.Length -and $lines[$j] -ne '```') { $rows.Add($lines[$j].Trim()); $j++ }
        if ($rows.Count -ne $h) { throw "Sprite $name has $($rows.Count) rows, not $h" }
        foreach ($r in $rows) { if ($r.Length -ne $w) { throw "Sprite $name has a row of $($r.Length) pixels, not $w" } }
        $sprites.Add([pscustomobject]@{ Name = $name; W = $w; H = $h; OX = $ox; OY = $oy; Tone = $tone; Legend = ($pairs -join ','); Rows = ($rows -join '/') })
        $i = $j
    }
    $i++
}
if ($sprites.Count -eq 0) { throw 'No sprites found' }

# ---- tone rows and named colours ----
function Get-TableRows([string]$heading) {
    $start = [Array]::FindIndex($lines, [Predicate[string]] { param($l) $l -eq $heading })
    if ($start -lt 0) { throw "No heading $heading" }
    $out = New-Object System.Collections.Generic.List[object]
    for ($k = $start + 1; $k -lt $lines.Length; $k++) {
        if ($lines[$k] -match '^#') { break }
        if ($lines[$k] -match '^\|' -and $lines[$k] -notmatch '^\|\s*-' ) {
            $cells = ($lines[$k].Trim().Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
            $out.Add($cells)
        }
    }
    return $out
}

$tones = New-Object System.Collections.Generic.List[object]
foreach ($c in (Get-TableRows '### 1.1 Colour rows (tones 1 to 5)')) {
    if ($c[0] -eq 'Row') { continue }
    $tones.Add([pscustomobject]@{ Name = $c[0]; Hex = ((1..5 | ForEach-Object { Get-Hex $c[$_] }) -join ',') })
}
$tints = New-Object System.Collections.Generic.List[object]
foreach ($c in (Get-TableRows '### 1.2 Named colours')) {
    if ($c[0] -eq 'Name') { continue }
    $tints.Add([pscustomobject]@{ Name = $c[0]; Member = (Get-Member $c[0]); Hex = (Get-Hex $c[1]) })
}
$themeRows = New-Object System.Collections.Generic.List[object]
foreach ($c in (Get-TableRows '### 2.4 Three themes')) {
    if ($c[0] -eq 'Key') { continue }
    $themeRows.Add([pscustomobject]@{ Key = $c[0]; Member = (Get-Member $c[0]); Meadow = (Get-Hex $c[2]); Canyon = (Get-Hex $c[3]); Candy = (Get-Hex $c[4]) })
}
if ($tones.Count -lt 10 -or $tints.Count -lt 40 -or $themeRows.Count -lt 25) { throw "Tables look wrong: $($tones.Count) tone rows, $($tints.Count) colours, $($themeRows.Count) theme keys" }

# every tone row a sprite names must exist
foreach ($s in $sprites) { if ($s.Tone -ne '' -and -not ($tones | Where-Object { $_.Name -eq $s.Tone })) { throw "Sprite $($s.Name) names the unknown tone row $($s.Tone)" } }

# ---- writing the classes ----
$header = 'Generated by tools/gen-blast-art.ps1 from docs/design/blast-buddies-art.md. Do not edit by hand: change the design and run the script again.'
$files = [ordered]@{}

# BuddiesArt
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* The pictures of Blast Buddies, by name: every sprite of the design, as the rows of a Tile (see there) with its size, its origin")
[void]$sb.AppendLine("   (the column and row of the point that stands on the ground, one row below the picture for anything that stands), the letters")
[void]$sb.AppendLine("   of its legend as 'A=RRGGBB' pairs and the name of the tone row its digits 1 to 5 use ('' when it has none). $header */")
[void]$sb.AppendLine('USING Progress.Lang.*.')
[void]$sb.AppendLine('USING ProGriddle.Core.*.')
[void]$sb.AppendLine('USING ProGriddle.Engine.*.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('BLOCK-LEVEL ON ERROR UNDO, THROW.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('CLASS ProGriddle.Games.BlastBuddies.BuddiesArt FINAL:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* every sprite name, in the order of the design */')
[void]$sb.AppendLine('    DEFINE PRIVATE STATIC VARIABLE sNames AS CHARACTER NO-UNDO INITIAL "' + (($sprites | ForEach-Object { $_.Name }) -join ',') + '".')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* How many sprites there are. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC INTEGER Count():')
[void]$sb.AppendLine("        RETURN $($sprites.Count).")
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* The name of sprite 1 to Count. Throws GridException outside that. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC CHARACTER NameAt(INPUT piIndex AS INTEGER):')
[void]$sb.AppendLine('        IF piIndex = ? OR piIndex < 1 OR piIndex > Count() THEN UNDO, THROW NEW GridException("There is no sprite " + STRING(piIndex)).')
[void]$sb.AppendLine('        RETURN ENTRY(piIndex, sNames).')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* True when the design has a sprite of that name. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC LOGICAL Has(INPUT pcName AS CHARACTER):')
[void]$sb.AppendLine('        RETURN pcName <> ? AND pcName <> "" AND LOOKUP(pcName, sNames) > 0.')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
foreach ($m in @(
    @('Width', 'INTEGER', 1, 'The width of a sprite in pixels.'),
    @('Height', 'INTEGER', 2, 'The height of a sprite in pixels.'),
    @('OriginX', 'INTEGER', 3, 'The column of a sprite''s origin.'),
    @('OriginY', 'INTEGER', 4, 'The row of a sprite''s origin.'),
    @('ToneRow', 'CHARACTER', 5, 'The name of the tone row (see BuddiesLook) the digits 1 to 5 of a sprite use, or "" for none.'),
    @('Legend', 'CHARACTER', 6, 'The legend of a sprite as Tile:Colourise reads it, "A=RRGGBB,B=RRGGBB" ("" for none).'),
    @('Rows', 'CHARACTER', 7, 'The rows of a sprite as Tile reads them, separated by "/".'))) {
    [void]$sb.AppendLine("    /* $($m[3]) Throws GridException for a sprite that is not in the design. */")
    $cast1 = if ($m[1] -eq 'INTEGER') { 'INTEGER(' } else { '' }
    $cast2 = if ($m[1] -eq 'INTEGER') { ')' } else { '' }
    [void]$sb.AppendLine("    METHOD PUBLIC STATIC $($m[1]) $($m[0])(INPUT pcName AS CHARACTER):")
    [void]$sb.AppendLine("        RETURN $cast1`ENTRY($($m[2]), Spec(pcName), `"|`")$cast2.")
    [void]$sb.AppendLine('    END METHOD.')
    [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('    /* The picture of a sprite as a Tile. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC Tile TileOf(INPUT pcName AS CHARACTER):')
[void]$sb.AppendLine('        RETURN NEW Tile(Rows(pcName)).')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* width|height|origin x|origin y|tone row|legend|rows, one string for each sprite. */')
[void]$sb.AppendLine('    METHOD PRIVATE STATIC CHARACTER Spec(INPUT pcName AS CHARACTER):')
[void]$sb.AppendLine('        IF pcName = ? THEN UNDO, THROW NEW GridException("A sprite needs a name").')
[void]$sb.AppendLine('        CASE pcName:')
foreach ($s in $sprites) {
    [void]$sb.AppendLine("            WHEN `"$($s.Name)`" THEN RETURN `"$($s.W)|$($s.H)|$($s.OX)|$($s.OY)|$($s.Tone)|$($s.Legend)|$($s.Rows)`".")
}
[void]$sb.AppendLine('            OTHERWISE UNDO, THROW NEW GridException("There is no sprite called " + pcName).')
[void]$sb.AppendLine('        END CASE.')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('END CLASS.')
$files['BuddiesArt.cls'] = $sb.ToString()

# BuddyTint (enum)
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* The named colours of Blast Buddies, one member for each (the order of the design's table). BuddiesLook:Colour gives the 0xRRGGBB")
[void]$sb.AppendLine("   number of one. $header */")
[void]$sb.AppendLine('ENUM ProGriddle.Games.BlastBuddies.BuddyTint:')
[void]$sb.AppendLine('')
$memberLines = @(); $k = 0
foreach ($t in $tints) { $memberLines += $(if ($k -eq 0) { "    DEFINE ENUM $($t.Member) = 0" } else { "                $($t.Member)" }); $k++ }
[void]$sb.AppendLine(($memberLines -join "`r`n") + '.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('END ENUM.')
$files['BuddyTint.cls'] = $sb.ToString()

# BuddiesLook
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* The colours of Blast Buddies: the tone rows (five hex colours from the lightest to the darkest, as Tile:Colourise reads them) by name,")
[void]$sb.AppendLine("   and the named colours (BuddyTint) as 0xRRGGBB numbers. $header */")
[void]$sb.AppendLine('USING Progress.Lang.*.')
[void]$sb.AppendLine('USING ProGriddle.Core.*.')
[void]$sb.AppendLine('USING ProGriddle.Engine.*.')
[void]$sb.AppendLine('USING ProGriddle.Games.BlastBuddies.*.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('BLOCK-LEVEL ON ERROR UNDO, THROW.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('CLASS ProGriddle.Games.BlastBuddies.BuddiesLook FINAL:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    DEFINE PRIVATE STATIC VARIABLE sColour AS INTEGER NO-UNDO EXTENT ' + $tints.Count + '.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    CONSTRUCTOR STATIC BuddiesLook():')
$n = 0
foreach ($t in $tints) { $n++; [void]$sb.AppendLine("        sColour[$n] = ColourMath:FromHex(`"$($t.Hex)`").") }
[void]$sb.AppendLine('    END CONSTRUCTOR.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* The names of the tone rows, as a comma list. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC CHARACTER ToneRowNames():')
[void]$sb.AppendLine('        RETURN "' + (($tones | ForEach-Object { $_.Name }) -join ',') + '".')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* The five hex colours of a tone row, lightest first, for Tile:Colourise. Throws GridException for an unknown row. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC CHARACTER ToneRow(INPUT pcName AS CHARACTER):')
[void]$sb.AppendLine('        IF pcName = ? THEN UNDO, THROW NEW GridException("A tone row needs a name").')
[void]$sb.AppendLine('        CASE pcName:')
foreach ($t in $tones) { [void]$sb.AppendLine("            WHEN `"$($t.Name)`" THEN RETURN `"$($t.Hex)`".") }
[void]$sb.AppendLine('            OTHERWISE UNDO, THROW NEW GridException("There is no tone row called " + pcName).')
[void]$sb.AppendLine('        END CASE.')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* The 0xRRGGBB number of a named colour. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS BuddyTint):')
[void]$sb.AppendLine('        IF NOT VALID-OBJECT(poTint) THEN UNDO, THROW NEW GridException("A colour needs a name").')
[void]$sb.AppendLine('        RETURN sColour[INTEGER(poTint) + 1].')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('END CLASS.')
$files['BuddiesLook.cls'] = $sb.ToString()

# ThemeKey (enum)
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* The keys of the terrain themes of Blast Buddies (sky, ground bands, speckles, water and so on), one member for each, in the order of")
[void]$sb.AppendLine("   the design's table. TerrainThemes:Colour gives the colour of a key in a theme. $header */")
[void]$sb.AppendLine('ENUM ProGriddle.Games.BlastBuddies.ThemeKey:')
[void]$sb.AppendLine('')
$memberLines = @(); $k = 0
foreach ($t in $themeRows) { $memberLines += $(if ($k -eq 0) { "    DEFINE ENUM $($t.Member) = 0" } else { "                $($t.Member)" }); $k++ }
[void]$sb.AppendLine(($memberLines -join "`r`n") + '.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('END ENUM.')
$files['ThemeKey.cls'] = $sb.ToString()

# TerrainThemes
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* The colours of the three terrain themes of Blast Buddies: Colour(theme, key) as a 0xRRGGBB number. $header */")
[void]$sb.AppendLine('USING Progress.Lang.*.')
[void]$sb.AppendLine('USING ProGriddle.Core.*.')
[void]$sb.AppendLine('USING ProGriddle.Engine.*.')
[void]$sb.AppendLine('USING ProGriddle.Games.BlastBuddies.*.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('BLOCK-LEVEL ON ERROR UNDO, THROW.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('CLASS ProGriddle.Games.BlastBuddies.TerrainThemes FINAL:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* the colour of key k (1 to ' + $themeRows.Count + ') of theme t (0 to 2) is at (t * ' + $themeRows.Count + ') + k */')
[void]$sb.AppendLine('    DEFINE PRIVATE STATIC VARIABLE sColour AS INTEGER NO-UNDO EXTENT ' + (3 * $themeRows.Count) + '.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    CONSTRUCTOR STATIC TerrainThemes():')
$n = 0
foreach ($t in $themeRows) { $n++; [void]$sb.AppendLine("        sColour[$n] = ColourMath:FromHex(`"$($t.Meadow)`").") }
$n = $themeRows.Count
foreach ($t in $themeRows) { $n++; [void]$sb.AppendLine("        sColour[$n] = ColourMath:FromHex(`"$($t.Canyon)`").") }
$n = 2 * $themeRows.Count
foreach ($t in $themeRows) { $n++; [void]$sb.AppendLine("        sColour[$n] = ColourMath:FromHex(`"$($t.Candy)`").") }
[void]$sb.AppendLine('    END CONSTRUCTOR.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('    /* The colour of a key in a theme. */')
[void]$sb.AppendLine('    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTheme AS Theme, INPUT poKey AS ThemeKey):')
[void]$sb.AppendLine('        IF NOT VALID-OBJECT(poTheme) OR NOT VALID-OBJECT(poKey) THEN UNDO, THROW NEW GridException("A theme colour needs a theme and a key").')
[void]$sb.AppendLine('        RETURN sColour[INTEGER(poTheme) * ' + $themeRows.Count + ' + INTEGER(poKey) + 1].')
[void]$sb.AppendLine('    END METHOD.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('END CLASS.')
$files['TerrainThemes.cls'] = $sb.ToString()

# ---- write or check ----
$bad = 0
foreach ($f in $files.Keys) {
    $path = Join-Path $outDir $f
    $text = ($files[$f] -replace "`r?`n", "`r`n")
    if ($Check) {
        if (-not (Test-Path $path) -or [IO.File]::ReadAllText($path) -ne $text) { Write-Host "Out of date: $f"; $bad++ }
    } else {
        New-Item -ItemType Directory -Force $outDir | Out-Null
        [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false)))
        Write-Host "Wrote $f"
    }
}
Write-Host ("{0} sprites, {1} tone rows, {2} named colours, {3} theme keys." -f $sprites.Count, $tones.Count, $tints.Count, $themeRows.Count)
if ($bad -gt 0) { exit 1 }
exit 0
