"""The preview pictures, drawn from the same data as the doc."""
from PIL import Image
from lib import Canvas, mix, text_width, hx
from palette import C, T, ROWS, PHANTOMS
import maze as MZ
import dibby
import phantoms as G
import items as I
import ui as U
import draw as D

W, H = 224, 288
OY = 24          # the maze starts at canvas row 24
ALL = {}
for mod in (dibby, G, I, U):
    for s in mod.build():
        ALL[s.name] = s


def tile_centre(c, r):
    return c * 8 + 4, OY + r * 8 + 4


def between(c, r):
    """The point between tile c and c + 1 on row r (where Dibby and Brian start)."""
    return c * 8 + 8, OY + r * 8 + 4


def floorish(cv, x, y):
    if not (0 <= x < W and 0 <= y < H):
        return False
    return cv.get(x, y) in (C('Floor'), C('Floor Stud'), C('Tunnel'))


def halo(cv, rows, cx, cy, ox, oy, colour):
    """The glow: every empty pixel next to the sprite that lands on the floor gets the dim colour."""
    h, w = len(rows), len(rows[0])
    for j in range(-1, h + 1):
        for i in range(-1, w + 1):
            inside = 0 <= i < w and 0 <= j < h and rows[j][i] != '.'
            if inside:
                continue
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ii, jj = i + dx, j + dy
                if 0 <= ii < w and 0 <= jj < h and rows[jj][ii] != '.':
                    near = True
            x, y = cx - ox + i, cy - oy + j
            if near and floorish(cv, x, y):
                cv.put(x, y, colour)


def glow_colour(row):
    return mix(ROWS[row][2], C('Floor'), 0.72)


def put_dibby(cv, name, cx, cy, d='left'):
    s = ALL[name]
    halo(cv, D.turn(s.rows, d), cx, cy, 8, 8, glow_colour('Dibby'))
    D.put(cv, s, cx, cy, d=d)


def put_phantom(cv, who, cx, cy, swish=0, look='left', angry=0):
    body = ALL['phantom_body_%d' % (swish + 1)]
    halo(cv, body.rows, cx, cy, 8, 8, glow_colour(who))
    D.phantom(cv, G, who, cx, cy, swish, look, angry)


def put_rolledback(cv, cx, cy, wob=0, flash=False):
    s = ALL[('flash_%d' if flash else 'rolledback_%d') % (wob + 1)]
    halo(cv, s.rows, cx, cy, 8, 8, glow_colour('Rollback'))
    D.put(cv, s, cx, cy)


def put_returning(cv, cx, cy, d, trail=True):
    if trail:
        # three fading bubbles behind the eyes, 4 pixels apart
        dx, dy = {'left': (1, 0), 'right': (-1, 0), 'up': (0, 1), 'down': (0, -1)}[d]
        for k, t in ((1, 0.45), (2, 0.7), (3, 0.85)):
            x, y = cx + dx * (6 + 4 * k), cy + dy * (6 + 4 * k)
            c = mix(C('Eye'), C('Floor'), t)
            if floorish(cv, x, y):
                cv.put(x, y, c)
    D.put(cv, ALL['returning_%s' % d], cx, cy)


def put_item(cv, name, cx, cy):
    s = ALL[name]
    D.put(cv, s, cx, cy)


def text(cv, s, x, y, colour, k=1, outline=None):
    cv.text(s, x, y, colour, k, outline)


def centred(s, k=1):
    return (W - text_width(s, k)) // 2


def rtext(cv, s, right, y, colour, k=1):
    cv.text(s, right - text_width(s, k) + 1, y, colour, k)


