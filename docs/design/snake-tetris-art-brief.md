# Snake and Tetris: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of two games at once, so they feel like a pair. It is a brief, not a spec: the numbers in "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake, Space Invaders and (nearly) Asteroids. Space Invaders and Asteroids each got a designed look: a palette, hand made art, screen layouts and effects, from a brief like this one. **Snake and Tetris have not**: they are drawn with flat coloured squares and a grid, and look like programmer art next to the others. This brief is to give them the same treatment.

Both are very well known, so the look must be **recognisable at a glance** (a long snake eating something, seven tetrominoes falling into a tall well) but **clean, modern and tasteful**: a loving remake by someone with taste in 2026, not a museum piece. The pair should share an art direction (palette family, type, how a block or a segment is shaded) while each keeps its own character. Space Invaders went neon pink, violet and cyan on indigo, and Asteroids went "Obsidian Line" (near black, warm white and steel lines), so please do not reuse either. The Cookoff window that launches all the games (dark navy, an orange accent, rounded glossy blocks, see "Context") is the nearest thing to a house style and a good starting point for the mood.

## The plan, in order

1. **Read this brief, then `docs/design/asteroids-art.md`** (the designer's answer for Asteroids). That file is the format and the level of detail we want back: every colour named, every shape as a block we can paste into code, every screen as a list of "this, in this colour, here". Skim `docs/games/tetris.md` and `docs/games/snake.md` for the rules.
2. **Choose the art direction for the pair**: a name, a paragraph, the shared palette family and the type (the 5 x 7 pixel font, see below). Say what is shared and what is different on purpose.
3. **Design Tetris**: the block tile and its seven colours, the ghost, the well and the panel, the HUD, the screens and the effects.
4. **Design Snake**: the head, body, tail and food tiles, the floor, the border, the HUD, the screens and the effects, at two tile sizes.
5. **Check your own work** against the list at the end ("Before you hand it back").
6. **Hand it back** as two markdown files and two preview images (see "How to give it back").

If you want to try two directions for one game, give both and say which you prefer.

## How the picture is made (please read, it decides what is possible)

Today both games draw one flat colour per logical cell with a grid between cells. The new look needs more than that, so **both games will move to a pixel canvas, the way Space Invaders and Asteroids draw**: a grid of pixels, each pixel one flat 24 bit colour, shown scaled up with hard nearest neighbour edges. Each logical cell of the game (a square of the well, a segment of the snake) becomes a **tile of pixels**, and we choose the tile from the cell's state and its neighbours. The game rules do not change.

### The hard limits

- **No anti-aliasing and no blending.** A pixel is one colour, and a later draw replaces an earlier one. Transparency is a pixel you leave out (the background shows through). A soft shadow or glow is made of extra pixels in dimmer colours.
- **Tile sizes.** Design every tile at **16 x 16 pixels**. For Snake also give the same set at **8 x 8** (the game uses 16 on boards up to 20 cells across and 8 on bigger ones, so the canvas stays about 320 x 320 pixels at most). Tetris uses 16 only.
- **Shown scale.** The canvas is scaled by a whole number (2x, 3x or more, whatever fits the screen), so **every detail must still read at 2x**, where one pixel is two screen pixels. A 1 pixel highlight is fine, a 1 pixel dot that carries meaning is not.
- **Budget.** Tetris is a 17 x 20 cell canvas (the well, a divider column and a panel six cells wide) = **272 x 320 pixels**, redrawn only when something changes, up to 60 frames a second during an animation. A full screen effect that changes every pixel every frame (a moving gradient, a shake of the whole picture) is not affordable. Up to about **60 particles** (single pixels or short lines) at a time is fine. A static background drawn once is free.
- **Text is made of pixels too.** We have a **5 x 7 pixel capital letter font** (digits and basic punctuation included), drawn at 1x, 2x or 3x, in one colour or a vertical gradient, with an optional one pixel dark outline. If you want a second smaller font for the HUD, give its glyph bitmaps.
- **Colours must be told apart by more than hue** (see `docs/accessibility.md`): the seven Tetris pieces especially. Give each piece a different inner mark or shading pattern as well as a colour, so a colour blind player can still tell an S from a Z at a glance. Keep good contrast between neighbouring values and the background.

### The tile format we will use

A tile is rows of characters, one per pixel, with a legend. `.` is transparent. Letters stand for colours listed in a legend table. To keep the files short and let one design serve many colours, **give a block tile as a tone map plus a colour table**: the rows use the tone characters `1` (highlight), `2` (light), `3` (base), `4` (shade), `5` (edge), and then for each piece (or each part of the snake) a row of the table gives the five hex values for tones 1 to 5. Anything that is not a recolour (an eye, a mark) uses letters `A` to `H` with their own hex values in the legend. For example, a bevelled 8 x 8 block:

```
55555555
51222234
52333334
52333334
52333334
52333334
53444444
44444444
```

You may use any number of colours in a tile, but say so, and keep each tile's legend to 16 colours or fewer.

## The rules, so the screens make sense

### Tetris

- A **well 10 cells wide and 20 high**. Seven pieces (I, O, T, S, Z, J, L) fall one at a time from a shuffled bag; today's colours are I cyan, O yellow, T purple, S green, Z red, J blue, L orange, and you may change them but the pieces must stay easy to tell apart. A **ghost** copy shows where the piece will land (it can be turned off). The next piece shows in the **panel on the right** (a 6 x 6 cell area beside a one cell divider).
- Keys: Left and Right move (they repeat), Down is a soft drop, Up or X turns clockwise, Z anticlockwise, Space is a hard drop, P pauses, R starts again, G toggles the ghost.
- A full row disappears and the rows above drop. 1, 2, 3 or 4 rows score 100, 300, 500 or 800 times the level. A soft drop scores 1 a row, a hard drop 2 a row. The level goes up every 10 lines, from 1 to 30 and the fall speeds up (800 ms a row at level 1, 50 ms from level 11).
- The game ends when a new piece has no room. The ten best scores are kept.
- Things to show: **score, lines, level, the next piece, the best score**. Today they are in the window's status bar; we would like them **drawn on the canvas beside the well** (in the panel and below it), so say where each goes.

### Snake

- A snake on a board with **walls**. It moves one cell at a time (150 ms a step at the start, faster with every food, down to 60), turns with the arrow keys, grows by one for each piece of **food**, and the game ends when it hits a wall or itself. Filling the board wins.
- **The board size varies**: seven sizes from 10 x 10 to 40 x 40 (20 x 20 is the default, and 30 x 20 and 40 x 30 are wide). The canvas is the board's size times the tile size, so the art must work on any of them.
- The game waits for a key at the start ("PRESS AN ARROW KEY"). Score is 10 for each food. Things to show: **score, length, level, the best score**. Today they are in the status bar; we would like them drawn on the canvas, in a strip above or below the board, so say which.
- A direction is known for the head, so it can show the way it is facing. The body is a ring of cells: each cell knows its neighbours on both sides, so **straight and corner pieces** are possible, and the last cell is the tail.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the pair. A palette as a table of names and hex values: the background (flat, a gradient, or a dark pattern drawn once), the well and its walls, the seven piece colour rows (five tones each), the ghost, the divider and panel, the snake rows (head, body, tail, five tones each), the food, the board floor and walls, the text colours, the HUD and highlights. Say which things share a colour on purpose.

### 2. Tetris tiles and parts (16 x 16)

| Part | Notes |
|---|---|
| Block tile | The tone map above, plus the table of five tones for each of the seven pieces. Say what **mark or pattern** tells each piece apart besides colour (a different bevel, a small inner shape, a stripe). Give any per piece tile that differs |
| Ghost block | A dim outline or a hatched tile, clearly not a real block |
| Well | The floor, the walls (left, right, bottom) and the empty cell. A faint grid or a plain dark floor, your call, but an empty cell must be a tile that does not fight the blocks |
| Divider and panel | The one cell divider and the 6 x 6 cell next piece panel, with its frame |
| Line clear | How a full row disappears: a flash, a wipe, a dissolve. Give the frames, and how many a row of 4 (a "Tetris") differs. Today a cleared row vanishes at once, so say how long the animation needs (we can add a short pause of about 0.3 s) |
| Lock | A brief flash or bounce when a piece settles |
| Hard drop | A streak or trail from the old place to the new |
| Level up | A short flourish |
| Game over | The well fills or dims; the banner |

### 3. Snake tiles and parts (16 x 16, and the same set at 8 x 8)

| Part | Notes |
|---|---|
| Head | 4 directions (give one and say which turns are mirrored or rotated). Eyes, a tongue flick, whatever suits. It must read at 8 x 8 |
| Body | A straight piece (horizontal and vertical) and the four corner pieces. Say if the body has a pattern that runs along it |
| Tail | 4 directions, tapering |
| Food | 2 to 4 frames if it animates (a pulse or a sparkle). A thing recognisable as food, at both sizes |
| Floor | The empty cell: a plain dark tile, a checkerboard of two close tones, a faint dot, your call. Say how the two tile sizes tie up |
| Border | The wall around the board: the edge pieces and the four corners |
| Eat | What happens when the food is taken: a pop, a ring, a flash on the head, the body bulging as it grows |
| Crash | How the game ends: the snake flashes and fades, or breaks into pieces, over about a second |
| Win | Something for filling the whole board |

### 4. Screen layouts
Where things sit and how they look. Give positions in **canvas pixels** (x across, y down, top left origin), the font, the size (1x, 2x or 3x) and the colour:

- **Tetris, in game**: the panel (NEXT and the piece), SCORE, LINES, LEVEL, HI-SCORE; the well beside it. Remember the canvas is 272 wide, and the well occupies the left 160 pixels, the divider the next 16, and the panel the last 96.
- **Tetris pause, game over, and the first seconds** (a start up animation is welcome).
- **Snake, in game**: the HUD strip (score, length, level, best) and the board. Show it for the 20 x 20 board (a 320 x 320 canvas plus a strip) and say how the strip behaves on a narrow board (10 x 10 is only 160 pixels across).
- **Snake waiting for a key** ("PRESS AN ARROW KEY"), **game over**, **you win**, and a **new best score** note.

### 5. Effects (tell us which are worth it)
Ideas we think are affordable: a soft glow at a line clear, small sparks when a piece locks, a slight trail behind a hard drop, the score digits pulsing on a big score, the snake's body brightening in a wave as it eats, a faint slow drifting pattern in the background, a gentle pulse on the food. Say which you want, which you would drop and what you would add. The budget is in "The hard limits".

## Before you hand it back (checks)

- Every tile reads at 2x. The seven Tetris pieces are told apart by mark as well as colour (run a colour blindness simulator over your preview).
- Text has good contrast on every background it sits on.
- The Snake art works at 8 x 8 as well as 16 x 16, on the smallest and biggest boards.
- Nothing needs a full screen change every frame.
- Every colour is in the palette table, and every pixel of every tile is either `.` or in a legend.

## How to give it back

Two markdown files, **`docs/design/tetris-art.md`** and **`docs/design/snake-art.md`**, each starting with the shared art direction and the palette rows it uses, then: every tile as a fenced block (name it, give its size, its legend, and the colour table for tone maps), the animation recipes (frames, timings, how many pixels move), each screen as a list of "this text or tile, in this colour, at this x and y", and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions. Also give **two preview images**, `docs/design/tetris-preview.png` and `docs/design/snake-preview.png`, drawn at 3x with nearest neighbour scaling, showing the in game screen of each (Snake on 20 x 20) and, if you can, the title or game over screen too. Say if anything in your design needs a rule of the game to change.

## Context

- **What the games look like now.** Tetris: a 10 x 20 well drawn as flat coloured squares with grid lines, a six cell panel for the next piece, the status bar for the numbers, a PAUSED or GAME OVER banner over the middle. Colours today (view codes): empty `12161B`, I `3CC9D6`, O `F2C14E`, T `A06BE0`, S `4CC38A`, Z `E5533D`, J `4F7DE8`, L `F0883E`, ghost `2A3441`, divider `181C20`, panel `1A1F25`. Snake: flat squares in four colours, empty `1E242B`, body `3FAE78`, head `8EF0C0` (lighter so the facing shows), food `E5533D`, with grid lines.
- **The nearest house style.** The Cookoff window (the launcher) is dark navy `0A0E16` with a `0E131E` gradient, a faint white grid, an orange accent and rounded glossy blocks drawn in the colours of the games. Asteroids' art is in `docs/design/asteroids-art.md` and Space Invaders' in `docs/design/space-invaders-art.md`, with `preview.png`, `asteroids-preview-title.png` and `asteroids-preview-ingame.png` beside them.
- **What stays the same.** The rules, the keys, the speeds and the scoring. The status bar and the window title will keep their text for the screen reader and for people who prefer it.
