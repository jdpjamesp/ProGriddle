"""Every sprite of Moonpatch as a grid of letters. Family letters (L, M, D, s, x) take their colours from the wave (palette.fam)."""
import math
from lib import Sprite, grid, mirror, rotate
from palette import fam
import shapes as SH

W1 = fam('Orchid')      # the legend the sheet shows the Gloam in (wave 1)
B1 = fam('Jade')        # the legend the sheet shows the bulbs in (wave 1)
ALL = {}


def add(s):
    ALL[s.name] = s
    return s


# ---------------------------------------------------------------- the bulbs
BULB = {
    4: grid('''
        ....L...
        ...LM...
        ..LLMM..
        .LLMMMD.
        LLMMMMDD
        LMMMMMDD
        .MMMMDD.
        ..sDDs..
    '''),
    3: grid('''
        ....L...
        ...LM...
        ..LLMM..
        .LLMMMD.
        LLMMMMDD
        L.MM.MD.
        ...M....
        ........
    '''),
    2: grid('''
        ....L...
        ...LM...
        ..LLMM..
        .L.MMMD.
        L..M..D.
        ........
        ........
        ........
    '''),
    1: grid('''
        ....L...
        ...LM...
        ..L..M..
        ...D....
        ........
        ........
        ........
        ........
    '''),
}
# The blight spots: where these cells are filled, a blighted bulb shows a dark spot (letter x).
SPOTS = [(4, 2), (2, 4), (5, 5), (3, 3)]


def blighted(rows):
    r = [list(x) for x in rows]
    for (i, j) in SPOTS:
        if r[j][i] in 'LMD' and (i, j) != (3, 3):
            r[j][i] = 'x'
    return [''.join(x) for x in r]


for hp in (4, 3, 2, 1):
    add(Sprite('bulb_%d' % hp, BULB[hp], dict(B1), group='bulb',
               note='A bulb with %d hit%s left. Drawn in the wave\'s bulb family.' % (hp, '' if hp == 1 else 's')))
for hp in (4, 3, 2, 1):
    add(Sprite('blight_%d' % hp, blighted(BULB[hp]), fam('', True), group='bulb',
               note='A blighted bulb with %d hit%s left: Blight colours in every wave, and dark blight spots.' % (hp, '' if hp == 1 else 's')))

add(Sprite('bulb_pop_1', grid('''
    ...L....
    .L..L.L.
    ..LMML..
    L.MMMM.L
    ..MMMM..
    .L.MM.L.
    ...L..L.
    L.......
'''), dict(B1), group='bulb', note='The last hit, frames 0 to 3: the bulb bursts into seeds. Wave\'s bulb family.'))
add(Sprite('bulb_pop_2', grid('''
    L.....L.
    ...L....
    .L....L.
    ....M...
    ..M.....
    L.....M.
    ...L....
    .L....L.
'''), dict(B1), group='bulb', note='The last hit, frames 4 to 7: the seeds scatter. Then nothing.'))

GLINT = [
    grid('''
        ........
        ........
        ....T...
        ...TWT..
        ....T...
        ........
        ........
        ........
    '''),
    grid('''
        ....T...
        ....T...
        ....W...
        TTWWWWTT
        ....W...
        ....T...
        ....T...
        ........
    '''),
    grid('''
        ........
        ...T.T..
        ....W...
        ...TWT..
        ....W...
        ...T.T..
        ........
        ........
    '''),
]
for i, g in enumerate(GLINT):
    add(Sprite('glint_%d' % (i + 1), g, {'T': 'Text', 'W': 'Spark'}, group='bulb',
               note='The repair glint, frame %d (4 game frames each), drawn over a bulb made whole.' % (i + 1)))

# ---------------------------------------------------------------- the Gloam
LEG_TOP = [(1, 5), (2, 6), (3, 7), (2, 6)]       # the x of the two top legs, by frame
LEG_LOW = [(3, 7), (2, 6), (1, 5), (2, 6)]


