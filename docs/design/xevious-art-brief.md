# Xevious: art and screen design brief

Written for: a designer who will produce the look of the game. It is a brief, not a spec: the numbers in "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea. Until the art arrives the game is built with plain placeholder shapes in one place (`XeviousArt`, `XeviousLook`), so the art can be dropped in without touching the rules.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. The next game is a faithful port of the 1982 vertical scrolling shooter **Xevious**: your ship flies up a scrolling land, shoots air enemies with a rapid gun (the Zapper) and bombs ground targets with a bomb that lands on a sight a fixed distance ahead (the Blaster).

The brief for the look is **smart, refined, but retro**. It should feel like the original at a glance, a land of forests, rivers, roads and strange geometric installations seen from above, but drawn the way a modern machine would draw it if it still respected the feel: crisp pixels, a limited and carefully chosen palette, smooth 60 frames a second scrolling, soft light on explosions, subtle parallax, clean type. Not a museum piece and not a glossy remake: a loving restoration. The "Lantern Glass" look of Tetris and Snake is a good sibling to study, but this should have its own palette and mood (a cool dawn over a green and ochre land is one idea; you may have a better one).

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas**: a grid of cells, each cell one flat 24 bit colour, shown scaled up with nearest neighbour edges (no anti-aliasing, no blending: a later draw replaces an earlier one, except where a pass is explicitly a tint).

### The hard limits

- The playfield is **224 columns by 256 rows** of cells (the classic vertical arcade shape), plus a score strip. It is normally shown at 3x and on smaller screens 2x, so **every detail must read at 2x**.
- The ground is a **tile map** of **16 x 16 cell tiles** (14 tiles across, scrolling up; the map is 16 areas long and then loops). Give the ground as a tile set, and say which tiles join to which (forest edges, riverbanks, roads, the lines drawn in the land). Ground tiles may have 2 or 3 frame variants so the land is not repetitive.
- **Sprites** are bitmaps on a **16 x 16** cell grid for ordinary things (ship, small enemies, ground targets, shots) and **32 x 32** for large things (the large installations, the mothership). Each sprite has an alpha mask: a cell is either colour or transparent. Give each sprite as a grid of palette indexes, one row per line, with `.` for transparent.
- The palette per sprite is up to **8 colours plus transparent**, and the whole game uses a master palette of at most **64 colours**, so name colours and reuse them.
- **Budget per frame**: up to about 60 sprites on screen and up to 100 particle cells. The ground layer is redrawn as it scrolls; the cost is fixed.
- Text is made of cells too: a 5 x 7 capital letter font, drawn at 1x, 2x or 3x, in one colour or a vertical gradient.
- Collisions use **boxes** (a width and height in cells for each thing), not the drawn outline. Give the box for each sprite if it is not the whole 16 x 16.
- Effects are functions of the game's own clock, as in Tetris and Snake: they have to be drawable from "frames since it started", not from state kept between frames.

## The rules, so the screens make sense

### The player

- A single ship (the **Solvalou** in the original; give it your own name if you like). It moves in 8 directions across the whole screen and stays facing up.
- **Zapper**: rapid fire at air targets. At most **2 shots** in flight at a time, with a short cool down between them. They travel up the screen and vanish at the top.
- **Blaster**: drops a bomb that lands on the **sight**, a crosshair drawn a fixed distance (about 8 tiles worth, 100 cells) ahead of the ship. Only **one bomb** can be on its way at a time. It takes a moment to land, shows as a small pulsing marker moving to the sight, and bursts with a small blast that kills ground targets in it. It does **nothing** to air targets. The sight turns red when a ground target is under it.
- A bomb lands where the sight was when it was dropped, so the sight must be easy to read over every kind of ground.
- Three lives. Extra lives at 20000 and 60000 points and then every 60000. Collecting a hidden **Special Flag** gives an extra life at once.
- When you die the area is restarted from a checkpoint a little way back, and you come back after a moment of protected blinking.

### Air targets (hit by the Zapper only)

| Name | What it does | Points |
|---|---|---|
| Toroid | A spinning ring that flies in a wave pattern from the top, in groups of 4 to 8. The first thing you meet. | 30 |
| Torkan | A flat disc that dives in and out, comes in groups. | 50 |
| Giddo Spario | A flipping diamond that fires a bullet as it turns. | 10 |
| Kapi | A mirror that flips and reflects, then dives. | 1000 |
| Jara | A small circle that wiggles down the screen, harder to hit. | 150 |
| Zakato | A glowing orb that teleports in near you and bursts into a ring of bullets. | 300 |
| Terrazi | Fast darts that rush the ship in formation. | 100 |
| Bacura | An **indestructible** spinning plate. Shots bounce off it, and bombs do nothing to it, so it can only be avoided. A rare trick scores it: 1000 points if it is hit with enough shots in a row. | 0 or 1000 |

