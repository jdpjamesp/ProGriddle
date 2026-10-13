<#
.SYNOPSIS
    Starts a new game from the template: its classes, tests, run file and docs page.
.DESCRIPTION
    Copies the files in templates/game into the right places for a game called -Name, with the
    name filled in:

        src/ProGriddle/Games/<Name>/<Name>Game.cls        the rules (a small steppable game to replace)
        src/ProGriddle/Games/<Name>/<Name>Input.cls       what the window needs from the game
        tests/ProGriddle/Games/<Name>/<Name>GameTests.cls
        tests/ProGriddle/Games/<Name>/<Name>InputTests.cls
        run/run-<name>.p                                  the composition root, with its Cookoff line
        docs/games/<name>.md                              the game's page

    The result compiles, passes its own tests and shows up as a button in the Cookoff straight
    away. Nothing existing is overwritten: if any of those files is there already, nothing is
    written. See docs/adding-a-game.md for what to do next.
.PARAMETER Name
    The class name of the game: a letter, then letters and digits, no spaces. For example Snake.
    It becomes the namespace ProGriddle.Games.<Name>, so it must not be an ABL reserved word.
.PARAMETER Title
    What the game is called on screen and on its Cookoff button. Defaults to the name.
.PARAMETER Blurb
    One line about the game, shown beside its button in the Cookoff. No bar character.
#>
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Title = '',
    [string]$Blurb = 'A new game on the ProGriddle grid.'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ($Name -notmatch '^[A-Z][A-Za-z0-9]*$') {
    throw "The name '$Name' must start with a capital letter and use only letters and digits, for example Snake."
}
if ($Blurb -match '\|') { throw 'The blurb cannot contain a bar, because the Cookoff line is Title | blurb.' }
if (-not $Title) { $Title = $Name }
$lower = $Name.ToLower()

# the files to make: the template, then where it goes
$files = @(
    @('Game.cls.template',       "src/ProGriddle/Games/$Name/${Name}Game.cls"),
    @('Input.cls.template',      "src/ProGriddle/Games/$Name/${Name}Input.cls"),
    @('GameTests.cls.template',  "tests/ProGriddle/Games/$Name/${Name}GameTests.cls"),
    @('InputTests.cls.template', "tests/ProGriddle/Games/$Name/${Name}InputTests.cls"),
    @('run.p.template',          "run/run-$lower.p"),
    @('page.md.template',        "docs/games/$lower.md")
)

# refuse to touch anything that exists already, before writing any file
$clash = @($files | Where-Object { Test-Path (Join-Path $root $_[1]) } | ForEach-Object { $_[1] })
if ($clash.Count -gt 0) {
    throw "Nothing written: these files exist already:`n  $($clash -join "`n  ")"
}

foreach ($f in $files) {
    $text = Get-Content (Join-Path $root "templates/game/$($f[0])") -Raw
    $text = $text.Replace('__Name__', $Name).Replace('__name__', $lower).Replace('__Title__', $Title).Replace('__Blurb__', $Blurb)
    $target = Join-Path $root $f[1]
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    [System.IO.File]::WriteAllText($target, $text, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "wrote $($f[1])"
}

Write-Host ''
Write-Host "$Title is started. Next:"
Write-Host "  1. Run its tests:   powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter `"$Name*`""
Write-Host "  2. Play it:         cookoff.bat (it has a button now), or run/run-$lower.p"
Write-Host "  3. Make it yours:   change ${Name}Game.cls (the rules), then ${Name}Input.cls, then the tests"
Write-Host "  4. Finish properly: add docs/games/$lower.md to the Games list in README.md, then run"
Write-Host "                      tools/check-layering.ps1 and tools/compile.ps1. See docs/adding-a-game.md."
