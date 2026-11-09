# FootballManager: art and screen design, "Chalk and Floodlights" (revision 2)

Designer's answer to `footballmanager-art-brief.md`, its revision `footballmanager-art-brief-2.md` and `footballmanager-rules.md`. Everything here is meant to be pasted into code with no further decisions. Section 11 lists what I decided and the calls still open for James.

**The idea in one line.** Every menu is the **chalkboard in the dressing room**: chalk lettering on a bottle green slate in a wooden frame, red and blue tactics magnets for the picks. Every match is a **floodlit night game**: the attacked end of the pitch in perspective with its goal line on the diagonal, seven figures, and a close up of the goal mouth for every shot.

**What changed in revision 2.** The pitch follows the rules' 32 x 22 grid with diagonal goal lines (3.2), with seven figures in an attack and the keeper on his diagonal. The kits are **white** and **black** (your side wears the colour picked on the new kit screen, the other side the other), told apart by a hoop and pinstripes as well as by colour. The pick 12 screen and the referee are gone, as are the card and substitute icons, the scorers strip and the loan warning colours. The cup is the **F.A. Cup**. Badges go by slot. Sprite names are unchanged where the sprite is unchanged; the renamed and removed ones are listed in 11.1.

**Names.** The game's name is drawn from a text constant by the rule of 6.5, and every club and player name comes from the game's data. This file and its previews do not carry the 1982 game's name or its lists of clubs and players: the previews show placeholder names in the data's format (a club of at most 10 characters, a player of at most 9 as `K.PUDDLE`), and every column is sized for those lengths.

Previews (made by the generator from the data in this file, so the pictures and the text cannot disagree):

- `footballmanager-preview.png` (3x): an attack on the right goal part way through, attack 7, the close up showing a high save.
- `footballmanager-preview-left.png` (3x): the same attack on the left goal (the mirrored view).
- `footballmanager-preview-table.png` (3x): the division 3 table, your club 3rd, both zones marked.
- `footballmanager-preview-squad.png` (3x): the squad, the cursor on a midfielder, all three energy levels.
- `footballmanager-preview-title.png` (3x): the title, part way through the intro (the shot on its way).
- `footballmanager-screens.png` (2x): every other screen: the three set up screens (name and level, club, colours), the week menu, pick the team, results, the money report, the transfer offer (bid, and refused), sell a player, the F.A. Cup round, an attack on the left goal without the close up, full time, end of season, sacked, paused, the trophy cabinet.
- `footballmanager-goalmouth.png` (3x): the nine saves, goals, wide, over, off the post, the shot's three frames and the ripple.
- `footballmanager-later.png` (2x): the four division looks and the stand at four sizes (section 9).
- `footballmanager-sprites.png` (4x): every sprite, alternate rows on the board and on the grass.
- `footballmanager-colour-check.png` (1x): the match, the squad and the kit screen as drawn, through deuteranopia, protanopia and tritanopia, and in grey scale.

## 0. Read this first

- The canvas is **320 x 240**, as the brief proposes, shown at 3x (2x on small screens), nearest neighbour. It is a **direct colour PixelCanvas** like Space Invaders, Centipede, Xevious and Cuber. 320 is wide enough: the table's last column ends at x 306 in the 5 x 7 font at 1x, so no size change is asked for.
- The **pitch** is the rules' 32 x 22 grid, drawn as the attacked end in perspective (3.2).
- Every menu screen has the same frame: the **status bar** (rows 0 to 13), the **board** in its wooden frame (rows 14 to 227), the **key bar** (rows 228 to 239). The match replaces the status bar with a **score bar** and the board with the pitch (section 3.1).
- **Sprite format**: the tone format of `snake-art.md`. `.` is transparent, `1` to `5` are the tones of the sprite's colour row (1 highlight, 2 light, 3 base, 4 shade, 5 edge), letters are fixed colours given in each legend. No legend has more than 16 colours (the largest has 14).
- **Origin**: every sprite gives its origin. For a figure it is **the middle of its feet** and goes on `cell_xy(column, row, side)` (section 3.2). Badges, faces and icons are placed by their top left (origin (0, 0)).
- **Facing**: figures are drawn facing right; the game mirrors the columns for left (the origin column becomes `width - 1 - x`). Every figure is lit from the top, so a mirrored figure is right. The kit pattern is applied **before** mirroring (section 4.1).
- **Text**: the house 5 x 7 font, plus six new glyphs and a 3 x 5 font for the dense places (section 5). Everything is in capitals.
- **Draw order** on the match: the baked background (stands, pitch, goals), the figures sorted by feet y (then x), the ball's shadow, the trail, the ball, the score bar and ticker, then the close up and any plate on top.
- **Time** is in milliseconds. Nothing changes every pixel every frame: the biggest per frame change is opening the close up (96 x 64, once) or swapping the crowd tiles (two strips of 320 x 8, every 150 ms during a cheer).
- **No blending**: every colour below is a flat value. A glow or a shadow is extra pixels in a dimmer colour.

## 1. Names and art direction

### 1.1 The look: Chalk and Floodlights

The menus are a **chalkboard** in a warm wooden frame, as if the week were planned on the dressing room wall: the slate is a deep bottle green (`14231E`), the text is chalk (warm white, a dim grey green for labels, a yellow chalk for anything that is yours or chosen), a few specks of chalk dust are baked into the slate, every second table row is a faint wipe, and the picks are **tactics magnets** (a red disc to start, a blue ring for the reserve). The match is the opposite light: a **night game under floodlights**, the pitch bright and mown in stripes, the stands dark and full of little coloured dots, the lamp heads glowing in the corners. The colours mean things and mean them everywhere: **chalk green is good** (credit, promotion, fresh legs, a win), **chalk red is bad** (debt, relegation, spent legs, defeat, the sack, every cost), **amber is a warning**, **yellow is you**, **blue is them and information**, **gold is money and glory**. Every one of those meanings also has a shape (a sign, an icon, a fill pattern, an arrow) so it never rests on hue alone.

It is a sibling of the others (dark ground, chunky pixels, the 5 x 7 font, banner plates with two rules) but its own thing: the only game on a green slate, the only one with a wood frame, and its accent is chalk yellow rather than amber (Lantern Glass), neon (Space Invaders) or ember (Dusk Lamps).

### 1.2 The names

| Thing | Name | Note |
|---|---|---|
| The game | a text constant | drawn on the title by the rule of 6.5; the file names keep the working title footballmanager |
| The look | Chalk and Floodlights | The board for the week, the lights for the match |
| The week menu | the Manager's Office (the board's title) | The original's choices, under a friendlier heading |
| The cup | F.A. CUP | as the brief writes it; rounds ROUND 1 to ROUND 6, SEMI-FINAL, FINAL |
| A pick | a magnet | Red disc to start, blue ring for the reserve |

### 1.3 What is the same on purpose

- **Everything that costs you is Chalk Red** (`FF6F61`): debt, wages, rent and interest in the money report, relegation, a spent bar, an injury, a defeat, SACKED. Everything that pays is **Chalk Green** (`7FE39A`). A minus sign, the cracked coin or a down arrow always comes with the red; a plus sign, the coin or an up arrow with the green.
- **Yellow chalk is you**: your club's name and row, your bars on the pick screen, the cursor, the selected item. **Blue chalk is them** (their bars) and information (week, division, morale, the cup).
- **Gold is money and glory**: the coin, the league trophy and the title lettering share the Gold row.
- **The kits are white and black**, and the keeper marigold, so the three never share a value; the white has a black hoop and black shorts, the black has pale pinstripes and white shorts.
- **The keeper is marigold everywhere**: the Keeper row on the pitch and in the close up, and the goalkeeper position icon (`Pos GK` = `Keeper 3`).
- **The board's rows** mean the same on every screen: Board Stripe on every second row, Cursor Row under the cursor, Your Row (with two Chalk Yellow rules) under your club.

## 2. The palette

**143 distinct colours.** Some names share a value on purpose and say so.

### 2.1 Tone rows

Most rows are made from a base: tones 1 and 2 are the base mixed with white, tones 4 and 5 the base mixed with Outline `0A0D0C`. Rows marked "set by hand" are not made that way.

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge | Used for |
|---|---|---|---|---|---|---|
| White | `FFFFFF` | `F6F7F9` | `E2E5EA` | `AEB4BF` | `545A68` | the white kit shirt and socks (set by hand; the hoop is Kit Hoop, the shorts Kit Dark Shorts) |
| Black | `9AA0AC` | `62687A` | `33373F` | `24272E` | `0E1013` | the black kit shirt and socks (set by hand, a cool grey highlight so it reads on the grass; the pinstripes are Kit Pinstripe, the shorts Kit Light Shorts) |
| Magnet Red | `F2ADA8` | `E9766E` | `E2493E` | `99352D` | `4B1F1B` | the red tactics magnet (picked to start) |
| Magnet Blue | `A9D7F5` | `6FBCEE` | `3FA6E8` | `2D729D` | `1A3B4E` | the blue ring magnet (the reserve) |
| Keeper | `F9E4A2` | `F5D164` | `F2C230` | `AC8C25` | `504317` | both goalkeepers: marigold (plain shirt, white gloves, black shorts) |
| Gold | `FFF4C0` | `FFDD70` | `F2B630` | `B07A1C` | `5A3A10` | coins, the trophy, the title (set by hand): gold is money and glory |
| Silver | `FFFFFF` | `E0E6EE` | `B4BECC` | `7A8698` | `3E4656` | the cup trophy, the bank and the lower medals (set by hand) |
| Wood | `E0A868` | `C89052` | `9A6634` | `6E4424` | `2A170C` | the frame round every chalkboard, the trophy plinths, the desk (set by hand) |
| Ball | `FFFFFF` | `FFFFFF` | `EEF1F4` | `C4CAD4` | `4A5060` | the ball (set by hand: tones 1 and 2 are both white so it stays bright in the air) |
| Flash | `FFFFFF` | `FFFFFF` | `FFF8DC` | `FFE07A` | `FFB23A` | the goal flash: any kit row is swapped for this one for 2 frames when its player scores |

### 2.2 Single colours

**The tunnel (status bar and key bar)**

| Name | Hex | Used for |
|---|---|---|
| Tunnel | `0C1311` | the status bar (rows 0 to 13) and the key bar (rows 228 to 239) |
| Tunnel Rule | `2A3A33` | the 1 pixel rule under the status bar and over the key bar |

**The chalkboard (every menu screen)**

| Name | Hex | Used for |
|---|---|---|
| Board | `14231E` | the board: a deep bottle green slate |
| Board Stripe | `1A2C26` | every second row of a table (a faint wipe of the board) |
| Board Dust | `20332C` | chalk dust: single baked pixels on the board, 1 in about 70 |
| Board Rule | `3C5449` | a chalk rule drawn faint: under a table head, between panels |
| Board Head | `0F1B17` | the title band at the top of a board (a darker strip) |
| Your Row | `3D3A16` | the band behind your club's row in every table |
| Cursor Row | `2E4A40` | the band behind the row under the cursor |

**Chalk (text)**

| Name | Hex | Used for |
|---|---|---|
| Chalk | `F1ECD9` | normal text: names, numbers |
| Chalk Dim | `93A89A` | labels, column heads, key hints, things you cannot pick |
| Chalk Yellow | `FFDA5C` | highlight: your club, the cursor, the selected item, titles |
| Chalk Green | `7FE39A` | good: money in credit, promotion, fresh, a win (W) |
| Chalk Amber | `FFAA33` | take care: weary, a draw is not this colour, a warning that is not yet bad |
| Chalk Red | `FF6F61` | bad: money in debt, relegation, spent, a defeat (L), injury, the sack |
| Chalk Blue | `8CC8FF` | information: morale, the cup, the week and division |
| Outline | `0A0D0C` | the 1 pixel outline behind text over the pitch, the title and the goal mouth |

**Bars**

| Name | Hex | Used for |
|---|---|---|
| Bar Empty | `2B3F37` | the empty part of every bar |
| Bar Tick | `6E8A7C` | the threshold ticks under a bar (at 6 and 12 of 20) |
| Bar Plain | `D8D2BC` | a bar with no warning level (Defence, Midfield, Attack, skill) |
| Bar Plain Dark | `A49E86` | the dashes of a plain bar |
| Fresh Dark | `3E9E5C` | the shadow row of a fresh bar |
| Weary Dark | `B8701C` | the gaps of a weary bar |
| Spent Dark | `A83A32` | the checks of a spent bar |

**Night and stadium**

| Name | Hex | Used for |
|---|---|---|
| Night | `070B14` | the sky over the ground (title, ground screen) |
| Night Haze | `0E1626` | the sky near the floodlights and the roof |
| Star | `3E4C6A` | a far star (baked, 1 pixel) |
| Roof | `343C50` | the stand roof and the floodlight pylons |
| Roof Edge | `545E78` | the lit edge of the roof |
| Stand | `1A2030` | the back of the stand behind the crowd |
| Crowd Shadow | `111522` | the gaps between heads in the crowd |
| Crowd Face | `D7A27E` | a face in the crowd |
| Crowd Face Dark | `9A6A4C` | a face in the crowd, the other tone |
| Crowd Red | `B34A44` | crowd shirts and scarves |
| Crowd Cream | `CFC5A8` | crowd shirts and scarves |
| Crowd Blue | `4A74AA` | crowd shirts and scarves |
| Crowd Gold | `C2903A` | crowd shirts and scarves |
| Crowd Plum | `74508C` | crowd shirts and scarves |
| Wall | `262C3C` | the wall at the front of the stand |
| Hoarding | `102A44` | the advertising boards round the pitch |
| Hoarding Lit | `3E8CC4` | the lit lettering blocks on the boards |
| Hoarding Warm | `D08A34` | the warm lettering blocks on the boards |
| Floodlight | `FFF6D2` | a floodlight lamp |
| Flood Glow | `6E6A54` | the glow ring round a floodlight lamp |
| Flood Haze | `2A2C30` | the outer glow ring round a floodlight |

**The pitch**

| Name | Hex | Used for |
|---|---|---|
| Grass A | `3E9440` | mown stripe A |
| Grass B | `378A3A` | mown stripe B |
| Run Off | `2C6E30` | the grass outside the lines |
| Line | `E6EFDA` | the pitch lines (slightly green so a white ball is whiter) |
| Post | `FFFFFF` | the goal posts and crossbar |
| Net | `B8C4C0` | the net mesh |
| Net Dark | `6C7A76` | the net in shade, and the back of the goal seen from above |
| Spot | `E6EFDA` | the penalty and centre spots (same as Line) |
| Ball Shadow | `24602A` | the shadow under the ball and under each figure |
| Trail 1 | `C4E2BC` | the ball trail, the pixel nearest the ball |
| Trail 2 | `8CC488` | the ball trail, the middle pixel |
| Trail 3 | `5CA45C` | the ball trail, the far pixel |

**Kits (the fixed parts)**

| Name | Hex | Used for |
|---|---|---|
| Kit Hoop | `24272E` | the black hoop on the white shirt (same as Black 4) |
| Kit Dark Shorts | `24272E` | the white kit's shorts: black (same as Kit Hoop on purpose) |
| Kit Dark Shorts Shade | `0E1013` | their shade side |
| Kit Pinstripe | `C8CCD4` | the pale grey pinstripes on the black shirt |
| Kit Light Shorts | `E2E5EA` | the black kit's shorts: white (same as White 3 on purpose) |
| Kit Light Shorts Shade | `AEB4BF` | their shade side |
| Glove | `F4EEDC` | the keeper's gloves |
| Keeper Shorts | `20242C` | the keepers' shorts |
| Keeper Shorts Dark | `121418` | the shade side |
| Boot | `17120E` | every boot |
| Skin 1 | `F2C6A0` | skin, light (base) |
| Skin 1 Shade | `C99474` | skin, light (shade) |
| Skin 2 | `C98A5C` | skin, medium (base) |
| Skin 2 Shade | `9C6640` | skin, medium (shade) |
| Skin 3 | `8A5634` | skin, deep (base) |
| Skin 3 Shade | `633A20` | skin, deep (shade) |
| Hair Dark | `2E1C12` | hair, dark brown |
| Hair Black | `141016` | hair, black |
| Hair Fair | `E2B85A` | hair, fair |
| Hair Ginger | `B8542A` | hair, ginger |
| Hair Grey | `B4B4B0` | hair, grey (managers and old pros) |

**Faces**

| Name | Hex | Used for |
|---|---|---|
| Eye | `141016` | pupils and brows |
| Eye White | `F6F2EA` | eye whites and teeth |
| Mouth | `7A2E26` | a mouth |
| Cheek | `E58A72` | a ruddy cheek |
| Face Back | `22342D` | the square behind a face (one step lighter than Board) |

**Badges**

| Name | Hex | Used for |
|---|---|---|
| Badge Edge | `0E0B0A` | the outline of every badge |
| Badge Red | `D8433A` | a badge colour |
| Badge White | `F3EEE0` | a badge colour |
| Badge Navy | `203A6E` | a badge colour |
| Badge Gold | `F2B630` | a badge colour (same as Gold 3) |
| Badge Black | `22222A` | a badge colour |
| Badge Green | `2F8A4A` | a badge colour |
| Badge Purple | `7046AE` | a badge colour |
| Badge Teal | `1E9A9A` | a badge colour |
| Badge Sky | `62BAF0` | a badge colour |
| Badge Maroon | `7E2236` | a badge colour |
| Badge Brown | `8A5A2E` | a badge colour |
| Badge Orange | `EE8A2E` | a badge colour |

**Icons**

