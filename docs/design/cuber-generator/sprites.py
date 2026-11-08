"""Every sprite: Pip, the Coil and its seed, the Thorn, the Frost, the moths, the halos and the effects.

Grids use tone digits 1 to 5 for the sprite's colour row (its `row`) and letters for fixed colours.
"""
from lib import Sprite, mirror, flipv
from shapes import layered, to_rows, paint, blank, inside

ALL = {}


def tl(row):
    return {str(i + 1): '%s %d' % (row, i + 1) for i in range(5)}


def add(name, rows, row, extra=None, note='', group='', origin=None, box=None):
    leg = tl(row) if row else {}
    if extra:
        leg.update(extra)
    s = Sprite(name, rows, leg, note=note, group=group, origin=origin, box=box)
    s.row = row
    ALL[name] = s
    return s


PIP_X = {'A': 'Eye', 'B': 'Pupil', 'C': 'Cheek'}

# ======================================================================================================================
# Pip (12 x 14, origin (6, 13): the middle of the feet; box the whole frame)


def pip_body(cy=7.5, rx=6.0, ry=5.6, cx=6.0):
    return layered(12, 14, [(cx, cy, rx, ry)])


def pip(face, pose='stand', eyes='open'):
    """face: 'dr' (down right, we see the face) or 'ur' (up right, we see the back of the head)."""
    if pose == 'stand':
        g = pip_body()
        top, cy = 2, 7
    elif pose == 'crouch':
        g = pip_body(cy=8.7, rx=6.0, ry=4.4)
        top, cy = 4, 8
    elif pose == 'air':
        g = pip_body(cy=6.2, rx=5.0, ry=6.0)
        top, cy = 0, 6
    elif pose == 'land':
        g = pip_body(cy=9.2, rx=6.0, ry=3.9)
        top, cy = 5, 9
    else:
        raise ValueError(pose)
    # the tuft: a little glowing sprout, leaning the way Pip goes (dr) or trailing (ur)
    if pose != 'air':
        if face == 'dr':
            paint(g, 6, top - 2, ['.11', '41.'])
        else:
            paint(g, 4, top - 2, ['11.', '.14'])
    else:
        paint(g, 6 if face == 'dr' else 5, 0, ['1'])
    # the face
    if face == 'dr':
        ex = [5, 8]
        if eyes == 'open':
            e = ['AA', 'AB', 'AB'] if pose != 'land' else ['AA', 'BB']
        elif eyes == 'half':
            e = ['22', 'AB']
        elif eyes == 'shut':
            e = ['22', 'BB']
        elif eyes == 'happy':
            e = ['BB', 'B.']
            e = ['.B', 'B.']
        elif eyes == 'x':
            e = ['B.B'[:2], '.B']
            e = ['BB', 'BB']
        elif eyes == 'wide':
            e = ['AA', 'BA', 'AA']
        ey = cy - 2 if pose != 'land' else cy - 1
        for x in ex:
            paint(g, x, ey, e if eyes != 'happy' else ['.B', 'B.'] if x == ex[0] else ['B.', '.B'])
        if eyes == 'happy':
            for x in ex:
                paint(g, x, ey, ['BB', 'B3'][0:1] + ['..'])
        cheek_y = ey + (3 if eyes in ('open', 'wide') and pose != 'land' else 2)
        paint(g, 3, cheek_y, ['C'])
        paint(g, 10, cheek_y, ['C'])
        if eyes == 'wide':
            paint(g, 7, cheek_y, ['B', 'B'])
        elif pose != 'land':
            paint(g, 7, cheek_y, ['BB'])
    else:
        # back of the head: the eyes peek over the top right
        ey = cy - 4 if pose != 'land' else cy - 3
        if pose == 'air':
            ey = cy - 4
        paint(g, 5, ey, ['AB', 'BB'])
        paint(g, 8, ey, ['AB', 'BB'])
        # a soft back seam, lit edge
        paint(g, 3, cy + 1, ['2'])
    # feet
    fy = 13
    if pose == 'air':
        paint(g, 3 if face == 'dr' else 2, fy - 1, ['.44..44.'])
    elif pose in ('crouch', 'land'):
        paint(g, 1, fy, ['.555..555.'])
    else:
        if face == 'dr':
            paint(g, 2, fy, ['555..555'])
        else:
            paint(g, 2, fy, ['555..555'])
    return to_rows(g)