def bead(f):
    rows = SH.render(8, 8, lambda x, y: SH.ball(x, y, 4.0, 4.0, 3.3, 'LMD'))
    for x in LEG_TOP[f]:
        SH.setc(rows, x - 1, 0, 'D' if f % 2 else 'M')
    for x in LEG_LOW[f]:
        SH.setc(rows, x - 1, 7, 'D' if f % 2 == 0 else 'M')
    SH.setc(rows, 3, 3, 'L')
    return rows


HEAD_OPEN = grid('''
    .D....L.
    ..LLL..L
    .LLLLke.
    LLLLMMM.
    LMMMMMM.
    .MMMMke.
    ..DDD..L
    .D....L.
''')
HEAD_SHUT = grid('''
    .D......
    ..LLL.L.
    .LLLLkeL
    LLLLMMM.
    LMMMMMM.
    .MMMMkeL
    ..DDD.L.
    .D......
''')


def head(f):
    rows = list(HEAD_OPEN if f < 2 else HEAD_SHUT)
    rows[0] = '.' * 8
    rows[7] = '.' * 8
    for x in LEG_TOP[f][:1]:
        SH.setc(rows, x, 0, 'D')
    for x in LEG_LOW[f][:1]:
        SH.setc(rows, x, 7, 'D')
    if f < 2:
        SH.setc(rows, 6, 0, 'L')
        SH.setc(rows, 6, 7, 'L')
    return rows


GL = dict(W1)
GL['e'] = 'Ember'
GL['k'] = 'Ink'
for f in range(4):
    add(Sprite('bead_%d' % (f + 1), bead(f), dict(GL), group='gloam',
               note='A bead of the Gloam, walking frame %d. Faces right; mirror it for left (the light stays on the top).' % (f + 1)))
for f in range(4):
    add(Sprite('head_%d' % (f + 1), head(f), dict(GL), group='gloam',
               note='The Gloamhead, frame %d: brighter than a bead, Ember eyes, pincers that open (frames 1, 2) and shut (3, 4). Faces right; mirror for left.' % (f + 1)))
add(Sprite('head_dive', rotate(head(0), 1), dict(GL), group='gloam',
           note='The Gloamhead diving (it touched a blighted bulb): head_1 turned a quarter clockwise, so it faces down. The beads behind it flicker in Blight (4.5).'))

# ---------------------------------------------------------------- the burst that leaves a bulb
add(Sprite('burst_1', grid('''
    ............
    ............
    ....FFFF....
    ...FFFFFF...
    ..FFFFFFFF..
    ..FFFFFFFF..
    ..FFFFFFFF..
    ..FFFFFFFF..
    ...FFFFFF...
    ....FFFF....
    ............
    ............
'''), {'F': 'Flash'}, group='burst', note='A bead or head shot, frames 0 to 2: a white flash that covers the tile (the new bulb is already baked under it).'))
add(Sprite('burst_2', grid('''
    ............
    ...B....B...
    ....BBBB....
    ..BB....BB..
    ..B......B..
    .B........B.
    .B........B.
    ..B......B..
    ..BB....BB..
    ....BBBB....
    ...B....B...
    ............
'''), {'B': 'Burst'}, group='burst', note='Frames 3 to 6: a gold ring opens and the new bulb shows inside it.'))
add(Sprite('burst_3', grid('''
    B..........B
    ............
    ..S......S..
    ............
    ............
    .S........S.
    ............
    ............
    ..S......S..
    ............
    ............
    B..........B
'''), {'B': 'Burst', 'S': 'Smoke'}, group='burst', note='Frames 7 to 10: the last sparks and a little smoke fly off the corners. Then only the bulb.'))

# ---------------------------------------------------------------- the Wick and its spark
WICK = [
    grid('''
        ...TT...
        ...WW...
        ..dWWd..
        .dWTTWd.
        .dWTTWd.
        .dWWWWd.
        dddddddd
        .d....d.
    '''),
    grid('''
        ....T...
        ...WT...
        ..dWWd..
        .dWTTWd.
        .dWTWWd.
        .dWWWWd.
        dddddddd
        .d....d.
    '''),
]
WL = {'T': 'Wick Light', 'W': 'Wick', 'd': 'Wick Deep'}
for i, g in enumerate(WICK):
    add(Sprite('wick_%d' % (i + 1), g, dict(WL), group='wick', box=(1, 1, 6, 6),
               note='The Wick, idle frame %d (the flame leans; 6 game frames each). Box: the inner 6 x 6, from (1, 1).' % (i + 1)))
