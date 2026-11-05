# Moonpatch: art and screen design, "Moonlit Bed"

Designer's answer to the art and de-branding brief for the fixed shooter in `docs/design`. Everything here is meant to be pasted into code with no further decisions. Section 10 lists what I decided and the questions the code will still have to answer.

**Same dance, different dancers.** The screen, the rules and the roles are kept exactly as the brief lists them: a field of obstacles that take four hits, a long segmented creature that crawls along a row, drops a row and turns at an obstacle or an edge, splits where it is shot and leaves an obstacle behind, a shooter held to the bottom six rows, a dropper, a zigzagger and a poisoner, a colour change each wave, a bright and slightly menacing garden at night. Every name, creature, obstacle, shooter, colour, logo and screen is an original design. The roles map across one to one (section 1.2), so the code, its timings and its points do not change.

Previews, all made from the data in this file:

- `moonpatch-preview.png` (3x): wave 1, NEW MOON. A whole Gloam coming down the field, the Wick firing, the Skitterjack in the band, the fireflies and the stars.
- `moonpatch-preview-busy.png` (3x): wave 2, CRESCENT. The Gloam just split in two with the burst that leaves a bulb and the light it throws on the field, a hurt Sower dropping bulbs, a stray head, the Skitterjack just shot close for 900.
- `moonpatch-preview-later.png` (3x): wave 5, FULL MOON. The Moonsnail crossing the upper rows with a trail of blighted bulbs behind it, a Gloam diving straight down with its tell on.
- `moonpatch-preview-title.png` (3x): the title, the logo, the Gloam crossing, the roll call.
- `moonpatch-screens.png` (2x): wave start, wave cleared, the extra Wick, game over, paused and the title a little later.
- `moonpatch-waves.png` (3x): the same corner of the field in all six waves.
- `moonpatch-sequences.png` (5x): the burst that leaves a bulb, a bulb wearing down (plain and blighted), the hit flash, the pop, the repair glint, the Wick breaking up, the muzzle flash, the dive tell.
- `moonpatch-sprites.png` (4x): every sprite in this file.
- `moonpatch-colour-check.png` (2x): two game screens and the swatches that matter, as drawn and through deuteranopia, protanopia and tritanopia.

Every grid and picture is made by one small script (`moonpatch-generator/`, see 9), so the pictures and the text cannot disagree.

## 0. Read this first

- The canvas is **240 x 256**: the **strip** (rows 0 to 15) and the **board**, 30 x 30 tiles of 8 x 8 (rows 16 to 255). Origin top left; one cell of this file is one canvas cell, shown at 3x (2x on small screens) with nearest neighbour scaling, on the direct colour `PixelCanvas`.
- The **player zone** (the band) is board rows 24 to 29, canvas rows 208 to 255.
- **Sprite format**: a grid of letters, one line a row. `.` is transparent. Each letter is a named colour from the legend under the grid (section 2). No sprite uses more than 8 colours.
- **Family letters**: the bulbs and the Gloam are drawn in the colours of the wave. In their grids `L`, `M` and `D` mean the Light, body and Deep colour of a hue family, and the wave says which family (section 4.4). Everything else has fixed colours.
- **Placing**: a sprite is drawn with its top left on its thing's position (the game's X and Y, plus 16 for the strip), as the game's boxes are kept. The exceptions say so: the bursts and the Wick breaking up are centred on the middle of the thing they replace.
- **Facing**: the Gloam and the Moonsnail are drawn facing right. Facing left is the mirror of the grid. The Skitterjack and the Sower are the same both ways.
- **Light**: from the upper left on everything that does not mirror.
- **Time**: every effect is a function of the game's own frame counts (`Frames`, `PhaseFrames`, and the frame a thing happened), at 60 frames a second, as in Tetris and Snake. Section 8 has them all in one table.

## 1. Names and art direction

### 1.1 The idea

**Moonpatch.** A walled vegetable patch at night, under a moon that changes as the waves go by. The ground is a deep blue dark, the rows of the bed are marked by faint dotted rules, and the patch is full of **bulbs**, little glowing onion shaped things that the night creatures have to push their way through. A long, glowing, beaded crawler, the **Gloam**, winds down through the bulbs towards the **Wick**, a small brass lantern that is the last light in the garden. It spits **sparks** upward. Three other pests make the night worse: the **Sower** drops in from above sowing new bulbs, the **Skitterjack** bounces across the band eating them, and the **Moonsnail** creeps along the upper rows and leaves a pale **blight** on every bulb it touches.

**Moonlit Bed (the look).** Saturated jewel colours on a deep blue night, with hard edged pixels and a few, well judged lights. The Wick is the only warm gold thing in the garden. The bulbs and the Gloam share six hue families that swap partners every wave, so the whole screen changes with the moon. Blight is the only pale lilac thing, much lighter than any healthy bulb. Ember red is the eye of everything that can kill the Wick. The modern part is in the light and the depth: a one cell glow round the Wick, the spark and the Gloamhead, a far layer of slow stars and a near layer of fireflies, grass that sways at the foot of the band, a short flare of light on the bulbs round a big kill, a moon in the strip that waxes with the waves.

### 1.2 The names and the roles

| Role in the brief | Name | What it is |
|---|---|---|
| The game | **Moonpatch** | A night in a garden bed |
| The shooter | **the Wick** | A small brass lantern on two feet; its flame flickers |
| The shot | **a spark** | A white hot head with a gold tail |
| The crawler | **the Gloam** | A string of glowing **beads**, each with two pairs of small legs |
| The crawler's head | **the Gloamhead** | A brighter bead with Ember eyes and pincers that open and shut |
| A loose head of later waves | **a stray head** | A Gloamhead on its own |
| The obstacle | **a bulb** | An onion shaped bulb with a pointed tip and roots; four states, eaten from below |
| A poisoned obstacle | **a blighted bulb** | The same bulb gone pale lilac, with dark blight spots |
| The dropper | **the Sower** | A grey winged seed beetle falling head first, a seed under it |
| The zigzagger | **the Skitterjack** | A red, long legged hopper, 16 wide, legs reaching and pulling in turn |
| The poisoner | **the Moonsnail** | A snail with a pale glowing shell; harmless to touch, pale eyes |
| A wave | **a night**, named after a phase of the moon | NEW MOON, CRESCENT, HALF MOON, GIBBOUS, FULL MOON, WANING, then round again |
| A life | **a Wick** | Shown as small lanterns in the strip |

## 2. The palette

**46 distinct colours** (the brief allows 48); some names share a value on purpose and say so.

### Ground, band and strip