def pip_simple(rows):
    return rows


PIP_ORIGIN = (6, 13)
for face, nm in (('dr', 'down right'), ('ur', 'up right')):
    add('pip_stand_%s' % face, pip(face), 'Pip', PIP_X, 'Pip standing, facing %s.' % nm, 'pip', PIP_ORIGIN)
add('pip_blink_1', pip('dr', eyes='half'), 'Pip', PIP_X, 'A blink, frame 1 (half shut). Only on the down right facing.', 'pip', PIP_ORIGIN)
add('pip_blink_2', pip('dr', eyes='shut'), 'Pip', PIP_X, 'A blink, frame 2 (shut).', 'pip', PIP_ORIGIN)
for face, nm in (('dr', 'down right'), ('ur', 'up right')):
    add('pip_hop_%s_1' % face, pip(face, 'crouch'), 'Pip', PIP_X, 'Hop %s, frame 1: the crouch (squash).' % nm, 'pip', PIP_ORIGIN)
    add('pip_hop_%s_2' % face, pip(face, 'air'), 'Pip', PIP_X, 'Hop %s, frame 2: in the air (stretch, feet tucked).' % nm, 'pip', PIP_ORIGIN)
    add('pip_hop_%s_3' % face, pip(face, 'land'), 'Pip', PIP_X, 'Hop %s, frame 3: the landing (squash, wider than the crouch).' % nm, 'pip', PIP_ORIGIN)

# falling: a tumble into the void
f1 = pip('dr', 'air', eyes='wide')
add('pip_fall_1', f1, 'Pip', PIP_X, 'Falling, frame 1: eyes wide, mouth open.', 'pip', PIP_ORIGIN)
add('pip_fall_2', [r for r in mirror(pip('ur', 'air'))], 'Pip', PIP_X, 'Falling, frame 2: turned away (the up right back view, mirrored).', 'pip', PIP_ORIGIN)
add('pip_fall_3', flipv(f1)[1:] + ['.' * 12], 'Pip', PIP_X, 'Falling, frame 3: upside down.', 'pip', PIP_ORIGIN)


def small_pip():
    g = layered(12, 14, [(6, 8.5, 4.0, 3.6)])
    paint(g, 4, 7, ['A.A', 'B.B'])
    paint(g, 6, 3, ['1'])
    paint(g, 6, 4, ['4'])
    return to_rows(g)


add('pip_fall_4', small_pip(), 'Pip', PIP_X, 'Falling, frame 4: small and far, about to be gone.', 'pip', PIP_ORIGIN)

# hit: a spin and a flash
hx_ = pip('dr', eyes='x')
add('pip_hit_1', hx_, 'Pip', PIP_X, 'Hit, frame 1: eyes squeezed shut.', 'pip', PIP_ORIGIN)
add('pip_hit_2', pip('ur'), 'Pip', PIP_X, 'Hit, frame 2: spun round (the back view).', 'pip', PIP_ORIGIN)
add('pip_hit_3', mirror(hx_), 'Pip', PIP_X, 'Hit, frame 3: spun to face down left (the mirror of frame 1).', 'pip', PIP_ORIGIN)
add('pip_hit_4', mirror(pip('ur')), 'Pip', PIP_X, 'Hit, frame 4: back view, mirrored. Then the death flash (two frames, tone row swap).', 'pip', PIP_ORIGIN)

# on a halo: riding up, tuft streaming down
def pip_ride(k):
    g = pip_body(cy=7.5)
    paint(g, 5, 3, ['.B..B.'[0:1]])
    paint(g, 5, 5, ['B.', '.B'] if False else ['..'])
    paint(g, 5, 5, ['B'])
    paint(g, 4, 5, ['B'])
    paint(g, 8, 5, ['B'])
    paint(g, 9, 5, ['B'])
    paint(g, 4, 4, ['.'])
    paint(g, 3, 7, ['C'])
    paint(g, 10, 7, ['C'])
    paint(g, 6, 8, ['BB'])
    paint(g, 2, 13, ['555..555'])
    # arms up on frame 2
    if k == 2:
        paint(g, 0, 4, ['5'])
        paint(g, 11, 4, ['5'])
        paint(g, 0, 3, ['4'])
        paint(g, 11, 3, ['4'])
        paint(g, 5, 0, ['.1.', '.4.'])
    else:
        paint(g, 6, 0, ['1', '4'])
    return to_rows(g)


