"""Small things: the 3 x 5 pop-up digits, score pop-ups, the debug target marker, Dibby's crash,
the cartoon parts and the sparkle."""
from lib import Sprite
import dibby

DIGITS = {
    '0': ["###", "#.#", "#.#", "#.#", "###"],
    '1': [".#.", "##.", ".#.", ".#.", "###"],
    '2': ["###", "..#", "###", "#..", "###"],
    '3': ["###", "..#", ".##", "..#", "###"],
    '4': ["#.#", "#.#", "###", "..#", "..#"],
    '5': ["###", "#..", "###", "..#", "###"],
    '6': ["###", "#..", "###", "#.#", "###"],
    '7': ["###", "..#", ".#.", ".#.", ".#."],
    '8': ["###", "#.#", "###", "#.#", "###"],
    '9': ["###", "#.#", "###", "..#", "###"],
}


def popup_rows(text, letter):
    """The digits with one pixel between them and a 1 pixel Outline all round (so it reads over walls)."""
    w = len(text) * 4 - 1
    core = [['.'] * w for _ in range(5)]
    for i, ch in enumerate(text):
        for y in range(5):
            for x in range(3):
                if DIGITS[ch][y][x] == '#':
                    core[y][i * 4 + x] = letter
    W, H = w + 2, 7
    out = [['.'] * W for _ in range(H)]
    for y in range(5):
        for x in range(w):
            if core[y][x] != '.':
                out[y + 1][x + 1] = core[y][x]
    for y in range(H):
        for x in range(W):
            if out[y][x] != '.':
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and out[yy][xx] not in '.K':
                        out[y][x] = 'K'
    return [''.join(r) for r in out]


PHANTOM_POINTS = ['200', '400', '800', '1600']
ITEM_POINTS = ['100', '300', '500', '700', '1000', '2000', '3000', '5000']

TARGET = [
    "2...2",
    ".2.2.",
    "..T..",
    ".2.2.",
    "2...2",
]

STARS = [
    "..S......S..",
    ".SSS....SSS.",
    "..S..S...S..",
    ".....SS.....",
]
ZZ = [
    "....ZZZZ",
    "......Z.",
    ".....Z..",
    "ZZZ.ZZZZ",
    "..Z.....",
    ".Z......",
    "ZZZ.....",
]
REWIND = [
    "..K..K.",
    ".KK.KK.",
    "KKKKKK.",
    ".KK.KK.",
    "..K..K.",
]
SPARKLE = [
    "..S..",
    "..S..",
    "SSXSS",
    "..S..",
    "..S..",
]
POP = [
    ["................",
     "................",
     "................",
     "................",
     "......S..S......",
     ".......SS.......",
     "....S.SXXS.S....",
     ".....SXXXXS.....",
     ".....SXXXXS.....",
     "....S.SXXS.S....",
     ".......SS.......",
     "......S..S......",
     "................",
     "................",
     "................",
     "................"],
    ["................",
     "................",
     "...S........S...",
     "....S......S....",
     ".....S....S.....",
     "................",
     "................",
     "..S....XX....S..",
     "..S....XX....S..",
     "................",
     "................",
     ".....S....S.....",
     "....S......S....",
     "...S........S...",
     "................",
     "................"],
]


def squash(rows, keep):
    """Keep only the listed source rows of a 16 x 16 frame, stacked onto the bottom of the box."""
    picked = [rows[i] for i in keep]
    return ['.' * 16] * (16 - len(picked)) + picked