| Name | Hex | Used for |
|---|---|---|
| Night | `0A0E22` | the ground of the garden, above the band |
| Rule | `161D3E` | the faint dotted rule under every tile row |
| Band | `121838` | the quieter band of the player zone (rows 24 to 29) |
| Band Rule | `2A3468` | the top edge of the band, the grass silhouettes at its foot |
| Strip | `05071A` | the strip of numbers |
| Strip Rule | `2A3468` | the line under the strip, the plate edges (same value as Band Rule) |
| Mote | `2A3468` | the far layer: slow drifting stars (same value as Band Rule) |
| Firefly | `5E8C52` | the near layer: a few slow fireflies (a pulse is a tint toward Night) |

### Bulbs and stalks

| Name | Hex | Used for |
|---|---|---|
| Stalk | `3E5A44` | the roots of a whole bulb, the seed the Sower carries |

### Jade family

| Name | Hex | Used for |
|---|---|---|
| Jade Light | `9CF0B0` | lit side |
| Jade | `2EB06A` | body |
| Jade Deep | `1C7A50` | shade |

### Coral family

| Name | Hex | Used for |
|---|---|---|
| Coral Light | `FFB09A` | lit side |
| Coral | `F2604A` | body |
| Coral Deep | `A23028` | shade |

### Tide family

| Name | Hex | Used for |
|---|---|---|
| Tide Light | `A8F4F8` | lit side |
| Tide | `1EA4BC` | body |
| Tide Deep | `17788C` | shade |

### Orchid family

| Name | Hex | Used for |
|---|---|---|
| Orchid Light | `FFA8F0` | lit side |
| Orchid | `DA4EC6` | body |
| Orchid Deep | `86247E` | shade |

### Cobalt family

| Name | Hex | Used for |
|---|---|---|
| Cobalt Light | `B4C8FF` | lit side |
| Cobalt | `5A82F4` | body |
| Cobalt Deep | `3044A8` | shade |

### Copper family

| Name | Hex | Used for |
|---|---|---|
| Copper Light | `F2C29A` | lit side |
| Copper | `C47A44` | body |
| Copper Deep | `7C4426` | shade |

### Blight (poison)

| Name | Hex | Used for |
|---|---|---|
| Blight Light | `F6F2FF` | a blighted bulb: the lit side; the Moonsnail shell highlight and eyes |
| Blight | `DCD0F8` | a blighted bulb: the body; the Moonsnail shell |
| Blight Deep | `8E7CC4` | a blighted bulb: the shade and the blight spots; the Moonsnail shell spiral |

### Danger

| Name | Hex | Used for |
|---|---|---|
| Ember | `FF4030` | the eyes of everything that can kill the Wick, and the Sower's eyes; nothing else |

### The Wick (the shooter) and its spark

| Name | Hex | Used for |
|---|---|---|
| Wick Light | `FFF6CC` | the lit glass and the flame tip; also the glow tint |
| Wick | `FFD040` | the lantern frame and the flame |
| Wick Deep | `B8801C` | the base and the shaded frame |
| Spark | `FFFFFF` | the head of the spark, the muzzle flash |
| Spark Tail | `FFE890` | the tail of the spark |

### The pests

| Name | Hex | Used for |
|---|---|---|
| Husk | `8A96BC` | the Sower: the shell |
| Husk Light | `D0DAF4` | the Sower: the lit shell, the beating wings |
| Jack | `D8343E` | the Skitterjack: the shell |
| Jack Light | `FF8A72` | the Skitterjack: the lit shell and the legs |
| Snail Foot | `566A9E` | the Moonsnail: the foot and the eye stalks |

### Bursts

| Name | Hex | Used for |
|---|---|---|
| Flash | `FFFFFF` | the first frames of every burst (same value as Spark) |
| Burst | `FFC060` | the ring of a burst, the flying sparks |
| Smoke | `3E3060` | the last frames of a burst, the Wick's falling pieces |

### Text and screens

| Name | Hex | Used for |
|---|---|---|
| Text | `F2EEE0` | all ordinary text, the moon |
| Text Dim | `8890B8` | labels, second rank text |
| Points | `FFD040` | the points where a thing died, the score (same value as Wick) |
| Moon Top | `F6F2FF` | the logo gradient: the top (same value as Blight Light) |
| Moon Low | `8C9CFF` | the logo gradient: the bottom |
| Plate | `181E4A` | the plate under PAUSED and GAME OVER, the dark side of the moon icon |
| Ink | `03040C` | text outlines, the pause veil (a tint) |

Shared on purpose:

- **Ember** (`FF4030`) is the eye of the Gloamhead and of the Sower, and the Skitterjack is in the same red family (Jack). Red eyes mean it can kill the Wick. The Moonsnail, the one pest that cannot, has pale eyes.
- **Wick** gold is the Wick and the numbers that are worth points to the player (the score, the points where a thing died). No creature or bulb is ever gold or yellow; the nearest family (Copper) is darker and browner (section 9).
- **Blight** lilac is only ever poison: blighted bulbs and the Moonsnail's shell, so the snail wears the colour of what it leaves behind. Every blighted bulb is at least twice as light as a healthy bulb of any wave.
- **Spark** and **Flash** are the same white: the head of the spark and the first frames of every burst.
- **Moon Top** and **Blight Light** are the same palest lilac (the moon and the blight both glow by moonlight). **Band Rule**, **Strip Rule** and **Mote** are the same dim blue.

## 3. The field

### 3.1 Ground, band and rules

- Board rows 0 to 23 (canvas 16 to 207): fill **Night**. Under every tile row, on the tile's last line (canvas row 16 + 8r + 7), a dotted rule: one cell of **Rule** at x = 2, 6, 10, ... (every 4th cell). No rule under row 23.
- The band, board rows 24 to 29 (canvas 208 to 255): fill **Band**. Its top line (canvas 208) is a solid line of **Band Rule**. Under each band row a sparser dotted rule of **Band Rule** at x = 2, 10, 18, ... (every 8th cell).
- These, the bulbs and the grass are baked into the background (as now). The stars and fireflies are drawn each frame over it (8.2).

### 3.2 The bulbs

A bulb is one tile, drawn with its top left on the tile. It loses its lower part first, because the sparks come from below: the roots, then the belly, then all but the tip. The tip and its lit edge are in every state, so a worn bulb still reads as a bulb, and the field reads as rows of the same small shape. The wave's bulb family colours the letters (4.4).

#### bulb_4 (8 x 8)

A bulb with 4 hits left. Drawn in the wave's bulb family.

Legend: `D` family Deep, `L` family Light, `M` family body, `s` Stalk (Blight Deep when blighted).

