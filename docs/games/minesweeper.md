# Minesweeper

Status: complete and playable. Built in Phase 4 as the first turn based game, and the first real test of the framework.

The rules are those of the classic Windows game. The look is modern: a dark board with flat tiles, bright numbers, a bomb and flag drawn from a symbol font, and a window that scales to any size. Everything in the [rules](#the-rules) section matches Windows Minesweeper, including the details people tend to get wrong (the first click, the way a flood treats flags, what a chord does).

## Playing it

From the repository root:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-minesweeper.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the mines. The last two are used by the automated checks.

### Controls

| Input | What it does |
|---|---|
| Left click on a closed cell | Open it. A flagged cell cannot be opened. A question marked cell can |
| Right click on a closed cell | Cycle: nothing, flag, question mark (when Marks is on), nothing |
| Both buttons together on an open number, a middle click, or a double click | Chord (see below) |
| Scores button or H | Show the high scores. Enter, Escape or OK closes the screen |
| F2 or R, or the New game button | Start a new game at the same level |
| Level box | Choose Beginner, Intermediate, Expert or Custom. Choosing starts a new game. Tab reaches it from the board and the arrow keys change it |
| Marks button or M | Switch the question mark step of the right click on or off. Remembered. A notice ("Question marks on" or "off") appears over the middle of the board and fades away |

Mouse buttons are read as a gesture and acted on when the last one is released, on the cell under the pointer, so a chord with both buttons never flags or opens anything on the way. A double click on a number is a chord too, which saves reaching for the second button: when the number already has that many flags round it, everything else around it opens. (On a closed cell, a double click is just two opens, and the second does nothing.)

### The high scores screen

The Scores button, or H, opens a window with the three standard levels, each with its board size and a ranked list of its ten fastest winning times, or "No wins yet". It shows what is in the settings file, so a new win is on it straight away.

The status bar and the window title show the level, the board size, the mine counter, the timer, the state (Ready, Playing, You win!, Game over), the best time for the level and whether Marks is on. The mine counter and the timer are three digits as in Windows.

### The levels

| Level | Board | Mines |
|---|---|---|
| Beginner | 9 x 9 | 10 |
| Intermediate | 16 x 16 | 40 |
| Expert | 30 x 16 (30 wide, 16 high) | 99 |
| Custom | width 9 to 30, height 9 to 24 | 10 up to (width - 1) * (height - 1) |

Custom values come from the settings file (below) and are brought back into range if they are outside it.

## The rules

These are the rules of Windows Minesweeper, one by one.

- **Opening a cell.** A cell with mines around it shows how many (1 to 8). A cell with none opens all eight neighbours, and each of those that is also blank does the same, and so on. The flood is done with an explicit stack, never recursion, so any board size is safe.
- **The flood and flags.** A flood skips flagged cells and they stay closed and flagged. A question marked cell is opened by a flood, and its mark goes.
- **The first click.** The first cell opened is never a mine. The mines are placed when the game starts, and if the first click lands on one, that mine moves to the first free cell in reading order (top row first, left to right), as Windows does. The neighbours of the first click can still be mines, so there is no guarantee of an opening.
- **Losing.** Opening a mine ends the game. The mine you opened turns red, every other mine is shown, and every flag that was not on a mine is crossed out. Correct flags stay as flags. The timer stops.
- **Winning.** The game is won when every cell that is not a mine is open. Flags are not needed. All the mines are then flagged for you, so the counter reads 000, and the timer stops.
- **The mine counter** is the number of mines minus the number of flags, and goes negative (shown `-01`) if you flag too many. Question marks are not flags and do not count.
- **The timer** starts on the first cell you open (flagging first does not start it), shows 001 straight away, counts a second at a time and stops at 999.
- **Chording** (both buttons, middle click or double click). On an open number, if the number of flags around it equals the number, every closed, unflagged neighbour is opened at once. If a flag is wrong, that opens a mine and loses. With too few or too many flags a chord does nothing. Question marks do not count as flags.
- **Best times.** Each of the three standard levels keeps a high score list of the ten fastest winning times (Custom games keep none). See the settings below.

## Settings

Edit `%APPDATA%\ProGriddle\settings.json` while the program is closed. Every key is optional.

| Key | Meaning | Default |
|---|---|---|
| `minesweeper.choice` | Level: `Beginner`, `Intermediate`, `Expert` or `Custom`. Saved when the window closes | `Beginner` |
| `minesweeper.marks` | `true` for the question mark step of the right click. Saved when you press Marks | `true` |
| `minesweeper.customWidth` | Width of a Custom game, 9 to 30 | 9 |
| `minesweeper.customHeight` | Height of a Custom game, 9 to 24 | 9 |
| `minesweeper.customMines` | Mines in a Custom game, 10 up to (width - 1) * (height - 1) | 10 |
| `minesweeper.scores.beginner`, `.intermediate`, `.expert` | The high score list, kept by the game | none |

A high score list is one string of up to ten winning times in seconds, fastest first, for example `"47,52,52,96"`. A win is added in its place, and a time that ties an older one ranks below it. The status line shows the head of the list as the best time. A hand edited list is read tolerantly: entries that are not a time from 1 to 999 are dropped and the rest are put in order.

The window also saves `window.width`, `window.height`, `window.x`, `window.y` and `window.maximised` by itself. These are shared with the other games.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Turn based: `MinesweeperGame` implements `ITurnBasedGame` on `AbstractGame`. Moves are Reveal, ToggleFlag and Chord. `Turn` counts the moves that changed the game |
| Grid | Five layers: `mine` (1 for a mine), `revealed`, `flag` (0 none, 1 flag, 2 question mark), `adjacent` (mines around) and `view` (what to draw). Bounded, Moore (8 cell) neighbourhood |
| Store | `TableStore`, so each cell is a record with named fields, as the plan intended for small boards |
| Controller | `TurnController`, with no clock of its own: the game changes only when a move is made |
| Clock | The game takes an `IClock` for the timer only. The window uses the same clock to refresh the status line each second. `FakeClock` makes the timer testable |
| Window | The generic `GameWindow`, which hides Start, Step and speed for a turn based game and shows New game. `MinesweeperInput` describes the game to it through `IGameInput` |
| Drawing | `GridView` with a palette and glyphs per value of the `view` layer (see below) |
| Randomness | `SeededRandom` through `IRandom`, so a seed gives the same board every time |
| Settings | `JsonFileSettings`, read by `run/run-minesweeper.p`, the input and the window |

Source: `src/ProGriddle/Games/Minesweeper/`. The composition root is `run/run-minesweeper.p`.

| Class | Job |
|---|---|
| `MinesweeperGame` | The game and all the rules above. `Reveal`, `ToggleFlag`, `Chord`, `Configure` (size and mines), `LoadBoard` (mines from text, for tests), readers for each layer |
| `MinesweeperInput` | The `IGameInput`: clicks, the level picker, the Marks command and the status line |
| `MinesweeperLevels` | The classic levels and the limits of a Custom game |
| `MinesweeperBestTimes` | The high score lists in the settings |
| `MinesweeperLook` | The colour, glyph and glyph colour for each `view` code, and the symbols used to draw a board as text in tests |
| `MinesweeperFactory` | Builds the grid and the game |
| `ViewCode` (an enum) | The meaning of each `view` value: 0 hidden, 1 flag, 2 question mark, 3 to 11 open with 0 to 8 around, 12 mine, 13 exploded mine, 14 wrong flag |

### What the framework had to learn

Minesweeper was the first game that did not fit the framework as it stood, so the framework changed rather than the game working round it:

- **Turn based games.** `ITurnBasedGame` and `TurnController` are new, and `IGameController` is the small interface `GameWindow` now uses, so the same window hosts a steppable game with a clock or a turn based one without. `GameController` implements it too.
- **Glyphs.** `GridView` only drew one coloured pixel per cell. `SetGlyphs` now draws text in cells by value, in a colour per value, with a cached font and brushes so a repaint allocates nothing per cell. Anything outside Latin 1 is given as a code point (`U+1F4A3`), because an ABL `CHARACTER` here is ISO 8859-1 and silently turns a bomb into a question mark. Code points are built as UTF-8 in a `LONGCHAR`, which the .NET bridge hands over as a real string.
- **Both buttons.** `IGameInput` gained `TertiaryAction` (a middle click or both buttons), and `GameWindow` now reads mouse input as a gesture acted on at release. Life ignores it.
- **New game keys.** F2 resets, as in Windows.
- **An extra text screen.** `IGameInput` gained `InfoLabel` (a name and a key such as `Scores:H`) and `InfoText`. The window adds a button and the key, and shows the text in the new `InfoDialog`. Any game can use it for scores, help or rules.
- **A notice over the board.** `IGameInput` gained `TakeNotice()`: after every action the window shows what it returns in the middle of the board for about a second and fades it out (`GridView:ShowNotice`). A button that only changes a setting otherwise gives no sign that it did anything.
- **Double click.** The window turns a double click into a `PrimaryAction` followed by a `TertiaryAction`, so Minesweeper chords and Life, which toggles on every click, still sees both clicks.
- **A game can change its own board size.** `Configure` replaces the game's grid, and `GridView` already resized to follow.

## Tests

All under `tests/ProGriddle/Games/Minesweeper/`, plus the framework tests next to the pieces they cover.

| Test class | What it proves |
|---|---|
| `MinesweeperGameTests` | Every rule above on boards set up with `LoadBoard`: counts, flood and flags, the first click on many seeded boards of every level, win and loss display, flag cycle, chording, the timer, a whole game, a flood over a 30 x 24 board |
| `MinesweeperInputTests` | The level picker, custom limits, clicks, the status line, high scores through a win, the scores screen text, the Marks command |
| `MinesweeperBestTimesTests` | Ranking, ties, the ten place limit, hand edited settings |
| `MinesweeperLevelsTests` | The classic levels and the custom limits |
| `MinesweeperLookTests` | The look lists line up with the view codes |
| `MinesweeperFactoryTests` | What the factory builds |
| `TurnControllerTests` (Engine) | The turn based controller |
| `GridViewTests` (WinForms) | Glyphs: by store kind, code points, painting |
| `InfoDialogTests` (WinForms) | The text screen: title, text, Enter and Escape close it |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Minesweeper*"`.

## Checking the window

`tools/gui-smoke-minesweeper.ps1` launches the real window with a throwaway settings file and a fixed seed, asks `tools/minesweeper-layout.p` where the mines are, and plays: flags and question marks, a left click on a flag, the timer, a chord with both mouse buttons and another with a double click, the scores screen blocking the board and closing on Escape, a whole winning game, the high score saved, F2, the level picker, a loss with the red mine, and starting again with Expert and Custom from the settings. It reads state from the window title and from cell colours in screenshots. It sends real keystrokes and mouse clicks to the foreground, so leave the keyboard and mouse alone for the couple of minutes it takes. Screenshots go to `build/screenshots`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/gui-smoke-minesweeper.ps1
```

### Manual checklist

- [ ] The numbers, flags and bombs are crisp and centred at every window size.
- [ ] Hidden, open and exploded cells are easy to tell apart.
- [ ] Both buttons together feels right on a real mouse, and a middle click works too.
- [ ] The toolbar is readable and the level box is easy to find.

## Design notes

- A cell on an edge or in a corner next to a mine can have only numbers around it, so a flood can never reach it. It has to be clicked. That is true of Windows Minesweeper too, and a test that expects a whole board to open from one click has to start from a mine in the middle.
- The `view` layer exists so drawing needs no rules: the game keeps one number per cell up to date and the window turns it into a colour and a glyph. The text renderer in the tests reads the same layer, which is what lets a test compare a whole board as a string.
- Mines are placed when the game starts and the first click only moves one if it lands on it. That keeps the board a pure function of the seed, so the same seed gives the same game.
- The best time is the head of the high score list. There is no name entry, because the classic names were only a label.
- A turn based game has no clock of its own. The timer is the game listening to a one second `IClock`, and the same clock tells the window to refresh the status line.