def hud(cv, score='4370', high='12560', lives=2, level=5, blink_on=True):
    if blink_on:
        text(cv, '1UP', 24, 1, C('Player'))
    rtext(cv, score, 63, 9, C('Text'))
    text(cv, 'HIGH SCORE', 82, 1, C('Label Text'))
    rtext(cv, high, 136, 9, C('Text'))
    for i in range(lives):
        D.put(cv, ALL['dibby_life'], 16 + 6 + i * 14, 272 + 7)
    order = level_items(level)
    for i, name in enumerate(reversed(order)):
        D.put(cv, ALL[name], 208 - 8 - i * 16, 272 + 8)


LEVEL_ITEM = ['item_floppy', 'item_tape', 'item_key', 'item_key', 'item_table', 'item_table', 'item_query', 'item_query',
              'item_trigger', 'item_trigger', 'item_lock', 'item_lock', 'item_server']


def item_for(level):
    return LEVEL_ITEM[min(level, 13) - 1]


def level_items(level):
    """The level counter: the items of the last 7 levels, oldest on the left."""
    lv = list(range(max(1, level - 6), level + 1))
    return [item_for(l) for l in lv]


def tokens(cv, lit=True):
    for c, r in MZ.token_cells():
        x0, y0 = c * 8, OY + r * 8
        D.put(cv, ALL['commit_on' if lit else 'commit_dim'], x0 + 4, y0 + 4)


def bits_gone():
    """The bits Dibby has eaten in the preview: the start lane to the left and up the left side."""
    out = set()
    for c in range(5, 14):
        out.add((c, 23))
    for r in range(20, 24):
        out.add((5, r))
    for c in range(1, 14):
        out.add((c, 20))
    for c in range(14, 23):
        out.add((c, 20))
    for r in range(8, 20):
        out.add((5, r))
    return out


def game_scene(cv, rolledback=False):
    cv.rect(0, 0, W, H, C('Floor'))
    MZ.draw(cv, OY, eaten=bits_gone())
    tokens(cv, lit=True)
    hud(cv)
    # the item under the lobby
    if not rolledback:
        put_item(cv, 'item_table', *between(13, 17))
    if not rolledback:
        put_dibby(cv, 'dibby_wide', *tile_centre(5, 9), d='up')
        put_phantom(cv, 'Mary', *tile_centre(5, 14), swish=0, look='up', angry=1)
        put_phantom(cv, 'Rich', *tile_centre(10, 8), swish=1, look='left')
        put_phantom(cv, 'Brian', *tile_centre(20, 23), swish=0, look='left')
        put_phantom(cv, 'Chip', *between(13, 14), swish=1, look='up')
    else:
        for c in range(1, 6):
            cv.rect(c * 8 + 3, OY + 5 * 8 + 3, 2, 2, C('Floor'))
        for r in range(1, 5):
            cv.rect(1 * 8 + 3, OY + r * 8 + 3, 2, 2, C('Floor'))
        cv.rect(1 * 8 + 1, OY + 3 * 8 + 1, 6, 6, C('Floor'))   # the commit token Dibby just ate
        put_dibby(cv, 'dibby_half', *tile_centre(5, 5), d='right')
        put_rolledback(cv, *tile_centre(12, 5), wob=0)
        put_rolledback(cv, *tile_centre(22, 8), wob=1, flash=True)
        put_rolledback(cv, *tile_centre(22, 14), wob=0)
        put_returning(cv, *tile_centre(17, 11), d='left')
        D.put(cv, ALL['pop_400'], *tile_centre(8, 5))


def ready_scene(cv):
    cv.rect(0, 0, W, H, C('Floor'))
    MZ.draw(cv, OY)
    tokens(cv)
    hud(cv, score='00', high='12560', lives=2, level=1)
    put_dibby(cv, 'dibby_closed', *between(13, 23), d='left')
    put_phantom(cv, 'Mary', *between(13, 11), look='left')
    put_phantom(cv, 'Rich', *between(13, 14), look='down', swish=1)
    put_phantom(cv, 'Brian', 96, OY + 14 * 8 + 4, look='up')
    put_phantom(cv, 'Chip', 128, OY + 14 * 8 + 4, look='up', swish=1)
    text(cv, 'READY!', centred('READY!'), OY + 17 * 8, C('Player'))
    text(cv, 'PLAYER ONE', centred('PLAYER ONE'), OY + 11 * 8, C('Pop Phantom'))


