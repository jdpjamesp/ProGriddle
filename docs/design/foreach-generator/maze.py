"""The FOR EACH maze: the 28 x 31 layout, the wall rule, the autotile set it makes, and drawing."""
import math

# Left half, columns 0 to 13. The right half is the mirror image (column c -> 27 - c).
# '#' wall, '.' data bit, 'o' commit token, ' ' empty lane, 't' tunnel lane (no bits, drawn dim),
# '-' lobby door, '=' lobby floor (phantoms only), 'S' empty lane where Dibby starts.
ROWS_LEFT = [
    "##############",  # 0
    "#.............",  # 1  top lane, full width
    "#.###.####.###",  # 2
    "#o###.####.###",  # 3
    "#.............",  # 4  full width
    "#.###.##.#####",  # 5
    "#.###.##.#####",  # 6
    "#.###.##.#####",  # 7
    "#.....##      ",  # 8
    "#####.#####.##",  # 9
    "#####.#####.##",  # 10
    "#####.##      ",  # 11 ring top
    "#####.## ####-",  # 12 lobby top wall and door (columns 13 and 14)
    "#####.## #====",  # 13
    "ttttt.   #====",  # 14 tunnel row
    "#####.## #====",  # 15
    "#####.## #####",  # 16 lobby bottom wall
    "#####.##      ",  # 17 ring bottom: READY! and the bonus item
    "#####.## #####",  # 18
    "#####.## #####",  # 19
    "#.............",  # 20
    "#.###.#####.##",  # 21
    "#.###.#####.##",  # 22
    "#o..#....    S",  # 23 Dibby's start (columns 13 and 14)
    "###.#.##.#####",  # 24
    "###.#.##.#####",  # 25
    "#.............",  # 26
    "#.#######.##.#",  # 27
    "#.#######.##.#",  # 28
    "#............ ",  # 29
    "##############",  # 30
]


def full_rows():
    rows = []
    for r in ROWS_LEFT:
        assert len(r) == 14, r
        right = r[::-1]
        rows.append(r + right)
    return rows


MAP = full_rows()
W, H = 28, 31


def kind(c, r):
    """Tile kind with the edge rule: a tile outside the map copies the nearest map tile."""
    c = min(max(c, 0), W - 1)
    r = min(max(r, 0), H - 1)
    return MAP[r][c]


def is_wall(c, r):
    # the door counts as wall for the wall rule, so the lobby line runs straight into it;
    # the lobby floor counts as path, so the lobby is drawn as a thin box
    return kind(c, r) in '#-'


def is_solid(c, r):
    return kind(c, r) == '#'


# ---------------------------------------------------------------- the wall rule
# Bands of the distance d (in pixels) from a wall pixel's centre to the nearest path tile.
BANDS = [(2.0, 'floor'), (3.0, 'Glow'), (4.0, 'Line'), (5.0, 'Gap'), (6.0, 'Inner'), (99, 'Fill')]
R_ROUND = 7.0  # radius of the cut on a convex wall corner


def tile_mask(c, r):
    """The 8 neighbours as bits: N=1 E=2 S=4 W=8 NE=16 SE=32 SW=64 NW=128 (bit set = wall)."""
    m = 0
    for bit, (dc, dr) in ((1, (0, -1)), (2, (1, 0)), (4, (0, 1)), (8, (-1, 0)),
                          (16, (1, -1)), (32, (1, 1)), (64, (-1, 1)), (128, (-1, -1))):
        if is_wall(c + dc, r + dr):
            m |= bit
    return m


NB = {1: (0, -1), 2: (1, 0), 4: (0, 1), 8: (-1, 0), 16: (1, -1), 32: (1, 1), 64: (-1, 1), 128: (-1, -1)}


