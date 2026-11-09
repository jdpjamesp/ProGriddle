"""The goal mouth rules: which pose meets which target, where it stands, and the ball's flight."""
import scene as S
import keeper as K

COLS = ('left', 'middle', 'right')
ROWS = ('high', 'middle', 'low')


def save_pose(c, r):
    """(sprite, mirrored, origin x, origin y) of the keeper saving at target column c, row r (0 to 2)."""
    tx, ty = S.GM_TX[c], S.GM_TY[r]
    if c == 1:
        if r == 0:
            dx, dy = K.glove_offset('gm_keeper_jump')
            return ('gm_keeper_jump', False, int(round(tx - dx)), int(round(ty - dy)))
        return ('gm_keeper_hold', False, S.KEEPER_FEET[0], S.KEEPER_FEET[1])
    name = 'gm_keeper_high_right' if r == 0 else 'gm_keeper_dive_right'
    dx, dy = K.glove_offset(name)
    flip = c == 0
    if flip:
        dx = -dx
    ox, oy = int(round(tx - dx)), int(round(ty - dy))
    if r == 2:
        oy = max(oy, 0)
    return (name, flip, ox, oy)


def beaten_pose(c, r):
    """The keeper beaten: he goes the other way (middle shots: he dives right low)."""
    oc = {0: 2, 1: 2, 2: 0}[c]
    orow = 1 if r == 0 else r
    name, flip, ox, oy = save_pose(oc, orow)
    return name, flip, ox, oy


def flight(tx, ty):
    """The ball's three frames toward the target: near at a third of the way from (48, 70), mid at two thirds, far on it."""
    sx, sy = 48, 70
    return [('gm_ball_near', sx + (tx - sx) // 3, sy + (ty - sy) // 3),
            ('gm_ball_mid', sx + 2 * (tx - sx) // 3, sy + 2 * (ty - sy) // 3),
            ('gm_ball_far', tx, ty)]
