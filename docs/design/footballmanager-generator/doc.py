"""Writes footballmanager-art.md from the same data that draws the previews."""
import sys
from palette import GROUPS, NAMED, ROWS, TONE, count_distinct
from lib import grid, text_width
from font import EXTRA, SMALL
import scene as S
import sprites as SP
import figures as F
import items as I
import screens as SC
import goalmouth as G
import keeper as K
import preview as PV
import check

out = []
P = out.append
A = SP.ALL


def legend_line(legend, rows, row=None):
    used = sorted(set(ch for r in rows for ch in r if ch != '.'))
    parts = []
    digits = [k for k in '12345' if k in used]
    if digits and row:
        parts.append('`%s` tones %s of the %s row (%s)' % (''.join(digits), ', '.join(digits), row,
                                                         ', '.join('`%s`' % TONE[row][int(d) - 1] for d in digits)))
    for k in sorted(legend):
        if k in used and not (k.isdigit() and row):
            parts.append('`%s` %s `%s`' % (k, legend[k], NAMED[legend[k]]))
    return '; '.join(parts) or 'none'


def block(name, rows, legend, origin, note='', row=None):
    P('#### %s (%d x %d, origin (%d, %d))' % (name, len(rows[0]), len(rows), origin[0], origin[1]))
    P('')
    if note:
        P(note)
        P('')
    P('Legend: ' + legend_line(legend, rows, row) + '.')
    P('')
    P('```')
    for r in rows:
        P(r)
    P('```')
    P('')


def sblock(s, note=None):
    block(s.name, s.rows, s.legend, s.origin, s.note if note is None else note, getattr(s, 'row', None))


def table(head, rows):
    P('| ' + ' | '.join(head) + ' |')
    P('|' + '|'.join(['---'] * len(head)) + '|')
    for r in rows:
        P('| ' + ' | '.join(str(c) for c in r) + ' |')
    P('')


