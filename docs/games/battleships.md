# Battleships

Status: complete and playable. Built in Phase 5 as the second turn based game, and the first with two boards and a computer opponent.

You and the computer each hide a fleet on a square sea. You place yours by hand (or at random), then take turns firing at each other's waters, one shot each whatever happens. The first to sink the other's whole fleet wins.

## Playing it

From the repository root:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-battleships.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the fleets and the computer's shots. The last two are used by the automated checks.

Both boards are on screen at once. The computer's waters are on the left, in blue, where you fire. Your own fleet is on the right, in teal. The dark column between them is only a divider.

### The rules

- **The fleet follows the board size.** A bigger sea holds more and longer ships (table below). Both sides get the same fleet.
- **No ship is shorter than two cells,** and a ship is a straight line, horizontal or vertical. A ship is never diagonal and never bent.
- **Ships may not touch,** not side to side, not end to end and not even at a corner. Every ship is surrounded by water, on your board and on the computer's.
- **Turns.** You fire at one cell of the computer's waters, and then the computer fires at one cell of yours. A hit does not give an extra shot. The computer does not reply to a shot that wins the game.
- **Sinking.** A ship is sunk when every one of its cells has been hit. You are told when you sink one and how long it was, and the whole ship shows as sunk.
- **Winning.** The first side to sink every ship of the other wins. If you lose, the computer's ships that you never found are shown.

| Board | Size | Fleet (ship lengths) | Ship cells |
|---|---|---|---|
| Tiny | 6 x 6 | 3, 2, 2 | 7 |
| Small | 8 x 8 | 4, 3, 3, 2 | 12 |
| Classic | 10 x 10 | 5, 4, 3, 3, 2 | 17 |
| Large | 12 x 12 | 5, 4, 4, 3, 3, 2, 2 | 23 |
| Huge | 15 x 15 | 6, 5, 4, 4, 3, 3, 3, 2, 2 | 32 |

Choose the board in the Board box. Choosing starts a new game. Every fleet takes under a fifth of its board, so the no touching rule can always be met.

### Placing your fleet

Until you fire your first shot you can rearrange your fleet:

| Input | What it does |
|---|---|
| Left click on your board | Place the next ship (longest first) with its first cell where you click, going across or down. A ship that would hang off the edge is moved back to fit. A ship that would touch another is refused and the notice says so |
| Rotate button or O | Turn the next ship horizontal or vertical. The status line says which |
| Right click on one of your ships | Take it back off. It becomes the next to place |
| Random button or F | Put the whole fleet on at random, replacing any you placed |
| Clear button or C | Take your whole fleet off |

When all your ships are down the status line says "Fleet ready" and the left board is open for firing. Placing more is refused.

### Firing and marking water

| Input | What it does |
|---|---|
| Left click on the computer's waters | Fire at that cell |
| Right click on the computer's waters | Mark the cell as water, or clear the mark. A marked cell cannot be fired at until you clear it |
| Water button or W | Mark every cell that must be water (see below) |
| Rules button or H | Show the rules and these controls |
| F2 or R, or the New game button | Start a new game on the same board |

**Marking water.** Marks are notes to yourself, shown as a wave. You can mark any cell you have not fired at, and a mark is not a turn. The Water command does the sure part for you:

- the four corners of every hit, because a ship is a straight line and so can never be diagonal to one of its own cells, and
- all eight cells round every sunk ship, because ships may not touch.

It leaves alone cells you have already fired at or marked, and says how many cells it marked. Anything else you work out, such as the cells next to a two-cell ship's missing end, you mark by hand.

### What the cells mean

On the computer's side: a wave is a cell you marked as water, a dot is a miss, a red cross is a hit, and a dark red cross is a ship you have sunk. On your side: steel blue is one of your ships, a dot is a shot of the computer's that missed, a red cross is a hit on you, and the computer's latest shot is lit so you can find it. A notice over the middle of the board says what the last turn did ("You hit a ship. Computer missed.") and fades away. The status line and the window title show the shots so far, the ships left on each side and the same words.

## Settings

The window saves `battleships.choice` (the board size) and its own `window.width`, `window.height`, `window.x`, `window.y` and `window.maximised`, which are shared with the other games. Nothing else needs setting.

## The computer opponent

`HuntTargetOpponent` plays the way a careful person does, and is never told where your ships are. It learns only what each of its shots did.

- **Hunting.** With no unfinished hit it fires at a random cell on one colour of a chessboard pattern. Every ship is at least two cells long, so it must cross that pattern. It prefers cells that still have an unfired neighbour, since a ship needs room.
- **Targeting.** After a hit it fires next to it. After two hits in a line it extends only that line, at its two ends, because ships are straight.
- **Water.** When a ship is sunk, every cell round it is water (ships may not touch), and the opponent never fires at water it knows about.
- Its randomness comes from the `IRandom` it is given, so a seeded one plays the same game every time.

