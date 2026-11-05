"""The preview pictures, all drawn from the sprites, the palette and the scene rules."""
import os
from PIL import Image
from lib import Canvas, put, glow, text_width, mix
from palette import C, wave, fam
import sprites as SP
import scene as S

ALL = SP.ALL
OUT = {}


# ---------------------------------------------------------------- the logo
LOGO = 'MOONPATCH'
LOGO_K = 3
LOGO_STEP = 6 * LOGO_K


def logo_width():
    return len(LOGO) * LOGO_STEP - LOGO_K


def logo(cv, x, y, frames=0):
    """MOONPATCH at 3x in the Moon gradient with an Ink outline; the two Os are moons, full and a crescent."""
    for i, ch in enumerate(LOGO):
        cx = x + i * LOGO_STEP
        if ch == 'O':
            continue
        cv.text(ch, cx, y, C('Moon Top'), LOGO_K, outline=C('Ink'), bottom=C('Moon Low'))
    for n, i in enumerate([1, 2]):
        cx = x + i * LOGO_STEP + 7
        cy = y + 11
        for yy in range(cy - 9, cy + 10):
            for xx in range(cx - 9, cx + 10):
                d = (xx - cx) ** 2 + (yy - cy) ** 2
                if d <= 62:
                    lit = True if n == 0 else (xx - cx + 4) ** 2 + (yy - cy + 1) ** 2 > 44
                    t = (yy - (cy - 8)) / 16.0
                    col = mix(C('Moon Top'), C('Moon Low'), max(0, min(1, t))) if lit else C('Plate')
                    cv.put(xx, yy, col)
                elif d <= 82:
                    cv.put(xx, yy, C('Ink'))
    # the halo round the full moon breathes over 120 frames
    import math
    t = 0.10 + 0.06 * math.sin(frames / 19.0)
    cx, cy = x + LOGO_STEP + 7, y + 11
    for yy in range(cy - 13, cy + 14):
        for xx in range(cx - 13, cx + 14):
            d = (xx - cx) ** 2 + (yy - cy) ** 2
            if 82 < d <= 160:
                cv.tint(xx, yy, C('Moon Top'), t)


# ---------------------------------------------------------------- scenes
def base(wave_n, frames, cells, blight=(), score=0, hi=24760, lives=3, lit_at=None, lit_age=0, extra_age=None):
    cv = Canvas()
    S.ground(cv, frames)
    S.bulbs(cv, cells, wave_n, blight, lit_at, lit_age)
    S.strip(cv, score, hi, wave_n, lives, frames, extra_age)
    return cv


def ingame():
    """Wave 1, early: a whole Gloam coming down, a spark in flight, the Skitterjack in the band."""
    fr = 1234
    cells = S.field(11, 34, zone=3)
    for c in [(18, 9), (19, 9), (22, 4), (5, 4)]:
        cells.pop(c, None)
    cv = base(1, fr, cells, score=1460, lives=3)
    segs = S.train(17, 4, -1, 12, turn_left=0, turn_right=24, off=3)
    S.gloam(cv, segs, 1, fr)
    S.skitterjack(cv, 168, S.by(25) + 3, fr)
    S.wick(cv, 116, S.by(28), fr, fired=1)
    S.spark(cv, 119, S.by(17))
    return cv


def later():
    """Wave 5, FULL MOON: a field blighted by the Moonsnail, which crosses the upper rows, and a Gloamhead diving."""
    fr = 4080
    cells = S.field(52, 44, zone=4)
    blight = {(x, y) for (x, y) in cells if 6 <= y <= 9 and x >= 9}
    cells[(14, 12)] = 4
    blight.add((14, 12))
    for c in [(x, 13) for x in range(7, 15)] + [(14, 14), (14, 15), (14, 16), (14, 17), (14, 18)]:
        cells.pop(c, None)
    cv = base(5, fr, cells, blight, score=31880, hi=31880, lives=2)
    S.moonsnail(cv, 6 * 8 + 2, S.by(8), fr, d=-1)
    # a train that touched a blighted bulb at (14, 13): the head dives down column 14, the beads follow it down
    S.gloam(cv, [(14 * 8, S.by(17) + 2, 1, True)], 5, fr, dive=True)
    tail = [(14 * 8, S.by(16) + 2, 1, False), (14 * 8, S.by(15) + 2, 1, False), (14 * 8, S.by(14) + 2, 1, False)]
    tail += [((13 - k) * 8 + 2, S.by(13), 1, False) for k in range(5)]
    S.gloam(cv, tail, 5, fr, dive=True)
    S.gloam(cv, S.train(4, 20, 1, 1), 5, fr)     # a stray head
    S.wick(cv, 64, S.by(27) + 2, fr)
    S.spark(cv, 67, S.by(22))
    return cv


