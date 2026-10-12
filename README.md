# ProLific

An OpenEdge ABL OO framework for grid based games. First target is Conway's Game of Life, then Minesweeper, Battleships and Tetris to prove the framework.

Status: Phase 2 (topology and neighbourhood) done. Nothing is playable yet.

## What exists so far

`Prolif.Core`: `Coord`, `Shape`, `Grid`, `GridException`, the `ICellStore` contract and three interchangeable stores. `ArrayStore` is dense and backed by a MEMPTR, `SparseStore` holds occupied cells only, and `TableStore` is a temp table with one record per cell and a named field per layer. All three pass the same contract tests (`tests/Prolif/Core/CellStoreContractTests.cls`).

Edges and neighbours: `BoundedTopology` (edges are walls) and `ToroidalTopology` (edges wrap), with `MooreNeighbourhood` (8 cells), `VonNeumannNeighbourhood` (4 cells) and `CustomNeighbourhood` (any offsets). `Grid.GetNeighbourIndexes(x, y, array)` fills a caller supplied array and returns the count, without allocating any object. It takes about 12 microseconds a call, so engines that visit every cell of a large board should work from the index step of each offset instead of calling it per cell.

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

- OpenEdge 12.8 on Windows (r-code is tied to the OpenEdge version, so build from source).
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

## Running the GUI spike

```
"C:\Progress\OpenEdge\bin\prowin.exe" -p tools/launch.p -param "run/run-spike.p,build/gui-spike.log,0"
```

`tools/launch.p` sets PROPATH and then runs the named program, so `USING` statements resolve at compile time. The last argument is an auto exit time in seconds (0 keeps the window open). Run from the repository root.

## Manual GUI checklist

Run by hand, because Claude Code cannot see the screen. For the spike:

- [ ] A window titled "ProLific GUI spike" opens with a 20 x 20 checkerboard.
- [ ] The status bar tick counter goes up once a second.
- [ ] Click a cell: the status bar shows `click cell x,y`.
- [ ] Press 2: the board becomes 100 x 100. Press 1 to return to 20 x 20.
- [ ] Press R: repaints run 10 times a second. Look for flicker or tearing at 100 x 100.
- [ ] Resize the window: the board rescales.
- [ ] Close the window: `build/gui-spike.log` ends with "closed cleanly" and the process exits.

## Phase 0 findings

Environment (OpenEdge 12.8.0.1207, Windows 11):

- `_progres -b` runs batch programs and ABLUnit. `prowin -b` also compiles .NET GUI classes. The .NET bridge targets .NET Framework 4.x (CLR v4.0.30319), not modern .NET. `USING System.Windows.Forms.* FROM ASSEMBLY.` and `System.Drawing` work in the standard way.
- GUI pattern that works: a form class inheriting `System.Windows.Forms.Form`, a control class inheriting `Panel` with `DoubleBuffered = TRUE` and an overridden `OnPaint`, events wired with `Subscribe` and removed with `Unsubscribe` in `FormClosed`, and `WAIT-FOR Application:Run(form)` followed by `QUIT`. Without the `QUIT`, prowin stays running after the window closes.
- Timer ticks, mouse clicks (with pixel to cell hit testing) and key presses were all confirmed through the spike log, driven by simulated input.
- **Dynamic extent limit: 28,000 elements, not 1,000,000.** A 1000 x 1000 board cannot be an INTEGER extent. A `MEMPTR` layer has no such limit and was as fast or faster (see below), so it is the planned backing for `ArrayStore`.
- Per cell `FillRectangle` through the bridge costs about 5 ms per paint at 20 x 20 and **about 95 to 100 ms at 100 x 100**, so 100 x 100 saturates at roughly 9 to 10 paints a second. The renderer will need a cheaper strategy (draw only live cells, or build a Bitmap and scale it). Flicker itself must be judged by eye using the checklist.

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
