"""Draws the preview pictures from the same data as the design file."""
import math
from lib import Canvas, put, put_c, shadow, mix, text_width
from palette import C
import scene as S
import player, air, ground, fx
import tiles as TL

ALL = {}
for mod in (player, air, ground, fx):
    for s in mod.sprites():
        ALL[s.name] = s
SH = C('Ink')


def P(n):
    return ALL[n]


def ingame(family='green', mood='day', area=3):
    cv = Canvas(S.W, S.H, C('Strip'))
    scroll = 6
    S.draw_ground(cv, family, scroll, mood)
    # scorch where a Cairn was bombed a moment ago, under the burst
    cx, cy = S.at_tile(8, 9, scroll)
    put(cv, P('cairn_scorch'), cx, cy)
    # ground targets
    for name, tx, ty in (('cairn', 7, 7), ('cairn', 2, 2), ('dish', 11, 3), ('bastion', 12, 8),
                         ('henge', 12, 14), ('burr', 8, 5)):
        x, y = S.at_tile(tx, ty, scroll)
        put(cv, P(name), x, y)
    # a Beetle crawling down the road (turned to face down)
    from lib import rotate
    bx, by = S.at_tile(10, 9, scroll)
    put(cv, P('beetle_1'), bx, by + 4, rows=rotate(P('beetle_1').rows, 2))
    # explosion light on the land, then the ground burst on the old Cairn
    gx, gy = cx + 8, cy + 8
    S.light(cv, gx, gy, 2)
    put_c(cv, P('ground_boom_3'), gx, gy)
    # shadows of everything in the air (ship +6 +10, enemies +4 +6), Ink at 35%
    ship = (112, 236)
    shadow(cv, P('lark_bank_left'), ship[0], ship[1], 6, 10, SH, 0.35)
    whirls = [(40, 64), (62, 50), (84, 44), (106, 50), (128, 64)]
    for i, (x, y) in enumerate(whirls):
        shadow(cv, P('whirl_%d' % (1 + i % 4)), x, y, 4, 6, SH, 0.35)
    shadow(cv, P('kite_2'), 176, 120, 4, 6, SH, 0.35)
    shadow(cv, P('anvil_2'), 36, 150, 4, 6, SH, 0.35)
    # the bomb's shadow on its way to the sight
    sx, sy = ship[0], ship[1] - 100
    put_c(cv, P('bomb_shadow'), ship[0], sy + 40, override={'S': mix(cv.get(ship[0], sy + 40), SH, 0.35)})
    # haze above the ground, under the air
    S.haze(cv, [(170, 40, 34, 14), (30, 196, 28, 11), (150, 210, 22, 8)])
    # the sight: locked, a Cairn under it
    tx, ty = S.at_tile(7, 7, scroll)
    sight_x, sight_y = tx + 8, ty + 8
    sp = P('sight_lock')
    S.bloom(cv, sp, sight_x - 7, sight_y - 7, C('Sight Lock'), 0.3)
    put(cv, sp, sight_x - 7, sight_y - 7)
    # the bomb in flight
    put_c(cv, P('bomb_2'), ship[0], sy + 46)
    # air enemies
    for i, (x, y) in enumerate(whirls):
        put_c(cv, P('whirl_%d' % (1 + i % 4)), x, y)
    put_c(cv, P('kite_2'), 176, 120)
    put_c(cv, P('anvil_2'), 36, 150)
    put_c(cv, P('air_boom_2'), 150, 78)
    # bullets, with bloom
    for (x, y, f) in ((168, 136, 2), (160, 152, 1), (152, 170, 2), (60, 92, 1)):
        b = P('bullet_%d' % f)
        S.bloom(cv, b, x - 2, y - 2, C('Hot'), 0.4)
        put(cv, b, x - 2, y - 2)
    # the Zapper shots
    for (x, y) in ((112, 196), (112, 150)):
        z = P('zap')
        S.bloom(cv, z, x - 1, y, C('Zap Glow'), 0.3)
        put(cv, z, x - 1, y)
    # the ship and its flame
    put_c(cv, P('lark_bank_left'), ship[0], ship[1])
    put(cv, P('flame_2'), ship[0] - 8, ship[1] - 8 + 13)
    S.strips(cv, 24630, 50000, 3, area)
    return cv


