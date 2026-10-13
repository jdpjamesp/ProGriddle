# Space Invaders: art and screen design, "Neon Afterglow"

Designer's answer to the brief. Everything below is meant to be pasted into code with no further decisions. Where I disagree with the brief or changed a number, it is listed in section 5.

## 0. Read this first

Assumptions (tell me if any is wrong and I will redo the affected numbers):

- Origin is top left, x across, y down, in cells, on the 224 x 256 grid.
- The simulation runs at 60 ticks a second. Timings are given in ticks with the seconds beside them. If your tick rate differs, scale the ticks.
- Text uses the 5 x 7 capital font with 1 cell of spacing. A character advances 6 cells at 1x, 12 at 2x and 18 at 3x, so a string of n characters at scale s is `n * 6s - s` cells wide. Centred strings below use `x = floor((224 - width) / 2)`.
- Sprite tones: `.` empty, `#` main colour, `+` second colour, `*` third colour. Every sprite header says what the three tones are for that sprite.
- No sprite has a halo. The format only has three tones and I spend the third on shading (see section 5, note 4).
- A sprite's solid body is every non-`.` cell, exactly as in the placeholder art. Nothing is bigger than the arcade size.

What is in the file:

1. Art direction and palette
2. Sprites (42 pictures in 19 families, every one with its size; the six shield chip masks stay as they are)
3. Screen layouts: in game, title, wave intro, wave cleared, game over, and the first five seconds
4. Effects: keep, drop, add, with numbers
5. What I changed from the brief, and why
6. Sprite index and a map from the old 34 pictures to the new names

## 1. Art direction and palette

### Idea

**Neon Afterglow.** It is the arcade cabinet remembered at night: a deep indigo sky that warms to violet at the horizon, and invaders that look lit from above, with a pale rim light on the crown and a deeper shade on the legs. The five invader rows run as a sunset ramp from hot pink at the top to cyan at the bottom, so a row is recognisable by colour and a type by silhouette. Your own side is cool and clean (mint cannon, mint shields, white-cyan shots). Warm colours are reserved for things that want your attention: bombs, the saucer, explosions and gold scores. When the screen is busy you only ever have to track warm things falling and cool things below.

### Colour rules

- Invaders: cool only (pink, orchid, periwinkle, azure, cyan). Each is lit from above: `+` pale on the crown and eyes, `#` body, `*` deeper on the limbs.
- Bombs: warm only, each kind its own hue (amber, red-orange, lemon) plus its own silhouette, so you never have to tell them apart by colour alone.
- Player: mint green for the cannon, mint-to-green for shields, white-cyan for the shot.
- Rack colours rotate by wave (see section 2.1), so a wave never looks like the one before.
- Sky stays dark. Nothing in the background is brighter than `34124F`, so sprites keep their contrast.

### Palette (about 60 named colours; gradients are computed per row)

Sky and ground

| Name | Hex | Used for |
|---|---|---|
| Night Top | `06051A` | sky at y = 0 |
| Night Horizon | `1D0B3A` | sky at y = 231. Row y is the linear blend of Night Top and Night Horizon at y / 231 |
| Underworld | `0A0814` | everything from y = 234 down |
| Ground Line | `3CE6A0` | the ground line, y = 232 |
| Ground Glow 1 | `1A6A60` | y = 231 |
| Ground Glow 2 | `13454F` | y = 230 |
| Ground Glow 3 | `1C2150` | y = 229 |
| Ground Under | `0E3A38` | y = 233 |
| Star Dim | `4A5088` | slow, far stars |
| Star Bright | `C9D2FF` | medium stars |
| Star Cyan | `7FE7FF` | fast, near stars |
| Star Twinkle | `FFFFFF` | the twinkle frame of a bright star |
| Nebula Violet | `4B1D7A` | optional nebula blob A |
| Nebula Blue | `1D3F7A` | optional nebula blob B |

Invader rows (the three tones of each row; `#` main, `+` light rim and eyes, `*` deep limbs)

| Row | Type | `#` main | `+` light | `*` deep |
|---|---|---|---|---|
| 1 | squid | `FF4FA8` Hot Pink | `FFD6EC` | `B02E78` |
| 2 | crab | `D060FF` Orchid | `F3D4FF` | `8A33C0` |
| 3 | crab | `8F7BFF` Periwinkle | `DCD6FF` | `5546C4` |
| 4 | octopus | `4AA8FF` Azure | `D2ECFF` | `2468C8` |
| 5 | octopus | `3DE8FF` Cyan | `DDFCFF` | `1FA0C8` |