# ======================================================================================================================
P('# FootballManager: art and screen design, "Chalk and Floodlights"')
P('')
P('Designer\'s answer to `footballmanager-art-brief.md` (the revised brief of 9 November 2026) and `footballmanager-rules.md`. Everything here is meant to be pasted into code with no further decisions. Section 11 lists what I decided and the calls still open for James.')
P('')
P('**The idea in one line.** Every menu is the **chalkboard in the dressing room**: chalk lettering on a bottle green slate in a wooden frame, red and blue tactics magnets for the picks. Every match is a **floodlit night game** seen from the gantry: a bright mown pitch, a dark stand of dots that jumps when a goal goes in, and a close up of the goal mouth for every shot. The working title stays in the file names; the name I propose for the game is **Gaffer** (section 1.2).')
P('')
P('**What is kept and what is ours.** The rules, the numbers, the weekly order (menu, pick the team, the match, the result and the money, the table, one transfer offer), the five team numbers, the four divisions of 16 and every screen in the brief\'s list are kept as the brief and the rules file give them. The name, the look, the goal mouth view (face on from the penalty spot, not isometric), the badges, the faces and **all club and player names** are original. The design does not use the 1982 game\'s name, screens, lettering, colours or its lists of clubs and players: the names in the previews are invented placeholders, and the art does not depend on any name, since every screen draws whatever text the game holds.')
P('')
P('Previews (made by the generator from the data in this file, so the pictures and the text cannot disagree):')
P('')
P('- `footballmanager-preview.png` (3x): the match part way through, attack 7, the close up showing a high save.')
P('- `footballmanager-preview-table.png` (3x): the division 3 table, your club 3rd, both zones marked.')
P('- `footballmanager-preview-squad.png` (3x): the squad, the cursor on a midfielder, all three energy levels.')
P('- `footballmanager-preview-title.png` (3x): the title, part way through the intro (the shot on its way).')
P('- `footballmanager-screens.png` (2x): every other screen: the three set up screens, the week menu, pick the team, results, the money report, the transfer offer (bid, and refused), sell a player, the cup round, full time, end of season, sacked, paused, the trophy cabinet.')
P('- `footballmanager-goalmouth.png` (3x): the nine saves, goals, wide, over, off the post, the shot\'s three frames and the ripple.')
P('- `footballmanager-later.png` (2x): the four division looks and the stand at four sizes (section 9).')
P('- `footballmanager-sprites.png` (4x): every sprite, alternate rows on the board and on the grass.')
P('- `footballmanager-colour-check.png` (1x): the match, the squad and the money report as drawn, through deuteranopia, protanopia and tritanopia, and in grey scale.')
P('')
P('## 0. Read this first')
P('')
P('- The canvas is **320 x 240**, as the brief proposes, shown at 3x (2x on small screens), nearest neighbour. It is a **direct colour PixelCanvas** like Space Invaders, Centipede, Xevious and Cuber. 320 is wide enough: the table\'s last column ends at x 306 in the 5 x 7 font at 1x, so no size change is asked for.')
P('- Every menu screen has the same frame: the **status bar** (rows 0 to 13), the **board** in its wooden frame (rows 14 to 227), the **key bar** (rows 228 to 239). The match replaces the status bar with a **score bar** and the board with the pitch (section 3.1).')
P('- **Sprite format**: the tone format of `snake-art.md`. `.` is transparent, `1` to `5` are the tones of the sprite\'s colour row (1 highlight, 2 light, 3 base, 4 shade, 5 edge), letters are fixed colours given in each legend. No legend has more than 16 colours (the largest has %d).' % max(len(s.legend) for s in A.values()))
P('- **Origin**: every sprite gives its origin. For a figure it is **the middle of its feet** and goes on `cell_xy(column, row)` (section 3.2). Badges, faces and icons are placed by their top left (origin (0, 0)).')
P('- **Facing**: figures are drawn facing right; the game mirrors the columns for left (the origin column becomes `width - 1 - x`). Every figure is lit from the top, so a mirrored figure is right. The kit pattern is applied **before** mirroring (section 4.1).')
P('- **Text**: the house 5 x 7 font, plus six new glyphs and a 3 x 5 font for the dense places (section 5). Everything is in capitals.')
P('- **Draw order** on the match: the baked background (stands, pitch, goals), the figures sorted by feet y (then x), the ball\'s shadow, the trail, the ball, the score bar and ticker, then the close up and any plate on top.')
P('- **Time** is in milliseconds. Nothing changes every pixel every frame: the biggest per frame change is opening the close up (96 x 64, once) or swapping the crowd tiles (two strips of 320 x 8, every 150 ms during a cheer).')
P('- **No blending**: every colour below is a flat value. A glow or a shadow is extra pixels in a dimmer colour.')
P('')
P('## 1. Names and art direction')
P('')
P('### 1.1 The look: Chalk and Floodlights')
P('')
P('The menus are a **chalkboard** in a warm wooden frame, as if the week were planned on the dressing room wall: the slate is a deep bottle green (`14231E`), the text is chalk (warm white, a dim grey green for labels, a yellow chalk for anything that is yours or chosen), a few specks of chalk dust are baked into the slate, every second table row is a faint wipe, and the picks are **tactics magnets** (a red disc to start, a blue ring for the reserve). The match is the opposite light: a **night game under floodlights**, the pitch bright and mown in stripes, the stands dark and full of little coloured dots, the lamp heads glowing in the corners. The colours mean things and mean them everywhere: **chalk green is good** (credit, promotion, fresh legs, a win), **chalk red is bad** (debt, relegation, spent legs, defeat, the sack, every cost), **amber is a warning**, **yellow is you**, **blue is them and information**, **gold is money and glory**. Every one of those meanings also has a shape (a sign, an icon, a fill pattern, an arrow) so it never rests on hue alone.')
P('')
P('It is a sibling of the others (dark ground, chunky pixels, the 5 x 7 font, banner plates with two rules) but its own thing: the only game on a green slate, the only one with a wood frame, and its accent is chalk yellow rather than amber (Lantern Glass), neon (Space Invaders) or ember (Dusk Lamps).')
P('')
P('### 1.2 The names')
P('')
table(['Thing', 'Name', 'Why'], [
    ['The game', '**Gaffer** (working title FootballManager, kept in the file names)', 'What the players call the manager. Short, warm, a little funny, and not the original\'s name'],
    ['The look', 'Chalk and Floodlights', 'The board for the week, the lights for the match'],
    ['The week menu', 'the Manager\'s Office (the board\'s title)', 'The menu of the original\'s choices, under a friendlier heading'],
    ['The cup', 'THE CUP', 'A knockout cup with no real competition\'s name (see 11.2)'],
    ['A pick', 'a magnet', 'Red disc to start, blue ring for the reserve'],
])
P('### 1.3 What is the same on purpose')
P('')
P('- **Everything that costs you is Chalk Red** (`%s`): debt, wages, rent and interest in the money report, relegation, a spent bar, an injury, a defeat, SACKED. Everything that pays is **Chalk Green** (`%s`). A minus sign, the cracked coin or a down arrow always comes with the red; a plus sign, the coin or an up arrow with the green.' % (NAMED['Chalk Red'], NAMED['Chalk Green']))
P('- **Yellow chalk is you**: your club\'s name and row, your bars on the pick screen, the cursor, the selected item. **Blue chalk is them** (their bars) and information (week, division, morale, the cup).')
P('- **Gold is money and glory**: the coin, the league trophy and the title lettering share the Gold row.')
P('- **The keeper is marigold everywhere**: the Keeper row on the pitch and in the close up, and the goalkeeper position icon (`Pos GK` = `Keeper 3`).')
P('- **The board\'s rows** mean the same on every screen: Board Stripe on every second row, Cursor Row under the cursor, Your Row (with two Chalk Yellow rules) under your club.')
P('')
# ---------------------------------------------------------------------------------------------------------------- palette
P('## 2. The palette')
P('')
P('**%d distinct colours.** Some names share a value on purpose and say so.' % count_distinct())
P('')
P('### 2.1 Tone rows')
P('')
P('Most rows are made from a base: tones 1 and 2 are the base mixed with white, tones 4 and 5 the base mixed with Outline `0A0D0C`. Rows marked "set by hand" are not made that way.')
P('')
table(['Row', '1 Highlight', '2 Light', '3 Base', '4 Shade', '5 Edge', 'Used for'],
      [[n] + ['`%s`' % h for h in t] + [d] for n, t, d in ROWS])
P('### 2.2 Single colours')
P('')
for g, items in GROUPS:
    P('**%s**' % g)
    P('')
    table(['Name', 'Hex', 'Used for'], [[n, '`%s`' % h, d] for n, h, d in items])
