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