Player

| Name | Hex | Used for |
|---|---|---|
| Cannon Main | `5CFF8A` | cannon `#` |
| Cannon Light | `F2FFF6` | cannon `+` (barrel core) |
| Cannon Deep | `1FA860` | cannon `*` (base) |
| Cannon Ghost | `BFFFD4` | respawn blink outline |
| Shield Top | `8CFFC8` | shield, row 0 |
| Shield Bottom | `1FA868` | shield, row 15 |
| Shield Flash | `E8FFF4` | shield shimmer and chip sparks |
| Shot Head | `FFFFFF` | shot `+` |
| Shot Body | `A8F6FF` | shot `#` |
| Shot Tail | `4FB6D6` | shot `*` |

Enemy extras (all warm)

| Name | `#` | `+` | `*` |
|---|---|---|---|
| Saucer | `FF3B5C` | `FFE14D` lights | `A81F3C` underbelly |
| Bomb squiggle | `FFB13D` | `FFF2C4` | `A8561C` |
| Bomb plunger | `FF5238` | `FFD9CC` | `9E2A1A` |
| Bomb roller | `F5FF5A` | `FFFFE0` | `8E9420` |
| Cannon blast | `5CFF8A` | `FFFFFF` | `FF9A3D` embers |
| Saucer blast | `FF3B5C` | `FFFFFF` | `FFE14D` gold sparks |

Saucer body pulse (the `#` of the saucer cycles, 8 ticks per step): `FF3B5C`, `FF5A7A`, `FF3B5C`, `E0284A`.

Text and screens

| Name | Hex | Used for |
|---|---|---|
| Text White | `FFFFFF` | numbers and words |
| Label Cyan | `7FE7FF` | SCORE, HI-SCORE, WAVE, table heading |
| Dim Text | `7F8DB0` | "=" and secondary words |
| Credit Text | `4A5088` | the bottom credit line |
| Gold | `FFE14D` | saucer score pop-up, "?", GET READY, new hi-score |
| Gold Fade | `A8872A` | last frames of the pop-up |
| Title Top | `FF7AD0` | SPACE and INVADERS, top row of the letters |
| Title Bottom | `6A5CFF` | SPACE and INVADERS, bottom row of the letters |
| Title Shadow | `2A1470` | drop shadow of the title (+1, +1) |
| Light Bar End | `3DE8FF` | right end of the underline |
| Over Top | `FF5A5A` | GAME OVER, top row |
| Over Bottom | `C8207A` | GAME OVER, bottom row |
| Over Shadow | `2A0B24` | GAME OVER drop shadow |
| Clear Top | `5CFF8A` | WAVE CLEARED, top row |
| Clear Bottom | `3DE8FF` | WAVE CLEARED, bottom row |
| HUD Rule | `2A2060` | optional hairline under the HUD |
| Text Outline | `06051A` | 1 cell outline behind overlay text drawn over the rack |

Gradient text: row r of n letter rows (r from 0) is the linear blend of the top and bottom colours at r / (n - 1).

### Background recipes

**A (recommended, what you have plus a ground glow).** Per row: Night Top to Night Horizon, then the four ground rows above, then Underworld.

**B (optional nebula, baked once at game start, never touched per frame).** For each cell, strength `s` from two soft blobs, then `colour = blend(sky(y), nebulaColour, s)`:

- Blob A: centre (60, 90), radii (70, 40), colour Nebula Violet, peak strength 0.35.
- Blob B: centre (170, 150), radii (60, 36), colour Nebula Blue, peak strength 0.28.
- For each blob, `d = sqrt(((x - cx) / rx)^2 + ((y - cy) / ry)^2)`; if `d < 1` then `s = peak * (1 - d^2)^2`, else 0.

I would ship B only if the sprites still read clearly on it; check the cannon lane (y 216 to 231) first, which B leaves untouched.

## 2. Sprites

Rules for all sprites: every row of a block has exactly the width in its heading, and there are exactly as many rows as the height. Frames are separate blocks named `name_0`, `name_1`, and so on.

### 2.1 Invaders

Tones for all invader pictures and their blasts: take the row's three tones from the "Invader rows" table. `#` body, `+` lit rim and eyes, `*` deep limbs.

