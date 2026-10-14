# Tetris: art and screen design, "Lantern Glass"

Designer's answer to `snake-tetris-art-brief.md`. It is meant to be pasted into code with no further decisions. Snake has its own file, `snake-art.md`, with the same art direction. Where I disagree with the brief or chose between options, it is listed in section 8. Previews: `tetris-preview.png` (in game, start up, pause, game over, at 3x) and `tetris-colour-check.png` (the seven pieces under three kinds of colour blindness).

## 0. Read this first

Conventions used everywhere below:

- The canvas is 272 x 320 pixels. Origin top left, x across, y down, in pixels. The well is `x 0 to 159`, the divider `x 160 to 175`, the panel `x 176 to 271`. A well cell `(col, row)` has its top left pixel at `(16 * col, 16 * row)`, col 0 to 9, row 0 (top) to 19.
- **Tile format**: as in the brief. `.` is transparent, `1` to `5` are the tones of a colour row (1 highlight, 5 edge), letters `A` to `H` have their own colour in the legend. Every tile is 16 x 16.
- **Draw order (back to front)**: 1 the baked background (gradient, panel dots, floor cells, walls, divider, cards), 2 level up sweep line, 3 settled blocks, 4 ghost, 5 the falling piece, 6 effects (trail, sparks), 7 HUD text, 8 banners. A later draw replaces an earlier one, so the ghost never covers a block (draw it only on empty cells) and the piece covers the ghost.
- **Text** is the 5 x 7 font, one pixel between letters. A character advances 6 pixels at 1x and 12 at 2x, so `n` characters at scale `k` are `n * 6k - k` pixels wide. "Centred in the well" means `x = floor((160 - width) / 2)`.
- **Time** is given in milliseconds, with the 60 a second frames beside it where that helps. Nothing here needs a frame rate; round to your own.

What is in the file:

1. Art direction and palette
2. Tiles: block and marks, ghost, floor, wall, divider, panel
3. Animations: lock, hard drop, line clear, Tetris, level up, game over, pause, start up
4. Screens: in game, pause, game over, start up, new best
5. Effects: keep, drop, add
6. Budgets
7. Checks
8. What I decided and why

## 1. Art direction and palette (shared by Snake and Tetris)

### Idea

**Lantern Glass.** Two games at night, lit by one lamp. The picture is the dark navy of the Cookoff launcher, and everything you play with is a small piece of lacquered glass: a block or a segment with a bright edge on the top left, a soft shade on the bottom right and a single specular glint, as if a lantern hung above and to the left of the screen. The jewel colours are saturated but never neon: teal, gold, amethyst, leaf, vermilion, cobalt and tangerine for the pieces; jade for the snake; vermilion for the apple. The only thing that is "the lamp" is **amber** (`FFA24A`), the Cookoff accent: it is the level number, the NEXT label, the rules of every banner and the four corner lamps of the snake board. There is no pink, violet-on-indigo or cyan glow (Space Invaders) and no near black with warm white lines (Asteroids). The result is warm, clean and a little toy-like, the way a modern remake of a classic should be.

### What is shared on purpose, and what differs

- **Shared**: the navy background and its gradient (`0A0E16` to `0E131E`), the light from the top left, the five tone ramp (highlight, light, base, shade, edge), the panel cards, the text colours, the amber accent, the Gold of "good news", the vermilion-to-amber of "bad news" (GAME OVER), the 5 x 7 font with a 1 pixel `Outline`, the way every banner is a dark plate with two amber rules.
- **Different**: Tetris is hard-edged and architectural (square bevelled blocks, a marked engraving on each piece, a ruled well). Snake is soft and organic (round tubes, a rounded head, a round apple, a checkerboard floor). Tetris has seven hues; Snake has two (jade, vermilion).

### Palette

Tones: every colour row below is five values from lightest (1) to darkest (5). Tone 3 is the base. Tones 1 and 2 are mixes of the base with white (70 percent and 30 percent), tones 4 and 5 are mixes of the base with `05080F` (32 percent and 64 percent). A new colour row can be made the same way.

**Background, text and frames (both games)**

