# Xevious

A vertical scrolling shooter in the look of the designer's "First Light" (the design file is `docs/design/skylark-art.md`, an original set of ships, enemies, targets and land). You fly the Lark up a land of forests, rivers, roads and lines cut in the ground. The Zapper shoots what is in the air and the Blaster drops a bomb on the sight, a mark a fixed way ahead of you, to hit what is on the ground. Hidden towers and pennants wait under the land, and every fourth stage ends with the Citadel. Real time on a 224 x 288 pixel canvas, played from the keyboard, with 8 bit sound. Playable now.

The rules are a port of the arcade game of the same name (the names of the enemies and targets in the code are the arcade's, the pictures are the designer's own).

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a blue button of its own:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-xevious.p"
```

`tools/launch.p` sets the PROPATH and then runs the named program. Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the waves of enemies. The window is the shape of the picture, up to 3 pixels to a pixel where the screen is big enough, and the view scales the picture to fill it.

The title screen shows the land under a veil, the name, and a roll call of five air enemies and five ground targets with their points (the Anvil's points are a question mark: see below). The fire keys have to be let go and pressed again to start.

### Controls

| Input | What it does |
|---|---|
| Arrow keys, or W A S D | Fly in eight directions (hold the key) |
| Space or Z | The Zapper: shoots the enemies in the air. Hold it to keep firing |
| X or B | The Blaster: drops a bomb on the sight. Hold it to bomb again as soon as the last has gone |
| P, or the Start and Pause button | Pause and carry on. The field is veiled and PAUSED shows |
| R or F2, or the New game button | Back to the title |
| + and - | Faster and slower, in steps of 10 percent of the real speed, and the speed is kept |
| M, or the Sound button | Sound on or off (only when the machine has a sound device) |

Movement and fire are held states, not key presses, so you can fly and fire both weapons at once. When both keys of one axis are down, the last pressed wins.

### The rules

- **The ship** moves 2 pixels a frame in eight directions. It is hit in a 12 x 12 box (a graze is forgiven).
- **The Zapper** has at most 2 shots in the air, a new one every 7 frames, flying 6 pixels a frame. It hits only what is in the air. A shot is a thin core: it hits where it touches.
- **The Blaster** drops one bomb at a time. It lands on the sight (88 pixels above the middle of the ship) after 26 frames and bursts for 14, with a 16 x 16 blast. It hits only the ground, and it lands on the ground it was dropped on (the ground scrolls and the bomb goes with it). The sight turns red when a visible target is under it.
- **Air enemies** (each from its own stage on, flying in waves): Whirl (30), Skate (50), Kite (10, fires as it turns), Glint (1000, a mirror that dives and snaps back), Midge (150, only its body can be hit), Wisp (300, appears near you as a spark, then bursts into a ring of eight bullets), Swift (100, rushes you) and the **Anvil**, which cannot be killed: shots only push it back, and after 40 hits it gives up and pays 1000.
- **Ground targets**: Cairn (10), Dish (20), Burr (100, fires), Bastion (200, fires two ways), Beetle (200, crawls), Henge (300, takes two bombs) and Hive (400, opens and sends up a Wisp). A target stands on a pad and leaves a scorch in the land.
- **Hidden things**: a bomb that lands on a hidden spot finds a **Spire** (2000 points, it shows for 24 frames and bursts) and, in the odd numbered stages, a **Pennant**, which waits where it was found and is an extra ship for the ship that flies over it. Nothing marks the spots, except that the Spire flickers a moment while the sight is over it.
- **Lives**: 3 ships, and another at 20000 points, at 60000 and then every 60000. When a ship is hit it breaks up, the stage goes back to the last checkpoint (every 480 pixels of ground) and the ship comes back protected for 150 frames.
- **Stages**: 16 areas, 120 rows of ground each, in two ground families (green and dry) and five moods of light. Every fourth stage ends with the **Citadel**, a round fortress with four shield plates, which the Zapper cannot hurt and 3 bombs on its core destroy (4000). At the end of a stage a bonus counts up, 30 points for every percent of the ground targets destroyed. After stage 16 it goes round again, with faster bullets and shorter waits.
- **The land** is always the same for a stage: the river and the road wind a column at a time (and cross over a bridge), forests lie in patches that join by their corners, and the land lines (a spiral, a sunwheel and a lark) are cut into open ground.

The status line reads `Score 1250   Hi 3400   Ships 3   Stage 2   Speed 80%`. The best score is kept.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `xevious.hiscore` | The best score (kept by the game) | 0 |
| `xevious.speed` | The speed as a percentage of the real 60 frames a second, 20 to 100 (the + and - keys change it) | 80 |
| `sound.on`, `sound.volume` | Sound on or off, and 0 to 100 | on, 50 |

The window also saves its position as `xevious.window.x` and `y`. Its size is always worked out from the picture. The painter has two switches for a slow machine, `Haze` (the clouds, on) and `Scanlines` (off).

## The look

The pictures, the colours, the tiles, the boxes and the areas are all generated from the designer's file: change `docs/design/skylark-art.md` and run `python tools/gen-xevious-art.py`, never edit `XeviousTint`, `XeviousLook`, `XeviousPicture`, `XeviousArt`, `XeviousTilePicture`, `XeviousTileArt` or `XeviousAreas` by hand. The collision boxes of the enemies and targets are the boxes in the design (`XeviousBoxes`).

The picture is drawn by `XeviousPainter`:

- The ground is in the background layer of the canvas, built once for an area and then scrolled down a row at a time, so a frame costs one block copy. Scorches are laid into that background where a target stood.
- Shadows fall down and to the right (a tint of Ink under everything in the air), haze drifts above the land, and ground bursts throw a warm light on the land under them, all from the light of the upper left.
- Every effect is a function of the game's own frame counts, so a test sees the same picture for the same game.
- `tools/preview-xevious.p` draws a scenario (title, area, play, boss, bonus, dying, over) into a BMP with no window.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Real time: `XeviousGame` implements `IRealTimeGame` on `AbstractGame`, frame by frame (`Advance`) |
| Rules | `XeviousRules` (every number), `XeviousMotion` (how the enemies fly, as functions of their age), `XeviousMap` (the land, as functions of the stage and the row) |
| Picture | `XeviousPainter` on a pixel canvas (`PixelCanvas`: `ScrollBackDown`, `PutBackRow`, `TintCells`, `DimRect`), with `XeviousSprites` (stamps and tile colours) |
| Input | `XeviousInput` (`IGameInput`, held keys as states) |
| Sound | `XeviousCues` and `XeviousSounds`: Zapper, bomb, kills, hidden finds, the Citadel and a hum that loops while it is out |

Tests drive the game frame by frame with `Advance` and build scenes with `SpawnAir`, `PlaceGround`, `SpawnBoss`, `PlacePlayer`, `StopWaves`, `StopLand` and `BeginStage`.
