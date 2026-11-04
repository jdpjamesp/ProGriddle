"""Bonus items (each its own shape), the COMMIT token, the data bit and other small things."""
from lib import Sprite


def box(rows, w=16, h=16):
    """Pad hand drawn rows to w x h, centred."""
    rows = [r.rstrip('\n') for r in rows]
    mw = max(len(r) for r in rows)
    rows = [r.ljust(mw, '.') for r in rows]
    left = (w - mw) // 2
    top = (h - len(rows)) // 2
    out = ['.' * w] * top + ['.' * left + r + '.' * (w - mw - left) for r in rows]
    out += ['.' * w] * (h - len(out))
    for r in out:
        assert len(r) == w, (r, len(r))
    return out


FLOPPY = box([
    "KKKKKKKKKKKK..",
    "KBB2222222BBK.",
    "KBB22KK222BBBK",
    "KBB22KK222BBBK",
    "KBB4444444BBBK",
    "KBBBBBBBBBBBBK",
    "KBLLLLLLLLLLBK",
    "KBLNNNNNNNNLBK",
    "KBLLLLLLLLLLBK",
    "KBLNNNNNNLLLBK",
    "KBLLLLLLLLLLBK",
    "KNNNNNNNNNNNNK",
    "KKKKKKKKKKKKKK",
])
TAPE = box([
    "....RRRRRR....",
    "..RRTTTTTTRR..",
    ".RTTTTTTTTTTR.",
    ".RTTTRRRRTTTR.",
    "RTTTRKRRKRTTTR",
    "RTTRRRRRRRRTTR",
    "RTTRKRRRRKRTTR",
    "RTTRRRKKRRRTTR",
    "RTTRRRRRRRRTTR",
    "RTTTRKRRKRTTTR",
    ".RTTTRRRRTTTR.",
    ".RTTTTTTTTTTR.",
    "..RRTTTTTTRR..",
    "....RRRRRR....",
])
KEY = box([
    ".GGGG.........",
    "GGOOGG........",
    "GO..OG........",
    "GO..OGGGGGGGGG",
    "GO..OGOOOOOOOG",
    "GGOOGG...GG.GG",
    ".GGGG....GO.GO",
    ".........OO.OO",
])
TABLE = box([
    "WWWWWWWWWWWWWW",
    "WHHHWHHHHWHHHW",
    "WHHHWHHHHWHHHW",
    "WWWWWWWWWWWWWW",
    "WCCCWCCCCWCCCW",
    "WCCCWCCCCWCCCW",
    "WWWWWWWWWWWWWW",
    "WCCCWCCCCWCCCW",
    "WCCCWCCCCWCCCW",
    "WWWWWWWWWWWWWW",
])
QUERY = box([
    "...SSSSS......",
    "..SGGGGGS.....",
    ".SGXXGGGGS....",
    "SGGXGGGGGGS...",
    "SGGGGGGGGGS...",
    "SGGGGGGGGGS...",
    "SGGGGGGGGGS...",
    ".SGGGGGGGS....",
    "..SGGGGGSSS...",
    "...SSSSSSHHH..",
    "........HHHH..",
    ".........HHHH.",
    "..........HHHH",
    "...........HH.",
])
GEAR = box([
    "......GG......",
    "..GG..GG..GG..",
    "..GGGGGGGGGG..",
    "...GGOOOOGG...",
    "..GGO....OGG..",
    "GGGO......OGGG",
    "GGGO......OGGG",
    "..GGO....OGG..",
    "...GGOOOOGG...",
    "..GGGGGGGGGG..",
    "..GG..GG..GG..",
    "......GG......",
])
LOCK = box([
    "....SSSSSS....",
    "...SS....SS...",
    "..SS......SS..",
    "..SS......SS..",
    "..SS......SS..",
    "GGGGGGGGGGGGGG",
    "GOOOOOOOOOOOOG",
    "GOGGGGKKGGGGOG",
    "GOGGGKKKKGGGOG",
    "GOGGGGKKGGGGOG",
    "GOGGGGKKGGGGOG",
    "GOOOOOOOOOOOOG",
    "GGGGGGGGGGGGGG",
])
SERVER = box([
    "QQQQQQQQQQ",
    "QRRRRRRRRQ",
    "QRVRARRVRQ",
    "QRRRRRRRRQ",
    "QQQQQQQQQQ",
    "QRRRRRRRRQ",
    "QRARVRRARQ",
    "QRRRRRRRRQ",
    "QQQQQQQQQQ",
    "QRRRRRRRRQ",
    "QRVRVRRVRQ",
    "QRRRRRRRRQ",
    "QQQQQQQQQQ",
    ".Q......Q.",
])

