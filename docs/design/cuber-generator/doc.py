"""Writes cuber-art.md from the same data that draws the previews."""
import sys
from palette import GROUPS, NAMED, NOTE, ROWS, TONE, THEMES, count_distinct
from lib import text_width
from preview import TITLE
import scene as S
import sprites as SP
import check

out = []
P = out.append
A = SP.ALL


def legend_line(s, row_word=None):
    used = s.used()
    parts = []
    digits = [k for k in '12345' if k in used]
    if digits and s.row:
        parts.append('`%s` tones %s of the %s row%s' % (''.join(digits), ', '.join(digits), row_word or s.row,
                                                        '' if row_word else ' (' + ', '.join('`%s`' % TONE[s.row][int(d) - 1] for d in digits) + ')'))
    for k in sorted(s.legend):
        if k in used and not k.isdigit():
            parts.append('`%s` %s `%s`' % (k, s.legend[k], NAMED[s.legend[k]]))
    return '; '.join(parts) or 'none'


def block(s, row_word=None, extra=''):
    P('#### %s (%d x %d, origin (%d, %d))' % (s.name, s.width, s.height, s.origin[0], s.origin[1]))
    P('')
    if s.note:
        P(s.note + (' ' + extra if extra else ''))
        P('')
    P('Legend: ' + legend_line(s, row_word) + '.')
    P('')
    P('```')
    for r in s.rows:
        P(r)
    P('```')
    P('')


def grid_block(title, rows, legend):
    P('#### ' + title)
    P('')
    P('Legend: ' + legend + '.')
    P('')
    P('```')
    for r in rows:
        P(r)
    P('```')
    P('')


def table(head, rows):
    P('| ' + ' | '.join(head) + ' |')
    P('|' + '|'.join(['---'] * len(head)) + '|')
    for r in rows:
        P('| ' + ' | '.join(str(c) for c in r) + ' |')
    P('')


# ======================================================================================================================
P('# Cuber: art and screen design, "Dusk Lamps"')
P('')
P('Designer\'s answer to `cuber-art-brief.md`. Everything here is meant to be pasted into code with no further decisions. Section 13 lists what I decided, the one rule I would like to add and the questions still open.')
P('')
P('**The idea in one line.** A pyramid of stone lamps floats in a dusk sky over a bottomless dark. A small glowing gummy called Pip hops from lamp to lamp lighting them; a smouldering serpent hunts it, red thorn balls bounce down, an ice crystal freezes the hunters, two moths snuff the lamps out again, and rings of light wait at the sides to lift Pip home. The working title stays in the file names; the name I propose for the game is **Lamplighter** (section 1).')
P('')
P('Every picture is an original design: the hero, the enemies, the cube colours, the pyramid\'s faces, the title lettering. The things that make the idea readable are kept on purpose: isometric cubes whose top changes, a round hero that hops along four diagonals, a long chaser that hatches from a ball, round bouncing hazards, discs at the sides and the void under the edge.')
P('')
P('Previews (made by the generator from the data in this file, so the pictures and the text cannot disagree):')
P('')
P('- `cuber-preview.png` (3x): level 2 round 1, part way: Pip mid hop with its shadow on the lamp it will land on, the glint and the 25 on the lamp it just lit, the Coil on row 3, a Thorn, a Frost, Snuff on the left edge, four halos waiting and one used up, lamps in all three states.')
P('- `cuber-preview-title.png` (3x): the title, part way through the intro (Pip has lit a path down the middle).')
P('- `cuber-preview-over.png` (3x): game over with a new high score.')
P('- `cuber-screens.png` (2x): READY, the level clear ripple half way, PAUSED, a freeze (the ring spreading, the Coil, the Thorn and Snuff frozen).')
P('- `cuber-themes.png` (3x): the four round themes in rows: unlit, half, done, the undo signal on an unlit and a lit lamp, the HUD target cube; under them one frame of a flipping lamp.')
P('- `cuber-sprites.png` (4x): every sprite in this file, alternate rows on a lit Mint lamp colour so both reads can be checked.')
P('- `cuber-colour-check.png` (1x): two game screens and the swatches, as drawn, through deuteranopia, protanopia and tritanopia, and in grey scale.')
P('')

# ======================================================================================================================
P('## 0. Read this first')
P('')
P('- The canvas is **256 x 256**, as the brief proposes, shown at 3x (2x on small screens) with nearest neighbour scaling. It is a **direct colour PixelCanvas** (as Space Invaders, Asteroids, Moonpatch and Skylark), not palette indexed cells: the lamps are 2:1 isometric pictures that do not sit on a square grid, and the sprites overlap them freely.')
P('- The **HUD** is rows 0 to 31, the pyramid rows 48 to 223, the **void** rows 216 to 255 (the pyramid\'s bottom row covers its top).')
P('- **Sprite format**: the tone format of `snake-art.md`. `.` is transparent, `1` to `5` are the tones of the sprite\'s colour row (1 highlight, 2 light, 3 base, 4 shade, 5 edge), letters are fixed colours given in each legend. No legend has more than 16 colours (most have 8 or fewer).')
P('- **Origin**: every sprite gives its origin, the pixel that goes on the thing\'s position. For everything that stands on a lamp it is **the middle of the feet**, and it goes on the lamp\'s **foot point**: `(cube x + 16, cube y + 8)`, the middle of the top diamond (section 3.4 has them all).')
P('- **Facing**: draw the `dr` (down right) and `ur` (up right) frames as given; down left and up left are the mirror of the grid (columns reversed, the origin column becomes `width - 1 - x`). Every moving thing is lit from the **top middle** (Pip glows from inside; the others have a soft top light), so mirroring never puts the light on the wrong side. The lamps are never mirrored and are lit from the top left.')
P('- **Draw order** (back to front): the baked background (sky, stars, void), the lamps (row 1 to row 7, left to right; each later lamp covers the edge line of the one above it, see 3.2), the sky particles, the halos, shadows, the glints, enemies whose foot point is higher on screen first (sort by foot y, then x), Pip, the puffs and sparks, the score pop ups, the HUD, the banners.')
P('- **Time** is in milliseconds; a frame is 1/60 s (about 16.7 ms), and the hop is 12 frames (200 ms) as the brief says.')
P('- **No em dashes, no blending**: every colour below is a flat value; a glow or a shadow is extra pixels in a dimmer colour.')
P('')

