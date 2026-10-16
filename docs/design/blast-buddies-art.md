# Blast Buddies: art and screen design, "Sunny Side"

Designer's answer to `blast-buddies-art-brief.md`. It is meant to be pasted into code with no further decisions. Where I disagree with the brief or had to choose, it is in section 9. Previews, all at 3x with nearest neighbour scaling:

- `blast-buddies-preview.png`: the in game screen (Meadow), a landscape that has taken a few hits, goons of all four teams, a rocket in the air, an explosion at 120 ms, a crate coming down by parachute.
- `blast-buddies-preview-title.png`: the title screen, a moment after the rocket bit the last S.
- `blast-buddies-preview-over.png`: the winner screen (Canyon).
- `blast-buddies-themes.png`: the same landscape in Meadow, Canyon and Candy.
- `blast-buddies-colour-check.png` (2x): the in game picture as it is, then simulated for deuteranopia, protanopia and tritanopia.
- `blast-buddies-holes.png` (2x): the many holes test, 16 random blasts on each theme.

Every sprite block, every table of numbers and every preview below was made by one small script from one set of data, so the pictures and the text cannot disagree. Every sprite was checked: each pixel is `.` or in its legend, no legend has more than 16 colours, and every goon frame keeps its body inside 9 x 11 (the backflip frames, which are turned, are the one stated exception).

## 0. Read this first

- The canvas is **384 x 240**, origin top left, shown at 3x (or 2x). One pixel of this file is one canvas pixel. It is the direct colour `PixelCanvas` of Invaders and Asteroids.
- **Sprite format**: as in the brief and `snake-art.md`. `.` is transparent. `1` to `5` are the five tones of the sprite's colour row (1 highlight, 5 edge). Capital letters are named colours from the legend under each block. A few sprites use letters past `H` (the goons use `I` for their Ink outline); `Tile` accepts any capital letter, and no legend goes over 16 colours.
- **The goon is designed once in the Reds row.** To draw another team, swap the colour row: digits `1` to `5` take that team's tones from section 1.1, and every letter keeps its colour. The team mark (section 3.2) is drawn on top.
- **Origin**: every block gives its origin as (column, row) inside the picture. For anything that stands, the origin row is **one below the picture's last row**: draw the sprite with its top left at `(x - ox, groundY - oy)`, where `groundY` is the first solid row under it, and its lowest row lands on `groundY - 1`, standing on the terrain. For the goon the origin is the middle of the feet.
- **Facing**: everything that walks is drawn facing right; mirror the columns for left (`x' = width - 1 - x`, and the origin column mirrors the same way). All shading is **from straight above** (a midday sun), so a mirrored frame is still lit correctly and no left frames are needed.
- **Turning**: the bazooka, the shotgun, the rocket and its exhaust are turned by the game in **64 steps** (5.625 degrees each) round their origin, nearest neighbour: for each screen pixel `(dx, dy)` from the pivot, the source pixel is `(round(cos a * dx + sin a * dy) + ox, round(-sin a * dx + cos a * dy) + oy)`, drawn if it is inside the picture and not `.`. Angle 0 points right, positive turns clockwise on screen (y grows down). Facing left, mirror the part first, then turn by the mirrored angle.
- **Draw order (back to front)**: 1 the baked sky (gradient, sun, far hills), 2 clouds, 3 the back water layer, 4 the front water, 5 the terrain (down to row 228, so a shore stands in the waves), 6 crates, mines, gravestones, flares, 7 goons and their marks, 8 held weapons, 9 shots, 10 explosions, smoke and particles, 11 labels (health, names, damage numbers, bubbles, icons), 12 the HUD, 13 banners. A goon or a shot below row 226 is clipped at row 226 (it is under the water).
- **Text** is the 5 x 7 font with one pixel between letters: `n` characters at scale `k` are `n * 6k - k` wide. "Centred" means `x = floor((384 - width) / 2)`. "With Outline" means the text is first drawn in `Outline` at the 8 one pixel offsets, then in its colour. Gradient text: row `r` of the `7k` letter rows is the mix of the top and bottom colours at `r / (7k - 1)`. The font has no comma or apostrophe, and every word below uses only its characters.
- **Time** is in milliseconds. The game runs 60 frames a second; animations count from the game's own clock, as in the other games. All randomness is the game's seeded random.

What is in the file: 1 art direction and palette, 2 terrain, sky and water, 3 sprites, 4 animation recipes, 5 screens, 6 effects, 7 budgets, 8 checks, 9 what I decided and why, 10 sprite index.

## 1. Art direction and palette

**Sunny Side.** A Saturday morning cartoon at noon: a big clean sky, a fat yellow sun with a dotted ring, chunky hills of grass and cocoa coloured soil with crumbs of stone in them, and a sea that sparkles. The goons are round, glossy, sweet coloured pills with one huge lens, lit from straight above so they look like boiled sweets. The ground is warm and earthy so the goons, in clean saturated colours with a dark Ink outline, always sit in front of it. The sky is the palest thing on the screen and the explosions are the hottest, so action reads first. Against its siblings: no navy, no neon and no dusk. It is the only daylight game in the box, and the brightest. One shared accent with the house style: the Cookoff orange `FF9A3C` on the HUD frames and banner rules.

Colour rules that keep it readable:

- Everything that moves has a 1 pixel **Ink** outline (`1C1426`). Terrain, sky and water never use Ink, so a goon, a crate or a shot always has a dark edge against them.
- The sky gradient and the far hills are paler and less saturated than any team colour. The Blast ramp (`FFF6C0` to `8A2A1E`) is used only by fire, sparks and fresh scorch.
- Team colours avoid yellow (no yellow body, see the brief) and avoid the grass greens. Gold is kept for good news: healing, the star crate, the halo, the winner.

### 1.1 Colour rows (tones 1 to 5)

Tones 1 and 2 are the base mixed with white at 70% and 30%; tone 3 is the base; tones 4 and 5 are the base mixed with `05080F` at 32% and 64%. (The same formula as Lantern Glass, so the families feel related.) Blast and Smoke are fixed ramps, not made by the formula.

| Row | 1 | 2 | 3 | 4 | 5 | Used for |
|---|---|---|---|---|---|---|
| Reds | `F8C8C4` | `EF7F76` | `E8483C` | `9F342E` | `571F1F` | team 1, the Reds (mark: an antenna with a ball) |
| Blues | `C5D5F8` | `779EEE` | `3D74E6` | `2B51A1` | `192F5C` | team 2, the Blues (mark: a three spike tuft) |
| Teals | `BCE8E2` | `62CABC` | `1FB3A0` | `177C72` | `0E4643` | team 3, the Teals (mark: a little top hat) |
| Grapes | `E1CEF6` | `B88DE9` | `9A5CE0` | `6A419D` | `3B265A` | team 4, the Grapes (mark: two round ears) |
| Metal | `D7DAE0` | `A2A9B7` | `7A8498` | `555C6C` | `2F3540` | weapon barrels, the mine, the gravestone rim |
| Grenade | `CAE1C4` | `83BA76` | `4E9C3C` | `376D2E` | `1F3D1F` | the grenade |
| Stick | `F4C4C4` | `E57575` | `DA3A3A` | `962A2C` | `521A1E` | dynamite |
| Crate | `EEDCC9` | `D8AD80` | `C88A4A` | `8A6037` | `4B3724` | the weapon crate (wood) |
| Stone | `E5E4E7` | `C2BFC8` | `A8A4B0` | `74727C` | `404049` | the gravestone |
| Gold | `FFEDC4` | `FFD475` | `FFC23A` | `AF862C` | `5F4B1E` | halo, star, sparkles, the selected highlight, good news |
| Blast | `FFF6C0` | `FFD54A` | `FF8A1E` | `E5402A` | `8A2A1E` | the explosion ramp, exhaust, sparks, fuse and muzzle flash |
| Smoke | `E4DEE6` | `C2BAC4` | `9A929E` | `766E7A` | `524A56` | smoke puffs and the rocket trail (light to dark as it ages) |

### 1.2 Named colours

| Name | Hex | Used for |
|---|---|---|
| Ink | `1C1426` | the 1 pixel outline of every goon, crate and weapon, the darkest detail |
| Lens | `FFFFFF` | the goon's big lens |
| Lens Shade | `C9D6E6` | the lower rim of the lens |
| Pupil | `1C1426` | the pupil (2 x 2) |
| Strap | `3A3046` | the goggle strap and eyelids |
| Mouth | `6A1E34` | the mouth |
| Tooth | `FFFFFF` | teeth in a grin |
| Boot | `3A3046` | feet |
| Blush | `FF8FA0` | cheeks when happy or healed |
| Rocket | `F4F4F0` | the rocket body |
| Rocket Tip | `E8483C` | the rocket nose and fins |
| Pin | `D8DEE6` | the grenade pin and lever |
| Fuse | `C8A070` | dynamite fuse |
| Tube | `6E8A3A` | the bazooka tube (olive) |
| Tube Light | `A4C060` | the bazooka tube highlight |
| Wood | `8A5A30` | shotgun stock |
| Radio | `3A3046` | the air strike radio |
| Flare | `FF4FA0` | the air strike flare light |
| Flare Hot | `FFD0E8` | the flare core |
| Mine Light | `FF3A3A` | the mine's light when lit |
| Mine Off | `6A2A2A` | the mine's light when dark |
| Health | `F6F6F2` | the health crate (white) |
| Health Shade | `C8CCD6` | the health crate shading |
| Cross | `E8483C` | the red cross on the health crate |
| Star | `FFD23A` | the star on the weapon crate |
| Chute A | `F6F6F2` | parachute stripe (white) |
| Chute B | `FF8A1E` | parachute stripe (orange) |
| Cord | `3A3046` | parachute cords |
| Heart | `FF5A7A` | the healed heart icon |
| Alert | `FFD23A` | the ! icon |
| Think | `FFFFFF` | the ? icon |
| Skull | `F6F6F2` | the skull icon |
| Bubble | `FFFFFF` | speech bubbles |
| Panel | `1C1426` | HUD panels (drawn as dark plates over the sky) |
| Panel Rule | `4A3E5A` | the 1 pixel inner line of a HUD panel |
| Text | `FFFFFF` | numbers and words |
| Label | `B8AECB` | labels and hints on panels |
| Accent | `FF9A3C` | the house orange: timer frame, banner rules |
| Warn | `FF4A3A` | the timer under 10 seconds |
| Good | `FFC23A` | healing numbers, the winner |
| Hurt | `FF5A4A` | damage numbers |
| Outline | `1C1426` | the 1 pixel outline behind text over the picture |
| Flash | `FFFFFF` | flashes and the first colour of every spark |
| Title Top | `FFF2A0` | the title gradient, top |
| Title Bottom | `FF6A2A` | the title gradient, bottom |
| Sheet | `2A2238` | background of the sprite sheet pictures only (not in the game) |

