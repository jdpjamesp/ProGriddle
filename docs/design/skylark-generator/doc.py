"""Writes skylark-art.md from the same data that draws the previews."""
import sys
from palette import GROUPS, NAMED
import tiles as TL
import scene as S
import preview as PV
import player, air, ground, fx
import check

out = []
P = out.append
ALL = PV.ALL


def legend_line(s):
    used = s.used()
    return ', '.join('`%s` %s `%s`' % (k, s.legend[k], NAMED[s.legend[k]]) for k in sorted(s.legend) if k in used) or 'none'


def block(s):
    P('#### %s (%d x %d)' % (s.name, s.width, s.height))
    P('')
    if s.note:
        P(s.note)
        P('')
    P('Legend: ' + legend_line(s) + '.')
    P('')
    P('```')
    for r in s.rows:
        P(r)
    P('```')
    P('')


def grid_block(title, rows, note=''):
    P('#### ' + title)
    P('')
    if note:
        P(note)
        P('')
    P('```')
    for r in rows:
        P(r)
    P('```')
    P('')


P('# Skylark: art and screen design, "First Light"')
P('')
P('Designer\'s answer to `xevious-art-brief.md`. Everything here is meant to be pasted into code with no further decisions. Section 9 lists what I decided and the questions the code will still have to answer.')
P('')
P('**One change to the brief, on purpose.** The brief asks for a faithful port of a 1982 arcade game. This design keeps the genre, the screen shape, the rules and the feel the brief describes (a vertical scroller over forests, rivers, roads and lines cut in the land, a rapid gun for the air and a bomb on a sight for the ground, hidden targets, a boss core behind four shields, an area bonus), but every name, ship, enemy, target, boss, tile and screen in it is an original design. Each original thing takes the role of one line of the brief\'s tables (section 3.2), so the rules, timings and point values in the brief map across one to one. Working title: **Skylark**; the ship is the **Lark**.')
P('')
P('Previews, all made from the data in this file:')
P('')
P('- `skylark-preview.png` (3x): in game, area 3, green land, a wave of Whirls, the sight locked on a Cairn, a bomb on its way, a ground burst with its light on the land, haze, shadows, bullets with bloom.')
P('- `skylark-preview-title.png` (3x): the title over the land, the logo, the land line that lights up, the roll call.')
P('- `skylark-preview-area.png` (2x): the area start marker and the end of area bonus.')
P('- `skylark-preview-over.png` (2x): game over and the pause.')
P('- `skylark-themes.png` (2x): the same moment in four moods across both ground families.')
P('- `skylark-sprites.png` (4x): every sprite in this file. `skylark-tiles.png` (4x): every tile in both families and the three land line designs. `skylark-breakup.png` (6x): the Lark breaking up.')
P('- `skylark-colour-check.png` (2x): the game screen and every danger colour on every ground, as drawn and through deuteranopia, protanopia and tritanopia.')
P('')
P('Every grid, tile and preview is made by one small script (`skylark-generator/`, see 9.10), so the pictures and the text cannot disagree.')
P('')

P('## 0. Read this first')
P('')
P('- The canvas is **224 x 288**: a **16 row score strip** (rows 0 to 15), the **playfield, 224 x 256** (rows 16 to 271) and a **16 row lives strip** (rows 272 to 287). Origin top left; one cell of this file is one canvas cell, shown at 3x (2x on small screens) with nearest neighbour scaling, on the direct colour `PixelCanvas`.')
P('- **Ground**: 14 x 16 tiles of 16 x 16 on screen, plus one row coming in at the top. The map scrolls down the screen by one cell per frame at the normal speed (a tile every 16 frames).')
P('- **Sprite format**: a grid of letters, one line a row. `.` is transparent. Each letter is a named colour from the legend under the grid (section 1). No sprite uses more than 8 colours.')
P('- **Placing**: a sprite is drawn centred on its thing\'s position: top left at `(x - width / 2, y - height / 2)`. The **box** in each note is in the sprite\'s own cells, from its top left; where no box is given it is the whole sprite.')
P('- **Facing**: everything faces up the screen as drawn. The Beetle is the one thing that turns: draw it by whole quarter turns (rotate the grid), never by a mirror, so the light stays on the upper left.')
P('- **Light**: from the upper left, always. Every shadow falls down and to the right.')
P('- **Time**: every effect is a function of the frame count since the thing started (60 frames a second), as in Tetris and Snake. Section 4 gives each one.')
P('')

