# Asteroids: art and screen design, "Obsidian Line"

Designer's answer to the brief. It is meant to be pasted into code with no further decisions. Where I disagree with the brief or chose between options, it is listed in section 8.

## 0. Read this first

Conventions used everywhere below:

- The grid is 320 x 240 cells. Origin top left, x across, y down, in cells. 60 ticks a second.
- **Shape files** are point lists in local coordinates: origin at the shape's centre, x grows right, y grows down, nose points up (negative y), units are cells, decimals allowed.
- **How points join** is the first line of each block. `closed` means the points are joined in order and the last joins back to the first. `open` means joined in order, the last does not join back. `segments` means every line holds one separate segment as `x1, y1, x2, y2`. A block can hold several polylines: a new `closed` or `open` line starts the next one.
- **Rotation**: the ship has 64 headings. Step 0 is nose up, steps count clockwise on the screen, one step is 5.625 degrees. A local point `(x, y)` at heading `s` with `a = s * 5.625 degrees` becomes `(x cos a - y sin a, x sin a + y cos a)`. Add the object's position, then round each coordinate to the nearest integer cell (`floor(v + 0.5)`) before the line algorithm runs. Rocks and saucers use the same rotation for their slow spin.
- **Wrap**: when an object's bounding circle (the "extent" in the table in section 3.1) crosses an edge, draw it again offset by plus or minus 320 or 240. In a corner that is up to four draws.
- **Text** is the 5 x 7 capital font. A character advances 6 cells at 1x, 12 at 2x, 18 at 3x, so a string of `n` characters at scale `k` is `n * 6k - k` cells wide. Centred text uses `x = floor((320 - width) / 2)`. Coordinates for text are its top left cell.
- **Ticks** are given with seconds beside them. Scale them if your rate differs.

What is in the file:

1. Art direction and palette
2. Line style
3. Shapes: ship, flame, shield, rocks, saucers, shots
4. Break ups, bursts and hyperspace (recipes)
5. Screens: in game, title, wave start, game over, pause, the first seconds
6. Effects: keep, drop, add
7. Budgets
8. What I decided and why

## 1. Art direction and palette

### Idea

**Obsidian Line.** Black volcanic glass with hairline strokes. The screen is a near black with a barely visible vignette, and everything on it is drawn in a single thin line. The rocks are cool stone grey, dimmer when large and brighter when small, so the fast, dangerous fragments are the clearest things on the screen. The ship is champagne ivory with a warm glow, the only warm white in the game, so you can always find yourself. Anything that wants to hurt you is ember: red-orange saucers and their shots. There is no pink, violet or cyan, and almost no colour at all outside those three families. The result is quiet, graphic and a bit expensive: an arcade vector monitor remembered by someone with good taste.

### Colour roles (what is the same, what differs on purpose)

- **Rocks** differ by size on purpose: large `7F8EA3` (dim), medium `A9B6C8`, small `D6DEE9` (bright). All three are cool, so no rock is ever mistaken for the ship or a saucer.
- **The ship** is the only warm white: `FFF4DC`. Its glow and its shots are warm too.
- **Saucers** are the only ember: the large one is orange-red `FF7A4D`, the small one hotter `FF4040`. Their shots share their colour, so you know whose shot it is.
- **Text** is cool white with grey labels, so it never competes with the ship.
- **Gold** `FFE29A` is rare and always means "good": the shield ring, a saucer score pop-up, a new hi-score, an extra life.

### Palette

Background

| Name | Hex | Used for |
|---|---|---|
| Void Edge | `030508` | the vignette at the screen edge |
| Void Centre | `0B1119` | the vignette at the middle. Cell colour = blend of Void Centre and Void Edge by `min(1, d^2)`, where `d = sqrt(((x - 160) / 200)^2 + ((y - 120) / 150)^2)`. Baked once. |
| Dust Dim | `141B27` | far dust, and 40 baked static dust cells |
| Dust Mid | `1C2434` | mid dust, and 20 baked static dust cells |
| Dust Bright | `2A3448` | near dust, and 10 baked static dust cells |

Player

| Name | Hex | Used for |
|---|---|---|
| Ship Core | `FFF4DC` | the ship outline |
| Ship Halo | `5B4E34` | the ship glow |
| Ship Spine | `B8A47A` | the line down the ship |
| Ship Icon | `D9CBA8` | lives icons in the HUD |
| Flame Outer | `FFC24D` | thruster flame outline |
| Flame Core | `FFF3C4` | thruster flame inner line |
| Shield Ring | `FFE29A` | the respawn ring |
| Shot Head | `FFFFFF` | player shot head (2 x 2 cells) |
| Shot Trail 1 | `E8DCC0` | first trail cell |
| Shot Trail 2 | `9C9078` | second trail cell |
| Shot Trail 3 | `544C3C` | third trail cell |

