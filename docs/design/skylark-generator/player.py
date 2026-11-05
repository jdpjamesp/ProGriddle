"""The Lark (the player's ship), its flame, the Zapper shot, the bomb, the sight and the breakup."""
from lib import Sprite, mirror

LARK_LEG = {'K': 'Hull Ink', 'W': 'Hull', 'M': 'Hull Mid', 'D': 'Hull Dark', 'G': 'Glass', 'O': 'Wing Mark'}

# Left half of the Lark, lit from the upper left. The right half is the mirror, one tone darker.
LEFT = [
    '........',
    '.......K',
    '......KW',
    '......KG',
    '.....KWG',
    '.....KWM',
    '....KKWM',
    '...KWKWM',
    '..KWWKWM',
    '.KWOWKWM',
    'KWWOWWWM',
    'KWWWWKWM',
    '.KKKKKDM',
    '.....KDK',
    '......K.',
    '........',
]
DARKER = {'W': 'M', 'M': 'D', 'D': 'D', 'G': 'G', 'O': 'O', 'K': 'K', '.': '.'}
LIGHTER = {'W': 'W', 'M': 'W', 'D': 'M', 'G': 'G', 'O': 'O', 'K': 'K', '.': '.'}


def join(left, right_map):
    out = []
    for r in left:
        right = ''.join(right_map[c] for c in r[::-1])
        out.append(r + right)
    return out


def lark_level():
    return join(LEFT, DARKER)


FOLD = {'W': 'M', 'M': 'D', 'D': 'D', 'G': 'G', 'O': 'O', 'K': 'K', '.': '.'}
SAME = {c: c for c in 'WMDGOK.'}


def fold(rows):
    """Fold a left half wing in by two cells (rows 7 to 12), keeping an outline at its tip."""
    out = []
    for i, r in enumerate(rows):
        if 7 <= i <= 12:
            r = '..' + r[2:]
            j = len(r) - len(r.lstrip('.'))
            if j < 5:
                r = r[:j] + 'K' + r[j + 1:]
        out.append(r)
    return out


def lark_bank(side):
    """Banking: the wing on the turning side folds in by two cells and goes a tone darker,
    the other wing tips up to the light. The light stays on the upper left."""
    if side == 'left':
        left = [''.join(FOLD[c] if k < 5 else c for k, c in enumerate(r)) for r in fold(LEFT)]
        return [a + ''.join(LIGHTER[c] for c in b[::-1]) for a, b in zip(left, LEFT)]
    right = [''.join(DARKER[FOLD[c]] if k < 5 else DARKER[c] for k, c in enumerate(r)) for r in fold(LEFT)]
    return [a + b[::-1] for a, b in zip(LEFT, right)]


FLAME_LEG = {'Y': 'Flame Hot', 'F': 'Flame'}
FLAME_1 = ['......Y..Y......', '......F..F......', '................']
FLAME_2 = ['......Y..Y......', '......Y..Y......', '.....F.FF.F.....']

SHOT = ['.Z.', 'GZG', 'GZG', '.Z.', '.G.', '.G.']
SHOT_LEG = {'Z': 'Zap', 'G': 'Zap Glow'}

BOMB_LEG = {'Y': 'Flame Hot', 'O': 'Wing Mark', 'K': 'Hull Ink'}
BOMB_1 = ['.......', '.......', '..OOO..', '..OYO..', '..OOO..', '.......', '.......']
BOMB_2 = ['.......', '..OOO..', '.OYYYO.', '.OYYYO.', '.OYYYO.', '..OOO..', '.......']
BOMB_3 = ['..OOO..', '.O...O.', 'O..Y..O', 'O.YYY.O', 'O..Y..O', '.O...O.', '..OOO..']
BOMB_SHADOW = ['.SSS.', 'SSSSS', '.SSS.']