Over 200 seeded games on a Classic board, firing at a fleet it cannot see, it sinks the whole fleet in 44 shots on average (best 29, worst 60 of the 100 cells) and never fires twice at a cell. Tests check the average and the no repeats rule. `IBattleshipsOpponent` is the whole contract (`Reset`, `NextShot`, `Observe`), so another strategy, easier or harder, can be dropped in without changing the game.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Turn based: `BattleshipsGame` implements `ITurnBasedGame` on `AbstractGame`. `Turn` counts your shots. Moves are `PlaceShip`, `RemoveShip`, `Fire` and `ToggleWater` |
| Grid | One grid holds both boards side by side: columns 0 to width - 1 are the computer's waters, one divider column, then yours. The grid is 2 * width + 1 wide. Four layers: `ship` (the ship's number, 0 for water), `shot` (0 none, 1 miss, 2 hit), `mark` (1 for water you marked) and `view` (what to draw) |
| Store | `TableStore`, with readable named fields |
| Shapes | Each ship is a `Shape` (a straight line, rotated for vertical) written into the grid with the store's `Stamp` |
| Controller and window | `TurnController` and the generic `GameWindow`. `BattleshipsInput` describes the game to it through `IGameInput` |
| Drawing | `GridView` with a palette and glyphs per value of `view` |
| Randomness | `SeededRandom` through `IRandom` for both fleets and for the opponent |
| Settings | `JsonFileSettings`, read by `run/run-battleships.p` and the window |

Source: `src/ProGriddle/Games/Battleships/`. The composition root is `run/run-battleships.p`.

| Class | Job |
|---|---|
| `BattleshipsGame` | The game and all the rules above. `Configure`, `LoadBoards` (both fleets from text, for tests), placing, firing, marking, and readers for every layer |
| `BattleshipsInput` | The `IGameInput`: clicks mean different things on each board, the board size picker, the commands, the status line, notices and the rules text |
| `BattleshipsFleets` | The standard board sizes and the fleet each one carries |
| `IBattleshipsOpponent` and `HuntTargetOpponent` | The computer's side |
| `BattleshipsLook` | The colour, glyph and glyph colour for each `view` code |
| `BattleshipsFactory` | Builds the grid and the game |
| `ViewCode` (an enum) | The meaning of each `view` value |

### What the framework had to learn

- **Two boards in one grid.** A game owns one `Grid`, so the two boards are two regions of it. That keeps the window, the renderer and the hit testing unchanged: a click arrives as a grid cell and `BattleshipsInput` works out which board it is on. The alternative, a window that shows two grids, was not needed.
- **Feedback for a refused click.** `IGameInput:CommandNotice` became `TakeNotice()`, called after every click, key and command, so the window can show "Ships may not touch, not even at a corner" over the board, not only the result of a command.
- **Everything else was already there:** the turn based controller, the glyph drawing, the info screen (here the rules), the picker, and the gesture handling from Minesweeper.

## Tests

All under `tests/ProGriddle/Games/Battleships/`.

| Test class | What it proves |
|---|---|
| `BattleshipsGameTests` | Every rule above on fleets set up with `LoadBoards`: legal random fleets on every size and seed, placing and refusing touching ships (side, end, corner), removing, rotating, boards from text and the bad ones refused, firing, sinking, the computer's replies and the lit shot, winning (no reply), losing (the unfound ships shown), marks, the obvious water rules, configuring, and whole games against the real opponent |
| `HuntTargetOpponentTests` | No repeated shots, the chessboard pattern, targeting a lone hit, extending a line, edges, water round a sunk ship, determinism |
| `BattleshipsInputTests` | Which board a click is on, the notices for each refusal, the status line in every state, the commands, the picker |
| `BattleshipsFleetsTests` | The sizes and fleets, no ship under two cells, every fleet under a fifth of its board |
| `BattleshipsLookTests`, `BattleshipsFactoryTests` | The look lists line up with the view codes, what the factory builds |
| `ScriptedOpponent` | A test double that fires the shots it is told to, so a test knows exactly what the computer does |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Battleships*"`.

## Checking the window

`tools/gui-smoke-battleships.ps1` launches the real window with a throwaway settings file and a fixed seed, asks `tools/battleships-layout.p` where the computer's ships are, and plays a whole game with the mouse and keys: a refused placement (side and corner), rotating, taking a ship back, Random and Clear, the rules screen blocking the board, a miss, a repeat shot, a hit, a marked cell, the Water command, sinking a ship, winning, F2, the board size picker and the saved settings coming back. It reads state from the window title and from cell colours in screenshots. It sends real keystrokes and mouse clicks to the foreground, so leave the keyboard and mouse alone for the couple of minutes it takes. Screenshots go to `build/screenshots`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/gui-smoke-battleships.ps1
```

### Manual checklist

- [ ] The two boards are easy to tell apart and the divider is clear.
- [ ] Hits, misses, marks and sunk ships are easy to tell apart, and the computer's latest shot is easy to find.
- [ ] The notice is readable over both boards and does not hide the status line.
- [ ] Placing a fleet by hand feels natural, including rotating and taking a ship back.
- [ ] The Huge board is still comfortable at a normal window size.

## Design notes

- The fleet is a table, not a formula, so each size can be tuned on its own. The only rule is that a fleet fills under a fifth of its board, which keeps random placement from ever failing in practice (the game still gives up with an error after 200 tries rather than loop for ever).
- Marking water is a note, not a move, so it never counts as a turn and the computer does not reply to it. A marked cell is protected from a stray click, like a flag in Minesweeper.
- The computer places its fleet when a game starts, and a ship hit or sunk is all it ever tells the opponent. There is no way for the opponent to see your ships.
- The status line and the window title carry the state so that scripts can read it from outside.
- There is no two player mode and no network play. The `IBattleshipsOpponent` seam is where a harder computer, or a remote player, would go.