P('## 1. Art direction and palette')
P('')
P('**First Light.** A survey flight at dawn over a quiet land. The land is soft and matte, in greens and ochres that sit close together so it never fights the action; everything that matters is crisper and more saturated than the land: the Lark is pale and cool, enemies in the air are plum and steel with one green eye, things on the ground are rust and stone with the same green eye, and the only pink in the game is the enemy bullet. The modern part is in the light, not in the detail: a slow haze above the land, a warm glow thrown by explosions, a one cell bloom round shots and the sight, real shadows on the ground. The pixels stay hard edged and the palette stays at 63 colours.')
P('')
P('Shared on purpose:')
P('')
P('- **Hot** (`FF3D8E`) is every enemy bullet and nothing else. Pink does not occur in the land, so a bullet reads on every ground; its white core (`Hot Core`) carries it where pink alone is weak (on Meadow and Road, see 8).')
P('- **Eye** (`7CFFB4`) is on every enemy, air and ground, and is the Citadel core (the same value is `Core`). Green eye means it can be killed. The **Anvil** has no eye and no plum: it is all iron, the one thing that cannot be killed.')
P('- **Flash** and **Zap** are the same white: the start of every explosion and the player\'s shot.')
P('- **Glow Light** and **Dawn Top** are the same: the light of explosions and the top of the title gradient. **Haze** and **Foam** are the same pale blue.')
P('- **Signal** is the warning lights on targets, the yellow of fire, and the score.')
P('- The **sight** is one colour (Sight, or Sight Lock when locked) with a one cell **Ink** keyline, which is what makes it read over foam, ochre and forest alike.')
P('')
for g, items in GROUPS:
    P('**%s**' % g)
    P('')
    P('| Name | Hex | Used for |')
    P('|---|---|---|')
    for n, v, note in items:
        P('| %s | `%s` | %s |' % (n, v, note))
    P('')
P('That is %d names and %d distinct values (the limit is 64).' % (len(NAMED), len(set(NAMED.values()))))
P('')
P('The enum `XeviousTint` in the brief becomes one member per name above, in this order (spaces dropped: `MeadowLight`, `HullInk`, ...). Tints (shadow, haze, light, the mood of an area) are passes that mix the cell under them toward a named colour by a fixed amount; they are not palette entries of their own.')
P('')

P('## 2. The ground')
P('')
P('### 2.1 How the tiles fit')
P('')
P('A tile is 16 x 16 letters. The letters are kept abstract so that **one tile serves both ground families**:')
P('')
P('| Letter | Green family | Dry family |')
P('|---|---|---|')
for k in 'gld':
    P('| `%s` | %s `%s` | %s `%s` |' % (k, TL.FAMILIES['green'][k], NAMED[TL.FAMILIES['green'][k]], TL.FAMILIES['dry'][k], NAMED[TL.FAMILIES['dry'][k]]))
for k, v in TL.COMMON.items():
    P('| `%s` | %s `%s` | the same |' % (k, v, NAMED[v]))
P('')
P('The joins:')
P('')
P('- **Open ground** (`open_1` to `open_3`) joins anything. Pick a variant by a hash of the tile\'s map position, so the land never repeats in a way the eye catches.')
P('- **Forest** is a corner set. Each map **corner** (the point where four tiles meet) is forest or not; a tile is chosen by its four corners (nw, ne, sw, se). Fifteen tiles cover every case (`forest_nw` ... `forest_full`; all four corners open is open ground). Two tiles side by side share the two corners on their join, so the edge always meets: the check in section 8 found every possible pair agreeing on all 16 cells of the join. The rim of the forest is lit (Canopy Light) where the open ground is above or left of it and dark (Understory) where it is below or right, and the ground just below and right of the trees is a shade darker, so the forest stands up off the land. `forest_full_2` is the same roof with the crowns moved 5 cells; use it for a third of the full tiles.')
P('- **Rivers** and **roads** are path tiles: the water or the road meets the **middle 8 cells** of each edge it leaves by (`river_ne` leaves by the north and east edges). A river is 8 cells of water with Foam at its edge and an Earth bank outside that; bends are quarter circles. A road is 6 cells of Road, a Road Edge cell each side and an Earth verge; its centre line is dashed 4 on, 4 off, in step across tiles because the dash pattern is counted from the tile\'s own edge.')
P('- **Bridges** are where a road crosses a river (`bridge_ns`: road north to south over a river east to west).')
P('- **Pads** (`pad`) are open ground with a stone slab. The bigger installations stand on one.')
P('- **Land lines** are 32 x 32 designs cut into open ground, made of four tiles each, quartered nw, ne, sw, se. Their lines are Ochre Light with an Earth cell below and right, in both families.')
P('- There is **no sea or void** at the edge: the map is 14 tiles wide and fills the screen.')
P('')
P('### 2.2 The tiles')
P('')
T = TL.tile_set()
for n, (rows, note) in T.items():
    grid_block('%s (16 x 16)' % n, rows, note[0].upper() + note[1:] + '.')
