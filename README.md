# ProGriddle

**Allowing you to cook up new grid based games easily.**

ProGriddle is an OpenEdge ABL object oriented framework for games played on a rectangular grid. Think of it as the griddle: it gives you the hot, flat surface (the board, the storage, the rules for edges and neighbours, the game loop, a window and saved settings), so all you bring is the recipe, the rules of your game.

- Written in OpenEdge ABL (OO), for OpenEdge 12.8 on Windows, with a WinForms window through the ABL .NET bridge.
- Game logic never touches the screen, so every game runs under plain batch tests with no window at all.
- Every piece is unit tested with ABLUnit. The window is checked by a script that drives the real thing.

This page documents the framework and how to create a new game with it. Each game that has been built has its own page, linked at the [end](#games).

## Contents

- [Requirements and quick start](#requirements-and-quick-start)
- [How it fits together](#how-it-fits-together)
- [The building blocks](#the-building-blocks)
- [The Cookoff](#the-cookoff)
- [Creating a new game](#creating-a-new-game)
- [Testing and tools](#testing-and-tools)
- [More documentation](#more-documentation)
- [Licence](#licence)
- [Games](#games)

## Requirements and quick start

- OpenEdge 12.8 or higher on Windows. R-code is tied to the OpenEdge version, so build from source.
- `prowin` for the window and `_progres -b` for batch tests. The install location comes from `$env:DLC`, defaulting to `C:\Progress\OpenEdge`.
- PowerShell for the helper scripts. If scripts are blocked, run them as `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`.

There is no build step: ABL source is compiled when it is run. Every launch passes `-T`, OpenEdge's temp file folder, so the session's temp files go to `%TEMP%\ProGriddle` (or `C:\temp` when `TEMP` is not set) and not into the repository. `cookoff.bat`, the Cookoff's own launches and every script in `tools` do this for you and create the folder; if you start prowin by hand with `-T`, create the folder first. From the repository root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -All
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-life.p"
```

The first runs every test (plain and WinForms). The second opens the Life game. `tools/launch.p` sets the PROPATH and then runs the program you name, which is how every window program is started.

Project setup for VS Code: `openedge-project.json` defines the PROPATH for the OpenEdge extension (`src`, `tests` and `run`). The extension also reads your OpenEdge install path from `.vscode/settings.json`, which is not committed because it is machine specific. Create it with:

```json
{
  "abl.configuration.runtimes": [
    { "name": "12.8", "path": "C:\\Progress\\OpenEdge", "default": true }
  ]
}
```

## How it fits together

Source lives under `src/ProGriddle`, one folder per namespace, one class per file. The layers only depend downwards:

```
 run/*.p                composition roots: the only place concrete classes are wired together
    |
 ProGriddle.Games.<Game>    a game's rules      depends on Core and Engine only
 ProGriddle.UI.WinForms     the window          depends on Core, Engine, UI.Text. The only layer that uses .NET
 ProGriddle.UI.Text         text renderer, fake clock, for tests
    |
 ProGriddle.Engine          game contracts, controller, clock, settings    depends on Core
    |
 ProGriddle.Core            grid, cell stores, topology, shapes            depends on nothing
```

`tools/check-layering.ps1` enforces this (it also runs in GitHub Actions and needs no OpenEdge install). A game never refers to the window and never to another game, which is what lets it run in tests with no GUI.

| Folder | Holds |
|---|---|
| `src/ProGriddle/Core` | `Coord`, `Shape`, `Grid`, the cell stores, topologies, neighbourhoods, `IRandom` |
| `src/ProGriddle/Engine` | `IGame`, `AbstractGame`, `GameController`, `TurnController`, `IClock`, `IGridRenderer`, `IGameInput`, settings |
| `src/ProGriddle/UI/WinForms` | `GameWindow`, `GridView`, `WinFormsGridRenderer`, `WinFormsClock`, `KeyMap` |
| `src/ProGriddle/UI/Text` | `TextGridRenderer`, `FakeClock` |
| `src/ProGriddle/Games/<Game>` | One folder per game |
| `run` | One `run-<game>.p` per game |
| `tests` | The same folder layout as `src`, `*Tests.cls` |
| `tools` | Scripts: tests, layering check, compile check, window smoke tests |
| `docs` | Deeper notes and the game pages |

## The building blocks

### Grid and cells

A `Grid` has a width, a height, a **cell store**, a **topology** and a **neighbourhood**. Cells are plain integers, never objects, so the framework stays fast.

- `x` and `y` start at 0 and the cell index is `(y * width) + x`.
- A store holds one or more named **layers** of integers, for example Minesweeper's `mine`, `revealed`, `flag` and `adjacent`. Layer names are letters, digits and underscores, start with a letter, and must not be `x` or `y`. Resolve a name once with `LayerIndex` and use the number in loops.
- Every layer starts at 0, and 0 means empty. What the numbers mean is up to the game.
- Anything out of range throws `GridException`. The framework never returns a magic value.

### Cell stores

Three interchangeable stores implement `ICellStore`, and the same contract tests run against all of them. A game picks the one that suits it.

| Store | Holds | Use it for |
|---|---|---|
| `ArrayStore` | All layers in one `MEMPTR`, 4 bytes a cell | Crowded boards, large boards, anything fast |
| `SparseStore` | Only the non zero cells, in a temp table | Big boards that are mostly empty |
| `TableStore` | One temp table record per cell with a named field per layer, up to 100,000 cells | Small boards that want readable, queryable fields: Minesweeper, Battleships, Tetris |

All three offer the same operations: read and write by x, y or index, fill a layer, count cells with a value, `Duplicate` and `CopyFrom` (including between different store types), shape stamping and collision tests (`CanPlace`, `Stamp`, `Erase`), and the row operations a Tetris style game needs (`IsRowFull`, `ClearRow`, `ShiftRowsDown`). Call `Dispose` when you have finished with a store; stores backed by memory free it there. See [Performance notes](docs/framework/performance.md) for how the choice was made.

### Shapes

`Shape` is an immutable set of cell offsets, with `Rotate` (90 degrees clockwise), `Flip`, a bounding box and a text form (`"XX/.X"`). It is shared by patterns, ships and pieces. Shapes are always normalised so their top left corner is (0, 0).

### Edges and neighbours

A topology says what happens at the edge of the board and a neighbourhood says which cells are neighbours:

- `BoundedTopology` (edges are walls) and `ToroidalTopology` (edges wrap round).
- `MooreNeighbourhood` (8 cells), `VonNeumannNeighbourhood` (4 cells) and `CustomNeighbourhood` (any list of offsets).
- `Grid:GetNeighbourIndexes(x, y, array)` fills an array you supply, returns how many neighbours there are, and allocates nothing.

Each distinct neighbouring cell is listed once, and a cell is never its own neighbour. That only matters on a wrapped board small enough for offsets to land on the same cell:

| Board | Moore neighbours of a cell | Von Neumann neighbours |
|---|---|---|
| 1 x 1 wrapped | 0 | 0 |
| 2 x 2 wrapped | 3 | 2 |
| 1 x 5 wrapped | 2 (the cells above and below) | 2 |
| 3 x 3 wrapped | 8 | 4 |
| 1 x 1 or 2 x 2 bounded | 0 or 3 | 0 or 2 |

### Games, the controller and the clock

A game implements `IGame` and is one of three kinds:

| Kind | Interface | Example |
|---|---|---|
| Steppable: the whole grid updates at once | `ISteppableGame` (`Step`, `Generation`) | Life |
| Turn based: a move is validated and applied | `ITurnBasedGame` (`Turn`) | Minesweeper, Battleships |
| Real time: advanced by a clock, whether or not the player acts | `IRealTimeGame` (`Paused`, `Tick`) | Tetris |

`AbstractGame` supplies the name, the grid, the over flag and the counter. `GameController` ties a steppable game to an `IGridRenderer` and an `IClock`: Start, PauseGame, StepOnce, Reset, SpeedUp, SlowDown (`GameCommand`), with six speeds and a redraw after every change. It stops the clock itself when the game is over. `TurnController` does the same for a turn based game, which has no clock and no stepping: only a new game (Reset) and a redraw (Refresh). `RealTimeController` binds a real time game to a renderer and a clock: each clock tick passes the milliseconds that really went by to the game's `Tick`, and it redraws only when `Tick` says something changed. It is built paused, so call `Start`; `PauseGame` stops the clock and sets the game's `Paused` flag, `Reset` starts a new game and runs it, and the clock stops by itself when the game is over. All three implement `IGameController`, which is all the window needs to know. Its `Steppable` says whether the game has stepping and a speed (Life) and `Pausable` whether it has a clock to start and stop (Life and any real time game, not a turn based one): the window shows the Start and Pause button when the game is pausable, and the stepping and the speed slider only when it is steppable. A turn based or real time game keeps its moves as its own methods (Minesweeper has Reveal, ToggleFlag and Chord, Tetris has MoveLeft, RotateClockwise and HardDrop) and the window reaches them through `IGameInput`.

A turn based game can hold more than one board in its one grid: Battleships keeps the computer's waters, a divider and your own fleet side by side, and works out which board a click is on. A game can also use an opponent of its own (Battleships has `IBattleshipsOpponent`, with a hunt-and-target computer player). A game that needs a timer takes an `IClock` of its own. Minesweeper counts seconds from one, and the same clock tells the window to refresh the status line.

`IClock` is a source of ticks. `WinFormsClock` wraps a Windows timer; `FakeClock` is advanced by hand, so games that depend on time are deterministic in tests. `IRandom` is the only source of randomness: pass a `SeededRandom` and a test gets the same board every time.

### Settings

`ISettings` keeps named values that outlive a session (window size, speed, a game's options). Keys are namespaced by game, like `life.speed`. Reading never fails: a missing key, or a key holding another type, returns the default you give. `JsonFileSettings` stores them in a small JSON file (by default `%APPDATA%\ProGriddle\settings.json`) and a missing or corrupt file just means defaults, with the next save writing a good file. `MemorySettings` is the in-memory version for tests.

### The window

`GameWindow` hosts any game, steppable, turn based or real time, and knows nothing about which one. For a steppable game it gives you a toolbar (Start or Pause, Step, Reset, the game's own commands, an optional picker, a speed slider), for a turn based game just a New game button, the game's own commands and the picker, and for a real time game a Pause button, New game, the commands and the picker. Either way it has the board, a status bar, keyboard and mouse handling, and saved window size, position and (when stepping) speed. A game describes itself to the window through `IGameInput`:

| Member | Used for |
|---|---|
| `StatusText` | The status bar and window title |
| `ChoiceLabel`, `ChoiceNames`, `Choice` | An optional picker (Life's pattern list). Empty names hide it |
| `CommandNames` | Extra buttons and keys, written `Name:Letter` such as `Random:G,Clear:C` |
| `IGameOptions` (implemented as well) | Extra drop down lists: `OptionCount`, and for each option a label, a settings key, the names on offer, the current value and `SetOption`. The window builds the lists after the picker, applies a choice, redraws (an option may replace the grid, as a board size does), and saves and restores each as `<prefix>.<key>`. Life uses it for its rules and board size |
| `BannerText` | Text kept over the middle of the board while it is not empty, such as `PAUSED` or `GAME OVER`. Unlike a notice it does not fade, and the window refreshes it after every key, click and tick (`GridView:SetBanner`) |
| `HandleKey(key)`, `ReleaseKey(key)` | The game's own keys, offered before the window's, so a real time game can use the arrows and the space bar. `key` is the .NET key name (`Left`, `Space`, `Z`). Return true when the game used the key, whether or not the move was possible, so the window never gives it a second meaning. A held key arrives again and again, which is key repeat: a game that must act once per press (a turn, a hard drop) remembers the key as held and ignores its repeats until `ReleaseKey(key)`. `ReleaseKey("")` means every key is up, which the window sends when it loses the focus |
| `TakeNotice()` | A few words on what the last action did (or why it was refused), shown for a moment over the board and faded out. Returns and clears the pending notice |
| `InfoLabel`, `InfoText` | An optional text screen such as high scores, written `Name:Letter` like `Scores:H`. Empty hides it |
| `Perform(name)` | Runs one of those commands |
| `PrimaryAction(x, y)`, `SecondaryAction(x, y)`, `TertiaryAction(x, y)` | Left click, right click, and a middle click or both buttons together, on a cell |

Mouse buttons are read as a gesture and acted on when the last one is released, on the cell under the pointer, and a double click is a `PrimaryAction` followed by a `TertiaryAction`. A game can offer a text screen (`InfoLabel` and `InfoText`, which Minesweeper uses for its high scores): the window adds a button and a key and shows the text in an `InfoDialog`. The keys every steppable game gets: Space start or pause, S or Right arrow one step, R or F2 reset, + or Up faster, - or Down slower. A turn based game only answers to R and F2 (a new game), and a real time game to P or Space (pause and resume, unless the game takes the key itself through `HandleKey`) as well. `GridView` draws the board as one pixel per cell in a bitmap scaled in a single call, using a palette of hex colours where the colour of a cell is the palette entry at its value. It can also draw text in cells (`SetGlyphs`): a glyph and a colour for chosen cell values, such as the numbers, flag and bomb of Minesweeper. Give anything outside Latin 1 as a code point (`U+1F4A3`), because an ABL string cannot carry it.

### The Cookoff

The ProGriddle Cookoff (`run/run-arcade.p`) is one window with a button for every game, so a single launch command reaches them all:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-arcade.p"
```

On Windows you can also double click `cookoff.bat` in the repository root, which does the same from any folder (it uses the install named by the `DLC` environment variable, or `C:\Progress\OpenEdge`).

Each game has a chip with its title and a colour: the one its run file asks for, or else one worked out from its title, so a game keeps its colour whatever else is added. The window grows to fit up to eight games, two to a row, and scrolls beyond that. Pointing at a chip shows that game's description under the COOKOFF badge. A click starts the game in a prowin of its own, so the Cookoff stays open and several games can be played at once. While a game is running its chip is outlined in its colour and says PLAYING in green, and goes back to normal when the game's window closes.

Nothing is registered anywhere. The Cookoff looks in the `run` folder for files named `run-*.p`, so **a new game appears as soon as its run file exists**. A run file can describe itself with one line in its header comment (and the comment must not close on that line):

```
   Arcade: Tetris | Falling blocks on a timer. Seven bag pieces, ghost piece, levels and a high score list.
```

The words before the first bar are the button's title and the words after it the line shown beside the button. An optional third part after a second bar names the colour of the chip, one of `red`, `orange`, `blue`, `purple`, `green`, `yellow` or `teal` (the four games here use the colours of the Cookoff artwork, for example `Arcade: Tetris | Falling blocks. | purple`). Without the line the title comes from the file name (`run-battleships.p` is Battleships) and there is no description. A run file that is not a game says `Arcade: hidden` (`run/run-arcade.p` does). Games are listed by title.

It is built from the same pieces as the games: `IGameCatalog` and `DirectoryGameCatalog` (the list of games, in `Engine`), `IGameLauncher` (starts a program, with `ProcessGameLauncher` in `UI.WinForms` starting a real prowin) and `ArcadeWindow` (the window), wired together in `run/run-arcade.p`. The look comes from the Cookoff artwork and is drawn in code by `CookoffBackdrop` (the navy backdrop, the wordmark, the badge and the board of mixed games), so it stays sharp and needs no image files. Only the window icon is a file, `assets/progriddle.ico`. A game does not need to know about the Cookoff.

## Creating a new game

Time to cook up a game on the griddle. The quick way is one command, which writes a working game with its tests, run file and docs page, and gives it a button in the Cookoff:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/new-game.ps1 -Name Snake -Title "Snake" -Blurb "Eat, grow, and do not bite yourself."
```

[Adding a game](docs/adding-a-game.md) is the walk through from there, and [CONTRIBUTING.md](CONTRIBUTING.md) is how a change goes. What follows is the same game written out by hand, so you can see every piece: a complete, working game in three small files. It lights one cell and moves it along the board, so it shows every piece you need. (Run it with `prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-scanner.p"` once you create the files.) Replace the rules with your own.

### 1. Decide what the game is

Pick the kind (steppable, turn based or real time), the board size, the layers it needs and which store suits it. Steppable and turn based games are supported end to end today (a steppable game uses `GameController` and a clock, a turn based one `TurnController`, see [Minesweeper](docs/games/minesweeper.md) for the turn based shape). The scanner uses one layer called `state` on an `ArrayStore`.

### 2. Write the game class

Create `src/ProGriddle/Games/Scanner/ScannerGame.cls`. It inherits `AbstractGame` and implements `ISteppableGame`. Override `OnInitialise` to set up the starting board; `Initialise` has already put `Generation` back to 0.

```
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Scanner.ScannerGame INHERITS AbstractGame IMPLEMENTS ISteppableGame:

    DEFINE PRIVATE VARIABLE mPosition AS INTEGER NO-UNDO.

    CONSTRUCTOR PUBLIC ScannerGame(INPUT poGrid AS Grid):
        SUPER("Scanner", poGrid).
    END CONSTRUCTOR.

    /* One lit cell moves along the board, a row at a time, and wraps round at the end. */
    METHOD PUBLIC VOID Step():
        Grid:Store:SetCellAt(1, mPosition, 0).
        mPosition = (mPosition + 1) MODULO Grid:CellCount.
        Grid:Store:SetCellAt(1, mPosition, 1).
        Generation = Generation + 1.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Grid:Store:FillLayer(1, 0).
        mPosition = 0.
        Grid:Store:SetCellAt(1, 0, 1).
    END METHOD.

END CLASS.
```

Set `IsOver = TRUE` when the game ends and the controller stops the clock by itself. The game never refers to a window, a timer or any .NET type.

### 3. Tell the window about the game

Create `src/ProGriddle/Games/Scanner/ScannerInput.cls` implementing `IGameInput`. This game needs no picker, no extra commands and ignores clicks, so most members are empty. A real game puts its click handling here (Life toggles a cell on a left click and places a pattern on a right click).

```
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Scanner.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Scanner.ScannerInput IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame AS ScannerGame NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            RETURN SUBSTITUTE("Generation &1", mGame:Generation).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.
        SET(INPUT pcValue AS CHARACTER):
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    CONSTRUCTOR PUBLIC ScannerInput(INPUT poGame AS ScannerGame):
        mGame = poGame.
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        RETURN "".
    END METHOD.

    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        RETURN FALSE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown command: " + pcCommand).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

END CLASS.
```

### 4. Write the composition root

Create `run/run-scanner.p`. This is the only place that builds concrete classes and wires them together: store, grid, game, view, clock, controller, window. Put an `Arcade: Title | one line about the game` line in its header comment and the game gets a button in [the Cookoff](#the-cookoff) with no other change. Reading board size and options from `ISettings` is the usual pattern (see `run/run-life.p`).

```
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Scanner.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE oSettings   AS ISettings      NO-UNDO.
DEFINE VARIABLE oGame       AS ScannerGame    NO-UNDO.
DEFINE VARIABLE oView       AS GridView       NO-UNDO.
DEFINE VARIABLE oClock      AS WinFormsClock  NO-UNDO.
DEFINE VARIABLE oController AS GameController NO-UNDO.
DEFINE VARIABLE oWindow     AS GameWindow     NO-UNDO.

Application:EnableVisualStyles().
oSettings = NEW JsonFileSettings(JsonFileSettings:DefaultPath()).

/* the grid: a store with one layer called state, wrapped in a Grid */
oGame = NEW ScannerGame(NEW Grid(NEW ArrayStore(30, 20, "state"))).
oGame:Initialise().

oView = NEW GridView().
oView:SetPalette("1B1F24,F2C14E").
oClock = NEW WinFormsClock().
oController = NEW GameController(oGame, NEW WinFormsGridRenderer(oView, "state"), oClock).
oWindow = NEW GameWindow("Scanner", oController, oView, NEW ScannerInput(oGame), oClock, oSettings, "scanner").

WAIT-FOR Application:Run(oWindow).

oController:Dispose().
oClock:Dispose().
oGame:Dispose().
QUIT.
```

The palette maps cell values to colours in order: value 0 is the first colour, value 1 the second, and so on. The last argument to `GameWindow` ("scanner") is the settings prefix, so the window saves `scanner.speed` and friends.

### 5. Test it without a window

Because the game has no UI dependency, test it in plain ABLUnit under `tests/ProGriddle/Games/Scanner/`. Useful pieces already exist: `TextGridRenderer` turns a grid into text so a test can compare a whole board, `FakeClock` plus `GameController` lets a test script a session ("start, advance 750 ms, expect generation 3"), `SeededRandom` makes random boards repeatable, and `tests/ProGriddle/Games/Life/` shows the shape of a full suite (game, rules, input, a scripted session).

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Scanner*"
```

### 6. Finish properly

- Run `tools/check-layering.ps1` (a game must not use the window or another game) and `tools/compile.ps1`.
- Follow the conventions in `CLAUDE.md`: wildcard `USING` per namespace, `BLOCK-LEVEL ON ERROR UNDO, THROW.` in every class, no objects created inside per-cell loops, every `MEMPTR` freed, no em dashes.
- If the game needs a change to the framework, change the framework and its tests. Do not special case a game inside `Core` or `Engine`.
- Add a page `docs/games/<game>.md` (how to play, settings, how it uses the framework, tests, performance) and add it to the [Games](#games) list below. A game is not finished until both exist.
- A window smoke test in the style of `tools/gui-smoke-life.ps1` is worth adding for any game with real interaction.

## Testing and tools

| Command | What it does |
|---|---|
| `tools/run-tests.ps1` | Runs every `tests/**/*Tests.cls` under `_progres -b`, except the WinForms ones. Exits non-zero on any failure or error |
| `tools/run-tests.ps1 -Gui` | Runs only the WinForms tests, under `prowin -b` |
| `tools/run-tests.ps1 -All` | Runs both sets |
| `tools/run-tests.ps1 -Filter "Grid*"` | Runs only test classes whose file name matches |
| `tools/check-layering.ps1` | Checks the layering rules. Needs no OpenEdge install |
| `tools/audit-conventions.ps1` | Checks the rules of `CLAUDE.md` that a script can: header comments, `BLOCK-LEVEL`, wildcard `USING`, no dashes, `MEMPTR` freed, every public member named in a test. Needs no OpenEdge |
| `tools/new-game.ps1 -Name Snake` | Starts a new game from `templates/game`: its classes, tests, run file and page. See [Adding a game](docs/adding-a-game.md) |
| `tools/check-template.ps1` | Makes a game from the template, runs its tests and removes it, to prove the template still works |
| `bench/run-life-bench.ps1` | Times the real Life engines on a 500 x 500 board for 100 generations. Takes several minutes |
| `tools/compile.ps1` | Compiles every source file in one pass and lists all errors (`-SourceOnly` skips tests) |
| `tools/gui-smoke-arcade.ps1` | Drives the Cookoff: a button for every game, starting Tetris and Life from it, the playing state and its return. Takes over the keyboard and mouse for under a minute |
| `tools/gui-smoke-life.ps1` | Drives the real Life window like a user and checks what happens. Takes over the keyboard and mouse for about a minute |
| `tools/gui-smoke-battleships.ps1` | The same for Battleships: placing a fleet, firing, marking water, a whole game, the board size picker. Takes over the keyboard and mouse for a couple of minutes |
| `tools/gui-smoke-minesweeper.ps1` | The same for Minesweeper: flags, chords, a whole game, the level picker, saved settings. Takes over the keyboard and mouse for a couple of minutes |
| `tools/gui-smoke-tetris.ps1` | The same for Tetris: moving, turning, held key repeat, drops and score, gravity, pause, ghost, a game over, the start level picker, saved settings. Takes over the keyboard and mouse for a couple of minutes |

Results go to `build/test-results/results.xml` (plain) and `build/test-results/gui/results.xml` (WinForms). Screenshots from the smoke test go to `build/screenshots`.

Under `prowin -b` WinForms objects can be built and drawn to a bitmap, but there is no .NET message loop, so timers never tick and real input is only checked in a windowed run. Other things worth knowing about testing on OpenEdge (ABLUnit fixtures, inherited tests, exit codes) are in [OpenEdge environment notes](docs/framework/environment.md).

## More documentation

- [Adding a game](docs/adding-a-game.md): from one command to a finished game, step by step.
- [Contributing](CONTRIBUTING.md): how a change goes, the rules of the codebase and what a good pull request looks like.
- [OpenEdge environment notes](docs/framework/environment.md): running and testing, language gotchas, the ABL keywords to avoid.
- [Performance notes](docs/framework/performance.md): the measurements behind the storage and rendering design.
- [Framework review](docs/framework/review.md): the Phase 7 review, what it found and fixed, and why the repository stays one piece.
- `CLAUDE.md`: the coding conventions every change follows.

## Licence

MIT, see `LICENSE`.

## Games

Start any of them from the **ProGriddle Cookoff**, one window with a button for every game below (and for any game you add, with no list to edit):

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-arcade.p"
```

[How the Cookoff finds games](#the-cookoff) and how to give yours a title and a line of description are covered above. Each game can also be started on its own with `-param "run/run-<game>.p"`, and each has its own page:

- [Conway's Game of Life](docs/games/life.md): steppable, dense and sparse engines, patterns, HighLife and other rule sets, saved settings. Playable now.
- [Battleships](docs/games/battleships.md): turn based, you against a computer on two boards, ships that may not touch, five board sizes with a fleet to match, placing by hand or at random, marking water, a hunting and targeting opponent. Playable now.
- [Minesweeper](docs/games/minesweeper.md): turn based, the classic Windows rules, four levels, a high score list and screen per level, question marks, chording (both buttons, middle or double click). Playable now.
- [Tetris](docs/games/tetris.md): real time, seven bag pieces falling on a timer, held key repeat, ghost piece, next piece panel, pause, levels and scoring, a start level picker, a high score list. Playable now.