| Name | Hex | Used for |
|---|---|---|
| Night Top | `0A0E16` | canvas background at y = 0, and the HUD strip of Snake |
| Night Bottom | `0E131E` | the background at the last row. Row y is the blend of Night Top and Night Bottom at y / (height - 1). Baked once |
| Dot | `121A29` | a faint 1 pixel dot every 16 pixels in the Tetris panel background (baked, `x = 184 + 16k`, `y = 8 + 16m`) |
| Panel Fill | `0E1420` | inside every card and the NEXT box |
| Frame Outer | `2D3D5F` | the outer 1 pixel line of a card, banner plate rules in Snake |
| Frame Inner | `1F2B44` | the inner 1 pixel line of a card, and the rule under the Snake HUD |
| Gap | `080C13` | the dark gap of the divider, and the fill of every banner plate |
| Text | `EEF2F8` | numbers and words |
| Label | `7C8AA2` | SCORE, LINES, LENGTH and similar labels, and the key hints |
| Dim | `9AA8BE` | the best score number, secondary lines on a banner |
| Accent | `FFA24A` | the lamp: NEXT, the level number, banner rules, the Snake corner lamps |
| Gold | `FFC857` | always means good news: a new best, a Tetris, a score pulse, YOU WIN |
| Over Top | `FFB27A` | GAME OVER, top row (gradient to Over Bottom) |
| Over Bottom | `E4503C` | GAME OVER, bottom row (same as the Z piece and the apple on purpose: red means danger) |
| Outline | `070A10` | a 1 pixel outline drawn behind any text that sits on play |
| Flash | `FFFFFF` | a hit or lock flash, and the first colour of every spark |

Gradient text: row `r` of `n` letter pixel rows (r from 0) is the blend of the top and bottom colours at `r / (n - 1)`. A 2x letter has 14 pixel rows, a 3x letter 21.

**Tetris well, divider and panel**

| Name | Hex | Used for |
|---|---|---|
| Floor Top | `0B111B` | empty cell, row 0. Row `r` (0 to 19) is the blend of Floor Top and Floor Bottom at `r / 19`. Baked |
| Floor Bottom | `101A2B` | empty cell, row 19 |
| Floor Grid | blend of the row's floor colour and `FFFFFF` at 3.5 percent | the 1 pixel line on the right and bottom of an empty cell |
| Wall High | `3A4C70` | the outer pixel of the left and bottom wall, and the divider's first-but-one column |
| Wall Low | `26344F` | the inner pixel of the left and bottom wall, the divider's first column |
| Ghost Line | `4F6288` | the outline of the ghost tile |
| Ghost Hatch | `222F4A` | the diagonal hatch inside the ghost tile |

**The seven pieces** (tone 3 is the colour you remember; the engraved mark is in section 2.2)

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge |
|---|---|---|---|---|---|
| I Teal | `BFEDE5` | `6BD6C2` | `2BC4A8` | `1F8877` | `134C46` |
| O Gold | `FCEEC6` | `F8D67B` | `F5C542` | `A88932` | `5B4C21` |
| T Amethyst | `E1D3F4` | `B997E6` | `9B6BDB` | `6B4B9A` | `3B2C58` |
| S Leaf | `D7EEC9` | `A3D780` | `7BC64A` | `558937` | `2F4C24` |
| Z Vermilion | `F7CAC4` | `EC8476` | `E4503C` | `9D392E` | `55221F` |
| J Cobalt | `C5D5F6` | `799DE9` | `3F73E0` | `2C519D` | `1A2F5A` |
| L Tangerine | `FBDCC3` | `F6AE74` | `F28C38` | `A6622B` | `5A381E` |

**Dead blocks** (the game over fill)

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge |
|---|---|---|---|---|---|
| Dead | `C7CAD0` | `7B8291` | `434D62` | `2F3747` | `1B212D` |

**Gold ramp** (a Tetris, score pulse): `FFFFFF`, then the tones of Gold `FFC857`:

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge |
|---|---|---|---|---|---|
| Gold | `FFEECD` | `FFD889` | `FFC857` | `AF8B40` | `5F4D29` |


## 2. Tiles

### 2.1 The block