add('pip_ride_1', pip_ride(1), 'Pip', PIP_X, 'On a halo, frame 1: happy eyes (shut arcs).', 'pip', PIP_ORIGIN)
add('pip_ride_2', pip_ride(2), 'Pip', PIP_X, 'On a halo, frame 2: arms up.', 'pip', PIP_ORIGIN)


def pip_win(k):
    rows = pip_ride(2) if k == 2 else pip('dr', 'crouch', eyes='shut')
    g = [list(r) for r in rows]
    if k == 1:
        # happy closed eyes in the crouch
        for x in (5, 6, 8, 9):
            for y in range(4, 10):
                if g[y][x] in 'AB2' and y >= 6:
                    pass
    return [''.join(r) for r in g]


add('pip_win_1', pip('dr', 'crouch', eyes='shut'), 'Pip', PIP_X, 'Winning, frame 1: the crouch, eyes shut with joy.', 'pip', PIP_ORIGIN)
add('pip_win_2', pip_ride(2), 'Pip', PIP_X, 'Winning, frame 2: the jump, arms up (drawn 4 pixels higher, see section 10).', 'pip', PIP_ORIGIN)


def pip_icon():
    g = layered(8, 8, [(4, 4.4, 4.0, 3.6)])
    paint(g, 2, 3, ['A.A', 'B.B'])
    paint(g, 4, 0, ['1'])
    return to_rows(g)


add('pip_icon', pip_icon(), 'Pip', PIP_X, 'A life in the HUD: Pip\'s head.', 'icon', (4, 7))


# ======================================================================================================================
# The Coil (16 x 24, origin (8, 23); the hit box is the 12 x 14 at columns 2 to 13, rows 10 to 23, as Pip's)
COIL_X = {'E': 'Ember', 'F': 'Ember Deep', 'Y': 'Coil Eye', 'W': 'Fang'}
COIL_ORIGIN = (8, 23)


def coil(face, pose='stand'):
    # (cx, cy, rx, ry) back to front: base coil, second coil, neck, head
    lift = {'stand': 0, 'crouch': 3, 'air': -3, 'land': 4}[pose]
    spread = {'stand': 0, 'crouch': -1, 'air': 2, 'land': -2}[pose]
    hx_ = 9.5 if face == 'dr' else 9.0
    base = (8, 20.5, 7.6, 3.4)
    ring = (7.5, 16.5 + lift * 0.5, 6.2, 3.0)
    neck = (6.5, 12.5 + lift * 0.8 - spread, 3.2, 3.6)
    head = (hx_, 6.5 + lift - spread * 1.5, 5.2, 4.6)
    if pose == 'land':
        base = (8, 21.0, 8.0, 3.0)
        ring = (7.5, 17.6, 6.6, 2.8)
    if pose == 'air':
        base = (8, 19.0, 6.4, 3.0)
        ring = (7.5, 15.0, 5.4, 2.8)
        neck = (6.5, 10.5, 3.0, 3.6)
        head = (hx_, 5.6, 5.2, 4.6)
    g = layered(16, 24, [base, ring, neck, head], rim='E', seam='5')
    hy = int(head[1])
    if face == 'dr':
        # horns back, eyes front, jaw open with fangs
        paint(g, 4, hy - 5, ['E...', '.E..'])
        paint(g, 8, hy - 5, ['E..', '.E.'])
        paint(g, 10, hy - 2, ['YY.YY'[0:2]])
        paint(g, 13, hy - 2, ['Y'])
        paint(g, 10, hy - 1, ['5'])
        paint(g, 9, hy + 1, ['.FFFF', '.WFW.'])
    else:
        # the back of the head: horns and a hot ridge, one eye at the far edge
        paint(g, 6, hy - 5, ['E...E', '.E..E'])
        paint(g, 7, hy - 2, ['F', '5', 'F'])
        paint(g, 13, hy - 2, ['Y'])
    # glowing seams: an ember dot on each seam
    out = to_rows(g)
    rows = [list(r) for r in out]
    for j in range(len(rows)):
        n = 0
        for i in range(len(rows[0])):
            if rows[j][i] == '5':
                n += 1
                if n == 3:
                    rows[j][i] = 'F'
    return [''.join(r) for r in rows]


