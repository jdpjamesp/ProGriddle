# FOR EACH: art and screen design, "Night Shift"

Everything here is meant to be pasted into code with no further decisions. Section 9 lists what I decided, and the questions the code will still have to answer.

Previews, all at 3x with nearest neighbour scaling:

- `foreach-preview.png`: in game, level 5, some bits eaten, Dibby going up the left lane, all four phantoms in play (Mary angry, stage 1), a TABLE item under the lobby.
- `foreach-preview-title.png`: the title and attract screen with the whole roll call, the points table and the chase demo lane.
- `foreach-preview-rolledback.png`: left, a commit token just eaten (two phantoms rolled back, one flashing, one returning, a 400 pop-up); right, the same in game moment as the first preview with the debug target overlay on.
- `foreach-preview-flash.png`: the end of level flash, both states (normal lines and white lines).
- `foreach-preview-ready-over.png`: the start of a game (PLAYER ONE, READY!) and GAME OVER.
- `foreach-cartoons.png`: the three cartoons, four key frames each.
- `foreach-sprites.png`: every sprite in this file on one sheet (4x).
- `foreach-colour-check.png` (2x): the things that must be told apart and the game screen, as drawn and through deuteranopia, protanopia and tritanopia.

Every sprite block, every tile, the maze maps and every preview were made by one small script from one set of data (`foreach-generator/`), so the pictures and the text cannot disagree. The checks in section 8 were run by that script.

## 0. Read this first

- The canvas is **224 x 288**: a **24 pixel HUD** (rows 0 to 23), the **maze, 28 x 31 tiles of 8 x 8 = 224 x 248** (rows 24 to 271) and a **16 pixel strip** (rows 272 to 287). Origin top left, one pixel of this file is one canvas pixel, shown at 2x or 3x by `GridView:FitToWindow`. It is the direct colour `PixelCanvas`.
- **Tile (c, r)** of the maze covers canvas pixels `x = 8c .. 8c + 7`, `y = 24 + 8r .. 24 + 8r + 7`. Its **centre** is canvas pixel `(8c + 4, 24 + 8r + 4)`.
- **Sprite format**: as in `snake-art.md`. `.` is transparent. `1` to `5` are the five tones of the sprite's colour row (1 highlight, 5 edge). Capital letters are named colours from the legend under each block. No legend has more than 16 colours.
- **Origin**: every 16 x 16 sprite has its origin at **(8, 8)**, the pixel just right of and below the middle. Draw it with its top left at `(x - 8, y - 8)`, where `(x, y)` is the character's pixel position. A character on a tile centre is at `(8c + 4, 24 + 8r + 4)`. Smaller sprites state their own origin.
- **Facing**: Dibby is drawn facing right. **Left** is a mirror (`x' = 15 - x`), **up** is a quarter turn anticlockwise (`row y of up = column 15 - y of right, read top to bottom`), **down** a quarter turn clockwise. All of Dibby's shading is symmetric about his middle line, so turned and mirrored frames are still lit correctly. In code: `turn` in `foreach-generator/draw.py`. The **phantoms are never turned**: the body is always upright and only the eyes look four ways.
- **Phantom colours**: a phantom is drawn as body (in its colour row), then its eyes, then its mark. The body is the same for all four; the mark tells them apart without colour.
- **Text** is the 5 x 7 font with one pixel between letters: `n` characters at scale `k` are `n * 6k - k` wide. "Centred" means `x = floor((224 - width) / 2)`. "With Outline" means the text is first drawn in `Outline` at the 8 one pixel offsets, then in its colour. Gradient text: row `r` of the `7k` letter rows is the mix of the top and bottom colours at `r / (7k - 1)`. Pop-up numbers use the 3 x 5 digits of section 3.6.
- **Time** is in milliseconds and the game runs 60 frames a second. Animations count from the game's own clock, as in the other games.
- **Draw order (back to front)**: 1 the baked maze (floor, studs, walls, door: drawn once per level, and again only for a palette swap), 2 bits and commit tokens (a bit is erased by drawing the floor tile again), 3 the item, 4 halos, 5 phantoms (eyes, then marks), 6 Dibby, 7 the debug overlay, 8 pop-ups, 9 the HUD and banners.

What is in the file: 1 art direction and palette, 2 the maze, 3 sprites, 4 animation recipes, 5 screens, 6 effects, 7 budgets, 8 checks, 9 what I decided and why, 10 sprite index.

## 1. Art direction and palette

**Night Shift.** The data centre at 3 in the morning: the lights are off, the floor is a dark raised floor with a faint stud at every tile corner, and the only light comes from the glowing teal bus lines that run round every rack. Little cream bits of data sit in the lanes, and the four commit tokens glow mint. Dibby, the database drum, is the warmest thing on the screen, a glossy amber cylinder with a lid, two eyes and a jaw. The phantoms (named after the phantom read) are four bright wisps with a tail, each with a personal accessory, and when Dibby commits they are rolled back: they melt into a deep blue puddle with a wobbly mouth. A lit maze at night, cool and calm: teal lines, an amber Dibby, and no pure black.

Against its siblings: Lantern Glass is navy and amber glass, Obsidian Line is vector lines on near black, Invaders is neon pink and violet on indigo, Girder Rush is dusk, Blast Buddies is daylight. Night Shift is the only one with **teal lines on a near black floor**, and the only one where the walls are lines and not blocks. One accent shared with the other games: the Cookoff orange lives in the title gradient.

Colour rules that keep it readable:

- **Teal is the maze and nothing else.** No character uses a teal body. The rolled back blue is darker and bluer than any wall colour, and the flashing white is lighter than any wall colour, so a rolled back phantom never melts into a wall.
- **Every character has a dark edge**: Dibby has a tone 5 outline all round, a phantom darkens to tone 4 at its sides and tone 5 along its bottom, so each reads where it overlaps a bright line as it turns a corner. Each also has a **halo** (section 6) on the floor round it.
- **Warm things can be eaten, cool things are the world.** Bits are cream, the items are bright and mostly warm, Dibby is amber. The only cool bright thing that moves is a rolled back phantom, and Dibby can eat that too.
- Things that are the same colour on purpose: `Player` gold is 1UP, READY!, PUSH START and (as `Door`) the door stripes, all "this is you, get ready"; `Pop Phantom` is the colour of phantom points and the rewind marks; `Bit` cream is every bit, the bits Dibby breaks into when he crashes, and the 10 PTS sample; `Token Ring` mint is the commit token, its sparkle and nothing else.

### 1.1 Colour rows (tones 1 to 5)

Tones 1 and 2 are the base mixed with white at 70% and 30%; tone 3 is the base; tones 4 and 5 are the base mixed with `05080F` at 32% and 64% (the Lantern Glass formula, so the families feel related). `Flash` is a fixed ramp, not the formula, so it stays white. The phantom rows are listed in role order: chaser, ambusher, unpredictable, shy.

| Row | 1 | 2 | 3 | 4 | 5 | Used for |
|---|---|---|---|---|---|---|
| Dibby | `FFEDC2` | `FFD471` | `FFC234` | `AF8628` | `5F4B1C` | Dibby, the database drum |
| Mary | `E9D1FF` | `CB94FF` | `B566FF` | `7D48B2` | `442A65` | Mary, the chaser (mark: a hair bow) |
| Rich | `FFD7EA` | `FFA2CD` | `FF7AB8` | `AF5682` | `5F314C` | Rich, the ambusher (mark: a top hat and heavy eyelids) |
| Brian | `FBC7C4` | `F67C76` | `F2443C` | `A6312E` | `5A1E1F` | Brian, the unpredictable one (mark: glasses) |
| Chip | `D8F4C4` | `A5E676` | `7EDC3C` | `57982E` | `31541F` | Chip, the shy one (mark: an antenna with a chip) |
| Rollback | `C4C8F8` | `757EEF` | `3A46E8` | `2932A3` | `181E5D` | a rolled back phantom |
| Flash | `FFFFFF` | `F4F6FF` | `E8ECFF` | `A8B0D8` | `6A7098` | a rolled back phantom about to recover (fixed ramp, not the formula) |
| Steel | `DCE0E6` | `AEB7C5` | `8C98AC` | `616A7A` | `363C48` | metal on the items: the floppy disk shutter |


### 1.2 Named colours

| Name | Hex | Used for |
|---|---|---|
| Floor | `06070E` | the floor of the maze and the HUD strips (drawn once) |
| Floor Stud | `111522` | the raised floor stud at each tile corner (drawn once) |
| Tunnel | `0B0F1C` | the tunnel floor, a shade lighter so the slow stretch reads |
| Glow | `0D2E30` | wall band 1: the dim glow beside the line |
| Line | `35E0CF` | wall band 2: the bright bus line |
| Gap | `082022` | wall band 3: the dark gap |
| Inner | `1C8C86` | wall band 4: the inner line |
| Fill | `061416` | wall band 5: the inside of a wall block |
| Pulse | `6CF2E2` | the bright line on the beat of the alarm (swaps with Line) |
| Door | `FFD23A` | the lobby door bar (stripes) |
| Door Shade | `3A2C10` | the dark stripes of the door bar |
| Flash Line | `FFFFFF` | end of level flash: replaces Line and Inner |
| Flash Glow | `2A4A5A` | end of level flash: replaces Glow |
| Bit | `FFE6B0` | a data bit, 2 x 2 |
| Token | `FFFFFF` | the commit token core |
| Token Ring | `7CF6A8` | the commit token ring |
| Token Dim | `2E8A5A` | the commit token in its dim blink frame |
| Eye | `FFFFFF` | the white of every eye |
| Pupil | `1C2A8C` | the pupil of a phantom or of Dibby |
| Ink | `140C1C` | outlines, glasses, the hat, dark details |
| Mouth | `5A1A2A` | the inside of Dibby's mouth |
| Tongue | `FF7A8A` | Dibby's tongue |
| LED | `5CFF8A` | the status light on Dibby |
| Rolledback Face | `FFE0C8` | the eyes and the wavy mouth of a rolled back phantom |
| Flash Face | `F2343C` | the eyes and the mouth of a flashing phantom |
| Bow | `FFD2F0` | Mary's bow highlight |
| Chip Body | `2A3038` | the little chip on Chip's antenna |
| Chip Pin | `C8D0DC` | the pins of that chip |
| Hat | `565A80` | Rich's top hat |
| Hat Top | `8A8EB8` | the lit top and brim edge of the hat |
| Hat Band | `F2443C` | the band of Rich's hat |
| Angry | `FF2A2A` | Mary's pupils when she is angry (second stage) |
| Steam | `C8D4E8` | the steam puff when Mary is angry |
| Disk Blue | `3A6AE8` | the floppy disk |
| Disk Dark | `22388A` | the floppy disk shade |
| Label | `F4F2E8` | labels on the floppy and the tape |
| Tape | `3A2A24` | the tape on the reel |
| Reel | `E8E8F0` | the tape reel |
| Gold | `FFD24A` | the key, the lock, the trigger gear |
| Gold Shade | `B0782A` | their shade |
| Grid | `E0F4FF` | the table grid lines |
| Grid Head | `3AA0E8` | the table header row |
| Grid Cell | `1A3A5A` | the table cells |
| Glass | `9AE8FF` | the magnifier glass |
| Glass Shine | `FFFFFF` | the shine on the glass |
| Handle | `8A4A2A` | the magnifier handle |
| Rack | `3A4258` | the server body |
| Rack Edge | `7A86A0` | the server outline and shelves |
| Rack LED | `5CFF8A` | server lights (on) |
| Rack Amber | `FFB23A` | server lights (busy) |
| Text | `F4F2FF` | scores and words |
| Label Text | `8FA8C0` | HUD labels, hints |
| Player | `FFD23A` | 1UP, READY!, the high score note |
| Over | `FF4A4A` | GAME OVER |
| Pop Phantom | `7FF0FF` | points for a phantom |
| Pop Item | `FF9AD0` | points for an item |
| Title Top | `FFF2A0` | the title gradient, top |
| Title Bottom | `FF8A2A` | the title gradient, bottom |
| Outline | `000000` | the 1 pixel outline behind text over the maze |
| Target | `FFFFFF` | the centre pixel of a debug target marker |
| Spark | `FFFFFF` | sparks and the first colour of every particle |
| Sheet | `1A1E2A` | background of the sprite sheet pictures only (not in the game) |

