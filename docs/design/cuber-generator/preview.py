"""The preview pictures, drawn from the same data as the doc."""
import os
import random
from lib import Canvas, put, put_c, text_width
from palette import C, TONE, hx, THEMES
import scene as S
import sprites as SP

A = SP.ALL


# ---- helpers ---------------------------------------------------------------------------------------------------------
def row_legend(spr, row):
    """Draw spr with its tone digits taken from another row (a moth as Puff, a puff in Rose...)."""
    return {str(i + 1): hx(TONE[row][i]) for i in range(5)}


def frozen(spr):
    """The frozen tint rule: every tone digit takes the Ice row; dark letters take Ice 5, the rest Ice 1."""
    m = {str(i + 1): hx(TONE['Ice'][i]) for i in range(5)}
    for k in spr.legend:
        if not k.isdigit():
            m[k] = hx(TONE['Ice'][4]) if k in 'BKFYE' else hx(TONE['Ice'][0])
    return m


def centred(s, k=1, w=256):
    return (w - text_width(s, k)) // 2


def hud(cv, score, hi, lives, level, rnd, theme):
    cv.text('SCORE', 8, 4, C('Label'))
    cv.text('%06d' % score, 8, 13, C('Text'), k=2)
    s = 'HI %06d' % hi
    x = centred(s)
    cv.text('HI', x, 4, C('Label'))
    cv.text('%06d' % hi, x + 18, 4, C('Text'))
    n = lives
    x0 = 128 - (10 * n - 2) // 2
    for i in range(n):
        put(cv, A['pip_icon'], x0 + 10 * i, 16)
    cv.text('LEVEL', 182, 4, C('Label'))
    cv.text(str(level), 218, 4, C('Text'))
    cv.text('ROUND', 182, 16, C('Label'))
    cv.text(str(rnd), 218, 16, C('Text'))
    S.draw_cube(cv, 232, 8, 'done', theme, size=16)


def pop(cv, s, x, y):
    cv.text(s, x - text_width(s) // 2, y, C('Gold'), outline=C('Outline'))


def particles(cv, seed=4):
    rnd = random.Random(seed)
    # far sky lanterns
    for x, y in ((22, 70), (236, 112), (40, 150), (214, 60)):
        cv.put(x, y + 3, C('Lantern Dim'))
        cv.put(x, y + 4, C('Lantern Dim'))
        cv.rect(x, y, 2, 3, C('Lantern'))
        cv.put(x - 1, y + 1, C('Lantern Dim'))
        cv.put(x + 2, y + 1, C('Lantern Dim'))
    # motes falling into the void, under the pyramid
    for _ in range(14):
        x, y = rnd.randrange(10, 246), rnd.randrange(228, 254)
        cv.put(x, y, C('Mote'))
        cv.put(x, y - 1, C('Mote'))


def hop_point(a, b, t, h=12):
    (x0, y0), (x1, y1) = a, b
    return round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t - 4 * h * t * (1 - t))


def shadow(cv, r, c, theme, states):
    st = states.get((r, c), 'unlit')
    _, row = S.cube_colours(st, theme)
    fx, fy = S.foot_xy(r, c)
    put_c(cv, A['shadow'], fx, fy + 1, override={'S': hx(TONE[row][3])})


def halos(cv, waiting, gone=(), k=1, theme=0):
    spots = {(side, r): (x, y) for side, r, x, y in S.disc_spots()}
    for key in waiting:
        x, y = spots[key]
        put_c(cv, A['halo_%d' % k], x, y)
    for key in gone:
        x, y = spots[key]
        put_c(cv, A['halo_gone'], x, y)


# ---- the screens -----------------------------------------------------------------------------------------------------
def ingame_states():
    st = {}
    lit = [(1, 0), (2, 0), (2, 1), (3, 0), (3, 1), (4, 1), (4, 0), (5, 1)]
    half = [(3, 2), (4, 2), (5, 0), (5, 2), (6, 1), (6, 2), (4, 3)]
    for rc in lit:
        st[rc] = 'done'
    for rc in half:
        st[rc] = 'half'
    return st


