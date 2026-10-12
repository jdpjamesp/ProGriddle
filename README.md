# ProLific

An OpenEdge ABL OO framework for grid based games. First target is Conway's Game of Life, then Minesweeper, Battleships and Tetris to prove the framework.

Status: Phase 3 in progress. Conway's Game of Life is playable in a window (see "Playing Life" below). Minesweeper, Battleships and Tetris are still to come.

## What exists so far

`Prolif.Core`: `Coord`, `Shape`, `Grid`, `GridException`, the `ICellStore` contract and three interchangeable stores. `ArrayStore` is dense and backed by a MEMPTR, `SparseStore` holds occupied cells only, and `TableStore` is a temp table with one record per cell and a named field per layer. All three pass the same contract tests (`tests/Prolif/Core/CellStoreContractTests.cls`).

Edges and neighbours: `BoundedTopology` (edges are walls) and `ToroidalTopology` (edges wrap), with `MooreNeighbourhood` (8 cells), `VonNeumannNeighbourhood` (4 cells) and `CustomNeighbourhood` (any offsets). `Grid.GetNeighbourIndexes(x, y, array)` fills a caller supplied array and returns the count, without allocating any object. It takes about 12 microseconds a call, so engines that visit every cell of a large board should work from the index step of each offset instead of calling it per cell.

Settings (`Prolif.Engine`): `ISettings` with typed values and defaults, `MemorySettings`, and `JsonFileSettings` which keeps them in a small JSON file (by default `%APPDATA%\ProLific\settings.json`). A missing or corrupt file never fails: the defaults are used and the next save writes a good file.

