# Girder Rush: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers under "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake, Space Invaders and Asteroids. The next game is a **barrel climbing platformer**, in the spirit of the 1981 arcade classic about a gorilla, a captive and a worker who climbs a building site to rescue them: a big ape at the top throws barrels that roll down sloping girders, and you jump them, climb ladders around them, and smash them with a hammer on the way up.

**Working title: Girder Rush.** It is only a working title, and a new name is welcome if you have a better one. We will **not** use the original's name or any of its character names.

### Recognisable, but not a copy (please read twice)

The game must be **recognisable at a glance as that kind of game**: a big ape at the top of a structure of sloping girders and ladders, barrels rolling down, a small hero at the bottom climbing up to a captive. But the pictures should be **our own**, and **modern**, not a pixel for pixel copy of the arcade sprites:

- **Do not** use the original's hero (no red cap and blue dungarees with a moustache), its ape's exact design, its captive's pink dress and hair, its exact girder colour scheme (red girders on black) or its title lettering. Do not draw anything that someone would call a trace of the original.
- **Do** keep what makes the idea readable: a **large, heavy ape** in a confident pose, **round barrels with hoops** that roll, **steel girders with rivets**, **ladders**, an **oil drum that flames**, a **hammer** power-up, a **small hero with a clear silhouette** that reads while running, climbing and jumping.
- Ideas, take or leave them: the hero is a **construction worker in a hard hat and a hi-vis vest** (a strong two colour silhouette: hat and vest); the captive is **not necessarily a person** (a friend, a dog, a little robot that sits on a lamp, a person in a hard hat, anything friendly and readable at 10 pixels wide, and give them an attention grabbing wave); the ape can be a **modern, slightly cartoon gorilla** with big shoulders and expressive eyes, wearing something that ties it to the site (a tool belt, a stripe of hazard tape, a safety helmet that is too small).
- The tone is a loving remake by someone with taste in 2026: **bright, clean, chunky pixels, rich colour, a little juice**. Not grim, not museum.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas** (the same one Space Invaders and Asteroids use): a grid of pixels, each pixel one flat 24 bit colour, shown scaled up with hard nearest neighbour edges. Sprites are drawn over a background that is already coloured, and the girders and ladders are drawn into that background.

### The hard limits

