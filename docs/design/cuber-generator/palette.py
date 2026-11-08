"""The Dusk Lamps palette for Lamplighter (working title Cuber): every colour in the game, by name, grouped by use.

Tone rows: five values from highlight (1) to edge (5). Most are made by tones(); a few are set by hand and say so.
"""
from lib import hx, mix, tohex

INK = '0B0614'


def tones(base, hi=0.62, lo=0.30, sh=0.36, ed=0.72, ink=INK):
    b = hx(base)
    w = (255, 255, 255)
    k = hx(ink)
    return [tohex(mix(b, w, hi)), tohex(mix(b, w, lo)), tohex(b), tohex(mix(b, k, sh)), tohex(mix(b, k, ed))]


# ---- tone rows: name -> five hex values, and a note --------------------------------------------------------------
ROWS = [
    # the tops of the lamps (the cubes). Unlit is the same on every level; half and lit change with the level theme.
    ('Unlit', tones('3A3F78', hi=0.38, lo=0.16, sh=0.30, ed=0.62), 'a lamp not yet reached: dark slate, plain top'),
    ('Mint Half', tones('2C8E8E', hi=0.46, lo=0.22), 'level 1 theme: a lamp half way (three hop levels)'),
    ('Mint', tones('5CEDB6', hi=0.62, lo=0.32), 'level 1 theme: a lamp done, the target colour'),
    ('Rose Half', tones('A0447A', hi=0.46, lo=0.22), 'level 2 theme: half way'),
    ('Rose', tones('FF84BE', hi=0.62, lo=0.32), 'level 2 theme: done'),
    ('Sky Half', tones('3468B0', hi=0.46, lo=0.22), 'level 3 theme: half way'),
    ('Sky', tones('7CCBFF', hi=0.62, lo=0.32), 'level 3 theme: done'),
    ('Lilac Half', tones('7650B4', hi=0.46, lo=0.22), 'level 4 theme: half way'),
    ('Lilac', tones('CDA6FF', hi=0.62, lo=0.32), 'level 4 theme: done'),
    # Pip, the hero (set by hand: a warm edge, not a grey one)
    ('Pip', ['FFF7D6', 'FFE88E', 'FFD247', 'E0912C', '4A1A22'], 'Pip, the hero: a lemon gummy that glows from inside'),
    # the Coil and its seed: charcoal with a hot rim (the rim and the cracks are the letters E and F)
    ('Coil', ['A79CB2', '726880', '4A4156', '2E2838', '15101C'], 'the Coil, the chaser, and its seed: charcoal'),
    # the Thorn: the only red thing that moves
    ('Thorn', tones('EC3442', hi=0.55, lo=0.26, sh=0.32, ed=0.66), 'the Thorn, the bouncing ball that kills'),
    # the Frost: ice, never dark, no rim
    ('Frost', ['FFFFFF', 'D6F6FF', '9EE6FF', '4FAFE0', '22609A'], 'the Frost, the ball that freezes (set by hand)'),
    # the moths: Snuff (left edge) and Puff (right edge), the undoers
    ('Snuff', tones('B4A0E0', hi=0.55, lo=0.25, sh=0.38, ed=0.70), 'Snuff, the moth of the left edge: dusty lilac wings'),
    ('Puff', tones('E0C27E', hi=0.55, lo=0.25, sh=0.38, ed=0.70), 'Puff, the moth of the right edge: dusty sand wings'),
    # halos (the discs)
    ('Halo', ['FFFFFF', 'C8F4FF', '6ED2F2', '2F86B6', '17406A'], 'a halo, the disc that lifts Pip home (set by hand)'),
    # the frozen tint row: any tone row is swapped for this one while the freeze lasts
    ('Ice', ['FFFFFF', 'E2F8FF', 'B6E8FA', '6CB4DA', '2C5E8C'], 'the frozen tint: replaces every tone row of a frozen enemy'),
    # the death flash rows
    ('Flash', ['FFFFFF', 'FFFFFF', 'FFF2EA', 'FF9A80', 'FF4A3A'], 'death flash frame 1: Pip goes white hot'),
    ('Negative', ['15101C', '2A1A30', '4A2236', 'FFE88E', 'FFFFFF'], 'death flash frame 2: Pip inverted (dark body, white edge)'),
]

TONE = {n: t for n, t, _ in ROWS}
ROW_NOTE = {n: d for n, _, d in ROWS}

THEMES = [  # level -> (half row, done row, name)
    ('Mint Half', 'Mint', 'MINT'),
    ('Rose Half', 'Rose', 'ROSE'),
    ('Sky Half', 'Sky', 'SKY'),
    ('Lilac Half', 'Lilac', 'LILAC'),
]