ITEMS = [
    # name, rows, legend, points, levels, note
    ('item_floppy', FLOPPY, {'K': 'Ink', 'B': 'Disk Blue', 'N': 'Disk Dark', 'L': 'Label'}, 'Steel', 100, '1',
     'A floppy disk: a square with a cut corner, a metal shutter and a label.'),
    ('item_tape', TAPE, {'R': 'Reel', 'T': 'Tape', 'K': 'Ink'}, None, 300, '2',
     'A tape reel: a round flange, dark tape wound on it, a hub with three holes.'),
    ('item_key', KEY, {'G': 'Gold', 'O': 'Gold Shade'}, None, 500, '3 and 4',
     'A primary key: a long key lying flat, ring on the left, two teeth.'),
    ('item_table', TABLE, {'W': 'Grid', 'H': 'Grid Head', 'C': 'Grid Cell'}, None, 700, '5 and 6',
     'A table: a wide grid with a blue header row.'),
    ('item_query', QUERY, {'S': 'Reel', 'G': 'Glass', 'X': 'Glass Shine', 'H': 'Handle'}, None, 1000, '7 and 8',
     'A query: a magnifier, a round glass with a handle to the bottom right.'),
    ('item_trigger', GEAR, {'G': 'Gold', 'O': 'Gold Shade'}, None, 2000, '9 and 10',
     'A trigger: a gear with eight teeth and an open middle.'),
    ('item_lock', LOCK, {'S': 'Reel', 'G': 'Gold', 'O': 'Gold Shade', 'K': 'Ink'}, None, 3000, '11 and 12',
     'A lock: a padlock, a tall shackle over a box with a keyhole.'),
    ('item_server', SERVER, {'Q': 'Rack Edge', 'R': 'Rack', 'V': 'Rack LED', 'A': 'Rack Amber'}, None, 5000, '13 on',
     'A server: a tall rack of three units with lights.'),
]

TOKEN = [
    "..RR..",
    ".RTTR.",
    "RTTTTR",
    "RTTTTR",
    ".RTTR.",
    "..RR..",
]
TOKEN_DIM = [
    "......",
    "..DD..",
    ".DRRD.",
    ".DRRD.",
    "..DD..",
    "......",
]


def build():
    out = []
    for name, rows, leg, tone, pts, lv, note in ITEMS:
        out.append(Sprite(name, rows, tone=tone, legend=leg, origin=(8, 8), group='item',
                          note='%s %d points, level %s.' % (note, pts, lv)))
    out.append(Sprite('commit_on', TOKEN, legend={'R': 'Token Ring', 'T': 'Token'}, origin=(3, 3), group='token',
                      note='The commit token, lit (6 x 6). Its top left is at tile pixel (1, 1).'))
    out.append(Sprite('commit_dim', TOKEN_DIM, legend={'R': 'Token Ring', 'D': 'Token Dim'}, origin=(3, 3), group='token',
                      note='The commit token, dim blink frame: smaller and darker, never gone, so a player can always see where it is.'))
    return out


ALL = {s.name: s for s in build()}