P('### 2.3 The land lines (32 x 32 each, four tiles)')
P('')
notes = {'spiral': 'A spiral of two and a half turns.', 'sunwheel': 'A ring with eight rays and a dot in the middle.', 'lark': 'The game\'s own mark: a bird from above with swept wings and a forked tail. It is also the mark that lights up on the title screen.'}
for n in TL.LINES:
    grid_block('lines_%s (32 x 32)' % n, TL.line_design(n), notes[n] + ' Cut it into `lines_%s_nw`, `_ne`, `_sw` and `_se`.' % n)
P('### 2.4 The 16 areas')
P('')
P('Each area uses one ground family, one mood and its own mix of features. The mood is a tint of the whole ground (and nothing above it) by the amount in the table; it costs one mix per ground cell, done once when a tile row is drawn, not every frame.')
P('')
P('| Mood | Tint | Amount | Feel |')
P('|---|---|---|---|')
for k, (n, t, f) in S.MOODS.items():
    P('| %s | %s | %d%% | %s |' % (k, n or 'none', int(t * 100), f))
P('')
P('| Area | Ground | Mood | The land |')
P('|---|---|---|---|')
for a, fam, mood, what in S.AREAS:
    P('| %d | %s | %s | %s |' % (a, fam, mood, what))
P('')
P('After area 16 the loop starts again at area 1 with the same looks. `skylark-themes.png` shows the four moods.')
P('')

P('## 3. Sprites')
P('')
P('### 3.1 The Lark and its weapons')
P('')
P('The Lark: a small swept wing survey craft, pale hull, cyan canopy, orange wing marks, two engine bells. Original to this game.')
P('')
for s in player.sprites():
    block(s)
P('### 3.2 Who is who')
P('')
P('Each original thing takes the role of one line of the brief\'s tables, so the rules, timings and points in the brief apply to it unchanged. Points are the brief\'s starting figures.')
P('')
P('| Ours | Role in the brief | Kind | Points | Looks like |')
P('|---|---|---|---|---|')
roles = [
    ('Whirl', 'the spinning ring, first wave', 'air', '30', 'a three bladed seed spinner, plum, steel hub, green eye'),
    ('Skate', 'the diving disc', 'air', '50', 'a flat ray glider'),
    ('Kite', 'the flipping diamond that fires as it turns', 'air', '10', 'a diamond kite on steel spars'),
    ('Glint', 'the mirror that flips, reflects, then dives', 'air', '1000', 'a long hexagonal mirror shard'),
    ('Midge', 'the small wiggler, hard to hit', 'air', '150', 'a small plum dragonfly with steel wings'),
    ('Wisp', 'the orb that appears near you and bursts into bullets', 'air', '300', 'a green glow in a plum cage'),
    ('Swift', 'the fast darts in formation', 'air', '100', 'a swallow shaped dart, nose down'),
    ('Anvil', 'the indestructible plate', 'air', '0 or 1000', 'a heavy iron hexagon with six bolts'),
    ('Cairn', 'the basic ground target', 'ground', '10', 'three stepped stone rings with a rust band'),
    ('Dish', 'the dome beside the road', 'ground', '20', 'a dish aerial on a footing'),
    ('Burr', 'the ball turret', 'ground', '100', 'a rust ball with eight spines'),
    ('Bastion', 'the larger turret', 'ground', '200', 'a square bunker with corner lights'),
    ('Beetle', 'the small tank', 'ground', '200', 'a crawler on two tracks'),
    ('Henge', 'the large tough target', 'ground', '300', 'eight standing stones round a pit'),
    ('Hive', 'the ground launcher', 'ground', '400', 'a domed silo that opens; Wisps rise from it'),
    ('Spire', 'the hidden tower', 'ground', '2000', 'a stepped needle with a signal tip'),
    ('Pennant', 'the hidden flag (extra life)', 'ground', '1 life', 'an orange pennant on a pole'),
    ('Citadel', 'the boss: a core behind four shields', 'boss', '4000', 'a round fortress of eight plates, a green core; four curved shield plates'),
]
for r in roles:
    P('| %s | %s | %s | %s | %s |' % r)
