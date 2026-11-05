# Centipede

A fixed shooter in neon, modelled on the 1981 arcade classic: a centipede crawls down a field of mushrooms towards your shooter, and every shot that hits a segment leaves a new mushroom behind it. A flea, a spider and a scorpion make it worse. Real time on a 240 x 256 pixel canvas, played from the keyboard, with 8 bit sound. Playable now. (The look and the rules follow the arcade closely and are not yet de-branded: the name, the mushrooms and the creatures are placeholders for the game's own names.)

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a green button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-centipede.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the mushrooms and the creatures. The window is the shape of the picture, up to 3 pixels to a pixel where the screen is big enough, and the view scales the picture to fill it.

The title screen shows a centipede crawling under the name and waits for the fire key. The fire key has to be let go and pressed again to start, so a key held down from the last game does not skip the screens.

### Controls

| Input | What it does |
|---|---|
| Arrow keys, or W A S D | Move the shooter, across and up and down, but only in the bottom six rows (hold the key) |
| Space, Z or X | Fire. Hold it to fire again the moment the shot is gone |
| P, or the Start and Pause button | Pause and carry on. The board dims and a PAUSED plate shows |
| R or F2, or the New game button | Back to the title |
| + and - | Faster and slower, in steps of 10 percent of the real speed, and the speed is kept |
| M, or the Sound button | Sound on or off (only when the machine has a sound device) |

Movement and fire are held states, not key presses: the game remembers which keys are down, so the shooter can move and fire together. When both keys of one axis are down, the last pressed wins.

### The rules

- The board is 30 x 30 tiles of 8 pixels, and everything moves a pixel at a time. The shooter is a 6 pixel box that cannot move into a mushroom.
- You have one shot in the air at a time, which flies 8 pixels a frame. It stops at the first thing it hits.
- A mushroom takes four hits (it darkens and loses bites as it goes) and is worth 1 point. A new game starts with 30 of them above the player zone.
- The centipede is 12 segments in wave 1, entering from the top right in row 0. Each segment crawls along its row, and when the next tile is a mushroom or the edge it drops one row and turns round. At the bottom it climbs back up the player zone, to the top of it and down again.
- Shooting a segment scores 10 (a head 100), leaves a mushroom where it was, and makes the segment behind it a head, so a train splits in two.
- From wave 2 the wave is still 12 segments, but one more of them each wave (to 8) is a loose head that comes in from the left of the player zone a few seconds after the body. The segments move 2 pixels a frame, 3 from wave 4.
- **The flea** falls down a column dropping mushrooms, but only when fewer than 5 mushrooms are left in the player zone. It takes two hits (the first makes it quicker) and is worth 200.
- **The spider** zigzags across the lower rows, eating mushrooms. It pays 900 shot close to your shooter, 600 a little way off and 300 far off.
- **The scorpion** (from wave 2) crosses the upper rows poisoning every mushroom it passes (they turn cyan) and is worth 1000. A segment that touches a poisoned mushroom dives straight to the bottom instead of dropping a row. The scorpion cannot hurt you.
- The centipede, the flea and the spider kill the shooter by touching it. After a shooter dies the field is mended (5 points for each mushroom made whole), the creatures leave and the wave starts again with a full centipede.
- You have 3 shooters, and get another at every 12000 points. Clearing a wave shows WAVE n CLEARED and starts the next one.

The status line reads `Score 1250   Hi 3400   Lives 3   Wave 2   Speed 70%`. The best score is kept.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `centipede.hiscore` | The best score (kept by the game) | 0 |
| `centipede.speed` | The speed as a percentage of the real 60 frames a second, 20 to 100 (the + and - keys change it) | 70 |
| `sound.on`, `sound.volume` | Sound on or off, and 0 to 100 | on, 50 |

The window also saves its position as `centipede.window.x` and `y`. Its size is always worked out from the picture.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Real time: `CentipedeGame` implements `IRealTimeGame` on `AbstractGame`, and runs frame by frame (`Advance`) |
| Grid | Two layers on an `ArrayStore`: `mushroom` (hit points, 0 for none) and `poison` |
| Picture | `CentipedePainter` draws on a `PixelCanvas` and hands it to `WinFormsGridRenderer` in direct colour, scaled by `GridView:FitToWindow` |
| Controller | `RealTimeController` with a `WinFormsClock` (a 15 ms tick: the game makes its own 60 frames a second out of the time it is given) |
| Window | The generic `GameWindow`, told about the game through `CentipedeInput` |
| Sound | `CentipedeSounds` (recipes), `CentipedeCues` (what is new: it compares the game's counters, and says which loops should sound), `SoundRenderer`, `WaveOutPlayer` |
| Settings | `JsonFileSettings`, read by `run/run-centipede.p` and the input |

Source: `src/ProGriddle/Games/Centipede/`. The composition root is `run/run-centipede.p`.

| Class | Job |
|---|---|
| `CentipedeGame` | The rules, frame by frame, in pixels. Counters that only go up, and `Frames` and `PhaseFrames` for the painter |
| `CentipedeRules` | Every number: the board, the speeds, the points |
| `CentipedeInput` | The held keys, the speed and best score in the settings, the sound command |
| `CentipedePainter` | The picture. The mushrooms are baked into the background and redrawn only when `FieldVersion` changes |
| `CentipedeLook`, `CentipedeTint` | The colours, by name |
| `CentipedeCues`, `CentipedeCue`, `CentipedeSounds` | The sounds |
| `CentipedeFactory`, `GamePhase` | The grid and the game, and the phases (title, playing, dying, cleared, game over) |

## Tests

All under `tests/ProGriddle/Games/Centipede/`.

| Test class | What it proves |
|---|---|
| `CentipedeGameTests` | The shooter, the shot, the segments (turning, diving, climbing, splitting), the waves, losing a shooter, the score and the three creatures, with scenes built by hand |
| `CentipedePainterTests` | The picture by pixel: the mushrooms and their damage, the segments, the creatures, the strip and every screen |
| `CentipedeCuesTests`, `CentipedeSoundsTests` | Each event reported once, head and body told apart, the loops, and every recipe making sound |
| `CentipedeInputTests` | The held keys, the speed and best score, the sound command |
| `CentipedeRulesTests`, `CentipedeLookTests`, `CentipedeFactoryTests` | The numbers, the colours and the grid |

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Centipede*"`.

## Design notes

- **Frames, not milliseconds.** The game is built on a frame that is a sixtieth of a second. `Tick` turns time into frames (at most six at a time, so a dragged window never makes the game lurch) and `SpeedPercent` scales it, so a slower game is the same game. Tests call `Advance`, one frame, and need no clock.
- **Pixels, not tiles.** Segments move a pixel at a time and decide what to do only when they are exactly on a tile boundary. That keeps a train in step with itself without the segments knowing about each other: every segment follows the same rules over the same field, so they all take the same path, and shooting one out of the middle splits the train because the segment behind now meets the new mushroom a moment earlier than the others.
- **The shot moves a pixel at a time** inside its 8 pixel frame, so it cannot skip over a segment or a mushroom.
- **Counters, not events.** The game never says "a segment was shot": `SegmentsKilled` goes up. The cue source compares counters with the ones it last saw, so two events in one frame are still two.
- **A wave is always 12 segments**, so the loose heads of later waves replace body segments rather than adding to them. The most loose heads is 8, so a body is never shorter than 4.
- **Public set up methods** (`PlaceMushroom`, `AddSegment`, `SpawnFlea`, `SpawnSpider`, `SpawnScorpion`, `PlacePlayer`, `AddScore`) build a scene without playing for it, so the tests (and a future demo screen) can set up exactly the position they want.
