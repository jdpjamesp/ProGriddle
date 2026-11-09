"""Checks run by the generator: the limits of the brief, contrast numbers, colour blindness, grey scale."""
from PIL import Image
from lib import Canvas, contrast, lum, put
from palette import C, NAMED, TONE, count_distinct  # noqa: F401
import sprites as SP
import screens as SC
import scene as S

MACHADO = {
    'deuteranopia': [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    'protanopia': [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    'tritanopia': [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

# the largest a sprite may be, by group; the close up keeper's two dives are wider than 24 on purpose (section 4.3)
SIZES = {'fig': (12, 12), 'ball': (5, 5), 'gm_keeper': (24, 32), 'gm_ball': (10, 10), 'ripple': (24, 16), 'badge': (16, 16),
         'face': (24, 24), 'icon': (8, 8), 'trophy': (32, 32), 'crowd': (32, 8)}
OVERHANG = {'gm_keeper_dive_right', 'gm_keeper_high_right'}


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


def case_clash(name, legend):
    """Letters that differ only by case in one legend (the game reads letters without regard to case)."""
    seen = {}
    for k in legend:
        seen.setdefault(k.lower(), []).append(k)
    return ['%s: legend letters %s differ only by case' % (name, ' and '.join(v)) for v in seen.values() if len(v) > 1]


def validate():
    bad = case_clash('goal_mouth', S.GM_LEGEND)
    for s in SP.FIGS.values():
        bad += case_clash(s.name, s.legend)
    for s in SP.ALL.values():
        for ch in s.used():
            if ch not in s.legend:
                bad.append('%s: %s not in legend' % (s.name, ch))
        for k, v in s.legend.items():
            if v not in NAMED:
                bad.append('%s: %s is not a palette name' % (s.name, v))
        bad += case_clash(s.name, s.legend)
        if len(s.legend) > 16:
            bad.append('%s: %d legend entries' % (s.name, len(s.legend)))
        mw, mh = SIZES[s.group]
        if s.name.startswith('fig_') or s.name.startswith('ref_') or s.name in ('gk_ready_1', 'gk_ready_2', 'gk_got_it'):
            mw = 8
        if (s.width > mw or s.height > mh) and s.name not in OVERHANG:
            bad.append('%s: %d x %d' % (s.name, s.width, s.height))
        if s.name.startswith('cab_') and (s.width > 12 or s.height > 16):
            bad.append('%s: %d x %d' % (s.name, s.width, s.height))
    for row in S.goal_mouth_rows():
        for ch in row:
            if ch not in S.GM_LEGEND:
                bad.append('goal mouth: %s' % ch)
    for v in NAMED.values():
        if len(v) != 6:
            bad.append('palette value %s' % v)
    return bad


def dist(a, b):
    rm = (a[0] + b[0]) / 2.0
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return ((2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db) ** 0.5


PAIRS = [  # things that must never be confused, and why
    ('White 3', 'Black 3', 'the two kits (they also differ by a hoop and pinstripes, and by the shorts)'),
    ('White 3', 'Keeper 3', 'the white kit and the keeper'),
    ('Black 3', 'Keeper 3', 'the black kit and the keeper'),
    ('Black 3', 'Grass A', 'the black kit on the grass'),
    ('White 3', 'Grass A', 'the white kit on the grass'),
    ('Chalk Green', 'Chalk Red', 'credit and debt, good and bad (they also differ by a sign or an icon)'),
    ('Chalk Green', 'Chalk Amber', 'fresh and weary (they also differ by the fill pattern)'),
    ('Chalk Amber', 'Chalk Red', 'weary and spent (pattern too)'),
    ('Chalk Yellow', 'Chalk Blue', 'your bar and theirs (the + or - mark too)'),
    ('Ball 3', 'Grass A', 'the ball on the grass'),
    ('Ball 3', 'Net', 'the ball against the net (pitch view)'),
    ('Ball 4', 'Night Haze', 'the close up ball against the back of the net'),
]


def separation():
    out = []
    for a, b, why in PAIRS:
        row = [a, b, why]
        for m in [None] + list(MACHADO.values()):
            ca, cb = C(a), C(b)
            if m:
                ca, cb = sim(ca, m), sim(cb, m)
            row.append(dist(ca, cb))
        out.append(row)
    return out


TEXTS = [('Chalk', 'Board'), ('Chalk', 'Board Stripe'), ('Chalk', 'Cursor Row'), ('Chalk Dim', 'Board'), ('Chalk Dim', 'Board Stripe'),
         ('Chalk Yellow', 'Board'), ('Chalk Yellow', 'Your Row'), ('Chalk Yellow', 'Cursor Row'), ('Chalk Green', 'Board'),
         ('Chalk Red', 'Board'), ('Chalk Red', 'Board Stripe'), ('Chalk Amber', 'Board'), ('Chalk Blue', 'Board'),
         ('Chalk', 'Tunnel'), ('Chalk Dim', 'Tunnel'), ('Chalk Yellow', 'Tunnel'), ('Chalk Green', 'Tunnel'),
         ('Chalk Red', 'Tunnel'), ('Chalk Blue', 'Tunnel'), ('Chalk Dim', 'Board Head'), ('Chalk Yellow', 'Board Head'),
         ('Title Bottom', 'Outline'), ('Chalk', 'Night')]


def text_contrast():
    return [(a, b, contrast(C(a), C(b))) for a, b in TEXTS]


def grey(im):
    return im.convert('L').convert('RGB')


def colour_check(path):
    ims = [SC.render('match').cv.image(1), SC.render('squad').cv.image(1), SC.render('kit').cv.image(1)]
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
    final.save(path)


if __name__ == '__main__':
    print('distinct colours', count_distinct())
    print('validate', validate() or 'passed')
    for row in separation():
        print(row[0], row[1], ' '.join('%.0f' % v for v in row[3:]))
    for a, b, c in text_contrast():
        print(a, 'on', b, '%.1f' % c)