## 2. The maze

### 2.1 The map (28 x 31)

The lobby in the middle with its door on top, a lane all round it with no bits in it, two side tunnels on row 14, four commit tokens near the corners (two high, two low), **240 bits**, Dibby's start under the lobby and the item spot right under the lobby. The left and right halves mirror each other (column `c` mirrors to `27 - c`). Every lane is one tile wide, there are no dead ends and no open 2 x 2 squares (checked).

The drawing map (what the generator draws from). Key: `#` wall, `.` bit (10), `o` commit token (50), space an empty lane, `t` tunnel lane (empty, drawn on the `Tunnel` floor, phantoms slow down), `-` the lobby door (phantoms only), `=` the lobby floor (phantoms only), `S` Dibby's start lane (empty).

```
              111111111122222222
    0123456789012345678901234567
 0  ############################
 1  #..........................#
 2  #.###.####.######.####.###.#
 3  #o###.####.######.####.###o#
 4  #..........................#
 5  #.###.##.##########.##.###.#
 6  #.###.##.##########.##.###.#
 7  #.###.##.##########.##.###.#
 8  #.....##            ##.....#
 9  #####.#####.####.#####.#####
10  #####.#####.####.#####.#####
11  #####.##            ##.#####
12  #####.## ####--#### ##.#####
13  #####.## #========# ##.#####
14  ttttt.   #========#   .ttttt
15  #####.## #========# ##.#####
16  #####.## ########## ##.#####
17  #####.##            ##.#####
18  #####.## ########## ##.#####
19  #####.## ########## ##.#####
20  #..........................#
21  #.###.#####.####.#####.###.#
22  #.###.#####.####.#####.###.#
23  #o..#....    SS    ....#..o#
24  ###.#.##.##########.##.#.###
25  ###.#.##.##########.##.#.###
26  #..........................#
27  #.#######.##.##.##.#######.#
28  #.#######.##.##.##.#######.#
29  #............  ............#
30  ############################
```

Counts: 240 bits and 4 commit tokens, 244 things to eat in all.

**The map for the maze reader**, in the code's symbols: `#` wall, `_` empty lane, `.` bit, `o` commit token, `-` door, `=` lobby floor, `T` tunnel lane, `U` an empty lane where phantoms may not turn up, `P` Dibby, `M` Mary, `R` Rich, `B` Brian, `C` Chip, `F` the item. A start letter stands on the tile whose left edge is the start x and whose middle is the start y. The no-turning-up stretches are columns 11 to 16 of rows 11 and 23 (12 tiles); `M` (14, 11) and `P` (14, 23) stand on two of them, so **the reader must treat the `M` and `P` tiles as `U` tiles as well**.

```
############################
#..........................#
#.###.####.######.####.###.#
#o###.####.######.####.###o#
#..........................#
#.###.##.##########.##.###.#
#.###.##.##########.##.###.#
#.###.##.##########.##.###.#
#.....##____________##.....#
#####.#####.####.#####.#####
#####.#####.####.#####.#####
#####.##___UUUMUU___##.#####
#####.##_####--####_##.#####
#####.##_#========#_##.#####
TTTTT.___#==B=R=C=#___.TTTTT
#####.##_#========#_##.#####
#####.##_##########_##.#####
#####.##______F_____##.#####
#####.##_##########_##.#####
#####.##_##########_##.#####
#..........................#
#.###.#####.####.#####.###.#
#.###.#####.####.#####.###.#
#o..#....__UUUPUU__....#..o#
###.#.##.##########.##.#.###
###.#.##.##########.##.#.###
#..........................#
#.#######.##.##.##.#######.#
#.#######.##.##.##.#######.#
#............__............#
############################
```

Checked: 240 bits, 4 commit tokens, and with each start letter read as the tile under it (`U` under `M` and `P`, `=` under `R`, `B` and `C`, `_` under `F`) every row is its own mirror: passed.

