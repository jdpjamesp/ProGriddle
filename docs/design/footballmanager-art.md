# FootballManager: art and screen design, "Chalk and Floodlights"

Designer's answer to `footballmanager-art-brief.md` (the revised brief of 9 November 2026) and `footballmanager-rules.md`. Everything here is meant to be pasted into code with no further decisions. Section 11 lists what I decided and the calls still open for James.

**The idea in one line.** Every menu is the **chalkboard in the dressing room**: chalk lettering on a bottle green slate in a wooden frame, red and blue tactics magnets for the picks. Every match is a **floodlit night game** seen from the gantry: a bright mown pitch, a dark stand of dots that jumps when a goal goes in, and a close up of the goal mouth for every shot. The working title stays in the file names; the name I propose for the game is **Gaffer** (section 1.2).

**What is kept and what is ours.** The rules, the numbers, the weekly order (menu, pick the team, the match, the result and the money, the table, one transfer offer), the five team numbers, the four divisions of 16 and every screen in the brief's list are kept as the brief and the rules file give them. The name, the look, the goal mouth view (face on from the penalty spot, not isometric), the badges, the faces and **all club and player names** are original. The design does not use the 1982 game's name, screens, lettering, colours or its lists of clubs and players: the names in the previews are invented placeholders, and the art does not depend on any name, since every screen draws whatever text the game holds.

Previews (made by the generator from the data in this file, so the pictures and the text cannot disagree):

- `footballmanager-preview.png` (3x): the match part way through, attack 7, the close up showing a high save.
- `footballmanager-preview-table.png` (3x): the division 3 table, your club 3rd, both zones marked.
- `footballmanager-preview-squad.png` (3x): the squad, the cursor on a midfielder, all three energy levels.
- `footballmanager-preview-title.png` (3x): the title, part way through the intro (the shot on its way).
- `footballmanager-screens.png` (2x): every other screen: the three set up screens, the week menu, pick the team, results, the money report, the transfer offer (bid, and refused), sell a player, the cup round, full time, end of season, sacked, paused, the trophy cabinet.
- `footballmanager-goalmouth.png` (3x): the nine saves, goals, wide, over, off the post, the shot's three frames and the ripple.
- `footballmanager-later.png` (2x): the four division looks and the stand at four sizes (section 9).
- `footballmanager-sprites.png` (4x): every sprite, alternate rows on the board and on the grass.
- `footballmanager-colour-check.png` (1x): the match, the squad and the money report as drawn, through deuteranopia, protanopia and tritanopia, and in grey scale.

## 0. Read this first

- The canvas is **320 x 240**, as the brief proposes, shown at 3x (2x on small screens), nearest neighbour. It is a **direct colour PixelCanvas** like Space Invaders, Centipede, Xevious and Cuber. 320 is wide enough: the table's last column ends at x 306 in the 5 x 7 font at 1x, so no size change is asked for.
- Every menu screen has the same frame: the **status bar** (rows 0 to 13), the **board** in its wooden frame (rows 14 to 227), the **key bar** (rows 228 to 239). The match replaces the status bar with a **score bar** and the board with the pitch (section 3.1).
- **Sprite format**: the tone format of `snake-art.md`. `.` is transparent, `1` to `5` are the tones of the sprite's colour row (1 highlight, 2 light, 3 base, 4 shade, 5 edge), letters are fixed colours given in each legend. No legend has more than 16 colours (the largest has 14).
- **Origin**: every sprite gives its origin. For a figure it is **the middle of its feet** and goes on `cell_xy(column, row)` (section 3.2). Badges, faces and icons are placed by their top left (origin (0, 0)).
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

| Thing | Name | Why |
|---|---|---|
| The game | **Gaffer** (working title FootballManager, kept in the file names) | What the players call the manager. Short, warm, a little funny, and not the original's name |
| The look | Chalk and Floodlights | The board for the week, the lights for the match |
| The week menu | the Manager's Office (the board's title) | The menu of the original's choices, under a friendlier heading |
| The cup | THE CUP | A knockout cup with no real competition's name (see 11.2) |
| A pick | a magnet | Red disc to start, blue ring for the reserve |

### 1.3 What is the same on purpose

