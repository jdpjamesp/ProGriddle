# Centipede: art and de-branding brief

Written for: the designer who will make the look and the names of the game. It is a brief, not a spec: the numbers in "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. This game is a fixed shooter that was built as a close copy of a famous 1981 arcade game: a long creature crawls down a field of obstacles towards a small shooter at the bottom, and every shot that hits it leaves a new obstacle behind. Three pests make it worse. The code is working and fully tested, and it uses plain placeholder shapes and colours in one place each.

**The job is to give it its own identity.** We want a design that is faithful to what makes the game play and feel the way it does, and as close to the original as it can be in structure, but that is not a copy of the original's look, names or characters. Think "same dance, different dancers". Concretely:

- **Keep** (these are the rules of the game, and the code depends on them): the shape of the screen, the field of obstacles that takes four hits, the segmented crawler that turns at an obstacle and drops a row, the shooter held to the bottom rows, the split of a crawler when a segment is hit, the three pests and what each does to the field, the colour changing of a wave, the sense of a busy, bright, slightly menacing garden at night.
- **Change** (everything you can see or read): every name, the drawn shapes of every creature, the obstacle, the shooter and the shot, the palette, the logo and the type. Do not use the original's names, its characters, its colour scheme or its exact silhouettes. A person who knows the original should recognise the game from how it plays and how the screen is arranged, and a person who has never seen it should find a game with a look of its own.
- **Do not name the original game** in your files or in any text you write. Describe things by their role ("the crawler", "the obstacle") and give them your own names.

The mood to aim for is the one of the neon look already in the game, a bright, glowing field on a dark night, but made with more care: a limited, chosen palette, crisp pixels, a few well judged flashes of light. Study the "Lantern Glass" work for Tetris and Snake (`docs/design/tetris-art.md`, `docs/design/snake-art.md`) and the finished look of Skylark (`docs/design/skylark-art.md`) for the quality bar and the way a design file is written.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas**: a grid of cells, each one flat 24 bit colour, shown scaled up with nearest neighbour edges (no anti-aliasing, no blending: a later draw replaces an earlier one, except where a pass is explicitly a tint).

### The hard limits

- The picture is **240 x 256 cells**: a strip of **16 rows** at the top for the numbers, then the **board of 30 x 30 tiles of 8 x 8 cells** (240 x 240). It is normally shown at 3x, so **every detail must read at 2x and 3x**.
- Everything is on a tile grid except that things move a cell at a time: the crawler, the shooter and the pests are positioned in cells, not tiles.
- The **shooter** lives only in the bottom 6 rows of the board (the player zone, rows 24 to 29) and its box is 6 x 6 cells. It may be drawn up to 8 x 8.
- **Sprites** are given as grids of palette indexes, one row per line, with `.` for transparent. A cell is either colour or transparent. Ordinary things are 8 x 8 (crawler segment, obstacle, shooter, shot) and the pests may be 8 x 8 or 8 wide by 16 tall. Say each sprite's size and where its collision box sits (boxes are rectangles, not the outline).
- Up to **8 colours plus transparent** per sprite and a master palette of **at most 48 named colours** for the whole game.
- **Budget:** up to 150 obstacles and about 20 other moving things on screen, and up to 60 particle cells at once. The obstacles are baked into the background and redrawn only when one changes, so a good obstacle design can be a little richer than a moving sprite.
- Text is made of cells: a **5 x 7 capital letter font** (digits and capitals, plus a few marks), at 1x, 2x or 3x, in one colour or a vertical gradient. If you want a different font, give it as a grid.
- Effects are functions of the game's own clock, as in Tetris and Snake: they must be drawable from "frames since it started", not from state kept between frames. The game runs at 60 frames a second.

## What is on the screen (the things to design)

