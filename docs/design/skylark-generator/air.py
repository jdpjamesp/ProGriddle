"""The air enemies of Skylark, all original: Whirl, Skate, Kite, Glint, Midge, Wisp, Swift, Anvil.
Each takes the role of one line of the brief's air table (see the design file, section 3.3)."""
import math
from lib import Sprite, grid, mirror
from shapes import render, ball, outline, edge, over, poly_inside, blank, setc

AIR = {'P': 'Plum', 'L': 'Plum Light', 'D': 'Plum Dark', 'S': 'Steel', 'E': 'Eye'}


def whirl(frame):
    """A three bladed seed spinner. 3 fold, so 4 frames of 30 degrees make the whole turn."""
    th = math.radians(frame * 30 - 90)

    def fn(x, y):
        cx, cy = 8, 8
        dx, dy = x - cx, y - cy
        r = math.hypot(dx, dy)
        if r < 1.0:
            return 'E'
        if r < 2.4:
            return 'S'
        for k in range(3):
            a = th + k * 2 * math.pi / 3
            ux, uy = math.cos(a), math.sin(a)
            al = dx * ux + dy * uy - 4.3
            ac = -dx * uy + dy * ux
            # a blade curves back: its across offset grows with the distance out
            ac -= al * 0.35
            if (al / 3.8) ** 2 + (ac / 1.9) ** 2 <= 1:
                if ac > 0.7:
                    return 'L'
                if ac < -0.9:
                    return 'D'
                return 'P'
        return None
    return render(16, 16, fn)


SKATE_FLAT = grid('''
................
................
.......DD.......
......DLLD......
.....DLLLLD.....
...DDLLPPLLDD...
.DDLLPPEEPPLLDD.
DLLLPPPPPPPPLLLD
DPPPPPDPPDPPPPPD
.DDPPDDPPDDPPDD.
...DD.DPPD.DD...
.......DD.......
.......SD.......
.......SD.......
........D.......
................
''')


def skate(f):
    """A flat ray glider. f: 'flat', 'dive' (wings swept back, nose down) or 'rise' (wings spread up)."""
    if f == 'flat':
        return SKATE_FLAT
    rows = [list(r) for r in SKATE_FLAT]
    if f == 'dive':
        # the wing tips swing back by one row: draw the wings one row lower at the tips
        out = blank(16, 16)
        out = [list(r) for r in out]
        for y in range(16):
            for x in range(16):
                ch = SKATE_FLAT[y][x]
                if ch == '.':
                    continue
                yy = y + (1 if (x < 4 or x > 11) else 0)
                if yy < 16:
                    out[yy][x] = ch if not (x < 4 or x > 11) else ('D' if ch == 'L' else ch)
        return [''.join(r) for r in out]
    out = [list('.' * 16) for _ in range(16)]
    for y in range(16):
        for x in range(16):
            ch = SKATE_FLAT[y][x]
            if ch == '.':
                continue
            yy = y - (1 if (x < 4 or x > 11) else 0)
            out[yy][x] = 'L' if (x < 4 or x > 11) and ch == 'P' else ch
    return [''.join(r) for r in out]


def kite(sx):
    """A flipping kite with a short tail. sx is how wide it is (1 face on, negative is its back)."""
    back = sx < 0
    s = abs(sx)

    def fn(x, y):
        dx, dy = x - 7.5, y - 6.5
        if s > 0.05 and abs(dx) / (6.5 * s) + abs(dy) / (6.5 if dy < 0 else 7.0) <= 1:
            if abs(dx) < 0.6 or abs(dy) < 0.6:
                return 'S'
            if back:
                return 'D'
            if 0.6 < abs(dx) < 1.6 and 0.6 < abs(dy) < 1.6:
                return 'E'
            return 'L' if (dy < 0) == (dx < 0) else 'P'
        if s <= 0.2 and abs(dx) < 0.6 and -6.5 < dy < 7:
            return 'S'
        return None
    rows = render(16, 16, fn)
    rows = [list(r) for r in rows]
    for y, x in ((14, 7), (15, 8)):
        rows[y][x] = 'D'
    return [''.join(r) for r in rows]