for face, nm in (('dr', 'down right'), ('ur', 'up right')):
    add('coil_stand_%s' % face, coil(face), 'Coil', COIL_X, 'The Coil, standing, facing %s: two coils on the lamp, the head reared over them.' % nm, 'coil', COIL_ORIGIN)
    add('coil_hop_%s_1' % face, coil(face, 'crouch'), 'Coil', COIL_X, 'Hop %s, frame 1: the coils press down.' % nm, 'coil', COIL_ORIGIN)
    add('coil_hop_%s_2' % face, coil(face, 'air'), 'Coil', COIL_X, 'Hop %s, frame 2: in the air, stretched tall.' % nm, 'coil', COIL_ORIGIN)
    add('coil_hop_%s_3' % face, coil(face, 'land'), 'Coil', COIL_X, 'Hop %s, frame 3: the landing, coils spread.' % nm, 'coil', COIL_ORIGIN)


def coil_fall(k):
    if k == 1:
        return coil('dr', 'air')
    if k == 2:
        return flipv(coil('dr', 'stand'))[1:] + ['.' * 16]
    g = layered(16, 24, [(8, 18, 5, 2.4), (8, 14.5, 4, 2.2), (8, 10, 3.6, 3.2)], rim='E', seam='5')
    paint(g, 8, 9, ['Y'])
    return to_rows(g)


add('coil_fall_1', coil_fall(1), 'Coil', COIL_X, 'Falling, frame 1: thrown up (the hop frame 2).', 'coil', COIL_ORIGIN)
add('coil_fall_2', coil_fall(2), 'Coil', COIL_X, 'Falling, frame 2: upside down.', 'coil', COIL_ORIGIN)
add('coil_fall_3', coil_fall(3), 'Coil', COIL_X, 'Falling, frame 3: small and far.', 'coil', COIL_ORIGIN)


# the seed (the Coil before it hatches): 10 x 10, origin (5, 9)
BALL_ORIGIN = (5, 9)


def seed(pose):
    e = {'squash': (5, 6.6, 5.0, 3.4), 'up': (5, 5.0, 4.2, 4.8), 'stretch': (5, 5.0, 3.6, 5.0)}[pose]
    g = layered(10, 10, [e], rim='E')
    cy = int(e[1])
    # a glowing crack across the shell
    if pose == 'squash':
        paint(g, 2, cy, ['F.F.FF'[0:1] + 'F', '..F'])
        paint(g, 2, cy - 1, ['.F.F'])
        paint(g, 5, cy, ['F.F'])
    else:
        paint(g, 2, cy - 1, ['F.', '.F'])
        paint(g, 4, cy, ['F.', '.F'])
        paint(g, 6, cy, ['F', '.'])
        paint(g, 6, cy - 1, ['.F'])
    return to_rows(g)


add('seed_1', seed('squash'), 'Coil', COIL_X, 'The seed, bounce frame 1: squash (on landing).', 'ball', BALL_ORIGIN)
add('seed_2', seed('up'), 'Coil', COIL_X, 'The seed, bounce frame 2: round (in the air).', 'ball', BALL_ORIGIN)
add('seed_3', seed('stretch'), 'Coil', COIL_X, 'The seed, bounce frame 3: stretch (leaving and arriving).', 'ball', BALL_ORIGIN)


def seed_hatch(k):
    g = layered(10, 10, [(5, 5.6, 4.6, 4.2)], rim='E')
    if k == 1:
        paint(g, 1, 4, ['FFFFFFFF'])
    else:
        paint(g, 1, 3, ['E.E.E.E.'])
        paint(g, 1, 4, ['FFFFFFFF'])
        paint(g, 3, 1, ['YY'[0:1] + '.' + 'Y'])
    return to_rows(g)