# ======================================================================================================================
P('## 1. Names and art direction')
P('')
P('### 1.1 The look: Dusk Lamps')
P('')
P('A pyramid of **stone lamps** floats in a **dusk sky**, the last violet after sunset with a few stars and far paper lanterns drifting up. Under it there is only the **void**, the sky going to near black, with dust motes falling into it. The lamps are cool lilac stone on their sides and dark slate glass on top. When Pip lands on one, its top **lights up from inside**: first a ring (half way) then a full glowing core, and the light **spills down** the two lip rows of the stone below it. A finished level is a pyramid of light in the dark, and the clear is a ripple of white running over it. The colours carry meaning: **light means progress** (dark, ring, glowing core, from dim to bright, so it reads in grey scale), **red hot means it hunts you** (the Coil\'s ember rim, its seed\'s cracks and the red Thorn), **ice means help** (the Frost and the halos are the only cool bright things on the board), and **gold means good news** (Pip, the points, a new high score).')
P('')
P('It is a sibling of the others (dark ground, chunky pixels, the 5 x 7 font, a lit edge on everything that moves, banner plates with two rules) but its own thing: a warm violet dusk instead of navy (Lantern Glass), indigo (Space Invaders), deep blue (Moonlit Bed) or near black (Asteroids). The four round themes (Mint, Rose, Sky, Lilac) are pastel lights, not jewel colours.')
P('')
P('### 1.2 The names and the roles')
P('')
table(['Role in the brief', 'Name', 'What it is'], [
    ['The game', '**Lamplighter** (working title Cuber)', 'You light every lamp on the hill before the night takes it'],
    ['A cube', '**a lamp**', 'A block of lilac stone with a glass top that lights up'],
    ['The hero', '**Pip**', 'A round lemon gummy that glows from inside, big eyes, pink cheeks, a little glowing sprout on its head, two stubby feet'],
    ['The chaser, as a ball', '**the seed**', 'A charcoal egg with a glowing ember crack, rim red hot'],
    ['The chaser, hunting', '**the Coil**', 'A smouldering charcoal serpent: two coils on the lamp, a horned head reared over them, yellow eyes, an open jaw with fangs, a red hot rim and embers glowing in its seams'],
    ['The bouncer', '**a Thorn**', 'A red ball with four spikes and two narrow eyes'],
    ['The freezer', '**a Frost**', 'An eight sided ice crystal with a white star, no rim, no eyes'],
    ['The undoers', '**Snuff** (left edge) and **Puff** (right edge)', 'Two moths who put lamps out: Snuff has dusty lilac wings, Puff dusty sand wings'],
    ['A disc', '**a halo**', 'A floating ring of cool light; a band of white runs round it'],
    ['The target colour', '**the round\'s light**', 'Mint, Rose, Sky or Lilac, shown as a small lit lamp in the HUD'],
])
P('')
P('### 1.3 What is the same on purpose')
P('')
P('- **Everything that kills Pip is red hot or red**: the Coil and its seed have an Ember rim (`FF5A36`) and ember seams; a Thorn is red (`EC3442`). Nothing else on the board uses red, and no helpful thing has a rim.')
P('- **Everything that helps is ice**: the Frost and the halos share the cool cyan white of the Ice and Halo rows, and the freeze tints the hunters in the same Ice row.')
P('- **Gold is good news**: Pip\'s base (`FFD247`) is the Gold of points, the high score and the extra life.')
P('- **Light means progress**: the lamp states go from dark to bright in every theme, the lit lamp spills light on its stone, and the level clear is a ripple of white.')
P('- **The shapes keep them apart without colour**: Pip is round with feet and a sprout, the seed is an egg (taller than wide, smooth), a Thorn is a ball with spikes, a Frost is an octagon with a star, the Coil is tall with horns, the moths have wings.')
P('')

# ======================================================================================================================
P('## 2. The palette')
P('')
P('**%d distinct colours.** Some names share a value on purpose and say so.' % count_distinct())
P('')
P('### 2.1 Tone rows')
P('')
P('Most rows are made from a base: tone 1 and 2 are the base mixed with white, tones 4 and 5 the base mixed with Outline `0B0614`. Rows marked "set by hand" are not made that way.')
P('')
table(['Row', '1 Highlight', '2 Light', '3 Base', '4 Shade', '5 Edge', 'Used for'],
      [[n] + ['`%s`' % v for v in t] + [d] for n, t, d in ROWS])