Life (`Prolif.Games.Life`): `LifeRules` (B/S notation, so Conway's `B3/S23` or HighLife `B36/S23`), `LifePatterns` (eleven named patterns and a plain text loader), `LifeGame`, and two interchangeable engines that give identical generations: `DenseLifeEngine` on an `ArrayStore` and `SparseLifeEngine` on a `SparseStore`. `LifeFactory` picks one.

Engine timings, random start, milliseconds per generation (the engines are checked against each other and against a slow reference in `LifeEngineTests`):

| Board | Live at start | Dense | Sparse |
|---|---|---|---|
| 100 x 100 | 3% | 46 | 8 |
| 100 x 100 | 10% | 50 | 47 |
| 100 x 100 | 30% | 46 | 263 |
| 300 x 300 | 3% | 314 | 166 |
| 300 x 300 | 10% | 311 | 680 |
| 300 x 300 | 30% | 306 | 2638 |

The dense engine costs the same at any density. The sparse engine costs 8 to 75 microseconds per live cell, so it wins only on mostly empty boards. They break even at about 5% live cells, and `LifeFactory` uses sparse below that. The sparse engine cannot run rules with a birth on zero neighbours (`B0`), which the dense engine can.

The window (`Prolif.UI.WinForms`): `GameWindow` hosts any steppable game and knows nothing about Life. It is built from `GridView` (draws the board as one pixel per cell in a Bitmap scaled in a single call, centred in the window), `WinFormsGridRenderer`, `WinFormsClock` (a Windows timer) and `KeyMap`. A game describes itself to the window through `IGameInput` (status text, a picker, extra commands, what clicks do), implemented for Life by `LifeInput`. `run/run-life.p` is the one place that builds and wires everything together.

## Neighbours on tiny boards

Each distinct neighbouring cell is listed once, and a cell is never its own neighbour. This only matters on a wrapped board small enough for offsets to land on the same cell:

| Board | Moore neighbours of a cell | Von Neumann neighbours |
|---|---|---|
| 1 x 1 toroidal | 0 | 0 |
| 2 x 2 toroidal | 3 | 2 |
| 1 x 5 toroidal | 2 (the cells above and below) | 2 |
| 3 x 3 toroidal | 8 | 4 |
| 1 x 1 bounded | 0 | 0 |
| 2 x 2 bounded | 3 | 2 |

Bounded boards never repeat a cell, because each offset reaches a different cell. Cells at least as far from every edge as the neighbourhood reach skip the topology and use precomputed index steps.

## Requirements

- OpenEdge 12.8 or higher on Windows (r-code is tied to the OpenEdge version, so build from source).
- `prowin` for the GUI, `_progres -b` for batch tests.
- PowerShell for the helper scripts. If scripts are blocked, run them as `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`.

## How to build and test

There is no separate build step. ABL source is compiled on the fly by the test runner.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Grid*"
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check-layering.ps1
```

- `run-tests.ps1` finds every `tests/**/*Tests.cls`, runs them through ABLUnit in batch mode and writes `build/test-results/results.xml`. It exits non-zero on any failure or error.
- The install location comes from `$env:DLC`, defaulting to `C:\Progress\OpenEdge`.
- `run-tests.ps1 -Gui` runs the WinForms tests (they need the .NET bridge) under `prowin -b`, and `-All` runs both sets. Batch mode has no .NET message loop, so timer ticks and real input are checked in a windowed run instead.
- `check-layering.ps1` enforces the layering rules (see `CLAUDE.md`). It needs no OpenEdge install and runs in GitHub Actions.

Things worth knowing about this environment:

- `_progres` ignores the PROPATH environment variable, so `tools/run-tests.p` sets `PROPATH` in code.
- ABLUnit returns exit code 0 even when tests fail, so the script judges success from the results XML.
- The ABLUnit output folder must exist before the run. The script creates it.

## Project setup

`openedge-project.json` defines the PROPATH for the VS Code OpenEdge extension: `src`, `tests` and `run`. The extension also reads the OpenEdge install path from `.vscode/settings.json`, which is not committed because it is machine specific. Create it with:

```json
{
  "abl.configuration.runtimes": [
    { "name": "12.8", "path": "C:\\Progress\\OpenEdge", "default": true }
  ]
}
```

## Playing Life

From the repository root:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -p tools/launch.p -param "run/run-life.p"
```

`tools/launch.p` sets PROPATH and then runs the named program, so `USING` statements resolve at compile time. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProLific\settings.json`) and a number of seconds after which the window closes by itself.

| Input | What it does |
|---|---|
| Left click on the board | Toggle a cell |
| Right click on the board | Place the chosen pattern with its corner at that cell (moved back if it would hang off the edge) |
| Space | Start, or pause when running |
| S or Right arrow | One generation |
| R | Reset to the board as it was at the first step |
| G | Random board (about a quarter alive), back to generation 0 |
| C | Clear the board |
| + or Up arrow, - or Down arrow | Faster, slower (six speeds, 1000 ms down to 30 ms a step) |
| Pattern box | Choose which pattern a right click places (the label says so). The keyboard goes back to the board once you have chosen |
| Speed slider, buttons | Same things with the mouse |

The status bar and the window title show the generation, the number of live cells, the rules, the board size and the speed. Resizing the window rescales the cells. The window size, position, speed and chosen pattern are remembered between runs.

Settings you can edit in `%APPDATA%\ProLific\settings.json` while the program is closed (all optional; the file holds `schemaVersion` and a `values` object):

| Key | Meaning | Default |
|---|---|---|
| `life.width`, `life.height` | Board size in cells, 5 to 400 | 100, 70 |
| `life.wrap` | `true` makes the edges wrap | `false` |
| `life.rules` | Rules in B/S notation, for example `B36/S23` for HighLife | `B3/S23` |
| `life.expectedLive` | Expected share of live cells, 0 to 1. Below 0.05 the sparse engine is used (good for big, mostly empty boards) | 0.1 |
| `life.palette` | Dead and alive colours as hex | `1B1F24,F2C14E` |
| `life.startPattern` | Pattern placed on a new board, or `None` | `GosperGliderGun` |

## Checking the window

`tools/gui-smoke-life.ps1` launches the real window with a throwaway settings file and drives it like a user: it finds the board from a screenshot, clicks and types, reads the state back from the window title, resizes it, closes it, checks that the process exits and the settings were saved, then starts it again to see them restored. It sends real keystrokes and mouse clicks to the foreground, so leave the keyboard and mouse alone for the 40 seconds or so it takes. Screenshots go to `build/screenshots`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/gui-smoke-life.ps1
```

`tools/compile.ps1` compiles every source file under `prowin -b` in one pass and lists all errors (add `-SourceOnly` to skip the tests).

## Manual GUI checklist

The smoke test covers behaviour. These are the things only your eyes can judge. Run the game and look for:

- [ ] No flicker or tearing while it runs at the fastest speed on a full board (press G, then Space, then + until Speed 6).
- [ ] The grid lines and cells look crisp and the cells stay square when you resize the window.
- [ ] The board is centred, with the same margin on both sides.
- [ ] The toolbar is readable and wraps sensibly when the window is made narrow.
- [ ] Window title, status bar and board all agree on the generation and live cell count.
- [ ] After closing, the window process is gone from Task Manager (watch for a leftover prowin.exe).

## Phase 0 findings

Environment (OpenEdge 12.8.0.1207, Windows 11):

- `_progres -b` runs batch programs and ABLUnit. `prowin -b` also compiles .NET GUI classes. The .NET bridge targets .NET Framework 4.x (CLR v4.0.30319), not modern .NET. `USING System.Windows.Forms.* FROM ASSEMBLY.` and `System.Drawing` work in the standard way.
- GUI pattern that works: a form class inheriting `System.Windows.Forms.Form`, a control class inheriting `Panel` with `DoubleBuffered = TRUE` and an overridden `OnPaint`, events wired with `Subscribe` and removed with `Unsubscribe` in `FormClosed`, and `WAIT-FOR Application:Run(form)` followed by `QUIT`. Without the `QUIT`, prowin stays running after the window closes.
- Timer ticks, mouse clicks (with pixel to cell hit testing) and key presses were all confirmed in a real window driven by simulated input. The Phase 0 spike has since been replaced by the real window, and `tools/gui-smoke-life.ps1` repeats those checks.
- **Dynamic extent limit: 28,000 elements, not 1,000,000.** A 1000 x 1000 board cannot be an INTEGER extent. A `MEMPTR` layer has no such limit and was as fast or faster (see below), so it is the planned backing for `ArrayStore`.
- Per cell `FillRectangle` through the bridge costs about 5 ms per paint at 20 x 20 and **about 95 to 100 ms at 100 x 100**, so 100 x 100 saturates at roughly 9 to 10 paints a second. That was solved in Phase 3: `GridView` builds a Bitmap with one pixel per cell directly over a MEMPTR and draws it scaled in one call, which costs a few milliseconds at 100 x 100 (the WinForms tests assert under 50 ms). Flicker itself is judged by eye using the checklist.

### Storage benchmark

Interpreted ABL costs roughly 1 microsecond per simple operation, so work done matters more than the storage type. Bounded edges, B3/S23, seeded random start. `ext` is a dynamic extent, `mem` is a MEMPTR, a trailing `f` adds an interior fast path (no bounds checks, unrolled neighbours), `tt` is a temp table with one record per cell, `sparse` is a temp table of live cells only. All modes gave identical live counts. Milliseconds per generation, 100 x 100, averaged over 20 generations:

| Start density | ext | extf | mem | memf | tt | sparse |
|---|---|---|---|---|---|---|
| 1% | 113 | 43 | 106 | 41 | 28 | 0.4 (board dies out) |
| 10% | 114 | 49 | 105 | 37 | 48 | 27 |
| 30% | 118 | 54 | 104 | 39 | 137 | 144 |

1000 x 1000: `mem` 10,347 ms per generation, `memf` 3,646 ms, `sparse` at 10% 6,392 ms, `sparse` at 30% 24,276 ms, `tt` at 10% 17,544 ms (and 17 s just to build 1,000,000 records). Tetris row clear and shift on a 10 x 20 temp table: about 2 ms for a four line clear. Memory: a MEMPTR layer is 4 bytes per cell (4 MB at 1000 x 1000). Process working set was not informative for temp tables, because ABL pages them to its temp file.

Caveats: random 1% and 10% starts decay within a few generations, so the sparse averages favour sparse at low density. The temp table and sparse engines touch only live cells, while the dense ones scan every cell.

Conclusions:

- Dense (`MEMPTR` with the interior fast path) is about 40 ms per generation at 100 x 100 whatever the density, so it is the safe default for boards up to a few hundred cells wide.
- Sparse wins below roughly 10 to 15% live density and loses badly above about 20%. The crossover at 100 x 100 is near 15%.
- 1000 x 1000 is not interactive in any mode (several seconds per generation at best). 500 x 500 for 100 generations will take minutes.
- Temp table per cell (`TableStore`) is fine for small boards (Minesweeper, Battleships, Tetris) and too slow for large Life boards.

## Licence

MIT, see `LICENSE`.
