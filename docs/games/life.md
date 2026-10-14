# Conway's Game of Life

Status: complete and playable. Built in Phase 3 as the first game on the framework.

Life is a simulation, not a game with a winner. Every cell is alive or dead, and on each generation all cells change at once according to how many of their eight neighbours are alive. You draw a starting pattern, press Space, and watch it evolve.

## Playing it

From the repository root:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-life.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program, so the `USING` statements resolve. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`) and a number of seconds after which the window closes by itself (used by the automated checks).

### Controls

| Input | What it does |
|---|---|
| Left click on the board | Toggle a cell |
| Left click and drag on the board | Bring every cell the mouse passes over to life, in a straight line between the points the window was told about, so a fast drag leaves no gaps. A drag paints, it does not toggle (going back over a cell leaves it alive), and it is not also a click |
| Right click on the board | Place the chosen pattern with its top left corner at that cell (moved back if it would hang off the edge) |
| Space | Start, or pause when running |
| S or Right arrow | One generation |
| R | Reset to the board as it was at the first step |
| G | Random board (about a quarter of the cells alive), back to generation 0 |
| C | Clear the board |
| + or Up arrow, - or Down arrow | Faster, slower (six speeds, from 1000 ms down to 30 ms a step) |
| Pattern box | Choose which pattern a right click places. The keyboard goes back to the board once you have chosen |
| Rules box | Choose the rule set (below). It applies from the next generation, on the board you have |
| Board box | Choose the board size (below). The live cells stay where they are, and the board goes back to generation 0 |
| Speed slider and the buttons | The same things with the mouse |

The status bar and the window title show the generation, the number of live cells, the rules, the board size and the speed. Resizing the window rescales the cells. The window size, position, speed, chosen pattern, rules and board size are remembered between runs.

### Rules and board size

The Rules and Board boxes change a game that is running, without starting it again. A notice over the board says what was chosen.

| Rules | Notation | What it does |
|---|---|---|
| Conway | B3/S23 | The classic |
| HighLife | B36/S23 | Like Conway, plus a small replicator |
| Seeds | B2/S | Nothing survives, every cell with two neighbours is born: explosive |
| Day and Night | B3678/S34678 | Symmetric between live and dead |
| Life without Death | B3/S012345678 | Cells never die, so patterns only grow |
| Maze | B3/S12345 | Fills the board with maze-like walls |

A rule set from `life.rules` that is none of these is added to the box under its notation. Changing the rules keeps the board, the generation and the state that Reset returns to.

The board sizes are 50 x 35, 75 x 50, 100 x 70, 150 x 100, 200 x 140 and 300 x 200, and the current size is added when it is something else (from `life.width` and `life.height`). A new size keeps every live cell in the same place, and loses the ones outside a smaller board. It goes back to generation 0, because the state that Reset returns to belongs to the old size, and the first step after it saves the new one. The wrapping and the engine choice (dense or sparse, by `life.expectedLive`) carry over, and the engine is chosen again for the new rules, since a rule with a birth on no neighbours (`B0`) needs the dense one.

### Patterns

Eleven named patterns, listed in the pattern box: Block, Beehive, Blinker, Toad, Beacon, Glider, LightweightSpaceship, RPentomino, Diehard, Acorn and GosperGliderGun. `LifePatterns:FromPlainText` also reads the common plain text pattern format (`!` comment lines, `.` dead, `O` alive).

### Settings

Edit `%APPDATA%\ProGriddle\settings.json` while the program is closed. Every key is optional. The file holds a `schemaVersion` and a `values` object. A missing or damaged file is ignored and rewritten on the next save.

| Key | Meaning | Default |
|---|---|---|
| `life.width`, `life.height` | Board size in cells, 5 to 400 | 100, 70 |
| `life.wrap` | `true` makes the edges wrap round | `false` |
| `life.rules` | Rules in B/S notation, for example `B36/S23` for HighLife | `B3/S23` |
| `life.expectedLive` | Expected share of live cells, 0 to 1. Below 0.05 the sparse engine is used (good for big, mostly empty boards) | 0.1 |
| `life.palette` | Dead and alive colours as hex | `1B1F24,F2C14E` |
| `life.startPattern` | Pattern placed on a new board, or `None` | `GosperGliderGun` |

The window also saves `window.width`, `window.height`, `window.x`, `window.y`, `window.maximised`, `life.speed`, `life.choice` (the pattern), `life.ruleset` (the name of the rule set, or its notation) and `life.size` (such as `150 x 100`) by itself. A saved `life.ruleset` or `life.size` wins over `life.rules`, `life.width` and `life.height` the next time the window opens. Edit or delete it to go back to those.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Steppable: `LifeGame` implements `ISteppableGame` on `AbstractGame`. The whole grid changes on each step. |
| Grid | One layer called `state`, 0 for dead and 1 for alive. Bounded by default, wrapped with `life.wrap`. Moore (8 cell) neighbourhood. |
| Stores | `ArrayStore` for crowded boards and `SparseStore` for mostly empty ones, chosen by `LifeFactory`. |
| Window | The generic `GameWindow`. Life describes itself to it through `LifeInput` (the `IGameInput` implementation). |
| Controller | The generic `GameController` with a `WinFormsClock`. |
| Settings | `JsonFileSettings`, read by `run/run-life.p` and the window. |
| Randomness | `SeededRandom` through `IRandom`, so the random board is repeatable in tests. |

Source: `src/ProGriddle/Games/Life/`. The composition root, the only place that builds and wires the concrete classes, is `run/run-life.p`.

| Class | Job |
|---|---|
| `LifeRules` | The birth and survival rule as data, in B/S notation. `B3/S23` is Conway's rule and `B36/S23` is HighLife. Counts outside 0 to 8 never give a birth or a survival. It also knows the six presets the Rules box offers. |
| `LifeSizes` | The board sizes the Board box offers and the text form `100 x 70`, with the limits of 5 and 400 cells a side. |
| `LifePatterns` | The named patterns, built on the framework's `Shape`, and the plain text loader. |
| `ILifeEngine` | Computes one generation on a grid, in place. |
| `DenseLifeEngine` | For an `ArrayStore`. Copies the layer out in one block, computes the next generation into a second buffer, and copies it back, so the update is simultaneous. Interior cells use precomputed index steps (unrolled for eight neighbours); edge cells ask the grid, so bounded and wrapped boards both work. |
| `SparseLifeEngine` | For a `SparseStore`. Exports the live cells, adds one to the count of each neighbour in a second temp table, decides only the counted cells, and imports the survivors. Its cost follows the number of live cells. It refuses rules with a birth on zero neighbours (`B0`). |
| `LifeGame` | The game. Single layer `state`. Reset (`Initialise`) returns to the board as it was when the first step was taken. |
| `LifeFactory` | Builds a game with the right store and engine for the expected crowding, and `Rebuild` changes the rules and size of a running game. |
| `LifeInput` | Left click toggles, left click and drag paints, right click places the chosen pattern, Random and Clear start a new board. It also implements `IGameOptions` for the Rules and Board boxes and `IDragInput` for the painting. |

## Performance

Random start, milliseconds per generation. The two engines are checked against each other, and against a slow reference, in `LifeEngineTests`.

| Board | Live at start | Dense | Sparse |
|---|---|---|---|
| 100 x 100 | 3% | 46 | 8 |
| 100 x 100 | 10% | 50 | 47 |
| 100 x 100 | 30% | 46 | 263 |
| 300 x 300 | 3% | 314 | 166 |
| 300 x 300 | 10% | 311 | 680 |
| 300 x 300 | 30% | 306 | 2638 |

On a 500 x 500 board for 100 generations (Phase 7, see [Performance notes](../framework/performance.md#life-at-500-x-500-phase-7)) the dense engine takes 0.7 to 0.9 seconds a generation whatever the density, 70 to 86 seconds in all, while the sparse engine takes 22 ms a generation from a 3% start and 3 ms from a 1% start, because those random boards die down within a few generations.

The dense engine costs the same at any density. The sparse engine costs 8 to 75 microseconds per live cell, so it wins only on mostly empty boards. They break even at about 5% live cells, and `LifeFactory` uses sparse below that. A board of 1000 x 1000 is not interactive in any mode. Background and the wider benchmark are in [Performance notes](../framework/performance.md).

## Tests

All under `tests/ProGriddle/Games/Life/`.

| Test class | What it proves |
|---|---|
| `LifeRulesTests` | The rule notation, births and survivals, bad input, the presets |
| `LifeSizesTests` | The offered sizes, the text form, the limits |
| `LifePatternsTests` | Each pattern's size, the name lookup, the plain text loader |
| `LifeEngineTests` | The Life behaviour itself, run on both engines: still lifes, oscillators, gliders (including the torus return after 4 x width generations), the Gosper gun, HighLife, S0 rules, and every generation of random boards against a slow independent reference |
| `LifeGameTests` | Editing cells, placing patterns, randomising, reset behaviour, validation, replacing the grid and engine |
| `LifeFactoryTests` | The 5% switch over, what it builds, and rebuilding a running game: cells kept or lost, generation, wrapping, the engine chosen again |
| `LifeInputTests` | The status text, the pattern picker, clicks and drags, the extra commands and the Rules and Board options |
| `GameWindowOptionsTests` (WinForms) | The window puts back saved options and ignores ones that are not on offer |
| `LifeSessionTests` | Whole keyboard sessions through `GameController`, `FakeClock` and `TextGridRenderer`, with no window |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1`.