def crash_frames():
    """Dibby's crash, 11 frames, then the 2 frame pop. Facing does not matter: always drawn as is."""
    c = dibby.CLOSED
    shock = [r.replace('P', 'E') for r in c]
    # X eyes: replace the two eyes with little crosses
    shock = [list(r) for r in shock]
    for x0 in (8, 11):
        for y in (7, 8, 9):
            for x in (x0, x0 + 1):
                shock[y][x] = '2'
        shock[7][x0] = 'P'; shock[8][x0] = 'P'; shock[8][x0 + 1] = 'P'; shock[9][x0 + 1] = 'P'
        shock[7][x0 + 1] = '2'; shock[9][x0] = '2'
    shock = [''.join(r) for r in shock]
    # the lid pops up one pixel, then two
    frames = []
    frames.append(shock)                                         # 1 X eyes
    up = ['.' * 16] + shock[2:7] + ['.' * 16] + shock[7:16]
    frames.append(up[:16])                                       # 2 the lid lifts
    up2 = shock[2:7] + ['.' * 16, '.' * 16] + shock[7:16]
    frames.append(up2[:16])                                      # 3 the lid flies higher
    # 4 to 7: the drum squashes down
    for keep in ([2, 3, 4, 6, 7, 8, 10, 11, 12, 13, 14, 15],
                 [2, 3, 6, 7, 8, 10, 12, 13, 14, 15],
                 [2, 3, 6, 8, 10, 13, 14, 15],
                 [2, 6, 10, 13, 15]):
        frames.append(squash(shock, keep))
    # 8 to 11: it falls apart into bits that spread and fade
    for spread, letter in ((1, 'B'), (2, 'B'), (3, 'D'), (4, 'D')):
        rows = [['.'] * 16 for _ in range(16)]
        for bx, by in ((5, 12), (8, 12), (11, 12), (6, 10), (10, 10), (8, 9)):
            x = 8 + (bx - 8) * (1 + spread * 0.5)
            y = by - spread + (spread * spread) // 3
            x, y = int(round(x)), int(round(y))
            for dx in (0, 1):
                for dy in (0, 1):
                    if 0 <= x + dx < 16 and 0 <= y + dy < 16:
                        rows[y + dy][x + dx] = letter
        frames.append([''.join(r) for r in rows])
    return frames


def scale2(rows):
    out = []
    for r in rows:
        rr = ''.join(ch * 2 for ch in r)
        out += [rr, rr]
    return out


def build():
    out = []
    for p in PHANTOM_POINTS:
        out.append(Sprite('pop_%s' % p, popup_rows(p, 'G'), legend={'G': 'Pop Phantom', 'K': 'Outline'}, origin=(len(p) * 2, 3),
                          group='pop', note='%s points for a phantom.' % p))
    for p in ITEM_POINTS:
        out.append(Sprite('pop_%s_item' % p, popup_rows(p, 'F'), legend={'F': 'Pop Item', 'K': 'Outline'}, origin=(len(p) * 2, 3),
                          group='pop', note='%s points for an item.' % p))
    out.append(Sprite('target', TARGET, tone='Mary', legend={'T': 'Target'},
                      origin=(2, 2), group='debug', note='The debug target marker, a cross in the phantom\'s tone 2 with a white centre, on the centre of the target tile.'))
    for i, f in enumerate(crash_frames()):
        out.append(Sprite('crash_%d' % (i + 1), f, tone='Dibby', legend={'E': 'Eye', 'P': 'Pupil', 'L': 'LED', 'B': 'Bit', 'D': 'Token Dim'},
                          origin=(8, 8), group='crash', note=''))
    for i, f in enumerate(POP):
        out.append(Sprite('crash_pop_%d' % (i + 1), f, legend={'S': 'Spark', 'X': 'Bit'}, origin=(8, 8), group='crash',
                          note='The pop at the end of the crash.'))
    out.append(Sprite('stars', STARS, legend={'S': 'Player'}, origin=(6, 2), group='cartoon',
                      note='Dizzy stars, drawn over a head (origin 6 pixels above the phantom origin).'))
    out.append(Sprite('zz', ZZ, legend={'Z': 'Text'}, origin=(0, 6), group='cartoon', note='Snore, for Chip.'))
    out.append(Sprite('rewind', REWIND, legend={'K': 'Pop Phantom'}, origin=(3, 2), group='cartoon', note='Rewind marks behind a phantom going backwards.'))
    out.append(Sprite('sparkle', SPARKLE, legend={'S': 'Token Ring', 'X': 'Spark'}, origin=(2, 2), group='fx', note='The sparkle on a commit token as it lights.'))
    out.append(Sprite('dibby_giant', scale2(dibby.HALF), tone='Dibby', legend=dibby.LEGEND, origin=(16, 16), group='cartoon',
                      note='Giant Dibby (32 x 32): the half frame at 2x, for the title.'))
    return out


ALL = {s.name: s for s in build()}