# ---------------------------------------------------------------------------------------------------------------- scenery
P('## 3. The scenery')
P('')
P('### 3.1 The match screen, by rows')
P('')
table(['Rows', 'What'], [
    ['0 to 17', 'the score bar (Tunnel, a Tunnel Rule on row 17), section 6.12'],
    ['18 to 33', 'the top stand: Roof rows 18 and 19, Roof Edge row 20, one row of crowd tiles rows 21 to 28, Wall row 29, the hoardings rows 30 to 33'],
    ['34 to 193', 'the pitch: 32 x 20 cells of 8 x 8 from x 32 (x 32 to 287); Run Off to the sides (x 0 to 31 and 288 to 319)'],
    ['194 to 205', 'the bottom stand: the hoardings rows 194 to 197, a row of crowd tiles rows 198 to 205'],
    ['206 to 227', 'the ticker (Tunnel, a Tunnel Rule on row 206)'],
    ['228 to 239', 'the key bar'],
])
P('Two floodlight heads (3.3) sit on the top stand at (3, 19) and (305, 19).')
P('')
P('### 3.2 The pitch and its cells')
P('')
P('The pitch is seen **from above**, the figures from the side (the classic way, and it keeps a cell square). The ball runs on **32 columns by 20 rows of cells of 8 x 8 pixels**, the size the brief proposes; it suits the look.')
P('')
P('- `cell_xy(c, r) = (32 + 8c + 4, 34 + 8r + 7)`: the middle of the bottom row of the cell. A figure\'s feet (its origin) go here, so its 12 rows rise 4 rows into the cell above.')
P('- `ball_xy(c, r) = (32 + 8c + 4, 34 + 8r + 4)`: the middle of the cell, the ball\'s origin. Its shadow is drawn 1 right and 3 down.')
P('- **The goals** are at both ends on **cell rows 8 to 11** (y 98 to 129), the left goal outside column 0, the right outside column 31 (see 11.2 about the rules file\'s goal numbers).')
P('')
P('The background, drawn once:')
P('')
table(['Part', 'Recipe'], [
    ['Run off', 'Run Off over rows 34 to 193, the full width'],
    ['Mown stripes', '16 stripes 16 pixels wide from x 32: Grass A on even stripes, Grass B on odd'],
    ['Touch and goal lines', 'Line on x 32 to 287 at y 34 and y 193; on y 34 to 193 at x 32 and x 287'],
    ['Halfway line', 'Line, 2 wide, x 159 and 160'],
    ['Centre circle', 'Line on the points of a circle radius 22 round (159.5, 113.5) (every 0.5 degree, rounded); a 2 x 2 spot at (159, 113)'],
    ['Penalty areas', '5 cells deep, cell rows 4 to 15 (y 66 to 161): the box lines at x 72 (left) and x 247 (right)'],
    ['Goal areas', '2 cells deep, cell rows 7 to 12 (y 90 to 137): lines at x 48 and x 271'],
    ['Spots', '2 x 2 at (60, 113) and (258, 113)'],
    ['Arcs', 'the points of a circle radius 18 round each spot that lie outside the box'],
    ['Goals', 'from above: 8 x 32 of Net Dark at x 24 to 31 and x 288 to 295, y 98 to 129, with Net on every pixel where (x + y) mod 3 = 0; Post on the goal line side (x 31 and x 288, y 97 to 130) and along the top and bottom (y 97 and 130); Net on the back line'],
    ['Corner flags', 'a 1 x 3 Post above each corner and a 2 pixel Chalk Yellow flag pointing in'],
])
P('### 3.3 Stands, crowd, hoardings and floodlights')
P('')
P('- **Crowd**: the tiles `crowd_1` (sitting) and `crowd_2` (cheering) of 32 x 8, repeated every 32 pixels from x 0. On a goal the two tiles swap every 150 ms for 1200 ms (section 7).')
P('- **Hoardings**: 4 rows of Hoarding, then blocks of lettering 2 rows tall on the middle 2 rows, starting at x 3: widths 10, 6, 14, 8, 12 repeating, a gap of 7 after each; block k is Hoarding Warm when k mod 3 = 0, else Hoarding Lit. There are no words on them.')
P('- **Floodlight**: a lamp head of 6 x 3 Floodlight at (x, y); round it a ring of Flood Glow (x - 1 to x + 6, y - 1 to y + 3) and outside that a ring of Flood Haze (x - 2 to x + 7, y - 2 to y + 4).')
P('')
for s in (A['crowd_1'], A['crowd_2']):
    sblock(s)
P('### 3.4 The goal mouth (96 x 64)')
P('')
P('Seen **face on from the penalty spot**: a strip of crowd, the wall and the hoardings, the dark stand, the goal frame with the net inside, the grass in front. It is drawn into a frame over the middle of the pitch for every shot (section 6.12) and reused on the title screen. The crossbar is rows 15 to 17, the posts x 10 to 12 and x 83 to 85, the net x 13 to 82 from row 18, the goal line row 47, the six yard line row 56.')
P('')
P('The targets (the ball\'s centre): columns **x 24, 48, 72** (left, middle, right) by rows **y 22, 32, 42** (high, middle, low). Outside the frame: wide left (4, 38), wide right (91, 38), over the bar (48, 9), off the left post (13, 30), off the right post (83, 30). The keeper\'s ready feet are at (48, 54). On a goal the crowd strip (rows 0 to 7) shows `crowd_2` instead.')
P('')
P('#### goal_mouth (96 x 64, top left (0, 0))')
P('')
P('Legend: ' + '; '.join('`%s` %s `%s`' % (k, v, NAMED[v]) for k, v in sorted(S.GM_LEGEND.items())) + '.')
P('')
P('```')
for r in S.goal_mouth_rows():
    P(r)