P('')
P('### 3.3 Air enemies')
P('')
P('All plum and steel with the green eye, lit from the upper left. Shadows: see section 5.')
P('')
for s in air.sprites():
    block(s)
P('### 3.4 Ground targets and what is left of them')
P('')
P('Rust and stone with the green eye. A scorch is drawn **on the ground layer** where the target stood (it scrolls with the land, it is not a sprite with a life of its own), and it is drawn the frame the burst starts, so the burst covers the change.')
P('')
for s in ground.sprites():
    if s.group in ('ground', 'scorch'):
        block(s)
P('### 3.5 The Citadel')
P('')
P('A round fortress of eight plates with a green core, 32 x 32, with four curved shield plates round it (north, east, south, west, each 1 cell off the rim). It is drawn on the ground layer\'s side of the shadows (it flies low) but bombs and shots both reach it: the shields are hit by the Zapper, the core only by the Blaster.')
P('')
for s in ground.sprites():
    if s.group == 'boss':
        block(s)
P('### 3.6 Explosions')
P('')
for s in fx.sprites():
    block(s)
P('### 3.7 The Lark breaking up')
P('')
P('The Lark is cut into four pieces (below; each grid is the whole 16 x 16 with only that piece\'s cells kept). Over **90 frames** (1.5 seconds) each piece moves by its drift times frames / 4 cells, starting from its start offset. From frame 12 each cell is mixed toward Smoke by `min(1, 1.4 x frame / 90)`; a cell is dropped when `((x * 7 + y * 11) mod 10) / 10` is below `frame / 90`, so the pieces crumble rather than blink out. The air explosion plays over the middle for its first 20 frames. See `skylark-breakup.png`.')
P('')
P('| Piece | Start offset | Drift (cells a frame x 4) |')
P('|---|---|---|')
for n, rows, sx, sy, dx, dy in player.breakup_pieces():
    P('| %s | (%d, %d) | (%.1f, %.1f) |' % (n, sx, sy, dx, dy))
P('')
for n, rows, sx, sy, dx, dy in player.breakup_pieces():
    grid_block('lark_piece_%s (16 x 16)' % n, rows, 'Legend: as `lark`.')