def over_scene(cv):
    cv.rect(0, 0, W, H, C('Floor'))
    MZ.draw(cv, OY, eaten=bits_gone())
    tokens(cv)
    hud(cv, lives=0, blink_on=True)
    text(cv, 'GAME OVER', centred('GAME OVER'), OY + 17 * 8, C('Over'))


def flash_scene(cv, white):
    cv.rect(0, 0, W, H, C('Floor'))
    MZ.draw(cv, OY, flash=white, dots=False)
    hud(cv, score='6820')
    put_dibby(cv, 'dibby_happy' if white else 'dibby_half', *tile_centre(18, 26), d='right')


def debug_scene(cv):
    game_scene(cv)
    # targets: Mary aims at Dibby's tile, Rich 4 ahead, Brian the doubled vector from Mary, Chip his corner
    hx_, hy_ = (5, 9)
    targets = {'Mary': ((5, 14), (5, 9)), 'Rich': ((10, 8), (5, 5)), 'Brian': ((20, 23), (5, 0)), 'Chip': ((13.5, 14), (0, 33))}
    for who, (frm, to) in targets.items():
        fx, fy = int(frm[0] * 8 + 4), OY + frm[1] * 8 + 4
        tc, tr = to
        tx, ty = int(tc * 8 + 4), OY + tr * 8 + 4
        dotted(cv, fx, fy, tx, ty, T(who, 2))
        tx = min(max(tx, 2), W - 3)
        ty = min(max(ty, 2), H - 3)
        D.put(cv, ALL['target'], tx, ty, row=who)


def dotted(cv, x0, y0, x1, y1, colour):
    """Bresenham, every other pixel drawn (1 on, 1 off), skipping the first 8 pixels (inside the phantom)."""
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    n = 0
    x, y = x0, y0
    while True:
        if n >= 8 and n % 2 == 0 and 0 <= x < W and 0 <= y < H:
            cv.put(x, y, colour)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy
        n += 1


ROLL = [('Mary', 'CHASER'), ('Rich', 'AMBUSH'), ('Brian', 'FICKLE'), ('Chip', 'SHY')]


def title_scene(cv, step=99):
    cv.rect(0, 0, W, H, C('Floor'))
    hud(cv, score='00', lives=0, level=0, blink_on=False) if False else None
    text(cv, '1UP', 24, 1, C('Player'))
    rtext(cv, '00', 63, 9, C('Text'))
    text(cv, 'HIGH SCORE', 82, 1, C('Label Text'))
    rtext(cv, '12560', 136, 9, C('Text'))
    # the logo: FOR EACH at 3x in the title gradient with an outline, and giant Dibby beside it
    cv.text('FOR', centred('FOR', 3), 30, C('Title Top'), 3, C('Outline'), C('Title Bottom'))
    cv.text('EACH', centred('EACH', 3), 56, C('Title Top'), 3, C('Outline'), C('Title Bottom'))
    D.put(cv, ALL['dibby_giant'], 186, 54)
    text(cv, 'PHANTOM', 34, 92, C('Label Text'))
    text(cv, 'NAME', 98, 92, C('Label Text'))
    text(cv, 'STYLE', 148, 92, C('Label Text'))
    for i, (who, style) in enumerate(ROLL):
        if step < i:
            break
        y = 108 + i * 22
        put_phantom(cv, who, 26, y + 3, look='right', swish=i % 2)
        text(cv, who.upper(), 98, y, T(who, 2))
        text(cv, style, 148, y, T(who, 2))
    # the points table
    y = 200
    cv.rect(77, y + 2, 2, 2, C('Bit'))
    text(cv, '10 PTS', 90, y, C('Text'))
    D.put(cv, ALL['commit_on'], 78, y + 15)
    text(cv, '50 PTS', 90, y + 12, C('Text'))
    # the chase demo lane: Dibby with a commit token eaten, chasing rolled back phantoms
    ly = 248
    put_dibby(cv, 'dibby_wide', 40, ly, d='right')
    put_rolledback(cv, 76, ly, 0)
    put_rolledback(cv, 96, ly, 1)
    put_rolledback(cv, 116, ly, 0, flash=True)
    put_rolledback(cv, 136, ly, 1)
    text(cv, 'PUSH START', centred('PUSH START'), 268, C('Player'))
    text(cv, 'CREDIT  0', 4, 280, C('Label Text'))


