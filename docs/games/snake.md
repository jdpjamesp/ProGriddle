# Snake

The classic: steer a snake round the board, eat the food, grow longer, and do not bite yourself or hit the wall. A real time game on a clock, played from the keyboard. Playable now.

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a green button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-snake.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the food. The automated checks use all three.

The snake sets off to the right as soon as the window opens.

### Controls

| Input | What it does |
|---|---|
| Arrow keys, or W A S D | Turn the snake |
| P or Space, or the Start and Pause button | Pause and carry on |
| R or F2, or the New game button | Start again |

A turn is made at the next step. Two quick presses (up, then left) both count, one on each of the next two steps, which is what makes tight turns possible. A key that would send the snake straight back on itself, or that points the way it is already going, is ignored.

### The rules

- The snake moves one cell at a time in the way it is facing. The walls are deadly, and so is its own body.
- Eating the food makes the snake one cell longer and scores 10. A new piece of food appears in a random empty cell.
- It starts at 150 milliseconds a step, and every piece of food takes 5 off, down to 60 at level 19, where it stops getting faster. The status line shows the level.
- The head may move into the cell the tail is just leaving, so a snake can chase its own tail round a ring.
- Filling the whole board wins the game (YOU WIN). Crashing ends it (GAME OVER).
- A pause, a long stall or a dragged window never makes the snake lurch: the game counts at most half a second of time in one go.

The status line (and the window title) reads `Score 30   Length 6   Level 4   Best 120`, and at the end `Game over   Score 30   Length 6   Best 120   New best score` when the game beat the best.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `snake.width`, `snake.height` | Board size in cells, 5 to 40 (read when the game starts) | 20, 20 |
| `snake.best` | The best score, kept by the game: it is updated when a game ends with a better one | 0 |

The window also saves `window.width`, `window.height`, `window.x`, `window.y` and `window.maximised` by itself. The best score is one number for every board size.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Real time: `SnakeGame` implements `IRealTimeGame` on `AbstractGame`, like Tetris |
| Grid | One layer called `view` on an `ArrayStore`, bounded: 0 empty, 1 body, 2 head, 3 food |
| Controller | `RealTimeController` with a `WinFormsClock` ticking every 20 ms. Each tick passes the real elapsed time to the game's `Tick`, and the controller redraws only when a step was made |
| Window | The generic `GameWindow`, told about the game through `SnakeInput` (the arrow keys come in through `HandleKey`) |
| Look | `SnakeLook`: a four colour palette, with a lighter head so the way it is facing shows |
| Randomness | An injected `IRandom` places every piece of food, so a seeded one gives the same game every time |
| Settings | `JsonFileSettings`, read by `run/run-snake.p` and by `SnakeInput` |

Source: `src/ProGriddle/Games/Snake/`. The composition root is `run/run-snake.p`.

| Class | Job |
|---|---|
| `SnakeGame` | The rules: steps, turns, food, speed, crashing and winning |
| `SnakeInput` | What the window needs: the keys, the status line, the banner and the best score |
| `SnakeFactory` | Builds the grid (an `ArrayStore` of one layer) and a game on it |
| `SnakeLook` | The palette and the text symbols the tests use |
| `ViewCodes.i` | The numbers the `view` layer holds |

## Tests

All under `tests/ProGriddle/Games/Snake/`.

| Test class | What it proves |
|---|---|
| `SnakeGameTests` | Time and steps, the stall cap, turning (the queue, reversing, repeats), eating and growing, where food may go, speed, crashing into each wall and into the body, chasing the tail, winning, `StartWith`, the contract errors |
| `SnakeInputTests` | The keys, the status line, the banner, the best score and the members the game leaves empty |

`ScriptedRandom` (in `tests/ProGriddle/Core`, shared with 2048) returns the numbers it is given, so a test chooses exactly where the food goes. Run the tests with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Snake*"`. The window is checked by `tools/gui-smoke-snake.ps1`, which takes over the keyboard for a minute or two.

## Design notes

- **A ring of cell indexes.** The snake is kept as a ring buffer of cells, tail to head, made once. A step writes the new head, clears the tail cell and moves two counters, so it does no allocation and does not search the board. The `view` layer is kept in step and is what the collision test reads.
- **Time, not frames.** `Tick` adds up the real milliseconds it is given and makes a step each time the step length has gone by, so the speed does not depend on how often the clock fires, and the tests drive the game with plain numbers.
- **Two turns can wait.** A single stored turn drops the second key of a quick pair, and an unbounded queue lets a burst of keys steer the snake long after the player stopped. Two is the usual compromise. A turn is checked against the turn before it, not the way the snake is facing now, so up then down is refused even though down is not opposite to the current heading.
- **The random source is asked once per piece of food**, for a number below the count of empty cells, so the food can never land on the snake, and a scripted source can choose the cell.
- **Arrow keys and the window.** Snake and 2048 are the first games played with the arrow keys from the first moment, which showed that Windows treats an arrow as a dialog key and swallows it unless the board says it wants it. `GridView:WantsKey` and the window focusing the board when it opens fixed that for every game.
