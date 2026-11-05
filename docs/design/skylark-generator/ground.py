"""The ground targets of Skylark, all original: Cairn, Dish, Burr, Bastion, Beetle, Henge, Hive,
Spire (hidden), Pennant (hidden) and the Citadel (the boss). Each takes the role of one line of
the brief's ground table (see the design file, section 3.4). Every target is drawn facing up."""
import math
from lib import Sprite, grid, rotate
from shapes import render, ball, outline, edge, over, blank, setc, poly_inside

GROUND = {'S': 'Stone', 'M': 'Stone Mid', 'D': 'Stone Dark', 'R': 'Rust', 'L': 'Rust Light',
          'Q': 'Rust Dark', 'Y': 'Signal', 'E': 'Eye', 'K': 'Ink'}


def cairn():
    """Three stepped rings of stone with a rust band, a green eye on top: a tiny ziggurat
    seen from above. Each step is offset up and left so the steps cast shade down and right."""
    def fn(x, y):
        for R, c, off, tone in ((1.5, 8, -1.6, 'E'), (3.0, 8, -1.2, 'S'), (4.6, 8, -0.6, 'R'), (6.6, 8, 0, 'M')):
            dx, dy = x - (c + off), y - (c + off)
            if abs(dx) + abs(dy) <= R * 1.25 and max(abs(dx), abs(dy)) <= R:
                if tone == 'M' and (dx > R - 1.3 or dy > R - 1.3):
                    return 'D'
                if tone == 'R' and (dx > R - 1.1 or dy > R - 1.1):
                    return 'Q'
                if tone == 'R' and (dx < -R + 1.1 or dy < -R + 1.1):
                    return 'L'
                return tone
        return None
    return render(16, 16, fn)


def dish():
    """A small dish aerial on a square footing: the dish is a lit bowl, the feed a green point."""
    base = render(16, 16, lambda x, y: ('D' if (x > 12 or y > 12) else 'M') if 2 < x < 14 and 2 < y < 14 else None)

    def fn(x, y):
        dx, dy = x - 7.5, y - 7
        r = math.hypot(dx * 1.0, dy * 1.25)
        if r < 1.0:
            return 'E'
        if r < 4.4:
            # the bowl: dark at the upper left inside, lit at the lower right inside
            return 'Q' if dx + dy < -1.5 else ('R' if dx + dy < 2.5 else 'L')
        if r < 5.6:
            return 'S' if dx + dy < 1 else 'M'
        return None
    top = render(16, 16, fn)
    top = [list(r) for r in top]
    for y in range(9, 13):          # the feed arm
        top[y][7] = 'D' if top[y][7] == '.' else top[y][7]
    top = [''.join(r) for r in top]
    return over(base, top)


def burr():
    """A ball turret with eight short spines and a green eye that looks at the Lark."""
    def fn(x, y):
        dx, dy = x - 7.5, y - 7.5
        r = math.hypot(dx, dy)
        b = ball(x, y, 7.5, 7.5, 4.8, ('L', 'R', 'Q'))
        if b:
            if abs(dx) < 1.1 and -1.1 < dy < 1.5:
                return 'E'
            return b
        a = (math.degrees(math.atan2(dy, dx)) + 360) % 45
        if r < 7.2 and (a < 7 or a > 38):
            return 'D' if dx + dy > 0 else 'S'
        return None
    return render(16, 16, fn)


BASTION_SRC = grid('''
DDDDDDDDDDDDDDDD
DYSSSSSSSSSSSSYD
DSSMMMMMMMMMMMMD
DSMMDDDDDDDDMMMD
DSMDLLLLLLLRQMMD
DSMDLRRRRRRRQMMD
DSMDLRKEEKRRQMMD
DSMDLRKEEKRRQMMD
DSMDLRRKKRRRQMMD
DSMDLRRRRRRRQMMD
DSMDRQQQQQQQQMMD
DSMMMMMKKMMMMMMD
DSMMMMMKKMMMMMMD
DMMMMMMKKMMMMMMD
DYMMMMMMMMMMMMYD
DDDDDDDDDDDDDDDD
''')