def busy():
    """Wave 2, CRESCENT: the Gloam just split in two, the burst that leaves a bulb, the Skitterjack shot close for 900,
    the light on the field, a Sower falling, a stray head."""
    fr = 2600
    cells = S.field(23, 36, zone=2)
    for c in [(10, 10), (11, 10), (12, 10), (13, 10), (14, 10), (15, 10), (16, 10), (17, 10), (18, 10), (19, 10), (20, 10),
              (21, 11), (7, 11), (8, 11), (9, 11), (21, 2), (21, 3), (21, 4), (21, 5)]:
        cells.pop(c, None)
    cells[(14, 10)] = 4          # the bulb the shot bead left behind
    hit = (14 * 8 + 4, S.by(10) + 4)
    cv = base(2, fr, cells, score=9310, hi=24760, lives=3, lit_at=hit, lit_age=2)
    front = S.train(10, 10, -1, 4, turn_left=0, turn_right=13, off=2)
    back = [(x, y, d, i == 0) for i, (x, y, d, h) in enumerate(S.train(15, 10, -1, 6, turn_left=15, turn_right=21, off=2))]
    back[0] = (back[0][0], back[0][1], back[0][2], True)
    S.gloam(cv, front, 2, fr)
    S.gloam(cv, back, 2, fr)
    S.burst(cv, 14, 10, 4)
    S.sower(cv, 21 * 8, S.by(5) + 3, fr, hurt=True)
    for y in (2, 3):
        cells[(21, y)] = 4
    S.bulbs(cv, {(21, 2): 4, (21, 3): 4}, 2)
    S.glint(cv, 21, 3, 1)
    S.gloam(cv, S.train(26, 25, -1, 1, off=5), 2, fr)
    S.burst(cv, 6, 27, 1)
    S.points(cv, 900, 6 * 8 + 4, S.by(27) - 2, 6)
    S.wick(cv, 72, S.by(28), fr)
    S.spark(cv, 75, S.by(15))
    return cv