def glint(sy):
    """A mirror shard: a long hexagon that turns about its middle line. Face on it is a mirror
    (Steel with a white glare stripe); edge on it is a bar; its back is plum."""
    back = sy < 0
    s = abs(sy)

    def fn(x, y):
        dx, dy = x - 8, y - 8
        hy = 6.5 * s
        if s < 0.2:
            return 'S' if abs(dy) < 0.6 and abs(dx) < 6.6 else None
        # a hexagon 13 wide, pointed at left and right
        if abs(dy) > hy or abs(dx) > 6.6 - abs(dy) / hy * 2.6:
            return None
        if back:
            return 'D' if abs(dy) > hy - 1 or abs(dx) > 5.2 - abs(dy) / hy * 2.6 else 'P'
        if abs(dx) > 5.4 - abs(dy) / hy * 2.6 or abs(dy) > hy - 1:
            return 'P'
        if abs(dx + dy * 1.1 - 1) < 1.0:
            return 'W'
        return 'S'
    return render(16, 16, fn)


MIDGE_1 = grid('''
............
....S..S....
...SS..SS...
..SSS.LSSS..
...SSPLSS...
.....PE.....
....SPPS....
...SSPDSS...
..SSS.DSSS..
......D.....
......D.....
............
''')
MIDGE_2 = grid('''
............
............
............
.....LL.....
.SSSSPLSSSS.
..SSSPEPSS..
.....PP.....
..SSSPDSSS..
.SSSS.DSSSS.
......D.....
......D.....
............
''')


def wisp(f):
    """A glowing orb in a plum cage. f 1: arriving (a spark), 2: whole, 3: about to burst."""
    def fn(x, y):
        dx, dy = x - 8, y - 8
        r = math.hypot(dx, dy)
        if f == 1:
            if r < 1.6:
                return 'W'
            if r < 2.8 and (abs(dx) < 0.6 or abs(dy) < 0.6):
                return 'E'
            return None
        R = 5.6 if f == 2 else 6.6
        if r < 1.4:
            return 'W'
        if r < R - 2.2:
            return 'E'
        if r < R - 1.1:
            a = math.degrees(math.atan2(dy, dx)) % 90
            return 'P' if (a < 18 or a > 72) else ('G' if f == 2 else 'E')
        if r < R:
            a = math.degrees(math.atan2(dy, dx)) % 45
            return 'D' if a < 22 else 'L'
        return None
    return render(16, 16, fn)


SWIFT_1 = grid('''
............
.L........L.
.LP......PL.
..LP....PL..
..LPP..PPL..
...LPPPPL...
...DPEEPD...
....DPPD....
....DPPD....
.....DD.....
.....SS.....
.....S......
''')
SWIFT_2 = grid('''
............
............
L..........L
LP........PL
.LPP....PPL.
..LPPPPPPL..
...DPEEPD...
....DPPD....
....DPPD....
.....DD.....
.....SS.....
......S.....
''')

IRON = {'I': 'Iron', 'J': 'Iron Light', 'K': 'Iron Edge'}


def anvil(k):
    """A heavy iron plate, a hexagon with six bolts, turning on its upright axis: 6 frames,
    k = 0..5 is 0, 30, ..., 150 degrees. Its back (k 3 to 5) is ribbed, so the turn reads."""
    a = math.radians(k * 30)
    sx = math.cos(a)
    back = sx < -0.01 or k >= 3
    s = abs(sx)
    if k == 3:
        s = 0.12

    def fn(x, y):
        dx, dy = x - 8, y - 8
        if s < 0.2:
            if abs(dx) < 1.1 and abs(dy) < 7:
                return 'J' if dx < 0 else 'K'
            return None
        ux = dx / s
        # a pointy topped hexagon of radius 7
        if abs(dy) > 7 or abs(ux) > 6.1 or abs(ux) * 0.5 + abs(dy) * 0.866 > 6.1:
            return None
        rim = abs(dy) > 6.0 or abs(ux) > 5.1 or abs(ux) * 0.5 + abs(dy) * 0.866 > 5.1
        if rim:
            return 'J' if (dx < 0 and dy < 2) or dy < -5 else 'K'
        if back:
            return 'K' if abs(dy) % 3 < 0.9 else 'I'
        for bx, by in ((0, -4.2), (3.6, -2.1), (3.6, 2.1), (0, 4.2), (-3.6, 2.1), (-3.6, -2.1)):
            if abs(ux - bx) < 0.9 / max(s, 0.5) and abs(dy - by) < 0.8:
                return 'K'
        if abs(dy) < 1.5 and abs(ux) < 1.5:
            return 'J'
        return 'I'
    return render(16, 16, fn)