| Name | Hex | Used for |
|---|---|---|
| Pos GK | `F2C230` | the goalkeeper icon (same as Keeper tone 3 on purpose) |
| Pos DF | `62BAF0` | the defender icon |
| Pos MF | `7FE39A` | the midfielder icon (same as Chalk Green) |
| Pos FW | `FF8A3D` | the forward icon |
| Icon Edge | `0A0D0C` | the dark edge of an 8 x 8 icon (same as Outline) |
| Plaster | `F4E2C4` | the injury plaster |
| Plaster Dot | `C8A880` | the holes in the plaster |
| Envelope | `E8DCC0` | the wage packet |
| Envelope Shade | `B0A280` | the wage packet, flap and shade |
| Brick | `B0563C` | the stadium icon walls and the ground screen bricks |
| Brick Dark | `7A3424` | the mortar |
| Turf | `3E9440` | the stadium icon grass (same as Grass A) |
| Flame | `FF8A3D` | the in form flame, outer (same as Pos FW) |
| Flame Core | `FFE07A` | the in form flame, core |
| Zzz | `8CC8FF` | the tired icon letters (same as Chalk Blue) |

**Effects**

| Name | Hex | Used for |
|---|---|---|
| Spark | `FFFFFF` | the first colour of every sparkle |
| Spark Warm | `FFF2A8` | the second colour of a sparkle |
| Spark Gold | `FFC93C` | the last colour of a sparkle |
| Title Top | `FFF4C0` | the title lettering, top of the gradient (same as Gold 1) |
| Title Bottom | `F2A230` | the title lettering, bottom of the gradient |
| Title Shadow | `3A2408` | the 2 pixel drop under the title lettering |

## 3. The scenery

### 3.1 The match screen, by rows

| Rows | What |
|---|---|
| 0 to 17 | the score bar (Tunnel, a Tunnel Rule on row 17), section 6.12 |
| 18 to 33 | the top stand: Roof rows 18 and 19, Roof Edge row 20, one row of crowd tiles rows 21 to 28, Wall row 29, the hoardings rows 30 to 33 |
| 34 to 193 | the pitch and the run off; the grid's 22 rows are y 36 to 189 (3.2) |
| 194 to 205 | the bottom stand: the hoardings rows 194 to 197, a row of crowd tiles rows 198 to 205 |
| 206 to 227 | the ticker (Tunnel, a Tunnel Rule on row 206) |
| 228 to 239 | the key bar |

Two floodlight heads (3.3) sit on the top stand at (3, 19) and (305, 19).

### 3.2 The pitch and its cells

**The geometry of the rules, and why there are two views.** The ball runs on 32 columns by 22 rows. It leaves through the right goal where column - row > 9 and through the left goal where column + row < 22. Those two diagonals cross (at column 15.5, row 6.5), so they cannot both be the ends of one drawn pitch; but each attack only ever goes toward one of them, and the two are mirror images: cell (c, r) on the left goal's side matches cell (31 - c, r) on the right goal's side (c + r < 22 becomes (31 - c) - r > 9). So the match shows **the attacked end**: the right goal view is drawn below, and the left goal view is the same picture with x mirrored (x becomes 319 - x) over rows 34 to 193. The home side attacks the right goal, the away side the left, as the rules say.

**The goal mouth rows.** The goal posts sit where the brief's columns put them: columns 17 to 24 lie on the right goal line (column = 9 + row) at **rows 8 to 15**, and columns 7 to 14 on the left goal line (column = 22 - row) at the same rows. The rules file also says "rows 5 to 13", which does not fit those columns on those lines (at rows 5 to 13 the right line runs through columns 14 to 22). The art draws rows 8 to 15 (GOAL_ROWS in the generator) until James says otherwise (11.2).

**Cell to pixel**, right goal view. A cell is 8 pixels wide and 7 tall; each row starts 3 pixels further left than the row above, so the pitch leans like a pitch seen from the side stand:

- the cell's top left: `(91 + 8c - 3r, 36 + 7r)`, for c 0 to 31, r 0 to 21;
- **a figure's feet** (its origin): `cell_xy(c, r) = (95 + 8c - 3r, 42 + 7r)`, the middle of the cell's bottom row;
- **the ball** (its origin): `ball_xy(c, r) = (95 + 8c - 3r, 39 + 7r)`, the middle of the cell; its shadow 1 right and 3 down;
- **left goal view**: `cell_xy_left(c, r) = (319 - x, y)` where (x, y) = `cell_xy(31 - c, r)`; the same for the ball; every figure is also mirrored (a figure facing the right goal on the right view faces the left goal on the left view).

The cells right of the goal line (column > 9 + row) are off the pitch: the ball only enters them as it leaves.

The background (right goal view), drawn once per view:

| Part | Recipe |
|---|---|
| Run off | Run Off over rows 34 to 193, the full width |
| The goal line | on each pixel row y from 36 to 189, Line at `gx(y) = 91 + 80 + 5 (y - 36) div 7` (the edge after column 9 + row); it runs from (171, 36) to (280, 189) |
| Lines parallel to it | `line_x(y, k) = 91 + 8k + 5 (y - 36) div 7`; the goal line is k = 10 |
| Mown stripes | every pixel left of the goal line on rows 36 to 189: Grass A when ((gx(y) - 1 - x) div 16) is even, else Grass B (stripes 16 wide, parallel to the goal line) |
| Touch lines | Line on row 36 from x 0 to gx(36), and on row 189 from x 0 to gx(189) (rows 0 and 21 of the grid) |
| Penalty area | k = 5 (5 cells in front of the line), rows 4 to 19: Line at line_x(y, 5) for y 64 to 175, and across from it to the goal line on y 64 and y 175 |
| Goal area | k = 8, rows 7 to 16: Line at line_x(y, 8) for y 85 to 154, and across on y 85 and y 154 |
| Penalty spot | 2 x 1 Line at y 116, x midway between line_x(116, 6) and line_x(116, 7) |
| The goal | the foot of the far post at (gx(92), 92), the top of row 8; the near post at (gx(147), 147), the bottom of row 15. Posts 14 pixels tall, Post with a Silver 3 column on their right; the crossbar along the line 14 pixels up, Post with Silver 3 beside it; the net behind, 10 pixels to the right of the line from the ground to the bar, Net where (x + y) mod 3 = 0 else Net Dark; the back posts and the roof edge of the net in Net |
| Left edge | the grid's column 0 is not a line: the grass runs on to x 0 |

