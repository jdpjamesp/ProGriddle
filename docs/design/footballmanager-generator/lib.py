"""Small pixel toolkit for the Gaffer design: colours, a canvas, the 5 x 7 font and sprite stamping."""
from PIL import Image
from font import CHARS, TABLE, EXTRA, SMALL


def hx(s):
    s = s.strip().lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def tohex(c):
    return '%02X%02X%02X' % c


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def lum(c):
    def ch(v):
        v = v / 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = c
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = lum(a), lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


def glyph(ch):
    if ch in EXTRA:
        return EXTRA[ch]
    i = CHARS.find(ch.upper())
    if i < 0:
        i = CHARS.find('?')
    bits = TABLE[i * 35:(i + 1) * 35]
    return [bits[r * 5:(r + 1) * 5] for r in range(7)]


def text_width(s, k=1):
    return 0 if not s else len(s) * 6 * k - k


def small_width(s):
    return 0 if not s else len(s) * 4 - 1


def money(v):
    """A money amount as the screens show it: a sign, then up to 7 digits; groups of 3 are kept apart by layout, not commas."""
    return ('+' if v >= 0 else '-') + str(abs(v))


def amount_width(v, k=1, sign=True):
    n = len(str(abs(v))) + (1 if sign else 0)
    return n * 6 * k - k + 2 * k * ((len(str(abs(v))) - 1) // 3)


class Canvas:
    def __init__(self, w=240, h=256, fill=(0, 0, 0)):
        self.w, self.h = w, h
        self.px = [[fill for _ in range(w)] for _ in range(h)]

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x]

    def rect(self, x, y, w, h, c):
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.put(i, j, c)

    def tint(self, x, y, colour, t):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = mix(self.px[y][x], colour, t)

    def text(self, s, x, y, colour, k=1, outline=None, bottom=None):
        n = 7 * k
        if outline is not None:
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dx or dy:
                        self._text(s, x + dx, y + dy, lambda r: outline, k)
        if bottom is None:
            self._text(s, x, y, lambda r: colour, k)
        else:
            self._text(s, x, y, lambda r: mix(colour, bottom, r / (n - 1)), k)

    def small(self, s, x, y, colour):
        cx = x
        for ch in s:
            rows = SMALL.get(ch.upper(), SMALL[' ']).split(',')
            for r in range(5):
                for c in range(3):
                    if rows[r][c] == '#':
                        self.put(cx + c, y + r, colour)
            cx += 4

    def amount(self, v, x, y, colour, k=1, right=None, sign=True):
        """A money amount: sign and digits, with 2 extra pixels before each group of 3 digits counted from the right.
        If right is given, the text ends at that x (inclusive)."""
        s = money(v)
        w = amount_width(v, k, sign)
        if right is not None:
            x = right - w + 1
        cx = x
        digits = s[1:]
        if sign:
            self._text(s[0], cx, y, lambda r: colour, k)
            cx += 6 * k
        for i, ch in enumerate(digits):
            left = len(digits) - i
            if i and left % 3 == 0:
                cx += 2 * k
            self._text(ch, cx, y, lambda r: colour, k)
            cx += 6 * k
        return x

    def _text(self, s, x, y, cf, k):
        cx = x
        for ch in s:
            g = glyph(ch)
            for r in range(7):
                for c in range(5):
                    if g[r][c] == '#':
                        for a in range(k):
                            for b in range(k):
                                self.put(cx + c * k + b, y + r * k + a, cf(r * k + a))
            cx += 6 * k

    def image(self, scale=3):
        im = Image.new('RGB', (self.w, self.h))
        im.putdata([c for row in self.px for c in row])
        return im.resize((self.w * scale, self.h * scale), Image.NEAREST)

    def copy(self):
        c = Canvas(self.w, self.h)
        c.px = [row[:] for row in self.px]
        return c


class Sprite:
    """A grid of legend letters, '.' transparent. legend: letter -> palette name."""

    def __init__(self, name, rows, legend, note='', box=None, group='', origin=None):
        self.name = name
        self.rows = rows
        self.legend = legend
        self.note = note
        self.group = group
        self.width = len(rows[0])
        self.height = len(rows)
        for r in rows:
            assert len(r) == self.width, (name, r)
        self.box = box or (0, 0, self.width, self.height)
        self.origin = origin or (self.width // 2, self.height // 2)

    def colours(self):
        from palette import C
        return {k: C(v) for k, v in self.legend.items()}

    def used(self):
        return sorted(set(ch for r in self.rows for ch in r if ch != '.'))


def grid(s):
    rows = [r.strip() for r in s.strip('\n').split('\n')]
    rows = [r for r in rows if r]
    w = max(len(r) for r in rows)
    return [r.ljust(w, '.') for r in rows]


def mirror(rows):
    return [r[::-1] for r in rows]


def rotate(rows, turns):
    """Quarter turns clockwise."""
    for _ in range(turns % 4):
        h, w = len(rows), len(rows[0])
        rows = [''.join(rows[h - 1 - y][x] for y in range(h)) for x in range(w)]
    return rows


def flipv(rows):
    return rows[::-1]


def put(cv, spr, x, y, override=None, rows=None, legend=None):
    """Draw spr with its top left at (x, y). legend: letter -> palette name, laid over the sprite's own."""
    from palette import C
    m = spr.colours()
    if legend:
        m.update({k: C(v) for k, v in legend.items()})
    if override:
        m.update(override)
    for j, line in enumerate(rows or spr.rows):
        for i, ch in enumerate(line):
            if ch != '.':
                cv.put(x + i, y + j, m[ch])


def put_c(cv, spr, cx, cy, override=None, rows=None, legend=None):
    """Draw spr with its origin on (cx, cy)."""
    ox, oy = spr.origin
    put(cv, spr, cx - ox, cy - oy, override, rows, legend)


def glow(cv, rows, x, y, colour, t):
    """The glow: a tint pass on the empty cells next to a filled cell (8 neighbours), top left at (x, y)."""
    h, w = len(rows), len(rows[0])
    seen = set()
    for j in range(-1, h + 1):
        for i in range(-1, w + 1):
            if 0 <= j < h and 0 <= i < w and rows[j][i] != '.':
                continue
            near = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    jj, ii = j + dy, i + dx
                    if 0 <= jj < h and 0 <= ii < w and rows[jj][ii] != '.':
                        near = True
            if near and (i, j) not in seen:
                seen.add((i, j))
                cv.tint(x + i, y + j, colour, t)


def shadow(cv, spr, cx, cy, dx, dy, colour, t, rows=None):
    """The ground shadow: a tint pass of the sprite's outline, offset."""
    ox, oy = spr.origin
    for j, line in enumerate(rows or spr.rows):
        for i, ch in enumerate(line):
            if ch != '.':
                cv.tint(cx - ox + i + dx, cy - oy + j + dy, colour, t)
