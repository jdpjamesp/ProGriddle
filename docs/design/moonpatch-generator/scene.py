"""Drawing the screen: the ground and its layers, the bulbs, the Gloam, the Wick, the pests, the strip and the plates.
Every effect is a function of the frame count, as the painter will have it."""
import math
import random
from lib import Canvas, put, glow, mirror, text_width, mix
from palette import C, fam, wave
import sprites as SP

STRIP = 16
W, H = 240, 256
BAND_TOP = STRIP + 24 * 8          # 208: the first row of the player zone


def by(row):
    """Canvas y of the top of a board tile row."""
    return STRIP + row * 8


# ---------------------------------------------------------------- the ground and its layers
STARS = [(13, 22), (47, 61), (88, 30), (121, 102), (160, 47), (203, 77), (229, 140), (30, 128), (72, 170), (140, 160),
         (186, 118), (11, 190), (101, 75), (215, 24), (58, 101), (176, 184), (124, 196), (34, 58)]
FIREFLIES = [(40, 70, 0.0), (190, 52, 1.7), (120, 140, 3.1), (70, 180, 4.4), (210, 160, 2.2)]
GRASS = [3, 9, 14, 22, 31, 37, 44, 53, 60, 66, 75, 83, 90, 98, 106, 113, 121, 128, 137, 144, 151, 160, 167, 175, 182, 190, 199, 206, 213, 221, 228, 236]


