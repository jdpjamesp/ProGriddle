"""Builds the screens: the ground from tiles, the strips, shadows, haze, light and bloom."""
import math
from lib import Canvas, put, put_c, shadow, mix, text_width
from palette import C
import tiles as TL

W, H = 224, 288
TOP = 16            # the playfield starts on canvas row 16 and is 256 rows tall
FIELD_H = 256

AREAS = [
    # area, family, mood (a whole-land tint), what the land is made of
    (1, 'dry', 'dawn', 'Open ochre plain, a lone road, the first land lines. Light and calm.'),
    (2, 'green', 'dawn', 'Meadow and the first forests, a river from the left.'),
    (3, 'green', 'day', 'Forest blocks cut by roads; Dishes along the roads.'),
    (4, 'dry', 'day', 'Wide land lines (all three designs), Bastions on pads.'),
    (5, 'green', 'day', 'A broad river with bridges; Beetles on the roads.'),
    (6, 'dry', 'haze', 'Long forest belts across a dry plain, the first Citadel.'),
    (7, 'green', 'haze', 'Meadow with many pads: an installation field.'),
    (8, 'dry', 'dusk', 'River country: two rivers, few roads.'),
    (9, 'green', 'dusk', 'Deep forest, roads only, Hives in clearings.'),
    (10, 'dry', 'dusk', 'Land lines everywhere, the spiral field.'),
    (11, 'green', 'day', 'A second dawn: meadow, rivers, a calm stretch then a Citadel.'),
    (12, 'dry', 'haze', 'Badlands: ochre with earth scars, Henges.'),
    (13, 'green', 'storm', 'Forest under storm light, Burr nests.'),
    (14, 'dry', 'storm', 'The road maze: crossings and Beetles.'),
    (15, 'green', 'dusk', 'Everything at once, two Citadels.'),
    (16, 'dry', 'dawn', 'The way home: the land lines again, bigger, and the last Citadel.'),
]
MOODS = {
    'dawn': ('Glow Light', 0.10, 'warm first light'),
    'day': (None, 0.0, 'no tint'),
    'haze': ('Haze', 0.14, 'pale, the far land softer'),
    'dusk': ('Dawn Low', 0.10, 'red low sun'),
    'storm': ('Ink', 0.18, 'dark, the bullets and the sight stand out more'),
}


def tile_colours(family):
    leg = TL.legend(family)
    return {k: C(v) for k, v in leg.items()}


def draw_tile(cv, rows, x, y, cmap):
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            cv.put(x + i, y + j, cmap[ch])


def h32(x, y):
    return TL.h32(x, y, 77)


def build_map():
    """The in game preview map: 14 x 17 tiles (one extra row for the scroll)."""
    fixed = {}
    for y in range(0, 2):
        fixed[(3, y)] = 'river_ns'
    fixed[(3, 2)] = 'river_ne'
    fixed[(4, 2)] = 'river_ew'
    fixed[(5, 2)] = 'river_sw'
    for y in range(3, 11):
        fixed[(5, y)] = 'river_ns' if y % 3 else 'river_ns_2'
    fixed[(5, 11)] = 'river_ne'
    for x in range(6, 10):
        fixed[(x, 11)] = 'river_ew'
    fixed[(10, 11)] = 'bridge_ns'
    for x in range(11, 14):
        fixed[(x, 11)] = 'river_ew'
    for y in range(0, 17):
        if (10, y) not in fixed:
            fixed[(10, y)] = 'road_ns'
    fixed[(10, 5)] = 'road_t_e'
    for x in range(11, 14):
        fixed[(x, 5)] = 'road_ew'
    fixed[(12, 8)] = 'pad'
    fixed[(12, 14)] = 'pad'

    def corner(x, y):
        return (0 <= x <= 3 and 4 <= y <= 10) or (12 <= x <= 14 and 0 <= y <= 3) or (0 <= x <= 3 and 13 <= y <= 17)

    T = TL.tile_set()
    m = {}
    for y in range(17):
        for x in range(14):
            if (x, y) in fixed:
                m[(x, y)] = fixed[(x, y)]
                continue
            mask = (int(corner(x, y)), int(corner(x + 1, y)), int(corner(x, y + 1)), int(corner(x + 1, y + 1)))
            n = TL.mask_name(mask)
            if n == 'forest_full' and h32(x, y) % 3 == 0:
                n = 'forest_full_2'
            if n is None:
                n = 'open_%d' % (1 + h32(x, y) % 3)
            m[(x, y)] = n
    return m


LINE_AT = (7, 1)   # the lark land line covers tiles (7..8, 1..2)