Positions the rules need (in tiles, and the canvas pixel of the character's origin):

| What | Where | Canvas pixel |
|---|---|---|
| Dibby's start | between tiles (13, 23) and (14, 23), facing left | (112, 212) |
| Mary's start (the chaser) | between (13, 11) and (14, 11), outside the lobby, above the door, looking left | (112, 116) |
| Rich's start | between (13, 14) and (14, 14), in the lobby, middle, looking down | (112, 140) |
| Brian's start | between (11, 14) and (12, 14), in the lobby, left, looking up | (96, 140) |
| Chip's start | between (15, 14) and (16, 14), in the lobby, right, looking up | (128, 140) |
| The door | tiles (13, 12) and (14, 12) | |
| Item | between (13, 17) and (14, 17) | (112, 164) |
| READY! and GAME OVER | tile row 17, centred | text top at y 160 |
| Tunnel slow zone | row 14, columns 0 to 4 and 23 to 27, and the 2 tiles off each edge | |
| Scatter corners | Mary (25, -3), Rich (2, -3), Brian (27, 33), Chip (0, 33): off the map | |
| No-turning-up stretches | row 11, columns 11 to 16, and row 23, columns 11 to 16 (the lanes over the lobby and over the start): a phantom there may not choose up | |

The lobby is 10 tiles wide (columns 9 to 18) with a floor of 8 x 3, so the three phantoms inside are 16 pixels apart and never overlap. To leave, a phantom goes to x = 112, then up through the door to y = 116.

### 2.2 The wall rule

Walls are **lines, not blocks**: every wall block is outlined by a bright line with a dim inner line inside it, following the shape of the block with rounded corners. The picture of every wall tile comes from one rule, applied to its 8 neighbours. I give the rule (so it can be computed) and the 47 tiles it makes (so it can be pasted). In code: `wall_distance` and `wall_tile` in `foreach-generator/maze.py`.

1. A tile is a **wall** for this rule if it is `#` or `-` (the door counts as wall, so the lobby line runs straight into it). Everything else, including the lobby floor, is **path**. A neighbour outside the map takes the kind of the **nearest tile on the map** (clamp the column and the row), so the outer border closes and the tunnel rows stay open off the edge.
2. For each pixel of a wall tile, centre `(x + 0.5, y + 0.5)` with x and y from 0 to 7, `d` is the straight line distance to the nearest **path neighbour tile** (each neighbour is the square `[8dc, 8dc + 8) x [8dr, 8dr + 8)` around the tile).
3. **Rounded outside corners**: for each corner of the tile whose **two side neighbours are both path**, take a circle of radius 7 whose centre is 7 pixels in from that corner (for the top left corner, (7, 7)). For a pixel up and left of that centre (for the top left corner), `d = min(d, 7 - distance to the centre)`.
4. Colour the pixel by `d`:

| d | Band | Colour | Letter in the tiles |
|---|---|---|---|
| 0 to 2 | floor | `06070E` (Floor) | `.` |
| 2 to 3 | Glow | `0D2E30` (Glow) | `G` |
| 3 to 4 | Line | `35E0CF` (Line) | `L` |
| 4 to 5 | Gap | `082022` (Gap) | `A` |
| 5 to 6 | Inner | `1C8C86` (Inner) | `I` |
| 6 and more | Fill | `061416` (Fill) | `F` |

So the line sits 3 pixels inside the wall tile: the lane looks 14 pixels wide (8 of the path tile plus 3 of floor each side), a 14 pixel body fits it, and a character that cuts a corner overlaps the glow and the edge of the line by a pixel or two. A block two tiles thick shows two lines with a 4 pixel fill between them; a wall **one tile thick** (the lobby walls and the short stub in row 23) shows a 2 pixel bright bar with glow either side, which is the thin wall look.

**Which tile**: number the neighbours N = 1, E = 2, S = 4, W = 8, NE = 16, SE = 32, SW = 64, NW = 128, a bit set when that neighbour is a wall. A **corner** bit only matters when both of its side neighbours are walls (NE needs N and E, and so on), so clear the others: `mask = N|E|S|W` plus `16` if NE and N and E, `32` if SE and S and E, `64` if SW and S and W, `128` if NW and N and W. That gives **47 different masks** (the usual blob set), listed below. A tile with mask 255 is all `Fill`. The game can either compute the rule once per level (it is static and drawn once) or look up these 47 tiles; both give the same pixels.

The 47 wall tiles, 6 to a row, each headed by its mask number. Letters: `.` Floor, `G` Glow, `L` Line, `A` Gap, `I` Inner, `F` Fill.

```
m0         m1         m2         m3         m4         m5      
........   ..GLLG..   ........   ..GLLG..   ........   ..GLLG..
........   ..GLLG..   ........   ..GLLGG.   ........   ..GLLG..
........   ..GLLG..   .....GGG   ..GLALGG   ........   ..GLLG..
...GG...   ...GG...   ...GGLLL   ...GLALL   ...GG...   ..GLLG..
...GG...   ...GG...   ...GGLLL   ...GGLLL   ...GG...   ..GLLG..
........   ........   .....GGG   .....GGG   ..GLLG..   ..GLLG..
........   ........   ........   ........   ..GLLG..   ..GLLG..
........   ........   ........   ........   ..GLLG..   ..GLLG..

m6         m7         m8         m9         m10        m11     
........   ..GLLG..   ........   ..GLLG..   ........   ..GLLG..
........   ..GLLGG.   ........   .GGLLG..   ........   .GGLLGG.
.....GGG   ..GLALGG   GGG.....   GGLALG..   GGGGGGGG   GGLAALGG
...GGLLL   ..GLAALL   LLLGG...   LLALG...   LLLLLLLL   LLAAAALL
...GLALL   ..GLAALL   LLLGG...   LLLGG...   LLLLLLLL   LLLLLLLL
..GLALGG   ..GLALGG   GGG.....   GGG.....   GGGGGGGG   GGGGGGGG
..GLLGG.   ..GLLGG.   ........   ........   ........   ........
..GLLG..   ..GLLG..   ........   ........   ........   ........

m12        m13        m14        m15        m19        m23     
........   ..GLLG..   ........   ..GLLG..   ..GLAIFF   ..GLAIFF
........   .GGLLG..   ........   .GGLLGG.   ..GLAIFF   ..GLAIFF
GGG.....   GGLALG..   GGGGGGGG   GGLAALGG   ..GLAAII   ..GLAIII
LLLGG...   LLAALG..   LLLLLLLL   LLAAAALL   ...GLAAA   ..GLAIAA
LLALG...   LLAALG..   LLAAAALL   LLAAAALL   ...GGLLL   ..GLAALL
GGLALG..   GGLALG..   GGLAALGG   GGLAALGG   .....GGG   ..GLALGG
.GGLLG..   .GGLLG..   .GGLLGG.   .GGLLGG.   ........   ..GLLGG.
..GLLG..   ..GLLG..   ..GLLG..   ..GLLG..   ........   ..GLLG..

m27        m31        m38        m39        m46        m47     
..GLAIFF   ..GLAIFF   ........   ..GLLG..   ........   ..GLLG..
.GGLAIFF   .GGLAIFF   ........   ..GLLGG.   ........   .GGLLGG.
GGLAIIII   GGLAIFII   .....GGG   ..GLALGG   GGGGGGGG   GGLAALGG
LLAAAAAA   LLAAIIAA   ...GGLLL   ..GLAALL   LLLLLLLL   LLAAAALL
LLLLLLLL   LLAAAALL   ...GLAAA   ..GLAIAA   LLAAAAAA   LLAAIIAA
GGGGGGGG   GGLAALGG   ..GLAAII   ..GLAIII   GGLAIIII   GGLAIFII
........   .GGLLGG.   ..GLAIFF   ..GLAIFF   .GGLAIFF   .GGLAIFF
........   ..GLLG..   ..GLAIFF   ..GLAIFF   ..GLAIFF   ..GLAIFF

m55        m63        m76        m77        m78        m79     
..GLAIFF   ..GLAIFF   ........   ..GLLG..   ........   ..GLLG..
..GLAIFF   .GGLAIFF   ........   .GGLLG..   ........   .GGLLGG.
..GLAIFF   GGLAIFFF   GGG.....   GGLALG..   GGGGGGGG   GGLAALGG
..GLAIFF   LLAAIFFF   LLLGG...   LLAALG..   LLLLLLLL   LLAAAALL
..GLAIFF   LLAAIFFF   AAALG...   AAIALG..   AAAAAALL   AAIIAALL
..GLAIFF   GGLAIFFF   IIAALG..   IIIALG..   IIIIALGG   IIFIALGG
..GLAIFF   .GGLAIFF   FFIALG..   FFIALG..   FFIALGG.   FFIALGG.
..GLAIFF   ..GLAIFF   FFIALG..   FFIALG..   FFIALG..   FFIALG..

m95        m110       m111       m127       m137       m139    
..GLAIFF   ........   ..GLLG..   ..GLAIFF   FFIALG..   FFIALG..
.GGLAIFF   ........   .GGLLGG.   .GGLAIFF   FFIALG..   FFIALGG.
GGLAIFII   GGGGGGGG   GGLAALGG   GGLAIFFF   IIAALG..   IIIIALGG
LLAAIIAA   LLLLLLLL   LLAAAALL   LLAAIFFF   AAALG...   AAAAAALL
AAIIAALL   AAAAAAAA   AAIIIIAA   AAIIFFFF   LLLGG...   LLLLLLLL
IIFIALGG   IIIIIIII   IIFFFFII   IIFFFFFF   GGG.....   GGGGGGGG
FFIALGG.   FFFFFFFF   FFFFFFFF   FFFFFFFF   ........   ........
FFIALG..   FFFFFFFF   FFFFFFFF   FFFFFFFF   ........   ........

m141       m143       m155       m159       m175       m191    
FFIALG..   FFIALG..   FFFFFFFF   FFFFFFFF   FFIALG..   FFFFFFFF
FFIALG..   FFIALGG.   FFFFFFFF   FFFFFFFF   FFIALGG.   FFFFFFFF
IIIALG..   IIFIALGG   IIIIIIII   IIFFFFII   IIFIALGG   IIFFFFFF
AAIALG..   AAIIAALL   AAAAAAAA   AAIIIIAA   AAIIAALL   AAIIFFFF
LLAALG..   LLAAAALL   LLLLLLLL   LLAAAALL   LLAAIIAA   LLAAIFFF
GGLALG..   GGLAALGG   GGGGGGGG   GGLAALGG   GGLAIFII   GGLAIFFF
.GGLLG..   .GGLLGG.   ........   .GGLLGG.   .GGLAIFF   .GGLAIFF
..GLLG..   ..GLLG..   ........   ..GLLG..   ..GLAIFF   ..GLAIFF

m205       m207       m223       m239       m255    
FFIALG..   FFIALG..   FFFFFFFF   FFIALG..   FFFFFFFF
FFIALG..   FFIALGG.   FFFFFFFF   FFIALGG.   FFFFFFFF
FFIALG..   FFFIALGG   FFFFFFII   FFFIALGG   FFFFFFFF
FFIALG..   FFFIAALL   FFFFIIAA   FFFIAALL   FFFFFFFF
FFIALG..   FFFIAALL   FFFIAALL   FFFFIIAA   FFFFFFFF
FFIALG..   FFFIALGG   FFFIALGG   FFFFFFII   FFFFFFFF
FFIALG..   FFIALGG.   FFIALGG.   FFFFFFFF   FFFFFFFF
FFIALG..   FFIALG..   FFIALG..   FFFFFFFF   FFFFFFFF
```

### 2.3 The other tiles

All 8 x 8, drawn once per level (and a bit is erased by drawing its floor tile again).

- **Floor** (every path tile): all `Floor`, with one `Floor Stud` pixel at its top left (0, 0). The studs make a faint raised floor grid 8 pixels apart that sits between the bits and never touches them.
- **Tunnel floor** (the `t` tiles): the same with `Tunnel` in place of `Floor`, so the slow stretch is visibly a shade lighter.
- **Bit**: `Bit`, **2 x 2**, at tile pixels (3, 3) to (4, 4), the middle of the tile.
- **Commit token**: the 6 x 6 sprite `commit_on` (section 3.5) with its top left at tile pixel (1, 1); blink frame `commit_dim`. It blinks, it never disappears.
- **The door** (tiles (13, 12) and (14, 12)): rows 3 and 4 of the tile, the same rows as the lobby line next to it, in hazard stripes, everything else floor. It reads as a barrier, not a wall: it is gold and black where every wall is teal.

```
........
........
........
AABBAABB
BBAABBAA
........
........
........
```

Door legend: `A` Door `FFD23A`, `B` Door Shade `3A2C10`, `.` Floor.

- **The tunnel mouths**: nothing extra to draw. The tunnel row runs off both edges (the clamp rule leaves it open), the walls above and below it are closed by the line, and a character in the tunnel is drawn clipped at the canvas edge and appears on the other side (it is drawn twice, once at x and once at x - 224 or x + 224, while it is within 8 pixels of an edge).
- **The outer border**: just walls; the rule draws its line 3 pixels in from the inside edge. The thick side blocks beside the tunnel are drawn with the line on their lane side only and fill to the screen edge.

### 2.4 Flashes and pulses (palette swaps of the baked maze)

- **End of level flash**: after the last bit, everything stops for **1000 ms**: the phantoms vanish, Dibby stays on the screen in his last frame (mouth half open), the item and pop-ups are removed. Then the walls swap **8 times, 200 ms each** (4 white flashes over 1600 ms): `Line` and `Inner` become `Flash Line` (`FFFFFF`) and `Glow` becomes `Flash Glow`; the next swap puts them back. `Fill`, `Gap`, the floor and the door do not change. Then the screen clears to `Floor` for 200 ms and the next level (or a cartoon) starts. On the last white swap Dibby shows `dibby_happy`.
- **The alarm pulse** (optional, on by default): on each beat of the alarm, `Line` becomes `Pulse` for 2 frames, then back. The alarm speeds up as the bits run out, so the walls breathe faster. Off while phantoms are rolled back (that sound has no beat).

## 3. Sprites

### 3.1 Dibby, the database drum

A database drum seen from the side: a lid (tones 1 and 2), a body with a disc seam, an amber status light at the back, two eyes at the front, and a **jaw**: the drum splits along its middle seam and the lower half drops open. The mouth inside is dark red with a pink tongue. The silhouette changes by the jaw dropping. Drawn facing right; see section 0 for the other three directions.

#### dibby_closed (16 x 16, origin (8, 8))

Closed: the jaw shut, a dark line along the split. The first frame of a level.

Legend: `1`-`5` tones of **Dibby**, `E` Eye `FFFFFF`, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`.

```
................
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
..543322EE2EE5..
..543322EP2EP5..
..543322EP2EP5..
..543322555555..
..5LL322222345..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### dibby_half (16 x 16, origin (8, 8))

Half open. Also the frame shown while Dibby is blocked by a wall.

Legend: `1`-`5` tones of **Dibby**, `E` Eye `FFFFFF`, `L` LED `5CFF8A`, `M` Mouth `5A1A2A`, `P` Pupil `1C2A8C`.

```
................
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
..543322EE2EE5..
..543322EP2EP5..
..543322EP2EP5..
..543322555555..
..5LL3225MMMMM..
..544444455555..
..543322223345..
...5543333455...
.....555555.....
```

#### dibby_wide (16 x 16, origin (8, 8))

Wide open, the tongue showing. The lid lifts one pixel.

Legend: `1`-`5` tones of **Dibby**, `E` Eye `FFFFFF`, `L` LED `5CFF8A`, `M` Mouth `5A1A2A`, `P` Pupil `1C2A8C`, `T` Tongue `FF7A8A`.

```
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
..543322EE2EE5..
..543322EP2EP5..
..543322EP2EP5..
..543322555555..
..5433225MMMMM..
..5LL325MMMMMM..
..5444445TTTMM..
..543322555555..
...5543333455...
.....555555.....
```

#### dibby_happy (16 x 16, origin (8, 8))

Title and attract only: happy eyes and a grin (used on the title and after a level is cleared).

Legend: `1`-`5` tones of **Dibby**, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`, `T` Tongue `FF7A8A`.

```
................
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
..543322PP2PP5..
..54332P22P225..
..543322222225..
..543322555555..
..5LL3225TTT55..
..544444455555..
..543322223345..
...5543333455...
.....555555.....
```

#### dibby_life (12 x 12, origin (6, 6))

The lives icon, 12 x 12, already facing left (it is the half frame drawn small).

Legend: `1`-`5` tones of **Dibby**, `E` Eye `FFFFFF`, `L` LED `5CFF8A`, `M` Mouth `5A1A2A`, `P` Pupil `1C2A8C`.

```
............
...555555...
.5511111155.
.5111111115.
.5422222245.
.52E2E22345.
.52P2P22345.
.5555522345.
.5MMMM52LL5.
.5555554445.
..55333355..
....5555....
```

Mouth cycle while moving: `closed`, `half`, `wide`, `half`, repeating (section 4). Stopped against a wall: `half`, held. Start of a level: `closed`, facing left.

### 3.2 The phantoms

One wisp body for all four, in each phantom's colour row, a dome on top and a tail that swishes from side to side. Lit from straight above. The body is **never turned or mirrored**; only the eyes move.

| Phantom | Colour row | Hunting style | Mark (the second way to tell them apart) |
|---|---|---|---|
| **Mary** | Mary `B566FF` | the chaser: heads straight for Dibby, starts outside the lobby above the door, goes angry (speeds up) when the bits run low | a hair bow |
| **Rich** | Rich `FF7AB8` | the ambusher: heads for the tile 4 ahead of Dibby | a top hat and heavy eyelids |
| **Brian** | Brian `F2443C` | the unpredictable one: uses Mary's position and Dibby's to find his target | glasses |
| **Chip** | Chip `7EDC3C` | the shy one: chases from far away, wanders to his own corner when close | an antenna with a chip |

The order of the four on the roll call and in the lobby is by role: chaser, ambusher, unpredictable, shy, so Mary, Rich, Brian, Chip.

#### phantom_body_1 (16 x 16, origin (8, 8))

The body, swish 1 (tail to the left). Drawn in each phantom's colour row; the same body for all four.

Legend: `1`-`5` tones of the phantom's own row (**Mary**, **Rich**, **Brian** or **Chip**, table 1.1).

```
................
................
.....111111.....
...1122222211...
..122222222221..
.12222223332221.
.32223333333333.
.43333333333334.
.43333333333334.
.54333334444445.
..433344444445..
..53444444455...
...44444555.....
..144455........
.13455..........
.555............
```

#### phantom_body_2 (16 x 16, origin (8, 8))

The body, swish 2 (tail to the right).

Legend: `1`-`5` tones of the phantom's own row (**Mary**, **Rich**, **Brian** or **Chip**, table 1.1).

```
................
................
.....111111.....
...1122222211...
..122222222221..
.12223332222221.
.33333333332223.
.43333333333334.
.43333333333334.
.54444443333345.
..544444443334..
...55444444435..
.....55544444...
........554441..
..........55431.
............555.
```

#### Eyes

Four 16 x 16 overlays with the same origin as the body; draw over the body. The whites shift one pixel the way the phantom is going and the pupils sit on that side. Which direction they show is an open question (section 9, point 13); the art works for either.

#### phantom_eyes_right (16 x 16, origin (8, 8))

The eyes looking right. Drawn over the body at the same origin.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
.....EE....EE...
....EEPP..EEPP..
....EEPP..EEPP..
.....EE....EE...
................
................
................
................
................
................
................
```

#### phantom_eyes_left (16 x 16, origin (8, 8))

The eyes looking left. Drawn over the body at the same origin.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
...EE....EE.....
..PPEE..PPEE....
..PPEE..PPEE....
...EE....EE.....
................
................
................
................
................
................
................
```

#### phantom_eyes_up (16 x 16, origin (8, 8))

The eyes looking up. Drawn over the body at the same origin.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
....PP....PP....
...EPPE..EPPE...
...EEEE..EEEE...
....EE....EE....
................
................
................
................
................
................
................
................
```

#### phantom_eyes_down (16 x 16, origin (8, 8))

The eyes looking down. Drawn over the body at the same origin.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
................
....EE....EE....
...EEEE..EEEE...
...EPPE..EPPE...
....PP....PP....
................
................
................
................
................
................
```

#### Marks

Overlays, 16 x 16, same origin, drawn after the eyes. Rich's lids are drawn **after** the eyes, so they cover the top row of the whites whichever way he looks.

#### mark_brian (16 x 16, origin (8, 8))

Glasses: two square rims and a bridge, drawn over his eyes (the eyes move inside the rims).

Legend: `K` Ink `140C1C`.

```
................
................
................
................
..KKKKKK.KKKKKK.
..K....KKK....K.
..K....K.K....K.
..K....K.K....K.
..K....K.K....K.
..KKKKKK.KKKKKK.
................
................
................
................
................
................
```

#### mark_mary (16 x 16, origin (8, 8))

A bow on the top right of her head.

Legend: `1`-`5` tones of **Mary**, `K` Ink `140C1C`, `W` Bow `FFD2F0`.

```
........W.....W.
........WW...WW.
........W5WKW5W.
........WW...WW.
........W.....W.
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

#### mark_chip (16 x 16, origin (8, 8))

An antenna with a little chip on top (pins either side).

Legend: `Q` Chip Body `2A3038`, `R` Chip Pin `C8D0DC`.

```
......QQQQ......
.....RQQQQR.....
.......RR.......
.......RR.......
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

#### mark_rich (16 x 16, origin (8, 8))

A top hat on his dome and heavy eyelids that cover the top row of his eyes, so he always looks half asleep.

Legend: `1`-`5` tones of **Rich**, `H` Hat Band `F2443C`, `U` Hat Top `8A8EB8`, `X` Hat `565A80`.

```
....UUUUUUU.....
....XXXXXXX.....
....HHHHHHH.....
..UUUUUUUUUUU...
................
..44444..44444..
..44444..44444..
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

#### Mary angry (the two speed ups)

Drawn after Mary's mark. Stage 1 when the first speed up starts, stage 2 at the second (the bits left for each stage come from the rules' speed table). In stage 2 her pupils are drawn in `Angry` (`FF2A2A`) instead of `Pupil`. Both stages last until she is eaten or Dibby crashes. While rolled back there is no mark and no angry overlay. No other phantom has an angry state.