P('```')
P('')
P('### 3.5 The board (every menu screen)')
P('')
table(['Part', 'Recipe'], [
    ['Frame', 'four rings from the outside in, each 1 pixel, from row 14 to row 227 and x 0 to 319: Wood 5, Wood 3, Wood 2 (the inlay ring, which changes by division, section 9), Wood 4'],
    ['Board', 'Board over x 4 to 315, y 18 to 223'],
    ['Chalk dust', 'a board pixel (x, y) is Board Dust when (37x + 101y + (xy mod 17)) mod 71 = 0 (about 1 in 71, baked once)'],
    ['Title band', 'Board Head over y 18 to 30, a Board Rule on y 31; the title in Chalk Yellow at (10, 21); the right hand note in Chalk Dim, right edge x 309, y 21'],
    ['Content', 'from y 33 down to y 223'],
    ['Table rows', 'every second row a band of Board Stripe the height of the row; the cursor\'s row Cursor Row; your club\'s row Your Row with a Chalk Yellow rule above and below'],
])
# ---------------------------------------------------------------------------------------------------------------- sprites
P('## 4. Sprites')
P('')
P('### 4.1 The kits and the match figures')
P('')
P('The figures (8 x 12, origin (4, 11), facing right) are given once with the shirt in tones 1 to 4; a kit is a tone row plus fixed letters plus a **pattern**, applied before mirroring, to the torso\'s tone pixels only (the torso is the rows from the first row holding a `1` down to the row above the first `S`):')
P('')
table(['Kit', 'Tone row', '`S` shorts', '`T` shorts shade', '`C` hands', 'Pattern (becomes `P`)', '`P` colour'], [
    ['home', 'Home', 'Home Shorts', 'Home Shorts Dark', 'Skin', '**vertical stripes**: torso columns 3 and 5, below the torso\'s top row', 'Home Stripe'],
    ['away', 'Away', 'Away Shorts', 'Away Shorts Dark', 'Skin', '**a hoop**: the torso\'s third row (top + 2), all of it', 'Away Hoop'],
    ['keeper', 'Keeper', 'Keeper Shorts', 'Keeper Shorts Dark', 'Glove', 'none (plain shirt, white gloves)', ''],
    ['referee', 'Referee', 'Referee 4', 'Referee 5', 'Skin', '**a collar**: the torso\'s top row', 'Ref Collar'],
])
P('Fixed letters in every figure: `A` skin, `B` skin shade, `H` hair, `O` Boot, `C` hands. **Skin and hair vary** by the player\'s number n (1 to 24): skin pair `n mod 3` (Skin 1, Skin 2, Skin 3, each with its Shade), hair `n mod 4` (Hair Dark, Hair Black, Hair Fair, Hair Ginger). The keepers and the referee use pair 1 and Hair Dark. The home side (left, attacking right) always wears home and the away side away, whichever is your club.')
P('')
P('The four kits standing, as the brief asks (pattern applied):')
P('')
for kit in ('home', 'away', 'keeper', 'referee'):
    s = SP.FIGS[('fig_stand', kit)]
    block('fig_stand_%s' % kit, s.rows, s.legend, s.origin, '', s.row)
P('The frames, before the pattern (shown with the Home row and the home legend):')
P('')
FRAME_NOTES = {
    'fig_stand': 'Standing (also the referee standing).',
    'fig_run_1': 'Running 1 of 4: contact, right leg forward (also referee run 1).',
    'fig_run_2': 'Running 2: passing, the body 1 pixel up.',
    'fig_run_3': 'Running 3: contact, the other leg (also referee run 2).',
    'fig_run_4': 'Running 4: passing.',
    'fig_kick_1': 'Kicking 1: the wind up (the anticipation frame, shown 80 ms before the ball moves).',
    'fig_kick_2': 'Kicking 2: the strike, the leg through; the ball leaves on this frame.',
    'fig_cheer_1': 'Celebrating 1: arms up.',
    'fig_cheer_2': 'Celebrating 2: a jump, arms wide.',
}
for n in FRAME_NOTES:
    s = SP.FIGS[(n, 'home')]
    block(n, grid(F.FIG[n]), s.legend if n != 'fig_stand' else s.legend, s.origin, FRAME_NOTES[n], 'Home')
P('### 4.2 The keeper on the pitch')
P('')
P('Keeper kit (marigold, white gloves). Ready and got it are 8 x 12 with origin (4, 11); the dives are 12 x 12 with origin (6, 11), the middle of the bottom row, which goes on the keeper\'s cell. **Dive up** is toward the top of the screen (the keeper of the left goal reaching to his left), **dive down** the other way; mirror both for the right goal.')
P('')
GK_NOTES = {'gk_ready_1': 'Ready 1: the crouch.', 'gk_ready_2': 'Ready 2: the bob, 1 pixel lower (400 ms each).',
            'gk_got_it': 'Got it: the ball held at the chest (`W` is the ball).',
            'gk_dive_up_1': 'Dive up 1: take off.', 'gk_dive_up_2': 'Dive up 2: full stretch.',
            'gk_dive_down_1': 'Dive down 1: going down.', 'gk_dive_down_2': 'Dive down 2: on the ground, full stretch.'}
for n, note in GK_NOTES.items():
    sblock(SP.FIGS[(n, 'keeper')], note)
P('### 4.3 The referee and the ball')
P('')
P('The referee is the figure in the Referee kit: `ref_stand` = fig_stand, `ref_run_1` = fig_run_1, `ref_run_2` = fig_run_3 (two frames at 140 ms). He never touches the ball.')
P('')
for n in ('ball_roll_1', 'ball_roll_2', 'ball_air', 'ball_shadow'):
    note = {'ball_roll_1': 'Rolling 1 (origin the middle).', 'ball_roll_2': 'Rolling 2: the patch moved round (60 ms each while it moves).',
            'ball_air': 'In the air: brighter, used for a shot or a long pass; its shadow stays on the ground 3 rows lower.',
            'ball_shadow': 'The shadow, drawn 1 right and 3 down of the ball\'s origin (more when in the air: 1 down per 2 pixels of height).'}[n]
    sblock(A[n], note)
P('### 4.4 The close up keeper')
P('')
P('Front view, the Keeper row with `E` Outline round the whole shape so he reads on the net. **Ready, hold and jump are 24 x 32** with the origin at the middle of the feet. The two dives **overhang the brief\'s 24 x 32**: the low dive is %d x %d and the high dive %d x %d, because a keeper at full stretch is longer than he is wide; their origin is **the middle of the waist** so the goal mouth table (6.24) can place them. Dive left and high dive left are the mirrors.' % (A['gm_keeper_dive_right'].width, A['gm_keeper_dive_right'].height, A['gm_keeper_high_right'].width, A['gm_keeper_high_right'].height))
P('')
GM_NOTES = {'gm_keeper_ready': 'Ready: crouched, arms out (bobs 1 pixel every 400 ms).',
            'gm_keeper_hold': 'Hold: the ball caught at the chest (a save in the middle column, middle or low).',
            'gm_keeper_jump': 'Jump: straight up, arms high (a save high in the middle; and the pose for over the bar).',
            'gm_keeper_dive_right': 'Dive right: low, almost flat.',
            'gm_keeper_high_right': 'High dive right: on a slant, lifted.'}