def draw_ground(cv, family, scroll, mood=None, mapping=None):
    """Draw the ground into the playfield. scroll: cells the view has moved into the top tile."""
    T = TL.tile_set()
    cmap = tile_colours(family)
    m = mapping or build_map()
    lark = TL.line_design('lark')
    for (x, y), name in m.items():
        rows = T[name][0]
        if (x - LINE_AT[0]) in (0, 1) and (y - LINE_AT[1]) in (0, 1):
            ox, oy = (x - LINE_AT[0]) * 16, (y - LINE_AT[1]) * 16
            rows = [r[ox:ox + 16] for r in lark[oy:oy + 16]]
        px, py = x * 16, TOP + y * 16 - scroll
        for j, r in enumerate(rows):
            yy = py + j
            if TOP <= yy < TOP + FIELD_H:
                for i, ch in enumerate(r):
                    cv.put(px + i, yy, cmap[ch])
    apply_mood(cv, mood)


def apply_mood(cv, mood):
    if not mood:
        return
    name, t, _ = MOODS[mood]
    if not name:
        return
    col = C(name)
    for y in range(TOP, TOP + FIELD_H):
        for x in range(W):
            cv.tint(x, y, col, t)


def at_tile(tx, ty, scroll):
    return tx * 16, TOP + ty * 16 - scroll


def light(cv, cx, cy, frame):
    """The light an explosion throws on the land: three rings of Glow Light, fading over 8 frames.
    Drawn on the ground before any sprite."""
    if frame >= 8:
        return
    k = 1 - frame / 8.0
    col = C('Glow Light')
    for y in range(cy - 24, cy + 25):
        for x in range(cx - 24, cx + 25):
            r = math.hypot(x - cx, y - cy)
            if r < 8:
                t = 0.30
            elif r < 16:
                t = 0.20
            elif r < 24:
                t = 0.10
            else:
                continue
            if TOP <= y < TOP + FIELD_H:
                cv.tint(x, y, col, t * k)


def haze(cv, clouds, t=0.22):
    """Parallax haze: soft clouds as a tint of Haze, solid inside, every other cell on the rim."""
    col = C('Haze')
    for (cx, cy, rx, ry) in clouds:
        for y in range(int(cy - ry - 2), int(cy + ry + 3)):
            for x in range(int(cx - rx - 2), int(cx + rx + 3)):
                if not (TOP <= y < TOP + FIELD_H):
                    continue
                # a lumpy edge: the radius wobbles with the angle
                a = math.atan2(y - cy, x - cx)
                wob = 1 + 0.12 * math.sin(a * 5 + cx) + 0.08 * math.sin(a * 3 + cy)
                d = math.hypot((x - cx) / rx, (y - cy) / ry) / wob
                if d < 0.85:
                    cv.tint(x, y, col, t)
                elif d < 1.0 and (x + y) % 2 == 0:
                    cv.tint(x, y, col, t)


def bloom(cv, spr, x, y, colour, t=0.35):
    """A one cell halo round a sprite (top left x, y), tinted toward colour."""
    h, w = spr.height, spr.width
    for j in range(-1, h + 1):
        for i in range(-1, w + 1):
            inside = 0 <= j < h and 0 <= i < w and spr.rows[j][i] != '.'
            if inside:
                continue
            near = any(0 <= j + b < h and 0 <= i + a < w and spr.rows[j + b][i + a] != '.'
                       for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if near:
                cv.tint(x + i, y + j, colour, t)


MINI_LARK = ['...K...', '..KWK..', '..KGK..', '.KWWMK.', 'KWOWMOK', 'KKWWMKK', '..K.K..']


def strips(cv, score, hi, lives, area):
    cv.rect(0, 0, W, TOP, C('Strip'))
    cv.rect(0, TOP + FIELD_H, W, H - TOP - FIELD_H, C('Strip'))
    cv.rect(0, TOP - 1, W, 1, C('Ink'))
    cv.text('SCORE', 6, 1, C('Text Dim'))
    s = '%d' % score
    cv.text(s, 6 + text_width('SCORE') + 6, 1, C('Signal'))
    cv.text('HI', 128, 1, C('Text Dim'))
    cv.text('%d' % hi, 128 + text_width('HI') + 6, 1, C('Zap Glow'))
    # the second line of the top strip is empty on purpose: the score sits on one quiet line
    by = TOP + FIELD_H + 4
    leg = {'K': C('Hull Ink'), 'W': C('Hull'), 'M': C('Hull Mid'), 'G': C('Glass'), 'O': C('Wing Mark')}
    for i in range(lives):
        for j, r in enumerate(MINI_LARK):
            for k, ch in enumerate(r):
                if ch != '.':
                    cv.put(6 + i * 10 + k, by + j, leg[ch])
    a = 'AREA %02d' % area
    cv.text(a, W - 6 - text_width(a), by, C('Text'))
