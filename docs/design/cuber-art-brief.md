# Cuber: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers under "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake, Space Invaders, Asteroids, Centipede, Xevious, Rogue, Blast Buddies and FOR EACH. The next game is a **hopping puzzle arcade game on a pyramid of cubes**, in the spirit of the 1982 classic: a small creature hops diagonally from cube to cube down a pyramid of isometric cubes, changing the top of every cube it lands on to a target colour, while enemies chase it, and it can fall off the edge to its death.

**Working title: Cuber.** A better name is welcome. We will **not** use the original's name or any of its character names.

### Recognisable, but with a modern twist (please read twice)

It must be **recognisable at a glance as that kind of game**: a pyramid of isometric cubes seen from a three quarter view, a small round hero that hops one cube at a time along the four diagonals, a snake like chaser, bouncing balls, floating escape discs at the sides. But the pictures and the feel should be **our own and modern**, not a pixel copy of the arcade sprites:

- **Do not** reuse the original's hero (an orange round creature with a long snout), its purple snake, its green and red balls as drawn, its cube colour scheme or its title lettering. Nothing should read as a trace of the original.
- **Do** keep what makes the idea readable: **isometric cubes** whose top face changes colour, a **hero with a clear silhouette in all four hop directions**, a **chaser** that is long and menacing, **round bouncing hazards**, **discs** that carry the hero to safety, the **edge of the pyramid and the void** below it.
- **The twist is yours to propose.** Some directions, take or leave them: cubes as **glowing light tiles on a dance floor or a circuit board** that light up when stepped on; cubes as **ice, paint or sugar** that melt, freeze or get painted; a **modern, soft, glassy look** with light that spreads from the cubes already lit; a hero that is a **bouncy little robot, a gummy creature, a jelly or a sprite of light**, with big readable eyes; the pyramid floating in a **night sky, a neon city or a cosmic void**. Colour that *means* something (progress, danger) and a little juice (a pulse of light that ripples across the lit cubes when a level is cleared) is the target.
- The tone is a loving remake by someone with taste in 2026: **bright, clean, chunky pixels, rich colour, a little juice**. Not grim, not museum.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas** (the same one Space Invaders, Centipede and Xevious use): a grid of pixels, each pixel one flat 24 bit colour, shown scaled up with hard nearest neighbour edges. Sprites are drawn over a background that is already coloured. The pyramid is drawn into the background, and **a cube's top face is repainted** (a small region) whenever its colour changes.

### The hard limits

- The canvas is **256 columns by 256 rows**, shown at 3x (768 x 768) where the screen is tall enough, else 2x. A different size is allowed if you ask for it and say why (a pyramid of 7 rows needs width). **Every detail must still read at 2x**: a 1 pixel highlight is fine, a 1 pixel dot that carries meaning is not.
- **No anti-aliasing and no blending.** A pixel is one colour and a later draw replaces an earlier one. Transparency is a pixel you leave out. A soft shadow or glow is made of extra pixels in dimmer colours.
- **Isometric by pixel rules.** Use the classic 2:1 pixel isometric: edges run 2 pixels across for every 1 pixel down, so lines stay clean at every size.
- **Sprite sizes.** The rules use the **body** of a sprite for hits, so the sizes below are limits for the solid body. A one pixel outline or a dim halo may sit outside it, and say so if it does.
  - **A cube** is **32 wide by 32 high** as a picture: a top diamond 32 x 16, and two side faces (left and right) below it, 16 high each. Cubes sit on a pitch of **32 pixels across and 24 pixels down** between rows (the faces overlap exactly as in the classic look). This gives a pyramid of 7 rows that is 224 wide and about 176 high, with room above and below for the HUD and the discs. Propose other numbers if you have a better idea and say so.
  - Hero body **12 wide by 14 high**. Its origin is **the middle of its feet**, the point that sits at the middle of a cube's top diamond.
  - Chaser: body **12 wide by 14 high** (the head), but it is **longer in its animation** (a body that coils in 3 or 4 segments when it is a "snake", or whatever shape you choose), and the hit is on the head only.
  - Bouncing ball: body **10 x 10**.
  - Everything else (discs, backgrounds, the HUD) is not hit by anything and can be any size that fits.