Exhaust fade ramp (4 steps, 5 ticks each): `FFC24D`, `E8A93C`, `A8772A`, `5E4318`.

Rocks

| Name | Hex | Used for |
|---|---|---|
| Rock Large | `7F8EA3` | large rock outline |
| Rock Medium | `A9B6C8` | medium rock outline |
| Rock Small | `D6DEE9` | small rock outline |
| Flash | `FFFFFF` | hit flash and spawn flash, any object |

Rock debris ramp (6 steps): `D6DEE9`, `A9B6C8`, `7F8EA3`, `5C6878`, `3C4552`, `222831`.

Enemies

| Name | Hex | Used for |
|---|---|---|
| Saucer L Core | `FF7A4D` | large saucer outline, its shots (arms) |
| Saucer L Halo | `5A2414` | large saucer glow |
| Saucer S Core | `FF4040` | small saucer outline, its shots (arms) |
| Saucer S Halo | `5A1414` | small saucer glow |
| Saucer Shot Centre | `FFD9B8` | middle cell of a saucer shot |
| Warning | `FF7A4D` | the "saucer incoming" edge marker |

Ember debris ramp (large saucer, 6 steps): `FFD9B8`, `FF8A4D`, `D8553A`, `9C3A2A`, `5C241C`, `2E1410`.
Red debris ramp (small saucer, 6 steps): `FFD0C8`, `FF5A4A`, `D83A3A`, `9C2A2A`, `5C1A1A`, `2E0E0E`.
Ship debris ramp (6 steps): `FFF4DC`, `D9CBA8`, `A8997A`, `766B54`, `463F32`, `24201A`.

Text and screens

| Name | Hex | Used for |
|---|---|---|
| Text White | `F4F7FB` | numbers and words |
| Label | `6F7C90` | SCORE, WAVE, HI-SCORE labels |
| Dim | `8FA0B8` | hi-score number, controls hint |
| Gold | `FFE29A` | pop-ups, NEW HI-SCORE, score pulse |
| Gold Fade | `A58E52` | last frames of a pop-up |
| Text Outline | `05070B` | a 1 cell outline behind HUD and overlay text so lines never cross a letter |
| Title Core | `F4F7FB` | the vector title strokes |
| Title Halo | `2A3B58` | the title glow (baked) |
| Title Rule | `1C2B44` | the thin rule under the title |
| Banner Top | `F4F7FB` | WAVE banner, top row (gradient to Banner Bottom) |
| Banner Bottom | `8FA0B8` | WAVE banner, bottom row |
| Over Top | `FF9A6B` | GAME OVER, top row (gradient to Over Bottom) |
| Over Bottom | `FF4040` | GAME OVER, bottom row |
| Attract Large | `4A5566` | large rocks behind the title |
| Attract Medium | `5F6C80` | medium rocks behind the title |
| Attract Small | `7A889C` | small rocks behind the title |

Gradient text: row `r` of `n` letter rows (r from 0) is the blend of the top and bottom colours at `r / (n - 1)`.

## 2. Line style

**One rule: things that act glow, things that drift do not.**

| Object | Style | Cost |
|---|---|---|
| Ship | core + halo | 5 segments, drawn 5 times |
| Saucers | core + halo | 10 or 11 segments, drawn 5 times |
| Rocks | core only, one cell | 1 pass |
| Flame, spine, shield ring | core only | 1 pass |
| Shots, particles, dust | single cells | cells, not segments |

**How a halo is made.** Draw the object's segments four more times in the halo colour, offset by `(-1, 0)`, `(1, 0)`, `(0, -1)`, `(0, 1)` cells, then draw the core once at the true position. That gives a one cell dim fringe on every side of every line, which reads as a soft glow at 3x and as a clear 2 pixel fringe at 2x.

**Draw order (back to front), every frame:**

1. Baked background: vignette, static dust, and on the title the baked title halo.
2. Moving dust.
3. All halos (ship, saucers), so a halo can never cover any core.
4. Rock cores, large first.
5. Saucer cores.
6. The ship: core, then spine in Ship Spine, then the flame.
7. Shield ring.
8. Shots: saucer shots, then player shots.
9. Particles and chips.
10. HUD and overlay text, each letter with its 1 cell Text Outline drawn first.

**Where two shapes cross**, the later one in this order wins the shared cells, so the ship always shows over rocks and shots always show over everything. Nothing is ever hidden by a glow.

**Glints and flashes.** A new object draws in Flash white for 6 ticks, then its own colour (the "lines brightening when they spawn" effect). A hit object draws in Flash white for 3 ticks, then bursts.

**At 2x**: a core is 2 pixels wide, a halo fringe is 2 pixels. Details of exactly one cell: the ship spine, a dust cell, a debris cell, a shot trail cell, the arms of a saucer shot. At 2x each is a 2 pixel dot; they are all decoration or non critical, and I kept them dim for that reason.