BASTION = [r.replace('Q', 'D') for r in BASTION_SRC]


def bastion():
    return BASTION


def beetle(f):
    """A small crawler with two tracks, a rust shell and a green eye at the front.
    Two frames: the track links move by one cell."""
    rows = []
    for y in range(16):
        r = ''
        for x in range(16):
            dx, dy = x + 0.5 - 8, y + 0.5 - 8.5
            ch = '.'
            if 2 <= x <= 4 or 11 <= x <= 13:
                if 1 <= y <= 14:
                    ch = 'K' if (y + f) % 3 == 0 else ('D' if x in (4, 13) else 'M')
            b = ball(x + 0.5, y + 0.5, 8, 8, 5.2, ('L', 'R', 'Q'))
            if b and 4 <= x <= 11:
                ch = b
                if 6 <= x <= 9 and 3 <= y <= 4:
                    ch = 'E' if x in (7, 8) else 'K'
            r += ch
        rows.append(r)
    return rows


def henge():
    """The tough one: a ring of eight standing stones round a dark pit with a green glow."""
    def fn(x, y):
        dx, dy = x - 8, y - 8
        r = math.hypot(dx, dy)
        if r < 2.2:
            return 'E' if r < 1.1 else 'K'
        if r < 4.2:
            return 'K' if r < 3.2 else 'D'
        a = (math.degrees(math.atan2(dy, dx)) + 360 + 22.5) % 45
        if 4.6 < r < 7.6 and 8 < a < 37:
            return 'S' if (dx + dy) < 0 and r < 6.6 else ('M' if r < 6.6 else 'D')
        if 4.2 <= r < 5.2:
            return 'M'
        return None
    return render(16, 16, fn)


def hive(opened):
    """A domed silo. Closed: a rust hatch in four leaves. Open: a dark mouth with a green glow."""
    def fn(x, y):
        b = ball(x, y, 8, 8, 7.2, ('S', 'M', 'D'))
        if not b:
            return None
        dx, dy = x - 8, y - 8
        r = math.hypot(dx, dy)
        if r < 4.2:
            if opened:
                if r < 1.6:
                    return 'E'
                return 'K' if r < 3.2 else 'Q'
            if abs(dx) < 0.6 or abs(dy) < 0.6:
                return 'Q'
            return 'L' if dx + dy < 0 else 'R'
        if r < 5.0:
            return 'D'
        return b
    return render(16, 16, fn)


def spire(flicker):
    """The hidden tower, a stepped needle seen from above with a signal light on its tip.
    The flicker frame is every other row only: it is shown for 2 frames when the sight passes over."""
    def fn(x, y):
        dx, dy = x - 8, y - 8
        m = (abs(dx) + abs(dy)) * 0.62
        if m < 1.1:
            return 'Y'
        if m < 2.6:
            return 'L' if dx + dy < 0 else 'R'
        if m < 4.6:
            return 'S' if dx + dy < 0 else 'M'
        if m < 6.6:
            return 'M' if dx + dy < 0 else 'D'
        return None
    rows = render(16, 16, fn)
    if flicker:
        rows = [r if y % 2 == 0 else '.' * 16 for y, r in enumerate(rows)]
        rows = [r.replace('M', 'S').replace('D', 'S').replace('R', 'S').replace('L', 'S') for r in rows]
    return rows


PENNANT_1 = grid('''
................
.....D..........
.....DOOOO......
.....DOWWOOO....
.....DOOOOWWOO..
.....DOWWOOOO...
.....DOOOO......
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
....DDD.........
...SSMMM........
................
''')
PENNANT_2 = grid('''
................
.....D..........
.....DOOO.......
.....DOWWOOOO...
.....DOOOWWOOOO.
.....DOWWOOO....
.....DOO........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
....DDD.........
...SSMMM........
................
''')


