# Framework review (Phase 7)

A review of the whole framework after four games and the Cookoff were built on it: what was checked, what was found and fixed, what was found and left alone on purpose, and why the repository stays whole. Written on 13 October 2026.

## What was reviewed

| Layer | Files | Interfaces | Public members | Lines |
|---|---|---|---|---|
| `Core` | 18 | 4 | 125 | 1,414 |
| `Engine` | 21 | 12 | 124 | 1,150 |
| `UI.Text` | 2 | 0 | 9 | 118 |
| `UI.WinForms` | 10 | 0 | 52 | 2,338 |

Plus the four games (7 to 9 classes each, about 1,000 lines each) and 57 test classes, 823 plain and 122 WinForms tests.

Two kinds of review:

1. **A scan of every source file** for the rules in `CLAUDE.md` that a script can check: a header comment on every class, `BLOCK-LEVEL ON ERROR UNDO, THROW.` in every class, wildcard `USING` only, no dash characters, a `SET-SIZE` wherever there is a `MEMPTR`, and every public member named in at least one test. The scan is now a tool, `tools/audit-conventions.ps1`, and the repository passes it. The layering check, the full compile and the whole test suite were run as well.
2. **A read of the framework code itself**, `Core`, `Engine` and `UI`, looking for what the scan cannot see: lost updates, overflow, wrong documentation, resource leaks, implementation detail in the public API, and code that only works while one program runs.

The games were checked by the scan and their tests, not read line by line: this is a review of the framework.

## Found and fixed

| # | Finding | Why it mattered | Fixed |
|---|---|---|---|
| 1 | **Settings could be lost when two games ran at once.** Every window read the settings file when it opened and wrote all of it back when it closed | The Cookoff runs games side by side. The last window to close undid a score or an option another game had saved, with no error | `Save` now rereads the file, puts in only the keys this program set, and writes that. Tests for two, and for deleted and corrupted files |
| 2 | **A temporary file name shared by every program** (`settings.json.tmp`) | Two saves at once could write the same file | The name now carries the time and a random number |
| 3 | **The clock and the notice fade read `Environment:TickCount`**, which wraps after about 25 days of uptime | Subtracting two readings across the wrap overflows an ABL `INTEGER`. A game open at that moment would raise an error on a tick | New `Ticks` class reads the Stopwatch as a 64 bit count. The clock's clamping rule is now tested |
| 4 | **`SeededRandom` failed on the lowest 64 bit seed** | `ABSOLUTE` of the most negative number overflows. The class says any whole number is a valid seed | That one value is now treated as 0, which it is equal to modulo 2^31. Test added |
| 5 | **`BattleshipsGame:OwnShotAt` had no test** | The rule is that every public method has one | Three tests |
| 6 | **Documentation that said something untrue** | `IGameController` said `IsRunning` is always false when not steppable (a real time game is not steppable and does run) and that `PauseGame` does nothing then. `Shape` said only `X` is a cell (a lower case `x` is too, because ABL ignores case). `ArrayStore` said `CopyBytesTo` is internal without saying why it is public | All three corrected |
| 7 | **The toolbar left a caption behind when it wrapped** (found while adding the option lists) | The word "Board" ended up on one row and its list on the next | Each caption and its control are now a unit in the toolbar |
| 8 | **A drop down list let the keys through while it was open** (found by the smoke test) | Typing in the list would also have stepped, reset or sped up the game | The window ignores the keys while any list is dropped down |
| 9 | **The Cookoff hid the third row of games** (found by adding a fifth game) | A game past the fourth was out of reach | The window grows to fit up to eight games and scrolls beyond |
| 10 | **A game's button colour changed when another game was added** | Colours were assigned by position in the list | A game's colour is the one its run file asks for, or one worked out from its title |

## Found and left alone, with the reason