## 3. Shapes

### 3.1 Summary

| Shape | Collision radius | Segments (core) | Extent for wrap |
|---|---|---|---|
| ship | 4.5 | 5 + 1 spine | 10 (includes the flame) |
| ship_b (variant) | 4.5 | 2 + 1 crossbar | 10 |
| saucer_l | 6.5 | 10 | 8 |
| saucer_s | 4.2 | 11 | 6 |
| rock_l0 to rock_l4 | 22 | 13 | 27 |
| rock_m0 to rock_m3 | 11 | 11 | 15 |
| rock_s0 to rock_s3 | 5.5 | 8 | 9 |
| shield ring | 9 (pulses 9 to 10.5) | 8 dashes | 12 |

The ship's circle (4.5) is smaller than its drawn tip (6) on purpose: a graze on the nose feels fair, and the body mass is within the circle.

### 3.2 Ship

Recommended: a paper plane with a spine. Origin is the centroid, so it spins about its visual middle.

#### ship (radius 4.5, 9 cells tall, 7.2 wide)
```
closed
0, -6
3.6, 3
1.6, 1.6
-1.6, 1.6
-3.6, 3
```

#### ship_spine (drawn after the ship core, in Ship Spine, no halo)
```
open
0, -4.4
0, 1.6
```

Variant B (classic open back with a crossbar, 2 segments plus the bar). I prefer A: the closed notched back reads as an engine and gives the flame somewhere to come from.

#### ship_b (radius 4.5)
```
open
-3.6, 3
0, -6
3.6, 3
```

#### ship_b_bar (Ship Core, no halo)
```
open
-2.2, 0.4
2.2, 0.4
```

### 3.3 Thruster flame (3 frames)

Drawn behind the ship, in the ship's local coordinates, with no halo. The outer line is Flame Outer, the inner line Flame Core. Cycle frames 0, 1, 2, 1 at 3 ticks a frame while Up is held. Frame 2 is deliberately lopsided so the flame flickers.

#### flame_0_outer
```
open
-1.3, 1.8
0, 6.2
1.3, 1.8
```

#### flame_0_core
```
open
0, 2
0, 4.2
```

#### flame_1_outer
```
open
-1.4, 1.8
0, 8.2
1.4, 1.8
```

#### flame_1_core
```
open
0, 2
0, 5.4
```

#### flame_2_outer
```
open
-1.2, 1.8
0.4, 7
1.2, 1.8
```

#### flame_2_core
```
open
0.2, 2
0.2, 4.6
```

### 3.4 Respawn shield

A dashed ring around the ship, plus a blink. No extra shape file is needed:

- Ring: 16 points on a circle of radius `r` around the ship. Draw only the even numbered segments (point 0 to 1, 2 to 3, and so on, 8 dashes) in Shield Ring, one cell, no halo.
- Radius: `r = 9 + 1.5 * sin(2 * pi * t / 30)`, where `t` counts ticks since the respawn.
- The ring turns: the point angles are offset by `t * 3` degrees.
- Entry: for the first 12 ticks the ring contracts from radius 14 to 9, then it pulses as above.
- The ship blinks: drawn when `floor(t / 5)` is even, hidden when odd. The ring does not blink.
- The last 30 ticks of the 90 tick protection: the ring also blinks, 3 ticks on and 3 off, so the player knows it is ending.
- The shield is cosmetic. The collision rule for the protected ship is up to the game.

### 3.5 Rocks

Every outline is a closed polyline whose vertices all lie between 0.85 and 1.15 times the radius, with a centroid within 0.06 of the radius of the origin, so the outline and the collision circle agree. The jagged look comes from alternating sharp points and notches within that band. Large rocks have 13 points, medium 11, small 8. Each size has several outlines; pick one at random when a rock is created, rotate it by a random start heading, and spin it slowly.

Spin (one heading step every N ticks, random sign): large 30 to 60, medium 15 to 30, small 6 to 14.

#### Large rocks (radius 22, 13 points each)

##### rock_l0
```
closed
0.9, -19.1
12.8, -21.3
16.8, -9.4
24.3, -2.3
18.2, 5.6
19.4, 14.9
7.5, 18.1
-3, 24.6
-13.2, 14.6
-18.6, 5.3
-24.7, -0.2
-16.4, -10.3
-7.7, -23.5
```

##### rock_l1
```
closed
4.3, -24.3
14.5, -19.8
13.2, -13.5
23.9, -5.1
24.4, 5.5
12.8, 14
8.5, 22.9
-4.5, 18.5
-16.1, 18.8
-18.5, 6
-24.2, -3.1
-15.8, -10.9
-14.9, -19.2
```