## 2. Terrain, sky and water

### 2.1 The terrain colour rule

Every solid pixel `(x, y)` gets its colour from this rule, tried in order. **Depth** is how many solid pixels lie directly above it in the same column before the first air pixel (the top solid pixel of a column has depth 0; the first solid pixel under a cave roof's air also has depth 0, so the floor of a cave gets grass).

1. If the pixel is in a **scorch ring** (section 2.3): the scorch colour for its ring step (1, 2 or 3).
2. Depth 0: `top1`. Depth 1: `top2`. Depth 2 or 3: `top3`. (A 4 pixel grass or crust band, brightest on top.)
3. If the pixel left, right or below it is air: `edge` (cave walls, cliff sides and undersides get a 1 pixel lit lip, so a cut face reads as a clean edge).
4. If `y >= rockY(x)`: `rock`, or `rock_speck` where the speckle tile says so. `rockY(x) = 200 + round(3 * sin(x / 23))`, a slow wave so the bedrock line never looks ruled.
5. Depth 4 to 13: `soil` or `soil_speck`.
6. Depth 14 and more: `deep` or `deep_speck`.

The pixel is speckled when `SPECKLE[y mod 16][x mod 16]` is `+`. The tile is fixed to the screen, not to the ground, so a crater shows the same stones that were inside the hill.

### 2.2 The speckle tile (16 x 16)

Small stones of 1 to 3 pixels, never in the same row twice in a row, so a cut edge never shows a straight line of speckles.

```
................
..+.........+...
.++.....+.......
.......++.......
...........+....
....+......++...
................
+.........+.....
.........++.....
...+............
..++.......+....
.............+..
......+.....++..
.....++.........
................
.+.........+....
```

### 2.3 Holes, scorch and the crumb rule

- An explosion of radius `r` at `(cx, cy)` turns every pixel with `distance <= r` into air.
- **Scorch**: every solid pixel with `r < distance <= r + 3` gets ring step `k = ceil(distance - r)` (1, 2 or 3), keeping the smaller step if it already had one. Step 1 is next to the hole. A scorched pixel keeps its scorch until it is blown away; scorch on a surface does not grow grass again.
- **Fresh glow**: for the first 200 ms the ring is drawn in Blast tone 3 (step 1), 4 (step 2) and 5 (step 3). At 200 ms it moves one colour cooler (step 1 Blast 4, step 2 Blast 5, step 3 `scorch3`); at 400 ms again (step 1 Blast 5, step 2 `scorch2`); at 600 ms every step has its own `scorch` colour. Only the ring pixels are redrawn.
- **Crumb rule**: after carving, flood fill (4 way) from every solid pixel inside the box `cx - r - 8` to `cx + r + 8`, `cy - r - 8` to `cy + r + 8`. Any piece of solid ground of **24 pixels or fewer** is turned to air and thrown out as debris (section 6.1). So no specks float in the sky. Bigger floating pieces stay, as in the genre: an arch or an island in the air is part of the fun.
- **Re-shade**: after a hole, re-colour every solid pixel in the columns `cx - r - 4` to `cx + r + 4`, from row `cy - r - 4` down to row `cy + r + 18` (depth only changes the band for depths up to 13), plus their left and right neighbours for the edge test. A cut surface gets its grass band, its edge and its scorch from the rule, with nobody drawing it.

### 2.4 Three themes

The same rule, sky and water with a different table. **Meadow**: blue sky, green grass, cocoa soil, grey bedrock, a blue sea. **Canyon**: an apricot morning sky, sandstone in cream, orange and rust, a teal lagoon. **Candy**: a lilac sky, white icing on top over pink, chocolate soil with sprinkles (the speckles are gold in the soil and sky blue deep down), a mint sea. Each one changes the sky, the ground, the speckle look, the water and the clouds.

| Key | Used for | Meadow | Canyon | Candy |
|---|---|---|---|---|
| sky_top | sky at y = 0 | `5AAEE8` | `F2885E` | `B48CE8` |
| sky_low | sky at the horizon, y = 200 | `C6E8F6` | `FFE0A8` | `FFD8F0` |
| sun | the sun disc | `FFE680` | `FFF6D0` | `FFFFFF` |
| sun_ring | the ring of pixels round the sun | `FFF3C0` | `FFE8B0` | `FFE8F6` |
| far | the far hills (baked) | `9CCFB4` | `E0A07A` | `E8B4E0` |
| far_top | the lit top row of the far hills | `B8E0C8` | `F0BC94` | `F6CCEC` |
| cloud | cloud | `FFFFFF` | `FFF0E0` | `FFFFFF` |
| cloud_shade | cloud underside | `DCEEF8` | `F8CDB0` | `F8D4EC` |
| top1 | surface band, depth 0 (the very top pixel) | `B8F060` | `FFE6A0` | `FFFFFF` |
| top2 | surface band, depth 1 | `84D23E` | `F4C870` | `FFD0E8` |
| top3 | surface band, depth 2 to 3 | `58A830` | `E0A850` | `F48CC0` |
| soil | soil band, depth 4 to 13 | `A0663A` | `D8763E` | `7E4A30` |
| soil_speck | soil speckle | `BC8452` | `E89458` | `FFD23A` |
| deep | deep band, depth 14 and more | `744A2C` | `AE5230` | `5E3422` |
| deep_speck | deep speckle | `5E3A22` | `943E24` | `4EC8E8` |
| rock | bedrock, y 200 and lower | `5E5866` | `6E3428` | `3E2418` |
| rock_speck | bedrock speckle | `746E7C` | `864434` | `56342A` |
| edge | a solid pixel with air on its left or right or below (cave walls and undersides) | `C08250` | `F09A5C` | `9A5E40` |
| scorch1 | scorch, 1 pixel from a hole | `2E2220` | `2E1A16` | `1E1210` |
| scorch2 | scorch, 2 pixels | `442E24` | `4A2620` | `2E1C16` |
| scorch3 | scorch, 3 pixels | `5A3E2C` | `6A3426` | `3E2A1E` |
| water_back | the back water layer | `1A5A9A` | `127A7A` | `2EA07A` |
| water | water body | `2378C8` | `1CA6A0` | `44C896` |
| water_top | the wave surface | `4AA8EE` | `4ED4C8` | `86ECC0` |
| foam | wave crests and splash | `D8F2FF` | `E0FFF8` | `F0FFF6` |

### 2.5 The sky (drawn once per map)

- **Gradient**: row `y` is the mix of `sky_top` and `sky_low` at `min(1, y / 200)`.
- **Sun**: a disc of radius 13 (every pixel with distance `<= 13`) at (316, 44) in `sun`, and a ring of the pixels with `15.5 <= distance <= 16.5` in `sun_ring`, leaving out every pixel where `(x + y) mod 4 = 0` (so it reads as a sparkle, not a line).
- **Far hills**: for each column, `h = 168 + 10 * sin(x / 31 + 0.7) + 5 * sin(x / 13)`; rows `h` to 239 are `far`, and row `h` itself is `far_top`. They sit behind the terrain and the water.
- **Clouds**: a cloud of size `n` at (x0, y0) is `n + 2` circles in a row: circle `i` at `(x0 + 9i, y0 - 4)` with radius 6 for odd `i`, and at `(x0 + 9i, y0 - 2)` with radius 5 for even `i`, cut flat at `y0 + 4`. The bottom 2 rows are `cloud_shade`, the rest `cloud`. The sample map has clouds at (40, 30, 3), (150, 56, 2), (230, 24, 3), (352, 86, 2) (x, y, n).
- **Drift**: clouds move with the wind, 1 pixel every `800 - 60 * |wind|` ms (wind is -10 to 10), and wrap round the sides. Only the cloud's box is redrawn (from the baked sky). With no wind they drift right every 800 ms.

### 2.6 The water

- The **back layer** fills rows 222 to 239 with `water_back`, with a 1 pixel swell: column `x` starts 1 row lower when `((x + b) div 8)` is even, where `b` steps by 1 every 120 ms.
- The **front water** starts at row 226. Rows 226 to 228 are the wave tile below (16 wide, repeated across the screen), rows 229 to 239 are `water`. `F` is `foam`, `T` is `water_top`, `.` lets the back layer show. Frames step every 200 ms: 1, 2, 3, 4.

Wave 1:

```
....FF..........
..FTTTF......FF.
FTTTTTTTF..FTTTT
```

Wave 2:

```
........FF......
......FTTTF.....
.FF..FTTTTTTTF..
```

Wave 3:

```
............FF..
.F........FTTTF.
TTTF.....FTTTTTT
```

Wave 4:

```
FF..............
TTF..........FTT
TTTTTF..FF..FTTT
```

- **Splash** (a goon, a crate or a shot reaching row 226): droplets in `foam` and `water_top`, 10 for a goon or a crate, 6 for a shot, thrown up at 1.5 to 3 pixels a frame between 240 and 300 degrees, with gravity 0.15 pixels a frame per frame, gone when they fall back to the water line. A ring: `foam` pixels on row 226 moving out 1 pixel a frame each side for 6 frames, every other column.
- **Sinking goon**: the `sink` frame, moved down 1 pixel every 60 ms for 12 rows (clipped at the water line), then 3 bubbles (a 3 x 3 ring of `foam`, no middle pixel) rise from row 236 to the water line at 1 pixel every 40 ms, 200 ms apart, each popping as one `foam` pixel for 60 ms.

### 2.7 The map edges

**Open on every side.** The sky goes off the left and the right, and the water runs the whole width. There is no wall: a goon or a crate that goes past x 0 or x 383, or reaches the water, is lost (the game treats leaving the sides the same as drowning, with a splash where it would have landed: at the edge column, row 226). Shots that leave the sides are gone; shots may fly above row 0 and come back down, and while one is above the screen a 3 x 2 Ink and Flash arrow at row 1 marks its column. The terrain generator should leave a gap of at least 10 columns of air at each side (as the sample map does), so the edge never looks cut by a ruler.

## 3. Sprites

### 3.1 The goon

A stubby pill, 9 x 11, with **one big lens** on a dark goggle strap that runs off both sides of the head, a tiny mouth, nubby arms (the 1 pixel bumps at the sides, just below the lens) and two boots. It is a rounded column, not a capsule with dungarees: no overalls, no second eye, no yellow. All the expression is in the lens (the pupil looks around, the lid comes down, the X when it hurts) and the mouth.

How the game picks the frame:

- Standing: `idle_1` and `idle_2` every 600 ms. A `blink` for 100 ms every 2.5 to 4 s. Every 5 to 9 s, `look_back` for 700 ms. Facing the nearest enemy when it is not its turn.
- **Worried** wins over idle whenever a live shot (rocket, grenade, dynamite, flare, missile) is within 48 pixels, and in the 1500 ms before the timer of a grenade or dynamite within 48 pixels runs out.
- **Grin** for 800 ms on its team's good news (an enemy hit, a crate taken). **Taunt** for 600 ms when an enemy shot lands within 24 pixels and does it no harm. **Shiver**: the active goon in its last 5 seconds, alternating with `worried` every 60 ms.
- Walking: a new frame every 3 pixels walked, 1 2 3 4. Jumping: `jump_rise` while going up, `jump_fall` while coming down, then `land` for 120 ms. Backflip: `flip_1` to `flip_4`, 90 ms each, then `jump_fall`.
- Aiming (the active goon, still, with a weapon that aims): `aim`, with the weapon part drawn at the pivot (section 3.3).
- Hit: `flinch` for 250 ms, then `fly_1` and `fly_2` every 80 ms while it is thrown, then `land`.
- Dying, sinking and winning: section 4.

The goon sprites below are all 11 x 12 (the 9 x 11 body, a 1 pixel Ink outline on the top and the sides, none under the feet), origin (5, 12), except the two turned backflip frames.

#### goon_idle_1 (11 x 12, origin (5, 12))

Idle A (breathing out). Picture 11 x 12 (the 9 x 11 body inside a 1 pixel Ink outline on the top and sides; no outline under the feet). Origin (5, 12): the middle of the feet, one row below the picture, so the last row sits on the ground.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I132223331I
I53333EE35I
.I5333225I.
..I45554I..
.IGGI.IGGI.
```

#### goon_idle_2 (11 x 12, origin (5, 12))

Idle B (breathing in: the head 1 pixel lower, squashed). Alternate A and B every 600 ms.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...........
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13222EE31I
.I5333225I.
..I45554I..
.IGGI.IGGI.
```

#### goon_blink (11 x 12, origin (5, 12))

Blink: 100 ms, every 2.5 to 4 s (random, seeded).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAA33333AAI
IAAAAAAAAAI
.IA33333AI.
.I3AAAAA3I.
I132223331I
I53333EE35I
.I5333225I.
..I45554I..
.IGGI.IGGI.
```

#### goon_look_back (11 x 12, origin (5, 12))

Fidget: looks back over its shoulder (the pupil on the left of the lens) for 700 ms, now and then while idle.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAADDBBBAAI
.IADDBBBAI.
.I3ACCCA3I.
I132223331I
I53333EE35I
.I5333225I.
..I45554I..
.IGGI.IGGI.
```

#### goon_worried (11 x 12, origin (5, 12))

Worried: the lid half down, a wobbly mouth. Whenever a live shot (rocket, grenade, dynamite, flare, mine) is within 48 pixels.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAAAAAAAAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I132232331I
I5333E4E35I
.I5332E25I.
..I45554I..
.IGGI.IGGI.
```

#### goon_grin (11 x 12, origin (5, 12))

Grin: on its own team's good news (a hit on an enemy, a crate), for 800 ms.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `H` Blush `FF8FA0`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA4I.
I132H333H1I
I533EFFE25I
.I532EE25I.
..I45554I..
.IGGI.IGGI.
```

#### goon_walk_1 (11 x 12, origin (5, 12))

Walk 1 of 4. A new frame every 3 pixels walked (walk 2 and walk 4 are the same frame).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
.I42223331I
I13333EE4I.
.I5333225I.
.II55555II.
IGGI...IGGI
```

#### goon_walk_2 (11 x 12, origin (5, 12))

Walk 2 and 4: passing (the head 1 pixel lower).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...........
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13222EE31I
.I5333225I.
..I44544I..
..IGGIGGI..
```

#### goon_walk_3 (11 x 12, origin (5, 12))

Walk 3 of 4.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13222334I.
.I4333EE31I
.I5333225I.
..I44544I..
..IGGIGGI..
```

#### goon_walk_4 (11 x 12, origin (5, 12))

Walk 4 (the same as walk 2).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...........
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13222EE31I
.I5333225I.
..I44544I..
..IGGIGGI..
```

#### goon_jump_rise (11 x 12, origin (5, 12))

Jump, rising (arms up).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.I.IIIII.I.
I1I11111I1I
.I1AAAAA1I.
IAABBDDBAAI
IAABBDDBAAI
.IABBBBBAI.
.I3ACCCA3I.
I132223331I
.I4333EE4I.
.I5333225I.
..I45554I..
..IGI.IGI..
```

#### goon_jump_fall (11 x 12, origin (5, 12))

Jump, falling (looking down at where it lands).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBBBBAAI
.IABBDDBAI.
.I3ACDDA3I.
I132223331I
I53333EE35I
.I5333EE5I.
..I55555I..
.IGI...IGI.
```

#### goon_aim (12 x 12, origin (5, 12))

Aiming: the front arm out at the weapon pivot. The weapon part (section 3.3) is drawn over it, turned to the aim angle round its pivot, which sits at the goon origin + (3, -5) facing right.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII....
..I11111I...
.I1AAAAA1I..
IAABBBBBAAI.
IAABBDDBAAI.
.IABBDDBAI..
.I3ACCCA3II.
.I422233311I
I13333EE4I..
.I5333225I..
..I45554I...
.IGGI.IGGI..
```

#### goon_flinch (11 x 12, origin (5, 12))

Hurt, flinch: eyes squeezed shut (an X of lids), mouth open. 250 ms when hit, before it is thrown.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAAA323AAAI
IAA3A3A3AAI
.IAA343AAI.
.I3AAAAA3I.
I132233331I
I5333EEE35I
.I533EFE5I.
..I45554I..
.IGGI.IGGI.
```

#### goon_fly_1 (11 x 12, origin (5, 12))

Hurt, flying A: thrown, arms and legs flailing, a gasp. Alternate A and B every 80 ms while it is in the air after a hit.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.I.IIIII.I.
I1I11111I1I
.IAAAAAAAI.
IABBBBBBBAI
IABBBDDBBAI
IABBBDDBBAI
.IACCCCCAI.
.I322EE23I.
I1533EE351I
I5I43224I5I
.II55555II.
IGI.....IGI
```

#### goon_fly_2 (11 x 12, origin (5, 12))

Hurt, flying B.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.IAAAAAAAI.
IABBBBBBBAI
IABBBDDBBAI
IABBBDDBBAI
.IACCCCCAI.
I1222EE221I
.I433EE34I.
.I5332235I.
IGI55555IGI
.IGI...IGI.
```

#### goon_land (11 x 12, origin (5, 12))

Landing: squashed flat for 120 ms after any fall or hop, then idle.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...........
...........
...........
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
I12222EE21I
.I4555554I.
IGGI...IGGI
```

#### goon_alarm_1 (11 x 12, origin (5, 12))

Dying, alarm 1: the lens wide, looking up, mouth an O.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.IAAAAAAAI.
IABBBBBBBAI
IABBBDDBBAI
IABBBDDBBAI
.IACCCCCAI.
I1222EE221I
I5333EE335I
.I5332235I.
..I45554I..
.IGGI.IGGI.
```

#### goon_alarm_2 (11 x 12, origin (5, 12))

Dying, alarm 2: in the air (draw it 6 pixels up), arms up.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.I.IIIII.I.
I1I11111I1I
.I1AAAAA1I.
IAABBDDBAAI
IAABBDDBAAI
.IABBBBBAI.
.I3ACCCA3I.
.I422EE24I.
I1533EE351I
I5I43224I5I
..I45554I..
..IGI.IGI..
```

#### goon_alarm_3 (11 x 12, origin (5, 12))

Dying, alarm 3: the flinch frame; then the goon is gone in a puff and the halo and gravestone rise.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAAA323AAAI
IAA3A3A3AAI
.IAA343AAI.
.I3AAAAA3I.
I132233331I
I5333EEE35I
.I533EFE5I.
..I45554I..
.IGGI.IGGI.
```

#### goon_sink (11 x 12, origin (5, 12))

In the water: sinking, only the top shows (the rows below the water line are drawn behind the water, so this frame is the top 7 rows of the goon plus its worried lid).

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `I` Ink `1C1426`.

```
...........
...........
...........
...........
...IIIII...
..I11111I..
.I1AAAAA1I.
IAAAAAAAAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I1555EE551I
```

#### goon_dance_1 (11 x 12, origin (5, 12))

Winning dance 1 of 3 (blushing grin). Play 1 2 3 2, 150 ms each, with a 2 pixel hop on frame 3.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `H` Blush `FF8FA0`, `I` Ink `1C1426`.

```
.I.IIIII...
I1I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
.I4H333H31I
.I42EFFE35I
.I532EE25I.
..I45555I..
.IGGI..IGI.
```

#### goon_dance_2 (11 x 12, origin (5, 12))

Winning dance 2.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `H` Blush `FF8FA0`, `I` Ink `1C1426`.

```
...IIIII.I.
..I11111I1I
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13H333H4I.
I532EFFE4I.
.I532EE25I.
..I55554I..
.IGI..IGGI.
```

#### goon_dance_3 (11 x 12, origin (5, 12))

Winning dance 3.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `H` Blush `FF8FA0`, `I` Ink `1C1426`.

```
.I.IIIII.I.
I1I11111I1I
.I1AAAAA1I.
IAABBDDBAAI
IAABBDDBAAI
.IABBBBBAI.
.I3ACCCA3I.
I13H333H31I
.I42EFFE4I.
.I532EE25I.
..I44534I..
..IGGIGGI..
```

#### goon_shiver (11 x 12, origin (5, 12))

Added: shiver, for the last 5 seconds of its turn: alternate worried and shiver every 60 ms.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAAAAAAAAAI
IAABBDDBAAI
.IABBDDBAI.
.I4ACCCA3I.
.I32232331I
.I433E4E35I
.I5332E25I.
..I45554I..
.IGGI.IGGI.
```

#### goon_taunt (11 x 12, origin (5, 12))

Added: taunt, when an enemy shot misses it by less than 24 pixels: 600 ms, a cheeky open grin.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `F` Tooth `FFFFFF`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...IIIII...
..I11111I..
.I1AAAAA1I.
IAABBBBBAAI
IAABBDDBAAI
.IABBDDBAI.
.I3ACCCA3I.
I13233334I.
I533EFFE4I.
.I532EE251I
..I45554I..
.IGGI.IGGI.
```

#### goon_flip_1 (11 x 12, origin (5, 12))

Backflip 1 of 4: the rising frame turned 0 quarter turns backwards (anticlockwise facing right). 90 ms each, centred on the arc; frames 2 and 4 are 11 x 9 inside the outline, turned, so they overhang the body sideways by 1 pixel each side.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.I.IIIII.I.
I1I11111I1I
.I1AAAAA1I.
IAABBDDBAAI
IAABBDDBAAI
.IABBBBBAI.
.I3ACCCA3I.
I132223331I
.I4333EE4I.
.I5333225I.
..I45554I..
..IGI.IGI..
```

#### goon_flip_2 (13 x 10, origin (6, 10))

Backflip 2 of 4: the rising frame turned 1 quarter turns backwards (anticlockwise facing right). 90 ms each, centred on the arc; frames 2 and 4 are 11 x 9 inside the outline, turned, so they overhang the body sideways by 1 pixel each side.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.I.II..I.....
I1IAAII1II...
.I1AAA3345II.
I1ABBBA3E24GI
I1ADDBC3E25I.
I1ADDBC2335I.
I1ABBBC2335I.
I1ABBBA2334GI
.I1AAA3345I..
I1IAAII1I....
```

#### goon_flip_3 (11 x 12, origin (5, 12))

Backflip 3 of 4: the rising frame turned 2 quarter turns backwards (anticlockwise facing right). 90 ms each, centred on the arc; frames 2 and 4 are 11 x 9 inside the outline, turned, so they overhang the body sideways by 1 pixel each side.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
...I...I...
..IGIIIGI..
..I45554I..
.I5223335I.
.I4EE3334I.
I133322231I
.I3ACCCA3I.
.IABBBBBAI.
IAABDDBBAAI
IAABDDBBAAI
.I1AAAAA1I.
I1I11111I1I
```

#### goon_flip_4 (13 x 10, origin (6, 10))

Backflip 4 of 4: the rising frame turned 3 quarter turns backwards (anticlockwise facing right). 90 ms each, centred on the arc; frames 2 and 4 are 11 x 9 inside the outline, turned, so they overhang the body sideways by 1 pixel each side.

Legend: `1`-`5` tones of **Reds**, `A` Strap `3A3046`, `B` Lens `FFFFFF`, `C` Lens Shade `C9D6E6`, `D` Pupil `1C1426`, `E` Mouth `6A1E34`, `G` Boot `3A3046`, `I` Ink `1C1426`.

```
.....I..II.I.
...II1IIAAI1I
.II5433AAA1I.
IG4332ABBBA1I
.I5332CBBBA1I
.I5332CBDDA1I
.I52E3CBDDA1I
IG42E3ABBBA1I
..I5433AAA1I.
....I1IIAAI1I
```

### 3.2 Team marks (the second way to tell teams apart)

Drawn after the goon, with the mark's origin at (goon x, head top + 1), where **head top** is the first row of the goon picture that is not `.` or `I` in its middle column (column 5, or column 5 of the mirrored picture). So the mark's last row sits on the top row of the head, and it bobs with the breathing frame. On the turned backflip frames, leave the mark off. The four shapes differ in silhouette (a stalk, spikes, a flat brim, two bumps) so they work with no colour at all.

#### mark_reds (7 x 6, origin (3, 6))

The Reds: an antenna with a red ball and a white glint. Every team mark is drawn after the goon with its origin on the goon's head top (see below).

Legend: `A` Ink `1C1426`, `B` Rocket Tip `E8483C`, `C` Lens `FFFFFF`, `I` Ink `1C1426`.

```
...I...
..IBI..
.IBCBI.
..IBI..
..IAI..
..IAI..
```

#### mark_blues (8 x 5, origin (4, 5))

The Blues: a three spike tuft, in the team tones (tone 1 and 3), tilted back.

Legend: `1`-`5` tones of **Blues**, `I` Ink `1C1426`.

```
..I.I.I.
.I3I3I3I
.I3I3I3I
I3333I3I
.I33333I
```

#### mark_teals (8 x 5, origin (4, 5))

The Teals: a tiny top hat in Ink with a gold band.

Legend: `A` Ink `1C1426`, `B` Good `FFC23A`, `I` Ink `1C1426`.

```
..IIII..
.IAAAAI.
.IAAAAI.
.IABBAI.
IAAAAAAI
```

#### mark_grapes (9 x 3, origin (4, 3))

The Grapes: two round ears, in the team tones.

Legend: `1`-`5` tones of **Grapes**, `I` Ink `1C1426`.

```
.II...II.
I33III33I
I3333333I
```

### 3.3 Held weapons (drawn over the `aim` frame)

The **aim pivot** is the goon origin + (3, -5) facing right, or + (-3, -5) facing left. A held weapon's origin goes on the pivot. The bazooka and the shotgun turn to the aim angle in 64 steps (section 0); the aim runs from straight down to straight up, 33 of the 64 steps. The grenade, the dynamite and the radio are held still in the hand.

#### held_bazooka (12 x 6, origin (3, 3))

Held bazooka, 10 x 4 (12 x 6 with its outline). Pivot (3, 3): the grip, which sits on the goon's aim pivot. Turned to the aim angle in 64 steps, nearest neighbour.

Legend: `A` Tube Light `A4C060`, `B` Ink `1C1426`, `C` Tube `6E8A3A`, `D` Rocket Tip `E8483C`, `E` Ink `1C1426`, `I` Ink `1C1426`.

```
.IIIIIIIIII.
IAAAAAAAAABI
ICCCCCCCCCBI
ICCCDDCCCCBI
.IIEEIIIIII.
...II.......
```

#### held_grenade (6 x 7, origin (2, 4))

Held grenade, in the hand at the pivot (not turned).

Legend: `1`-`5` tones of **Grenade**, `A` Pin `D8DEE6`, `B` Pin `D8DEE6`, `I` Ink `1C1426`.

```
..II..
.IABI.
I3333I
I3233I
I3333I
.I33I.
..II..
```

#### held_dynamite (5 x 8, origin (2, 6))

Held dynamite (not turned).

Legend: `1`-`5` tones of **Stick**, `A` Fuse `C8A070`, `I` Ink `1C1426`.

```
..I..
.IAI.
.IAI.
I333I
I313I
I333I
I333I
.III.
```

#### held_shotgun (13 x 5, origin (2, 2))

Held shotgun, 11 x 3 (13 x 5). Pivot (2, 2). Turned to the aim angle.

Legend: `A` Pin `D8DEE6`, `B` Wood `8A5A30`, `C` Radio `3A3046`, `I` Ink `1C1426`.

```
.IIIIIIIIIII.
IAAAAAAAAAAAI
IBBBBBCCCCCCI
IBBIIIIIIIII.
.II..........
```

#### held_radio (6 x 7, origin (2, 5))

Held radio for the air strike (not turned).

Legend: `A` Pin `D8DEE6`, `B` Radio `3A3046`, `C` Flare `FF4FA0`, `I` Ink `1C1426`.

```
.I....
IAI...
IAII..
IBBBI.
IBCBI.
IBBBI.
.III..
```

### 3.4 Shots and things in the world

The rocket is long, white and finned, and turns to its heading; the grenade is small, round, green and has a pin; the dynamite is a tall red stick with a white band and a sparking fuse. They differ in size and silhouette, not only colour.

#### rocket (11 x 7, origin (5, 3))

Bazooka rocket, 9 x 5 (11 x 7), pointing right with the fins at the back. Origin (5, 3): its centre. Turned to its heading in 64 steps.

Legend: `A` Rocket `F4F4F0`, `B` Rocket Tip `E8483C`, `C` Rocket Tip `E8483C`, `I` Ink `1C1426`.

```
.I.........
IBIIIIIII..
IBBAAAAACI.
IBBAAAAACCI
IBBAAAAACI.
IBIIIIIII..
.I.........
```

#### exhaust_0 (4 x 3, origin (4, 1))

Exhaust A, 4 x 3, drawn behind the rocket's tail (turned with it).

Legend: `1`-`5` tones of **Blast**.

```
..12
1233
..12
```

#### exhaust_1 (4 x 3, origin (4, 1))

Exhaust B. Alternate every 50 ms.

Legend: `1`-`5` tones of **Blast**.

```
...1
.123
...1
```

#### grenade (6 x 7, origin (3, 7))

Grenade, 4 x 5 inside a 6 x 7 picture. Round, with a pin on top: told from the rocket by shape. Origin (3, 7): bottom middle. Not turned. The game draws its seconds above it (1x, Text with Outline, 3 pixels above).

Legend: `1`-`5` tones of **Grenade**, `A` Pin `D8DEE6`, `B` Pin `D8DEE6`, `I` Ink `1C1426`.

```
..II..
.IABI.
I3333I
I3123I
I3333I
.I33I.
..II..
```

#### dynamite (7 x 10, origin (3, 10))

Dynamite, 5 x 8 (7 x 10). A white band. Origin (3, 10).

Legend: `1`-`5` tones of **Stick**, `A` Fuse `C8A070`, `B` Rocket `F4F4F0`, `I` Ink `1C1426`.

```
...I...
..IAI..
.IAIII.
I33333I
I31113I
I33333I
I3BBB3I
I33333I
I33333I
.IIIII.
```

#### fuse_spark_0 (3 x 3, origin (1, 1))

Fuse spark A, at the tip of the fuse.

Legend: `A` Good `FFC23A`, `B` Flash `FFFFFF`.

```
.A.
ABA
.A.
```

#### fuse_spark_1 (3 x 3, origin (1, 1))

Fuse spark B. Alternate every 60 ms.

Legend: `A` Good `FFC23A`, `B` Flash `FFFFFF`.

```
A.A
.B.
A.A
```

#### muzzle_0 (5 x 3, origin (0, 1))

Shotgun muzzle flash A, at the barrel tip (turned with the gun), 60 ms.

Legend: `1`-`5` tones of **Blast**.

```
.12..
12221
.12..
```

#### muzzle_1 (5 x 3, origin (0, 1))

Muzzle flash B, 60 ms, then gone.

Legend: `1`-`5` tones of **Blast**.

```
..1..
.1231
..1..
```

#### flare_0 (5 x 9, origin (2, 9))

Air strike flare, 3 x 7 (5 x 9), stuck in the ground. Origin (2, 9).

Legend: `A` Flare `FF4FA0`, `B` Flare Hot `FFD0E8`, `C` Radio `3A3046`, `I` Ink `1C1426`.

```
..I..
.IAI.
IABAI
.IAI.
.ICI.
.ICI.
.ICI.
.ICI.
..I..
```

#### flare_1 (5 x 9, origin (2, 9))

Flare B (the light swells). Alternate every 150 ms.

Legend: `A` Flare `FF4FA0`, `B` Flare Hot `FFD0E8`, `C` Radio `3A3046`, `I` Ink `1C1426`.

```
.III.
IAAAI
IABAI
IAAAI
.ICI.
.ICI.
.ICI.
.ICI.
..I..
```

#### missile (5 x 9, origin (2, 9))

Air strike missile, 3 x 7 (5 x 9), drawn nose down as it falls (fins on top). Origin (2, 9): one row below the nose tip, so it is the point that touches the ground. Not turned.

Legend: `A` Rocket Tip `E8483C`, `B` Rocket `F4F4F0`, `C` Rocket Tip `E8483C`, `I` Ink `1C1426`.

```
.I.I.
ICICI
.IBI.
IBBBI
IBBBI
IBBBI
IAAAI
.IAI.
..I..
```

#### mine_0 (9 x 6, origin (4, 6))

Mine, cold: 7 x 4 (9 x 6). Origin (4, 6) on the ground.

Legend: `1`-`5` tones of **Metal**, `A` Mine Off `6A2A2A`, `I` Ink `1C1426`.

```
....I....
..IIAII..
.I33333I.
I3333333I
I4444444I
.IIIIIII.
```

#### mine_1 (9 x 6, origin (4, 6))

Mine, armed, light on. Alternate mine_1 and mine_0 every 200 ms once a goon is within 20 pixels.

Legend: `1`-`5` tones of **Metal**, `A` Mine Light `FF3A3A`, `B` Mine Light `FF3A3A`, `I` Ink `1C1426`.

```
...III...
..IBABI..
.I33333I.
I3333333I
I4444444I
.IIIIIII.
```

### 3.5 Crates and the parachute

The two crates differ in **material and symbol**: health is a white box with a big red cross, weapons is a wooden box with planks and a gold star.

#### crate_health (14 x 14, origin (7, 14))

Health crate, 12 x 12 (14 x 14 with its outline), a white box with a big red cross. Origin (7, 14) on the ground.

Legend: `A` Health `F6F6F2`, `B` Ink `1C1426`, `C` Cross `E8483C`, `D` Health Shade `C8CCD6`, `I` Ink `1C1426`.

```
.IIIIIIIIIIII.
IBBBBBBBBBBBBI
IBAAAACCAAAABI
IBAAAACCAAAABI
IBAAAACCAAAABI
IBAAAACCAAAABI
IBCCCCCCCCCCBI
IBCCCCCCCCCCBI
IBAAAACCAAAABI
IBAAAACCAAAABI
IBDDDDCCDDDDBI
IBDDDDCCDDDDBI
IBBBBBBBBBBBBI
.IIIIIIIIIIII.
```

#### crate_weapon (14 x 14, origin (7, 14))

Weapon crate, 12 x 12 (14 x 14), a wooden box with a gold star: told from the health crate by shape (a star, not a cross) and by its wood.

Legend: `1`-`5` tones of **Crate**, `A` Star `FFD23A`, `B` Ink `1C1426`, `I` Ink `1C1426`.

```
.IIIIIIIIIIII.
IBBBBBBBBBBBBI
IB1111111111BI
IB2222AA2222BI
IB222AAAA222BI
IBAAAAAAAAAABI
IB3AAAAAAAA3BI
IB33AAAAAA33BI
IB33AAAAAA33BI
IB3AAA33AAA3BI
IB4AA4444AA4BI
IB4444444444BI
IBBBBBBBBBBBBI
.IIIIIIIIIIII.
```

#### chute_0 (18 x 10, origin (9, 10))

Parachute, open, 18 x 10. Origin (9, 10): where the cords meet the crate's top middle. The crate falls 1 pixel every 40 ms under it and sways 1 pixel left and right every 600 ms.

Legend: `A` Chute A `F6F6F2`, `B` Chute B `FF8A1E`, `C` Cord `3A3046`, `I` Ink `1C1426`.

```
....IIIIIIIIII....
..IIAABBAABBAAII..
.IAABBAABBAABBAAI.
IAABBAABBAABBAABBI
IIIIIIIIIIIIIIIIII
.C......C.......C.
..C.....C......C..
...C....C.....C...
....C...C....C....
.....C..C...C.....
```

#### chute_1 (18 x 10, origin (9, 10))

Parachute collapsing, as the crate lands: 150 ms, then it is gone.

Legend: `A` Chute A `F6F6F2`, `B` Chute B `FF8A1E`, `C` Cord `3A3046`, `I` Ink `1C1426`.

```
..................
..................
..................
.....IIIIIIII.....
...IIAABBAABII....
..IAABBAABBAABI...
..IIIIIIIIIIIII...
.....C..C..C......
......C.C.C.......
.......CCC........
```

### 3.6 Weapon icons

#### icon_bazooka (14 x 14, origin (0, 0))

Menu icon, 14 x 14, drawn on a Panel square.

Legend: `A` Tube Light `A4C060`, `C` Tube `6E8A3A`, `D` Rocket Tip `E8483C`, `E` Ink `1C1426`, `I` Rocket Tip `E8483C`.

```
..............
..............
..............
..........I...
.AAAAAAAAAII..
IAAAAAAAAAIII.
ICCCCCCCCCIII.
ICCDDCCCCCII..
.CCCCCCCCCI...
...EE.........
...EE.........
..............
..............
..............
```

#### icon_grenade (14 x 14, origin (0, 0))

Menu icon, 14 x 14, drawn on a Panel square.

Legend: `1`-`5` tones of **Grenade**, `A` Pin `D8DEE6`, `B` Pin `D8DEE6`, `I` Ink `1C1426`.

```
.....AA.......
....A..A......
.....BB.......
....IIII......
...I3333I.....
..I312333I....
..I322333I....
..I333333I....
..I333334I....
..I333344I....
...I3344I.....
....IIII......
..............
..............
```

#### icon_dynamite (14 x 14, origin (0, 0))

Menu icon, 14 x 14, drawn on a Panel square.

Legend: `1`-`5` tones of **Stick**, `A` Fuse `C8A070`, `B` Rocket `F4F4F0`, `I` Ink `1C1426`.

```
.......A......
......A.......
.....A........
....IIIII.....
....I333I.....
....I313I.....
....I333I.....
....IBBBI.....
....I333I.....
....I333I.....
....I333I.....
....I444I.....
....IIIII.....
..............
```

#### icon_shotgun (14 x 14, origin (0, 0))

Menu icon, 14 x 14, drawn on a Panel square.

Legend: `A` Pin `D8DEE6`, `B` Wood `8A5A30`, `C` Radio `3A3046`, `I` Ink `1C1426`.

```
..............
..............
..............
..............
AAAAAAAAAAAAA.
IIIIIIIIIIIII.
BBBBBCCCCCCCC.
BBBBBIIIIIIII.
BBB...........
BB............
..............
..............
..............
..............
```

#### icon_airstrike (14 x 14, origin (0, 0))

Menu icon, 14 x 14, drawn on a Panel square.

Legend: `A` Flare `FF4FA0`, `B` Flare Hot `FFD0E8`, `C` Rocket `F4F4F0`, `D` Rocket Tip `E8483C`, `I` Ink `1C1426`.

```
.I....I....I..
ICI..ICI..ICI.
ICI..ICI..ICI.
ICI..ICI..ICI.
IDI..IDI..IDI.
.I....I....I..
..............
..............
..............
......AA......
.....ABBA.....
......AA......
.......I......
.......I......
```

#### icon_selected (16 x 16, origin (1, 1))

The selected highlight: gold corner brackets, 16 x 16, round the 14 x 14 icon. They pulse (Gold for 300 ms, Flash for 100 ms).

Legend: `A` Good `FFC23A`.

```
AAAA........AAAA
A..............A
A..............A
A..............A
................
................
................
................
................
................
................
................
A..............A
A..............A
A..............A
AAAA........AAAA
```

### 3.7 Aiming: the reticle and the power dots

**Power** is not a bar: while fire is held, a line of **dots grows along the aim**, from the pivot outwards, so the eye never leaves the goon. There are 16 dot steps; dot `k` (0 to 15) is 2 x 1 pixels at distance `6 + 1.6k` from the pivot along the aim, 2 rows above the aim line (so it never covers the weapon), coloured `mix(Good, Hurt, k / 15)`: gold near the goon, hot red at full power. One more dot every 100 ms; full power after 1600 ms; release fires. The reticle stays at 28 pixels the whole time.

#### reticle_0 (9 x 9, origin (4, 4))

Reticle A, 9 x 9, centred 28 pixels from the aim pivot along the aim. White ring with an Ink centre: it reads on sky and on soil.

Legend: `A` Flash `FFFFFF`, `B` Ink `1C1426`.

```
...AAA...
.A.....A.
.........
A...B...A
A..BBB..A
A...B...A
.........
.A.....A.
...AAA...
```

#### reticle_1 (9 x 9, origin (4, 4))

Reticle B (a breath out). Alternate every 300 ms.

Legend: `A` Flash `FFFFFF`, `B` Ink `1C1426`.

```
..AAAAA..
.A.....A.
A.......A
A...B...A
A..B.B..A
A...B...A
A.......A
.A.....A.
..AAAAA..
```

### 3.8 Death: the halo and the gravestone

#### halo (7 x 3, origin (3, 1))

Halo, 7 x 3. Rises from the goon's head, see 4.

Legend: `A` Good `FFC23A`.

```
.AAAAA.
A.....A
.AAAAA.
```

#### gravestone (10 x 11, origin (5, 11))

Gravestone, 8 x 9 (10 x 11). Origin (5, 11) on the ground where the goon stood. A small team mark is drawn on it (the team's mark sprite, origin on its top, 2 pixels down). It stays and falls with the ground.

Legend: `1`-`5` tones of **Stone**, `A` Ink `1C1426`, `I` Ink `1C1426`.

```
...IIII...
..I3333I..
.I311113I.
I31222213I
I32AAAA23I
I32AIIA23I
I32AAAA23I
I32222223I
I33333333I
I44444444I
.IIIIIIII.
```

### 3.9 Icons over a goon, and the squeal bubble

One icon at a time, origin at (goon x, health number top - 4). Priority: skull, alert, think, heart.

#### ico_heart (7 x 7, origin (3, 7))

Icon: healed. Floats 4 pixels above the goon's health number.

Legend: `A` Heart `FF5A7A`, `I` Ink `1C1426`.

```
..I.I..
.IAIAI.
IAAAAAI
IAAAAAI
.IAAAI.
..IAI..
...I...
```

#### ico_alert (4 x 8, origin (2, 8))

Icon: ! (a shot is coming, or it is this goon's turn).

Legend: `A` Alert `FFD23A`, `I` Ink `1C1426`.

```
.II.
IAAI
IAAI
IAAI
IAAI
.II.
IAAI
.II.
```

#### ico_think (7 x 8, origin (3, 8))

Icon: ? (the computer is thinking: it bobs 1 pixel every 300 ms).

Legend: `A` Think `FFFFFF`, `I` Ink `1C1426`.

```
.IIII..
IAAAAI.
.IIIAAI
..IAAI.
..IAI..
...I...
..IAI..
...I...
```

#### ico_skull (7 x 7, origin (3, 7))

Icon: doomed (health under 10, or on its way into the water).

Legend: `A` Skull `F6F6F2`, `B` Ink `1C1426`, `I` Ink `1C1426`.

```
..III..
.IAAAI.
IAAAAAI
IABABAI
IAAAAAI
.IAIAI.
..I.I..
```

#### bubble_oof (21 x 12, origin (2, 12))

Squeal bubble plate, 21 x 12 (for 3 letters: OOF, AAA, EEK, YAY). The word is drawn in the 5 x 7 font at 1x, Ink, at (3, 1) inside it. Wider words: 6 pixels more per letter. Origin (2, 12): the tail tip, at the goon's head top + (3, -2).

Legend: `A` Bubble `FFFFFF`.

```
.AAAAAAAAAAAAAAAAAAA.
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAA
.AAAAAAAAAAAAAAAAAAA.
..AA.................
..A..................
```

## 4. Animation recipes

| What | Frames | Timing | Movement |
|---|---|---|---|
| Idle | `idle_1`, `idle_2` | 600 ms each | none (the head drops 1 pixel in `idle_2`) |
| Blink | `blink` | 100 ms, every 2.5 to 4 s |  |
| Fidget | `look_back` | 700 ms, every 5 to 9 s |  |
| Walk | `walk_1` to `walk_4` | a frame every 3 pixels | the game's walk speed (1 pixel every 40 ms suggested); it steps up slopes of 3 pixels or less |
| Hop | `jump_rise`, `jump_fall`, `land` | land 120 ms | the physics arc; 4 dust pixels on landing |
| Backflip | `flip_1` to `flip_4` | 90 ms each | the higher arc, backwards; then `jump_fall` |
| Hit | `flinch` then `fly_1`, `fly_2` | 250 ms, then 80 ms each | thrown by the explosion; a squeal bubble for 700 ms if it lost 10 or more |
| Damage number | text | rise 1 pixel every 40 ms for 24 pixels | starts 6 pixels above the health number; the last 200 ms in Smoke tone 3, then gone |
| Dying | `ico_skull` 600 ms, `alarm_1` 200, `alarm_2` 200 (6 up), `alarm_3` 150 | 1150 ms | then a puff, see below |
| Puff | 8 Smoke discs of radius 2 | tone 1 to 5, a tone every 80 ms | round the goon's middle, drifting up 1 pixel every 60 ms |
| Gravestone | `gravestone` | rises out of the ground 1 pixel every 55 ms (600 ms) | clipped at the ground line, origin where the feet were; stays, and falls with the ground |
| Halo | `halo` | rises 1 pixel every 40 ms from the head top for 16 pixels, then bobs 1 pixel every 400 ms | ends 4 pixels above the gravestone and stays with it |
| Sinking | `sink` | 1 pixel every 60 ms for 12 pixels | a splash on entry, 3 bubbles after |
| Win dance | `dance_1` 2 3 2 | 150 ms each | a 2 pixel hop on frame 3 |
| Parachute | `chute_0` over the crate | falls 1 pixel every 40 ms | sways 1 pixel every 600 ms; on landing `chute_1` 150 ms, then a wobble: x +1, -1, +1, 0 at 60 ms each |
| Crate sparkle | one Flash pixel with 4 Gold tone 2 arms | 100 ms, every 600 ms | at a random corner pixel of the crate |
| Rocket exhaust | `exhaust_0`, `exhaust_1` | 50 ms each | behind the tail, turned with the rocket |
| Rocket trail | Smoke discs radius 1.5 | one every 50 ms at the tail | each ages a tone every 120 ms (1 to 5), then is gone; at most 12 |
| Grenade | `grenade` | bounces | its seconds above it; the last second in Warn |
| Fuse | `fuse_spark_0`, `_1` | 60 ms each | at the fuse tip |
| Flare | `flare_0`, `_1` | 150 ms each | missiles arrive 800 ms after it lands |
| Air strike | 5 `missile` | 60 ms apart | 12 pixels apart, centred on the flare, from row -9, falling 4 pixels a frame |
| Mine | `mine_0`, `mine_1` | 200 ms each once a goon is within 20 pixels |  |
| Reticle | `reticle_0`, `_1` | 300 ms each |  |
| Selected icon | `icon_selected` | Gold 300 ms, Flash 100 ms |  |
| Think icon | `ico_think` | bobs 1 pixel every 300 ms | while the computer thinks |

## 5. Screens (384 x 240)

### 5.1 Panels

A **panel** at (x, y, w, h) is a `Panel` rectangle with a 1 pixel `Panel Rule` line on its second row and its second last row (columns x + 1 to x + w - 2), and its 4 corner pixels left out (the picture shows through, so it looks rounded). A **framed** panel also has a 1 pixel border in the frame colour on its outer edge (corners still left out). Panels are drawn over the picture, which is redrawn under them when they go.

### 5.2 In game

The HUD keeps to the top corners and the bottom middle, so the middle of the map is clear.

- **Timer**: panel (4, 4, 30, 24) framed in `Accent`. The seconds at 2x, centred in the panel, y 9, in `Text` (from 10 down: `Warn`, see 5.5). During the retreat time it shows the retreat seconds in `Label`.
- **Active goon**: panel (38, 4, 92, 24). The goon's name at 1x, its team tone 2, at (44, 8). The team name (`REDS`, `BLUES`, `TEALS`, `GRAPES`) at 1x in `Label` at (44, 18). The weapon's menu icon with its top left at (112, 7).
- **Wind**: panel (296, 4, 84, 24). `WIND` at 1x in `Label` at (302, 8). Ten 3 x 5 chevrons on row 18, chevron `i` (0 to 9) at x `304 + 4i`; they point the way the wind blows (`>` shape `#..`, `.#.`, `..#`, `.#.`, `#..` for right, mirrored for left). `|wind|` of them are lit, counted from the right end for a wind to the left and from the left end for a wind to the right; lit chevron `i` is `mix(Good, Hurt, i / 9)`, unlit ones are `Panel Rule`.
- **Team bars**: panel (124, 222, 136, 18), over the water. Team `t` (0 to 3, in turn order) has a 2 row bar from x 130, rows `225 + 3t` and `226 + 3t`, `round(total / 400 * 120)` pixels long, where total is the sum of its goons' health. Row 1 in team tone 2, row 2 in tone 3, with a **pattern per team** so they are told apart without colour: Reds plain; Blues every 4th column in tone 4; Teals alternating columns of tone 2 and 3 on both rows; Grapes columns 4 and 5 of every 6 in tone 4. A bar shrinks 1 pixel every 20 ms after damage.
- **Over each goon**: its health at 1x in its team tone 2 with Outline, centred on the goon x, with its top 14 rows above the head top. The active goon also has its name at 1x in team tone 1 with Outline, top 24 rows above the head top. During a turn the active goon has an `ico_alert` for its first 600 ms.
- **Power**: the dots along the aim (3.7), no separate bar.
- **Grenade and dynamite timers**: the seconds at 1x, `Text` with Outline, centred, 3 rows above the shot.

### 5.3 Weapon menu

Opened with **Tab** on the active goon's turn; Left and Right choose; Space or Enter takes it; Tab or Escape closes it. The game is paused while it is open (the timer stops).

- Panel (143, 34, 98, 40), framed in `Accent`, just below the HUD and centred.
- Icon `i` (0 to 4) in the order bazooka, grenade, dynamite, shotgun, air strike, top left at `(150 + 18i, 41)`. A weapon with no ammo left is drawn with every pixel replaced by `Panel Rule`.
- `icon_selected` with its top left at `(149 + 18i, 40)` round the chosen one.
- The chosen weapon's name at 1x in `Text`, centred on the panel (x `143 + (98 - width) / 2`), y 61: `BAZOOKA` (41 wide), `GRENADE` (41 wide), `DYNAMITE` (47 wide), `SHOTGUN` (41 wide), `AIR STRIKE` (59 wide). With ammo counts (from a crate), add ` X2` and so on after the name.

### 5.4 Title (see `blast-buddies-preview-title.png`)

- The Meadow sky and a sample landscape with no holes, water frames running. Four goons standing on the hills, being silly: Reds `dance_1` at x 60, Blues `grin` at x 90 (mirrored), Teals `taunt` at x 236, Grapes `dance_3` at x 266 (mirrored), each cycling its frames.
- `BLAST` at 5x, gradient `Title Top` to `Title Bottom` with Outline, x 119 (centred, 145 wide), y 34.
- `BUDDIES` at 5x, the same, x 89 (centred, 205 wide), y 76.
- Hint panel at (45, 196, 293, 30).
- `ARROWS WALK AND AIM   ENTER JUMPS   SPACE FIRES` at 1x, `Label`, x 51 (centred, 281 wide), y 201.
- `PRESS SPACE` at 1x, `Text`, x 159 (centred, 65 wide), y 213, blinking 500 ms on and 500 ms off.
- **Animation** (it loops every 8 s): at 1500 ms a rocket comes in from the left at row 120, climbing on an arc, with its trail, and hits the top right corner of the last S of BUDDIES at (294, 80) at 2700 ms. That is a radius 12 explosion recipe (section 6.1) with the shake, and it leaves a bite: every title pixel within 7 of (294, 80) goes back to sky, those 7 to 8.5 away become Smoke tone 5, and 8.5 to 10 away Blast tone 4 (the title's scorch). 10 Blast tone 2 sparks at distance 14 and 10 Smoke tone 2 puffs at 18 hang round it for 1 s. The goons all play `alarm_1` for 400 ms, then `grin`. The bite stays until the loop starts again.

### 5.5 The turn

- **Turn banner** (1000 ms, at the start of every turn): panel (0, 96, 384, 40) with `Accent` rows 96 and 135 across the whole width. The goon's name at 3x in its team tone 1 with Outline, centred, y 101. Under it, `REDS TURN` (and so on) at 1x in `Label`, centred, y 125. For a computer team, `REDS TURN   COMPUTER`. The goon already shows `ico_alert`. The timer starts when the banner goes.
- **Timer warning** (the last 10 seconds): the digits turn `Warn`; the timer frame alternates `Accent` and `Warn` every 500 ms; on each new second the digits are drawn 1 pixel higher for 100 ms (a tick). In the last 5 seconds the active goon shivers (3.1). The picture itself is not tinted (section 6.2).
- **Retreat**: after firing, the timer shows the retreat seconds in `Label` (3 suggested); the aim dots and the reticle go.

### 5.6 A goon dying, and a team eliminated

- **Dying** goons are resolved one at a time when every shot has settled, in turn order: the skull, the alarm frames, the puff, the gravestone and the halo (section 4), 1.5 s each.
- **Team eliminated**: the banner panel of 5.5, for 1500 ms. `BLUES ARE OUT` (any team) at 2x in that team's tone 1 with Outline, centred (`BLUES ARE OUT` is 154 wide), y 106. Under it, `ALL BUDDIES DOWN` at 1x in `Label`, centred, y 125.

### 5.7 Winner and draw (see `blast-buddies-preview-over.png`)

- The last picture of the map stays, mixed 35% toward Ink `1C1426` (drawn once). The winning team's goons, drawn after the dim, play the win dance.
- Panel (0, 60, 384, 64) with `Accent` on rows 60, 61, 122 and 123 across the width.
- `TEALS WIN` at 3x, gradient `Title Top` to `Good` with Outline, x 112 (centred, 159 wide), y 70.
- `TAD AND LOU STILL STANDING` at 1x, `Label`, x 114 (centred, 155 wide), y 98 (the names of the goons left, joined by AND, or `ONE BUDDY STANDING` style lines when there are more than two: `3 BUDDIES STILL STANDING`).
- `PRESS SPACE` at 1x, `Text`, x 159 (centred, 65 wide), y 110, blinking 500 / 500.
- **Draw** (the last goons of every team die together): the same panel. `NOBODY WINS` at 3x, gradient `Label` to `Smoke` tone 4 with Outline, centred (195 wide), y 70. `EVERY BUDDY WENT BOOM` at 1x in `Label`, centred (125 wide), y 98. `PRESS SPACE` as above. No dance: the gravestones and halos stay in the picture.

### 5.8 Paused

The picture freezes (no dim). The banner panel of 5.5: `PAUSED` at 3x in `Text` with Outline, centred (105 wide), y 101; `P TO PLAY ON   ESC TO QUIT` at 1x in `Label`, centred (155 wide), y 125.

### 5.9 The first five seconds of a match

1. 0 ms: the sky, the water and the terrain are drawn at once (no slow build).
2. From 300 ms the goons arrive by **parachute**, one every 150 ms in turn order, each from row -12 under a `chute_0`, falling 2 pixels a frame, so the whole cast lands within about 3 s. On landing: `chute_1` for 150 ms, 4 dust pixels, `land` for 120 ms, then `grin` for 400 ms.
3. When the last goon has landed, every goon plays `look_back` for 300 ms at the same time (they size each other up), then idle.
4. The first turn banner.

## 6. Effects

### 6.1 The explosion recipe

For a blast of radius `r` at (cx, cy), with `t` the time since it went off. All of it is pixels; nothing is blended.

1. **Flash**, 0 to 33 ms (2 frames): every pixel within `0.8r` in `Flash`.
2. **Fireball**, from 33 ms: radius `R = r * min(1, 0.5 + (t - 33) / 134)` (it grows from half size to full in 134 ms), and from 160 ms it shrinks: `R = R * max(0.3, 1 - (t - 160) / 400)`. A pixel at `d = distance / R` is band 0 (`d < 0.35`), 1 (`< 0.6`), 2 (`< 0.85`) or 3 (`<= 1`), and from 100 ms every band moves one cooler every 60 ms (`band + floor((t - 100) / 60)`), using Blast tones 1 to 5 for bands 0 to 4; band 5 or more is not drawn. It is gone by about 400 ms.
3. **Shock ring**, from 33 ms: 60 pixels at every 6 degrees, at radius `r + 2 + (t - 33) / 20`, in Blast tone 2, until 250 ms.
4. **Debris**: the terrain's own colours (`top2`, `soil`, `soil_speck`, `deep`, `top1` in turn), each thrown out at a random angle between 200 and 340 degrees (upwards), 1.5 to 3.5 pixels a frame, gravity 0.15 pixels a frame per frame; every third piece is 2 pixels wide. Count: **24 for r 12, 40 for r 20, 60 for r 30** (plus the crumbs from the crumb rule, one pixel each). A piece is gone when it lands on solid ground (it does not stick) or reaches the water.
5. **Smoke**: from 200 ms, `round(r / 4)` discs of radius 2.5 in a row above the hole (from `cx - r * 0.6`, 6 pixels apart, at `cy - r - 6`, every other one 3 higher), Smoke tone 2, ageing a tone every 150 ms and rising 1 pixel every 60 ms, gone after tone 5.
6. **Scorch** on the terrain: section 2.3 (the glow, then the cool down).
7. **Shake**: r 30 moves the whole picture by 2 pixels for 5 frames (+2, -2, +1, -1, 0 on x, and +1, -1, 0, 0, 0 on y); r 20 by 1 pixel for 3 frames (+1, -1, 0 on x); r 12 does not shake. The HUD does not shake.

| Radius | Flash | Debris | Smoke discs | Shake | Use |
|---|---|---|---|---|---|
| 12 | 0.8r = 10 | 24 | 3 | none | grenade bounce hits, air strike missiles, mines, shotgun (at 0.5r) |
| 20 | 16 | 40 | 5 | 1 px, 3 frames | bazooka, grenade |
| 30 | 24 | 60 | 8 | 2 px, 5 frames | dynamite |

### 6.2 Keep, drop, add

| Effect | Verdict | Recipe |
|---|---|---|
| Explosion | keep (the star) | 6.1 |
| Dust on landing | keep | 4 pixels of `top1` and `top2`, 2 each side of the feet, moving out 1 pixel a frame and up 1 for 4 frames, then gone. Only after a fall of 6 pixels or more. |
| Rocket smoke trail | keep | section 4 |
| Fuse sparks | keep | `fuse_spark_0` and `_1`, plus one Blast tone 2 pixel thrown up 1 to 2 pixels every 120 ms |
| Splash and bubbles | keep | section 2.6 |
| Damage numbers | keep | 1x in `Hurt` (healing in `Good` with a `+`) with Outline; section 4 |
| Squeal bubble | keep | `bubble_oof` with OOF, AAA, EEK or YOW (random) for 700 ms; YAY for a heal |
| Halo and gravestone | keep | section 4 |
| Crate sparkle | keep | section 4 |
| Crate landing wobble | keep | section 4 |
| Drifting clouds | keep | section 2.5 |
| Shotgun tracer | keep | from the muzzle to the hit: frame 1 every pixel in `Flash`, frame 2 every other pixel in Blast tone 2, then gone. Each shot. |
| Whole picture tint, last 10 s | **drop** | it would change every pixel; the timer warning in 5.5 and the shiver do the job |
| Wind streaks | add | when `|wind| >= 6`, 4 lines of 3 pixels in `cloud` drift across the sky at 3 pixels a frame in the wind's direction, only above row 100 |
| Near miss taunt | add | the `taunt` frame, section 3.1 |
| Shiver | add | section 3.1 |
| Parachute arrival | add | section 5.9 |
| Off screen arrow | add | section 2.7 |
| Water glints | add | every 400 ms one random `foam` pixel on rows 230 to 238 for 200 ms (at most 3 at a time) |

## 7. Budgets

- **Particles**: the worst case is a dynamite blast: 60 debris, up to 24 crumbs, 8 smoke discs and the 60 pixel ring (which is drawn, not simulated): about 92 moving things, under the 120 of the brief. Two blasts at once (an air strike) are 5 x r 12: 5 x 24 = 120 debris, which is the limit, so the air strike's missiles throw **16** debris each, not 24.
- **Redraw**: the sky is baked once per map (gradient, sun and far hills in one picture). Each frame only redraws the boxes of what moved or changed: clouds, the water strip (rows 222 to 239, 384 x 18), goons, shots, particles and the HUD numbers that changed. The terrain is redrawn only in the re-shade box of a new hole and in the scorch rings while they cool. The shake is the one whole picture move, a few frames at a time.
- **Colours**: every sprite uses 16 colours or fewer; the goons use 14 (5 tones and 9 letters).

## 8. Checks

- **Sprite check**: every pixel of every sprite is `.` or in its legend, no legend is over 16 colours, and every goon frame (not counting the turned backflip) fits 9 x 11 inside its outline. Result: no problems.
- **Contrast** (WCAG ratio, higher is better; 4.5 is the usual line for text):

| Foreground | Background | Ratio |
|---|---|---|
| Text | Panel | 17.8 |
| Label | Panel | 8.5 |
| Warn | Panel | 5.3 |
| Good | Panel | 11.1 |
| Accent | Panel | 8.4 |
| Ink | Bubble | 17.8 |
| Reds tone 2 (names, numbers) | Panel | 6.8 |
| Blues tone 2 (names, numbers) | Panel | 6.7 |
| Teals tone 2 (names, numbers) | Panel | 9.1 |
| Grapes tone 2 (names, numbers) | Panel | 6.8 |
| Goon outline or lens, Meadow | worst: water | 4.6 |
| Goon outline or lens, Canyon | worst: deep | 5.2 |
| Goon outline or lens, Candy | worst: edge | 5.2 |

The goon rows take, for each theme, the better of the Ink outline and the white lens against every terrain band, the sky, the clouds and the water, and report the worst of those: a goon never has less than 4.6 to 1 on its edge against anything it can stand in front of. Against an explosion, the Ink outline is at least 7.6 to 1 on Blast tones 1 to 3 (the inner bands of the fireball), and the white lens carries it on the darker outer bands.
- **Colour blindness** (`blast-buddies-colour-check.png`, Machado 2009 at full strength): under deuteranopia and protanopia the Reds and the Teals turn into similar greys, and the Blues and the Grapes into similar blues. That is why every team has a mark of its own shape (antenna, tuft, top hat, ears) and every team bar a pattern of its own. The health crate (cross on white) and the weapon crate (star on wood), and the rocket (long, finned) and the grenade (round, pinned) differ in shape and stay apart in all three. Under tritanopia the Blast ramp turns pink, but the flash, the ring and the smoke still read as an explosion.
- **Many holes** (`blast-buddies-holes.png`): 16 random blasts of radius 12, 20 and 30 on each theme. Every cut face gets its edge lip and scorch, the crumb rule leaves no specks in the air, and the larger floating pieces read as islands with a grass top and a lit underside.
- **2x**: the smallest carriers of meaning are the 2 x 2 pupil, the team marks (at least 3 pixels in each direction), the power dots (2 x 1 each, but read as a line) and the 3 x 5 wind chevrons. No single pixel carries meaning alone.

## 9. What I decided and why

- **Name**: kept **Blast Buddies**, and the creatures are **buddies** on screen (`ALL BUDDIES DOWN`). It is friendly, it says what happens, and every letter is in the font. The internal word "goon" stays in this file and the code.
- **Teams**: Reds, Blues, Teals and Grapes (purple). No yellow team, because a yellow round body with goggles is the thing the brief warns against. Each also has a mark: antenna, tuft, top hat, ears. Gold is kept for good news.
- **One lens, no overalls**: a single big lens on a dark strap is the face; the body is one colour row, so the silhouette is a pill with a band across it, not a capsule in dungarees.
- **The weapon is a separate part** turned in 64 steps round a pivot (the brief's first option). It is less art, and an aim shown to 5.6 degrees is fairer than 9 poses.
- **Power as dots along the aim**, not a bar in the HUD: the eye stays on the goon and the reticle, and it shows the direction and the strength in one thing.
- **Hats as separate parts**: team marks are their own sprites drawn on the head top, so one goon set serves four teams and a mark can be swapped (or a hat added for fun later) without touching the goon frames.
- **The crumb rule** (pieces of 24 pixels or fewer fall away) is a **rule of the game**, not only art: the physics must turn them to air too, or a goon could stand on a speck the picture no longer shows. Please confirm.
- **Open edges**: leaving the sides counts as drowning. This is a rule change if the game planned walls.
- **Controls**: Left and Right walk, Up and Down aim, **Enter** hops and **Enter twice within 250 ms** backflips, hold **Space** to charge and release to fire, **Tab** opens the weapon menu, **P** pauses, **Escape** quits (from pause). The brief did not fix the keys; the title hint uses these.
- **No picture tint** in the last 10 seconds (it changes every pixel); the HUD warning and the shiver replace it.
- **Air strike debris** reduced to 16 a missile, to stay inside the particle budget.
- **Retreat time**: 3 seconds suggested; it only changes the timer colour, so any number works.
- **Shotgun hole**: half the radius 12 recipe (r 6, no smoke). The damage is the game's call.

Needs a decision from you: the crumb rule as a game rule, open edges, and the controls. Everything else can be changed in code without new art.

## 10. Sprite index

| Sprite | Size | Origin | Group |
|---|---|---|---|
| `goon_idle_1` | 11 x 12 | (5, 12) | goon |
| `goon_idle_2` | 11 x 12 | (5, 12) | goon |
| `goon_blink` | 11 x 12 | (5, 12) | goon |
| `goon_look_back` | 11 x 12 | (5, 12) | goon |
| `goon_worried` | 11 x 12 | (5, 12) | goon |
| `goon_grin` | 11 x 12 | (5, 12) | goon |
| `goon_walk_1` | 11 x 12 | (5, 12) | goon |
| `goon_walk_2` | 11 x 12 | (5, 12) | goon |
| `goon_walk_3` | 11 x 12 | (5, 12) | goon |
| `goon_walk_4` | 11 x 12 | (5, 12) | goon |
| `goon_jump_rise` | 11 x 12 | (5, 12) | goon |
| `goon_jump_fall` | 11 x 12 | (5, 12) | goon |
| `goon_aim` | 12 x 12 | (5, 12) | goon |
| `goon_flinch` | 11 x 12 | (5, 12) | goon |
| `goon_fly_1` | 11 x 12 | (5, 12) | goon |
| `goon_fly_2` | 11 x 12 | (5, 12) | goon |
| `goon_land` | 11 x 12 | (5, 12) | goon |
| `goon_alarm_1` | 11 x 12 | (5, 12) | goon |
| `goon_alarm_2` | 11 x 12 | (5, 12) | goon |
| `goon_alarm_3` | 11 x 12 | (5, 12) | goon |
| `goon_sink` | 11 x 12 | (5, 12) | goon |
| `goon_dance_1` | 11 x 12 | (5, 12) | goon |
| `goon_dance_2` | 11 x 12 | (5, 12) | goon |
| `goon_dance_3` | 11 x 12 | (5, 12) | goon |
| `goon_shiver` | 11 x 12 | (5, 12) | goon |
| `goon_taunt` | 11 x 12 | (5, 12) | goon |
| `goon_flip_1` | 11 x 12 | (5, 12) | goon |
| `goon_flip_2` | 13 x 10 | (6, 10) | goon |
| `goon_flip_3` | 11 x 12 | (5, 12) | goon |
| `goon_flip_4` | 13 x 10 | (6, 10) | goon |
| `mark_reds` | 7 x 6 | (3, 6) | marks |
| `mark_blues` | 8 x 5 | (4, 5) | marks |
| `mark_teals` | 8 x 5 | (4, 5) | marks |
| `mark_grapes` | 9 x 3 | (4, 3) | marks |
| `held_bazooka` | 12 x 6 | (3, 3) | held |
| `held_grenade` | 6 x 7 | (2, 4) | held |
| `held_dynamite` | 5 x 8 | (2, 6) | held |
| `held_shotgun` | 13 x 5 | (2, 2) | held |
| `held_radio` | 6 x 7 | (2, 5) | held |
| `rocket` | 11 x 7 | (5, 3) | shots |
| `exhaust_0` | 4 x 3 | (4, 1) | shots |
| `exhaust_1` | 4 x 3 | (4, 1) | shots |
| `grenade` | 6 x 7 | (3, 7) | shots |
| `dynamite` | 7 x 10 | (3, 10) | shots |
| `fuse_spark_0` | 3 x 3 | (1, 1) | shots |
| `fuse_spark_1` | 3 x 3 | (1, 1) | shots |
| `muzzle_0` | 5 x 3 | (0, 1) | shots |
| `muzzle_1` | 5 x 3 | (0, 1) | shots |
| `flare_0` | 5 x 9 | (2, 9) | shots |
| `flare_1` | 5 x 9 | (2, 9) | shots |
| `missile` | 5 x 9 | (2, 9) | shots |
| `mine_0` | 9 x 6 | (4, 6) | shots |
| `mine_1` | 9 x 6 | (4, 6) | shots |
| `crate_health` | 14 x 14 | (7, 14) | crates |
| `crate_weapon` | 14 x 14 | (7, 14) | crates |
| `chute_0` | 18 x 10 | (9, 10) | crates |
| `chute_1` | 18 x 10 | (9, 10) | crates |
| `icon_bazooka` | 14 x 14 | (0, 0) | icons |
| `icon_grenade` | 14 x 14 | (0, 0) | icons |
| `icon_dynamite` | 14 x 14 | (0, 0) | icons |
| `icon_shotgun` | 14 x 14 | (0, 0) | icons |
| `icon_airstrike` | 14 x 14 | (0, 0) | icons |
| `icon_selected` | 16 x 16 | (1, 1) | icons |
| `reticle_0` | 9 x 9 | (4, 4) | aim |
| `reticle_1` | 9 x 9 | (4, 4) | aim |
| `halo` | 7 x 3 | (3, 1) | death |
| `gravestone` | 10 x 11 | (5, 11) | death |
| `ico_heart` | 7 x 7 | (3, 7) | icons_over |
| `ico_alert` | 4 x 8 | (2, 8) | icons_over |
| `ico_think` | 7 x 8 | (3, 8) | icons_over |
| `ico_skull` | 7 x 7 | (3, 7) | icons_over |
| `bubble_oof` | 21 x 12 | (2, 12) | icons_over |