add('seed_hatch_1', seed_hatch(1), 'Coil', COIL_X, 'Hatching, frame 1: the crack glows all the way round.', 'ball', BALL_ORIGIN)
add('seed_hatch_2', seed_hatch(2), 'Coil', COIL_X, 'Hatching, frame 2: the shell opens and the eyes show. Then the Coil stands.', 'ball', BALL_ORIGIN)


# ======================================================================================================================
# The Thorn (10 x 10, origin (5, 9)): a red ball with spikes
THORN_X = {'W': 'Fang', 'B': 'Pupil'}


THORN = {
    'squash': ['..........',
               '....23....',
               '....34....',
               '..555555..',
               '35W1222354',
               '353B33B354',
               '.54444445.',
               '..555555..',
               '....44....',
               '....45....'],
    'up': ['....23....',
           '....34....',
           '...5555...',
           '..5W1225..',
           '2351223534',
           '335B33B544',
           '..533345..',
           '...5555...',
           '....44....',
           '....45....'],
    'stretch': ['....23....',
                '...5555...',
                '..5W1225..',
                '..512235..',
                '235B33B534',
                '3453333544',
                '..533345..',
                '..543445..',
                '...5555...',
                '....45....'],
}


def thorn(pose):
    return THORN[pose]


add('thorn_1', thorn('squash'), 'Thorn', THORN_X, 'The Thorn, bounce frame 1: squash.', 'ball', BALL_ORIGIN)
add('thorn_2', thorn('up'), 'Thorn', THORN_X, 'The Thorn, bounce frame 2: round, spikes out.', 'ball', BALL_ORIGIN)
add('thorn_3', thorn('stretch'), 'Thorn', THORN_X, 'The Thorn, bounce frame 3: stretch.', 'ball', BALL_ORIGIN)


