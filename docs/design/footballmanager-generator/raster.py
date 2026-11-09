"""A tiny rasteriser used to build the larger pictures (the close up keeper, faces, badges) as letter grids.

It only runs inside the generator: what goes into the design file is the finished grid, never these shapes."""
import math


class Grid:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [['.'] * w for _ in range(h)]

    def set(self, x, y, ch):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.g[y][x]
        return '.'

    def disc(self, cx, cy, r, ch):
        for y in range(self.h):
            for x in range(self.w):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.3:
                    self.g[y][x] = ch

    def ellipse(self, cx, cy, rx, ry, ch):
        for y in range(self.h):
            for x in range(self.w):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 + 0.05:
                    self.g[y][x] = ch

    def capsule(self, a, b, r, ch):
        ax, ay = a
        bx, by = b
        dx, dy = bx - ax, by - ay
        ll = dx * dx + dy * dy or 1
        for y in range(self.h):
            for x in range(self.w):
                t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / ll))
                px, py = ax + t * dx, ay + t * dy
                if (x - px) ** 2 + (y - py) ** 2 <= r * r + 0.25:
                    self.g[y][x] = ch

    def poly(self, pts, ch):
        n = len(pts)
        for y in range(self.h):
            for x in range(self.w):
                px, py = x + 0.5, y + 0.5
                inside = False
                j = n - 1
                for i in range(n):
                    xi, yi = pts[i]
                    xj, yj = pts[j]
                    if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
                        inside = not inside
                    j = i
                if inside:
                    self.g[y][x] = ch

    def rows(self):
        return [''.join(r) for r in self.g]

    def outline(self, ch, over='.', diag=False):
        """Put ch on every empty pixel next to a filled one."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] != over:
                    continue
                nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
                if diag:
                    nb += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
                if any(self.get(x + a, y + b) not in ('.', ch) for a, b in nb):
                    add.append((x, y))
        for x, y in add:
            self.g[y][x] = ch

    def shade(self, body='3', top='2', hi='1', low='4', right_low=True):
        """Top light: a body pixel with nothing of its body above it becomes top (and the ones under a top stay);
        a body pixel with an edge below or to the right becomes low."""
        src = [r[:] for r in self.g]

        def at(x, y):
            if 0 <= x < self.w and 0 <= y < self.h:
                return src[y][x]
            return '.'
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x] != body:
                    continue
                if at(x, y - 1) != body:
                    self.g[y][x] = top
                elif at(x, y + 1) != body or (right_low and at(x + 1, y) != body):
                    self.g[y][x] = low


def rot(p, c, deg):
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))