- **Everything that costs you is Chalk Red** (`FF6F61`): debt, wages, rent and interest in the money report, relegation, a spent bar, an injury, a defeat, SACKED. Everything that pays is **Chalk Green** (`7FE39A`). A minus sign, the cracked coin or a down arrow always comes with the red; a plus sign, the coin or an up arrow with the green.
- **Yellow chalk is you**: your club's name and row, your bars on the pick screen, the cursor, the selected item. **Blue chalk is them** (their bars) and information (week, division, morale, the cup).
- **Gold is money and glory**: the coin, the league trophy and the title lettering share the Gold row.
- **The keeper is marigold everywhere**: the Keeper row on the pitch and in the close up, and the goalkeeper position icon (`Pos GK` = `Keeper 3`).
- **The board's rows** mean the same on every screen: Board Stripe on every second row, Cursor Row under the cursor, Your Row (with two Chalk Yellow rules) under your club.

## 2. The palette

**144 distinct colours.** Some names share a value on purpose and say so.

### 2.1 Tone rows

Most rows are made from a base: tones 1 and 2 are the base mixed with white, tones 4 and 5 the base mixed with Outline `0A0D0C`. Rows marked "set by hand" are not made that way.

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge | Used for |
|---|---|---|---|---|---|---|
| Home | `F2ADA8` | `E9766E` | `E2493E` | `99352D` | `4B1F1B` | the home kit shirt and socks: coral red (the stripes are Home Stripe, the shorts Home Shorts) |
| Away | `A9D7F5` | `6FBCEE` | `3FA6E8` | `2D729D` | `1A3B4E` | the away kit shirt and socks: sky blue (the hoop is Away Hoop, the shorts Away Shorts) |
| Keeper | `F9E4A2` | `F5D164` | `F2C230` | `AC8C25` | `504317` | both goalkeepers: marigold (plain shirt, white gloves, black shorts) |
| Referee | `8E96A8` | `5C6476` | `343A48` | `242833` | `15181F` | the referee: charcoal (set by hand, a lighter highlight so the shape reads on the grass) |
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
| Home Stripe | `F4EEDC` | the white stripes on the home shirt |
| Home Shorts | `F4EEDC` | the home shorts (same as Home Stripe on purpose) |
| Home Shorts Dark | `BDB5A0` | the shade side of the home shorts |
| Away Hoop | `16305E` | the navy hoop on the away shirt |
| Away Shorts | `16305E` | the away shorts (same as Away Hoop on purpose) |
| Away Shorts Dark | `0C1C3A` | the shade side of the away shorts |
| Glove | `F4EEDC` | the keeper's gloves |
| Keeper Shorts | `20242C` | the keepers' shorts |
| Keeper Shorts Dark | `121418` | the shade side |
| Ref Collar | `E6EFDA` | the referee's collar and cuffs |
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

**Badges and cards**

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
| Card Yellow | `FFD23A` | a yellow card |
| Card Red | `E4302C` | a red card |
| Card Edge | `3A0E0C` | the edge of a card |

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
| 34 to 193 | the pitch: 32 x 20 cells of 8 x 8 from x 32 (x 32 to 287); Run Off to the sides (x 0 to 31 and 288 to 319) |
| 194 to 205 | the bottom stand: the hoardings rows 194 to 197, a row of crowd tiles rows 198 to 205 |
| 206 to 227 | the ticker (Tunnel, a Tunnel Rule on row 206) |
| 228 to 239 | the key bar |

Two floodlight heads (3.3) sit on the top stand at (3, 19) and (305, 19).

### 3.2 The pitch and its cells

The pitch is seen **from above**, the figures from the side (the classic way, and it keeps a cell square). The ball runs on **32 columns by 20 rows of cells of 8 x 8 pixels**, the size the brief proposes; it suits the look.