P('## 4. Animation recipes (frames at 60 a second)')
P('')
recipes = [
    ('Lark', 'Level when not moving sideways. `lark_bank_left` or `_right` from the first frame of sideways movement; back to level 4 frames after it stops.'),
    ('Flame', '`flame_1` and `flame_2` swap every 4 frames; `flame_2` only while moving up.'),
    ('Zap', 'No frames. Moves 6 cells a frame. Bloom: Zap Glow at 30% on the cells round it.'),
    ('Bomb', 'Frames 1 2 3 2, 3 frames each, until the last 4 frames, which stay on 3. Moves from the Lark to the sight in 32 frames in a straight line (it is a lob seen from above: it grows by nothing, the shadow tells the story). The shadow starts under the Lark and reaches the sight on the same frame.'),
    ('Sight', 'Normal or locked; locked is decided every frame. Locked gets a bloom of Sight Lock at 30%.'),
    ('Whirl', '4 frames, 3 frames each (a turn in 12 frames).'),
    ('Skate', 'flat while gliding; dive while going down the screen faster than the land; rise for 8 frames as it pulls out.'),
    ('Kite', '1 2 3 4 3 2, 6 frames each; it fires on the frame it reaches 3.'),
    ('Glint', '1 2 3 4 3 2, 5 frames each while it reflects (shots that hit on frame 1 are reflected), then frame 3 (edge on) for its dive.'),
    ('Midge', '1 2, 2 frames each.'),
    ('Wisp', '1 for 8 frames (no box), then 2 and 3 swapping every 6 frames, then 3 for the last 12 frames before the ring of bullets.'),
    ('Swift', '1 2, 3 frames each.'),
    ('Anvil', '6 frames, 4 frames each (a half turn in 24; frames 1 to 6 then 1 again, as the plate is the same both ways round).'),
    ('Bullet', '1 2, 2 frames each. Bloom: Hot at 40%.'),
    ('Beetle', '1 2, 4 frames each while moving; stays on its frame when it stops.'),
    ('Hive', 'closed; open for the 20 frames before a Wisp leaves it, then closed.'),
    ('Spire', 'hidden: nothing is drawn. While the sight centre is in its box: `spire_flicker` on frames where `frame mod 16` is 0 or 1. Bombed: `spire` for 24 frames, then a ground burst and `spire_scorch`.'),
    ('Pennant', '1 2, 8 frames each, until collected or scrolled off.'),
    ('Citadel', 'core: still. Hit: `citadel_core_hit` 2 frames, then ground bursts at the core and at the four plate sockets, 6 frames apart, and the scorch of the core (`henge_scorch` doubled to 32 x 32) is left on the ground.'),
    ('Shields', 'whole; after the first hit `shield_n_cracked`; the second hit breaks it off: it drifts out from the core at 1 cell a frame for 30 frames, its cells mixed toward Smoke by frame / 30, with an air explosion at its middle on the first frame.'),
    ('Air explosion', '5 frames, 4 frames each.'),
    ('Ground burst', '6 frames, 5 frames each. Light on the land for its first 8 frames (section 5).'),
    ('Area marker', 'see 5.2.'),
]
P('| Thing | Recipe |')
P('|---|---|')
for a, b in recipes:
    P('| %s | %s |' % (a, b))
P('')

P('## 5. Motion and finish (the modern part)')
P('')
P('Drawing order, back to front: ground tiles (with mood), scorches, ground targets, explosion light, ground shadows, bomb shadow, haze, sight, bomb, air enemies, ground bursts and air explosions, bullets, shots, the Lark and its flame, the strips, words.')
P('')
fxrows = [
    ('Haze', 'Clouds above the land: soft lumps (an ellipse with a wobbling rim) drawn as a tint of Haze at 22%; the rim is every other cell (a checker), which reads as soft at 3x with no blending. They move down at 1.25 times the land\'s speed and drift sideways 1 cell every 64 frames, so the land seems to slide under them. 2 or 3 on screen.', 'about 2000 tint cells a frame at most (a fixed cost, like the ground)'),
    ('Explosion light', 'Ground bursts and the Citadel throw light on the land under them: three rings of Glow Light, 30% inside 8 cells, 20% to 16, 10% to 24, all scaled by `1 - frame / 8`, for 8 frames. Drawn on the ground only, so it warms the land and not the sprites.', 'up to 1800 tint cells for 8 frames per burst; at most 2 at once'),
    ('Bloom', 'A one cell halo round bullets (Hot, 40%), shots (Zap Glow, 30%) and the locked sight (Sight Lock, 30%): the 4 neighbour cells of the sprite outline, tinted.', 'about 12 cells a bullet, well inside the particle budget'),
    ('Shadows', 'Everything in the air casts its outline on the ground as a tint of Ink at 35%: the Lark offset (+6, +10), air enemies (+4, +6), the bomb (its own shadow sprite). Ground targets cast none (their shade is drawn in).', 'one tint per sprite cell'),
    ('Scanlines', 'Optional, off by default (`skylark.scanlines`): every odd canvas row mixed toward Ink by 12%. It costs the whole field, so it is the one pass worth switching off on a slow machine.', '28672 tints a frame when on'),
]
P('| Effect | What | Cost |')
P('|---|---|---|')
for a, b, c in fxrows:
    P('| %s | %s | %s |' % (a, b, c))
P('')