#### mary_angry_1 (16 x 16, origin (8, 8))

Mary angry, stage 1 (the first speed up): slanted brows, drawn after her bow.

Legend: `K` Ink `140C1C`.

```
................
................
................
...KK.......KK..
.....KKK.KKK....
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

#### mary_angry_2 (16 x 16, origin (8, 8))

Mary angry, stage 2 (the second speed up): the brows, a steam puff on the side away from her bow, and her pupils are drawn in Angry red.

Legend: `K` Ink `140C1C`, `S` Steam `C8D4E8`.

```
.SS.............
SS..............
.SS.............
...KK.......KK..
.....KKK.KKK....
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

### 3.3 Rolled back, flashing and returning

Rolled back is a different **shape**, not just a colour: lower, wider, no tail, no mark, melting into drips, with pinpoint eyes and a wavy mouth. Flashing is the same shape in the `Flash` row with a red face. The game flips between `rolledback_n` and `flash_n` every **125 ms** for the last 2000 ms of the rolled back time (16 flips; the wobble frame keeps running underneath, every 133 ms). A rolled back phantom has no eye direction: its face is fixed.

#### rolledback_1 (16 x 16, origin (8, 8))

Rolled back, wobble 1: lower and wider than a phantom, melting into drips, with pinpoint eyes and a wavy mouth. No marks, no tail.

Legend: `1`-`5` tones of **Rollback**, `F` Rolledback Face `FFE0C8`.

```
................
................
................
.....111111.....
...1122222211...
..122222222221..
.122FF3223FF221.
.323FF3333FF323.
1233333333333321
433F4FF33FF4F334
53F444FFFF444F35
.43454444445434.
.445.544445.544.
.54...5445...45.
..5....55....5..
................
```

#### rolledback_2 (16 x 16, origin (8, 8))

Rolled back, wobble 2: the drips change.

Legend: `1`-`5` tones of **Rollback**, `F` Rolledback Face `FFE0C8`.

```
................
................
................
.....111111.....
...1122222211...
..122222222221..
.122FF3223FF221.
.323FF3333FF323.
1333333333333331
433F3FF33FF3F334
54F334FFFF433F45
.54444534544445.
..4445.44.5444..
..545..44..545..
...5...45...5...
.......5........
```

#### flash_1 (16 x 16, origin (8, 8))

Flashing, wobble 1: the rolled back body in the Flash row, red face.

Legend: `1`-`5` tones of **Flash**, `G` Flash Face `F2343C`.

```
................
................
................
.....111111.....
...1122222211...
..122222222221..
.122GG3223GG221.
.323GG3333GG323.
1233333333333321
433G4GG33GG4G334
53G444GGGG444G35
.43454444445434.
.445.544445.544.
.54...5445...45.
..5....55....5..
................
```

#### flash_2 (16 x 16, origin (8, 8))

Flashing, wobble 2.

Legend: `1`-`5` tones of **Flash**, `G` Flash Face `F2343C`.

```
................
................
................
.....111111.....
...1122222211...
..122222222221..
.122GG3223GG221.
.323GG3333GG323.
1333333333333331
433G3GG33GG3G334
54G334GGGG433G45
.54444534544445.
..4445.44.5444..
..545..44..545..
...5...45...5...
.......5........
```

Returning: after Dibby eats a phantom, only its eyes are left, one size up, and they go back to the lobby. Draw them with a three bubble trail behind (section 6).

#### returning_right (16 x 16, origin (8, 8))

Returning to the lobby, looking right: only the eyes, a size bigger than the normal eyes.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
....EEE....EEE..
...EEEPP..EEEPP.
...EEEPP..EEEPP.
...EEEEE..EEEEE.
....EEE....EEE..
................
................
................
................
................
................
```

#### returning_left (16 x 16, origin (8, 8))

Returning to the lobby, looking left: only the eyes, a size bigger than the normal eyes.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
..EEE....EEE....
.PPEEE..PPEEE...
.PPEEE..PPEEE...
.EEEEE..EEEEE...
..EEE....EEE....
................
................
................
................
................
................
```

#### returning_up (16 x 16, origin (8, 8))

Returning to the lobby, looking up: only the eyes, a size bigger than the normal eyes.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
...PPE....PPE...
..EPPEE..EPPEE..
..EEEEE..EEEEE..
..EEEEE..EEEEE..
...EEE....EEE...
................
................
................
................
................
................
................
```

#### returning_down (16 x 16, origin (8, 8))

Returning to the lobby, looking down: only the eyes, a size bigger than the normal eyes.

Legend: `E` Eye `FFFFFF`, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
................
...EEE....EEE...
..EEEEE..EEEEE..
..EEEEE..EEEEE..
..EPPEE..EPPEE..
...PPE....PPE...
................
................
................
................
................
```