def ingame(theme=0, hi=24800):
    cv = S.background(theme)
    particles(cv)
    st = ingame_states()
    S.pyramid(cv, st, theme)
    hud(cv, 4325, hi, 2, 2, 1, theme)
    halos(cv, [('left', 3), ('left', 5), ('right', 4), ('right', 5)], gone=[('left', 4)], k=2)
    # the lit glint on the lamp Pip just left, and its points
    x, y = S.cube_xy(5, 1)
    put(cv, A['glint_2'], x, y)
    fx, fy = S.foot_xy(5, 1)
    pop(cv, '25', fx, fy - 26)
    # Pip mid hop from (5, 1) to (6, 2): shadow on the target lamp
    shadow(cv, 6, 2, theme, st)
    px, py = hop_point(S.foot_xy(5, 1), S.foot_xy(6, 2), 0.5)
    put_c(cv, A['pip_hop_dr_2'], px, py)
    # the Coil on (3, 2), hunting
    put_c(cv, A['coil_stand_dr'], *S.foot_xy(3, 2))
    # a Thorn bouncing on (6, 4), a Frost on (4, 3)? keep the Frost far: (7, 5)
    put_c(cv, A['thorn_2'], *S.foot_xy(6, 4))
    put_c(cv, A['frost_1'], *S.foot_xy(7, 5))
    # Snuff on the left edge
    put_c(cv, A['moth_ur_3'], *S.foot_xy(7, 0))
    return cv


def plate(cv, y0, h):
    cv.rect(0, y0, 256, h, C('Plate'))
    cv.rect(0, y0, 256, 1, C('Plate Rule'))
    cv.rect(0, y0 + h - 1, 256, 1, C('Plate Rule'))


def gameover():
    cv = ingame(hi=4325)
    plate(cv, 100, 56)
    cv.text('GAME OVER', centred('GAME OVER', 3), 108, C('Over Top'), k=3, bottom=C('Over Bottom'))
    s = 'NEW HIGH SCORE'
    cv.text(s, centred(s), 136, C('Gold'))
    s = '004325'
    cv.text(s, centred(s, 1), 146, C('Text'))
    return cv


TITLE = 'LAMPLIGHTER'


def title(step=10):
    """The title: the intro has Pip hop down the pyramid once, lighting a path; `step` is how far it has got."""
    cv = S.background(0)
    particles(cv, 9)
    path = [(1, 0), (2, 1), (3, 1), (4, 2), (5, 2), (6, 3), (7, 3)]
    st = {rc: 'done' for rc in path[:min(step, len(path))]}
    S.pyramid(cv, st, 0)
    hi = 'HI %06d' % 24800
    x = centred(hi)
    cv.text('HI', x, 4, C('Label'))
    cv.text('%06d' % 24800, x + 18, 4, C('Text'))
    cv.text(TITLE, centred(TITLE, 3), 16, C('Title Top'), k=3, outline=C('Outline'), bottom=C('Title Bottom'))
    k = min(step, len(path)) - 1
    if k >= 0:
        r, c = path[k]
        put_c(cv, A['pip_stand_dr'], *S.foot_xy(r, c))
    halos(cv, [('left', 4), ('right', 4)], k=1)
    cv.text('PRESS SPACE', centred('PRESS SPACE', 2), 228, C('Gold'), k=2, outline=C('Outline'))
    s = 'ARROWS HOP   P PAUSE'
    cv.text(s, centred(s), 246, C('Label'))
    return cv


