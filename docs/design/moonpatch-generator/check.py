"""Checks run by the generator: the limits of the brief, contrast numbers, colour blindness."""
from PIL import Image
from lib import Canvas, contrast, lum
from palette import C, NAMED, FAMILIES, count_distinct  # noqa: F401 (count_distinct is used by run_all)
import sprites as SP
import preview as PV

MACHADO = {
    'deuteranopia': [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    'protanopia': [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    'tritanopia': [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

# the largest a sprite may be, by group (the brief: 8 x 8 things, pests up to 16 wide as the game's boxes are)
SIZES = {'bulb': (8, 8), 'gloam': (8, 8), 'wick': (8, 8), 'sower': (8, 8), 'jack': (16, 8), 'snail': (16, 8),
         'burst': (12, 12), 'wickdeath': (16, 16), 'strip': (8, 8)}


def lin(v):
    v /= 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def unlin(v):
    v = max(0.0, min(1.0, v))
    v = 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return int(round(v * 255))


def sim(c, m):
    l = [lin(c[0]), lin(c[1]), lin(c[2])]
    return tuple(unlin(sum(m[i][j] * l[j] for j in range(3))) for i in range(3))


def simulate(im, m):
    out = im.copy()
    px, po = im.load(), out.load()
    cache = {}
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            c = px[x, y]
            if c not in cache:
                cache[c] = sim(c, m)
            po[x, y] = cache[c]
    return out


def validate():
    bad = []
    if count_distinct() > 48:
        bad.append('palette has %d colours' % count_distinct())
    for s in SP.ALL.values():
        for ch in s.used():
            if ch not in s.legend:
                bad.append('%s: %s not in legend' % (s.name, ch))
        n = len(set(NAMED[s.legend[c]] for c in s.used() if c in s.legend))
        if s.group == 'gloam':
            n = len(set(s.used()))            # family letters stand for one colour each in any wave
        if n > 8:
            bad.append('%s: %d colours' % (s.name, n))
        mw, mh = SIZES[s.group]
        if s.name == 'spark' or s.name == 'muzzle' or s.name == 'wick_icon':
            continue
        if s.width > mw or s.height > mh:
            bad.append('%s: %d x %d' % (s.name, s.width, s.height))
    return bad


def dist(a, b):
    """A rough perceptual distance (redmean), 0 to about 765."""
    rm = (a[0] + b[0]) / 2.0
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return ((2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db) ** 0.5


def separation():
    """For each vision and each pair the brief names (the Wick, the Blight, every Gloam family), the smallest distance."""
    keys = ['Wick', 'Blight'] + FAMILIES
    out = {}
    for vname, m in [('normal', None)] + list(MACHADO.items()):
        worst = None
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                if a in FAMILIES and b in FAMILIES:
                    continue                 # two Gloam families are never on screen together
                ca, cb = C(a), C(b)
                if m:
                    ca, cb = sim(ca, m), sim(cb, m)
                d = dist(ca, cb)
                if worst is None or d < worst[0]:
                    worst = (d, a, b)
        out[vname] = worst
    return out


def blight_lightness():
    """The relative luminance of the Blight bulb body against each bulb family's body: the poison must be lighter."""
    return [(f, lum(C(f)), lum(C('Blight'))) for f in FAMILIES]


GROUNDS = ['Night', 'Band']
THINGS = ['Wick', 'Spark', 'Blight', 'Ember', 'Jack', 'Husk', 'Snail Foot', 'Text', 'Text Dim', 'Points'] + FAMILIES + [f + ' Deep' for f in FAMILIES]


def contrast_table():
    return [(t, [contrast(C(t), C(g)) for g in GROUNDS]) for t in THINGS]


def colour_check(path):
    ims = [PV.busy().image(1), PV.later().image(1)]
    sw = Canvas(240, 8 * 12 + 8, C('Night'))
    names = ['Wick', 'Wick Light', 'Spark', 'Blight', 'Blight Light', 'Blight Deep', 'Ember', 'Jack', 'Husk', 'Snail Foot'] + FAMILIES
    for i, n in enumerate(names):
        x, y = 4 + (i % 8) * 29, 4 + (i // 8) * 30
        sw.rect(x, y, 24, 24, C(n))
    for i, f in enumerate(FAMILIES):
        x = 4 + i * 38
        sw.rect(x, 70, 10, 10, C(f))
        sw.rect(x + 12, 70, 10, 10, C('Blight'))
        sw.rect(x + 24, 70, 10, 10, C('Wick'))
    ims.append(sw.image(1))
    rows = []
    for im in ims:
        w = im.size[0] * 4 + 24
        out = Image.new('RGB', (w, im.size[1]), C('Ink'))
        out.paste(im, (0, 0))
        for k, m in enumerate(MACHADO.values()):
            out.paste(simulate(im, m), ((im.size[0] + 8) * (k + 1), 0))
        rows.append(out)
    W = max(r.size[0] for r in rows)
    H = sum(r.size[1] for r in rows) + 8 * (len(rows) - 1)
    final = Image.new('RGB', (W, H), C('Ink'))
    y = 0
    for r in rows:
        final.paste(r, (0, y))
        y += r.size[1] + 8
    final.resize((W * 2, H * 2), Image.NEAREST).save(path)


if __name__ == '__main__':
    print('distinct colours', count_distinct())
    print('validate', validate() or 'passed')
    for k, v in separation().items():
        print(k, '%.0f' % v[0], v[1], v[2])
    for f, a, b in blight_lightness():
        print(f, '%.3f' % a, 'blight %.3f' % b)
    for t, cs in contrast_table():
        print(t, ' '.join('%.1f' % c for c in cs))