for n, note in GM_NOTES.items():
    sblock(A[n], note)
P('### 4.5 The close up ball and the ripple')
P('')
P('The ball flies **away** from the viewer, from (48, 70) below the picture to its target, so it shrinks: near, mid, far (section 7.4). The ripple is drawn centred on the ball before the ball, over the net only (skip pixels outside x 13 to 82, y 18 to 46).')
P('')
for n in ('gm_ball_near', 'gm_ball_mid', 'gm_ball_far', 'gm_ripple_1', 'gm_ripple_2', 'gm_ripple_3'):
    sblock(A[n], {'gm_ball_near': 'Near (9 x 9), the first frame of the shot.', 'gm_ball_mid': 'Mid (7 x 7).', 'gm_ball_far': 'Far (5 x 5), on the target.',
                  'gm_ripple_1': 'Ripple 1: the first ring.', 'gm_ripple_2': 'Ripple 2: the ring spreads, an inner ring of Net.', 'gm_ripple_3': 'Ripple 3: fading (Net only).'}[n])
P('### 4.6 Club badges (16 x 16) and mini badges (8 x 8)')
P('')
P('Eight badges, assigned to the 64 clubs as `badge = club number mod 8`. The mini badge for the status bar and the tables is the badge sampled at every odd pixel (x and y 1, 3, 5, ... 15), given below so no code has to do it.')
P('')
for b in I.BADGES:
    sblock(A[b[0]])
for b in I.BADGES:
    sblock(A[b[0].replace('badge_', 'mini_')])
P('### 4.7 Faces (24 x 24)')
P('')
P('Eight faces, reused as `face = player number mod 8` (the manager uses face_8 on the set up screen). The shirt at the bottom is the Home row; the game may swap it for any kit row. `P` is the collar.')
P('')
for f in I.FACES:
    sblock(A[f[0]])
P('### 4.8 Icons (8 x 8)')
P('')
P('Every icon is a shape first and a colour second. Most have a 1 pixel `E` Icon Edge so they read on any ground. Placed by the top left.')
P('')
for n in I.ICONS:
    sblock(A[n])
P('### 4.9 Trophies')
P('')
for n in ('trophy_league', 'trophy_cup', 'cab_league', 'cab_cup'):
    sblock(A[n])
# ---------------------------------------------------------------------------------------------------------------- fonts
P('## 5. Text')
P('')
P('### 5.1 The 5 x 7 font and six new glyphs')
P('')
P('The house font as it is (capitals, digits, `- < > = ? . : ! +` and space; 6 pixels a character at 1x). Six glyphs are added for this game: `/ , \' ( ) %`.')
P('')
for ch, rows in EXTRA.items():
    P('#### glyph `%s` (5 x 7)' % ch)
    P('')
    P('```')
    for r in rows:
        P(r)
    P('```')
    P('')
P('### 5.2 Money')
P('')
P('An amount is a sign then up to 7 digits, with **2 extra pixels (at 1x; 4 at 2x) before each group of 3 digits** counted from the right, so 1 234 567 reads without commas. The sign is always drawn for cash, gate, costs and prizes (`+` in Chalk Green, `-` in Chalk Red); a loan, a value, a bid and an offer have no sign and keep the plain colour. Widths at 1x: `+1 234 567` is 56 pixels, `-18 450` is 39.')
P('')
P('### 5.3 The 3 x 5 font')
P('')
P('For the column heads of the squad, the chart\'s scale, the energy numbers, the pick screen\'s labels and numbers. 4 pixels a character. `#` is a lit pixel.')
P('')
P('```')
keys = list(SMALL.keys())
for i in range(0, len(keys), 12):
    chunk = keys[i:i + 12]
    P('  '.join(' %s ' % (k if k != ' ' else '_') for k in chunk))
    rows = [[SMALL[k].split(',')[j] for k in chunk] for j in range(5)]
    for r in rows:
        P('  '.join(x.replace('.', '.') for x in r))
    P('')