##### rock_l2
```
closed
-1.9, -18.8
6.2, -18.3
21.3, -12.8
24, -5.4
17.4, 7.6
18.9, 16.3
1.1, 19.5
-5.8, 18.2
-11.7, 15.5
-21.6, 12.7
-23.6, -6.1
-14.2, -13.5
-12.7, -20.9
```

##### rock_l3
```
closed
-2.8, -18.8
11.6, -15.6
19.9, -15.1
19, 0.4
24.2, 4.8
15.7, 19.1
4.6, 18.5
-10, 22.4
-14.3, 13.2
-18.1, 6.8
-18.9, -4.1
-20.6, -13.8
-5.8, -18.2
```

##### rock_l4
```
closed
0.3, -19.3
13.5, -20.7
16.7, -10.2
24.4, -4.4
17.8, 7.6
18.1, 17
6.9, 18.4
-7.6, 23.7
-13.2, 14.2
-21.8, 12.2
-19.4, 1.3
-19.8, -15.2
-14.9, -19.7
```

#### Medium rocks (radius 11, 11 points each)

##### rock_m0
```
closed
-0.4, -9.5
6.9, -10.3
8.5, -4.5
12.4, 1.8
5.8, 7.6
1.9, 12.2
-2, 9.6
-7.6, 9.8
-12.2, 0.3
-9.4, -2
-6.3, -10.5
```

##### rock_m1
```
closed
0.7, -9.7
5.7, -7.6
9.8, -7.3
9.7, -0.2
7.3, 9.8
4, 8.9
-3.5, 9.1
-9, 8.2
-9.6, -0.7
-10.8, -6.1
-7.5, -9.9
```

##### rock_m2
```
closed
-0.4, -12.5
7, -10.4
8.7, -4.7
9.5, -0.1
7.9, 9.6
3.1, 12
-4.8, 11.4
-7.6, 6.1
-12.2, 0.5
-10.8, -6.2
-3.9, -8.9
```

##### rock_m3
```
closed
-1.3, -9.7
7.8, -9.7
8, -5.4
11.9, 3.4
7.2, 9.8
1.4, 9.5
-1.6, 12.4
-6.5, 6.9
-12.1, 3
-8, -5.7
-4.3, -8.7
```

#### Small rocks (radius 5.5, 8 points each)

##### rock_s0
```
closed
0.8, -6.1
4.7, -4.1
4.7, -1.3
2.3, 4.3
-0.5, 6.2
-3.9, 2.9
-6.2, 0.2
-2.4, -4.2
```

##### rock_s1
```
closed
0.2, -4.8
4.8, -3.9
6.1, -0.5
2.7, 4.1
-1.3, 6
-3.5, 3.2
-4.9, -0.1
-3.4, -5.1
```

##### rock_s2
```
closed
1.5, -6
3.9, -2.9
6.1, 1.1
2.6, 4.1
-0.2, 6.1
-2.6, 4
-5.9, -1.6
-3.4, -3.3
```

##### rock_s3
```
closed
-1.1, -4.6
3.7, -5
4.7, -1.3
5, 3.6
0.4, 4.8
-3.5, 5.1
-4.7, -0.8
-3.5, -3.4
```


### 3.6 Saucers

Not rotated, always upright. Core plus halo. Two extra lines inside each: the waist and the dome base.

#### saucer_l (large saucer, radius 6.5, 14 wide, 8 tall)
```
closed
-7, 0
-3, -3
-2, -5
2, -5
3, -3
7, 0
3.5, 3
-3.5, 3
```

#### saucer_l_waist
```
open
-7, 0
7, 0
```

#### saucer_l_dome
```
open
-3, -3
3, -3
```

The small saucer is meaner: a flatter dome and a toothed underside, hotter colour.

#### saucer_s (small saucer, radius 4.2, 9 wide, 7 tall)
```
closed
-4.5, 0.5
-2.2, -1.6
-1, -3.8
1, -3.8
2.2, -1.6
4.5, 0.5
1.8, 2.8
0, 1.6
-1.8, 2.8
```

#### saucer_s_waist
```
open
-4.5, 0.5
4.5, 0.5
```

#### saucer_s_dome
```
open
-2.2, -1.6
2.2, -1.6
```

### 3.7 Shots

**Player shot.** Not a line: cells.

- Head: a 2 x 2 block of Shot Head, its top left cell at the shot's rounded position.
- Trail: three single cells behind the head along the opposite of the shot's direction, 1.3 cells apart: the first in Shot Trail 1, then Shot Trail 2, then Shot Trail 3. They are cosmetic and are skipped where a rock or saucer already has a cell.
- Fade out: in the last 15 ticks of its life the head drops to Shot Trail 1 and the trail to Shot Trail 3 and then nothing.
- Collision: a point at the head.

**Saucer shot.** A spinning plus, five cells, deliberately different in colour and shape.

