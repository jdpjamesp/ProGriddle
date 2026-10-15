# Girder Rush: art and screen design, "Dusk Shift"

Designer's answer to `girder-rush-art-brief.md`. It is meant to be pasted into code with no further decisions. Where I disagree with the brief or had to choose, it is in section 10; the most important one is that **the girder heights in the brief do not leave room for the hero**, so section 2.1 has new numbers (and lowest girder slopes the other way). Previews, all at 3x with nearest neighbour scaling: `girder-rush-preview.png` (stage 1 in game), `girder-rush-preview-title.png` (title and attract), `girder-rush-preview-over.png` (game over), and `girder-rush-colour-check.png` (the in game picture as it is, then simulated for deuteranopia, protanopia and tritanopia).

Every sprite block, every table of numbers and every preview below was made by one small script from one set of data, so the pictures and the text cannot disagree. Every sprite was checked: each pixel is `.` or in its legend, and no legend has more than 16 colours.

## 0. Read this first

- The canvas is **224 x 256**, origin top left, shown at 3x (or 2x). One pixel of this file is one canvas pixel.
- **Sprite format**: as in the brief and `snake-art.md`. `.` is transparent. `1` to `5` are the five tones of the sprite's colour row (1 highlight, 5 edge). Capital letters are named colours from the legend under each block. A few sprites use letters past `H` (up to `L`); `Tile` accepts any capital letter, and no legend goes over 16 colours.
- **Origin**: every block gives its origin as (column, row) inside the picture. For anything that stands, the origin row is **one below the picture's last row**: draw the sprite with its top left at `(x - ox, surfaceY - oy)` and its lowest row lands on `surfaceY - 1`, directly on top of the girder's surface row. So "origin on the surface" means the feet touch the surface row and never cover it.
- **Facing**: everything that walks is drawn facing right; mirror the columns for left (`x' = width - 1 - x`, and the origin column mirrors the same way). All lighting is **from straight above** (the site floodlights on the crane), so mirrored frames are still correct and no left frames are needed. The ape and the captive face the viewer.
- **Draw order (back to front)**: 1 the baked background (sky, skyline, crane), 2 ladders, 3 girders, 4 static props (oil drum, barrel stack, hammers, items), 5 the ape and the captive, 6 barrels and fireballs, 7 the hero, 8 particles and score pop-ups, 9 the HUD, 10 banners.
- **Text** is the 5 x 7 font with one pixel between letters: `n` characters at scale `k` are `n * 6k - k` wide. "Centred" means `x = floor((224 - width) / 2)`. Gradient text: row `r` of `n` letter rows is the mix of the top and bottom colours at `r / (n - 1)`. The font has no comma or apostrophe, and every word below uses only its characters.
- **Time** is in milliseconds. The game runs 60 frames a second; animations count from the game's own clock, as in the other games.

What is in the file: 1 art direction and palette, 2 stage 1 layout and scenery, 3 sprites, 4 animation recipes, 5 screens, 6 effects, 7 later stages, 8 budgets, 9 checks, 10 what I decided and why.

## 1. Art direction and palette

### Idea

**Dusk Shift.** The last hour of the day shift on a tower going up. The sky runs from deep night blue at the top to a low ember glow on the horizon, behind a skyline of unfinished concrete frames and one tower crane with a red light on its jib. The structure you climb is **teal painted steel**: Warren truss girders with rivets, the sky showing through the triangles, and **hazard striped end caps** where a girder stops (so "the edge" is obvious). Ladders are pale aluminium. Against that cool, quiet set, everything that matters is lit and warm: the hero is a site worker in a **white hard hat and a lime hi-vis vest with silver tape**, barrels are warm oak with iron hoops, fire is white hot to red, and good things (hammer glints, bonus sparkles, extra life, score pop-ups) are gold. The ape is a big **silverback** in a safety helmet that is far too small and a belt of hazard tape; the captive is **Rivet**, a little survey robot with a mint screen face and an orange antenna lamp. It is a sibling of the other games (the same five tone ramp formula as Lantern Glass, the Cookoff orange as the accent, the same plates and outlined text), but its own thing: teal and lime on dusk, which no other game uses.

### Colour rules (what is the same on purpose)

1. **Structure is cool**: girders, ladders, the perch, columns, the HUD frames. Nothing that moves is teal or grey blue.
2. **What hurts you is warm and round**: barrels (oak), fireballs and flames (the Flame row). The one exception is the **wild barrel**, a blue chemical drum with a white band, on purpose: it breaks the rules, so it looks wrong at a glance.
3. **Safety orange is the house accent** (`FF9A3C`, close to the Cookoff orange): the stage number, the bonus box, banner rules, the ape's helmet and Rivet's antenna lamp (the two characters at the top share it).
4. **Gold means good news**: hammer glint, bonus sparkles, score pop-ups, NEW HIGH SCORE, STAGE CLEAR, the extra life.
5. **The hero owns lime and white**: nothing else on screen is lime, so the hero is the one thing your eye finds first.
6. **The background is always darker and greyer than anything that moves** (the brightest background colour, `7A5A30`, is a 2 pixel window).

### Tone rows

Tones: five values from lightest (1) to darkest (5); tone 3 is the base. As in Lantern Glass: tones 1 and 2 mix the base with white (70 and 30 percent), tones 4 and 5 mix it with `05080F` (32 and 64 percent). The Flame row is hand made.

| Row | 1 Highlight | 2 Light | 3 Base | 4 Shade | 5 Edge | Used for |
|---|---|---|---|---|---|---|
| Steel `3C8A9A` | `C4DCE1` | `76ADB8` | `3C8A9A` | `2A606E` | `193741` | girders, columns and platforms (teal painted steel) |
| Rail `A9B8C8` | `E5EAEE` | `C3CDD8` | `A9B8C8` | `75808D` | `404752` | ladder rails and rungs (aluminium) |
| Vest `C6EC3C` | `EEF9C4` | `D7F276` | `C6EC3C` | `88A32E` | `4A5A1F` | the hero: hi-vis vest, and the HUD lives icon band |
| Wood `B5652C` | `E9D1C0` | `CB936B` | `B5652C` | `7D4723` | `442919` | barrels (staves and end grain) |
| Cobalt `3B74DA` | `C4D5F4` | `769EE5` | `3B74DA` | `2A5199` | `182F58` | the wild barrel (a blue chemical drum) |
| Fur `5C5672` | `CECCD5` | `8D899C` | `5C5672` | `403D52` | `242433` | the ape (a silverback: tones 1 and 2 are the silver) |
| Drum `4B566E` | `C9CCD4` | `81899A` | `4B566E` | `353D50` | `1E2431` | the oil drum |
| Robot `D9E3E6` | `F4F7F8` | `E4EBEE` | `D9E3E6` | `959DA1` | `51575C` | the captive, Rivet the survey robot |
| Head `B3BFCC` | `E8ECF0` | `CAD2DB` | `B3BFCC` | `7B8490` | `444A53` | the hammer head and bonus item metal |
| Gold `FFC23A` | `FFEDC4` | `FFD475` | `FFC23A` | `AF862C` | `5F4B1E` | helpers: hammer glint, bonus sparkle, extra life, score pop-ups |
| Flame `FF8A1E` | `FFF6CF` | `FFD340` | `FF8A1E` | `E2412A` | `7A1C14` | fireball, drum flames, sparks and the hot rim of everything that burns |

### Named colours

| Name | Hex | Used for |
|---|---|---|
| Sky Top | `090C18` | sky at y = 0 (behind the HUD) |
| Sky High | `111733` | sky at y = 96 |
| Sky Low | `231D38` | sky at y = 184 |
| Sky Ember | `3A2332` | sky at y = 243, the last light of the day on the horizon |
| Star | `3A4570` | a few 1 pixel stars, baked |
| Far Block | `161B30` | the far skyline (unfinished towers) |
| Near Block | `1B2238` | the near skyline and the crane |
| Block Edge | `252E4A` | a 1 pixel lit top edge on each tower and the crane jib |
| Window | `5A4A34` | a lit window, 1 x 2 pixels, baked |
| Window Warm | `7A5A30` | a brighter lit window, a few of them |
| Crane Lamp | `D8503A` | the red light on the crane jib tip (blinks) |
| Ground Fill | `0C0F1A` | below the ground girder, y 252 to 255 |
| Rivet | `E4F6F8` | rivet shine (letter R in the girder profile) |
| Rivet Dim | `1E4A54` | rivet shadow (letter D) |
| Bracket | `2A5F6C` | girder end brackets and the support columns (letter B) |
| Rail Dark | `4A5566` | lift cables and spring coils (later stage sketches) |
| Head Light | `E2E8EE` | spring coil shine (later stage sketches) |
| Hat | `F6F8FA` | hard hat |
| Hat Shade | `BCC6D2` | hard hat lower half and brim |
| Skin | `EDB48A` | face and hands |
| Skin Shade | `B97A55` | ear, chin shadow |
| Trousers | `2D3E6E` | work trousers (navy) |
| Trousers Light | `4A5E98` | the lit side of the trousers |
| Reflect | `E8F2FF` | reflective tape on the vest and trousers |
| Ink | `0A0D17` | the 1 pixel outline of the hero, eyes, boots, the darkest detail anywhere |
| Face | `2B2433` | the ape face, hands and feet (leathery) |
| Muzzle | `857786` | the ape muzzle and brow ridge light |
| Eye White | `F2EEE4` | eye whites, teeth |
| Pupil | `120C10` | pupils, nostrils, mouth |
| Helmet | `FF8A2A` | the ape safety helmet (too small) |
| Helmet Light | `FFC48A` | the helmet shine |
| Tape | `FFD23A` | hazard tape (yellow) |
| Tape Dark | `1C1A22` | hazard tape (dark stripe) |
| Angry | `E2412A` | the angry eye glint (same as Flame tone 4 on purpose) |
| Hoop | `2E2224` | barrel hoops and the end rim (iron) |
| Hoop Light | `8E7E78` | the lit edge of a hoop |
| Grain | `6E3A18` | end grain lines and plank seams |
| Drum Rim | `C8D2DC` | the wild barrel rim |
| Hazard | `F4F6F8` | the wild barrel band (white) |
| Drum Band | `FFD23A` | the oil drum hazard band (same as Tape) |
| Drum Band Dark | `1C1A22` | the oil drum hazard band stripes (same as Tape Dark) |
| Drum Mark | `FF8A1E` | the two flame marks on the oil drum (Flame tone 3) |
| Glow | `5A2A1E` | the dim pulse round the burning drum |
| Glow Hot | `8A3A20` | the bright step of the drum glow |
| Fire Eye | `2A0A08` | fireball eyes |
| Screen | `1E3A44` | Rivet the robot face screen |
| Screen Eye | `7CF0E0` | Rivet eyes (a cool mint glow) |
| Antenna | `FF8A2A` | the antenna lamp (same as Helmet: the site orange) |
| Wheel | `30384A` | Rivet tracks and arm joints |
| Bubble | `F6F8FA` | the HELP speech bubble |
| Help Red | `E2412A` | the word HELP |
| Handle | `C48A4E` | hammer handle (light ash) |
| Handle Dark | `7E5230` | hammer handle shade and grip |
| Tape Case | `FFC23A` | tape measure case (Gold tone 3) |
| Tape Blade | `EEF2F8` | tape measure blade |
| Lunch | `E2412A` | lunch box body |
| Lunch Light | `F07A62` | lunch box lid |
| Flask | `2FA37A` | the thermos flask (site green) |
| Flask Light | `8FE0C0` | the flask shine |
| Cup | `EEF2F8` | the flask cup |
| Text | `EEF2F8` | numbers and words |
| Label | `8090AA` | SCORE, HIGH SCORE, STAGE, BONUS labels and hints |
| Dim | `A2AEC2` | the high score number, secondary lines |
| Accent | `FF9A3C` | the site orange: the stage number, banner rules, the bonus box frame |
| Good | `FFC23A` | good news: a new high score, extra life, STAGE CLEAR (Gold tone 3) |
| Warn | `FF5A3C` | the bonus timer under 1000, blinking |
| Over Top | `FFB27A` | GAME OVER, top row of the gradient |
| Over Bottom | `E2412A` | GAME OVER, bottom row |
| Title Top | `FFE36A` | the title, top row of the gradient |
| Title Bottom | `FF8A2A` | the title, bottom row |
| Plate | `070A12` | the fill of every banner plate and the bonus box |
| Plate Rule | `2A3550` | the inner line of the bonus box |
| Outline | `070A10` | the 1 pixel outline behind text that sits on play |
| Flash | `FFFFFF` | a hit flash, the first colour of every spark |

## 2. Stage 1 layout and scenery

### 2.1 The girders (final numbers)

A girder is a line on its **top surface**. Its surface at column `x` is `y0 + d * floor((x - x0) / 16)`: one pixel every 16 columns, stepping at the girder's own 16 column tiles. The girder is drawn 8 rows deep from the surface down (rows `surface` to `surface + 7`). Barrels roll downhill; at an open end they fall off, turn round and land on the girder below.

