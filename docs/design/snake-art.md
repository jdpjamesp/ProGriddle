# Snake: art and screen design, "Lantern Glass"

Designer's answer to `snake-tetris-art-brief.md`. It is meant to be pasted into code with no further decisions. Tetris has its own file, `tetris-art.md`, with the same art direction. Where I disagree with the brief or chose between options, it is listed in section 8. Preview: `snake-preview.png` at 3x: the first row is the 20 x 20 board in game, waiting for a key and game over; the second row is a 10 x 10 board (the narrow strip) and a 40 x 40 board (8 pixel tiles).

## 0. Read this first

Conventions used everywhere below:

- A **cell** is one square of the board. A **tile** is the pixels of one cell: 16 x 16 on boards up to 20 cells across (10, 15 and 20 wide), 8 x 8 on bigger ones (30 and 40 wide). `S` is the tile size.
- The canvas is `W = cols * S` wide and `strip + rows * S` high. The **HUD strip** is above the board; the board's top left pixel is `(0, strip)`. Strip height is 32 when `W >= 320` and 24 when `W < 320` (section 4.1). Positions below are for the 20 x 20 board: `W = 320`, strip 32, board `y 32 to 351`, canvas 320 x 352.
- **Tile format**: as in the brief. `.` is transparent, `1` to `5` are the tones of a colour row (1 highlight, 5 edge), letters `A` to `H` have their own colour in the legend.
- **Draw order (back to front)**: 1 the baked floor (checkerboard), 2 food, 3 body from the tail towards the head, 4 head, 5 effects, 6 the **wall ring** (it is drawn over everything, see 2.5), 7 the HUD, 8 banners.
- **Text** is the 5 x 7 font, one pixel between letters. A character advances 6 pixels at 1x and 12 at 2x, so `n` characters at scale `k` are `n * 6k - k` pixels wide. "Centred" means `x = floor((W - width) / 2)`.
- **Time** is in milliseconds, nothing needs a frame rate. The game steps every 150 ms down to 60 ms; animations run on their own clock (60 a second or what you have) and never change the step.

What is in the file:

1. Art direction and palette
2. Tiles at 16 and at 8: head, body, corner, tail, food, floor, wall
3. Animations: tongue, food, eat, crash, win
4. Screens: in game (and how the strip changes with the board), waiting, game over, you win, new best
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

**Snake rows**

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge |
|---|---|---|---|---|---|
| Head `4FD6A0` | `CAF3E2` | `84E2BC` | `4FD6A0` | `379472` | `205243` |
| Body `2FB383` | `C1E8DA` | `6DCAA8` | `2FB383` | `227C5E` | `144639` |
| Tail `27996F` | `BEE0D4` | `68B89A` | `27996F` | `1C6B50` | `113C32` |
| Body Bright (the eat wave) | `DDFAEE` | `B1F4D8` | `8FF0C8` | `63A68D` | `375C52` |
| Apple `E5533D` | `F7CBC5` | `ED8777` | `E5533D` | `9D3B2E` | `562320` |

**Snake extras**

| Name | Hex | Used for |
|---|---|---|
| Floor A | `0D1420` | empty cell where `(x + y)` is even |
| Floor B | `101826` | empty cell where `(x + y)` is odd. Two values this close read as a quiet checkerboard, not a grid |
| Ring High | `4A5C80` | the outer pixel row of the board wall |
| Ring Low | `26344F` | the second pixel row of the board wall (16 pixel tiles only) |
| Lamp | `FFA24A` | the four corner lamps (same as Accent) |
| Eye | `F4F7FB` | eye white (letter `A` in the head tile) |
| Pupil | `0A0E16` | pupil (letter `B`) |
| Tongue | `E5533D` | the tongue (letter `T`), same as the apple's base |
| Stem | `7A4A2A` | the apple stem (letter `S`) |
| Leaf | `4FBF6A` | the apple leaf (letter `G`) |