def sheet(path, scale=4):
    names = list(ALL)
    cols = 12
    cw, ch = 36, 36
    rows = (len(names) + cols - 1) // cols
    cv = Canvas(cols * cw, rows * ch, C('Sheet'))
    for i, n in enumerate(names):
        s = ALL[n]
        x = (i % cols) * cw + (cw - s.width) // 2
        y = (i // cols) * ch + (ch - s.height) // 2
        row = s.tone
        if s.group == 'phantom':
            row = PHANTOMS[(i) % 4]
        D.put(cv, s, x + s.origin[0], y + s.origin[1], row=row)
    cv.image(scale).save(path)


def save(cvs, path, scale=3, gap=6):
    ims = [c.image(scale) for c in cvs]
    w = sum(im.size[0] for im in ims) + gap * scale * (len(ims) - 1)
    out = Image.new('RGB', (w, ims[0].size[1]), C('Sheet'))
    x = 0
    for im in ims:
        out.paste(im, (x, 0))
        x += im.size[0] + gap * scale
    out.save(path)


def main(outdir):
    import os
    j = lambda n: os.path.join(outdir, n)
    cv = Canvas(W, H); game_scene(cv); save([cv], j('foreach-preview.png'))
    a = Canvas(W, H); title_scene(a)
    save([a], j('foreach-preview-title.png'))
    a = Canvas(W, H); game_scene(a, rolledback=True)
    b = Canvas(W, H); debug_scene(b)
    save([a, b], j('foreach-preview-rolledback.png'))
    a = Canvas(W, H); flash_scene(a, False)
    b = Canvas(W, H); flash_scene(b, True)
    save([a, b], j('foreach-preview-flash.png'))
    a = Canvas(W, H); ready_scene(a)
    b = Canvas(W, H); over_scene(b)
    save([a, b], j('foreach-preview-ready-over.png'))
    sheet(j('foreach-sprites.png'))
    cartoons(j('foreach-cartoons.png'))




# ---------------------------------------------------------------- the three cartoons
CART_H = 40
CART_Y = 24      # the lane (character centre row) inside a strip


def strip():
    cv = Canvas(W, CART_H, C('Floor'))
    return cv


def cartoon_frames():
    """Key frames of the three cartoons, as (title, [canvas, ...]) with 4 strips each."""
    y = CART_Y
    out = []
    # 1 DEADLOCK: Mary chases Dibby, Rich comes the other way, Dibby ducks, they bonk and lock
    f = []
    a = strip(); put_dibby(a, 'dibby_wide', 120, y, d='right'); put_phantom(a, 'Mary', 80, y, look='right'); f.append(a)
    a = strip(); put_dibby(a, 'dibby_half', 112, y, d='right'); put_phantom(a, 'Mary', 84, y, look='right', swish=1)
    put_phantom(a, 'Rich', 150, y, look='left'); f.append(a)
    a = strip(); D.put(a, ALL['crash_5'], 112, y); put_phantom(a, 'Mary', 104, y - 8, look='right'); put_phantom(a, 'Rich', 120, y - 8, look='left', swish=1)
    D.put(a, ALL['stars'], 112, y - 20); f.append(a)
    a = strip(); put_phantom(a, 'Mary', 104, y - 4, look='right'); put_phantom(a, 'Rich', 120, y - 4, look='left', swish=1)
    D.put(a, ALL['item_lock'], 112, y - 16); put_dibby(a, 'dibby_happy', 170, y, d='right'); f.append(a)
    out.append(('DEADLOCK', f))
    # 2 ROLLBACK: Brian chases Dibby, Dibby turns, Brian is played backwards off the screen, twice
    f = []
    a = strip(); put_dibby(a, 'dibby_wide', 140, y, d='right'); put_phantom(a, 'Brian', 100, y, look='right'); f.append(a)
    a = strip(); put_dibby(a, 'dibby_half', 140, y, d='left'); put_phantom(a, 'Brian', 116, y, look='right', swish=1)
    text(a, 'UNDO', 128, 4, C('Player')); f.append(a)
    a = strip(); put_dibby(a, 'dibby_happy', 140, y, d='left'); put_phantom(a, 'Brian', 80, y, look='right')
    D.put(a, ALL['rewind'], 96, y); D.put(a, ALL['rewind'], 104, y); f.append(a)
    a = strip(); put_dibby(a, 'dibby_wide', 120, y, d='left'); put_phantom(a, 'Brian', 14, y, look='right', swish=1)
    D.put(a, ALL['rewind'], 30, y); f.append(a)
    out.append(('ROLLBACK', f))
    # 3 NIGHT BATCH: Chip, the shy one, has hidden away for a nap; the other three crash into him, all four in a heap
    f = []
    a = strip(); D.phantom(a, G, 'Chip', 60, y, 0, 'down'); D.put(a, ALL['zz'], 66, y - 8); put_dibby(a, 'dibby_half', 20, y, d='right'); f.append(a)
    a = strip(); D.phantom(a, G, 'Chip', 112, y, 1, 'down'); D.put(a, ALL['zz'], 118, y - 8)
    for i, who in enumerate(('Mary', 'Rich', 'Brian')):
        put_phantom(a, who, 30 + i * 18, y, look='right', swish=i % 2)
    f.append(a)
    a = strip(); D.phantom(a, G, 'Chip', 112, y + 4, 1, 'down')
    put_phantom(a, 'Mary', 100, y - 2, look='right'); put_phantom(a, 'Rich', 124, y - 4, look='left', swish=1); put_phantom(a, 'Brian', 112, y - 12, look='down')
    D.put(a, ALL['stars'], 112, y - 24); f.append(a)
    a = strip(); D.phantom(a, G, 'Chip', 112, y + 4, 0, 'down'); D.put(a, ALL['zz'], 118, y - 6)
    D.put(a, ALL['rolledback_1'], 96, y + 2); D.put(a, ALL['rolledback_2'], 128, y + 2); D.put(a, ALL['rolledback_1'], 112, y - 10)
    put_dibby(a, 'dibby_happy', 190, y, d='left'); f.append(a)
    out.append(('NIGHT BATCH', f))
    return out


def cartoons(path, scale=3):
    fr = cartoon_frames()
    rows = len(fr)
    out = Image.new('RGB', (W * 2 * scale + 4 * scale, (CART_H * 2 + 4) * rows * scale + 10 * scale * rows), C('Sheet'))
    yy = 0
    for title, strips in fr:
        lab = Canvas(W * 2 + 4, 10, C('Sheet'))
        lab.text(title, 2, 2, C('Label Text'))
        out.paste(lab.image(scale), (0, yy))
        yy += 10 * scale
        for i, s in enumerate(strips):
            x = (i % 2) * (W + 4) * scale
            y = yy + (i // 2) * (CART_H + 4) * scale
            out.paste(s.image(scale), (x, y))
        yy += (CART_H * 2 + 4) * scale
    out.save(path)


if __name__ == '__main__':
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
