"""The First Light palette for Skylark: every colour in the game, by name, grouped by use."""
from lib import hx

GROUPS = [
    ('Land', [
        ('Meadow', '6E9A52', 'open ground, green areas'),
        ('Meadow Light', '8DB466', 'grass tufts, the lit side of ground detail'),
        ('Meadow Dark', '4F7840', 'ground speckle, the dark side of tufts'),
        ('Ochre', 'C2A260', 'open ground, dry areas'),
        ('Ochre Light', 'DEC283', 'the lit side of dry ground detail, the land lines'),
        ('Ochre Dark', '977A44', 'dry ground speckle, the banks of rivers'),
        ('Earth', '6B5236', 'bare earth, the road verges, the floor of the land lines'),
        ('Pad', 'A9A493', 'the stone pads that installations stand on (joints in Stone Dark)'),
    ]),
    ('Forest', [
        ('Canopy', '2F6440', 'the forest roof'),
        ('Canopy Light', '4A8A52', 'the lit crowns of trees'),
        ('Canopy Dark', '1F4630', 'between the crowns'),
        ('Understory', '13301F', 'the dark rim where forest meets open ground'),
    ]),
    ('Water', [
        ('River', '3C78A8', 'river and lake water'),
        ('River Light', '72AAD2', 'ripples, the lit glint lines'),
        ('River Dark', '2A5680', 'deep water, the shaded bank edge'),
        ('Foam', 'D8ECF4', 'the white edge where water meets the bank, the sparkle'),
    ]),
    ('Road', [
        ('Road', '8C877C', 'the road surface'),
        ('Road Edge', '5D594F', 'the road kerb and the bridge rails'),
        ('Road Line', 'EDE3C4', 'the dashed centre line'),
    ]),
    ('The player', [
        ('Hull', 'F2F5F8', 'the Lark: the lit hull, the bright edge of the wings'),
        ('Hull Mid', 'B4C2D2', 'the Lark: the hull'),
        ('Hull Dark', '64738C', 'the Lark: the shaded hull, the keel'),
        ('Hull Ink', '2A3448', 'the Lark: the outline cells and the engine bells'),
        ('Glass', '46D6EE', 'the Lark: the canopy (also Zap Glow is its sibling)'),
        ('Wing Mark', 'F2A33A', 'the Lark: the orange wing marks, the pennant'),
        ('Flame', 'FF9A3A', 'the thruster flame'),
        ('Flame Hot', 'FFF2A8', 'the thruster core, the bomb core'),
        ('Zap', 'FFFFFF', 'the player shot core'),
        ('Zap Glow', '8AF0FF', 'the player shot bloom, the hi-score'),
        ('Sight', 'B6FFE6', 'the sight, normal'),
        ('Sight Lock', 'FF4A4A', 'the sight over a ground target'),
    ]),
    ('Air enemies', [
        ('Plum', '7C4EAE', 'air enemies: the body'),
        ('Plum Light', 'B88EE4', 'air enemies: the lit edge'),
        ('Plum Dark', '472A6E', 'air enemies: the shade'),
        ('Steel', 'D2D0E2', 'air enemies: the metal trim'),
        ('Eye', '7CFFB4', 'the glowing eye on every enemy, air and ground'),
        ('Iron', '3C3C4C', 'the Anvil, the one thing that cannot be killed'),
        ('Iron Light', '8E8EA6', 'the Anvil: the lit rim'),
        ('Iron Edge', '1C1C26', 'the Anvil: the outline and the bolt holes'),
    ]),
    ('Ground targets', [
        ('Stone', 'D4CBB6', 'ground targets: the lit stone'),
        ('Stone Mid', '9E947E', 'ground targets: the stone'),
        ('Stone Dark', '5E5646', 'ground targets: the shade'),
        ('Rust', 'C4583A', 'ground targets: the painted panels'),
        ('Rust Light', 'EC8C5C', 'ground targets: the lit paint'),
        ('Rust Dark', '7C3022', 'ground targets: the dark paint, the barrels'),
        ('Signal', 'FFD64A', 'warning lights, the fire yellow, the score'),
    ]),
    ('Danger', [
        ('Hot', 'FF3D8E', 'every enemy bullet, nothing else is this colour'),
        ('Hot Core', 'FFE4F0', 'the centre of an enemy bullet'),
    ]),
    ('Explosions', [
        ('Flash', 'FFFFFF', 'the first frame of every explosion (same value as Zap)'),
        ('Fire', 'FF8A2A', 'the body of a fire ball'),
        ('Fire Dark', 'C8402A', 'the outer flame'),
        ('Smoke', '5C4C48', 'smoke and flying debris'),
        ('Scorch', '2C231B', 'the burnt ground left behind'),
        ('Scorch Edge', '4D3E2C', 'the ragged rim of a scorch'),
        ('Glow Light', 'FFE2A6', 'the light an explosion throws on the land (a tint)'),
    ]),
    ('Boss', [
        ('Shell', '6C7C98', 'the Citadel: the hull'),
        ('Shell Light', 'AEBED6', 'the Citadel: the lit plates'),
        ('Shell Dark', '3A4560', 'the Citadel: the shade and the seams'),
        ('Core', '7CFFB4', 'the Citadel core (same value as Eye, on purpose)'),
        ('Core Dark', '1E7A5C', 'the Citadel core: the ring round the eye'),
    ]),
    ('Text and strip', [
        ('Strip', '0D1522', 'the score and lives strips, the pause veil'),
        ('Ink', '0A1018', 'outlines of text, the shadow tint'),
        ('Text', 'F4EFE2', 'all ordinary text'),
        ('Text Dim', '8A95AA', 'labels and second rank text'),
        ('Dawn Top', 'FFE2A6', 'the title gradient: the top (same value as Glow Light)'),
        ('Dawn Low', 'F2764E', 'the title gradient: the bottom'),
        ('Haze', 'D8ECF4', 'the parallax haze, a tint (same value as Foam)'),
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