**Crash ramp** (the body fading out, 5 steps): the tones of the mix of Body `2FB383` and `2A3345` at 0.2, 0.4, 0.6, 0.8 and 1.0, in that order. Step `k` uses `tones(mix(2FB383, 2A3345, k / 5))` with `k` from 1 to 5; after step 5 the cell shows the floor.

**Gold ramp** (the win wave): the tones of Gold `FFC857`:

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge |
|---|---|---|---|---|---|
| Gold | `FFEECD` | `FFD889` | `FFC857` | `AF8B40` | `5F4D29` |


## 2. Tiles

### 2.1 Which tile for which cell

The body is a ring of cells and each knows its neighbours. Look at the head and at each body cell, in order:

| Cell | Tile | How it is oriented |
|---|---|---|
| Head | `head` (or `head_tongue`) | drawn facing East; **turn it clockwise** `0, 1, 2, 3` times for facing E, S, W, N. The facing is the opposite of the side where the next cell of the body is |
| Body, neighbours E and W | `body_straight` | as drawn |
| Body, neighbours N and S | `body_straight` | turned clockwise once |
| Body, neighbours E and S | `body_corner` | as drawn |
| Body, neighbours S and W | `body_corner` | turned once |
| Body, neighbours N and W | `body_corner` | turned twice |
| Body, neighbours N and E | `body_corner` | turned three times |
| Tail (the last cell), the body is on its W | `tail` | as drawn (the tip points East) |
| Tail, body on its N | `tail` | turned once |
| Tail, body on its E | `tail` | turned twice |
| Tail, body on its S | `tail` | turned three times |
| Food | `food_0` to `food_3` | no turning |
| Empty | a flat `S` x `S` square of Floor A or Floor B | by `(x + y)` even or odd |

"Turned clockwise once" means the pixel at row `j`, column `i` goes to row `i`, column `S - 1 - j`. Nothing is mirrored, so no tile needs a left and right version. A one cell snake (the very start) is just the head with the body side taken as West.

The tiles are drawn as lit tubes, light from the top left. Turning a tile turns its highlight with it (the vertical piece has its highlight on the right); at this size that reads as the tube twisting, and it keeps the set to one drawing per shape. All of them have the same width so they join without a seam.

The body has a pattern that runs along it: **one small darker scale**, the 2 x 2 pixel (1 pixel at 8) mark in tone 4 in the middle of every straight piece, with a tone 1 glint above it, and the same scale on the middle of the arc of every corner. A snake of any length therefore shows a row of beads, and a growing snake shows a new bead.

### 2.2 Tiles at 16 x 16

Legends: `head`: tones of **Head**, `A` Eye, `B` Pupil, `T` Tongue. `body_*` : tones of **Body**. `tail`: tones of **Tail**. `food_*`: tones of **Apple**, `S` Stem, `G` Leaf, `W` `FFFFFF`.

#### head (16 x 16, faces East)
```
................
555555555555....
1111112223335...
11111222AA335...
11111222AB3445..
11112222333445..
11122223334445..
12222233334445..
22222333344445..
22223333444445..
22333344444445..
33333444AB4445..
33344444AA445...
3444444444445...
555555555555....
................
```

#### head_tongue (16 x 16, faces East)
```
................
555555555555....
1111112223335...
11111222AA335...
11111222AB3445..
11112222333445..
11122223334445.T
12222233334445T.
22222333344445T.
22223333444445.T
22333344444445..
33333444AB4445..
33344444AA445...
3444444444445...
555555555555....
................
```

#### body_straight (16 x 16, horizontal)
```
................
................
5555555555555555
1111111111111111
1111111111111111
2222222222222222
2222222112222222
2222222442222222
3333333443333333
3333333333333333
4444444444444444
4444444444444444
4444444444444444
5555555555555555
................
................
```

#### body_corner (16 x 16, joins East and South)
```
................
................
............5555
..........555111
........55111111
.......551111122
......5111112222
.....51111122222
....551112222333
....511124433333
...5111124433444
...5111223334444
..55112223344444
..51112233444455
..5112223344455.
..511222334445..
```