def screens():
    """Four small screens side by side at 1x: READY, the level clear ripple, PAUSED, a freeze."""
    out = Canvas(256 * 4 + 24, 256, C('Outline'))

    def paste(cv, i):
        for y in range(256):
            for x in range(256):
                out.put(i * 264 + x, y, cv.get(x, y))

    # READY
    cv = S.background(0)
    S.pyramid(cv, {}, 0)
    hud(cv, 0, 24800, 2, 1, 1, 0)
    put_c(cv, A['pip_stand_dr'], *S.foot_xy(1, 0))
    halos(cv, [('left', 4), ('right', 4)], k=1)
    plate(cv, 112, 24)
    cv.text('READY', centred('READY', 2), 117, C('Text'), k=2)
    paste(cv, 0)
    # the ripple: every lamp lit, the sweep half way (rows 1 to 4 done, row 5 flashing)
    cv = S.background(0)
    S.pyramid(cv, {rc: 'done' for rc in S.cells()}, 0)
    hud(cv, 6850, 24800, 2, 1, 1, 0)
    for c in range(5):
        x, y = S.cube_xy(5, c)
        put(cv, A['glint_1'], x, y)
    put_c(cv, A['pip_win_2'], S.foot_xy(7, 3)[0], S.foot_xy(7, 3)[1] - 4)
    halos(cv, [('right', 4)], k=3)
    paste(cv, 1)
    # PAUSED
    cv = ingame()
    plate(cv, 112, 32)
    cv.text('PAUSED', centred('PAUSED', 2), 116, C('Text'), k=2)
    s = 'P TO PLAY'
    cv.text(s, centred(s), 134, C('Label'))
    paste(cv, 2)
    paste(screens_frozen(), 3)
    return out


def screens_frozen():
    """A freeze: the ring spreading from the Frost Pip just caught, the Coil, the Thorn and Snuff frozen."""
    cv = S.background(0)
    particles(cv)
    st = ingame_states()
    S.pyramid(cv, st, 0)
    hud(cv, 4425, 24800, 2, 2, 1, 0)
    fx, fy = S.foot_xy(5, 2)
    put_c(cv, A['freeze_ring_3'], fx, fy)
    put_c(cv, A['pip_stand_dr'], fx, fy)
    pop(cv, '100', fx, fy - 26)
    put_c(cv, A['coil_stand_dr'], *S.foot_xy(3, 2), override=frozen(A['coil_stand_dr']))
    put_c(cv, A['thorn_2'], *S.foot_xy(6, 4), override=frozen(A['thorn_2']))
    put_c(cv, A['moth_ur_3'], *S.foot_xy(7, 0), override=frozen(A['moth_ur_3']))
    halos(cv, [('left', 3), ('left', 5), ('right', 4), ('right', 5)], gone=[('left', 4)], k=4)
    return cv


def themes():
    """One row per round theme: unlit, half, done, then the undo signal on an unlit and a done lamp, the HUD target.
    Under them a flipping lamp (one frame, a later level idea)."""
    cv = Canvas(8 + 6 * 40 + 8, 8 + 4 * 40 + 44, C('Dusk B'))
    for t in range(4):
        y0 = 8 + t * 40
        for k, st in enumerate(('unlit', 'half', 'done', 'undo', 'undo_done')):
            S.draw_cube(cv, 8 + k * 40, y0, st, t)
        S.draw_cube(cv, 8 + 5 * 40 + 8, y0 + 8, 'done', t, size=16)
    rows = S.flip_grid()
    m, _ = S.cube_colours('unlit', 0)
    m['D'] = hx(TONE['Mint'][2])
    for j, line in enumerate(rows):
        for i, ch in enumerate(line):
            if ch != '.':
                cv.put(8 + i, 8 + 4 * 40 + j, m[ch])
    cv.text('FLIP', 48, 8 + 4 * 40 + 12, C('Label'))
    return cv


def sprites_sheet():
    import sheet
    return sheet.sheet()


def main(out):
    ingame().image(3).save(os.path.join(out, 'cuber-preview.png'))
    title().image(3).save(os.path.join(out, 'cuber-preview-title.png'))
    gameover().image(3).save(os.path.join(out, 'cuber-preview-over.png'))
    screens().image(2).save(os.path.join(out, 'cuber-screens.png'))
    themes().image(3).save(os.path.join(out, 'cuber-themes.png'))
    sprites_sheet().image(4).save(os.path.join(out, 'cuber-sprites.png'))


if __name__ == '__main__':
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else '../out')