P('### 2.2 Single colours')
P('')
for g, items in GROUPS:
    P('**%s**' % g)
    P('')
    table(['Name', 'Hex', 'Used for'], [[n, '`%s`' % h, d] for n, h, d in items])

P('### 2.3 The round themes')
P('')
P('The light changes every **round** (four rounds to a level, so every level shows all four), as the target colour of the brief does. The level sets the rules (two hops or three, undo lamps). The theme is round - 1 (0 to 3).')
P('')
table(['Round', 'Theme', 'Unlit row', 'Half row', 'Done row (the target)', 'Lip colours of a lit lamp'],
      [[i + 1, n, 'Unlit', h, d, 'Spill %s, Spill %s Dark' % (d, d)] for i, (h, d, n) in enumerate(THEMES)])

# ======================================================================================================================
P('## 3. The scenery')
P('')
P('### 3.1 The background (baked once per screen)')
P('')
P('- Rows 0 to 30: HUD `0C0818`. Row 31: HUD Rule `2C2250` across the canvas.')
P('- Rows 32 to 255: six flat bands, %s. The two rows above each band boundary are a checkerboard of the two bands: pixel (x, y) takes the lower band when `(x + y)` is even. No gradient.' % ', '.join('%s from row %d' % (n, y) for y, n in S.BANDS))
P('- **Stars**: %d single pixels, baked. Positions come from a seeded random (seed 7) in x 2 to 253, y 34 to 213; about one in five is Star `8676B4`, the rest Star Dim `3A2C5E`. The generator\'s list: %s.' % (len(S.stars()), ', '.join('(%d, %d)%s' % (x, y, '*' if n == 'Star' else '') for x, y, n in S.stars())))
P('  A `*` marks a bright one. Four of the bright ones twinkle (section 9).')
P('- **The void**: the two darkest bands under the pyramid, plus the falling motes (section 9). Nothing else is there, so a fall reads as "gone".')
P('')

P('### 3.2 The lamp (32 x 32)')
P('')
P('The picture of one lamp, top left at the cube\'s (x, y). The top is a 2:1 diamond 32 x 16 (rows 0 to 15, 4 pixels wide at the tips); the two faces are 16 high below its lower edges. Light comes from the top left: the left face is lit, the right in shade, the top has a light rim on its two upper edges and a shade rim on its two lower ones.')
P('')
P('**How they tile.** With the pitch of the brief (32 across, 24 down, each row starting 16 further left) the lamps meet exactly, with one overlap: the last row of each face (the `E` edge line) lies under the top rim of the lamp below. Draw the rows from the top down and the edge line shows only on the outer faces of the pyramid, where it gives the hill a crisp dark outline. Checked by the generator: no other pixel overlaps, no gap.')
P('')
FACE = '`L` Left Lip `8E7EB8` (Spill on a lit lamp), `M` Left `5E4F8A`, `N` Left Low `4C3F74`, `R` Right Lip `584A80` (Spill Dark on a lit lamp), `S` Right `3A305E`, `T` Right Low `2E264C`, `E` Edge `150E26`'
grid_block('lamp_unlit (32 x 32): not reached', S.cube_grid('unlit'), '`1` to `5` the Unlit row; ' + FACE)
P('A plain dark slate top. Grey scale: the darkest of the three.')
P('')
grid_block('lamp_half (32 x 32): half way (three hop levels only)', S.cube_grid('half'), '`1` to `5` the theme\'s Half row; ' + FACE)
P('A **ring**: the inner diamond (16 x 8, centred) drawn as a 2 pixel outline in tones 1 (upper half) and 2 (lower half). Grey scale: the middle one, and the only top with a hollow ring.')
P('')
grid_block('lamp_done (32 x 32): lit, the target', S.cube_grid('done'), '`1` to `5` the theme\'s Done row; `L` Spill (theme), `R` Spill (theme) Dark; the rest as above')
P('A **glowing core**: the inner diamond filled with tone 2 and a bright tone 1 bar at its middle, and the light spilling on the lips. Grey scale: by far the brightest.')
P('')
P('Repainting a lamp when its state changes: redraw the whole 32 x 32 picture at its place, then redraw the lamps of the next row that overlap it (its two children cover its edge line) and any sprite on it. That is the small region the brief allows: at most 3 lamp pictures.')
P('')
grid_block('lamp_mini (16 x 16): the target in the HUD', S.cube_grid('done', 16), '`1` to `5` the theme\'s Done row; faces as lamp_done (it is the same recipe at half size, with 1 pixel rims)')

P('### 3.3 Lit glint and the ripple')
P('')
P('When a lamp reaches **done**, it is repainted at once and the glint plays over its top (drawn as a sprite with its top left on the cube\'s top left): frame 1 flashes the upper rim white and shows a small star, frame 2 a long four point star, frame 3 a small star and two sparkles. Tone 1 is the theme\'s Done row.')
P('')
for k in (1, 2, 3):
    block(A['glint_%d' % k], row_word='theme\'s Done')
