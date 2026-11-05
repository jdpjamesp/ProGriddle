"""The ground tile set: 16 x 16 tiles made from a few rules, so the joins always meet.

Tile letters are kept abstract so one tile serves both ground families:
  g ground, l ground light, d ground dark      (Meadow... in green areas, Ochre... in dry areas)
  e Earth, p Pad, s Stone Dark (pad joints)
  c Canopy, k Canopy Light, n Canopy Dark, u Understory
  w River, r River Light, v River Dark, f Foam
  a Road, b Road Edge, y Road Line
  h Ochre Light (the land lines, the same in both families)
"""
import math

FAMILIES = {
    'green': {'g': 'Meadow', 'l': 'Meadow Light', 'd': 'Meadow Dark'},
    'dry': {'g': 'Ochre', 'l': 'Ochre Light', 'd': 'Ochre Dark'},
}
COMMON = {
    'e': 'Earth', 'p': 'Pad', 's': 'Stone Dark',
    'c': 'Canopy', 'k': 'Canopy Light', 'n': 'Canopy Dark', 'u': 'Understory',
    'w': 'River', 'r': 'River Light', 'v': 'River Dark', 'f': 'Foam',
    'a': 'Road', 'b': 'Road Edge', 'y': 'Road Line', 'h': 'Ochre Light',
}


def legend(family):
    m = dict(COMMON)
    m.update(FAMILIES[family])
    return m


def h32(x, y, seed):
    n = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n ^ (n >> 16)) & 0xFFFF


def blank():
    return [['g'] * 16 for _ in range(16)]


def rows_of(t):
    return [''.join(r) for r in t]


# ---------------------------------------------------------------- open ground
def open_ground(variant):
    """Three variants. Tufts are a light cell over a dark cell; variant 3 has a few earth stones."""
    t = blank()
    seed = 11 + variant * 7
    spots = [(x, y) for y in range(1, 15) for x in range(1, 15) if h32(x, y, seed) % 23 == 0]
    for x, y in spots:
        t[y][x] = 'l'
        t[y + 1][x] = 'd'
    for y in range(16):
        for x in range(16):
            if t[y][x] == 'g' and h32(x, y, seed + 3) % 29 == 0:
                t[y][x] = 'd'
    if variant == 3:
        for x, y in ((4, 5), (10, 11), (11, 11), (12, 3)):
            t[y][x] = 'e'
            if t[y - 1][x] == 'g':
                t[y - 1][x] = 'l'
    if variant == 2:   # a faint mown stripe pair, runs edge to edge so tiles join
        for x in range(16):
            if t[7][x] == 'g':
                t[7][x] = 'l' if x % 4 else 'g'
    return rows_of(t)


# ---------------------------------------------------------------- forest
CANOPY = [
    # 16 x 16 tiling roof of crowns: k lit, c body, n between crowns. Repeats with no seam.
    'nckkcnncckkcnnck',
    'ckkkccnckkkccnck',
    'ckkcccnckkcccnck',
    'cccccnnccccc nnc'.replace(' ', 'n'),
    'nccccnnnccccnnnn',
    'nnccnnckkcnnnckk',
    'nnnnnckkkccnckkk',
    'cknnnckkcccnckkc',
    'kkcnncccccnncccc',
    'kkccnnccccnnnccc',
    'cccccnnccnnnnncc',
    'ccccnnnnnnckkcnn',
    'nccnnckkcnckkkcn',
    'nnnnckkkccccccnn',
    'cknnckkccccccnnc',
    'kkcnncccccnnnnck',
]


def forest(mask, variant=1):
    """mask: four corners (nw, ne, sw, se), 1 = forest. A cell is forest when the
    bilinear blend of the corners, plus a small jitter, is past one half. Along a shared
    edge two tiles use the same two corners, so the edges meet."""
    nw, ne, sw, se = mask
    inside = [[False] * 18 for _ in range(18)]
    for y in range(-1, 17):
        for x in range(-1, 17):
            tx = min(1, max(0, (x + 0.5) / 16))
            ty = min(1, max(0, (y + 0.5) / 16))
            v = (nw * (1 - tx) * (1 - ty) + ne * tx * (1 - ty) + sw * (1 - tx) * ty + se * tx * ty)
            j = (h32(x & 15, y & 15, 5) % 9 - 4) / 40.0
            if 0 < x < 15 and 0 < y < 15:
                v += j
            inside[y + 1][x + 1] = v > 0.5
    t = blank()
    if variant > 1:
        g = open_ground(variant)
        t = [list(r) for r in g]
    else:
        t = [list(r) for r in open_ground(1)]
    shift = 0 if variant == 1 else 5
    for y in range(16):
        for x in range(16):
            if inside[y + 1][x + 1]:
                ch = CANOPY[y][(x + shift) & 15]
                # the rim: dark where open ground lies below or to the right (the trees cast
                # shade), light where it lies above or to the left (lit edge of a crown)
                if not inside[y + 2][x + 1] or not inside[y + 1][x + 2]:
                    ch = 'u'
                elif not inside[y][x + 1] or not inside[y + 1][x]:
                    ch = 'k'
                t[y][x] = ch
            else:
                # ground shaded just below and to the right of the trees
                if inside[y][x + 1] or inside[y + 1][x] or inside[y][x]:
                    t[y][x] = 'd'
    return rows_of(t)