- `cell_xy(c, r) = (32 + 8c + 4, 34 + 8r + 7)`: the middle of the bottom row of the cell. A figure's feet (its origin) go here, so its 12 rows rise 4 rows into the cell above.
- `ball_xy(c, r) = (32 + 8c + 4, 34 + 8r + 4)`: the middle of the cell, the ball's origin. Its shadow is drawn 1 right and 3 down.
- **The goals** are at both ends on **cell rows 8 to 11** (y 98 to 129), the left goal outside column 0, the right outside column 31 (see 11.2 about the rules file's goal numbers).

The background, drawn once:

| Part | Recipe |
|---|---|
| Run off | Run Off over rows 34 to 193, the full width |
| Mown stripes | 16 stripes 16 pixels wide from x 32: Grass A on even stripes, Grass B on odd |
| Touch and goal lines | Line on x 32 to 287 at y 34 and y 193; on y 34 to 193 at x 32 and x 287 |
| Halfway line | Line, 2 wide, x 159 and 160 |
| Centre circle | Line on the points of a circle radius 22 round (159.5, 113.5) (every 0.5 degree, rounded); a 2 x 2 spot at (159, 113) |
| Penalty areas | 5 cells deep, cell rows 4 to 15 (y 66 to 161): the box lines at x 72 (left) and x 247 (right) |
| Goal areas | 2 cells deep, cell rows 7 to 12 (y 90 to 137): lines at x 48 and x 271 |
| Spots | 2 x 2 at (60, 113) and (258, 113) |
| Arcs | the points of a circle radius 18 round each spot that lie outside the box |
| Goals | from above: 8 x 32 of Net Dark at x 24 to 31 and x 288 to 295, y 98 to 129, with Net on every pixel where (x + y) mod 3 = 0; Post on the goal line side (x 31 and x 288, y 97 to 130) and along the top and bottom (y 97 and 130); Net on the back line |
| Corner flags | a 1 x 3 Post above each corner and a 2 pixel Chalk Yellow flag pointing in |

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
| home | Home | Home Shorts | Home Shorts Dark | Skin | **vertical stripes**: torso columns 3 and 5, below the torso's top row | Home Stripe |
| away | Away | Away Shorts | Away Shorts Dark | Skin | **a hoop**: the torso's third row (top + 2), all of it | Away Hoop |
| keeper | Keeper | Keeper Shorts | Keeper Shorts Dark | Glove | none (plain shirt, white gloves) |  |
| referee | Referee | Referee 4 | Referee 5 | Skin | **a collar**: the torso's top row | Ref Collar |

Fixed letters in every figure: `A` skin, `B` skin shade, `H` hair, `O` Boot, `C` hands. **Skin and hair vary** by the player's number n (1 to 24): skin pair `n mod 3` (Skin 1, Skin 2, Skin 3, each with its Shade), hair `n mod 4` (Hair Dark, Hair Black, Hair Fair, Hair Ginger). The keepers and the referee use pair 1 and Hair Dark. The home side (left, attacking right) always wears home and the away side away, whichever is your club.

The four kits standing, as the brief asks (pattern applied):

#### fig_stand_home (8 x 12, origin (4, 11))

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `P` Home Stripe `F4EEDC`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

#### fig_stand_away (8 x 12, origin (4, 11))

Legend: `1234` tones 1, 2, 3, 4 of the Away row (`A9D7F5`, `6FBCEE`, `3FA6E8`, `2D729D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `P` Away Hoop `16305E`; `S` Away Shorts `16305E`; `T` Away Shorts Dark `0C1C3A`.

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

#### fig_stand_referee (8 x 12, origin (4, 11))

Legend: `234` tones 2, 3, 4 of the Referee row (`5C6476`, `343A48`, `242833`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `P` Ref Collar `E6EFDA`; `S` Referee 4 `242833`; `T` Referee 5 `15181F`.

```
...HHH..
...HAAA.
...BAA..
..PPPP..
.C2333C.
.C3334C.
..3344..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
```

The frames, before the pattern (shown with the Home row and the home legend):

#### fig_stand (8 x 12, origin (4, 11))

Standing (also the referee standing).

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Running 1 of 4: contact, right leg forward (also referee run 1).

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Running 3: contact, the other leg (also referee run 2).

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

Legend: `1234` tones 1, 2, 3, 4 of the Home row (`F2ADA8`, `E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `C` Skin 1 `F2C6A0`; `H` Hair Dark `2E1C12`; `O` Boot `17120E`; `S` Home Shorts `F4EEDC`; `T` Home Shorts Dark `BDB5A0`.

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

### 4.3 The referee and the ball

The referee is the figure in the Referee kit: `ref_stand` = fig_stand, `ref_run_1` = fig_run_1, `ref_run_2` = fig_run_3 (two frames at 140 ms). He never touches the ball.

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

Eight badges, assigned to the 64 clubs as `badge = club number mod 8`. The mini badge for the status bar and the tables is the badge sampled at every odd pixel (x and y 1, 3, 5, ... 15), given below so no code has to do it.

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

Eight faces, reused as `face = player number mod 8` (the manager uses face_8 on the set up screen). The shirt at the bottom is the Home row; the game may swap it for any kit row. `P` is the collar.

#### face_1 (24 x 24, origin (0, 0))

short dark hair, a smile

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Dark `2E1C12`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 3 `8A5634`; `B` Skin 3 Shade `633A20`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Ginger `B8542A`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `D` Home 3 `E2493E`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Fair `E2B85A`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 2 `C98A5C`; `B` Skin 2 Shade `9C6640`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Dark `2E1C12`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 3 `8A5634`; `B` Skin 3 Shade `633A20`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Black `141016`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

Legend: `234` tones 2, 3, 4 of the Home row (`E9766E`, `E2493E`, `99352D`); `A` Skin 1 `F2C6A0`; `B` Skin 1 Shade `C99474`; `C` Eye White `F6F2EA`; `F` Cheek `E58A72`; `G` Face Back `22342D`; `H` Hair Grey `B4B4B0`; `K` Eye `141016`; `M` Mouth `7A2E26`; `P` Home Stripe `F4EEDC`; `W` Eye White `F6F2EA`.

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

#### state_card (8 x 8, origin (0, 0))

suspended (not used by the rules, kept for later): a red card

Legend: `E` Icon Edge `0A0D0C`; `R` Card Red `E4302C`.

```
..EEEE..
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
..EEEE..
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

#### ev_yellow (8 x 8, origin (0, 0))

a yellow card

Legend: `E` Icon Edge `0A0D0C`; `Y` Card Yellow `FFD23A`.

```
..EEEE..
.EYYYYE.
.EYYYYE.
.EYYYYE.
.EYYYYE.
.EYYYYE.
.EYYYYE.
..EEEE..
```

#### ev_red (8 x 8, origin (0, 0))

a red card

Legend: `E` Icon Edge `0A0D0C`; `R` Card Red `E4302C`.

```
..EEEE..
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
.ERRRRE.
..EEEE..
```

#### ev_sub (8 x 8, origin (0, 0))

substitution: on (green, up) and off (red, down)

Legend: `E` Icon Edge `0A0D0C`; `G` Chalk Green `7FE39A`; `R` Chalk Red `FF6F61`.

```
........
.E...E..
EGE.ERE.
GGGERRRE
EGE.ERE.
EGE.ERE.
.E...E..
........
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

whistle: kick off, half time, full time

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

#### kit_home (8 x 8, origin (0, 0))

the home kit, for the score bar

Legend: `3` Home 3 `E2493E`; `E` Icon Edge `0A0D0C`; `P` Home Stripe `F4EEDC`.

```
.EE..EE.
EPPEEPPE
EP3P3P3E
.E3P3PE.
.E3P3PE.
.E3P3PE.
..EEEE..
........
```

#### kit_away (8 x 8, origin (0, 0))

the away kit, for the score bar

Legend: `3` Away 3 `3FA6E8`; `E` Icon Edge `0A0D0C`; `P` Away Hoop `16305E`.

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

Legend: `E` Icon Edge `0A0D0C`; `H` Home 1 `F2ADA8`; `R` Home 3 `E2493E`; `S` Home 4 `99352D`.

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

Legend: `E` Icon Edge `0A0D0C`; `H` Away 1 `A9D7F5`; `R` Away 3 `3FA6E8`; `S` Away 4 `2D729D`.

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
| the loan: digits with group gaps, no sign, ends by x 284 | 5 x 7, 1x | Chalk, or Chalk Red above 80% of the limit | 238 | 4 |
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
| Loan meter | 124 x 6, filled loan / limit: Chalk Green solid under 40%, Chalk Amber dashed to 80%, Chalk Red checked above; a Chalk Red tick 10 rows tall at 80% and 12 rows tall at the limit |

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
| the name's drop (2 pixels down and right) | 5 x 7, 5x | Title Shadow | 74 | 16 |
| the name | 5 x 7, 5x, outline, gradient to Title Bottom | Title Top | 72 | 14 |
| the line under the name (centred on x 160) | 5 x 7, 1x | Chalk | 83 | 54 |
| the ball flying at the goal (intro, section 7.1) (origin on this point) | sprite gm_ball_near |  | 136 | 186 |
| a banner plate 128 x 19 (section 6.4) | plate | Tunnel | 96 | 204 |
| PRESS SPACE, on 500 ms, off 300 ms (centred on x 160) | 5 x 7, 1x | Chalk Yellow | 128 | 210 |
| the key bar (320 x 12) | fill | Tunnel | 0 | 228 |
| the hint line (centred on x 160) | 5 x 7, 1x | Chalk Dim | 29 | 231 |

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

### 6.8 New game 3: pick 12 players

A grid of the 24: defenders, midfielders, forwards. Picks 1 to 11 get the red magnet, the 12th the blue ring (the reserve).

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the board with the title "PICK 12 PLAYERS" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "PICKED 9 OF 12" | 5 x 7, 1x | Chalk Dim | 227 | 21 |
| the key bar: ARROWS MOVE  ENTER PICK  SPACE DONE | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| no status bar yet: the strip is plain Tunnel (320 x 14) | fill | Tunnel | 0 | 0 |
| column head icon, column c at x = 12 + 102 c | sprite pos_df |  | 12 | 37 |
| column head | 5 x 7, 1x | Chalk Dim | 23 | 38 |
| a picked player's magnet; the 12th pick gets magnet_res | sprite magnet_on |  | 12 | 54 |
| player name, row k at y = 54 + 20 k (Chalk if picked, Chalk Dim if not) | 5 x 7, 1x | Chalk | 23 | 54 |
| an empty slot: a 6 x 6 square at magnet x + 1, y + 1 | fill | Board Rule | 13 | 95 |
| the cursor band (100 x 16) | fill | Cursor Row | 110 | 90 |

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
| LEAGUE, or THE CUP and the round name (centred on x 242) | 5 x 7, 1x | Chalk Blue | 225 | 54 |
| your badge | sprite badge_tower |  | 196 | 70 |
| their badge | sprite badge_kettle |  | 272 | 70 |
| V (centred on x 242) | 5 x 7, 2x | Chalk Dim | 237 | 75 |
| your club (centred on x 242) | 5 x 7, 1x | Chalk Yellow | 207 | 94 |
| their club (centred on x 242) | 5 x 7, 1x | Chalk | 210 | 104 |
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
| position icon, row i at y = 47 + 11 i | sprite pos_gk |  | 16 | 46 |
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
| the right hand of the title band: "V MIZZLE CITY" | 5 x 7, 1x | Chalk Dim | 233 | 21 |
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

The pitch is 32 x 20 cells of 8 x 8 pixels from (32, 34). The goal mouth close up is drawn over the middle of the pitch for each shot.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the match background (section 3.1 and 3.2) | background |  | 0 | 0 |
| the score bar (320 x 18) | fill | Tunnel | 0 | 0 |
| its rule (320 x 1) | fill | Tunnel Rule | 0 | 17 |
| home mini badge | sprite mini_tower |  | 4 | 5 |
| home kit icon | sprite kit_home |  | 14 | 5 |
| home club (your club in Chalk Yellow) | 5 x 7, 1x | Chalk | 24 | 6 |
| home goals, 2x (right edge x 152) | 5 x 7, 2x | Chalk Yellow | 143 | 2 |
| the dash, 2x (centred on x 160) | 5 x 7, 2x | Chalk Dim | 155 | 2 |
| away goals, 2x | 5 x 7, 2x | Chalk Yellow | 168 | 2 |
| away club (right edge x 295) | 5 x 7, 1x | Chalk | 231 | 6 |
| away kit icon | sprite kit_away |  | 298 | 5 |
| away mini badge | sprite mini_kettle |  | 308 | 5 |
| the 22 figures and the referee: feet on cell_xy(c, r) (3.2; the kick off shape is under this table) | sprites |  | 32 | 34 |
| the ball on its cell, with its shadow 1 right and 3 down and the trail of 8.3 | sprite ball_roll_1 |  | 252 | 118 |
| the ticker (320 x 22) | fill | Tunnel | 0 | 206 |
| its rule (320 x 1) | fill | Tunnel Rule | 0 | 206 |
| the event icon | sprite ev_save |  | 6 | 213 |
| the ticker line (up to 40 characters) | 5 x 7, 1x | Chalk | 18 | 214 |
| the running attack count (right edge x 313) | 5 x 7, 1x | Chalk Dim | 267 | 214 |
| the key bar (320 x 12) | fill | Tunnel | 0 | 228 |
| keys | 5 x 7, 1x | Chalk Yellow | 6 | 231 |
| the close up frame: Outline ring (102 x 70) | fill | Outline | 109 | 79 |
| then a Chalk Yellow ring (100 x 68) | fill | Chalk Yellow | 110 | 80 |
| then Outline again (98 x 66) | fill | Outline | 111 | 81 |
| the goal mouth picture (section 3.4) | goal mouth |  | 112 | 82 |
| the keeper, high dive to the right (the goal mouth table, 6.24) (origin on this point) | sprite gm_keeper_high_right |  | 176 | 108 |
| the ball at the top right target, in the gloves: SAVED (origin on this point) | sprite gm_ball_mid |  | 184 | 104 |

**The kick off shape** (home attacks right; the away side is at `(31 - column, 19 - row)`, mirrored):

| Who | Cells (column, row) |
|---|---|
| keeper | (1, 9) |
| defenders | (6, 3), (6, 7), (6, 12), (6, 16) |
| midfielders | (11, 3), (11, 7), (11, 12), (11, 16) |
| forwards | (15, 8), (14, 12) |
| referee | (16, 4) |

The figures then move as the game says; the art only needs their cells. A figure with the ball, or running to it, uses the run frames (100 ms each); the others stand. The figure that shoots plays kick 1, kick 2.

### 6.13 Full time

A plate over the last frame of the pitch. The rules have no halves and no named scorers, so the panel lists the attacks.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the match background (section 3.1 and 3.2) | background |  | 0 | 0 |
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
| label | 3 x 5 | Chalk Dim | 72 | 158 |
| a goal: ev_goal, then the attack number, every 30 pixels | sprite ev_goal |  | 100 | 156 |

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
| away (right edge x 270) | 5 x 7, 1x | Chalk | 206 | 43 |
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
| fill: Chalk Green (solid) under 40%, Chalk Amber (dashed) to 80%, Chalk Red (checked) above, like the energy bar | bar | by level | 26 | 176 |
| the 80% tick (1 x 10) | fill | Chalk Red | 125 | 174 |
| the limit tick (1 x 12) | fill | Chalk Red | 149 | 173 |
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

**Column positions** (5 x 7 at 1x, numbers right aligned on these right edges): zone marker x 6; POS right edge 22; mini badge x 26; CLUB x 38 (12 characters, to x 108); P 140; W 160; D 180; L 200; F 226; A 250; GD 276 (sign always drawn); PTS 306. Rows from y 48, every 11 (the 16th at y 213).

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
| position, row i at y = 38 + 13 i | sprite pos_gk |  | 8 | 37 |
| name (Chalk Dim and not pickable if injured) | 5 x 7, 1x | Chalk | 20 | 38 |
| skill pips | pips |  | 96 | 40 |
| value, no sign | 5 x 7, 1x, money | Chalk Dim | 130 | 38 |
| the cursor band (160 x 13) | fill | Cursor Row | 4 | 100 |
| the panel rule (1 x 190) | fill | Board Rule | 168 | 34 |
| the face frame (30 x 30) | fill | Wood 3 | 208 | 44 |
| the face | sprite face_6 |  | 211 | 47 |
| name (centred on x 243) | 5 x 7, 1x | Chalk Yellow | 217 | 82 |
| label (centred on x 243) | 5 x 7, 1x | Chalk Dim | 211 | 104 |
| the offer, 2x, no sign (0.8 to 1.3 times the value) | 5 x 7, 2x, money | Chalk Green | 239 | 116 |
| label (centred on x 243) | 5 x 7, 1x | Chalk Dim | 229 | 140 |
| the value for comparison (drawn as an amount) (centred on x 243) | 5 x 7, 1x | Chalk Dim | 226 | 150 |
| Y | 5 x 7, 1x | Chalk Green | 184 | 176 |
| N | 5 x 7, 1x | Chalk Red | 250 | 176 |

### 6.19 The cup round

Shown before a cup match. The round names: ROUND 1 to ROUND 6, SEMI-FINAL, FINAL; a replay adds REPLAY.

| What | Font or kind | Colour | x | y |
|---|---|---|---|---|
| the status bar (section 6.1) | status bar |  | 0 | 0 |
| the board with the title "THE CUP" (section 6.2) | board | Chalk Yellow | 10 | 21 |
| the right hand of the title band: "WEEK 11" | 5 x 7, 1x | Chalk Dim | 269 | 21 |
| the key bar: ENTER PICK THE TEAM | key bar | Chalk Yellow and Chalk Dim | 6 | 231 |
| the cup trophy (origin bottom middle) (origin on this point) | sprite trophy_cup |  | 160 | 78 |
| the round, 3x (centred on x 160) | 5 x 7, 3x, outline | Chalk Blue | 99 | 86 |
| REPLAY, only for a replay (centred on x 160) | 5 x 7, 1x | Chalk Amber | 143 | 112 |
| the home club's badge | sprite badge_tower |  | 52 | 132 |
| the home club (yours in Chalk Yellow) (right edge x 146) | 5 x 7, 1x | Chalk Yellow | 76 | 137 |
| V (centred on x 160) | 5 x 7, 1x | Chalk Dim | 158 | 137 |
| the away club | 5 x 7, 1x | Chalk | 174 | 137 |
| the away club's badge | sprite badge_star |  | 252 | 132 |
| their division (centred on x 214) | 5 x 7, 1x | Chalk Dim | 185 | 150 |
| AT HOME (Chalk Green) or AWAY (Chalk Blue) (centred on x 160) | 5 x 7, 1x | Chalk Green | 140 | 168 |
| what the gate will be, when it is known (cup away, semi-final, final) (centred on x 160) | 5 x 7, 1x | Chalk Dim | 80 | 190 |

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
| the match background (section 3.1 and 3.2) | background |  | 0 | 0 |
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
| the tally (centred on x 160) | 5 x 7, 1x | Chalk | 53 | 214 |

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
| Dribble | 160 ms a step (2 columns), the ball tweens 1 pixel every 10 ms | the ball rolls (ball_roll_1, 2 every 60 ms), the carrier runs beside it, the nearest 3 players of each side run 1 pixel every 20 ms toward it; the trail (8.3) |
| A defender wins it | 300 ms | the defender plays kick 1 and 2 (80 ms, 120 ms), the ball goes back; ticker BLOCKED (`ev_block`) |
| The shot | 80 + 120 ms | the shooter plays kick 1, kick 2; the ball changes to ball_air |
| The close up opens | 0 ms (one draw of the frame and the picture) | the frame (102 x 70) and the goal mouth over the pitch at (112, 82) |
| Ready | 300 ms | the keeper in ready |
| The flight | 3 x 80 ms | gm_ball_near, gm_ball_mid, gm_ball_far (7.4); the keeper changes to his pose on the last frame |
| The result | 900 ms | saved: hold; goal: the ripple (3 x 80 ms), the shake (8.2), the crowd cheer (8.4); wide or over: hold |
| Close | 0 ms | the pitch under the close up is redrawn (the cells it covered) |
| After a goal | 1200 ms | the scorer's side plays the celebrate frames (150 ms each) where they stand; the ticker flashes GOAL (8.6) |

An attack takes about 2.5 to 3.5 seconds, so 12 attacks are 30 to 40 seconds. SPACE skips to full time.

### 7.3 Figures

Run 1, 2, 3, 4 at 100 ms; the referee's two run frames at 140 ms; the keeper's ready bob at 400 ms; a keeper's dive on the pitch: dive 1 for 100 ms, dive 2 for 500 ms, then ready; got it for 600 ms after a save; celebrate 1, 2 at 150 ms.

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
| 8.6 Ticker flash | **keep, for goals** | GOAL in the ticker alternates Chalk Yellow and Chalk every 200 ms for 1200 ms (the red card flash is dropped: the rules have no cards) |
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
| Home 3 | Away 3 | the two kits (they also differ by stripes and a hoop) | 416 | 283 | 304 | 535 |
| Home 3 | Keeper 3 | home and the keepers | 244 | 180 | 252 | 331 |
| Away 3 | Keeper 3 | away and the keepers | 409 | 345 | 376 | 405 |
| Referee 3 | Grass A | the referee on the grass | 181 | 196 | 215 | 200 |
| Chalk Green | Chalk Red | credit and debt, good and bad (they also differ by a sign or an icon) | 326 | 127 | 216 | 401 |
| Chalk Green | Chalk Amber | fresh and weary (they also differ by the fill pattern) | 286 | 153 | 198 | 299 |
| Chalk Amber | Chalk Red | weary and spent (pattern too) | 135 | 100 | 153 | 143 |
| Chalk Yellow | Chalk Blue | your bar and theirs (the + or - mark too) | 312 | 282 | 284 | 271 |
| Ball 3 | Grass A | the ball on the grass | 439 | 381 | 382 | 402 |
| Ball 3 | Net | the ball against the net (pitch view) | 149 | 144 | 143 | 148 |
| Ball 4 | Night Haze | the close up ball against the back of the net | 536 | 538 | 536 | 542 |

- **Kits** differ by stripes (home), a hoop (away), plain with white hands (keepers) and a collar (referee), and by the shorts (cream, navy, black, charcoal), so the kits are told apart in grey scale (`footballmanager-colour-check.png`).
- **Energy and morale** differ by fill (solid, dashed, checked), length and the ticks at 6 and 12; **money** by the sign and the coin or cracked coin; **zones** by up and down arrows; **your bars** by the + or -.
- **The ball** is white with a dark edge (Ball 5) and a shadow on the grass; on the close up the back net is dark (Night Haze and Net Dark), so the white ball is the brightest thing in the goal.
- **Your club** stands out in every table: the Your Row band, two Chalk Yellow rules and yellow text (a shape and a value cue, not only a hue).

## 11. What I decided, and what is open

### 11.1 Decided

- The look (Chalk and Floodlights), the name proposal (Gaffer), the canvas (320 x 240 as briefed), the pitch (32 x 20 cells of 8 as briefed, from above), the goal mouth view (face on, our own), the kits (home stripes, away hoop, both fixed by side), the cell to pixel mapping and every position in section 6.
- The art needs **no rule change**.

### 11.2 Open calls for James

1. **The name and the names.** Is **Gaffer** right? And all club and player names must be invented (not the 1982 lists, which are that game's content and include real clubs); I can write a list of 64 clubs and 24 players in the same spirit as the previews' if you want it.
2. **Where the goals are.** The rules file says a goal passes through "columns 7 to 14 or 17 to 24, rows 5 to 13", which reads as if the original's pitch lay the other way (goals at the top and bottom). The art puts the goals at the left and right ends on cell rows 8 to 11, as the brief's "goals at the ends" says. Which should the port follow? If the rule's numbers stay, the pitch would need to be turned (20 x 32) and the stands moved to the sides.
3. **Blocked shots** get no close up (the block is on the pitch, with the ticker). Or would you like a close up with the ball bouncing back off a defender's legs at the edge of the picture?
4. **No halves, no scorers.** The rules have no half time and no named scorers, so there is a full time panel only, and it marks the goals by attack number. OK, or should the port add a half time break after the fifth round?
5. **The cup's name**: the rules call it the FA Cup; the screens say THE CUP, since the real competition's name is not ours to use. OK?
6. **Unused icons**: the suspended card, the yellow and red cards and the substitution icon are drawn (the brief lists them) but the rules have no cards or substitutes. Keep them for later, or drop them?
7. **The loan in the status bar** goes Chalk Red above 80% of the limit (a warning before the sack). The original gave no warning; this is presentation only. Keep?
8. **Class names** for the generated code (suggested `FootballLook`, `FootballArt`, `FootballTint` as the other games do), and the ABL art generator, are not written: this is art only.

## 12. The generator

Everything in this file and every preview is made by the Python scripts in `docs/design/footballmanager-generator` (Python 3 and Pillow). From that folder, `python run_all.py` writes the file and the pictures into `docs/design`. Change the design there, not here.