P('**The ripple** (level clear): 28 steps of 40 ms, one lamp per step in reading order (row 1 to 7, left to right). At its step a lamp shows glint_1 for 2 steps (80 ms) and goes back to plain done. Two passes, the second starting when the first is at row 5 (step 15). Then the pyramid is repainted **unlit in the next theme** one row per 60 ms from the top (7 steps). At no time does more than one row flash at once, so it is well inside the three flashes a second rule of `docs/accessibility.md`.')
P('')

P('### 3.4 Lamp, foot and halo coordinates (final numbers)')
P('')
P('Row `r` (1 to 7) has `r` lamps, column `c` 0 to r - 1. Lamp top left `x = 128 - 16 r + 32 c`, `y = 48 + 24 (r - 1)`. Foot point `(x + 16, y + 8)`. These are the brief\'s numbers unchanged: the apex lamp is at (112, 48), the bottom row ends at y = 223, the void below is 32 rows.')
P('')
rows = []
for r in range(1, 8):
    rows.append([r, ' '.join('(%d, %d)' % S.cube_xy(r, c) for c in range(r)), ' '.join('(%d, %d)' % S.foot_xy(r, c) for c in range(r))])
table(['Row', 'Lamp top left, c = 0 to r - 1', 'Foot points'], rows)
P('**Halos** sit where a lamp would be if the row went one further: on the left at column -1, on the right at column r, for rows 3, 4 and 5. The halo\'s origin (the middle of its hole) goes on that foot point, so Pip hops onto it with the same arithmetic as onto a lamp: up left from (r + 1, 0) lands on the left halo of row r, up right from (r + 1, r + 1) on the right halo of row r. The gap between a halo and its row\'s end lamp is 4 pixels (the brief asked about 8; at 8 the halo would not be on the hop\'s landing point).')
P('')
table(['Side', 'Row', 'Foot point (halo origin)', 'Halo picture top left'],
      [[s, r, '(%d, %d)' % (x, y), '(%d, %d)' % (x - 12, y - 6)] for s, r, x, y in S.disc_spots()])
P('Which spots hold a halo is a rule of the round; the art draws any of the six.')
P('')
P('**Starts**: Pip on the apex, foot point (128, 56). The seed, Thorns and Frosts drop in at the foot point of (2, 0) or (2, 1), from 24 pixels above it (they appear under the HUD rule), falling 3 pixels a frame, then bounce on. Snuff enters on (7, 0) and Puff on (7, 6), each with a hop from 16 pixels below the foot point. The Coil stands where its seed hatched.')
P('')
P('### 3.5 Pip\'s shadow')
P('')
block(A['shadow'], extra='')
P('Drawn on the lamp under Pip (when standing) and, during a hop, on the start lamp for frames 1 to 2 and on the landing lamp from frame 3. Never drawn off the pyramid (so a hop off the edge has no shadow to land on: a small warning).')
P('')

# ======================================================================================================================
P('## 4. Pip')
P('')
P('Body 12 x 14 (the whole frame), origin (6, 13), the middle of the feet. The Pip row is set by hand (a warm brown edge, not grey). Pip glows from inside: the highlight is on the top of its head, so the mirrored frames are right.')
P('')
for n in ['pip_stand_dr', 'pip_stand_ur', 'pip_blink_1', 'pip_blink_2', 'pip_hop_dr_1', 'pip_hop_dr_2', 'pip_hop_dr_3',
          'pip_hop_ur_1', 'pip_hop_ur_2', 'pip_hop_ur_3', 'pip_fall_1', 'pip_fall_2', 'pip_fall_3', 'pip_fall_4',
          'pip_hit_1', 'pip_hit_2', 'pip_hit_3', 'pip_hit_4', 'pip_ride_1', 'pip_ride_2', 'pip_win_1', 'pip_win_2']:
    block(A[n])
P('**Death flash** (12 x 14): the frame Pip is on, drawn with its tone row swapped: the Flash row for 100 ms (white hot), the Negative row for 100 ms (dark body, white edge), the Flash row for 100 ms. Letters stay as they are. Two white flashes, a small area: inside the accessibility rule.')
P('')
P('### 4.1 Lives')
P('')
block(A['pip_icon'], extra='Drawn at y = 16 in the HUD (section 11).')

# ======================================================================================================================
P('## 5. The seed and the Coil')
P('')
P('### 5.1 The seed (the chaser before it hatches)')
P('')
P('Body 10 x 10, origin (5, 9). Charcoal with an Ember rim and a crack that glows. It is an egg: taller than wide and smooth, where a Thorn is round with spikes.')
P('')
for n in ['seed_1', 'seed_2', 'seed_3', 'seed_hatch_1', 'seed_hatch_2']:
    block(A[n])
P('### 5.2 The Coil')
P('')
P('Picture 16 x 24, origin (8, 23), the middle of the lowest coil. **Its hit box is the 12 x 14 at columns 2 to 13, rows 10 to 23**, exactly Pip\'s box round the same origin, as the brief asks (the hit is on the head, and the head reared above is overhang: 2 columns each side and 10 rows above). The rim `E` is the hot rim; `F` are embers in the seams between coils.')
P('')
for n in ['coil_stand_dr', 'coil_hop_dr_1', 'coil_hop_dr_2', 'coil_hop_dr_3', 'coil_stand_ur', 'coil_hop_ur_1',
          'coil_hop_ur_2', 'coil_hop_ur_3', 'coil_fall_1', 'coil_fall_2', 'coil_fall_3']:
    block(A[n])