### 3.4 Items

Eight database things, each a different **shape** so colour is never needed: square with a cut corner, round reel, long key, wide grid, glass and handle, toothed gear, arch over a box, tall rack. They sit at the item spot (112, 164) and in the level counter. The "ready to eat" bounce costs no art: draw the item 1 pixel higher for 133 ms every 533 ms.

| Item | Points | Levels |
|---|---|---|
| FLOPPY | 100 | 1 |
| TAPE | 300 | 2 |
| KEY | 500 | 3 and 4 |
| TABLE | 700 | 5 and 6 |
| QUERY | 1000 | 7 and 8 |
| TRIGGER | 2000 | 9 and 10 |
| LOCK | 3000 | 11 and 12 |
| SERVER | 5000 | 13 on |

#### item_floppy (16 x 16, origin (8, 8))

A floppy disk: a square with a cut corner, a metal shutter and a label. 100 points, level 1.

Legend: `1`-`5` tones of **Steel**, `B` Disk Blue `3A6AE8`, `K` Ink `140C1C`, `L` Label `F4F2E8`, `N` Disk Dark `22388A`.

```
................
.KKKKKKKKKKKK...
.KBB2222222BBK..
.KBB22KK222BBBK.
.KBB22KK222BBBK.
.KBB4444444BBBK.
.KBBBBBBBBBBBBK.
.KBLLLLLLLLLLBK.
.KBLNNNNNNNNLBK.
.KBLLLLLLLLLLBK.
.KBLNNNNNNLLLBK.
.KBLLLLLLLLLLBK.
.KNNNNNNNNNNNNK.
.KKKKKKKKKKKKKK.
................
................
```

#### item_tape (16 x 16, origin (8, 8))

A tape reel: a round flange, dark tape wound on it, a hub with three holes. 300 points, level 2.

Legend: `K` Ink `140C1C`, `R` Reel `E8E8F0`, `T` Tape `3A2A24`.

```
................
.....RRRRRR.....
...RRTTTTTTRR...
..RTTTTTTTTTTR..
..RTTTRRRRTTTR..
.RTTTRKRRKRTTTR.
.RTTRRRRRRRRTTR.
.RTTRKRRRRKRTTR.
.RTTRRRKKRRRTTR.
.RTTRRRRRRRRTTR.
.RTTTRKRRKRTTTR.
..RTTTRRRRTTTR..
..RTTTTTTTTTTR..
...RRTTTTTTRR...
.....RRRRRR.....
................
```

#### item_key (16 x 16, origin (8, 8))

A primary key: a long key lying flat, ring on the left, two teeth. 500 points, level 3 and 4.

Legend: `G` Gold `FFD24A`, `O` Gold Shade `B0782A`.

```
................
................
................
................
..GGGG..........
.GGOOGG.........
.GO..OG.........
.GO..OGGGGGGGGG.
.GO..OGOOOOOOOG.
.GGOOGG...GG.GG.
..GGGG....GO.GO.
..........OO.OO.
................
................
................
................
```

#### item_table (16 x 16, origin (8, 8))

A table: a wide grid with a blue header row. 700 points, level 5 and 6.

Legend: `C` Grid Cell `1A3A5A`, `H` Grid Head `3AA0E8`, `W` Grid `E0F4FF`.

```
................
................
................
.WWWWWWWWWWWWWW.
.WHHHWHHHHWHHHW.
.WHHHWHHHHWHHHW.
.WWWWWWWWWWWWWW.
.WCCCWCCCCWCCCW.
.WCCCWCCCCWCCCW.
.WWWWWWWWWWWWWW.
.WCCCWCCCCWCCCW.
.WCCCWCCCCWCCCW.
.WWWWWWWWWWWWWW.
................
................
................
```

#### item_query (16 x 16, origin (8, 8))

A query: a magnifier, a round glass with a handle to the bottom right. 1000 points, level 7 and 8.

Legend: `G` Glass `9AE8FF`, `H` Handle `8A4A2A`, `S` Reel `E8E8F0`, `X` Glass Shine `FFFFFF`.

```
................
....SSSSS.......
...SGGGGGS......
..SGXXGGGGS.....
.SGGXGGGGGGS....
.SGGGGGGGGGS....
.SGGGGGGGGGS....
.SGGGGGGGGGS....
..SGGGGGGGS.....
...SGGGGGSSS....
....SSSSSSHHH...
.........HHHH...
..........HHHH..
...........HHHH.
............HH..
................
```

#### item_trigger (16 x 16, origin (8, 8))

A trigger: a gear with eight teeth and an open middle. 2000 points, level 9 and 10.

Legend: `G` Gold `FFD24A`, `O` Gold Shade `B0782A`.

```
................
................
.......GG.......
...GG..GG..GG...
...GGGGGGGGGG...
....GGOOOOGG....
...GGO....OGG...
.GGGO......OGGG.
.GGGO......OGGG.
...GGO....OGG...
....GGOOOOGG....
...GGGGGGGGGG...
...GG..GG..GG...
.......GG.......
................
................
```

#### item_lock (16 x 16, origin (8, 8))

A lock: a padlock, a tall shackle over a box with a keyhole. 3000 points, level 11 and 12.

Legend: `G` Gold `FFD24A`, `K` Ink `140C1C`, `O` Gold Shade `B0782A`, `S` Reel `E8E8F0`.

```
................
.....SSSSSS.....
....SS....SS....
...SS......SS...
...SS......SS...
...SS......SS...
.GGGGGGGGGGGGGG.
.GOOOOOOOOOOOOG.
.GOGGGGKKGGGGOG.
.GOGGGKKKKGGGOG.
.GOGGGGKKGGGGOG.
.GOGGGGKKGGGGOG.
.GOOOOOOOOOOOOG.
.GGGGGGGGGGGGGG.
................
................
```

#### item_server (16 x 16, origin (8, 8))

A server: a tall rack of three units with lights. 5000 points, level 13 on.

Legend: `A` Rack Amber `FFB23A`, `Q` Rack Edge `7A86A0`, `R` Rack `3A4258`, `V` Rack LED `5CFF8A`.

```
................
...QQQQQQQQQQ...
...QRRRRRRRRQ...
...QRVRARRVRQ...
...QRRRRRRRRQ...
...QQQQQQQQQQ...
...QRRRRRRRRQ...
...QRARVRRARQ...
...QRRRRRRRRQ...
...QQQQQQQQQQ...
...QRRRRRRRRQ...
...QRVRVRRVRQ...
...QRRRRRRRRQ...
...QQQQQQQQQQ...
....Q......Q....
................
```

### 3.5 Data

The **bit** is not a sprite: it is 2 x 2 `Bit` at tile pixels (3, 3) to (4, 4). The commit token:

#### commit_on (6 x 6, origin (3, 3))

The commit token, lit (6 x 6). Its top left is at tile pixel (1, 1).

Legend: `R` Token Ring `7CF6A8`, `T` Token `FFFFFF`.

```
..RR..
.RTTR.
RTTTTR
RTTTTR
.RTTR.
..RR..
```

#### commit_dim (6 x 6, origin (3, 3))

The commit token, dim blink frame: smaller and darker, never gone, so a player can always see where it is.

Legend: `D` Token Dim `2E8A5A`, `R` Token Ring `7CF6A8`.

```
......
..DD..
.DRRD.
.DRRD.
..DD..
......
```

#### sparkle (5 x 5, origin (2, 2))

The sparkle on a commit token as it lights.

Legend: `S` Token Ring `7CF6A8`, `X` Spark `FFFFFF`.

```
..S..
..S..
SSXSS
..S..
..S..
```

### 3.6 Pop-ups and the 3 x 5 digits

The pop-up is the points in 3 x 5 digits (one pixel apart) with a one pixel `Outline` all round so it reads over a wall line. A 4 digit pop-up is 17 x 7; it is drawn centred on where the thing was eaten and replaces the sprites there for the pause. The digits:

```
###  .#.  ###  ###  #.#  ###  ###  ###  ###  ###
#.#  ##.  ..#  ..#  #.#  #..  #..  ..#  #.#  #.#
#.#  .#.  ###  .##  ###  ###  ###  .#.  ###  ###
#.#  .#.  #..  ..#  ..#  ..#  #.#  .#.  #.#  ..#
###  ###  ###  ###  ..#  ###  ###  .#.  ###  ###
```

(0 to 9, left to right.) Phantom points are `Pop Phantom`, item points are `Pop Item`.

#### pop_200 (13 x 7, origin (6, 3))

200 points for a phantom.

Legend: `G` Pop Phantom `7FF0FF`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KGGGKGGGKGGGK
KKKGKGKGKGKGK
KGGGKGKGKGKGK
KGKKKGKGKGKGK
KGGGKGGGKGGGK
KKKKKKKKKKKKK
```

#### pop_400 (13 x 7, origin (6, 3))

400 points for a phantom.

Legend: `G` Pop Phantom `7FF0FF`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KGKGKGGGKGGGK
KGKGKGKGKGKGK
KGGGKGKGKGKGK
KKKGKGKGKGKGK
..KGKGGGKGGGK
..KKKKKKKKKKK
```

#### pop_800 (13 x 7, origin (6, 3))

800 points for a phantom.

Legend: `G` Pop Phantom `7FF0FF`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KGGGKGGGKGGGK
KGKGKGKGKGKGK
KGGGKGKGKGKGK
KGKGKGKGKGKGK
KGGGKGGGKGGGK
KKKKKKKKKKKKK
```

#### pop_1600 (17 x 7, origin (8, 3))

1600 points for a phantom.

Legend: `G` Pop Phantom `7FF0FF`, `K` Outline `000000`.

```
.KKKKKKKKKKKKKKKK
KKGKKGGGKGGGKGGGK
KGGKKGKKKGKGKGKGK
KKGKKGGGKGKGKGKGK
KKGKKGKGKGKGKGKGK
KGGGKGGGKGGGKGGGK
KKKKKKKKKKKKKKKKK
```

#### pop_100_item (13 x 7, origin (6, 3))

100 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
.KKKKKKKKKKKK
KKFKKFFFKFFFK
KFFKKFKFKFKFK
KKFKKFKFKFKFK
KKFKKFKFKFKFK
KFFFKFFFKFFFK
KKKKKKKKKKKKK
```

#### pop_300_item (13 x 7, origin (6, 3))

300 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KFFFKFFFKFFFK
KKKFKFKFKFKFK
.KFFKFKFKFKFK
KKKFKFKFKFKFK
KFFFKFFFKFFFK
KKKKKKKKKKKKK
```

#### pop_500_item (13 x 7, origin (6, 3))

500 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KFFFKFFFKFFFK
KFKKKFKFKFKFK
KFFFKFKFKFKFK
KKKFKFKFKFKFK
KFFFKFFFKFFFK
KKKKKKKKKKKKK
```

#### pop_700_item (13 x 7, origin (6, 3))