**The attack layout.** Seven figures: the keeper, the dribbler (one cell behind the ball, on the ball's row), two more attackers and three defenders, on the cells the game gives. The keeper stands on **c = 8 + r** (right goal; c + r = 23 at the left goal), rows 8 to 13, and steps along that diagonal toward the ball's row one cell at a time (a step is 120 ms of run frames). Attackers face the goal; defenders and the keeper face the ball. The ball moves **two columns a step**, toward the goal (8.3 gives its trail), and drifts a row when the game says.

### 3.3 Stands, crowd, hoardings and floodlights

- **Crowd**: the tiles `crowd_1` (sitting) and `crowd_2` (cheering) of 32 x 8, repeated every 32 pixels from x 0. On a goal the two tiles swap every 150 ms for 1200 ms (section 7).
- **Hoardings**: 4 rows of Hoarding, then blocks of lettering 2 rows tall on the middle 2 rows, starting at x 3: widths 10, 6, 14, 8, 12 repeating, a gap of 7 after each; block k is Hoarding Warm when k mod 3 = 0, else Hoarding Lit. There are no words on them.
- **Floodlight**: a lamp head of 6 x 3 Floodlight at (x, y); round it a ring of Flood Glow (x - 1 to x + 6, y - 1 to y + 3) and outside that a ring of Flood Haze (x - 2 to x + 7, y - 2 to y + 4).

#### crowd_1 (32 x 8, origin (0, 0))

a 32 x 8 tile of fans, repeated along a stand, sitting

Legend: `B` Crowd Blue `4A74AA`; `C` Crowd Cream `CFC5A8`; `D` Crowd Face Dark `9A6A4C`; `F` Crowd Face `D7A27E`; `G` Crowd Gold `C2903A`; `K` Crowd Shadow `111522`; `P` Crowd Plum `74508C`; `R` Crowd Red `B34A44`.

```
DDKKDDKKDDKKFFKKDDKKFFKKFFKKFFKK
BBKKGGKKRRKKRRKKRRKKCCKKGGKKCCKK
BBKKGGKKRRKKRRKKRRKKCCKKGGKKCCKK
BBKKGGKKRRKKRRKKRRKKCCKKGGKKCCKK
KKFFKKFFKKDDKKDDKKFFKKDDKKFFKKFF
KKGGKKPPKKCCKKPPKKPPKKRRKKRRKKCC
KKGGKKPPKKCCKKPPKKPPKKRRKKRRKKCC
KKGGKKPPKKCCKKPPKKPPKKRRKKRRKKCC
```

#### crowd_2 (32 x 8, origin (0, 0))

a 32 x 8 tile of fans, repeated along a stand, cheering (heads up, arms up)

Legend: `B` Crowd Blue `4A74AA`; `C` Crowd Cream `CFC5A8`; `D` Crowd Face Dark `9A6A4C`; `F` Crowd Face `D7A27E`; `G` Crowd Gold `C2903A`; `K` Crowd Shadow `111522`; `P` Crowd Plum `74508C`; `R` Crowd Red `B34A44`.

```
BBKKDDKKRRKRFFRKRRKCFFCKGGKKFFKK
BBKKGGKKRRKKRRKKRRKKCCKKGGKKCCKK
BBKKGGKKRRKKRRKKRRKKCCKKGGKKCCKK
CKKKGPFFPKKKRRDDKKKKCRDDRKKKCCFF
KKFFKKPPKCDDCKPPKPFFPKRRKKFFKKCC
KKGGKKPPKKCCKKPPKKPPKKRRKKRRKKCC
KKGGKKPPKKCCKKPPKKPPKKRRKKRRKKCC
KKGGKKKKKKCCKKKKKKPPKKKKKKRRKKKK
```

### 3.4 The goal mouth (96 x 64)

Seen **face on from the penalty spot**: a strip of crowd, the wall and the hoardings, the dark stand, the goal frame with the net inside, the grass in front. It is drawn into a frame over the middle of the pitch for every shot (section 6.12) and reused on the title screen. The crossbar is rows 15 to 17, the posts x 10 to 12 and x 83 to 85, the net x 13 to 82 from row 18, the goal line row 47, the six yard line row 56.

The targets (the ball's centre): columns **x 24, 48, 72** (left, middle, right) by rows **y 22, 32, 42** (high, middle, low). Outside the frame: wide left (4, 38), wide right (91, 38), over the bar (48, 9), off the left post (13, 30), off the right post (83, 30). The keeper's ready feet are at (48, 54). On a goal the crowd strip (rows 0 to 7) shows `crowd_2` instead.

#### goal_mouth (96 x 64, top left (0, 0))

Legend: `L` Line `E6EFDA`; `N` Net `B8C4C0`; `P` Post `FFFFFF`; `Q` Silver 3 `B4BECC`; `a` Grass A `3E9440`; `b` Grass B `378A3A`; `c` Crowd Red `B34A44`; `d` Crowd Face Dark `9A6A4C`; `f` Crowd Face `D7A27E`; `g` Ball Shadow `24602A`; `h` Hoarding `102A44`; `k` Crowd Shadow `111522`; `l` Hoarding Lit `3E8CC4`; `m` Net Dark `6C7A76`; `n` Night Haze `0E1626`; `s` Stand `1A2030`; `w` Wall `262C3C`.

```
ddkkddkkddkkffkkddkkffkkffkkffkkddkkddkkddkkffkkddkkffkkffkkffkkddkkddkkddkkffkkddkkffkkffkkffkk
cckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckk
cckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckk
cckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckk
kkffkkffkkddkkddkkffkkddkkffkkffkkffkkffkkddkkddkkffkkddkkffkkffkkffkkffkkddkkddkkffkkddkkffkkff
kkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcc
kkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcc
kkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcckkcc
wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
llllllhhhhhhhhhhhhllllllhhhhhhhhhhhhllllllhhhhhhhhhhhhllllllhhhhhhhhhhhhllllllhhhhhhhhhhhhllllll
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
ssssssssssPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPssssssssss
ssssssssssPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPssssssssss
ssssssssssQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmNNPPQssssssssss
ssssssssssPPQnnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnmnnnPPQssssssssss
ssssssssssPPQNNnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnnmnnNNPPQssssssssss
LLLLLLLLLLPPQLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLPPQLLLLLLLLLL
aaLaaaaaaaaaaggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggaaaaaaaaaaLaa
aLaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaLa
bLbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbLb
LbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbL
LbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbL
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

### 3.5 The board (every menu screen)

| Part | Recipe |
|---|---|
| Frame | four rings from the outside in, each 1 pixel, from row 14 to row 227 and x 0 to 319: Wood 5, Wood 3, Wood 2 (the inlay ring, which changes by division, section 9), Wood 4 |
| Board | Board over x 4 to 315, y 18 to 223 |
| Chalk dust | a board pixel (x, y) is Board Dust when (37x + 101y + (xy mod 17)) mod 71 = 0 (about 1 in 71, baked once) |
| Title band | Board Head over y 18 to 30, a Board Rule on y 31; the title in Chalk Yellow at (10, 21); the right hand note in Chalk Dim, right edge x 309, y 21 |
| Content | from y 33 down to y 223 |
| Table rows | every second row a band of Board Stripe the height of the row; the cursor's row Cursor Row; your club's row Your Row with a Chalk Yellow rule above and below |

## 4. Sprites

### 4.1 The kits and the match figures

The figures (8 x 12, origin (4, 11), facing right) are given once with the shirt in tones 1 to 4; a kit is a tone row plus fixed letters plus a **pattern**, applied before mirroring, to the torso's tone pixels only (the torso is the rows from the first row holding a `1` down to the row above the first `S`):

| Kit | Tone row | `S` shorts | `T` shorts shade | `C` hands | Pattern (becomes `P`) | `P` colour |
|---|---|---|---|---|---|---|
| white | White | Kit Dark Shorts | Kit Dark Shorts Shade | Skin | **a hoop**: the torso's third row (top + 2), all of it | Kit Hoop |
| black | Black | Kit Light Shorts | Kit Light Shorts Shade | Skin | **pinstripes**: torso columns 3 and 5, below the torso's top row | Kit Pinstripe |
| keeper | Keeper | Keeper Shorts | Keeper Shorts Dark | Glove | none (plain shirt, white gloves) |  |

Your side wears the colour picked on the kit screen (6.8), the other side the other one, home or away. Fixed letters in every figure: `A` skin, `B` skin shade, `H` hair, `O` Boot, `C` hands. **Skin and hair vary** by the player's number n (1 to 24): skin pair `n mod 3` (Skin 1, Skin 2, Skin 3, each with its Shade), hair `n mod 4` (Hair Dark, Hair Black, Hair Fair, Hair Ginger). The opposition's figures use their place on the pitch as n. The keeper uses pair 2 and Hair Black on the pitch, as in the close up.

The three kits standing (pattern applied):

#### fig_stand_white (8 x 12, origin (4, 11))

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `P` Kit Hoop `24272E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.C2333C.
.CPPPPC.
..3344..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
```

#### fig_stand_black (8 x 12, origin (4, 11))

Legend: `1234` tones 1, 2, 3, 4 of the Black row (`9AA0AC`, `62687A`, `33373F`, `24272E`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `P` Kit Pinstripe `C8CCD4`; `S` Kit Light Shorts `E2E5EA`; `T` Kit Light Shorts Shade `AEB4BF`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.C2P3PC.
.C3P3PC.
..3P4P..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
```

#### fig_stand_keeper (8 x 12, origin (4, 11))

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.C2333C.
.C3334C.
..3344..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
```

The frames, before the pattern (shown with the White row and the white legend):

#### fig_stand (8 x 12, origin (4, 11))

Standing.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.C2333C.
.C3334C.
..3344..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
```

#### fig_run_1 (8 x 12, origin (4, 11))

Running 1 of 4: contact, right leg forward.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.22333C.
C.3334..
..3344..
..SSST..
.SS..T..
.3....4.
3.....4.
O.....OO
```

#### fig_run_2 (8 x 12, origin (4, 11))

Running 2: passing, the body 1 pixel up.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
........
...HHH..
...HAAA.
...BAA..
..2112..
.C2333..
..33342.
..3344C.
..SSST..
...ST...
...34...
...OO...
```

#### fig_run_3 (8 x 12, origin (4, 11))

Running 3: contact, the other leg.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.C23332.
...334.C
..3344..
..SSST..
..S..TT.
.3.....4
.3.....4
OO......
```

#### fig_run_4 (8 x 12, origin (4, 11))

Running 4: passing.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
........
...HHH..
...HAAA.
...BAA..
..2112..
.22333..
.C3334C.
..3344..
..SSST..
...TS...
...43...
...OO...
```

#### fig_kick_1 (8 x 12, origin (4, 11))

Kicking 1: the wind up (the anticipation frame, shown 80 ms before the ball moves).

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.22333C.
C.3334..
..3344..
..SSST..
.SS..T..
S....4..
3....4..
O....OO.
```

#### fig_kick_2 (8 x 12, origin (4, 11))

Kicking 2: the strike, the leg through; the ball leaves on this frame.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
...HHH..
...HAAA.
...BAA..
..2112..
C22333..
..3334C.
..3344..
..SSSTT.
..S...TT
..3....4
..3.....
..OO....
```

#### fig_cheer_1 (8 x 12, origin (4, 11))

Celebrating 1: arms up.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
.C....C.
.2HHH.2.
.2HAAA2.
..2AA2..
..2112..
..2333..
..3334..
..3344..
..SSST..
..S..T..
..3..4..
..OO.OO.
```

#### fig_cheer_2 (8 x 12, origin (4, 11))

Celebrating 2: a jump, arms wide.

Legend: `1234` tones 1, 2, 3, 4 of the White row (`FFFFFF`, `F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Kit Dark Shorts `24272E`; `T` Kit Dark Shorts Shade `0E1013`.

```
C......C
.2.HHH2.
..2HAA2.
...2AA..
..2112..
..2333..
..3334..
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
```

### 4.2 The keeper on the pitch

Keeper kit (marigold, white gloves). Ready and got it are 8 x 12 with origin (4, 11); the dives are 12 x 12 with origin (6, 11), the middle of the bottom row, which goes on the keeper's cell. **Dive up** is toward the top of the screen (the keeper of the left goal reaching to his left), **dive down** the other way; mirror both for the right goal.

#### gk_ready_1 (8 x 12, origin (4, 11))

Ready 1: the crouch.

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
........
...HHH..
...HAAA.
...BAA..
..2112..
C223332C
..3334..
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
```

#### gk_ready_2 (8 x 12, origin (4, 11))

Ready 2: the bob, 1 pixel lower (400 ms each).

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
........
........
...HHH..
...HAAA.
...BAA..
C.2112.C
.223332.
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
```

#### gk_got_it (8 x 12, origin (4, 11))

Got it: the ball held at the chest (`W` is the ball).

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`; `W` Ball 3 `EEF1F4`.

```
...HHH..
...HAAA.
...BAA..
..2112..
.22333..
.C33WWC.
..3WWW..
..3344..
..SSST..
..S..T..
..3..4..
..OO.OO.
```

#### gk_dive_up_1 (12 x 12, origin (6, 11))

Dive up 1: take off.

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
.....C......
.....2..C...
....2HH2....
....HAAA....
....BAA.....
...2112.....
...23333....
...3334.....
...3344.....
...SSTT.....
..S...4.....
..O....O....
```

#### gk_dive_up_2 (12 x 12, origin (6, 11))

Dive up 2: full stretch.

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
........C.C.
.......2.2..
......2HH...
.....HAAA...
.....BAA....
....2112....
...23333....
...3334.....
..3344......
..SST.......
.S..T.......
O....O......
```

#### gk_dive_down_1 (12 x 12, origin (6, 11))

Dive down 1: going down.

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
............
............
............
...HHH......
...HAAA.....
...BAA.2....
..21123C....
..33334.....
..3344SS....
...SST..T4..
....34....O.
....O.......
```

#### gk_dive_down_2 (12 x 12, origin (6, 11))

Dive down 2: on the ground, full stretch.

Legend: `1234` tones 1, 2, 3, 4 of the Keeper row (`F9E4A2`, `F5D164`, `F2C230`, `AC8C25`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Glove `F4EEDC`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
............
............
............
............
............
............
...........O
..HHH...SS34
.HAAA233SST.
.BAA213344..
C22233344...
C2..........
```

### 4.3 The ball

There is no referee on the pitch in revision 2 (seven figures only), so `ref_stand`, `ref_run_1` and `ref_run_2` are gone.

#### ball_roll_1 (5 x 5, origin (2, 2))

Rolling 1 (origin the middle).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
.555.
51225
52235
53345
.555.
```

#### ball_roll_2 (5 x 5, origin (2, 2))

Rolling 2: the patch moved round (60 ms each while it moves).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
.555.
52135
53225
54335
.555.
```

#### ball_air (5 x 5, origin (2, 2))

In the air: brighter, used for a shot or a long pass; its shadow stays on the ground 3 rows lower.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
.555.
51125
51235
52345
.555.
```

#### ball_shadow (5 x 5, origin (2, 2))

The shadow, drawn 1 right and 3 down of the ball's origin (more when in the air: 1 down per 2 pixels of height).

Legend: `S` Ball Shadow `24602A`.

```
.....
.....
.....
.SSS.
SSSSS
```

### 4.4 The close up keeper

Front view, the Keeper row with `E` Outline round the whole shape so he reads on the net. **Ready, hold and jump are 24 x 32** with the origin at the middle of the feet. The two dives **overhang the brief's 24 x 32**: the low dive is 39 x 21 and the high dive 32 x 28, because a keeper at full stretch is longer than he is wide; their origin is **the middle of the waist** so the goal mouth table (6.24) can place them. Dive left and high dive left are the mirrors.

#### gm_keeper_ready (24 x 32, origin (12, 31))

Ready: crouched, arms out (bobs 1 pixel every 400 ms).

Legend: `234` tones 2, 3, 4 of the Keeper row (`F5D164`, `F2C230`, `AC8C25`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `C` Glove `F4EEDC`; `E` Outline `0A0D0C`; `H` Hair Black `141016`; `K` Eye `141016`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
...........EEE..........
..........EHHHE.........
.........EHHHHHE........
.........EHHHHHE........
.........EHAAAHE........
........EAAKAKAAE.......
.........EAAAAAE........
.........EAAAAAE........
..........EBABE.........
......EEEEEBBBEEEEE.....
.....E222222B222222E....
....E233333333333332E...
...E23333333333334332E..
..E23343333333334E4332E.
.E2334E4333333334EE4332E
.E334E.E33333334E..E334E
.E334E.E33333334E..E434E
.E34E..E33333334E...E34E
.E34E..E44444444E...E34E
ECCCE..ESSSSSSSTE...ECCC
ECCCE..ESSSSSSSTE...ECCC
ECCCE..ESSSSSSSTE...ECCC
.EEE...ETTTTTTTT2E...EEE
.......E222EEE224E......
......E234E...E332E.....
......E434E...E434E.....
.....E2A4E.....E4A2E....
.....E4A4E.....E4A4E....
.....E324E.....E424E....
.....E34E.......E34E....
....EOOOOE.....EOOOOE...
.....E44E.......E44E....
```

#### gm_keeper_hold (24 x 32, origin (12, 31))

Hold: the ball caught at the chest (a save in the middle column, middle or low).

Legend: `234` tones 2, 3, 4 of the Keeper row (`F5D164`, `F2C230`, `AC8C25`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `C` Glove `F4EEDC`; `E` Outline `0A0D0C`; `H` Hair Black `141016`; `K` Eye `141016`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`; `W` Ball 3 `EEF1F4`; `X` Ball 4 `C4CAD4`.

```
...........EEE..........
..........EHHHE.........
.........EHHHHHE........
.........EHHHHHE........
.........EHAAAHE........
........EAAKAKAAE.......
.........EAAAAAE........
.........EAAAAAE........
..........EBABE.........
......EEEEEBBBEEEEE.....
.....E222222B222222E....
....E233333333333332E...
....E333333333333334E...
....E333333WWW333334E...
....E3333CCWWWCC3334E...
....E333CCCCXCCCC334E...
....E3333CCWXXCC3334E...
....E334333WWW334434E...
....E44E44444444EE44E...
.....EEESSSSSSSTE.EE....
.......ESSSSSSSTE.......
.......ESSSSSSSTE.......
.......ETTTTTTTT2E......
.......E222EEE224E......
......E234E...E332E.....
......E434E...E434E.....
.....E2A4E.....E4A2E....
.....E4A4E.....E4A4E....
.....E324E.....E424E....
.....E34E.......E34E....
....EOOOOE.....EOOOOE...
.....E44E.......E44E....
```

#### gm_keeper_jump (24 x 32, origin (12, 31))

Jump: straight up, arms high (a save high in the middle; and the pose for over the bar).

Legend: `234` tones 2, 3, 4 of the Keeper row (`F5D164`, `F2C230`, `AC8C25`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `C` Glove `F4EEDC`; `E` Outline `0A0D0C`; `H` Hair Black `141016`; `K` Eye `141016`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
.......EEE.....EEE......
......ECCCE...ECCCE.....
......ECCCEEEEECCCE.....
......ECCCEHHHECCCE.....
......E334HHHHH334E.....
......E334HHHHH434E.....
......E34EHAAAHE34E.....
......E34AAKAKAA34E.....
......E34EAAAAAE34E.....
......E34EAAAAAE34E.....
......E34EEBABEE34E.....
......E34EEBBBEE34E.....
......E33222B22234E.....
......E43333333344E.....
.......E33333334EE......
.......E33333334E.......
.......E33333334E.......
.......E43333334E.......
........E333334E........
........E333334E........
........E444444E........
........ESSSSSTE........
........ESSSSSTE........
........ESSSSSTE........
.......ETTTTTTTTE.......
........E222E222E.......
........E334EE34E.......
........E334EE342E......
........E44E.E4A4E......
........EAAE.E4A4E......
........E22E..E24E......
........E44E..E44E......
```

#### gm_keeper_dive_right (39 x 21, origin (18, 11))

Dive right: low, almost flat.

Legend: `234` tones 2, 3, 4 of the Keeper row (`F5D164`, `F2C230`, `AC8C25`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `C` Glove `F4EEDC`; `E` Outline `0A0D0C`; `H` Hair Black `141016`; `K` Eye `141016`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
.................................EE....
............................EEEEECCE...
.........................EEE2222CCCE...
......................EEE2223333CCCE...
.....................E222333HHHH4CE....
....................EE333444HHHHEE.....
..................EE22334EEHHAAHHE.....
................EE223334EEEAAKAAHE.....
...............E22333334EBBAAAAAAE.EE..
........EEEEEEE233333334EBBAAAKAAEECCE.
.....EEE222222ST333333332EEEAAAAE2CCCCE
..EEE22AA3334SST333333334EEEE22223CCCE.
.EOOO34AA444ETST433333334E222333444EE..
EOOOO44EEEEEEETST444444442333344EEE....
.EEEEEE...EE222TTEEEEEEEE44444EE.......
.........E22334ETE.......EEEEE.........
.......EEAA344E.E......................
.....EE22AA4EE.........................
....EOOO42EE...........................
...EOOOOEE.............................
....EEEE...............................
```

#### gm_keeper_high_right (32 x 28, origin (14, 12))

High dive right: on a slant, lifted.

Legend: `234` tones 2, 3, 4 of the Keeper row (`F5D164`, `F2C230`, `AC8C25`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `C` Glove `F4EEDC`; `E` Outline `0A0D0C`; `H` Hair Black `141016`; `K` Eye `141016`; `O` Boot `17120E`; `S` Keeper Shorts `20242C`; `T` Keeper Shorts Dark `121418`.

```
................E222HHHHHE..EE..
...............E2334HHHHHE.ECCE.
..............E2334EHAAAHEECCCCE
..............E3334AAKAAAAECCCE.
.............E2334EEAAAKAA234E..
.............E334EEBAAAAA234E...
.............E3332EBBAAA2334E...
............E233332BEEE2334E....
...........E23333332EE2334E.....
...........E3333333322334E......
..........E2333333334334E.......
.........E2433333334E44E........
.........EST4333344E.EE.........
........E2SST4334EE.............
.......E2SSSST44E...............
......E24TSSSSTE................
.....E2332TTSSTE................
....EAA34EE2TTTE................
...E2AA4E.E322E.................
..E2322E.E234E..................
.E2334E.E2434E..................
EOOO4E..EAA4E...................
EOOOE..E22AE....................
.EEE...E332E....................
......E234E.....................
.....EOOOOE.....................
......EOOE......................
.......EE.......................
```

### 4.5 The close up ball and the ripple

The ball flies **away** from the viewer, from (48, 70) below the picture to its target, so it shrinks: near, mid, far (section 7.4). The ripple is drawn centred on the ball before the ball, over the net only (skip pixels outside x 13 to 82, y 18 to 46).

#### gm_ball_near (9 x 9, origin (4, 4))

Near (9 x 9), the first frame of the shot.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
...555...
..51225..
.5112235.
511223345
512233345
522333445
.5334445.
..54445..
...555...
```

#### gm_ball_mid (7 x 7, origin (3, 3))

Mid (7 x 7).

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
..555..
.51225.
5122235
5122345
5223345
.53445.
..555..
```

#### gm_ball_far (5 x 5, origin (2, 2))

Far (5 x 5), on the target.

Legend: `12345` tones 1, 2, 3, 4, 5 of the Ball row (`FFFFFF`, `FFFFFF`, `EEF1F4`, `C4CAD4`, `4A5060`).

```
.555.
51225
52235
53345
.555.
```

#### gm_ripple_1 (24 x 16, origin (12, 8))

Ripple 1: the first ring.

Legend: `L` Spark `FFFFFF`.

```
........................
.........L.L.L..........
......L.L.L.L.L.L.......
.....L.L.........L.L....
....L.............L.L...
...L...............L.L..
..L.L...............L...
...L.................L..
..L.................L...
...L...............L.L..
..L.L...............L...
...L.L.............L....
....L.L.........L.L.....
.......L.L.L.L.L.L......
..........L.L.L.........
........................
```

#### gm_ripple_2 (24 x 16, origin (12, 8))

Ripple 2: the ring spreads, an inner ring of Net.

Legend: `L` Spark `FFFFFF`; `N` Net `B8C4C0`.

```
..L.L.L...........L.L...
.L.L...N.N.N.N.N...L.L..
L.L...N.N.......N.N...L.
.L...N...........N.N...L
L...N...............N...
...N.................N..
..N.................N.N.
.N...................N..
..N...................N.
.N.N.................N..
..N.................N...
...N...............N...L
L...N.N...........N...L.
.L...N.N.......N.N...L.L
..L.L...N.N.N.N.N...L.L.
...L.L...........L.L.L..
```

#### gm_ripple_3 (24 x 16, origin (12, 8))

Ripple 3: fading (Net only).

Legend: `N` Net `B8C4C0`.

```
..N.N...............N...
.N...................N.N
N.....................N.
.......................N
........................
........................
........................
........................
........................
........................
........................
........................
N.......................
.N.....................N
N.N...................N.
...N...............N.N..
```

### 4.6 Club badges (16 x 16) and mini badges (8 x 8)

Eight badges, assigned **by slot**: the club in slot s (1 to 16) of its division gets badge `(s - 1) mod 8` in the order below (star, hoops, tower, anchor, tree, chevron, fish, kettle), so every division shows each badge twice, slots s and s + 8. The mini badge for the status bar and the tables is the badge sampled at every odd pixel (x and y 1, 3, 5, ... 15), given below so no code has to do it.

#### badge_star (16 x 16, origin (0, 0))

red and white halves, a gold star

Legend: `A` Badge Red `D8433A`; `B` Badge White `F3EEE0`; `C` Badge Gold `F2B630`; `E` Badge Edge `0E0B0A`.

```
................
.EEEEEEEEEEEEEE.
.EAAAAAABBBBBBE.
.EAAAAACBBBBBBE.
.EAAAAACBBBBBBE.
.EAACCCCCCCBBBE.
.EAAACCCCCBBBBE.
.EAAAACCCBBBBBE.
.EAAACCACCBBBBE.
.EAAACAABCBBBBE.
..EAAAAABBBBBE..
...EAAAABBBBE...
....EAAABBBE....
.....EEABEE.....
.......EE.......
................
```

#### badge_hoops (16 x 16, origin (0, 0))

gold and black hoops, a white ball

Legend: `A` Badge Gold `F2B630`; `B` Badge Black `22222A`; `C` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
................
.....EEEEEE.....
....EAAAAAAE....
...EBBBBBBBBE...
..EBBBCCCBBBBE..
.EBBBCCBCCBBBBE.
.EAACCAAACCAAAE.
.EAACAAAAACAAAE.
.EAACCAAACCAAAE.
.EBBBCCBCCBBBBE.
.EBBBBCCCBBBBBE.
..EBBBBBBBBBBE..
...EAAAAAAAAE...
....EAAAAAAE....
.....EEEEEE.....
................
```

#### badge_tower (16 x 16, origin (0, 0))

navy, a white tower

Legend: `A` Badge Navy `203A6E`; `C` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
................
.EEEEEEEEEEEEEE.
.EAAAAAAAAAAAAE.
.EAACACACACAAAE.
.EAACCCCCCCAAAE.
.EAAACCCCCAAAAE.
.EAAACCCCCAAAAE.
.EAAACCACCAAAAE.
.EAAACCACCAAAAE.
.EAACCCCCCCAAAE.
..EAAAAAAAAAAE..
...EAAAAAAAAE...
....EAAAAAAE....
.....EEAAEE.....
.......EE.......
................
```

#### badge_anchor (16 x 16, origin (0, 0))

sky blue, a navy anchor

Legend: `A` Badge Sky `62BAF0`; `C` Badge Navy `203A6E`; `E` Badge Edge `0E0B0A`.

```
................
.....EEEEEE.....
....EAAAAAAE....
...EAAAAAAAAE...
..EAAAACAAAAAE..
.EAAAACACAAAAAE.
.EAAAAACAAAAAAE.
.EAAACCCCCAAAAE.
.EAAAAACAAAAAAE.
.EAACAACAACAAAE.
.EAAACCCCCAAAAE.
..EAAAAAAAAAAE..
...EAAAAAAAAE...
....EAAAAAAE....
.....EEEEEE.....
................
```

#### badge_tree (16 x 16, origin (0, 0))

green with a gold border, a gold oak

Legend: `A` Badge Green `2F8A4A`; `B` Badge Gold `F2B630`; `C` Badge Gold `F2B630`; `E` Badge Edge `0E0B0A`.

```
................
.EEEEEEEEEEEEEE.
.EBBBBBBBBBBBBE.
.EBAAACCCAAAABE.
.EBAACCCCCAAABE.
.EBACCCCCCCAABE.
.EBAACCCCCAAABE.
.EBAAAACAAAAABE.
.EBAAAACAAAAABE.
.EBAAACCCAAAABE.
..EBAAAAAAAABE..
...EBAAAAAABE...
....EBBAABBE....
.....EEBBEE.....
.......EE.......
................
```

#### badge_chevron (16 x 16, origin (0, 0))

purple, a white chevron

Legend: `A` Badge Purple `7046AE`; `B` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
................
.EEEEEEEEEEEEEE.
.EAAAAAAAAAAAAE.
.EAAAAAAAAAAAAE.
.EAAAAAAAAAAAAE.
.EAAAAABBAAAAAE.
.EAAAABBBBAAAAE.
.EAAABBBBBBAAAE.
.EAABBBAABBBAAE.
.EBBBBAAAABBBBE.
..EBBAAAAAABBE..
...EAAAAAAAAE...
....EAAAAAAE....
.....EEAAEE.....
.......EE.......
................
```

#### badge_fish (16 x 16, origin (0, 0))

teal and white stripes, a navy fish

Legend: `A` Badge Teal `1E9A9A`; `B` Badge White `F3EEE0`; `C` Badge Navy `203A6E`; `E` Badge Edge `0E0B0A`.

```
................
.EEEEE....EEEEE.
.EBBAAEEEEBBAAE.
.EBBAABBAABBAAE.
.EBBAACCAABBAAE.
.EBBACCCCACBAAE.
.EBBCACCCCCBAAE.
.EBBACCCCACBAAE.
.EBBAACCAABBAAE.
.EBBAABBAABBAAE.
.EBBAABBAABBAAE.
..EBAABBAABBAE..
...EEABBAABEE...
.....EEBAEE.....
.......EE.......
................
```

#### badge_kettle (16 x 16, origin (0, 0))

orange and white quarters, a black kettle

Legend: `A` Badge Orange `EE8A2E`; `B` Badge White `F3EEE0`; `C` Badge Black `22222A`; `E` Badge Edge `0E0B0A`.

```
................
.....EEEEEE.....
....EAAABBBE....
...EAAAABBBBE...
..EAAACCBBBBBE..
.EAAACAACBBBBBE.
.EAAACCCCBCBBBE.
.EAACCCCCCBBBBE.
.EBBBCCCCAAAAAE.
.EBBBCCCCAAAAAE.
.EBBBBBBAAAAAAE.
..EBBBBBAAAAAE..
...EBBBBAAAAE...
....EBBBAAAE....
.....EEEEEE.....
................
```

#### mini_star (8 x 8, origin (0, 0))

the 8 x 8 badge_star for the status bar and the tables

Legend: `A` Badge Red `D8433A`; `B` Badge White `F3EEE0`; `C` Badge Gold `F2B630`; `E` Badge Edge `0E0B0A`.

```
EEEEEEE.
EAACBBB.
EACCCBB.
EAACBBB.
EACACBB.
.EAABB..
..EAE...
........
```

#### mini_hoops (8 x 8, origin (0, 0))

the 8 x 8 badge_hoops for the status bar and the tables

Legend: `A` Badge Gold `F2B630`; `B` Badge Black `22222A`; `C` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
..EEE...
.EBBBB..
EBCBCBB.
EAAAAAA.
EBCBCBB.
.BBBBBE.
..AAAE..
........
```

#### mini_tower (8 x 8, origin (0, 0))

the 8 x 8 badge_tower for the status bar and the tables

Legend: `A` Badge Navy `203A6E`; `C` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
EEEEEEE.
EAAAAAA.
EACCCAA.
EACACAA.
EACCCAA.
.EAAAA..
..EAE...
........
```

#### mini_anchor (8 x 8, origin (0, 0))

the 8 x 8 badge_anchor for the status bar and the tables

Legend: `A` Badge Sky `62BAF0`; `C` Badge Navy `203A6E`; `E` Badge Edge `0E0B0A`.

```
..EEE...
.EAAAA..
EAAAAAA.
EACCCAA.
EAACAAA.
.AAAAAE.
..AAAE..
........
```

#### mini_tree (8 x 8, origin (0, 0))

the 8 x 8 badge_tree for the status bar and the tables

Legend: `A` Badge Green `2F8A4A`; `B` Badge Gold `F2B630`; `C` Badge Gold `F2B630`; `E` Badge Edge `0E0B0A`.

```
EEEEEEE.
EAACAAB.
EACCCAB.
EAACAAB.
EAACAAB.
.EAAAB..
..EBE...
........
```

#### mini_chevron (8 x 8, origin (0, 0))

the 8 x 8 badge_chevron for the status bar and the tables

Legend: `A` Badge Purple `7046AE`; `B` Badge White `F3EEE0`; `E` Badge Edge `0E0B0A`.

```
EEEEEEE.
EAAAAAA.
EAABAAA.
EABBBAA.
EBBAABB.
.EAAAA..
..EAE...
........
```

#### mini_fish (8 x 8, origin (0, 0))

the 8 x 8 badge_fish for the status bar and the tables

Legend: `A` Badge Teal `1E9A9A`; `B` Badge White `F3EEE0`; `C` Badge Navy `203A6E`; `E` Badge Edge `0E0B0A`.

```
EEE..EE.
EBABABA.
EBCCABA.
EBCCABA.
EBABABA.
.BABABE.
..EBE...
........
```

#### mini_kettle (8 x 8, origin (0, 0))

the 8 x 8 badge_kettle for the status bar and the tables

Legend: `A` Badge Orange `EE8A2E`; `B` Badge White `F3EEE0`; `C` Badge Black `22222A`; `E` Badge Edge `0E0B0A`.

```
..EEE...
.EAABB..
EACABBB.
EACCCBB.
EBCCAAA.
.BBBAAE.
..BBAE..
........
```

### 4.7 Faces (24 x 24)

Eight faces, reused as `face = player number mod 8` (the manager uses face_8 on the set up screen). The shirt at the bottom is the White row with a Kit Hoop collar; for a side in black the game swaps the White row for the Black row. `P` is the collar.

#### face_1 (24 x 24, origin (0, 0))

short dark hair, a smile

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Dark `2E1C12`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGHHHHHHGGGGGGGGG
GGGGGGGHHHHHHHHHHHGGGGGG
GGGGGGHHHHHHHHHHHHHGGGGG
GGGGGGHHHHHHHHHHHHHGGGGG
GGGGGGHHAAAAHHHHHHGGGGGG
GGGGGGHAAAAAAAAAABGGGGGG
GGGGGGGAHHHAAAHHHBGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFAAABAAAFBGGGGGG
GGGGGGGAAAAABBAAABGGGGGG
GGGGGGGGAMAAAAAMBGGGGGGG
GGGGGGGGAAMMMMMABGGGGGGG
GGGGGGGGGAAAAAABGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_2 (24 x 24, origin (0, 0))

a big round afro, a wide grin

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGHHHHHHHGGGGGGGG
GGGGGGGHHHHHHHHHHHGGGGGG
GGGGGHHHHHHAAAHHHHHHGGGG
GGGGGHHHHHHHHHHHHHHHGGGG
GGGGHHHHAAAAAAAAHHHHHGGG
GGGGHHHHAAAAAAAABHHHHGGG
GGGHHHHAAAAAAAAAABHHHHGG
GGGHHHHAHHHAAAHHHBHHHHGG
GGGHHHHAAAAAAAAAABHHHHGG
GGGGHHAAWKAAAAWKAABHHGGG
GGGGHHBAAAAAAAAAABBHHGGG
GGGGGHHAFAAABAAAFBHHGGGG
GGGGGHHAAAAABBAAABHHGGGG
GGGGGGGHAMMMMMMMBHGGGGGG
GGGGGGGGAAWWWWWABGGGGGGG
GGGGGGGGGAMMMMMBGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_3 (24 x 24, origin (0, 0))

shaved head, a full beard

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 3 `8A5634`; `B` Skin 3 Shade `633A20`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGBBBBBBGGGGGGGGG
GGGGGGGBBBBBBBBBBGGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGGAKKKAAAKKKBGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFAAABAAAFBGGGGGG
GGGGGGGHHHHHHHHHHHGGGGGG
GGGGGGGGHHHHHHHHHGGGGGGG
GGGGGGGGHHMMMMMHHGGGGGGG
GGGGGGGGGHHHHHHHGGGGGGGG
GGGGGGGGGGHHHHGGGGGGGGGG
GGGGGGGGGGHHHHGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_4 (24 x 24, origin (0, 0))

a ginger mop and freckles

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Ginger `B8542A`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGHHHHHHHHGGGGGGGG
GGGGGGHHHHHHHHHHHHGGGGGG
GGGGGHHHHHHHHHHHHHHGGGGG
GGGGGHHHHHHHHHHHHHHGGGGG
GGGGGHHHHHHHHHHHHHHGGGGG
GGGGGHHHHAHAAHAHBHGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGGAHHHAAAHHHBGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFFAABAAFFBGGGGGG
GGGGGGGAAAFABBFAABGGGGGG
GGGGGGGGAMAAAAAMBGGGGGGG
GGGGGGGGAAMMMMMABGGGGGGG
GGGGGGGGGAAAAAABGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_5 (24 x 24, origin (0, 0))

long fair hair and a headband

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `D` Magnet Red 3 `E2493E`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Fair `E2B85A`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGHHHGGGGGGGGGG
GGGGGGGGHHHHHHHHGGGGGGGG
GGGGGGHHHHHHHHHHHHGGGGGG
GGGGGGHHHHHHHHHHHHGGGGGG
GGGGGGDDDDDDDDDDDDDGGGGG
GGGGGGHHAAAAAAAABHHGGGGG
GGGGGHHAAAAAAAAAABHHGGGG
GGGGGHHAHHHAAAHHHBHHGGGG
GGGGGHHAAAAAAAAAABHHGGGG
GGGGGHAAWKAAAAWKAABHGGGG
GGGGGHBAAAAAAAAAABBHGGGG
GGGGGHHAFAAABAAAFBHHGGGG
GGGGGHHAAAAABBAAABHHGGGG
GGGGGGHHAMAAAAAMBHHGGGGG
GGGGGGHHAAMMMMMABHHGGGGG
GGGGGGGHHAAAAAABHHGGGGGG
GGGGGGGHHHHAABHHHHGGGGGG
GGGGGGGGGHHHHHHHGGGGGGGG
GGGGGGGG2PBHHHP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_6 (24 x 24, origin (0, 0))

a quiff and a proud moustache

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Dark `2E1C12`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGHHHHHHHHGGGGGG
GGGGGGGGHHHHHHHHHHHGGGGG
GGGGGGHHHHHHHHHHHHHGGGGG
GGGGGGHHHHHHHHHHHHHGGGGG
GGGGGGHHAAAAAAAABGGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGGAHHHAAAHHHBGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFAAABAAAFBGGGGGG
GGGGGGGAAAAABBAAABGGGGGG
GGGGGGGGAAHHHHHABGGGGGGG
GGGGGGGGAHMMMMMHBGGGGGGG
GGGGGGGGGAAAAAABGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_7 (24 x 24, origin (0, 0))

short hair with a side parting, serious

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 3 `8A5634`; `B` Skin 3 Shade `633A20`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGHHHHHHGGGGGGGGG
GGGGGGGHHAHHHHHHHHGGGGGG
GGGGGGHHHHHHHHHHHHHGGGGG
GGGGGGHHHHAAAAAABGGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGGAHHHAAAHHHBGGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFAAABAAAFBGGGGGG
GGGGGGGAAAAABBAAABGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGGGAAMMMMMABGGGGGGG
GGGGGGGGGAAAAAABGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

#### face_8 (24 x 24, origin (0, 0))

grey and thinning, a grin: the veteran

Legend: `234` tones 2, 3, 4 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Eye White `F6F2EA`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Grey `B4B4B0`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Kit Hoop `24272E`; `W` Eye White `F6F2EA`.

```
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGCCAAGGGGGGGGGG
GGGGGGGGGAAAAAABGGGGGGGG
GGGGGGGGAAAAAAAABGGGGGGG
GGGGGGHHAAAAAAAABHHGGGGG
GGGGGGHHAAAAAAAAAHHGGGGG
GGGGGGHHKKKAAAKKKHHGGGGG
GGGGGGGAAAAAAAAAABGGGGGG
GGGGGGAAWKAAAAWKAABGGGGG
GGGGGGBAAAAAAAAAABBGGGGG
GGGGGGGAFAAABAAAFBGGGGGG
GGGGGGGAAAAABBAAABGGGGGG
GGGGGGGGAMHHHHHMBGGGGGGG
GGGGGGGGAHWWWWWHBGGGGGGG
GGGGGGGGGAMMMMMBGGGGGGGG
GGGGGGGGGGBAABGGGGGGGGGG
GGGGGGGGGGBBBBGGGGGGGGGG
GGGGGGGG2PBBBBP22GGGGGGG
GGGGG22233P33P333222GGGG
GGGG2333333PP33333332GGG
GGG2333333333333333332GG
GG244444444444444444442G
```

The kit screen's two big shirts (24 x 24, top left origin):

#### shirt_white (24 x 24, origin (0, 0))

the white kit, big, for the kit screen

Legend: `2345` tones 2, 3, 4, 5 of the White row (`F6F7F9`, `E2E5EA`, `AEB4BF`, `545A68`); `P` Kit Hoop `24272E`; `V` Kit Hoop `24272E`.

```
........55555555........
.....55522V222V2555.....
....5222333V3V332225....
...523333333V33333325...
..52333333333333333325..
..53333333333333333345..
.5233333333333333333325.
.5333333333333333333345.
523333333333333333333325
.5443433333333333343445.
..55453333333333345455..
....55PPPPPPPPPPPP55....
.....5PPPPPPPPPPPP5.....
.....5PPPPPPPPPPPP5.....
.....5PPPPPPPPPPPP5.....
.....53333333333345.....
.....53333333333345.....
.....53333333333345.....
.....53333333333345.....
.....53333333333345.....
.....53333333333345.....
.....54444444444445.....
......555555555555......
........................
```

#### shirt_black (24 x 24, origin (0, 0))

the black kit, big, for the kit screen

Legend: `2345` tones 2, 3, 4, 5 of the Black row (`62687A`, `33373F`, `24272E`, `0E1013`); `P` Kit Pinstripe `C8CCD4`; `V` Kit Pinstripe `C8CCD4`.

```
........55555555........
.....55522V222V2555.....
....5222333V3V332225....
...523333333V33333325...
..5233333P333P333P3325..
..5333333P333P333P3345..
.52333333P333P333P33325.
.53333333P333P333P33345.
523333333P333P333P333325
.54434333P333P333P43445.
..5545333P333P333P5455..
....55333P333P333P55....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5333P333P333P5.....
.....5444P444P444P5.....
......555555555555......
........................
```

### 4.8 Icons (8 x 8)

Every icon is a shape first and a colour second. Most have a 1 pixel `E` Icon Edge so they read on any ground. Placed by the top left.

#### pos_gk (8 x 8, origin (0, 0))

goalkeeper: a glove

Legend: `E` Icon Edge `0A0D0C`; `P` Pos GK `F2C230`; `W` Glove `F4EEDC`.

```
.E.E.E..
EPEPEPE.
EPPPPPE.
EPPPPPPE
EPPPPPE.
.EPPPPE.
.EWWWE..
..EEE...
```

#### pos_df (8 x 8, origin (0, 0))

defender: a shield

Legend: `E` Icon Edge `0A0D0C`; `P` Pos DF `62BAF0`; `W` Spark `FFFFFF`.

```
.EEEEEE.
EPPPPPPE
EPWPPPPE
EPPPPPPE
EPPPPPPE
.EPPPPE.
..EPPE..
...EE...
```

#### pos_mf (8 x 8, origin (0, 0))

midfielder: a diamond

Legend: `E` Icon Edge `0A0D0C`; `P` Pos MF `7FE39A`; `W` Spark `FFFFFF`.

```
...EE...
..EPPE..
.EPPPPE.
EPPWPPPE
.EPPPPE.
..EPPE..
...EE...
........
```

#### pos_fw (8 x 8, origin (0, 0))

forward: an arrow

Legend: `E` Icon Edge `0A0D0C`; `P` Pos FW `FF8A3D`.

```
....E...
...EPE..
.EEEPPE.
EPPPPPPE
.EEEPPE.
...EPE..
....E...
........
```

#### state_injured (8 x 8, origin (0, 0))

injured: a red cross on a plaster

Legend: `E` Icon Edge `0A0D0C`; `R` Chalk Red `FF6F61`; `W` Plaster `F4E2C4`.

```
...EE...
..EWWE..
.EERREE.
EWRRRRWE
EWRRRRWE
.EERREE.
..EWWE..
...EE...
```

#### state_tired (8 x 8, origin (0, 0))

tired (energy 6 or less): two Zs

Legend: `E` Icon Edge `0A0D0C`; `Z` Zzz `8CC8FF`.

```
.EEE....
EZZZE...
.EEZEE..
.EZEZZE.
EZZZEZE.
.EEEZZE.
....EE..
........
```

#### state_form (8 x 8, origin (0, 0))

in form (energy 16 or more and fit): a flame

Legend: `E` Icon Edge `0A0D0C`; `F` Flame `FF8A3D`; `Y` Flame Core `FFE07A`.

```
...E....
..EFEE..
.EFFEFE.
.EFFFFE.
EFFYYFE.
EFYYYYFE
.EFYYFE.
..EEEE..
```

#### ev_goal (8 x 8, origin (0, 0))

goal: the ball in the net

Legend: `E` Icon Edge `0A0D0C`; `N` Net `B8C4C0`; `W` Ball 3 `EEF1F4`.

```
.EEEEEE.
ENNNNNNE
ENENENE.
.ENEWWE.
ENEWWWWE
.ENWWWWE
ENENWWE.
.E.EEE..
```

#### ev_injury (8 x 8, origin (0, 0))

injury: a red cross

Legend: `E` Icon Edge `0A0D0C`; `R` Chalk Red `FF6F61`.

```
...EE...
..ERRE..
.EERREE.
ERRRRRRE
ERRRRRRE
.EERREE.
..ERRE..
...EE...
```

#### ev_whistle (8 x 8, origin (0, 0))

whistle: kick off and full time

Legend: `E` Icon Edge `0A0D0C`; `K` Silver 5 `3E4656`; `S` Silver 3 `B4BECC`.

```
.....EE.
.EEEESSE
ESSSSSSE
ESKKSSSE
ESKKSSE.
.ESSEE..
..EE....
........
```

#### ev_save (8 x 8, origin (0, 0))

a save: two gloves and the ball

Legend: `C` Glove `F4EEDC`; `E` Icon Edge `0A0D0C`; `W` Ball 3 `EEF1F4`.

```
.E....E.
ECE..ECE
ECCEECCE
.ECCCCE.
.ECWWCE.
..EWWE..
...EE...
........
```

#### ev_wide (8 x 8, origin (0, 0))

wide: a post and the ball beside it

Legend: `E` Icon Edge `0A0D0C`; `P` Post `FFFFFF`; `W` Ball 3 `EEF1F4`.

```
.E......
EPE.E...
EPEEWE..
EPE.E...
EPE.....
EPE.....
.E......
........
```

#### ev_block (8 x 8, origin (0, 0))

blocked: a defender and the ball turned back

Legend: `E` Icon Edge `0A0D0C`; `S` Chalk Dim `93A89A`; `W` Ball 3 `EEF1F4`.

```
..EE....
.ESSE...
ESSSSE..
.ESSEWE.
.ESSEE..
ESEESE..
.E..E...
........
```

#### money_coin (8 x 8, origin (0, 0))

cash in credit: a gold coin

Legend: `D` Gold 4 `B07A1C`; `E` Icon Edge `0A0D0C`; `G` Gold 3 `F2B630`; `H` Gold 1 `FFF4C0`; `S` Gold 4 `B07A1C`.

```
..EEEE..
.EGGGGE.
EGHGGGGE
EGGDDGGE
EGGDDGGE
EGGGGGSE
.EGSSSE.
..EEEE..
```

#### money_owed (8 x 8, origin (0, 0))

cash in debt: a cracked red coin

Legend: `D` Spent Dark `A83A32`; `E` Icon Edge `0A0D0C`; `H` Spark Warm `FFF2A8`; `R` Chalk Red `FF6F61`; `S` Spent Dark `A83A32`.

```
..EE.EE.
.ERRERRE
ERHRERRE
ERREDRRE
ERRDERRE
ERRERRSE
.ERSESE.
..EE.E..
```

#### money_bank (8 x 8, origin (0, 0))

the bank (repay)

Legend: `E` Icon Edge `0A0D0C`; `S` Silver 3 `B4BECC`.

```
...EE...
..ESSE..
.ESSSSE.
ESSSSSSE
.ESESESE
.ESESESE
ESSSSSSE
.EEEEEE.
```

#### money_loan (8 x 8, origin (0, 0))

the loan: a note with a red seal

Legend: `E` Icon Edge `0A0D0C`; `L` Silver 4 `7A8698`; `P` Envelope `E8DCC0`; `R` Chalk Red `FF6F61`.

```
.EEEEE..
EPPPPPE.
EPLLLPPE
EPPPPPPE
EPLLLLPE
EPPPRRPE
EPPPRRPE
.EEEEEE.
```

#### money_ground (8 x 8, origin (0, 0))

the ground (gate receipts, rent)

Legend: `B` Brick `B0563C`; `E` Icon Edge `0A0D0C`; `G` Turf `3E9440`.

```
.E....E.
EBE..EBE
EBBEEBBE
EBBBBBBE
EBGGGGBE
EBGGGGBE
.EEEEEE.
........
```

#### money_wages (8 x 8, origin (0, 0))

the wage packet

Legend: `E` Icon Edge `0A0D0C`; `P` Envelope `E8DCC0`; `S` Envelope Shade `B0A280`.

```
.EEEEEE.
EPPPPPPE
EPSPPSPE
EPPSSPPE
EPPPPPPE
EPPPPPPE
.EEEEEE.
........
```

#### morale (8 x 8, origin (0, 0))

morale: a smiling face

Legend: `C` Chalk Blue `8CC8FF`; `E` Icon Edge `0A0D0C`; `K` Board `14231E`.

```
..EEEE..
.ECCCCE.
ECKCCKCE
ECCCCCCE
ECKCCKCE
ECCKKCCE
.ECCCCE.
..EEEE..
```

#### kit_white (8 x 8, origin (0, 0))

the white kit (a black hoop), for the score bar

Legend: `3` White 3 `E2E5EA`; `E` Icon Edge `0A0D0C`; `P` Kit Hoop `24272E`.

```
.EE..EE.
E33EE33E
E333333E
.E3333E.
.EPPPPE.
.E3333E.
..EEEE..
........
```

#### kit_black (8 x 8, origin (0, 0))

the black kit (pale pinstripes), for the score bar

Legend: `3` Black 3 `33373F`; `E` Icon Edge `0A0D0C`; `P` Kit Pinstripe `C8CCD4`.

```
.EE..EE.
E33EE33E
E3P3P33E
.EP3P3E.
.EP3P3E.
.EP3P3E.
..EEEE..
........
```

#### mark_up (8 x 8, origin (0, 0))

promotion zone marker

Legend: `G` Chalk Green `7FE39A`.

```
........
...G....
..GGG...
.GGGGG..
...G....
...G....
........
........
```

#### mark_down (8 x 8, origin (0, 0))

relegation zone marker

Legend: `R` Chalk Red `FF6F61`.

```
........
...R....
...R....
.RRRRR..
..RRR...
...R....
........
........
```

#### mark_star (8 x 8, origin (0, 0))

the lit star beside a club that went up

Legend: `Y` Chalk Yellow `FFDA5C`.

```
........
...Y....
...Y....
YYYYYYY.
.YYYYY..
..YYY...
.YY.YY..
........
```

#### magnet_on (8 x 8, origin (0, 0))

picked to start: a red tactics magnet

Legend: `E` Icon Edge `0A0D0C`; `H` Magnet Red 1 `F2ADA8`; `R` Magnet Red 3 `E2493E`; `S` Magnet Red 4 `99352D`.

```
..EEEE..
.ERRRRE.
ERHRRRRE
ERRRRRRE
ERRRRRRE
ERRRRRSE
.ERSSSE.
..EEEE..
```

#### magnet_res (8 x 8, origin (0, 0))

the reserve: a blue ring magnet

Legend: `E` Icon Edge `0A0D0C`; `H` Magnet Blue 1 `A9D7F5`; `R` Magnet Blue 3 `3FA6E8`; `S` Magnet Blue 4 `2D729D`.

```
..EEEE..
.ERRRRE.
ERHEERRE
ERE..ERE
ERE..ERE
ERREERSE
.ERSSSE.
..EEEE..
```

#### cursor_1 (8 x 8, origin (0, 0))

the chalk arrow cursor, frame 1

Legend: `Y` Chalk Yellow `FFDA5C`.

```
........
.YY.....
.YYYY...
.YYYYYY.
.YYYY...
.YY.....
........
........
```

#### cursor_2 (8 x 8, origin (0, 0))

frame 2: one pixel right

Legend: `Y` Chalk Yellow `FFDA5C`.

```
........
..YY....
..YYYY..
..YYYYY.
..YYYY..
..YY....
........
........
```

### 4.9 Trophies

#### trophy_league (32 x 32, origin (16, 31))

the league trophy: a gold cup on a wooden plinth

Legend: `12345` tones 1, 2, 3, 4, 5 of the Gold row (`FFF4C0`, `FFDD70`, `F2B630`, `B07A1C`, `5A3A10`); `V` Wood 2 `C89052`; `W` Wood 3 `9A6634`; `X` Wood 5 `2A170C`; `Y` Gold 2 `FFDD70`.

```
.............5555555............
.......555555222222255555.......
......52224444444444444225......
......533344444444444443455.....
....5523331333333333333345255...
...522343313333333333334523225..
..52334533133333333333345543325.
...5345533313333333333345.5345..
...533253331333333333334552345..
...543454331333333333334553345..
....53455331333333333345.5345...
....5432543133333333345.52345...
.....545.54333333333345..545....
......5...543333333345....5.....
...........5443333445...........
............55433455............
..............5345..............
..............5345..............
..............5345..............
..............5345..............
...........5555345555...........
..........522223322225..........
.........5233333333345..........
........55444444444442555.......
.......5VVVVVVVVVVVVVVVVV5......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWYYYYYYYYYWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5XXXXXXXXXXXXXXXXX5......
........55555555555555555.......
```

#### trophy_cup (32 x 32, origin (16, 31))

the cup: the same shape in silver

Legend: `12345` tones 1, 2, 3, 4, 5 of the Silver row (`FFFFFF`, `E0E6EE`, `B4BECC`, `7A8698`, `3E4656`); `V` Wood 2 `C89052`; `W` Wood 3 `9A6634`; `X` Wood 5 `2A170C`; `Y` Gold 2 `FFDD70`.

```
.............5555555............
.......555555222222255555.......
......52224444444444444225......
......533344444444444443455.....
....5523331333333333333345255...
...522343313333333333334523225..
..52334533133333333333345543325.
...5345533313333333333345.5345..
...533253331333333333334552345..
...543454331333333333334553345..
....53455331333333333345.5345...
....5432543133333333345.52345...
.....545.54333333333345..545....
......5...543333333345....5.....
...........5443333445...........
............55433455............
..............5345..............
..............5345..............
..............5345..............
..............5345..............
...........5555345555...........
..........522223322225..........
.........5233333333345..........
........55444444444442555.......
.......5VVVVVVVVVVVVVVVVV5......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWYYYYYYYYYWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5WWWWWWWWWWWWWWWW5.......
.......5XXXXXXXXXXXXXXXXX5......
........55555555555555555.......
```

#### cab_league (12 x 16, origin (6, 15))

the league trophy in the cabinet

Legend: `12345` tones 1, 2, 3, 4, 5 of the Gold row (`FFF4C0`, `FFDD70`, `F2B630`, `B07A1C`, `5A3A10`); `V` Wood 2 `C89052`; `W` Wood 3 `9A6634`.

```
..55555555..
.52222222255
523313333452
533313333454
544333333454
.554333345.5
...543345...
....5345....
....545.....
...554555...
..52232225..
..544444455.
.5VVVVVVVVV5
.5WWWWWWWW5.
.5WWWWWWWW5.
..55555555..
```

#### cab_cup (12 x 16, origin (6, 15))

the cup in the cabinet

Legend: `12345` tones 1, 2, 3, 4, 5 of the Silver row (`FFFFFF`, `E0E6EE`, `B4BECC`, `7A8698`, `3E4656`); `V` Wood 2 `C89052`; `W` Wood 3 `9A6634`.

```
..55555555..
.52222222255
523313333452
533313333454
544333333454
.554333345.5
...543345...
....5345....
....545.....
...554555...
..52232225..
..544444455.
.5VVVVVVVVV5
.5WWWWWWWW5.
.5WWWWWWWW5.
..55555555..
```

## 5. Text

### 5.1 The 5 x 7 font and six new glyphs

The house font as it is (capitals, digits, `- < > = ? . : ! +` and space; 6 pixels a character at 1x). Six glyphs are added for this game: `/ , ' ( ) %`.

#### glyph `/` (5 x 7)

```
....#
....#
...#.
..#..
.#...
#....
#....
```

#### glyph `,` (5 x 7)

```
.....
.....
.....
.....
..##.
..#..
.#...
```

#### glyph `'` (5 x 7)

```
..#..
..#..
.#...
.....
.....
.....
.....
```

#### glyph `(` (5 x 7)

```
...#.
..#..
.#...
.#...
.#...
..#..
...#.
```

#### glyph `)` (5 x 7)

```
.#...
..#..
...#.
...#.
...#.
..#..
.#...
```

#### glyph `%` (5 x 7)

```
##...
##..#
...#.
..#..
.#...
#..##
...##
```

### 5.2 Money

An amount is a sign then up to 7 digits, with **2 extra pixels (at 1x; 4 at 2x) before each group of 3 digits** counted from the right, so 1 234 567 reads without commas. The sign is always drawn for cash, gate, costs and prizes (`+` in Chalk Green, `-` in Chalk Red); a loan, a value, a bid and an offer have no sign and keep the plain colour. Widths at 1x: `+1 234 567` is 56 pixels, `-18 450` is 39.

### 5.3 The 3 x 5 font

For the column heads of the squad, the chart's scale, the energy numbers, the pick screen's labels and numbers. 4 pixels a character. `#` is a lit pixel.

```
 0    1    2    3    4    5    6    7    8    9    A    B 
###  .#.  ##.  ##.  #.#  ###  .##  ###  ###  ###  .#.  ##.
#.#  ##.  ..#  ..#  #.#  #..  #..  ..#  #.#  #.#  #.#  #.#
#.#  .#.  .#.  .#.  ###  ##.  ###  .#.  ###  ###  ###  ##.
#.#  .#.  #..  ..#  ..#  ..#  #.#  .#.  #.#  ..#  #.#  #.#
###  ###  ###  ##.  ..#  ##.  ###  .#.  ###  ##.  #.#  ##.

 C    D    E    F    G    H    I    J    K    L    M    N 
.##  ##.  ###  ###  .##  #.#  ###  ..#  #.#  #..  #.#  ##.
#..  #.#  #..  #..  #..  #.#  .#.  ..#  #.#  #..  ###  #.#
#..  #.#  ##.  ##.  #.#  ###  .#.  ..#  ##.  #..  ###  #.#
#..  #.#  #..  #..  #.#  #.#  .#.  #.#  #.#  #..  #.#  #.#
.##  ##.  ###  #..  .##  #.#  ###  .#.  #.#  ###  #.#  #.#

 O    P    Q    R    S    T    U    V    W    X    Y    Z 
.#.  ##.  .#.  ##.  .##  ###  #.#  #.#  #.#  #.#  #.#  ###
#.#  #.#  #.#  #.#  #..  .#.  #.#  #.#  #.#  #.#  #.#  ..#
#.#  ##.  #.#  ##.  .#.  .#.  #.#  #.#  ###  .#.  .#.  .#.
#.#  #..  ##.  #.#  ..#  .#.  #.#  #.#  ###  #.#  .#.  #..
.#.  #..  .##  #.#  ##.  .#.  ###  .#.  #.#  #.#  .#.  ###

 -    +    .    :    /    %    _ 
...  ...  ...  ...  ..#  #.#  ...
...  .#.  ...  .#.  ..#  ..#  ...
###  ###  ...  ...  .#.  .#.  ...
...  .#.  ...  .#.  #..  #..  ...
...  ...  .#.  ...  #..  #.#  ...

```

## 6. Screens

Each screen is a list of "this, in this colour, at this x and y" (the top left of the text or sprite unless it says centred or right edge). A row of a table gives the first row and the step. Font `5 x 7, 2x` is the house font at 2x; `3 x 5` the small font.

### 6.1 The status bar (every menu screen)

| What | Font | Colour | x | y |
|---|---|---|---|---|
| mini badge of your club (8 x 8) | sprite |  | 3 | 3 |
| your club name, up to 12 characters | 5 x 7, 1x | Chalk Yellow | 14 | 4 |
| WK n (week 1 to 15 and the cup weeks) | 5 x 7, 1x | Chalk Blue | 94 | 4 |
| DIV n | 5 x 7, 1x | Chalk Blue | 128 | 4 |
| money_coin, or money_owed when the cash is below 0 | sprite |  | 162 | 3 |
| the cash: sign and digits, group gaps (section 5.2), ends by x 222 | 5 x 7, 1x | Chalk Green or Chalk Red | 172 | 4 |
| money_loan | sprite |  | 228 | 3 |
| the loan: digits with group gaps, no sign, ends by x 284 | 5 x 7, 1x | Chalk | 238 | 4 |
| morale icon | sprite |  | 288 | 3 |
| the morale, 2 digits, right aligned | 5 x 7, 1x | Chalk Blue | 298 | 4 |

The bar is Tunnel over rows 0 to 12 with a Tunnel Rule on row 13. On the set up screens the bar is plain Tunnel (there is no club yet).

### 6.2 The board and the key bar

The board is section 3.5. The key bar is Tunnel over rows 228 to 239 with a Tunnel Rule on row 228; from x 6 on y 231, each key in Chalk Yellow, 4 pixels, its meaning in Chalk Dim, 10 pixels to the next key.

### 6.3 Bars and pips

| Bar | Recipe |
|---|---|
| Energy (1 to 20) | 20 units, 2 pixels a unit (40 x 5 in the squad, 40 x 4 on the pick screen) over Bar Empty. Level: **fresh** 13 to 20, Chalk Green, solid, the bottom row Fresh Dark; **weary** 7 to 12, Chalk Amber with every 4th column Weary Dark (dashes); **spent** 1 to 6, Chalk Red and Spent Dark in a check. The last lit column is Chalk (the marker). Ticks of Bar Tick under units 6 and 12 (the threshold marks). Spent pulses: the whole fill turns Spent Dark for 200 ms every 600 ms |
| Morale (1 to 20) | 10 pips of 3 x 5, every 4 pixels; a pip is 2 points, an odd point lights its first 2 columns; the same three levels and colours as energy; the top left pixel of a full pip is Chalk. Used on the week menu and the end of season where a bar would be too wide |
| Skill (1 to 5) | 5 squares (3 x 3 every 4 pixels; 5 x 5 every 6 on the transfer card), Chalk Yellow lit, Bar Empty unlit |
| Your number against theirs | two bars of 20 units at 5 pixels a unit, 4 rows each with 1 row between: yours Chalk Yellow, theirs Chalk Blue, over Bar Empty; after them the two numbers in the 3 x 5 font, and after yours a **+** (Chalk Green) when you are level or ahead, a **-** (Chalk Red) when behind |
| Loan meter | 124 x 6 over Bar Empty, filled loan / limit in Bar Plain with the last column Chalk; a Chalk Dim tick 12 rows tall at the limit. No warning colours (the original gives none) |

### 6.4 Plates

A plate (for PAUSED, full time, results of a bid, promoted): a 1 pixel Outline ring, Tunnel inside, a 1 pixel rule 2 pixels in from the top and from the bottom (inset 2 at the sides). The rule colour says what kind of news it is: Chalk Yellow (neutral), Chalk Green (good), Chalk Red (bad).

### 6.5 Title and attract

Drawn on the Night ground with no status bar. The goal mouth picture of section 3.4 is reused, framed by the stand.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| stars: 14 single pixels (list in section 7.1) | pixel | Star | 14 | 6 |
| floodlight pylon (2 x 46) | fill | Roof | 22 | 20 |
| floodlight pylon (2 x 46) | fill | Roof | 292 | 20 |
| floodlight lamp heads (6 x 3, with the glow rings of section 3.3) | floodlight | Floodlight | 20 | 14 |
| floodlight lamp head | floodlight | Floodlight | 290 | 14 |
| the roof (320 x 2) | fill | Roof | 0 | 66 |
| the roof edge (320 x 1) | fill | Roof Edge | 0 | 68 |
| the stand (320 x 35) | fill | Stand | 0 | 69 |
| 3 rows of crowd tiles from x -32 every 32, row n shifted 11 n pixels right (mod 32) | sprite crowd_1 (crowd_2 on a goal) |  | -16 | 71 |
| the front wall (320 x 2) | fill | Wall | 0 | 98 |
| the hoardings (section 3.3) | hoardings |  | 0 | 100 |
| the pitch: bands of Grass A and Grass B, 6, 7, 8, 10, 12, 14, 17, 20, 24 and 30 rows tall | fill | Grass A / Grass B | 0 | 104 |
| the goal: goal mouth rows 14 to 46 only (the frame and the net), skipping its Stand pixels, with the picture's row 0 at y 96 | goal mouth |  | 112 | 96 |
| the goal line, the full width | fill | Line | 0 | 145 |
| the keeper (bobbing 1 pixel every 400 ms) (origin on this point) | sprite gm_keeper_ready |  | 160 | 152 |
| the box the name fills (x 40 to 279, y 8 to 49): see the name rule under this table | dashed box (preview only) | Chalk Dim | 40 | 8 |
| the line under the name (centred on x 160) | 5 x 7, 1x | Chalk | 83 | 54 |
| the ball flying at the goal (intro, section 7.1) (origin on this point) | sprite gm_ball_near |  | 136 | 186 |
| a banner plate 128 x 19 (section 6.4) | plate | Tunnel | 96 | 204 |
| PRESS SPACE, on 500 ms, off 300 ms (centred on x 160) | 5 x 7, 1x | Chalk Yellow | 128 | 210 |
| the key bar (320 x 12) | fill | Tunnel | 0 | 228 |
| the hint line (centred on x 160) | 5 x 7, 1x | Chalk Dim | 29 | 231 |

**The name rule.** The game's name is a text constant, drawn in the 5 x 7 font with a vertical gradient from Title Top to Title Bottom, an Outline and a 2 pixel Title Shadow drop down and right, centred on x 160. Up to 8 characters: one line at 5x, top at y 14. 9 to 16 characters: split at the space nearest the middle into two lines, each at 3x (a line of up to 16 characters is at most 285 pixels), tops at y 8 and y 31. Then the line under the name at y 54. The dashed box in the preview marks the area the name fills.

### 6.6 New game 1: the manager and the level

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the board with the title "NEW GAME" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "STEP 1 OF 3" | 5 x 7, 1x | Chalk Dim | 245 | 21 |
| the key bar: ENTER NEXT  UP DOWN LEVEL  ESC BACK | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| no status bar yet: the strip is plain Tunnel (320 x 14) | fill | Tunnel | 0 | 0 |
| label | 5 x 7, 1x | Chalk Dim | 16 | 40 |
| the name box (126 x 13) | fill | Board Head | 14 | 50 |
| the name box rule (126 x 1) | fill | Chalk Dim | 14 | 62 |
| the name typed so far (up to 20 characters) | 5 x 7, 1x | Chalk | 17 | 53 |
| the text cursor, a block, on 500 ms off 300 ms (5 x 7) | fill | Chalk Yellow | 90 | 53 |
| label | 5 x 7, 1x | Chalk Dim | 16 | 76 |
| level number, row i at y = 88 + 13 i | 5 x 7, 1x | Chalk Dim | 20 | 88 |
| level name | 5 x 7, 1x | Chalk | 32 | 88 |
| difficulty pips: 7 squares 3 x 3 every 5 pixels, the first (level) lit | fill | Chalk Amber / Bar Empty | 120 | 90 |
| the band under the cursor's level, 13 rows from y - 3 | fill | Cursor Row | 4 | 111 |
| the cursor | sprite cursor_1 |  | 8 | 114 |
| a wood frame round the face (30 x 30) | fill | Wood 3 | 222 | 46 |
| the manager (decoration only) | sprite face_8 |  | 225 | 49 |
| caption (centred on x 237) | 5 x 7, 1x | Chalk Dim | 208 | 82 |

### 6.7 New game 2: pick a club

Four pages, one a division, 16 clubs a page in two columns of 8, with their 16 x 16 badges.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the board with the title "PICK A CLUB" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "DIVISION 4, PAGE 4 OF 4" | 5 x 7, 1x | Chalk Dim | 173 | 21 |
| the key bar: ARROWS MOVE  ENTER PICK  PAGE DIVISION | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| no status bar yet: the strip is plain Tunnel (320 x 14) | fill | Tunnel | 0 | 0 |
| badge, club i at x = 14 + 152 (i div 8), y = 38 + 23 (i mod 8) | sprite badge_star |  | 14 | 38 |
| club name at badge x + 22, y + 5 | 5 x 7, 1x | Chalk | 36 | 43 |
| the cursor band (148 x 20) | fill | Cursor Row | 10 | 82 |

### 6.8 New game 3: your colours

Replaces the pick 12 screen (the squad is dealt at random). Your side wears the colour picked, the other side the other one.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the board with the title "YOUR COLOURS" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "STEP 3 OF 3" | 5 x 7, 1x | Chalk Dim | 245 | 21 |
| the key bar: LEFT RIGHT CHOOSE  ENTER START | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| no status bar yet: the strip is plain Tunnel (320 x 14) | fill | Tunnel | 0 | 0 |
| line (centred on x 160) | 5 x 7, 1x | Chalk Dim | 107 | 42 |
| card 1 (88 x 104), Cursor Row when chosen, else Board Stripe (88 x 104) | fill | Cursor Row | 52 | 60 |
| the chosen card's 1 pixel Chalk Yellow ring | lines | Chalk Yellow | 52 | 60 |
| the big shirt | sprite shirt_white |  | 84 | 70 |
| the kit on two figures (fig_stand and fig_run_1, pattern applied), top left | sprites |  | 78 | 104 |
| the colour, 2x (centred on x 96) | 5 x 7, 2x | Chalk Yellow | 67 | 124 |
| the pattern (centred on x 96) | 5 x 7, 1x | Chalk Dim | 85 | 146 |
| card 2 (88 x 104), Cursor Row when chosen, else Board Stripe (88 x 104) | fill | Board Stripe | 180 | 60 |
| the big shirt | sprite shirt_black |  | 212 | 70 |
| the kit on two figures (fig_stand and fig_run_1, pattern applied), top left | sprites |  | 206 | 104 |
| the colour, 2x (centred on x 224) | 5 x 7, 2x | Chalk | 195 | 124 |
| the pattern (centred on x 224) | 5 x 7, 1x | Chalk Dim | 204 | 146 |
| the cursor beside the chosen card | sprite cursor_1 |  | 40 | 108 |
| line: BLACK or WHITE, the colour not chosen (centred on x 160) | 5 x 7, 1x | Chalk | 83 | 182 |

### 6.9 The week menu

The first screen of every week: the choices of the original menu, and the next match.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "MANAGER'S OFFICE" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "WEEK 10" | 5 x 7, 1x | Chalk Dim | 269 | 21 |
| the key bar: 1-7 CHOOSE  ENTER PLAY THE MATCH | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| key, item i at y = 42 + 18 i | 5 x 7, 1x | Chalk Yellow | 20 | 42 |
| icon | sprite money_coin |  | 30 | 41 |
| item | 5 x 7, 1x | Chalk | 42 | 42 |
| the cursor band (17 rows from y - 5) (150 x 17) | fill | Cursor Row | 4 | 145 |
| the cursor | sprite cursor_1 |  | 8 | 150 |
| the rule between the halves (1 x 170) | fill | Board Rule | 166 | 40 |
| label (centred on x 242) | 5 x 7, 1x | Chalk Dim | 213 | 42 |
| LEAGUE, or F.A. CUP and the round name (centred on x 242) | 5 x 7, 1x | Chalk Blue | 225 | 54 |
| your badge | sprite badge_tower |  | 196 | 70 |
| their badge | sprite badge_kettle |  | 272 | 70 |
| V (centred on x 242) | 5 x 7, 2x | Chalk Dim | 237 | 75 |
| your club (centred on x 242) | 5 x 7, 1x | Chalk Yellow | 222 | 94 |
| their club (centred on x 242) | 5 x 7, 1x | Chalk | 216 | 104 |
| HOME or AWAY (Chalk Blue) (centred on x 242) | 5 x 7, 1x | Chalk Green | 231 | 116 |
| their place (centred on x 242) | 5 x 7, 1x | Chalk Dim | 207 | 132 |
| your place (centred on x 242) | 5 x 7, 1x | Chalk Dim | 210 | 142 |
| label (centred on x 242) | 5 x 7, 1x | Chalk Dim | 216 | 164 |
| the last result, 2x: WON (Chalk Green), DREW (Chalk), LOST (Chalk Red) (centred on x 242) | 5 x 7, 2x | Chalk Green | 201 | 176 |

### 6.10 The squad

The STATUS choice. 16 rows; the right hand panel shows the player under the cursor.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "THE SQUAD" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "14 OF 16" | 5 x 7, 1x | Chalk Dim | 263 | 21 |
| the key bar: UP DOWN MOVE  ESC BACK | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| head | 5 x 7, 1x | Chalk Dim | 30 | 35 |
| head | 3 x 5 | Chalk Dim | 108 | 36 |
| head | 3 x 5 | Chalk Dim | 134 | 36 |
| head (right edge x 250) | 3 x 5 | Chalk Dim | 232 | 36 |
| rule under the heads (254 x 1) | fill | Board Rule | 4 | 44 |
| picked mark (magnet_on to start, magnet_res the reserve) | sprite magnet_on |  | 4 | 46 |
| position icon, row i at y = 47 + 11 i | sprite pos_df |  | 16 | 46 |
| name (Chalk Dim if injured) | 5 x 7, 1x | Chalk | 30 | 47 |
| skill: 5 pips 3 x 3 every 4 pixels (section 6.3) | pips | Chalk Yellow / Bar Empty | 108 | 49 |
| energy bar 40 x 5 (section 6.3) | bar | by level | 134 | 48 |
| energy number, 2 digits | 3 x 5 | Chalk Dim | 177 | 48 |
| value, no sign (right edge x 250) | 5 x 7, 1x, money, no sign | Chalk | 220 | 47 |
| every second row: a band 11 rows tall from y - 2 | fill | Board Stripe | 4 | 56 |
| state icon (injured, tired, in form), nothing when plain fit | sprite state_form |  | 186 | 68 |
| the cursor band (254 x 11) | fill | Cursor Row | 4 | 111 |
| an empty place in the squad | 5 x 7, 1x | Chalk Dim | 30 | 201 |
| the panel rule (1 x 190) | fill | Board Rule | 262 | 33 |
| a wood frame round the face (30 x 30) | fill | Wood 3 | 272 | 40 |
| the face (the game picks one of 8 by the player's number) | sprite face_4 |  | 275 | 43 |
| the surname, centred on x 287 | 3 x 5 | Chalk Yellow | 274 | 76 |
| position | sprite pos_mf |  | 283 | 86 |
| label | 3 x 5 | Chalk Dim | 268 | 100 |
| label | 3 x 5 | Chalk Dim | 268 | 116 |
| state | sprite state_form |  | 296 | 124 |
| label | 3 x 5 | Chalk Dim | 268 | 150 |
| the whole wage bill a week (a cost: Chalk Red) | 3 x 5 | Chalk Red | 282 | 166 |

### 6.11 Pick the team

Left: the squad with the picks. Right: the five numbers, yours over theirs, and the shape of the team on a chalk pitch.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "PICK THE TEAM" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "V MIZZLE C." | 5 x 7, 1x | Chalk Dim | 245 | 21 |
| the key bar: ENTER PICK  R RESERVE  SPACE KICK OFF | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| pick mark, row i at y = 38 + 13 i | sprite magnet_on |  | 6 | 37 |
| name | 5 x 7, 1x | Chalk | 30 | 38 |
| energy bar 40 x 4 | bar | by level | 102 | 39 |
| the cursor band (160 x 13) | fill | Cursor Row | 4 | 139 |
| injured: cannot be picked | sprite state_injured |  | 146 | 141 |
| the panel rule (1 x 190) | fill | Board Rule | 168 | 34 |
| key: your bars | 5 x 7, 1x | Chalk Yellow | 176 | 36 |
| key: their bars | 5 x 7, 1x | Chalk Blue | 206 | 36 |
| label, number i at y = 50 + 21 i | 3 x 5 | Chalk Dim | 176 | 50 |
| the pair of bars, 5 pixels a point (section 6.3) | compare bars | Chalk Yellow / Chalk Blue | 176 | 57 |
| the chalk pitch: a 132 x 62 outline and a halfway line | lines | Chalk Dim | 176 | 158 |
| the 11 magnets of the shape, 4-4-2, centred on (x + 6, 31), (x + 26, 9 / 23 / 39 / 53), (x + 48, the same), (x + 62, 23 / 39) from the pitch's top left; the keeper's magnet in the Keeper row | sprite magnet_on |  | 176 | 158 |
| the shape, from the picks (centred on x 275) | 5 x 7, 1x | Chalk Dim | 261 | 186 |

### 6.12 The match

One attack at a time on the pitch of the rules (3.2): seven figures, the ball two columns a step. The view is of the goal being attacked; the left goal's view is the mirror. The close up opens over the far corner for the shot.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the match background, right goal view (3.1, 3.2); for the left goal the rows 34 to 193 mirrored | background |  | 0 | 0 |
| the score bar (320 x 18) | fill | Tunnel | 0 | 0 |
| its rule (320 x 1) | fill | Tunnel Rule | 0 | 17 |
| home mini badge | sprite mini_tower |  | 4 | 5 |
| home side's kit icon (kit_white or kit_black) | sprite kit_white |  | 14 | 5 |
| home club (your club in Chalk Yellow, the other in Chalk) | 5 x 7, 1x | Chalk Yellow | 24 | 6 |
| home goals, 2x (right edge x 152) | 5 x 7, 2x | Chalk Yellow | 143 | 2 |
| the dash, 2x (centred on x 160) | 5 x 7, 2x | Chalk Dim | 155 | 2 |
| away goals, 2x | 5 x 7, 2x | Chalk Yellow | 168 | 2 |
| away club (right edge x 295) | 5 x 7, 1x | Chalk | 243 | 6 |
| away side's kit icon | sprite kit_black |  | 298 | 5 |
| away mini badge | sprite mini_kettle |  | 308 | 5 |
| the seven figures: feet on cell_xy(c, r) (the attack layout is under this table) | sprites |  | 0 | 0 |
| the ball on cell (18, 12): ball_xy, its shadow 1 right and 3 down, the trail of 8.3 | sprite ball_roll_1 |  | 203 | 123 |
| the ticker (320 x 22) | fill | Tunnel | 0 | 206 |
| its rule (320 x 1) | fill | Tunnel Rule | 0 | 206 |
| the event icon | sprite ev_save |  | 6 | 213 |
| the ticker line (up to 40 characters) | 5 x 7, 1x | Chalk | 18 | 214 |
| the running attack count (right edge x 313) | 5 x 7, 1x | Chalk Dim | 267 | 214 |
| the key bar (320 x 12) | fill | Tunnel | 0 | 228 |
| keys | 5 x 7, 1x | Chalk Yellow | 6 | 231 |
| the close up frame: Outline ring (right goal view; at x 212 for the left goal) (102 x 70) | fill | Outline | 6 | 84 |
| then a Chalk Yellow ring (100 x 68) | fill | Chalk Yellow | 7 | 85 |
| then Outline again (98 x 66) | fill | Outline | 8 | 86 |
| the goal mouth picture (section 3.4) | goal mouth |  | 9 | 87 |
| the keeper, high dive to the right (the goal mouth table, 6.24) (origin on this point) | sprite gm_keeper_high_right |  | 70 | 122 |
| the ball at the top right target, in the gloves: SAVED (origin on this point) | sprite gm_ball_mid |  | 81 | 109 |

**The attack in the preview** (right goal view; for the left goal use `cell_xy_left` and mirror each figure):

| Figure | Cell (c, r) | Kit | Frame | Faces |
|---|---|---|---|---|
| keeper | (19, 11) | keeper | gk_ready_1 | left |
| attacker | (17, 12) | white | fig_kick_1 | right |
| attacker | (13, 8) | white | fig_run_2 | right |
| attacker | (14, 17) | white | fig_run_4 | right |
| defender | (17, 9) | black | fig_run_1 | left |
| defender | (20, 14) | black | fig_stand | left |
| defender | (15, 16) | black | fig_run_3 | left |

| Who | Where |
|---|---|
| the keeper | on c = 8 + r (right goal) or c + r = 23 (left goal), rows 8 to 13, faces the play |
| the dribbler | one cell behind the ball, faces the goal |
| two more attackers | on the cells the game gives, face the goal |
| three defenders | on the cells the game gives, face the ball |

The ball is on (18, 12), struck from (16, 12) and (14, 12) before it: two columns a step.

### 6.13 Full time

A plate over the last frame of the pitch: the score and the counts of the attacks. No half time and no scorers, as the original.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the match background, right goal view (3.1, 3.2); for the left goal the rows 34 to 193 mirrored | background |  | 0 | 0 |
| the score bar (320 x 18) | fill | Tunnel | 0 | 0 |
| a plate 192 x 120 (section 6.4) | plate | Tunnel | 64 | 50 |
| title (centred on x 160) | 5 x 7, 1x | Chalk Yellow | 134 | 57 |
| home badge | sprite badge_tower |  | 92 | 72 |
| away badge | sprite badge_kettle |  | 212 | 72 |
| home goals, 3x (right edge x 150) | 5 x 7, 3x | Chalk Yellow | 136 | 70 |
| dash (centred on x 160) | 5 x 7, 3x | Chalk Dim | 153 | 70 |
| away goals, 3x | 5 x 7, 3x | Chalk Yellow | 170 | 70 |
| WON (Chalk Green), DRAWN (Chalk), LOST (Chalk Red) (centred on x 160) | 5 x 7, 1x | Chalk Green | 152 | 96 |
| your count, row i at y = 112 + 11 i (right edge x 110) | 5 x 7, 1x | Chalk | 106 | 112 |
| label (centred on x 160) | 5 x 7, 1x | Chalk Dim | 140 | 112 |
| their count | 5 x 7, 1x | Chalk | 210 | 112 |

### 6.14 Results

This week's result and the other matches of the division (the original's random pairings), then the next match.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "RESULTS" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "WEEK 10" | 5 x 7, 1x | Chalk Dim | 269 | 21 |
| the key bar: ENTER MONEY | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| your match: home badge | sprite badge_tower |  | 30 | 38 |
| home | 5 x 7, 1x | Chalk Yellow | 50 | 43 |
| score 2x (centred on x 160) | 5 x 7, 2x | Chalk Yellow | 143 | 39 |
| away (right edge x 270) | 5 x 7, 1x | Chalk | 218 | 43 |
| away badge | sprite badge_kettle |  | 274 | 38 |
| rule (292 x 1) | fill | Board Rule | 14 | 60 |
| label (centred on x 160) | 5 x 7, 1x | Chalk Dim | 95 | 66 |
| home club, row i at y = 80 + 12 i (right edge x 146) | 5 x 7, 1x | Chalk | 88 | 80 |
| score (centred on x 160) | 5 x 7, 1x | Chalk Yellow | 152 | 80 |
| away club | 5 x 7, 1x | Chalk | 175 | 80 |
| rule (292 x 1) | fill | Board Rule | 14 | 170 |
| label | 5 x 7, 1x | Chalk Dim | 20 | 180 |
| the next match | 5 x 7, 1x | Chalk | 50 | 180 |
| a cup week adds this line | sprite ev_whistle |  | 20 | 196 |
| the cup line | 5 x 7, 1x | Chalk Blue | 32 | 197 |

### 6.15 The money report

The week's money, then a 10 week chart of the cash and the loan against its limit. L and R open the loan and repay boxes.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "MONEY REPORT" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "WEEK 10" | 5 x 7, 1x | Chalk Dim | 269 | 21 |
| the key bar: L LOAN  R REPAY  ENTER THE TABLE | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| icon, line i at y = 40 + 13 i | sprite money_ground |  | 14 | 39 |
| label | 5 x 7, 1x | Chalk | 26 | 40 |
| amount, sign always drawn (right edge x 150) | 5 x 7, 1x, money | Chalk Green | 114 | 40 |
| the sum rule (125 x 1) | fill | Chalk Dim | 26 | 92 |
| label | 5 x 7, 1x | Chalk Yellow | 26 | 97 |
| the week's total (right edge x 150) | 5 x 7, 1x, money | Chalk Green | 120 | 97 |
| label | 5 x 7, 1x | Chalk | 26 | 118 |
| money_owed when the cash is below 0, else money_coin | sprite money_owed |  | 14 | 117 |
| the cash, 2x (right edge x 150) | 5 x 7, 2x, money | Chalk Red | 77 | 114 |
| label | 5 x 7, 1x | Chalk | 26 | 140 |
| icon | sprite money_loan |  | 14 | 139 |
| the loan, 2x, no sign | 5 x 7, 2x, money | Chalk | 77 | 136 |
| label | 5 x 7, 1x | Chalk Dim | 26 | 160 |
| the limit (250 000 times the division multiplier) (right edge x 150) | 5 x 7, 1x, money, no sign | Chalk Dim | 114 | 160 |
| the loan meter: 124 x 6, filled loan / limit (124 x 6) | fill | Bar Empty | 26 | 176 |
| fill Bar Plain, the last column Chalk; the same at every level | bar | Bar Plain | 26 | 176 |
| the limit tick (1 x 12) | fill | Chalk Dim | 149 | 173 |
| percent of the limit | 3 x 5 | Chalk Dim | 26 | 186 |
| the panel rule (1 x 190) | fill | Board Rule | 168 | 34 |
| chart title | 3 x 5 | Chalk Dim | 176 | 36 |
| the zero line (y 110) (128 x 1) | fill | Chalk Dim | 176 | 110 |
| 10 bars 8 wide every 12 pixels from x 180: 1 pixel a 500, up to 60; credit up from the line, solid Chalk Green; debt down, checked Chalk Red and Spent Dark; a Chalk cap on the end | bars | Chalk Green / Chalk Red | 180 | 110 |
| scale | 3 x 5 | Chalk Dim | 176 | 50 |
| scale | 3 x 5 | Chalk Dim | 176 | 166 |
| week numbers under the bars | 3 x 5 | Chalk Dim | 182 | 178 |

### 6.16 The league table

The house table: 16 rows of 11, zones marked at the left, your club on a band with an arrow.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "DIVISION 3" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "AFTER 9 OF 15" | 5 x 7, 1x | Chalk Dim | 233 | 21 |
| the key bar: ENTER TRANSFER OFFER | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| head POS (right edge x 22) | 5 x 7, 1x | Chalk Dim | 6 | 35 |
| head CLUB | 5 x 7, 1x | Chalk Dim | 38 | 35 |
| head P (right edge x 140) | 5 x 7, 1x | Chalk Dim | 136 | 35 |
| head W (right edge x 160) | 5 x 7, 1x | Chalk Dim | 156 | 35 |
| head D (right edge x 180) | 5 x 7, 1x | Chalk Dim | 176 | 35 |
| head L (right edge x 200) | 5 x 7, 1x | Chalk Dim | 196 | 35 |
| head F (right edge x 226) | 5 x 7, 1x | Chalk Dim | 222 | 35 |
| head A (right edge x 250) | 5 x 7, 1x | Chalk Dim | 246 | 35 |
| head GD (right edge x 276) | 5 x 7, 1x | Chalk Dim | 266 | 35 |
| head PTS (right edge x 306) | 5 x 7, 1x | Chalk Dim | 290 | 35 |
| rule under the heads (312 x 1) | fill | Board Rule | 4 | 44 |
| promotion places 1 to 3 (not in division 1) | sprite mark_up |  | 6 | 49 |
| position, row i at y = 48 + 11 i (right edge x 22) | 5 x 7, 1x | Chalk | 18 | 48 |
| mini badge | sprite mini_star |  | 26 | 47 |
| club | 5 x 7, 1x | Chalk | 38 | 48 |
| goal difference: + or - always drawn (right edge x 276) | 5 x 7, 1x | Chalk | 260 | 48 |
| points (right edge x 306) | 5 x 7, 1x | Chalk | 296 | 48 |
| every second row: a band 11 tall from y - 2 | fill | Board Stripe | 4 | 57 |
| your club: a Your Row band (312 x 11) | fill | Your Row | 4 | 68 |
| and a Chalk Yellow rule over it (312 x 1) | fill | Chalk Yellow | 4 | 68 |
| and under it (312 x 1) | fill | Chalk Yellow | 4 | 78 |
| relegation places 14 to 16 (not in division 4) | sprite mark_down |  | 6 | 192 |
| a dashed rule (2 on, 2 off) under place 3, Chalk Green | dashes | Chalk Green | 4 | 78 |
| a dashed rule over place 14, Chalk Red (not in division 4) | dashes | Chalk Red | 4 | 188 |

**Column positions** (5 x 7 at 1x, numbers right aligned on these right edges): zone marker x 6; POS right edge 22; mini badge x 26; CLUB x 38 (10 characters, to x 96); P 140; W 160; D 180; L 200; F 226; A 250; GD 276 (sign always drawn); PTS 306. Rows from y 48, every 11 (the 16th at y 213).

### 6.17 The transfer offer

One player a week. Type a bid; the result plate replaces the bid box.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "TRANSFER OFFER" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "SQUAD 14 OF 16" | 5 x 7, 1x | Chalk Dim | 227 | 21 |
| the key bar: DIGITS BID  ENTER OFFER  ESC NO THANKS | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| the player card (280 x 92) | fill | Board Stripe | 20 | 40 |
| its top rule (280 x 1) | fill | Board Rule | 20 | 40 |
| the face frame (30 x 30) | fill | Wood 3 | 32 | 50 |
| the face | sprite face_2 |  | 35 | 53 |
| name, 2x | 5 x 7, 2x | Chalk Yellow | 74 | 50 |
| position | sprite pos_fw |  | 74 | 70 |
| position name | 5 x 7, 1x | Chalk | 86 | 71 |
| label | 5 x 7, 1x | Chalk Dim | 74 | 86 |
| skill: 5 pips 5 x 5 every 6 pixels | pips | Chalk Yellow / Bar Empty | 110 | 86 |
| label | 5 x 7, 1x | Chalk Dim | 74 | 100 |
| energy bar 40 x 5 | bar | by level | 116 | 100 |
| label | 5 x 7, 1x | Chalk Dim | 190 | 86 |
| the value, 2x, no sign | 5 x 7, 2x, money, no sign | Chalk | 190 | 98 |
| its bottom rule (280 x 1) | fill | Board Rule | 20 | 131 |
| label | 5 x 7, 1x | Chalk Dim | 30 | 146 |
| the bid box (140 x 22) | fill | Board Head | 28 | 158 |
| its rule (140 x 1) | fill | Chalk Yellow | 28 | 179 |
| the bid as typed, 2x, no sign | 5 x 7, 2x, money | Chalk Yellow | 34 | 162 |
| the cursor block, on 500 ms off 300 ms (10 x 14) | fill | Chalk Yellow | 98 | 162 |
| label | 5 x 7, 1x | Chalk Dim | 190 | 150 |
| the cash | 5 x 7, 1x, money | Chalk Red | 190 | 162 |
| label | 5 x 7, 1x | Chalk Dim | 190 | 176 |
| limit less loan (what you could still borrow), no sign | 5 x 7, 1x, money, no sign | Chalk | 190 | 188 |

After the bid, a plate replaces the bid box (see `footballmanager-screens.png`): rules Chalk Green with ACCEPTED and "HE JOINS AS YOUR RESERVE", or Chalk Red with REFUSED, "THE PRICE GOES UP TO" and the new value in Chalk Yellow.

### 6.18 Sell a player

Pick one of yours; the club's offer appears on the right.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "SELL A PLAYER" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the key bar: UP DOWN MOVE  Y ACCEPT  N REFUSE | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| position, row i at y = 38 + 13 i | sprite pos_df |  | 8 | 37 |
| name (Chalk Dim and not pickable if injured) | 5 x 7, 1x | Chalk | 20 | 38 |
| skill pips | pips |  | 96 | 40 |
| value, no sign | 5 x 7, 1x, money | Chalk Dim | 130 | 38 |
| the cursor band (160 x 13) | fill | Cursor Row | 4 | 100 |
| the panel rule (1 x 190) | fill | Board Rule | 168 | 34 |
| the face frame (30 x 30) | fill | Wood 3 | 208 | 44 |
| the face | sprite face_6 |  | 211 | 47 |
| name (centred on x 243) | 5 x 7, 1x | Chalk Yellow | 220 | 82 |
| label (centred on x 243) | 5 x 7, 1x | Chalk Dim | 211 | 104 |
| the offer, 2x, no sign (0.8 to 1.3 times the value) | 5 x 7, 2x, money | Chalk Green | 239 | 116 |
| label (centred on x 243) | 5 x 7, 1x | Chalk Dim | 229 | 140 |
| the value for comparison (drawn as an amount) (centred on x 243) | 5 x 7, 1x | Chalk Dim | 226 | 150 |
| Y | 5 x 7, 1x | Chalk Green | 184 | 176 |
| N | 5 x 7, 1x | Chalk Red | 250 | 176 |

### 6.19 The F.A. Cup round

Shown before a cup match. The round names: ROUND 1 to ROUND 6, SEMI-FINAL, FINAL; a replay adds REPLAY.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "F.A. CUP" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "WEEK 11" | 5 x 7, 1x | Chalk Dim | 269 | 21 |
| the key bar: ENTER PICK THE TEAM | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| the cup trophy (origin bottom middle) (origin on this point) | sprite trophy_cup |  | 160 | 78 |
| the round, 3x (centred on x 160) | 5 x 7, 3x, outline | Chalk Blue | 99 | 86 |
| REPLAY, only for a replay (centred on x 160) | 5 x 7, 1x | Chalk Amber | 143 | 112 |
| the home club's badge | sprite badge_tower |  | 72 | 132 |
| the home club (yours in Chalk Yellow) (right edge x 146) | 5 x 7, 1x | Chalk Yellow | 106 | 137 |
| V (centred on x 160) | 5 x 7, 1x | Chalk Dim | 158 | 137 |
| the away club | 5 x 7, 1x | Chalk | 174 | 137 |
| the away club's badge | sprite badge_star |  | 252 | 132 |
| their division (centred on x 214) | 5 x 7, 1x | Chalk Dim | 185 | 150 |
| AT HOME (Chalk Green) or AWAY (Chalk Blue) (centred on x 160) | 5 x 7, 1x | Chalk Green | 140 | 168 |

### 6.20 End of season

Your place, the prize money and one of PROMOTED, RELEGATED or STAYING UP.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "END OF SEASON 2" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the key bar: ENTER NEXT SEASON | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| label (centred on x 160) | 5 x 7, 1x | Chalk Dim | 125 | 42 |
| the place, 4x (centred on x 160) | 5 x 7, 4x, outline | Chalk Yellow | 126 | 54 |
| line (centred on x 160) | 5 x 7, 1x | Chalk | 122 | 88 |
| label (centred on x 160) | 5 x 7, 1x | Chalk Dim | 128 | 106 |
| the prize, 2x (right edge x 196) | 5 x 7, 2x, money | Chalk Green | 111 | 118 |
| a plate 180 x 44, rules Chalk Green (promoted), Chalk Red (relegated) or Chalk Dim (staying up) | plate | Chalk Green | 70 | 146 |
| stars (none when relegated or staying up) | sprite mark_star |  | 79 | 151 |
| up arrows (mark_down when relegated, none when staying up) | sprite mark_up |  | 80 | 168 |
| PROMOTED, RELEGATED or STAYING UP, 2x (centred on x 160) | 5 x 7, 2x, outline | Chalk Green | 113 | 160 |
| line (centred on x 160) | 5 x 7, 1x | Chalk | 122 | 196 |

### 6.21 Sacked

The only way to lose. The board is wiped and the word is chalked big; the cabinet tally stays.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "THE BOARD HAS MET" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the key bar: SPACE NEW GAME  ESC QUIT | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| SACKED, 5x (centred on x 160) | 5 x 7, 5x, outline | Chalk Red | 73 | 48 |
| reason (centred on x 160) | 5 x 7, 1x | Chalk | 86 | 100 |
| label | 5 x 7, 1x | Chalk Dim | 92 | 116 |
| the loan, no sign | 5 x 7, 1x, money | Chalk Red | 192 | 116 |
| label | 5 x 7, 1x | Chalk Dim | 92 | 128 |
| rule (292 x 1) | fill | Board Rule | 14 | 146 |
| label (centred on x 160) | 5 x 7, 1x | Chalk Dim | 128 | 154 |
| league titles (origin on this point) | sprite cab_league |  | 120 | 186 |
| count | 5 x 7, 1x | Chalk | 130 | 176 |
| cups (origin on this point) | sprite cab_cup |  | 190 | 186 |
| count | 5 x 7, 1x | Chalk | 200 | 176 |
| line (centred on x 160) | 5 x 7, 1x | Chalk Dim | 83 | 200 |

### 6.22 Paused

A plate over whatever screen is up (here the match).

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the match background, right goal view (3.1, 3.2); for the left goal the rows 34 to 193 mirrored | background |  | 0 | 0 |
| a plate 120 x 40 | plate | Tunnel | 100 | 96 |
| PAUSED, 2x (centred on x 160) | 5 x 7, 2x | Chalk Yellow | 125 | 104 |
| line (centred on x 160) | 5 x 7, 1x | Chalk Dim | 125 | 123 |

### 6.23 Trophy cabinet

Glass shelves in a wood case: one trophy per title, in the order won, the season under each.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "TROPHY CABINET" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "ALF MCGUFFIN" | 5 x 7, 1x | Chalk Dim | 239 | 21 |
| the key bar: ESC BACK | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| the case (272 x 170) | fill | Wood 4 | 24 | 38 |
| the glass back (264 x 162) | fill | Night Haze | 28 | 42 |
| a shelf, shelf k at y = 92 + 54 k (264 x 4) | fill | Wood 2 | 28 | 92 |
| shelf label | 5 x 7, 1x | Chalk Dim | 36 | 48 |
| a league title, every 22 pixels from x 50 (origin on this point) | sprite cab_league |  | 50 | 91 |
| shelf label | 5 x 7, 1x | Chalk Dim | 36 | 102 |
| a cup, every 22 pixels (origin on this point) | sprite cab_cup |  | 50 | 145 |
| shelf label: the full size trophies of the last titles | 5 x 7, 1x | Chalk Dim | 36 | 156 |
| the latest league title, full size (origin on this point) | sprite trophy_league |  | 120 | 199 |
| the latest cup, full size (origin on this point) | sprite trophy_cup |  | 200 | 199 |
| the tally (centred on x 160) | 5 x 7, 1x | Chalk | 59 | 214 |

### 6.24 The goal mouth: who goes where

The game has decided the outcome; the close up shows it. For a **save** at target (column, row) the keeper is drawn with this sprite, mirrored or not, with its origin on this point (inside the 96 x 64 picture). The ball (`gm_ball_far`, or the held ball of `gm_keeper_hold`) is on the target.

| Target | Ball at | Keeper sprite | Mirrored | Keeper origin at |
|---|---|---|---|---|
| high left | (24, 22) | gm_keeper_high_right | yes | (35, 35) |
| high middle | (48, 22) | gm_keeper_jump | no | (48, 51) |
| high right | (72, 22) | gm_keeper_high_right | no | (61, 35) |
| middle left | (24, 32) | gm_keeper_dive_right | yes | (40, 37) |
| middle middle | (48, 32) | gm_keeper_hold | no | (48, 54) |
| middle right | (72, 32) | gm_keeper_dive_right | no | (56, 37) |
| low left | (24, 42) | gm_keeper_dive_right | yes | (40, 47) |
| low middle | (48, 42) | gm_keeper_hold | no | (48, 54) |
| low right | (72, 42) | gm_keeper_dive_right | no | (56, 47) |

- **Goal**: the keeper goes the wrong way. A shot to the left column gets the right column's save pose, a shot to the middle or the right column gets the left column's save pose (each from the table, same row, but the middle row's pose for a high shot). The ball goes in at its target as gm_ball_far, the ripple plays round it, the crowd strip cheers.
- **Wide** (left or right): the ball at the wide point, the keeper in the middle row dive toward it, 6 pixels short. **Over**: the ball at (48, 9), the keeper in the jump pose at feet (48, 54). **Off the post**: the ball at the post point and five spark pixels round it (Spark at (-3, -3), (0, -4) and (3, -3); Spark Warm at (3, -3) on frame 2; Spark Gold at (-4, 1) and (4, 1)), then the result is a save or wide as the game says.
- **Blocked**: there is no close up. The block happens on the pitch, where a defender stops the ball; the ticker shows `ev_block` and BLOCKED (see 11.2).

## 7. Animation recipes and timings

### 7.1 The title

Stars at (14, 6), (40, 30), (66, 12), (250, 8), (284, 34), (300, 14), (120, 4), (200, 2), (160, 58), (30, 60), (230, 50), (98, 44), (276, 60), (180, 40). The intro loops every 6000 ms:

| ms | What changes | Pixels |
|---|---|---|
| 0 to 1200 | the keeper bobs (ready, 1 pixel down and back, 400 ms) | about 200 a step |
| 1200 | the ball appears as gm_ball_near at (136, 186) | 70 |
| 1300, 1400 | gm_ball_mid, then gm_ball_far, toward the top left target, (136, 118) on this screen (the goal mouth picture's row 0 is at y 96, x 112) | 120 |
| 1400 | the keeper dives the wrong way (gm_keeper_dive_right) | about 900 |
| 1500 to 1740 | ripple 1, 2, 3, 80 ms each | under 100 |
| 1500 to 2700 | the crowd tiles swap every 150 ms | 3 rows of 320 x 8 |
| 2700 to 6000 | the keeper back to ready; PRESS SPACE blinks (on 500 ms, off 300 ms) the whole time |  |

### 7.2 The match, one attack

| Step | Timing | What changes |
|---|---|---|
| Dribble | 160 ms a step (2 columns), the ball tweens along the step | the ball rolls (ball_roll_1, 2 every 60 ms), the dribbler runs behind it on the run frames, the other six move to the cells the game gives (run frames while they move); the keeper steps along his diagonal; the trail (8.3) |
| A defender wins it | 300 ms | the defender plays kick 1 and 2 (80 ms, 120 ms), the ball goes back; ticker BLOCKED (`ev_block`) |
| The shot | 80 + 120 ms | the shooter plays kick 1, kick 2; the ball changes to ball_air |
| The close up opens | 0 ms (one draw of the frame and the picture) | the frame (102 x 70) and the goal mouth over the far corner of the view: picture at (9, 87) on the right goal view, (215, 87) on the left |
| Ready | 300 ms | the keeper in ready |
| The flight | 3 x 80 ms | gm_ball_near, gm_ball_mid, gm_ball_far (7.4); the keeper changes to his pose on the last frame |
| The result | 900 ms | saved: hold; goal: the ripple (3 x 80 ms), the shake (8.2), the crowd cheer (8.4); wide or over: hold |
| Close | 0 ms | the pitch under the close up is redrawn (the cells it covered) |
| After a goal | 1200 ms | the scorer's side plays the celebrate frames (150 ms each) where they stand; the ticker flashes GOAL (8.6) |

An attack takes about 2.5 to 3.5 seconds, so 12 attacks are 30 to 40 seconds. SPACE skips to full time.

### 7.3 Figures

Run 1, 2, 3, 4 at 100 ms; the keeper's ready bob at 400 ms; a keeper's dive on the pitch: dive 1 for 100 ms, dive 2 for 500 ms, then ready; got it for 600 ms after a save; celebrate 1, 2 at 150 ms.

### 7.4 The close up shot

The ball starts at (48, 70) (below the picture) and is drawn at a third of the way to its target (near), two thirds (mid), then on the target (far), 80 ms each. Pixels: under 100 a frame, plus the keeper's pose change (under 900).

### 7.5 Menus

The cursor alternates cursor_1 and cursor_2 every 400 ms. The text cursor (a block) is on 500 ms, off 300 ms. A magnet that is placed drops in: drawn 2 pixels high for 40 ms, then 1 pixel high for 40 ms, then in place.

## 8. Effects

| Effect | Verdict | Recipe |
|---|---|---|
| 8.1 Net ripple and sparkle on a goal | **keep** | the three ripple frames round the ball (80 ms each), then 6 spark pixels thrown out from the ball over 300 ms (Spark, Spark Warm, Spark Gold, 100 ms each colour) |
| 8.2 Goal mouth shake | **keep** | the close up (frame and picture) drawn 1 pixel right, left, right, then home, 50 ms each, from the frame the ball crosses the line; only the close up moves |
| 8.3 Ball trail | **keep** | while the ball moves, the 3 pixels behind it along its path, 2, 4 and 6 pixels back: Trail 1, Trail 2, Trail 3; none when still |
| 8.4 The crowd jumps | **keep** | both stands swap crowd_1 and crowd_2 every 150 ms for 1200 ms on a goal (yours or theirs); the close up's crowd strip too |
| 8.5 Money counting up | **keep** | on the money report the cash rolls from last week's to this week's in 8 steps of 50 ms (the digits drawn at each step's value) |
| 8.6 Ticker flash | **keep, for goals** | GOAL in the ticker alternates Chalk Yellow and Chalk every 200 ms for 1200 ms (the red card flash is dropped: the original has no cards) |
| 8.7 Low energy pulse | **keep** | spent bars: the fill turns Spent Dark for 200 ms every 600 ms |
| 8.8 Coin shower | **keep** | when the cash goes from below 0 to 0 or more: 12 particles of 2 x 2 (Gold 2 over Gold 4) fall from the status bar coin, 1 pixel every 20 ms, for 600 ms, over the board only |
| 8.9 Lit star for promotion | **keep** | at the season end the promoted clubs' rows show mark_star in place of mark_up, swapping with Chalk Amber for one frame every 800 ms |
| 8.10 Chalk wipe between screens | **add** | the new board is drawn in columns of 16 pixels from the left, one column every 16 ms (20 steps, 320 ms); each step changes 16 x 210 pixels |
| 8.11 Magnet drop | **add** | section 7.5 |
| Screen shake of the whole match | **drop** | too much movement over a whole screen; the close up shakes alone |

## 9. Later screens

- **Divisions** (`footballmanager-later.png`, top): the third ring of the board's frame (the inlay) and a ring round the club badge on the menu change with your division: division 4 Wood 2 (plain wood), division 3 Silver 3, division 2 Gold 3, division 1 Gold 1 with a mark_star at each end of the title band.
- **A bigger ground**: the stand on the match screen fills with the division: of every 4 crowd tiles, 1 is full in division 4, 2 in division 3, 3 in division 2, all 4 in division 1; an empty tile is Stand with Wall seat marks (2 pixels every 4, on the third row of each 4). The title screen's stand has 1 tier in division 4, 2 in divisions 3 and 2, 3 in division 1, with floodlights from division 2 (`footballmanager-later.png`, bottom).
- **A friendly or European match** (later): a plate across the score bar with the words FRIENDLY or the competition, the pitch striped across (horizontal stripes) instead of along, and the hoardings all Hoarding Lit.
- **The manager's office** (later): the week menu already carries this name; a picture version would be a desk (Wood row) across the bottom third, a phone (Board Head and Chalk Dim), a wall calendar showing the week number in the 5 x 7 font at 3x, and the trophy cabinet's smallest shelf on the wall.

## 10. Checks

- **Sprite check**: passed (every pixel of every sprite is `.` or in its legend, every legend name is in the palette, every legend has 16 colours or fewer, every sprite fits its size except the two close up dives, which say so in 4.4).
- **Text contrast** (WCAG ratio, 4.5 is the usual floor for small text):

| Text | On | Ratio |
|---|---|---|
| Chalk | Board | 13.8 |
| Chalk | Board Stripe | 12.4 |
| Chalk | Cursor Row | 8.2 |
| Chalk Dim | Board | 6.4 |
| Chalk Dim | Board Stripe | 5.8 |
| Chalk Yellow | Board | 12.0 |
| Chalk Yellow | Your Row | 8.5 |
| Chalk Yellow | Cursor Row | 7.1 |
| Chalk Green | Board | 10.4 |
| Chalk Red | Board | 6.0 |
| Chalk Red | Board Stripe | 5.4 |
| Chalk Amber | Board | 8.6 |
| Chalk Blue | Board | 9.2 |
| Chalk | Tunnel | 15.9 |
| Chalk Dim | Tunnel | 7.4 |
| Chalk Yellow | Tunnel | 13.8 |
| Chalk Green | Tunnel | 12.0 |
| Chalk Red | Tunnel | 6.9 |
| Chalk Blue | Tunnel | 10.6 |
| Chalk Dim | Board Head | 7.0 |
| Chalk Yellow | Board Head | 13.0 |
| Title Bottom | Outline | 9.3 |
| Chalk | Night | 16.6 |

- **Things that must not be confused**, as a colour distance (redmean, 0 to about 765) for normal vision, deuteranopia, protanopia and tritanopia. The low ones are why a second cue is there:

| A | B | Why | Normal | Deuter. | Protan. | Tritan. |
|---|---|---|---|---|---|---|
| White 3 | Black 3 | the two kits (they also differ by a hoop and pinstripes, and by the shorts) | 520 | 521 | 520 | 521 |
| White 3 | Keeper 3 | the white kit and the keeper | 279 | 261 | 341 | 151 |
| Black 3 | Keeper 3 | the black kit and the keeper | 414 | 415 | 389 | 443 |
| Black 3 | Grass A | the black kit on the grass | 187 | 202 | 221 | 211 |
| White 3 | Grass A | the white kit on the grass | 407 | 349 | 351 | 367 |
| Chalk Green | Chalk Red | credit and debt, good and bad (they also differ by a sign or an icon) | 326 | 127 | 216 | 401 |
| Chalk Green | Chalk Amber | fresh and weary (they also differ by the fill pattern) | 286 | 153 | 198 | 299 |
| Chalk Amber | Chalk Red | weary and spent (pattern too) | 135 | 100 | 153 | 143 |
| Chalk Yellow | Chalk Blue | your bar and theirs (the + or - mark too) | 312 | 282 | 284 | 271 |
| Ball 3 | Grass A | the ball on the grass | 439 | 381 | 382 | 402 |
| Ball 3 | Net | the ball against the net (pitch view) | 149 | 144 | 143 | 148 |
| Ball 4 | Night Haze | the close up ball against the back of the net | 536 | 538 | 536 | 542 |

- **Kits** differ by value (white against black against marigold) and by pattern (a black hoop on white, pale pinstripes on black, plain keepers with white gloves) and by the shorts (black under white, white under black), so they are told apart in grey scale and under every colour blindness filter (`footballmanager-colour-check.png`).
- **At 2x** (640 x 480, the small screen scale) every screen was checked: the smallest text is the 3 x 5 font at 2x (6 x 10 pixels on screen), figures are 16 x 24, the ball 6 x 6 with its dark edge and shadow, so the white ball still reads beside a white shirt.
- **No full screen change every frame.** Each view of the pitch and every board is drawn once; a frame redraws only the sprites that move (their old rectangles from the stored background, then the new ones), the ticker line and the score bar's clock. The close up redraws only its own 96 x 64 picture. Switching between the right and the left goal view, or opening a menu, is a single full draw on a change of screen, not on every frame.
- **Energy and morale** differ by fill (solid, dashed, checked), length and the ticks at 6 and 12; **money** by the sign and the coin or cracked coin; **zones** by up and down arrows; **your bars** by the + or -.
- **The ball** is white with a dark edge (Ball 5) and a shadow on the grass; on the close up the back net is dark (Night Haze and Net Dark), so the white ball is the brightest thing in the goal.
- **Your club** stands out in every table: the Your Row band, two Chalk Yellow rules and yellow text (a shape and a value cue, not only a hue).

## 11. What I decided, and what is open

### 11.1 Decided

- The look (Chalk and Floodlights), the canvas (320 x 240), the pitch as the rules' 32 x 22 grid in the attacked end view with its mirror (3.2), the cell to pixel mapping and the feet and ball positions, the face on goal mouth close up, the kits (white with a hoop, black with pinstripes, picked on the kit screen), and every position in section 6.
- Removed in revision 2: the pick 12 screen (replaced by the kit screen), the referee (`ref_stand`, `ref_run_1`, `ref_run_2`), the icons `state_card`, `ev_yellow`, `ev_red`, `ev_sub`, the scorers strip on full time, the loan warning colours and the Referee, Ref Collar, Card and Pick Row colours. Renamed: `kit_home` and `kit_away` are now `kit_white` and `kit_black`; the Home and Away tone rows are now White and Black. New: `shirt_white`, `shirt_black`, the kit screen. Every other sprite name is as in revision 1.
- The game's name and the club and player names are not in the art: the title draws a text constant by the rule of 6.5 and every list comes from the game's data. I have not put the 1982 game's name or its name lists into this file or the previews; the placeholders show the format and the column widths are sized for it.
- The art needs **no rule change**.

### 11.2 Open calls for James

1. **The goal rows.** The columns given (17 to 24 and 7 to 14) sit on the goal lines at rows 8 to 15, but the rules file says rows 5 to 13. The art uses 8 to 15 (3.2). If the port uses 5 to 13, the goal moves 3 rows up the line and its columns become 14 to 22 and 9 to 17; tell me and I will move it (one constant in the generator).
2. **The left edge of the grid.** Column 0 has no line (the grass runs to the edge of the screen). Would you rather a halfway line there, which would make the view read as half a pitch?
3. **The in form and tired icons** on the squad screen are kept from revision 1 (the original shows energy only as a number). Keep them, or drop them as extras?
4. **Class names** for the generated code (suggested `FootballLook`, `FootballArt`, `FootballTint` as the other games do), and the ABL art generator, are not written: this is art only.

## 12. The generator

Everything in this file and every preview is made by the Python scripts in `docs/design/footballmanager-generator` (Python 3 and Pillow). From that folder, `python run_all.py` writes the file and the pictures into `docs/design`. Change the design there, not here.