- **Facing.** The hero and the enemies move on **four diagonals**: down left, down right, up left, up right. Design **down right and up right**, and the game mirrors them for left. If your shading would look wrong mirrored (light from the top left), give the left facing frames too and say so.
- **Cheap per frame.** A handful of moving sprites and up to about **60 particles** (single pixels, or lines of 2 or 3) is fine. The **pyramid is static background**, repainted one cube top at a time. A full screen effect that changes every pixel every frame (a moving gradient, a shake of the whole picture) is not affordable. A ripple that sweeps along the cubes (one cube top per step, 28 in all) is.
- **Text is made of pixels too.** We have a **5 x 7 capital letter font** (digits and basic punctuation included), drawn at 1x, 2x or 3x, in one colour or a vertical gradient, with an optional one pixel dark outline. If you want a smaller font for the HUD, give its glyph bitmaps.
- **Colours must be told apart by more than hue** (see `docs/accessibility.md`): the **three cube states** (not yet reached, half way, done) must differ in **pattern or brightness** as well as colour, and the **enemies must differ from the hero and from each other by shape** as well as colour, with good contrast against the cubes and the background.

### The sprite format we will use

A sprite is rows of characters, one per pixel, with a legend. `.` is transparent. Give frames as separate blocks named `Hero hop down right 1`, `Hero hop down right 2` and so on.

Use the **tone format** of the Snake and Tetris art: for a part that is recoloured or shaded, the rows use `1` (highlight), `2` (light), `3` (base), `4` (shade), `5` (edge), and a colour table gives the five hex values for tones 1 to 5 for each colour row (hero body, cube top state 1, state 2, state 3, and so on). Anything with its own fixed colour (an eye, a spark) uses letters `A` to `H` with their own hex values in the legend. Keep each sprite's legend to **16 colours or fewer**, and say so if you need more. Look at `docs/design/snake-art.md` section 0 for how that file lays it out: we paste the result into code with no decisions left.

## The rules, so the screens make sense

- **The pyramid** has **7 rows**: row 1 has one cube at the top, row 7 has seven cubes, 28 cubes in all. The hero starts on the top cube.
- **The hero hops** one cube at a time on the four diagonals, a short arc of about 12 pixels high over about 12 frames. It **cannot be steered mid hop**. Landing on a cube changes its top. Hopping off the edge into the void **loses a life** (with a fall).
- **Cube colours:** on the first levels a cube has **two states** (not done, done). On later levels a cube needs **three hops** to be done (not done, half, done), and on some levels a cube **turns back** to a previous state when an enemy of the "undo" kind lands on it. All cubes done **completes the level**.
- **Enemies** (design **four kinds** of your own, we use the working names only so the rules make sense):
  - **The chaser**: hatches as a ball at the top, bounces down, then turns into a long hunting creature that hops toward the hero. It is the one that is **deadly and smart**. If the hero escapes on a disc, the chaser follows and falls off the edge (a big score).
  - **The bouncer**: a round ball that hops down the pyramid at random. Touching it **loses a life**.
  - **The freezer**: a different ball that **freezes every enemy for a few seconds** when the hero touches it (good for the hero).
  - **The undoers (two of them)**: little creatures that hop down the pyramid and **turn a cube they land on back a state**. One walks the left edge, one the right edge (sideways hoppers). The hero can **catch** one by landing on it for a score.
- **Discs.** On each side of the pyramid, a few **floating discs** wait. Hop onto one and it carries the hero back to the top and **removes the chasing enemies**. A disc that has been used is gone for that level. Design a disc (spinning, 4 frames), a disc in flight and a gone disc.
- Three lives, an extra one at 8000 points. Scores: a cube done 25, a disc left over at the end of the level 50 each, a caught undoer 300, the chaser falling for a disc 500, the freezer 100 (say so if you want different values).
- **Levels and rounds.** Four rounds to a level, and the rules change with the level (more hops, faster enemies). The HUD shows **LEVEL and ROUND** and **the target colour** as a small cube.
- The HUD: the score (6 digits), the high score, the lives left, the level and round, the **target cube** (the colour the hero is painting).

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look, and a **palette** as a table of names and hex values: the background (and the void beneath), the cubes (top state 1, 2 and 3, each with their left and right faces in two tones), the hero, the chaser, the bouncer, the freezer, the undoers, the discs, effects (hit flash, ripple), the text and the HUD.

