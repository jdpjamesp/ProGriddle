"""Explosions and the area marker: drawn from the frame number only."""
import math
from lib import Sprite
from shapes import render

BOOM = {'W': 'Flash', 'Y': 'Signal', 'F': 'Fire', 'R': 'Fire Dark', 'S': 'Smoke'}


def hashf(x, y, k):
    from tiles import h32
    return h32(int(x), int(y), 31 + k) / 65535.0


def air_boom(f, size=16):
    """Air explosion, 5 frames: a white flash, a fire ball, a burning ring, a broken ring of smoke,
    a few smoke specks."""
    c = size / 2.0
    k = size / 16.0

    def fn(x, y):
        dx, dy = x - c, y - c
        r = math.hypot(dx, dy) / k
        n = hashf(x, y, f)
        if f == 0:
            return 'W' if r < 3.2 else ('Y' if r < 4.4 else None)
        if f == 1:
            if r < 2.4:
                return 'W'
            if r < 4.6:
                return 'Y'
            if r < 6.2:
                return 'F'
            return 'R' if r < 7.0 and n < 0.6 else None
        if f == 2:
            if r < 2.0:
                return 'Y' if n < 0.5 else None
            if r < 4.5:
                return 'F' if n < 0.8 else 'Y'
            if r < 6.8:
                return 'R' if n < 0.8 else 'F'
            return 'R' if r < 7.6 and n < 0.4 else None
        if f == 3:
            if 4.0 < r < 7.4:
                return ('S' if n < 0.55 else ('R' if n < 0.75 else None))
            return None
        if f == 4:
            if 5.0 < r < 7.8 and n < 0.28:
                return 'S'
            return None
    return render(size, size, fn)


def ground_boom(f):
    """Ground burst, 6 frames, 32 x 32: flash, a fire dome, the dome with rising flame tongues,
    the ring spreads, smoke and flying debris, the last smoke."""
    def fn(x, y):
        dx, dy = x - 16, y - 16
        r = math.hypot(dx, dy)
        n = hashf(x, y, f + 10)
        a = math.atan2(dy, dx)
        if f == 0:
            return 'W' if r < 5 else ('Y' if r < 7 else None)
        if f == 1:
            if r < 4:
                return 'W'
            if r < 8:
                return 'Y'
            if r < 11:
                return 'F' if n < 0.9 else 'R'
            return None
        if f == 2:
            tongue = 11 + 3 * math.cos(a * 6)
            if r < 5:
                return 'Y'
            if r < 9:
                return 'F'
            if r < tongue:
                return 'R' if n < 0.8 else 'F'
            return None
        if f == 3:
            if r < 6:
                return 'F' if n < 0.6 else 'R'
            if r < 12:
                return 'R' if n < 0.55 else ('S' if n < 0.8 else None)
            if r < 14 and n < 0.25:
                return 'S'
            return None
        if f == 4:
            if r < 10:
                return 'S' if n < 0.45 else ('R' if n < 0.52 else None)
            if r < 15 and n < 0.12:
                return 'S'
            return None
        if f == 5:
            if 6 < r < 14 and n < 0.16:
                return 'S'
            return None
    return render(32, 32, fn)


def sprites():
    out = []
    for f in range(5):
        out.append(Sprite('air_boom_%d' % (f + 1), air_boom(f), BOOM,
                          'Air explosion, frame %d of 5 (4 frames each, 20 frames in all).' % (f + 1), group='boom'))
    for f in range(6):
        out.append(Sprite('ground_boom_%d' % (f + 1), ground_boom(f), BOOM,
                          'Ground burst, frame %d of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.' % (f + 1), group='boom'))
    return out