### Ground targets (hit by the Blaster only)

| Name | What it is | Points |
|---|---|---|
| Barra | A pyramid, the basic ground target. | 10 |
| Zolbak | A radar dome, found beside the road. | 20 |
| Logram | A ball turret that fires when you are close. | 100 |
| Derota | A larger turret that fires more often. | 200 |
| Grobda | A small tank that crawls along the ground. | 200 |
| Garu Barra | A large pyramid with a hole in it, tougher. | 300 |
| Garu Zakato | A ground launcher that sends up Zakato. | 400 |
| Sol | A **hidden tower**. It is invisible. Bomb the exact spot and the Sol appears and is destroyed. It gives 2000 points. It is revealed when the sight is directly over it, as a quick flicker. | 2000 |
| Special Flag | A hidden flag, found by bombing a hidden spot. Gives an extra life. | 1 life |
| Andor Genesis | The mothership, the boss of some areas: a large 32 x 32 core with four shield pieces round it, bomb the core. | 4000 |

All point values are starting figures and live in one place (`XeviousRules`), so they are easy to correct.

### Flow of a game

- 16 **areas**, each a long stretch of land of its own look and its own enemy mix. Each area starts with a short marker and the area number. After area 16 the game loops from area 1 with harder numbers.
- The score, the hi-score, lives and the area number are shown in the strip (top for the score, the bottom for lives).
- A final **score bonus** appears at the end of each area: a "BONUS" line and a count up for the percentage of ground targets destroyed (the original tracked this, and it is the heart of the scoring).

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look. A master palette of at most 64 named colours as a table (name, hex), grouped by use: land, water, forest, road, ground targets, the player's ship, enemies, bullets, explosions, text and strip. Colours must still read when twenty things are on the screen at once. Say which are shared on purpose (for example every enemy bullet is the same hot colour so the player always knows what hurts).

### 2. The ground tile set
A set of 16 x 16 tiles with their names and the joins between them: open ground (3 variants), forest (centre, edges and corners), river (straight, bends, banks), road (straight, crossings), the lines and shapes drawn in the land (a few large 32 x 32 designs), and the sea or void at the edge of the map if any. Say how the 16 areas differ in look (a table: area number, ground colour theme, the mood).

### 3. Sprites (palette index grids)

| Shape | Notes |
|---|---|
| Player ship | 16 x 16, facing up. A banking frame to the left and to the right (3 frames). A thruster flame of 2 frames. |
| Zapper shot | One or two cells, bright. |
| Bomb | 3 frames of a small pulsing marker, and a shadow while on its way. |
| Sight | A crosshair, 2 states: normal and over a ground target (red). Drawn in a single colour, over any ground. |
| Toroid | A ring that spins: 4 frames. |
| Torkan, Giddo Spario, Kapi, Jara, Zakato, Terrazi | One frame set each, 2 to 4 frames. Say how many cells each is and its box. |
| Bacura | A plate that turns: 6 frames. |
| Enemy bullet | A small bright dot, 2 frames, always the same hot colour. |
| Ground targets | One sprite each (see the table above), plus a **destroyed** version (scorch) that stays on the ground for a while. |
| Sol | The hidden tower: the revealed frame, and the flicker. |
| Special Flag | 2 frames of waving. |
| Andor Genesis | 32 x 32 core, four shield pieces and the way they break off. |
| Explosions | Air explosion (5 frames), ground burst (6 frames, larger), ship breaking up (the ship in 3 to 5 pieces drifting and fading over about 1.5 seconds). |
| Area marker | The text and effect used between areas. |

### 4. Screens
The title screen (with the logo drawn from cells), the area start, the bonus screen at the end of an area, the game over screen, the pause. Say where the score and the lives live and what the type looks like.

### 5. Motion and finish (the "modern" part)
This is where the modern machine shows. Say what you want, and what it costs in cells or particles:
- A slow parallax layer of cloud or haze above the ground.
- A soft light on explosions that brightens the land under it for a few frames.
- A gentle bloom on bullets and the sight.
- A shadow under the ship and the air enemies, on the ground, offset a few cells.
- Scanline or phosphor softness, if any, as an optional pass that can be switched off.

### 6. What you can leave to us
The scrolling, the collision boxes, the timing of waves and the sound are done in code. You only describe how it looks.

## Where the art goes

- Sprites: `src/ProGriddle/Games/Xevious/XeviousArt.cls` (one place, sizes must stay).
- Colours: `XeviousLook.cls` and the `XeviousTint` enum.
- Ground tiles: `XeviousTiles.cls`.
- When the designer's file is ready, a generator script (like `tools/gen-foreach-art.py`) will write these classes from `docs/design/xevious-art.md`. They are generated, so change the design file and run the script, never edit the classes by hand.