add(Sprite('spark', grid('''
    SS
    SS
    tt
    tt
    WW
    W.
    .d
    d.
'''), {'S': 'Spark', 't': 'Spark Tail', 'W': 'Wick', 'd': 'Wick Deep'}, group='wick', box=(0, 0, 2, 1),
    note='The spark, 2 x 8: a white head and a tail that fades, so a shot flying 8 cells a frame leaves an unbroken streak. Box: the top row.'))
add(Sprite('muzzle', grid('''
    .S..S.
    ..SS..
    S.SS.S
'''), {'S': 'Spark'}, group='wick', note='The muzzle flash: 2 game frames after a shot leaves, its bottom row on the flame tip (row 0 of the Wick).'))
add(Sprite('wick_icon', grid('''
    ..T..
    ..W..
    .dWd.
    dWTWd
    dWWWd
    ddddd
'''), dict(WL), group='wick', note='A Wick in the strip: one for each life in hand.'))


def wick_death(f):
    """Frame f (0 to 5) of the Wick breaking up, 16 x 16, centred on the Wick's centre."""
    rows = SH.blank(16, 16)
    if f == 0:
        return SH.render(16, 16, lambda x, y: 'F' if (x - 8) ** 2 + (y - 8) ** 2 < 12 else ('T' if (x - 8) ** 2 + (y - 8) ** 2 < 22 else None))
    pieces = [(-1.0, -1.3, 'T'), (1.1, -1.1, 'W'), (-1.4, 0.2, 'd'), (1.4, 0.4, 'W'), (-0.6, 1.2, 'd'), (0.7, 1.3, 'T'), (0.0, -1.6, 'T')]
    r = 1.0 + f * 1.25
    for dx, dy, c in pieces:
        x = int(round(7.5 + dx * r))
        y = int(round(7.5 + dy * r + (f * f) * 0.12))
        ch = c if f < 4 else ('k' if f == 5 else c)
        SH.setc(rows, x, y, ch)
        if f < 3:
            SH.setc(rows, x + 1, y, ch)
            SH.setc(rows, x, y + 1, 'e' if f == 1 else ch)
        if f >= 2:
            SH.setc(rows, x - int(math.copysign(1, dx)) if dx else x, y - 1 if dy < 0 else y + 1, 'k')
    if f in (1, 2):
        for (x, y) in ((7, 7), (8, 8), (7, 8), (8, 7)):
            SH.setc(rows, x, y, 'B')
    return rows


for f in range(6):
    add(Sprite('wick_break_%d' % (f + 1), wick_death(f),
               {'F': 'Flash', 'T': 'Wick Light', 'W': 'Wick', 'd': 'Wick Deep', 'e': 'Ember', 'B': 'Burst', 'k': 'Smoke'},
               group='wickdeath', note='The Wick breaking up, frame %d of 6 (10 game frames each). 16 x 16, centred on the Wick\'s centre.' % (f + 1)))

# ---------------------------------------------------------------- the Sower (the dropper)
SOWER = [
    grid('''
        h......h
        .hHHHHh.
        .HhHHHH.
        .HhHHHH.
        ..HHHH..
        ..eHHe..
        ...ss...
        ...ss...
    '''),
    grid('''
        ........
        h.HHHH.h
        hHhHHHHh
        .HhHHHH.
        ..HHHH..
        ..eHHe..
        ...ss...
        ....s...
    '''),
]
SL = {'H': 'Husk', 'h': 'Husk Light', 'e': 'Ember', 's': 'Stalk'}
SH_HURT = {'H': 'Husk Light', 'h': 'Text', 'e': 'Ember', 's': 'Stalk'}
for i, g in enumerate(SOWER):
    add(Sprite('sower_%d' % (i + 1), g, dict(SL), group='sower',
               note='The Sower falling head first, wings frame %d (3 game frames each). It carries a seed under it. Box: the whole 8 x 8.' % (i + 1)))