def wall_distance(mask, x, y):
    """Distance from the centre of pixel (x, y) of a wall tile to the nearest path, for a neighbour mask."""
    px, py = x + 0.5, y + 0.5
    best = 99.0
    for bit, (dc, dr) in NB.items():
        if mask & bit:
            continue
        # the path tile occupies [dc*8, dc*8+8) x [dr*8, dr*8+8)
        x0, y0 = dc * 8, dr * 8
        dx = max(x0 - px, 0, px - (x0 + 8))
        dy = max(y0 - py, 0, py - (y0 + 8))
        best = min(best, math.hypot(dx, dy))
    # convex corners: a corner whose two side neighbours are both path is cut by a circle
    for (sa, sb, cx, cy) in ((1, 8, 0, 0), (1, 2, 8, 0), (4, 2, 8, 8), (4, 8, 0, 8)):
        if not (mask & sa) and not (mask & sb):
            # centre of the circle sits R_ROUND inside the tile from that corner
            ccx = cx + (R_ROUND if cx == 0 else -R_ROUND)
            ccy = cy + (R_ROUND if cy == 0 else -R_ROUND)
            if (px - ccx) * (1 if cx == 0 else -1) < 0 and (py - ccy) * (1 if cy == 0 else -1) < 0:
                best = min(best, R_ROUND - math.hypot(px - ccx, py - ccy))
    return best


def band(d):
    for lim, name in BANDS:
        if d < lim:
            return name
    return 'Fill'


CODE = {'floor': '.', 'Glow': 'G', 'Line': 'L', 'Gap': 'A', 'Inner': 'I', 'Fill': 'F'}


def wall_tile(mask):
    return tuple(''.join(CODE[band(wall_distance(mask, x, y))] for x in range(8)) for y in range(8))


def canonical(mask):
    """Corner bits only matter when both their side neighbours are walls: clear the others."""
    m = mask & 15
    for cb, a, b in ((16, 1, 2), (32, 4, 2), (64, 4, 8), (128, 1, 8)):
        if (mask & cb) and (mask & a) and (mask & b):
            m |= cb
    return m


def tile_set():
    """Every distinct wall tile, keyed by canonical mask (47 of them, the classic blob set)."""
    seen = {}
    for m in range(256):
        cm = canonical(m)
        if cm not in seen:
            seen[cm] = wall_tile(cm)
    return dict(sorted(seen.items()))


# ---------------------------------------------------------------- counts and checks
def counts():
    d = sum(row.count('.') for row in MAP)
    o = sum(row.count('o') for row in MAP)
    return d, o


def check_layout():
    bad = []
    walk = lambda ch: ch in '.o tS'
    for r in range(H - 1):
        for c in range(W - 1):
            if all(walk(MAP[rr][cc]) for rr, cc in ((r, c), (r + 1, c), (r, c + 1), (r + 1, c + 1))):
                bad.append('open 2x2 at %d,%d' % (c, r))
    # dead ends and connectivity (tunnel wraps)
    cells = [(c, r) for r in range(H) for c in range(W) if walk(MAP[r][c])]
    for c, r in cells:
        n = 0
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cc, rr = (c + dc) % W, r + dr
            if 0 <= rr < H and walk(MAP[rr][cc]):
                n += 1
            elif 0 <= rr < H and MAP[rr][cc] == '-' :
                n += 1
        if n < 2:
            bad.append('dead end at %d,%d' % (c, r))
    seen = {cells[0]}
    todo = [cells[0]]
    while todo:
        c, r = todo.pop()
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cc, rr = (c + dc) % W, r + dr
            if 0 <= rr < H and walk(MAP[rr][cc]) and (cc, rr) not in seen:
                seen.add((cc, rr))
                todo.append((cc, rr))
    if len(seen) != len(cells):
        bad.append('not connected: %d of %d' % (len(seen), len(cells)))
    return bad


if __name__ == '__main__':
    for i, r in enumerate(MAP):
        print('%2d %s' % (i, r))
    print(counts(), check_layout())
    print(len(tile_set()), 'tiles')


# ---------------------------------------------------------------- drawing
from palette import C

DOOR = (
    "........",
    "........",
    "........",
    "AABBAABB",
    "BBAABBAA",
    "........",
    "........",
    "........",
)

