"""The lamps (cubes), the pyramid layout, the sky and the void."""
import random
from lib import Canvas, Sprite
from palette import C, TONE, hx, THEMES, spill

W, H = 256, 256
HUD_H = 32
PITCH_X, PITCH_Y = 32, 24
APEX_Y = 48
ROWS = 7


# ---- geometry --------------------------------------------------------------------------------------------------------
def cube_xy(r, c):
    """Top left of the 32 x 32 picture of the cube at row r (1 to 7), column c (0 to r - 1)."""
    return 128 - 16 * r + 32 * c, APEX_Y + 24 * (r - 1)


def foot_xy(r, c):
    """Where a sprite's origin (the middle of its feet) goes for the cube at (r, c). c may be -1 or r for a disc."""
    x, y = cube_xy(r, c)
    return x + 16, y + 8


def cells():
    return [(r, c) for r in range(1, ROWS + 1) for c in range(r)]


# ---- the cube picture --------------------------------------------------------------------------------------------------
def top_hw(j, n=16):
    """Half width of the top diamond at row j, for a diamond n rows high (2 across for 1 down)."""
    h = n // 2
    return 2 * (j + 1) if j < h else 2 * (n - j)


def cube_grid(state, size=32):
    """state: 'unlit', 'half', 'done', 'undo' (an unlit lamp that can turn back), 'undo_done'.
    Top uses tone digits 1 to 5 of the state's row; the faces use letters (see LEG)."""
    s = size
    th = s // 2          # top diamond height
    fh = s // 2          # face height
    g = [['.'] * s for _ in range(s)]
    mid = s // 2
    bottom = [0] * s
    for j in range(th):
        hw = top_hw(j, th)
        x0, x1 = mid - hw, mid + hw - 1
        for i in range(x0, x1 + 1):
            g[j][i] = '3'
            bottom[i] = j
        rim = 2 if s == 32 else 1
        for k in range(rim):
            if j < th // 2:
                g[j][x0 + k] = '2'
                g[j][x1 - k] = '2'
            else:
                g[j][x0 + k] = '4'
                g[j][x1 - k] = '4'
        if j == 0:
            for i in range(x0, x1 + 1):
                g[j][i] = '2'
        if j == th - 1:
            for i in range(x0, x1 + 1):
                g[j][i] = '4'
    # inner diamond: half the size, centred
    ih = th // 2
    inner = []
    for jj in range(ih):
        hw = top_hw(jj, ih)
        j = th // 4 + jj
        inner.append((j, mid - hw, mid + hw - 1))
    if state in ('half',):
        rim = 2 if s == 32 else 1
        for j, x0, x1 in inner:
            t = '1' if j < th // 2 else '2'
            for k in range(rim):
                g[j][x0 + k] = t
                g[j][x1 - k] = t
            if j == inner[0][0] or j == inner[-1][0]:
                for i in range(x0, x1 + 1):
                    g[j][i] = t
    if state in ('done', 'undo_done'):
        for j, x0, x1 in inner:
            for i in range(x0, x1 + 1):
                g[j][i] = '2'
        core = inner[len(inner) // 2 - 1:len(inner) // 2 + 1] if s == 32 else []
        for j, x0, x1 in core:
            for i in range(x0 + 4, x1 - 3):
                g[j][i] = '1'
    if state in ('undo', 'undo_done'):
        # a dotted rim: on every other row the 2 rim pixels on each side change, light dots on an unlit lamp,
        # dark dots on a lit one (a lamp that can turn back)
        dot = '1' if state == 'undo' else '5'
        for j in range(1, th - 1):
            hw = top_hw(j, th)
            x0, x1 = mid - hw, mid + hw - 1
            if j % 2 == 0:
                g[j][x0] = g[j][x0 + 1] = dot
                g[j][x1] = g[j][x1 - 1] = dot
    # faces
    for i in range(s):
        left = i < mid
        top0 = bottom[i] + 1
        for k in range(fh):
            j = top0 + k
            if j >= s:
                break
            if k < 2:
                ch = 'L' if left else 'R'
            elif k >= fh - 1:
                ch = 'E'
            elif k >= fh - 4:
                ch = 'N' if left else 'T'
            else:
                ch = 'M' if left else 'S'
            g[j][i] = ch
    return [''.join(r) for r in g]


FACE_LEG = {'L': 'Left Lip', 'M': 'Left', 'N': 'Left Low', 'R': 'Right Lip', 'S': 'Right', 'T': 'Right Low', 'E': 'Edge'}


def cube_colours(state, theme=0):
    """letter -> colour for a cube in a state, in a level theme."""
    half, done, _ = THEMES[theme]
    row = {'unlit': 'Unlit', 'undo': 'Unlit', 'half': half, 'done': done, 'undo_done': done}[state]
    m = {str(i + 1): hx(TONE[row][i]) for i in range(5)}
    for k, v in FACE_LEG.items():
        m[k] = C(v)
    if state in ('done', 'undo_done'):
        a, b = spill(done)
        m['L'], m['R'] = C(a), C(b)
    return m, row


def draw_cube(cv, x, y, state, theme=0, size=32):
    rows = cube_grid(state if state != 'flip' else 'unlit', size)
    m, _ = cube_colours(state if state != 'flip' else 'unlit', theme)
    for j, line in enumerate(rows):
        for i, ch in enumerate(line):
            if ch != '.':
                cv.put(x + i, y + j, m[ch])


def flip_grid():
    """One frame of a flipping lamp (a later level): the top squashed to half height, the far face showing."""
    g = cube_grid('unlit')
    out = [['.'] * 32 for _ in range(32)]
    # top squashed: rows 4..11 of an 8 high diamond
    for j in range(8):
        hw = top_hw(j, 8)
        for i in range(16 - hw * 2, 16 + hw * 2):
            out[4 + j][i] = '3' if 0 < j < 7 else ('2' if j == 0 else '4')
    # under it the back face edge in the done tone, a 4 row strip
    for j in range(12, 16):
        for i in range(32):
            if g[j][i] in '1234' or g[j][i] in 'LR':
                out[j][i] = 'D'
    for j in range(32):
        for i in range(32):
            if out[j][i] == '.' and g[j][i] in 'LMNRSTE':
                out[j][i] = g[j][i]
    return [''.join(r) for r in out]


# ---- the background --------------------------------------------------------------------------------------------------
BANDS = [(32, 'Dusk A'), (80, 'Dusk B'), (128, 'Dusk C'), (176, 'Dusk D'), (216, 'Void Top'), (240, 'Void Deep')]


def band_at(y):
    name = None
    for y0, n in BANDS:
        if y >= y0:
            name = n
    return name


def stars(seed=7):
    rnd = random.Random(seed)
    out = []
    while len(out) < 46:
        x, y = rnd.randrange(2, 254), rnd.randrange(34, 214)
        out.append((x, y, 'Star' if rnd.random() < 0.22 else 'Star Dim'))
    return out


def background(theme=0):
    cv = Canvas(W, H, C('HUD'))
    for y in range(HUD_H, H):
        for x in range(W):
            cv.put(x, y, C(band_at(y)))
        # 2 row dither into the next band: rows y0 - 2 and y0 - 1 take the next band on a checkerboard
        for y0, n in BANDS[1:]:
            if y0 - 2 <= y < y0:
                for x in range(W):
                    if (x + y) % 2 == 0:
                        cv.put(x, y, C(n))
    for x in range(W):
        cv.put(x, HUD_H - 1, C('HUD Rule'))
    for x, y, n in stars():
        cv.put(x, y, C(n))
    return cv


def pyramid(cv, states, theme=0):
    """states: (r, c) -> state name; missing cells are unlit."""
    for r, c in cells():
        x, y = cube_xy(r, c)
        draw_cube(cv, x, y, states.get((r, c), 'unlit'), theme)


# ---- discs --------------------------------------------------------------------------------------------------------
DISC_ROWS = [3, 4, 5]


def disc_spots():
    """(side, row, centre x, centre y): the halo's centre goes on the foot point of the cube that is not there."""
    out = []
    for r in DISC_ROWS:
        out.append(('left', r) + foot_xy(r, -1))
        out.append(('right', r) + foot_xy(r, r))
    return out