def sight_rows():
    return [
        'kkkk.......kkkk',
        'kSSSk..k..kSSSk',
        'kSkk..kSk..kkSk',
        'kSk...kSk...kSk',
        '.k.....k.....k.',
        '...............',
        '.kk....k....kk.',
        'kSSk..kSk..kSSk',
        '.kk....k....kk.',
        '...............',
        '.k.....k.....k.',
        'kSk...kSk...kSk',
        'kSkk..kSk..kkSk',
        'kSSSk..k..kSSSk',
        'kkkk.......kkkk',
    ]


def sprites():
    out = []
    out.append(Sprite('lark', lark_level(), LARK_LEG, 'The Lark, level flight. Facing up, lit from the upper left. Box 12 x 12 at (2, 2), a little inside the wings so a graze is forgiven.', box=(2, 2, 12, 12), group='player'))
    out.append(Sprite('lark_bank_left', lark_bank('left'), LARK_LEG, 'Moving left: the left wing folds in and darkens, the right wing turns its top to the light. Same box.', box=(2, 2, 12, 12), group='player'))
    out.append(Sprite('lark_bank_right', lark_bank('right'), LARK_LEG, 'Moving right: the mirror of lark_bank_left, with the light kept on the upper left. Same box.', box=(2, 2, 12, 12), group='player'))
    out.append(Sprite('flame_1', FLAME_1, FLAME_LEG, 'Thruster, frame 1 of 2 (4 frames each). Drawn with its top left at the Lark\'s top left + (0, 13), so the flames sit under the two engine bells.', group='player', origin=(8, 0)))
    out.append(Sprite('flame_2', FLAME_2, FLAME_LEG, 'Thruster, frame 2 of 2. While the Lark moves up the flame stays on frame 2.', group='player', origin=(8, 0)))
    out.append(Sprite('zap', SHOT, SHOT_LEG, 'The Zapper shot. Box 1 x 4 at (1, 0): the core only. The glow cells are the bloom and never collide.', box=(1, 0, 1, 4), group='player'))
    out.append(Sprite('bomb_1', BOMB_1, BOMB_LEG, 'Bomb in flight, frame 1 of 3 (3 frames each, looping 1 2 3 2). It has no box: a bomb only acts where it lands.', group='player'))
    out.append(Sprite('bomb_2', BOMB_2, BOMB_LEG, 'Bomb, frame 2.', group='player'))
    out.append(Sprite('bomb_3', BOMB_3, BOMB_LEG, 'Bomb, frame 3: the ring opens out, the core shrinks. The last 4 frames before it lands it stays on this frame.', group='player'))
    out.append(Sprite('bomb_shadow', BOMB_SHADOW, {'S': 'Ink'}, 'The bomb\'s shadow: a tint pass (Ink at 35%), not a colour. It slides from under the Lark to the sight while the bomb flies, so the player can see where it will land.', group='player'))
    rows = sight_rows()
    out.append(Sprite('sight', rows, {'S': 'Sight', 'k': 'Ink'}, 'The sight, normal. One colour (Sight) with an Ink keyline one cell wide, so it reads over foam, ochre and forest alike. The centre cell (7, 7) is the aim point. The bomb\'s blast box is 16 x 16 centred on that cell.', group='player'))
    out.append(Sprite('sight_lock', rows, {'S': 'Sight Lock', 'k': 'Ink'}, 'The sight over a ground target: the same cells in Sight Lock. It also gets the bloom (section 5).', group='player'))
    return out


def breakup_pieces():
    """The Lark cut into four pieces: nose, left wing, right wing, tail. (name, rows, start x, start y, dx, dy, turn)."""
    s = lark_level()
    def cut(x0, y0, x1, y1):
        return [''.join(s[y][x] if (x0 <= x < x1 and y0 <= y < y1) else '.' for x in range(16)) for y in range(16)]
    return [
        ('nose', cut(5, 0, 11, 7), 0, -1, 0.0, -0.6),
        ('wing_left', cut(0, 7, 6, 13), -1, 0, -0.7, 0.2),
        ('wing_right', cut(10, 7, 16, 13), 1, 0, 0.7, 0.2),
        ('tail', cut(6, 7, 10, 16), 0, 1, 0.0, 0.5),
    ]