Colour changes: by row (fixed table), by wave (wave `w` uses the five row colours rotated by `(w - 1) mod 5`, so wave 2 has orchid on row 1, then periwinkle, azure, cyan, pink on row 5, and the triple travels with its colour), and not by time. Eyes and rims do not animate. The frame swap is the animation.

Silhouettes are the arcade ones, so the 16 cell spacing and the hit sizes are unchanged. What is new: glowing eyes, a lit crown, deep limbs that make the legs read as darker than the body, and a stronger leg swing between frames.

#### squid_0 (8 x 8)
Row 1, 30 points. Frame 0, legs together.
```
...++...
..####..
.######.
##+##+##
########
..*..*..
.*.**.*.
*.*..*.*
```

#### squid_1 (8 x 8)
Frame 1, legs have marched one row down and spread.
```
...++...
..####..
.######.
##+##+##
########
.*.**.*.
*.*..*.*
*......*
```

#### crab_0 (11 x 8)
Rows 2 and 3, 20 points. Frame 0, claws down, antenna tips lit.
```
..+.....+..
...#...#...
..#######..
.##+###+##.
###########
*.#######.*
*.#.....#.*
...**.**...
```

#### crab_1 (11 x 8)
Frame 1, claws up.
```
..+.....+..
*..#...#..*
*.#######.*
*##+###+##*
###########
.#########.
..*.....*..
.*.......*.
```

#### oct_0 (12 x 8)
Rows 4 and 5, 10 points. Frame 0, tentacles in.
```
....++++....
.##########.
############
###++##++###
############
...**..**...
..**.**.**..
**........**
```

#### oct_1 (12 x 8)
Frame 1, tentacles out.
```
....++++....
.##########.
############
###++##++###
############
..***..***..
.**..**..**.
..**....**..
```

### 2.2 Cannon, respawn blink, lives icon

#### cannon (13 x 8)
`#` Cannon Main, `+` Cannon Light (the barrel core, a 3 cell glowing line), `*` Cannon Deep (the base row).
```
......+......
.....#+#.....
.....#+#.....
.###########.
#############
#############
#############
*************
```

#### cannon_ghost (13 x 8)
Respawn blink frame. Only `+` is used, in Cannon Ghost. Alternate `cannon` and `cannon_ghost` every 6 ticks for 90 ticks (1.5 s) after the blast. It is a hollow outline of the same silhouette, so the eye reads it as a ghost of the cannon. Cosmetic only; hit tests use whatever your rules say about respawn.
```
......+......
.....+.+.....
.....+.+.....
.+++++++++++.
+...........+
+...........+
+...........+
+++++++++++++
```

#### lives (11 x 6)
The small cannon for the HUD. Same three tones as `cannon`.
```
.....+.....
....###....
.#########.
###########
###########
***********
```

### 2.3 Saucer

`#` Saucer body (pulses, see palette), `+` lights (Gold), `*` underbelly. Two frames, swapped every 8 ticks, so the lights chase.

#### saucer_0 (16 x 7)
```
.....######.....
...##########...
..############..
.##+##+##+##+##.
################
..***..**..***..
...*........*...
```

#### saucer_1 (16 x 7)
```
.....######.....
...##########...
..############..
.###+##+##+##+#.
################
..***..**..***..
...*........*...
```

### 2.4 Shield

#### shield (22 x 16)
Same bunker silhouette as the placeholder, so every hit test and chip mask you have still fits. Body only, `#` for every cell. The colour is by row: row `r` (0 to 15) is the blend of Shield Top and Shield Bottom at `r / 15`. A cell keeps its colour when its neighbours are chewed away, so a chewed shield always looks like a lit slab with bites out of it.

Variant A (preferred): the pure gradient above.
Variant B: the same gradient with every odd row multiplied by 0.92, which gives faint scanlines. Prettier when intact, a little busier when chewed.
```
....##############....
...################...
..##################..
.####################.
######################
######################
######################
######################
######################
######################
######################
######################
#######........#######
######..........######
#####............#####
#####............#####
```

### 2.5 Bombs (all 3 x 7)

For all bombs: `#` main colour, `+` pale head (the last row, or the crossbar), `*` deep tail (the top two rows, so the bomb reads as a comet falling). Colours per kind are in the palette. Play the four frames in order at 4 ticks per frame.

