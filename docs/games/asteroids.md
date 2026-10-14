# Asteroids

Fly, thrust and drift, and shoot the rocks into smaller rocks while saucers hunt you. The ship turns and thrusts with a little drag on a screen that wraps on all four edges, a wave starts with four large rocks and gets more crowded, and every break up, burst and spark has its own small effect. The board is 320 x 240 cells, one cell to a pixel, drawn in the glowing line look of the designer's "Obsidian Line" brief.

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-asteroids.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself (for scripted checks), and a seed for the rocks, the saucers and the dust (for scripted checks).

### Controls

| Input | What it does |
|---|---|
| Left or A | Turn the ship left, for as long as the key is held |
| Right or D | Turn the ship right, for as long as the key is held |
| Up or W | Thrust, for as long as the key is held |
| Space or Z | Fire. Hold it to keep firing (four shots in the air at most, one every eight frames) |
| Down or S | Hyperspace: jump to a random place, with a small chance of blowing up |
| P | Pause and run. Pausing shows the picture dimmed with PAUSED over it |
| R or F2 | A new game |
| + or - | Faster or slower, in steps of 10 percent of the real speed (20 to 100). It starts at 80 and the choice is kept |

Turning, thrust and fire work at the same time. Both turn keys down: the one pressed last wins. The title screen and the game over screen wait for the fire key, which must be pressed afresh (a key that was already down does not start the game).

### The rules

