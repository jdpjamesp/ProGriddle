"""The four phantoms (Mary, Rich, Brian, Chip): wisp bodies, eyes, marks, the rolled back and returning looks."""
from lib import Sprite, shade

# Body masks, 16 x 16. The head is a dome, the body tapers into a tail that swishes.
# Rows 0 and 1 are kept free for the marks (antenna, hat, bow).
BODY_A = [
    "................",
    "................",
    ".....######.....",
    "...##########...",
    "..############..",
    ".##############.",
    ".##############.",
    ".##############.",
    ".##############.",
    ".##############.",
    "..############..",
    "..###########...",
    "...########.....",
    "..######........",
    ".#####..........",
    ".###............",
]
BODY_B = [
    "................",
    "................",
    ".....######.....",
    "...##########...",
    "..############..",
    ".##############.",
    ".##############.",
    ".##############.",
    ".##############.",
    ".##############.",
    "..############..",
    "...###########..",
    ".....########...",
    "........######..",
    "..........#####.",
    "............###.",
]

# The rolled back body: lower, wider, melting into three drips. No tail.
ROLLEDBACK_A = [
    "................",
    "................",
    "................",
    ".....######.....",
    "...##########...",
    "..############..",
    ".##############.",
    ".##############.",
    "################",
    "################",
    "################",
    ".##############.",
    ".###.######.###.",
    ".##...####...##.",
    "..#....##....#..",
    "................",
]
ROLLEDBACK_B = [
    "................",
    "................",
    "................",
    ".....######.....",
    "...##########...",
    "..############..",
    ".##############.",
    ".##############.",
    "################",
    "################",
    "################",
    ".##############.",
    "..####.##.####..",
    "..###..##..###..",
    "...#...##...#...",
    ".......#........",
]

# Faces drawn on the rolled back body (a letter for the face colour, '.' leaves the body).
ROLLEDBACK_FACE = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "....FF....FF....",
    "....FF....FF....",
    "................",
    "...F.FF..FF.F...",
    "..F...FFFF...F..",
    "................",
    "................",
    "................",
    "................",
    "................",
]


def tone_body(mask):
    return shade(mask, {'#': ('T',)})


def with_face(rows, face, letter):
    out = []
    for r, f in zip(rows, face):
        out.append(''.join(letter if fc == 'F' and rc != '.' else rc for rc, fc in zip(r, f)))
    return out