It should be a **sibling of the other games, but its own thing**. The nearest ones are Lantern Glass (Tetris and Snake: dark navy, one amber lamp, glassy jewel colours), Space Invaders (neon pink, violet and cyan on indigo), Moonlit Bed (Centipede), Skylark (Xevious) and Asteroids (glowing lines on near black). Please do not reuse those palettes. Say which colours are the same on purpose across things (for example "everything that hurts you has a hot rim and a tail of sparks").

### 2. The scenery
- The **background**: what the pyramid floats in, drawn once, so it can be rich, but darker and less saturated than the cubes and the sprites so it does not fight them. The area beneath the pyramid is **the void**: it must read as "if you fall here, you are gone".
- The **cube**: top diamond for each state, the left face, the right face, a one pixel edge line, shown as a picture of 32 x 32 with its tone map. The top diamond may carry a **pattern** (stripes, a dot, a ring) so the states can be told apart without colour.
- A **cube lit** effect (a brief glint when a cube completes), and a **ripple** (a recipe that runs over the 28 cubes in a few frames).
- The **discs**: on each side, 3 or 4 positions on a diagonal row (the proposal in section 4).
- A **shadow** of the hero on the cube if you want one (a few dim pixels).

### 3. Sprites (frame lists, with the sizes above)

| Sprite | Size | Frames and notes |
|---|---|---|
| Hero, standing | body 12 x 14 | facing down right and up right, 1 each, plus a blink (2) |
| Hero, hopping | same | for each of the 2 right facing directions, 3 frames: crouch, mid air, landing (the game mirrors for left) |
| Hero, falling | same | 4 frames of a tumble into the void |
| Hero, hit | same | by an enemy: a spin and a flash, 4 frames |
| Hero, on a disc | same | 2 frames, riding up |
| Hero, winning | same | a happy 2 frame jump |
| Chaser, egg or ball | body 10 x 10 | bouncing, 3 frames |
| Chaser, hunting | body 12 x 14 head, longer body | standing, hopping (3 frames each way, down right and up right), and the segments should read as a creature that is **dangerous** and not cute |
| Chaser, falling | | 3 frames, when it follows the hero off the edge |
| Bouncer | body 10 x 10 | 3 frames of a bounce (squash, up, stretch) |
| Freezer | body 10 x 10 | 3 frames, and a **freeze burst** (6 frames of a ring that spreads from it) |
| Undoer (sideways hopper) | body 12 x 12 | 3 frames of a hop, in the two facings |
| Frozen enemy | | the same sprites in a frozen tint (give it as a tint rule, not new art) |
| Disc | about 24 x 12 | spinning, 4 frames, and the same lifting off (2) |
| Cube states | 32 x 32 | state 1, 2, 3 (see section 2) |
| Score pop-ups | text | 25, 100, 300, 500: the 5 x 7 font is fine, say how they rise and fade |
| Lives icon | about 8 x 8 | the hero's head, shown in the HUD |
| Spark / landing puff | small | 3 frames, for a landing on a cube |
| Death flash | 12 x 14 | the hero's colour inverted for 2 frames |

Two points: **every frame must fit its body size** (or you say how much it overhangs), and the frame lists above are a **minimum**. If the hero needs an anticipation frame, add it and say where it would be used.

### 4. Screen layouts on the canvas
Give each screen as a list of "this text or sprite, in this colour, at this x and y" (origin at the top left):