- The canvas is **224 columns by 256 rows** (the arcade's own resolution), shown at 3x (672 x 768) where the screen is tall enough, else 2x. **Every detail must still read at 2x**, where one pixel is two screen pixels: a 1 pixel highlight is fine, a 1 pixel dot that carries meaning is not.
- **No anti-aliasing and no blending.** A pixel is one colour and a later draw replaces an earlier one. Transparency is a pixel you leave out. A soft shadow or glow is made of extra pixels in dimmer colours.
- **Sprite sizes.** The game's rules use the **body** of a sprite for hits, so the sizes below are limits for the solid body. A one pixel outline or a dim halo may sit outside it, and say so if it does.
  - Hero body **12 wide by 16 high** (a 14 x 18 picture with an outline is fine). Its origin is the **middle of its feet**: the point that stands on the girder.
  - Barrel: body **12 x 12** (a circle of radius 6 for hits).
  - Fireball: body **10 x 10**.
  - Everything else (ape, captive, scenery) is not hit by anything, so it can be any size that fits the layout. The ape may be up to about 48 x 40.
- **Facing.** Design everything that walks **facing right**; the game mirrors it for left. If your shading would look wrong mirrored (a light from the top left), either design so it does not matter or give the left facing frames too and say so.
- **Cheap per frame.** A handful of moving sprites and up to about **60 particles** (single pixels, or lines of 2 or 3) is fine. A full screen effect that changes every pixel every frame (a moving gradient, a shake of the whole picture) is not affordable. A static background drawn once is free.
- **Text is made of pixels too.** We have a **5 x 7 capital letter font** (digits and basic punctuation included), drawn at 1x, 2x or 3x, in one colour or a vertical gradient, with an optional one pixel dark outline. If you want a smaller font for the HUD, give its glyph bitmaps.
- **Colours must be told apart by more than hue** (see `docs/accessibility.md`): the hero, the barrels, the fireballs and the ladders must differ in **shape or pattern** as well as colour, and have good contrast against the girders and the background.

### The sprite format we will use

A sprite is rows of characters, one per pixel, with a legend. `.` is transparent. Give frames as separate blocks named `Hero walk 1`, `Hero walk 2` and so on.

Use the **tone format** of the Snake and Tetris art: for a part that is recoloured or shaded, the rows use `1` (highlight), `2` (light), `3` (base), `4` (shade), `5` (edge), and a colour table gives the five hex values for tones 1 to 5 for each colour row (hero vest, ape fur, barrel wood and so on). Anything with its own fixed colour (an eye, a rivet, a flame) uses letters `A` to `H` with their own hex values in the legend. Keep each sprite's legend to **16 colours or fewer**, and say so if you need more. Look at `docs/design/snake-art.md` section 0 for how that file lays it out: we paste the result into code with no decisions left.

### The girders and ladders are special: they follow the slope

Girders in this game **slope**: a girder is a straight line from one height at its left end to another at its right end, and the hero and the barrels move along the top surface. So a girder is **not** a tile that you place on a grid. Instead:

- Give the girder as a **profile**: a repeating pattern **16 pixels wide and 8 pixels high** (top surface row, the web, the rivets, the bottom flange). The game draws it **one column at a time**, moving each column up or down by the slope (1 pixel every 16 columns in the proposal below), so the pattern follows the line. Design it so that a one pixel step up or down every so often still looks right (no row of rivets that a step would cut in half).
- The **top row of the profile is the surface** the hero stands on. Say which row it is.
- Give the **ends**: how a girder ends at the left and right (a plain cut, a cap, a bracket, a column it rests on). Barrels fall off an end, so the end must read as "the edge".
- **Ladders** are **10 pixels wide**. Give one rung tile (10 wide, 4 high) that the game repeats down the ladder, plus a top cap and a bottom foot. Also give a **broken ladder** (the middle part is missing, so it cannot be climbed but barrels may still roll down it).

## The rules, so the screens make sense

This is **stage 1** (the barrels). Later stages are listed at the end, so the style can cover them.

- The hero starts at the bottom left. The captive is at the top. The ape stands on a platform at the top left and throws barrels. The hero must climb all the way up to the captive to finish the stage.
- There are **five sloping girders** between the ground and the top, each sloping the other way to the one below it, joined by ladders (some whole, some broken). Barrels roll along a girder with the slope, turn at the end and fall onto the girder below (and sometimes go down a ladder).
- The hero **walks** left and right, **climbs** a ladder up or down (no gravity while climbing, and cannot jump while on a ladder), and **jumps** (a fixed arc that cannot be steered, about **18 pixels high** and about 24 long). Touching a barrel or a fireball loses a life.
- **Jumping over a barrel scores**: 100 for one, 300 for two or more in one jump.
- **Hammers**: one or two power-ups on the girders. Grab one and for a few seconds the hero swings it, **smashing barrels and fireballs** (a score of 300 to 800) instead of being hurt, and cannot climb or jump while holding it.
- An **oil drum** sits at the bottom left. A barrel that reaches it sets the drum **burning**, and a **fireball** is born from it, chases the hero up the ladders and turns at the girder ends.
- **Bonus items**: three or four small things (the arcade left a hat, a purse and an umbrella lying about) lie on the girders and score when touched. Please design **3 of your own**.
- A **bonus timer** counts down from 5000 in steps of 100, and what is left when the stage ends is added to the score. Reaching the captive ends the stage: the ape reacts and the next stage begins.
- Three lives, an extra one at 7000 points. Scores: a barrel jumped 100 or 300, a hammer smash 300 to 800, a bonus item 300 to 800 (say so if you want different values).
- The HUD: the score (6 digits), the high score, the lives left, the stage number, the bonus timer.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look, and a **palette** as a table of names and hex values: the background, the girders (surface, web, rivets, shadow), the ladders, the hero (hat, vest, skin, trousers, boots), the ape, the captive, barrels (wood, hoops, the highlight), the wild barrel (see below), the oil drum and its flames, the fireball, the hammer, the bonus items, the text and the HUD.

It should be a **sibling of the other games, but its own thing**. The nearest ones are Lantern Glass (Tetris and Snake: dark navy, one amber lamp, glassy jewel colours, light from the top left), Space Invaders (neon pink, violet and cyan on indigo) and Asteroids (glowing vector lines on near black). Please do not reuse those palettes. A **construction site at dusk** is the obvious direction (cool steel and slate against a deep sky, safety yellow and orange for the things that matter, a warm lamp, a little rust), but your idea is welcome. Say which colours are the same on purpose across things (for example "everything that hurts you has a warm hot rim").

### 2. The scenery
- The **background**: a sky and a distant skyline of unfinished buildings, or a night site with a crane. It may be a vertical gradient with a few static shapes. It is drawn once, so it can be rich, but it must **not fight the girders and the sprites** (keep it darker and less saturated than anything that moves).
- The **girder profile**, its **left and right ends**, the **ladder rung, cap and foot**, the **broken ladder**, a **column or support** where a girder meets the side (optional), the **ground line** (the bottom girder is flat), the **top platform** the ape stands on and the **captive's platform**.
- A **rivet** shine or sparkle if you want one (see effects).

### 3. Sprites (frame lists, with the sizes above)

| Sprite | Size | Frames and notes |
|---|---|---|
| Hero, standing | body 12 x 16 | 1, plus a blink or idle fidget (2) if you want it |
| Hero, walking | same | 3 or 4 frames |
| Hero, climbing | same | 2 frames that alternate (hands and feet), and 1 for the top of the ladder where the hero climbs onto the girder |
| Hero, jumping | same | 1 rising and 1 falling (or 1 for both) |
| Hero, with the hammer | the hero, with the hammer up (above the head) and down (in front), and a body that still fits 12 x 16 | 2 frames, walking while holding it, facing right. The hammer may stick out wider than the body: give its full size and its hit position |
| Hero, hit | body 12 x 16 | the death: a spin and fall of 4 to 6 frames, then a final frame lying or a puff, over about 1.5 seconds |
| Hero, winning | | a happy 2 frame jump or wave for when the captive is reached |
| Ape | up to 48 x 40 | **idle** (breathing, 2 frames), **grabbing a barrel** from the stack (2 frames), **throwing** it (2 frames), **pounding its chest** (2 frames, for the start of the stage), **angry/looking at the hero** (1), **defeated** (2 frames, for when the hero reaches the captive: it falls, tumbles away or sulks) |
| Barrel stack | about 24 x 24 | the barrels next to the ape: 1 frame, and 1 with one barrel missing |
| Barrel, rolling | body 12 x 12 | **4 frames** of the roll, right to left in the sprite's rotation so the loop is seamless (the game rolls it either way) |
| Barrel, falling | 12 x 12 | 2 frames, tumbling as it drops from one girder to the next |
| Barrel, going down a ladder | 12 x 12 | 1 or 2 frames |
| Wild barrel | 12 x 12 | a **different** barrel (another colour and a different hoop pattern) that does not follow the girders and rolls straight down; same frames as above, and they must read as different at a glance |
| Oil drum | about 16 x 16 | 1 frame cold, and a **flame** of 3 frames that keeps burning once it is lit |
| Fireball | body 10 x 10 | 2 or 3 frames of flicker, facing both ways if it matters |
| Hammer power-up | about 10 x 10 | 1 frame, plus a glint of 2 frames |
| Captive | about 10 x 16, or what you decide | idle (2), calling for help (2, with the word HELP in a speech bubble as text or as a drawn bubble), rescued (2) |
| Bonus items | about 10 x 10 each | 3 of your own, 1 frame each, plus a sparkle for when one is taken |
| Score pop-ups | text | 100, 200, 300, 500, 800: the 5 x 7 font is fine, say how they rise and fade |
| Lives icon | about 8 x 8 | the hero's head or hat, shown in the HUD |
| Barrel smash | 12 x 12 | 3 frames of a barrel bursting under the hammer (planks and a ring of hoops flying out) |
| Fireball smash | 10 x 10 | 3 frames |
| Smoke or dust | small | a puff for a landing after a jump and for a barrel hitting a girder: 3 frames |

Two points: **every frame must fit its body size** (or you say how much it overhangs), and the frame lists above are a **minimum** (if you think the hero needs a skid frame at the end of a run, or the ape a taunt, add them and say where they would be used).

### 4. Screen layouts on the 224 x 256 grid
Give each screen as a list of "this text or sprite, in this colour, at this x and y" (origin at the top left):

- **In game, stage 1**: the six levels of girders and the ladders, where the ape, the barrel stack, the captive, the oil drum, the hammers and the three bonus items stand, and where the hero starts. **A starting proposal** that you may adjust by about 4 pixels, but please send back the **final numbers**:
  - The HUD takes the top 32 rows.
  - The ground is a flat girder with its surface at **y = 240**. Above it, five sloping girders have their surface at the left end at about **y = 208, 176, 144, 112, 80**, each sloping across its length of about 200 pixels by about **12 to 14 pixels** (1 pixel every 16 columns), the lowest girder sloping up to the right, the next up to the left, and so on. The top platform (the ape's) is flat at about **y = 56**, and the captive's platform is a little higher and to the right.
  - There must be at least **28 pixels of clear height** above every girder (the hero is 16, a jump is 18 high), and ladders are 10 wide and join one girder surface to the one above.
  - Please give the **ladder positions** (x and which girders each joins, and which are broken) that you think make a good, fair stage: about 2 whole ladders and 1 broken per girder.
- **HUD**: SCORE (6 digits), HIGH SCORE, lives, the stage number, the bonus timer in a box. Give positions, font and colours.
- **Title / attract screen**: the name, a hint line (the controls), a blinking PRESS SPACE, and the **intro** that the arcade had and everyone remembers: the ape climbs up the structure with the captive over its shoulder and plants itself on the top. A short animation is welcome (the game can play a sequence of frames on a timer; say how many pixels of the picture change).
- **Get ready** (a short READY banner at the start of every life), **stage clear**, **game over**, **paused**, and **a new high score**.
- Anything that makes the first five seconds feel special.

### 5. Effects (tell us which are worth it)
Ideas we think are affordable: dust on a landing, a spark where a barrel hits a girder, rivets that glint now and then, a hot glow round the oil drum (a few dim pixels that pulse), a short trail behind a rolling barrel, a flash on a hammer smash and a ring of debris, a score pop-up that rises, the screen's lamps flickering a little, a slow drift of cloud or smoke in the sky behind the girders, the ape's chest-pounding shaking one or two girders by a pixel (we can offset a girder's rows briefly), the hero's hat flying off when hit. Say which you want, which you would drop and what you would add.

## Later stages, so your style can cover them

Only stage 1 needs finished sprites now, but **please show one sketch tile or a short list for each of these** so the look holds together when we build them:

- **Stage 2, the pie factory**: flat girders with **conveyor belts** that move the hero (a belt surface with animated arrows or rollers, 2 frames), pies or crates that roll along them, an oil drum or a hopper at the top that drops fireballs.
- **Stage 3, the elevators**: **lifts** that move up and down (a platform sprite 16 x 8, a cable, a shaft), and **springs or bouncing hazards** the ape throws.
- **Stage 4, the rivets**: a symmetrical site with **8 rivets** to remove by walking over them (a rivet sprite in two states, in place and removed, and the hole), and fireballs only.
- A **bonus screen** if you think of one.

## Before you hand it back (checks)

- Every sprite reads at 2x, and the hero, the barrel and the fireball are told apart by shape and pattern as well as colour (run a colour blindness simulator over your preview).
- The hero reads clearly against **every** girder, ladder and background it can stand in front of.
- The two kinds of barrel and the fireball can never be mistaken for each other in a quick glance.
- Every sprite fits its body size, and the origin (the middle of the feet for the hero) is stated for each.
- The girder profile still looks right with a one pixel step every 16 columns, and a barrel rolling along it does not look as if it floats or sinks.
- Nothing needs a full screen change every frame.
- Every colour is in the palette table, and every pixel of every sprite is either `.` or in a legend.
- Text has good contrast on every background it sits on.

## How to give it back

One markdown file, **`docs/design/girder-rush-art.md`**, starting with the art direction and the palette, then: the girder profile, ends, ladders and scenery as fenced blocks (named, with sizes and legends), every sprite as a fenced block (named, with its size, its origin, its legend and the colour table for tone maps), the animation recipes (frames, timings in milliseconds, how many pixels move), each screen as a list of "this text or sprite, in this colour, at this x and y", and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions.

Also give **preview images** drawn at 3x with nearest neighbour scaling: `docs/design/girder-rush-preview.png` (stage 1 in game, with the hero, a few barrels in the air and on the girders, the ape and the captive) and, if you can, the title and the game over screens (`girder-rush-preview-title.png`, `girder-rush-preview-over.png`). If you want to try a variant, give two and say which you prefer. Say if anything in your design needs a rule of the game to change.

## Context

- **The rules and the code**: nothing exists yet. The rules above are what we plan to build, and the physics (the hero standing on a sloping girder, a barrel rolling and falling off the end) is plain integer arithmetic on the **top line** of each girder, so what matters for the art is that the **surface row is clear and the sprites' feet and the barrels' lowest point sit on it**.
- **The nearest house style.** The Cookoff window (the launcher) is dark navy `0A0E16` with an orange accent. The other games' art is in `docs/design/` (`tetris-art.md`, `snake-art.md`, `space-invaders-art.md`, `asteroids-art.md`, with previews beside them). Look at `snake-art.md` for how a finished file looks and what level of detail is the right one.
- **Sound** is built separately, in the same spirit as the others (chiptune style, and the ape and the hero can have a look that suggests it), so you do not need to design for sound.
