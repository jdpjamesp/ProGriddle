# Blast Buddies: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers under "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake, Space Invaders and Asteroids, and a barrel climbing platformer (Girder Rush) is next in the queue. This brief is for the game after that: a **turn based artillery game on destructible terrain**, in the spirit of the 1990s classics where teams of little creatures stand on a landscape and blow each other, and the ground under each other, to pieces with bazookas, grenades and dynamite.

**Working title: Blast Buddies.** A better name is welcome. We will not use the name or the look of any existing game in this family.

The game must be **funny, bright and readable**: the comedy of tiny creatures, huge explosions and a landscape that crumbles. It should feel like a loving remake by someone with taste in 2026: **crunchy chunky pixels, rich colour, lots of juice, and no clutter.**

### The creature: an abstract henchman (please read twice)

The little creatures ("goons" in this brief, call them what you like) should have the **charm of a cheerful mob of stubby henchmen**: small, round, stubby, a big goofy eye (or two) as the whole face, tiny limbs, a lot of personality in a very small number of pixels. But they are **abstract and our own**:

- **Do not** draw any existing mascot: not the yellow capsule henchmen with goggles and blue dungarees from the animated films, not worms, not lemmings. No yellow body with blue overalls. If someone sees it and says "that is the X one", change it.
- **Do** make a strong, simple **silhouette**: think geometric (a pill, a bean, a rounded square), a **band of visor or goggle or one big lens** for the eyes, a tiny mouth that can show a lot (a grin, a gasp, a squeal), little nubby arms and feet. Maybe a small hat, tuft or antenna per team.
- The goons are **small** (see the hard limits) so the eye and the pose carry everything. Expression is the whole game: they must look **cheerful when idle, worried when about to be hit, shocked when hit, sad when they die**.
- **Teams** are told apart by **colour and by one more thing** (a hat, an antenna, a stripe, a different goggle strap), so a colour blind player can tell teams apart. Please design **four teams**.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas** (the same one Space Invaders and Asteroids use): a grid of pixels, each pixel one flat 24 bit colour, shown scaled up with hard nearest neighbour edges. The **terrain is made of the pixels themselves**: every pixel of the landscape is either solid or air, and an explosion turns a disc of solid pixels into air, so the picture and the physics are the same thing.

### The hard limits

- The canvas is **384 columns by 240 rows**, shown scaled by a whole number so it fills the window (3x where the screen is tall enough, else 2x). **Every detail must still read at 2x**, where one pixel is two screen pixels: a 1 pixel highlight is fine, a 1 pixel dot that carries meaning is not.
- **No anti-aliasing and no blending.** A pixel is one colour and a later draw replaces an earlier one. Transparency is a pixel you leave out. A soft shadow or glow is made of extra pixels in dimmer colours.
- **Goon body: 9 pixels wide by 11 high.** That is what stands on the ground and is hit by things. Its origin is the **middle of its feet**. The picture may be up to **13 x 15** with an outline, a hat or an antenna, and a one pixel outline or dim halo may sit outside the body: say so if it does.
- **Facing.** Design everything that walks **facing right**; the game mirrors it for left. If your shading would look wrong mirrored (a light from the top left), either design so it does not matter or give left facing frames too and say so.
- **Terrain is rule based, not a bitmap.** The game generates the landscape from numbers (hills, caves, islands), and every solid pixel gets its colour from a **rule** that depends on how deep it is below the nearest air above it, and on a repeating speckle pattern. So give the terrain as **bands and a pattern**, not as a picture (see section 2). When an explosion carves a hole, the pixels around the hole are re-shaded by the same rule, so a cut surface gets a new grass edge or a scorched rim without anyone drawing it.
- **Budget.** The canvas is redrawn only when something changes, up to 60 times a second during action. Up to about **120 particles** (single pixels, or lines of 2 or 3) at a time is fine, for explosions. A full screen effect that changes every pixel every frame (a moving gradient, a whole screen shake) is not affordable, but **shaking the picture by one or two pixels on a big explosion** is. A static background that is drawn once is free, and a slowly moving cloud layer is cheap.
- **Text is made of pixels too.** We have a **5 x 7 capital letter font** (digits and basic punctuation included), drawn at 1x, 2x or 3x, in one colour or a vertical gradient, with an optional one pixel dark outline. If you want a smaller font for the HUD, give its glyph bitmaps.
- **Colours must be told apart by more than hue** (see `docs/accessibility.md`): the four teams, the bazooka rocket against a grenade, and the health crate against the weapon crate, must differ in **shape or pattern** as well as colour, and everything must read against the terrain and the sky.