### The field and the obstacle
- The playfield is a dark night with a quieter band for the player zone and faint rules between rows. Give the ground, the band and the strip of numbers their look.
- The **obstacle** (a mushroom in the placeholder, give it your own idea: a rock, a coral, a pylon, a flower...) is one 8 x 8 tile and has **four states of health**, from whole to nearly gone, each hit taking a bite out of it. Draw the four states so they read as the same thing wearing down, and so the whole field reads as a field, not as noise, when 150 are on screen.
- A **poisoned** version of every state (the scorpion's touch, see below), in a clearly different colour. Colour blind safe: the poison must differ in lightness as well as hue.
- A flash for a hit and a short disappearance for the last one.
- An obstacle that is **repaired** (made whole again after the shooter dies) should have a small glint, one frame or a few.

### The crawler (the long creature)
- A body of **segments** and a **head**, each 8 x 8. The head is the segment that leads, and a loose head also appears on its own in later waves, so the head must read at a glance as the dangerous end.
- The segments crawl left or right along a row and then drop one row and turn round, so draw **left and right facing** versions (or one that mirrors) and **2 to 4 frames of walking** that loop. Frames are chosen from the game's clock, so a train of segments should walk in a ripple, not all in step.
- A head going down and a head climbing up (it climbs back through the player zone at the bottom) may be drawn the same or differently, your call.
- A **poisoned** crawler dives straight down: give it a tell (a tint, a flicker) so the player can read why it has changed.
- A new wave may use a new colour scheme: give the crawler **at least 6 palettes** (wave 1 to 6 and then they repeat), each with a colour for the body and the head, and a different colour for the obstacle's tint so the whole screen shifts with the wave. Say how the waves are named or numbered.
- Death of a segment: a small burst that leaves an obstacle where it was. Show the moment of the swap (burst, then obstacle appearing) in a few frames.

### The shooter and the shot
- The shooter is 8 x 8, always facing up, bright, easy to find among everything else. 2 frames of idle motion (a flicker, a glow) are nice.
- The **shot** is one cell wide and about 4 cells tall, very bright. Only one is in flight at a time and it flies 8 cells a frame, so make it look fast.
- The shooter's **death**: the shooter breaks up over about a second (3 to 6 frames of pieces, then the field is mended with the glint described above). Say how long each frame lasts in game frames.
- A muzzle flash of a frame or two when it fires, if you want one.
- The shooter must not be confused with any hazard: choose a colour of its own that no pest or crawler ever uses.

### The three pests
Each has its own rule in the game; keep the roles and change the creature.

| Role in the game | What it does | Notes for the art |
|---|---|---|
| **The dropper** | Falls straight down a column leaving obstacles behind it. It takes two hits and moves faster after the first. | 8 x 8 or 8 x 16, 2 frames, plus a second look for the hurt state (a hit in a different colour or a flash). Its trail of new obstacles should look as if it dropped them. |
| **The zigzagger** | Bounces diagonally across the lower rows, eating obstacles as it goes, and can kill the shooter. Scores more the closer it is shot to the shooter (900, 600 or 300). | The most dangerous pest, the most animated one: 4 frames of a legged or spinning movement. Make its path readable (it should look like it is about to turn). |
| **The poisoner** | Crosses the upper rows from the side, turning every obstacle it touches poisonous. It cannot hurt the shooter. | 8 x 8 or 8 x 16, 2 to 4 frames. Reads as strange but harmless to touch. Colour should hint at the poison colour. |

The points shown on a pest's death (and of the crawler's head) should appear as small text for about half a second where it died: give the colour and the size (1x is enough).

### The strip and the screens
- **The strip** (16 cells high, top of the picture): the score on the left, the best score in the middle, the lives as small shooter icons on the right, and the wave number. Say where each goes, in cells.
- **Title screen:** the name, in a logo you draw from cells, over a **crawler that walks across the screen**. Below it a blinking "PRESS SPACE". The play is a long, calm title screen, so give it some life (a drifting spore, a pulse of the field).
- **Wave start** (a quick "WAVE n" line over the field) and **wave cleared** ("WAVE n CLEARED", with the bonus if there is one).
- **Game over:** the words, the final score, and the best score if it was beaten.
- **Paused:** a plate over a dimmed board.
- Say what the **extra shooter** looks like when it is won (a flash on the lives, a small text).

### Motion and finish (the "modern" part)
Say what you want, and what it costs in cells or particles. Ideas, all optional:
- A soft **glow** under bright things (the shot, the head of the crawler, the shooter) as a few cells of lighter colour round them, drawn as part of the sprite.
- A faint, slow **drift** of motes or stars in the background (a few cells, a function of the clock).
- A short **light** on the field when something big dies, brightening the nearest obstacles for 3 to 5 frames.
- Scan line or phosphor softness as a pass that can be switched off.

## What we need from you

1. **A name and an idea for the game and a one paragraph art direction.** A name for the game, for the shooter, for the crawler and its head, for the obstacle and for the three pests. All original, none of the original's. Say what world it is in.
2. **The palette.** At most 48 named colours as a table (name, hex), grouped by use: ground and band, obstacle (whole to worn, and poisoned), crawler (a body and head colour for each of 6 waves), shooter, shot, the three pests, bursts and sparks, text and strip. Say which colours are shared on purpose (for example every danger always has one family of colours so the player learns to read them) and show that the shooter's colour, the poison colour and the crawler's colours can be told apart for the three common kinds of colour blindness.
3. **Sprites** as palette index grids with their sizes, frames and boxes (listed above).
4. **The screens**: the title with its logo, the start and clear of a wave, game over and pause, and the strip, with the cells they occupy and the type.
5. **Previews.** Please make pictures of the in game screen (wave 1 and a later wave), the title, a busy moment with the crawler split in two and a pest on the screen, and a sprite sheet. The best way is a small script that reads your design file and writes the pictures (like `docs/design/skylark-generator/`), so the pictures and the text cannot disagree.
6. **A short list of what you decided** that the code might need to ask about, and the questions you could not settle.

## What you can leave to us

The crawling and turning, the speeds, the collision boxes, the waves and the timing, the points and the sounds are done in code and should not be redesigned. You describe only how it looks and what it is called.

## Where the art goes

- Sprites: a new class `CentipedeArt` (working name, to be renamed with the game), one place, sizes must stay.
- Colours: `CentipedeLook` and the `CentipedeTint` enum (both exist already, with placeholder colours).
- Names and text: the title, the words on the screens and the status line.
- When your design file is ready (say `docs/design/<game>-art.md`), a generator script (like `tools/gen-foreach-art.py`) writes these classes from it. They are generated, so change the design file and run the script, never edit the classes by hand. The game, the docs page (`docs/games/centipede.md`) and the Cookoff entry will be renamed together once the name is chosen.