def ground(cv, frames):
    cv.rect(0, STRIP, W, BAND_TOP - STRIP, C('Night'))
    cv.rect(0, BAND_TOP, W, H - BAND_TOP, C('Band'))
    for row in range(30):
        y = by(row) + 7
        col = C('Rule') if row < 23 else C('Band Rule')
        if row == 23:
            continue
        for x in range(2, W, 4 if row < 24 else 8):
            cv.put(x, y, col)
    for x in range(W):
        cv.put(x, BAND_TOP, C('Band Rule'))
    # the far layer: stars that drift down a cell every 64 frames, above the band
    for i, (x, y) in enumerate(STARS):
        yy = STRIP + (y - STRIP + frames // 64) % (BAND_TOP - STRIP - 2)
        cv.put(x, yy, C('Mote'))
    # the near layer: fireflies on a slow loop, pulsing
    for (x0, y0, p) in FIREFLIES:
        x = int(round(x0 + 9 * math.sin(frames / 110.0 + p)))
        y = int(round(y0 + 5 * math.sin(frames / 80.0 + p * 1.3)))
        t = 0.5 + 0.5 * math.sin(frames / 24.0 + p)
        cv.put(x, y, C('Firefly'))
        cv.tint(x, y, C('Night'), 0.6 * (1 - t))
    # the grass at the foot of the band, swaying one cell every 40 frames
    for i, x in enumerate(GRASS):
        h = 2 + (i * 7) % 3
        lean = ((frames // 40) + i) % 2
        for k in range(h):
            cv.put(x + (lean if k == h - 1 else 0), H - 1 - k, C('Band Rule'))


# ---------------------------------------------------------------- the bulbs
def field(seed, n, zone=4, rows=(1, 23)):
    rnd = random.Random(seed)
    cells = {}
    while len(cells) < n:
        cells[(rnd.randrange(0, 30), rnd.randrange(rows[0], rows[1]))] = rnd.choice([4, 4, 4, 4, 3, 3, 2, 1])
    k = 0
    while k < zone:
        c = (rnd.randrange(0, 30), rnd.randrange(24, 29))
        if c not in cells:
            cells[c] = rnd.choice([4, 3, 2])
            k += 1
    return cells


LIT = {'L': 'Text', 'M': None, 'D': None}


def bulbs(cv, cells, wave_n, blight=(), lit_at=None, lit_age=0):
    family = wave(wave_n)[2]
    for (x, y), hp in cells.items():
        b = (x, y) in blight
        spr = SP.ALL[('blight_%d' if b else 'bulb_%d') % hp]
        leg = fam(family, b)
        if lit_at is not None and lit_age < 5:
            cx, cy = x * 8 + 4, by(y) + 4
            if (cx - lit_at[0]) ** 2 + (cy - lit_at[1]) ** 2 <= 28 * 28:
                leg = dict(leg)
                leg['D'], leg['M'], leg['L'] = leg['M'], leg['L'], 'Text'
        put(cv, spr, x * 8, by(y), legend=leg)


# ---------------------------------------------------------------- the Gloam
def train(head_x, row, d, n, turn_left=0, turn_right=29, off=0):
    """Positions of a train of n segments whose head is at tile (head_x, row) going d (1 right, -1 left),
    off cells into its next tile. Behind the head the train runs back along the row, then up a row the other way."""
    out = []
    x, y, dd = head_x, row, d
    for i in range(n):
        out.append((x * 8 + off * dd, by(y), dd, i == 0))
        nx = x - dd
        if nx < turn_left or nx > turn_right:
            y -= 1
            dd = -dd
        else:
            x = nx
    return out


def gloam(cv, segs, wave_n, frames, dive=False, glow_on=True):
    family = wave(wave_n)[1]
    leg = fam(family)
    leg['e'] = 'Ember'
    leg['k'] = 'Ink'
    for i, (x, y, d, is_head) in enumerate(segs):
        f = ((frames + 2 * i) // 4) % 4
        if is_head and dive:
            spr = SP.ALL['head_dive']
        else:
            spr = SP.ALL[('head_%d' if is_head else 'bead_%d') % (f + 1)]
        rows = spr.rows if d > 0 or (is_head and dive) else mirror(spr.rows)
        l2 = leg
        if dive and not is_head and (frames // 4) % 2 == 0:
            l2 = dict(leg)
            l2['L'], l2['M'] = 'Blight Light', 'Blight'
        if is_head and glow_on:
            glow(cv, rows, x, y, C(family + ' Light'), 0.3)
        put(cv, spr, x, y, rows=rows, legend=l2)


# ---------------------------------------------------------------- the Wick, the spark and the pests
def wick(cv, x, y, frames, fired=None):
    spr = SP.ALL['wick_%d' % (1 + (frames // 6) % 2)]
    glow(cv, spr.rows, x, y, C('Wick Light'), 0.18)
    put(cv, spr, x, y)
    if fired is not None and fired < 2:
        put(cv, SP.ALL['muzzle'], x + 1, y - 3)


def spark(cv, x, y):
    s = SP.ALL['spark']
    glow(cv, s.rows[:4], x, y, C('Spark Tail'), 0.25)
    put(cv, s, x, y)


def sower(cv, x, y, frames, hurt=False):
    k = 1 + (frames // 3) % 2
    s = SP.ALL[('sower_hurt_%d' if hurt else 'sower_%d') % k]
    if hurt and (frames // 2) % 2 == 1:
        put(cv, s, x, y, legend={k2: 'Flash' for k2 in s.legend})
    else:
        put(cv, s, x, y)


def skitterjack(cv, x, y, frames):
    put(cv, SP.ALL['skitterjack_%d' % (1 + (frames // 4) % 4)], x, y)


def moonsnail(cv, x, y, frames, d=1):
    s = SP.ALL['moonsnail_%d' % (1 + (frames // 8) % 2)]
    put(cv, s, x, y, rows=s.rows if d > 0 else mirror(s.rows))


def burst(cv, tx, ty, age):
    """The burst that leaves a bulb, centred on tile (tx, ty), age in game frames."""
    k = 1 if age < 3 else 2 if age < 7 else 3 if age < 11 else 0
    if k:
        put(cv, SP.ALL['burst_%d' % k], tx * 8 - 2, by(ty) - 2)


def glint(cv, tx, ty, age):
    k = age // 4
    if 0 <= k < 3:
        put(cv, SP.ALL['glint_%d' % (k + 1)], tx * 8, by(ty))


def points(cv, value, cx, cy, age):
    s = str(value)
    w = text_width(s)
    cv.text(s, cx - w // 2, cy - 3 - age // 8, C('Points'), 1, outline=C('Ink'))


# ---------------------------------------------------------------- the strip
def strip(cv, score, hi, wave_n, lives, frames=0, extra_age=None):
    cv.rect(0, 0, W, STRIP - 1, C('Strip'))
    cv.rect(0, STRIP - 1, W, 1, C('Strip Rule'))
    cv.text(str(score), 4, 4, C('Points'))
    cv.text('HI', 82, 4, C('Text Dim'))
    cv.text(str(hi), 96, 4, C('Text'))
    put(cv, SP.ALL['moon_%d' % (1 + (wave_n - 1) % 6)], 160, 4)
    cv.text(str(wave_n), 170, 4, C('Text'))
    for k in range(min(lives, 5)):
        icon = SP.ALL['wick_icon']
        x = W - 9 - k * 8
        if extra_age is not None and k == lives - 1 and extra_age < 60 and (extra_age // 4) % 2 == 0:
            put(cv, icon, x, 5, legend={q: 'Spark' for q in icon.legend})
        else:
            put(cv, icon, x, 5)


# ---------------------------------------------------------------- plates and words
def centred(cv, s, y, colour, k=1, outline=True, bottom=None):
    w = text_width(s, k)
    cv.text(s, (W - w) // 2, y, colour, k, outline=C('Ink') if outline else None, bottom=bottom)


def veil(cv, t=0.55):
    for y in range(STRIP, H):
        for x in range(W):
            cv.tint(x, y, C('Ink'), t)


def plate(cv, w, h, cy):
    x, y = (W - w) // 2, cy - h // 2
    cv.rect(x, y, w, h, C('Plate'))
    for i in range(w):
        cv.put(x + i, y, C('Strip Rule'))
        cv.put(x + i, y + h - 1, C('Strip Rule'))
    for j in range(h):
        cv.put(x, y + j, C('Strip Rule'))
        cv.put(x + w - 1, y + j, C('Strip Rule'))
    return y


def banner(cv, y, h, t=0.6):
    """A soft dark band across the board behind words over the field: a tint toward Ink, fading over its top and bottom 3 rows."""
    for j in range(h):
        edge = min(j, h - 1 - j)
        k = t * min(1.0, (edge + 1) / 4.0)
        for x in range(W):
            cv.tint(x, y + j, C('Ink'), k)


def scanlines(cv, t=0.18):
    for y in range(1, H, 2):
        for x in range(W):
            cv.tint(x, y, C('Ink'), t)