- Frame A (plus): centre `(0, 0)` in Saucer Shot Centre, the four arms `(-1, 0)`, `(1, 0)`, `(0, -1)`, `(0, 1)` in the shooting saucer's core colour.
- Frame B (cross): centre `(0, 0)` in Saucer Shot Centre, the four arms `(-1, -1)`, `(1, -1)`, `(-1, 1)`, `(1, 1)` in the same colour.
- Swap every 4 ticks. It does not fade out.
- Collision: a circle of radius 1.5.

## 4. Break ups, bursts and hyperspace

All times in ticks. "Chip" is a short line piece of two points, drawn core only. "Ramp" means step through the listed colours evenly across the life. There is no blending, so a fade is a staircase of colours.

### 4.1 Ship breaking up (90 ticks, 1.5 s)

1. Ticks 0 to 2: the whole ship drawn in Flash white (3 ticks).
2. The ship is replaced by 5 pieces, each a `segments` line in local coordinates, drawn core only in the ship debris ramp:

#### ship_pieces (5 segments, in ship local coordinates at the moment of death)
```
segments
0, -6, -3.6, 3
0, -6, 3.6, 3
-3.6, 3, -1.6, 1.6
3.6, 3, 1.6, 1.6
-1.6, 1.6, 1.6, 1.6
```

3. Each piece moves: velocity = 0.5 times the ship's velocity plus 0.25 to 0.45 cells a tick directed away from the ship's centre through the piece's midpoint; drag 0.985 a tick; spin 2 to 5 degrees a tick with a random sign, about the piece's own midpoint.
4. Fade: the 6 step ship debris ramp, 15 ticks a step, then gone.
5. Debris: 6 single cells, random directions, 0.4 to 0.8 cells a tick, drag 0.97, life 40, ship debris ramp.
6. Ring: 8 cells at 45 degree spacing starting at radius 3, moving out at 0.6 cells a tick, life 14, colours Flash, Shot Trail 1, Shot Trail 2, Shot Trail 3.

Particle cost: 5 pieces + 6 debris + 8 ring = 19.

### 4.2 Rock bursts

All rocks first draw in Flash white (3 ticks; 2 for a small rock), then the rock is removed. Large and medium rocks are replaced by two rocks of the next size, which get the old rock's velocity plus a random push of 0.3 to 0.6 cells a tick in opposite directions. Debris uses the rock debris ramp.

| Rock | Debris cells | Speed (cells a tick) | Drag | Life | Chips |
|---|---|---|---|---|---|
| Large | 10 at random angles | 0.35 to 0.9 | 0.97 | 30 to 44 | 3, each 3 cells long (`-1.5, 0` to `1.5, 0`), start on a random vertex of the old outline, move outward 0.4 to 0.7, spin 2 to 4 degrees a tick, life 36 |
| Medium | 8 at random angles | 0.35 to 0.8 | 0.97 | 24 to 36 | 2, each 2.4 cells long, same recipe, life 28 |
| Small | 8 in a ring: 45 degree spacing from a random start | 0.75, all the same | 0.96 | 16 to 22 | none |

Particle cost: large 13, medium 10, small 8.

### 4.3 Saucer exploding (60 ticks, 1 s)

1. Ticks 0 to 2: the whole saucer drawn in Flash white.
2. The saucer is replaced by its own segments as chips: every segment of its outline, waist and dome (10 for the large saucer, 11 for the small), drawn core only, ember ramp for the large saucer and red ramp for the small. Each chip moves outward from the saucer's centre through its midpoint at 0.3 to 0.7 cells a tick, drag 0.98, spin 2 to 5 degrees a tick with random sign, life 60.
3. Ring: 12 cells at 30 degree spacing, radius 2, speed 0.9, life 22, the same ramp.
4. Score pop-up: see section 6.

Particle cost: 10 + 12 = 22 (large), 11 + 12 = 23 (small).

### 4.4 Hyperspace (about 1 s, 62 ticks)

Leaving (12 ticks, 2 ticks a frame). The ship is drawn at the same heading with its local points scaled by `(sx, sy)`, `sx` across and `sy` along its nose axis, no halo:

| Frame | sx | sy | Colour |
|---|---|---|---|
| 0 | 1.0 | 1.0 | Ship Core |
| 1 | 0.8 | 1.4 | Ship Core |
| 2 | 0.6 | 1.9 | Flash |
| 3 | 0.4 | 2.5 | Flash |
| 4 | 0.25 | 3.2 | Ship Debris 1 |
| 5 | 0.1 | 4.0 | Ship Debris 2 |

(Ship Debris 1 and 2 are the first two colours of the ship debris ramp.) After frame 5 the ship is gone. At the last frame, 10 cells burst out as a ring from radius 2 at 0.7 cells a tick, life 10, colours Flash, Shot Trail 1, Shot Trail 2, Shot Trail 3.

