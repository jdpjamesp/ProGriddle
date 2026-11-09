"""Badges, faces, icons, trophies, the cursor and the close up ball: built here, written into the design as grids."""
import random
from raster import Grid
from lib import grid

# ---------------------------------------------------------------------------------------------------------------- badges
CHARGES = {
    'star': '...#...,...#...,#######,.#####.,..###..,.##.##.,.#...#.',
    'tower': '#.#.#.#,#######,.#####.,.#####.,.##.##.,.##.##.,#######',
    'anchor': '...#...,..#.#..,...#...,.#####.,...#...,#..#..#,.#####.',
    'tree': '..###..,.#####.,#######,.#####.,...#...,...#...,..###..',
    'fish': '.......,..##...,.####.#,#.#####,.####.#,..##...,.......',
    'kettle': '..##...,.#..#..,.####.#,######.,.####..,.####..,.......',
    'ball': '..###..,.##.##.,##...##,#.....#,##...##,.##.##.,..###..',
    'bolt': '....##.,...##..,..##...,.#####.,...##..,..##...,.##....',
}

BADGES = [
    # name, shape, field, colour a, colour b, charge, charge colour, what it is
    ('badge_star', 'shield', 'halves', 'Badge Red', 'Badge White', 'star', 'Badge Gold', 'red and white halves, a gold star'),
    ('badge_hoops', 'round', 'hoops', 'Badge Gold', 'Badge Black', 'ball', 'Badge White', 'gold and black hoops, a white ball'),
    ('badge_tower', 'shield', 'plain', 'Badge Navy', 'Badge Navy', 'tower', 'Badge White', 'navy, a white tower'),
    ('badge_anchor', 'round', 'plain', 'Badge Sky', 'Badge Sky', 'anchor', 'Badge Navy', 'sky blue, a navy anchor'),
    ('badge_tree', 'shield', 'border', 'Badge Green', 'Badge Gold', 'tree', 'Badge Gold', 'green with a gold border, a gold oak'),
    ('badge_chevron', 'shield', 'chevron', 'Badge Purple', 'Badge White', None, None, 'purple, a white chevron'),
    ('badge_fish', 'crest', 'stripes', 'Badge Teal', 'Badge White', 'fish', 'Badge Navy', 'teal and white stripes, a navy fish'),
    ('badge_kettle', 'round', 'quarters', 'Badge Orange', 'Badge White', 'kettle', 'Badge Black', 'orange and white quarters, a black kettle'),
]


def badge_mask(shape):
    m = []
    for y in range(16):
        row = ''
        for x in range(16):
            if shape == 'shield':
                ins = 1 <= x <= 14 and 1 <= y <= 14 and (y <= 9 or abs(x - 7.5) <= (14.5 - y) * 1.3 + 0.6)
            elif shape == 'round':
                ins = (x - 7.5) ** 2 + (y - 7.5) ** 2 <= 7.1 ** 2
            else:  # crest: a shield with a notched top
                ins = 1 <= x <= 14 and 1 <= y <= 14 and (y <= 10 or abs(x - 7.5) <= (14.5 - y) * 1.6 + 0.6)
                if y <= 2 and 6 <= x <= 9:
                    ins = y == 2
            row += '#' if ins else '.'
        m.append(row)
    return m