# ======================================================================================================================
P('## 6. The Thorn and the Frost')
P('')
P('Both 10 x 10, origin (5, 9), the bottom middle. **A quick glance cannot mix them up**: red and spiky with eyes against pale blue, smooth eight sided, with a white star and no eyes; and the seed is a dark egg with a red rim. The colour check (13) shows them apart in all three kinds of colour blindness and in grey scale (the Frost is the lightest thing that moves, the seed the darkest).')
P('')
P('### 6.1 The Thorn')
P('')
for n in ['thorn_1', 'thorn_2', 'thorn_3']:
    block(A[n])
P('### 6.2 The Frost')
P('')
for n in ['frost_1', 'frost_2', 'frost_3']:
    block(A[n])
P('### 6.3 The freeze burst')
P('')
P('Six frames of a flat ring (2 across for 1 down, like the lamps), 50 ms each, centred on the Frost\'s foot point (the origin is the ring\'s middle). Frames 5 and 6 are dotted as it fades. Drawn over the lamps, under the sprites.')
P('')
for k in range(1, 7):
    block(A['freeze_ring_%d' % k])
P('### 6.4 Frozen (a tint rule, no new art)')
P('')
P('While the freeze lasts, every hunter (seed, Coil, Thorns, moths) is drawn with its **tone digits taken from the Ice row**, and its letters as Ice 5 `2C5E8C` for the dark ones (`B`, `K`, `F`, `Y`, `E`) and Ice 1 `FFFFFF` for the rest. In the last 1000 ms the tint switches off and on every 250 ms (twice a second) to warn that they will move again. See the fourth screen of `cuber-screens.png`.')
P('')

# ======================================================================================================================
P('## 7. Snuff and Puff, the moths')
P('')
P('Body 12 x 12, origin (6, 11). One design, two rows: **Snuff** (left edge) uses the Snuff row, **Puff** (right edge) the Puff row; the grids below are shown with Snuff. `dr` shows the face (eyes), `ur` the back (eye spots of tone 1 on the wings). Symmetric, so the mirror for the left facings is the same picture. They have no rim and no red: they are a nuisance you can catch, not a killer.')
P('')
for n in ['moth_dr_1', 'moth_dr_2', 'moth_dr_3', 'moth_ur_1', 'moth_ur_2', 'moth_ur_3']:
    block(A[n], extra='')
P('Use `dr` for a down right hop and its mirror for down left, `ur` for up right and its mirror for up left, as for Pip. Standing is frame 3. When a moth lands on a lamp, the lamp goes back one state at once (repainted) and four motes of the moth\'s tone 2 drop from it (section 9).')
P('')

# ======================================================================================================================
P('## 8. Halos')
P('')
P('Picture 24 x 12 (lift off 24 x 16), origin (12, 6), the middle of the hole, which is where Pip\'s feet go. The ring is lit on its far side (tone 2) and shaded on its near side (tones 4 and 5); a band of white runs round it a quarter turn a frame.')
P('')
for n in ['halo_1', 'halo_2', 'halo_3', 'halo_4', 'halo_lift_1', 'halo_lift_2', 'halo_gone']:
    block(A[n])

# ======================================================================================================================
P('## 9. Effects')
P('')
P('### 9.1 Sprites')
P('')
for k in (1, 2, 3):
    block(A['puff_%d' % k], row_word='new state\'s')
P('### 9.2 Score pop ups')
P('')
P('The 5 x 7 font at 1x, Gold `FFD247` with a 1 pixel Outline, centred on the thing that scored, its top 26 pixels above the foot point. It rises 1 pixel every 50 ms for 8 pixels, holds 300 ms, shows in Label `9C8EC4` for the last 150 ms, then goes. 25 (a lamp done), 50 (each halo left at the end, shown on the halo before it goes), 100 (a Frost), 300 (a moth caught), 500 (the Coil following Pip off the edge, shown at the spot it fell from, at 2x).')
P('')
P('### 9.3 The effects list')
P('')
table(['Effect', 'Verdict', 'Recipe'], [
    ['Flash and sparkle when a lamp is done', 'keep', 'glint_1 50 ms, glint_2 100 ms, glint_3 100 ms over the lamp; the lamp itself is repainted done at once'],
    ['The ripple on a level clear', 'keep', 'section 3.3'],
    ['A trail of 3 dim pixels behind a hop', 'keep, small', 'from hop frame 3 to 10, at Pip\'s three last foot points (one every 2 frames): pixels of Pip 2, Pip 4, Pip 4, each living 100 ms'],
    ['A soft shadow under Pip', 'keep', 'section 3.5'],
    ['Squash and stretch on every bounce', 'keep', 'the frame lists of 4 to 7 do it: crouch, air, land'],
    ['Flash the HUD target when the last lamp is done', 'keep', 'the mini lamp draws in Spark `FFFFFF` for 100 ms, back for 100 ms, Spark for 100 ms'],
    ['Falling sparks when anything leaves the edge', 'keep', '6 particles from the point it left: start 2 pixels apart, fall 1 to 3 pixels a frame, colours tone 2 of its row then tone 4, live 400 ms'],
    ['A ring when a Frost goes off', 'keep', 'section 6.3'],
    ['A slow drift of stars or lights', 'keep', '4 far lanterns (2 x 3 Lantern, a Lantern Dim pixel each side of the middle row and a 2 pixel tail under) rise 1 pixel every 200 ms and wrap from y 216 to y 36; 4 bright stars twinkle (swap to Star Dim for 150 ms, one every 700 ms in turn)'],
    ['Discs pulsing', 'changed', 'the white band running round the halo does the job and reads better than a pulse'],
    ['Motes falling into the void (added)', 'add', '10 motes (2 pixels tall, Mote `35264E`) under the pyramid, rows 226 to 255, fall 1 pixel every 80 ms and wrap: the void is a fall, not a floor'],
    ['A blink every few seconds (added)', 'add', 'when Pip stands still: every 3000 to 5000 ms, blink_1 50 ms, blink_2 100 ms, blink_1 50 ms'],
    ['Light spilling down a lit lamp (added)', 'add', 'part of the lamp picture (the lips), no extra cost'],
    ['Moth dust (added)', 'add', 'when a moth undoes a lamp: 4 motes of its tone 2 fall from the lamp top 1 pixel a frame for 300 ms'],
    ['Screen shake', 'drop', 'not affordable, and the death flash says it'],
])