def title(frames=200):
    cv = Canvas()
    S.ground(cv, frames)
    wn = 1 + (frames // 360) % 6          # the title walks through the six waves, one each crossing
    cells = {(2, 2): 4, (27, 3): 4, (5, 9): 3, (24, 10): 4, (1, 13): 4, (28, 14): 2, (3, 23): 4, (26, 22): 4, (2, 26): 3,
             (27, 26): 4}
    S.bulbs(cv, cells, wn)
    S.strip(cv, 1460, 24760, wn, 0, frames)
    x = (S.W - logo_width()) // 2
    logo(cv, x, 30, frames)
    S.centred(cv, 'A NIGHT IN THE GARDEN', 62, C('Text Dim'))
    # the Gloam crosses under the name, a cell a frame, from right to left, and wraps
    head_x = 250 - (frames % 360)
    segs = [(head_x + i * 8, S.by(9) + 2, -1, i == 0) for i in range(12)]
    S.gloam(cv, segs, wn, frames)
    # roll call
    y0 = 120
    rows = [('head_1', 'GLOAMHEAD', '100'), ('bead_1', 'BEAD', '10'), ('sower_1', 'SOWER', '200'),
            ('skitterjack_1', 'SKITTERJACK', '300 600 900'), ('moonsnail_1', 'MOONSNAIL', '1000'), ('bulb_4', 'BULB', '1')]
    for i, (spr, name, pts) in enumerate(rows):
        y = y0 + i * 14
        s = ALL[spr]
        leg = None
        if spr.startswith(('head', 'bead')):
            leg = fam('Orchid')
            leg['e'] = 'Ember'
            leg['k'] = 'Ink'
        if spr.startswith('bulb'):
            leg = fam('Jade')
        put(cv, s, 56 + (16 - s.width) // 2, y, legend=leg)
        cv.text(name, 80, y + 1, C('Text'))
        cv.text(pts, 150, y + 1, C('Points'))
    if (frames // 30) % 2 == 0:
        S.centred(cv, 'PRESS SPACE', 214, C('Text'), 2)
    S.centred(cv, 'MOVE ARROWS  FIRE SPACE', 240, C('Text Dim'), 1, outline=False)
    return cv


def wave_start():
    cv = base(3, 300, S.field(31, 30, zone=0), score=12040, lives=3)
    S.wick(cv, 116, S.by(28), 300)
    S.banner(cv, 90, 50)
    S.centred(cv, 'WAVE 3', 98, C('Text'), 2)
    put(cv, ALL['moon_3'], 116, 118)
    S.centred(cv, 'HALF MOON', 128, C('Text Dim'))
    return cv


def wave_clear():
    cells = S.field(32, 40, zone=3)
    cv = base(2, 1800, cells, score=11870, lives=3)
    S.wick(cv, 100, S.by(27), 1800)
    S.banner(cv, 90, 44)
    S.centred(cv, 'WAVE 2 CLEARED', 98, C('Text'), 2)
    S.centred(cv, 'BONUS 500', 122, C('Points'))
    return cv


def extra():
    cv = base(4, 77, S.field(41, 34, zone=2), score=12010, lives=4, extra_age=8)
    S.banner(cv, S.STRIP, 16)
    S.centred(cv, 'EXTRA WICK', S.STRIP + 4, C('Points'))
    S.wick(cv, 116, S.by(28), 77)
    S.gloam(cv, S.train(20, 6, 1, 12, turn_left=6, turn_right=29, off=4), 4, 77)
    return cv


def game_over():
    cv = base(4, 500, S.field(44, 52, zone=5), score=31880, hi=31880, lives=0)
    S.gloam(cv, S.train(12, 26, 1, 7, turn_left=8, turn_right=20), 4, 500)
    S.veil(cv)
    y = S.plate(cv, 168, 64, 128)
    S.centred(cv, 'GAME OVER', y + 9, C('Moon Top'), 2, bottom=C('Moon Low'))
    S.centred(cv, 'SCORE 31880', y + 32, C('Text'))
    S.centred(cv, 'NEW BEST', y + 46, C('Points'))
    return cv


def paused():
    cv = base(1, 1234, S.field(11, 34, zone=3), score=1460, lives=3)
    S.gloam(cv, S.train(17, 4, -1, 12, turn_left=0, turn_right=24, off=3), 1, 1234)
    S.wick(cv, 116, S.by(28), 1234)
    S.veil(cv)
    y = S.plate(cv, 120, 32, 128)
    S.centred(cv, 'PAUSED', y + 9, C('Text'), 2)
    return cv


def screens():
    cs = [wave_start(), wave_clear(), extra(), game_over(), paused(), title(915)]
    gap = 8
    out = Canvas(3 * 240 + 2 * gap, 2 * 256 + gap, C('Ink'))
    for i, c in enumerate(cs):
        ox, oy = (i % 3) * (240 + gap), (i // 3) * (256 + gap)
        for y in range(256):
            out.px[oy + y][ox:ox + 240] = c.px[y]
    return out


def waves():
    """The same corner of the field in all six waves, with a bead train and a blighted bulb."""
    cells = S.field(77, 22, zone=2, rows=(1, 12))
    blight = {sorted(cells)[3], sorted(cells)[9]}
    w, h = 112, 112
    out = Canvas(3 * w + 2 * 6, 2 * h + 18 + 6, C('Ink'))
    for n in range(1, 7):
        cv = Canvas()
        S.ground(cv, 500)
        S.bulbs(cv, cells, n, blight)
        S.gloam(cv, S.train(8, 6, 1, 7, turn_left=2, turn_right=13, off=2), n, 500 + n)
        ox, oy = ((n - 1) % 3) * (w + 6), ((n - 1) // 3) * (h + 9 + 6)
        for y in range(h):
            out.px[oy + 9 + y][ox:ox + w] = cv.px[S.STRIP + y][0:w]
        out.text('%d %s' % (n, wave(n)[0]), ox + 1, oy + 1, C('Text'))
    return out


def sequences():
    """Strips of frames: burst to bulb, the bulb wearing down, the pop, the glint, the Wick breaking up, the dive tell."""
    cv = Canvas(200, 118, C('Night'))
    y = 2
    cv.text('BURST TO BULB', 2, y, C('Text Dim'))
    y += 10
    for i, age in enumerate([0, 2, 4, 6, 8, 10, 12]):
        ox = 2 + i * 18
        put(cv, ALL['bulb_4'], ox + 2, y + 2, legend=fam('Tide'))
        k = 1 if age < 3 else 2 if age < 7 else 3 if age < 11 else 0
        if k:
            put(cv, ALL['burst_%d' % k], ox, y)
    y += 18
    cv.text('HITS  BLIGHT  POP', 2, y, C('Text Dim'))
    y += 10
    for i, hp in enumerate([4, 3, 2, 1]):
        put(cv, ALL['bulb_%d' % hp], 2 + i * 11, y, legend=fam('Tide'))
        put(cv, ALL['blight_%d' % hp], 52 + i * 11, y)
    put(cv, ALL['bulb_4'], 104, y, legend={'L': 'Tide Light', 'M': 'Tide Light', 'D': 'Tide Light', 's': 'Tide Light'})
    put(cv, ALL['bulb_pop_1'], 116, y, legend=fam('Tide'))
    put(cv, ALL['bulb_pop_2'], 128, y, legend=fam('Tide'))
    for i in range(3):
        put(cv, ALL['bulb_4'], 148 + i * 12, y, legend=fam('Tide'))
        put(cv, ALL['glint_%d' % (i + 1)], 148 + i * 12, y)
    y += 14
    cv.text('THE WICK BREAKS UP', 2, y, C('Text Dim'))
    y += 10
    for i in range(6):
        put(cv, ALL['wick_break_%d' % (i + 1)], 2 + i * 20, y)
    put(cv, ALL['wick_1'], 126, y + 4)
    put(cv, ALL['muzzle'], 141, y + 1)
    put(cv, ALL['wick_2'], 140, y + 4)
    y += 22
    cv.text('DIVE TELL', 2, y, C('Text Dim'))
    y += 10
    for i, fr in enumerate([0, 4]):
        segs = [(2 + i * 64 + 8 * k, y, 1, False) for k in range(5)]
        for (x, yy, d, h) in segs:
            leg = fam('Coral')
            if (fr // 4) % 2 == 0:
                leg['L'], leg['M'] = 'Blight Light', 'Blight'
            put(cv, ALL['bead_1'], x, yy, legend=leg)
    put(cv, ALL['head_dive'], 130, y, legend=dict(fam('Coral'), e='Ember', k='Ink'))
    return cv


def sprites_sheet():
    groups = [('bulb', 'BULBS'), ('gloam', 'THE GLOAM'), ('burst', 'BURST'), ('wick', 'THE WICK'), ('wickdeath', 'BREAK UP'),
              ('sower', 'SOWER'), ('jack', 'SKITTERJACK'), ('snail', 'MOONSNAIL'), ('strip', 'MOONS')]
    rows_out = []
    for g, label in groups:
        items = [s for s in ALL.values() if s.group == g]
        rows_out.append((label, items))
    hgt = sum(10 + max(s.height for s in it) + 6 for _, it in rows_out) + 4
    cv = Canvas(232, hgt, C('Night'))
    y = 2
    for label, items in rows_out:
        cv.text(label, 2, y, C('Text Dim'))
        y += 10
        x = 2
        for s in items:
            leg = None
            if s.group == 'gloam':
                leg = dict(fam('Orchid'), e='Ember', k='Ink')
            put(cv, s, x, y, legend=leg)
            x += s.width + 4
        y += max(s.height for s in items) + 6
    return cv


def main(out):
    jobs = [('moonpatch-preview.png', ingame, 3), ('moonpatch-preview-later.png', later, 3), ('moonpatch-preview-busy.png', busy, 3),
            ('moonpatch-preview-title.png', title, 3), ('moonpatch-screens.png', screens, 2), ('moonpatch-waves.png', waves, 3),
            ('moonpatch-sequences.png', sequences, 5), ('moonpatch-sprites.png', sprites_sheet, 4)]
    for name, fn, k in jobs:
        fn().image(k).save(os.path.join(out, name))


if __name__ == '__main__':
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else '../out')
