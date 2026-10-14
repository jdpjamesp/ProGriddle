# Asteroids: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers in "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake and Space Invaders. The next game is **Asteroids**: you fly a small ship around a wrapping screen, thrust and drift with inertia, and shoot rocks that break into smaller rocks, while saucers cross and shoot at you.

The look has to be **recognisable** (anyone who has seen Asteroids should know it at a glance: a triangular ship, jagged rocks, a flying saucer, lines on black) but **clean, modern and sleek**: think a loving remake by someone with taste in 2026, not a museum piece. Glowing vector lines, restrained colour, smooth feeling motion, no clutter. Space Invaders in this project went neon pink, violet and cyan on an indigo sky; Asteroids should feel like a sibling but its own thing, so please do not just reuse that palette.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas**: a grid of cells, each cell one flat 24 bit colour. The ship, rocks and saucers are **vector outlines**: we rotate a list of points and draw straight lines between them, one cell wide, redrawing every frame at 60 frames a second. So you design shapes as **point lists**, not as pixel pictures.

### The hard limits

- The playfield is **320 columns by 240 rows** of cells (4:3). It is shown scaled up with hard nearest neighbour edges, normally 3x (960 x 720) and on smaller screens 2x (640 x 480), so **every line must still read at 2x**, where one cell is two screen pixels. There is no anti-aliasing and no blending: a cell is one colour, and a later draw replaces an earlier one.
- A line is drawn with a plain integer line algorithm, so a line is one cell thick by default. A thicker line, a glow or a halo is possible, but it is made of **extra cells** (for example a dim copy of each line one cell either side, drawn first, then the bright core on top). Say what you want and how many cells it costs.
- Positions in the game are fixed point and the ship can face any of **64 directions** (5.6 degree steps), so shapes are rotated at run time. Give each shape in a **local coordinate system**: the origin is the shape's centre, x grows right, y grows down, and the shape's **nose points up** (negative y). Coordinates are in cells and may be decimals.
- Collisions use **circles** (a radius for each object), not the drawn outline. The outline you design for each rock should be within about 15 percent of its radius so what the player sees matches what hits. Give the radius for each shape.
- **Budget per frame**: up to about 400 line segments, and up to about 80 particles (single cells or short line pieces). A screen wide effect that changes every cell each frame (a full bloom, a moving gradient) is not affordable. A static background that is drawn once is fine.
- Text is made of cells too. We have a **5 x 7 pixel capital letter font** (digits and basic punctuation included) which can be drawn at 1x, 2x and 3x, in one colour or a vertical gradient. If you want a second, smaller font for the HUD (say 3 x 5 digits) give its glyph bitmaps.
- The playfield **wraps** on all four edges: an object leaving the right edge comes back on the left, and a shape crossing an edge is drawn in two places. Design with that in mind (nothing should look odd when cut by the edge).

## The rules, so the screens make sense

- Left and Right rotate the ship, Up fires the thruster, Space fires, Down jumps to a random place (hyperspace, with a small chance of blowing up). There is inertia: the ship keeps drifting, with a little drag.
- A wave starts with 4 large rocks, plus 2 more each wave up to 11. A shot splits a large rock into two medium ones, a medium into two small ones, and a small one just bursts. Large, medium and small are worth 20, 50 and 100 points.
- At most 4 shots in flight, each fading out after a distance of about three quarters of the screen width.
- A large saucer (200 points) crosses now and then and fires at random; a small saucer (1000 points) is rarer and aims at you.
- Three lives, an extra one at 10000 points. A new ship appears only when the middle of the screen is clear, and is protected (blinking) for a second and a half.
- A score of up to 6 digits, a hi-score, lives, the wave number.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look. A palette as a table of names and hex values: the background (black or near black is expected, but a very dark gradient, a faint vignette or faint dust is welcome as long as it does not fight the lines), the ship, its thruster flame, the shots, the three sizes of rock (same colour or varying by size?), the large and small saucer, the saucer shots, explosion debris, the text, the HUD, highlights. Colours must still read when twenty things are on the screen at once. Say which things are the same colour and which are different on purpose.