```
....L...
...LM...
..LLMM..
.LLMMMD.
LLMMMMDD
LMMMMMDD
.MMMMDD.
..sDDs..
```

#### bulb_3 (8 x 8)

A bulb with 3 hits left. Drawn in the wave's bulb family.

Legend: `D` family Deep, `L` family Light, `M` family body.

```
....L...
...LM...
..LLMM..
.LLMMMD.
LLMMMMDD
L.MM.MD.
...M....
........
```

#### bulb_2 (8 x 8)

A bulb with 2 hits left. Drawn in the wave's bulb family.

Legend: `D` family Deep, `L` family Light, `M` family body.

```
....L...
...LM...
..LLMM..
.L.MMMD.
L..M..D.
........
........
........
```

#### bulb_1 (8 x 8)

A bulb with 1 hit left. Drawn in the wave's bulb family.

Legend: `D` family Deep, `L` family Light, `M` family body.

```
....L...
...LM...
..L..M..
...D....
........
........
........
........
```

**Blighted** bulbs are the same four grids in the Blight colours, whatever the wave, with dark spots (`x`) where the spots fall on a filled cell. Blight is much lighter than any healthy bulb and the spots change the shape, so a blighted bulb reads without colour.

#### blight_4 (8 x 8)

A blighted bulb with 4 hits left: Blight colours in every wave, and dark blight spots.

Legend: `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `M` Blight `DCD0F8`, `s` Blight Deep `8E7CC4`, `x` Blight Deep `8E7CC4`.

```
....L...
...LM...
..LLxM..
.LLMMMD.
LLxMMMDD
LMMMMxDD
.MMMMDD.
..sDDs..
```

#### blight_3 (8 x 8)

A blighted bulb with 3 hits left: Blight colours in every wave, and dark blight spots.

Legend: `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `M` Blight `DCD0F8`, `x` Blight Deep `8E7CC4`.

```
....L...
...LM...
..LLxM..
.LLMMMD.
LLxMMMDD
L.MM.xD.
...M....
........
```

#### blight_2 (8 x 8)

A blighted bulb with 2 hits left: Blight colours in every wave, and dark blight spots.

Legend: `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `M` Blight `DCD0F8`, `x` Blight Deep `8E7CC4`.

```
....L...
...LM...
..LLxM..
.L.MMMD.
L..M..D.
........
........
........
```

#### blight_1 (8 x 8)

A blighted bulb with 1 hit left: Blight colours in every wave, and dark blight spots.

Legend: `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `M` Blight `DCD0F8`.

```
....L...
...LM...
..L..M..
...D....
........
........
........
........
```

**A hit**: the bulb that took the hit is drawn for 2 frames with every letter in the family Light colour (Blight Light when blighted), then in its new state.

**The last hit**: the pop, then nothing.

#### bulb_pop_1 (8 x 8)

The last hit, frames 0 to 3: the bulb bursts into seeds. Wave's bulb family.

Legend: `L` family Light, `M` family body.

```
...L....
.L..L.L.
..LMML..
L.MMMM.L
..MMMM..
.L.MM.L.
...L..L.
L.......
```

#### bulb_pop_2 (8 x 8)

The last hit, frames 4 to 7: the seeds scatter. Then nothing.

Legend: `L` family Light, `M` family body.

```
L.....L.
...L....
.L....L.
....M...
..M.....
L.....M.
...L....
.L....L.
```

**A bulb made whole** (after the Wick is lost, see 5.4) shows a glint over it, 3 frames of 4 game frames each. White and Text, so it reads in any wave.

#### glint_1 (8 x 8)

The repair glint, frame 1 (4 game frames each), drawn over a bulb made whole.

Legend: `T` Text `F2EEE0`, `W` Spark `FFFFFF`.

```
........
........
....T...
...TWT..
....T...
........
........
........
```

#### glint_2 (8 x 8)

The repair glint, frame 2 (4 game frames each), drawn over a bulb made whole.

Legend: `T` Text `F2EEE0`, `W` Spark `FFFFFF`.

```
....T...
....T...
....W...
TTWWWWTT
....W...
....T...
....T...
........
```

#### glint_3 (8 x 8)

The repair glint, frame 3 (4 game frames each), drawn over a bulb made whole.

Legend: `T` Text `F2EEE0`, `W` Spark `FFFFFF`.

```
........
...T.T..
....W...
...TWT..
....W...
...T.T..
........
........
```

### 3.3 The bulbs in numbers

150 bulbs on screen is 150 copies of one small shape on a regular grid, which reads as a planted bed and not as noise. The bulbs are baked, so the only per frame cost is the light on the field (8.3), a few bulbs drawn again for 5 frames.

## 4. The Gloam

### 4.1 Beads

Each bead is a lit ball with a highlight in the upper left, and a pair of small legs above and below that step through 4 frames. The beads touch only at the middle, so a train reads as a string of beads and a split is easy to see.

#### bead_1 (8 x 8)

A bead of the Gloam, walking frame 1. Faces right; mirror it for left (the light stays on the top).

Legend: `D` family Deep, `L` family Light, `M` family body.

```
M...M...
..LLLM..
.LLLLMD.
.LLLMMD.
.LLMMMD.
.MMMMDD.
..DDDD..
..D...D.
```

#### bead_2 (8 x 8)

A bead of the Gloam, walking frame 2. Faces right; mirror it for left (the light stays on the top).

Legend: `D` family Deep, `L` family Light, `M` family body.

```
.D...D..
..LLLM..
.LLLLMD.
.LLLMMD.
.LLMMMD.
.MMMMDD.
..DDDD..
.M...M..
```

#### bead_3 (8 x 8)

A bead of the Gloam, walking frame 3. Faces right; mirror it for left (the light stays on the top).

Legend: `D` family Deep, `L` family Light, `M` family body.

```
..M...M.
..LLLM..
.LLLLMD.
.LLLMMD.
.LLMMMD.
.MMMMDD.
..DDDD..
D...D...
```

#### bead_4 (8 x 8)

A bead of the Gloam, walking frame 4. Faces right; mirror it for left (the light stays on the top).

Legend: `D` family Deep, `L` family Light, `M` family body.

```
.D...D..
..LLLM..
.LLLLMD.
.LLLMMD.
.LLMMMD.
.MMMMDD.
..DDDD..
.M...M..
```

### 4.2 The Gloamhead

The head is the dangerous end at a glance, three ways at once: it is mostly the family Light colour (a bead is mostly the body colour), it has two **Ember** eyes set in Ink, and its pincers stick out in front. The pincers open on frames 1 and 2 and shut on frames 3 and 4 of the same walking cycle. A head climbing back up the band is drawn the same as one going down.