# Eyes: a pair, drawn on the body at its top left (the eye sprite is 16 x 16 too, same origin).
# Each eye is 3 wide and 4 tall; the pupil (2 x 2) sits on the side the phantom is moving to.
def eyes(direction, big=False):
    rows = [['.'] * 16 for _ in range(16)]
    ex = (3, 9) if not big else (2, 9)
    ey = 5 if not big else 5
    w, h = (4, 4) if not big else (5, 5)
    # the whites shift one pixel the way the phantom looks
    sx = {'left': -1, 'right': 1, 'up': 0, 'down': 0}[direction]
    sy = {'left': 0, 'right': 0, 'up': -1, 'down': 1}[direction]
    for x0 in ex:
        x0 += sx
        y0 = ey + sy
        for y in range(h):
            for x in range(w):
                corner = (x in (0, w - 1)) and (y in (0, h - 1))
                if not corner:
                    rows[y0 + y][x0 + x] = 'E'
        # pupil
        px = {'left': 0, 'right': w - 2, 'up': (w - 2) // 2, 'down': (w - 2) // 2}[direction]
        py = {'left': (h - 2) // 2, 'right': (h - 2) // 2, 'up': 0, 'down': h - 2}[direction]
        for y in range(2):
            for x in range(2):
                rows[y0 + py + y][x0 + px + x] = 'P'
    return [''.join(r) for r in rows]


# Marks: overlays, 16 x 16 with the same origin as the body. Letters only.
MARK_BRIAN = [  # glasses: two square rims round the eyes and a bridge
    "................",
    "................",
    "................",
    "................",
    "..KKKKKK.KKKKKK.",
    "..K....KKK....K.",
    "..K....K.K....K.",
    "..K....K.K....K.",
    "..K....K.K....K.",
    "..KKKKKK.KKKKKK.",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]
MARK_MARY = [  # a bow on the top right of the head
    "........W.....W.",
    "........WW...WW.",
    "........W5WKW5W.",
    "........WW...WW.",
    "........W.....W.",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]
MARK_CHIP = [  # an antenna with a little chip on top
    "......QQQQ......",
    ".....RQQQQR.....",
    ".......RR.......",
    ".......RR.......",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]
MARK_RICH = [  # a top hat (sits on the dome) and heavy eyelids over the top half of the eyes
    "....UUUUUUU.....",
    "....XXXXXXX.....",
    "....HHHHHHH.....",
    "..UUUUUUUUUUU...",
    "................",
    "..LLLLL..LLLLL..",
    "..LLLLL..LLLLL..",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]
# Mary angry (the speed up when the data runs low). Stage 1: brows. Stage 2: brows and a steam puff.
# The brows are drawn after her bow, so the right brow sits over its lower left loop.
ANGRY_1 = [
    "................",
    "................",
    "................",
    "...KK.......KK..",
    ".....KKK.KKK....",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]
ANGRY_2 = [
    ".SS.............",
    "SS..............",
    ".SS.............",
    "...KK.......KK..",
    ".....KKK.KKK....",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]

MARK_NOTES = {
    'Brian': 'Glasses: two square rims and a bridge, drawn over his eyes (the eyes move inside the rims).',
    'Mary': 'A bow on the top right of her head.',
    'Chip': 'An antenna with a little chip on top (pins either side).',
    'Rich': 'A top hat on his dome and heavy eyelids that cover the top row of his eyes, so he always looks half asleep.',
}

LEG = {'E': 'Eye', 'P': 'Pupil', 'K': 'Ink', 'F': 'Rolledback Face', 'W': 'Bow', 'Q': 'Chip Body', 'R': 'Chip Pin',
       'H': 'Hat Band', 'S': 'Steam', 'A': 'Angry'}


def build():
    out = []
    out.append(Sprite('phantom_body_1', tone_body(BODY_A), tone='Mary', origin=(8, 8), group='phantom',
                      note='The body, swish 1 (tail to the left). Drawn in each phantom\'s colour row; the same body for all four.'))
    out.append(Sprite('phantom_body_2', tone_body(BODY_B), tone='Mary', origin=(8, 8), group='phantom',
                      note='The body, swish 2 (tail to the right).'))
    for d in ('right', 'left', 'up', 'down'):
        out.append(Sprite('phantom_eyes_%s' % d, eyes(d), legend={'E': 'Eye', 'P': 'Pupil'}, origin=(8, 8), group='eyes',
                          note='The eyes looking %s. Drawn over the body at the same origin.' % d))
    marks = (('mark_brian', MARK_BRIAN, {'K': 'Ink'}), ('mark_mary', MARK_MARY, {'W': 'Bow', 'K': 'Ink'}),
             ('mark_chip', MARK_CHIP, {'Q': 'Chip Body', 'R': 'Chip Pin'}),
             ('mark_rich', MARK_RICH, {'X': 'Hat', 'U': 'Hat Top', 'H': 'Hat Band', 'L': None}))
    for name, rows, leg in marks:
        who = name.split('_')[1].capitalize()
        tone = None
        rr = rows
        if 'W' in leg:   # Mary's bow: pale pink with her own tone 5 inside and an Ink knot
            leg = {'W': 'Bow', 'K': 'Ink'}
            tone = 'Mary'
        if 'L' in leg:   # Rich's lids are his own tone 4
            rr = [r.replace('L', '4') for r in rows]
            leg = {'X': 'Hat', 'U': 'Hat Top', 'H': 'Hat Band'}
            tone = 'Rich'
        out.append(Sprite(name, rr, tone=tone, legend=leg, origin=(8, 8), group='mark', note=MARK_NOTES[who]))
    out.append(Sprite('mary_angry_1', ANGRY_1, legend={'K': 'Ink'}, origin=(8, 8), group='mark',
                      note='Mary angry, stage 1 (the first speed up): slanted brows, drawn after her bow.'))
    out.append(Sprite('mary_angry_2', ANGRY_2, legend={'K': 'Ink', 'S': 'Steam'}, origin=(8, 8), group='mark',
                      note='Mary angry, stage 2 (the second speed up): the brows, a steam puff on the side away from her bow, and her pupils are drawn in Angry red.'))
    sa = with_face(tone_body(ROLLEDBACK_A), ROLLEDBACK_FACE, 'F')
    sb = with_face(tone_body(ROLLEDBACK_B), ROLLEDBACK_FACE, 'F')
    out.append(Sprite('rolledback_1', sa, tone='Rollback', legend={'F': 'Rolledback Face'}, origin=(8, 8), group='rolledback',
                      note='Rolled back, wobble 1: lower and wider than a phantom, melting into drips, with pinpoint eyes and a wavy mouth. No marks, no tail.'))
    out.append(Sprite('rolledback_2', sb, tone='Rollback', legend={'F': 'Rolledback Face'}, origin=(8, 8), group='rolledback',
                      note='Rolled back, wobble 2: the drips change.'))
    out.append(Sprite('flash_1', [r.replace('F', 'G') for r in sa], tone='Flash', legend={'G': 'Flash Face'}, origin=(8, 8), group='rolledback',
                      note='Flashing, wobble 1: the rolled back body in the Flash row, red face.'))
    out.append(Sprite('flash_2', [r.replace('F', 'G') for r in sb], tone='Flash', legend={'G': 'Flash Face'}, origin=(8, 8), group='rolledback',
                      note='Flashing, wobble 2.'))
    for d in ('right', 'left', 'up', 'down'):
        out.append(Sprite('returning_%s' % d, eyes(d, big=True), legend={'E': 'Eye', 'P': 'Pupil'}, origin=(8, 8), group='returning',
                          note='Returning to the lobby, looking %s: only the eyes, a size bigger than the normal eyes.' % d))
    return out


ALL = {s.name: s for s in build()}


def phantom_layers(who, swish=0, look='right', angry=0):
    """The sprites to draw for a normal phantom, back to front, and their colour row."""
    L = [(ALL['phantom_body_%d' % (swish + 1)], who), (ALL['phantom_eyes_%s' % look], None)]
    if who == 'Mary' and angry == 2:
        L[1] = (ALL['phantom_eyes_%s' % look], 'angry')
    L.append((ALL['mark_%s' % who.lower()], None))
    if who == 'Mary' and angry:
        L.append((ALL['mary_angry_%d' % angry], None))
    return L
