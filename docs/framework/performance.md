# Performance notes

Measured in Phase 0 and Phase 3 on OpenEdge 12.8.0.1207, Windows 11. These numbers decided the storage design and the default store for each game. Re-measure before relying on them on another machine. The throwaway Phase 0 experiment code (`bench/phase0-storage.p` and its runners) was removed in Phase 7, once its results were written down here and the real Life engines had their own benchmark, `bench/run-life-bench.ps1`. It is still in git history: `git log --diff-filter=D -- bench/phase0-storage.p` finds the commit that removed it, and `git show <parent of that commit>:bench/phase0-storage.p` prints it.

## The rule of thumb

Interpreted ABL costs roughly 1 microsecond per simple operation. The work a generation does matters more than where the cells are stored, so code that touches only the cells that matter (live cells, changed cells) beats code that scans every cell when most of the board is empty. Method calls cost more than simple operations, so hot loops work directly on index arithmetic and memory, not on method calls per cell.

## Array and memory limits

- A dynamic extent array holds at most **28,000 elements**, not 1,000,000. A 1000 x 1000 board cannot be an INTEGER extent. This is why `ArrayStore` keeps its cells in a `MEMPTR` (4 bytes per cell), which has no such limit and was as fast or faster than an extent.
- An extent of `ROWID` fails after a few thousand elements. `TableStore` therefore keeps its per cell row ids as fixed width text in a `MEMPTR`, and is limited to 100,000 cells.
- Passing a large array to a procedure or assigning a whole large extent can overflow the stack (`-s`). Copy element by element or use a `MEMPTR`.
- Process working set tells you nothing about temp tables, because ABL pages them to its temp file.

## Storage benchmark (Phase 0)

Bounded edges, B3/S23, seeded random start. `ext` is a dynamic extent, `mem` is a MEMPTR, a trailing `f` adds an interior fast path (no bounds checks, unrolled neighbours), `tt` is a temp table with one record per cell, `sparse` is a temp table of live cells only. All modes gave identical live counts. Milliseconds per generation, 100 x 100, averaged over 20 generations:

| Start density | ext | extf | mem | memf | tt | sparse |
|---|---|---|---|---|---|---|
| 1% | 113 | 43 | 106 | 41 | 28 | 0.4 (board dies out) |
| 10% | 114 | 49 | 105 | 37 | 48 | 27 |
| 30% | 118 | 54 | 104 | 39 | 137 | 144 |

At 1000 x 1000: `mem` 10,347 ms per generation, `memf` 3,646 ms, `sparse` at 10% 6,392 ms, `sparse` at 30% 24,276 ms, `tt` at 10% 17,544 ms (and 17 seconds just to build 1,000,000 records). A Tetris style row clear and shift on a 10 x 20 temp table: about 2 ms for a four line clear.

Caveats: random 1% and 10% starts decay within a few generations, so the sparse averages favour sparse at low density. The temp table and sparse engines touch only live cells, while the dense ones scan every cell.

Conclusions that shaped the framework:

- Dense (`MEMPTR` with the interior fast path) is about 40 ms per generation at 100 x 100 whatever the density, so it is the safe default for boards up to a few hundred cells wide.
- Sparse wins on mostly empty boards and loses badly on crowded ones. The Life engines measured in Phase 3 break even at about 5% live cells (see [Life](../games/life.md)).
- 1000 x 1000 is not interactive in any mode. Treat roughly 200 x 200 as the practical interactive limit for dense Life.
- A temp table per cell (`TableStore`) suits small boards (Minesweeper, Battleships, Tetris) and is too slow for large Life boards.

## Life at 500 x 500 (Phase 7)

The real engines, built by `LifeFactory`, on a 500 x 500 board (250,000 cells) for 100 generations, bounded, B3/S23, a seeded random start, each case in its own `_progres -b` process (`bench/run-life-bench.ps1`, the case list and the program are in `bench/`). Same machine and install as above.

| Start | Engine | Live at start | Live at the end | Total for 100 generations | Per generation |
|---|---|---|---|---|---|
| 30% | Dense | 74,972 | 23,546 | 70.4 s | 703 ms |
| 10% | Dense | 24,988 | 11,780 | 71.9 s | 718 ms |
| 3% | Dense | 7,500 | 151 | 86.2 s | 861 ms |
| 3% | Sparse | 7,500 | 151 | 2.2 s | 22 ms |
| 1% | Sparse | 2,563 | 4 | 0.3 s | 3 ms |
| 0.3% | Sparse | 785 | 0 | 0.08 s | under 1 ms |

- **Dense is a steady 0.7 to 0.9 seconds a generation**, so a whole 100 generation run takes more than a minute, whatever the board holds. That is about 2.9 microseconds a cell, in line with the 300 x 300 figures (310 ms for 90,000 cells). The spread between the three dense rows is machine noise, not density.
- **Sparse follows the number of live cells**: 22 ms a generation for a run that starts with 7,500 and dies down to 151, which is the same board that takes the dense engine 86 seconds.
- **The sparse figures flatter it.** A random start at these densities collapses within a few generations (look at the "live at the end" column), so most of the 100 generations are nearly empty. A board that stays crowded costs sparse 8 to 75 microseconds a live cell (the Life page has the figures), so a settled population of 25,000 cells would cost it between 0.2 and 1.9 seconds a generation, about the same as dense or worse. That is why `LifeFactory` switches at 5% live and does not simply prefer sparse.
- **A 500 x 500 board is a run it, wait for it, look at it experience, not an interactive one** with the dense engine. The Life window offers boards up to 300 x 200 (60,000 cells, about 0.2 seconds a generation dense) for that reason, and a larger board can still be asked for with `life.width` and `life.height` up to 400.

## Neighbour lookup

`Grid:GetNeighbourIndexes` costs about 12.5 microseconds a call (125 ms to visit every cell of a 100 x 100 board), three times the inline loop. Engines that visit every cell therefore work from the precomputed index step of each neighbour offset and only call the grid for cells near an edge. Engines that visit few cells (the sparse Life engine) can call it freely.

## Drawing

- One `FillRectangle` call per cell through the .NET bridge costs about 5 ms a paint at 20 x 20 and **95 to 100 ms at 100 x 100**, a ceiling of roughly 9 paints a second.
- `GridView` instead builds a `Bitmap` with one pixel per cell directly over a `MEMPTR`, fills the pixels with `PUT-LONG`, and draws the whole board with one scaled `DrawImage` using nearest neighbour interpolation. That costs a few milliseconds at 100 x 100 (the WinForms tests assert under 50 ms for both the pixel fill and the paint).
- A double buffered `Panel` does not flicker at 10 repaints a second at 100 x 100 (confirmed by eye, and again for the real window).