| Finding | Why it stays |
|---|---|
| `ArrayStore:CopyBytesTo` and `CopyBytesFrom` are public and expose a `MEMPTR` | The dense Life engine and the board view copy a whole layer in one block through them, which is the difference between about 40 ms and several seconds a generation at 100 x 100. They are documented as internal and no game uses them |
| `TableStore:BufferHandle` hands out the temp table's buffer | It is for queries and debugging and says so. A game that writes through it breaks the store |
| `GameCommand:UndoMove` is not supported by any controller | The enum is the vocabulary for an undo game (Sokoban was on the list of ideas), and a controller that does not support a command already throws `GridException`. Removing and re adding it would cost more than it saves |
| `JsonFileSettings:Save` copies the temporary file over the real one (`OS-COPY`), which is not an atomic rename | ABL has no atomic rename. A crash during the copy could leave a bad file, and a bad file is already handled: it is ignored and rewritten. Merging on save keeps the window for trouble small |
| When two programs set the same key, the later save wins | There is no sensible merge for two different values of one setting. Different keys, which is what games use, merge cleanly |
| The stores are not thread safe | Everything runs on the UI thread, which is what makes ticks and drawing never race. Nothing in the framework starts a thread |
| `Shape:Equals` has no matching hash | ABL objects have no hash code to keep in step |
| `CustomNeighbourhood` is not `FINAL` | `MooreNeighbourhood` and `VonNeumannNeighbourhood` inherit from it |
| Dynamic extents are limited (about 28,000 elements) | A known ABL limit, already designed around: `ArrayStore` is a `MEMPTR`, and the performance notes say so |

## What was checked and found sound

- **Layering.** `Core` uses nothing else, `Engine` uses `Core`, `UI.Text` uses both, `UI.WinForms` is the only layer with .NET, and no game uses another game or the window. The layering check was green throughout.
- **Resource handling.** Every `MEMPTR` in the framework (`ArrayStore`, `TableStore`, `GridView`, the dense Life engine, Minesweeper's flood stack) is reset to size 0 in a `FINALLY`, a `Dispose` or a destructor, which was read, not only scanned for. Every .NET object that the windows make and keep is disposed in `ReleaseResources`, and every event a window subscribes to is unsubscribed when it closes.
- **No allocation in cell loops.** The hot loops in the framework (`GridView:FillPixels` and `PaintGlyphs`, `AbstractCellStore`, `ArrayStore`, `Grid:GetNeighbourIndexes`, the Life engines) work on integers and indexes, and the pens, brushes and fonts they need are made once outside the loop.
- **Error handling.** Contract violations throw `GridException` everywhere, with a message that names the offending value.
- **Settings.** A missing, empty, garbage, not an object, no version, wrong shape or newer version file is ignored and replaced on the next save, and each case has a test (the Phase 7 requirement).
- **Randomness.** All of a game's and an engine's randomness goes through `IRandom`. The only call of ABL's own `RANDOM` is in `JsonFileSettings`, to make a temporary file name unlike another program's, which needs no repeatability.

## How the public API has grown

The interfaces a game implements have stayed small and have only grown by extension, never by change:

| Added | For | Needed by |
|---|---|---|
| `ITurnBasedGame`, `TurnController`, `IGameController` | Games with no clock | Minesweeper |
| `IGameInput` members (`TakeNotice`, `InfoLabel`, `TertiaryAction`) | Notices, text screens, both mouse buttons | Minesweeper |
| `IRealTimeGame`, `RealTimeController`, `Pausable`, `HandleKey`, `BannerText` | Games on a clock the player does not drive | Tetris |
| `IGameOptions` | Extra drop down lists in the window | Life (rules and board size) |
| `IGameCatalog`, `IGameLauncher` | Finding and starting games | The Cookoff |

Each time, a game that did not need the addition kept compiling unchanged, because the new members went on a new interface or were already empty for it.

## One repository: decided

The original plan (stage 2) was to split the repository in two, a framework and a games repository, once three conditions held:

| Condition | Met? |
|---|---|
| The layering check has been green throughout | Yes |
| The public API has been reviewed | Yes, by this review |
| The last two games went in with no change to `Core` or `Engine` | No. Battleships added to `IGameInput` and to the window, Tetris added `IRealTimeGame`, the real time controller, `Pausable`, the key members and the banner, and Life's rule and size options added `IGameOptions` |

**Decision (James, 13 October 2026): the repository will not be split.** It stays one repository. That settles the question for good, so it is not an open item to revisit, and it is the simpler arrangement for what the project is: the framework and its games change together, a framework change and the game that needs it land in one commit, and the layering check already keeps the layers apart inside the one tree. Nothing in the framework depends on the split, and nothing needs to be prepared for it.

## Method notes for the next review

- `tools/check-template.ps1` proves the template still compiles and passes its tests, so a framework change that breaks new games is noticed straight away.
- `tools/audit-conventions.ps1` is the scan, and it needs no OpenEdge, so it is the quickest first step.
- The Phase 0 numbers have a second, cheaper check now: `bench/run-life-bench.ps1` measures the real engines at 500 x 500.