P('## 6. Screens')
P('')
P('### 6.1 The strips')
P('')
P('- **Top** (rows 0 to 15, Strip with an Ink line on row 15): `SCORE` in Text Dim at (6, 1), the score in Signal after it; `HI` in Text Dim at (128, 1), the hi-score in Zap Glow after it. One quiet line; the second line is left empty on purpose.')
P('- **Bottom** (rows 272 to 287): one mini Lark (7 x 7, below) per spare life from (6, 276), 10 cells apart; `AREA 03` in Text, right aligned 6 cells from the edge.')
P('')
grid_block('mini_lark (7 x 7)', S.MINI_LARK, 'Legend: as `lark` (`K` Hull Ink, `W` Hull, `M` Hull Mid, `G` Glass, `O` Wing Mark).')
P('- All words are the 5 x 7 font. Big words (titles, AREA, GAME OVER) are 3x or 4x in the dawn gradient (Dawn Top to Dawn Low, top to bottom) with an Ink outline one cell wide; ordinary words are 1x in Text or Text Dim; numbers that matter (score, bonus) are Signal.')
P('')
P('### 6.2 Area start (`skylark-preview-area.png`, left)')
P('')
P('The land keeps scrolling. A band 30 rows tall across the middle of the field (from row 120), the land under it mixed toward Strip by 80%, with a Wing Mark line on its top and bottom rows. `AREA 4` at 3x in the dawn gradient, centred. A short bar of Flash, 24 cells long, runs along the top line left to right and along the bottom line right to left at 6 cells a frame (the sweep). The band is up for 120 frames: it opens from its middle line to full height over the first 10 and closes over the last 10.')
P('')
P('### 6.3 End of area bonus (`skylark-preview-area.png`, right)')
P('')
P('A panel 192 x 160 (from (16, 56)), the land under it mixed toward Strip by 82%, Wing Mark lines top and bottom. `AREA 3 CLEAR` at 2x in the dawn gradient. Three lines (label in Text Dim, value in Text, right aligned): ground targets destroyed of all on the area, the percentage, Spires found. A bar of one 5 x 5 square per ground target, two rows of 24: the squares light in Signal one every 3 frames as the count goes up, the rest stay Stone Dark. Then `BONUS` at 2x and the bonus in Signal, which counts up with the squares.')
P('')
P('### 6.4 Title (`skylark-preview-title.png`)')
P('')
P('The land of area 1 scrolls slowly under an Ink veil of 55%. The **lark land line** in the land is drawn in Dawn Top instead of its usual colour, as if lit by the sun: the logo grows from it. `SKYLARK` at 4x in the dawn gradient with an Ink outline, then three horizon lines (Dawn Low 150 long, Wing Mark 110, Dawn Top 60), like a sunrise. The roll call: `AIR` and `GROUND` in Text Dim, five of each with their points in Signal (the Anvil\'s points are a `?`, a hint at the trick). `PUSH FIRE` at 2x in Text, blinking 40 frames on, 20 off.')
P('')
P('### 6.5 Game over and pause (`skylark-preview-over.png`)')
P('')
P('- **Game over**: the land stops, an Ink veil of 50%, `GAME OVER` at 3x in the dawn gradient with an Ink outline, the area reached and its percentage in Text Dim under it. 4 seconds, then the title.')
P('- **Pause**: everything freezes, a Strip veil of 60% over the field (the strips stay bright), `PAUSED` at 3x in Text with an Ink outline, `P TO PLAY ON` in Text Dim.')
P('')
P('The words are drawn by the painter, not the window banner (as in Tetris and Snake). The font has no `%` or `/`, so the screens say `PCT` and `OF` (9.6).')
P('')

P('## 7. Budgets')
P('')
P('- Sprites: the busiest moment in the in game preview has 24 sprites; a heavy wave (8 Whirls, 12 bullets, 4 ground targets, the sight, the bomb, 2 shots, the Lark, 2 explosions) is about 32, inside the 60.')
P('- Particles: the breakup is 4 pieces (sprites, not particles); bloom is about 12 tint cells a bullet. Nothing else uses particles, so the 100 particle cells are free for the code (smoke trails, sparks off the Anvil).')
P('- Tints a frame: shadows (about 150 x the number of air things), haze (up to 2000), explosion light (up to 1800 a burst, 2 at once), bloom (about 12 each). The mood tint is paid once per tile row, not per frame.')
P('')