FOREST_MASKS = [(a, b, c, d) for a in (0, 1) for b in (0, 1) for c in (0, 1) for d in (0, 1)]


def mask_name(m):
    if m == (1, 1, 1, 1):
        return 'forest_full'
    if m == (0, 0, 0, 0):
        return None
    return 'forest_' + ''.join(n for n, v in zip(('nw', 'ne', 'sw', 'se'), m) if v)


# ---------------------------------------------------------------- paths (rivers and roads)
MID = {'n': (7.5, -0.5), 's': (7.5, 15.5), 'w': (-0.5, 7.5), 'e': (15.5, 7.5)}
CORNER = {'ne': (16, 0), 'nw': (0, 0), 'se': (16, 16), 'sw': (0, 16)}


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / float(dx * dx + dy * dy)))
    qx, qy = ax + t * dx, ay + t * dy
    return math.hypot(px - qx, py - qy)


def path_dist(exits, x, y, curved):
    """Distance from cell centre (x, y) to the path's middle line."""
    px, py = x + 0.5, y + 0.5
    ex = set(exits)
    if curved and len(ex) == 2 and ex not in ({'n', 's'}, {'e', 'w'}):
        k = ''.join(sorted(ex, key=lambda c: 'ns'.find(c) if c in 'ns' else 2))
        cx, cy = CORNER[k]
        return abs(math.hypot(px - cx, py - cy) - 8)
    d = 99
    for e in ex:
        mx, my = MID[e]
        d = min(d, seg_dist(px, py, 8, 8, mx + 0.5, my + 0.5))
    return d


def river(exits, variant=1):
    """Water 8 cells wide (half width 4), a foam cell at its edge, an earth bank cell outside it."""
    t = [list(r) for r in open_ground(variant)]
    for y in range(16):
        for x in range(16):
            d = path_dist(exits, x, y, True)
            if d < 3.5:
                ch = 'w'
                if d < 1.2:
                    ch = 'v'
                if (x + 2 * y + variant * 3) % 9 == 0 and d < 3:
                    ch = 'r'
                t[y][x] = ch
            elif d < 4.6:
                t[y][x] = 'f'
            elif d < 5.6:
                t[y][x] = 'e'
            elif d < 6.4 and t[y][x] == 'g':
                t[y][x] = 'd'
    return rows_of(t)


def road(exits):
    """Road 6 cells wide, an edge cell each side, a dashed centre line (4 on, 4 off)."""
    t = [list(r) for r in open_ground(1)]
    for y in range(16):
        for x in range(16):
            d = path_dist(exits, x, y, False)
            if d < 3.0:
                t[y][x] = 'a'
            elif d < 4.0:
                t[y][x] = 'b'
            elif d < 5.0 and t[y][x] == 'g':
                t[y][x] = 'e'
    ex = set(exits)
    straight_ns = ex == {'n', 's'}
    straight_ew = ex == {'e', 'w'}
    for i in range(16):
        on = (i % 8) in (1, 2, 3, 4)
        if (straight_ns or ('n' in ex and i < 4) or ('s' in ex and i > 11)) and on:
            if t[i][7] == 'a':
                t[i][7] = 'y'
        if (straight_ew or ('w' in ex and i < 4) or ('e' in ex and i > 11)) and on:
            if t[7][i] == 'a':
                t[7][i] = 'y'
    return rows_of(t)


def bridge(road_dir):
    """A road crossing a river: the river runs one way, the road over it the other, with rails."""
    if road_dir == 'ns':
        t = [list(r) for r in river(('e', 'w'))]
        for y in range(16):
            for x in range(3, 13):
                t[y][x] = 'b' if x in (3, 12) else ('a' if x in range(4, 12) else t[y][x])
            if (y % 8) in (1, 2, 3, 4):
                t[y][7] = 'y'
        for y in (3, 12):
            for x in (2, 13):
                t[y][x] = 'b'
    else:
        t = [list(r) for r in bridge('ns')]
        return [''.join(t[x][y] for x in range(16)) for y in range(16)]
    # a bridge tile keeps to 8 colours: no tufts, no ripples
    return [r.replace('l', 'g').replace('d', 'g').replace('r', 'w') for r in rows_of(t)]


def pad():
    """A stone pad: 14 x 14 slab with a bevel, joints in a cross. Installations stand on it."""
    t = [list(r) for r in open_ground(1)]
    for y in range(1, 15):
        for x in range(1, 15):
            ch = 'p'
            if y == 1 or x == 1:
                ch = 'l'
            if y == 14 or x == 14:
                ch = 's'
            if (x == 7 or y == 7) and 1 < x < 14 and 1 < y < 14:
                ch = 's'
            t[y][x] = ch
    for x in range(2, 16):
        if t[15][x] == 'g':
            t[15][x] = 'd'
    return rows_of(t)