# ---------------------------------------------------------------- the Citadel
SHELL = {'A': 'Shell Light', 'B': 'Shell', 'C': 'Shell Dark', 'E': 'Core', 'G': 'Core Dark',
         'W': 'Flash', 'Y': 'Signal', 'K': 'Ink'}


def citadel_core(hit=False):
    """A 32 x 32 round fortress: a ring of eight plates round a deep socket, a green core in
    the socket. The core is the target. On 'hit' the core flashes white for 2 frames."""
    def fn(x, y):
        dx, dy = x - 16, y - 16
        r = math.hypot(dx, dy)
        if r > 13.5:
            return None
        a = (math.degrees(math.atan2(dy, dx)) + 360) % 360
        if r < 2.2:
            return 'W'
        if r < 4.6:
            return 'W' if hit else 'E'
        if r < 6.0:
            return 'G'
        if r < 7.0:
            return 'K'
        if r < 7.8:
            return 'C'
        # eight plates with dark seams; lit on the upper left
        if (a % 45) < 3.5:
            return 'C'
        if r > 12.6:
            return 'C'
        lit = (-dx - dy) / (r + 0.01)
        if r < 9.0:
            return 'A' if lit > 0.3 else 'C'
        if 10.2 < r < 11.4 and (a % 45) > 18 and (a % 45) < 27:
            return 'Y'
        return 'A' if lit > 0.45 else ('B' if lit > -0.65 else 'C')
    return render(32, 32, fn)


def petal(state):
    """A shield plate, 16 x 12, drawn for the north side (convex side up). The east, south and west
    plates are quarter turns of it. state: 'whole', 'cracked'."""
    def fn(x, y):
        dx, dy = x - 8, y - 13
        r = math.hypot(dx, dy)
        if 7.0 < r < 12.6 and abs(dx) < 7.6 and dy < 0:
            if r > 11.6:
                return 'C'
            if r < 8.0:
                return 'K'
            if abs(dx) < 1.1 and 9.0 < r < 10.6:
                return 'Y'
            return 'A' if dx < -1.5 else ('B' if dx < 3.5 else 'C')
        return None
    rows = render(16, 12, fn)
    if state == 'cracked':
        rows = [list(r) for r in rows]
        for x, y in ((4, 3), (5, 4), (5, 5), (6, 6), (7, 6), (11, 2), (10, 3), (10, 4)):
            if rows[y][x] != '.':
                rows[y][x] = 'K'
        for x, y in ((6, 5), (10, 2)):
            rows[y][x] = 'W'
        rows = [''.join(r) for r in rows]
    return rows