#### tail (16 x 16, the body is on the West, the tip points East)
```
................
................
55..............
11555...........
111111555.......
22222111115.....
22222222222115..
2222222222222222
3333333333333334
33333334444445..
44444444445.....
444444555.......
44555...........
55..............
................
................
```

#### food_0 (16 x 16)
```
........S.......
........S.GG....
........SGGGG...
........S.......
.....555555.....
....51112235....
...5111122345...
...5111223345...
...5112223345...
...5222233445...
...5223334445...
...5333344445...
....53444445....
.....554455.....
.......55.......
................
```

#### food_1 (16 x 16)
```
........S.......
........S.GG....
........SGGGG...
......55S5......
....55112255....
...5511122355...
...5111122335...
..511112233445..
..511122233445..
..512222334445..
..522233344445..
..553333444455..
...5334444445...
....54444445....
.....555555.....
................
```

#### food_2 (16 x 16)
```
........S.......
........S.GG....
........SGGGG...
.....555S55.....
....51112225....
...5111122335...
..511112223345..
..511112233345..
..511122233445..
..512222334445..
..522233344445..
..522333444445..
..553334444455..
...5544444455...
....55544555....
......5555......
```

#### food_3 (16 x 16, with a sparkle)
```
........S.......
........S.GG....
........SGGGG...
......55S5......
....W5112255....
...WWW1122355...
...5W11122335...
..511112233445..
..511122233445..
..512222334445..
..522233344445..
..553333444455..
...5334444445...
....54444445....
.....555555.....
................
```

At 8 x 8 the eyes are one white pixel each (`A`, no pupil), the tongue is two pixels, the scale is one pixel, and the apple has a 2 pixel stem and a 2 pixel leaf; the sparkle frame has one `W` pixel at `(2, 3)`.

### 2.3 Tiles at 8 x 8

Legends: `head`: tones of **Head**, `A` Eye, `B` Pupil, `T` Tongue. `body_*` : tones of **Body**. `tail`: tones of **Tail**. `food_*`: tones of **Apple**, `S` Stem, `G` Leaf, `W` `FFFFFF`.

#### head (8 x 8, faces East)
```
555555..
1112A35.
1122335.
1223345.
2233445.
3334445.
3444A45.
555555..
```

#### head_tongue (8 x 8, faces East)
```
555555..
1112A35.
1122335.
1223345T
2233445T
3334445.
3444A45.
555555..
```

#### body_straight (8 x 8, horizontal)
```
........
55555555
22222222
22242222
33334333
44444444
55555555
........
```

#### body_corner (8 x 8, joins East and South)
```
........
.....555
....5111
...11122
..512233
.5112344
.5123445
.512345.
```

#### tail (8 x 8, the body is on the West, the tip points East)
```
........
55......
21115...
22222225
33333445
44445...
55......
........
```

#### food_0 (8 x 8)
```
....SG..
....SG..
...55...
..5125..
.512345.
..5345..
..5555..
........
```

#### food_1 (8 x 8)
```
....SG..
....SG..
..5555..
.511235.
.512345.
.523445.
..5445..
...55...
```

#### food_2 (8 x 8)
```
....SG..
...5SG..
..5125..
.511235.
.512345.
.523345.
.554455.
..5555..
```

#### food_3 (8 x 8, with a sparkle)
```
....SG..
....SG..
..5555..
.5W1235.
.512345.
.523445.
..5445..
...55...
```

### 2.4 Floor

The empty cell is a flat colour square, **one colour for the whole tile** (16 x 16 or 8 x 8): Floor A where `(x + y)` is even, Floor B where it is odd. Because the checkerboard is per cell, not per pixel, the two sizes tie up exactly: the 8 pixel board is the same picture as the 16 pixel board at half the size. Baked once.

### 2.5 The wall ring

The canvas is exactly the board, so the wall is drawn **over the outermost pixels of the board**, as the last thing in the picture (after the snake, so the head never overlaps it). It is `t` pixels thick, `t = 2` at 16 and `t = 1` at 8:

- the outer row of pixels around the whole board in Ring High;
- at 16 only, the next row in Ring Low (one pixel inside);
- four **corner lamps** in Lamp (amber), `t x t` pixels at each corner of the board.

Edge piece (repeat along each side; a `t` pixel strip, turn it for the other sides):

#### edge_n (16 pixel boards, 16 x 2, top side; `H` Ring High, `L` Ring Low)
```
HHHHHHHHHHHHHHHH
LLLLLLLLLLLLLLLL
```

#### edge_n (8 pixel boards, 8 x 1)
```
HHHHHHHH
```

#### corner (16 pixel boards, 2 x 2, all four corners; `A` Lamp)
```
AA
AA
```

#### corner (8 pixel boards, 1 x 1)
```
A
```

The ring covers 2 pixels (1 at 8) of an edge cell, so a snake at the wall loses a sliver of its tile; it still reads, and it tells the player the wall is deadly and in front of them. For the bottom and right sides, Ring High is the outermost row and Ring Low the one inside, as for the top.

## 3. Animations

### 3.1 Tongue flick

While the snake is moving, the head draws `head_tongue` for 100 ms every 600 ms and `head` otherwise. While waiting for a key it flicks 100 ms every 400 ms. The tongue is 4 pixels at 16 and 2 pixels at 8.

### 3.2 Food

A pulse and a glint, 4 frames of 120 ms: `food_0`, `food_1`, `food_2`, `food_1`, and so on (a heartbeat). Every 4th time round, `food_3` (the glint) is played in place of `food_0`. When food appears it grows in: three frames of 50 ms with the apple's radius at 2, 4 and 5.5 pixels at 16 (1, 2 and 2.6 at 8), the same drawing recipe as the tiles. The food is a 1 cell thing and never covers a snake cell.

### 3.3 Eat 300 ms

Triggered when the head enters the food's cell.

