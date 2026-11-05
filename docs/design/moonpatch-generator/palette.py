"""The Moonlit Bed palette for Moonpatch: every colour in the game, by name, grouped by use."""
from lib import hx

# The six hue families. Each wave pairs one family for the Gloam with another for the bulbs (see WAVES).
FAMILIES = ['Jade', 'Coral', 'Tide', 'Orchid', 'Cobalt', 'Copper']

GROUPS = [
    ('Ground, band and strip', [
        ('Night', '0A0E22', 'the ground of the garden, above the band'),
        ('Rule', '161D3E', 'the faint dotted rule under every tile row'),
        ('Band', '121838', 'the quieter band of the player zone (rows 24 to 29)'),
        ('Band Rule', '2A3468', 'the top edge of the band, the grass silhouettes at its foot'),
        ('Strip', '05071A', 'the strip of numbers'),
        ('Strip Rule', '2A3468', 'the line under the strip, the plate edges (same value as Band Rule)'),
        ('Mote', '2A3468', 'the far layer: slow drifting stars (same value as Band Rule)'),
        ('Firefly', '5E8C52', 'the near layer: a few slow fireflies (a pulse is a tint toward Night)'),
    ]),
    ('Bulbs and stalks', [
        ('Stalk', '3E5A44', 'the roots of a whole bulb, the seed the Sower carries'),
    ]),
    ('Jade family', [
        ('Jade Light', '9CF0B0', 'lit side'),
        ('Jade', '2EB06A', 'body'),
        ('Jade Deep', '1C7A50', 'shade'),
    ]),
    ('Coral family', [
        ('Coral Light', 'FFB09A', 'lit side'),
        ('Coral', 'F2604A', 'body'),
        ('Coral Deep', 'A23028', 'shade'),
    ]),
    ('Tide family', [
        ('Tide Light', 'A8F4F8', 'lit side'),
        ('Tide', '1EA4BC', 'body'),
        ('Tide Deep', '17788C', 'shade'),
    ]),
    ('Orchid family', [
        ('Orchid Light', 'FFA8F0', 'lit side'),
        ('Orchid', 'DA4EC6', 'body'),
        ('Orchid Deep', '86247E', 'shade'),
    ]),
    ('Cobalt family', [
        ('Cobalt Light', 'B4C8FF', 'lit side'),
        ('Cobalt', '5A82F4', 'body'),
        ('Cobalt Deep', '3044A8', 'shade'),
    ]),
    ('Copper family', [
        ('Copper Light', 'F2C29A', 'lit side'),
        ('Copper', 'C47A44', 'body'),
        ('Copper Deep', '7C4426', 'shade'),
    ]),
    ('Blight (poison)', [
        ('Blight Light', 'F6F2FF', 'a blighted bulb: the lit side; the Moonsnail shell highlight and eyes'),
        ('Blight', 'DCD0F8', 'a blighted bulb: the body; the Moonsnail shell'),
        ('Blight Deep', '8E7CC4', 'a blighted bulb: the shade and the blight spots; the Moonsnail shell spiral'),
    ]),
    ('Danger', [
        ('Ember', 'FF4030', 'the eyes of everything that can kill the Wick, and the Sower\'s eyes; nothing else'),
    ]),
    ('The Wick (the shooter) and its spark', [
        ('Wick Light', 'FFF6CC', 'the lit glass and the flame tip; also the glow tint'),
        ('Wick', 'FFD040', 'the lantern frame and the flame'),
        ('Wick Deep', 'B8801C', 'the base and the shaded frame'),
        ('Spark', 'FFFFFF', 'the head of the spark, the muzzle flash'),
        ('Spark Tail', 'FFE890', 'the tail of the spark'),
    ]),
    ('The pests', [
        ('Husk', '8A96BC', 'the Sower: the shell'),
        ('Husk Light', 'D0DAF4', 'the Sower: the lit shell, the beating wings'),
        ('Jack', 'D8343E', 'the Skitterjack: the shell'),
        ('Jack Light', 'FF8A72', 'the Skitterjack: the lit shell and the legs'),
        ('Snail Foot', '566A9E', 'the Moonsnail: the foot and the eye stalks'),
    ]),
    ('Bursts', [
        ('Flash', 'FFFFFF', 'the first frames of every burst (same value as Spark)'),
        ('Burst', 'FFC060', 'the ring of a burst, the flying sparks'),
        ('Smoke', '3E3060', 'the last frames of a burst, the Wick\'s falling pieces'),
    ]),
    ('Text and screens', [
        ('Text', 'F2EEE0', 'all ordinary text, the moon'),
        ('Text Dim', '8890B8', 'labels, second rank text'),
        ('Points', 'FFD040', 'the points where a thing died, the score (same value as Wick)'),
        ('Moon Top', 'F6F2FF', 'the logo gradient: the top (same value as Blight Light)'),
        ('Moon Low', '8C9CFF', 'the logo gradient: the bottom'),
        ('Plate', '181E4A', 'the plate under PAUSED and GAME OVER, the dark side of the moon icon'),
        ('Ink', '03040C', 'text outlines, the pause veil (a tint)'),
    ]),
]

NAMED = {}
NOTES = {}
for g, items in GROUPS:
    for n, v, note in items:
        assert n not in NAMED, n
        NAMED[n] = v
        NOTES[n] = (g, note)


def C(name):
    return hx(NAMED[name])


def count_distinct():
    return len(set(NAMED.values()))


# The waves: name, the Gloam's family, the bulbs' family. Wave 7 is wave 1 again, and so on.
WAVES = [
    ('NEW MOON', 'Orchid', 'Jade'),
    ('CRESCENT', 'Coral', 'Tide'),
    ('HALF MOON', 'Jade', 'Copper'),
    ('GIBBOUS', 'Tide', 'Orchid'),
    ('FULL MOON', 'Copper', 'Cobalt'),
    ('WANING', 'Cobalt', 'Coral'),
]


def wave(n):
    """1 based wave number to (name, gloam family, bulb family)."""
    return WAVES[(n - 1) % len(WAVES)]


def fam(family, blight=False):
    """Legend for the family letters L, M, D (and s, x for bulbs)."""
    if blight:
        return {'L': 'Blight Light', 'M': 'Blight', 'D': 'Blight Deep', 's': 'Blight Deep', 'x': 'Blight Deep'}
    return {'L': family + ' Light', 'M': family, 'D': family + ' Deep', 's': 'Stalk', 'x': family + ' Deep'}