P('```')
P('')
# ---------------------------------------------------------------------------------------------------------------- screens
P('## 6. Screens')
P('')
P('Each screen is a list of "this, in this colour, at this x and y" (the top left of the text or sprite unless it says centred or right edge). A row of a table gives the first row and the step. Font `5 x 7, 2x` is the house font at 2x; `3 x 5` the small font.')
P('')
P('### 6.1 The status bar (every menu screen)')
P('')
table(['What', 'Font', 'Colour', 'x', 'y'], [[w, f, c, x, y] for w, f, c, x, y in S.STATUS_ITEMS])
P('The bar is Tunnel over rows 0 to 12 with a Tunnel Rule on row 13. On the set up screens the bar is plain Tunnel (there is no club yet).')
P('')
P('### 6.2 The board and the key bar')
P('')
P('The board is section 3.5. The key bar is Tunnel over rows 228 to 239 with a Tunnel Rule on row 228; from x 6 on y 231, each key in Chalk Yellow, 4 pixels, its meaning in Chalk Dim, 10 pixels to the next key.')
P('')
P('### 6.3 Bars and pips')
P('')
table(['Bar', 'Recipe'], [
    ['Energy (1 to 20)', '20 units, 2 pixels a unit (40 x 5 in the squad, 40 x 4 on the pick screen) over Bar Empty. Level: **fresh** 13 to 20, Chalk Green, solid, the bottom row Fresh Dark; **weary** 7 to 12, Chalk Amber with every 4th column Weary Dark (dashes); **spent** 1 to 6, Chalk Red and Spent Dark in a check. The last lit column is Chalk (the marker). Ticks of Bar Tick under units 6 and 12 (the threshold marks). Spent pulses: the whole fill turns Spent Dark for 200 ms every 600 ms'],
    ['Morale (1 to 20)', '10 pips of 3 x 5, every 4 pixels; a pip is 2 points, an odd point lights its first 2 columns; the same three levels and colours as energy; the top left pixel of a full pip is Chalk. Used on the week menu and the end of season where a bar would be too wide'],
    ['Skill (1 to 5)', '5 squares (3 x 3 every 4 pixels; 5 x 5 every 6 on the transfer card), Chalk Yellow lit, Bar Empty unlit'],
    ['Your number against theirs', 'two bars of 20 units at 5 pixels a unit, 4 rows each with 1 row between: yours Chalk Yellow, theirs Chalk Blue, over Bar Empty; after them the two numbers in the 3 x 5 font, and after yours a **+** (Chalk Green) when you are level or ahead, a **-** (Chalk Red) when behind'],
    ['Loan meter', '124 x 6, filled loan / limit: Chalk Green solid under 40%, Chalk Amber dashed to 80%, Chalk Red checked above; a Chalk Red tick 10 rows tall at 80% and 12 rows tall at the limit'],
])
P('### 6.4 Plates')
P('')
P('A plate (for PAUSED, full time, results of a bid, promoted): a 1 pixel Outline ring, Tunnel inside, a 1 pixel rule 2 pixels in from the top and from the bottom (inset 2 at the sides). The rule colour says what kind of news it is: Chalk Yellow (neutral), Chalk Green (good), Chalk Red (bad).')
P('')
for key, title, f, note in SC.SCREENS:
    kw = {}
    rec = SC.render(key, **kw)
    P('### 6.%d %s' % (5 + SC.SCREENS.index((key, title, f, note)), title))
    P('')
    if note:
        P(note)
        P('')
    table(['What', 'Font or kind', 'Colour', 'x', 'y'], [[w, fo, c, x, y] for (w, fo, c, x, y) in rec.rows])
    if key == 'table':
        P('**Column positions** (5 x 7 at 1x, numbers right aligned on these right edges): zone marker x 6; POS right edge 22; mini badge x 26; CLUB x 38 (12 characters, to x 108); P 140; W 160; D 180; L 200; F 226; A 250; GD 276 (sign always drawn); PTS 306. Rows from y 48, every 11 (the 16th at y 213).')
        P('')
    if key == 'match':
        P('**The kick off shape** (home attacks right; the away side is at `(31 - column, 19 - row)`, mirrored):')
        P('')
        table(['Who', 'Cells (column, row)'], [[k, ', '.join('(%d, %d)' % p for p in v)] for k, v in SC.KICKOFF.items()])
        P('The figures then move as the game says; the art only needs their cells. A figure with the ball, or running to it, uses the run frames (100 ms each); the others stand. The figure that shoots plays kick 1, kick 2.')
        P('')
    if key == 'offer':
        P('After the bid, a plate replaces the bid box (see `footballmanager-screens.png`): rules Chalk Green with ACCEPTED and "HE JOINS AS YOUR RESERVE", or Chalk Red with REFUSED, "THE PRICE GOES UP TO" and the new value in Chalk Yellow.')
        P('')
P('### 6.%d The goal mouth: who goes where' % (5 + len(SC.SCREENS)))
P('')
P('The game has decided the outcome; the close up shows it. For a **save** at target (column, row) the keeper is drawn with this sprite, mirrored or not, with its origin on this point (inside the 96 x 64 picture). The ball (`gm_ball_far`, or the held ball of `gm_keeper_hold`) is on the target.')
P('')
rows = []
for r in range(3):
    for c in range(3):
        name, flip, ox, oy = G.save_pose(c, r)
        rows.append(['%s %s' % (G.ROWS[r], G.COLS[c]), '(%d, %d)' % (S.GM_TX[c], S.GM_TY[r]), name, 'yes' if flip else 'no', '(%d, %d)' % (ox, oy)])