The three kinds were too alike in the placeholder (two were diagonal zigzags). Now: the **squiggle** is a one cell wave, the **plunger** is a stick with a crossbar that slides up and down it, and the **roller** is a chain of plus signs and diamonds that scrolls like a rolling tyre.

#### squiggle_0 (3 x 7)
```
.*.
..*
.#.
#..
.#.
..#
.+.
```

#### squiggle_1 (3 x 7)
```
..*
.*.
#..
.#.
..#
.#.
+..
```

#### squiggle_2 (3 x 7)
```
.*.
*..
.#.
..#
.#.
#..
.+.
```

#### squiggle_3 (3 x 7)
```
*..
.*.
..#
.#.
#..
.#.
..+
```

#### plunger_0 (3 x 7)
Crossbar high.
```
.*.
+++
.#.
.#.
.#.
.#.
.+.
```

#### plunger_1 (3 x 7)
Crossbar in the middle.
```
.*.
.*.
.#.
+++
.#.
.#.
.+.
```

#### plunger_2 (3 x 7)
Crossbar low.
```
.*.
.*.
.#.
.#.
.#.
+++
.+.
```

#### plunger_3 (3 x 7)
Same as `plunger_1` (the bar travels back up). Listed so the code can loop four frames.
```
.*.
.*.
.#.
+++
.#.
.#.
.+.
```

#### roller_0 (3 x 7)
```
.*.
***
.#.
#.#
.#.
###
.+.
```

#### roller_1 (3 x 7)
```
***
.*.
#.#
.#.
###
.#.
+.+
```

#### roller_2 (3 x 7)
```
.*.
*.*
.#.
###
.#.
#.#
.+.
```

#### roller_3 (3 x 7)
```
*.*
.*.
###
.#.
#.#
.#.
+++
```

### 2.5b Player shot

#### shot (1 x 6)
Recommended. `+` head Shot Head, `#` body Shot Body (rows 1 to 3), `*` tail Shot Tail (rows 4 and 5). The body for hit tests is rows 0 to 3, the same 1 x 4 as now; the two tail cells are cosmetic and may be skipped by hit tests. The tail is only painted over sky cells, never over a shield or invader, so it cannot leave a stray mark on them.
```
+
#
#
#
*
*
```

#### shot_b (3 x 6)
Variant with a side glow. Same tones. The `*` cells beside the body are cosmetic and only painted over sky cells. I like it less: with no blending, a glow beside the shot looks like part of the shot once it passes close to an invader.
```
.+.
.#.
*#*
*#*
.*.
.*.
```

### 2.6 Explosions and hits

#### blast_0 (13 x 8)
Alien explosion, frame 0 (ticks 0 to 3). `#` the dead invader's row colour, `+` white, `*` the row's deep tone. A starburst with a white core.
```
......+......
.#....+....#.
..#..+++..#..
...#+++++#...
...#+++++#...
..#..+++..#..
.#....+....#.
......+......
```

#### blast_1 (13 x 8)
Frame 1 (ticks 4 to 7): scattering shards.
```
..#.......#..
#...#...#...#
...+.....+...
.#.........#.
.#.........#.
...+.....+...
#...#...#...#
..#.......#..
```

#### blast_2 (13 x 8)
Frame 2 (ticks 8 to 11): fading embers, in `*`.
```
.*.........*.
.............
*...........*
.............
.............
*...........*
.............
.*.........*.
```

#### cblast_0 (16 x 8)
Cannon explosion, frame 0 (ticks 0 to 8): a white flash. `#` Cannon Main, `+` white, `*` embers (`FF9A3D`).
```
...*....#....*..
.#....*..*....#.
....#.+++.#.....
*..#.+++++.#..*.
..#.+++++++.#...
.*.#.+++++.#.*..
...#.#+++#.#....
..*#########*...
```

#### cblast_1 (16 x 8)
Frame 1. Alternates with frame 2 every 6 ticks from tick 9 to tick 44.
```
.*....#...*.....
....*..#....*...
.#...+...+..#...
...#..+++..#..*.
*...+++++++..#..
..#.++#+#++.#.*.
.*..#.####.#....
...*#########...
```

#### cblast_2 (16 x 8)
Frame 2.
```
................
..*.......*.....
.....*...*....*.
.*..#....*.#....
...*.#*..*..#.*.
..#.*..##..*.#..
.*.##.*##*.##.*.
..###########...
```

