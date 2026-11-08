"""Shape helpers: shaded ellipses and layered blobs, turned into tone digit grids."""


def inside(i, j, cx, cy, rx, ry):
    x, y = i + 0.5 - cx, j + 0.5 - cy
    return (x / rx) ** 2 + (y / ry) ** 2 <= 1.0


def layered(w, h, layers, rim='5', seam='5', hl=(0.0, -0.45)):
    """layers: list of (cx, cy, rx, ry), back to front. Returns a grid of tone digits.
    The outer boundary of the union is `rim`, the edge of a front layer over a back one is `seam`.
    Shading: a light at the top middle of each layer (so a mirrored grid is still right)."""
    own = [[-1] * w for _ in range(h)]
    for k, (cx, cy, rx, ry) in enumerate(layers):
        for j in range(h):
            for i in range(w):
                if inside(i, j, cx, cy, rx, ry):
                    own[j][i] = k
    g = [['.'] * w for _ in range(h)]
    for j in range(h):
        for i in range(w):
            k = own[j][i]
            if k < 0:
                continue
            nb = [own[j + dy][i + dx] if 0 <= j + dy < h and 0 <= i + dx < w else -1
                  for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if -1 in nb:
                g[j][i] = rim
                continue
            # a seam: the pixel just below or beside a front layer's lower edge belongs to the back layer
            if j > 0 and own[j - 1][i] > k:
                g[j][i] = seam
                continue
            cx, cy, rx, ry = layers[k]
            x = (i + 0.5 - cx) / rx - hl[0]
            y = (j + 0.5 - cy) / ry - hl[1]
            d = (x * x + y * y) ** 0.5
            yy = (j + 0.5 - cy) / ry
            if d < 0.24:
                t = '1'
            elif d < 0.55:
                t = '2'
            elif yy > 0.55:
                t = '4'
            else:
                t = '3'
            g[j][i] = t
    return g


def to_rows(g):
    return [''.join(r) for r in g]


def paint(g, x, y, rows):
    """Paint string rows into grid g at (x, y); '.' leaves the grid alone, ' ' too."""
    for j, line in enumerate(rows):
        for i, ch in enumerate(line):
            if ch not in '. ' and 0 <= y + j < len(g) and 0 <= x + i < len(g[0]):
                g[y + j][x + i] = ch


def blank(w, h):
    return [['.'] * w for _ in range(h)]
