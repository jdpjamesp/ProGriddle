"""Small pixel toolkit for the Girder Rush design: colours, tone ramps, a canvas, the 5 x 7 font,
sprite stamping and an auto shader that turns a hand drawn region map into tone rows."""
from PIL import Image
from font import CHARS, TABLE

DARK = (0x05, 0x08, 0x0F)


def hx(s):
    s = s.strip().lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def tohex(c):
    return '%02X%02X%02X' % c


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def tones(base):
    """Five tones, lightest first, by the Lantern Glass formula (sibling games share it)."""
    b = hx(base) if isinstance(base, str) else base
    w = (255, 255, 255)
    return [mix(b, w, 0.7), mix(b, w, 0.3), b, mix(b, DARK, 0.32), mix(b, DARK, 0.64)]


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


# ---------------------------------------------------------------- font
def glyph(ch):
    i = CHARS.find(ch.upper())
    if i < 0:
        i = CHARS.find('?')
    bits = TABLE[i * 35:(i + 1) * 35]
    return [bits[r * 5:(r + 1) * 5] for r in range(7)]


def text_width(s, k=1):
    return 0 if not s else len(s) * 6 * k - k


# ---------------------------------------------------------------- canvas
class Canvas:
    def __init__(self, w=224, h=256, fill=(0, 0, 0)):
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

    def stamp(self, spr, x, y, mirror=False, recolour=None):
        """Draw a sprite with its top left at (x, y)."""
        rows = spr.rows
        cmap = spr.colours()
        if recolour:
            cmap = recolour(cmap)
        for j, row in enumerate(rows):
            n = len(row)
            for i, ch in enumerate(row):
                if ch == '.':
                    continue
                ii = (n - 1 - i) if mirror else i
                self.put(x + ii, y + j, cmap[ch])

    def stamp_at_origin(self, spr, ox, oy, mirror=False, recolour=None):
        ax, ay = spr.origin
        if mirror:
            ax = spr.width - 1 - ax
        self.stamp(spr, ox - ax, oy - ay, mirror, recolour)

    def text(self, s, x, y, colour, k=1, outline=None, bottom=None):
        """Draw text; colour is one colour, or a gradient (top, bottom) with bottom given."""
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


# ---------------------------------------------------------------- sprites
class Sprite:
    def __init__(self, name, rows, tone=None, legend=None, origin=(0, 0), note='', group='', body=None):
        self.name = name
        self.rows = rows
        self.tone = tone            # colour row name used by digits 1..5, or None
        self.legend = legend or {}  # letter -> palette name
        self.origin = origin
        self.note = note
        self.group = group
        self.body = body            # (x, y, w, h) of the solid body inside the picture, or None
        self.width = len(rows[0])
        self.height = len(rows)
        for r in rows:
            assert len(r) == self.width, (name, r)

    def colours(self):
        from palette import ROWS, NAMED
        m = {}
        if self.tone:
            t = ROWS[self.tone]
            for i in range(5):
                m[str(i + 1)] = t[i]
        for k, v in self.legend.items():
            m[k] = hx(NAMED[v]) if not isinstance(v, tuple) else v
        return m

    def used(self):
        return sorted(set(ch for r in self.rows for ch in r if ch != '.'))


def shade(art, spec, outline=None, feet_open=True, keep=None):
    """Turn a region map into output rows.

    art: list of strings, one char a pixel, '.' empty.
    spec: region char -> ('T',) tones lit from above, ('F', 'X') a fixed letter,
          ('S', 'X', 'Y') a letter lit from above with Y as its lower half or shade.
    outline: letter for a 1 pixel outline round the shape (added outside), or None.
    """
    h = len(art)
    w = len(art[0])

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return art[y][x]
        return '.'

    out = [['.'] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            ch = art[y][x]
            if ch == '.':
                continue
            sp = spec[ch]
            if sp[0] == 'F':
                out[y][x] = sp[1]
                continue
            # distance to the top and bottom of this run of the same region in this column
            a = 0
            while at(x, y - a - 1) == ch:
                a += 1
            b = 0
            while at(x, y + b + 1) == ch:
                b += 1
            t = a / (a + b) if a + b else 0.5
            if sp[0] == 'S':
                out[y][x] = sp[1] if t < 0.5 or a + b == 0 else sp[2]
                continue
            edge_side = at(x - 1, y) == '.' or at(x + 1, y) == '.'
            below_empty = at(x, y + 1) == '.'
            above_empty = at(x, y - 1) == '.'
            if above_empty:
                tone = '1'
            elif below_empty:
                tone = '5'
            elif t < 0.3:
                tone = '2'
            elif t < 0.68:
                tone = '3'
            else:
                tone = '4'
            if edge_side and tone in '23':
                tone = str(int(tone) + 1)
            out[y][x] = tone
    if outline:
        o2 = [r[:] for r in out]
        for y in range(h):
            for x in range(w):
                if out[y][x] != '.':
                    continue
                n = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < w and 0 <= yy < h and out[yy][xx] != '.':
                        n = True
                if n:
                    o2[y][x] = outline
        out = o2
    rows = [''.join(r) for r in out]
    if keep:
        rows = keep(rows)
    return rows


def pad(art, left=1, right=1, top=1, bottom=0):
    w = len(art[0]) + left + right
    rows = ['.' * w] * top + ['.' * left + r + '.' * right for r in art] + ['.' * w] * bottom
    return rows


def grid(s):
    rows = [r.strip() for r in s.strip('\n').split('\n')]
    rows = [r for r in rows if r]
    w = max(len(r) for r in rows)
    return [r.ljust(w, '.') for r in rows]


def outline(rows, L='H', below=True):
    h, w = len(rows), len(rows[0])
    o = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if rows[y][x] != '.':
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, -1), (0, 1)):
                if dy == -1 and not below:
                    continue
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and rows[yy][xx] != '.':
                    o[y][x] = L
                    break
    return [''.join(r) for r in o]


def rotate(rows, turns):
    for _ in range(turns % 4):
        h, w = len(rows), len(rows[0])
        rows = [''.join(rows[h - 1 - y][x] for y in range(h)) for x in range(w)]
    return rows


def mirror(rows):
    return [r[::-1] for r in rows]
