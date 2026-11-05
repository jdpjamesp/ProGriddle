"""Checks run by the generator: the limits of the brief, contrast numbers, colour blindness."""
from PIL import Image
from lib import Canvas, contrast, mix, put
from palette import C, NAMED, count_distinct
import preview as PV
import scene as S
import tiles as TL

MACHADO = {
    'deuteranopia': [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    'protanopia': [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    'tritanopia': [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


def lin(v):
    v /= 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def unlin(v):
    v = max(0.0, min(1.0, v))
    v = 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return int(round(v * 255))


def simulate(im, m):
    out = im.copy()
    px, po = im.load(), out.load()
    cache = {}
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            c = px[x, y]
            if c not in cache:
                l = [lin(c[0]), lin(c[1]), lin(c[2])]
                cache[c] = tuple(unlin(sum(m[i][j] * l[j] for j in range(3))) for i in range(3))
            po[x, y] = cache[c]
    return out


def validate():
    bad = []
    if count_distinct() > 64:
        bad.append('palette has %d colours' % count_distinct())
    for s in PV.ALL.values():
        for ch in s.used():
            if ch not in s.legend:
                bad.append('%s: %s not in legend' % (s.name, ch))
        n = len(set(NAMED[s.legend[c]] for c in s.used() if c in s.legend))
        if n > 8:
            bad.append('%s: %d colours' % (s.name, n))
        big = s.group == 'boss' and s.name.startswith('citadel') or s.name.startswith('ground_boom')
        lim = 32 if big else 16
        if s.width > lim or s.height > lim:
            bad.append('%s: %d x %d' % (s.name, s.width, s.height))
    for n, (rows, _) in TL.tile_set().items():
        if len(rows) != 16 or any(len(r) != 16 for r in rows):
            bad.append('tile %s is not 16 x 16' % n)
        for fam in TL.FAMILIES:
            leg = TL.legend(fam)
            if len(set(NAMED[leg[c]] for r in rows for c in r)) > 8:
                bad.append('tile %s: more than 8 colours' % n)
    return bad


def joins():
    """Every pair of forest tiles that may sit side by side: the cells either side of the join
    should agree (forest next to forest, open next to open) on at least 14 of the 16."""
    T = TL.tile_set()
    worst = 16
    forest = set('cknu')
    for a in TL.FOREST_MASKS:
        for b in TL.FOREST_MASKS:
            if (a[1], a[3]) != (b[0], b[2]):
                continue
            ra = T.get(TL.mask_name(a) or 'open_1')[0]
            rb = T.get(TL.mask_name(b) or 'open_1')[0]
            agree = sum((ra[y][15] in forest) == (rb[y][0] in forest) for y in range(16))
            worst = min(worst, agree)
    return worst


GROUNDS = ['Meadow', 'Ochre', 'Canopy', 'River', 'Road', 'Foam', 'Earth']
THINGS = ['Hot', 'Hot Core', 'Ink', 'Sight', 'Sight Lock', 'Zap', 'Zap Glow', 'Plum', 'Rust', 'Hull', 'Iron']


def contrast_table():
    return [(t, [contrast(C(t), C(g)) for g in GROUNDS]) for t in THINGS]


def colour_check(path):
    cv = PV.ingame()
    strip = Canvas(len(GROUNDS) * 30, len(THINGS) * 12 + 4, C('Ink'))
    for i, g in enumerate(GROUNDS):
        strip.rect(i * 30, 0, 29, strip.h, C(g))
        for j, t in enumerate(THINGS):
            strip.rect(i * 30 + 10, 4 + j * 12, 9, 7, C(t))
    ims = [cv.image(1), strip.image(1)]
    row = []
    for im in ims:
        w = sum([im.size[0]] * 4) + 24
        out = Image.new('RGB', (w, im.size[1]), C('Ink'))
        out.paste(im, (0, 0))
        for k, m in enumerate(MACHADO.values()):
            out.paste(simulate(im, m), ((im.size[0] + 8) * (k + 1), 0))
        row.append(out)
    W = max(r.size[0] for r in row)
    H = sum(r.size[1] for r in row) + 8
    final = Image.new('RGB', (W, H), C('Ink'))
    final.paste(row[0], (0, 0))
    final.paste(row[1], (0, row[0].size[1] + 8))
    final.resize((W * 2, H * 2), Image.NEAREST).save(path)