### The sprite format we will use

A sprite is rows of characters, one per pixel, with a legend. `.` is transparent. Give frames as separate blocks named `Goon walk 1`, `Goon walk 2` and so on.

Use the **tone format** of the Snake and Tetris art: for a part that is recoloured or shaded, the rows use `1` (highlight), `2` (light), `3` (base), `4` (shade), `5` (edge), and a colour table gives the five hex values for tones 1 to 5 for each colour row. **The goons use this**: design the goon once, and give a colour row for each of the four teams. Anything with its own fixed colour (an eye, a tooth, a flame) uses letters `A` to `H` with their own hex values in the legend. Keep each sprite's legend to **16 colours or fewer**, and say so if you need more. Look at `docs/design/snake-art.md` section 0 for how that file lays it out: we paste the result into code with no decisions left.

## The rules, so the screens make sense

- **2 to 4 teams**, each with **3 or 4 goons** (the player chooses). A team may be played by a person or by the **computer**. Players take turns on one keyboard; the computer takes its turn by itself, after a short "thinking" pause.
- On a team's turn it plays **one goon** (the game picks the next goon in order). That goon has **45 seconds** to: **walk** left and right, **jump** (a hop, and a higher backwards flip), **choose a weapon**, **aim** (an angle that goes up and down, with a reticle), and **fire** (hold the fire key to charge a **power bar**, release to shoot). After firing, a short **retreat time** of a few seconds lets the goon scuttle away before the turn ends.
- **Wind** blows sideways, and changes every turn. It pushes rockets and anything light that is in the air.
- **Weapons** (the first release): **bazooka** (a rocket that flies in an arc, pushed by the wind, and explodes when it touches the ground or a goon), **grenade** (bounces, with a timer of 3 seconds shown as a digit above it), **dynamite** (dropped, with a 5 second fuse, huge), **shotgun** (two instant shots along the aim line), **air strike** (you place a flare, and 5 small missiles rain down a moment later). A short list of icons is shown to pick from.
- An **explosion** takes out a disc of terrain (a radius of about 12 for small and 30 for a big one), hurts and **throws** every goon nearby (the closer, the harder), and leaves a **scorched rim**.
- **Goons fall** when the ground goes from under them and take damage when they fall a long way. Falling into the **water** at the bottom of the screen (or off the sides) kills the goon: it sinks with a splash and a bubble.
- **Crates** drop by **parachute** now and then: a **health crate** (heals) and a **weapon crate** (gives a weapon). Walk into one to take it.
- Each goon has **100 health**, shown above its head as a number. A goon that reaches 0 **dies**: it jumps in alarm, **a halo and a small gravestone** rise, and the goon is gone. The **last team with a goon standing wins**.
- **Mines** (optional, a small thing sitting on the ground that explodes when a goon is near) are in the plan for later but please sketch one.
- The HUD: each team's **total health** as a coloured bar, the **wind** (an arrow and a strength), the **turn timer**, the **weapon** in use, the **power bar** while charging, the **name of the active goon and team**.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look, and a **palette** as a table of names and hex values: the four team colour rows (five tones each), the sky (a gradient from the top to the horizon), the terrain (see below), the water, the explosions (a ramp from white to yellow, orange, red and smoke), the weapons, the crates, the HUD panels, the text and the highlights.

It should be a **sibling of the other games, but its own thing**. The nearest ones are Lantern Glass (Tetris and Snake: dark navy, one amber lamp, glassy jewel colours), Space Invaders (neon pink, violet and cyan on indigo), Asteroids (glowing vector lines on near black) and Girder Rush (a construction site at dusk). This one should be the **brightest and warmest of all**: daylight, a big sky, saturated colours, a cartoon sun. Please do not reuse those palettes.

