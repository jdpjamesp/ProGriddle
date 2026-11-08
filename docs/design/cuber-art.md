# Cuber: art and screen design, "Dusk Lamps"

Designer's answer to `cuber-art-brief.md`. Everything here is meant to be pasted into code with no further decisions. Section 13 lists what I decided, the one rule I would like to add and the questions still open.

**The idea in one line.** A pyramid of stone lamps floats in a dusk sky over a bottomless dark. A small glowing gummy called Pip hops from lamp to lamp lighting them; a smouldering serpent hunts it, red thorn balls bounce down, an ice crystal freezes the hunters, two moths snuff the lamps out again, and rings of light wait at the sides to lift Pip home. The working title stays in the file names; the name I propose for the game is **Lamplighter** (section 1).

Every picture is an original design: the hero, the enemies, the cube colours, the pyramid's faces, the title lettering. The things that make the idea readable are kept on purpose: isometric cubes whose top changes, a round hero that hops along four diagonals, a long chaser that hatches from a ball, round bouncing hazards, discs at the sides and the void under the edge.

Previews (made by the generator from the data in this file, so the pictures and the text cannot disagree):

- `cuber-preview.png` (3x): level 2 round 1, part way: Pip mid hop with its shadow on the lamp it will land on, the glint and the 25 on the lamp it just lit, the Coil on row 3, a Thorn, a Frost, Snuff on the left edge, four halos waiting and one used up, lamps in all three states.
- `cuber-preview-title.png` (3x): the title, part way through the intro (Pip has lit a path down the middle).
- `cuber-preview-over.png` (3x): game over with a new high score.
- `cuber-screens.png` (2x): READY, the level clear ripple half way, PAUSED, a freeze (the ring spreading, the Coil, the Thorn and Snuff frozen).
- `cuber-themes.png` (3x): the four round themes in rows: unlit, half, done, the undo signal on an unlit and a lit lamp, the HUD target cube; under them one frame of a flipping lamp.
- `cuber-sprites.png` (4x): every sprite in this file, alternate rows on a lit Mint lamp colour so both reads can be checked.
- `cuber-colour-check.png` (1x): two game screens and the swatches, as drawn, through deuteranopia, protanopia and tritanopia, and in grey scale.

## 0. Read this first