Gap: 30 ticks with no ship. The new position is chosen as the game likes.

Returning (12 ticks): 10 cells start in a ring of radius 12 around the new position and move inward at 1.0 cells a tick over 12 ticks, colours Shot Trail 3, 2, 1, Flash. As they arrive the ship plays frames 5 down to 0 of the table in reverse, 2 ticks a frame, then it is solid.

The ship is invulnerable during the gap and the return (it is not drawn, so it cannot be hit anyway).

If the hyperspace fails, the ship is destroyed on return: play section 4.1 at the new position, plus an extra ring of 16 cells in the ember ramp's first three colours, radius 4, speed 0.8, life 20, to mark that this was a failed jump.

Particle cost: 10 (leaving) and 10 (returning), never at once; 35 for a failed jump.

## 5. Screens

Everything in this section is a list of "item, colour, column, row". All text is the 5 x 7 font. Every piece of text that can sit over play has its 1 cell Text Outline.

### 5.1 In game

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Score label | `SCORE` | Label | 1x | 12 | 8 |
| Score value | 6 digits, zero padded | Text White | 2x | 12 | 18 |
| Lives | the `ship` outline scaled by 0.9, no spine, no halo, upright, one icon per spare life, centred at `(17 + 11 * k, 44)` | Ship Icon | | | |
| Hi-score label | `HI-SCORE` | Label | 1x | 136 | 8 |
| Hi-score value | 6 digits | Dim | 1x | 142 | 18 |
| Wave label | `WAVE` | Label | 1x | 285 | 8 |
| Wave value | right aligned to x = 307 (two digits at x = 285, three at x = 273) | Text White | 2x | 285 | 18 |

The HUD occupies rows 8 to 49 at the top left, rows 8 to 31 in the middle and on the right. Everything below row 50 is play. The middle of the screen (a 60 x 60 box centred on 160, 120) has nothing in it but play.

The score value is 70 cells wide (x 12 to 81, rows 18 to 31).

### 5.2 Title screen

Behind it: the vignette, the dust, and the attract mode: 6 rocks (2 large, 2 medium, 2 small) in the three Attract colours, drifting at 0.05 to 0.2 cells a tick in random directions, spinning as in game. Every 14 seconds a large saucer crosses at row 205 from left to right, in its normal colours, and fires nothing. The attract rocks are dimmer than the title on purpose, so the title is the brightest thing on the screen.

**The title letters are vector outlines**, drawn as lines in the same style as the game (Title Core, with a baked halo), not pixel letters. They match the rocks and the ship, and they cost almost nothing: the halo (Title Halo, the four-offset recipe) is drawn once into the background, and only the 41 core segments are drawn each frame, on top of the attract rocks.

Letter glyphs are in letter local coordinates (x 0 to 20, y 0 to 28, the origin the top left of the letter; `I` is 16 wide). Place each letter at its `x` and the common `y = 58`:

| Letter | A | S | T | E | R | O | I | D | S |
|---|---|---|---|---|---|---|---|---|---|
| x | 40 | 68 | 96 | 124 | 152 | 180 | 208 | 232 | 260 |

##### glyph_A

```
open
0, 28
10, 0
20, 28
open
3.2, 19
16.8, 19
```

##### glyph_S

```
open
20, 0
0, 0
0, 14
20, 14
20, 28
0, 28
```

##### glyph_T

```
open
0, 0
20, 0
open
10, 0
10, 28
```

##### glyph_E

```
open
20, 0
0, 0
0, 28
20, 28
open
0, 14
14, 14
```

##### glyph_R

```
open
0, 28
0, 0
20, 0
20, 14
0, 14
open
8, 14
20, 28
```

##### glyph_O

```
closed
4, 0
16, 0
20, 4
20, 24
16, 28
4, 28
0, 24
0, 4
```

##### glyph_I (16 wide)

```
open
0, 0
16, 0
open
8, 0
8, 28
open
0, 28
16, 28
```

##### glyph_D

```
closed
0, 0
14, 0
20, 6
20, 22
14, 28
0, 28
```

S is used twice (positions 68 and 260). Each glyph is a list of polylines in letter local coordinates; a new `open` or `closed` line starts the next polyline.


| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Title | `ASTEROIDS`, vector | Title Core, halo Title Halo | | per table | 58 |
| Rule | one cell line from x = 40 to x = 279 | Title Rule | | 40 | 98 |
| Subtitle | `A PROGRIDDLE COOKOFF GAME` | Label | 1x | 85 | 106 |
| Hint line 1 | `LEFT RIGHT TURN   UP THRUST   SPACE FIRE` (three spaces between groups) | Dim | 1x | 40 | 168 |
| Hint line 2 | `DOWN HYPERSPACE` | Dim | 1x | 115 | 180 |
| Press space | `PRESS SPACE`, blinks 36 ticks on and 24 off | Text White | 2x | 95 | 204 |

