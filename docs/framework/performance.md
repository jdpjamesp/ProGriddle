# Performance notes

Measured in Phase 0 and Phase 3 on OpenEdge 12.8.0.1207, Windows 11. These numbers decided the storage design and the default store for each game. Re-measure before relying on them on another machine.

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

## Neighbour lookup

`Grid:GetNeighbourIndexes` costs about 12.5 microseconds a call (125 ms to visit every cell of a 100 x 100 board), three times the inline loop. Engines that visit every cell therefore work from the precomputed index step of each neighbour offset and only call the grid for cells near an edge. Engines that visit few cells (the sparse Life engine) can call it freely.

## Drawing

- One `FillRectangle` call per cell through the .NET bridge costs about 5 ms a paint at 20 x 20 and **95 to 100 ms at 100 x 100**, a ceiling of roughly 9 paints a second.
- `GridView` instead builds a `Bitmap` with one pixel per cell directly over a `MEMPTR`, fills the pixels with `PUT-LONG`, and draws the whole board with one scaled `DrawImage` using nearest neighbour interpolation. That costs a few milliseconds at 100 x 100 (the WinForms tests assert under 50 ms for both the pixel fill and the paint).
- A double buffered `Panel` does not flicker at 10 repaints a second at 100 x 100 (confirmed by eye, and again for the real window).