- The ship turns three headings in four frames (a full circle in about 1.4 seconds out of 64 headings), thrusts, and slows a little all the time. It has a top speed, and the screen wraps on every edge. A bar flashes on both edges where it crosses one.
- Up to four shots in the air, fired from the nose, each fading after about three quarters of the screen. A shot also carries half of the ship's own speed.
- A wave starts with **4 large rocks and 2 more each wave, up to 11**, after half a second. A shot splits a large rock into two medium ones, a medium into two small ones, and a small one just bursts: 20, 50 and 100 points. The two pieces get the old rock's speed and a push in opposite directions.
- A rock that touches the ship breaks it. The new ship comes only when the middle of the screen is clear (no rock within 30 cells, counting the rock's own size), and a dim dashed ring shows why it is not there yet. It then blinks inside a shield ring for a second and a half. **Three ships**, and an extra one at every 10000 points (the new icon flashes, and the score turns gold).
- When the last rock goes, the next wave comes after a second.
- **Saucers.** About 20 seconds into a wave, and then every 15 to 30 seconds, a saucer crosses the screen at a random height, and a chevron blinks at the edge it will enter by for the 60 frames before. The large saucer (200 points) fires in any direction. The small one (1000 points, only from 3000 points up, and more often as the score grows) aims at the ship, less wildly as the score grows (an error of 6 headings at 3000 points, none at 30000). A saucer and its shots break the ship; a saucer that flies into the ship, or into a rock, is destroyed. The points of a saucer rise from where it was for 48 frames.
- **Hyperspace.** The ship stretches away (12 frames), is gone for 30 and comes back at a random place at rest (12 frames) with no shield. The chance of a failure is 6 percent plus half a percent for every rock on the screen: a failed jump breaks the ship where it comes back, with an extra ring of sparks.
- **Game over** shows the score (and NEW HI-SCORE if the record fell) over the drifting rocks, and PRESS SPACE after 90 frames.

The title screen traces ASTEROIDS with a beam, letter by letter, then draws the rule under it, types the subtitle in, fades the key hints in and blinks PRESS SPACE, over six dim rocks. A large saucer crosses behind it every 14 seconds and fires nothing.

The game runs at 60 frames a second at full speed whatever the clock does: it adds up the time it is given and makes a frame for every sixtieth of a second (at the speed chosen), never more than four at once, so a stall cannot make a burst. The speed slows everything together, so it is the same game, only easier. It starts at 80 percent.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `asteroids.hiscore` | The best score, written as soon as it is beaten | 0 |
| `asteroids.speed` | Percent of the real speed, 20 to 100, changed with + and - | 80 |

The window saves its position (`asteroids.window.x` and `.y`) and whether it was maximised. Its size is not kept: each time it opens it is made the shape of the board (320 x 240 cells), so there is no empty space round the game: 3 pixels to a cell where the screen is tall enough, else 2.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Real time: `AsteroidsGame` implements `IRealTimeGame` on `AbstractGame` |
| Grid | `ArrayStore` 320 x 240 with three layers: `view` (the colour of a cell, 0xRRGGBB), `kind` and `back` (what shows when nothing is on it, with the vignette and the still dust baked in) |
| Controller | `RealTimeController` with a `WinFormsClock` ticking every 15 ms |
| View | `GridView` in direct colour with the grid lines off |
| Window | The generic `GameWindow`, told about the game through `AsteroidsInput` |
| Settings | `JsonFileSettings`, read by `run/run-asteroids.p` and the window |
| Random | An `IRandom` for the rocks, the saucers, the dust and the debris, so a seeded game is the same every time |

Source: `src/ProGriddle/Games/Asteroids/`. The composition root is `run/run-asteroids.p`.

| Class | Job |
|---|---|
| `AsteroidsGame` | The rules, the phases (title, playing, game over, in the `GamePhase` enum) and the drawing of a frame |
| `AsteroidsInput` | Keys as held states, the speed keys, the status line and the saved best score and speed |
| `AsteroidsFactory` | Builds the grid and the game |
| `RockField` | The rocks: 64 slots with position, velocity, size, spin and the flash of a new rock |
| `DebrisPool` | 48 pieces of debris, single cells and spinning line chips, and the recipes for the ship, rock and saucer break ups, rings, the muzzle spark and the exhaust |
| `TitleTrace` | The title word, traced stroke by stroke by a beam |
| `AsteroidsArt` | **Every shape** (ship, flame, 3 sizes of rock in variants, saucers, the title letters), as outlines |
| `AsteroidsLook` | **Every colour** (the Obsidian Line palette) and the ramps that fade in steps |
| `Palette`, `Ramp`, `ShipMode`, `GamePhase` | The names of the colours, of the colour ramps, of what the ship is doing and of the phases (enums) |
| `PixelCanvas` (Engine) | Restores the picture from the `back` layer, draws lines in a batch (one copy of the board in and out), puts text stamps in, and dims the whole picture |
| `Outline`, `OutlinePen`, `Heading` (Engine) | Shapes made of lines, drawn at one of 64 headings with wrapping at the edges, and the sine table behind them |
| `TextStamp`, `PixelFont` (Engine) | Outlined text drawn once into a block of cells and copied each frame |
| `ColourMath` (Engine) | Hex parsing, mixing and scaling of colours |

Collisions are circles round the ship, rocks, saucers and shots, never the drawn lines, so the look can change without touching the rules. Everything that moves has a position and velocity in 4096ths of a cell, so the maths is whole numbers and a seeded game plays the same every time.

### Framework changes this game needed

- `PixelCanvas` moved to Engine from Space Invaders and gained `DrawLine`, batches (`BeginBatch` and `EndBatch`: lines are drawn into a copy of the board and put back in one block), `PutCells` and `Dim`.
- New Engine classes: `Outline`, `OutlinePen`, `Heading`, `TextStamp` and `Sprite`, and `ColourMath:Scale`.
- `RealTimeController:PauseGame` now redraws once, so a game can show a picture while it is paused (Asteroids dims its picture and shows PAUSED).
- Windows are started with `-l 1024` (the Cookoff launcher and every command here): the code of the framework and a game is more than the default local buffer of a prowin, which would otherwise print warning 5408 as it grows.

## Tests

All under `tests/ProGriddle/Games/Asteroids/` (and `tests/ProGriddle/Engine/` for the Engine classes).

| Test class | What it proves |
|---|---|
| `AsteroidsGameTests` | The rules, frame by frame: turning, thrust, drag, wrapping, shots, the rocks and their splits and points, the ship breaking up and coming back, the shield, the saucers, hyperspace, game over, the HUD, the banners, the title, pause and every effect |
| `AsteroidsInputTests` | Held keys, both turn keys, an empty name letting go of every key, the status line for each phase and the saved best score and speed |
| `RockFieldTests` | The rock slots and their movement |
| `DebrisPoolTests` | Cells and chips moving, slowing, spinning, wrapping, fading through a ramp and going; the pool refusing more when full; every recipe |
| `TitleTraceTests` | The beam drawing the title letter by letter |
| `AsteroidsArtTests`, `AsteroidsLookTests` | The sizes and radii the rules rely on, the palette and the ramps |
| Engine: `OutlineTests`, `OutlinePenTests`, `HeadingTests`, `TextStampTests`, `PixelCanvasTests`, `ColourMathTests`, `RealTimeControllerTests` | The classes above |

A test drives the game with `Advance` (one sixtieth of a second, drawn). `AsteroidsGame:Drawing` can be switched off so a test that only cares about the rules runs hundreds of frames without drawing each one, which took the Asteroids tests from 385 seconds to about 100.

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Asteroids*"` (and `-Filter "DebrisPool*"`, `"TitleTrace*"`). The script prints a line every 15 seconds so a long run shows it is alive.

The window check is `tools/gui-smoke-asteroids.ps1`: it plays a real window (the traced title and its rule and hints, starting a game, the ship and the rocks, a held key turning the ship, the flame, a shot, pause with the dimmed picture, a new game, the saved window position). It takes over the keyboard for about a minute, so do not touch it while it runs. `tools/look-asteroids.ps1` saves a screenshot of the title screen to `build/screenshots` and sends no keys.

## Design notes

- **The look is a separate design.** Every shape, colour, screen layout and effect came from a design brief and the designer's answer, `docs/design/asteroids-art.md` ("Obsidian Line"). The art is in `AsteroidsArt` and the colours in `AsteroidsLook`, one place each. Where the design did not fit, this is what the game does instead:
  - The subtitle types in a letter a tick (the design says a letter every two ticks, which does not fit in the 32 ticks it has), and the two key hint lines start 20 ticks apart.
  - The beam head of the title is pure white (Flash), because Title Core and Text White are the same colour in the palette.
  - Rocks and saucers do not draw in white for three frames before they burst: the burst is the same frame as the hit, so the rock splits at once and a shot scores at once (the flash would have delayed both). The ship does flash for three frames.
  - The muzzle spark has its own three step ramp (white and the first two shot trail colours), the ring ramps are the same colours run forwards and backwards (`Spark` and `SparkIn`), and the failed jump ring uses the first three ember colours (`Warm`).
  - Debris lines are drawn at the nearest of 64 headings and to the nearest cell, so a spinning chip steps rather than turns smoothly.
- **Held keys, not key repeats.** The keyboard stops repeating a key while another is down, and this game needs turning, thrust and fire at once, so `AsteroidsInput` keeps the set of keys that are down (key down, key up, and an empty name when the window loses focus) and gives the game the state each time.
- **Frames are the unit of everything.** The game counts frames, not milliseconds, and `Tick` only turns time into frames, so a test steps the game exactly and a stall in the window cannot make a burst (at most four frames a tick, and at most 100 ms counted).
- **Drawing is one batch.** A frame restores the background, plots the moving dust, then draws every line (halos first, so a glow never covers a line) into a copy of the board that goes back in one block, then draws the cells (shots, sparks, text) over them. Outlined text drawn cell by cell took 100 ms a frame, so text is a `TextStamp` made once and copied, and the game keeps the last 96. A whole frame costs about 7 to 9 ms with 44 small rocks and a saucer on the screen.
- **Effects are a luxury.** The debris pool holds 48 pieces and drops the new one when it is full, instead of throwing, so a busy screen loses a spark and never the game. A ship break up is 19 pieces, a large rock 13, a saucer 22 or 23.
- **Pause is drawn once.** `PauseGame` redraws, and the game dims the picture once (every colour times 0.45) and puts PAUSED over it. The next frame after resuming draws a fresh picture, so nothing is undone. A pause before the first frame shows nothing, so the start up pause does not flash.
- **Start slower than the arcade.** Like Space Invaders, the game starts at 80 percent speed with + and - to change it.