The HUD from 5.1 is shown on the title with the score at `000000` and the real hi-score.

### 5.3 Wave start (90 ticks, 1.5 s)

1. Tick 0: the ship is at the centre with its respawn shield (new game or new wave).
2. Ticks 0 to 15: a one cell line grows from the centre outward to 60 cells each side at row 92, in Dim with a halo in Title Halo (the four-offset recipe, 5 passes).
3. Ticks 8 to 90: `WAVE n` at 3x, vertical gradient Banner Top to Banner Bottom over its 21 rows, with a Text Outline. One digit: `x = 107`; two digits: `x = 98`. Row 64. The banner is above the middle box, so the ship stays visible.
4. Ticks 70 to 90: the banner and the line step through the Dim ramp: Dim, Label, Title Rule, then off.
5. Tick 30: the rocks appear at their start positions, each drawn in Flash white for 6 ticks and then in its colour (the spawn brightening).
6. Tick 90: the shield ring continues until its 90 ticks end. The game is live from tick 30.

### 5.4 Game over

| Item | Content | Colour | Scale | x | y |
|---|---|---|---|---|---|
| Game over | `GAME OVER`, vertical gradient Over Top to Over Bottom over 21 rows, with Text Outline | gradient | 3x | 80 | 84 |
| Score line | `SCORE ` in Label then the 6 digits in Text White (12 characters) | | 1x | 124 | 116 |
| New record | `NEW HI-SCORE`, only if beaten, blinking 10 ticks on and 10 off | Gold | 1x | 124 | 132 |
| Press space | `PRESS SPACE`, appears 90 ticks after the screen, blinks 36 on and 24 off | Text White | 1x | 127 | 170 |

The rocks keep drifting behind the text, drawn in the normal colours. Letters of GAME OVER appear one every 3 ticks, left to right.

### 5.5 Paused

Render the frame once with every colour multiplied by 0.45, then hold it (a one off cost, not per frame). On top, `PAUSED` at 3x in Text White with a Text Outline, `x = 107`, `y = 100`. Nothing moves, nothing blinks.

### 5.6 The first few seconds

On the title screen, the title does not simply appear. It is traced by a beam, like a vector monitor drawing:

1. Ticks 0 to 20: only the vignette and dust. The dust fades in: each dust cell appears at a random tick in this range.
2. Ticks 20 to 110: the 9 letters are traced one after another in reading order, each stroke drawn at 12 cells a tick. A white 2 x 2 head runs along the stroke; behind it the stroke is in Title Core. When a stroke completes, its halo is baked into the background cells.
3. Ticks 110 to 128: the rule below the title draws in from the centre outward (both sides at 14 cells a tick).
4. Ticks 128 to 160: the subtitle types out, one character every 2 ticks.
5. Ticks 160 to 200: the hint lines fade in: Title Rule, Label, Dim, one step per 5 ticks each.
6. Tick 200: `PRESS SPACE` starts blinking. The attract rocks and the saucer have been drifting the whole time.

When the game starts, the ship traces in: its 5 outline segments appear one every 2 ticks in Flash white, then settle to Ship Core, then the spine, then the shield ring contracts in.

## 6. Effects

Budget numbers are in section 7. "Cells" are single cells, "chips" are two point lines.

**Keep**

1. **Exhaust trail.** While Up is held, emit 1 cell every 2 ticks from the tail centre. Velocity = 0.9 times the ship's velocity minus 0.3 cells a tick along the heading; life 20; the exhaust ramp, 5 ticks a step. At most 8 alive.
2. **Wrap flash, ship only.** When the ship crosses an edge, draw a 24 cell bar along the edge, centred on the crossing, 1 cell thick, on both the exit and the entry edge. Colours Ship Halo, then `3A3222`, then `1F1B13`, 4 ticks each. At most 48 cells. Rocks and saucers do not do this: with 30 rocks it would be noise.
3. **Hit flash.** Flash white for 3 ticks before any burst (in section 4).
4. **Dust.** 70 baked static cells (40 Dust Dim, 20 Dust Mid, 10 Dust Bright) plus 20 moving cells that drift left and slightly down at 0.04, 0.08 and 0.14 cells a tick (in Dust Dim, Dust Mid and Dust Bright), wrapping at the edges. They are drawn before every line.
5. **Saucer score pop-up.** `200` or `1000` at 1x in Gold with a Text Outline, centred on the saucer's last position, rising 1 cell every 4 ticks for 48 ticks, in Gold Fade for the last 12 ticks.
6. **HUD pulse.** On a saucer kill or an extra life, the 6 score digits draw in Gold for 20 ticks, then Text White.
7. **Spawn brightening.** Any new object draws in Flash white for 6 ticks.

**Drop**