for i, g in enumerate(SOWER):
    add(Sprite('sower_hurt_%d' % (i + 1), g, dict(SH_HURT), group='sower',
               note='The Sower after one hit, frame %d: a paler shell (and on frames where (Frames div 2) mod 2 = 1, draw it all in Flash).' % (i + 1)))

# ---------------------------------------------------------------- the Skitterjack (the zigzagger)
JACK_OUT = grid('''
    .T............T.
    T.T...JJJJ...T.T
    ...T.JTTJJJ.T...
    .TTTTJTJJJJTTTT.
    T....JeJJeJ....T
    ..TTTJJJJJJTTT..
    .T....JJJJ....T.
    T..............T
''')
JACK_IN = grid('''
    ................
    ..T...JJJJ...T..
    .T.T.JTTJJJ.T.T.
    T..TTJTJJJJTT..T
    ...T.JeJJeJ.T...
    .TT..JJJJJJ..TT.
    T..T..JJJJ..T..T
    ....T......T....
''')


def jack(f):
    """Frames 1 to 4: both sides out, left out and right in, both in, left in and right out."""
    left = JACK_OUT if f in (0, 1) else JACK_IN
    right = JACK_OUT if f in (0, 3) else JACK_IN
    return [l[:8] + r[8:] for l, r in zip(left, right)]


JL = {'J': 'Jack', 'T': 'Jack Light', 'e': 'Text'}
for f in range(4):
    add(Sprite('skitterjack_%d' % (f + 1), jack(f), dict(JL), group='jack', box=(0, 0, 16, 8),
               note='The Skitterjack, frame %d (4 game frames each; the two sides take turns to reach and pull). 16 x 8, the same both ways. Box: the whole 16 x 8.' % (f + 1)))

# ---------------------------------------------------------------- the Moonsnail (the poisoner)
SNAIL = [
    grid('''
        ...BBBB.........
        ..BLLLLB.....e.e
        .BLDDDLB.....f.f
        .BLDLBDLB....f.f
        .BLDDBLB....fff.
        ..BLLLB.ffffffff
        .ffBBBfffffffff.
        ffffffffffffff..
    '''),
    grid('''
        ....BBBB........
        ...BLLLLB.....e.
        ..BLDDDLB....ef.
        ..BLDLBDLB...f.f
        ..BLDDBLB...fff.
        ...BLLLB.ffffff.
        ..ffBBBffffffff.
        .ffffffffffffff.
    '''),
]
NL = {'B': 'Blight', 'L': 'Blight Light', 'D': 'Blight Deep', 'f': 'Snail Foot', 'e': 'Blight Light'}
for i, g in enumerate(SNAIL):
    add(Sprite('moonsnail_%d' % (i + 1), g, dict(NL), group='snail', box=(0, 0, 16, 8),
               note='The Moonsnail crawling right, frame %d (8 game frames each): the foot stretches and the shell rides forward. Mirror it for left. Pale eyes: it cannot hurt the Wick.' % (i + 1)))

# ---------------------------------------------------------------- the strip
def moon(phase):
    """The moon icon, 7 x 7, for wave phase 0 to 5: new, crescent, half, gibbous, full, waning."""
    def f(x, y):
        dx, dy = x - 3.5, y - 3.5
        if dx * dx + dy * dy > 11.5:
            return None
        half = (11.5 - dy * dy) ** 0.5            # the half width of the disc on this row
        t = [None, 0.55, 0.0, -0.55, None, 0.55][phase]
        if phase == 0:
            return 'r' if dx * dx + dy * dy > 6.5 else 'p'
        elif phase == 4:
            lit = True
        elif phase == 5:
            lit = dx < -t * half                   # the waning crescent, lit on the left
        else:
            lit = dx > t * half                    # lit from the right, the terminator moves left
        return 'T' if lit else 'p'
    return SH.render(7, 7, f)


for i in range(6):
    add(Sprite('moon_%d' % (i + 1), moon(i), {'T': 'Text', 'p': 'Plate', 'r': 'Text Dim'}, group='strip',
               note='The moon in the strip for wave %d (and every sixth wave after it).' % (i + 1)))