### 2. The terrain (as rules)
- The **terrain colour rule**: bands by **depth below the nearest air above** (for example grass on the top 3 pixels, topsoil for the next 10, dark soil below that, and rock at the bottom of the map), a **speckle pattern** (a repeating 16 x 16 tile, giving small stones or dots) that is added over the bands in a slightly lighter or darker value, and **how a surface that faces a hole is lit** (the pixel row along the edge of a cave can be lighter).
- The **scorch rule**: the colour of the ring of terrain pixels just outside a fresh hole (say 3 pixels wide, dark with a glow in the first frames, and then cooling to a dark brown).
- **Three themes** (**palette swaps** of the same rules, for variety): for example a green meadow, a desert or moon, and ice or candy: **your choice, make them as different as you can** (the sky, the terrain bands, the water colour, the cloud style). Each is a table of hex values.
- The **sky**: a vertical gradient, a **sun or moon**, a distant layer of hills or skyline and a few clouds. It is drawn once, and the clouds can drift slowly (give their frames and speeds). It must **not fight the goons and the explosions**: keep it darker or less saturated than anything that moves or explodes.
- The **water**: a strip along the bottom of the screen, 12 to 16 pixels high, with 4 frames of a wave surface that loops, and a second, darker, slower layer behind it. Say how a goon or a rocket entering the water splashes.
- The **map edge**: what the left and right sides and the bottom look like (is there a wall? Is it open sky and water so things fall off?).

### 3. Sprites (frame lists, with the sizes above)