# ======================================================================================================================
# The Frost (10 x 10, origin (5, 9)): an eight sided ice crystal with a white star, no rim
def frost(pose):
    if pose == 'up':
        h, w, y0 = 10, 10, 0
    elif pose == 'squash':
        h, w, y0 = 8, 10, 2
    else:
        h, w, y0 = 10, 8, 0
    x0 = (10 - w) // 2
    g = blank(10, 10)
    c = 3 if h == 10 and w == 10 else 2
    for j in range(h):
        for i in range(w):
            dj = min(j, h - 1 - j)
            di = min(i, w - 1 - i)
            if di + dj >= c:
                g[y0 + j][x0 + i] = '3'
    # outline, shade, star
    for j in range(10):
        for i in range(10):
            if g[j][i] == '.':
                continue
            nb = [g[j + dy][i + dx] if 0 <= j + dy < 10 and 0 <= i + dx < 10 else '.' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if '.' in nb:
                g[j][i] = '5'
            elif j - y0 > h // 2 + 1 or i - x0 > w - 3:
                g[j][i] = '4'
    my, mx = y0 + h // 2, x0 + w // 2
    for i in range(x0 + 2, x0 + w - 2):
        g[my - 1][i] = '1'
    for j in range(y0 + 2, y0 + h - 2):
        g[j][mx - 1] = '1'
    for (dx, dy) in ((-2, -2), (1, -2), (-2, 1), (1, 1)):
        if g[my - 1 + dy][mx - 1 + dx] in '34':
            g[my - 1 + dy][mx - 1 + dx] = '2'
    g[my - 1][mx - 1] = '1'
    return to_rows(g)


add('frost_1', frost('squash'), 'Frost', None, 'The Frost, bounce frame 1: squash.', 'ball', BALL_ORIGIN)
add('frost_2', frost('up'), 'Frost', None, 'The Frost, bounce frame 2: the whole crystal.', 'ball', BALL_ORIGIN)
add('frost_3', frost('stretch'), 'Frost', None, 'The Frost, bounce frame 3: stretch.', 'ball', BALL_ORIGIN)


def ring(k):
    """The freeze burst, frame k (1 to 6): a flat ring (2 across for 1 down) that spreads, dotted as it fades."""
    rx = 6 + 5 * k
    ry = rx / 2.0
    w, h = 2 * rx + 2, int(2 * ry) + 2
    g = blank(w, h)
    cx, cy = w / 2.0, h / 2.0
    for j in range(h):
        for i in range(w):
            if inside(i, j, cx, cy, rx, ry) and not inside(i, j, cx, cy, rx - 2.2, ry - 1.1):
                if k >= 5 and (i + j) % 2:
                    continue
                g[j][i] = '1' if k <= 2 else ('2' if k <= 4 else '3')
                if j > cy and k <= 4:
                    g[j][i] = '3' if k <= 2 else '4'
    return to_rows(g)


for k in range(1, 7):
    r_ = ring(k)
    add('freeze_ring_%d' % k, r_, 'Frost', None, 'The freeze burst, frame %d: centred on the Frost\'s foot point.' % k, 'fx', (len(r_[0]) // 2, len(r_) // 2))


# ======================================================================================================================
# The moths, Snuff and Puff (12 x 12, origin (6, 11))
MOTH_X = {'K': 'Moth Body', 'A': 'Moth Eye'}
MOTH_ORIGIN = (6, 11)

MOTH = {
    ('dr', 1): [  # crouch: wings folded down
        '............',
        '...5....5...',
        '....5..5....',
        '....KKKK....',
        '....AKKA....',
        '.5555KK5555.',
        '512335K53215',
        '512335K53215',
        '5233335333 5'.replace(' ', '2'),
        '.55545K5455.',
        '....55K55...',
        '...5.K.K.5..'.replace('K', '.'),
    ],
    ('dr', 2): [  # air: wings up
        '55.5....5.55',
        '5125....5215',
        '51235..53215',
        '.5235KKK5325'[0:12],
        '.5335AKKA335'[0:12],
        '..555KKK555.',
        '....5KKK5...',
        '.....KKK....',
        '.....KKK....',
        '......K.....',
        '............',
        '....5...5...',
    ],
    ('dr', 3): [  # land: wings out
        '...5....5...',
        '....5..5....',
        '....KKKK....',
        '55..AKKA..55',
        '5135.KK.5315',
        '51335KK53315',
        '52335KK53325',
        '.5545KK5455.',
        '..515KK515..',
        '..535KK535..',
        '...5.KK.5...',
        '....5..5....',
    ],
}


def moth_back(rows):
    out = []
    for r in rows:
        out.append(r.replace('A', 'K'))
    out = [list(r) for r in out]
    # eye spots on the wings, seen from behind
    for j, r in enumerate(out):
        for i, ch in enumerate(r):
            pass
    return [''.join(r) for r in out]


def moth_spots(rows):
    g = [list(r) for r in rows]
    for j in range(len(g)):
        for i in range(len(g[0])):
            if g[j][i] == '3' and j > 0 and g[j - 1][i] == '3':
                g[j][i] = '1'
                break
    return [''.join(r) for r in g]


for k, word in ((1, 'the crouch, wings folded down'), (2, 'in the air, wings up'), (3, 'the landing, wings out (also standing)')):
    rows = MOTH[('dr', k)]
    rows = [r.ljust(12, '.')[:12] for r in rows]
    add('moth_dr_%d' % k, rows, 'Snuff', MOTH_X, 'A moth hopping down right (we see its face), frame %d: %s. Snuff uses the Snuff row, Puff the Puff row.' % (k, word), 'moth', MOTH_ORIGIN)
    back = moth_spots(moth_back(rows))
    add('moth_ur_%d' % k, back, 'Snuff', MOTH_X, 'A moth hopping up right (we see its back and the eye spots on its wings), frame %d.' % k, 'moth', MOTH_ORIGIN)


# ======================================================================================================================
# Halos (the discs): 24 x 12, origin (12, 6) the middle of the hole, which is where Pip's feet go
HALO_X = {'W': 'Spark'}
HALO_ORIGIN = (12, 6)


def halo(k, dim=False):
    import math
    w, h = 24, 12
    g = blank(w, h)
    cx, cy = 12.0, 6.0
    for j in range(h):
        for i in range(w):
            if inside(i, j, cx, cy, 12, 6) and not inside(i, j, cx, cy, 7.2, 3.0):
                if dim:
                    edge = not inside(i, j, cx, cy, 11, 5)
                    if edge and (i + j) % 2 == 0:
                        g[j][i] = '5'
                    continue
                ang = math.degrees(math.atan2((j + 0.5 - cy) * 2, i + 0.5 - cx)) % 360
                outer = not inside(i, j, cx, cy, 11, 5)
                if outer and j + 0.5 > cy:
                    t = '5'
                elif j + 0.5 < cy - 2:
                    t = '2'
                elif j + 0.5 > cy + 1:
                    t = '4'
                else:
                    t = '3'
                if k:
                    a0 = (k - 1) * 90 + 20
                    d = (ang - a0) % 360
                    if d < 26:
                        t = 'W' if not outer else '1'
                    elif d < 50:
                        t = '1' if t != '5' else t
                g[j][i] = t
    return to_rows(g)


for k in range(1, 5):
    add('halo_%d' % k, halo(k), 'Halo', HALO_X, 'A halo waiting, frame %d: a band of light runs round the ring (a quarter turn a frame).' % k, 'halo', HALO_ORIGIN)


def halo_lift(k):
    rows = [list(r) for r in halo(k * 2 - 1)]
    rows += [list('.' * 24) for _ in range(4)]
    for i in (5, 9, 14, 18) if k == 1 else (3, 7, 11, 16, 20):
        for j in range(12, 12 + (3 if k == 1 else 4)):
            if (j + i) % 2 == 0 or k == 1:
                rows[j][i] = '3' if j < 14 else '4'
    return [''.join(r) for r in rows]


add('halo_lift_1', halo_lift(1), 'Halo', HALO_X, 'A halo lifting off, frame 1: streaks of light below (24 x 16, origin (12, 6) still).', 'halo', HALO_ORIGIN)
add('halo_lift_2', halo_lift(2), 'Halo', HALO_X, 'A halo lifting off, frame 2: longer, dotted streaks. Played in turn while it flies.', 'halo', HALO_ORIGIN)
add('halo_gone', halo(0, dim=True), 'Halo', HALO_X, 'A halo used up: a dotted ghost of the ring in the darkest tone (for 2 seconds, then nothing).', 'halo', HALO_ORIGIN)


# ======================================================================================================================
# effects
FX_X = {'W': 'Spark'}
puff = {
    1: ['..2....2..',
        '.1......1.',
        '..........'],
    2: ['.2......2.',
        '1........1',
        '..........'],
    3: ['2........2',
        '..........',
        '1........1'],
}
for k, rows in puff.items():
    add('puff_%d' % k, rows, 'Mint', FX_X, 'The landing puff, frame %d (10 x 3), centred on the foot point. Tones 1 and 2 of the lamp\'s new state (Mint shown).' % k, 'fx', (5, 1))


def glint(k):
    from scene import top_hw
    g = blank(32, 16)
    sx, sy = 10, 5
    arm = {1: 1, 2: 3, 3: 1}[k]
    for d in range(1, arm + 1):
        c = 'W' if d == 1 and k != 3 else '1'
        for x in (sx - 2 * d, sx - 2 * d + 1, sx + 2 * d, sx + 2 * d + 1):
            if d == arm and x in (sx - 2 * d, sx + 2 * d + 1) and arm > 1:
                continue
            g[sy][x] = c
        g[sy - d][sx] = g[sy - d][sx + 1] = c if d < 3 else '.'
        g[sy + d][sx] = g[sy + d][sx + 1] = c if d < 3 else '.'
    g[sy][sx] = g[sy][sx + 1] = 'W' if k != 3 else '1'
    if k == 1:
        for j in range(8):
            hw = top_hw(j)
            g[j][16 - hw] = g[j][17 - hw] = 'W'
            g[j][15 + hw] = g[j][14 + hw] = 'W'
    if k == 3:
        g[3][22] = '1'
        g[10][23] = '1'
        g[8][5] = '1'
    return to_rows(g)


for k in range(1, 4):
    add('glint_%d' % k, glint(k), 'Mint', FX_X, 'The lamp lit glint, frame %d (32 x 16), drawn with its top left on the cube\'s top left. Tone 1 is the theme\'s done row.' % k, 'fx', (0, 0))

add('shadow', ['.SSSSSS.', 'SSSSSSSS', '.SSSSSS.'], None, {'S': 'Unlit 4'}, 'Pip\'s shadow (8 x 3), centred on the foot point, one row lower. `S` is tone 4 of the row of the lamp it falls on (Unlit shown).', 'fx', (4, 0))
