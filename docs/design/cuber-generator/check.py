"""Checks run by the generator: the limits of the brief, contrast numbers, colour blindness, grey scale."""
from PIL import Image
from lib import Canvas, contrast, lum, put_c
from palette import C, NAMED, TONE, THEMES, hx, count_distinct  # noqa: F401
import sprites as SP
import preview as PV
import scene as S

MACHADO = {
    'deuteranopia': [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    'protanopia': [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    'tritanopia': [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

# the largest a sprite's picture may be, by group; the Coil's picture is bigger than its 12 x 14 box on purpose
SIZES = {'pip': (12, 14), 'coil': (16, 24), 'ball': (10, 10), 'moth': (12, 12), 'halo': (24, 16), 'icon': (8, 8), 'fx': (80, 40)}


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
    for s in SP.ALL.values():
        for ch in s.used():
            if ch not in s.legend:
                bad.append('%s: %s not in legend' % (s.name, ch))
        if len(s.legend) > 16:
            bad.append('%s: %d legend entries' % (s.name, len(s.legend)))
        mw, mh = SIZES[s.group]
        if s.width > mw or s.height > mh:
            bad.append('%s: %d x %d' % (s.name, s.width, s.height))
    # the three lamp states must be in order of brightness in every theme (grey scale)
    for half, done, name in THEMES:
        a, b, c = lum(hx(TONE['Unlit'][2])), lum(hx(TONE[half][2])), lum(hx(TONE[done][2]))
        if not (a < b < c) or c / b < 1.8 or b / a < 1.5:
            bad.append('theme %s: luminance %.3f %.3f %.3f' % (name, a, b, c))
    return bad


def dist(a, b):
    """A rough perceptual distance (redmean), 0 to about 765."""
    rm = (a[0] + b[0]) / 2.0
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return ((2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db) ** 0.5


def separation():
    """The smallest distance, per vision, between the things that must never be confused."""
    keys = ['Pip 3', 'Coil 3', 'Ember', 'Thorn 3', 'Frost 3', 'Snuff 3', 'Puff 3', 'Halo 3']
    out = {}
    for vname, m in [('normal', None)] + list(MACHADO.items()):
        worst = None
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                ca, cb = C(a), C(b)
                if m:
                    ca, cb = sim(ca, m), sim(cb, m)
                d = dist(ca, cb)
                if worst is None or d < worst[0]:
                    worst = (d, a, b)
        out[vname] = worst
    return out


def state_lum():
    return [(name, lum(hx(TONE['Unlit'][2])), lum(hx(TONE[half][2])), lum(hx(TONE[done][2]))) for half, done, name in THEMES]


GROUNDS = ['Dusk A', 'Dusk C', 'Unlit 3', 'Mint Half 3', 'Mint 3']
THINGS = ['Pip 3', 'Pip 5', 'Coil 3', 'Ember', 'Thorn 3', 'Frost 3', 'Frost 5', 'Snuff 3', 'Puff 3', 'Halo 3']
TEXTS = [('Text', 'HUD'), ('Label', 'HUD'), ('Gold', 'HUD'), ('Text', 'Plate'), ('Gold', 'Plate'), ('Over Bottom', 'Plate'),
         ('Gold', 'Outline'), ('Label', 'Void Top'), ('Title Bottom', 'Outline')]


def contrast_table():
    return [(t, [contrast(C(t), C(g)) for g in GROUNDS]) for t in THINGS]


def text_contrast():
    return [(a, b, contrast(C(a), C(b))) for a, b in TEXTS]


def grey(im):
    return im.convert('L').convert('RGB')


def colour_check(path):
    ims = [PV.ingame().image(1), PV.screens_frozen().image(1)]
    sw = Canvas(256, 120, C('Dusk B'))
    for t, (half, done, _) in enumerate(THEMES):
        for k, st in enumerate(('unlit', 'half', 'done')):
            S.draw_cube(sw, 4 + t * 64 + (k % 2) * 30, 4 + k * 12 + (k // 2) * 20, st, t)
    for i, n in enumerate(['pip_stand_dr', 'coil_stand_dr', 'thorn_2', 'frost_2', 'seed_2', 'moth_dr_3']):
        put_c(sw, SP.ALL[n], 20 + i * 40, 116)
    ims.append(sw.image(1))
    rows = []
    for im in ims:
        w = im.size[0] * 5 + 32
        out = Image.new('RGB', (w, im.size[1]), C('Outline'))
        out.paste(im, (0, 0))
        for k, m in enumerate(MACHADO.values()):
            out.paste(simulate(im, m), ((im.size[0] + 8) * (k + 1), 0))
        out.paste(grey(im), ((im.size[0] + 8) * 4, 0))
        rows.append(out)
    W = max(r.size[0] for r in rows)
    H = sum(r.size[1] for r in rows) + 8 * (len(rows) - 1)
    final = Image.new('RGB', (W, H), C('Outline'))
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
    for r in state_lum():
        print(r[0], ' '.join('%.3f' % x for x in r[1:]))
    for t, cs in contrast_table():
        print(t, ' '.join('%.1f' % c for c in cs))
    for a, b, c in text_contrast():
        print(a, 'on', b, '%.1f' % c)