table(['Target', 'Ball at', 'Keeper sprite', 'Mirrored', 'Keeper origin at'], rows)
P('- **Goal**: the keeper goes the wrong way. A shot to the left column gets the right column\'s save pose, a shot to the middle or the right column gets the left column\'s save pose (each from the table, same row, but the middle row\'s pose for a high shot). The ball goes in at its target as gm_ball_far, the ripple plays round it, the crowd strip cheers.')
P('- **Wide** (left or right): the ball at the wide point, the keeper in the middle row dive toward it, 6 pixels short. **Over**: the ball at (48, 9), the keeper in the jump pose at feet (48, 54). **Off the post**: the ball at the post point and five spark pixels round it (Spark at (-3, -3), (0, -4) and (3, -3); Spark Warm at (3, -3) on frame 2; Spark Gold at (-4, 1) and (4, 1)), then the result is a save or wide as the game says.')
P('- **Blocked**: there is no close up. The block happens on the pitch, where a defender stops the ball; the ticker shows `ev_block` and BLOCKED (see 11.2).')
P('')
# ---------------------------------------------------------------------------------------------------------------- animation
P('## 7. Animation recipes and timings')
P('')
P('### 7.1 The title')
P('')
P('Stars at (14, 6), (40, 30), (66, 12), (250, 8), (284, 34), (300, 14), (120, 4), (200, 2), (160, 58), (30, 60), (230, 50), (98, 44), (276, 60), (180, 40). The intro loops every 6000 ms:')
P('')
table(['ms', 'What changes', 'Pixels'], [
    ['0 to 1200', 'the keeper bobs (ready, 1 pixel down and back, 400 ms)', 'about 200 a step'],
    ['1200', 'the ball appears as gm_ball_near at (136, 186)', '70'],
    ['1300, 1400', 'gm_ball_mid, then gm_ball_far, toward the top left target, (136, 118) on this screen (the goal mouth picture\'s row 0 is at y 96, x 112)', '120'],
    ['1400', 'the keeper dives the wrong way (gm_keeper_dive_right)', 'about 900'],
    ['1500 to 1740', 'ripple 1, 2, 3, 80 ms each', 'under 100'],
    ['1500 to 2700', 'the crowd tiles swap every 150 ms', '3 rows of 320 x 8'],
    ['2700 to 6000', 'the keeper back to ready; PRESS SPACE blinks (on 500 ms, off 300 ms) the whole time', ''],
])
P('### 7.2 The match, one attack')
P('')
table(['Step', 'Timing', 'What changes'], [
    ['Dribble', '160 ms a step (2 columns), the ball tweens 1 pixel every 10 ms', 'the ball rolls (ball_roll_1, 2 every 60 ms), the carrier runs beside it, the nearest 3 players of each side run 1 pixel every 20 ms toward it; the trail (8.3)'],
    ['A defender wins it', '300 ms', 'the defender plays kick 1 and 2 (80 ms, 120 ms), the ball goes back; ticker BLOCKED (`ev_block`)'],
    ['The shot', '80 + 120 ms', 'the shooter plays kick 1, kick 2; the ball changes to ball_air'],
    ['The close up opens', '0 ms (one draw of the frame and the picture)', 'the frame (102 x 70) and the goal mouth over the pitch at (112, 82)'],
    ['Ready', '300 ms', 'the keeper in ready'],
    ['The flight', '3 x 80 ms', 'gm_ball_near, gm_ball_mid, gm_ball_far (7.4); the keeper changes to his pose on the last frame'],
    ['The result', '900 ms', 'saved: hold; goal: the ripple (3 x 80 ms), the shake (8.2), the crowd cheer (8.4); wide or over: hold'],
    ['Close', '0 ms', 'the pitch under the close up is redrawn (the cells it covered)'],
    ['After a goal', '1200 ms', 'the scorer\'s side plays the celebrate frames (150 ms each) where they stand; the ticker flashes GOAL (8.6)'],
])
P('An attack takes about 2.5 to 3.5 seconds, so 12 attacks are 30 to 40 seconds. SPACE skips to full time.')
P('')
P('### 7.3 Figures')
P('')
P('Run 1, 2, 3, 4 at 100 ms; the referee\'s two run frames at 140 ms; the keeper\'s ready bob at 400 ms; a keeper\'s dive on the pitch: dive 1 for 100 ms, dive 2 for 500 ms, then ready; got it for 600 ms after a save; celebrate 1, 2 at 150 ms.')
P('')
P('### 7.4 The close up shot')
P('')
P('The ball starts at (48, 70) (below the picture) and is drawn at a third of the way to its target (near), two thirds (mid), then on the target (far), 80 ms each. Pixels: under 100 a frame, plus the keeper\'s pose change (under 900).')
P('')
P('### 7.5 Menus')
P('')
P('The cursor alternates cursor_1 and cursor_2 every 400 ms. The text cursor (a block) is on 500 ms, off 300 ms. A magnet that is placed drops in: drawn 2 pixels high for 40 ms, then 1 pixel high for 40 ms, then in place.')
P('')
# ---------------------------------------------------------------------------------------------------------------- effects
P('## 8. Effects')
P('')
table(['Effect', 'Verdict', 'Recipe'], [
    ['8.1 Net ripple and sparkle on a goal', '**keep**', 'the three ripple frames round the ball (80 ms each), then 6 spark pixels thrown out from the ball over 300 ms (Spark, Spark Warm, Spark Gold, 100 ms each colour)'],
    ['8.2 Goal mouth shake', '**keep**', 'the close up (frame and picture) drawn 1 pixel right, left, right, then home, 50 ms each, from the frame the ball crosses the line; only the close up moves'],
    ['8.3 Ball trail', '**keep**', 'while the ball moves, the 3 pixels behind it along its path, 2, 4 and 6 pixels back: Trail 1, Trail 2, Trail 3; none when still'],
    ['8.4 The crowd jumps', '**keep**', 'both stands swap crowd_1 and crowd_2 every 150 ms for 1200 ms on a goal (yours or theirs); the close up\'s crowd strip too'],
    ['8.5 Money counting up', '**keep**', 'on the money report the cash rolls from last week\'s to this week\'s in 8 steps of 50 ms (the digits drawn at each step\'s value)'],
    ['8.6 Ticker flash', '**keep, for goals**', 'GOAL in the ticker alternates Chalk Yellow and Chalk every 200 ms for 1200 ms (the red card flash is dropped: the rules have no cards)'],
    ['8.7 Low energy pulse', '**keep**', 'spent bars: the fill turns Spent Dark for 200 ms every 600 ms'],
    ['8.8 Coin shower', '**keep**', 'when the cash goes from below 0 to 0 or more: 12 particles of 2 x 2 (Gold 2 over Gold 4) fall from the status bar coin, 1 pixel every 20 ms, for 600 ms, over the board only'],
    ['8.9 Lit star for promotion', '**keep**', 'at the season end the promoted clubs\' rows show mark_star in place of mark_up, swapping with Chalk Amber for one frame every 800 ms'],
    ['8.10 Chalk wipe between screens', '**add**', 'the new board is drawn in columns of 16 pixels from the left, one column every 16 ms (20 steps, 320 ms); each step changes 16 x 210 pixels'],
    ['8.11 Magnet drop', '**add**', 'section 7.5'],
    ['Screen shake of the whole match', '**drop**', 'too much movement over a whole screen; the close up shakes alone'],
])
# ---------------------------------------------------------------------------------------------------------------- later
P('## 9. Later screens')
P('')
P('- **Divisions** (`footballmanager-later.png`, top): the third ring of the board\'s frame (the inlay) and a ring round the club badge on the menu change with your division: division 4 Wood 2 (plain wood), division 3 Silver 3, division 2 Gold 3, division 1 Gold 1 with a mark_star at each end of the title band.')
P('- **A bigger ground**: the stand on the match screen fills with the division: of every 4 crowd tiles, 1 is full in division 4, 2 in division 3, 3 in division 2, all 4 in division 1; an empty tile is Stand with Wall seat marks (2 pixels every 4, on the third row of each 4). The title screen\'s stand has 1 tier in division 4, 2 in divisions 3 and 2, 3 in division 1, with floodlights from division 2 (`footballmanager-later.png`, bottom).')
P('- **A friendly or European match** (later): a plate across the score bar with the words FRIENDLY or the competition, the pitch striped across (horizontal stripes) instead of along, and the hoardings all Hoarding Lit.')
P('- **The manager\'s office** (later): the week menu already carries this name; a picture version would be a desk (Wood row) across the bottom third, a phone (Board Head and Chalk Dim), a wall calendar showing the week number in the 5 x 7 font at 3x, and the trophy cabinet\'s smallest shelf on the wall.')
P('')
# ---------------------------------------------------------------------------------------------------------------- checks
P('## 10. Checks')
P('')
bad = check.validate()
P('- **Sprite check**: %s (every pixel of every sprite is `.` or in its legend, every legend name is in the palette, every legend has 16 colours or fewer, every sprite fits its size except the two close up dives, which say so in 4.4).' % ('passed' if not bad else ', '.join(bad)))
P('- **Text contrast** (WCAG ratio, 4.5 is the usual floor for small text):')
P('')
table(['Text', 'On', 'Ratio'], [[a, b, '%.1f' % c] for a, b, c in check.text_contrast()])
P('- **Things that must not be confused**, as a colour distance (redmean, 0 to about 765) for normal vision, deuteranopia, protanopia and tritanopia. The low ones are why a second cue is there:')
P('')
table(['A', 'B', 'Why', 'Normal', 'Deuter.', 'Protan.', 'Tritan.'], [[a, b, why] + ['%.0f' % v for v in vals] for a, b, why, *vals in check.separation()])
P('- **Kits** differ by stripes (home), a hoop (away), plain with white hands (keepers) and a collar (referee), and by the shorts (cream, navy, black, charcoal), so the kits are told apart in grey scale (`footballmanager-colour-check.png`).')
P('- **Energy and morale** differ by fill (solid, dashed, checked), length and the ticks at 6 and 12; **money** by the sign and the coin or cracked coin; **zones** by up and down arrows; **your bars** by the + or -.')
P('- **The ball** is white with a dark edge (Ball 5) and a shadow on the grass; on the close up the back net is dark (Night Haze and Net Dark), so the white ball is the brightest thing in the goal.')
P('- **Your club** stands out in every table: the Your Row band, two Chalk Yellow rules and yellow text (a shape and a value cue, not only a hue).')
P('')
# ---------------------------------------------------------------------------------------------------------------- open
P('## 11. What I decided, and what is open')
P('')
P('### 11.1 Decided')
P('')
P('- The look (Chalk and Floodlights), the name proposal (Gaffer), the canvas (320 x 240 as briefed), the pitch (32 x 20 cells of 8 as briefed, from above), the goal mouth view (face on, our own), the kits (home stripes, away hoop, both fixed by side), the cell to pixel mapping and every position in section 6.')
P('- The art needs **no rule change**.')
P('')
P('### 11.2 Open calls for James')
P('')
P('1. **The name and the names.** Is **Gaffer** right? And all club and player names must be invented (not the 1982 lists, which are that game\'s content and include real clubs); I can write a list of 64 clubs and 24 players in the same spirit as the previews\' if you want it.')
P('2. **Where the goals are.** The rules file says a goal passes through "columns 7 to 14 or 17 to 24, rows 5 to 13", which reads as if the original\'s pitch lay the other way (goals at the top and bottom). The art puts the goals at the left and right ends on cell rows 8 to 11, as the brief\'s "goals at the ends" says. Which should the port follow? If the rule\'s numbers stay, the pitch would need to be turned (20 x 32) and the stands moved to the sides.')
P('3. **Blocked shots** get no close up (the block is on the pitch, with the ticker). Or would you like a close up with the ball bouncing back off a defender\'s legs at the edge of the picture?')
P('4. **No halves, no scorers.** The rules have no half time and no named scorers, so there is a full time panel only, and it marks the goals by attack number. OK, or should the port add a half time break after the fifth round?')
P('5. **The cup\'s name**: the rules call it the FA Cup; the screens say THE CUP, since the real competition\'s name is not ours to use. OK?')
P('6. **Unused icons**: the suspended card, the yellow and red cards and the substitution icon are drawn (the brief lists them) but the rules have no cards or substitutes. Keep them for later, or drop them?')
P('7. **The loan in the status bar** goes Chalk Red above 80% of the limit (a warning before the sack). The original gave no warning; this is presentation only. Keep?')
P('8. **Class names** for the generated code (suggested `FootballLook`, `FootballArt`, `FootballTint` as the other games do), and the ABL art generator, are not written: this is art only.')
P('')
# ---------------------------------------------------------------------------------------------------------------- generator
P('## 12. The generator')
P('')
P('Everything in this file and every preview is made by the Python scripts in `docs/design/footballmanager-generator` (Python 3 and Pillow). From that folder, `python run_all.py` writes the file and the pictures into `docs/design`. Change the design there, not here.')
P('')

text = '\n'.join(out)
assert chr(0x2014) not in text and chr(0x2013) not in text, 'dash'
open(sys.argv[1], 'w').write(text)