#### head_1 (8 x 8)

The Gloamhead, frame 1: brighter than a bead, Ember eyes, pincers that open (frames 1, 2) and shut (3, 4). Faces right; mirror for left.

Legend: `D` family Deep, `L` family Light, `M` family body, `e` Ember `FF4030`, `k` Ink `03040C`.

```
.D....L.
..LLL..L
.LLLLke.
LLLLMMM.
LMMMMMM.
.MMMMke.
..DDD..L
...D..L.
```

#### head_2 (8 x 8)

The Gloamhead, frame 2: brighter than a bead, Ember eyes, pincers that open (frames 1, 2) and shut (3, 4). Faces right; mirror for left.

Legend: `D` family Deep, `L` family Light, `M` family body, `e` Ember `FF4030`, `k` Ink `03040C`.

```
..D...L.
..LLL..L
.LLLLke.
LLLLMMM.
LMMMMMM.
.MMMMke.
..DDD..L
..D...L.
```

#### head_3 (8 x 8)

The Gloamhead, frame 3: brighter than a bead, Ember eyes, pincers that open (frames 1, 2) and shut (3, 4). Faces right; mirror for left.

Legend: `D` family Deep, `L` family Light, `M` family body, `e` Ember `FF4030`, `k` Ink `03040C`.

```
...D....
..LLL.L.
.LLLLkeL
LLLLMMM.
LMMMMMM.
.MMMMkeL
..DDD.L.
.D......
```

#### head_4 (8 x 8)

The Gloamhead, frame 4: brighter than a bead, Ember eyes, pincers that open (frames 1, 2) and shut (3, 4). Faces right; mirror for left.

Legend: `D` family Deep, `L` family Light, `M` family body, `e` Ember `FF4030`, `k` Ink `03040C`.

```
..D.....
..LLL.L.
.LLLLkeL
LLLLMMM.
LMMMMMM.
.MMMMkeL
..DDD.L.
..D.....
```

### 4.3 The dive (it touched a blighted bulb)

#### head_dive (8 x 8)

The Gloamhead diving (it touched a blighted bulb): head_1 turned a quarter clockwise, so it faces down. The beads behind it flicker in Blight (4.5).

Legend: `D` family Deep, `L` family Light, `M` family body, `e` Ember `FF4030`, `k` Ink `03040C`.

```
...LL...
..MMLL.D
.DMMLLL.
DDMMLLL.
.DMMMLL.
..kMMk..
L.eMMe.L
.L....L.
```

While a segment is diving, on frames where `(Frames div 4) mod 2 = 0` its `L` and `M` letters are drawn in **Blight Light** and **Blight** instead of the family colours: the train flickers pale, the colour of what it touched, and that is the tell. The head uses `head_dive` for the whole dive.

### 4.4 The six nights

Wave n uses row ((n - 1) mod 6) + 1. The Gloam takes one family and the bulbs another, so no wave has the Gloam on bulbs of its own colour, and each family takes both jobs in the cycle. The moon in the strip shows the night.

| Wave | Night | The Gloam (L / M / D) | The bulbs (L / M / D) |
|---|---|---|---|
| 1 | NEW MOON | Orchid: `FFA8F0` `DA4EC6` `86247E` | Jade: `9CF0B0` `2EB06A` `1C7A50` |
| 2 | CRESCENT | Coral: `FFB09A` `F2604A` `A23028` | Tide: `A8F4F8` `1EA4BC` `17788C` |
| 3 | HALF MOON | Jade: `9CF0B0` `2EB06A` `1C7A50` | Copper: `F2C29A` `C47A44` `7C4426` |
| 4 | GIBBOUS | Tide: `A8F4F8` `1EA4BC` `17788C` | Orchid: `FFA8F0` `DA4EC6` `86247E` |
| 5 | FULL MOON | Copper: `F2C29A` `C47A44` `7C4426` | Cobalt: `B4C8FF` `5A82F4` `3044A8` |
| 6 | WANING | Cobalt: `B4C8FF` `5A82F4` `3044A8` | Coral: `FFB09A` `F2604A` `A23028` |

The roots of a whole bulb are always **Stalk**. Blighted bulbs are always Blight.

### 4.5 The walk, the ripple and the glow