# ======================================================================================================================
P('## 10. Animation recipes and timings')
P('')
table(['What', 'Frames and timing', 'Pixels that change'], [
    ['Pip hop (any direction)', '12 frames (200 ms). Frame f (1 to 12), t = f / 12. Position = start + (end - start) t, minus `round(48 t (1 - t))` in y (12 high at the top). Frames 1 to 2 hop_1 (and Pip stays on the start point for those 2), 3 to 10 hop_2, 11 to 12 hop_3, then stand. dr art for down right and down left (mirrored), ur for up right and up left (mirrored). Puff on landing.', 'Pip 12 x 14 twice (old and new place) plus the shadow, about 400'],
    ['Pip stand', 'stand_dr after a down hop, stand_ur after an up hop (mirrored for the left ones). Blink as 9.3.', 'none'],
    ['Pip falls off the front (a down hop off the edge)', 'the hop goes on past t = 1 with no landing: y speed grows by 0.35 a frame. fall_1 to fall_3 for 100 ms each, then fall_4 until the feet pass y = 260. Falling sparks from the edge point.', 'about 170 a frame'],
    ['Pip falls off the back (an up hop off the edge)', 'fall_4 only, and stop drawing when the feet are 8 pixels below the edge of the lamp it left: it drops behind the hill', 'about 100 a frame'],
    ['Pip is hit', 'hit_1, hit_2, hit_3, hit_4, twice, 80 ms each (640 ms), then the death flash (300 ms), then READY on the apex', '170 a frame'],
    ['Pip rides a halo', 'Pip on halo_lift (alternating 100 ms) from the halo spot to 16 pixels above the apex foot point in a straight line over 1200 ms; ride_1 and ride_2 swap every 150 ms. Then Pip lands on the apex (hop_3 for 2 frames) and the halo is gone (halo_gone for 2000 ms at its spot, then nothing).', 'about 500 a frame'],
    ['Pip wins (level clear)', 'win_1 and win_2 every 150 ms (win_2 drawn 4 pixels higher) for the whole ripple', '170'],
    ['Seed, Thorn, Frost bounce', 'a hop as Pip\'s (12 frames, 10 high): frame 3 (stretch) at f 1 to 2, frame 2 (round) f 3 to 10, frame 3 f 11, frame 1 (squash) f 12 and 4 frames more on the lamp', '100'],
    ['Seed hatches', 'on the bottom row: hatch_1 300 ms, hatch_2 200 ms, then the Coil stands', '100'],
    ['Coil hop', 'as Pip\'s, 12 frames, 10 high: hop_1 f 1 to 2, hop_2 f 3 to 10, hop_3 f 11 to 12, then stand', '16 x 24 twice, about 750'],
    ['Coil falls (following Pip off the edge)', 'fall_1, fall_2 100 ms each, then fall_3 until it leaves the canvas, with falling sparks in Ember; the 500 pop at the edge', '380'],
    ['Moth hop', 'as Pip\'s: frame 1 f 1 to 2, frame 2 f 3 to 10, frame 3 f 11 onwards (also its standing frame)', '150'],
    ['Halo waiting', 'halo_1 to halo_4, 120 ms each, looping', 'about 40 a frame'],
    ['Lamp done', 'repaint, glint (9.3), pop', 'up to 3 lamp pictures once'],
    ['Freeze', 'ring 6 x 50 ms; the tint for the freeze time; warning in the last 1000 ms', 'the ring and the frozen sprites'],
])

