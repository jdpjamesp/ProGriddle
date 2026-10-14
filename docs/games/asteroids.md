# Asteroids

Status: started from the ProGriddle game template. Replace this page as the game takes shape: the sections below are the ones every game page has.

Fly, thrust and drift, and shoot the rocks into smaller rocks while saucers hunt you.

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-asteroids.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`) and a number of seconds after which the window closes by itself, which the automated checks use.

### Controls

| Input | What it does |
|---|---|
| Space or P, or the Start button | Start, or pause when running |
| S or Right arrow, or the Step button | One generation |
| R or F2, or the Reset button | Back to the start |
| + or Up arrow, - or Down arrow | Faster, slower (six speeds) |

Add the game's own keys, clicks and buttons here.

### The rules

Describe the rules here. The template game has one: a single lit cell moves along the board a cell at a time, row by row, and starts again at the top left when it reaches the end.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `asteroids.width`, `asteroids.height` | Board size in cells, 5 to 200 | 30, 20 |

The window also saves `window.width`, `window.height`, `window.x`, `window.y`, `window.maximised` and `asteroids.speed` by itself.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Steppable: `AsteroidsGame` implements `ISteppableGame` on `AbstractGame` |
| Grid | One layer called `state`, on an `ArrayStore`, bounded |
| Controller | `GameController` with a `WinFormsClock` |
| Window | The generic `GameWindow`, told about the game through `AsteroidsInput` |
| Settings | `JsonFileSettings`, read by `run/run-asteroids.p` and the window |

Source: `src/ProGriddle/Games/Asteroids/`. The composition root is `run/run-asteroids.p`.

| Class | Job |
|---|---|
| `AsteroidsGame` | The game and its rules |
| `AsteroidsInput` | What the window needs: the status line, and anything the game adds (picker, commands, clicks, keys) |

## Tests

All under `tests/ProGriddle/Games/Asteroids/`.

| Test class | What it proves |
|---|---|
| `AsteroidsGameTests` | The rules |
| `AsteroidsInputTests` | The status line and the members the game leaves empty |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Asteroids*"`.

## Design notes

Write down what is not obvious from the code: why a rule is the way it is, what was tried and dropped.
