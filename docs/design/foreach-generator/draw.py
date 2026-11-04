"""Drawing helpers shared by the previews: stamp a sprite at its origin, in a colour row, turned."""
from palette import ROWS, NAMED, C
from lib import hx


def turn(rows, d):
    """Rows facing right turned to face d: left is a mirror, up and down are quarter turns."""
    if d == 'right':
        return rows
    if d == 'left':
        return [r[::-1] for r in rows]
    h, w = len(rows), len(rows[0])
    if d == 'up':      # a quarter turn anticlockwise
        return [''.join(rows[y][w - 1 - x] for y in range(h)) for x in range(w)]
    if d == 'down':    # a quarter turn clockwise
        return [''.join(rows[h - 1 - y][x] for y in range(h)) for x in range(w)]
    raise ValueError(d)


def cmap(spr, row=None, override=None):
    m = {}
    r = row or spr.tone
    if r:
        for i in range(5):
            m[str(i + 1)] = ROWS[r][i]
    for k, v in spr.legend.items():
        m[k] = hx(NAMED[v])
    if override:
        m.update(override)
    return m


def put(cv, spr, cx, cy, row=None, d='right', override=None, rows=None):
    """Draw spr with its origin on canvas pixel (cx, cy)."""
    rr = turn(rows or spr.rows, d)
    m = cmap(spr, row, override)
    ox, oy = spr.origin
    for j, line in enumerate(rr):
        for i, ch in enumerate(line):
            if ch != '.':
                cv.put(cx - ox + i, cy - oy + j, m[ch])


def phantom(cv, G, who, cx, cy, swish=0, look='right', angry=0):
    for spr, extra in G.phantom_layers(who, swish, look, angry):
        if spr.group == 'phantom':
            put(cv, spr, cx, cy, row=who)
        elif extra == 'angry':
            put(cv, spr, cx, cy, override={'P': C('Angry')})
        elif spr.tone:
            put(cv, spr, cx, cy)
        else:
            put(cv, spr, cx, cy)