### 2. Line style
How a line is drawn: one cell, or a one cell core with a dimmer one cell halo, or something else you can make from cells. Give the core and halo colours, the order they are drawn in, and how it should look where two shapes cross. Say whether the ship, the rocks and the saucers share one style or differ (for example only the player's ship glowing).

### 3. Shapes (point lists in local cells, nose up)

| Shape | Notes |
|---|---|
| Ship | The classic arrowhead or something a little more refined. About 7 to 9 cells tall. Give the outline points, and any inner lines (a cockpit line, a notch at the back). Radius for collisions. |
| Ship thruster flame | 2 or 3 frames that alternate while thrusting. Points in the same local coordinates, behind the ship. |
| Ship shield / respawn | How the ship looks while protected and blinking: a ring, a pulse, a dimmer outline? |
| Large rock | Radius about 20 to 24. At least **4 different outlines** (point lists with irregular radii, 10 to 14 points each) so rocks do not all look the same. |
| Medium rock | Radius about 10 to 12. At least 4 outlines. |
| Small rock | Radius about 5 to 6. At least 3 outlines. |
| Large saucer | About 14 cells wide. The classic dome and flat body with the lines across. Radius. |
| Small saucer | About 9 cells wide. A variant that looks meaner. Radius. |
| Player shot | A single bright cell, or 2 cells, or a short streak with a fading tail. |
| Saucer shot | Different from the player's at a glance (colour and shape). |
| Ship breaking up | The ship comes apart into 3 to 5 line pieces that spin and drift apart over about 1.5 seconds, fading out. Give the pieces as point pairs in local coordinates, and how they move (spin speed, drift speed, fade). |
| Rock bursting | What a small rock does when it is hit, and what the break up of a larger one looks like: a ring of debris, a flash, short line pieces? Particle counts. |
| Saucer exploding | Same question. |
| Hyperspace | The ship leaving and returning: a shrinking or stretching effect, a flash, a ring. A few frames. |

Everything above should work when rotated to any of 64 directions and at both 2x and 3x scale. If a design detail is only one cell in size, say so, because at 2x it is a 2 pixel dot.

### 4. Screen layouts on the 320 x 240 grid
Where things sit and how they look:

- **In game**: SCORE (6 digits), HI-SCORE, lives shown as small ship icons, the wave number. Give the positions (column and row), the font and the colours. Keep the middle of the screen clear.
- **Title / attract screen**: the name ASTEROIDS in big letters, a short hint line (the controls), a blinking PRESS SPACE, and ideas for what drifts behind it (a few slow rocks and a saucer passing, drawn with the same shapes). Say how the title letters look: plain gradient pixel letters, or drawn as vector outlines so they match the game?
- **Wave start**: a short WAVE n banner. **Game over**: GAME OVER, the score and a NEW HI-SCORE note. **Paused**.
- Anything that makes the first few seconds feel special.

### 5. Effects (tell us which are worth it)
Ideas we think are affordable: a short fading trail behind the ship while it thrusts, screen edge flashes when a shape wraps, a brief flash of the lines when a rock is hit, a slow drift of very faint dust or stars in the background, a score pop-up where a saucer was destroyed, a subtle pulse of the HUD score on a big hit, lines brightening briefly when they spawn. Say which you want, which you would drop and what you would add. The budget is in "The hard limits".

## How to give it back

One markdown file with: the palette table, the line style, every shape as a fenced block of points in local coordinates (name the shape, say its collision radius, and say which points join to which: usually "in order, closed", with any extra lines listed separately), the particle and fragment recipes, each screen as a list of "this text or shape, in this colour, at this column and row", and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions. If you want to try a variant, give two and say which you prefer.