700 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKK
KFFFKFFFKFFFK
KKKFKFKFKFKFK
.KFKKFKFKFKFK
.KFKKFKFKFKFK
.KFKKFFFKFFFK
.KKKKKKKKKKKK
```

#### pop_1000_item (17 x 7, origin (8, 3))

1000 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
.KKKKKKKKKKKKKKKK
KKFKKFFFKFFFKFFFK
KFFKKFKFKFKFKFKFK
KKFKKFKFKFKFKFKFK
KKFKKFKFKFKFKFKFK
KFFFKFFFKFFFKFFFK
KKKKKKKKKKKKKKKKK
```

#### pop_2000_item (17 x 7, origin (8, 3))

2000 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKKKKKK
KFFFKFFFKFFFKFFFK
KKKFKFKFKFKFKFKFK
KFFFKFKFKFKFKFKFK
KFKKKFKFKFKFKFKFK
KFFFKFFFKFFFKFFFK
KKKKKKKKKKKKKKKKK
```

#### pop_3000_item (17 x 7, origin (8, 3))

3000 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKKKKKK
KFFFKFFFKFFFKFFFK
KKKFKFKFKFKFKFKFK
.KFFKFKFKFKFKFKFK
KKKFKFKFKFKFKFKFK
KFFFKFFFKFFFKFFFK
KKKKKKKKKKKKKKKKK
```

#### pop_5000_item (17 x 7, origin (8, 3))

5000 points for an item.

Legend: `F` Pop Item `FF9AD0`, `K` Outline `000000`.

```
KKKKKKKKKKKKKKKKK
KFFFKFFFKFFFKFFFK
KFKKKFKFKFKFKFKFK
KFFFKFKFKFKFKFKFK
KKKFKFKFKFKFKFKFK
KFFFKFFFKFFFKFFFK
KKKKKKKKKKKKKKKKK
```

### 3.7 The debug target overlay

#### target (5 x 5, origin (2, 2))

The debug target marker, a cross in the phantom's tone 2 with a white centre, on the centre of the target tile.

Legend: `1`-`5` tones of the phantom's own row (tone 2 only), `T` Target `FFFFFF`.

```
2...2
.2.2.
..T..
.2.2.
2...2
```

