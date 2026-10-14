# Space Invaders

The 1978 arcade game with its own rules, in a neon look: 55 invaders that speed up as they die, one shot on the screen at a time, shields that crumble a cell at a time, three kinds of bomb and the mystery saucer. The board is the arcade's own 224 x 256 grid, one cell to a pixel, drawn in direct colour.

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-spaceinvaders.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the sparks, the stars and the marks on the shields. The automated checks use them.

### Controls

| Input | What it does |
|---|---|
| Left or A | Move the cannon left, for as long as the key is held |
| Right or D | Move the cannon right, for as long as the key is held |
| Space, Up, W or Z | Fire. Hold it and the cannon fires again the moment its shot is gone |
| P, or the Pause button | Pause and run |
| R or F2, or the New game button | A new game |
| + or - | Faster or slower, in steps of 10 percent of the arcade's speed (20 to 100). It starts at 70 and the choice is kept |

Moving and firing work at the same time. Both direction keys down: the one pressed last wins. The title screen and the game over screen wait for the fire key, which must be pressed afresh (a key that was already down does not start the game).

### The rules

- 55 invaders in 5 rows of 11. A squid (top row) is worth 30, a crab (rows 2 and 3) 20 and an octopus (rows 4 and 5) 10. The rack moves two cells sideways and drops 8 at each edge. **One invader moves each frame**, as in the arcade, so the rack speeds up as the wave is shot down. If an invader reaches the cannon's row the game is over, whatever lives are left.
- The cannon moves one cell a frame and has **one shot at a time**: it cannot fire again until the shot has hit something or reached the top. The shot moves four cells a frame. A shot that meets a bomb destroys both.
- Three kinds of bomb, at most one of each in the air. The rolling bomb is dropped from the column above the cannon, the plunger and the squiggly one from columns in the arcade's pattern. They fall 1.25 cells a frame. **The reload is a distance and a time**: a new bomb is only dropped once every bomb already falling has come a fair way down, and not sooner than a gap after the last one. Both shorten as the score rises (the reload steps are 48 below 200 points, then 16, 11, 8 and 7 from 3000, each worth 3 frames). So at 100 percent speed a bomb comes about every 2.4 seconds at the start, every 0.8 seconds from 200 points, and every 0.4 seconds from 3000. The squiggly bomb is not dropped while the saucer is out.
- Four shields wear away a mark at a time where a shot or a bomb hits them, and the invaders eat them as they walk through. They are rebuilt for every wave.
- The saucer crosses the top about every 25 seconds (1536 frames), never with fewer than 8 invaders left, and alternates the side it starts from. It is worth 50, 100, 150 or 300 by the arcade's table of shot counts: the 23rd shot is the 300, and every 15th after it.
- Three cannons, and an extra one at 1500 points. The cannon cannot move or fire while a wave is drawn in (one invader a frame, bottom row first), nor while it explodes.
- Each new wave starts the rack lower down the screen (eight steps, then it stays), and the five rows' colours rotate by one each wave.

At 100 percent the game is the arcade's own speed, which is a lot to ask of a first game, so it starts at 70. The speed slows everything together (the invaders, the shot, the bombs and the cannon), so it is the same game, only easier. It is shown in the status line.

The game runs at 60 frames a second at full speed whatever the clock does: it adds up the time it is given and makes a frame for every sixtieth of a second, never more than four at once, so a stall cannot make a burst.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `spaceinvaders.hiscore` | The best score, written as soon as it is beaten | 0 |
| `spaceinvaders.speed` | Percent of the arcade's speed, 20 to 100, changed with + and - | 70 |

The window saves its position (`spaceinvaders.window.x` and `.y`) and whether it was maximised. Its size is not kept: each time it opens it is made the shape of the board (224 x 256 cells), so there is no empty space round the game: 3 pixels to a cell where the screen is tall enough, else 2. A window never opens bigger than the screen's working area.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Real time: `SpaceInvadersGame` implements `IRealTimeGame` on `AbstractGame` |
| Grid | `ArrayStore` 224 x 256 with three layers: `view` (the colour of a cell, 0xRRGGBB), `kind` (what is in it, the `CellKind` enum) and `back` (what shows when nothing is on it) |
| Controller | `RealTimeController` with a `WinFormsClock` ticking as often as Windows allows |
| View | `GridView` in direct colour with the grid lines off |
| Window | The generic `GameWindow`, told about the game through `SpaceInvadersInput` |
| Settings | `JsonFileSettings`, read by `run/run-spaceinvaders.p` and the window |
| Random | An `IRandom` for the sparks, the stars and the marks on the shields, so a seeded game is the same every time |

Source: `src/ProGriddle/Games/SpaceInvaders/`. The composition root is `run/run-spaceinvaders.p`.

| Class | Job |
|---|---|
| `SpaceInvadersGame` | The rules and the phases (title, starting, playing, dying, cleared, game over, in the `GamePhase` enum) |
| `SpaceInvadersInput` | Keys as held states, the speed keys, the status line, the pause banner and the saved best score and speed |
| `SpaceInvadersFactory` | Builds the grid and the game |
| `InvaderRack` | The 55 invaders: where each is, which moves next, the edges, the drops and the speed-up |
| `PixelCanvas` (Engine) | Draws and erases sprites by kind, clips at the edges, writes text with the pixel font (also big gradient text) and restores the picture from the `back` layer |
| `Sprite` (Engine) | A small text picture with up to three tones (`#`, `+`, `*`) |
| `PixelFont` (Engine) | The 5 x 7 capital letter font |
| `InvadersArt` | **Every picture, in one place** (45 of them, as text) |
| `Image` | The name of each of the 45 pictures (an enum) |
| `InvadersLook` | **Every colour, in one place** (79 of them), the row colours by wave (mixing and hex parsing are in `ColourMath`, in Engine) |
| `Palette` | The name of each of the 79 colours (an enum) |
| `GamePhase` | The phases of the game: title, starting, playing, dying, cleared, game over (an enum) |
| `CellKind` | What is in a cell of the `kind` layer: none, shield, alien, bomb, saucer, player, shot, fx (an enum) |

