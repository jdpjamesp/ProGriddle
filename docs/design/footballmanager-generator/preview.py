"""Draws every preview picture from the same data as the design file."""
import os
from PIL import Image
from lib import Canvas, put, mirror, text_width
from palette import C
import sprites as SP
import scene as S
import screens as SC
import goalmouth as G
import sheet

PREFIX = 'footballmanager'


def put_c(cv, name, cx, cy, flip=False):
    s = SP.ALL[name]
    ox, oy = s.origin
    if flip:
        ox = s.width - 1 - ox
    put(cv, s, cx - ox, cy - oy, rows=mirror(s.rows) if flip else None)


def gm_cell(kind, c=1, r=1, step=None, cheer=False):
    """One goal mouth picture (96 x 64) for an outcome."""
    cv = Canvas(96, 64, C('Night'))
    S.goal_mouth(cv, 0, 0, 1 if cheer else 0)
    if kind == 'ready':
        put_c(cv, 'gm_keeper_ready', *S.KEEPER_FEET)
        if step is not None:
            b, bx, by = G.flight(S.GM_TX[c], S.GM_TY[r])[step]
            put_c(cv, b, bx, by)
        return cv
    if kind == 'save':
        name, flip, ox, oy = G.save_pose(c, r)
        put_c(cv, name, ox, oy, flip)
        if name != 'gm_keeper_hold':
            put_c(cv, 'gm_ball_mid', S.GM_TX[c], S.GM_TY[r])
            put_c(cv, name, ox, oy, flip) if False else None
        return cv
    if kind == 'goal':
        name, flip, ox, oy = G.beaten_pose(c, r)
        tx, ty = S.GM_TX[c], S.GM_TY[r]
        put_c(cv, 'gm_ripple_%d' % (step or 2), tx, ty)
        put_c(cv, name, ox, oy, flip)
        put_c(cv, 'gm_ball_far', tx, ty)
        return cv
    if kind in S.GM_WIDE:
        tx, ty = S.GM_WIDE[kind]
        if kind == 'over':
            put_c(cv, 'gm_keeper_jump', 48, 54)
        else:
            right = kind.endswith('right')
            name, flip, ox, oy = G.save_pose(2 if right else 0, 1)
            put_c(cv, name, ox + (-6 if right else 6), oy, flip)
        put_c(cv, 'gm_ball_far', tx, ty)
        if kind.startswith('post'):
            for dx, dy, n in ((-3, -3, 'Spark'), (3, -3, 'Spark Warm'), (0, -4, 'Spark'), (-4, 1, 'Spark Gold'), (4, 1, 'Spark Gold')):
                cv.put(tx + dx, ty + dy, C(n))
        return cv


def goalmouth_sheet():
    pad = 6
    cv = Canvas(5 * (96 + pad) + pad, 4 * (64 + pad + 10) + pad, C('Tunnel'))

    def place(img, i, j, label):
        x, y = pad + i * (96 + pad), pad + j * (64 + pad + 10)
        for yy in range(64):
            for xx in range(96):
                cv.put(x + xx, y + yy, img.get(xx, yy))
        cv.small(label, x, y + 66, C('Chalk Dim'))
    for r in range(3):
        for c in range(3):
            place(gm_cell('save', c, r), c, r, 'SAVE %s %s' % (G.ROWS[r].upper(), G.COLS[c].upper()))
    place(gm_cell('goal', 0, 0, 2, True), 3, 0, 'GOAL HIGH LEFT')
    place(gm_cell('goal', 2, 2, 3, True), 4, 0, 'GOAL LOW RIGHT')
    place(gm_cell('wide_right'), 3, 1, 'WIDE RIGHT')
    place(gm_cell('over'), 4, 1, 'OVER THE BAR')
    place(gm_cell('post_left'), 3, 2, 'OFF THE POST')
    place(gm_cell('goal', 1, 1, 1, True), 4, 2, 'GOAL MIDDLE')
    for k in range(5):
        if k < 3:
            img = gm_cell('ready', 2, 0, step=k)
            lab = 'SHOT %d: %s' % (k + 1, ['NEAR', 'MID', 'FAR'][k])
        else:
            img = gm_cell('goal', 0, 1, k - 2, True) if k == 3 else gm_cell('goal', 0, 1, 3, True)
            lab = 'RIPPLE %d' % (k - 2) if k == 3 else 'RIPPLE 3'
        place(img, k, 3, lab)
    return cv