The **line** from a phantom to its target: Bresenham from the phantom's origin to the target tile's centre, every other pixel drawn (1 on, 1 off), in the phantom's tone 2, skipping the first 8 pixels so it starts outside the body. A target off the map (the scatter corners) is drawn clamped to the canvas edge. Brian's line can also show his two helper points (the tile 2 ahead of Dibby and Mary's position) as single `Target` pixels, for anyone who wants to see exactly how he aims. Drawn after the characters, under the pop-ups.

### 3.8 The crash

When a phantom catches Dibby everything stops for **1000 ms**, the phantoms vanish, and then he crashes in **11 frames of 133 ms (1467 ms)**: X eyes, the lid pops off and flies up, the drum squashes down row by row, then it falls apart into bits that spread and fade. Then a 2 frame pop, 100 ms each. These frames are drawn **as they are, never turned**, at Dibby's position.

#### crash_1 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`.

```
................
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
..543322P22P25..
..543322PP2PP5..
..5433222P22P5..
..543322555555..
..5LL322222345..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_2 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`.

```
................
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
................
..543322P22P25..
..543322PP2PP5..
..5433222P22P5..
..543322555555..
..5LL322222345..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_3 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`.

```
.....555555.....
...5511111155...
..511111111115..
..521111111125..
..542222222245..
................
................
..543322P22P25..
..543322PP2PP5..
..5433222P22P5..
..543322555555..
..5LL322222345..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_4 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `L` LED `5CFF8A`, `P` Pupil `1C2A8C`.

```
................
................
................
................
.....555555.....
...5511111155...
..511111111115..
..542222222245..
..543322P22P25..
..543322PP2PP5..
..543322555555..
..5LL322222345..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_5 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
................
.....555555.....
...5511111155...
..542222222245..
..543322P22P25..
..543322PP2PP5..
..543322555555..
..544444444445..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_6 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**, `P` Pupil `1C2A8C`.

```
................
................
................
................
................
................
................
................
.....555555.....
...5511111155...
..542222222245..
..543322PP2PP5..
..543322555555..
..543322223345..
...5543333455...
.....555555.....
```

#### crash_7 (16 x 16, origin (8, 8))

Legend: `1`-`5` tones of **Dibby**.

```
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
.....555555.....
..542222222245..
..543322555555..
..543322223345..
.....555555.....
```

#### crash_8 (16 x 16, origin (8, 8))

Legend: `B` Bit `FFE6B0`.

```
................
................
................
................
................
................
................
................
........BB......
.....BB.BB.BB...
.....BB....BB...
....BB..BB..BB..
....BB..BB..BB..
................
................
................
```

#### crash_9 (16 x 16, origin (8, 8))

Legend: `B` Bit `FFE6B0`.

```
................
................
................
................
................
................
................
................
........BB......
....BB..BB..BB..
....BB......BB..
..BB....BB....BB
..BB....BB....BB
................
................
................
```

#### crash_10 (16 x 16, origin (8, 8))

Legend: `D` Token Dim `2E8A5A`.

```
................
................
................
................
................
................
................
................
................
........DD......
...DD...DD...DD.
...DD........DD.
DD......DD......
DD......DD......
................
................
```

#### crash_11 (16 x 16, origin (8, 8))

Legend: `D` Token Dim `2E8A5A`.

```
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
........DD......
..DD....DD....DD
..DD..........DD
D.......DD......
D.......DD......
................
```

#### crash_pop_1 (16 x 16, origin (8, 8))

The pop at the end of the crash.

Legend: `S` Spark `FFFFFF`, `X` Bit `FFE6B0`.

```
................
................
................
................
......S..S......
.......SS.......
....S.SXXS.S....
.....SXXXXS.....
.....SXXXXS.....
....S.SXXS.S....
.......SS.......
......S..S......
................
................
................
................
```

#### crash_pop_2 (16 x 16, origin (8, 8))

The pop at the end of the crash.

Legend: `S` Spark `FFFFFF`, `X` Bit `FFE6B0`.

```
................
................
...S........S...
....S......S....
.....S....S.....
................
................
..S....XX....S..
..S....XX....S..
................
................
.....S....S.....
....S......S....
...S........S...
................
................
```

### 3.9 Cartoon parts

#### stars (12 x 4, origin (6, 2))

Dizzy stars, drawn over a head (origin 6 pixels above the phantom origin).

Legend: `S` Player `FFD23A`.

```
..S......S..
.SSS....SSS.
..S..S...S..
.....SS.....
```

#### zz (8 x 7, origin (0, 6))

Snore, for Chip.

Legend: `Z` Text `F4F2FF`.

```
....ZZZZ
......Z.
.....Z..
ZZZ.ZZZZ
..Z.....
.Z......
ZZZ.....
```

#### rewind (7 x 5, origin (3, 2))

Rewind marks behind a phantom going backwards.

Legend: `K` Pop Phantom `7FF0FF`.

```
..K..K.
.KK.KK.
KKKKKK.
.KK.KK.
..K..K.
```

#### dibby_giant (32 x 32, origin (16, 16))

Giant Dibby (32 x 32): the half frame at 2x, for the title.

Legend: `1`-`5` tones of **Dibby**, `E` Eye `FFFFFF`, `L` LED `5CFF8A`, `M` Mouth `5A1A2A`, `P` Pupil `1C2A8C`.

```
................................
................................
................................
................................
..........555555555555..........
..........555555555555..........
......55551111111111115555......
......55551111111111115555......
....551111111111111111111155....
....551111111111111111111155....
....552211111111111111112255....
....552211111111111111112255....
....554422222222222222224455....
....554422222222222222224455....
....554433332222EEEE22EEEE55....
....554433332222EEEE22EEEE55....
....554433332222EEPP22EEPP55....
....554433332222EEPP22EEPP55....
....554433332222EEPP22EEPP55....
....554433332222EEPP22EEPP55....
....554433332222555555555555....
....554433332222555555555555....
....55LLLL33222255MMMMMMMMMM....
....55LLLL33222255MMMMMMMMMM....
....554444444444445555555555....
....554444444444445555555555....
....554433332222222233334455....
....554433332222222233334455....
......55554433333333445555......
......55554433333333445555......
..........555555555555..........
..........555555555555..........
```

The cartoons also use the lock item, the UNDO text (5 x 7 font in `Player`) and the normal sprites.

## 4. Animation recipes

| What | Frames | Timing |
|---|---|---|
| Dibby mouth | closed, half, wide, half | the next frame every **2 pixels moved** (so it chomps faster when he is faster and stops when he stops); blocked: `half`, held |
| Dibby eating a bit | no art change | the rules' pause of 1 frame per bit (3 per commit token) |
| Phantom swish | body 1, body 2 | swap every **133 ms** (8 frames), all phantoms in step |
| Rolled back wobble | rolledback 1, rolledback 2 | swap every **133 ms** |
| Flashing | rolledback n, flash n | flip every **125 ms** in the last 2000 ms of the rolled back time |
| Rolled back time | | from the rules' table: 6000 ms at level 1, then down; none from level 19 (the phantoms only turn round) |
| Phantom eaten | the pop-up replaces the phantom and Dibby | everything stops for **1000 ms**, then the eyes start returning |
| Item eaten | the pop-up replaces the item | **2000 ms**, play does not stop |
| Commit token blink | on, dim | **167 ms** each (3 blinks a second); the sparkle (section 6) on each change to on |
| 1UP blink | shown, hidden | **267 ms** each, while a game is on |
| Item bounce | 1 pixel up | 133 ms up every 533 ms |
| Mary angry | stage 1, stage 2 | follows the speed up table; no blink |
| Crash | 11 frames then 2 | 1000 ms freeze, 11 x 133 ms, 2 x 100 ms |
| End of level | 8 palette swaps | 1000 ms still, 8 x 200 ms, 200 ms black |
| READY! | text | 2000 ms at the start of a game (after the start up), 1000 ms after a crash |

## 5. Screens

All positions are canvas pixels, the top left of the text or the origin of the sprite. Text is the 5 x 7 font at 1x unless it says otherwise.

### 5.1 In game (`foreach-preview.png`)

| What | Colour | Position |
|---|---|---|
| HUD background | `Floor` | rows 0 to 23 and 272 to 287 |
| `1UP` (blinks while a game is on) | `Player` | (24, 1), tile row 0 |
| Score, right aligned, at least `00` | `Text` | right edge x 63, y 9, tile row 1 |
| `HIGH SCORE` | `Label Text` | (82, 1) |
| High score, right aligned | `Text` | right edge x 136, y 9 |
| (2UP area, empty) | | x 168 to 216 |
| Tile row 2 (y 16 to 23) | empty | |
| The maze | section 2 | y 24 to 271 |
| Spare lives, `dibby_life` | | origins (22, 279), (36, 279), (50, 279) ... 14 apart, up to 5 |
| Level counter: the items of the last 7 levels, newest on the right | | origins (200, 280), (184, 280), ... 16 apart, right to left |

### 5.2 Start of a game (about 2 seconds, then READY!)

The "boot" (all of it is drawing the static maze in steps, so it is cheap):

1. **0 to 600 ms**: the bus lines power up from the lobby outward. A wall pixel is drawn when the time passes `distance from (112, 140) x 2.5 ms`; until then it is `Floor`. The door lights last.
2. **600 to 1200 ms**: the data loads like a table: row r of bits appears at `600 + 18r ms`, the commit tokens last, with their sparkle.
3. **1200 ms**: `PLAYER ONE` in `Pop Phantom`, centred, at y 112 (tile row 11), and `READY!` in `Player`, centred, at y 160 (tile row 17).
4. **2000 ms**: the characters appear: Dibby closed, facing left; Mary above the door looking left; in the lobby Rich in the middle looking down, Brian on the left and Chip on the right, both looking up. `PLAYER ONE` goes. **4000 ms**: `READY!` goes and play starts.

After a crash: the maze stays as it is, the characters are put back, `READY!` for 1000 ms.

### 5.3 The crash, the flash, the cartoons

- **Crash**: section 3.8. The item goes at the moment of the catch; pop-ups go. The HUD loses a spare life when READY! comes back.
- **End of level flash**: section 2.4 (`foreach-preview-flash.png`).
- **Cartoons** (`foreach-cartoons.png`) play on a clear `Floor` screen with only the HUD, on a lane at y 160 (the characters' origin row), after levels **2, 5 and 9** (and the third again after 13 and 17). Each is about 5 seconds, characters at their in game speed:
  1. **DEADLOCK** (after 2): Mary chases Dibby in from the left. Rich comes in from the right. Dibby squashes flat (crash frame 5) and they bonk heads over him; dizzy stars, then the LOCK item appears over both, and they are stuck. Dibby, happy, trots off to the right.
  2. **ROLLBACK** (after 5): Brian chases Dibby. Dibby stops, turns, and `UNDO` appears over him. Brian is played backwards off the screen to the left with rewind marks behind him, comes back, and is rewound again. Dibby chomps after him.
  3. **NIGHT BATCH** (after 9, 13 and 17): Chip, who has hidden away for a nap, drifts in fast asleep, snoring Zz. Mary, Rich and Brian race in after Dibby and pile into him; stars. When they get up they are rolled back, Chip is still asleep on the bottom of the pile, and Dibby grins.

### 5.4 Game over

`GAME OVER` in `Over`, centred, at y 160 (tile row 17), where READY! was. The maze stays as it was at the crash (bits left uneaten), no characters, the level counter stays. 1UP stops blinking and stays on. 3000 ms, then the attract screen. If the score is a new high score, `NEW HIGH SCORE` in `Player` takes GAME OVER's place for the second half (it is 83 pixels wide and fits the lane).

### 5.5 Title and attract (`foreach-preview-title.png`)

In this order, each step on a clear `Floor` screen with the HUD:

| Step | What | Colour | Position |
|---|---|---|---|
| 0 ms | `FOR` at 3x, gradient, Outline | `Title Top` to `Title Bottom` | centred, y 30 |
| | `EACH` at 3x, gradient, Outline | same | centred, y 56 |
| | Giant Dibby (`dibby_giant`) | | origin (186, 54); chomps (half and closed at 2x) every 267 ms |
| 1000 ms | `PHANTOM`, `NAME`, `STYLE` | `Label Text` | (34, 92), (98, 92), (148, 92) |
| 1500 ms, then every 1000 ms | one row per phantom: the phantom, then 500 ms later its name, then 500 ms later its style | the phantom's tone 2 | phantom origin (26, 111 + 22i), name (98, 108 + 22i), style (148, 108 + 22i), i = 0 Mary, 1 Rich, 2 Brian, 3 Chip |
| | the four styles | | `CHASER`, `AMBUSH`, `FICKLE`, `SHY` |
| 6500 ms | a bit (2 x 2 at (77, 202)) and `10 PTS` | `Bit`, `Text` | text (90, 200) |
| | a commit token (`commit_on`, origin (78, 215)) and `50 PTS` | `Text` | text (90, 212) |
| 7500 ms | the chase demo on the lane y 248: Dibby runs in from the left, eats a commit token at x 60 (drawn), the four phantoms (coming from the right) are rolled back and run; Dibby eats them one by one with the 200, 400, 800, 1600 pop-ups | | lane y 248 |
| always | `PUSH START` (blinks 533 ms) | `Player` | centred, y 268 |
| always | `CREDIT  0` | `Label Text` | (4, 280) |
| about 14 s | the high score table: `HIGH SCORES` at 2x in `Player`, centred at y 92; then 5 rows `1  12560  ABC` in `Text` (rank and name in `Label Text`), x 52, y 120 + 14i. 5000 ms | | |
| about 19 s | a demo game (the computer plays level 1 for 20 s), then back to the title | | |

### 5.6 Paused and the high score note

- **Paused**: everything stops where it is; `PAUSED` in `Player` at y 160, centred, in place of READY!, blinking 533 ms. Nothing else changes (no dimming, which would be a full screen change).
- **A new high score during play**: the high score digits follow the score, and `HIGH SCORE` turns `Player` for the rest of the game.
- **Extra life at 10000**: the new life icon appears in the strip and blinks 4 times (133 ms) with the extra life jingle.

### 5.7 The first five seconds

The boot (5.2) is the special part: the bus lines light up from the lobby outwards like a machine powering on, then the data loads row by row, so the maze arrives the way a server comes up. Giant Dibby on the title chomps, and the roll call brings each phantom in with its mark visible before its name.

## 6. Effects

| Effect | Verdict | Recipe |
|---|---|---|
| **Halo** round every character | **keep** | every empty pixel 4-next to the sprite's pixels that lands on `Floor`, `Floor Stud` or `Tunnel` gets the sprite's tone 3 mixed 72% toward `Floor`. Never drawn on a wall pixel, so the lines stay clean |
| **Returning trail** | **keep** | 3 single pixels behind the eyes, 10, 14 and 18 pixels from the origin, `Eye` mixed toward `Floor` at 45%, 70%, 85%, only on floor |
| **Commit token sparkle** | **keep** | `sparkle` (5 x 5) over the commit token for 2 frames each time it turns on |
| **Bit puff** (a bit eaten) | **keep** | 2 frames: the 4 pixels diagonal to the bit's 2 x 2 in `Bit`, then the 4 pixels 2 out in `Bit` mixed 60% to `Floor`, then the floor. Nothing on a commit token (it has its own flash) |
| **Score bounce** | **keep** | a pop-up is drawn 1 pixel higher for its first 100 ms |
| **Ring** where a phantom is eaten | **keep** | an 8 pixel circle of single pixels in `Pop Phantom` at radius 8, then 12, 100 ms each, then gone (16 + 24 pixels, inside the particle budget) |
| **Tunnel edge flash** | drop | the phantoms slow there and the eye should be on them, not on the edge |
| **Whole maze wash** in the last second of the rolled back time | drop | it is a full screen change, and the flashing phantoms already say it |
| **Alarm pulse** on the walls | **keep, optional** | section 2.4: `Line` to `Pulse` for 2 frames on each beat of the alarm, off while phantoms are rolled back. Setting `foreach.pulse` |
| **Crash bits** | **keep** | the crash frames already break Dibby into bits; add 8 single `Bit` pixels flying out 1 pixel a frame for 6 frames |
| **Door blink** when a phantom goes through | add | the door stripes swap (A and B change places) while a phantom is in a door tile |
| **Commit flash** | add | when a commit token is eaten, the 4 pixels round Dibby's halo turn `Token Ring` for 2 frames |

## 7. Budgets

- The maze is baked once per level into the canvas (every wall, floor and door pixel). A palette swap (the flash, the pulse) redraws only the wall pixels whose colour changes (`Line`, `Inner`, `Glow`): about 12000 pixels, a few times a second at most.
- Per frame: 5 characters (16 x 16 with a halo), one item, up to 2 pop-ups, the debug overlay (4 markers, 4 lines of at most ~150 pixels), and at most ~40 particles (the ring is 40 at its biggest, the crash bits 8). Each moving thing first restores the baked maze under its last box (16 x 16 plus 1 for the halo), then draws: no full screen work.
- Every sprite fits 16 x 16 except the pop-ups (at most 17 x 7) and the giant Dibby on the title (32 x 32).

## 8. Checks (run by the generator)

- Every pixel of every sprite and tile is `.` or in its legend, and no legend has more than 16 colours: **passed**.
- Every sprite fits its 16 x 16 box (the pop-ups at most 17 x 7, the giant Dibby 32 x 32), origin stated for each: passed.
- The bus line is closed: every `Line` pixel of the drawn maze has at least two `Line` neighbours (8 way) except where it runs off the screen edge beside the tunnels: 0 broken pixels.
- The map has 240 bits and 4 commit tokens, no dead ends, no open 2 x 2 squares, and every lane connects (with the tunnel wrap): passed. The reader map matches it (section 2.1).
- Shape and mark, not only colour: the four phantoms (bow, hat and lids, glasses, antenna), normal against rolled back (a tail and a mark against no tail, drips and a wavy mouth), rolled back against flashing (the face changes from light to red, the body from dark to light), the bit (2 x 2) against the commit token (6 x 6 round, with a ring), and the eight items (eight silhouettes). See `foreach-colour-check.png` (the top row now also has Mary at angry stage 2): under deuteranopia and protanopia Mary turns blue (the only blue phantom, so the chaser stays easy to follow), Brian becomes a dark olive and Chip and Dibby both go yellow, which is why the marks and Dibby's different shape carry them; under tritanopia Brian and Rich are both pink red and told apart by glasses against a hat. Mary's brows stay dark on her light dome in every simulation, and her red stage 2 pupils keep the white round them.
- Contrast (WCAG ratio) against the floor, of the characters against the bright `Line`, of the roll call colours, and of the angry frames on Mary:

| Colour | Against | Ratio |
|---|---|---|
| Text | Floor | 18.2 |
| Label Text | Floor | 8.2 |
| Player | Floor | 13.9 |
| Over | Floor | 6.1 |
| Pop Phantom | Floor | 15.1 |
| Pop Item | Floor | 10.3 |
| Bit | Floor | 16.5 |
| Token | Floor | 20.1 |
| Line | Floor | 12.2 |
| Inner | Floor | 4.9 |
| Door | Floor | 13.9 |
| Mary tone 3 | Floor | 6.0 |
| Mary tone 3 | Line | 2.0 |
| Rich tone 3 | Floor | 8.4 |
| Rich tone 3 | Line | 1.5 |
| Brian tone 3 | Floor | 5.4 |
| Brian tone 3 | Line | 2.2 |
| Chip tone 3 | Floor | 11.7 |
| Chip tone 3 | Line | 1.0 |
| Dibby tone 3 | Floor | 12.5 |
| Dibby tone 3 | Line | 1.0 |
| Rollback tone 3 | Floor | 3.1 |
| Rollback tone 3 | Line | 3.9 |
| Flash tone 3 | Floor | 17.1 |
| Flash tone 3 | Line | 1.4 |
| Mary tone 2 (roll call) | Floor | 8.8 |
| Rich tone 2 (roll call) | Floor | 10.8 |
| Brian tone 2 (roll call) | Floor | 7.7 |
| Chip tone 2 (roll call) | Floor | 13.6 |
| Ink (angry brows) | Mary tone 1 | 13.7 |
| Ink (angry brows) | Mary tone 2 | 8.4 |
| Angry (pupils) | Eye | 3.7 |
| Steam | Floor | 13.4 |

Every text colour, and each roll call row, is above 6 to 1 on the floor. A character body against the bright line is low (that is the point of the line), which is why every character has a dark edge (section 1) and the halo is never drawn on a wall: where Dibby or a phantom overlaps a line in a turn, its edge separates it. The angry brows are above 8 to 1 on Mary's top tones; the `Angry` pupils are 3.7 to 1 against the white of the eye, enough for a 2 x 2 mark that also changes hue.

## 9. What I decided and why

1. **The look is our own.** Dibby is a database drum with a jaw, amber; the phantoms are wisps with a tail and a personal mark; the maze is our own layout; the items, the three cartoons, the logo and the roll call are new. The rules (the four hunting styles, the scatter and chase waves, the rolled back table, the speed tables, cornering, the bit pause, the angry speed up, returning to the lobby, the tunnel, the item schedule and points, the extra life, the cartoon schedule, the attract mode order) are kept as the rules say.
2. **The database theme**: Dibby the database drum; bits of data; commit tokens; the phantoms (after the phantom read) who are rolled back; items that are database things; the cartoons DEADLOCK, ROLLBACK and NIGHT BATCH; the working title **FOR EACH**, the ABL loop that visits every record, which is what Dibby does to the maze. It is a nod to the OpenEdge world through words an ABL developer knows, without any company's name, logo or brand colours.
3. **The phantoms are Mary, Rich, Brian and Chip** (James's names), by role: Mary the chaser, Rich the ambusher, Brian the unpredictable one, Chip the shy one. Each keeps the colour row and mark first drawn for them.
4. **File names**: this file is `foreach-art.md` and the pictures are `foreach-*.png`.
5. **Walls as a rule, with the 47 tiles listed.** The rule is a distance band rule (as Blast Buddies), but it only ever looks at a tile's 8 neighbours, so it is also an exact autotile set. Use whichever is easier in ABL; the pixels are the same.
6. **The lobby is 10 tiles wide** (a floor of 8 x 3), so the three phantoms inside never overlap at 16 pixels apart. The door is at columns 13 and 14.
7. **Facing**: Dibby turns (mirror and quarter turns, his shading is symmetric); the phantoms do not turn, only their eyes move.
8. **Level 256**: reaching level 256 shows `ERROR: LEVEL > 255` in `Over` on the READY! line, the maze flashes as at the end of a level, and the game ends with the high score table.
9. **The roll call** says `PHANTOM`, `NAME`, `STYLE`, and the styles are one word each.
10. **Nothing in this design needs a rule of the game to change.** The scatter corners, the start positions, the no-turning-up stretches and the tunnel zone are given for our map (section 2.1).
11. **Not done in this pass** (it needs PowerShell, git or a window): no commit, no art classes, no screenshot from the real canvas. The previews come from the generator, which draws exactly what the rules above describe.
12. **The generator** is in `docs/design/foreach-generator/` (Python 3 and Pillow). From that folder run `python run_all.py`: it writes `foreach-art.md` and every `foreach-*.png` into `docs/design/` (or into the folder given as its one argument) and prints the checks. The data is in the `.py` files themselves: `palette.py` (colours), `maze.py` (the map, the wall rule, the reader map), `dibby.py`, `phantoms.py`, `items.py`, `ui.py` (sprites), `draw.py` (`turn` and stamping), `preview.py` (the pictures), `check.py` (the checks) and `doc.py` (this file).
13. **Open questions** for the code (not rules of the game, and not settled above), each with my preference:
    1. **Which way the eyes look.** A phantom decides its next turn one tile early. Show the direction it is moving in now, or the one it has chosen for the next tile? *Preference: the chosen next direction*, so a sharp player can read a turn coming; the art is the same.
    2. **`M` and `P` on no-turning-up tiles** (section 2.1): the reader must count them as `U`. *Preference: the reader keeps a separate list of start positions and reads every start tile as the tile under it.*
    3. **Pop-ups near the edge.** A 17 pixel pop-up centred near the tunnel mouth would leave the canvas. *Preference: clamp it so it stays fully inside x 0 to 223.*
    4. **High score name entry** is not designed. *Preference: 3 letters, chosen with up and down and confirmed with fire, in `Player` at 2x on the GAME OVER line, the letter being changed blinking 267 ms.*
    5. **Settings and keys.** *Preference: `foreach.debug` for the target overlay (key D), `foreach.pulse` for the alarm pulse (on), `foreach.speed` as a percentage like Asteroids.*
    6. **The demo game in the attract mode.** *Preference: the computer player is a simple greedy chaser of the nearest bit that avoids the nearest phantom, run on the seeded random source so the demo is the same every time.*
    7. **Two players.** The 2UP area is left empty. *Preference: one player only.*
    8. **Draw order of overlapping phantoms.** *Preference: in role order with Mary last (on top), so the chaser is never hidden.*
    9. **The halo and the trail in the tunnel.** *Preference: drawn on the `Tunnel` floor too (it counts as floor), and cut at the canvas edge like the sprite.*
    10. **The level counter after level 13.** *Preference: it keeps showing the last 7 items, so from level 19 on it is seven servers.*

## 10. Sprite index

| Sprite | Size | Origin | Section |
|---|---|---|---|
| dibby_closed | 16 x 16 | (8, 8) | 3.1 |
| dibby_half | 16 x 16 | (8, 8) | 3.1 |
| dibby_wide | 16 x 16 | (8, 8) | 3.1 |
| dibby_happy | 16 x 16 | (8, 8) | 3.1 |
| dibby_life | 12 x 12 | (6, 6) | 3.1 |
| phantom_body_1 | 16 x 16 | (8, 8) | 3.2 |
| phantom_body_2 | 16 x 16 | (8, 8) | 3.2 |
| phantom_eyes_right | 16 x 16 | (8, 8) | 3.2 |
| phantom_eyes_left | 16 x 16 | (8, 8) | 3.2 |
| phantom_eyes_up | 16 x 16 | (8, 8) | 3.2 |
| phantom_eyes_down | 16 x 16 | (8, 8) | 3.2 |
| mark_brian | 16 x 16 | (8, 8) | 3.2 |
| mark_mary | 16 x 16 | (8, 8) | 3.2 |
| mark_chip | 16 x 16 | (8, 8) | 3.2 |
| mark_rich | 16 x 16 | (8, 8) | 3.2 |
| mary_angry_1 | 16 x 16 | (8, 8) | 3.2 |
| mary_angry_2 | 16 x 16 | (8, 8) | 3.2 |
| rolledback_1 | 16 x 16 | (8, 8) | 3.3 |
| rolledback_2 | 16 x 16 | (8, 8) | 3.3 |
| flash_1 | 16 x 16 | (8, 8) | 3.3 |
| flash_2 | 16 x 16 | (8, 8) | 3.3 |
| returning_right | 16 x 16 | (8, 8) | 3.3 |
| returning_left | 16 x 16 | (8, 8) | 3.3 |
| returning_up | 16 x 16 | (8, 8) | 3.3 |
| returning_down | 16 x 16 | (8, 8) | 3.3 |
| item_floppy | 16 x 16 | (8, 8) | 3.4 |
| item_tape | 16 x 16 | (8, 8) | 3.4 |
| item_key | 16 x 16 | (8, 8) | 3.4 |
| item_table | 16 x 16 | (8, 8) | 3.4 |
| item_query | 16 x 16 | (8, 8) | 3.4 |
| item_trigger | 16 x 16 | (8, 8) | 3.4 |
| item_lock | 16 x 16 | (8, 8) | 3.4 |
| item_server | 16 x 16 | (8, 8) | 3.4 |
| commit_on | 6 x 6 | (3, 3) | 3.5 |
| commit_dim | 6 x 6 | (3, 3) | 3.5 |
| pop_200 | 13 x 7 | (6, 3) | 3.6 |
| pop_400 | 13 x 7 | (6, 3) | 3.6 |
| pop_800 | 13 x 7 | (6, 3) | 3.6 |
| pop_1600 | 17 x 7 | (8, 3) | 3.6 |
| pop_100_item | 13 x 7 | (6, 3) | 3.6 |
| pop_300_item | 13 x 7 | (6, 3) | 3.6 |
| pop_500_item | 13 x 7 | (6, 3) | 3.6 |
| pop_700_item | 13 x 7 | (6, 3) | 3.6 |
| pop_1000_item | 17 x 7 | (8, 3) | 3.6 |
| pop_2000_item | 17 x 7 | (8, 3) | 3.6 |
| pop_3000_item | 17 x 7 | (8, 3) | 3.6 |
| pop_5000_item | 17 x 7 | (8, 3) | 3.6 |
| target | 5 x 5 | (2, 2) | 3.7 |
| crash_1 | 16 x 16 | (8, 8) | 3.8 |
| crash_2 | 16 x 16 | (8, 8) | 3.8 |
| crash_3 | 16 x 16 | (8, 8) | 3.8 |
| crash_4 | 16 x 16 | (8, 8) | 3.8 |
| crash_5 | 16 x 16 | (8, 8) | 3.8 |
| crash_6 | 16 x 16 | (8, 8) | 3.8 |
| crash_7 | 16 x 16 | (8, 8) | 3.8 |
| crash_8 | 16 x 16 | (8, 8) | 3.8 |
| crash_9 | 16 x 16 | (8, 8) | 3.8 |
| crash_10 | 16 x 16 | (8, 8) | 3.8 |
| crash_11 | 16 x 16 | (8, 8) | 3.8 |
| crash_pop_1 | 16 x 16 | (8, 8) | 3.8 |
| crash_pop_2 | 16 x 16 | (8, 8) | 3.8 |
| stars | 12 x 4 | (6, 2) | 3.9 |
| zz | 8 x 7 | (0, 6) | 3.9 |
| rewind | 7 x 5 | (3, 2) | 3.9 |
| sparkle | 5 x 5 | (2, 2) | 3.5 |
| dibby_giant | 32 x 32 | (16, 16) | 3.9 |

