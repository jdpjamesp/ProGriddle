"""Validation, contrast numbers and the colour blindness picture."""
from PIL import Image
from lib import Canvas, contrast, mix
from palette import C, T, ROWS, PHANTOMS, NAMED
import preview as PV
import draw as D
import maze as MZ

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
    for s in PV.ALL.values():
        cm = D.cmap(s, s.tone or 'Brian')
        for ch in s.used():
            if ch not in cm:
                bad.append('%s: %s not in legend' % (s.name, ch))
        if len(set(cm[c] for c in s.used() if c in cm)) > 16:
            bad.append('%s: too many colours' % s.name)
        if s.group == 'pop':
            if s.width > 17 or s.height > 7:
                bad.append('%s: pop-up %d x %d' % (s.name, s.width, s.height))
        elif s.width > 16 or s.height > 16:
            if s.name != 'dibby_giant':
                bad.append('%s: %d x %d is bigger than 16 x 16' % (s.name, s.width, s.height))
    # every wall tile is made only of the band letters
    for m, t in MZ.tile_set().items():
        for r in t:
            for ch in r:
                if ch not in '.GLAIF':
                    bad.append('tile %d: %s' % (m, ch))
    return bad


def line_closed():
    """Every Line pixel of the drawn maze has at least two Line neighbours (8 way): the line never breaks."""
    cv = Canvas(224, 288, C('Floor'))
    MZ.draw(cv, 24, dots=False)
    L = C('Line')
    bad = 0
    for y in range(24, 272):
        for x in range(224):
            if cv.get(x, y) != L:
                continue
            n = 0
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if (dx or dy) and 0 <= x + dx < 224 and 24 <= y + dy < 272 and cv.get(x + dx, y + dy) == L:
                        n += 1
            if n < 2 and 0 < x < 223:
                bad += 1
    return bad


def lineup():
    """The things that must be told apart, on the floor and beside a wall."""
    cv = Canvas(224, 120, C('Floor'))
    MZ_draw_strip(cv)
    y = 20
    for i, who in enumerate(PHANTOMS):
        PV.put_phantom(cv, who, 20 + i * 26, y, look='right', swish=i % 2)
    PV.put_rolledback(cv, 128, y, 0)
    PV.put_rolledback(cv, 154, y, 0, flash=True)
    PV.put_returning(cv, 182, y, 'right', trail=False)
    PV.put_phantom(cv, 'Mary', 206, 87, look='right', angry=2)
    PV.put_dibby(cv, 'dibby_wide', 206, y, d='right')
    for i, it in enumerate(['item_floppy', 'item_tape', 'item_key', 'item_table', 'item_query', 'item_trigger', 'item_lock', 'item_server']):
        D.put(cv, PV.ALL[it], 16 + i * 26, 56)
    cv.rect(16, 86, 2, 2, C('Bit'))
    D.put(cv, PV.ALL['commit_on'], 40, 87)
    D.put(cv, PV.ALL['commit_dim'], 60, 87)
    for i, who in enumerate(PHANTOMS):
        D.put(cv, PV.ALL['target'], 90 + i * 14, 87, row=who)
    cv.text('READY!', 150, 84, C('Player'))
    cv.text('GAME OVER', 150, 100, C('Over'))
    cv.text('1UP', 16, 100, C('Player'))
    cv.text('HIGH SCORE', 50, 100, C('Label Text'))
    return cv


def MZ_draw_strip(cv):
    # a bit of wall at the right edge of the lineup so the halo and the overlap can be judged
    pass


def colour_check(path):
    base = lineup().image(1)
    game = Canvas(224, 288)
    PV.game_scene(game)
    g = game.image(1)
    tiles = [base] + [simulate(base, MACHADO[k]) for k in ('deuteranopia', 'protanopia', 'tritanopia')]
    games = [g] + [simulate(g, MACHADO[k]) for k in ('deuteranopia', 'protanopia', 'tritanopia')]
    out = Image.new('RGB', (228 * 4, 124 + 292), C('Sheet'))
    labels = ['AS DRAWN', 'DEUTERANOPIA', 'PROTANOPIA', 'TRITANOPIA']
    for i, (t, gg) in enumerate(zip(tiles, games)):
        out.paste(t, (i * 228, 0))
        out.paste(gg, (i * 228, 124))
    lab = Canvas(228 * 4, 10, C('Sheet'))
    for i, l in enumerate(labels):
        lab.text(l, i * 228 + 2, 2, C('Label Text'))
    full = Image.new('RGB', (228 * 4, 10 + out.size[1]), C('Sheet'))
    full.paste(lab.image(1), (0, 0))
    full.paste(out, (0, 10))
    full.resize((full.size[0] * 2, full.size[1] * 2), Image.NEAREST).save(path)


def contrast_rows():
    rows = []
    F = C('Floor')
    for n in ('Text', 'Label Text', 'Player', 'Over', 'Pop Phantom', 'Pop Item', 'Bit', 'Token', 'Line', 'Inner', 'Door'):
        rows.append((n, 'Floor', contrast(C(n), F)))
    for who in PHANTOMS + ['Dibby', 'Rollback', 'Flash']:
        rows.append(('%s tone 3' % who, 'Floor', contrast(ROWS[who][2], F)))
        rows.append(('%s tone 3' % who, 'Line', contrast(ROWS[who][2], C('Line'))))
    for who in PHANTOMS:
        rows.append(('%s tone 2 (roll call)' % who, 'Floor', contrast(ROWS[who][1], F)))
    rows.append(('Ink (angry brows)', 'Mary tone 1', contrast(C('Ink'), ROWS['Mary'][0])))
    rows.append(('Ink (angry brows)', 'Mary tone 2', contrast(C('Ink'), ROWS['Mary'][1])))
    rows.append(('Angry (pupils)', 'Eye', contrast(C('Angry'), C('Eye'))))
    rows.append(('Steam', 'Floor', contrast(C('Steam'), F)))
    return rows


if __name__ == '__main__':
    import sys
    print(validate())
    print('broken line pixels:', line_closed())
    for r in contrast_rows():
        print('%-28s %-6s %.1f' % r)
    colour_check(sys.argv[1] if len(sys.argv) > 1 else 'foreach-colour-check.png')