def screens_sheet():
    keys = [('setup1', {}), ('setup2', {}), ('kit', {}), ('menu', {}), ('pick', {}), ('results', {}), ('money', {}),
            ('offer', {}), ('offer', {'result': 'no'}), ('sell', {}), ('cup', {}), ('match', {'side': 'left', 'inset': False}), ('fulltime', {}), ('season', {}),
            ('sacked', {}), ('paused', {}), ('cabinet', {})]
    cols = 4
    rows = (len(keys) + cols - 1) // cols
    big = Image.new('RGB', (cols * 328 * 2, rows * 248 * 2), C('Outline'))
    for i, (k, kw) in enumerate(keys):
        im = SC.render(k, **kw).cv.image(2)
        big.paste(im, ((i % cols) * 328 * 2 + 8, (i // cols) * 248 * 2 + 8))
    return big


DIV_LOOK = [  # division, the frame's inlay ring (ring 3 of FRAME), the title band's star, crowd tiles lit of every 4
    (4, 'Wood 2', False, 1),
    (3, 'Silver 3', False, 2),
    (2, 'Gold 3', False, 3),
    (1, 'Gold 1', True, 4),
]


def later_sheet():
    cv = Canvas(320, 4 * 34 + 4 * 44 + 4, C("Night"))
    y = 4
    for div, inlay, star, lit in DIV_LOOK:
        for i, n in enumerate(S.FRAME):
            if i == 2:
                n = inlay
            cv.rect(i, y + i, 320 - 2 * i, 30 - 2 * i, C(n))
        cv.rect(4, y + 4, 312, 22, C('Board Head'))
        cv.text('DIVISION %d' % div, 10, y + 11, C('Chalk Yellow'))
        if star:
            put(cv, SP.ALL['mark_star'], 76, y + 10)
            put(cv, SP.ALL['mark_star'], 300, y + 10)
        put(cv, SP.ALL['badge_tower'], 150, y + 7)
        # the badge's ring in the inlay colour
        for k in range(16):
            cv.put(149 + k, y + 6, C(inlay))
            cv.put(149 + k, y + 23, C(inlay))
        cv.small('INLAY ' + inlay.upper(), 200, y + 12, C('Chalk Dim'))
        y += 34
    # the stand at 4 sizes: crowd tiles lit (others are empty seats)
    for div, inlay, star, lit in DIV_LOOK:
        cv.rect(0, y, 320, 40, C('Night'))
        tiers = {4: 1, 3: 2, 2: 2, 1: 3}[div]
        top = y + 40 - (tiers * 9 + 9)
        cv.rect(0, top, 320, 2, C('Roof'))
        cv.rect(0, top + 2, 320, 1, C('Roof Edge'))
        cv.rect(0, top + 3, 320, tiers * 9 + 6, C('Stand'))
        for t in range(tiers):
            for k, x in enumerate(range(0, 320, 32)):
                if (k + t) % 4 < lit:
                    put(cv, SP.ALL['crowd_1'], x, top + 4 + t * 9)
                else:
                    for yy in range(8):
                        for xx in range(32):
                            if yy % 4 == 2 and xx % 4 < 2:
                                cv.put(x + xx, top + 4 + t * 9 + yy, C('Wall'))
        S.hoard(cv, y + 36)
        if div <= 2:
            for fx in (8, 306):
                S.floodlight(cv, fx, top - 6)
        cv.small('DIVISION %d' % div, 4, y + 2, C('Chalk Dim'))
        y += 44
    return cv


def main(out):
    def save(cv, name, k=3):
        cv.image(k).save(os.path.join(out, '%s-%s.png' % (PREFIX, name)) if name else os.path.join(out, PREFIX + '.png'))
    SC.render('match').cv.image(3).save(os.path.join(out, PREFIX + '-preview.png'))
    SC.render('match', side='left').cv.image(3).save(os.path.join(out, PREFIX + '-preview-left.png'))
    SC.render('table').cv.image(3).save(os.path.join(out, PREFIX + '-preview-table.png'))
    SC.render('squad').cv.image(3).save(os.path.join(out, PREFIX + '-preview-squad.png'))
    SC.render('title').cv.image(3).save(os.path.join(out, PREFIX + '-preview-title.png'))
    screens_sheet().save(os.path.join(out, PREFIX + '-screens.png'))
    goalmouth_sheet().image(3).save(os.path.join(out, PREFIX + '-goalmouth.png'))
    later_sheet().image(2).save(os.path.join(out, PREFIX + '-later.png'))
    sheet.sheet().image(4).save(os.path.join(out, PREFIX + '-sprites.png'))


if __name__ == '__main__':
    import sys
    main(sys.argv[1])