BIT = (
    "........",
    "........",
    "........",
    "...BB...",
    "...BB...",
    "........",
    "........",
    "........",
)


def floor_tile(c, r, cv, x0, y0, cols):
    f = cols['Tunnel'] if kind(c, r) == 't' else cols['Floor']
    for y in range(8):
        for x in range(8):
            cv.put(x0 + x, y0 + y, f)
    # a stud at the top left corner of every floor tile
    cv.put(x0, y0, cols['Floor Stud'])


def colours(flash=False, pulse=False):
    names = ['Floor', 'Floor Stud', 'Tunnel', 'Glow', 'Line', 'Gap', 'Inner', 'Fill', 'Door', 'Door Shade', 'Bit']
    m = {n: C(n) for n in names}
    if pulse:
        m['Line'] = C('Pulse')
    if flash:
        m['Line'] = C('Flash Line')
        m['Inner'] = C('Flash Line')
        m['Glow'] = C('Flash Glow')
    return m


def draw(cv, oy=24, eaten=(), flash=False, pulse=False, tokens=True, dots=True, lobby_open=True):
    cols = colours(flash, pulse)
    band_col = {'G': 'Glow', 'L': 'Line', 'A': 'Gap', 'I': 'Inner', 'F': 'Fill'}
    for r in range(H):
        for c in range(W):
            k = MAP[r][c]
            x0, y0 = c * 8, oy + r * 8
            if k == '#':
                t = wall_tile(canonical(tile_mask(c, r)))
                for y in range(8):
                    for x in range(8):
                        ch = t[y][x]
                        cv.put(x0 + x, y0 + y, cols['Floor'] if ch == '.' else cols[band_col[ch]])
            elif k == '-':
                for y in range(8):
                    for x in range(8):
                        ch = DOOR[y][x]
                        cv.put(x0 + x, y0 + y, cols['Floor'] if ch == '.' else (cols['Door'] if ch == 'A' else cols['Door Shade']))
            else:
                floor_tile(c, r, cv, x0, y0, cols)
                if k == '.' and dots and (c, r) not in eaten:
                    cv.rect(x0 + 3, y0 + 3, 2, 2, cols['Bit'])
    return cols


def token_cells():
    return [(c, r) for r in range(H) for c in range(W) if MAP[r][c] == 'o']


def bit_cells():
    return [(c, r) for r in range(H) for c in range(W) if MAP[r][c] == '.']


# ---------------------------------------------------------------- the map for the maze reader
NO_UP = [(c, r) for r in (11, 23) for c in range(11, 17)]
STARTS = {'P': (14, 23), 'M': (14, 11), 'R': (14, 14), 'B': (12, 14), 'C': (16, 14), 'F': (14, 17)}


def reader_map():
    """The map in the maze reader's symbols. A start letter stands on the tile whose left edge is the
    start x and whose middle is the start y; it wins over U on the same tile."""
    rows = [list(r) for r in MAP]
    out = []
    for r in range(H):
        line = []
        for c in range(W):
            k = rows[r][c]
            ch = {'#': '#', '.': '.', 'o': 'o', '-': '-', '=': '=', 't': 'T', ' ': '_', 'S': '_'}[k]
            if (c, r) in NO_UP:
                ch = 'U'
            line.append(ch)
        out.append(line)
    for letter, (c, r) in STARTS.items():
        out[r][c] = letter
    return [''.join(l) for l in out]


def check_reader_map():
    m = reader_map()
    bits = sum(r.count('.') for r in m)
    toks = sum(r.count('o') for r in m)
    # the mirror check: every start letter stands for the tile under it (a lane, U or the lobby floor)
    under = {'P': 'U', 'M': 'U', 'R': '=', 'B': '=', 'C': '=', 'F': '_'}
    plain = [''.join(under.get(ch, ch) for ch in r) for r in m]
    mirror = all(r == r[::-1] for r in plain)
    return bits, toks, mirror