| Girder | x0 to x1 | Surface at x0 | d | Surface at x1 | Open end | Barrels roll |
|---|---|---|---|---|---|---|
| ground | 0 to 223 | 244 | +0 | 244 | none | left, to the oil drum |
| g1 | 0 to 207 | 208 | +1 | 220 | right | right |
| g2 | 16 to 223 | 184 | -1 | 172 | left | left |
| g3 | 0 to 207 | 136 | +1 | 148 | right | right |
| g4 | 16 to 223 | 112 | -1 | 100 | left | left |
| top | 0 to 79 | 64 | +0 | 64 | none | (the ape's platform) |
| g5 | 80 to 207 | 65 | +1 | 72 | right | right |
| perch | 96 to 143 | 40 | +0 | 40 | both (guard rails) | (the captive's perch) |

`top` and `g5` meet at x 79 / 80 and read as one girder: flat under the ape, then sloping down to the right (the step from 64 to 65 is the first slope step). The ground is flat and solid (no truss holes). Below it, rows 252 to 255 are Ground Fill.

**Clear height**, surface to surface, at the closest and widest point of each pair:

| Lower | Upper | Closest | Widest |
|---|---|---|---|
| ground | g1 | 24 | 36 |
| g1 | g2 | 25 | 47 |
| g2 | g3 | 25 | 47 |
| g3 | g4 | 25 | 47 |
| g4 | g5 | 29 | 43 |
| g4 | top | 45 | 48 |
| g5 | perch | 26 | 28 |

So the space under a girder (surface below to the underside of the girder above, 8 less) is at least 16: the hero (16 high) always fits standing. A jump at the very closest end can pass in front of the girder above by up to 18 pixels; there is no ceiling in the rules, so the hero is simply drawn over it. Section 10 says why the brief's 28 cannot be had on 224 rows.

### 2.2 Ladders

Ladders are 10 wide at `x = 16k + 3`, inside one 16 column step, so both ends are flat. A ladder runs from the upper girder's surface to the lower girder's surface; the hero climbs between those two y values. Broken ladders cannot be climbed; barrels may still go down them.

| x (left column) | Lower | Upper | Top surface y | Bottom surface y | Kind |
|---|---|---|---|---|---|
| 35 | ground | g1 | 210 | 244 | broken |
| 99 | ground | g1 | 214 | 244 | whole |
| 179 | ground | g1 | 219 | 244 | whole |
| 35 | g1 | g2 | 183 | 210 | whole |
| 131 | g1 | g2 | 177 | 216 | whole |
| 195 | g1 | g2 | 173 | 220 | broken |
| 35 | g2 | g3 | 138 | 183 | broken |
| 83 | g2 | g3 | 141 | 180 | whole |
| 179 | g2 | g3 | 147 | 174 | whole |
| 35 | g3 | g4 | 111 | 138 | whole |
| 115 | g3 | g4 | 106 | 143 | whole |
| 163 | g3 | g4 | 103 | 146 | broken |
| 99 | g4 | g5 | 66 | 107 | broken |
| 179 | g4 | g5 | 71 | 102 | whole |
| 131 | g5 | perch | 40 | 68 | whole |

Two whole ladders per gap and one broken (one whole at the top, as the last climb should be a choice under fire), placed so that the whole ones are never straight above each other: you must walk a girder each time, under the barrels. The hoist ladders for the intro (section 5.3) are at x 99 and 115 from y 244 up to 40, drawn only during the intro.

**How to draw a ladder** (top surface `ty`, bottom surface `by`): `ladder_cap` at `ty - 3`; then `ladder_rung` every 4 rows from `ty` while the row is below `by - 3` (the girder covers the first two); then `ladder_foot` at `by - 3`. A **broken** ladder: the cap, rungs from `ty` to `ty + 7`, `ladder_broken_top` at `ty + 8`, nothing, then `ladder_broken_bottom` at `by - 13`, one rung at `by - 7` and the foot at `by - 3`. Draw ladders before girders.

### 2.3 Where things stand

| Thing | x | y (surface) | Notes |
|---|---|---|---|
| hero_start | 40 | 244 | origin of the hero, facing right |
| oil_drum | 12 | 244 | origin of `oil_drum`; the flame sits on its top row (y 228) |
| hammer_1 | 72 | 181 | centre of `hammer_item` at y - 14 = 167 |
| hammer_2 | 152 | 104 | centre at y - 14 = 90 |
| item_tape | 152 | 217 | 300 points |
| item_lunch | 136 | 144 | 500 points |
| item_flask | 168 | 70 | 800 points |
| ape | 50 | 64 | origin of the ape (the middle of its feet), picture x 27 to 72 |
| stack | 12 | 64 | origin of `barrel_stack`, x 0 to 23 |
| captive | 112 | 40 | origin of Rivet; the HELP bubble tail tip is at (121, 29) |

The barrel leaves the ape's hands at origin + (19, -6) = (69, 58), centre of the barrel, and starts rolling right along `top` and `g5`. Fireballs are born at the drum's top, (12, 226), and drop onto the ground facing right.

### 2.4 HUD (top 24 rows) and the bonus box

The HUD sits on the sky (no plate) in rows 0 to 23. The bonus box hangs under it on the right, where no girder is close.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| SCORE label | `SCORE` | Label | 1x | 6 | 2 |
| SCORE value | 6 digits, zero padded | Text (Good for 300 ms after a score, see 6) | 2x | 6 | 10 |
| Lives | one `lives_icon` per spare life, up to 4 | | | 93, 103, 113, 123 | 3 |
| STAGE | `STAGE ` in Label, then the number in Accent | Label, Accent | 1x | 91 (centred as `STAGE 1`) | 14 |
| HIGH SCORE label | `HIGH SCORE` | Label | 1x | 159 (right edge 218) | 2 |
| HIGH SCORE value | 6 digits | Dim (Good when you hold it) | 2x | 148 | 10 |
| Bonus box | 54 x 26, Plate fill, 1 pixel Accent frame, Plate Rule lines at rows 2 and 23 inside | | | 166 | 26 |
| BONUS label | `BONUS` | Label | 1x | 178 | 30 |
| BONUS value | 4 digits | Text; Warn below 1000, blinking 250 on 250 off | 2x | 170 | 37 |

The bonus starts at 5000 and drops 100 every 2 seconds (the brief's step; 100 seconds for the stage). At 0 the hero loses a life, as in the arcade.

### 2.5 Scenery tiles

#### girder_profile (16 x 8, origin (0, 0))

Repeat every 16 columns from the girder's x0. Row 0 is the surface. Holes (dots) show the sky.

Legend: `1`-`5` tones of **Steel**, `D` Rivet Dim `1E4A54`, `R` Rivet `E4F6F8`.

```
1111111111111111
222R2222222R2222
444D4444444D4444
33....3333....33
.44..44..44..44.
..4444....4444..
2222R2222222R222
5555555555555555
```

#### ground_profile (16 x 8, origin (0, 0))

The ground girder (flat, y 244). Solid web with one bolt plate. Rows 252 to 255 below it are Ground Fill.

Legend: `1`-`5` tones of **Steel**, `B` Bracket `2A5F6C`, `D` Rivet Dim `1E4A54`, `R` Rivet `E4F6F8`.

```
1111111111111111
222R2222222R2222
444D4444444D4444
3333333333333333
4444444444444444
44444BB444444444
2222R2222222R222
5555555555555555
```

#### girder_end_left (4 x 8, origin (0, 0))

Left hand open end: replaces the first 4 columns (x0 to x0 + 3).

Legend: `1`-`5` tones of **Steel**, `A` Tape `FFD23A`, `B` Tape Dark `1C1A22`.

```
1111
5BAA
5BBA
5ABB
5AAB
5BAA
5222
5555
```

#### girder_end_right (4 x 8, origin (3, 0))

Right hand open end: replaces the last 4 columns (x1 - 3 to x1). Origin is the last column, row 0.

Legend: `1`-`5` tones of **Steel**, `A` Tape `FFD23A`, `B` Tape Dark `1C1A22`.

```
1111
AAB5
ABB5
BBA5
BAA5
AAB5
2225
5555
```

#### girder_end_wall (4 x 10, origin (0, 0))

Closed end at the screen edge (x = 0 or 223): replaces 4 columns, mirrored on the right. Hangs 2 rows below.

Legend: `1`-`5` tones of **Steel**, `B` Bracket `2A5F6C`.

```
1111
2B22
4B44
3B33
4B44
4B44
2B22
5B55
.B5.
.55.
```

#### ladder_rung (10 x 4, origin (0, 0))

Repeat down the ladder every 4 rows, starting at the upper girder's underside.

Legend: `1`-`5` tones of **Rail**.

```
24......24
2422222224
2455555524
24......24
```

#### ladder_cap (10 x 3, origin (0, 2))

Rail tops that stand 3 rows above the upper surface (handholds): rows surface - 3 to surface - 1. Drawn before the girder, so the girder covers the rails where they cross it.

Legend: `1`-`5` tones of **Rail**.

```
12......12
24......24
24......24
```

#### ladder_foot (10 x 3, origin (0, 2))

The last 3 rows above the lower surface: rows surface - 3 to surface - 1.

Legend: `1`-`5` tones of **Rail**.

```
24......24
24......24
55......55
```

#### ladder_broken_top (10 x 6, origin (0, 0))

The end of the upper stub of a broken ladder (bent rails).

Legend: `1`-`5` tones of **Rail**.

```
24......24
2422222224
2455555524
24......4.
.4......4.
.4.......5
```

#### ladder_broken_bottom (10 x 6, origin (0, 0))

The top of the lower stub of a broken ladder.

Legend: `1`-`5` tones of **Rail**.

```
.1.......1
.2......2.
24......24
2422222224
2455555524
24......24
```

#### perch_rail (4 x 5, origin (0, 4))

A guard rail post at each end of the captive's perch, 4 wide, standing on the perch surface. A 1 row rail joins the two post tops (Rail tone 2).

Legend: `1`-`5` tones of **Rail**.

```
.12.
.24.
.24.
.24.
1111
```

**The step**: the profile is drawn one column at a time, each column at its own surface y. All its vertical features (the truss posts, the rivets) are away from columns 0 and 15, and the steps fall exactly between column 15 of one tile and column 0 of the next, where the truss diagonal meets the next one. A 1 pixel step there reads as a joint between two girder sections. Barrels and the hero use the surface row of the column under their middle, so their lowest row always touches it (no float, no sink).

**Open and closed ends**: an open end gets `girder_end_left` or `girder_end_right` over its last 4 columns. An end at the screen edge that is not open (g1 and g3 at x 0, g2 and g4 at x 223) gets `girder_end_wall`, mirrored on the right. The ground and the top platform have none. The perch gets a guard rail post (`perch_rail`) at each end, joined by a 1 pixel rail at y 36.

### 2.6 The background (baked once)

1. **Sky**: rows 0 to 243 are a vertical blend through Sky Top (y 0), Sky High (y 96), Sky Low (y 184) and Sky Ember (y 243). Rows 252 to 255 are Ground Fill.
2. **Stars**: 15 single pixels of Star at (14,36) (40,52) (66,30) (90,46) (150,34) (172,60) (210,40) (122,74) (24,88) (196,96) (58,108) (138,100) (6,120) (214,126) (102,118).
3. **Far towers** (Far Block), each from its top y down to 243, as a concrete frame: a floor line every 8 rows from the top and a 2 pixel column every 8 columns from its left plus one on its right edge, the bays left as sky. A Block Edge line on the top row and 2 pixel rebar stubs above every column. At (x, width, top): (4, 30, 150), (38, 22, 172), (64, 34, 128), (104, 26, 160), (136, 40, 138), (182, 20, 168), (204, 20, 146). Three 1 x 2 Window pixels per tower in random bays (seed it, so it is the same every run).
4. **The crane** (Near Block): a mast of two 1 pixel uprights at x 160 and 165 from y 80 to 243 with a zigzag between them (a 6 row period) and a cross bar every 6 rows; a jib from x 96 to 219, rows 80 to 83, top row Block Edge, with a zigzag lattice; a counterweight block x 206 to 217, rows 84 to 89; the cab x 158 to 167, rows 84 to 90 with a 2 pixel Window Warm; a hook cable at x 128 from y 84 to 123 with a 5 pixel hook. The **Crane Lamp** is 2 pixels at (96, 79) and (97, 79) and blinks (section 6).
5. **Near towers** (Near Block, solid, Block Edge top row, four lit windows each, one of them Window Warm) at (0, 22, 196), (26, 40, 210), (72, 18, 190), (96, 44, 216), (148, 30, 198), (186, 38, 206).

The whole background is darker than the darkest thing that moves in front of it (the ape's fur edge and the barrels' edge tone are the nearest, and both are outlined by lighter tones).

## 3. Sprites

Body boxes: the hero's body is the 12 x 16 inside the 1 pixel Ink outline (picture columns 1 to 12, the 16 rows above the origin); the barrel is the full 12 x 12 (a circle of radius 6 for hits, centre at origin + (0, -6)); the fireball is the full 10 x 10. Nothing else is hit.

### 3.1 The hero

One legend for every hero frame: `1`-`5` Vest, `A` Hat, `B` Hat Shade (brim and the hammer head), `C` Skin, `D` Skin Shade, `E` Trousers Light, `F` Trousers, `G` Reflect, `H` Ink (outline, eyes), `I` Handle Dark (boots and the hammer handle). 14 colours. The outline is not drawn under the feet (the girder is there). Mirror for facing left.

#### hero_stand (14 x 17, origin (7, 17))

Standing. Origin (7, 17): the middle of the feet; the picture's last row sits on the surface row.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
.HF3GGGGGG3FH.
.HF33333333FH.
.HC4GGGGGG4CH.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHIIIIH.
```

#### hero_blink (14 x 17, origin (7, 17))

Idle blink: 120 ms every 3 s while standing still.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCCCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
.HF3GGGGGG3FH.
.HF33333333FH.
.HC4GGGGGG4CH.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHIIIIH.
```

#### hero_walk_1 (14 x 17, origin (7, 17))

Walk 1 of 4 (stride).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311HH.
.HF3GGGGGG3FCH
HF533333334HH.
HCH4GGGGGG4H..
.HHEEEEEEEEH..
.HEFFHHHHFFEH.
.HFFH....HFFFH
HIIH......HIIH
```

#### hero_walk_2 (14 x 17, origin (7, 17))

Walk 2 of 4 (passing, the body 1 pixel lower).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..............
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
..HF3GGGGG4H..
..HF3333334H..
..HC4GGGGG5H..
...HEEEEEEH...
....HFFFFH....
....HIIIIIH...
```

#### hero_walk_3 (14 x 17, origin (7, 17))

Walk 3 of 4 (stride, the other leg).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
.HH11333311H..
HCF3GGGGGG3FH.
.HH433333335FH
..H4GGGGGG4HCH
..HEEEEEEEEHH.
..HFFFHHFFFH..
.HFFFH..HFFH..
.HIIH...HIIIH.
```

#### hero_climb_1 (14 x 17, origin (7, 17))

Climb A, seen from behind. Alternates with climb B every 8 pixels climbed.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..H..HHHH.....
.HCHHAAAAH....
.HFHAAAAAAH...
.HFAAAAAAAAH..
.HFAAAAAAAACH.
.H3BBBBBBBBFH.
.H333333333FH.
.H4GGGGGGGG3H.
.H4333333334H.
.H4GGGGGGGG4H.
.H5333333335H.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHFFFH..
...HHH.HFFFH..
.......HIIIH..
```

#### hero_climb_2 (14 x 17, origin (7, 17))

Climb B.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH..H..
....HAAAAHHCH.
...HAAAAAAHFH.
..HAAAAAAAAFH.
.HCAAAAAAAAFH.
.HFBBBBBBBB3H.
.HF333333333H.
.H3GGGGGGGG4H.
.H4333333334H.
.H4GGGGGGGG4H.
.H5333333335H.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HFFFHHIIIH..
..HFFFH.HHH...
..HIIIH.......
```

#### hero_climb_top (14 x 17, origin (7, 17))

Climbing onto the girder (the last 8 pixels of a ladder, and the first 8 going down).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..............
..............
..............
..............
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
..HAAAAAAAAH..
.HBBBBBBBBBBH.
.HC23333332CH.
.HF3GGGGGG3FH.
.HF43333334FH.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHIIIH..
...HHH..HHH...
```

#### hero_jump (14 x 17, origin (7, 17))

Jump, rising (and the first half of the arc).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
.H.HDCCCCDCHH.
HCHHDDDDDDHHCH
HFHHHDDDDHHHFH
.HF11333311FH.
..H4GGGGGG4H..
..H43333334H..
..H4GGGGGG4H..
..HEEEEEEEEH..
.HEFFHHHHFFEH.
.HIIFH..HFIIH.
..HHH....HHH..
```

#### hero_fall (14 x 17, origin (7, 17))

Jump, falling (the second half), arms up.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..H..HHHH..H..
.HCHHAAAAHHCH.
.HFHAAAAAAHFH.
.HFHAAAAAAAFH.
.HFBBBBBBBBBBH
..H5DCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
..H4GGGGGG4H..
..H43333334H..
..H4GGGGGG4H..
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHIIIH..
```

#### hero_hammer_up (18 x 21, origin (7, 21))

Hammer up: walking with the hammer, frame A. Picture 18 x 21 with its outline.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.......HHHHHH.....
......HBBBBBBH....
......HBBBBBBH....
......HBBBBBBH....
.....HHHHIIHH.....
....HAAAAIIH......
...HAAAAAAIIH.....
...HAAAAAAICH.....
..HBBBBBBBBBBH....
...HDCCCHCHFH.....
...HDCCCCDCFH.....
...HDDDDDDHFH.....
...HHDDDDHHFH.....
..H11333311FH.....
.HF3GGGGGG4H......
.HF33333334H......
.HC4GGGGGG4H......
..HEEEEEEEEH......
..HFFFHHFFFH......
..HFFFHHFFFH......
..HIIIHHIIIIH.....
```

#### hero_hammer_down (20 x 21, origin (7, 21))

Hammer down: frame B.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
....................
....................
....................
....................
.....HHHH...........
....HAAAAH..........
...HAAAAAAH.........
...HAAAAAAAHH.......
..HBBBBBBBBBBH......
...HDCCCHCHHH.......
...HDCCCCDCH........
...HDDDDDDH.....HHH.
...HHDDDDHHH...HBBBH
..H11333311FHHHHBBBH
.HF3GGGGGG3FCIIIBBBH
.HF33333334HHHHHBBBH
.HC4GGGGGG4H...HBBBH
..HEEEEEEEEH....HHH.
..HFFFHHFFFH........
..HFFFHHFFFH........
..HIIIHHIIIIH.......
```

#### hero_win_1 (14 x 17, origin (7, 17))

Winning A: a jump with both arms up (drawn 3 pixels higher than the feet).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..H..HHHH..H..
.HCHHAAAAHHCH.
.HFHAAAAAAHFH.
.HFHAAAAAAAFH.
.HFBBBBBBBBBBH
..H5DCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
..H4GGGGGG4H..
..H43333334H..
..H4GGGGGG4H..
..HEEEEEEEEH..
.HEFFHHHHFFEH.
.HIIFH..HFIIH.
..HHH....HHH..
```

#### hero_win_2 (14 x 17, origin (7, 17))

Winning B: a wave, on the girder. Alternate A and B every 250 ms.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
...........H..
.....HHHH.HCH.
....HAAAAHHFH.
...HAAAAAAHFH.
...HAAAAAAAFH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
.HF3GGGGGG4H..
.HF33333334H..
.HC4GGGGGG4H..
..HEEEEEEEEH..
..HFFFHHFFFH..
..HIIIHHIIIIH.
```

#### hat_fly (12 x 6, origin (6, 3))

The hat, flying off when the hero is hit (a particle, see the recipes). Origin (6, 3): its middle.

Legend: `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `H` Ink `0A0D17`.

```
....HHHH....
...HAAAAH...
..HAAAAAAH..
..HAAAAAAAH.
.HBBBBBBBBBH
..HHHHHHHHH.
```

#### hero_hit_1 (14 x 17, origin (7, 17))

Hit 1: the standing frame drawn in Flash white (all colours replaced) for 100 ms.

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
...HAAAAAAAHH.
..HBBBBBBBBBBH
...HDCCCHCHHH.
...HDCCCCDCH..
...HDDDDDDH...
...HHDDDDHH...
..H11333311H..
.HF3GGGGGG3FH.
.HF33333333FH.
.HC4GGGGGG4CH.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
..HIIIHHIIIIH.
```

#### hero_hit_2 (14 x 17, origin (7, 17))

Hit 2: turned to face the other way (a spin).

Legend: `1`-`5` tones of **Vest**, `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
.....HHHH.....
....HAAAAH....
...HAAAAAAH...
.HHAAAAAAAH...
HBBBBBBBBBBH..
.HHHCHCCCDH...
.HCCDCCCCDH...
..HHDDDDDDH...
...HHDDDDHH...
..H11333311H..
.HF3GGGGGG3FH.
.HF33333333FH.
.HC4GGGGGG4CH.
..HEEEEEEEEH..
..HFFFHHFFFH..
..HFFFHHFFFH..
.HIIIIHHIIIH..
```

#### hero_hit_3 (14 x 17, origin (7, 17))

Hit 3: knocked back, hat gone (the hat flies off as a particle, see the recipes).

Legend: `1`-`5` tones of **Vest**, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..............
..............
..............
..............
.....HHHH.....
....HCCCCHH...
..HHDCCCCCHH..
.HFHDDDDDDCCH.
.HFHDDDDDDHH..
.HCHHDDDDHH...
..H11333311H..
.HF3GGGGGG3FH.
.HF33333333FCH
..H4GGGGGG4HH.
..HEEEEEEEEH..
..HFFFHHFFFH..
.HIIIH..HIIIH.
```

#### hero_hit_4 (14 x 17, origin (7, 17))

Hit 4: knees giving way.

Legend: `1`-`5` tones of **Vest**, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..............
..............
..............
..............
..............
.....HHHH.....
....HCCCCHH...
...HDCCCCCHH..
...HDDDDDDCH..
...HDDDDDDH...
..HHHDDDDHHH..
.HF11333311FH.
.HC3GGGGGG3CH.
..H43333334H..
.HEEEEEEEEEEH.
HEFFHHHHHHFFEH
HIIH......HIIH
```

#### hero_hit_5 (18 x 17, origin (9, 17))

Hit 5: lying on the girder, 16 x 4 (it overhangs the 12 wide body by 2 each side; nothing collides with it). Held until the life ends.

Legend: `1`-`5` tones of **Vest**, `C` Skin `EDB48A`, `D` Skin Shade `B97A55`, `E` Trousers Light `4A5E98`, `F` Trousers `2D3E6E`, `G` Reflect `E8F2FF`, `H` Ink `0A0D17`, `I` Handle Dark `7E5230`.

```
..................
..................
..................
..................
..................
..................
..................
..................
..................
..................
..................
..................
..HHH..........HH.
.HCCCHHHHHHHHHHIIH
HCDCDC1G11G1EEEFIH
HDDDD23G33G3FFFFFH
.HCDH5555555FFFHH.
```

**Hammer hit boxes** (relative to the origin, facing right; mirror x for left): hammer up, the head is x 0 to +5, y -20 to -18 (it hits things above the hero, such as a barrel dropping from the girder above); hammer down, the head is x +9 to +11, y -9 to -5 (in front, at knee height, where rolling barrels are). Either frame smashes anything that touches the head **or** the hero's body while the hammer is held.

### 3.2 The ape

Seen from the front, so never mirrored. 46 x 40, origin (23, 40): the middle of its feet on `top` at (50, 64). Legend for every ape frame: `1`-`5` Fur, `A` Face, `B` Muzzle, `C` Eye White, `D` Pupil, `E` Helmet, `F` Helmet Light, `G` Tape, `H` Tape Dark, `I` Angry. The two frames that hold a barrel add `J`, `K`, `L` (Wood tones 2, 3 and 4) and draw the barrel's iron with `H` and its shine with `B`, to stay at 16 colours.

#### ape_idle_1 (46 x 40, origin (23, 40))

Idle A: knuckles on the platform. Alternates with idle B every 400 ms.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
....................FFFFFF....................
...................FFFFFFFF...................
..................FFEEEEEEFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............1244333333334421...............
...............32AACCAAAACCAA23...............
...............33AACDAAAADCAA33...............
............11133AAAAAAAAAAAA33111............
..........1122233AABBBBBBBBAA3322211..........
......111122222332ABBDBBDBBA233222221111......
.....12222222233432BBBBBBBB23433222222221.....
....122222222234433BBDDDDBB334432222222221....
....32222222224444433222233444442222222223....
...12222333233444AAAA4444AAAA44433233322221...
...322223333334AAAAAAAAAAAAAAAA433333322223...
...32222333333AAAAAAAAAAAAAAAAAA33333322223...
..122333333333AAAAAAAAAAAAAAAAAA333333333221..
..323333333333AAAAAAAAAAAAAAAAAA333333333323..
.1223333443333AAAAAAAAAAAAAAAAAA3333443333221.
.32333334443332AAAAAAAAAAAAAAAA23334443333323.
.3233333444444222AAAAAAAAAAAA2224444443333323.
12333333444444322AAAAAAAAAAAA22344444433333321
32333333554444333AAAAAAAAAAAA33344445533333323
43333334..4444333AAAAAAAAAAAA3334444..43333334
43334444..5444444AAAAAAAAAAAA4444445..44443334
43344444...4444443AAAAAAAAAA3444444...44444334
43344444...GHHGGHHGGHHGGHHGGHHGGHHG...44444334
534444441..HHGGHHGGHHGGHHGGHHGGHHGG..144444435
.44444443.12222222222222222222222221.34444444.
.44444444.42222222222355322222222224.44444444.
.44444444.433333333334..433333333334.44444444.
.44AAAA44.533333333335..533333333335.44AAAA44.
.4AAAAAA4..4433333344....4433333344..4AAAAAA4.
.5AAAAAA5..5544444455....5544444455..5AAAAAA5.
..5AAAA5.....444444........444444.....5AAAA5..
...5555....AAAAAAAAAA.....AAAAAAAAAA...5555...
```

#### ape_idle_2 (46 x 40, origin (23, 40))

Idle B: breathing in, the head and shoulders 1 pixel higher.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
...................FFFFFFFF...................
..................FFFFFFFFFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............1244333333334421...............
...............32AACCAAAACCAA23...............
...............33AACDAAAADCAA33...............
............11133AAAAAAAAAAAA33111............
..........1122233AABBBBBBBBAA3322211..........
......111122222332ABBDBBDBBA233222221111......
.....12222222233432BBBBBBBB23433222222221.....
....122222222234433BBDDDDBB334432222222221....
....32222222224444433222233444442222222223....
...12222333233444AAAA4444AAAA44433233322221...
...322223333334AAAAAAAAAAAAAAAA433333322223...
...32222333333AAAAAAAAAAAAAAAAAA33333322223...
..122233333333AAAAAAAAAAAAAAAAAA333333332221..
..323333333333AAAAAAAAAAAAAAAAAA333333333323..
.1223333443333AAAAAAAAAAAAAAAAAA3333443333221.
.32333334443332AAAAAAAAAAAAAAAA23334443333323.
.3233333444444222AAAAAAAAAAAA2224444443333323.
12333333444444322AAAAAAAAAAAA22344444433333321
32333333554444333AAAAAAAAAAAA33344445533333323
43333334..4444333AAAAAAAAAAAA3334444..43333334
43333344..5444444AAAAAAAAAAAA4444445..44333334
43334444...5444443AAAAAAAAAA3444445...44443334
43344444....GHHGGHHGGHHGGHHGGHHGGH....44444334
53444444...GHHGGHHGGHHGGHHGGHHGGHHG...44444435
.44444441..322222222222222222222223..14444444.
.44444443.12222222222255222222222221.34444444.
.44444444.433222222334..433222222334.44444444.
.44444444.433333333334..433333333334.44444444.
.44AAAA44.533333333335..533333333335.44AAAA44.
.4AAAAAA4..4444444444....4444444444..4AAAAAA4.
.5AAAAAA5..5544444455....5544444455..5AAAAAA5.
..5AAAA5.....444444........444444.....5AAAA5..
...5555....AAAAAAAAAA.....AAAAAAAAAA...5555...
```

#### ape_grab_1 (46 x 40, origin (23, 40))

Grab A: turns to the stack on its right hand side (screen left), arm reaching out.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
..................FFFFFF......................
.................FFFFFFFF.....................
................FFEEEEEEFF....................
................EEEEEEEEEE....................
................4EEEEEEEE4....................
...............EEEEEEEEEEEE...................
..............12233333333221..................
..............333AAAAAAAA333..................
.............1244333333334421.................
.............32AACCAAAACCAA33.................
.............33AADCAAAADCAA33.................
............123AAAAAAAAAAAA3311111............
..........11223AABBBBBBBBAA332222211..........
......1111222232ABBDBBDBBA24333222221111......
.....122222222322BBBBBBBB2344333222222221.....
....1222222223433BBDDDDBB33443332222222221....
...122332222234433333222244444442222222223....
..122233333233444AAAA4444AAAA44433233322221...
.12223333333334AAAAAAAAAAAAAAAA433333322223...
12233333333333AAAAAAAAAAAAAAAAAA33333322223...
32333344333333AAAAAAAAAAAAAAAAAA333333333221..
43333344433333AAAAAAAAAAAAAAAAAA333333333323..
43333445443333AAAAAAAAAAAAAAAAAA3333443333221.
4444345.4443342AAAAAAAAAAAAAAAA23334443333323.
444444..544444222AAAAAAAAAAAA2224444443333323.
444445...44444322AAAAAAAAAAAA22344444433333321
AAAA4....54444333AAAAAAAAAAAA33344445533333323
AAAA5.....4444333AAAAAAAAAAAA3334444..43333334
AAAA......5444444AAAAAAAAAAAA4444445..44443334
AAAA.......4444443AAAAAAAAAA3444444...44444334
...........GHHGGHHGGHHGGHHGGHHGGHHG...44444334
...........HHGGHHGGHHGGHHGGHHGGHHGG..144444435
..........12222222222222222222222221.34444444.
..........42222222222355322222222224.44444444.
..........433333333334..433333333334.44444444.
..........533333333335..533333333335.44AAAA44.
...........4433333344....4433333344..4AAAAAA4.
...........5544444455....5544444455..5AAAAAA5.
.............444444........444444.....5AAAA5..
...........AAAAAAAAAA.....AAAAAAAAAA...5555...
```

#### ape_grab_2 (46 x 40, origin (23, 40))

Grab B: the barrel lifted to its chest with both hands (the barrel is part of this picture).

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`, `J` Wood tone 2 `CB936B`, `K` Wood tone 3 `B5652C`, `L` Wood tone 4 `7D4723`.

```
....................FFFFFF....................
...................FFFFFFFF...................
..................FFEEEEEEFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............1244333333334421...............
...............32AACCAAAACCAA23...............
...............33AACDAAAADCAA33...............
............11133AAAAAAAAAAAA33111............
..........1122233AABBBBBBBBAA3322211..........
......111122222332ABBDBBDBBA233222221111......
.....12222222233432BBBBBBBB23433222222221.....
....122222222334433BBDDDDBB334433222222221....
....32222222234444433222233444443222222223....
....3222223233444AAAA4444AAAA4443323222223....
....43333333334AAAAAAAAAAAAAAAA43333333334....
....4333333333AAAAAAABBBBAAAAAAA3333333334....
....4333333334AAAAABBBBBBBBAAAAA4333333334....
....4333333334AAAABBJLHHLJBBAAAA4333333334....
....433333333422AAHJJLJJLJJHAA224333333334....
....4444434334443HHKKLKKLKKHH3444334344444....
....444444444AAAAHKKKLKKLKKKHAAAA444444444....
....544444444AAAAHKKKLKKLKKKHAAAA444444445....
.....54444444AAAAHHLLLLLLLLHHAAAA44444445.....
......5554444AAAA4HLLLLLLLLH4AAAA4444555......
.........55442222AHHLLLLLLHHA22224455.........
...........4444443AHHHLLHHHA3444444...........
...........GHHGGHHGGHHHHHHGGHHGGHHG...........
...........HHGGHHGGHHGGHHGGHHGGHHGG...........
..........12222222222222222222222221..........
..........42222222222355322222222224..........
..........433333333334..433333333334..........
..........533333333335..533333333335..........
...........4433333344....4433333344...........
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_throw_1 (46 x 40, origin (23, 40))

Throw A: the barrel swung out to the right at waist height (still part of the picture).

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`, `J` Wood tone 2 `CB936B`, `K` Wood tone 3 `B5652C`, `L` Wood tone 4 `7D4723`.

```
....................FFFFFF....................
...................FFFFFFFF...................
..................FFEEEEEEFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............1244333333334421...............
...............33AACCAAAACCAA23...............
...............33AACDAAAADCAA33...............
...........111133AAAAAAAAAAAA3311.............
.........11222233AABBBBBBBBAA332211...........
......111222223342ABBDBBDBBA23322221111.......
.....12222222333432BBBBBBBB2243222222221......
....122222222334433BBDDDDBB33442222222221.....
....3222222224444443222233344442222222223.....
....322223233444AAAA4444AAAA44432222222221....
...12222233334AAAAAAAAAAAAAAAA432222222223....
...3222223333AAAAAAAAAAAAAAAAAA33232222223....
...3233333333AAAAAAAAAAAAAAAAAA333333332221...
..12333333333AAAAAAAAAAAAAAAAAA333333333323...
..32333333333AAAAAAAAAAAAAAAAAA3333333333221..
..323333343332AAAAAAAAAAAAAAAA23333333333324..
..33333334444222AAAAAAAAAAAA2224333333333324..
.123333334444322AAAAAAAAAAAA22343333BBBB3335..
.333333334444333AAAAAAAAAAAA333433BBBBBBBB4...
.433333334444333AAAAAAAAAAAA33343BBJLHHLJBB...
.433444445444444AAAAAAAAAAAA44443HJJLJJLJJH...
.43344444.4444443AAAAAAAAAA34444HHKKLKKLKKHH..
.43444444.GGHHGGHHGGHHGGHHGGHHGGHKKKLKKLKKKH..
.534444441GHHGGHHGGHHGGHHGGHHGGHHKKKLKKLKKKH..
..444444422222222222222222222222HHLLLLLLLLHH..
..4444444322222222223553222222224HLLLLLLLLH...
..4444444333333333334..4333333334HHLLLLLLHH...
..44AAAA4333333333335..53333333344HHHLLHHH....
..4AAAAAA44433333344....4433333344..HHHH......
..5AAAAAA55544444455....5544444455............
...5AAAA5...444444........444444..............
....5555..AAAAAAAAAA.....AAAAAAAAAA...........
```

#### ape_throw_2 (46 x 40, origin (23, 40))

Throw B: the barrel is released. The game creates the rolling barrel with its centre at the ape origin + (19, -6), moving right.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
.....................FFFFFF...................
....................FFFFFFFF..................
...................FFEEEEEEFF.................
...................EEEEEEEEEE.................
...................4EEEEEEEE4.................
..................EEEEEEEEEEEE................
.................12233333333221...............
.................333AAAAAAAA333...............
................1244333333334421..............
................33AACCAAAACCAA23..............
................33AACDAAAADCAA33..............
...........1111133AAAAAAAAAAAA321.............
.........112222233AABBBBBBBBAA32211...........
......1112222233342ABBDBBDBBA2322221111.......
.....122222223334432BBBBBBBB223222222221......
....1222222223334433BBDDDDBB3343222222221.....
....3222222224444444222233333443222222223.....
....322223233444AAAA4444AAAA44433233332221....
...12222233334AAAAAAAAAAAAAAAA433333333223....
...3222223333AAAAAAAAAAAAAAAAAA333333332221...
...3233333333AAAAAAAAAAAAAAAAAA3333333332221..
..12333333333AAAAAAAAAAAAAAAAAA3333343333223..
..32333333333AAAAAAAAAAAAAAAAAA33334443333221.
..323333343332AAAAAAAAAAAAAAAA243344443333323.
..33333334444222AAAAAAAAAAAA222444445443333321
.123333334444322AAAAAAAAAAAA22344444.543333333
.333333334444333AAAAAAAAAAAA33344445..43333333
.433333334444333AAAAAAAAAAAA3334444...43333333
.433444445444444AAAAAAAAAAAA4444445...44344334
.43344444.4444443AAAAAAAAAA3444444....54444444
.43444444.GGHHGGHHGGHHGGHHGGHHGGHH.....4444444
.534444441GHHGGHHGGHHGGHHGGHHGGHHG.....4444444
..444444422222222222222222222222221....4444444
..444444432222222222355322222222224....44AAAA4
..4444444333333333334..433333333334....54AAAA4
..44AAAA4333333333335..533333333335.....5AAAA5
..4AAAAAA44433333344....4433333344.......AAAA.
..5AAAAAA55544444455....5544444455............
...5AAAA5...444444........444444..............
....5555..AAAAAAAAAA.....AAAAAAAAAA...........
```

#### ape_pound_1 (46 x 40, origin (23, 40))

Pound A: both fists raised to shoulder height.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
....................FFFFFF....................
....AAAA...........FFFFFFFF...........AAAA....
...AAAAAA.........FFEEEEEEFF.........AAAAAA...
..1AAAAAA1........EEEEEEEEEE........1AAAAAA1..
..3AAAAAA4........4EEEEEEEE4........4AAAAAA3..
.12AAAAAA4.......EEEEEEEEEEEE.......4AAAAAA21.
.322AAAA25......12233333333221......52AAAA223.
.33222224.......333AAAAAAAA333.......42222233.
133222225......1244333333334421......522222331
33322223.......32AACCAAAACCAA23.......32222333
43332223.......33AACDAAAADCAA33.......32223334
43333334....11133AAAAAAAAAAAA33111....43333334
444333331.1122233AABBBBBBBBAA3322211.133333444
444333332122222332ABBDBBDBBA233222221233333444
5444333322222233432BBBBBBBB2343322222233334445
.544433322222234433BCCCCCCB334432222223334445.
..544444322222444443ADDDDA344444222223444445..
...54444333233444AAAA3333AAAA44433233344445...
....54443333334AAAAAAAAAAAAAAAA43333334445....
.....544333333AAAAAAAAAAAAAAAAAA333333445.....
......55333333AAAAAAAAAAAAAAAAAA33333355......
........433333AAAAAAAAAAAAAAAAAA333334........
........443333AAAAAAAAAAAAAAAAAA333344........
........4443332AAAAAAAAAAAAAAAA2333444........
........544444222AAAAAAAAAAAA222444445........
.........44444322AAAAAAAAAAAA22344444.........
.........54444333AAAAAAAAAAAA33344445.........
..........4444333AAAAAAAAAAAA3334444..........
..........5444444AAAAAAAAAAAA4444445..........
...........4444443AAAAAAAAAA3444444...........
...........GHHGGHHGGHHGGHHGGHHGGHHG...........
...........HHGGHHGGHHGGHHGGHHGGHHGG...........
..........12222222222222222222222221..........
..........42222222222355322222222224..........
..........433333333334..433333333334..........
..........533333333335..533333333335..........
...........4433333344....4433333344...........
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_pound_2 (46 x 40, origin (23, 40))

Pound B: fists on the chest (alternate A and B every 150 ms, four times).

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
....................FFFFFF....................
...................FFFFFFFF...................
..................FFEEEEEEFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............1244333333334421...............
...............32AACCAAAACCAA23...............
...............33AACDAAAADCAA33...............
............11133AAAAAAAAAAAA33111............
..........1122233AABBBBBBBBAA3322211..........
......111122222332ABBDBBDBBA233222221111......
.....12222222233432BBBBBBBB23433222222221.....
....122222222234433BCCCCCCB334432222222221....
....3222222222444443ADDDDA3444442222222223....
....3222333233444AAAA3333AAAA4443323332223....
...123333333334AAAAAAAAAAAAAAAA433333333321...
...33333333333AAAAAAAAAAAAAAAAAA33333333333...
...33333333333AAAAAAAAAAAAAAAAAA33333333333...
...43333333333AAAAAAAAAAAAAAAAAA33333333334...
..133333443333AAAAAAAAAAAAAAAAAA333344333331..
..4334444443332AAAAAAAAAAAAAAAA2333444444334..
..444444444444222AAAAAAAAAAAA222444444444444..
..544444444444322AAAAAAAAAAAA223444444444445..
...54444554444333AAAAAAAAAAAA33344445544445...
....5555..4444333AAAAAAAAAAAA3334444..5555....
..........5444444AAAAAAAAAAAA4444445..........
...........4444443AAAAAAAAAA3444444...........
...........GHHGGHHGGHHGGHHGGHHGGHHG...........
...........HHGGHHGGHHGGHHGGHHGGHHGG...........
..........12222222222222222222222221..........
..........42222222222355322222222224..........
..........433333333334..433333333334..........
..........533333333335..533333333335..........
...........4433333344....4433333344...........
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_angry (46 x 40, origin (23, 40))

Angry: looking at the hero, teeth bared, red glints in its eyes. Shown when the hero climbs above girder 4.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `C` Eye White `F2EEE4`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`, `I` Angry `E2412A`.

```
....................FFFFFF....................
...................FFFFFFFF...................
..................FFEEEEEEFF..................
..................EEEEEEEEEE..................
..................4EEEEEEEE4..................
.................EEEEEEEEEEEE.................
................12233333333221................
................333AAAAAAAA333................
...............12443A3333A34421...............
...............32AACDAAAADCAA23...............
...............33AACIAAAAICAA33...............
............11133AAAAAAAAAAAA33111............
..........1122233AABBBBBBBBAA3322211..........
......111122222332ABBDBBDBBA233222221111......
.....12222222233432BBBBBBBB23433222222221.....
....122222222234433BCCCCCCB334432222222221....
....3222222222444443ADDDDA3444442222222223....
...12222333233444AAAA3333AAAA44433233322221...
...322223333334AAAAAAAAAAAAAAAA433333322223...
...32222333333AAAAAAAAAAAAAAAAAA33333322223...
..122333333333AAAAAAAAAAAAAAAAAA333333333221..
..323333333333AAAAAAAAAAAAAAAAAA333333333323..
.1223333443333AAAAAAAAAAAAAAAAAA3333443333221.
.32333334443332AAAAAAAAAAAAAAAA23334443333323.
.3233333444444222AAAAAAAAAAAA2224444443333323.
12333333444444322AAAAAAAAAAAA22344444433333321
32333333554444333AAAAAAAAAAAA33344445533333323
43333334..4444333AAAAAAAAAAAA3334444..43333334
43334444..5444444AAAAAAAAAAAA4444445..44443334
43344444...4444443AAAAAAAAAA3444444...44444334
43344444...GHHGGHHGGHHGGHHGGHHGGHHG...44444334
534444441..HHGGHHGGHHGGHHGGHHGGHHGG..144444435
.44444443.12222222222222222222222221.34444444.
.44444444.42222222222355322222222224.44444444.
.44444444.433333333334..433333333334.44444444.
.44AAAA44.533333333335..533333333335.44AAAA44.
.4AAAAAA4..4433333344....4433333344..4AAAAAA4.
.5AAAAAA5..5544444455....5544444455..5AAAAAA5.
..5AAAA5.....444444........444444.....5AAAA5..
...5555....AAAAAAAAAA.....AAAAAAAAAA...5555...
```

#### ape_defeated_1 (46 x 40, origin (23, 40))

Defeated A: dazed, hands on its head, eyes shut, the helmet knocked sideways.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
...........11AAAA............AAAA11...........
.........112AAAAAA..........AAAAAA411.........
........1222AAAAAA..........AAAAAAFFFFFF......
......112223AAAAAA...1111...AAAAAFFFFFFFF.....
.....1222333AAAAAA.11222211.AAAAAEEEEEEEE.....
...1122223332AAAA.1333333331.AAAA3EEEEEE311...
..12222223333225.123344443321.52EEEEEEEEEE21..
.12222222344355.13344444444331.55222222222221.
1222222224445...334AAAAAAAA433...5333222222221
433333333455...1244333333334421...553222223334
4333333335.....33AAAAAAAAAAAA33.....5222223334
533333334...11123AADDAAAADDAA32111...333333335
.4433333311122233AAAAAAAAAAAA3322211123333344.
.5443333322222233AABBBBBBBBAA3322222233333445.
..5443333222223342ABBDBBDBBA2433222223333345..
...4444432222234432BBBBBBBB2344322222333344...
...5444432222244444BBDDDDBB4444422222344445...
....4444433233444AAA333333AAA4443323334444....
....54444333334AAAAAAAAAAAAAAAA43333334445....
.....544433333AAAAAAAAAAAAAAAAAA333334445.....
......55433333AAAAAAAAAAAAAAAAAA33333455......
........433333AAAAAAAAAAAAAAAAAA333334........
........443333AAAAAAAAAAAAAAAAAA333344........
........4443332AAAAAAAAAAAAAAAA2333444........
........544444222AAAAAAAAAAAA222444445........
.........44444322AAAAAAAAAAAA22344444.........
.........54444333AAAAAAAAAAAA33344445.........
..........4444333AAAAAAAAAAAA3334444..........
..........5444444AAAAAAAAAAAA4444445..........
...........4444443AAAAAAAAAA3444444...........
...........GHHGGHHGGHHGGHHGGHHGGHHG...........
...........HHGGHHGGHHGGHHGGHHGGHHGG...........
..........12222222222222222222222221..........
..........42222222222355322222222224..........
..........433333333334..433333333334..........
..........533333333335..533333333335..........
...........4433333344....4433333344...........
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_climb_1 (46 x 40, origin (23, 40))

Climb A (the intro), seen from behind: left arm up, right arm down. The captive rides on its right shoulder: draw captive_help_1 or 2 with its origin at the ape origin + (12, -30). Alternate A and B every 8 pixels climbed.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
....11111111........FFFFFF....................
....32222224.......FFFFFFFF...................
....32222235......FFEEEEEEFF..................
...12222224.......EEEEEEEEEE..................
...32222224.......4EEEEEEEE4..................
...32222224......EEEEEEEEEEEE.................
...33333225.....12222222222221................
..13333323......32222222222223................
..43333334.....1222222222222221...............
..43333334.....3222222222222223...............
..53333334.....3222222222222223...............
...43333331.1112222222222222222111............
...433333321222222222222222222222211..........
...4443333222222333333333333332222221111......
...54444332222223333333333333322222222221.....
....44443322222333333333333333322222222221....
....44443322222333333333333333322222222223....
....44444332333333333333333333333323322223....
....544444333333333333333333333333333222221...
.....54444333333333333333333333333333333223...
......55443333333333333333333333333333333321..
........443333333333333333333333333333333323..
........443333334444444444444433333343333323..
........4443333444444444444444433334433333321.
........5444444444444444444444444444433333323.
.........444444444444444444444444444433333334.
.........544444444444444444444444444544444334.
..........44444444444444444444444444.44444334.
..........54444444444444444444444445.44444435.
...........444444444444444444444444.14444444..
...........GHHGGHHGGHHGGHHGGHHGGHHG.34444444..
...........HHGGHHGGHHGGHHGGHHGGHHGG.44444444..
..........1222222222222222222222222134AAAA44..
..........422222222223553222222222234AAAAAA4..
..........433333333334..4333333333335AAAAAA5..
..........533333333335..533333333335.5AAAA5...
...........4433333344....4433333344...5555....
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_climb_2 (46 x 40, origin (23, 40))

Climb B: the other arm up.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
....................FFFFFF........11111111....
...................FFFFFFFF.......42222223....
..................FFEEEEEEFF......53222223....
..................EEEEEEEEEE.......42222221...
..................4EEEEEEEE4.......42222223...
.................EEEEEEEEEEEE......42222223...
................12222222222221.....52233333...
................32222222222223......32333331..
...............1222222222222221.....43333334..
...............3222222222222223.....43333334..
...............3222222222222223.....43333335..
............1112222222222222222111.13333334...
..........112222222222222222222222123333334...
......1111222222333333333333332222223333444...
.....12222222222333333333333332222223344445...
....12222222222333333333333333322222334444....
....32222222222333333333333333322222334444....
....32222332333333333333333333333323344444....
...122222333333333333333333333333333444445....
...32233333333333333333333333333333344445.....
..12333333333333333333333333333333334455......
..323333333333333333333333333333333344........
..323333343333334444444444444433333344........
.1233333344333344444444444444443333444........
.3233333344444444444444444444444444445........
.433333334444444444444444444444444444.........
.433444445444444444444444444444444445.........
.43344444.44444444444444444444444444..........
.53444444.54444444444444444444444445..........
..44444441.444444444444444444444444...........
..44444443.GHHGGHHGGHHGGHHGGHHGGHHG...........
..44444444.HHGGHHGGHHGGHHGGHHGGHHGG...........
..44AAAA4312222222222222222222222221..........
..4AAAAAA432222222222355322222222224..........
..5AAAAAA5333333333334..433333333334..........
...5AAAA5.533333333335..533333333335..........
....5555...4433333344....4433333344...........
...........5544444455....5544444455...........
.............444444........444444.............
...........AAAAAAAAAA.....AAAAAAAAAA..........
```

#### ape_defeated_2 (46 x 40, origin (23, 0))

Defeated B: defeated A turned upside down (rows reversed): it tumbles off the platform and falls out of the bottom of the picture at 3 pixels a frame.

Legend: `1`-`5` tones of **Fur**, `A` Face `2B2433`, `B` Muzzle `857786`, `D` Pupil `120C10`, `E` Helmet `FF8A2A`, `F` Helmet Light `FFC48A`, `G` Tape `FFD23A`, `H` Tape Dark `1C1A22`.

```
...........AAAAAAAAAA.....AAAAAAAAAA..........
.............444444........444444.............
...........5544444455....5544444455...........
...........4433333344....4433333344...........
..........533333333335..533333333335..........
..........433333333334..433333333334..........
..........42222222222355322222222224..........
..........12222222222222222222222221..........
...........HHGGHHGGHHGGHHGGHHGGHHGG...........
...........GHHGGHHGGHHGGHHGGHHGGHHG...........
...........4444443AAAAAAAAAA3444444...........
..........5444444AAAAAAAAAAAA4444445..........
..........4444333AAAAAAAAAAAA3334444..........
.........54444333AAAAAAAAAAAA33344445.........
.........44444322AAAAAAAAAAAA22344444.........
........544444222AAAAAAAAAAAA222444445........
........4443332AAAAAAAAAAAAAAAA2333444........
........443333AAAAAAAAAAAAAAAAAA333344........
........433333AAAAAAAAAAAAAAAAAA333334........
......55433333AAAAAAAAAAAAAAAAAA33333455......
.....544433333AAAAAAAAAAAAAAAAAA333334445.....
....54444333334AAAAAAAAAAAAAAAA43333334445....
....4444433233444AAA333333AAA4443323334444....
...5444432222244444BBDDDDBB4444422222344445...
...4444432222234432BBBBBBBB2344322222333344...
..5443333222223342ABBDBBDBBA2433222223333345..
.5443333322222233AABBBBBBBBAA3322222233333445.
.4433333311122233AAAAAAAAAAAA3322211123333344.
533333334...11123AADDAAAADDAA32111...333333335
4333333335.....33AAAAAAAAAAAA33.....5222223334
433333333455...1244333333334421...553222223334
1222222224445...334AAAAAAAA433...5333222222221
.12222222344355.13344444444331.55222222222221.
..12222223333225.123344443321.52EEEEEEEEEE21..
...1122223332AAAA.1333333331.AAAA3EEEEEE311...
.....1222333AAAAAA.11222211.AAAAAEEEEEEEE.....
......112223AAAAAA...1111...AAAAAFFFFFFFF.....
........1222AAAAAA..........AAAAAAFFFFFF......
.........112AAAAAA..........AAAAAA411.........
...........11AAAA............AAAA11...........
```

### 3.3 Barrels, the wild barrel, the stack, the smash

#### barrel_roll_0 (12 x 12, origin (6, 12))

Rolling, frame 1 of 4, a quarter turn clockwise each (the bung goes top, right, bottom, left). Rolling right plays 0 1 2 3, rolling left 3 2 1 0. Origin (6, 12): the bottom of the circle, on the surface.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `B` Hoop Light `8E7E78`, `C` Grain `6E3A18`.

```
....BBBB....
..BBBBBBBB..
.BB2CAAC2BB.
.A22C22C22A.
AA33C33C33AA
A333C33C333A
A333C33C333A
AA44C44C44AA
.A44C44C44A.
.AA5C55C5AA.
..AAA55AAA..
....AAAA....
```

#### barrel_roll_1 (12 x 12, origin (6, 12))

Rolling, frame 2 of 4, a quarter turn clockwise each (the bung goes top, right, bottom, left). Rolling right plays 0 1 2 3, rolling left 3 2 1 0. Origin (6, 12): the bottom of the circle, on the surface.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `B` Hoop Light `8E7E78`, `C` Grain `6E3A18`.

```
....BBBB....
..BBB11BBB..
.BB211112BB.
.A22222222A.
AACCCCCCCCAA
A3333333BB3A
A3333333AA3A
AACCCCCCCCAA
.A44444444A.
.AA555555AA.
..AAA55AAA..
....AAAA....
```

#### barrel_roll_2 (12 x 12, origin (6, 12))

Rolling, frame 3 of 4, a quarter turn clockwise each (the bung goes top, right, bottom, left). Rolling right plays 0 1 2 3, rolling left 3 2 1 0. Origin (6, 12): the bottom of the circle, on the surface.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `B` Hoop Light `8E7E78`, `C` Grain `6E3A18`.

```
....BBBB....
..BBB11BBB..
.BB2C11C2BB.
.A22C22C22A.
AA33C33C33AA
A333C33C333A
A333C33C333A
AA44C44C44AA
.A44CBBC44A.
.AA5CAAC5AA.
..AAA55AAA..
....AAAA....
```

#### barrel_roll_3 (12 x 12, origin (6, 12))

Rolling, frame 4 of 4, a quarter turn clockwise each (the bung goes top, right, bottom, left). Rolling right plays 0 1 2 3, rolling left 3 2 1 0. Origin (6, 12): the bottom of the circle, on the surface.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `B` Hoop Light `8E7E78`, `C` Grain `6E3A18`.

```
....BBBB....
..BBB11BBB..
.BB211112BB.
.A22222222A.
AACCCCCCCCAA
ABB33333333A
AAA33333333A
AACCCCCCCCAA
.A44444444A.
.AA555555AA.
..AAA55AAA..
....AAAA....
```

#### barrel_fall_0 (12 x 12, origin (6, 12))

Falling A: seen from the side, lying. Alternates with B every 100 ms while it drops.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
............
..A111111A..
A2A222222A2A
A2A222222A2A
A3A333333A3A
A3A333333A3A
ACACCCCCCACA
A4A444444A4A
A4A444444A4A
ACACCCCCCACA
..A555555A..
............
```

#### barrel_fall_1 (12 x 12, origin (6, 12))

Falling B: the same barrel standing up (a quarter turn).

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
..AAAAAAAA..
..22222222..
.AAAAAAAAAA.
.43C33C33C5.
.43C33C33C5.
.43C33C33C5.
.43C33C33C5.
.44C44C44C5.
.44C44C44C5.
.AAAAAAAAAA.
..44444444..
..AAAAAAAA..
```

#### barrel_ladder_0 (12 x 12, origin (6, 12))

Going down a ladder, A: lying, seen from the front of the ladder.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
............
..A111111A..
A2A222222A2A
A2A222222A2A
A3A333333A3A
A3A333333A3A
ACACCCCCCACA
A4A444444A4A
A4A444444A4A
ACACCCCCCACA
..A555555A..
............
```

#### barrel_ladder_1 (12 x 12, origin (6, 12))

Going down a ladder, B: the stave lines moved one row (it is turning). Alternate every 80 ms.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
............
..A111111A..
A2A222222A2A
A2A222222A2A
A3A333333A3A
ACACCCCCCACA
A3A333333A3A
A4A444444A4A
ACACCCCCCACA
A4A444444A4A
..A555555A..
............
```

#### barrel_stack (24 x 24, origin (12, 24))

The stack beside the ape: four upright barrels. Origin (12, 24): the middle of its base.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
..AAAAAAAA....AAAAAAAA..
..22222222....22222222..
.AAAAAAAAAA..AAAAAAAAAA.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.44C44C44C5..44C44C44C5.
.44C44C44C5..44C44C44C5.
.AAAAAAAAAA..AAAAAAAAAA.
..44444444....44444444..
..AAAAAAAA....AAAAAAAA..
..AAAAAAAA....AAAAAAAA..
..22222222....22222222..
.AAAAAAAAAA..AAAAAAAAAA.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.44C44C44C5..44C44C44C5.
.44C44C44C5..44C44C44C5.
.AAAAAAAAAA..AAAAAAAAAA.
..44444444....44444444..
..AAAAAAAA....AAAAAAAA..
```

#### barrel_stack_taken (24 x 24, origin (12, 24))

The stack with the top right barrel gone (shown from grab A until the next throw ends).

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `C` Grain `6E3A18`.

```
..AAAAAAAA..............
..22222222..............
.AAAAAAAAAA.............
.43C33C33C5.............
.43C33C33C5.............
.43C33C33C5.............
.43C33C33C5.............
.44C44C44C5.............
.44C44C44C5.............
.AAAAAAAAAA.............
..44444444..............
..AAAAAAAA..............
..AAAAAAAA....AAAAAAAA..
..22222222....22222222..
.AAAAAAAAAA..AAAAAAAAAA.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.43C33C33C5..43C33C33C5.
.44C44C44C5..44C44C44C5.
.44C44C44C5..44C44C44C5.
.AAAAAAAAAA..AAAAAAAAAA.
..44444444....44444444..
..AAAAAAAA....AAAAAAAA..
```

#### barrel_smash_0 (12 x 12, origin (6, 12))

Smash 1: the barrel flashes white from the middle (60 ms).

Legend: `1`-`5` tones of **Wood**, `B` Hoop Light `8E7E78`, `W` Flash `FFFFFF`.

```
....BBBB....
..BBBBBBBB..
.BB11WW11BB.
.B1WWWWWW1B.
BB1WWWWWW1BB
B1WWWWWWWW1B
B1WWWWWWWW1B
BB1WWWWWW1BB
.B1WWWWWW1B.
.BB11WW11BB.
..BBB11BBB..
....BBBB....
```

#### barrel_smash_1 (12 x 12, origin (6, 12))

Smash 2: planks and hoop pieces fly out (80 ms).

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `W` Flash `FFFFFF`.

```
............
............
....A..2....
....AA22....
..22.W..AA..
...2.WWWA...
...AWWW.2...
..AA..W.22..
....22AA....
....2..A....
............
............
```

#### barrel_smash_2 (12 x 12, origin (6, 12))

Smash 3: the last pieces, further out and darker (80 ms).

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`.

```
............
....A..4....
....A..4....
............
.44......AA.
............
............
.AA......44.
............
....4..A....
....4..A....
............
```

#### wild_roll_0 (12 x 12, origin (6, 12))

Wild barrel, frame 1 of 4 (45 degrees a frame: the band has two fold symmetry, so it spins twice as fast).

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`, `C` Hoop `2E2224`.

```
....AAAA....
..AAA11AAA..
.AA211112AA.
.A22222222A.
AA33333333AA
ABBBBBBBBBBA
ABBBBBBBBBBA
CC44444444CC
.C44444444C.
.CC555555CC.
..CCC55CCC..
....CCCC....
```

#### wild_roll_1 (12 x 12, origin (6, 12))

Wild barrel, frame 2 of 4 (45 degrees a frame: the band has two fold symmetry, so it spins twice as fast).

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`, `C` Hoop `2E2224`.

```
....AAAA....
..AAA11AAA..
.AAB11112AA.
.ABBB22222A.
AA3BBB3333AA
A333BBB3333A
A3333BBB333A
CC4444BBB4CC
.C44444BBBC.
.CC55555BCC.
..CCC55CCC..
....CCCC....
```

#### wild_roll_2 (12 x 12, origin (6, 12))

Wild barrel, frame 3 of 4 (45 degrees a frame: the band has two fold symmetry, so it spins twice as fast).

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`, `C` Hoop `2E2224`.

```
....AAAA....
..AAABBAAA..
.AA21BB12AA.
.A222BB222A.
AA333BB333AA
A3333BB3333A
A3333BB3333A
CC444BB444CC
.C444BB444C.
.CC55BB55CC.
..CCCBBCCC..
....CCCC....
```

#### wild_roll_3 (12 x 12, origin (6, 12))

Wild barrel, frame 4 of 4 (45 degrees a frame: the band has two fold symmetry, so it spins twice as fast).

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`, `C` Hoop `2E2224`.

```
....AAAA....
..AAA11AAA..
.AA21111BAA.
.A22222BBBA.
AA3333BBB3AA
A3333BBB333A
A333BBB3333A
CC4BBB4444CC
.CBBB44444C.
.CCB55555CC.
..CCC55CCC..
....CCCC....
```

#### wild_fall_0 (12 x 12, origin (6, 12))

Wild barrel falling A (it falls most of the time: it drops straight through the girders).

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`.

```
............
..11BBBB11..
AA22BBBB22AA
AA22BBBB22AA
AA33BBBB33AA
AA33BBBB33AA
AA33BBBB33AA
AA44BBBB44AA
AA44BBBB44AA
AA44BBBB44AA
..55BBBB55..
............
```

#### wild_fall_1 (12 x 12, origin (6, 12))

Wild barrel falling B.

Legend: `1`-`5` tones of **Cobalt**, `A` Drum Rim `C8D2DC`, `B` Hazard `F4F6F8`.

```
..AAAAAAAA..
..AAAAAAAA..
.4222222225.
.4333333335.
.BBBBBBBBBB.
.BBBBBBBBBB.
.BBBBBBBBBB.
.BBBBBBBBBB.
.4444444445.
.4444444445.
..AAAAAAAA..
..AAAAAAAA..
```

The wild barrel does not use ladders and has no ladder frames: it drops straight through the girders, playing `wild_fall_0` and `wild_fall_1`, and only rolls (`wild_roll_*`) for the moment it bounces on a girder.

### 3.4 The oil drum and its flame

#### oil_drum (16 x 16, origin (8, 16))

The oil drum, cold. 16 x 16, origin (8, 16): the middle of its base, on the ground. The two flame marks are Flame tone 3 (letter F).

Legend: `1`-`5` tones of **Drum**, `A` Ink `0A0D17`, `F` Drum Mark `FF8A1E`, `G` Drum Band `FFD23A`, `H` Drum Band Dark `1C1A22`.

```
.AAAAAAAAAAAAAA.
A11111111111111A
A22222222222222A
A33333333333333A
A33333333333333A
AGGHHGGHHGGHHGGA
AGHHGGHHGGHHGGHA
A33333333333333A
A333FF3333FF333A
A33FFFF33FFFF33A
A333FF3333FF333A
A33333333333333A
A44444444444444A
A44444444444444A
A55555555555555A
.AAAAAAAAAAAAAA.
```

#### drum_flame_0 (16 x 10, origin (8, 10))

Drum flame 1 of 3, drawn with its bottom row on the drum's top row (origin (8, 10)). Plays 0 1 2 1, 90 ms a frame, once lit.

Legend: `1`-`5` tones of **Flame**.

```
.....1......1...
....121....12...
...12321..1231..
..1233321.12321.
..23433321233321
.234443332334332
.234444433444443
..23455444455543
..34555555555554
...4555555555554
```

#### drum_flame_1 (16 x 10, origin (8, 10))

Drum flame 2 of 3, drawn with its bottom row on the drum's top row (origin (8, 10)). Plays 0 1 2 1, 90 ms a frame, once lit.

Legend: `1`-`5` tones of **Flame**.

```
...1........1...
..121...1..121..
..1231.121.1232.
.12332.123123332
.233431233233443
.234443334344443
.234444434444443
..34554444555443
..34555555555554
...4555555555554
```

#### drum_flame_2 (16 x 10, origin (8, 10))

Drum flame 3 of 3, drawn with its bottom row on the drum's top row (origin (8, 10)). Plays 0 1 2 1, 90 ms a frame, once lit.

Legend: `1`-`5` tones of **Flame**.

```
.......1........
......121...1...
.1...12321.121..
.12..123321231..
.233.12333212331
.233432344323443
.234443444444444
..23455444455543
..34555555555554
...4555555555554
```

### 3.5 Fireball

#### fireball_0 (10 x 10, origin (5, 10))

Fireball, flicker 1 of 3 (play 0 1 2 1, 70 ms a frame). Faces right, mirrored for left. Origin (5, 10): the bottom middle, on the surface.

Legend: `1`-`5` tones of **Flame**, `A` Fire Eye `2A0A08`.

```
....4.....
...43..4..
..432.43..
.4322332..
.43211234.
432111A2A4
432111A2A4
.43222234.
..444444..
...5555...
```

#### fireball_1 (10 x 10, origin (5, 10))

Fireball, flicker 2 of 3 (play 0 1 2 1, 70 ms a frame). Faces right, mirrored for left. Origin (5, 10): the bottom middle, on the surface.

Legend: `1`-`5` tones of **Flame**, `A` Fire Eye `2A0A08`.

```
......4...
..4..43...
..34.432..
.43223324.
.43211234.
432111A2A4
432111A2A4
.43222234.
..444444..
...5555...
```

#### fireball_2 (10 x 10, origin (5, 10))

Fireball, flicker 3 of 3 (play 0 1 2 1, 70 ms a frame). Faces right, mirrored for left. Origin (5, 10): the bottom middle, on the surface.

Legend: `1`-`5` tones of **Flame**, `A` Fire Eye `2A0A08`.

```
..4.......
..34...4..
.432..434.
.4322232..
.43211234.
432111A2A4
432111A2A4
.43222234.
..444444..
...5555...
```

#### fire_smash_0 (10 x 10, origin (5, 10))

Fireball smash 1: white flash (60 ms).

Legend: `1`-`5` tones of **Flame**, `W` Flash `FFFFFF`.

```
..........
...2222...
..211112..
.21WWWW12.
.21WWWW12.
.21WWWW12.
.21WWWW12.
..211112..
...2222...
..........
```

#### fire_smash_1 (10 x 10, origin (5, 10))

Smash 2: a burst ring (80 ms).

Legend: `1`-`5` tones of **Flame**.

```
..........
..........
....2.....
...3.33...
....11....
..231132..
...3.33...
.....2....
..........
..........
```

#### fire_smash_2 (10 x 10, origin (5, 10))

Smash 3: embers, further out (80 ms).

Legend: `1`-`5` tones of **Flame**.

```
..........
...4..4...
..........
.4......4.
..........
..........
.4......4.
..........
...4..4...
..........
```

### 3.6 The captive: Rivet

Rivet is a small survey robot: a screen face with two mint eyes, an orange antenna lamp, a little chest light and tracks. 12 x 17 with its outline, origin (6, 17) on the perch. Legend: `1`-`5` Robot, `A` Screen, `B` Screen Eye, `C` Antenna, `D` Wheel, `E` Ink, `F` Ink (the antenna when it is off), `G` Antenna (the chest light).

#### captive_idle_1 (12 x 17, origin (6, 17))

Rivet, idle A: antenna lamp lit. Alternates with idle B every 500 ms.

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `C` Antenna `FF8A2A`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
......E.....
.....ECE....
...EEEDEE...
..E111311E..
.E1AAAAAA1E.
.E4ABBABA4E.
.E4ABBABA4E.
.E5AAAAAA5E.
..E523325E..
..EE3DD3EE..
.ED133331DE.
.ED33GG33DE.
.ED342243DE.
..E444444E..
.EDDDDDDDDE.
EDFDFDFDFDDE
.EDDDDDDDDE.
```

#### captive_help_1 (12 x 17, origin (6, 17))

Calling for help A: left arm up. Alternate with help B every 160 ms, for 1.6 s every 4 s, with the HELP bubble.

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `C` Antenna `FF8A2A`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
.E....E.....
EDE..ECE....
EDEEEEDEE...
EDD111311E..
.E3AAAAAA1E.
.E4ABBABA4E.
.E4ABBABA4E.
.E5AAAAAA5E.
..E523325E..
...E3DD3EE..
..E133331DE.
..E43GG33DE.
..E442243DE.
..E444444E..
.EDDDDDDDDE.
EDFDFDFDFDDE
.EDDDDDDDDE.
```

#### captive_help_2 (12 x 17, origin (6, 17))

Calling for help B: right arm up.

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `C` Antenna `FF8A2A`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
......E...E.
.....ECE.EDE
...EEEDEEEDE
..E111311DDE
.E1AAAAAA3E.
.E4ABBABA4E.
.E4ABBABA4E.
.E5AAAAAA5E.
..E523325E..
..EE3DD3E...
.ED133331E..
.ED33GG34E..
.ED342244E..
..E444444E..
.EDDDDDDDDE.
EDFDFDFDFDDE
.EDDDDDDDDE.
```

#### captive_rescued_1 (12 x 17, origin (6, 17))

Rescued A: both arms up, happy eyes. Alternates with rescued B every 200 ms (a hop).

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `C` Antenna `FF8A2A`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
.E....E...E.
EDE..ECE.EDE
EDEEEEDEEEDE
EDD111311DDE
.E3AAAAAA3E.
.E4ABAABB4E.
.E4BAABBA4E.
.E5AAAAAA5E.
..E523325E..
...E3DD3E...
..E133331E..
..E43GG34E..
..E442244E..
..E444444E..
.EDDDDDDDDE.
EDFDFDFDFDDE
.EDDDDDDDDE.
```

#### captive_idle_2 (12 x 17, origin (6, 17))

Idle B: antenna lamp dark.

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
......E.....
.....EFE....
...EEEDEE...
..E111311E..
.E1AAAAAA1E.
.E4ABBABA4E.
.E4ABBABA4E.
.E5AAAAAA5E.
..E523325E..
..EE3DD3EE..
.ED133331DE.
.ED33GG33DE.
.ED342243DE.
..E444444E..
.EDDDDDDDDE.
EDFDFDFDFDDE
.EDDDDDDDDE.
```

#### captive_rescued_2 (12 x 17, origin (6, 17))

Rescued B: arms out, the tracks turned (the track pattern moves one pixel). Draw it 1 pixel higher than A: a little hop.

Legend: `1`-`5` tones of **Robot**, `A` Screen `1E3A44`, `B` Screen Eye `7CF0E0`, `C` Antenna `FF8A2A`, `D` Wheel `30384A`, `E` Ink `0A0D17`, `F` Ink `0A0D17`, `G` Antenna `FF8A2A`.

```
............
......E.....
.....ECE....
...EEEDEE...
..E111311E..
.E1AAAAAA1E.
.E4ABAABB4E.
.E4BAABBA4E.
.E5AAAAAA5E.
EDE323323EDE
.ED22DD22DE.
..E433334E..
..E43GG34E..
..E442244E..
..E444444E..
.EDDDDDDDDE.
EFDFDFDFDFDE
```

#### help_bubble (32 x 13, origin (1, 7))

HELP bubble, 32 x 13 with its Ink outline. Origin (1, 7): the tip of its tail, on the left. Shown with help A and B.

Legend: `A` Bubble `F6F8FA`, `B` Help Red `E2412A`, `C` Ink `0A0D17`.

```
.....CCCCCCCCCCCCCCCCCCCCCCCCC..
....CAAAAAAAAAAAAAAAAAAAAAAAAAC.
...CAAAAAAAAAAAAAAAAAAAAAAAAAAAC
...CAAABAAABABBBBBABAAAAABBBBAAC
...CAAABAAABABAAAAABAAAAABAAABAC
..CAAAABAAABABAAAAABAAAAABAAABAC
.CAAAAABBBBBABBBBAABAAAAABBBBAAC
CAAAAAABAAABABAAAAABAAAAABAAAAAC
.CCCAAABAAABABAAAAABAAAAABAAAAAC
...CAAABAAABABBBBBABBBBBABAAAAAC
...CAAAAAAAAAAAAAAAAAAAAAAAAAAAC
....CAAAAAAAAAAAAAAAAAAAAAAAAAC.
.....CCCCCCCCCCCCCCCCCCCCCCCCC..
```

#### heart (7 x 6, origin (3, 6))

A heart, 7 x 6, that pops up between the hero and Rivet on the rescue (see the recipes).

Legend: `A` Help Red `E2412A`.

```
.AA.AA.
AAAAAAA
AAAAAAA
.AAAAA.
..AAA..
...A...
```

### 3.7 Hammer, bonus items, sparkles

#### hammer_item (12 x 12, origin (6, 6))

The hammer power-up, 10 x 10 (12 x 12 with its outline). Origin (6, 6): its centre, which floats 14 pixels above the surface and bobs 1 pixel every 400 ms.

Legend: `1`-`5` tones of **Head**, `A` Handle `C48A4E`, `B` Handle Dark `7E5230`, `C` Ink `0A0D17`.

```
..CCCCC.....
.C11111C....
.C22222C....
.C33333C....
.C44444C....
..CC55C.....
....CABC....
.....CABC...
......CABC..
.......CABC.
........CAC.
.........C..
```

#### glint_0 (5 x 3, origin (2, 1))

Glint A, 5 x 3, at the hammer head's top left corner.

Legend: `G` Good `FFC23A`, `W` Flash `FFFFFF`.

```
..G..
.GWG.
..G..
```

#### glint_1 (5 x 5, origin (2, 2))

Glint B, 5 x 5, centred on the same point. Glint plays A, B, A for 80 ms each, every 1.2 s.

Legend: `G` Good `FFC23A`, `W` Flash `FFFFFF`.

```
..W..
..G..
WGWGW
..G..
..W..
```

#### item_tape (13 x 11, origin (6, 11))

Bonus: a tape measure (300). Origin (6, 11): bottom middle, on the surface.

Legend: `A` Tape Case `FFC23A`, `B` Handle Dark `7E5230`, `C` Ink `0A0D17`, `D` Tape Blade `EEF2F8`, `E` Tape Blade `EEF2F8`, `F` Ink `0A0D17`.

```
...FFFFFFF...
..FAAAAAAAF..
.FAABBBBBAAF.
.FABBAAABBAF.
.FABACCCABAF.
.FABACCCABAF.
.FABBAAABBAF.
.FAABBBBBAADF
..FAAAAAAADDF
...FFFFFFFFEF
..........FEF
```

#### item_lunch (12 x 11, origin (6, 11))

Bonus: a lunch box (500).

Legend: `A` Lunch `E2412A`, `B` Lunch Light `F07A62`, `C` Hat `F6F8FA`, `D` Hoop `2E2224`, `E` Hat Shade `BCC6D2`, `F` Ink `0A0D17`.

```
....FFFF....
...FEEEEF...
..FFEFFEFF..
.FAAAAAAAAF.
FBBBBBBBBBBF
FAAAAAAAAAAF
FAAAACCAAAAF
FAAAACCAAAAF
FAAAAAAAAAAF
FAAAAAAAAAAF
FDDDDDDDDDDF
```

#### item_flask (12 x 11, origin (6, 11))

Bonus: a thermos flask (800).

Legend: `A` Flask `2FA37A`, `B` Flask Light `8FE0C0`, `C` Hat `F6F8FA`, `D` Hoop `2E2224`, `E` Cup `EEF2F8`, `F` Ink `0A0D17`.

```
....FFFF....
...FEEEEF...
...FEEEEF...
...FDDDDF...
..FAAAAAAF..
..FABAAAAF..
..FABAAAAF..
..FAAAAAAF..
..FABCCAAF..
..FAACCAAF..
..FAAAAAAF..
```

#### sparkle_0 (7 x 7, origin (3, 3))

Taken sparkle 1 of 3, 7 x 7, centred on the item (70 ms a frame).

Legend: `1`-`5` tones of **Gold**.

```
.......
.......
...1...
..121..
...1...
.......
.......
```

#### sparkle_1 (7 x 7, origin (3, 3))

Taken sparkle 2 of 3, 7 x 7, centred on the item (70 ms a frame).

Legend: `1`-`5` tones of **Gold**.

```
...1...
...2...
..121..
1221221
..121..
...2...
...1...
```

#### sparkle_2 (7 x 7, origin (3, 3))

Taken sparkle 3 of 3, 7 x 7, centred on the item (70 ms a frame).

Legend: `1`-`5` tones of **Gold**.

```
...3...
.......
.3.2.3.
3.2.2.3
.3.2.3.
.......
...3...
```

### 3.8 HUD and small effects

#### lives_icon (8 x 8, origin (0, 0))

Lives icon, 8 x 8: the hero's head in its hard hat. One per spare life.

Legend: `A` Hat `F6F8FA`, `B` Hat Shade `BCC6D2`, `C` Skin `EDB48A`, `D` Ink `0A0D17`.

```
..AAAA..
.AAAAAA.
.AAAAAA.
BBBBBBBB
.CCCCCC.
.CDCCDC.
..CCCC..
........
```

#### dust_0 (8 x 4, origin (4, 4))

Dust 1 of 3, 8 x 4, centred on the feet or the barrel's lowest point (60 ms a frame).

Legend: `1`-`5` tones of **Rail**.

```
........
........
..1..1..
.121121.
```

#### dust_1 (8 x 4, origin (4, 4))

Dust 2 of 3, 8 x 4, centred on the feet or the barrel's lowest point (60 ms a frame).

Legend: `1`-`5` tones of **Rail**.

```
........
.1....1.
121..121
.2....2.
```

#### dust_2 (8 x 4, origin (4, 4))

Dust 3 of 3, 8 x 4, centred on the feet or the barrel's lowest point (60 ms a frame).

Legend: `1`-`5` tones of **Rail**.

```
1......1
.2....2.
........
3......3
```

**Score pop-ups** are text, not sprites: the value (`100`, `200`, `300`, `500`, `800`) in the 5 x 7 font at 1x, Good with a 1 pixel Outline, centred over the thing that scored. It rises 1 pixel every 50 ms for 12 pixels (600 ms), holds for 200 ms, then is drawn in Accent for 100 ms and Label for 100 ms and goes. At most 3 at once; a fourth replaces the oldest.

## 4. Animation recipes

| What | Frames | Timing | Pixels that change |
|---|---|---|---|
| Hero walk | walk_1, walk_2, walk_3, walk_2 | a new frame every 4 pixels walked (about 80 ms at the arcade pace); walk_2 is drawn as it is (it is one pixel lower inside its picture, so the hero bobs) | one 14 x 17 sprite |
| Hero stand | stand; blink for 120 ms every 3 s | | 2 pixels |
| Hero climb | climb_1, climb_2, by distance | swap every 8 pixels climbed; `hero_climb_top` for the last 8 pixels at the top and the first 8 going down | one sprite |
| Hero jump | jump while rising, fall from the top of the arc | the arc is the game's | one sprite |
| Hammer | hammer_up, hammer_down | swap every 133 ms (8 frames) while held; for the last 2 s the hammer head flashes Flash white every other swap, as the warning it is ending | an 18 x 21 or 20 x 21 sprite |
| Hero hit | hit_1 (all pixels Flash) 100, hit_2 150, hit_3 150, hit_2 150, hit_3 150, hit_4 300, hit_5 held 500 | 1.5 s, then the life ends | one sprite, plus the hat |
| Hat flies off | `hat_fly` from the hero's head at hit_3 | starts at (vx -1.2 facing right, mirrored left, vy -2.2 px a frame), gravity 0.15 a frame, falls off the screen or stops on a girder surface | 12 x 6 sprite |
| Hero win | win_1, win_2 | 250 ms each, 4 times | one sprite |
| Ape idle | idle_1, idle_2 | 400 ms each | a 46 x 40 sprite (only the head and shoulders change, about 300 pixels) |
| Ape throw | grab_1 300, grab_2 300, throw_1 200, throw_2 300, then idle | the stack shows `barrel_stack_taken` from grab_1 until throw_2 ends; the rolling barrel is created at the start of throw_2 | one sprite |
| Ape pound | pound_1, pound_2, alternating 150 ms, 8 frames | at the start of a stage and after the hero loses a life | one sprite |
| Ape angry | angry, held | while the hero is on g5 or the perch ladder; it still throws, using the angry face in place of idle | one sprite |
| Ape defeated | defeated_1 for 800 ms, then defeated_2 falling 3 px a frame off the bottom of the picture, with 6 dizzy sparkles (sparkle_1) circling its head while it is dazed | 1.5 s | one sprite moving |
| Barrel roll | roll_0 to 3, or 3 to 0 | a new frame every 3 pixels rolled (one quarter turn in 3 pixels, about right for a 12 pixel wheel at the rules' speed) | 12 x 12 |
| Barrel fall | fall_0, fall_1 | 100 ms each while falling; on landing a `dust` puff and a spark (section 6) | 12 x 12 |
| Barrel on a ladder | ladder_0, ladder_1 | 80 ms each | 12 x 12 |
| Wild barrel | wild_fall_0, wild_fall_1 while dropping, wild_roll_0 to 3 while it bounces | 80 ms; 45 degrees a frame | 12 x 12 |
| Barrel smash | smash_0 60, smash_1 80, smash_2 80, then the pop-up | | 12 x 12 |
| Fireball | 0, 1, 2, 1 | 70 ms each | 10 x 10 |
| Fireball smash | 0 60, 1 80, 2 80 | | 10 x 10 |
| Drum flame | 0, 1, 2, 1 | 90 ms each, from the moment a barrel reaches the drum, then for the rest of the stage | 16 x 10 |
| Drum lights | the first time: drum_flame_2 drawn in Flash white for 60 ms, then the loop | | |
| Hammer glint | glint_0, glint_1, glint_0 | 80 ms each, every 1200 ms; the hammer bobs 1 pixel up and down every 400 ms | 5 x 5 |
| Rivet idle | idle_1, idle_2 | 500 ms each | 2 pixels (the lamp) |
| Rivet help | help_1, help_2 with the bubble | 160 ms each for 1600 ms, every 4000 ms | 12 x 17 and the bubble |
| Rivet rescued | rescued_1, rescued_2 (1 pixel higher) | 200 ms each | |
| Item taken | sparkle_0, 1, 2 at the item's centre, then the pop-up | 70 ms each | 7 x 7 |
| Dust | dust_0, 1, 2 | 60 ms each | 8 x 4 |

## 5. Screens

### 5.1 In game, stage 1

Background (2.6), ladders (2.2), girders (2.1), then the things in 2.3, the HUD (2.4). `girder-rush-preview.png` shows it with the ape about to throw, Rivet calling for help, the drum burning, a fireball on g1, barrels on top, g4, g2, falling off g3 and on a ladder, a wild barrel dropping, the hero jumping a barrel on g2 for 100 points, both hammers (one glinting) and the three items.

### 5.2 Title and attract screen

The baked background with only the ground girder. `girder-rush-preview-title.png`.

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| High score | `HIGH SCORE 024600` (the real one) | Dim | 1x | 6 | 4 |
| Title line 1 | `GIRDER` | gradient Title Top to Title Bottom, Outline | 4x | 42 | 34 |
| Title line 2 | `RUSH` | same | 4x | 66 | 68 |
| Show girder | a girder x 40 to 183, flat, surface 140, open (hazard caps) at both ends | Steel | | 40 | 140 |
| The ape | `ape_pound_1` and `ape_pound_2` alternating 150 ms, origin (112, 140) | | | | |
| Barrel stack | `barrel_stack`, origin (58, 140) | | | | |
| Rivet | `captive_help_1` and `_2`, origin (168, 140) | | | | |
| Points table | three rows at y 164, 180, 196: an icon at x 34 (barrel_roll_0, hammer_item, item_flask, centred on the row), the words at x 54, the points right aligned to 190 | Text, Good | 1x | 54 | 164 |
| | `JUMP A BARREL` / `100`, `SMASH IT` / `300`, `PICK UP` / `300 TO 800` | | | | |
| Hint | `ARROWS MOVE   SPACE JUMPS` | Label | 1x | 37 | 218 |
| Press | `PRESS SPACE`, blinking 500 on 300 off | Text | 1x | 79 | 230 |
| The hero | `hero_stand` at (20, 244), blinking now and then | | | | |

Changed pixels per frame: the ape (about 400), the press line (about 200 when it blinks), Rivet. Everything else is static.

### 5.3 The intro (the first five seconds)

Plays once when a game starts (any key skips to 5.4). About 6 seconds, all on the stage 1 picture with the girders **flat** to begin with: every girder drawn at the surface y of its middle step (g1 at 214, g2 at 178, g3 at 142, g4 at 106, g5 at 68), and the two hoist ladders at x 99 and 115 from the ground to the perch.

1. **0 to 3000**: the ape climbs the hoist ladders from the ground (`ape_climb_1` and `_2`, swapping every 8 pixels, 1 pixel every 16 ms, so 200 pixels in about 3.2 s), with Rivet on its shoulder (captive_help_1 and _2 at the ape origin + (12, -30)). Rivet's HELP bubble is shown the whole way up.
2. **3000 to 3400**: at the top it puts Rivet on the perch (Rivet appears at its place, the bubble goes) and steps left onto the top platform to its spot at (50, 64). The hoist ladders are pulled up behind it: each 400 ms, the lowest 40 rows of the hoist are erased (redraw the background there), bottom first.
3. **3400 to 5800**: the ape **jumps**. Five times, 480 ms each: 120 ms drawn 6 pixels higher (idle_2), 120 ms back down on pound_2, and on each landing **one girder tips into its slope**, top to bottom (g5, g4, g3, g2, g1): redraw that girder (its background strip first, then the girder) with the final slope, with a `dust` puff at both of its ends and every ladder that touches it redrawn. That is one 224 x 16 strip per landing.
4. **5800 to 6400**: `ape_pound` (8 frames), then READY (5.4).

It nods to the arcade's famous intro (the climb, the stomps that bend the girders) without copying a single picture: our ape, our hoist ladders, our tipping steel.

### 5.4 Get ready (each life)

A plate across the middle of the stage, y 118 to 145 (28 high), Plate fill, 2 pixel Accent rules at its top and bottom rows. `READY` at 2x in Text with an Outline, centred (x 83, y 125). Shown 1500 ms; the ape plays idle, Rivet idle, nothing moves. The barrels from the last life are gone, the drum keeps burning.

### 5.5 Stage clear

When the hero reaches the perch: everything stops (barrels and fireballs freeze, then each one smashes with its smash frames over 300 ms, one every 60 ms). The ape plays `ape_defeated_1` then `_2`; Rivet plays rescued; the hero plays win; a `heart` (7 x 6, Help Red) appears halfway between the hero and Rivet and rises 1 pixel every 60 ms for 12 pixels. At 1200 ms a plate (y 112 to 151, 40 high, Accent rules) shows `STAGE CLEAR` 2x in a gradient Title Top to Title Bottom with an Outline (x 47, y 118) and `BONUS 3400` 1x Good (centred, y 138); the bonus counts into the score 100 at a time every 20 ms, each step moving the bonus box number down too. Then the next stage.

### 5.6 Game over

After the last life's hit animation, the whole stage is mixed once 45 percent with `05080F` (rows 24 to 255; the HUD stays bright). A plate the full width, `y 106 to 173` (68 high), Plate fill, 2 pixel Accent rules on its top two and bottom two rows. `GAME OVER` 3x gradient Over Top to Over Bottom with an Outline, centred (x 32, y 116). `SCORE 007300` 1x Dim centred at y 144. `PRESS SPACE` 1x Text centred at y 158, blinking 500 on 300 off. `girder-rush-preview-over.png`.

### 5.7 Paused

The same dim as game over (once), then a plate the full width, y 116 to 149 (34 high), Plate fill, 2 pixel Accent rules on its top and bottom rows. `PAUSED` 2x Text with an Outline, centred (x 77, y 121), and `P TO GO ON` 1x Label, centred (x 83, y 139). Nothing animates while paused, the crane lamp included, so the paused picture is static.

### 5.8 A new high score

Three places, nothing else: the HIGH SCORE value turns Good (and the label `HIGH SCORE` flashes Good 300 on 300 off for 2 s) the moment the score passes it; the game over plate gets a line `NEW HIGH SCORE` 1x Good at y 132 (the score line moves to y 144 as before); the title screen shows the new one in its corner.

## 6. Effects: keep, drop, add

**Keep**

1. **Dust on landing**: `dust_0` to `2` under the hero's feet when a jump lands, and under a barrel when it lands from a fall.
2. **Spark where a barrel lands**: 4 particles from the barrel's lowest point, at (-1.2, -1.4), (-0.6, -2), (0.6, -2), (1.2, -1.4) pixels a frame, gravity 0.12, life 14 frames; colours by age: Flash (0 to 2), Gold tone 2 (3 to 6), Accent (7 to 10), Flame tone 4 (11 to 13).
3. **Rivet glint**: every 1500 ms, one random rivet pixel (an `R` of any girder) is drawn Flash for 60 ms, then Gold tone 1 for 60 ms. 1 pixel.
4. **Hot glow round the burning drum**: 10 pixels at (drum x +/- 9 or 10, drum y - 2 to - 10, the pattern in the preview) that pulse between Glow and Glow Hot every 180 ms. Only once the drum is lit.
5. **A short trail behind a rolling barrel**: 3 pixels behind it (Wood tones 3, 4, 5, 2 pixels apart, at its centre height, alternating 1 pixel up and down), only on a girder, not when falling.
6. **Hammer smash**: a Flash white frame of the smash sprite, then a ring of 8 debris particles (Wood tone 2 for a barrel, Flame tone 2 for a fireball) from its centre at 1.5 pixels a frame, 45 degrees apart, life 12 frames, fading to tone 4.
7. **Score pop-ups** (3.8).
8. **The crane lamp**: 2 pixels at (96, 79) and (97, 79), Crane Lamp for 600 ms then Near Block for 600 ms. The only thing in the sky that moves.
9. **The ape's pound shaking a girder**: on each pound_2 frame, the `top` platform's rows are drawn 1 pixel lower for 60 ms (redraw the strip x 0 to 79, rows 63 to 73). Not the sloped girders, so the hero never stands on a moving surface.
10. **The hat flying off** (section 4).
11. **Score pulse**: the SCORE value drawn Good for 300 ms after any score.

**Drop**

- **A drifting cloud or smoke layer in the sky**: it would redraw the background behind the girders every frame; the crane lamp gives the sky its life for 2 pixels.
- **The screen's lamps flickering**: flicker on the whole picture is a full screen change; the rivet glint does the job at 1 pixel.
- **Shaking the sloped girders**: the hero and the barrels stand on them, so a moving surface would have to be a rule; I kept the shake on the ape's own platform.

**Add**

1. **The hammer warning**: the hammer head flashes white every other frame for the last 2 seconds (section 4), so the player is not surprised when it goes.
2. **The intro's tipping girders** (5.3).
3. **The heart** on the rescue (5.5).
4. **The bonus warning**: under 1000 the bonus turns Warn and blinks (2.4).
5. **Dizzy sparkles** round the defeated ape (section 4).

## 7. Later stages (sketches, so the style holds)

Not final art. The rules for each are the brief's; these show how they look in Dusk Shift.

- **Stage 2, the mixing plant** (our own take on the pie factory): flat girders with conveyor belts (the belt profile below, dark rubber with orange chevrons that move with the belt, rollers in Steel), cement sacks riding them (in place of pies), and a hopper at the top in Steel with a Flame glow at its mouth that drops fireballs. Sky: the same dusk, one crane further away.
- **Stage 3, the lifts**: lift decks (16 x 8, Steel with a hazard edge) on 2 pixel cables in Rail Dark, running in open shafts drawn as two Steel lines; the ape throws **springs** (Gold coils, two frames, stretched and squashed) that bounce along the top and drop down the right hand side.
- **Stage 4, the rivets**: a symmetrical tower with 8 yellow capped rivets standing on the girder tops (Gold tones, an iron rim). Walking over one plays the sparkle and leaves an 8 x 2 hole in the surface. When all 8 are out, the girders drop away from under the ape (each girder falls 2 pixels a frame) and it lands upside down (`ape_defeated_2`).
- **Bonus screen**: **Lunch Break**, a 10 second screen between stages 4 and the loop: the hero on the ground and lunch boxes, flasks and tape measures dropping from the crane hook; catch them for points. Uses only sprites that already exist.

#### sketch_belt_0 (16 x 8, origin (0, 0))

Stage 2 sketch: a conveyor belt profile, 16 x 8, frame 1 of 2 (the chevrons move 1 pixel a frame the way the belt runs; rollers in Steel).

Legend: `1`-`5` tones of **Steel**, `A` Accent `FF9A3C`, `B` Hoop `2E2224`.

```
1111111111111111
5AA55AA55AA55AA5
5555555555555555
.B44B..B44B..B4.
B4334BB4334BB43.
B4334BB4334BB43.
.B44B..B44B..B4.
................
```

#### sketch_belt_1 (16 x 8, origin (0, 0))

Stage 2 sketch: a conveyor belt profile, 16 x 8, frame 2 of 2 (the chevrons move 1 pixel a frame the way the belt runs; rollers in Steel).

Legend: `1`-`5` tones of **Steel**, `A` Accent `FF9A3C`, `B` Hoop `2E2224`.

```
1111111111111111
55AA55AA55AA55AA
5555555555555555
.B44B..B44B..B4.
B4334BB4334BB43.
B4334BB4334BB43.
.B44B..B44B..B4.
................
```

#### sketch_sack (12 x 10, origin (6, 10))

Stage 2 sketch: a cement sack (12 x 10) that rides the belts, our own stand in for the pies. Wood tones as hessian, an orange stencil mark.

Legend: `1`-`5` tones of **Wood**, `A` Hoop `2E2224`, `B` Accent `FF9A3C`.

```
..AAAAAAAA..
.AA111111AA.
.A12222221A.
A1222BB2221A
A1222BB2221A
A1223333221A
A1233333321A
A1333333331A
.A43333334A.
..AAAAAAAA..
```

#### sketch_lift (16 x 8, origin (0, 2))

Stage 3 sketch: a lift platform, 16 x 8 (deck rows 2 to 6), hazard edge, with its cable (2 pixels, Rail Dark) above.

Legend: `1`-`5` tones of **Steel**, `A` Tape `FFD23A`, `B` Rail Dark `4A5566`.

```
.......BB.......
.......BB.......
1111111111111111
2222222222222222
5AA55AA55AA55AA5
4444444444444444
5555555555555555
................
```

#### sketch_spring_0 (12 x 12, origin (6, 11))

Stage 3 sketch: the bouncing spring the ape throws, stretched.

Legend: `1`-`5` tones of **Gold**, `A` Hoop `2E2224`, `B` Rail Dark `4A5566`, `C` Head Light `E2E8EE`.

```
....AAAA....
...A1111A...
...AAAAAA...
..BCCCCCCB..
...BBBBBB...
..BCCCCCCB..
...BBBBBB...
..BCCCCCCB..
...BBBBBB...
..BCCCCCCB..
..AAAAAAAA..
............
```

#### sketch_spring_1 (12 x 12, origin (6, 11))

Stage 3 sketch: the bouncing spring the ape throws, squashed.

Legend: `1`-`5` tones of **Gold**, `A` Hoop `2E2224`, `B` Rail Dark `4A5566`, `C` Head Light `E2E8EE`.

```
............
............
............
............
....AAAA....
...A1111A...
...AAAAAA...
..BCCCCCCB..
..BCCCCCCB..
..BCCCCCCB..
..AAAAAAAA..
............
```

#### sketch_rivet_in (8 x 6, origin (4, 6))

Stage 4 sketch: a yellow capped rivet standing on a girder (8 x 6). Walking over it removes it.

Legend: `1`-`5` tones of **Gold**, `A` Hoop `2E2224`, `B` Hoop `2E2224`.

```
..AAAA..
.A1111A.
A122221A
A123321A
.AAAAAA.
..B..B..
```

#### sketch_rivet_out (8 x 6, origin (4, 6))

Stage 4 sketch: the hole left in the girder's top 2 rows (8 x 2). The sparkle plays where the rivet was.

Legend: `C` Rivet Dim `1E4A54`, `D` Ground Fill `0C0F1A`.

```
........
........
........
........
CCCCCCCC
CDDDDDDC
```

## 8. Budgets

| Item | Pixels or objects |
|---|---|
| Background, ladders, girders | baked once into the back layer; redrawn only in the intro (one 224 x 16 strip per tipping girder) and for the platform shake (80 x 11) |
| A normal frame | the hero (14 x 17 or 18 x 20 with the hammer), up to 6 barrels (12 x 12), up to 4 fireballs (10 x 10), the ape (46 x 40, but only when its frame changes), Rivet (12 x 17), the drum flame (16 x 10): about 4000 pixels |
| Particles | sparks 4 per landing, debris 8 per smash, the hat, the drum glow 10, the glint 1: well under 60 at once in play |
| HUD | redrawn only when a number changes: about 2000 pixels |
| Worst case | the stage clear: up to 10 smashes in 300 ms (80 particles at most for one moment, then gone), still no full screen change |
| Full screen changes | only the game over dim and the pause dim, once each |

## 9. Checks

### Contrast (WCAG ratio, computed from the hex values)

| Colour | On | Ratio |
|---|---|---|
| Text | Sky Top | 17.3 : 1 |
| Label | Sky Top | 6.0 : 1 |
| Dim | Sky Top | 8.7 : 1 |
| Accent | Sky Top | 9.2 : 1 |
| Text | Plate | 17.6 : 1 |
| Label | Plate | 6.1 : 1 |
| Warn | Plate | 6.4 : 1 |
| Good | Plate | 12.3 : 1 |
| Over Top | Plate | 11.2 : 1 |
| Over Bottom | Plate | 4.7 : 1 |
| Title Bottom | Sky High | 7.5 : 1 |
| Help Red | Bubble | 3.9 : 1 |
| Hero vest (Vest 3) | Sky Low | 11.9 : 1 |
| Hero vest (Vest 3) | girder web (Steel 4) | 5.2 : 1 |
| Hero vest (Vest 3) | ladder rail (Rail 2) | 1.2 : 1 |
| Hero hat | Sky Low | 15.1 : 1 |
| Hero outline (Ink) | ladder rail (Rail 2) | 12.0 : 1 |
| Barrel wood (Wood 3) | Sky Low | 3.7 : 1 |
| Barrel wood (Wood 3) | girder surface (Steel 1) | 3.0 : 1 |
| Wild drum (Cobalt 3) | Sky Low | 3.6 : 1 |
| Wild band (Hazard) | Cobalt 3 | 4.1 : 1 |
| Fireball (Flame 2) | Sky Ember | 10.0 : 1 |
| Girder surface (Steel 1) | Sky Low | 11.2 : 1 |
| Girder web (Steel 3) | Sky Low | 4.1 : 1 |
| Ladder rail (Rail 2) | Sky Low | 10.0 : 1 |
| Ape fur (Fur 3) | Sky High | 2.5 : 1 |
| Rivet robot (Robot 3) | Sky Top | 14.9 : 1 |

All text passes 4.5 except two: the word HELP on its white bubble (3.9) is 8 pixels high, bold and red on white, so it reads as a sign rather than as text; and the game over gradient's bottom row (4.7, passes). Play colours that are close in luminance are told apart by **shape and pattern**:

- The **hero** against a ladder rail (1.2): the hero always has the 1 pixel Ink outline (12 : 1 against the rail) and is lime and white with silver bands; the ladder is a grey frame of thin rails.
- **Barrel against the girder surface** (3.0) and the sky (3.7): the barrel has a dark iron rim all round (Hoop, about 10 : 1 against the girder top) and a lit top, so its outline always reads.
- **The ape's fur against the sky** (2.5): the ape is not something the player has to avoid; its silver tones 1 and 2 on top, the orange helmet and the hazard belt carry its shape.

### Colour blindness

`girder-rush-colour-check.png` is the in game picture, then the same simulated (Machado, Oliveira and Fernandes 2009, full severity) for deuteranopia, protanopia and tritanopia. In all three: the hero stays the brightest small thing (white hat, light vest, silver bands); the barrels go olive brown and stay round with a dark rim and plank seams; the fireball goes bright yellow and keeps its flame shape and eyes; the wild barrel stays blue and white with a white band, the clearest of all. Barrel, wild barrel and fireball differ in **shape** (round with seams, round with one wide band, a flame with tongues and eyes), **brightness** (mid, mid with a white band, very bright) and **motion** (rolling, dropping, chasing), so they never depend on hue.

### The brief's list

- **Every sprite reads at 2x**: no meaning is carried by a single pixel. The smallest meaningful marks are the hero's eye (1 x 1 on a 4 x 3 face, decoration), the fireball's eyes (1 x 2 each) and the barrel's bung (2 x 2).
- **The hero reads against every girder, ladder and background**: the Ink outline does it; numbers above.
- **The two barrels and the fireball cannot be confused**: above.
- **Every sprite fits its body and states its origin**: the hero's frames are 12 x 16 inside the outline except the hammer frames (the hammer sticks out: 4 rows above the body in hammer up, 6 columns to the right in hammer down, given in 3.1) and the last hit frame (16 wide, lying down, 2 each side); barrels are 12 x 12, the fireball 10 x 10.
- **The girder profile with a step**: 2.5.
- **No full screen change every frame**: section 8.
- **Every colour is in the palette, every pixel is in a legend**: checked by the script that wrote this file.
- **Text contrast**: above.

## 10. What I decided and why

1. **New girder heights.** The brief's left end heights (208, 176, 144, 112, 80) with alternating slopes of 12 to 14 pixels bring each pair of girders to about 19 pixels apart at one end: that is 11 pixels under a girder for a 16 pixel hero. The fix that keeps the brief's slope (1 pixel every 16 columns, 12 pixels across a girder) is to space the girders so they are 24 to 25 apart at the closest end and 47 at the widest: the surfaces in 2.1. The 28 pixels of clear height the brief asked for cannot exist everywhere on 224 rows with five sloping girders, a ground, the ape and a HUD (it would need about 300 rows); what the hero needs is to fit standing (it does, 16 or more everywhere) and for the jump not to be blocked (there is no ceiling, so it is not). **Rule question for you**: please keep "no ceiling collision" in the rules, or the closest ends become places you cannot jump.
2. **The lowest girder slopes up to the left, not the right.** With five alternating girders and the ape at the top left, the top girder must slope down to the right (so the barrels leave the ape), which makes the lowest one slope down to the right too. It rolls barrels off its right end onto the ground, and they roll left along the ground into the oil drum. This is how the classic layout works as well.
3. **The ape stands on the top girder's flat left part** (`top`, y 64) rather than on a separate shelf above it, and Rivet's perch is higher and to the right (y 40, x 96 to 143). That saves the 24 rows a separate shelf would cost.
4. **The HUD takes 24 rows, not 32**, and the bonus timer is in a box below it on the right (x 166 to 219, y 26 to 51), in the space beside Rivet that no girder uses. The lives icons and the stage number are in the middle of the HUD. The 8 rows saved go to the girders.
5. **Ground at y 244** (the brief had 240, inside its 4 pixel allowance).
6. **Light from straight above** for everything, so every walking sprite can be mirrored with no extra frames.
7. **The rolling barrel is seen from its end** (a round wheel of oak with an iron rim, a pair of plank seams that turn and a bung that goes round), and from the side when it falls or goes down a ladder. A quarter turn a frame keeps the four frames clean pixel art, with no jagged in between angles.
8. **The wild barrel is a blue chemical drum**, breaking the "warm things hurt" rule on purpose so it reads as different at once; it spins at twice the visible rate (its band repeats every half turn).
9. **Letters past H**: the hero needs 9 named colours (A to I) and the barrel holding ape frames 12 (A to L). Each legend stays within 16 colours; the brief's 16 colour limit is kept, its A to H range is not.
10. **Bonus items of our own**: a tape measure (300), a lunch box (500), a thermos flask (800). The captive is Rivet, a robot; the ape is a silverback with a too small helmet; the hero is a site worker in a hard hat and hi-vis. No red cap, no dungarees, no pink dress, no red girders.
11. **The intro** is the ape climbing hoist ladders with Rivet on its shoulder, pulling the ladders up and tipping each flat girder into its slope with a stomp (5.3). This needs the game to draw the girders flat first and to redraw one girder at a time.
12. **Name**: Girder Rush is good; I kept it. The title is two lines of 4x text, so the name is the biggest thing on the title screen.

## 11. Sprite index

| Sprite | Size | Group |
|---|---|---|
| hero_stand | 14 x 17 | hero |
| hero_blink | 14 x 17 | hero |
| hero_walk_1 | 14 x 17 | hero |
| hero_walk_2 | 14 x 17 | hero |
| hero_walk_3 | 14 x 17 | hero |
| hero_climb_1 | 14 x 17 | hero |
| hero_climb_2 | 14 x 17 | hero |
| hero_climb_top | 14 x 17 | hero |
| hero_jump | 14 x 17 | hero |
| hero_fall | 14 x 17 | hero |
| hero_hammer_up | 18 x 21 | hero |
| hero_hammer_down | 20 x 21 | hero |
| hero_win_1 | 14 x 17 | hero |
| hero_win_2 | 14 x 17 | hero |
| hat_fly | 12 x 6 | hero |
| hero_hit_1 | 14 x 17 | hero |
| hero_hit_2 | 14 x 17 | hero |
| hero_hit_3 | 14 x 17 | hero |
| hero_hit_4 | 14 x 17 | hero |
| hero_hit_5 | 18 x 17 | hero |
| ape_idle_1 | 46 x 40 | ape |
| ape_idle_2 | 46 x 40 | ape |
| ape_grab_1 | 46 x 40 | ape |
| ape_grab_2 | 46 x 40 | ape |
| ape_throw_1 | 46 x 40 | ape |
| ape_throw_2 | 46 x 40 | ape |
| ape_pound_1 | 46 x 40 | ape |
| ape_pound_2 | 46 x 40 | ape |
| ape_angry | 46 x 40 | ape |
| ape_defeated_1 | 46 x 40 | ape |
| ape_climb_1 | 46 x 40 | ape |
| ape_climb_2 | 46 x 40 | ape |
| ape_defeated_2 | 46 x 40 | ape |
| barrel_roll_0 | 12 x 12 | barrel |
| barrel_roll_1 | 12 x 12 | barrel |
| barrel_roll_2 | 12 x 12 | barrel |
| barrel_roll_3 | 12 x 12 | barrel |
| barrel_fall_0 | 12 x 12 | barrel |
| barrel_fall_1 | 12 x 12 | barrel |
| barrel_ladder_0 | 12 x 12 | barrel |
| barrel_ladder_1 | 12 x 12 | barrel |
| wild_roll_0 | 12 x 12 | wild |
| wild_roll_1 | 12 x 12 | wild |
| wild_roll_2 | 12 x 12 | wild |
| wild_roll_3 | 12 x 12 | wild |
| wild_fall_0 | 12 x 12 | wild |
| wild_fall_1 | 12 x 12 | wild |
| barrel_stack | 24 x 24 | barrel |
| barrel_stack_taken | 24 x 24 | barrel |
| barrel_smash_0 | 12 x 12 | barrel |
| barrel_smash_1 | 12 x 12 | barrel |
| barrel_smash_2 | 12 x 12 | barrel |
| oil_drum | 16 x 16 | drum |
| drum_flame_0 | 16 x 10 | drum |
| drum_flame_1 | 16 x 10 | drum |
| drum_flame_2 | 16 x 10 | drum |
| fireball_0 | 10 x 10 | fire |
| fireball_1 | 10 x 10 | fire |
| fireball_2 | 10 x 10 | fire |
| fire_smash_0 | 10 x 10 | fire |
| fire_smash_1 | 10 x 10 | fire |
| fire_smash_2 | 10 x 10 | fire |
| captive_idle_1 | 12 x 17 | captive |
| captive_help_1 | 12 x 17 | captive |
| captive_help_2 | 12 x 17 | captive |
| captive_rescued_1 | 12 x 17 | captive |
| captive_idle_2 | 12 x 17 | captive |
| captive_rescued_2 | 12 x 17 | captive |
| help_bubble | 32 x 13 | captive |
| heart | 7 x 6 | captive |
| hammer_item | 12 x 12 | hammer |
| glint_0 | 5 x 3 | hammer |
| glint_1 | 5 x 5 | hammer |
| item_tape | 13 x 11 | items |
| item_lunch | 12 x 11 | items |
| item_flask | 12 x 11 | items |
| sparkle_0 | 7 x 7 | items |
| sparkle_1 | 7 x 7 | items |
| sparkle_2 | 7 x 7 | items |
| lives_icon | 8 x 8 | hud |
| dust_0 | 8 x 4 | fx |
| dust_1 | 8 x 4 | fx |
| dust_2 | 8 x 4 | fx |
| girder_profile | 16 x 8 | scenery |
| ground_profile | 16 x 8 | scenery |
| girder_end_left | 4 x 8 | scenery |
| girder_end_right | 4 x 8 | scenery |
| girder_end_wall | 4 x 10 | scenery |
| ladder_rung | 10 x 4 | scenery |
| ladder_cap | 10 x 3 | scenery |
| ladder_foot | 10 x 3 | scenery |
| ladder_broken_top | 10 x 6 | scenery |
| ladder_broken_bottom | 10 x 6 | scenery |
| perch_rail | 4 x 5 | scenery |
| sketch_belt_0 | 16 x 8 | later |
| sketch_belt_1 | 16 x 8 | later |
| sketch_sack | 12 x 10 | later |
| sketch_lift | 16 x 8 | later |
| sketch_spring_0 | 12 x 12 | later |
| sketch_spring_1 | 12 x 12 | later |
| sketch_rivet_in | 8 x 6 | later |
| sketch_rivet_out | 8 x 6 | later |