Shots, bombs and invaders hit what the `kind` layer says is in a cell, never what colour it is, so the look can change without touching the rules. To change the art, edit the lists in `InvadersArt` and `InvadersLook`: the sizes (invaders 8, 11 and 12 wide by 8 high, cannon 13 x 8, saucer 16 x 7, shield 22 x 16, bombs 3 x 7) must stay, because the rules use those boxes.

### Framework changes this game needed

- `GridView:DirectColor`: with it on, a cell's value is its 0xRRGGBB colour, and an `ArrayStore` fills with one block copy instead of a palette lookup per cell.
- `GameWindow` keeps the size and position of **each game's own window** (`<game>.window.*`), falling back to the last window to close, so this tall board and a wide one such as Life do not fight over one shape. A window never opens larger than the screen's working area.

## Tests

All under `tests/ProGriddle/Games/SpaceInvaders/`.

| Test class | What it proves |
|---|---|
| `SpaceInvadersGameTests` | The rules, frame by frame, through the kind layer: the phases, the wave drawing in, the cannon and its limits, one shot at a time and re-firing when held, what a shot hits (invaders by kind, a shield, a bomb, the saucer, the top), the bombs and the squiggly rule, the cannon blowing up and coming back, invaders landing, wave clear and a lower rack, the extra cannon, the clock (`Tick`, the four frame cap, pause), the look of the explosion, the blink and the saucer, and the contract errors |
| `SpaceInvadersInputTests` | Held keys, both direction keys, an empty name letting go of every key, the status line for each phase, the banner and the saved best score |
| `SpaceInvadersFactoryTests` | The grid, the title screen and seeded stars |
| `InvaderRackTests` | The rack: order of movement, edges, drops, speed-up |
| `PixelCanvasTests`, `SpriteTests`, `PixelFontTests` (now in `tests/ProGriddle/Engine/`) | Drawing, erasing by kind, clipping, text and the font |
| `InvadersArtTests`, `InvadersLookTests` | The picture sizes the rules rely on, the palette, the row colours by wave |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Invad*"` (and `-Filter "SpaceInvaders*"`).

The window check is `tools/gui-smoke-spaceinvaders.ps1`: it plays a real window (title screen, start, the wave and its colours, held keys steering the cannon, a shot, pause, a new game, the saved window size). It takes over the keyboard for about a minute, so do not touch it while it runs. `tools/look-spaceinvaders.ps1` saves a screenshot of the title screen, with no keys.

## Design notes

- **One invader a frame** is the whole secret of the arcade's feel: the rack is slow with 55 invaders (a pass of 55 frames) and frantic with one (a move every frame). The rack is its own class so this is tested without a screen.
- **Held keys, not key repeats.** The keyboard stops repeating a key while another is down, and the arcade needs moving and firing at once, so `SpaceInvadersInput` keeps the set of keys that are down (key down, key up, and an empty name when the window loses the keyboard) and tells the game each time.
- **The kind layer.** Colours say how a cell looks, kinds say what it is. A shot in flight reads the kind of the cell above it. That is also why text and stars cannot be hit, and why stars are not allowed to paint over text: a star is only put on where plain sky shows, and only taken off where it is showing.
- **The first bomb is aimed.** The rolling bomb comes from the invader above the cannon, so a cannon that stands still on the title-to-play change is hit within about two and a half seconds, as in the arcade.
- **Phases keep the clock running.** The game never reports itself over: the game over screen waits for the fire key and returns to the title, so the stars keep drifting and the controller is never stopped.
- **The look is a separate design.** The art (palette, 45 pictures, screen layouts and effects) came from a design brief (`docs/design/space-invaders-art-brief.md`) and the designer's answer (`docs/design/space-invaders-art.md`, with `preview.png`). It is all built. What it adds to the rules, all cosmetic: the title builds itself letter by letter; a wave builds itself over 130 frames (shields grow from the foot up, the invaders appear in light, WAVE n and a blinking GET READY, the cannon blinks); clearing a wave flashes the ground and sweeps a light along it under WAVE CLEARED; the cannon goes white, explodes in four pictures and comes back blinking; left alone for 8 seconds the title sends an octopus walking along the foot of the screen and then the saucer across the top, with 10 seconds of quiet and round again; a shot has a tail and a white muzzle flash; a shield shimmers where it is bitten; the ground flashes where a bomb lands and pulses red while the rack is low; the saucer's lights chase and its body pulses; a saucer kill turns the score gold and a pop-up climbs and fades; the last invader flickers; bright stars twinkle.
- **Stars and words share colours.** A star is only taken off where it is showing (the cell is empty and its colour is the star's), so the label cyan, the credit and the twinkle white are each a shade away from the colours of the stars: they were once identical, and a star falling through a word ate a stripe out of it.