def badge(name, shape, field, a, b, charge, cc):
    m = badge_mask(shape)
    g = [['.'] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if m[y][x] != '#':
                continue
            if field == 'halves':
                c = 'A' if x < 8 else 'B'
            elif field == 'hoops':
                c = 'A' if (y // 3) % 2 == 0 else 'B'
            elif field == 'stripes':
                c = 'A' if (x // 2) % 2 == 0 else 'B'
            elif field == 'quarters':
                c = 'A' if (x < 8) == (y < 8) else 'B'
            elif field == 'chevron':
                c = 'B' if 0 <= (y - 4) - abs(x - 7.5) * 0.9 < 3 else 'A'
            else:
                c = 'A'
            g[y][x] = c
    # edge: every mask pixel next to an outside pixel
    for y in range(16):
        for x in range(16):
            if m[y][x] == '#' and any(not (0 <= y + dy < 16 and 0 <= x + dx < 16) or m[y + dy][x + dx] != '#'
                                      for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y][x] = 'E'
    if field == 'border':
        for y in range(16):
            for x in range(16):
                if g[y][x] == 'A' and any(g[y + dy][x + dx] == 'E' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    g[y][x] = 'B'
    # a 1 pixel highlight down the left of the field (a sheen on the enamel)
    if charge:
        rows = CHARGES[charge].split(',')
        ox, oy = 4, 4 if shape != 'round' else 4
        if shape == 'shield' or shape == 'crest':
            oy = 3
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch == '#':
                    g[oy + j][ox + i] = 'C'
    legend = {'E': 'Badge Edge', 'A': a, 'B': b}
    if charge:
        legend['C'] = cc
    rows = [''.join(r) for r in g]
    legend = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    return rows, legend


def mini(rows16):
    """The 8 x 8 badge for the status bar and the table: every second pixel, then the edge redrawn."""
    out = []
    for y in range(8):
        r = ''
        for x in range(8):
            r += rows16[y * 2 + 1][x * 2 + 1] if y * 2 + 1 < 16 else '.'
        out.append(r)
    return out


# ---------------------------------------------------------------------------------------------------------------- faces
FACES = [
    # name, skin (base, shade), hair colour, style, extra, mouth, what
    ('face_1', 1, 'Hair Dark', 'short', None, 'smile', 'short dark hair, a smile'),
    ('face_2', 2, 'Hair Black', 'afro', None, 'grin', 'a big round afro, a wide grin'),
    ('face_3', 3, 'Hair Black', 'shaved', 'beard', 'flat', 'shaved head, a full beard'),
    ('face_4', 1, 'Hair Ginger', 'mop', 'freckles', 'smile', 'a ginger mop and freckles'),
    ('face_5', 1, 'Hair Fair', 'long', 'band', 'smile', 'long fair hair and a headband'),
    ('face_6', 2, 'Hair Dark', 'quiff', 'tache', 'flat', 'a quiff and a proud moustache'),
    ('face_7', 3, 'Hair Black', 'part', None, 'flat', 'short hair with a side parting, serious'),
    ('face_8', 1, 'Hair Grey', 'bald', 'tache', 'grin', 'grey and thinning, a grin: the veteran'),
]
SKIN = {1: ('Skin 1', 'Skin 1 Shade'), 2: ('Skin 2', 'Skin 2 Shade'), 3: ('Skin 3', 'Skin 3 Shade')}


def face(skin, hair, style, extra, mouth):
    g = Grid(24, 24)
    g.rect = None
    for y in range(24):
        for x in range(24):
            g.g[y][x] = 'G'
    # shoulders and shirt (White row tones, the game may recolour with the Black row)
    g.ellipse(12, 26, 11, 7.5, '3')
    g.shade()
    # collar
    for x in range(9, 15):
        g.set(x, 19, 'P')
    g.set(10, 20, 'P'); g.set(13, 20, 'P'); g.set(11, 21, 'P'); g.set(12, 21, 'P')
    # neck
    for y in range(15, 20):
        for x in range(10, 14):
            g.set(x, y, 'B')
    if style == 'afro':
        g.ellipse(12, 8, 9, 7.5, 'H')
    if style == 'long':
        g.ellipse(12, 10, 7.5, 9, 'H')
    # head
    g.ellipse(12, 10, 5.6, 7.0, 'A')
    g.set(6, 10, 'A'); g.set(18, 10, 'A'); g.set(6, 11, 'B'); g.set(18, 11, 'B')  # ears
    for y in range(4, 18):  # shade down the right side of the face
        xs = [x for x in range(24) if g.g[y][x] == 'A']
        if xs:
            g.g[y][max(xs)] = 'B'
    # hair styles
    if style == 'short':
        for y, (a, b) in enumerate([(9, 14), (7, 17), (6, 18), (6, 18), (6, 7), (6, 6)], start=2):
            for x in range(a, b + 1):
                g.set(x, y, 'H')
        for x in range(12, 18):
            g.set(x, 6, 'H')
    elif style == 'afro':
        for x in range(7, 17):
            g.set(x, 4, 'H')
        g.set(7, 5, 'H'); g.set(16, 5, 'H')
    elif style == 'mop':
        for y, (a, b) in enumerate([(8, 15), (6, 17), (5, 18), (5, 18), (5, 18), (5, 7)], start=1):
            for x in range(a, b + 1):
                g.set(x, y, 'H')
        for x in (8, 10, 13, 15, 17):
            g.set(x, 6, 'H')
    elif style == 'long':
        for y, (a, b) in enumerate([(8, 15), (6, 17), (6, 17)], start=2):
            for x in range(a, b + 1):
                g.set(x, y, 'H')
    elif style == 'quiff':
        for y, (a, b) in enumerate([(10, 17), (8, 18), (6, 18), (6, 18), (6, 7)], start=1):
            for x in range(a, b + 1):
                g.set(x, y, 'H')
    elif style == 'part':
        for y, (a, b) in enumerate([(9, 14), (7, 17), (6, 18), (6, 9)], start=2):
            for x in range(a, b + 1):
                g.set(x, y, 'H')
        g.set(9, 3, 'A')
    elif style == 'shaved':
        for y, (a, b) in enumerate([(9, 14), (7, 16)], start=3):
            for x in range(a, b + 1):
                g.set(x, y, 'B')
    elif style == 'bald':
        for x in (6, 7, 17, 18):
            for y in (6, 7, 8):
                g.set(x, y, 'H')
        g.set(10, 3, 'C')  # a shine on the dome
        g.set(11, 3, 'C')
    if extra == 'band':
        for x in range(6, 19):
            g.set(x, 5, 'D')
    # brows and eyes
    for x in (8, 9, 10, 14, 15, 16):
        g.set(x, 8, 'H' if style not in ('shaved', 'bald') else 'K')
    for ex in (9, 15):
        g.set(ex - 1, 10, 'W'); g.set(ex, 10, 'K')
    # nose
    g.set(12, 12, 'B'); g.set(12, 13, 'B'); g.set(13, 13, 'B')
    # mouth
    if mouth == 'smile':
        for x in range(10, 15):
            g.set(x, 15, 'M')
        g.set(9, 14, 'M'); g.set(15, 14, 'M')
    elif mouth == 'grin':
        for x in range(9, 16):
            g.set(x, 14, 'M')
        for x in range(10, 15):
            g.set(x, 15, 'W')
        for x in range(10, 15):
            g.set(x, 16, 'M')
    else:
        for x in range(10, 15):
            g.set(x, 15, 'M')
    if extra == 'beard':
        for y in range(13, 19):
            for x in range(6, 19):
                if g.get(x, y) in ('A', 'B') and not (10 <= x <= 14 and y == 15):
                    g.set(x, y, 'H')
        for x in range(10, 15):
            g.set(x, 15, 'M')
    if extra == 'tache':
        for x in range(10, 15):
            g.set(x, 14, 'H')
        g.set(9, 15, 'H'); g.set(15, 15, 'H')
    if extra == 'freckles':
        for x, y in ((8, 12), (10, 13), (14, 13), (16, 12), (9, 12), (15, 12)):
            g.set(x, y, 'F')
    else:
        g.set(8, 12, 'F'); g.set(16, 12, 'F')
    rows = g.rows()
    sk, sh = SKIN[skin]
    legend = {'G': 'Face Back', 'A': sk, 'B': sh, 'H': hair, 'K': 'Eye', 'W': 'Eye White', 'M': 'Mouth', 'F': 'Cheek',
              'P': 'Kit Hoop', 'D': 'Magnet Red 3', 'C': 'Skin 1'}
    if skin == 1:
        legend['C'] = 'Eye White'
    legend.update({k: 'White %s' % k for k in '12345'})
    legend = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    return rows, legend


def shirt(kit):
    """A big shirt for the kit screen: body, sleeves, a V collar; the white has a black hoop, the black pale pinstripes."""
    g = Grid(24, 24)
    g.poly([(4, 3), (9, 1), (15, 1), (20, 3), (23, 9), (19, 11), (18, 9), (18, 22), (6, 22), (6, 9), (5, 11), (1, 9)], '3')
    g.shade()
    for y in range(24):
        for x in range(24):
            if g.g[y][x] in '1234':
                if kit == 'white' and 11 <= y <= 14:
                    g.g[y][x] = 'P'
                if kit == 'black' and x % 4 == 1 and y >= 4 and 6 <= x <= 18:
                    g.g[y][x] = 'P'
    for x, y in ((10, 1), (11, 2), (12, 3), (13, 2), (14, 1)):
        g.set(x, y, 'V')
    g.outline('5')
    rows = g.rows()
    legend = {'P': 'Kit Hoop' if kit == 'white' else 'Kit Pinstripe', 'V': 'Kit Hoop' if kit == 'white' else 'Kit Pinstripe'}
    legend.update({k: ('White %s' if kit == 'white' else 'Black %s') % k for k in '12345'})
    legend = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    return rows, legend


# ---------------------------------------------------------------------------------------------------------------- icons
def icon(shape, legend, outline=True, w=8, h=8):
    rows = grid(shape)
    g = Grid(w, h)
    oy = (h - len(rows)) // 2
    ox = (w - len(rows[0])) // 2
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch != '.':
                g.g[oy + j][ox + i] = ch
    if outline:
        g.outline('E')
        legend = dict(legend, E='Icon Edge')
    rows = g.rows()
    legend = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    return rows, legend


ICONS = {
    # positions: four shapes as well as four colours
    'pos_gk': ('P.P.P.,PPPPP.,PPPPPP,PPPPP.,.PPPP.,.WWW..', {'P': 'Pos GK', 'W': 'Glove'}, 'goalkeeper: a glove'),
    'pos_df': ('PPPPPP,PWPPPP,PPPPPP,PPPPPP,.PPPP.,..PP..', {'P': 'Pos DF', 'W': 'Spark'}, 'defender: a shield'),
    'pos_mf': ('..PP..,.PPPP.,PPWPPP,.PPPP.,..PP..', {'P': 'Pos MF', 'W': 'Spark'}, 'midfielder: a diamond'),
    'pos_fw': ('...P..,...PP.,PPPPPP,...PP.,...P..', {'P': 'Pos FW'}, 'forward: an arrow'),
    # states
    'state_injured': ('..WW..,..RR..,WRRRRW,WRRRRW,..RR..,..WW..', {'W': 'Plaster', 'R': 'Chalk Red'}, 'injured: a red cross on a plaster'),
    'state_tired': ('ZZZ...,..Z...,.Z.ZZ.,ZZZ.Z.,...ZZ.', {'Z': 'Zzz'}, 'tired (energy 6 or less): two Zs'),
    'state_form': ('..F...,.FF.F.,.FFFF.,FFYYF.,FYYYYF,.FYYF.', {'F': 'Flame', 'Y': 'Flame Core'}, 'in form (energy 16 or more and fit): a flame'),
    # events
    'ev_goal': ('NNNNNN,N.N.N.,.N.WW.,N.WWWW,.NWWWW,N.NWW.', {'N': 'Net', 'W': 'Ball 3'}, 'goal: the ball in the net'),
    'ev_injury': ('..RR..,..RR..,RRRRRR,RRRRRR,..RR..,..RR..', {'R': 'Chalk Red'}, 'injury: a red cross'),
    'ev_whistle': ('....SS,SSSSSS,SKKSSS,SKKSS.,.SS...', {'S': 'Silver 3', 'K': 'Silver 5'}, 'whistle: kick off and full time'),
    'ev_save': ('C....C,CC..CC,.CCCC.,.CWWC.,..WW..', {'C': 'Glove', 'W': 'Ball 3'}, 'a save: two gloves and the ball'),
    'ev_wide': ('P....,P..W.,P....,P....,P....', {'P': 'Post', 'W': 'Ball 3'}, 'wide: a post and the ball beside it'),
    'ev_block': ('.SS...,SSSS..,.SS.W.,.SS...,S..S..', {'S': 'Chalk Dim', 'W': 'Ball 3'}, 'blocked: a defender and the ball turned back'),
    # money and club
    'money_coin': ('.GGGG.,GHGGGG,GGDDGG,GGDDGG,GGGGGS,.GSSS.', {'G': 'Gold 3', 'H': 'Gold 1', 'D': 'Gold 4', 'S': 'Gold 4'}, 'cash in credit: a gold coin'),
    'money_owed': ('.RR.RR,RHR.RR,RR.DRR,RRD.RR,RR.RRS,.RS.S.', {'R': 'Chalk Red', 'H': 'Spark Warm', 'D': 'Spent Dark', 'S': 'Spent Dark'}, 'cash in debt: a cracked red coin'),
    'money_bank': ('..SS..,.SSSS.,SSSSSS,.S.S.S,.S.S.S,SSSSSS', {'S': 'Silver 3'}, 'the bank (repay)'),
    'money_loan': ('PPPPP.,PLLLPP,PPPPPP,PLLLLP,PPPRRP,PPPRRP', {'P': 'Envelope', 'L': 'Silver 4', 'R': 'Chalk Red'}, 'the loan: a note with a red seal'),
    'money_ground': ('B....B,BB..BB,BBBBBB,BGGGGB,BGGGGB', {'B': 'Brick', 'G': 'Turf'}, 'the ground (gate receipts, rent)'),
    'money_wages': ('PPPPPP,PSPPSP,PPSSPP,PPPPPP,PPPPPP', {'P': 'Envelope', 'S': 'Envelope Shade'}, 'the wage packet'),
    'morale': ('.CCCC.,CKCCKC,CCCCCC,CKCCKC,CCKKCC,.CCCC.', {'C': 'Chalk Blue', 'K': 'Board'}, 'morale: a smiling face'),
    'kit_white': ('33..33,333333,.3333.,.PPPP.,.3333.', {'P': 'Kit Hoop', '3': 'White 3'}, 'the white kit (a black hoop), for the score bar'),
    'kit_black': ('33..33,3P3P33,.P3P3.,.P3P3.,.P3P3.', {'P': 'Kit Pinstripe', '3': 'Black 3'}, 'the black kit (pale pinstripes), for the score bar'),
    # table and markers
    'mark_up': ('..G..,.GGG.,GGGGG,..G..,..G..', {'G': 'Chalk Green'}, 'promotion zone marker'),
    'mark_down': ('..R..,..R..,RRRRR,.RRR.,..R..', {'R': 'Chalk Red'}, 'relegation zone marker'),
    'mark_star': ('...Y...,...Y...,YYYYYYY,.YYYYY.,..YYY..,.YY.YY.', {'Y': 'Chalk Yellow'}, 'the lit star beside a club that went up'),
    'magnet_on': ('.RRRR.,RHRRRR,RRRRRR,RRRRRR,RRRRRS,.RSSS.', {'R': 'Magnet Red 3', 'H': 'Magnet Red 1', 'S': 'Magnet Red 4'}, 'picked to start: a red tactics magnet'),
    'magnet_res': ('.RRRR.,RH..RR,R....R,R....R,RR..RS,.RSSS.', {'R': 'Magnet Blue 3', 'H': 'Magnet Blue 1', 'S': 'Magnet Blue 4'}, 'the reserve: a blue ring magnet'),
    'cursor_1': ('YY....,YYYY..,YYYYYY,YYYY..,YY....', {'Y': 'Chalk Yellow'}, 'the chalk arrow cursor, frame 1'),
    'cursor_2': ('.YY...,.YYYY.,.YYYYY,.YYYY.,.YY...', {'Y': 'Chalk Yellow'}, 'frame 2: one pixel right'),
}
ICON_OUTLINE = {'cursor_1': False, 'cursor_2': False, 'mark_up': False, 'mark_down': False, 'mark_star': False}


# ---------------------------------------------------------------------------------------------------------------- trophies
def trophy(w, h, metal, big=True):
    g = Grid(w, h)
    if big:
        g.poly([(7, 2), (25, 2), (24, 9), (21, 14), (17, 16), (15, 16), (11, 14), (8, 9)], '3')  # bowl
        g.ellipse(16, 2.5, 9.2, 1.6, '3')
        g.capsule((6, 5), (4, 6), 1.0, '3'); g.capsule((4, 6), (6, 11), 1.0, '3')  # handles
        g.capsule((26, 5), (28, 6), 1.0, '3'); g.capsule((28, 6), (26, 11), 1.0, '3')
        g.poly([(14.5, 16), (17.5, 16), (17, 21), (15, 21)], '3')  # stem
        g.poly([(11, 21), (21, 21), (22, 24), (10, 24)], '3')  # foot
        g.shade(body='3', top='2', low='4')
        for y in range(3, 12):
            g.set(10 + (y > 6), y, '1')
        g.ellipse(16, 2.5, 8, 0.8, '4')
        g.poly([(8, 24), (24, 24), (24, 30), (8, 30)], 'W')  # plinth
        for x in range(8, 25):
            g.set(x, 24, 'V')
            g.set(x, 30, 'X')
        for x in range(12, 21):
            g.set(x, 27, 'Y')  # the plate
        g.outline('5')
    else:
        g.poly([(2, 1), (10, 1), (9.5, 5), (7, 8), (5, 8), (2.5, 5)], '3')
        g.capsule((1, 2), (1, 4), 0.6, '3'); g.capsule((11, 2), (11, 4), 0.6, '3')
        g.poly([(5.5, 8), (6.5, 8), (6.5, 10), (5.5, 10)], '3')
        g.poly([(3, 10), (9, 10), (9, 12), (3, 12)], '3')
        g.shade(body='3', top='2', low='4')
        g.set(4, 2, '1'); g.set(4, 3, '1')
        g.poly([(2, 12), (10, 12), (10, 15), (2, 15)], 'W')
        for x in range(2, 11):
            g.set(x, 12, 'V')
        g.outline('5')
    rows = g.rows()
    legend = {k: '%s %s' % (metal, k) for k in '12345'}
    legend.update({'W': 'Wood 3', 'V': 'Wood 2', 'X': 'Wood 5', 'Y': 'Gold 2'})
    legend = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    return rows, legend


# ---------------------------------------------------------------------------------------------------------------- crowd
CROWD_COLOURS = 'RCBGP'
CROWD_NAMES = {'R': 'Crowd Red', 'C': 'Crowd Cream', 'B': 'Crowd Blue', 'G': 'Crowd Gold', 'P': 'Crowd Plum',
               'F': 'Crowd Face', 'D': 'Crowd Face Dark', 'K': 'Crowd Shadow', 'S': 'Stand'}


def crowd(cheer):
    """32 x 8 tile, repeated along a stand: two rows of fans (heads on rows 0 and 4)."""
    rnd = random.Random(7)
    g = [['K'] * 32 for _ in range(8)]
    for row, y0, off in ((0, 0, 0), (1, 4, 2)):
        for i in range(8):
            x = i * 4 + off
            shirt = CROWD_COLOURS[rnd.randrange(5)]
            face = 'F' if rnd.random() < 0.6 else 'D'
            up = 1 if (cheer and (i + row) % 2 == 0) else 0
            arms = cheer and (i + row) % 3 != 1
            hy = y0 - up
            for dx in (0, 1):
                if 0 <= hy < 8:
                    g[hy][(x + dx) % 32] = face
                for yy in (hy + 1, hy + 2, hy + 3):
                    if 0 <= yy < 8:
                        g[yy][(x + dx) % 32] = shirt
            if arms and 0 <= hy < 8:
                g[hy][(x - 1) % 32] = shirt if hy >= 0 else 'K'
                g[hy][(x + 2) % 32] = shirt
    return [''.join(r) for r in g]


# ---------------------------------------------------------------------------------------------------------------- close up ball and ripple
GM_BALL = {
    'gm_ball_near': '...555...,..51225..,.5112235.,511223345,512233345,522333445,.5334445.,..54445..,...555...',
    'gm_ball_mid': '..555..,.51225.,5122235,5122345,5223345,.53445.,..555..',
    'gm_ball_far': '.555.,51225,52235,53345,.555.',
}


def ripple(k):
    """The net ripple round the ball: three rings of lit mesh, 24 x 16, centre (12, 8)."""
    g = Grid(24, 16)
    r = 3 + k * 3
    for y in range(16):
        for x in range(24):
            d = (((x - 11.5) / 1.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if abs(d - r) < 0.9 and (x + y) % 2 == 0:
                g.g[y][x] = 'L' if k < 3 else 'N'
            elif abs(d - (r - 2.5)) < 0.7 and (x + y) % 2 == 0 and k > 1:
                g.g[y][x] = 'N'
    return g.rows()