- **In game**: the 28 cubes (give the **x and y of each cube's top left corner**, row by row), the **disc positions** (3 on the left, 3 on the right, say where), where the hero, the chaser and the enemies **start** (the first cubes below the apex), and the HUD. **A starting proposal** that you may adjust by about 4 pixels, but please send back the **final numbers**:
  - The HUD takes the top **32 rows**, the pyramid starts below it with its apex cube centred on the middle of the canvas (x = 128, so that cube's left edge is at x = 112).
  - Row *r* (1 to 7) has *r* cubes, each 32 apart, the row's first cube at x = 128 - 16 *r* and the cube's top at y = 48 + 24 *(r - 1)*. The bottom row ends at about y = 48 + 6 * 24 + 32 = 224, leaving 32 rows of void beneath.
  - Disc positions at about **8 pixels from a row's last cube** at rows 3 and 4 (check what looks right and give the numbers).
- **HUD**: the score, the high score, lives, level and round, the target cube. Give positions, font and colours.
- **Title / attract screen**: the name, a hint line (the controls), a blinking PRESS SPACE, and a short **intro** that shows the hero hopping down the pyramid once, painting it as it goes. A short animation is welcome (the game can play a sequence of frames on a timer; say how many pixels of the picture change).
- **Get ready** (a short READY banner at the start of every life), **level clear** (the ripple), **game over**, **paused**, and **a new high score**.
- Anything that makes the first five seconds feel special.

### 5. Effects (tell us which are worth it)
Ideas we think are affordable: a short flash and sparkle when a cube is completed, the ripple across the pyramid on a level clear, a trail of 3 dim pixels behind a hop, a soft shadow under the hero on its cube, a squash and stretch on every bounce, a flash of the whole target cube in the HUD when the hero completes the last one, falling sparks when anything leaves the edge, a ring when a freezer goes off, a slow drift of stars or lights behind the pyramid, the discs pulsing. Say which you want, which you would drop and what you would add.

## Later levels, so your style can cover them

Only the first level needs finished sprites now, but **please show one sketch tile or a short list for each of these** so the look holds together:

- **Three hop cubes**: the third state, and what the half state looks like.
- **Undo cubes**: the signal that a cube may turn back (a different edge line or a faint pattern).
- **Moving or flipping cubes** (optional, for a later level): a cube that flips over or shifts, one frame of the flip.
- **A bonus screen** if you think of one.

## Before you hand it back (checks)

- Every sprite reads at 2x, and the hero, the enemies and the cubes are told apart by shape and pattern as well as colour (run a colour blindness simulator over your preview).
- The hero reads clearly on **every** cube state and against the background.
- The chaser, the bouncer and the freezer can **never be mistaken for each other** in a quick glance (the first two are deadly, the third helps).
- The three cube states can be told apart in grayscale.
- Every sprite fits its body size, and the origin (the middle of the feet) is stated for each.
- The cubes tile exactly with no gap and no overlap on the pitch you chose, and a sprite standing on a cube sits at the middle of the top diamond.
- Nothing needs a full screen change every frame.
- Every colour is in the palette table, and every pixel of every sprite is either `.` or in a legend.
- Text has good contrast on every background it sits on.

## How to give it back

One markdown file, **`docs/design/cuber-art.md`**, starting with the art direction and the palette, then: the cube states and scenery as fenced blocks (named, with sizes and legends), every sprite as a fenced block (named, with its size, its origin, its legend and the colour table for tone maps), the animation recipes (frames, timings in milliseconds, how many pixels move), each screen as a list of "this text or sprite, in this colour, at this x and y" and the final cube and disc coordinates, and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions.

Also give **preview images** drawn at 3x with nearest neighbour scaling: `docs/design/cuber-preview.png` (a level part way through, with the hero mid hop, a bouncer, the chaser, some cubes in each state and the discs) and, if you can, the title and the game over screens (`cuber-preview-title.png`, `cuber-preview-over.png`). If you want to try a variant, give two and say which you prefer. Say if anything in your design needs a rule of the game to change.

## Context

- **The rules and the code**: nothing exists yet. The rules above are what we plan to build. The hop, the fall and the enemy moves are plain integer arithmetic on **cube coordinates** (a row and a column), so what matters for the art is that **the middle of a cube's top diamond is where every sprite's feet go**.
- **The nearest house style.** The Cookoff window (the launcher) is dark navy `0A0E16` with an orange accent. The other games' art is in `docs/design/` (`tetris-art.md`, `snake-art.md`, `space-invaders-art.md`, `asteroids-art.md`, `moonpatch-art.md`, `skylark-art.md`, with previews beside them). Look at `snake-art.md` for how a finished file looks and what level of detail is the right one.
- **Sound** is built separately, in the same spirit as the others (chiptune style), so you do not need to design for sound.