# ======================================================================================================================
P('## 11. Screens')
P('')
P('All text is the 5 x 7 font. "Centred" means `x = floor((256 - width) / 2)` with `width = n * 6k - k` for n characters at scale k.')
P('')
P('### 11.1 The HUD (every game screen)')
P('')
table(['Item', 'Text or sprite', 'Colour', 'x, y'], [
    ['Label', 'SCORE, 1x', 'Label `9C8EC4`', '8, 4'],
    ['Score', '6 digits, 2x', 'Text `F4F0FA`', '8, 13 (to 77, 26)'],
    ['High score', '`HI` 1x then 6 digits 1x, one space between', 'HI in Label, digits in Text', 'centred as one 9 character string: x 101, y 4 (digits at x 119)'],
    ['Lives', 'pip_icon, one for each life in hand (not the one in play), up to 5', 'its own', 'y 16, 10 apart, the row centred: first x = 128 - (10 n - 2) / 2'],
    ['Level', '`LEVEL` 1x, then the number 1x', 'Label, number in Text', '182, 4; number at 218, 4'],
    ['Round', '`ROUND` 1x, then the number', 'Label, number in Text', '182, 16; number at 218, 16'],
    ['Target', 'lamp_mini in the round\'s Done row', 'its own', 'top left 232, 8'],
    ['Rule', 'the HUD Rule line', '`2C2250`', 'row 31'],
])
P('Text in the HUD needs no outline (it sits on HUD `0C0818`); text on the play area always has the 1 pixel Outline.')
P('')
P('### 11.2 Title and attract (`cuber-preview-title.png`)')
P('')
table(['Item', 'Text or sprite', 'Colour', 'x, y'], [
    ['High score', 'as the HUD', 'as the HUD', '101, 4'],
    ['Title', TITLE + ', 3x, with Outline', 'gradient Title Top `FFF4C0` to Title Bottom `FF9A4E`', 'centred: x %d, y 16 (to y 36)' % ((256 - text_width(TITLE, 3)) // 2)],
    ['The pyramid', 'all unlit, Mint theme, two halos (left and right of row 4)', '', 'section 3.4'],
    ['Pip', 'the intro (below)', '', 'from the apex'],
    ['Press space', 'PRESS SPACE, 2x, Outline', 'Gold `FFD247`', 'centred: x 63, y 228; shown 600 ms, hidden 400 ms'],
    ['Keys', 'ARROWS HOP   P PAUSE, 1x', 'Label', 'centred: x %d, y 246' % ((256 - text_width('ARROWS HOP   P PAUSE')) // 2)],
])
P('**The intro** (the first five seconds): the title is drawn one letter every 60 ms, left to right, each letter dropping 4 pixels into place over 3 frames. Then Pip lands on the apex from above (hop_2 then hop_3) and hops down the middle, (1, 0), (2, 1), (3, 1), (4, 2), (5, 2), (6, 3), (7, 3), one hop every 500 ms, lighting each lamp with its glint. At the bottom it turns to face the player (stand_dr, a blink) and the ripple runs once over the lit path. After 4 seconds of quiet the path goes dark (one lamp per 60 ms from the bottom) and the intro starts again. About 600 pixels change at the busiest frame.')
P('')
P('**Keys** (a proposal; the brief does not fix them): the arrows as the pyramid seen at 45 degrees: Up = up right, Right = down right, Down = down left, Left = up left; the number pad 9, 3, 1, 7 for the same. P pauses, Space starts.')
P('')
P('### 11.3 READY, PAUSED, level clear, game over, new high score')
P('')
P('A **banner plate** is a full width band of Plate `0C0818` with a 1 pixel Plate Rule `6ED2F2` as its top and bottom rows.')
P('')
table(['Screen', 'Plate rows', 'Text', 'Colour', 'x, y', 'Timing'], [
    ['READY', '112 to 135', 'READY, 2x', 'Text', 'centred, y 117', '1500 ms at the start of every life; Pip already on the apex'],
    ['PAUSED', '112 to 143', 'PAUSED 2x; P TO PLAY 1x', 'Text; Label', 'centred, y 116; centred, y 134', 'while paused; everything else stops'],
    ['Level clear', 'none', 'the ripple (3.3), Pip winning; then ROUND n or LEVEL n, 2x, on a plate at 112 to 135 for 1000 ms', 'Gold', 'centred, y 117', 'about 3 seconds in all'],
    ['GAME OVER', '100 to 155', 'GAME OVER, 3x', 'gradient Over Top `FFB0A0` to Over Bottom `EC3442`', 'centred: x 48, y 108', 'the game frozen under it; 4000 ms, then the title'],
    ['New high score', '(on the GAME OVER plate)', 'NEW HIGH SCORE 1x; the score 1x', 'Gold; Text', 'centred, y 136; centred, y 146', 'NEW HIGH SCORE shown 500 ms, hidden 250 ms. Without a new best the plate shows only SCORE 004325 in Text at y 140'],
    ['Extra life', 'none', 'a pop up 1UP at the HUD lives row', 'Gold', 'over the new icon', 'as a score pop up'],
])

# ======================================================================================================================
P('## 12. Later levels')
P('')
P('Shown in `cuber-themes.png`, one row per theme.')
P('')
P('- **Three hop lamps**: unlit, then **half** (the ring), then **done** (the core). Shown above in 3.2. All four themes keep the order dark, middle, bright (luminance in 13).')
P('- **Undo lamps** (levels where a hop on a lit lamp turns it back): the same lamps with a **dotted rim**, every other row of the outer rim swapped: light dots on an unlit or half lamp, dark dots (tone 5) on a lit one. The dots tell the player "this one can go back" without colour.')
grid_block('lamp_undo (32 x 32): an unlit lamp that can turn back', S.cube_grid('undo'), '`1` to `5` the Unlit row (the dots are tone 1); faces as lamp_unlit')
grid_block('lamp_undo_done (32 x 32): a lit lamp that can turn back', S.cube_grid('undo_done'), '`1` to `5` the theme\'s Done row (the dots are tone 5); faces as lamp_done')
P('- **A flipping lamp** (optional, later): one frame, the top squashed to 8 rows and the lit underside showing as a band (`D` the theme\'s Done 3). Play: unlit, this frame for 60 ms, its own mirror (rows of the top reversed) for 60 ms, the new state.')
grid_block('lamp_flip (32 x 32)', S.flip_grid(), '`1` to `5` the Unlit row; `D` the theme\'s Done tone 3; faces as lamp_unlit')
P('- **A bonus round** (a suggestion): the lamps are dark, the sky is the Void Deep colour, and a dozen halos float over the pyramid at random lamp foot points; Pip has 20 seconds to hop on as many as it can (each one 100) with no enemies. It reuses every picture in this file.')
P('')

# ======================================================================================================================
P('## 13. Checks')
P('')
bad = check.validate()
P('- **Every sprite fits its size**, every pixel is `.` or in its legend, no legend has more than 16 entries: %s. Sizes: Pip and its frames 12 x 14; the seed, the Thorn, the Frost 10 x 10; the moths 12 x 12; the Coil\'s picture 16 x 24 with its 12 x 14 hit box (5.2); halos 24 x 12 (24 x 16 lifting).' % ('passed' if not bad else ', '.join(bad)))
P('- **The lamps tile exactly** on the brief\'s pitch (only the edge line is covered, 3.2), and every sprite\'s origin goes on the middle of the top diamond (3.4).')
P('- **The lamp states in grey scale** (relative luminance of the base tone, unlit / half / done):')
P('')
table(['Theme', 'Unlit', 'Half', 'Done'], [[n, '%.3f' % a, '%.3f' % b, '%.3f' % c] for n, a, b, c in check.state_lum()])
P('Each step is at least 2 times brighter than the one before, and the patterns (plain, ring, core) differ too.')
P('')
P('- **Things that must not be confused**, the smallest colour distance (redmean, 0 to about 765) between Pip, the Coil, the Ember rim, the Thorn, the Frost, the two moths and the halos, per vision:')
P('')
table(['Vision', 'Smallest distance', 'Between'], [[k, '%.0f' % v[0], '%s and %s' % (v[1], v[2])] for k, v in check.separation().items()])
P('The closest pairs are kept apart by shape: the Ember rim is a 1 pixel line round a dark serpent, the Thorn a filled red ball; the Frost is a filled crystal, a halo a ring with a hole; Pip is round with eyes and feet, Puff has wings.')
P('')
P('- **Against the ground** (contrast ratio of a thing\'s base, and of the edge where it has one, against the sky, an unlit, a half and a lit lamp):')
P('')
table(['Thing'] + check.GROUNDS, [[t] + ['%.1f' % c for c in cs] for t, cs in check.contrast_table()])
P('Where a base is close to a ground (Pip on a lit lamp, the Coil on an unlit one, a Thorn on a half one) the edge carries it: Pip\'s tone 5 edge is 9.7 against a lit Mint top, the Coil\'s Ember rim 3.1 against an unlit top and 5.5 against the sky, the Thorn\'s tone 5 edge is dark on every pale top. Check this by eye in `cuber-colour-check.png`.')
P('')
P('- **Text**: ' + ', '.join('%s on %s %.1f' % (a, b, c) for a, b, c in check.text_contrast()) + '.')
P('- **Nothing changes the whole screen every frame**: the biggest change is the ripple, one lamp top per 40 ms.')
P('- **Colour blindness**: `cuber-colour-check.png`, the in game screen, the freeze screen and the swatches as drawn, then deuteranopia, protanopia and tritanopia (Machado 2009 matrices), then grey scale.')
P('')

# ======================================================================================================================
P('## 14. What I decided, and what is open')
P('')
P('- **Name**: Lamplighter (the hero lights lamps). Characters Pip, the seed, the Coil, Thorns, Frosts, Snuff and Puff, halos. Nothing is named after the original.')
P('- **Canvas**: 256 x 256 and the brief\'s cube numbers, unchanged. Halos are 4 pixels from their row (the hop landing point decides that), not 8.')
P('- **Direct colour PixelCanvas**, not palette indexed cells.')
P('- **The light changes every round**, not every level, so each level shows all four themes. The level sets the rules. If you would rather the theme follow the level, nothing in the art changes, only which row the HUD and the lamps use.')
P('- **One rule I would add** (optional): the brief does not say how a fall off the back looks; I draw it as dropping behind the hill (10, fall off the back).')
P('- **Scores**: unchanged from the brief.')
P('- **Open**: the keys (11.2 is a proposal); whether the moths should hop on the side faces like true sideways hoppers (I keep them on the tops, standing on the edge lamps, which reads more clearly at this size); the bonus round; the class names (suggest `LamplighterLook`, `LamplighterArt`, `LamplighterPalette` instead of Cuber*); an ABL art generator is not written.')
P('')
P('## 15. The generator')
P('')
P('`cuber-generator/` (Python 3 and Pillow). `python run_all.py` writes this file and every `cuber-*.png` into the folder above it. `palette.py` holds every colour, `scene.py` the lamps, the layout and the sky, `sprites.py` every sprite, `preview.py` the screens, `check.py` the checks, `doc.py` this file.')
P('')

text = '\n'.join(out)
assert chr(0x2014) not in text and chr(0x2013) not in text
open(sys.argv[1] if len(sys.argv) > 1 else '../out/cuber-art.md', 'w').write(text)