#### cblast_3 (16 x 8)
Frame 3: rubble and low embers, ticks 45 to 110 (then the cannon respawns). Swap two of the `*` cells between rows 4 and 5 every 8 ticks for a flicker.
```
................
................
.*..........*...
................
....*......*....
..*....**....*..
.....#.**.#.....
..##.######.##..
```

#### topburst_0 (8 x 8)
Shot hits the top, frame 0 (6 ticks). `#` Shot Body, `+` white, `*` Shot Tail.
```
#..##..#
.#.++.#.
..#++#..
###++###
###++###
..#++#..
.#.++.#.
#..##..#
```

#### topburst_1 (8 x 8)
Frame 1 (6 ticks).
```
*......*
.*....*.
........
...++...
...++...
........
.*....*.
*......*
```

#### splat_0 (8 x 4)
Bomb lands on the ground, frame 0 (4 ticks). Use the tones of the bomb that landed. Draw it so its bottom row sits on y = 231.
```
.#.++.#.
#.####.#
.######.
..####..
```

#### splat_1 (8 x 4)
Frame 1 (6 ticks).
```
*......*
.*.**.*.
..#..#..
.#.##.#.
```

#### sblast_0 (16 x 7)
Saucer explosion, frame 0 (6 ticks). `#` Saucer red, `+` white, `*` gold sparks.
```
.....#.++.#.....
..#.##.++.##.#..
.#.####++####.#.
#.#####++#####.#
.#.####++####.#.
..#.##.++.##.#..
.....#.++.#.....
```

#### sblast_1 (16 x 7)
Frame 1 (8 ticks).
```
..*.....#....*..
.#....*....#....
*...#..++..#...*
...#...++...#...
*...#..++..#...*
.#....*....#....
..*.....#....*..
```

#### sblast_2 (16 x 7)
Frame 2 (10 ticks). Gold sparks only. After it, the score pop-up takes over (section 4).
```
................
.*..........*...
................
*....*....*....*
................
.*..........*...
................
```

#### chip_spark_0 (7 x 5)
Shield chip debris, centred on the cell that was hit, 4 ticks. `#` the shield colour of that row, `+` Shield Flash.
```
.#...#.
#..+..#
..#.#..
.#...#.
#.....#
```

#### chip_spark_1 (7 x 5)
4 ticks.
```
.......
#.....#
...+...
#.....#
.......
```

