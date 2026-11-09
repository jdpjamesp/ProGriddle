"""Every screen, as a list of things drawn at x, y. The same calls draw the previews and write the tables in the doc."""
from lib import Canvas, put, text_width, small_width, amount_width, mirror, Sprite
from palette import C
import sprites as SP
import scene as S
import data as D

SCREENS = []   # (key, title, function, note)


class Rec:
    """Draws on a canvas and keeps a row for the design file for every call that has a 'what'."""

    def __init__(self, fill='Night'):
        self.cv = Canvas(320, 240, C(fill))
        self.rows = []
        self.notes = []

    def log(self, what, font, colour, x, y):
        if what:
            self.rows.append((what, font, colour, x, y))

    def note(self, s):
        self.notes.append(s)

    def text(self, s, x, y, col, k=1, what='', outline=None, bottom=None, center=None, right=None):
        w = text_width(s, k)
        if center is not None:
            x = center - w // 2
        if right is not None:
            x = right - w + 1
        self.cv.text(s, x, y, C(col), k, C(outline) if outline else None, C(bottom) if bottom else None)
        font = '5 x 7, %dx' % k + (', outline' if outline else '') + (', gradient to ' + bottom if bottom else '')
        where = '' if center is None else ' (centred on x %d)' % center
        where += '' if right is None else ' (right edge x %d)' % right
        self.log(what + (where if what else ''), font, col, x, y)
        return x

    def small(self, s, x, y, col, what='', right=None):
        if right is not None:
            x = right - small_width(s) + 1
        self.cv.small(s, x, y, C(col))
        self.log(what + ('' if right is None else ' (right edge x %d)' % right) if what else '', '3 x 5', col, x, y)

    def amount(self, v, x, y, col, k=1, what='', right=None, sign=True):
        x = self.cv.amount(v, x, y, C(col), k, right, sign)
        self.log(what + ('' if right is None else ' (right edge x %d)' % right) if what else '',
                 '5 x 7, %dx, money%s' % (k, '' if sign else ', no sign'), col, x, y)
        return x

    def sprite(self, name, x, y, what='', flip=False, legend=None):
        s = SP.ALL[name]
        put(self.cv, s, x, y, rows=mirror(s.rows) if flip else None, legend=legend)
        self.log(what or '', 'sprite ' + name + (' (mirrored)' if flip else ''), '', x, y)

    def sprite_c(self, name, cx, cy, what='', flip=False, legend=None):
        s = SP.ALL[name]
        ox, oy = s.origin
        if flip:
            ox = s.width - 1 - ox
        put(self.cv, s, cx - ox, cy - oy, rows=mirror(s.rows) if flip else None, legend=legend)
        self.log(what + ' (origin on this point)' if what else '', 'sprite ' + name + (' (mirrored)' if flip else ''), '', cx, cy)

    def rect(self, x, y, w, h, col, what=''):
        self.cv.rect(x, y, w, h, C(col))
        self.log(what + ' (%d x %d)' % (w, h) if what else '', 'fill', col, x, y)


def screen(key, title, note=''):
    def deco(f):
        SCREENS.append((key, title, f, note))
        return f
    return deco


def menu_frame(r, title, right=None, keys=(), status=True):
    if status:
        S.status_bar(r.cv, D.STATUS)
        r.log('the status bar (section 6.1)', 'status bar', '', 0, 0)
    S.board(r.cv, title, right)
    r.log('the board with the title "%s" (section 6.2)' % title, 'board', 'Chalk Yellow', 10, 21)
    if right:
        r.log('the right hand of the title band: "%s"' % right, '5 x 7, 1x', 'Chalk Dim', 310 - text_width(right), 21)
    S.key_bar(r.cv, keys)
    if keys:
        r.log('the key bar: ' + '  '.join('%s %s' % kv for kv in keys), 'key bar', 'Chalk Yellow and Chalk Dim', 6, 231)


POS_ICON = {'gk': 'pos_gk', 'df': 'pos_df', 'mf': 'pos_mf', 'fw': 'pos_fw'}
POS_NAME = {'gk': 'GOALKEEPER', 'df': 'DEFENDER', 'mf': 'MIDFIELDER', 'fw': 'FORWARD'}
STATE_ICON = {'injured': 'state_injured', 'tired': 'state_tired', 'form': 'state_form'}


# ======================================================================================================================
@screen('title', 'Title and attract', 'Drawn on the Night ground with no status bar. The goal mouth picture of section 3.4 is reused, framed by the stand.')
def title(r, frame=0):
    cv = r.cv
    for (x, y) in [(14, 6), (40, 30), (66, 12), (250, 8), (284, 34), (300, 14), (120, 4), (200, 2), (160, 58), (30, 60),
                   (230, 50), (98, 44), (276, 60), (180, 40)]:
        cv.put(x, y, C('Star'))
    r.log('stars: 14 single pixels (list in section 7.1)', 'pixel', 'Star', 14, 6)
    # floodlight pylons
    for px in (20, 290):
        r.rect(px + 2, 20, 2, 46, 'Roof', 'floodlight pylon' if px == 20 else 'floodlight pylon')
        S.floodlight(cv, px, 14)
        S.floodlight(cv, px, 8) if False else None
    r.log('floodlight lamp heads (6 x 3, with the glow rings of section 3.3)', 'floodlight', 'Floodlight', 20, 14)
    r.log('floodlight lamp head', 'floodlight', 'Floodlight', 290, 14)
    # the stand
    r.rect(0, 66, 320, 2, 'Roof', 'the roof')
    r.rect(0, 68, 320, 1, 'Roof Edge', 'the roof edge')
    r.rect(0, 69, 320, 35, 'Stand', 'the stand')
    for row in range(3):
        for x in range(-32, 320, 32):
            put(cv, SP.ALL['crowd_%d' % (frame + 1)], x + (row * 11) % 32, 71 + row * 9)
    r.log('3 rows of crowd tiles from x -32 every 32, row n shifted 11 n pixels right (mod 32)', 'sprite crowd_1 (crowd_2 on a goal)', '', -16, 71)
    r.rect(0, 98, 320, 2, 'Wall', 'the front wall')
    S.hoard(cv, 100)
    r.log('the hoardings (section 3.3)', 'hoardings', '', 0, 100)
    # the pitch in front: bands that grow toward the viewer
    y = 104
    k = 0
    for h in (6, 7, 8, 10, 12, 14, 17, 20, 24, 30):
        if y > 239:
            break
        r.cv.rect(0, y, 320, min(h, 240 - y), C('Grass A' if k % 2 == 0 else 'Grass B'))
        y += h
        k += 1
    r.log('the pitch: bands of Grass A and Grass B, 6, 7, 8, 10, 12, 14, 17, 20, 24 and 30 rows tall', 'fill', 'Grass A / Grass B', 0, 104)
    # the goal: the goal mouth picture without its crowd and hoarding rows (rows 14 to 63 of it)
    rows = S.goal_mouth_rows()
    for j in range(14, 64):
        for i in range(96):
            ch = rows[j][i]
            if ch in 'abL' and j >= 47:
                continue
            if ch == 's':
                continue
            cv.put(112 + i, 104 + j - 14 + 6, C(S.GM_LEGEND[ch]))
    r.log('the goal: goal mouth rows 14 to 46 only (the frame and the net), skipping its Stand pixels, with the picture\'s row 0 at y 96', 'goal mouth', '', 112, 96)
    for x in range(0, 320):
        cv.put(x, 145, C('Line'))
    r.log('the goal line, the full width', 'fill', 'Line', 0, 145)
    r.sprite_c('gm_keeper_ready', 160, 152, 'the keeper (bobbing 1 pixel every 400 ms)')
    # the name: drawn from the game's name text by the rule of section 6.5; the preview shows the box it fills
    for x in range(40, 280):
        if x % 4 < 2:
            cv.put(x, 8, C('Chalk Dim'))
            cv.put(x, 49, C('Chalk Dim'))
    for y in range(8, 50):
        if y % 4 < 2:
            cv.put(40, y, C('Chalk Dim'))
            cv.put(279, y, C('Chalk Dim'))
    r.log('the box the name fills (x 40 to 279, y 8 to 49): see the name rule under this table', 'dashed box (preview only)', 'Chalk Dim', 40, 8)
    r.text(D.TITLE, 0, 25, 'Chalk Dim', 1, '', center=160)
    r.text('A FOOTBALL MANAGEMENT GAME', 0, 54, 'Chalk', 1, 'the line under the name', center=160)
    r.sprite_c('gm_ball_near', 136, 186, 'the ball flying at the goal (intro, section 7.1)')
    S.plate(cv, 96, 204, 128, 19, 'Chalk Yellow')
    r.log('a banner plate 128 x 19 (section 6.4)', 'plate', 'Tunnel', 96, 204)
    r.text('PRESS SPACE', 0, 210, 'Chalk Yellow', 1, 'PRESS SPACE, on 500 ms, off 300 ms', center=160)
    r.rect(0, 228, 320, 12, 'Tunnel', 'the key bar')
    r.text('ARROWS MOVE  ENTER CHOOSE  P PAUSE  ESC QUIT', 0, 231, 'Chalk Dim', 1, 'the hint line', center=160)