# ---------------------------------------------------------------- land lines (32 x 32 designs)
def line_design(name):
    """A 32 x 32 design cut in the land: 2 cell lines in h with an earth cell below and right."""
    pts = []
    if name == 'spiral':
        a = 0.0
        while a < 5.2 * math.pi:
            r = 1.5 + a * 0.82
            pts.append((16 + r * math.cos(a), 16 + r * math.sin(a)))
            a += 0.04
    elif name == 'sunwheel':
        for i in range(360):
            a = math.radians(i)
            pts.append((16 + 7 * math.cos(a), 16 + 7 * math.sin(a)))
        for k in range(8):
            a = math.radians(k * 45 + 22.5)
            for r in range(10, 15):
                pts.append((16 + r * math.cos(a), 16 + r * math.sin(a)))
        for i in range(360):
            a = math.radians(i)
            pts.append((16 + 2 * math.cos(a), 16 + 2 * math.sin(a)))
    elif name == 'lark':
        # an original glyph: a bird from above with swept wings and a forked tail
        poly = [(16, 3), (18, 8), (29, 13), (19, 13), (18, 20), (22, 28), (16, 24),
                (10, 28), (14, 20), (13, 13), (3, 13), (14, 8), (16, 3)]
        for (ax, ay), (bx, by) in zip(poly, poly[1:]):
            n = int(max(abs(bx - ax), abs(by - ay)) * 3) + 1
            for i in range(n + 1):
                pts.append((ax + (bx - ax) * i / n, ay + (by - ay) * i / n))
    on = [[False] * 32 for _ in range(32)]
    for x, y in pts:
        for dx in (0, 1):
            for dy in (0, 1):
                xi, yi = int(x + dx - 0.5), int(y + dy - 0.5)
                if 0 <= xi < 32 and 0 <= yi < 32:
                    on[yi][xi] = True
    g = [list(open_ground(1)[y % 16][x % 16] for x in range(32)) for y in range(32)]
    for y in range(32):
        for x in range(32):
            if on[y][x]:
                g[y][x] = 'h'
            elif (y > 0 and on[y - 1][x]) or (x > 0 and on[y][x - 1]):
                g[y][x] = 'e'
    return [''.join(r) for r in g]


def quarter(rows32, q):
    ox = 16 if q in ('ne', 'se') else 0
    oy = 16 if q in ('sw', 'se') else 0
    return [r[ox:ox + 16] for r in rows32[oy:oy + 16]]


# ---------------------------------------------------------------- the whole set
def tile_set():
    """name -> (rows, joins note). Order is the order of the design file."""
    T = {}
    for v in (1, 2, 3):
        T['open_%d' % v] = (open_ground(v), 'joins anything on every side')
    for m in FOREST_MASKS:
        n = mask_name(m)
        if n:
            T[n] = (forest(m), 'corners %s are forest; an edge joins a tile whose two corners on that edge match' % '/'.join(c for c, f in zip(('nw', 'ne', 'sw', 'se'), m) if f))
    T['forest_full_2'] = (forest((1, 1, 1, 1), 2), 'a variant of forest_full (the crowns shifted 5 cells)')
    for ex, nm in ((('n', 's'), 'river_ns'), (('e', 'w'), 'river_ew'), (('n', 'e'), 'river_ne'),
                   (('n', 'w'), 'river_nw'), (('s', 'e'), 'river_se'), (('s', 'w'), 'river_sw')):
        T[nm] = (river(ex), 'water meets the middle 8 cells of the %s edges' % '/'.join(ex).upper())
    T['river_ns_2'] = (river(('n', 's'), 2), 'a variant of river_ns')
    T['river_ns_3'] = (river(('n', 's'), 3), 'a variant of river_ns')
    for ex, nm in ((('n', 's'), 'road_ns'), (('e', 'w'), 'road_ew'), (('n', 'e'), 'road_ne'),
                   (('n', 'w'), 'road_nw'), (('s', 'e'), 'road_se'), (('s', 'w'), 'road_sw'),
                   (('n', 's', 'e'), 'road_t_e'), (('n', 's', 'w'), 'road_t_w'),
                   (('e', 'w', 'n'), 'road_t_n'), (('e', 'w', 's'), 'road_t_s'),
                   (('n', 's', 'e', 'w'), 'road_cross')):
        T[nm] = (road(ex), 'road meets the middle 8 cells (6 road, 2 edge) of the %s edges' % '/'.join(ex).upper())
    T['bridge_ns'] = (bridge('ns'), 'a road going N/S over a river going E/W')
    T['bridge_ew'] = (bridge('ew'), 'a road going E/W over a river going N/S')
    T['pad'] = (pad(), 'joins open ground on every side; the base of every ground installation')
    return T


LINES = ['spiral', 'sunwheel', 'lark']