| Sprite | Size | Frames and notes |
|---|---|---|
| Goon, idle | body 9 x 11 | 2 frames of breathing, plus a blink, plus a **worried** and an **idle fidget** (looks around). Say how the game should pick |
| Goon, walking | same | 4 frames |
| Goon, jumping | same | rising, falling, and a **backflip** of 4 frames |
| Goon, aiming | same | arms up, holding a weapon. Give the **weapon pose as a separate part** that the game draws at the aim angle (the sprite is the goon, and the weapon is a small shape that rotates in 64 steps round a pivot on the goon's body: give the pivot), or give **9 aiming poses** (straight down, through level, to straight up): your choice, say which |
| Goon, hurt | same | 2 frames: a flinch, and a **flying** pose (arms and legs flailing, for when it is thrown) with 2 frames, and a **landing** frame |
| Goon, dying | same | the alarm jump (3 frames), then the **halo and the gravestone** that rise and stay, over about 1.5 seconds |
| Goon, in the water | | a **sinking** frame and a splash |
| Goon, winning | | a happy dance of 3 frames |
| Goon, expressions | small | an optional set of small **icons** (a heart for a healed goon, an exclamation mark, a question mark for the computer thinking, a skull for the doomed) that float above the goon |
| Bazooka rocket | about 9 x 5 | 1 frame (it is rotated by the game), plus 2 frames of **exhaust flame** and a smoke puff |
| Grenade | about 6 x 6 | 1 frame, with the digit above it drawn by the game |
| Dynamite | about 5 x 9 | 1 frame and a **fuse spark** of 2 frames |
| Shotgun, muzzle flash, tracer | small | the flash (2 frames) and the line the shot draws |
| Air strike flare and missiles | about 3 x 7 | the flare (2 frames) and a small missile |
| Mine | about 7 x 4 | 1 frame cold, 2 frames with a **blinking light** |
| Crates | about 12 x 12 | a **health crate** (a cross or a heart) and a **weapon crate** (a star or a question mark), different in shape as well as colour; 1 frame each |
| Parachute | about 18 x 10 | 2 frames, one open and one collapsing as the crate lands |
| Weapon icons | 14 x 14 | one for each of the 5 weapons above, for the menu (1 frame each), plus a **selected** highlight |
| Reticle | about 9 x 9 | the aim marker, drawn at a distance from the goon along the aim, 2 frames |
| Power bar | | how the bar looks while charging (give its colours and its size in pixels, say if it is round the goon, or a bar above it, or at the bottom of the screen) |

Two points: **every frame must fit its body size** (or you say how much it overhangs), and the frame lists above are a **minimum**: if you think the goon needs a taunt for when the enemy misses, or a shiver when the timer is low, add it and say where it would be used.

### 4. Screen layouts on the 384 x 240 grid
Give each screen as a list of "this text or sprite, in this colour, at this x and y" (origin at the top left):

- **In game**: a sky filling the picture, the **terrain** (a sample landscape is welcome as a sketch, just to show the look), the goons, the HUD. Where do the **team bars**, the **wind**, the **timer**, the **weapon selected**, the **power bar** and the **name of the active goon** go? Keep the middle of the map clear.
- The **weapon menu**: a panel of 5 icons that opens over the picture, how it looks and where it sits.
- **Title screen**: the name, a controls hint, a blinking PRESS SPACE, a sample landscape with some goons being silly (and perhaps a rocket that crosses and blows a hole in the "title" letters). Give a short animation if you can.
- **Turn banner** (a short "TEAM RED" or the goon's name), **turn timer warning** (the last 10 seconds), **a goon dying**, **a team eliminated**, **winner** and **draw** (every team lost its last goon at once), and **paused**.
- Anything that makes the first five seconds feel special.

### 5. Effects (tell us which are worth it)
The **explosion** is the star: please give a **recipe** (not a bitmap), for three sizes (radius 12, 20 and 30): a white flash for a frame or two, an expanding **ring** and **fireball** that cool through the palette ramp, a ring of **debris** in the terrain's own colours (pixels of dirt flying out and falling, up to 60), **smoke** that rises and fades, a **scorch** on the terrain, and a **screen shake** of one or two pixels for the big one. Also: dust on a landing, a trail of smoke behind a rocket, sparks on a fuse, a splash in the water (droplets and a ring), floating damage numbers that rise and fade (the 5 x 7 font is fine), a goon's squeal as a small word bubble ("OOF!", "AAA!"), the halo and the gravestone, a sparkle on a crate, a wobble as a crate lands, clouds that drift, a tint on the whole picture for the last 10 seconds of a turn (we can recolour the HUD, not the picture). Say which you want, which you would drop and what you would add.

## Before you hand it back (checks)

- Every sprite reads at 2x, and the four teams, the two kinds of crate and the rocket and the grenade are told apart by shape and pattern as well as colour (run a colour blindness simulator over your preview).
- A goon reads clearly against **every** terrain band, the sky, the water and an explosion it can stand in front of, in every theme.
- Every sprite fits its body size, and the origin (the middle of the feet for a goon) is stated for each.
- The terrain rule gives a good looking result after **many holes** (a landscape that has been blown through ten times still looks good, with clean edges).
- Nothing needs a full screen change every frame (the shake and the drifting clouds are fine).
- Every colour is in the palette table, and every pixel of every sprite is either `.` or in a legend.
- Text has good contrast on every background it sits on.

## How to give it back

One markdown file, **`docs/design/blast-buddies-art.md`**, starting with the art direction and the palette, then: the terrain rules, the three themes, the sky and the water; every sprite as a fenced block (named, with its size, its origin, its legend and the colour table for tone maps); the explosion and effect recipes; the animation recipes (frames, timings in milliseconds, how many pixels move); each screen as a list of "this text or sprite, in this colour, at this x and y"; and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions.

Also give **preview images** drawn at 3x with nearest neighbour scaling: `docs/design/blast-buddies-preview.png` (the in game screen with a landscape that has taken a few hits, four goons of different teams, a rocket in the air and an explosion) and, if you can, the title and the game over screens (`blast-buddies-preview-title.png`, `blast-buddies-preview-over.png`) and a **theme sheet** (`blast-buddies-themes.png`: the same landscape in all three themes). If you want to try a variant, give two and say which you prefer. Say if anything in your design needs a rule of the game to change.

## Context

- **The rules and the code**: nothing exists yet. The rules above are what we plan to build. The physics (a goon standing on terrain pixels, a shell flying, an explosion removing a disc) works on the **solid or air** state of each pixel, and the **colour** of a pixel is only the picture of it, so what matters for the art is that the **top of the terrain is a clean, readable edge** and the goons' feet sit on it.
- **The computer player** plays like a person (it picks a weapon, an angle and a power) and has a short "thinking" pause with the question mark icon. It does not need art of its own.
- **The nearest house style.** The Cookoff window (the launcher) is dark navy `0A0E16` with an orange accent. The other games' art is in `docs/design/` (`tetris-art.md`, `snake-art.md`, `space-invaders-art.md`, `asteroids-art.md`, with previews beside them). Look at `snake-art.md` for how a finished file looks and what level of detail is the right one.
- **Sound** is built separately, in the same spirit as the others (chiptune style), so you do not need to design for sound.
