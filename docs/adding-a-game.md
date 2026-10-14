# Adding a game

This is the long form of [Creating a new game](../README.md#creating-a-new-game) in the README. By the end you have a game that compiles, has tests, has a page of its own, and has a button in the Cookoff, and you know where each part of it lives. It takes about half an hour for the first game.

You need the repository running first: see [Getting running](../CONTRIBUTING.md#getting-running). The conventions are in [CONTRIBUTING.md](../CONTRIBUTING.md) and, in full, in [CLAUDE.md](../CLAUDE.md).

## 1. Start from the template

Pick a name: a capital letter, then letters and digits, such as `Pong`. It becomes the namespace `ProGriddle.Games.Pong`. Then, from the repository root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/new-game.ps1 -Name Pong -Title "Pong" -Blurb "A bat, a ball and the first to eleven."
```

It writes six files and changes nothing that exists (if any of the six is there already it writes nothing and says which):

| File | What it is |
|---|---|
| `src/ProGriddle/Games/Pong/PongGame.cls` | The rules. The template game lights one cell and moves it along the board, so there is something to see |
| `src/ProGriddle/Games/Pong/PongInput.cls` | What the window needs from the game: the status line, and the clicks, keys, picker and commands the game adds |
| `tests/ProGriddle/Games/Pong/PongGameTests.cls` | Tests of the rules |
| `tests/ProGriddle/Games/Pong/PongInputTests.cls` | Tests of the input |
| `run/run-pong.p` | The composition root: the one place that builds the real objects and starts the window |
| `docs/games/pong.md` | The game's page |

Check that you start from something that works:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Pong*"
cookoff.bat
```

The tests pass, and the Cookoff has a Pong button (the `Arcade:` line in the header of `run/run-pong.p` is where its title and blurb come from). Click it and press Space: a lit cell crawls along the board. Space starts and pauses, S steps, R resets.

## 2. Choose the kind of game

The template is **steppable**: every tick of a clock changes the whole grid, as in Life. There are three kinds, and the kind decides which interface the game implements and which controller drives it:

| Kind | The game implements | Driven by | The move is | Example |
|---|---|---|---|---|
| Steppable | `ISteppableGame` (`Step`, `Generation`) | `GameController` and a clock | The clock | [Life](games/life.md) |
| Turn based | `ITurnBasedGame` (`Turn`) | `TurnController`, no clock | A click or a command on the game's own methods | [Minesweeper](games/minesweeper.md), [Battleships](games/battleships.md) |
| Real time | `IRealTimeGame` (`Paused`, `Tick`) | `RealTimeController` and a clock | A key, and the clock's `Tick` | [Tetris](games/tetris.md) |

To change kind, change the interface the game implements, the controller in `run/run-pong.p`, and what `PongInput` does with clicks and keys. The pages above show each shape in full. Whatever the kind, the game inherits `AbstractGame`, which supplies the name, the grid, `IsOver` and the counter.

## 3. Make the rules yours

Write the test first, then the rule. The template's tests show the pattern: build the game on a small `ArrayStore`, call a method, compare the board as text with `TextGridRenderer`:

```
METHOD PUBLIC VOID StepMovesTheLitCellOneAlongAndCountsTheGeneration():
    mGame:Step().
    Assert:Equals(1, mGame:Position).
    Assert:Equals(".#../..../....", Board()).
END METHOD.
```

Then change `Step`, `OnInitialise` and what the grid holds. A few things to know:

- **The grid and its layers.** A grid is a width, a height and a *store* of named layers of integers, for example `"state"` or `"mine,revealed,flag,view"`. Pick the store by the size of the board: `ArrayStore` for most boards (fast, a block of memory), `SparseStore` for big mostly empty boards, `TableStore` for small boards where named fields and queries help (Minesweeper, Battleships, Tetris). [Performance notes](framework/performance.md) has the numbers.
- **A `view` layer.** When the picture is not simply the rules (Minesweeper hides cells, Tetris overlays a falling piece), keep one more layer that holds, for each cell, just what to draw. The window turns that number into a colour with a palette, and the tests compare it as text.
- **Shapes.** `Shape` is an immutable set of cell offsets that can rotate and flip. Life patterns, Battleships ships and Tetris pieces are all shapes, and `Stamp`, `Erase` and `CanPlace` put them on a layer.
- **Randomness** goes through `IRandom`. Pass a `SeededRandom` from the run file and tests get the same game every time.
- **Named values are enums.** If the game has phases, kinds of cell, view codes or a palette, make each an `ENUM` in its own file (`MyGamePhase`-style, see `GamePhase` in Asteroids) and not a list of `&GLOBAL-DEFINE` lines in an include. Write `INTEGER(ViewCode:Head)` where a value goes into a cell store.
- **Throw `GridException`** for a call that breaks the contract. Never return a magic value.
- **No allocation in a loop over cells.** Read and write cells with `GetCellAt` and `SetCellAt`, and build objects outside the loop.
- **The game never touches a window, a timer or a .NET type.** If it needs the time, it takes an `IClock`, and tests pass a `FakeClock` they advance by hand.

## 4. Tell the window about the game

`PongInput` implements `IGameInput`, and the generic `GameWindow` builds everything from it. Each member you fill in gives the window something:

| Member | The window gets |
|---|---|
| `StatusText` | The status bar and the window title (a script can read it from outside) |
| `ChoiceLabel`, `ChoiceNames`, `Choice` | A drop down list, such as the pattern list of Life |
| `CommandNames` | Extra buttons and keys, written `Name:Letter`, such as `Random:G,Clear:C`. `Perform` runs them |
| `PrimaryAction`, `SecondaryAction`, `TertiaryAction` | Left click, right click, and a middle click or both buttons, on a cell (a double click is a primary then a tertiary) |
| `HandleKey`, `ReleaseKey` | The game's own keys, for a real time game. Return true for a key you use |
| `BannerText` | Words kept over the board, such as `PAUSED` or `GAME OVER` |
| `TakeNotice` | A few words that fade, saying what the last action did, or why it was refused |
| `InfoLabel`, `InfoText` | An extra screen of text, such as high scores or help |

More drop down lists, for example a rule set or a board size, come from also implementing `IGameOptions` (Life does). Test each of these in `PongInputTests`.

## 5. Settings

A game reads and saves values through `ISettings`, namespaced by the game: `pong.width`, `pong.highScore`. Reading never fails (a missing or wrong typed key gives the default you pass). The run file reads the starting options, and the window saves its own size, position and speed. Several games share the one file, and a save puts in only the keys that program set, so games do not undo each other.

## 6. Check the window

The generated run file works as it stands. The pieces it wires, in order: settings, game, view (`GridView` with a palette: value 0 is the first colour, value 1 the second), clock, controller, window. Change the palette to give the cell values their colours. For text in cells (numbers, flags) see `SetGlyphs`, and remember a flag or a bomb outside Latin 1 must be given as a code point.

Any game with real interaction deserves a smoke test in the style of `tools/gui-smoke-life.ps1`: it launches the real window with a throwaway settings file, drives it with real keys and clicks, reads the state back from the window title and from screenshots, and checks the settings were saved. Warn anyone before you run it, because it takes over the keyboard and mouse.

## 7. Finish properly

- **Tests.** Every public method has one. `tools/run-tests.ps1 -All` is green.
- **Layering.** `tools/check-layering.ps1` passes: your game uses only `Core` and `Engine`, never another game and never the window.
- **Compile.** `tools/compile.ps1` lists no problems.
- **The page.** Edit `docs/games/pong.md` so it describes your game: how to play, controls, settings, how it uses the framework, tests, design notes.
- **The README.** Add a line to the Games list in `README.md` that links the page. A game is not finished until the page exists and is linked.
- **The Cookoff.** Make sure the `Arcade:` line in `run/run-pong.p` says what you want on the button: `Arcade: Title | one line about it | colour`. The colour is optional (red, orange, blue, purple, green, yellow or teal), and a game that names none gets one worked out from its title, which stays the same whatever else is added. `Arcade: hidden` keeps a run file out of the Cookoff, and a run file with no such line gets a button titled from its file name.
- **The framework.** If the game needed the framework to change, it changed in `Core` or `Engine` with its own tests, not as a special case for your game.
- **Commits.** Small, one per sub step, with messages that say what and why.

## Mistakes to expect

The compiler message is usually clear, but a few are not:

| Symptom | Cause |
|---|---|
| "The keyword x may not be used as a name" | `x` is an ABL keyword. The usual suspects: `text`, `line`, `first`, `group`, `status`, `key`, `font`, `row`, `col`, `header`, `current`, `last`. Rename it |
| An error prints but the code carries on | The class is missing `BLOCK-LEVEL ON ERROR UNDO, THROW.` |
| Two symbols behave as one | Text comparison ignores case, so `"o"` equals `"O"` |
| A `?` where a symbol should be | A `CHARACTER` under `prowin` is ISO 8859-1. Pass the symbol to `GridView` as a code point |
| An unterminated comment | A `*/` inside a comment, even in an example string |
| A string with `~` in it loses a character | `~` is the escape character in an ABL string |
| An inherited test does not run | ABLUnit does not run `@Test` methods of a base class |
| The tests "passed" but something failed | ABLUnit exits 0 even when tests fail. Use `tools/run-tests.ps1` |

More in [OpenEdge environment notes](framework/environment.md).