def title():
    cv = Canvas(S.W, S.H, C('Strip'))
    S.draw_ground(cv, 'dry', 0, 'dawn')
    # a veil over the land so the words read: Ink at 55%
    for y in range(S.TOP, S.TOP + S.FIELD_H):
        for x in range(S.W):
            cv.tint(x, y, C('Ink'), 0.55)
    # the logo: SKYLARK at 4x in the dawn gradient, an Ink outline, a lark land line above it
    word = 'SKYLARK'
    k = 4
    w = text_width(word, k)
    x0 = (S.W - w) // 2
    lark = TL.line_design('lark')
    for j, r in enumerate(lark):
        for i, ch in enumerate(r):
            if ch == 'h':
                cv.put(S.LINE_AT[0] * 16 + i, S.TOP + S.LINE_AT[1] * 16 + j, C('Dawn Top'))
    cv.text(word, x0, 70, C('Dawn Top'), k=k, outline=C('Ink'), bottom=C('Dawn Low'))
    # the horizon rule under the logo: three lines that grow shorter, like a sunrise
    for i, (ww, col) in enumerate(((150, 'Dawn Low'), (110, 'Wing Mark'), (60, 'Dawn Top'))):
        cv.rect((S.W - ww) // 2, 104 + i * 3, ww, 1, C(col))
    # the roll call
    cv.text('AIR', 28, 124, C('Text Dim'))
    cv.text('GROUND', 130, 124, C('Text Dim'))
    rows_air = [('whirl_1', '30'), ('skate_flat', '50'), ('swift_1', '100'), ('midge_1', '150'), ('anvil_1', '?')]
    rows_gnd = [('cairn', '10'), ('dish', '20'), ('burr', '100'), ('bastion', '200'), ('henge', '300')]
    for i, (n, pts) in enumerate(rows_air):
        s = P(n)
        put_c(cv, s, 36, 144 + i * 20)
        cv.text(pts, 54, 141 + i * 20, C('Signal') if pts != '?' else C('Text Dim'))
    for i, (n, pts) in enumerate(rows_gnd):
        s = P(n)
        put_c(cv, s, 138, 144 + i * 20)
        cv.text(pts, 156, 141 + i * 20, C('Signal'))
    cv.text('PUSH FIRE', (S.W - text_width('PUSH FIRE', 2)) // 2, 248, C('Text'), k=2, outline=C('Ink'))
    S.strips(cv, 0, 50000, 0, 1)
    return cv


def area_start(area=4):
    cv = Canvas(S.W, S.H, C('Strip'))
    S.draw_ground(cv, 'dry', 3, 'day')
    # the marker: a band of Strip across the field, the words in it, a light sweep line
    y0 = 120
    for y in range(y0, y0 + 30):
        for x in range(S.W):
            cv.tint(x, y, C('Strip'), 0.8)
    cv.rect(0, y0, S.W, 1, C('Wing Mark'))
    cv.rect(0, y0 + 29, S.W, 1, C('Wing Mark'))
    a = 'AREA %d' % area
    cv.text(a, (S.W - text_width(a, 3)) // 2, y0 + 5, C('Dawn Top'), k=3, bottom=C('Dawn Low'))
    # the sweep: a short white bar running along the top line
    cv.rect(140, y0, 24, 1, C('Flash'))
    cv.rect(60, y0 + 29, 24, 1, C('Flash'))
    put_c(cv, P('lark'), 112, 236)
    put(cv, P('flame_1'), 104, 241)
    S.strips(cv, 24630, 50000, 3, area)
    return cv


def bonus(area=3):
    cv = Canvas(S.W, S.H, C('Strip'))
    S.draw_ground(cv, 'green', 10, 'dusk')
    for y in range(S.TOP + 40, S.TOP + 200):
        for x in range(16, S.W - 16):
            cv.tint(x, y, C('Strip'), 0.82)
    cv.rect(16, S.TOP + 40, S.W - 32, 1, C('Wing Mark'))
    cv.rect(16, S.TOP + 199, S.W - 32, 1, C('Wing Mark'))
    t = 'AREA %d CLEAR' % area
    cv.text(t, (S.W - text_width(t, 2)) // 2, S.TOP + 52, C('Dawn Top'), k=2, bottom=C('Dawn Low'))
    lines = [('GROUND TARGETS', '37 OF 48', 'Text'), ('DESTROYED', '77 PCT', 'Text'),
             ('SPIRES FOUND', '1', 'Text')]
    for i, (l, v, c) in enumerate(lines):
        cv.text(l, 30, S.TOP + 86 + i * 14, C('Text Dim'))
        cv.text(v, S.W - 30 - text_width(v), S.TOP + 86 + i * 14, C(c))
    # the bar: one cell per target, lit for the ones destroyed
    for i in range(48):
        x = 30 + (i % 24) * 7
        y = S.TOP + 132 + (i // 24) * 7
        cv.rect(x, y, 5, 5, C('Signal') if i < 37 else C('Stone Dark'))
    cv.text('BONUS', 30, S.TOP + 170, C('Text'), k=2)
    v = '7700'
    cv.text(v, S.W - 30 - text_width(v, 2), S.TOP + 170, C('Signal'), k=2)
    S.strips(cv, 32330, 50000, 3, area)
    return cv


def over_and_pause():
    a = Canvas(S.W, S.H, C('Strip'))
    S.draw_ground(a, 'dry', 8, 'dusk')
    for y in range(S.TOP, S.TOP + S.FIELD_H):
        for x in range(S.W):
            a.tint(x, y, C('Ink'), 0.5)
    t = 'GAME OVER'
    a.text(t, (S.W - text_width(t, 3)) // 2, 120, C('Dawn Top'), k=3, outline=C('Ink'), bottom=C('Dawn Low'))
    a.text('AREA 5   57 PCT', (S.W - text_width('AREA 5   57 PCT')) // 2, 152, C('Text Dim'))
    S.strips(a, 41270, 50000, 0, 5)
    b = ingame()
    for y in range(S.TOP, S.TOP + S.FIELD_H):
        for x in range(S.W):
            b.tint(x, y, C('Strip'), 0.6)
    t = 'PAUSED'
    b.text(t, (S.W - text_width(t, 3)) // 2, 124, C('Text'), k=3, outline=C('Ink'))
    m = 'P TO PLAY ON'
    b.text(m, (S.W - text_width(m)) // 2, 152, C('Text Dim'))
    out = Canvas(S.W * 2 + 8, S.H, C('Ink'))
    for y in range(S.H):
        for x in range(S.W):
            out.put(x, y, a.get(x, y))
            out.put(S.W + 8 + x, y, b.get(x, y))
    return out


def side(*cvs, gap=8):
    w = sum(c.w for c in cvs) + gap * (len(cvs) - 1)
    h = max(c.h for c in cvs)
    out = Canvas(w, h, C('Ink'))
    x0 = 0
    for c in cvs:
        for y in range(c.h):
            for x in range(c.w):
                out.put(x0 + x, y, c.get(x, y))
        x0 += c.w + gap
    return out


def themes():
    """The same screen in the four moods and both families."""
    cvs = []
    for fam, mood in (('dry', 'dawn'), ('green', 'haze'), ('dry', 'dusk'), ('green', 'storm')):
        cv = ingame(fam, mood)
        cv.text(fam.upper() + ' ' + mood.upper(), 6, S.TOP + 4, C('Text'), outline=C('Ink'))
        cvs.append(cv)
    return side(*cvs)


def sprite_sheet(names, cols=10, cell=34):
    rows = (len(names) + cols - 1) // cols
    cv = Canvas(cols * cell, rows * cell, C('Meadow'))
    for i, n in enumerate(names):
        s = P(n)
        x = (i % cols) * cell + (cell - s.width) // 2
        y = (i // cols) * cell + (cell - s.height) // 2
        if s.group in ('ground', 'scorch', 'boss'):
            cv.rect((i % cols) * cell + 1, (i // cols) * cell + 1, cell - 2, cell - 2, C('Ochre'))
        if s.name == 'bomb_shadow':
            put(cv, s, x, y, override={'S': mix(C('Meadow'), C('Ink'), 0.35)})
        else:
            put(cv, s, x, y)
    return cv


def tile_sheet():
    T = TL.tile_set()
    names = list(T)
    cols = 12
    cell = 18
    out = []
    for fam in ('green', 'dry'):
        rows = (len(names) + cols - 1) // cols
        cv = Canvas(cols * cell, rows * cell, C('Ink'))
        cm = S.tile_colours(fam)
        for i, n in enumerate(names):
            S.draw_tile(cv, T[n][0], (i % cols) * cell + 1, (i // cols) * cell + 1, cm)
        out.append(cv)
    lines = Canvas(3 * 34, 34, C('Ink'))
    cm = S.tile_colours('dry')
    for i, n in enumerate(TL.LINES):
        S.draw_tile(lines, TL.line_design(n), i * 34 + 1, 1, cm)
    out.append(lines)
    return side(*out)


def breakup():
    """The ship breaking up: 5 key moments, the pieces drifting and fading over 90 frames."""
    frames = [0, 12, 30, 60, 89]
    cvs = []
    pieces = player.breakup_pieces()
    for f in frames:
        cv = Canvas(48, 48, C('Meadow'))
        fade = f / 90.0
        for name, rows, sx, sy, dx, dy in pieces:
            ox = 16 + sx + dx * f * 0.25
            oy = 16 + sy + dy * f * 0.25
            leg = P('lark').colours()
            for j, r in enumerate(rows):
                for i, ch in enumerate(r):
                    if ch == '.':
                        continue
                    # pieces lose cells as they fade: a cell goes when its own number is past the fade
                    if ((i * 7 + j * 11) % 10) / 10.0 < fade:
                        continue
                    c = leg[ch]
                    if f >= 12:
                        c = mix(c, C('Smoke'), min(1, fade * 1.4))
                    cv.put(int(ox + i), int(oy + j), c)
        if f < 20:
            b = P('air_boom_%d' % (1 + f // 5))
            put_c(cv, b, 24, 24)
        cvs.append(cv)
    return side(*cvs, gap=2)


def main(out):
    import os
    j = lambda n: os.path.join(out, n)
    ingame().image(3).save(j('skylark-preview.png'))
    title().image(3).save(j('skylark-preview-title.png'))
    side(area_start(), bonus()).image(2).save(j('skylark-preview-area.png'))
    over_and_pause().image(2).save(j('skylark-preview-over.png'))
    themes().image(2).save(j('skylark-themes.png'))
    sprite_sheet(list(ALL)).image(4).save(j('skylark-sprites.png'))
    tile_sheet().image(4).save(j('skylark-tiles.png'))
    breakup().image(6).save(j('skylark-breakup.png'))