## Checking the window

`tools/gui-smoke-life.ps1` launches the real window with a throwaway settings file and drives it like a user. It finds the board from a screenshot, clicks and types, drives the pattern, rules and board lists with a real mouse and the arrow keys (HighLife, Seeds, back to Conway, then a bigger, a smaller and the usual board), reads the state back from the window title, resizes the window, closes it, checks that the process exits and the settings were saved, drags the mouse across the board (in a few big jumps, to check no cell is skipped), then starts it again to see them restored. It sends real keystrokes and mouse clicks to the foreground, so leave the keyboard and mouse alone for the minute or so it takes. Screenshots go to `build/screenshots`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/gui-smoke-life.ps1
```

### Manual checklist

The smoke test covers behaviour. These are the things only your eyes can judge:

- [ ] No flicker or tearing while it runs at the fastest speed on a full board (press G, then Space, then + until Speed 6).
- [ ] The grid lines and cells look crisp and the cells stay square when you resize the window.
- [ ] The board is centred, with the same margin on both sides.
- [ ] The toolbar is readable and wraps sensibly when the window is made narrow.
- [ ] Window title, status bar and board all agree on the generation and live cell count.
- [ ] After closing, the window process is gone from Task Manager (watch for a leftover `prowin.exe`).

## Design notes

- Right click is the only way to place a pattern. A "choose a pattern, then left click to place it" mode was considered and deliberately not built.
- The window title carries the status text and the speed so that scripts can read the state from outside.
- Reset returns to the board as it was when the first step was taken, or to a board saved with `CaptureStart`. Editing at generation 0 and then stepping saves the edited board as the new start. With nothing captured, Reset empties the board.
- The sparse engine and the dense engine count each distinct neighbouring cell once, and never count a cell as its own neighbour, which only matters on tiny wrapped boards (see [Edges and neighbours](../../README.md#edges-and-neighbours)).