- The canvas is **256 x 256**, as the brief proposes, shown at 3x (2x on small screens) with nearest neighbour scaling. It is a **direct colour PixelCanvas** (as Space Invaders, Asteroids, Moonpatch and Skylark), not palette indexed cells: the lamps are 2:1 isometric pictures that do not sit on a square grid, and the sprites overlap them freely.
- The **HUD** is rows 0 to 31, the pyramid rows 48 to 223, the **void** rows 216 to 255 (the pyramid's bottom row covers its top).
- **Sprite format**: the tone format of `snake-art.md`. `.` is transparent, `1` to `5` are the tones of the sprite's colour row (1 highlight, 2 light, 3 base, 4 shade, 5 edge), letters are fixed colours given in each legend. No legend has more than 16 colours (most have 8 or fewer).
- **Origin**: every sprite gives its origin, the pixel that goes on the thing's position. For everything that stands on a lamp it is **the middle of the feet**, and it goes on the lamp's **foot point**: `(cube x + 16, cube y + 8)`, the middle of the top diamond (section 3.4 has them all).
- **Facing**: draw the `dr` (down right) and `ur` (up right) frames as given; down left and up left are the mirror of the grid (columns reversed, the origin column becomes `width - 1 - x`). Every moving thing is lit from the **top middle** (Pip glows from inside; the others have a soft top light), so mirroring never puts the light on the wrong side. The lamps are never mirrored and are lit from the top left.
- **Draw order** (back to front): the baked background (sky, stars, void), the lamps (row 1 to row 7, left to right; each later lamp covers the edge line of the one above it, see 3.2), the sky particles, the halos, shadows, the glints, enemies whose foot point is higher on screen first (sort by foot y, then x), Pip, the puffs and sparks, the score pop ups, the HUD, the banners.
- **Time** is in milliseconds; a frame is 1/60 s (about 16.7 ms), and the hop is 12 frames (200 ms) as the brief says.
- **No em dashes, no blending**: every colour below is a flat value; a glow or a shadow is extra pixels in a dimmer colour.

## 1. Names and art direction

### 1.1 The look: Dusk Lamps

A pyramid of **stone lamps** floats in a **dusk sky**, the last violet after sunset with a few stars and far paper lanterns drifting up. Under it there is only the **void**, the sky going to near black, with dust motes falling into it. The lamps are cool lilac stone on their sides and dark slate glass on top. When Pip lands on one, its top **lights up from inside**: first a ring (half way) then a full glowing core, and the light **spills down** the two lip rows of the stone below it. A finished level is a pyramid of light in the dark, and the clear is a ripple of white running over it. The colours carry meaning: **light means progress** (dark, ring, glowing core, from dim to bright, so it reads in grey scale), **red hot means it hunts you** (the Coil's ember rim, its seed's cracks and the red Thorn), **ice means help** (the Frost and the halos are the only cool bright things on the board), and **gold means good news** (Pip, the points, a new high score).

It is a sibling of the others (dark ground, chunky pixels, the 5 x 7 font, a lit edge on everything that moves, banner plates with two rules) but its own thing: a warm violet dusk instead of navy (Lantern Glass), indigo (Space Invaders), deep blue (Moonlit Bed) or near black (Asteroids). The four round themes (Mint, Rose, Sky, Lilac) are pastel lights, not jewel colours.

### 1.2 The names and the roles

| Role in the brief | Name | What it is |
|---|---|---|
| The game | **Lamplighter** (working title Cuber) | You light every lamp on the hill before the night takes it |
| A cube | **a lamp** | A block of lilac stone with a glass top that lights up |
| The hero | **Pip** | A round lemon gummy that glows from inside, big eyes, pink cheeks, a little glowing sprout on its head, two stubby feet |
| The chaser, as a ball | **the seed** | A charcoal egg with a glowing ember crack, rim red hot |
| The chaser, hunting | **the Coil** | A smouldering charcoal serpent: two coils on the lamp, a horned head reared over them, yellow eyes, an open jaw with fangs, a red hot rim and embers glowing in its seams |
| The bouncer | **a Thorn** | A red ball with four spikes and two narrow eyes |
| The freezer | **a Frost** | An eight sided ice crystal with a white star, no rim, no eyes |
| The undoers | **Snuff** (left edge) and **Puff** (right edge) | Two moths who put lamps out: Snuff has dusty lilac wings, Puff dusty sand wings |
| A disc | **a halo** | A floating ring of cool light; a band of white runs round it |
| The target colour | **the round's light** | Mint, Rose, Sky or Lilac, shown as a small lit lamp in the HUD |


### 1.3 What is the same on purpose

- **Everything that kills Pip is red hot or red**: the Coil and its seed have an Ember rim (`FF5A36`) and ember seams; a Thorn is red (`EC3442`). Nothing else on the board uses red, and no helpful thing has a rim.
- **Everything that helps is ice**: the Frost and the halos share the cool cyan white of the Ice and Halo rows, and the freeze tints the hunters in the same Ice row.
- **Gold is good news**: Pip's base (`FFD247`) is the Gold of points, the high score and the extra life.
- **Light means progress**: the lamp states go from dark to bright in every theme, the lit lamp spills light on its stone, and the level clear is a ripple of white.
- **The shapes keep them apart without colour**: Pip is round with feet and a sprout, the seed is an egg (taller than wide, smooth), a Thorn is a ball with spikes, a Frost is an octagon with a star, the Coil is tall with horns, the moths have wings.

## 2. The palette

**130 distinct colours.** Some names share a value on purpose and say so.

### 2.1 Tone rows

Most rows are made from a base: tone 1 and 2 are the base mixed with white, tones 4 and 5 the base mixed with Outline `0B0614`. Rows marked "set by hand" are not made that way.

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge | Used for |
|---|---|---|---|---|---|---|
| Unlit | `8588AB` | `5A5E8E` | `3A3F78` | `2C2E5A` | `1D1C3A` | a lamp not yet reached: dark slate, plain top |
| Mint Half | `8DC2C2` | `5AA7A7` | `2C8E8E` | `205D62` | `142C36` | level 1 theme: a lamp half way (three hop levels) |
| Mint | `C1F8E3` | `90F3CD` | `5CEDB6` | `3F9A7C` | `224741` | level 1 theme: a lamp done, the target colour |
| Rose Half | `CC9AB7` | `B56D97` | `A0447A` | `6A2E55` | `351731` | level 2 theme: half way |
| Rose | `FFD0E6` | `FFABD3` | `FF84BE` | `A75781` | `4F2944` | level 2 theme: done |
| Sky Half | `91ADD4` | `6189C1` | `3468B0` | `254578` | `162140` | level 3 theme: half way |
| Sky | `CDEBFF` | `A6DCFF` | `7CCBFF` | `5384AA` | `2B3D56` | level 3 theme: done |
| Lilac Half | `B5A0D6` | `9476C4` | `7650B4` | `4F357A` | `291B41` | level 4 theme: half way |
| Lilac | `ECDDFF` | `DDC2FF` | `CDA6FF` | `876CAA` | `413356` | level 4 theme: done |
| Pip | `FFF7D6` | `FFE88E` | `FFD247` | `E0912C` | `4A1A22` | Pip, the hero: a lemon gummy that glows from inside |
| Coil | `A79CB2` | `726880` | `4A4156` | `2E2838` | `15101C` | the Coil, the chaser, and its seed: charcoal |
| Thorn | `F6A4AA` | `F16973` | `EC3442` | `A42533` | `581624` | the Thorn, the bouncing ball that kills |
| Frost | `FFFFFF` | `D6F6FF` | `9EE6FF` | `4FAFE0` | `22609A` | the Frost, the ball that freezes (set by hand) |
| Snuff | `DDD4F1` | `C7B8E8` | `B4A0E0` | `746592` | `3E3451` | Snuff, the moth of the left edge: dusty lilac wings |
| Puff | `F1E4C5` | `E8D19E` | `E0C27E` | `8F7B56` | `4B3E34` | Puff, the moth of the right edge: dusty sand wings |
| Halo | `FFFFFF` | `C8F4FF` | `6ED2F2` | `2F86B6` | `17406A` | a halo, the disc that lifts Pip home (set by hand) |
| Ice | `FFFFFF` | `E2F8FF` | `B6E8FA` | `6CB4DA` | `2C5E8C` | the frozen tint: replaces every tone row of a frozen enemy |
| Flash | `FFFFFF` | `FFFFFF` | `FFF2EA` | `FF9A80` | `FF4A3A` | death flash frame 1: Pip goes white hot |
| Negative | `15101C` | `2A1A30` | `4A2236` | `FFE88E` | `FFFFFF` | death flash frame 2: Pip inverted (dark body, white edge) |

### 2.2 Single colours

**Sky, void and HUD**

| Name | Hex | Used for |
|---|---|---|
| HUD | `0C0818` | the HUD strip, rows 0 to 31 |
| HUD Rule | `2C2250` | the 1 pixel rule under the HUD (row 31) |
| Dusk A | `231538` | the dusk sky, band 1 (rows 32 to 79) |
| Dusk B | `1D1130` | band 2 (rows 80 to 127) |
| Dusk C | `170D28` | band 3 (rows 128 to 175) |
| Dusk D | `120A20` | band 4 (rows 176 to 215) |
| Void Top | `0A0614` | the void, rows 216 to 239 |
| Void Deep | `050309` | the void, rows 240 to 255: if you fall here you are gone |
| Star Dim | `3A2C5E` | a far star (1 pixel, baked) |
| Star | `8676B4` | a near star (1 pixel, a few of them twinkle by swapping with Star Dim) |
| Lantern | `B0704A` | a far sky lantern (2 x 3, drifting up, a particle) |
| Lantern Dim | `5A3436` | the glow round a far lantern and its tail |
| Mote | `35264E` | a mote falling into the void (particles under the pyramid) |

**The stone of the lamps (cube sides)**

| Name | Hex | Used for |
|---|---|---|
| Left Lip | `8E7EB8` | the left face: the 2 rows under the top edge |
| Left | `5E4F8A` | the left face, lit from the upper left |
| Left Low | `4C3F74` | the left face, the lowest 3 rows (a soft fall off) |
| Right Lip | `584A80` | the right face: the 2 rows under the top edge |
| Right | `3A305E` | the right face, in shade |
| Right Low | `2E264C` | the right face, the lowest 3 rows |
| Edge | `150E26` | the 1 pixel edge line of the outer bottom edges and the seam |

**Lamp light**

| Name | Hex | Used for |
|---|---|---|
| Spill Mint | `5FBFA6` | the lip rows of a lit lamp, level 1 (light spilling down the stone) |
| Spill Mint Dark | `3E8A86` | the right lip of a lit lamp, level 1 |
| Spill Rose | `C4729E` | the lips of a lit lamp, level 2 |
| Spill Rose Dark | `8C4C7C` | the right lip of a lit lamp, level 2 |
| Spill Sky | `6E9ED8` | the lips of a lit lamp, level 3 |
| Spill Sky Dark | `4C6CA8` | the right lip of a lit lamp, level 3 |
| Spill Lilac | `A88ADC` | the lips of a lit lamp, level 4 |
| Spill Lilac Dark | `7660AA` | the right lip of a lit lamp, level 4 |

**Pip extras**

| Name | Hex | Used for |
|---|---|---|
| Eye | `FFFFFF` | an eye white (letter A) |
| Pupil | `1E0E26` | a pupil (letter B), and Pip's closed eye line |
| Cheek | `FF8C78` | Pip's cheeks (letter C) |

**Danger**

| Name | Hex | Used for |
|---|---|---|
| Ember | `FF5A36` | the hot rim of the Coil and its seed, the cracks of the seed: everything that hunts you |
| Ember Deep | `B0242C` | the deep cracks and the inside of the Coil's jaw |
| Coil Eye | `FFE24A` | the Coil's eyes |
| Fang | `FFF4E8` | the Coil's fangs and the Thorn's glint |

**Moth extras**

| Name | Hex | Used for |
|---|---|---|
| Moth Body | `5C4A6E` | the body of both moths |
| Moth Eye | `F4F0FF` | the eyes of both moths |

**Text and screens**

| Name | Hex | Used for |
|---|---|---|
| Text | `F4F0FA` | numbers and words |
| Label | `9C8EC4` | SCORE, HI, LEVEL, ROUND and the key hints |
| Gold | `FFD247` | good news: a new high score, points, an extra life (same value as Pip tone 3 on purpose) |
| Title Top | `FFF4C0` | the title, top row of the gradient |
| Title Bottom | `FF9A4E` | the title, bottom row |
| Over Top | `FFB0A0` | GAME OVER, top row |
| Over Bottom | `EC3442` | GAME OVER, bottom row (the Thorn's red: red means danger) |
| Plate | `0C0818` | the fill of every banner plate (same value as HUD) |
| Plate Rule | `6ED2F2` | the two rules of a banner plate (same value as Halo tone 3: a banner is good news or a pause) |
| Outline | `0B0614` | the 1 pixel outline behind text on the play area |
| Spark | `FFFFFF` | the first colour of every spark and glint |

### 2.3 The round themes

The light changes every **round** (four rounds to a level, so every level shows all four), as the target colour of the brief does. The level sets the rules (two hops or three, undo lamps). The theme is round - 1 (0 to 3).

| Round | Theme | Unlit row | Half row | Done row (the target) | Lip colours of a lit lamp |
|---|---|---|---|---|---|
| 1 | MINT | Unlit | Mint Half | Mint | Spill Mint, Spill Mint Dark |
| 2 | ROSE | Unlit | Rose Half | Rose | Spill Rose, Spill Rose Dark |
| 3 | SKY | Unlit | Sky Half | Sky | Spill Sky, Spill Sky Dark |
| 4 | LILAC | Unlit | Lilac Half | Lilac | Spill Lilac, Spill Lilac Dark |

## 3. The scenery

### 3.1 The background (baked once per screen)

- Rows 0 to 30: HUD `0C0818`. Row 31: HUD Rule `2C2250` across the canvas.
- Rows 32 to 255: six flat bands, Dusk A from row 32, Dusk B from row 80, Dusk C from row 128, Dusk D from row 176, Void Top from row 216, Void Deep from row 240. The two rows above each band boundary are a checkerboard of the two bands: pixel (x, y) takes the lower band when `(x + y)` is even. No gradient.
- **Stars**: 46 single pixels, baked. Positions come from a seeded random (seed 7) in x 2 to 253, y 34 to 213; about one in five is Star `8676B4`, the rest Star Dim `3A2C5E`. The generator's list: (84, 72), (14, 52), (26, 127), (234, 163)*, (24, 145), (63, 57), (17, 178)*, (59, 195), (244, 49), (103, 46), (13, 176), (76, 141)*, (32, 180), (210, 208)*, (150, 180), (97, 58), (18, 178)*, (54, 161), (111, 114), (238, 150), (65, 80), (64, 54), (136, 160), (188, 148), (252, 52)*, (109, 76), (40, 159), (248, 205)*, (144, 180), (211, 114), (91, 186), (206, 150)*, (25, 103), (172, 50)*, (181, 113), (176, 148), (100, 205), (242, 152), (158, 63), (57, 107)*, (65, 135), (225, 161)*, (116, 136), (228, 69), (223, 174), (108, 125).
  A `*` marks a bright one. Four of the bright ones twinkle (section 9).
- **The void**: the two darkest bands under the pyramid, plus the falling motes (section 9). Nothing else is there, so a fall reads as "gone".

### 3.2 The lamp (32 x 32)

The picture of one lamp, top left at the cube's (x, y). The top is a 2:1 diamond 32 x 16 (rows 0 to 15, 4 pixels wide at the tips); the two faces are 16 high below its lower edges. Light comes from the top left: the left face is lit, the right in shade, the top has a light rim on its two upper edges and a shade rim on its two lower ones.

**How they tile.** With the pitch of the brief (32 across, 24 down, each row starting 16 further left) the lamps meet exactly, with one overlap: the last row of each face (the `E` edge line) lies under the top rim of the lamp below. Draw the rows from the top down and the edge line shows only on the outer faces of the pyramid, where it gives the hill a crisp dark outline. Checked by the generator: no other pixel overlaps, no gap.

#### lamp_unlit (32 x 32): not reached

Legend: `1` to `5` the Unlit row; `L` Left Lip `8E7EB8` (Spill on a lit lamp), `M` Left `5E4F8A`, `N` Left Low `4C3F74`, `R` Right Lip `584A80` (Spill Dark on a lit lamp), `S` Right `3A305E`, `T` Right Low `2E264C`, `E` Edge `150E26`.

```
..............2222..............
............22333322............
..........223333333322..........
........2233333333333322........
......22333333333333333322......
....223333333333333333333322....
..2233333333333333333333333322..
22333333333333333333333333333322
44333333333333333333333333333344
LL4433333333333333333333333344RR
LLLL443333333333333333333344RRRR
MMLLLL44333333333333333344RRRRSS
MMMMLLLL4433333333333344RRRRSSSS
MMMMMMLLLL443333333344RRRRSSSSSS
MMMMMMMMLLLL44333344RRRRSSSSSSSS
MMMMMMMMMMLLLL4444RRRRSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

A plain dark slate top. Grey scale: the darkest of the three.

#### lamp_half (32 x 32): half way (three hop levels only)

Legend: `1` to `5` the theme's Half row; `L` Left Lip `8E7EB8` (Spill on a lit lamp), `M` Left `5E4F8A`, `N` Left Low `4C3F74`, `R` Right Lip `584A80` (Spill Dark on a lit lamp), `S` Right `3A305E`, `T` Right Low `2E264C`, `E` Edge `150E26`.

```
..............2222..............
............22333322............
..........223333333322..........
........2233333333333322........
......22333333111133333322......
....223333331133331133333322....
..2233333311333333331133333322..
22333333113333333333331133333322
44333333223333333333332233333344
LL4433333322333333332233333344RR
LLLL443333332233332233333344RRRR
MMLLLL44333333222233333344RRRRSS
MMMMLLLL4433333333333344RRRRSSSS
MMMMMMLLLL443333333344RRRRSSSSSS
MMMMMMMMLLLL44333344RRRRSSSSSSSS
MMMMMMMMMMLLLL4444RRRRSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

A **ring**: the inner diamond (16 x 8, centred) drawn as a 2 pixel outline in tones 1 (upper half) and 2 (lower half). Grey scale: the middle one, and the only top with a hollow ring.

#### lamp_done (32 x 32): lit, the target

Legend: `1` to `5` the theme's Done row; `L` Spill (theme), `R` Spill (theme) Dark; the rest as above.

```
..............2222..............
............22333322............
..........223333333322..........
........2233333333333322........
......22333333222233333322......
....223333332222222233333322....
..2233333322222222222233333322..
22333333222211111111222233333322
44333333222211111111222233333344
LL4433333322222222222233333344RR
LLLL443333332222222233333344RRRR
MMLLLL44333333222233333344RRRRSS
MMMMLLLL4433333333333344RRRRSSSS
MMMMMMLLLL443333333344RRRRSSSSSS
MMMMMMMMLLLL44333344RRRRSSSSSSSS
MMMMMMMMMMLLLL4444RRRRSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

A **glowing core**: the inner diamond filled with tone 2 and a bright tone 1 bar at its middle, and the light spilling on the lips. Grey scale: by far the brightest.

Repainting a lamp when its state changes: redraw the whole 32 x 32 picture at its place, then redraw the lamps of the next row that overlap it (its two children cover its edge line) and any sprite on it. That is the small region the brief allows: at most 3 lamp pictures.

#### lamp_mini (16 x 16): the target in the HUD

Legend: `1` to `5` the theme's Done row; faces as lamp_done (it is the same recipe at half size, with 1 pixel rims).

```
......2222......
....23333332....
..233322223332..
2333222222223332
4333222222223334
LL433322223334RR
LLLL43333334RRRR
MMLLLL4444RRRRSS
MMMMLLLLRRRRSSSS
NNMMMMLLRRSSSSTT
NNNNMMMMSSSSTTTT
NNNNNNMMSSTTTTTT
EENNNNNNTTTTTTEE
..EENNNNTTTTEE..
....EENNTTEE....
......EEEE......
```

### 3.3 Lit glint and the ripple

When a lamp reaches **done**, it is repainted at once and the glint plays over its top (drawn as a sprite with its top left on the cube's top left): frame 1 flashes the upper rim white and shows a small star, frame 2 a long four point star, frame 3 a small star and two sparkles. Tone 1 is the theme's Done row.

#### glint_1 (32 x 16, origin (0, 0))

The lamp lit glint, frame 1 (32 x 16), drawn with its top left on the cube's top left. Tone 1 is the theme's done row.

Legend: `W` Spark `FFFFFF`.

```
..............WWWW..............
............WW....WW............
..........WW........WW..........
........WW............WW........
......WW..WW............WW......
....WW..WWWWWW............WW....
..WW......WW................WW..
WW............................WW
................................
................................
................................
................................
................................
................................
................................
................................
```

#### glint_2 (32 x 16, origin (0, 0))

The lamp lit glint, frame 2 (32 x 16), drawn with its top left on the cube's top left. Tone 1 is the theme's done row.

Legend: `1` tones 1 of the theme's Done row; `W` Spark `FFFFFF`.

```
................................
................................
................................
..........11....................
..........WW....................
.....111WWWWWW111...............
..........WW....................
..........11....................
................................
................................
................................
................................
................................
................................
................................
................................
```

#### glint_3 (32 x 16, origin (0, 0))

The lamp lit glint, frame 3 (32 x 16), drawn with its top left on the cube's top left. Tone 1 is the theme's done row.

Legend: `1` tones 1 of the theme's Done row.

```
................................
................................
................................
......................1.........
..........11....................
........111111..................
..........11....................
................................
.....1..........................
................................
.......................1........
................................
................................
................................
................................
................................
```

**The ripple** (level clear): 28 steps of 40 ms, one lamp per step in reading order (row 1 to 7, left to right). At its step a lamp shows glint_1 for 2 steps (80 ms) and goes back to plain done. Two passes, the second starting when the first is at row 5 (step 15). Then the pyramid is repainted **unlit in the next theme** one row per 60 ms from the top (7 steps). At no time does more than one row flash at once, so it is well inside the three flashes a second rule of `docs/accessibility.md`.

### 3.4 Lamp, foot and halo coordinates (final numbers)

Row `r` (1 to 7) has `r` lamps, column `c` 0 to r - 1. Lamp top left `x = 128 - 16 r + 32 c`, `y = 48 + 24 (r - 1)`. Foot point `(x + 16, y + 8)`. These are the brief's numbers unchanged: the apex lamp is at (112, 48), the bottom row ends at y = 223, the void below is 32 rows.

| Row | Lamp top left, c = 0 to r - 1 | Foot points |
|---|---|---|
| 1 | (112, 48) | (128, 56) |
| 2 | (96, 72) (128, 72) | (112, 80) (144, 80) |
| 3 | (80, 96) (112, 96) (144, 96) | (96, 104) (128, 104) (160, 104) |
| 4 | (64, 120) (96, 120) (128, 120) (160, 120) | (80, 128) (112, 128) (144, 128) (176, 128) |
| 5 | (48, 144) (80, 144) (112, 144) (144, 144) (176, 144) | (64, 152) (96, 152) (128, 152) (160, 152) (192, 152) |
| 6 | (32, 168) (64, 168) (96, 168) (128, 168) (160, 168) (192, 168) | (48, 176) (80, 176) (112, 176) (144, 176) (176, 176) (208, 176) |
| 7 | (16, 192) (48, 192) (80, 192) (112, 192) (144, 192) (176, 192) (208, 192) | (32, 200) (64, 200) (96, 200) (128, 200) (160, 200) (192, 200) (224, 200) |

**Halos** sit where a lamp would be if the row went one further: on the left at column -1, on the right at column r, for rows 3, 4 and 5. The halo's origin (the middle of its hole) goes on that foot point, so Pip hops onto it with the same arithmetic as onto a lamp: up left from (r + 1, 0) lands on the left halo of row r, up right from (r + 1, r + 1) on the right halo of row r. The gap between a halo and its row's end lamp is 4 pixels (the brief asked about 8; at 8 the halo would not be on the hop's landing point).

| Side | Row | Foot point (halo origin) | Halo picture top left |
|---|---|---|---|
| left | 3 | (64, 104) | (52, 98) |
| right | 3 | (192, 104) | (180, 98) |
| left | 4 | (48, 128) | (36, 122) |
| right | 4 | (208, 128) | (196, 122) |
| left | 5 | (32, 152) | (20, 146) |
| right | 5 | (224, 152) | (212, 146) |

Which spots hold a halo is a rule of the round; the art draws any of the six.

**Starts**: Pip on the apex, foot point (128, 56). The seed, Thorns and Frosts drop in at the foot point of (2, 0) or (2, 1), from 24 pixels above it (they appear under the HUD rule), falling 3 pixels a frame, then bounce on. Snuff enters on (7, 0) and Puff on (7, 6), each with a hop from 16 pixels below the foot point. The Coil stands where its seed hatched.

### 3.5 Pip's shadow

#### shadow (8 x 3, origin (4, 0))

Pip's shadow (8 x 3), centred on the foot point, one row lower. `S` is tone 4 of the row of the lamp it falls on (Unlit shown).

Legend: `S` Unlit 4 `2C2E5A`.

```
.SSSSSS.
SSSSSSSS
.SSSSSS.
```

Drawn on the lamp under Pip (when standing) and, during a hop, on the start lamp for frames 1 to 2 and on the landing lamp from frame 3. Never drawn off the pyramid (so a hop off the edge has no shadow to land on: a small warning).

## 4. Pip

Body 12 x 14 (the whole frame), origin (6, 13), the middle of the feet. The Pip row is set by hand (a warm brown edge, not grey). Pip glows from inside: the highlight is on the top of its head, so the mirrored frames are right.

#### pip_stand_dr (12 x 14, origin (6, 13))

Pip standing, facing down right.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
.......11...
......41....
...555555...
..52222225..
.5322112235.
53322AA2AA35
53322AB2AB35
53332AB2AB35
533C333BB3C5
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_stand_ur (12 x 14, origin (6, 13))

Pip standing, facing up right.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
....11......
.....14.....
...555555...
..522AB2AB..
.5322BB2BB5.
533221122335
533222222335
533322223335
533233333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_blink_1 (12 x 14, origin (6, 13))

A blink, frame 1 (half shut). Only on the down right facing.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
.......11...
......41....
...555555...
..52222225..
.5322112235.
533222222235
53322AB2AB35
533C222BB3C5
533333333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_blink_2 (12 x 14, origin (6, 13))

A blink, frame 2 (shut).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
.......11...
......41....
...555555...
..52222225..
.5322112235.
533222222235
53322BB2BB35
533C222BB3C5
533333333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_hop_dr_1 (12 x 14, origin (6, 13))

Hop down right, frame 1: the crouch (squash).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
............
............
.......11...
......41....
....5555....
..55222255..
.5322AA2AA5.
53322AB2AB35
53332AB2AB35
533C333BB3C5
.5333333335.
.5544444455.
...555555...
..555..555..
```

#### pip_hop_dr_2 (12 x 14, origin (6, 13))

Hop down right, frame 2: in the air (stretch, feet tucked).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
....5515....
...522225...
..52211225..
..52211225..
.5322AA2AA5.
.5332AB2AB5.
.5333AB3AB5.
.53C333BB3C.
.5333333335.
..53333335..
...544445...
....5555....
....44..44..
............
```

#### pip_hop_dr_3 (12 x 14, origin (6, 13))

Hop down right, frame 3: the landing (squash, wider than the crouch).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
............
............
............
.......11...
......41....
....5555....
..55222255..
.5322112235.
53322AA2AA35
53333BB3BB35
533C333333C5
.5544444455.
...555555...
..555..555..
```

#### pip_hop_ur_1 (12 x 14, origin (6, 13))

Hop up right, frame 1: the crouch (squash).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
............
............
....11......
.....14.....
....5AB5AB..
..552BB2BB..
.5322112235.
533221122335
533322223335
533233333335
.5333333335.
.5544444455.
...555555...
..555..555..
```

#### pip_hop_ur_2 (12 x 14, origin (6, 13))

Hop up right, frame 2: in the air (stretch, feet tucked).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
....5155....
...522225...
..522AB2AB..
..522BB2BB..
.5322112235.
.5332222335.
.5333223335.
.5323333335.
.5333333335.
..53333335..
...544445...
....5555....
...44..44...
............
```

#### pip_hop_ur_3 (12 x 14, origin (6, 13))

Hop up right, frame 3: the landing (squash, wider than the crouch).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
............
............
............
....11......
.....14.....
....5555....
..552AB2AB..
.5322BB2BB5.
533222222335
533332233335
533233333335
.5544444455.
...555555...
..555..555..
```

#### pip_fall_1 (12 x 14, origin (6, 13))

Falling, frame 1: eyes wide, mouth open.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
....5515....
...522225...
..52211225..
..52211225..
.5322AA2AA5.
.5332BA2BA5.
.5333AA3AA5.
.53C333B33C.
.533333B335.
..53333335..
...544445...
....5555....
....44..44..
............
```

#### pip_fall_2 (12 x 14, origin (6, 13))

Falling, frame 2: turned away (the up right back view, mirrored).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
....5515....
...522225...
..BA2BA225..
..BB2BB225..
.5322112235.
.5332222335.
.5333223335.
.5333333235.
.5333333335.
..53333335..
...544445...
....5555....
...44..44...
............
```

#### pip_fall_3 (12 x 14, origin (6, 13))

Falling, frame 3: upside down.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
....44..44..
....5555....
...544445...
..53333335..
.533333B335.
.53C333B33C.
.5333AA3AA5.
.5332BA2BA5.
.5322AA2AA5.
..52211225..
..52211225..
...522225...
....5515....
............
```

#### pip_fall_4 (12 x 14, origin (6, 13))

Falling, frame 4: small and far, about to be gone.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
............
............
............
......1.....
......4.....
....5555....
...521125...
..53A1A235..
..53B2B335..
..53333335..
...544445...
....5555....
............
............
```

#### pip_hit_1 (12 x 14, origin (6, 13))

Hit, frame 1: eyes squeezed shut.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
.......11...
......41....
...555555...
..52222225..
.5322112235.
53322BB2BB35
53322BB2BB35
533C222BB3C5
533333333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_hit_2 (12 x 14, origin (6, 13))

Hit, frame 2: spun round (the back view).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
....11......
.....14.....
...555555...
..522AB2AB..
.5322BB2BB5.
533221122335
533222222335
533322223335
533233333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_hit_3 (12 x 14, origin (6, 13))

Hit, frame 3: spun to face down left (the mirror of frame 1).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
...11.......
....14......
...555555...
..52222225..
.5322112235.
53BB2BB22335
53BB2BB22335
5C3BB222C335
533333333335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_hit_4 (12 x 14, origin (6, 13))

Hit, frame 4: back view, mirrored. Then the death flash (two frames, tone row swap).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
......11....
.....41.....
...555555...
..BA2BA225..
.5BB2BB2235.
533221122335
533222222335
533322223335
533333332335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_ride_1 (12 x 14, origin (6, 13))

On a halo, frame 1: happy eyes (shut arcs).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
......1.....
......4.....
...555555...
..52222225..
.5322112235.
5332BB12BB35
533222222335
533C222233C5
533333BB3335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_ride_2 (12 x 14, origin (6, 13))

On a halo, frame 2: arms up.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
......1.....
......4.....
...555555...
4.52222225.4
553221122355
5332BB12BB35
533222222335
533C222233C5
533333BB3335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

#### pip_win_1 (12 x 14, origin (6, 13))

Winning, frame 1: the crouch, eyes shut with joy.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
............
............
.......11...
......41....
....5555....
..55222255..
.5322222225.
53322BB2BB35
533C222BB3C5
533333333335
.5333333335.
.5544444455.
...555555...
..555..555..
```

#### pip_win_2 (12 x 14, origin (6, 13))

Winning, frame 2: the jump, arms up (drawn 4 pixels higher, see section 10).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `B` Pupil `1E0E26`; `C` Cheek `FF8C78`.

```
......1.....
......4.....
...555555...
4.52222225.4
553221122355
5332BB12BB35
533222222335
533C222233C5
533333BB3335
533333333335
.5333333335.
..54444445..
...555555...
..555..555..
```

**Death flash** (12 x 14): the frame Pip is on, drawn with its tone row swapped: the Flash row for 100 ms (white hot), the Negative row for 100 ms (dark body, white edge), the Flash row for 100 ms. Letters stay as they are. Two white flashes, a small area: inside the accessibility rule.

### 4.1 Lives

#### pip_icon (8 x 8, origin (4, 7))

A life in the HUD: Pip's head. Drawn at y = 16 in the HUD (section 11).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Pip row (`FFF7D6`, `FFE88E`, `FFD247`, `E0912C`, `4A1A22`); `A` Eye `FFFFFF`; `B` Pupil `1E0E26`.

```
....1...
..5555..
.521125.
53A1A235
53B2B335
53333335
.544445.
..5555..
```

## 5. The seed and the Coil

### 5.1 The seed (the chaser before it hatches)

Body 10 x 10, origin (5, 9). Charcoal with an Ember rim and a crack that glows. It is an egg: taller than wide and smooth, where a Thorn is round with spikes.

#### seed_1 (10 x 10, origin (5, 9))

The seed, bounce frame 1: squash (on landing).

Legend: `1234` tones 1, 2, 3, 4 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`.

```
..........
..........
..........
...EEEE...
.EE2112EE.
E32F1F223E
E3FF2F2F3E
E333F3333E
.E444444E.
..EEEEEE..
```

#### seed_2 (10 x 10, origin (5, 9))

The seed, bounce frame 2: round (in the air).

Legend: `1234` tones 1, 2, 3, 4 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`.

```
....EE....
..EE22EE..
.E321123E.
.E321123E.
.EF2222FE.
.E3FF3F3E.
.E333F33E.
.E333333E.
..EE44EE..
....EE....
```

#### seed_3 (10 x 10, origin (5, 9))

The seed, bounce frame 3: stretch (leaving and arriving).

Legend: `1234` tones 1, 2, 3, 4 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`.

```
...EEEE...
..E2222E..
..E2112E..
..E2112E..
.EF2222FE.
.E3FF3F3E.
..E33F3E..
..E3333E..
..E4444E..
...EEEE...
```

#### seed_hatch_1 (10 x 10, origin (5, 9))

Hatching, frame 1: the crack glows all the way round.

Legend: `1234` tones 1, 2, 3, 4 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`.

```
..........
....EE....
..EE22EE..
.E221122E.
.FFFFFFFF.
E33222233E
.E333333E.
.E333333E.
..E4444E..
...EEEE...
```

#### seed_hatch_2 (10 x 10, origin (5, 9))

Hatching, frame 2: the shell opens and the eyes show. Then the Coil stands.

Legend: `1234` tones 1, 2, 3, 4 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `Y` Coil Eye `FFE24A`.

```
..........
...YEY....
..EE22EE..
.E2E1E2EE.
.FFFFFFFF.
E33222233E
.E333333E.
.E333333E.
..E4444E..
...EEEE...
```

### 5.2 The Coil

Picture 16 x 24, origin (8, 23), the middle of the lowest coil. **Its hit box is the 12 x 14 at columns 2 to 13, rows 10 to 23**, exactly Pip's box round the same origin, as the brief asks (the hit is on the head, and the head reared above is overhang: 2 columns each side and 10 rows above). The rim `E` is the hot rim; `F` are embers in the seams between coils.

#### coil_stand_dr (16 x 24, origin (8, 23))

The Coil, standing, facing down right: two coils on the lamp, the head reared over them.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
................
....E...E.......
.....E.EEEEE....
......E22122E...
.....E3211YY3Y..
....E332215233E.
....E333222333E.
....E33333FFFFE.
.....E3333WFWE..
.....E444444E...
....E25444EE....
...E32155E......
...E32223E......
...E33333E......
...E444445EE....
..E354445223E...
.E33355F23333E..
..E333333333E...
..E4444444445E..
.E355F54555533E.
E33333252233333E
.E333333333333E.
..EE44444444EE..
....EEEEEEEE....
```

#### coil_hop_dr_1 (16 x 24, origin (8, 23))

Hop down right, frame 1: the coils press down.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
................
................
................
................
................
................
....E...EEE.....
.....EEE2E2EE...
.....E3211123E..
.....E3211YY3Y..
....E332225233E.
....E333333333E.
.....E3333FFFF..
....E33333WFWE..
....E544444EE...
...E325544E.....
..E3333355FEE...
.E35333335333E..
.E33444443333E..
.E33554F533335E.
E35544F44445533E
.E3355F5555333E.
..EE44444444EE..
....EEEEEEEE....
```

#### coil_hop_dr_2 (16 x 24, origin (8, 23))

Hop down right, frame 2: in the air, stretched tall.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
....E...E.......
.....E.EEEEE....
......E22122E...
.....E3211YY3Y..
....E332215233E.
....E333222333E.
....E33333FFFFE.
.....E3333WFWE..
....E4444444EE..
....E55444EE....
...E33255E......
....E333E.......
....E4444E......
...E544452EE....
..E3355F2233E...
..E333333333E...
...E3333333E....
..E5544444F5EE..
..E3355F55233E..
..E3333333333E..
..EE33333333EE..
....EEEEEEEE....
................
................
```

#### coil_hop_dr_3 (16 x 24, origin (8, 23))

Hop down right, frame 3: the landing, coils spread.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
................
................
................
................
................
................
................
................
....E...E.......
.....E.EEEEE....
......E22122E...
.....E3211YY3Y..
....E332215233E.
....E333222333E.
....E33333FFFFE.
...E533333WFWE..
.EE3354444444E..
.E33325444445E..
.E3333355F553E..
.E5533333F4455E.
E335444445F5333E
E33355F55333333E
.EEE33333333EEE.
....EEEEEEEE....
```

#### coil_stand_ur (16 x 24, origin (8, 23))

The Coil, standing, facing up right: two coils on the lamp, the head reared over them.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `Y` Coil Eye `FFE24A`.

```
................
......E...E.....
......EEEEEE....
.....E221122E...
....E32F11223Y..
....E32522223E..
....E33F22233E..
....E33333333E..
....E33333333E..
.....E444444E...
....E54444EE....
...E3255FE......
...E32223E......
...E33333E......
...E444445EE....
..E354445223E...
.E33355F23333E..
..E333333333E...
..E4444444445E..
.E355F54555533E.
E33333252233333E
.E333333333333E.
..EE44444444EE..
....EEEEEEEE....
```

#### coil_hop_ur_1 (16 x 24, origin (8, 23))

Hop up right, frame 1: the coils press down.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `Y` Coil Eye `FFE24A`.

```
................
................
................
................
................
................
......E.EEE.....
......EE22EE....
.....E221122E...
....E32F11223Y..
....E33522233E..
....E33F33333E..
....E33333333E..
....E3333333E...
....E544444E....
...E325544E.....
..E33333552EE...
.E35333335333E..
.E33444443333E..
.E33554F533335E.
E35544F44445533E
.E3355F5555333E.
..EE44444444EE..
....EEEEEEEE....
```

#### coil_hop_ur_2 (16 x 24, origin (8, 23))

Hop up right, frame 2: in the air, stretched tall.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `Y` Coil Eye `FFE24A`.

```
......E...E.....
.......EEEE.....
.....EE2222EE...
....E32F11223Y..
....E32511223E..
....E33F22233E..
....E33333333E..
....E33333333E..
....E4444444E...
....E54444EE....
...E3355FE......
....E333E.......
....E4444E......
...E544452EE....
..E3355F2233E...
..E333333333E...
...E3333333E....
..E5544444F5EE..
..E3355F55233E..
..E3333333333E..
..EE33333333EE..
....EEEEEEEE....
................
................
```

#### coil_hop_ur_3 (16 x 24, origin (8, 23))

Hop up right, frame 3: the landing, coils spread.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `Y` Coil Eye `FFE24A`.

```
................
................
................
................
................
................
................
................
......E...E.....
......EEEEEE....
.....E221122E...
....E32F11223Y..
....E32522223E..
....E33F22233E..
....E33333333E..
...E333333333E..
.EE3544444444E..
.E33354444445E..
.E333355F5553E..
.E5533333F4455E.
E335444445F5333E
E33355F55333333E
.EEE33333333EEE.
....EEEEEEEE....
```

#### coil_fall_1 (16 x 24, origin (8, 23))

Falling, frame 1: thrown up (the hop frame 2).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
....E...E.......
.....E.EEEEE....
......E22122E...
.....E3211YY3Y..
....E332215233E.
....E333222333E.
....E33333FFFFE.
.....E3333WFWE..
....E4444444EE..
....E55444EE....
...E33255E......
....E333E.......
....E4444E......
...E544452EE....
..E3355F2233E...
..E333333333E...
...E3333333E....
..E5544444F5EE..
..E3355F55233E..
..E3333333333E..
..EE33333333EE..
....EEEEEEEE....
................
................
```

#### coil_fall_2 (16 x 24, origin (8, 23))

Falling, frame 2: upside down.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `F` Ember Deep `B0242C`; `W` Fang `FFF4E8`; `Y` Coil Eye `FFE24A`.

```
..EE44444444EE..
.E333333333333E.
E33333252233333E
.E355F54555533E.
..E4444444445E..
..E333333333E...
.E33355F23333E..
..E354445223E...
...E444445EE....
...E33333E......
...E32223E......
...E32155E......
....E25444EE....
.....E444444E...
.....E3333WFWE..
....E33333FFFFE.
....E333222333E.
....E332215233E.
.....E3211YY3Y..
......E22122E...
.....E.EEEEE....
....E...E.......
................
................
```

#### coil_fall_3 (16 x 24, origin (8, 23))

Falling, frame 3: small and far.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Coil row (`A79CB2`, `726880`, `4A4156`, `2E2838`, `15101C`); `E` Ember `FF5A36`; `Y` Coil Eye `FFE24A`.

```
................
................
................
................
................
................
................
......EEEE......
.....E2112E.....
....E322Y23E....
....E333333E....
.....E3333E.....
......E44E......
....EE5555EE....
....E332233E....
....E333333E....
....E544445E....
...E33555533E...
...E33333333E...
....EEEEEEEE....
................
................
................
................
```

## 6. The Thorn and the Frost

Both 10 x 10, origin (5, 9), the bottom middle. **A quick glance cannot mix them up**: red and spiky with eyes against pale blue, smooth eight sided, with a white star and no eyes; and the seed is a dark egg with a red rim. The colour check (13) shows them apart in all three kinds of colour blindness and in grey scale (the Frost is the lightest thing that moves, the seed the darkest).

### 6.1 The Thorn

#### thorn_1 (10 x 10, origin (5, 9))

The Thorn, bounce frame 1: squash.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Thorn row (`F6A4AA`, `F16973`, `EC3442`, `A42533`, `581624`); `B` Pupil `1E0E26`; `W` Fang `FFF4E8`.

```
..........
....23....
....34....
..555555..
35W1222354
353B33B354
.54444445.
..555555..
....44....
....45....
```

#### thorn_2 (10 x 10, origin (5, 9))

The Thorn, bounce frame 2: round, spikes out.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Thorn row (`F6A4AA`, `F16973`, `EC3442`, `A42533`, `581624`); `B` Pupil `1E0E26`; `W` Fang `FFF4E8`.

```
....23....
....34....
...5555...
..5W1225..
2351223534
335B33B544
..533345..
...5555...
....44....
....45....
```

#### thorn_3 (10 x 10, origin (5, 9))

The Thorn, bounce frame 3: stretch.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Thorn row (`F6A4AA`, `F16973`, `EC3442`, `A42533`, `581624`); `B` Pupil `1E0E26`; `W` Fang `FFF4E8`.

```
....23....
...5555...
..5W1225..
..512235..
235B33B534
3453333544
..533345..
..543445..
...5555...
....45....
```

### 6.2 The Frost

#### frost_1 (10 x 10, origin (5, 9))

The Frost, bounce frame 1: squash.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Frost row (`FFFFFF`, `D6F6FF`, `9EE6FF`, `4FAFE0`, `22609A`).

```
..........
..........
..555555..
.52332335.
5333133345
5311111145
5323123345
5333133345
.54444445.
..555555..
```

#### frost_2 (10 x 10, origin (5, 9))

The Frost, bounce frame 2: the whole crystal.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Frost row (`FFFFFF`, `D6F6FF`, `9EE6FF`, `4FAFE0`, `22609A`).

```
...5555...
..533335..
.52312335.
5333133345
5311111145
5323123345
5333133345
.54414445.
..544445..
...5555...
```

#### frost_3 (10 x 10, origin (5, 9))

The Frost, bounce frame 3: stretch.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Frost row (`FFFFFF`, `D6F6FF`, `9EE6FF`, `4FAFE0`, `22609A`).

```
...5555...
..533335..
.52312345.
.53313345.
.53111145.
.52312345.
.53313345.
.54414445.
..544445..
...5555...
```

### 6.3 The freeze burst

Six frames of a flat ring (2 across for 1 down, like the lamps), 50 ms each, centred on the Frost's foot point (the origin is the ring's middle). Frames 5 and 6 are dotted as it fades. Drawn over the lamps, under the sprites.

#### freeze_ring_1 (24 x 13, origin (12, 6))

The freeze burst, frame 1: centred on the Frost's foot point.

Legend: `13` tones 1, 3 of the Frost row (`FFFFFF`, `9EE6FF`).

```
........................
.......1111111111.......
....1111........1111....
...111............111...
..11................11..
.11..................11.
.11..................11.
.33..................33.
..33................33..
...333............333...
....3333........3333....
.......3333333333.......
........................
```

#### freeze_ring_2 (34 x 18, origin (17, 9))

The freeze burst, frame 2: centred on the Frost's foot point.

Legend: `13` tones 1, 3 of the Frost row (`FFFFFF`, `9EE6FF`).

```
..................................
...........111111111111...........
........1111..........1111........
.....1111................1111.....
....111....................111....
...11........................11...
..11..........................11..
.111..........................111.
.11............................11.
.11............................11.
.333..........................333.
..33..........................33..
...33........................33...
....333....................333....
.....3333................3333.....
........3333..........3333........
...........333333333333...........
..................................
```

#### freeze_ring_3 (44 x 23, origin (22, 11))

The freeze burst, frame 3: centred on the Frost's foot point.

Legend: `24` tones 2, 4 of the Frost row (`D6F6FF`, `4FAFE0`).

```
............................................
................222222222222................
...........222222..........222222...........
........2222....................2222........
......222..........................222......
.....222............................222.....
....22................................22....
...22..................................22...
..22....................................22..
.222....................................222.
.22......................................22.
.22......................................22.
.44......................................44.
.444....................................444.
..44....................................44..
...44..................................44...
....44................................44....
.....444............................444.....
......444..........................444......
........4444....................4444........
...........444444..........444444...........
................444444444444................
............................................
```

#### freeze_ring_4 (54 x 28, origin (27, 14))

The freeze burst, frame 4: centred on the Frost's foot point.

Legend: `24` tones 2, 4 of the Frost row (`D6F6FF`, `4FAFE0`).

```
......................................................
....................22222222222222....................
...............222222............222222...............
............2222......................2222............
.........2222............................2222.........
.......222..................................222.......
......222....................................222......
....222........................................222....
...222..........................................222...
...22............................................22...
..22..............................................22..
.222..............................................222.
.22................................................22.
.22................................................22.
.22................................................22.
.44................................................44.
.444..............................................444.
..44..............................................44..
...44............................................44...
...444..........................................444...
....444........................................444....
......444....................................444......
.......444..................................444.......
.........4444............................4444.........
............4444......................4444............
...............444444............444444...............
....................44444444444444....................
......................................................
```

#### freeze_ring_5 (64 x 33, origin (32, 16))

The freeze burst, frame 5: centred on the Frost's foot point.

Legend: `3` tones 3 of the Frost row (`9EE6FF`).

```
................................................................
.........................3.3.3.3.3.3.3.3........................
....................3.3.3...............3.3.3...................
...............3.3.3.........................3.3................
............3.3.................................3.3.............
...........3.......................................3.3..........
........3.3...........................................3.........
.......3.3.............................................3........
......3.................................................3.3.....
.....3...................................................3.3....
....3.....................................................3.3...
...3.......................................................3....
..3.........................................................3...
...3.........................................................3..
..3...........................................................3.
.3...........................................................3..
..3...........................................................3.
.3...........................................................3..
..3...........................................................3.
...3.........................................................3..
..3.........................................................3...
...3.......................................................3....
....3.....................................................3.3...
.....3...................................................3.3....
......3.................................................3.3.....
.......3.3.............................................3........
........3.3...........................................3.........
...........3.......................................3.3..........
............3.3.................................3.3.............
...............3.3.3.........................3.3................
....................3.3.3...............3.3.3...................
.........................3.3.3.3.3.3.3.3........................
................................................................
```

#### freeze_ring_6 (74 x 38, origin (37, 19))

The freeze burst, frame 6: centred on the Frost's foot point.

Legend: `3` tones 3 of the Frost row (`9EE6FF`).

```
..........................................................................
.............................3.3.3.3.3.3.3.3..............................
........................3.3.3...............3.3.3.3.......................
...................3.3.3...........................3.3....................
................3.3...................................3.3.................
.............3.3.........................................3.3..............
............3...............................................3.3...........
.........3.3...................................................3..........
........3.3.....................................................3.........
.......3.........................................................3.3......
......3...........................................................3.3.....
.....3.............................................................3.3....
....3...............................................................3.3...
...3.................................................................3....
..3...................................................................3...
...3...................................................................3..
..3...................................................................3.3.
.3.....................................................................3..
..3.....................................................................3.
.3.....................................................................3..
..3.....................................................................3.
.3.3...................................................................3..
..3...................................................................3...
...3...................................................................3..
....3.................................................................3...
...3.3...............................................................3....
....3.3.............................................................3.....
.....3.3...........................................................3......
......3.3.........................................................3.......
.........3.....................................................3.3........
..........3...................................................3.3.........
...........3.3...............................................3............
..............3.3.........................................3.3.............
.................3.3...................................3.3................
....................3.3...........................3.3.3...................
.......................3.3.3.3...............3.3.3........................
..............................3.3.3.3.3.3.3.3.............................
..........................................................................
```

### 6.4 Frozen (a tint rule, no new art)

While the freeze lasts, every hunter (seed, Coil, Thorns, moths) is drawn with its **tone digits taken from the Ice row**, and its letters as Ice 5 `2C5E8C` for the dark ones (`B`, `K`, `F`, `Y`, `E`) and Ice 1 `FFFFFF` for the rest. In the last 1000 ms the tint switches off and on every 250 ms (twice a second) to warn that they will move again. See the fourth screen of `cuber-screens.png`.

## 7. Snuff and Puff, the moths

Body 12 x 12, origin (6, 11). One design, two rows: **Snuff** (left edge) uses the Snuff row, **Puff** (right edge) the Puff row; the grids below are shown with Snuff. `dr` shows the face (eyes), `ur` the back (eye spots of tone 1 on the wings). Symmetric, so the mirror for the left facings is the same picture. They have no rim and no red: they are a nuisance you can catch, not a killer.

#### moth_dr_1 (12 x 12, origin (6, 11))

A moth hopping down right (we see its face), frame 1: the crouch, wings folded down. Snuff uses the Snuff row, Puff the Puff row.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `746592`, `3E3451`); `A` Moth Eye `F4F0FF`; `K` Moth Body `5C4A6E`.

```
............
...5....5...
....5..5....
....KKKK....
....AKKA....
.5555KK5555.
512335K53215
512335K53215
523333533325
.55545K5455.
....55K55...
...5.....5..
```

#### moth_dr_2 (12 x 12, origin (6, 11))

A moth hopping down right (we see its face), frame 2: in the air, wings up. Snuff uses the Snuff row, Puff the Puff row.

Legend: `1235` tones 1, 2, 3, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `3E3451`); `A` Moth Eye `F4F0FF`; `K` Moth Body `5C4A6E`.

```
55.5....5.55
5125....5215
51235..53215
.5235KKK5325
.5335AKKA335
..555KKK555.
....5KKK5...
.....KKK....
.....KKK....
......K.....
............
....5...5...
```

#### moth_dr_3 (12 x 12, origin (6, 11))

A moth hopping down right (we see its face), frame 3: the landing, wings out (also standing). Snuff uses the Snuff row, Puff the Puff row.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `746592`, `3E3451`); `A` Moth Eye `F4F0FF`; `K` Moth Body `5C4A6E`.

```
...5....5...
....5..5....
....KKKK....
55..AKKA..55
5135.KK.5315
51335KK53315
52335KK53325
.5545KK5455.
..515KK515..
..535KK535..
...5.KK.5...
....5..5....
```

#### moth_ur_1 (12 x 12, origin (6, 11))

A moth hopping up right (we see its back and the eye spots on its wings), frame 1.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `746592`, `3E3451`); `K` Moth Body `5C4A6E`.

```
............
...5....5...
....5..5....
....KKKK....
....KKKK....
.5555KK5555.
512335K53215
512135K53215
523313533325
.55545K5455.
....55K55...
...5.....5..
```

#### moth_ur_2 (12 x 12, origin (6, 11))

A moth hopping up right (we see its back and the eye spots on its wings), frame 2.

Legend: `1235` tones 1, 2, 3, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `3E3451`); `K` Moth Body `5C4A6E`.

```
55.5....5.55
5125....5215
51235..53215
.5215KKK5325
.5335KKKK135
..555KKK555.
....5KKK5...
.....KKK....
.....KKK....
......K.....
............
....5...5...
```

#### moth_ur_3 (12 x 12, origin (6, 11))

A moth hopping up right (we see its back and the eye spots on its wings), frame 3.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Snuff row (`DDD4F1`, `C7B8E8`, `B4A0E0`, `746592`, `3E3451`); `K` Moth Body `5C4A6E`.

```
...5....5...
....5..5....
....KKKK....
55..KKKK..55
5135.KK.5315
51135KK53315
52315KK53325
.5545KK5455.
..515KK515..
..535KK535..
...5.KK.5...
....5..5....
```

Use `dr` for a down right hop and its mirror for down left, `ur` for up right and its mirror for up left, as for Pip. Standing is frame 3. When a moth lands on a lamp, the lamp goes back one state at once (repainted) and four motes of the moth's tone 2 drop from it (section 9).

## 8. Halos

Picture 24 x 12 (lift off 24 x 16), origin (12, 6), the middle of the hole, which is where Pip's feet go. The ring is lit on its far side (tone 2) and shaded on its near side (tones 4 and 5); a band of white runs round it a quarter turn a frame.

#### halo_1 (24 x 12, origin (12, 6))

A halo waiting, frame 1: a band of light runs round the ring (a quarter turn a frame).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......2222222222.......
....2222222222222222....
..22222222222222222222..
.2222222........2222222.
333333............333333
33333..............33333
53333..............33335
554444............WW4455
.5444444........1WWWWW1.
..55444444444441111W11..
....5554444444411555....
.......5555555555.......
```

#### halo_2 (24 x 12, origin (12, 6))

A halo waiting, frame 2: a band of light runs round the ring (a quarter turn a frame).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......2222222222.......
....2222222222222222....
..22222222222222222222..
.2222222........2222222.
333333............333333
33333..............33333
53333..............33335
554411............444455
.511111W........4444445.
..551WWWW4444444444455..
....111WW44444444555....
.......1555555555.......
```

#### halo_3 (24 x 12, origin (12, 6))

A halo waiting, frame 3: a band of light runs round the ring (a quarter turn a frame).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......1222222222.......
....1111122222222222....
..11W11112222222222222..
.1WWWWW1........2222222.
3333WW............333333
33333..............33333
53333..............33335
554444............444455
.5444444........4444445.
..55444444444444444455..
....5554444444444555....
.......5555555555.......
```

#### halo_4 (24 x 12, origin (12, 6))

A halo waiting, frame 4: a band of light runs round the ring (a quarter turn a frame).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......2222222221.......
....22222222222WW111....
..2222222222222WWWW111..
.2222222........W111111.
333333............113333
33333..............33333
53333..............33335
554444............444455
.5444444........4444445.
..55444444444444444455..
....5554444444444555....
.......5555555555.......
```

#### halo_lift_1 (24 x 16, origin (12, 6))

A halo lifting off, frame 1: streaks of light below (24 x 16, origin (12, 6) still).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......2222222222.......
....2222222222222222....
..22222222222222222222..
.2222222........2222222.
333333............333333
33333..............33333
53333..............33335
554444............WW4455
.5444444........1WWWWW1.
..55444444444441111W11..
....5554444444411555....
.......5555555555.......
.....3...3....3...3.....
.....3...3....3...3.....
.....4...4....4...4.....
........................
```

#### halo_lift_2 (24 x 16, origin (12, 6))

A halo lifting off, frame 2: longer, dotted streaks. Played in turn while it flies.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Halo row (`FFFFFF`, `C8F4FF`, `6ED2F2`, `2F86B6`, `17406A`); `W` Spark `FFFFFF`.

```
.......1222222222.......
....1111122222222222....
..11W11112222222222222..
.1WWWWW1........2222222.
3333WW............333333
33333..............33333
53333..............33335
554444............444455
.5444444........4444445.
..55444444444444444455..
....5554444444444555....
.......5555555555.......
................3...3...
...3...3...3............
................4...4...
...4...4...4............
```

#### halo_gone (24 x 12, origin (12, 6))

A halo used up: a dotted ghost of the ring in the darkest tone (for 2 seconds, then nothing).

Legend: `5` tones 5 of the Halo row (`17406A`).

```
........5.5.5.5.5.......
.....5...........5.5....
..5.................5...
.5......................
5.....................5.
.......................5
5.......................
.5.....................5
......................5.
...5.................5..
....5.5...........5.....
.......5.5.5.5.5........
```

## 9. Effects

### 9.1 Sprites

#### puff_1 (10 x 3, origin (5, 1))

The landing puff, frame 1 (10 x 3), centred on the foot point. Tones 1 and 2 of the lamp's new state (Mint shown).

Legend: `12` tones 1, 2 of the new state's row.

```
..2....2..
.1......1.
..........
```

#### puff_2 (10 x 3, origin (5, 1))

The landing puff, frame 2 (10 x 3), centred on the foot point. Tones 1 and 2 of the lamp's new state (Mint shown).

Legend: `12` tones 1, 2 of the new state's row.

```
.2......2.
1........1
..........
```

#### puff_3 (10 x 3, origin (5, 1))

The landing puff, frame 3 (10 x 3), centred on the foot point. Tones 1 and 2 of the lamp's new state (Mint shown).

Legend: `12` tones 1, 2 of the new state's row.

```
2........2
..........
1........1
```

### 9.2 Score pop ups

The 5 x 7 font at 1x, Gold `FFD247` with a 1 pixel Outline, centred on the thing that scored, its top 26 pixels above the foot point. It rises 1 pixel every 50 ms for 8 pixels, holds 300 ms, shows in Label `9C8EC4` for the last 150 ms, then goes. 25 (a lamp done), 50 (each halo left at the end, shown on the halo before it goes), 100 (a Frost), 300 (a moth caught), 500 (the Coil following Pip off the edge, shown at the spot it fell from, at 2x).

### 9.3 The effects list

| Effect | Verdict | Recipe |
|---|---|---|
| Flash and sparkle when a lamp is done | keep | glint_1 50 ms, glint_2 100 ms, glint_3 100 ms over the lamp; the lamp itself is repainted done at once |
| The ripple on a level clear | keep | section 3.3 |
| A trail of 3 dim pixels behind a hop | keep, small | from hop frame 3 to 10, at Pip's three last foot points (one every 2 frames): pixels of Pip 2, Pip 4, Pip 4, each living 100 ms |
| A soft shadow under Pip | keep | section 3.5 |
| Squash and stretch on every bounce | keep | the frame lists of 4 to 7 do it: crouch, air, land |
| Flash the HUD target when the last lamp is done | keep | the mini lamp draws in Spark `FFFFFF` for 100 ms, back for 100 ms, Spark for 100 ms |
| Falling sparks when anything leaves the edge | keep | 6 particles from the point it left: start 2 pixels apart, fall 1 to 3 pixels a frame, colours tone 2 of its row then tone 4, live 400 ms |
| A ring when a Frost goes off | keep | section 6.3 |
| A slow drift of stars or lights | keep | 4 far lanterns (2 x 3 Lantern, a Lantern Dim pixel each side of the middle row and a 2 pixel tail under) rise 1 pixel every 200 ms and wrap from y 216 to y 36; 4 bright stars twinkle (swap to Star Dim for 150 ms, one every 700 ms in turn) |
| Discs pulsing | changed | the white band running round the halo does the job and reads better than a pulse |
| Motes falling into the void (added) | add | 10 motes (2 pixels tall, Mote `35264E`) under the pyramid, rows 226 to 255, fall 1 pixel every 80 ms and wrap: the void is a fall, not a floor |
| A blink every few seconds (added) | add | when Pip stands still: every 3000 to 5000 ms, blink_1 50 ms, blink_2 100 ms, blink_1 50 ms |
| Light spilling down a lit lamp (added) | add | part of the lamp picture (the lips), no extra cost |
| Moth dust (added) | add | when a moth undoes a lamp: 4 motes of its tone 2 fall from the lamp top 1 pixel a frame for 300 ms |
| Screen shake | drop | not affordable, and the death flash says it |

## 10. Animation recipes and timings

| What | Frames and timing | Pixels that change |
|---|---|---|
| Pip hop (any direction) | 12 frames (200 ms). Frame f (1 to 12), t = f / 12. Position = start + (end - start) t, minus `round(48 t (1 - t))` in y (12 high at the top). Frames 1 to 2 hop_1 (and Pip stays on the start point for those 2), 3 to 10 hop_2, 11 to 12 hop_3, then stand. dr art for down right and down left (mirrored), ur for up right and up left (mirrored). Puff on landing. | Pip 12 x 14 twice (old and new place) plus the shadow, about 400 |
| Pip stand | stand_dr after a down hop, stand_ur after an up hop (mirrored for the left ones). Blink as 9.3. | none |
| Pip falls off the front (a down hop off the edge) | the hop goes on past t = 1 with no landing: y speed grows by 0.35 a frame. fall_1 to fall_3 for 100 ms each, then fall_4 until the feet pass y = 260. Falling sparks from the edge point. | about 170 a frame |
| Pip falls off the back (an up hop off the edge) | fall_4 only, and stop drawing when the feet are 8 pixels below the edge of the lamp it left: it drops behind the hill | about 100 a frame |
| Pip is hit | hit_1, hit_2, hit_3, hit_4, twice, 80 ms each (640 ms), then the death flash (300 ms), then READY on the apex | 170 a frame |
| Pip rides a halo | Pip on halo_lift (alternating 100 ms) from the halo spot to 16 pixels above the apex foot point in a straight line over 1200 ms; ride_1 and ride_2 swap every 150 ms. Then Pip lands on the apex (hop_3 for 2 frames) and the halo is gone (halo_gone for 2000 ms at its spot, then nothing). | about 500 a frame |
| Pip wins (level clear) | win_1 and win_2 every 150 ms (win_2 drawn 4 pixels higher) for the whole ripple | 170 |
| Seed, Thorn, Frost bounce | a hop as Pip's (12 frames, 10 high): frame 3 (stretch) at f 1 to 2, frame 2 (round) f 3 to 10, frame 3 f 11, frame 1 (squash) f 12 and 4 frames more on the lamp | 100 |
| Seed hatches | on the bottom row: hatch_1 300 ms, hatch_2 200 ms, then the Coil stands | 100 |
| Coil hop | as Pip's, 12 frames, 10 high: hop_1 f 1 to 2, hop_2 f 3 to 10, hop_3 f 11 to 12, then stand | 16 x 24 twice, about 750 |
| Coil falls (following Pip off the edge) | fall_1, fall_2 100 ms each, then fall_3 until it leaves the canvas, with falling sparks in Ember; the 500 pop at the edge | 380 |
| Moth hop | as Pip's: frame 1 f 1 to 2, frame 2 f 3 to 10, frame 3 f 11 onwards (also its standing frame) | 150 |
| Halo waiting | halo_1 to halo_4, 120 ms each, looping | about 40 a frame |
| Lamp done | repaint, glint (9.3), pop | up to 3 lamp pictures once |
| Freeze | ring 6 x 50 ms; the tint for the freeze time; warning in the last 1000 ms | the ring and the frozen sprites |

## 11. Screens

All text is the 5 x 7 font. "Centred" means `x = floor((256 - width) / 2)` with `width = n * 6k - k` for n characters at scale k.

### 11.1 The HUD (every game screen)

| Item | Text or sprite | Colour | x, y |
|---|---|---|---|
| Label | SCORE, 1x | Label `9C8EC4` | 8, 4 |
| Score | 6 digits, 2x | Text `F4F0FA` | 8, 13 (to 77, 26) |
| High score | `HI` 1x then 6 digits 1x, one space between | HI in Label, digits in Text | centred as one 9 character string: x 101, y 4 (digits at x 119) |
| Lives | pip_icon, one for each life in hand (not the one in play), up to 5 | its own | y 16, 10 apart, the row centred: first x = 128 - (10 n - 2) / 2 |
| Level | `LEVEL` 1x, then the number 1x | Label, number in Text | 182, 4; number at 218, 4 |
| Round | `ROUND` 1x, then the number | Label, number in Text | 182, 16; number at 218, 16 |
| Target | lamp_mini in the round's Done row | its own | top left 232, 8 |
| Rule | the HUD Rule line | `2C2250` | row 31 |

Text in the HUD needs no outline (it sits on HUD `0C0818`); text on the play area always has the 1 pixel Outline.

### 11.2 Title and attract (`cuber-preview-title.png`)

| Item | Text or sprite | Colour | x, y |
|---|---|---|---|
| High score | as the HUD | as the HUD | 101, 4 |
| Title | LAMPLIGHTER, 3x, with Outline | gradient Title Top `FFF4C0` to Title Bottom `FF9A4E` | centred: x 30, y 16 (to y 36) |
| The pyramid | all unlit, Mint theme, two halos (left and right of row 4) |  | section 3.4 |
| Pip | the intro (below) |  | from the apex |
| Press space | PRESS SPACE, 2x, Outline | Gold `FFD247` | centred: x 63, y 228; shown 600 ms, hidden 400 ms |
| Keys | ARROWS HOP   P PAUSE, 1x | Label | centred: x 68, y 246 |

**The intro** (the first five seconds): the title is drawn one letter every 60 ms, left to right, each letter dropping 4 pixels into place over 3 frames. Then Pip lands on the apex from above (hop_2 then hop_3) and hops down the middle, (1, 0), (2, 1), (3, 1), (4, 2), (5, 2), (6, 3), (7, 3), one hop every 500 ms, lighting each lamp with its glint. At the bottom it turns to face the player (stand_dr, a blink) and the ripple runs once over the lit path. After 4 seconds of quiet the path goes dark (one lamp per 60 ms from the bottom) and the intro starts again. About 600 pixels change at the busiest frame.

**Keys** (a proposal; the brief does not fix them): the arrows as the pyramid seen at 45 degrees: Up = up right, Right = down right, Down = down left, Left = up left; the number pad 9, 3, 1, 7 for the same. P pauses, Space starts.

### 11.3 READY, PAUSED, level clear, game over, new high score

A **banner plate** is a full width band of Plate `0C0818` with a 1 pixel Plate Rule `6ED2F2` as its top and bottom rows.

| Screen | Plate rows | Text | Colour | x, y | Timing |
|---|---|---|---|---|---|
| READY | 112 to 135 | READY, 2x | Text | centred, y 117 | 1500 ms at the start of every life; Pip already on the apex |
| PAUSED | 112 to 143 | PAUSED 2x; P TO PLAY 1x | Text; Label | centred, y 116; centred, y 134 | while paused; everything else stops |
| Level clear | none | the ripple (3.3), Pip winning; then ROUND n or LEVEL n, 2x, on a plate at 112 to 135 for 1000 ms | Gold | centred, y 117 | about 3 seconds in all |
| GAME OVER | 100 to 155 | GAME OVER, 3x | gradient Over Top `FFB0A0` to Over Bottom `EC3442` | centred: x 48, y 108 | the game frozen under it; 4000 ms, then the title |
| New high score | (on the GAME OVER plate) | NEW HIGH SCORE 1x; the score 1x | Gold; Text | centred, y 136; centred, y 146 | NEW HIGH SCORE shown 500 ms, hidden 250 ms. Without a new best the plate shows only SCORE 004325 in Text at y 140 |
| Extra life | none | a pop up 1UP at the HUD lives row | Gold | over the new icon | as a score pop up |

## 12. Later levels

Shown in `cuber-themes.png`, one row per theme.

- **Three hop lamps**: unlit, then **half** (the ring), then **done** (the core). Shown above in 3.2. All four themes keep the order dark, middle, bright (luminance in 13).
- **Undo lamps** (levels where a hop on a lit lamp turns it back): the same lamps with a **dotted rim**, every other row of the outer rim swapped: light dots on an unlit or half lamp, dark dots (tone 5) on a lit one. The dots tell the player "this one can go back" without colour.
#### lamp_undo (32 x 32): an unlit lamp that can turn back

Legend: `1` to `5` the Unlit row (the dots are tone 1); faces as lamp_unlit.

```
..............2222..............
............22333322............
..........113333333311..........
........2233333333333322........
......11333333333333333311......
....223333333333333333333322....
..1133333333333333333333333311..
22333333333333333333333333333322
11333333333333333333333333333311
LL4433333333333333333333333344RR
LLLL113333333333333333333311RRRR
MMLLLL44333333333333333344RRRRSS
MMMMLLLL1133333333333311RRRRSSSS
MMMMMMLLLL443333333344RRRRSSSSSS
MMMMMMMMLLLL11333311RRRRSSSSSSSS
MMMMMMMMMMLLLL4444RRRRSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

#### lamp_undo_done (32 x 32): a lit lamp that can turn back

Legend: `1` to `5` the theme's Done row (the dots are tone 5); faces as lamp_done.

```
..............2222..............
............22333322............
..........553333333355..........
........2233333333333322........
......55333333222233333355......
....223333332222222233333322....
..5533333322222222222233333355..
22333333222211111111222233333322
55333333222211111111222233333355
LL4433333322222222222233333344RR
LLLL553333332222222233333355RRRR
MMLLLL44333333222233333344RRRRSS
MMMMLLLL5533333333333355RRRRSSSS
MMMMMMLLLL443333333344RRRRSSSSSS
MMMMMMMMLLLL55333355RRRRSSSSSSSS
MMMMMMMMMMLLLL4444RRRRSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

- **A flipping lamp** (optional, later): one frame, the top squashed to 8 rows and the lit underside showing as a band (`D` the theme's Done 3). Play: unlit, this frame for 60 ms, its own mirror (rows of the top reversed) for 60 ms, the new state.
#### lamp_flip (32 x 32)

Legend: `1` to `5` the Unlit row; `D` the theme's Done tone 3; faces as lamp_unlit.

```
................................
................................
................................
................................
............22222222............
........3333333333333333........
....333333333333333333333333....
33333333333333333333333333333333
33333333333333333333333333333333
LL..333333333333333333333333..RR
LLLL....3333333333333333....RRRR
MMLLLL......44444444......RRRRSS
MMMMDDDDDDDDDDDDDDDDDDDDDDDDSSSS
MMMMMMDDDDDDDDDDDDDDDDDDDDSSSSSS
MMMMMMMMDDDDDDDDDDDDDDDDSSSSSSSS
MMMMMMMMMMDDDDDDDDDDDDSSSSSSSSSS
MMMMMMMMMMMMLLLLRRRRSSSSSSSSSSSS
MMMMMMMMMMMMMMLLRRSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
MMMMMMMMMMMMMMMMSSSSSSSSSSSSSSSS
NNMMMMMMMMMMMMMMSSSSSSSSSSSSSSTT
NNNNMMMMMMMMMMMMSSSSSSSSSSSSTTTT
NNNNNNMMMMMMMMMMSSSSSSSSSSTTTTTT
EENNNNNNMMMMMMMMSSSSSSSSTTTTTTEE
..EENNNNNNMMMMMMSSSSSSTTTTTTEE..
....EENNNNNNMMMMSSSSTTTTTTEE....
......EENNNNNNMMSSTTTTTTEE......
........EENNNNNNTTTTTTEE........
..........EENNNNTTTTEE..........
............EENNTTEE............
..............EEEE..............
```

- **A bonus round** (a suggestion): the lamps are dark, the sky is the Void Deep colour, and a dozen halos float over the pyramid at random lamp foot points; Pip has 20 seconds to hop on as many as it can (each one 100) with no enemies. It reuses every picture in this file.

## 13. Checks

- **Every sprite fits its size**, every pixel is `.` or in its legend, no legend has more than 16 entries: passed. Sizes: Pip and its frames 12 x 14; the seed, the Thorn, the Frost 10 x 10; the moths 12 x 12; the Coil's picture 16 x 24 with its 12 x 14 hit box (5.2); halos 24 x 12 (24 x 16 lifting).
- **The lamps tile exactly** on the brief's pitch (only the edge line is covered, 3.2), and every sprite's origin goes on the middle of the top diamond (3.4).
- **The lamp states in grey scale** (relative luminance of the base tone, unlit / half / done):

| Theme | Unlit | Half | Done |
|---|---|---|---|
| MINT | 0.058 | 0.218 | 0.662 |
| ROSE | 0.058 | 0.130 | 0.415 |
| SKY | 0.058 | 0.138 | 0.542 |
| LILAC | 0.058 | 0.129 | 0.475 |

Each step is at least 2 times brighter than the one before, and the patterns (plain, ring, core) differ too.

- **Things that must not be confused**, the smallest colour distance (redmean, 0 to about 765) between Pip, the Coil, the Ember rim, the Thorn, the Frost, the two moths and the halos, per vision:

| Vision | Smallest distance | Between |
|---|---|---|
| normal | 84 | Ember and Thorn 3 |
| deuteranopia | 59 | Ember and Thorn 3 |
| protanopia | 60 | Frost 3 and Halo 3 |
| tritanopia | 36 | Pip 3 and Puff 3 |

The closest pairs are kept apart by shape: the Ember rim is a 1 pixel line round a dark serpent, the Thorn a filled red ball; the Frost is a filled crystal, a halo a ring with a hole; Pip is round with eyes and feet, Puff has wings.

- **Against the ground** (contrast ratio of a thing's base, and of the edge where it has one, against the sky, an unlit, a half and a lit lamp):

| Thing | Dusk A | Dusk C | Unlit 3 | Mint Half 3 | Mint 3 |
|---|---|---|---|---|---|
| Pip 3 | 11.8 | 12.9 | 6.7 | 2.7 | 1.0 |
| Pip 5 | 1.2 | 1.3 | 1.5 | 3.7 | 9.7 |
| Coil 3 | 1.8 | 1.9 | 1.0 | 2.5 | 6.5 |
| Ember | 5.5 | 6.0 | 3.1 | 1.3 | 2.1 |
| Thorn 3 | 4.2 | 4.6 | 2.4 | 1.0 | 2.8 |
| Frost 3 | 12.3 | 13.5 | 7.0 | 2.8 | 1.1 |
| Frost 5 | 2.6 | 2.9 | 1.5 | 1.7 | 4.4 |
| Snuff 3 | 7.3 | 8.0 | 4.2 | 1.7 | 1.6 |
| Puff 3 | 9.9 | 10.8 | 5.6 | 2.3 | 1.2 |
| Halo 3 | 9.8 | 10.8 | 5.6 | 2.3 | 1.2 |

Where a base is close to a ground (Pip on a lit lamp, the Coil on an unlit one, a Thorn on a half one) the edge carries it: Pip's tone 5 edge is 9.7 against a lit Mint top, the Coil's Ember rim 3.1 against an unlit top and 5.5 against the sky, the Thorn's tone 5 edge is dark on every pale top. Check this by eye in `cuber-colour-check.png`.

- **Text**: Text on HUD 17.6, Label on HUD 6.7, Gold on HUD 13.7, Text on Plate 17.6, Gold on Plate 13.7, Over Bottom on Plate 4.8, Gold on Outline 13.9, Label on Void Top 6.7, Title Bottom on Outline 9.5.
- **Nothing changes the whole screen every frame**: the biggest change is the ripple, one lamp top per 40 ms.
- **Colour blindness**: `cuber-colour-check.png`, the in game screen, the freeze screen and the swatches as drawn, then deuteranopia, protanopia and tritanopia (Machado 2009 matrices), then grey scale.

## 14. What I decided, and what is open

- **Name**: Lamplighter (the hero lights lamps). Characters Pip, the seed, the Coil, Thorns, Frosts, Snuff and Puff, halos. Nothing is named after the original.
- **Canvas**: 256 x 256 and the brief's cube numbers, unchanged. Halos are 4 pixels from their row (the hop landing point decides that), not 8.
- **Direct colour PixelCanvas**, not palette indexed cells.
- **The light changes every round**, not every level, so each level shows all four themes. The level sets the rules. If you would rather the theme follow the level, nothing in the art changes, only which row the HUD and the lamps use.
- **One rule I would add** (optional): the brief does not say how a fall off the back looks; I draw it as dropping behind the hill (10, fall off the back).
- **Scores**: unchanged from the brief.
- **Open**: the keys (11.2 is a proposal); whether the moths should hop on the side faces like true sideways hoppers (I keep them on the tops, standing on the edge lamps, which reads more clearly at this size); the bonus round; the class names (suggest `LamplighterLook`, `LamplighterArt`, `LamplighterPalette` instead of Cuber*); an ABL art generator is not written.

## 15. The generator

`cuber-generator/` (Python 3 and Pillow). `python run_all.py` writes this file and every `cuber-*.png` into the folder above it. `palette.py` holds every colour, `scene.py` the lamps, the layout and the sky, `sprites.py` every sprite, `preview.py` the screens, `check.py` the checks, `doc.py` this file.
