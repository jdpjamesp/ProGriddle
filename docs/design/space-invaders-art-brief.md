# Space Invaders: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers below are hard limits, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We are adding **Space Invaders**, as faithful to the 1978 arcade rules as we can make it (one shot on screen at a time, the invaders speeding up as they die, shields that crumble pixel by pixel, the saucer, three kinds of bomb) but with a **modern, slick, neon look and feel**. It should feel like a loving remake that someone with taste made in 2026: crisp chunky pixels, rich colour, glow, a bit of juice, and no clutter.

## The hard limits

- The whole screen is a **grid of 224 columns by 256 rows** (the arcade's own resolution). Each cell is one pixel of the picture and holds **one flat 24 bit colour**. There is no transparency, no blending and no anti-aliasing: a cell is a colour, and that is all.
- The picture is drawn **scaled up with hard nearest neighbour edges**, normally 3x (672 x 768 on screen), so every cell shows as a chunky square pixel. The grid outlines are off.
- Anything on screen, including **all text**, is made of cells. We draw text with a small pixel font (a 5 x 7 capital letter font is the plan), so the HUD and the title screen are part of the picture.
- Sprites are drawn into a **background that is already coloured** (so a sprite is a set of coloured cells over it). A dim "halo" or shadow ring around a sprite is possible, since it is just more cells, but keep a sprite's solid body inside the arcade size because **collisions use the body**.
- Cheap per frame: a handful of moving things plus a few dozen particles is fine. A full screen effect that changes every cell every frame (a moving gradient, a shake of the whole screen) is not.

## Sprite format we will use

Rows of text, one character per cell, rows separated by `/`, for example the arcade squid frame 1:

```
...##...
..####..
.######.
##.##.##
########
..#..#..
.#.##.#.
#.#..#.#
```

`.` is empty (the background shows through). `#` is the sprite's main colour. `+` is a second, usually lighter or darker, colour for details such as eyes, highlights or the edge glow, and `*` a third (a hot core, say). So **each sprite is up to three tones**, and you choose the three colours per sprite (and say whether they change with the row, the wave or the time). The same format is fine for explosions, bombs and the shot.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look. A palette as a table of names and hex values: the background (it may be a vertical gradient, say deep navy at the top fading to a dark violet near the ground, with a faint nebula if you like), the five rows of invaders (they were red, magenta/white, green on the arcade because of the cellophane overlay, so use colour to tell the rows and the three types apart), the cannon, the shields, the three bomb types, the shot, the saucer, the ground line, the text and the highlights. Colours should still read when a lot of things happen at once.

### 2. Sprites (arcade sizes, width x height; two frames wherever it says so)

| Sprite | Size | Notes |
|---|---|---|
| Squid, top row, 30 points | 8 x 8 | 2 frames (the legs move) |
| Crab, rows 2 and 3, 20 points | 11 x 8 | 2 frames |
| Octopus, rows 4 and 5, 10 points | 12 x 8 | 2 frames |
| Cannon | 13 x 8 | 1 frame, plus the blink for when it respawns |
| Saucer | 16 x 7 | 1 or 2 frames, it can pulse |
| Shield | 22 x 16 | the classic bunker, with the arch cut out of the bottom. It is **crumbled one cell at a time**, so give it a surface that stays good-looking when it is chewed (a flat colour, or a gentle vertical gradient, works best) |
| Bomb 1, 2 and 3 | about 3 x 7 | three different kinds (a squiggle, a plunger, a rolling cross), 2 to 4 frames each |
| Player shot | 1 x 4, or 1 x 6 with a fading tail | |
| Alien explosion | about 13 x 8 | 2 or 3 frames, an arcade-like splat or a modern burst |
| Cannon explosion | about 16 x 8 | 2 to 4 frames, it lasts a second or so |
| Shot hits the top | about 8 x 8 | a starburst |
| Bomb hits the ground, shield chip, saucer explosion | small | your call |
| Lives icon | the cannon, small | shown in the HUD |

The invader bodies must stay close to these sizes, because the arcade spacing is 16 cells between invaders. If a design wants to be a cell or two bigger (an outline), say so and say which way.

### 3. Screen layouts on the 224 x 256 grid
Where things sit and how they look. The arcade had the score at the top, the saucer lane below it, the rack in the middle, four shields, the cannon, a ground line near the bottom and the lives and credit under it. Please lay out:

- **In game**: SCORE, HI-SCORE, the lives, the wave number, the ground line. Say which rows each uses.
- **Title / attract screen**: the name in big pixel letters, the points table (a saucer = ? MYSTERY, a squid = 30 POINTS, and so on, with the sprites), and a "PRESS SPACE" line that blinks.
- **Game over**, and **wave cleared / get ready**.
- Anything that makes the first five seconds feel special (an intro where the invaders build up row by row, as the arcade did, is welcome).

### 4. Effects (tell us which are worth it)
Ideas we think are affordable: a starfield with slow parallax and a twinkle, a particle burst when an invader dies (a dozen cells in the invader's colour, flying out and fading), a brief white flash on the cannon when it is hit, the saucer's colour cycling, a thin glow under the shots, the shields shimmering when hit, the HUD score pulsing on a big hit, a few frames of colour change on the ground line when a bomb lands. Say which you want, which you would drop and what you would add.

## How to give it back

One markdown file with: the palette table, then every sprite in the format above in fenced blocks (name them, and say the colours for `#`, `+` and `*`), then each layout as a fenced 224 x 256 sketch or, simpler, as a list of "this text, in this colour, at this column and row". Aim for something we can paste into code with no further decisions. If you want to try a variant, give us two and say which you prefer.

## Where things sit now (cell coordinates, x across, y down, top left origin)

- HUD: labels SCORE at (8, 6), HI-SCORE at (88, 6), WAVE at (179, 6) in the label cyan; the numbers 10 rows under them at (8, 16), (97, 16), (192, 16), in white. Text is the 5 x 7 pixel font.
- Saucer lane: the saucer flies along y = 32. A shot that reaches y = 30 hits the top.
- The invader rack: 5 rows of 11, 16 cells apart across and 16 down at the start of wave 1 (squid, crab, crab, octopus, octopus from the top). Later waves start lower.
- Shields: four, 22 x 16, top at y = 184, first at x = 35, 44 cells apart.
- Cannon: top at y = 216, x runs from 8 to 203. Ground line: y = 232, one cell thick.
- Lives: the number at (8, 241) then small cannons at x = 18, 34, ... at y = 240.
- Title screen: big gradient letters SPACE at (68, 44) and INVADERS at (41, 70), both 3x scaled text; "SCORE ADVANCE TABLE" at (52, 108); saucer at (70, 124), squid at (74, 138), crab at (72, 152), octopus at (72, 166) each followed by "= ? MYSTERY", "= 30 POINTS", "= 20 POINTS", "= 10 POINTS" at x = 94; blinking PRESS SPACE at (79, y).
- Game over: GAME OVER, 2x scaled gradient text, at (61, 100).
- Effects now: sparks (up to 64 particles) on kills and shield hits, 2 frame blasts, a gold score pop-up where the saucer was hit, the starfield.

## The current look (attach `build/screenshots/si-title.png`)

Neon pink, violet and cyan invaders on an indigo gradient sky, green shields shaded top to bottom, a mint cannon, a thin green ground line. Everything is functional and tidy but the pictures are plain arcade shapes with eyes filled in: this is where we want your craft.

## What is most worth improving

1. The three invaders and their two poses each: more character within the same box, same silhouette feel, still instantly readable at 3x.
2. The cannon, the saucer, and a shield surface that chews nicely.
3. The three bombs (each should be unmistakable and animated), the player shot, and the explosions (alien, cannon, top burst, ground splat).
4. A better title screen layout (today: big gradient SPACE INVADERS, a score table, blinking PRESS SPACE), the GAME OVER look, a wave cleared and get ready look, and the HUD polish.
5. Which effects to keep, drop or add, within the cheap per frame limit.

## The current placeholder art (the starting point, please improve it)

Generated from `InvadersArt.cls` and `InvadersLook.cls`. Rows are separated by `/` in the code and shown one per line here. Sizes are width x height.

### Palette now (30 colours)

| # | Hex | Used for |
|---|---|---|
| 1 | `06051A` | the top of the sky, almost black with a hint of indigo |
| 2 | `1D0B3A` | the sky at the horizon, a deep violet |
| 3 | `0A0814` | below the ground line |
| 4 | `3CE6A0` | the ground line |
| 5 | `4A5088` | a faint star |
| 6 | `C9D2FF` | a bright star |
| 7 | `7FE7FF` | a cyan star |
| 8 | `FF4FA8` | the squid, hot pink |
| 9 | `FFE0F2` | the squid eyes |
| 10 | `A06BFF` | the crab, violet |
| 11 | `EFE6FF` | the crab eyes |
| 12 | `3DE8FF` | the octopus, cyan |
| 13 | `E2FCFF` | the octopus eyes |
| 14 | `5CFF8A` | the cannon, mint green |
| 15 | `FFFFFF` | the tip of the barrel |
| 16 | `FF3B5C` | the saucer, red |
| 17 | `FFE14D` | the saucer lights |
| 18 | `8CFFC8` | the top of a shield |
| 19 | `1FA868` | the bottom of a shield |
| 20 | `FFB13D` | an alien bomb, amber |
| 21 | `FFF2C4` | the tip of a bomb |
| 22 | `A8F6FF` | the player shot |
| 23 | `FFFFFF` | the head of the shot |
| 24 | `FFFFFF` | a flash of white |
| 25 | `FFFFFF` | the numbers and words |
| 26 | `7FE7FF` | the labels of the scores |
| 27 | `FF4F7A` | GAME OVER |
| 28 | `FFD84D` | a saucer score |
| 29 | `FF7AD0` | the top of the title letters |
| 30 | `6A5CFF` | the bottom of the title letters |

The sky is a vertical gradient from colour 1 (top) to colour 2 (at the ground line, row 232), drawn row by row. Below row 232 is colour 3. 48 stars drift at three speeds in colours 5, 6, 7. Invaders are coloured by type only (all rows of one type match). A shield is shaded row by row from colour 18 to colour 19.

### The 34 pictures now

**1. Squid, pose 0** (8 x 8): top row, 30 points. #=squid colour (hot pink), +=eyes (pale pink)

```
...##...
..####..
.######.
##+##+##
########
..#..#..
.#.##.#.
#.#..#.#
```

**2. Squid, pose 1** (8 x 8): the other pose, same colours

```
...##...
..####..
.######.
##+##+##
########
.#.##.#.
#......#
.#....#.
```

**3. Crab, pose 0** (11 x 8): rows 2 and 3, 20 points. #=crab (violet), +=eyes

```
..#.....#..
...#...#...
..#######..
.##+###+##.
###########
#.#######.#
#.#.....#.#
...##.##...
```

**4. Crab, pose 1** (11 x 8): same colours

```
..#.....#..
#..#...#..#
#.#######.#
###+###+###
###########
.#########.
..#.....#..
.#.......#.
```

**5. Octopus, pose 0** (12 x 8): rows 4 and 5, 10 points. #=octopus (cyan), +=eyes

```
....####....
.##########.
############
###++##++###
############
...##..##...
..##.##.##..
##........##
```

**6. Octopus, pose 1** (12 x 8): same colours

```
....####....
.##########.
############
###++##++###
############
..###..###..
.##..##..##.
..##....##..
```

**7. Cannon** (13 x 8): #=cannon (mint), +=barrel tip (white)

```
......+......
.....###.....
.....###.....
.###########.
#############
#############
#############
#############
```

**8. Saucer** (16 x 7): #=saucer (red), +=lights (yellow)

```
.....######.....
...##########...
..############..
.##+##+##+##+##.
################
..###..##..###..
...#........#...
```

**9. Shield** (22 x 16): 22 x 16, #=body only; drawn as a vertical gradient green top to bottom by row, and crumbled a cell at a time

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

**10. Bomb rolling, frame 0** (3 x 7): #=amber, +=pale tip (the last row)

```
#..
.#.
..#
.#.
#..
.#.
..+
```

**11. Bomb rolling, frame 1** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
..#
.#.
#..
.#.
..#
.#+
```

**12. Bomb rolling, frame 2** (3 x 7): #=amber, +=pale tip (the last row)

```
..#
.#.
#..
.#.
..#
.#.
#.+
```

**13. Bomb rolling, frame 3** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
#..
.#.
..#
.#.
#..
.#+
```

**14. Bomb plunger, frame 0** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
.#.
###
.#.
.#.
.#.
.+.
```

**15. Bomb plunger, frame 1** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
.#.
.#.
###
.#.
.#.
.+.
```

**16. Bomb plunger, frame 2** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
.#.
.#.
.#.
###
.#.
.+.
```

**17. Bomb plunger, frame 3** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
.#.
.#.
###
.#.
.#.
.+.
```

**18. Bomb squiggly, frame 0** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
..#
.#.
#..
.#.
..#
.#+
```

**19. Bomb squiggly, frame 1** (3 x 7): #=amber, +=pale tip (the last row)

```
#..
.#.
..#
.#.
#..
.#.
..+
```

**20. Bomb squiggly, frame 2** (3 x 7): #=amber, +=pale tip (the last row)

```
.#.
#..
.#.
..#
.#.
#..
.#+
```

**21. Bomb squiggly, frame 3** (3 x 7): #=amber, +=pale tip (the last row)

```
..#
.#.
#..
.#.
..#
.#.
#.+
```

**22. Player shot** (1 x 4): 1 x 4, #=pale cyan, +=the head (white)

```
+
#
#
#
```

**23. Alien blast, frame 0** (13 x 8): plays where an invader died, #=the dead invader's colour, +=white flash

```
...#..#..#...
#...#.#.#...#
.#..#...#..#.
..#.......#..
##...+++...##
..#.......#..
.#..#...#..#.
#...#.#.#...#
```

**24. Alien blast, frame 1** (13 x 8): same colours

```
.............
#.....#.....#
..#.......#..
....#...#....
.............
....#...#....
..#.......#..
#.....#.....#
```

**25. Cannon blast, frame 0** (16 x 8): plays when the cannon is hit, alternates with frame 1 about 10 times a second for 110 frames, #=mint, +=white

```
..#...#..#...#..
.....#..##..#...
..#..#.####.#...
.#.#..######.#..
..######+###.#..
.#.########.##..
..####+#####.#..
...#########....
```

**26. Cannon blast, frame 1** (16 x 8): same colours

```
...#..#...#.#...
.#...#.#..#...#.
...#.######.#...
..#.########.#..
.#.##+#####.#.#.
..########.#.#..
.#.#######..#...
..##########.#..
```

**27. Shot hits the top (burst)** (7 x 7): #=shot cyan, +=white, shown 8 frames

```
#..#..#
.#.#.#.
..###..
###+###
..###..
.#.#.#.
#..#..#
```

**28. Bomb splat on the ground** (6 x 4): #=amber, +=pale, shown 8 frames; this is a placeholder shape

```
.#.##.
#.##.#
.####.
..##..
```

**29. Shield chip from a shot, variant 0** (7 x 5): cells removed from a shield where a shot hit, from below; # marks a removed cell

```
..#.#..
.#####.
#######
.#####.
..###..
```

**30. Shield chip from a shot, variant 1** (7 x 5): cells removed from a shield where a shot hit, from below; # marks a removed cell

```
.#..#..
#######
.#####.
#######
..###..
```

**31. Shield chip from a shot, variant 2** (7 x 5): cells removed from a shield where a shot hit, from below; # marks a removed cell

```
..###..
#######
.#####.
.#.#.#.
..#.#..
```

**32. Shield chip from a bomb, variant 0** (7 x 6): cells removed where a bomb hit, from above; # marks a removed cell

```
..###..
.#####.
#######
.#####.
..#.#..
.#...#.
```

**33. Shield chip from a bomb, variant 1** (7 x 6): cells removed where a bomb hit, from above; # marks a removed cell

```
.#####.
#######
#######
.#####.
#.###.#
..#.#..
```

**34. Shield chip from a bomb, variant 2** (7 x 6): cells removed where a bomb hit, from above; # marks a removed cell

```
..#.#..
.#####.
#######
#######
.#.#.#.
...#...
```