1. **Head flash**: the head tile draws with every tone replaced by `FFFFFF`, `FFFFFF`, `F4F7FB`, `D8DEE9`, `AEB8CB` (tones 1 to 5) for 66 ms.
2. **Ring**: 8 pixels at 45 degree spacing from the food cell's centre, in six steps of 33 ms: radius `3 + 1.2 f` pixels (`1.5 + 0.6 f` at 8) for `f` from 0 to 5; colours by `f`: `FFFFFF`, Apple tone 1, 2, 3, 4, 5. They are drawn after the snake.
3. **Body wave** (the body brightening in a wave as it eats): starting at the cell behind the head, every body cell in turn draws with the **Body Bright** row instead of Body for 90 ms, one new cell every 30 ms, so three cells are lit at once and the wave runs from head to tail. At the tail it ends. The new, longer snake is drawn from the next step as usual (the growth is the game's, the wave only decorates).
4. **Score pulse**: the SCORE number draws Gold for 300 ms.

Cost: one tile at a time for the flash, 8 pixels for the ring, 3 tiles for the wave.

### 3.4 Crash 900 ms (then the banner)

Triggered when the head hits a wall or itself. The game is over, so nothing else moves.

1. **0 to 360**: the whole snake alternates **white** and **normal** every 60 ms (three flashes): white is the same replacement as the head flash (tones `FFFFFF`, `FFFFFF`, `F4F7FB`, `D8DEE9`, `AEB8CB`).
2. **0 to 360**: **sparks** from the head: 12 pixels from the head's centre, at 30 degree spacing, speed `0.6 + 0.2 * (i mod 3)` pixels a frame, drag 0.97, life 18 frames; colours by age: `FFFFFF` (0 to 3), Gold tone 2 (4 to 8), Accent (9 to 12), `E5533D` (13 to 15), the Crash ramp's last (16 to 17). Drawn after the snake.
3. **360 to 900**: the body **fades out from the tail to the head**. Number the cells from the tail, `k = 0` to `n - 1`. Cell `k` starts at `360 + 240 * k / (n - 1)` ms and then steps through the 5 steps of the **Crash ramp**, 60 ms a step; after step 5 it is floor. The food stays.
4. **900**: the banner plate grows in (section 4.3).

For a 40 x 40 board a long snake may have 1000 cells; the start times are spread over 240 ms so at most about 1000 / 4 tiles change per 60 ms step. It is the one moment of the game that touches many tiles, and it happens once.

### 3.5 Win 1500 ms

Triggered when the board is full.

1. **0 to 1200**: a **Gold wave** runs from the head to the tail twice: each cell, in turn from the head, draws with the Gold row for 90 ms, one new cell every `600 / n` ms (so one lap takes 600 ms whatever the length).
2. **0 to 1200**: **24 sparks**, a new one every 50 ms from a random cell of the board, rising: `vy = -0.5`, drag 1, life 20 frames; colours by age: `FFFFFF`, Gold tone 2, Gold tone 3, Accent. Drawn after the snake.
3. **1200**: the banner plate (section 4.4).

## 4. Screens

### 4.1 In game and the HUD strip

The strip is on top, above the board, and is filled Night Top with a rule at its bottom. There are four stats in four equal columns: SCORE, LENGTH, LEVEL, BEST.

**Wide boards (`W >= 320`: 20 x 20 at 16, and 40 x 30 and 40 x 40 at 8)**: strip 32 high.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Rule | a 2 pixel line across, `y 30 to 31` | Frame Inner | | 0 | 30 |
| SCORE label | `SCORE` | Label | 1x | 8 | 4 |
| SCORE value | the score, no padding | Text | 2x | 8 | 14 |
| LENGTH label | `LENGTH` | Label | 1x | 88 | 4 |
| LENGTH value | the length | Text | 2x | 88 | 14 |
| LEVEL label | `LEVEL` | Label | 1x | 168 | 4 |
| LEVEL value | the level | Accent | 2x | 168 | 14 |
| BEST label | `BEST` | Label | 1x | 248 | 4 |
| BEST value | the best score | Dim | 2x | 248 | 14 |

A column is 80 pixels wide, so 5 digits at 2x (58 pixels) always fit; the board's largest score is 1600 cells x 10 = 16 000.

**Narrow boards (`W < 320`: 10 x 10 and 15 x 15 at 16, 30 x 20 and 30 x 30 at 8)**: strip 24 high, **the same four stats at 1x**, in four columns each `W / 4` wide.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Rule | a 1 pixel line across, `y = 23` | Frame Inner | | 0 | 23 |
| Labels | `SCORE`, `LENGTH`, `LEVEL`, `BEST` | Label | 1x | `4 + k * (W / 4)`, k = 0 to 3 | 4 |
| Values | score, length, level, best | Text, Text, Accent, Dim | 1x | same x | 13 |

On the 10 x 10 board (`W = 160`) a column is 40 pixels: `LENGTH` is 35 wide, and a 4 digit value at 1x is 23 wide, so nothing touches its neighbour. On a narrower board than 160 (the game's smallest is 160) the labels would be cut to `SC`, `LEN`, `LV`, `BE`.

The board below the strip: the baked checkerboard floor, the food, the snake, then the wall ring over the outermost pixels (2.5). `snake-preview.png` shows the 20 x 20 board (first picture), the 10 x 10 board and the 40 x 40 board (second row).

**New best during play**: when the score passes the best, the BEST label becomes `NEW BEST` (`NEW` on a narrow board) in Gold blinking 300 ms on and 300 off, and the value follows the score in Gold.

### 4.2 Waiting for a key (20 x 20)

The snake is drawn at its start place (the head at the middle of the board, facing East, the body trailing West) and the food somewhere on the board.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Plate | `x = floor((W - width) / 2) - 8`, `y = 32 + 80 - 8 = 104`, width `w + 16`, height 23, filled Gap, with a 1 pixel Frame Outer rule on its top and bottom rows | | | | |
| Text | `PRESS AN ARROW KEY`, blinking 500 ms on and 300 ms off | Text | 1x | `floor((W - 107) / 2)` | 112 (`strip + rows * S / 4`) |
| Arrow | the 4 x 7 chevron below, drawn 4 pixels to the right of the head's cell, vertically centred on it, blinking with the text | Accent | | head cell right edge + 4 | head cell centre - 3 |

```
#...
##..
.##.
..##
.##.
##..
#...
```

The head flicks its tongue every 400 ms (3.1). The text is 107 pixels wide and fits every board down to 160.

### 4.3 Game over

After the crash (3.4), at 900 ms the plate grows from its middle line (height 2, 20, 44, 68, 50 ms a step), centred on the board's centre `by = strip + rows * S / 2`.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Board | the faded snake, the food, and **the whole board dimmed once**: every pixel mixed 45 percent and `05080F` 55 percent | | | | |
| Plate | the full width `W`, `y = by - 34`, height 68, filled Gap | | | 0 | `by - 34` |
| Rules | 2 pixel lines in Accent on the plate's top two and bottom two rows | Accent | | 0 | `by - 34` and `by + 32` |
| Title | `GAME OVER`, gradient Over Top to Over Bottom, Outline | gradient | 2x | `floor((W - 106) / 2)` | `by - 24` |
| Score line | `SCORE n   LENGTH m` (three spaces between) | Dim | 1x | centred | `by - 2` |
| New best | `NEW BEST`, only if beaten, blinks 300 on 300 off | Gold | 1x | centred | `by + 10` |
| Hint | `PRESS R` | Text | 1x | centred | `by + 22` |

For the 20 x 20 board: `by = 192`, the plate is `y 158 to 225`. The BEST value in the strip shows Gold, and the label `NEW BEST`, if the best was beaten. The longest score line (`SCORE 16000   LENGTH 1600`) is 149 pixels wide and fits the 160 pixel board.

### 4.4 You win

After the win (3.5), at 1200 ms the plate grows as in 4.3, 84 high, centred on `by`.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Plate | the full width, `y = by - 42`, height 84, filled Gap, Accent rules on the top and bottom two rows | | | 0 | `by - 42` |
| Title | `YOU WIN`, gradient Gold `FFC857` to Accent `FFA24A`, Outline | gradient | 3x | `floor((W - 123) / 2)` | `by - 34` |
| Score line | `SCORE n   LENGTH m` | Dim | 1x | centred | `by + 4` |
| New best | `NEW BEST`, only if beaten | Gold | 1x | centred | `by + 16` |
| Hint | `PRESS R` | Text | 1x | centred | `by + 28` |

### 4.5 A new best score

Three places say it, nothing else: the BEST label and value in the strip (Gold, 4.1), the NEW BEST line on the game over and win plates, and the score pulse (3.3).

## 5. Effects

**Keep** (all in the budget)

1. **Food pulse and glint** (3.2).
2. **Tongue flick** (3.1).
3. **Eat ring, head flash, body wave** (3.3).
4. **Crash flash, sparks and tail to head fade** (3.4).
5. **Win wave and rising sparks** (3.5).
6. **Score pulse**: the SCORE number in Gold for 300 ms after each food.
7. **Dim once at the end**: the board mixed with `05080F` once under the game over plate.

**Drop**

- **A drifting background** and **a glow around the food**: both would redraw many pixels every frame; the checkerboard is the quiet background we want.
- **Screen shake on a crash.** It moves every pixel.
- **A bulging body** (a wider tile where the food is swallowed): it needs a second set of tiles; the brightening wave says the same thing with a recolour.

**Add**

1. **The waiting arrow** (4.2): it shows which way the snake will go when the first key is pressed.
2. **Food grow in** (3.2): a 150 ms pop so a new apple is easy to spot.
3. **NEW BEST in the strip while playing** (4.1).

## 6. Budgets

| Item | Pixels or objects |
|---|---|
| Checkerboard floor | baked once, then copied |
| Strip | redrawn only when a number changes: about 1000 pixels |
| A step | the new head tile, the old head's tile (now body), the tail's tile and the floor cell it leaves: 4 tiles, 1024 pixels at 16, 256 at 8 |
| The wall ring | re-stamped after each redraw of an edge cell, or after any full redraw: `t * 2 * (W + H)` about 2700 pixels at 16 |
| Eat | 8 particles, 1 flash tile, 3 wave tiles per 30 ms |
| Crash | 12 particles, then about `n / 8` tiles per 60 ms step |
| Win | 24 particles at most, 2 tiles per 30 ms on a long board |
| **Worst case** | the win with 24 particles; no full screen change on any frame |

## 7. Checks


### Contrast

| Text | On | Contrast | Result |
|---|---|---|---|
| Text | Night Top (the strip) | 17.2 : 1 | pass |
| Label | Night Top (the strip) | 5.5 : 1 | pass |
| Dim | Night Top (the strip) | 8.0 : 1 | pass |
| Accent | Night Top (the strip) | 9.7 : 1 | pass |
| Text | Gap (plates) | 17.4 : 1 | pass |
| Dim | Gap (plates) | 8.1 : 1 | pass |
| Gold | Gap (plates) | 12.7 : 1 | pass |
| Over Top | Gap (plates) | 11.1 : 1 | pass |
| Over Bottom | Gap (plates) | 5.1 : 1 | pass |
| Head base | Floor A | 10.1 : 1 | pass |
| Body base | Floor A | 6.9 : 1 | pass |
| Body base | Floor B | 6.7 : 1 | pass |
| Apple base | Floor B | 4.8 : 1 | pass |
| Body base | Apple base | 1.4 : 1 | FAIL |

The last row is the only pair of play colours that could be confused by hue (jade against red): the snake and the apple differ by **shape** (a long tube with a pointed tail against a round fruit with a stem and a leaf) and by luminance, so a colour blind player never has to tell them apart by colour. Each tile has a dark 1 pixel edge (tone 5) and a bright highlight (tone 1) which carry the shape, and the head is lighter than the body so the facing reads.


### The brief's list

- Every tile reads at 2x: the thinnest parts are the 2 pixel tongue and the 1 pixel specular, which are decoration; the eyes are 2 x 2 pixels. At 8 x 8 the eyes are one pixel each and the tongue two.
- The art works at 8 x 8 and 16 x 16 on the smallest and biggest boards: a 10 x 10 board and a 40 x 40 board (8 pixel tiles) are the pictures in the second row of the preview; the HUD strip works from 160 to 320 pixels wide (4.1).
- Text contrast: see the table.
- Nothing needs a full screen change every frame: see section 6.
- Every colour is in the palette tables and every pixel of every tile is `.` or a tone `1` to `5` or a legend letter.


## 8. What I decided and why

1. **The wall is a ring over the board's edge pixels**, since the canvas is exactly the board and the brief fixes the size. It costs 2 pixels (1 at 8) of the outer cells and gives the board a frame; the amber corner lamps are the house accent.
2. **A checkerboard of two very close tones**, per cell, so that the two tile sizes show the same picture and no grid line is needed (the brief's "programmer art" grid is gone).
3. **One scale per tile** rather than a full pattern, so the pattern reads at 8 x 8 and the snake stays calm on a long board.
4. **The head is lighter and a little wider than the body**, with a 4 pixel tongue that flicks. The brief wanted the facing to show; the eyes at the front and the tongue say it twice.
5. **The strip is above the board** and changes size with the board's width (32 at 320 or more, 24 below): there is no scale that fits four labelled numbers on 160 pixels at 2x, so the narrow strip uses 1x text.
6. **Animations that run after the game has ended** (the crash 900 ms, the win 1200 ms) delay the banner. The rules, keys, speeds and scoring do not change; if you want the banner at once, skip the crash animation and draw 4.3 straight away.
7. **The body brightening wave** instead of a bulge: one recolour of a few tiles, no second tile set.
8. **Colours**: jade for the snake and vermilion for the apple stay recognisable (green snake, red apple) and match today's, but they are lit tubes and fruit now, not flat squares.