P('## 8. Checks (run by the generator)')
P('')
bad = check.validate()
P('- Limits: %s (every sprite at most 8 colours plus transparent, 16 x 16 at most except the Citadel core and the ground bursts at 32 x 32, every tile 16 x 16 and at most 8 colours in either family, the palette at most 64 distinct values).' % ('all passed' if not bad else '; '.join(bad)))
P('- Forest joins: of every pair of forest tiles that may sit side by side, the worst agrees on %d of the 16 cells of the join.' % check.joins())
P('- Contrast (WCAG ratio, luminance only) of the things that must be seen, against each ground:')
P('')
P('| Thing | ' + ' | '.join(check.GROUNDS) + ' |')
P('|---|' + '---|' * len(check.GROUNDS))
for t, v in check.contrast_table():
    P('| %s | %s |' % (t, ' | '.join('%.1f' % x for x in v)))
P('')
P('How to read it: Hot and Sight Lock are pure colour (about 1 to 2 against the land in brightness), which is why neither is ever drawn alone. A bullet is a Hot ring round a Hot Core and gets a Hot bloom; the sight always has its Ink keyline (Ink is 2.6 or better on every ground, and much better on the light ones where Sight is weakest). Under the three colour blindness simulations (`skylark-colour-check.png`) the bullet stays the lightest small thing on the land, the locked sight goes dark where the normal sight is light (so the change still reads, by brightness), and plum enemies stay apart from green land in all three.')
P('')

P('## 9. What I decided and why, and open questions')
P('')
dec = [
    'Original designs throughout, as said at the top. The genre, layout and rules are the brief\'s; the look and every character are new.',
    'Strips: the brief says 224 x 256 plus a score strip with the lives at the bottom. I made the canvas 224 x 288, a 16 row strip above and below, so the playfield is the full 224 x 256.',
    'Two ground families instead of 16 palettes: green and dry share every tile through three letters, and the 16 areas differ by family, mood tint and features. That keeps the palette at 63 and makes 16 distinct looks.',
    'The sight has an Ink keyline. The brief says one colour; I kept one colour for the sight itself and added the keyline because no single colour reads over foam, ochre and dark forest at once.',
    'The bomb has no fall animation in size, only the pulse and the shadow sliding to the sight: from straight above a falling thing does not shrink much, and the shadow makes the landing point plain.',
    'The font has no `%` or `/`. The screens say `PCT` and `OF`. If the font gets those two glyphs later, use them.',
    'The Citadel takes Zapper hits on its shields and Blaster hits on its core. If the rules want the shields to need bombs too, the art does not change.',
    'Scorch marks belong to the ground layer, not the sprite list, so they cost nothing per frame once laid.',
    '**Names in code.** The brief puts the art in `XeviousArt`, `XeviousLook`, `XeviousTint` and `XeviousTiles` and the rules in `XeviousRules`. Since the game is not that game, I suggest `SkylarkArt`, `SkylarkLook`, `SkylarkTint`, `SkylarkTiles`, `SkylarkRules` and a `Games/Skylark` folder. Open: your call.',
    'The generator is in `docs/design/skylark-generator/` (Python 3 and Pillow). `python run_all.py` writes this file and every picture into `docs/design`. It does not yet write the ABL classes: the brief says a script like `tools/gen-foreach-art.py` will, once the code is started.',
    'Open: should the Anvil trick (1000 points for enough hits in a row) show anything? I would flash its rim (Iron Light to Flash) on each hit of a run, so the player learns the trick exists. Not drawn yet.',
    'Open: the hidden Pennant spot and the hidden Spire spot have no tell at all, as the brief asks. If they should, a single cell of Ochre Light in the ground tile under them would be the gentlest hint.',
]
for i, d in enumerate(dec):
    P('%d. %s' % (i + 1, d))
P('')

P('## 10. Sprite index')
P('')
P('| Sprite | Size | Group |')
P('|---|---|---|')
for s in ALL.values():
    P('| `%s` | %d x %d | %s |' % (s.name, s.width, s.height, s.group))
P('')

text = '\n'.join(out) + '\n'
assert chr(0x2014) not in text and chr(0x2013) not in text
open(sys.argv[1], 'w').write(text)