Shield chip masks (the brief's pictures 29 to 34) are not art, so I left them exactly as they are.

## 3. Screen layouts

Drawing order, back to front: sky (and optional nebula), stars, ground, shields, invaders, bombs, the player shot, the cannon, particles, HUD and overlay text. **Stars must never paint over text or sprites.** In the title screenshot the drifting stars sit on top of the letters of INVADERS and of SCORE ADVANCE TABLE; skip any star cell that a foreground layer covers.

### 3.1 In game

| Item | Content | Colour | x | y | Rows used |
|---|---|---|---|---|---|
| SCORE label | `SCORE` | Label Cyan | 8 | 6 | 6 to 12 |
| Score value | 5 digits, zero padded | Text White | 8 | 16 | 16 to 22 |
| HI-SCORE label | `HI-SCORE` | Label Cyan | 88 | 6 | 6 to 12 |
| Hi-score value | 5 digits | Text White | 97 | 16 | 16 to 22 |
| WAVE label | `WAVE` | Label Cyan | 193 | 6 | 6 to 12 |
| Wave value | right aligned so its last cell is x = 215 | Text White | 205 for two digits, 199 for three | 16 | 16 to 22 |
| HUD rule (optional) | one cell line, every other cell lit | HUD Rule | 8 to 215 | 27 | 27 |
| Saucer lane | `saucer`, flies left to right or right to left | see palette | -16 to 224 | 32 | 32 to 38 |
| Shot hits the top | `topburst` centred on the shot | see palette | shot x - 4 | 26 | 26 to 33 |
| Rack | unchanged | | 16 cell grid | | |
| Shields | `shield` | gradient | 35 + 44 * k (k = 0 to 3) | 184 | 184 to 199 |
| Cannon | `cannon` | | 8 to 203 | 216 | 216 to 223 |
| Ground glow | 3 rows | Ground Glow 3, 2, 1 | 0 to 223 | 229 to 231 | |
| Ground line | one cell | Ground Line | 0 to 223 | 232 | 232 |
| Ground under | one cell | Ground Under | 0 to 223 | 233 | 233 |
| Lives number | 1 digit | Text White | 8 | 241 | 241 to 247 |
| Lives icons | `lives` | | 18 + 16 * k | 241 | 241 to 246 |

Changes from the brief: the WAVE label moves from 179 to 193 and its number is right aligned, so the right margin matches the 8 cell margin on the left and the cannon's 8 to 215 travel. The lives icon is 6 tall and moves from y = 240 to 241, so its middle lines up with the middle of the 7 tall number.

### 3.2 Title and attract screen

The HUD stays as in 3.1 with the current score and hi-score.

| Item | Content | Colour | x | y |
|---|---|---|---|---|
| Title shadow | `SPACE` and `INVADERS`, 3x | Title Shadow | 69 and 42 | 45 and 71 |
| SPACE | 3x | gradient Title Top to Title Bottom over its 21 rows | 68 | 44 |
| INVADERS | 3x | the same gradient, restarted for this line | 41 | 70 |
| Light bar | one row, left to right gradient Title Top, Title Bottom, Light Bar End | | 41 to 181 | 95 |
| Light bar shadow | one row | `2A2A6A` | 41 to 181 | 96 |
| Heading | `SCORE ADVANCE TABLE` | Label Cyan | 55 | 108 |
| Saucer row | `saucer_0` and `saucer_1`, 2 Hz | saucer tones | 70 | 124 |
| Squid row | `squid_0` and `squid_1`, row 1 tones | | 74 | 138 |
| Crab row | `crab_0` and `crab_1`, row 2 tones | | 72 | 152 |
| Octopus row | `oct_0` and `oct_1`, row 5 tones | | 72 | 166 |
| Equals signs | `=` | Dim Text | 94 | 124, 138, 152, 166 |
| Points tokens | `?`, `30`, `20`, `10`. The `?` sits in the second character column (x = 112). The two digit values start at x = 106 | `?` Gold; 30 Hot Pink; 20 Orchid; 10 Cyan | 106 | 124, 138, 152, 166 |
| Words | `MYSTERY`, `POINTS` (three times) | Text White | 124 | 124, 138, 152, 166 |
| Press space | `PRESS SPACE`, 1x, blinks 36 ticks on, 24 off | Gold | 79 | 200 |
| Credit | `PROGRIDDLE COOKOFF`, 1x | Credit Text | 58 | 241 |

The table words line up in one column (x = 124) for all four rows, which the current screen also does.

### 3.3 Wave intro ("get ready"), about 2.2 seconds, 130 ticks

1. Tick 0: sky, stars, ground and HUD are drawn. The cannon sits at x = 8 and blinks (`cannon`, `cannon_ghost`, every 6 ticks).
2. Ticks 0 to 28: the shields build upward one row per tick, one shield starting every 4 ticks (shield k starts at tick 4k).
3. Ticks 10 to 65: the rack is built one invader per tick, bottom row first, each row left to right. A new invader is drawn all in `+` for 3 ticks, then in its true tones. This is the arcade's build up.
4. Ticks 0 to 130: `WAVE n` at 2x with a gradient from Title Top to Title Bottom, centred at y = 150: x = 77 for a one digit wave number and x = 71 for two digits. Beneath it, `GET READY` at 1x in Gold at x = 85, y = 170, blinking 8 ticks on and 8 off. Both are drawn with a 1 cell Text Outline, so they stay legible when a late wave rack reaches that height.
5. Tick 130: the cannon goes solid, the text disappears and play starts.

### 3.4 Wave cleared, about 1.5 seconds, 90 ticks

1. Tick 0: everything freezes for 20 ticks. The last invader's blast has played out.
2. Ticks 20 to 90: the ground line flashes white for 6 ticks, then a 12 cell wide bright segment (Text White) sweeps along it from left to right at 8 cells a tick, leaving Ground Line colour behind it.
3. Ticks 20 to 90: `WAVE CLEARED` at 2x, gradient Clear Top to Clear Bottom, at x = 41, y = 100. Letters pop in one per 2 ticks, left to right.
4. Ticks 50 to 90: `NEXT WAVE n` at 1x in Label Cyan at x = 79 (one digit; subtract 3 for each extra digit), y = 120.
5. Tick 90: the wave intro (3.3) starts.

### 3.5 Game over

| Item | Content | Colour | x | y |
|---|---|---|---|---|
| Shadow | `GAME OVER`, 2x | Over Shadow | 60 | 101 |
| GAME OVER | 2x, gradient Over Top to Over Bottom over its 14 rows | | 59 | 100 |
| Score line | `SCORE ` in Label Cyan, then 5 digits in Text White (11 characters) | | 79 | 124 |
| New record | `NEW HI-SCORE`, only when beaten, blinking 10 ticks on, 10 off | Gold | 76 | 138 |
| Press space | `PRESS SPACE`, 36 ticks on, 24 off, starts 90 ticks after the screen appears | Gold | 79 | 164 |

For the first 30 ticks the ground line flashes Over Top. The rack stays frozen where it was. Letters pop in as on the title, one per 3 ticks.

### 3.6 The first five seconds (title intro, 260 ticks)

All of it is cheap: it only ever paints a few new cells per tick.

| Tick | What happens |
|---|---|
| 0 to 20 | Sky and ground only. Stars fade in: each star appears at a random tick in this range. |
| 20 to 90 | The 13 title letters pop in one at a time, 5 ticks apart: SPACE left to right, then INVADERS left to right. A new letter is drawn all white for 2 ticks, then in its gradient. The drop shadow appears with it. |
| 90 to 110 | The light bar sweeps from left to right, 7 cells a tick. |
| 110 to 150 | `SCORE ADVANCE TABLE` types out, one character every 2 ticks. |
| 150 to 222 | The table rows appear one at a time, 18 ticks apart: sprite pops in all in `+` for 3 ticks, then the `=`, the token and the word type in. |
| 222 | `PRESS SPACE` starts to blink. |
| After 8 seconds idle | An octopus (row 5 tones) walks along y = 205 from left to right, one cell every 4 ticks, then the saucer crosses the saucer lane once. Loop with a 10 second pause. |

## 4. Effects: keep, drop, add

All numbers are per effect. Cost assumes "cells changed per tick".

**Keep**

1. **Starfield with parallax and twinkle.** 48 stars in three layers: 16 Star Dim at 1 cell every 6 ticks, 20 Star Bright at 1 every 3, 12 Star Cyan at 1 every 2. Four of the Star Bright ones twinkle: swap to Star Twinkle for 4 ticks every 40 to 90 ticks (random per star). Skip star cells under any text or sprite.
2. **Particle burst when an invader dies.** 12 particles in the invader's tones. Start velocity `vx` random in [-1.2, 1.2] cells a tick, `vy` in [-1.4, 0.6], gravity 0.06 a tick, life 16 to 24 ticks. Colour steps through `+`, then `#`, then `*`, then gone, a quarter of its life each. Cap total particles at 64.
3. **White flash on the cannon when hit.** `cblast_0` already starts with a white core; also draw the cannon's old cells in `+` for 2 ticks before the blast.
4. **Saucer colour cycling.** The pulse in the palette, 8 ticks a step. Plus the chasing lights in `saucer_0` and `saucer_1`.
5. **Shield shimmer on a hit.** When a cell is chewed, every surviving shield cell within 2 cells of it is drawn in Shield Flash for 3 ticks, then in its row colour. About 20 cells.
6. **HUD score pulse on a big hit.** Saucer kills only: the score digits go Gold for 24 ticks, then White. 5 digits.
7. **Ground line reacts to a bomb landing.** The 13 ground cells around the impact flash in the bomb's `#` colour for 6 ticks, then back, along with `splat`.
8. **Saucer score pop-up.** Gold text where the saucer died, rising one cell every 3 ticks for 45 ticks, switching to Gold Fade for the last 6.

**Drop**

- **Glow under the shots as a halo.** With no blending, a halo reads as part of the shot or of the thing it passes. The cosmetic tail in `shot` gives the same speed cue for 2 cells.
- **Anything that touches every cell** (moving gradient, screen shake), as you said.

**Add**

1. **Muzzle flash.** When the cannon fires, draw a 5 cell plus shape in white (`+` at the barrel tip and the four cells around it) for 3 ticks. 5 cells.
2. **Last invader panic.** When one invader is left, it alternates between its true tones and all `+` every 6 ticks. 1 sprite.
3. **Danger pulse.** When the bottom of the lowest invader reaches y = 176 or lower (8 cells above the shields), the ground line pulses between Ground Line and Over Top at 2 Hz. 224 cells, but only on a colour change, twice a second.
4. **Wave cleared sweep** (3.4): the bright segment travelling along the ground line.
5. **Title and game over letters pop in** (3.5 and 3.6): a few cells a tick.

## 5. What I changed from the brief, and why

1. **WAVE moved and right aligned** (3.1): the right margin was 22 cells against 8 on the left. This is a layout suggestion; keep 179 if you prefer.
2. **Lives icons at y = 241** with a new 11 x 6 picture (the brief put them at 240).
3. **Stars behind the text.** Visible in the screenshot, a one line fix, and the biggest quality win on the title screen for no art cost.
4. **No halo, third tone spent on shading.** The three tone format means a halo would cost the deep shade. I think the shade does more for readability at 3x than a halo would. If you want a ring, I would add it for the cannon and the saucer only.
5. **Bombs redrawn.** Two of the placeholder bombs were both diagonal zigzags. Now each has its own silhouette (wave, T-bar, chain) and its own hue.
6. **Four animation frames for the cannon blast, three for the alien blast.** The placeholder had two each; the extra frames are the main thing that makes a kill feel like it counts.
7. **Centred coordinates.** I used the font arithmetic in section 0 for the heading (x = 55, you have 52) and GAME OVER (x = 59, you have 61). If your font has a different advance, keep your numbers; the rest of the layout does not depend on them.
8. **Shields and shield chip masks unchanged.** The silhouette is already right; the gain is in the colour and the shimmer.

## 6. Sprite index

| Name | Size | Frames | `#` | `+` | `*` |
|---|---|---|---|---|---|
| squid | 8 x 8 | 2 | row tone | row tone | row tone |
| crab | 11 x 8 | 2 | row tone | row tone | row tone |
| oct | 12 x 8 | 2 | row tone | row tone | row tone |
| cannon | 13 x 8 | 1 | Cannon Main | Cannon Light | Cannon Deep |
| cannon_ghost | 13 x 8 | 1 | none | Cannon Ghost | none |
| lives | 11 x 6 | 1 | Cannon Main | Cannon Light | Cannon Deep |
| saucer | 16 x 7 | 2 | pulse | Gold | Saucer underbelly |
| shield | 22 x 16 | 1 | gradient by row | none | none |
| squiggle | 3 x 7 | 4 | `FFB13D` | `FFF2C4` | `A8561C` |
| plunger | 3 x 7 | 4 | `FF5238` | `FFD9CC` | `9E2A1A` |
| roller | 3 x 7 | 4 | `F5FF5A` | `FFFFE0` | `8E9420` |
| shot | 1 x 6 | 1 | Shot Body | Shot Head | Shot Tail |
| shot_b | 3 x 6 | 1 | Shot Body | Shot Head | Shot Tail |
| blast | 13 x 8 | 3 | row tone | white | row deep |
| cblast | 16 x 8 | 4 | Cannon Main | white | `FF9A3D` |
| topburst | 8 x 8 | 2 | Shot Body | white | Shot Tail |
| splat | 8 x 4 | 2 | bomb tone | bomb pale | bomb deep |
| sblast | 16 x 7 | 3 | Saucer red | white | Gold |
| chip_spark | 7 x 5 | 2 | shield row tone | Shield Flash | none |

Map from the brief's 34 pictures to the new names:

| Brief | New |
|---|---|
| 1, 2 | `squid_0`, `squid_1` |
| 3, 4 | `crab_0`, `crab_1` |
| 5, 6 | `oct_0`, `oct_1` |
| 7 | `cannon` (plus new `cannon_ghost`, `lives`) |
| 8 | `saucer_0`, `saucer_1` |
| 9 | `shield` |
| 10 to 13 (rolling) | `roller_0` to `roller_3` (redrawn) |
| 14 to 17 (plunger) | `plunger_0` to `plunger_3` |
| 18 to 21 (squiggly) | `squiggle_0` to `squiggle_3` |
| 22 | `shot` (new 1 x 6) |
| 23, 24 | `blast_0` to `blast_2` |
| 25, 26 | `cblast_0` to `cblast_3` |
| 27 | `topburst_0`, `topburst_1` (8 x 8) |
| 28 | `splat_0`, `splat_1` (8 x 4) |
| 29 to 34 | unchanged (shield chip masks); new `chip_spark_0`, `chip_spark_1` |