- Segment i (its place in the game's list, `SegmentX(i)`) uses walking frame `((Frames + 2 * i) div 4) mod 4`, so a train ripples, each bead half a step behind the one before.
- Facing: the grid as drawn when `SegmentDirection(i) > 0`, mirrored when `< 0`.
- **Glow**: a head has a one cell glow, a tint pass of its family Light at 30 percent on the empty cells round its outline (8 neighbours). Beads have none.

### 4.6 A segment shot: the burst that leaves a bulb

The game puts the new bulb in at once, so it is baked under the burst. The burst is centred on the tile (top left at the tile's top left minus 2, 2). Frames 0 to 2 hide the tile in a white flash, frames 3 to 6 open a gold ring with the new bulb inside it, frames 7 to 10 throw the last sparks off the corners. The same burst is used for a head (which also throws the light on the field, 8.3) and for every pest.

#### burst_1 (12 x 12)

A bead or head shot, frames 0 to 2: a white flash that covers the tile (the new bulb is already baked under it).

Legend: `F` Flash `FFFFFF`.

```
............
............
....FFFF....
...FFFFFF...
..FFFFFFFF..
..FFFFFFFF..
..FFFFFFFF..
..FFFFFFFF..
...FFFFFF...
....FFFF....
............
............
```

#### burst_2 (12 x 12)

Frames 3 to 6: a gold ring opens and the new bulb shows inside it.

Legend: `B` Burst `FFC060`.

```
............
...B....B...
....BBBB....
..BB....BB..
..B......B..
.B........B.
.B........B.
..B......B..
..BB....BB..
....BBBB....
...B....B...
............
```

#### burst_3 (12 x 12)

Frames 7 to 10: the last sparks and a little smoke fly off the corners. Then only the bulb.

Legend: `B` Burst `FFC060`, `S` Smoke `3E3060`.

```
B..........B
............
..S......S..
............
............
.S........S.
............
............
..S......S..
............
............
B..........B
```

## 5. The Wick and the spark

### 5.1 The Wick

A small brass lantern on two feet, gold and warm white, the only gold thing on the board. The flame leans one way and then the other every 6 frames. It has a one cell glow: a tint pass of **Wick Light** at 18 percent round its outline.

#### wick_1 (8 x 8)

The Wick, idle frame 1 (the flame leans; 6 game frames each). Box: the inner 6 x 6, from (1, 1).

Legend: `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`.

```
...TT...
...WW...
..dWWd..
.dWTTWd.
.dWTTWd.
.dWWWWd.
dddddddd
.d....d.
```

#### wick_2 (8 x 8)

The Wick, idle frame 2 (the flame leans; 6 game frames each). Box: the inner 6 x 6, from (1, 1).

Legend: `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`.

```
....T...
...WT...
..dWWd..
.dWTTWd.
.dWTWWd.
.dWWWWd.
dddddddd
.d....d.
```

### 5.2 The spark and the muzzle

#### spark (2 x 8)

The spark, 2 x 8: a white head and a tail that fades, so a shot flying 8 cells a frame leaves an unbroken streak. Box: the top row.

Legend: `S` Spark `FFFFFF`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`, `t` Spark Tail `FFE890`.

```
SS
SS
tt
tt
WW
W.
.d
d.
```

The spark is drawn with its top left on `(ShotX, 16 + ShotY)`. Its head and first tail rows have a glow, a tint of **Spark Tail** at 25 percent. It is 2 wide because the game's shot box is 2 wide.

#### muzzle (6 x 3)

The muzzle flash: 2 game frames after a shot leaves, its bottom row on the flame tip (row 0 of the Wick).

Legend: `S` Spark `FFFFFF`.

```
.S..S.
..SS..
S.SS.S
```

The muzzle flash is drawn while the spark is within 16 cells of the Wick's top (its first 2 frames), with its top left at `(PlayerX + 1, 16 + PlayerY - 3)`.

### 5.3 Lives

#### wick_icon (5 x 6)

A Wick in the strip: one for each life in hand.

Legend: `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`.

```
..T..
..W..
.dWd.
dWTWd
dWWWd
ddddd
```

### 5.4 The Wick breaking up, and the field mended

The game spends 100 frames in the dying phase. Frames 0 to 59 are the break up, 6 frames of 10 game frames each, centred on the Wick's centre: a white flash, then the frame and the glass fly apart, fall a little and turn to smoke. Frames 60 to 99 mend the field: every bulb that will be made whole (worn or blighted) gets the glint (3.2), and from the first glint frame on it is drawn as a whole, healthy bulb. Bulb k, counting worn and blighted bulbs in reading order (top row first, left to right), starts its glint at `PhaseFrames = 60 + min(3 * k, 27)`, so the mending runs down the screen like a wave of light.

#### wick_break_1 (16 x 16)

The Wick breaking up, frame 1 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `F` Flash `FFFFFF`, `T` Wick Light `FFF6CC`.

```
................
................
................
.......TT.......
.....TTTTTT.....
....TTFFFFTT....
....TFFFFFFT....
...TTFFFFFFTT...
...TTFFFFFFTT...
....TFFFFFFT....
....TTFFFFTT....
.....TTTTTT.....
.......TT.......
................
................
................
```

#### wick_break_2 (16 x 16)

The Wick breaking up, frame 2 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `B` Burst `FFC060`, `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`, `e` Ember `FF4030`.

```
................
................
................
................
........TT......
.....TT.e.WW....
.....e....e.....
.......BB.......
....dd.BB.......
....e......WW...
......dd...e....
......e..TT.....
.........e......
................
................
................
```

#### wick_break_3 (16 x 16)

The Wick breaking up, frame 3 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `B` Burst `FFC060`, `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`, `k` Smoke `3E3060`.

```
................
........k.......
.....k..TT......
....TT..T.k.....
....T......WW...
...........W....
................
.......BB.......
.......BB.......
...dd.......WW..
...dk......kW...
................
.....dd.........
.....dk...TT....
.........kT.....
................
```

#### wick_break_4 (16 x 16)

The Wick breaking up, frame 4 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `d` Wick Deep `B8801C`, `k` Smoke `3E3060`.

```
........k.......
....k...T.......
...T........k...
.............W..
................
................
................
................
................
................
.d............W.
..k..........k..
................
................
.....d..........
......k....T....
```

#### wick_break_5 (16 x 16)

The Wick breaking up, frame 5 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `T` Wick Light `FFF6CC`, `W` Wick `FFD040`, `k` Smoke `3E3060`.

```
........T.......
...k............
..T..........k..
..............W.
................
................
................
................
................
................
................
................
k...............
...............k
................
................
```

#### wick_break_6 (16 x 16)

The Wick breaking up, frame 6 of 6 (10 game frames each). 16 x 16, centred on the Wick's centre.

Legend: `k` Smoke `3E3060`.

```
.k..............
k...............
..............k.
...............k
................
................
................
................
................
................
................
................
................
................
................
................
```

## 6. The three pests

### 6.1 The Sower (the dropper, 200)

A grey seed beetle falling head first with a seed under it, wings beating every 3 frames. After the first hit its shell goes pale and it flickers white every other 2 frames as it speeds up. The bulbs it sows appear with the glint (3.2) for their first 12 frames, so they look dropped, not just there.

#### sower_1 (8 x 8)

The Sower falling head first, wings frame 1 (3 game frames each). It carries a seed under it. Box: the whole 8 x 8.

Legend: `H` Husk `8A96BC`, `e` Ember `FF4030`, `h` Husk Light `D0DAF4`, `s` Stalk `3E5A44`.

```
h......h
.hHHHHh.
.HhHHHH.
.HhHHHH.
..HHHH..
..eHHe..
...ss...
...ss...
```

#### sower_2 (8 x 8)

The Sower falling head first, wings frame 2 (3 game frames each). It carries a seed under it. Box: the whole 8 x 8.

Legend: `H` Husk `8A96BC`, `e` Ember `FF4030`, `h` Husk Light `D0DAF4`, `s` Stalk `3E5A44`.

```
........
h.HHHH.h
hHhHHHHh
.HhHHHH.
..HHHH..
..eHHe..
...ss...
....s...
```

#### sower_hurt_1 (8 x 8)

The Sower after one hit, frame 1: a paler shell (and on frames where (Frames div 2) mod 2 = 1, draw it all in Flash).

Legend: `H` Husk Light `D0DAF4`, `e` Ember `FF4030`, `h` Text `F2EEE0`, `s` Stalk `3E5A44`.

```
h......h
.hHHHHh.
.HhHHHH.
.HhHHHH.
..HHHH..
..eHHe..
...ss...
...ss...
```

#### sower_hurt_2 (8 x 8)

The Sower after one hit, frame 2: a paler shell (and on frames where (Frames div 2) mod 2 = 1, draw it all in Flash).

Legend: `H` Husk Light `D0DAF4`, `e` Ember `FF4030`, `h` Text `F2EEE0`, `s` Stalk `3E5A44`.

```
........
h.HHHH.h
hHhHHHHh
.HhHHHH.
..HHHH..
..eHHe..
...ss...
....s...
```

### 6.2 The Skitterjack (the zigzagger, 900 / 600 / 300)

The most dangerous pest and the busiest sprite: a red body with white eyes on top and three long legs a side, the two sides reaching out and pulling in by turns over 4 frames. It is the same both ways, so it never flips in mid air. **The turn tell**: when it is within 2 cells of the top or the bottom of its path (the zigzagger's Y at 162 or less, or 230 or more, near the limits of 160 and 232 that the game bounces at), it holds frame 3, both sides pulled in, a crouch before the bounce.

#### skitterjack_1 (16 x 8)

The Skitterjack, frame 1 (4 game frames each; the two sides take turns to reach and pull). 16 x 8, the same both ways. Box: the whole 16 x 8.

Legend: `J` Jack `D8343E`, `T` Jack Light `FF8A72`, `e` Text `F2EEE0`.

```
.T............T.
T.T...JJJJ...T.T
...T.JTTJJJ.T...
.TTTTJTJJJJTTTT.
T....JeJJeJ....T
..TTTJJJJJJTTT..
.T....JJJJ....T.
T..............T
```

#### skitterjack_2 (16 x 8)

The Skitterjack, frame 2 (4 game frames each; the two sides take turns to reach and pull). 16 x 8, the same both ways. Box: the whole 16 x 8.

Legend: `J` Jack `D8343E`, `T` Jack Light `FF8A72`, `e` Text `F2EEE0`.

```
.T..............
T.T...JJJJ...T..
...T.JTTJJJ.T.T.
.TTTTJTJJJJTT..T
T....JeJJeJ.T...
..TTTJJJJJJ..TT.
.T....JJJJ..T..T
T..........T....
```

#### skitterjack_3 (16 x 8)

The Skitterjack, frame 3 (4 game frames each; the two sides take turns to reach and pull). 16 x 8, the same both ways. Box: the whole 16 x 8.

Legend: `J` Jack `D8343E`, `T` Jack Light `FF8A72`, `e` Text `F2EEE0`.

```
................
..T...JJJJ...T..
.T.T.JTTJJJ.T.T.
T..TTJTJJJJTT..T
...T.JeJJeJ.T...
.TT..JJJJJJ..TT.
T..T..JJJJ..T..T
....T......T....
```

#### skitterjack_4 (16 x 8)

The Skitterjack, frame 4 (4 game frames each; the two sides take turns to reach and pull). 16 x 8, the same both ways. Box: the whole 16 x 8.

Legend: `J` Jack `D8343E`, `T` Jack Light `FF8A72`, `e` Text `F2EEE0`.

```
..............T.
..T...JJJJ...T.T
.T.T.JTTJJJ.T...
T..TTJTJJJJTTTT.
...T.JeJJeJ....T
.TT..JJJJJJTTT..
T..T..JJJJ....T.
....T..........T
```

### 6.3 The Moonsnail (the poisoner, 1000)

A snail with a pale Blight shell and a dark blue foot, two eye stalks with pale glowing eyes. It wears the colour of the blight it leaves, it is round and slow, and it has no red: strange, but plainly harmless to touch. Its foot stretches and its shell rides forward every 8 frames. Mirror it when it crawls left (the poisoner's direction below 0).

#### moonsnail_1 (16 x 8)

The Moonsnail crawling right, frame 1 (8 game frames each): the foot stretches and the shell rides forward. Mirror it for left. Pale eyes: it cannot hurt the Wick.

Legend: `B` Blight `DCD0F8`, `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `e` Blight Light `F6F2FF`, `f` Snail Foot `566A9E`.

```
...BBBB.........
..BLLLLB.....e.e
.BLDDDLB.....f.f
.BLDLBDLB....f.f
.BLDDBLB....fff.
..BLLLB.ffffffff
.ffBBBfffffffff.
ffffffffffffff..
```

#### moonsnail_2 (16 x 8)

The Moonsnail crawling right, frame 2 (8 game frames each): the foot stretches and the shell rides forward. Mirror it for left. Pale eyes: it cannot hurt the Wick.

Legend: `B` Blight `DCD0F8`, `D` Blight Deep `8E7CC4`, `L` Blight Light `F6F2FF`, `e` Blight Light `F6F2FF`, `f` Snail Foot `566A9E`.

```
....BBBB........
...BLLLLB.....e.
..BLDDDLB....ef.
..BLDLBDLB...f.f
..BLDDBLB...fff.
...BLLLB.ffffff.
..ffBBBffffffff.
.ffffffffffffff.
```

### 6.4 Points where a thing died

The points of every pest, and of a Gloamhead, appear where it died: the 1x font in **Points** gold with a one cell **Ink** outline, centred on the thing's centre, rising one cell every 8 frames for 30 frames. (The game already gives `LastBonus`, `LastBonusX`, `LastBonusY` and `LastBonusFrame`.)

## 7. The strip and the screens

### 7.1 The strip

Rows 0 to 14 **Strip**, row 15 a line of **Strip Rule**. All text is the 1x font with its top at row 4.

| What | Where (cells) | Colour |
|---|---|---|
| The score | x 4, left aligned | Points |
| `HI` | x 82 | Text Dim |
| The best score | x 96, left aligned | Text |
| The moon of the night | x 160, y 4, 7 x 7 (`moon_n`) | Text, Plate, Text Dim |
| The wave number | x 170 | Text |
| The lives | `wick_icon` at x = 231 - 8k for k = 0 to lives - 2 (the Wick on the board is the last one), up to 5, y 5 | Wick colours |

#### moon_1, NEW MOON (7 x 7)

The moon in the strip for wave 1 (and every sixth wave after it).

Legend: `p` Plate `181E4A`, `r` Text Dim `8890B8`.

```
..rrr..
.rpppr.
rpppppr
rpppppr
rpppppr
.rpppr.
..rrr..
```

#### moon_2, CRESCENT (7 x 7)

The moon in the strip for wave 2 (and every sixth wave after it).

Legend: `T` Text `F2EEE0`, `p` Plate `181E4A`.

```
..ppT..
.ppppT.
pppppTT
pppppTT
pppppTT
.ppppT.
..ppT..
```

#### moon_3, HALF MOON (7 x 7)

The moon in the strip for wave 3 (and every sixth wave after it).

Legend: `T` Text `F2EEE0`, `p` Plate `181E4A`.

```
..ppT..
.pppTT.
ppppTTT
ppppTTT
ppppTTT
.pppTT.
..ppT..
```

#### moon_4, GIBBOUS (7 x 7)

The moon in the strip for wave 4 (and every sixth wave after it).

Legend: `T` Text `F2EEE0`, `p` Plate `181E4A`.

```
..pTT..
.pTTTT.
ppTTTTT
ppTTTTT
ppTTTTT
.pTTTT.
..pTT..
```

#### moon_5, FULL MOON (7 x 7)

The moon in the strip for wave 5 (and every sixth wave after it).

Legend: `T` Text `F2EEE0`.

```
..TTT..
.TTTTT.
TTTTTTT
TTTTTTT
TTTTTTT
.TTTTT.
..TTT..
```

#### moon_6, WANING (7 x 7)

The moon in the strip for wave 6 (and every sixth wave after it).

Legend: `T` Text `F2EEE0`, `p` Plate `181E4A`.

```
..Tpp..
.Tpppp.
TTppppp
TTppppp
TTppppp
.Tpppp.
..Tpp..
```

### 7.2 The title

Over the night ground with its stars and fireflies, a few bulbs, and the strip with the last score and the best:

- **The logo**: `MOONPATCH` in the 3x font, 161 cells wide, centred (x 39), top at row 30, in a vertical gradient from **Moon Top** to **Moon Low** with a one cell **Ink** outline. The two Os are moons, drawn as discs of radius 7.9 (cells whose centre is within 62 of the middle, squared) in the same gradient with a ring of Ink: the first full, the second a crescent (the cells within 44 of a point 4 left and 1 up of the middle, squared, are **Plate**). The full moon has a halo, a tint of Moon Top on the ring from 9.1 to 12.6 cells out, at `0.10 + 0.06 * sin(Frames / 19)`.
- `A NIGHT IN THE GARDEN`, 1x, Text Dim, centred, row 62.
- **The Gloam crosses** under the name, on canvas row 90, twelve segments, one cell a frame from right to left: the head at `x = 250 - (Frames mod 360)`. Each crossing is the next night's colours (the bulbs and the moon in the strip change with it), so the title shows all six in turn.
- **The roll call** from row 120, 14 rows apart: each sprite centred in x 56 to 71, its name at x 80 in Text, its points at x 150 in Points: GLOAMHEAD 100, BEAD 10, SOWER 200, SKITTERJACK 300 600 900, MOONSNAIL 1000, BULB 1.
- `PRESS SPACE`, 2x, Text, centred, row 214, shown while `(Frames div 30) mod 2 = 0`. Under it `MOVE ARROWS  FIRE SPACE`, 1x, Text Dim, row 240.

### 7.3 Wave start, wave cleared

- **Wave start** (the first 90 frames of a night): a soft dark banner (8.4) on canvas rows 90 to 139, `WAVE n` 2x Text centred at row 98, the moon of the night at (116, 118), the name of the night 1x Text Dim centred at row 128.
- **Wave cleared** (the 90 frames of the cleared phase): the banner on rows 90 to 133, `WAVE n CLEARED` 2x Text centred at row 98, and if a bonus is ever given, `BONUS n` 1x Points centred at row 122.

### 7.4 Game over and paused

- The board is veiled: a tint of **Ink** at 55 percent on rows 16 to 255, as now.
- **Game over**: a plate of **Plate** 168 x 64 centred at row 128, edged with one cell of Strip Rule. `GAME OVER` 2x in the logo gradient at plate top + 9, `SCORE n` 1x Text at + 32, and when the best was beaten `NEW BEST` 1x Points at + 46.
- **Paused**: a plate 120 x 32 centred at row 128, `PAUSED` 2x Text at plate top + 9.

### 7.5 An extra Wick

For 60 frames the new lantern in the strip is drawn all in **Spark** white on frames where `(age div 4) mod 2 = 0`, and for 90 frames `EXTRA WICK` in 1x Points is centred at row 20 over a banner on rows 16 to 31.

## 8. Motion and finish (the modern part)

### 8.1 Every timing in one place

| Thing | Rule | Reads |
|---|---|---|
| Bead and head walk | frame `((Frames + 2 * i) div 4) mod 4` | Frames, segment index |
| Dive tell | Blight on `(Frames div 4) mod 2 = 0`, head uses head_dive | Frames, a diving flag per segment |
| Wick flame | frame `(Frames div 6) mod 2` | Frames |
| Muzzle flash | while the spark is within 16 cells of the Wick | ShotActive, ShotY, PlayerY |
| Bulb hit flash | 2 frames all Light | the bulb and frame of the last hit |
| Pop | frames 0 to 3, 4 to 7 | the bulb and frame of the last kill |
| Burst | frames 0 to 2, 3 to 6, 7 to 10 | where and when a thing died |
| Wick break up | `PhaseFrames div 10`, 0 to 5 | PhaseFrames in the dying phase |
| Mending glint | bulb k from `60 + min(3k, 27)`, 4 frames a step | PhaseFrames, the field |
| Sower wings, hurt flicker | `(Frames div 3) mod 2`; white on `(Frames div 2) mod 2 = 1` | Frames, the dropper's hit points |
| Skitterjack legs, crouch | `(Frames div 4) mod 4`; frame 3 near its limits | Frames, the zigzagger's Y |
| Moonsnail | `(Frames div 8) mod 2`, mirrored when going left | Frames, the poisoner's direction |
| Points | 30 frames, up a cell every 8 | LastBonus... |
| Light on the field | 5 frames after a big kill | where and when |
| Stars | `y + Frames div 64`, wrapping in rows 16 to 205 | Frames |
| Fireflies | see 8.2 | Frames |
| Grass | tips lean on `(Frames div 40 + i) mod 2` | Frames |
| PRESS SPACE | shown on `(Frames div 30) mod 2 = 0` | Frames |

### 8.2 Depth: stars, fireflies and grass

Three layers that move at three speeds, so the flat bed has depth without a scroll:

- **Far, stars**: 18 single cells of **Mote** at fixed places (the list is in `scene.py`, `STARS`), drifting down a cell every 64 frames and wrapping inside the rows above the band. 18 cells a frame.
- **Near, fireflies**: 5 single cells of **Firefly** on slow loops: `x = x0 + 9 sin(Frames / 110 + p)`, `y = y0 + 5 sin(Frames / 80 + 1.3p)`, pulsing by a tint toward Night of `0.6 * (1 - t)` with `t = 0.5 + 0.5 sin(Frames / 24 + p)` (`FIREFLIES` in `scene.py`). 5 cells a frame. They are dim and small enough never to be mistaken for a spark.
- **Front, grass**: 32 blades of **Band Rule**, 2 to 4 cells tall, at the foot of the band (`GRASS` in `scene.py`); the tip of each leans one cell on `((Frames div 40) + i) mod 2`. Baked twice (both leans) or redrawn: 32 cells.

### 8.3 Light on the field

For 5 frames after a Gloamhead, the Sower, the Skitterjack or the Moonsnail dies, the bulbs whose centres are within 28 cells of the burst are drawn one step lighter: `D` in the body colour, `M` in Light, `L` in **Text**. At most about 12 bulbs, redrawn over the background for 5 frames.

### 8.4 Glows, banners, veils

- Glows are tint passes on the empty cells round a sprite's outline (8 neighbours): the Gloamhead (its family Light, 30 percent), the Wick (Wick Light, 18), the spark (Spark Tail, 25). About 40 cells a frame.
- The banner behind words over the field is a tint toward **Ink** at 60 percent, fading over its first and last 3 rows.
- **Scan lines** (off by default, a setting): a tint of **Ink** at 18 percent on every odd canvas row, drawn last.

Budget: the bursts and the break up are sprites, not particles. The only loose cells are the stars (18) and the fireflies (5), and the glows are about 40 tinted cells, a fixed cost well inside the brief's 60 particle cells and 20 moving things.

## 9. Checks, and the generator

### 9.1 Colour blindness

The three that the brief names must never be confused: the **Wick**, the **Blight**, and the **Gloam** in each family. The smallest distance (a redmean colour distance, about 0 to 765; 100 and up reads as plainly different) between any two of them, as drawn and simulated (Machado 2009, full strength):

| Vision | Smallest distance | Between |
|---|---|---|
| normal | 199 | Wick and Copper |
| deuteranopia | 173 | Wick and Coral |
| protanopia | 160 | Wick and Jade |
| tritanopia | 102 | Wick and Blight |

And the poison differs in lightness, as asked: relative luminance of a blighted bulb's body against a healthy one of each family.

| Family | Body | Blight |
|---|---|---|
| Jade | 0.327 | 0.671 |
| Coral | 0.277 | 0.671 |
| Tide | 0.305 | 0.671 |
| Orchid | 0.244 | 0.671 |
| Cobalt | 0.247 | 0.671 |
| Copper | 0.261 | 0.671 |

Blighted bulbs also have dark spots, so they differ in shape as well as in colour.

### 9.2 Contrast on the ground

| Colour | on Night | on Band |
|---|---|---|
| Wick | 13.1 | 11.8 |
| Spark | 19.1 | 17.3 |
| Blight | 13.1 | 11.9 |
| Ember | 5.5 | 5.0 |
| Jack | 4.1 | 3.7 |
| Husk | 6.5 | 5.9 |
| Snail Foot | 3.6 | 3.3 |
| Text | 16.5 | 14.9 |
| Text Dim | 6.1 | 5.5 |
| Points | 13.1 | 11.8 |
| Jade | 6.9 | 6.2 |
| Coral | 6.0 | 5.4 |
| Tide | 6.5 | 5.8 |
| Orchid | 5.4 | 4.9 |
| Cobalt | 5.4 | 4.9 |
| Copper | 5.7 | 5.1 |
| Jade Deep | 3.6 | 3.3 |
| Coral Deep | 2.7 | 2.5 |
| Tide Deep | 3.7 | 3.4 |
| Orchid Deep | 2.3 | 2.1 |
| Cobalt Deep | 2.3 | 2.1 |
| Copper Deep | 2.5 | 2.2 |

Every thing that matters is above 3 on both grounds. The Deep colours are shade only, never alone at an edge that has to read.

### 9.3 The generator

`moonpatch-generator/` holds the source of everything here: `palette.py` (the colours and the nights), `sprites.py` (every grid), `scene.py` (the ground, the layers and the rules of 8), `preview.py` (the pictures), `check.py` (the limits, the contrast and the colour blindness numbers), `doc.py` (this file). Run `python run_all.py` (Python 3 and Pillow) to write this file and every picture into `docs/design`. Change the data and run it again; do not edit this file by hand. The checks it runs: at most 48 colours, at most 8 colours a sprite, the sizes in the brief (8 x 8; the Skitterjack and the Moonsnail 16 x 8, as the game's boxes are; the bursts 12 x 12 and the break up 16 x 16, which are effects).

## 10. What I decided, and open questions

### 10.1 Decided (the code may want to know)

- **Two pests are 16 wide, not 16 tall.** The brief says a pest may be 8 x 16; the game's boxes for the zigzagger and the poisoner are 16 wide and 8 tall, so the Skitterjack and the Moonsnail are drawn 16 x 8 to match.
- **The spark is 2 cells wide**, not 1, because the game's shot box is 2 wide. Its head is 2 x 2 white.
- **The bulb wears from below**: roots, belly, then all but the tip, because the shots come from below.
- **Glows are tint passes**, as the brief allows for a pass that is a tint. If the painter would rather not tint, drawing the glow cells in the family Light colour at full strength also works, but looks heavier.
- **The head's eyes sit in Ink**, so they read on every night, including CRESCENT where the Gloam is Coral.
- **The waves are nights named after the moon**, with the moon in the strip, and the title walks through all six.
- **The mending happens in the second part of the dying phase** (from frame 60), drawn by the painter from the field as it is, so no new state is needed; the game still mends the field at frame 100 as now.
- **The palette has 46 colours**, so there is room for two more.

### 10.2 Open questions

1. **The name.** Moonpatch, the Wick, the Gloam, bulbs, the Sower, the Skitterjack and the Moonsnail are working names. Are they the ones you want? The class names would follow (`MoonpatchArt`, `MoonpatchLook`, `MoonpatchTint`, and the game, the docs page and the Cookoff entry renamed together, as the brief says).
2. **Readers the painter needs** that the game may not have yet: which bulb was hit last and when (for the hit flash and the pop), where and when a segment or a pest died (for the burst and the light on the field; `LastBonus` covers the pests and heads but not the beads), and whether each segment is diving (for the dive tell).
3. **WAVE n after a lost Wick.** Should the wave start banner also show when a night starts again after the Wick is lost, or only for a new night? I would show it for a new night only.
4. **The wave cleared bonus.** The rules have none now, so the `BONUS n` line is designed but not drawn. Keep it for later or drop it?
5. **The roll call on the title** is new (the brief asks only for the name, the crawler and PRESS SPACE). Keep it, or keep the title bare?
6. **Scan lines**: designed as a setting, off by default. Do you want the setting, or leave it out?
7. **The art generator** (`tools/gen-<game>-art.py`, like the FOR EACH one) that writes the classes from this file is not written; this is a design only.