BULLET_1 = grid('''
.....
..H..
.HCH.
..H..
.....
''')
BULLET_2 = grid('''
..H..
.HCH.
HCCCH
.HCH.
..H..
''')


def sprites():
    out = []
    for f in range(4):
        out.append(Sprite('whirl_%d' % (f + 1), whirl(f), AIR,
                          'Whirl, frame %d of 4 (the blades %d degrees on). 3 frames each, so it turns once in 12 frames and looks like a seed spinning down.' % (f + 1, f * 30) if f == 0 else 'Whirl, frame %d of 4 (%d degrees).' % (f + 1, f * 30),
                          box=(2, 2, 12, 12), group='air'))
    for f, n in (('flat', 'Skate, gliding (also its frame when it turns back up and leaves).'),
                 ('dive', 'Skate, diving: the wing tips sweep back one row and go dark.'),
                 ('rise', 'Skate, pulling out: the wing tips lift one row and catch the light.')):
        out.append(Sprite('skate_' + f, skate(f), AIR, n + ' Box 14 x 8 at (1, 4).', box=(1, 4, 14, 8), group='air'))
    for i, (sx, n) in enumerate(((1, 'face on, the eye open'), (0.55, 'turning'), (0.12, 'edge on: a stick'), (-0.55, 'its back: no eye'))):
        out.append(Sprite('kite_%d' % (i + 1), kite(sx), AIR, 'Kite, frame %d of 4: %s. It fires as it reaches frame 3. Box 10 x 12 at (3, 1).' % (i + 1, n), box=(3, 1, 10, 12), group='air'))
    leg = dict(AIR)
    leg['W'] = 'Flash'
    for i, (sy, n) in enumerate(((1, 'face on: a mirror with a white glare'), (0.5, 'tipping'), (0.1, 'edge on: a line'), (-0.5, 'its plum back'))):
        out.append(Sprite('glint_%d' % (i + 1), glint(sy), leg, 'Glint, frame %d of 4: %s. Box 12 x 12 at (2, 2) on every frame (it is the same mirror).' % (i + 1, n), box=(2, 2, 12, 12), group='air'))
    out.append(Sprite('midge_1', MIDGE_1, AIR, 'Midge, wings up. 12 x 12. 2 frames each. Box 4 x 8 at (4, 2): only the body, which is why it is hard to hit.', box=(4, 2, 4, 8), group='air'))
    out.append(Sprite('midge_2', MIDGE_2, AIR, 'Midge, wings down.', box=(4, 2, 4, 8), group='air'))
    leg = dict(AIR)
    leg['W'] = 'Flash'
    leg['G'] = 'Core Dark'
    for f, n in ((1, 'arriving: a spark where it will be (no box yet, 8 frames)'), (2, 'whole, the cage turning slowly (swap with frame 3 every 6 frames)'), (3, 'about to burst: the cage glows, 12 frames, then the ring of bullets')):
        out.append(Sprite('wisp_%d' % f, wisp(f), leg, 'Wisp, %s. Box 10 x 10 at (3, 3) on frames 2 and 3.' % n, box=(3, 3, 10, 10), group='air'))
    out.append(Sprite('swift_1', SWIFT_1, AIR, 'Swift, wings in. 12 x 12, nose down, rushing the Lark. 2 frames each. Box 6 x 8 at (3, 3).', box=(3, 3, 6, 8), group='air'))
    out.append(Sprite('swift_2', SWIFT_2, AIR, 'Swift, wings out.', box=(3, 3, 6, 8), group='air'))
    for k in range(6):
        out.append(Sprite('anvil_%d' % (k + 1), anvil(k), IRON,
                          'Anvil, frame %d of 6 (%d degrees). %s' % (k + 1, k * 30, 'Iron only: no Plum, no Eye. The dark, heavy, unlit look says it cannot be killed. 4 frames each. Box 12 x 14 at (2, 1) on every frame, so shots stop on it even edge on.' if k == 0 else ''),
                          box=(2, 1, 12, 14), group='air'))
    hot = {'H': 'Hot', 'C': 'Hot Core'}
    out.append(Sprite('bullet_1', BULLET_1, hot, 'Enemy bullet, frame 1 of 2 (2 frames each). Box 3 x 3 at (1, 1). Every enemy shot in the game is this, in Hot.', box=(1, 1, 3, 3), group='air'))
    out.append(Sprite('bullet_2', BULLET_2, hot, 'Enemy bullet, frame 2: the flare. Same box.', box=(1, 1, 3, 3), group='air'))
    return out