One tone map serves all seven pieces; each piece has its own **engraved mark** on top of it (section 2.2) and its own colour row. The bevel is the house style: a 1 pixel edge (tone 5), a highlight band on the top and left (tones 1 and 2), a shade band on the bottom and right (tone 4), a lighter upper half of the face (tone 2) for the gloss, and a 3 pixel specular glint (tone 1) at `(4, 4)`.

#### block_blank (16 x 16, tone map, no mark)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112222222445
5122122222222445
5122222222222445
5123333333333445
5123333333333445
5123333333333445
5123333333333445
5123333333333445
5123333333333445
5124444444444445
5144444444444445
5555555555555555
```

Colour row: any row of the piece table. Used on its own only for the dead blocks of the game over (with the Dead row) and as the base of the seven tiles below.

### 2.2 The seven pieces and their marks

Each mark is **engraved**: tone 5 for the groove and a tone 1 echo one pixel down and to the right for the lit lip. The marks are chosen so no two share a direction or a shape, and they are all 2 pixels thick or more, so each reads at 2x. They are also the letters of the game where that is cheap: the J and L marks are the letters.

| Piece | Colour row | Mark | What it is (in the 16 x 16 tile) |
|---|---|---|---|
| I | Teal | horizontal slot | 2 pixels high, `x 4 to 11`, `y 7 to 8` |
| O | Gold | inset square | a 6 x 6 outline, `x 5 to 10`, `y 5 to 10` |
| T | Amethyst | plus | arms 2 pixels thick, `x 4 to 11` and `y 4 to 11` |
| S | Leaf | slash `/` | a 2 pixel diagonal from `(4, 11)` up to `(11, 4)` |
| Z | Vermilion | backslash `\` | a 2 pixel diagonal from `(4, 4)` down to `(11, 11)` |
| J | Cobalt | hook `J` | stem `x 9 to 10`, `y 4 to 11`; foot `y 10 to 11`, `x 4 to 10` |
| L | Tangerine | hook `L` | stem `x 5 to 6`, `y 4 to 11`; foot `y 10 to 11`, `x 5 to 11` |

The tile is chosen by the view code (1 to 7 = I O T S Z J L). Every tile uses only `1` to `5` and `.`: no other letters.

#### block_I (16 x 16, colour row Teal)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112222222445
5122122222222445
5122222222222445
5123555555553445
5123555555551445
5123311111111445
5123333333333445
5123333333333445
5123333333333445
5124444444444445
5144444444444445
5555555555555555
```

#### block_O (16 x 16, colour row Gold)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112222222445
5122155555522445
5122251111512445
5123351333513445
5123351333513445
5123351333513445
5123355555513445
5123331111113445
5123333333333445
5124444444444445
5144444444444445
5555555555555555
```

#### block_T (16 x 16, colour row Amethyst)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112552222445
5122122551222445
5122222551222445
5123555555553445
5123555555551445
5123311551111445
5123333551333445
5123333551333445
5123333311333445
5124444444444445
5144444444444445
5555555555555555
```

#### block_S (16 x 16, colour row Leaf)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112222252445
5122122222551445
5122222225511445
5123333355113445
5123333551133445
5123335511333445
5123355113333445
5123551133333445
5123311333333445
5124444444444445
5144444444444445
5555555555555555
```

#### block_Z (16 x 16, colour row Vermilion)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122552222222445
5122155222222445
5122225522222445
5123333553333445
5123333355333445
5123333335533445
5123333333553445
5123333333351445
5123333333331445
5124444444444445
5144444444444445
5555555555555555
```