- **A halo on rocks.** Up to 44 small rocks at 8 segments is already 352 segments. A halo would cost four times that. Rocks stay quiet on purpose, and the glow marks things that act.
- **A bloom, vignette flashes or screen shake.** Any of them touches every cell, which the budget forbids, and none helps the clean look.
- **Wrap flashes on rocks and saucers.** Too busy.

**Add**

1. **Muzzle spark.** When the ship fires: 3 cells from the nose, spread plus or minus 20 degrees, speed 0.9, life 6, colours Flash, Shot Trail 1, Shot Trail 2.
2. **Saucer warning marker.** 60 ticks before a saucer enters, a 5 cell chevron in Warning at the edge where it will enter (x = 2 on the left, x = 317 on the right, at the saucer's row), pointing inward, blinking 8 ticks on and 8 off. The chevron cells for a right pointing marker are `(0, -2)`, `(1, -1)`, `(2, 0)`, `(1, 1)`, `(0, 2)` from the top left of the marker; mirror it on the right edge.
3. **Extra life.** The new icon in the HUD alternates Ship Icon and Flash every 4 ticks for 40 ticks.
4. **Respawn clear check.** While waiting for the centre to clear, draw a dim dashed ring (the respawn ring) at the centre in Title Rule, radius 14, so the player sees why the ship is not back yet. 8 dashes.

## 7. Budgets

### Segments (limit about 400)

| Item | Segments |
|---|---|
| Ship: core 5, halo 20, spine 1 | 26 |
| Flame | 3 |
| Respawn ring (only while shielded) | 8 |
| Large saucer: core 10, halo 40 (only one saucer at a time) | 50 |
| Small saucer: core 11, halo 44 (only one saucer at a time) | 55 |
| Lives icons, 5 each, up to 6 | 30 |
| Large rock | 13 |
| Medium rock | 11 |
| Small rock | 8 |
| Title: 41 core segments (halo is baked) | 41 |

Fixed part in play: ship 26 + flame 3 + ring 8 + saucer 55 + icons 30 = 122. That leaves about 278 for rocks, and about 10 percent more must be reserved for wrap copies.

| Situation | Rock segments | Total with fixed part |
|---|---|---|
| Wave 5 start: 11 large | 143 | 265 |
| Typical mid wave: 6 large, 6 medium, 10 small | 224 | 346 |
| Worst case: 44 small | 352 | 474 |

**Degrade ladder** when the projected total passes 380, applied in this order, each step instant and reversible:

1. Drop the ship and saucer halos (saves up to 64).
2. Bake the lives icons into a HUD layer so they cost nothing per frame (saves 30).
3. Skip the flame and respawn ring (saves up to 11).
4. After steps 1 to 3 the worst case of 44 small rocks falls from 474 to about 369, inside the limit. Never allow more than 44 rocks alive at once.

### Particles (limit about 80)

| Pool | Cells or chips |
|---|---|
| Moving dust | 20 |
| Exhaust trail | 8 |
| Muzzle spark | 4 |
| Debris pool (bursts, pieces, rings, pop-ups' text is cells in text, not here) | 48 |

Worst realistic overlap: ship destroyed (19) plus two rock bursts (26) is 45, inside the 48. If the pool is full, a new burst spawns half its debris cells and never skips its chips or pieces, so every explosion still has its structure. The title uses no pool at all.

Shots are not counted here: 4 player shots of 7 cells and 2 saucer shots of 5 cells, 38 cells in total, drawn as cells.

## 8. What I decided and why

1. **A glow on the ship and saucers only.** The brief asks whether all objects share one style. They do not: with 44 rocks possible, a rock halo breaks the budget, and glow is more elegant as a signal ("things that act glow") than as a coating.
2. **Cool stone rocks, warm champagne ship, ember saucers.** Three colour families that cannot be confused, none of Space Invaders' pink, violet or cyan.
3. **Rock brightness rises as the rock shrinks.** The small rocks are the ones that kill you, so they should be the clearest. It also gives depth.
4. **Rocks are jagged within 15 percent.** That limit makes outlines naturally rounder than the arcade's, so the jaggedness comes from alternating sharp points and deep notches. All 13 outlines were checked: every vertex is between 0.86 and 1.14 times the radius, and each outline's area matches its circle within 9 percent.
5. **The title is vector.** Pixel letters would be the only pixel art on a screen of lines. Vector letters match, and with the halo baked and the beam trace they are the cheapest and best looking option.
6. **Ship collision radius 4.5 against a 6 cell nose.** Fair to the player; change it to 5 if you want it stricter.
7. **Variant B for the ship** is included, but A is the recommendation.
8. **The nebula and a bloom are not included.** A near black vignette and 90 dust cells are enough; anything more would fight the lines.
9. **Pause dims once**, not per frame, so it stays inside the budget.