@screen('setup1', 'New game 1: the manager and the level')
def setup1(r):
    menu_frame(r, 'NEW GAME', 'STEP 1 OF 3', keys=(('ENTER', 'NEXT'), ('UP DOWN', 'LEVEL'), ('ESC', 'BACK')), status=False)
    r.rect(0, 0, 320, 14, 'Tunnel', 'no status bar yet: the strip is plain Tunnel')
    r.text('YOUR NAME', 16, 40, 'Chalk Dim', 1, 'label')
    r.rect(14, 50, 126, 13, 'Board Head', 'the name box')
    r.rect(14, 62, 126, 1, 'Chalk Dim', 'the name box rule')
    r.text('ALF MCGUFFIN', 17, 53, 'Chalk', 1, 'the name typed so far (up to 20 characters)')
    r.rect(17 + text_width('ALF MCGUFFIN') + 2, 53, 5, 7, 'Chalk Yellow', 'the text cursor, a block, on 500 ms off 300 ms')
    r.text('LEVEL', 16, 76, 'Chalk Dim', 1, 'label')
    levels = ['BEGINNER', 'NOVICE', 'AVERAGE', 'GOOD', 'EXPERT', 'SUPER EXPERT', 'GENIUS']
    for i, n in enumerate(levels):
        y = 88 + i * 13
        if i == 2:
            S.row_band(r.cv, y - 3, 13, 'Cursor Row')
            r.log('the band under the cursor\'s level, 13 rows from y - 3', 'fill', 'Cursor Row', 4, y - 3)
            r.sprite('cursor_1', 8, y, 'the cursor')
        r.text('%d' % (i + 1), 20, y, 'Chalk Yellow' if i == 2 else 'Chalk Dim', 1, 'level number, row i at y = 88 + 13 i' if i == 0 else '')
        r.text(n, 32, y, 'Chalk Yellow' if i == 2 else 'Chalk', 1, 'level name' if i == 0 else '')
        for p in range(7):
            r.cv.rect(120 + p * 5, y + 2, 3, 3, C('Chalk Amber' if p <= i else 'Bar Empty'))
        if i == 0:
            r.log('difficulty pips: 7 squares 3 x 3 every 5 pixels, the first (level) lit', 'fill', 'Chalk Amber / Bar Empty', 120, y + 2)
    # the manager's face, framed: decoration only
    r.rect(222, 46, 30, 30, 'Wood 3', 'a wood frame round the face')
    r.sprite('face_8', 225, 49, 'the manager (decoration only)')
    r.text('THE GAFFER', 0, 82, 'Chalk Dim', 1, 'caption', center=237)


@screen('setup2', 'New game 2: pick a club', 'Four pages, one a division, 16 clubs a page in two columns of 8, with their 16 x 16 badges.')
def setup2(r):
    menu_frame(r, 'PICK A CLUB', 'DIVISION 4, PAGE 4 OF 4', keys=(('ARROWS', 'MOVE'), ('ENTER', 'PICK'), ('PAGE', 'DIVISION')), status=False)
    r.rect(0, 0, 320, 14, 'Tunnel', 'no status bar yet: the strip is plain Tunnel')
    for i, n in enumerate(D.CLUBS):
        col, row = i // 8, i % 8
        x, y = 14 + col * 152, 38 + row * 23
        badge = D.badge_of(n, 'badge')
        if i == 2:
            r.rect(x - 4, y - 2, 148, 20, 'Cursor Row', 'the cursor band')
            r.sprite('cursor_1', x - 2 + 0, y + 5) if False else None
        r.sprite(badge, x, y, 'badge, club i at x = 14 + 152 (i div 8), y = 38 + 23 (i mod 8)' if i == 0 else '')
        r.text(n, x + 22, y + 5, 'Chalk Yellow' if i == 2 else 'Chalk', 1, 'club name at badge x + 22, y + 5' if i == 0 else '')


@screen('kit', 'New game 3: your colours', 'Replaces the pick 12 screen (the squad is dealt at random). Your side wears the colour picked, the other side the other one.')
def kit(r):
    menu_frame(r, 'YOUR COLOURS', 'STEP 3 OF 3', keys=(('LEFT RIGHT', 'CHOOSE'), ('ENTER', 'START')), status=False)
    r.rect(0, 0, 320, 14, 'Tunnel', 'no status bar yet: the strip is plain Tunnel')
    r.text('YOUR SIDE PLAYS IN', 0, 42, 'Chalk Dim', 1, 'line', center=160)
    for k, (kit, name, x) in enumerate((('white', 'WHITE', 52), ('black', 'BLACK', 180))):
        chosen = k == 0
        r.rect(x, 60, 88, 104, 'Cursor Row' if chosen else 'Board Stripe', 'card %d (88 x 104), Cursor Row when chosen, else Board Stripe' % (k + 1))
        if chosen:
            for (x0, y0, w, h) in ((x, 60, 88, 1), (x, 163, 88, 1), (x, 60, 1, 104), (x + 87, 60, 1, 104)):
                r.cv.rect(x0, y0, w, h, C('Chalk Yellow'))
            r.log('the chosen card\'s 1 pixel Chalk Yellow ring', 'lines', 'Chalk Yellow', x, 60)
        r.sprite('shirt_' + kit, x + 32, 70, 'the big shirt' if k == 0 else 'the big shirt')
        r.sprite_c('fig_stand', x + 30, 128, 'a figure in the kit', legend=None) if False else None
        put(r.cv, SP.FIGS[('fig_stand', kit)], x + 26, 104)
        put(r.cv, SP.FIGS[('fig_run_1', kit)], x + 54, 104)
        r.log('the kit on two figures (fig_stand and fig_run_1, pattern applied), top left', 'sprites', '', x + 26, 104)
        r.text(name, 0, 124, 'Chalk Yellow' if chosen else 'Chalk', 2, 'the colour, 2x', center=x + 44)
        r.text('HOOP' if kit == 'white' else 'STRIPES', 0, 146, 'Chalk Dim', 1, 'the pattern', center=x + 44)
    r.sprite('cursor_1', 40, 108, 'the cursor beside the chosen card')
    r.text('THE OTHER SIDE WEARS BLACK', 0, 182, 'Chalk', 1, 'line: BLACK or WHITE, the colour not chosen', center=160)