# ---- single colours ------------------------------------------------------------------------------------------------
GROUPS = [
    ('Sky, void and HUD', [
        ('HUD', '0C0818', 'the HUD strip, rows 0 to 31'),
        ('HUD Rule', '2C2250', 'the 1 pixel rule under the HUD (row 31)'),
        ('Dusk A', '231538', 'the dusk sky, band 1 (rows 32 to 79)'),
        ('Dusk B', '1D1130', 'band 2 (rows 80 to 127)'),
        ('Dusk C', '170D28', 'band 3 (rows 128 to 175)'),
        ('Dusk D', '120A20', 'band 4 (rows 176 to 215)'),
        ('Void Top', '0A0614', 'the void, rows 216 to 239'),
        ('Void Deep', '050309', 'the void, rows 240 to 255: if you fall here you are gone'),
        ('Star Dim', '3A2C5E', 'a far star (1 pixel, baked)'),
        ('Star', '8676B4', 'a near star (1 pixel, a few of them twinkle by swapping with Star Dim)'),
        ('Lantern', 'B0704A', 'a far sky lantern (2 x 3, drifting up, a particle)'),
        ('Lantern Dim', '5A3436', 'the glow round a far lantern and its tail'),
        ('Mote', '35264E', 'a mote falling into the void (particles under the pyramid)'),
    ]),
    ('The stone of the lamps (cube sides)', [
        ('Left Lip', '8E7EB8', 'the left face: the 2 rows under the top edge'),
        ('Left', '5E4F8A', 'the left face, lit from the upper left'),
        ('Left Low', '4C3F74', 'the left face, the lowest 3 rows (a soft fall off)'),
        ('Right Lip', '584A80', 'the right face: the 2 rows under the top edge'),
        ('Right', '3A305E', 'the right face, in shade'),
        ('Right Low', '2E264C', 'the right face, the lowest 3 rows'),
        ('Edge', '150E26', 'the 1 pixel edge line of the outer bottom edges and the seam'),
    ]),
    ('Lamp light', [
        ('Spill Mint', '5FBFA6', 'the lip rows of a lit lamp, level 1 (light spilling down the stone)'),
        ('Spill Mint Dark', '3E8A86', 'the right lip of a lit lamp, level 1'),
        ('Spill Rose', 'C4729E', 'the lips of a lit lamp, level 2'),
        ('Spill Rose Dark', '8C4C7C', 'the right lip of a lit lamp, level 2'),
        ('Spill Sky', '6E9ED8', 'the lips of a lit lamp, level 3'),
        ('Spill Sky Dark', '4C6CA8', 'the right lip of a lit lamp, level 3'),
        ('Spill Lilac', 'A88ADC', 'the lips of a lit lamp, level 4'),
        ('Spill Lilac Dark', '7660AA', 'the right lip of a lit lamp, level 4'),
    ]),
    ('Pip extras', [
        ('Eye', 'FFFFFF', 'an eye white (letter A)'),
        ('Pupil', '1E0E26', 'a pupil (letter B), and Pip\'s closed eye line'),
        ('Cheek', 'FF8C78', 'Pip\'s cheeks (letter C)'),
    ]),
    ('Danger', [
        ('Ember', 'FF5A36', 'the hot rim of the Coil and its seed, the cracks of the seed: everything that hunts you'),
        ('Ember Deep', 'B0242C', 'the deep cracks and the inside of the Coil\'s jaw'),
        ('Coil Eye', 'FFE24A', 'the Coil\'s eyes'),
        ('Fang', 'FFF4E8', 'the Coil\'s fangs and the Thorn\'s glint'),
    ]),
    ('Moth extras', [
        ('Moth Body', '5C4A6E', 'the body of both moths'),
        ('Moth Eye', 'F4F0FF', 'the eyes of both moths'),
    ]),
    ('Text and screens', [
        ('Text', 'F4F0FA', 'numbers and words'),
        ('Label', '9C8EC4', 'SCORE, HI, LEVEL, ROUND and the key hints'),
        ('Gold', 'FFD247', 'good news: a new high score, points, an extra life (same value as Pip tone 3 on purpose)'),
        ('Title Top', 'FFF4C0', 'the title, top row of the gradient'),
        ('Title Bottom', 'FF9A4E', 'the title, bottom row'),
        ('Over Top', 'FFB0A0', 'GAME OVER, top row'),
        ('Over Bottom', 'EC3442', 'GAME OVER, bottom row (the Thorn\'s red: red means danger)'),
        ('Plate', '0C0818', 'the fill of every banner plate (same value as HUD)'),
        ('Plate Rule', '6ED2F2', 'the two rules of a banner plate (same value as Halo tone 3: a banner is good news or a pause)'),
        ('Outline', '0B0614', 'the 1 pixel outline behind text on the play area'),
        ('Spark', 'FFFFFF', 'the first colour of every spark and glint'),
    ]),
]

NAMED = {}
NOTE = {}
for _, items in GROUPS:
    for n, h, d in items:
        NAMED[n] = h
        NOTE[n] = d
for n, t, _ in ROWS:
    for i, h in enumerate(t):
        NAMED['%s %d' % (n, i + 1)] = h


def C(name):
    return hx(NAMED[name])


def spill(done):
    """The lip colours of a lit lamp for a done row name."""
    return 'Spill ' + done, 'Spill ' + done + ' Dark'


def count_distinct():
    return len(set(v.upper() for v in NAMED.values()))