# ---------------------------------------------------------------- scorch marks
def scorch(rows, big=False):
    """The destroyed version of a target: the burnt ground in the target's footprint grown by
    one cell, a ragged rim, and a few cells of the target's own dark parts left as rubble."""
    h, w = len(rows), len(rows[0])
    fill = [[rows[y][x] != '.' for x in range(w)] for y in range(h)]
    out = [['.'] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            near = any(0 <= y + j < h and 0 <= x + i < w and fill[y + j][x + i]
                       for j in (-1, 0, 1) for i in (-1, 0, 1))
            if not near:
                continue
            n = (x * 7 + y * 13 + (x * y) % 5) % 11
            on_edge = not fill[y][x]
            if on_edge:
                out[y][x] = 'Z' if n < 6 else '.'
            else:
                out[y][x] = 'X'
                if rows[y][x] in 'DQKCG' and n < 3:
                    out[y][x] = 'D'
                elif n == 4:
                    out[y][x] = 'Z'
    return [''.join(r) for r in out]


SCORCH = {'X': 'Scorch', 'Z': 'Scorch Edge', 'D': 'Smoke'}


def sprites():
    out = []
    T = [
        ('cairn', cairn(), 'Cairn: three stepped rings of stone with a rust band and a green eye on top.', (2, 2, 12, 12)),
        ('dish', dish(), 'Dish: a dish aerial on a square footing. Stands beside the road.', (2, 2, 12, 12)),
        ('burr', burr(), 'Burr: a ball turret with eight spines. Its eye is the muzzle.', (3, 3, 10, 10)),
        ('bastion', bastion(), 'Bastion: a square bunker, a signal light at each corner, an armoured hatch with a green sight and a gun slot pointing down at the Lark.', (1, 1, 14, 14)),
        ('beetle_1', beetle(0), 'Beetle, frame 1 of 2 (track links move every 4 frames). Facing up; it is drawn turned by quarter turns to face its way along the road.', (2, 1, 12, 14)),
        ('beetle_2', beetle(1), 'Beetle, frame 2.', (2, 1, 12, 14)),
        ('henge', henge(), 'Henge: the tough one, eight standing stones round a dark pit.', (1, 1, 14, 14)),
        ('hive_closed', hive(False), 'Hive, closed.', (1, 1, 14, 14)),
        ('hive_open', hive(True), 'Hive, open: shown for 20 frames before a Wisp rises out of it.', (1, 1, 14, 14)),
    ]
    for name, rows, note, box in T:
        out.append(Sprite(name, rows, GROUND, note + ' Box %d x %d at (%d, %d).' % (box[2], box[3], box[0], box[1]), box=box, group='ground'))
    for name, rows, note, box in T:
        if name in ('beetle_2', 'hive_open'):
            continue
        base = name.split('_')[0]
        out.append(Sprite(base + '_scorch', scorch(rows), SCORCH,
                          'What is left of the %s: drawn on the ground layer where it stood, stays until it scrolls off.' % base.capitalize(), group='scorch'))
    out.append(Sprite('spire', spire(False), GROUND, 'Spire, revealed: drawn for 24 frames, then it bursts (ground burst) and leaves spire_scorch. Box 12 x 12 at (2, 2), the same box the bomb has to hit while it is hidden.', box=(2, 2, 12, 12), group='ground'))
    out.append(Sprite('spire_flicker', spire(True), GROUND, 'Spire, the flicker: every other row, all Stone. Drawn on 2 frames out of every 16 while the sight\'s centre cell is inside its box.', box=(2, 2, 12, 12), group='ground'))
    out.append(Sprite('spire_scorch', scorch(spire(False)), SCORCH, 'What is left of the Spire.', group='scorch'))
    pl = {'D': 'Stone Dark', 'S': 'Stone', 'M': 'Stone Mid', 'O': 'Wing Mark', 'W': 'Hull'}
    out.append(Sprite('pennant_1', PENNANT_1, pl, 'Pennant, frame 1 of 2 (8 frames each). It appears where the hidden spot was bombed and waits; flying over it collects it. Box 10 x 14 at (3, 1).', box=(3, 1, 10, 14), group='ground'))
    out.append(Sprite('pennant_2', PENNANT_2, pl, 'Pennant, frame 2.', box=(3, 1, 10, 14), group='ground'))
    out.append(Sprite('citadel_core', citadel_core(), SHELL, 'The Citadel core, 32 x 32. The bomb has to land in the core box, 10 x 10 at (11, 11). The plates take no damage.', box=(11, 11, 10, 10), group='boss'))
    out.append(Sprite('citadel_core_hit', citadel_core(True), SHELL, 'The core, hit: the eye goes white for 2 frames, then the Citadel breaks up (section 4).', box=(11, 11, 10, 10), group='boss'))
    out.append(Sprite('shield_n', petal('whole'), SHELL, 'A shield plate, the north one. East, south and west are this turned 1, 2 and 3 quarter turns clockwise. Each sits 1 cell off the core\'s rim. A shield is an air target: Zapper hits crack it.', box=(1, 1, 14, 10), group='boss'))
    out.append(Sprite('shield_n_cracked', petal('cracked'), SHELL, 'The plate after its first hit: dark cracks, two white sparks. The second hit breaks it off (section 4).', box=(1, 1, 14, 10), group='boss'))
    return out