#### block_J (16 x 16, colour row Cobalt)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122112225522445
5122122225512445
5122222225512445
5123333335513445
5123333335513445
5123333335513445
5123555555513445
5123555555513445
5123311111113445
5124444444444445
5144444444444445
5555555555555555
```

#### block_L (16 x 16, colour row Tangerine)
```
5555555555555555
5111111111111115
5122222222222245
5122222222222445
5122155222222445
5122155122222445
5122255122222445
5123355133333445
5123355133333445
5123355133333445
5123355555553445
5123355555551445
5123331111111445
5124444444444445
5144444444444445
5555555555555555
```

### 2.3 Ghost

A hollow, hatched outline: the floor shows through, so it can never be taken for a block. Legend: `D` Ghost Line `4F6288`, `H` Ghost Hatch `222F4A`. The four corner pixels are left out so it reads as a rounded frame.

#### block_ghost (16 x 16)
```
.DDDDDDDDDDDDDD.
D..............D
D.H...H...H....D
D....H...H...H.D
D...H...H...H..D
D..H...H...H...D
D.H...H...H....D
D....H...H...H.D
D...H...H...H..D
D..H...H...H...D
D.H...H...H....D
D....H...H...H.D
D...H...H...H..D
D..H...H...H...D
D..............D
.DDDDDDDDDDDDDD.
```

### 2.4 Floor, walls, divider

**Empty cell** (`floor_r`, row `r`): 15 x 15 pixels of the floor colour for that row (`F`) with the last column and the last row in Floor Grid (`G`). The floor colour for row `r` is the blend of Floor Top and Floor Bottom at `r / 19`; Floor Grid is that colour mixed with white at 3.5 percent. The cell fights nothing: it is darker than every block tone and the grid is barely lighter than the floor.

#### floor_r (16 x 16, legend `F` = floor colour, `G` = Floor Grid)
```
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
FFFFFFFFFFFFFFFG
GGGGGGGGGGGGGGGG
```

**Walls.** The brief fixes the well at 160 pixels, which leaves no room for a wall of tiles, so the walls are lines drawn into the baked background: the **left wall** is two columns, `x = 0` in Wall High and `x = 1` in Wall Low, over all 320 rows; the **bottom wall** is two rows, `y = 318` in Wall Low and `y = 319` in Wall High, over `x 0 to 159`. A block drawn at column 0 or row 19 covers them (later draw wins), and its own tone 5 edge then forms the boundary. The **right wall** is the divider.

**Divider** (`x 160 to 175`, the full 320 rows, one column of pixels repeated down the screen): the colour of column `i` (0 to 15) is

| Column i | Colour |
|---|---|
| 0 | Wall Low |
| 1 | Wall High |
| 2 to 13 | Gap |
| 14 | Frame Inner |
| 15 | Frame Outer |

So the right wall of the well is two lit pixels, then 12 pixels of dark gap, then the left edge of the panel.

### 2.5 Panel and cards

**Frame** (a rectangle `x, y, w, h`): fill the whole rectangle Frame Outer, fill the rectangle inset by 1 with Frame Inner, fill the rectangle inset by 2 with Panel Fill, then set the four corner pixels of the outer rectangle to Night Top (so the corners are cut). The frames on the canvas are:

| Frame | x | y | w | h |
|---|---|---|---|---|
| NEXT box (the 6 x 6 cell panel) | 176 | 0 | 96 | 96 |
| SCORE card | 180 | 104 | 88 | 40 |
| LINES card | 180 | 150 | 88 | 40 |
| LEVEL card | 180 | 196 | 88 | 40 |
| HI-SCORE card | 180 | 242 | 88 | 40 |

The rest of the panel (`x 176 to 271`, `y 0 to 319`) is the background gradient with the Dot grid.

## 3. Animations

Every recipe is in milliseconds from its trigger. "Lit" means the block tone map drawn with the **lit row** of its piece: tone 1 becomes `FFFFFF`, tone 2 becomes the piece's tone 1, tone 3 its tone 2, tone 4 its tone 3, and tone 5 its tone 4 (everything one step lighter, the highlight pure white). "Floor" means the floor cell of that row.

### 3.1 Lock (a piece settles) 100 ms

1. 0 to 50: the four cells of the piece draw **lit**.
2. 50 to 100: the four cells draw as the normal tile with only tone 1 replaced by `FFFFFF`.
3. After 100: the normal tile.
4. Sparks: for each cell of the piece that has something under it (the floor or a block), emit 2 sparks at `(16 * col + 5, 16 * row + 15)` and `(16 * col + 10, 16 * row + 15)`, one pixel each. Velocity `vx = -0.6` and `+0.6` pixels a frame, `vy = -0.35`, gravity `+0.04` a frame, life 10 frames (166 ms), colour by age: `Flash` (frames 0 to 1), piece tone 1 (2 to 4), tone 2 (5 to 7), tone 3 (8 to 9). At most 8 sparks (an I piece lying flat).

### 3.2 Hard drop (Space) 200 ms

1. At the moment of the drop, for each of the piece's cell columns, take the cell that was highest in that column: the **trail** is a vertical streak 2 pixels wide at `x = 16 * col + 7` to `8`, from the top of the old cell down to the top of the new cell.
2. Draw the streak only on pixels that are not a settled block (the stack is drawn after it), so it never overwrites the stack.
3. Colour by age, 4 steps of 50 ms: piece tone 2, piece tone 3, piece tone 4, then gone.
4. Impact: a 1 pixel line across the landed piece's bottom edge, `y = 16 * row_bottom + 15`, width the piece width, growing 4 pixels each side per frame over 3 frames (50 ms each), in `Flash`, piece tone 1, piece tone 3.
5. Then the lock (3.1) plays at the new place.

Cost: a 4 wide piece falling 17 rows draws four streaks of 2 x 272 = about 2200 pixels for 200 ms. Cheap.

### 3.3 Line clear, 1 to 3 rows: 300 ms (a freeze, see section 8)

While this plays the game is frozen (no gravity, no input). All cleared rows play the same frames at once. Columns are numbered 0 to 9.

| Frame | Time | The cleared row shows |
|---|---|---|
| 0 | 0 to 50 | every block **lit** |
| 1 | 50 to 100 | the whole row 160 x 16 solid `FFFFFF` |
| 2 | 100 to 150 | columns 4 and 5 are floor; the others lit |
| 3 | 150 to 200 | columns 3 to 6 are floor |
| 4 | 200 to 250 | columns 2 to 7 are floor |
| 5 | 250 to 300 | columns 0 to 9 are floor |

At 300 the rows above drop at once (the game's normal shift). Sparks: on frames 2 to 5, for each cleared row emit 2 sparks at the centres of the two columns that just turned to floor, `y = 16 * row + 8`; velocity `vx = +-(0.5 to 1.2)`, `vy = -(0.4 to 1.1)`, gravity `+0.05`, life 12 frames, colours Flash, Gold 1, Gold 2, Gold 3 (the Gold ramp, tone 1 to 3). At most 24 sparks for 1 to 3 rows.

The SCORE number draws in Gold for 400 ms (then Text), and it counts up in 3 steps over 150 ms if you want a roll (optional).

### 3.4 A Tetris (4 rows): 420 ms

The same, with these changes, to make it clearly bigger:

| Frame | Time | The four rows show |
|---|---|---|
| 0 | 0 to 60 | every block drawn with the **Gold row** (the Gold ramp used as tones 1 to 5) |
| 1 | 60 to 120 | the whole 160 x 64 band solid `FFFFFF` |
| 2 | 120 to 180 | columns 4 and 5 floor |
| 3 | 180 to 240 | columns 3 to 6 floor |
| 4 | 240 to 300 | columns 2 to 7 floor |
| 5 | 300 to 360 | columns 0 to 9 floor |
| 6 | 360 to 420 | the four rows are floor; the sparks play out |

Also: `TETRIS` in 2x with a vertical gradient Gold (`FFC857`) to Accent (`FFA24A`) and the 1 pixel Outline, centred in the well at `x = 45`, `y = (centre of the band) - 7` (clamped to `8 to 298`), shown from 120 to 720 ms and then gone, over the well (it is drawn after the stack). Sparks: up to 48 at the same recipe with 4 per wipe frame per row. The SCORE number draws Gold for 800 ms.

### 3.5 Level up 480 ms

1. A **sweep line** rises through the well: 2 pixels high, full width 160, `y = 318 - 18 * f` for frames `f = 0 to 17` (one frame is 16.7 ms, 300 ms in all), colours Gold (frames 0 to 8) then Gold tone 3 (9 to 17). It is drawn before the blocks, so only the empty floor shows it.
2. The LEVEL card's Frame Outer turns Accent for 480 ms.
3. The level number blinks: Gold 80 ms, Accent 80 ms, three times.

### 3.6 Game over 1500 ms

1. 0 to 800: the well **fills with dead blocks** from the bottom row to the top, one row every 40 ms. A row turns to `block_blank` in the Dead colour row with the mark of whatever block was there (an empty cell gets the blank dead block). The panel stays as it is.
2. 800 to 1000: hold.
3. 1000 to 1200: the banner plate grows from the middle line: its height goes 2, 24, 56, 96 pixels, 50 ms a step, centred on `y = 164`.
4. 1200 to 1500: the letters of GAME OVER appear one every 33 ms, left to right.
5. At 1500: the score line, and NEW BEST if it beat the best (blinking 300 ms on and 300 off, and the HI-SCORE label turns to NEW BEST in Gold). `PRESS R` appears at 1800 ms.

Cost: 20 rows with 10 tiles each, 1 row per 40 ms: 10 tiles redrawn per update. The fill is the only moment the whole well changes, and it changes row by row.

### 3.7 Pause

Draw the well once with every pixel mixed 45 percent colour and 55 percent `05080F` (a one off cost, then it is held), the panel as it is. On top, the banner plate and PAUSED (section 4.2). Nothing moves, nothing blinks.

### 3.8 Start up 1600 ms (display only)

The game starts when the window opens, so this needs a short hold before the first piece starts to fall (section 8). Skip it at once with any key.

1. 0 to 300: the panel builds in: the NEXT box at 0, then the four cards at 60 ms intervals (a card appears, it does not fade).
2. 100 to 1000: the word `TETRIS` falls into the well. Each letter is 3x with a vertical gradient from tone 2 to tone 4 of a piece (T from Z, E from L, T from O, R from S, I from I, S from J) and the 1 pixel Outline. The letters are placed at `x = 27 + 18 * n` (n from 0 to 5) and fall in 16 pixel steps every 50 ms from `y = -24` to `y = 52`, the letter `n` starting `120 * n` ms after 100 ms. They stop at `y = 52`.
3. 1000 to 1100: the six letters lock (lit, 3.1).
4. 1100 to 1600: `READY` at 2x, Text with Outline, at `x = 51`, `y = 140`, blinks 100 ms on 100 off. The letters leave as in 3.3, frames 2 to 5, from 1300 to 1500.
5. 1600: the well is empty, `READY` goes, the first piece appears and the game starts.

## 4. Screens

All text is the 5 x 7 font. A 1 pixel Outline is drawn behind any text that sits on play (the banners). Panel text sits on Panel Fill and needs none.

### 4.1 In game

Panel (all text is drawn on Panel Fill):

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| NEXT label | `NEXT` | Accent | 1x | 212 | 8 |
| Next piece | the next piece's tiles, its bounding box centred in the area `x 192 to 255`, `y 24 to 87` | piece row | | `192 + (64 - 16 * width) / 2 - 16 * minx` | `24 + (64 - 16 * height) / 2 - 16 * miny` |
| SCORE label | `SCORE` | Label | 1x | 188 | 110 |
| SCORE value | 6 digits, zero padded | Text | 2x | 188 | 122 |
| LINES label | `LINES` | Label | 1x | 188 | 156 |
| LINES value | 6 digits | Text | 2x | 188 | 168 |
| LEVEL label | `LEVEL` | Label | 1x | 188 | 202 |
| LEVEL value | 2 digits | Accent | 2x | 188 | 214 |
| Best label | `HI-SCORE` | Label | 1x | 188 | 248 |
| Best value | 6 digits | Dim | 2x | 188 | 260 |
| Hint 1 | `P PAUSE` | Label | 1x | 188 | 294 |
| Hint 2 | `G GHOST` | Label | 1x | 188 | 304 |

A 6 digit value at 2x is 70 pixels wide (`x 188 to 257`) inside a card whose inner edge is `x 183 to 264`. A value of a million or more is drawn at 1x, right aligned to `x = 263`, with no padding. The piece boxes use `minx`, `miny`, `width`, `height` in cells of the piece's shape in its spawn turn.

Well: baked floor, walls and the divider (section 2.4); the settled blocks; the ghost (only if G is on) on empty cells; the falling piece. Ghost and piece use the tile of the piece's own colour row.

### 4.2 Pause

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Well | dimmed once (3.7) | | | 0 | 0 |
| Plate | `x 0 to 159`, `y 124 to 179`, filled Gap, with a 2 pixel Accent rule on its top two rows and bottom two rows | | | 0 | 124 |
| Title | `PAUSED` | Text with Outline | 2x | 45 | 145 |
| Hint | `P TO RESUME` | Dim | 1x | 47 | 164 |

### 4.3 Game over

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Well | the dead fill (3.6) | | | 0 | 0 |
| Plate | `x 0 to 159`, `y 116 to 211`, filled Gap, 2 pixel Accent rules top and bottom | | | 0 | 116 |
| Title | `GAME OVER`, gradient Over Top to Over Bottom, with Outline | gradient | 2x | 27 | 128 |
| Score line | `SCORE ` and 6 digits, centred in the well | Dim | 1x | `floor((160 - width) / 2)` | 156 |
| New best | `NEW BEST`, only if beaten, blinks 300 on 300 off | Gold | 1x | 56 | 172 |
| Hint | `PRESS R` | Text | 1x | 59 | 192 |

In the panel the label HI-SCORE becomes `NEW BEST` in Gold (and the value is the new score) when a best was set.

### 4.4 Start up

See 3.8. The frame at 1100 ms is in `tetris-preview.png` (second picture): TETRIS locked, `A PROGRIDDLE` at `x = 5` `y = 84` and `COOKOFF GAME` at `x = 5`, `y = 94`, both Label 1x (they appear with the word and leave with it), READY at 2x.

### 4.5 New best score during play

When the score passes the old best, the HI-SCORE label becomes `NEW BEST` in Gold and the value follows the score in Gold. One time, the card's Frame Outer turns Accent for 600 ms. No other change.

## 5. Effects

**Keep** (all are in the budget)

1. **Lock flash and sparks** (3.1): the piece sits down with a small flash and up to 8 sparks.
2. **Hard drop trail** (3.2): the streak and the impact line.
3. **Line clear wipe, sparks and Gold flash** (3.3, 3.4): the centre out wipe, the Gold row for a Tetris and the `TETRIS` word.
4. **Level up sweep** (3.5).
5. **Score pulse**: the SCORE number draws in Gold for 400 ms after any line clear (800 ms for a Tetris).
6. **Floor gradient** (baked): the well floor gets lighter by 2 percent a row to the bottom, so the well has depth for nothing.
7. **Pause dims once** (3.7).
8. **NEXT blink**: when a new piece appears in the NEXT box it draws in `FFFFFF`-lit for 50 ms.

**Drop**

- **A moving background pattern.** The panel dots are enough. Anything that moves behind the blocks would fight them.
- **Screen shake and a bloom.** Both touch every pixel every frame, which the budget forbids, and neither helps the clean look.
- **A glow around a clearing row.** It would need extra pixels over blocks and the floor of the rows above; the white flash and the Gold row say the same thing.

**Add**

1. **Danger walls.** When the highest settled block is in the top 4 rows (rows 0 to 3), the left wall and the bottom wall pulse: Wall High goes `E4503C` and Wall Low `7A2A20`, 250 ms on and 250 ms off. It is four thin strips, 2 x 320 and 2 x 160. It stops when the stack drops.
2. **Card flash on LEVEL and NEW BEST** (3.5, 4.5).

## 6. Budgets

| Item | Pixels or objects |
|---|---|
| Background gradient, floor, walls, divider, cards | baked once, then copied (free) |
| One block tile | 256 pixels |
| A full stack of 200 blocks (worst case redraw) | 51 200 pixels (only when the stack changes) |
| Falling piece, ghost, NEXT | 3 x 4 = 12 tiles = 3 072 pixels |
| Lock sparks | up to 8 |
| Line clear sparks | up to 24 (1 to 3 rows), up to 48 (a Tetris) |
| Hard drop trail | up to 4 streaks, no particles |
| Game over fill | one 160 x 16 row (10 tiles) per 40 ms |
| **Worst case at one time** | a Tetris (48 sparks) and a lock spark (8) = **56 particles, inside 60** |

Nothing changes every pixel of the screen on every frame. The lock, trail and sweep each touch a few strips; the clear and the game over touch one row at a time.


## 7. Checks

### Contrast

| Text | On | Contrast | Result |
|---|---|---|---|
| Text | Panel Fill | 16.4 : 1 | pass |
| Label | Panel Fill | 5.3 : 1 | pass |
| Dim | Panel Fill | 7.7 : 1 | pass |
| Accent | Panel Fill | 9.2 : 1 | pass |
| Text | Gap (banner plate) | 17.4 : 1 | pass |
| Dim | Gap (banner plate) | 8.1 : 1 | pass |
| Gold | Gap (banner plate) | 12.7 : 1 | pass |
| Over Top | Gap (banner plate) | 11.1 : 1 | pass |
| Over Bottom | Gap (banner plate) | 5.1 : 1 | pass |
| Label | Night Top | 5.5 : 1 | pass |

Every pair passes 4.5 : 1. The hint lines (Label on Panel Fill) are the lowest; they are help text, and the same text is in the Help screen.


### Colour blindness

`tetris-colour-check.png` shows the seven pieces under normal vision and three simulations (deuteranopia, protanopia, tritanopia; the Machado 2009 matrices at full severity, on linearised RGB). Colour alone does not carry the piece: the marks do (a horizontal slot, a square, a plus, a slash, a backslash, a J hook, an L hook), and each mark is different in shape and direction from every other. The closest two base colours in each simulation, as a distance in sRGB (0 to 441):

| Vision | Closest pair | Distance |
|---|---|---|
| normal | O and L | 58 |
| deuteranopia | S and L | 28 |
| protanopia | T and J | 17 |
| tritanopia | I and J | 65 |

Under protanopia T (amethyst) and J (cobalt) are close in colour, but a plus and a J hook cannot be mistaken, and the preview shows it.

### The brief's list

- Every tile reads at 2x: the thinnest detail is the 2 pixel mark and the 1 pixel specular glint, which is decoration.
- The seven pieces are told apart by mark as well as colour: see above.
- Text contrast: see the table.
- Nothing needs a full screen change every frame: see section 6.
- Every colour is in the palette tables and every pixel of every tile is `.` or a tone `1` to `5` or a legend letter (the ghost uses `D` and `H` only).


## 8. What I decided and why

1. **Walls are pixel lines, not tiles.** The brief's 160 pixel well has room for ten cells and nothing else. A 2 pixel wall on the left and bottom, and the divider on the right, frames it without moving the geometry. A block at the edge covers the wall and its own edge takes over.
2. **The same bevel for every piece, a mark for the difference.** One tone map keeps the stack calm and the pieces differ by engraving, so the stack never looks like a patchwork, and a colour blind player has a shape to read.
3. **The marks are letters where cheap.** J and L are drawn as their own hooks; the rest are abstract and need a few minutes to learn, but none of them is a thing you could mistake.
4. **Pause dims the stack once, it does not hide it.** The brief did not ask; hiding the stack would be a change of play.
5. **A line clear needs a 300 ms freeze (420 ms for a Tetris), a game over fill 1.5 s, and the start up 1.6 s.** The brief allowed about 0.3 s for the clear. The start up needs the first piece to wait 1.6 s (or less, if a key is pressed); if you would rather not delay the first piece, play only steps 1 and 3 of 3.8 (the panel build in) and skip the falling word. **No rule, key, speed or score changes.**
6. **The panel holds the numbers.** The status bar and the window title keep their text, as the brief asks.
7. **Score is capped in the picture, not in the game.** Six digits at 2x fit the card; a million or more switches to 1x.
8. **I left out a glow and a moving background** (section 5) and added danger walls, which tell the player something the pieces cannot.
9. **Colours.** The seven are close to today's (teal for cyan, gold, amethyst, leaf, vermilion, cobalt, tangerine) so players keep their habits, but each is a jewel tone on a dark navy rather than a flat primary.