@screen('menu', 'The week menu', 'The first screen of every week: the choices of the original menu, and the next match.')
def menu(r):
    menu_frame(r, 'MANAGER\'S OFFICE', 'WEEK 10', keys=(('1-7', 'CHOOSE'), ('ENTER', 'PLAY THE MATCH')))
    items = [('1', 'SELL A PLAYER', 'money_coin'), ('2', 'TAKE A LOAN', 'money_loan'), ('3', 'REPAY THE LOAN', 'money_bank'),
             ('4', 'THE SQUAD', 'pos_mf'), ('5', 'CHANGE LEVEL', 'state_form'), ('6', 'SAVE THE GAME', 'money_wages'),
             ('7', 'PLAY THE MATCH', 'ev_whistle')]
    for i, (k, t, ic) in enumerate(items):
        y = 42 + i * 18
        if i == 6:
            r.rect(4, y - 5, 150, 17, 'Cursor Row', 'the cursor band (17 rows from y - 5)')
            r.sprite('cursor_1', 8, y, 'the cursor')
        r.text(k, 20, y, 'Chalk Yellow', 1, 'key, item i at y = 42 + 18 i' if i == 0 else '')
        r.sprite(ic, 30, y - 1, 'icon' if i == 0 else '')
        r.text(t, 42, y, 'Chalk Yellow' if i == 6 else 'Chalk', 1, 'item' if i == 0 else '')
    # the next match card
    r.rect(166, 40, 1, 170, 'Board Rule', 'the rule between the halves')
    r.text('NEXT MATCH', 0, 42, 'Chalk Dim', 1, 'label', center=242)
    r.text('LEAGUE', 0, 54, 'Chalk Blue', 1, 'LEAGUE, or F.A. CUP and the round name', center=242)
    r.sprite('badge_tower', 196, 70, 'your badge')
    r.sprite('badge_kettle', 272, 70, 'their badge')
    r.text('V', 0, 75, 'Chalk Dim', 2, 'V', center=242)
    r.text('MUDBURY', 0, 94, 'Chalk Yellow', 1, 'your club', center=242)
    r.text('MIZZLE C.', 0, 104, 'Chalk', 1, 'their club', center=242)
    r.text('HOME', 0, 116, 'Chalk Green', 1, 'HOME or AWAY (Chalk Blue)', center=242)
    r.text('THEY ARE 8TH', 0, 132, 'Chalk Dim', 1, 'their place', center=242)
    r.text('YOU ARE 3RD', 0, 142, 'Chalk Dim', 1, 'your place', center=242)
    r.text('LAST WEEK', 0, 164, 'Chalk Dim', 1, 'label', center=242)
    r.text('WON 2-1', 0, 176, 'Chalk Green', 2, 'the last result, 2x: WON (Chalk Green), DREW (Chalk), LOST (Chalk Red)', center=242)


