"""Geometry helpers: draw a shape by asking each cell centre a question."""
import math


def render(w, h, fn):
    rows = []
    for y in range(h):
        r = ''
        for x in range(w):
            r += fn(x + 0.5, y + 0.5) or '.'
        rows.append(r)
    return rows


def ball(x, y, cx, cy, R, tones):
    """A lit ball: tones is (light, mid, dark) letters, light from the upper left. None outside."""
    nx, ny = (x - cx) / R, (y - cy) / R
    d = nx * nx + ny * ny
    if d > 1:
        return None
    nz = math.sqrt(1 - d)
    l = (-nx - ny) * 0.55 + nz * 0.7
    if l > 0.75:
        return tones[0]
    if l > 0.25:
        return tones[1]
    return tones[2]


def outline(rows, L):
    """Add an outline letter on empty cells next to a filled cell (4 neighbours)."""
    h, w = len(rows), len(rows[0])
    o = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if rows[y][x] != '.':
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and rows[yy][xx] != '.':
                    o[y][x] = L
                    break
    return [''.join(r) for r in o]


def edge(rows, L, keep=''):
    """Turn the outer ring of filled cells into L (inside the shape)."""
    h, w = len(rows), len(rows[0])
    o = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if rows[y][x] == '.' or rows[y][x] in keep:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < w and 0 <= yy < h) or rows[yy][xx] == '.':
                    o[y][x] = L
                    break
    return [''.join(r) for r in o]


def over(base, top):
    """Lay top over base; '.' in top lets base show."""
    return [''.join(t if t != '.' else b for b, t in zip(rb, rt)) for rb, rt in zip(base, top)]


def poly_inside(px, py, poly):
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > py) != (y2 > py):
            xi = x1 + (py - y1) * (x2 - x1) / (y2 - y1)
            if px < xi:
                inside = not inside
    return inside


def blank(w, h):
    return ['.' * w for _ in range(h)]


def setc(rows, x, y, ch):
    if 0 <= y < len(rows) and 0 <= x < len(rows[0]):
        r = rows[y]
        rows[y] = r[:x] + ch + r[x + 1:]