@screen('squad', 'The squad', 'The STATUS choice. 16 rows; the right hand panel shows the player under the cursor.')
def squad(r):
    menu_frame(r, 'THE SQUAD', '14 OF 16', keys=(('UP DOWN', 'MOVE'), ('ESC', 'BACK')))
    hy = 35
    r.text('NAME', 30, hy, 'Chalk Dim', 1, 'head')
    r.small('SKILL', 108, hy + 1, 'Chalk Dim', 'head')
    r.small('ENERGY', 134, hy + 1, 'Chalk Dim', 'head')
    r.small('VALUE', 250, hy + 1, 'Chalk Dim', 'head', right=250)
    r.rect(4, 44, 254, 1, 'Board Rule', 'rule under the heads')
    for i, p in enumerate(D.SQUAD + [None, None]):
        y = 47 + i * 11
        if i % 2 == 1:
            r.cv.rect(4, y - 2, 254, 11, C('Board Stripe'))
        if i == 1:
            r.log('every second row: a band 11 rows tall from y - 2', 'fill', 'Board Stripe', 4, y - 2)
        if p is None:
            r.text('-', 30, y, 'Chalk Dim', 1, 'an empty place in the squad' if i == 14 else '')
            continue
        name, pos, skill, energy, st, value, mark = p
        if i == 6:
            r.rect(4, y - 2, 254, 11, 'Cursor Row', 'the cursor band')
        if mark:
            r.sprite('magnet_on' if mark == 'start' else 'magnet_res', 4, y - 1, 'picked mark (magnet_on to start, magnet_res the reserve)' if i == 0 else '')
        r.sprite(POS_ICON[pos], 16, y - 1, 'position icon, row i at y = 47 + 11 i' if i == 0 else '')
        col = 'Chalk Dim' if st == 'injured' else ('Chalk Yellow' if i == 6 else 'Chalk')
        r.text(name, 30, y, col, 1, 'name (Chalk Dim if injured)' if i == 0 else '')
        S.skill_pips(r.cv, 108, y + 2, skill)
        if i == 0:
            r.log('skill: 5 pips 3 x 3 every 4 pixels (section 6.3)', 'pips', 'Chalk Yellow / Bar Empty', 108, y + 2)
        S.energy_bar(r.cv, 134, y + 1, energy)
        if i == 0:
            r.log('energy bar 40 x 5 (section 6.3)', 'bar', 'by level', 134, y + 1)
        r.small('%2d' % energy, 186, y + 1, 'Chalk Dim', 'energy number' if i == 0 else '', right=185 + 7) if False else None
        r.cv.small('%2d' % energy, 177, y + 1, C('Chalk Dim'))
        if i == 0:
            r.log('energy number, 2 digits', '3 x 5', 'Chalk Dim', 177, y + 1)
        if st in STATE_ICON:
            r.sprite(STATE_ICON[st], 186, y - 1, 'state icon (injured, tired, in form), nothing when plain fit' if i == 2 else '')
        r.amount(value, 0, y, 'Chalk', 1, 'value, no sign' if i == 0 else '', right=250, sign=False)
    # the right hand panel: the player under the cursor
    p = D.SQUAD[6]
    r.rect(262, 33, 1, 190, 'Board Rule', 'the panel rule')
    r.rect(272, 40, 30, 30, 'Wood 3', 'a wood frame round the face')
    r.sprite('face_4', 275, 43, 'the face (the game picks one of 8 by the player\'s number)')
    r.small(p[0].split('.')[1], 0, 76, 'Chalk Yellow', 'surname') if False else None
    r.cv.small(p[0].split('.')[1], 287 - small_width(p[0].split('.')[1]) // 2, 76, C('Chalk Yellow'))
    r.log('the surname, centred on x 287', '3 x 5', 'Chalk Yellow', 287 - small_width('CRUMPET') // 2, 76)
    r.sprite('pos_mf', 283, 86, 'position')
    r.small('SKILL', 268, 100, 'Chalk Dim', 'label')
    S.skill_pips(r.cv, 268, 107, p[2], big=False)
    r.small('ENERGY', 268, 116, 'Chalk Dim', 'label')
    r.cv.small('%d' % p[3], 296, 116, C('Chalk'))
    r.sprite('state_form', 296, 124, 'state')
    r.small('WAGES', 268, 150, 'Chalk Dim', 'label')
    r.small('WEEK', 268, 156, 'Chalk Dim', '')
    r.cv.small('4200', 282, 166, C('Chalk Red'))
    r.log('the whole wage bill a week (a cost: Chalk Red)', '3 x 5', 'Chalk Red', 282, 166)


@screen('pick', 'Pick the team', 'Left: the squad with the picks. Right: the five numbers, yours over theirs, and the shape of the team on a chalk pitch.')
def pick(r):
    menu_frame(r, 'PICK THE TEAM', 'V MIZZLE C.', keys=(('ENTER', 'PICK'), ('R', 'RESERVE'), ('SPACE', 'KICK OFF')))
    for i, p in enumerate(D.SQUAD):
        y = 38 + i * 13
        name, pos, skill, energy, st, value, mark = p
        if i == 8:
            r.rect(4, y - 3, 160, 13, 'Cursor Row', 'the cursor band')
        if mark:
            r.sprite('magnet_on' if mark == 'start' else 'magnet_res', 6, y - 1, 'pick mark, row i at y = 38 + 13 i' if i == 0 else '')
        elif st != 'injured':
            r.cv.rect(7, y, 6, 6, C('Board Rule'))
        r.sprite(POS_ICON[pos], 18, y - 1)
        col = 'Chalk Dim' if st == 'injured' else ('Chalk' if mark else 'Chalk Dim')
        r.text(name, 30, y, col, 1, 'name' if i == 0 else '')
        S.energy_bar(r.cv, 102, y + 1, energy, unit=2, h=4)
        if i == 0:
            r.log('energy bar 40 x 4', 'bar', 'by level', 102, y + 1)
        if st == 'injured':
            r.sprite('state_injured', 146, y - 1, 'injured: cannot be picked')
        else:
            S.skill_pips(r.cv, 146, y + 1, skill)
    # the comparison
    r.rect(168, 34, 1, 190, 'Board Rule', 'the panel rule')
    r.text('YOU', 176, 36, 'Chalk Yellow', 1, 'key: your bars')
    r.text('THEM', 206, 36, 'Chalk Blue', 1, 'key: their bars')
    stats = [('ENERGY', 13, 11), ('MORALE', 14, 10), ('DEFENCE', 14, 12), ('MIDFIELD', 15, 13), ('ATTACK', 9, 12)]
    for i, (n, a, b) in enumerate(stats):
        y = 50 + i * 21
        r.small(n, 176, y, 'Chalk Dim', 'label, number i at y = 50 + 21 i' if i == 0 else '')
        S.compare_bar(r.cv, 176, y + 7, a, b, unit=5 if False else 5)
        if i == 0:
            r.log('the pair of bars, 5 pixels a point (section 6.3)', 'compare bars', 'Chalk Yellow / Chalk Blue', 176, y + 7)
    # the chalk pitch with the shape
    px, py, pw, ph = 176, 158, 132, 62
    for (x0, y0, w, h) in ((px, py, pw, 1), (px, py + ph - 1, pw, 1), (px, py, 1, ph), (px + pw - 1, py, 1, ph), (px + pw // 2, py, 1, ph)):
        r.cv.rect(x0, y0, w, h, C('Chalk Dim'))
    r.log('the chalk pitch: a 132 x 62 outline and a halfway line', 'lines', 'Chalk Dim', px, py)
    for (x0, y0, w, h) in ((px, py + 18, 14, 1), (px, py + 43, 14, 1), (px + 13, py + 18, 1, 26)):
        r.cv.rect(x0, y0, w, h, C('Chalk Dim'))
    shape = [(6, 31, 'gk')] + [(26, y, 'df') for y in (9, 23, 39, 53)] + [(48, y, 'mf') for y in (9, 23, 39, 53)] + [(62, y, 'fw') for y in (23, 39)]
    for (dx, dy, pos) in shape:
        put(r.cv, SP.ALL['magnet_on'], px + dx - 3, py + dy - 3, legend={'R': 'Keeper 3', 'H': 'Keeper 1', 'S': 'Keeper 4'} if pos == 'gk' else None)
    r.log('the 11 magnets of the shape, 4-4-2, centred on (x + 6, 31), (x + 26, 9 / 23 / 39 / 53), (x + 48, the same), (x + 62, 23 / 39) from the pitch\'s top left; the keeper\'s magnet in the Keeper row', 'sprite magnet_on', '', px, py)
    r.text('4-4-2', 0, py + ph // 2 - 3, 'Chalk Dim', 1, 'the shape, from the picks', center=px + 99)


def score_bar(r, hs, as_, attack, home='MUDBURY', away='MIZZLE C.'):
    cv = r.cv
    r.rect(0, 0, 320, 18, 'Tunnel', 'the score bar')
    r.rect(0, 17, 320, 1, 'Tunnel Rule', 'its rule')
    r.sprite('mini_tower', 4, 5, 'home mini badge')
    r.sprite('kit_white', 14, 5, 'home side\'s kit icon (kit_white or kit_black)')
    r.text(home, 24, 6, 'Chalk Yellow', 1, 'home club (your club in Chalk Yellow, the other in Chalk)')
    r.text(str(hs), 0, 2, 'Chalk Yellow', 2, 'home goals, 2x', right=152)
    r.text('-', 0, 2, 'Chalk Dim', 2, 'the dash, 2x', center=160)
    r.text(str(as_), 168, 2, 'Chalk Yellow', 2, 'away goals, 2x')
    r.text(away, 0, 6, 'Chalk', 1, 'away club', right=295)
    r.sprite('kit_black', 298, 5, 'away side\'s kit icon')
    r.sprite('mini_kettle', 308, 5, 'away mini badge')


@screen('match', 'The match', 'One attack at a time on the pitch of the rules (3.2): seven figures, the ball two columns a step. The view is of the goal being attacked; the left goal\'s view is the mirror. The close up opens over the far corner for the shot.')
def match(r, inset=True, frame=0, side='right'):
    S.match_background(r.cv, frame, side)
    r.log('the match background, right goal view (3.1, 3.2); for the left goal the rows 34 to 193 mirrored', 'background', '', 0, 0)
    score_bar(r, 2, 1, 7)
    for (c, rr, kit, n, flip) in ATTACK_PREVIEW:
        s = SP.FIGS[(n, kit)]
        fx, fy = S.cell_xy(c, rr, side)
        ox, oy = s.origin
        if side == 'left':
            flip = not flip
        if flip:
            ox = s.width - 1 - ox
        put(r.cv, s, fx - ox, fy - oy, rows=mirror(s.rows) if flip else None)
    r.log('the seven figures: feet on cell_xy(c, r) (the attack layout is under this table)', 'sprites', '', 0, 0)
    path = [(14, 12), (16, 12)]
    bc, br = 18, 12
    bx, by = S.ball_xy(bc, br, side)
    d = -1 if side == 'right' else 1
    for k in range(3):
        r.cv.put(bx + d * (2 + 2 * k), by + (k + 1) // 2, C('Trail %d' % (k + 1)))
    put(r.cv, SP.ALL['ball_shadow'], bx - 2 + 1, by - 2 + 3)
    put(r.cv, SP.ALL['ball_roll_1'], bx - 2, by - 2)
    r.log('the ball on cell (18, 12): ball_xy, its shadow 1 right and 3 down, the trail of 8.3', 'sprite ball_roll_1', '', bx, by)
    r.rect(0, 206, 320, 22, 'Tunnel', 'the ticker')
    r.rect(0, 206, 320, 1, 'Tunnel Rule', 'its rule')
    r.sprite('ev_save', 6, 213, 'the event icon')
    r.text('SAVED BY THE KEEPER', 18, 214, 'Chalk', 1, 'the ticker line (up to 40 characters)')
    r.text('ATTACK 7', 0, 214, 'Chalk Dim', 1, 'the running attack count', right=313)
    r.rect(0, 228, 320, 12, 'Tunnel', 'the key bar')
    r.text('SPACE', 6, 231, 'Chalk Yellow', 1, 'keys')
    r.text('SKIP', 40, 231, 'Chalk Dim', 1, '')
    r.text('P', 74, 231, 'Chalk Yellow', 1, '')
    r.text('PAUSE', 84, 231, 'Chalk Dim', 1, '')
    if inset:
        x, y = (9, 87) if side == 'right' else (215, 87)
        r.rect(x - 3, y - 3, 102, 70, 'Outline', 'the close up frame: Outline ring (right goal view; at x 212 for the left goal)')
        r.rect(x - 2, y - 2, 100, 68, 'Chalk Yellow', 'then a Chalk Yellow ring')
        r.rect(x - 1, y - 1, 98, 66, 'Outline', 'then Outline again')
        S.goal_mouth(r.cv, x, y)
        r.log('the goal mouth picture (section 3.4)', 'goal mouth', '', x, y)
        r.sprite_c('gm_keeper_high_right', x + 61, y + 35, 'the keeper, high dive to the right (the goal mouth table, 6.24)')
        r.sprite_c('gm_ball_mid', x + 72, y + 22, 'the ball at the top right target, in the gloves: SAVED')


# the preview's attack, right goal view: (column, row, kit, frame, mirrored). The home side (white) attacks right.
ATTACK_PREVIEW = [
    (19, 11, 'keeper', 'gk_ready_1', True),
    (17, 12, 'white', 'fig_kick_1', False), (13, 8, 'white', 'fig_run_2', False), (14, 17, 'white', 'fig_run_4', False),
    (17, 9, 'black', 'fig_run_1', True), (20, 14, 'black', 'fig_stand', True), (15, 16, 'black', 'fig_run_3', True),
]
ATTACK_ROLES = [('the keeper', 'on c = 8 + r (right goal) or c + r = 23 (left goal), rows 8 to 13, faces the play'),
                ('the dribbler', 'one cell behind the ball, faces the goal'),
                ('two more attackers', 'on the cells the game gives, face the goal'),
                ('three defenders', 'on the cells the game gives, face the ball')]


@screen('fulltime', 'Full time', 'A plate over the last frame of the pitch: the score and the counts of the attacks. No half time and no scorers, as the original.')
def fulltime(r):
    match(r, inset=False)
    r.rows = [row for row in r.rows if row[0].startswith('the match background') or row[0].startswith('the score bar')]
    S.plate(r.cv, 64, 50, 192, 120)
    r.log('a plate 192 x 120 (section 6.4)', 'plate', 'Tunnel', 64, 50)
    r.text('FULL TIME', 0, 57, 'Chalk Yellow', 1, 'title', center=160)
    r.sprite('badge_tower', 92, 72, 'home badge')
    r.sprite('badge_kettle', 212, 72, 'away badge')
    r.text('2', 0, 70, 'Chalk Yellow', 3, 'home goals, 3x', right=150)
    r.text('-', 0, 70, 'Chalk Dim', 3, 'dash', center=160)
    r.text('1', 170, 70, 'Chalk Yellow', 3, 'away goals, 3x')
    r.text('WON', 0, 96, 'Chalk Green', 1, 'WON (Chalk Green), DRAWN (Chalk), LOST (Chalk Red)', center=160)
    rows = [('ATTACKS', 7, 4), ('SHOTS', 5, 3), ('SAVED', 2, 1), ('BLOCKED', 2, 1)]
    for i, (n, a, b) in enumerate(rows):
        y = 112 + i * 11
        r.text(str(a), 0, y, 'Chalk', 1, 'your count, row i at y = 112 + 11 i' if i == 0 else '', right=110)
        r.text(n, 0, y, 'Chalk Dim', 1, 'label' if i == 0 else '', center=160)
        r.text(str(b), 210, y, 'Chalk', 1, 'their count' if i == 0 else '')


@screen('results', 'Results', 'This week\'s result and the other matches of the division (the original\'s random pairings), then the next match.')
def results(r):
    menu_frame(r, 'RESULTS', 'WEEK 10', keys=(('ENTER', 'MONEY'),))
    r.sprite('badge_tower', 30, 38, 'your match: home badge')
    r.text('MUDBURY', 50, 43, 'Chalk Yellow', 1, 'home')
    r.text('2-1', 0, 39, 'Chalk Yellow', 2, 'score 2x', center=160)
    r.text('MIZZLE C.', 0, 43, 'Chalk', 1, 'away', right=270)
    r.sprite('badge_kettle', 274, 38, 'away badge')
    r.rect(14, 60, 292, 1, 'Board Rule', 'rule')
    r.text('THE REST OF DIVISION 3', 0, 66, 'Chalk Dim', 1, 'label', center=160)
    others = [('GRUBSWORTH', 3, 0, 'SNOOZEHAM'), ('WOBBLEFORD', 1, 1, 'PIEMOUTH'), ('TOFFEETON', 2, 2, 'DRIZZLEBY'),
              ('SLOWCOMBE', 0, 1, 'BRAMBLE U.'), ('KETTLEWHIP', 4, 2, 'PUDDLEMOOR'), ('CRUMBLETON', 1, 0, 'BOGWATER'),
              ('NETTLE R.', 0, 0, 'HOPSWICH')]
    for i, (a, x, y_, b) in enumerate(others):
        y = 80 + i * 12
        if i % 2:
            r.cv.rect(14, y - 2, 292, 11, C('Board Stripe'))
        r.text(a, 0, y, 'Chalk', 1, 'home club, row i at y = 80 + 12 i' if i == 0 else '', right=146)
        r.text('%d-%d' % (x, y_), 0, y, 'Chalk Yellow', 1, 'score' if i == 0 else '', center=160)
        r.text(b, 175, y, 'Chalk', 1, 'away club' if i == 0 else '')
    r.rect(14, 170, 292, 1, 'Board Rule', 'rule')
    r.text('NEXT', 20, 180, 'Chalk Dim', 1, 'label')
    r.text('AWAY V GRUBSWORTH', 50, 180, 'Chalk', 1, 'the next match')
    r.sprite('ev_whistle', 20, 196, 'a cup week adds this line')
    r.text('THEN THE F.A. CUP ROUND 4', 32, 197, 'Chalk Blue', 1, 'the cup line')


@screen('money', 'The money report', 'The week\'s money, then a 10 week chart of the cash and the loan against its limit. L and R open the loan and repay boxes.')
def money(r):
    menu_frame(r, 'MONEY REPORT', 'WEEK 10', keys=(('L', 'LOAN'), ('R', 'REPAY'), ('ENTER', 'THE TABLE')))
    lines = [('money_ground', 'GATE', 14250), ('money_wages', 'WAGES', -4200), ('money_ground', 'GROUND RENT', -1000),
             ('money_bank', 'INTEREST', -2123)]
    for i, (ic, n, v) in enumerate(lines):
        y = 40 + i * 13
        r.sprite(ic, 14, y - 1, 'icon, line i at y = 40 + 13 i' if i == 0 else '')
        r.text(n, 26, y, 'Chalk', 1, 'label' if i == 0 else '')
        r.amount(v, 0, y, 'Chalk Green' if v >= 0 else 'Chalk Red', 1, 'amount, sign always drawn' if i == 0 else '', right=150)
    r.rect(26, 92, 125, 1, 'Chalk Dim', 'the sum rule')
    r.text('THIS WEEK', 26, 97, 'Chalk Yellow', 1, 'label')
    r.amount(6927, 0, 97, 'Chalk Green', 1, 'the week\'s total', right=150)
    r.text('CASH', 26, 118, 'Chalk', 1, 'label')
    r.sprite('money_owed', 14, 117, 'money_owed when the cash is below 0, else money_coin')
    r.amount(-18450, 0, 114, 'Chalk Red', 2, 'the cash, 2x', right=150)
    r.text('LOAN', 26, 140, 'Chalk', 1, 'label')
    r.sprite('money_loan', 14, 139, 'icon')
    r.cv.amount(212300, 0, 136, C('Chalk'), 2, right=150, sign=False)
    r.log('the loan, 2x, no sign', '5 x 7, 2x, money', 'Chalk', 150 - amount_width(212300, 2, False) + 1, 136)
    r.text('LIMIT', 26, 160, 'Chalk Dim', 1, 'label')
    r.amount(500000, 0, 160, 'Chalk Dim', 1, 'the limit (250 000 times the division multiplier)', right=150, sign=False)
    # the loan meter: plain, no warning colours (the original gives none)
    r.rect(26, 176, 124, 6, 'Bar Empty', 'the loan meter: 124 x 6, filled loan / limit')
    fill = 124 * 212300 // 500000
    r.cv.rect(26, 176, fill, 6, C('Bar Plain'))
    r.cv.rect(26 + fill - 1, 176, 1, 6, C('Chalk'))
    r.log('fill Bar Plain, the last column Chalk; the same at every level', 'bar', 'Bar Plain', 26, 176)
    r.rect(26 + 123, 173, 1, 12, 'Chalk Dim', 'the limit tick')
    r.small('42%', 26, 186, 'Chalk Dim', 'percent of the limit')
    # the chart
    cx, cy0, cy1 = 176, 44, 150
    r.rect(168, 34, 1, 190, 'Board Rule', 'the panel rule')
    r.text('CASH, 10 WEEKS', 176, 36, 'Chalk Dim', 1, 'label') if False else None
    r.small('CASH 10 WEEKS', 176, 36, 'Chalk Dim', 'chart title')
    zero = 110
    r.rect(cx, zero, 128, 1, 'Chalk Dim', 'the zero line (y 110)')
    hist = [-6000, -14000, -9000, 3000, 12000, 7000, -2000, -11000, -25377, -18450]
    for k, v in enumerate(hist):
        x = cx + 4 + k * 12
        h = min(60, abs(v) // 500)
        if v >= 0:
            r.cv.rect(x, zero - h, 8, h, C('Chalk Green'))
            r.cv.rect(x, zero - h, 8, 1, C('Chalk'))
        else:
            for yy in range(zero + 1, zero + 1 + h):
                for xx in range(x, x + 8):
                    r.cv.put(xx, yy, C('Chalk Red' if (xx + yy) % 2 == 0 else 'Spent Dark'))
            r.cv.rect(x, zero + h, 8, 1, C('Chalk'))
    r.log('10 bars 8 wide every 12 pixels from x 180: 1 pixel a 500, up to 60; credit up from the line, solid Chalk Green; debt down, checked Chalk Red and Spent Dark; a Chalk cap on the end', 'bars', 'Chalk Green / Chalk Red', cx + 4, zero)
    r.small('+30000', cx, 50, 'Chalk Dim', 'scale')
    r.small('-30000', cx, 166, 'Chalk Dim', 'scale')
    for k in range(10):
        r.cv.small('%d' % (k + 1), cx + 6 + k * 12 - (2 if k == 9 else 0), 178, C('Chalk Dim'))
    r.log('week numbers under the bars', '3 x 5', 'Chalk Dim', cx + 6, 178)


@screen('table', 'The league table', 'The house table: 16 rows of 11, zones marked at the left, your club on a band with an arrow.')
def table(r, div=3):
    menu_frame(r, 'DIVISION %d' % div, 'AFTER 9 OF 15', keys=(('ENTER', 'TRANSFER OFFER'),))
    cols = [('POS', 22, 'r'), ('CLUB', 38, 'l'), ('P', 140, 'r'), ('W', 160, 'r'), ('D', 180, 'r'), ('L', 200, 'r'),
            ('F', 226, 'r'), ('A', 250, 'r'), ('GD', 276, 'r'), ('PTS', 306, 'r')]
    for n, x, a in cols:
        if a == 'r':
            r.text(n, 0, 35, 'Chalk Dim', 1, 'head %s (right edge x %d)' % (n, x) if True else '', right=x)
            r.rows[-1] = (r.rows[-1][0].split(' (right')[0] + ' (right edge x %d)' % x,) + r.rows[-1][1:]
        else:
            r.text(n, x, 35, 'Chalk Dim', 1, 'head %s' % n)
    r.rect(4, 44, 312, 1, 'Board Rule', 'rule under the heads')
    rows = sorted(enumerate(D.TABLE), key=lambda t: -(t[1][1] * 3 + t[1][2]))
    for i, (ci, (p, w, d, l, f, a)) in enumerate(rows):
        y = 48 + i * 11
        name = D.CLUBS[ci]
        mini = D.badge_of(name)
        you = name == D.CLUB
        if i % 2 == 1:
            r.cv.rect(4, y - 2, 312, 11, C('Board Stripe'))
        if i == 1:
            r.log('every second row: a band 11 tall from y - 2', 'fill', 'Board Stripe', 4, y - 2)
        if you:
            r.rect(4, y - 2, 312, 11, 'Your Row', 'your club: a Your Row band')
            r.rect(4, y - 2, 312, 1, 'Chalk Yellow', 'and a Chalk Yellow rule over it')
            r.rect(4, y + 8, 312, 1, 'Chalk Yellow', 'and under it')
        col = 'Chalk Yellow' if you else 'Chalk'
        if i < 3 and div > 1:
            r.sprite('mark_up', 6, y + 1, 'promotion places 1 to 3 (not in division 1)' if i == 0 else '')
        if i >= 13 and div < 4:
            r.sprite('mark_down', 6, y + 1, 'relegation places 14 to 16 (not in division 4)' if i == 13 else '')
        first = i == 0
        r.text('%d' % (i + 1), 0, y, col, 1, 'position, row i at y = 48 + 11 i' if first else '', right=22)
        r.sprite(mini, 26, y - 1, 'mini badge' if first else '')
        r.text(name, 38, y, col, 1, 'club' if first else '')
        for v, x in ((p, 140), (w, 160), (d, 180), (l, 200), (f, 226), (a, 250)):
            r.text(str(v), 0, y, col, 1, '', right=x)
        gd = f - a
        r.text(('+' if gd > 0 else ('-' if gd < 0 else ' ')) + str(abs(gd)), 0, y, col if gd >= 0 else ('Chalk Red' if not you else col), 1,
               'goal difference: + or - always drawn' if first else '', right=276)
        r.text(str(w * 3 + d), 0, y, 'Chalk Yellow' if you else 'Chalk', 1, 'points' if first else '', right=306)
        if you:
            r.sprite('cursor_1', 310, y, 'the arrow at the end of your row', flip=True) if False else None
            put(r.cv, SP.ALL['cursor_1'], -10, y)  # off screen: kept in the rest of the rows
    # zone rules
    for k in range(4, 316, 4):
        r.cv.rect(k, 48 + 3 * 11 - 3, 2, 1, C('Chalk Green'))
        if div < 4:
            r.cv.rect(k, 48 + 13 * 11 - 3, 2, 1, C('Chalk Red'))
    r.log('a dashed rule (2 on, 2 off) under place 3, Chalk Green', 'dashes', 'Chalk Green', 4, 48 + 3 * 11 - 3)
    r.log('a dashed rule over place 14, Chalk Red (not in division 4)', 'dashes', 'Chalk Red', 4, 48 + 13 * 11 - 3)


@screen('offer', 'The transfer offer', 'One player a week. Type a bid; the result plate replaces the bid box.')
def offer(r, result=None):
    menu_frame(r, 'TRANSFER OFFER', 'SQUAD 14 OF 16', keys=(('DIGITS', 'BID'), ('ENTER', 'OFFER'), ('ESC', 'NO THANKS')))
    r.rect(20, 40, 280, 92, 'Board Stripe', 'the player card')
    r.rect(20, 40, 280, 1, 'Board Rule', 'its top rule')
    r.rect(30, 50, 54, 54, 'Wood 3', 'the face frame') if False else None
    r.rect(32, 50, 30, 30, 'Wood 3', 'the face frame')
    r.sprite('face_2', 35, 53, 'the face')
    r.text('U.PARSNIP', 74, 50, 'Chalk Yellow', 2, 'name, 2x')
    r.sprite('pos_fw', 74, 70, 'position')
    r.text('FORWARD', 86, 71, 'Chalk', 1, 'position name')
    r.text('SKILL', 74, 86, 'Chalk Dim', 1, 'label')
    S.skill_pips(r.cv, 110, 86, 4, big=True)
    r.log('skill: 5 pips 5 x 5 every 6 pixels', 'pips', 'Chalk Yellow / Bar Empty', 110, 86)
    r.text('ENERGY', 74, 100, 'Chalk Dim', 1, 'label')
    S.energy_bar(r.cv, 116, 100, 15)
    r.log('energy bar 40 x 5', 'bar', 'by level', 116, 100)
    r.text('VALUE', 190, 86, 'Chalk Dim', 1, 'label')
    r.amount(60000, 190, 98, 'Chalk', 2, 'the value, 2x, no sign', sign=False)
    r.rect(20, 131, 280, 1, 'Board Rule', 'its bottom rule')
    if result is None:
        r.text('YOUR BID', 30, 146, 'Chalk Dim', 1, 'label')
        r.rect(28, 158, 140, 22, 'Board Head', 'the bid box')
        r.rect(28, 179, 140, 1, 'Chalk Yellow', 'its rule')
        r.cv.amount(55000, 34, 162, C('Chalk Yellow'), 2, sign=False)
        r.log('the bid as typed, 2x, no sign', '5 x 7, 2x, money', 'Chalk Yellow', 34, 162)
        r.rect(34 + amount_width(55000, 2, False) + 2, 162, 10, 14, 'Chalk Yellow', 'the cursor block, on 500 ms off 300 ms')
        r.text('CASH', 190, 150, 'Chalk Dim', 1, 'label')
        r.amount(-18450, 190, 162, 'Chalk Red', 1, 'the cash')
        r.text('LOAN ROOM', 190, 176, 'Chalk Dim', 1, 'label')
        r.amount(287700, 190, 188, 'Chalk', 1, 'limit less loan (what you could still borrow), no sign', sign=False)
    else:
        ok = result == 'yes'
        col = 'Chalk Green' if ok else 'Chalk Red'
        S.plate(r.cv, 40, 146, 240, 56, col)
        r.log('a plate 240 x 56 with rules in Chalk Green (accepted) or Chalk Red (refused)', 'plate', col, 40, 146)
        r.text('ACCEPTED' if ok else 'REFUSED', 0, 154, col, 2, 'ACCEPTED or REFUSED, 2x', center=160, outline='Outline')
        if ok:
            r.text('HE JOINS AS YOUR RESERVE', 0, 176, 'Chalk', 1, 'line', center=160)
        else:
            r.text('THE PRICE GOES UP TO', 0, 174, 'Chalk', 1, 'line', center=160)
            r.amount(72000, 0, 186, 'Chalk Yellow', 1, 'the new value (a fifth more)', right=180, sign=False)


@screen('sell', 'Sell a player', 'Pick one of yours; the club\'s offer appears on the right.')
def sell(r):
    menu_frame(r, 'SELL A PLAYER', '', keys=(('UP DOWN', 'MOVE'), ('Y', 'ACCEPT'), ('N', 'REFUSE')))
    for i, p in enumerate(D.SQUAD):
        y = 38 + i * 13
        name, pos, skill, energy, st, value, mark = p
        if i == 5:
            r.rect(4, y - 3, 160, 13, 'Cursor Row', 'the cursor band')
        r.sprite(POS_ICON[pos], 8, y - 1, 'position, row i at y = 38 + 13 i' if i == 0 else '')
        r.text(name, 20, y, 'Chalk Dim' if st == 'injured' else ('Chalk Yellow' if i == 5 else 'Chalk'), 1, 'name (Chalk Dim and not pickable if injured)' if i == 0 else '')
        S.skill_pips(r.cv, 96, y + 2, skill)
        r.cv.amount(value, 0, y, C('Chalk Dim'), 1, right=160, sign=False)
        if i == 0:
            r.log('skill pips', 'pips', '', 96, y + 2)
            r.log('value, no sign', '5 x 7, 1x, money', 'Chalk Dim', 160 - amount_width(value, 1, False) + 1, y)
    r.rect(168, 34, 1, 190, 'Board Rule', 'the panel rule')
    r.rect(208, 44, 30, 30, 'Wood 3', 'the face frame')
    r.sprite('face_6', 211, 47, 'the face')
    r.text('F.WIMBLE', 0, 82, 'Chalk Yellow', 1, 'name', center=243)
    r.text('AN OFFER OF', 0, 104, 'Chalk Dim', 1, 'label', center=243)
    r.cv.amount(34500, 0, 116, C('Chalk Green'), 2, right=300, sign=False)
    r.log('the offer, 2x, no sign (0.8 to 1.3 times the value)', '5 x 7, 2x, money', 'Chalk Green', 300 - amount_width(34500, 2, False) + 1, 116)
    r.text('VALUE', 0, 140, 'Chalk Dim', 1, 'label', center=243)
    r.text('30 000', 0, 150, 'Chalk Dim', 1, 'the value for comparison (drawn as an amount)', center=243)
    r.text('Y ACCEPT', 184, 176, 'Chalk Green', 1, 'Y')
    r.text('N REFUSE', 250, 176, 'Chalk Red', 1, 'N')


@screen('cup', 'The F.A. Cup round', 'Shown before a cup match. The round names: ROUND 1 to ROUND 6, SEMI-FINAL, FINAL; a replay adds REPLAY.')
def cup(r):
    menu_frame(r, 'F.A. CUP', 'WEEK 11', keys=(('ENTER', 'PICK THE TEAM'),))
    r.sprite_c('trophy_cup', 160, 78, 'the cup trophy (origin bottom middle)')
    r.text('ROUND 4', 0, 86, 'Chalk Blue', 3, 'the round, 3x', center=160, outline='Outline')
    r.text('REPLAY', 0, 112, 'Chalk Amber', 1, 'REPLAY, only for a replay', center=160)
    r.sprite('badge_tower', 72, 132, 'the home club\'s badge')
    r.text('MUDBURY', 0, 137, 'Chalk Yellow', 1, 'the home club (yours in Chalk Yellow)', right=146)
    r.text('V', 0, 137, 'Chalk Dim', 1, 'V', center=160)
    r.text('GRUBSWORTH', 174, 137, 'Chalk', 1, 'the away club')
    r.sprite('badge_star', 234 + 20, 132, 'their badge') if False else None
    r.sprite('badge_star', 252, 132, 'the away club\'s badge')
    r.text('DIVISION 1', 0, 150, 'Chalk Dim', 1, 'their division', center=214)
    r.text('AT HOME', 0, 168, 'Chalk Green', 1, 'AT HOME (Chalk Green) or AWAY (Chalk Blue)', center=160)
    


@screen('season', 'End of season', 'Your place, the prize money and one of PROMOTED, RELEGATED or STAYING UP.')
def season(r):
    menu_frame(r, 'END OF SEASON 2', '', keys=(('ENTER', 'NEXT SEASON'),))
    r.text('YOU FINISHED', 0, 42, 'Chalk Dim', 1, 'label', center=160)
    r.text('3RD', 0, 54, 'Chalk Yellow', 4, 'the place, 4x', center=160, outline='Outline')
    r.text('IN DIVISION 3', 0, 88, 'Chalk', 1, 'line', center=160)
    r.text('PRIZE MONEY', 0, 106, 'Chalk Dim', 1, 'label', center=160)
    r.amount(140000, 0, 118, 'Chalk Green', 2, 'the prize, 2x', right=196)
    S.plate(r.cv, 70, 144, 180, 44, 'Chalk Green')
    r.log('a plate 180 x 44, rules Chalk Green (promoted), Chalk Red (relegated) or Chalk Dim (staying up)', 'plate', 'Chalk Green', 70, 146)
    for x in (80, 232):
        r.sprite('mark_star', x - 1, 151, 'stars (none when relegated or staying up)' if x == 80 else '')
        r.sprite('mark_up', x, 168, 'up arrows (mark_down when relegated, none when staying up)' if x == 80 else '')
    r.text('PROMOTED', 0, 160, 'Chalk Green', 2, 'PROMOTED, RELEGATED or STAYING UP, 2x', center=160, outline='Outline')
    r.text('TO DIVISION 2', 0, 196, 'Chalk', 1, 'line', center=160)


@screen('sacked', 'Sacked', 'The only way to lose. The board is wiped and the word is chalked big; the cabinet tally stays.')
def sacked(r):
    menu_frame(r, 'THE BOARD HAS MET', '', keys=(('SPACE', 'NEW GAME'), ('ESC', 'QUIT')))
    r.text('SACKED', 0, 48, 'Chalk Red', 5, 'SACKED, 5x', center=160, outline='Outline')
    r.text('THE LOAN PASSED ITS LIMIT', 0, 100, 'Chalk', 1, 'reason', center=160)
    r.text('LOAN', 92, 116, 'Chalk Dim', 1, 'label')
    r.cv.amount(512750, 0, 116, C('Chalk Red'), 1, right=228, sign=False)
    r.log('the loan, no sign', '5 x 7, 1x, money', 'Chalk Red', 228 - amount_width(512750, 1, False) + 1, 116)
    r.text('LIMIT', 92, 128, 'Chalk Dim', 1, 'label')
    r.cv.amount(500000, 0, 128, C('Chalk Dim'), 1, right=228, sign=False)
    r.rect(14, 146, 292, 1, 'Board Rule', 'rule')
    r.text('YOUR RECORD', 0, 154, 'Chalk Dim', 1, 'label', center=160)
    r.sprite_c('cab_league', 120, 186, 'league titles')
    r.text('X 1', 130, 176, 'Chalk', 1, 'count')
    r.sprite_c('cab_cup', 190, 186, 'cups')
    r.text('X 2', 200, 176, 'Chalk', 1, 'count')
    r.text('3 SEASONS, BEST DIVISION 2', 0, 200, 'Chalk Dim', 1, 'line', center=160)


@screen('paused', 'Paused', 'A plate over whatever screen is up (here the match).')
def paused(r):
    match(r, inset=False)
    r.rows = [row for row in r.rows if row[0].startswith('the match background')]
    S.plate(r.cv, 100, 96, 120, 40)
    r.log('a plate 120 x 40', 'plate', 'Tunnel', 100, 96)
    r.text('PAUSED', 0, 104, 'Chalk Yellow', 2, 'PAUSED, 2x', center=160)
    r.text('P TO PLAY ON', 0, 123, 'Chalk Dim', 1, 'line', center=160)


@screen('cabinet', 'Trophy cabinet', 'Glass shelves in a wood case: one trophy per title, in the order won, the season under each.')
def cabinet(r):
    menu_frame(r, 'TROPHY CABINET', 'ALF MCGUFFIN', keys=(('ESC', 'BACK'),))
    r.rect(24, 38, 272, 170, 'Wood 4', 'the case')
    r.rect(28, 42, 264, 162, 'Night Haze', 'the glass back')
    for k in range(3):
        y = 92 + k * 54
        r.rect(28, y, 264, 4, 'Wood 2', 'a shelf, shelf k at y = 92 + 54 k' if k == 0 else '')
        r.cv.rect(28, y + 3, 264, 1, C('Wood 4'))
    r.text('LEAGUE', 36, 48, 'Chalk Dim', 1, 'shelf label')
    for i, s in enumerate((3, 5)):
        r.sprite_c('cab_league', 50 + i * 22, 91, 'a league title, every 22 pixels from x 50' if i == 0 else '')
        r.cv.small('S%d' % s, 45 + i * 22, 82 + 16, C('Chalk Dim')) if False else None
    r.text('F.A. CUP', 36, 102, 'Chalk Dim', 1, 'shelf label')
    for i, s in enumerate((2, 4, 5)):
        r.sprite_c('cab_cup', 50 + i * 22, 145, 'a cup, every 22 pixels' if i == 0 else '')
    r.text('BIG ONES', 36, 156, 'Chalk Dim', 1, 'shelf label: the full size trophies of the last titles')
    r.sprite_c('trophy_league', 120, 199, 'the latest league title, full size')
    r.sprite_c('trophy_cup', 200, 199, 'the latest cup, full size')
    r.text('2 TITLES   3 F.A. CUPS   6 SEASONS', 0, 214, 'Chalk', 1, 'the tally', center=160)


# ======================================================================================================================
def render(key, **kw):
    for k, t, f, note in SCREENS:
        if k == key:
            rec = Rec()
            f(rec, **kw)
            return rec
    raise KeyError(key)
