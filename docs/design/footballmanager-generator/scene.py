"""The scenery: the tunnel bars, the chalkboard, the match pitch, the stands and the goal mouth picture.

Every number here is final and is printed into the design file by doc.py."""
from lib import Canvas, put, text_width
from palette import C
import sprites as SP

W, H = 320, 240

# ---- the frame of every menu screen -------------------------------------------------------------------------------
STATUS = (0, 13)          # rows of the status bar (rule on row 13)
BOARD = (14, 227)         # rows of the wooden frame and the board
KEYS = (228, 239)         # rows of the key bar (rule on row 228)
FRAME = ['Wood 5', 'Wood 3', 'Wood 2', 'Wood 4']   # the frame rings, outside in (4 pixels)
INNER = (4, 18, 315, 223)  # the board inside the frame: x0, y0, x1, y1
HEAD = (18, 30)           # the title band rows (Board Head), the rule under it on row 31
CONTENT_Y = 33


def dust(x, y):
    """Is this board pixel a speck of chalk dust? (baked once; about 1 pixel in 70)"""
    return (x * 37 + y * 101 + (x * y) % 17) % 71 == 0


def status_bar(cv, st):
    cv.rect(0, 0, W, 13, C('Tunnel'))
    cv.rect(0, 13, W, 1, C('Tunnel Rule'))
    put(cv, SP.ALL[st.get('mini', 'mini_tower')], 3, 3)
    cv.text(st['club'], 14, 4, C('Chalk Yellow'))
    cv.text('WK %d' % st['week'], 94, 4, C('Chalk Blue'))
    cv.text('DIV %d' % st['div'], 128, 4, C('Chalk Blue'))
    cash = st['cash']
    put(cv, SP.ALL['money_coin' if cash >= 0 else 'money_owed'], 162, 3)
    cv.amount(cash, 172, 4, C('Chalk Green' if cash >= 0 else 'Chalk Red'))
    put(cv, SP.ALL['money_loan'], 228, 3)
    loan = st['loan']
    cv.amount(loan, 238, 4, C('Chalk'), sign=False)
    put(cv, SP.ALL['morale'], 288, 3)
    cv.text('%2d' % st['morale'], 298, 4, C('Chalk Blue'))


STATUS_ITEMS = [
    ('mini badge of your club (8 x 8)', 'sprite', '', 3, 3),
    ('your club name, up to 12 characters', '5 x 7, 1x', 'Chalk Yellow', 14, 4),
    ('WK n (week 1 to 15 and the cup weeks)', '5 x 7, 1x', 'Chalk Blue', 94, 4),
    ('DIV n', '5 x 7, 1x', 'Chalk Blue', 128, 4),
    ('money_coin, or money_owed when the cash is below 0', 'sprite', '', 162, 3),
    ('the cash: sign and digits, group gaps (section 5.2), ends by x 222', '5 x 7, 1x', 'Chalk Green or Chalk Red', 172, 4),
    ('money_loan', 'sprite', '', 228, 3),
    ('the loan: digits with group gaps, no sign, ends by x 284', '5 x 7, 1x', 'Chalk', 238, 4),
    ('morale icon', 'sprite', '', 288, 3),
    ('the morale, 2 digits, right aligned', '5 x 7, 1x', 'Chalk Blue', 298, 4),
]


def key_bar(cv, keys):
    cv.rect(0, 228, W, 12, C('Tunnel'))
    cv.rect(0, 228, W, 1, C('Tunnel Rule'))
    x = 6
    for k, what in keys:
        cv.text(k, x, 231, C('Chalk Yellow'))
        x += text_width(k) + 4
        cv.text(what, x, 231, C('Chalk Dim'))
        x += text_width(what) + 10


def board(cv, title, right=None):
    for i, n in enumerate(FRAME):
        cv.rect(i, 14 + i, W - 2 * i, 214 - 2 * i, C(n))
    x0, y0, x1, y1 = INNER
    cv.rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, C('Board'))
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if dust(x, y):
                cv.put(x, y, C('Board Dust'))
    cv.rect(x0, HEAD[0], x1 - x0 + 1, HEAD[1] - HEAD[0] + 1, C('Board Head'))
    cv.rect(x0, 31, x1 - x0 + 1, 1, C('Board Rule'))
    cv.text(title, 10, 21, C('Chalk Yellow'))
    if right:
        cv.text(right, 310 - text_width(right), 21, C('Chalk Dim'))


def plate(cv, x, y, w, h, rule='Chalk Yellow'):
    """A banner plate over anything: Outline ring, Tunnel fill, a rule top and bottom."""
    cv.rect(x - 1, y - 1, w + 2, h + 2, C('Outline'))
    cv.rect(x, y, w, h, C('Tunnel'))
    cv.rect(x + 2, y + 2, w - 4, 1, C(rule))
    cv.rect(x + 2, y + h - 3, w - 4, 1, C(rule))


def row_band(cv, y, h, name):
    cv.rect(INNER[0], y, INNER[2] - INNER[0] + 1, h, C(name))


# ---- bars -----------------------------------------------------------------------------------------------------------
def level(v):
    return 'fresh' if v >= 13 else ('weary' if v >= 7 else 'spent')


LEVEL_COL = {'fresh': ('Chalk Green', 'Fresh Dark'), 'weary': ('Chalk Amber', 'Weary Dark'), 'spent': ('Chalk Red', 'Spent Dark')}


def energy_bar(cv, x, y, v, unit=2, h=5, pulse=False):
    """Energy (1 to 20): a solid bar for fresh, dashed for weary, checked for spent; ticks under 6 and 12; a white end cap."""
    n = 20 * unit
    cv.rect(x, y, n, h, C('Bar Empty'))
    lv = level(v)
    a, b = LEVEL_COL[lv]
    fill = v * unit
    for i in range(fill):
        for j in range(h):
            c = a
            if lv == 'fresh' and j == h - 1:
                c = b
            if lv == 'weary' and i % 4 == 3:
                c = b
            if lv == 'spent' and (i + j) % 2 == 1:
                c = b
            if pulse and lv == 'spent':
                c = b
            cv.put(x + i, y + j, C(c))
    if fill > 0:
        for j in range(h):
            cv.put(x + fill - 1, y + j, C('Chalk'))
    for t in (6, 12):
        cv.put(x + t * unit - 1, y + h, C('Bar Tick'))


def morale_pips(cv, x, y, v):
    """Morale (1 to 20): 10 pips of 3 x 5, a pip is 2 points, an odd point lights the pip's first 2 columns."""
    lv = level(v)
    a, b = LEVEL_COL[lv]
    for p in range(10):
        px = x + p * 4
        lit = min(2, max(0, v - p * 2))
        for i in range(3):
            for j in range(5):
                on = lit == 2 or (lit == 1 and i < 2)
                cv.put(px + i, y + j, C(a if on else 'Bar Empty'))
        if lit:
            cv.put(px, y, C('Chalk') if lit == 2 else C(a))


def skill_pips(cv, x, y, v, big=False):
    s = 5 if big else 3
    for p in range(5):
        cv.rect(x + p * (s + 1), y, s, s, C('Chalk Yellow' if p < v else 'Bar Empty'))


def compare_bar(cv, x, y, mine, theirs, unit=3):
    """One of the five team numbers, you over them: Chalk Yellow 4 rows, Chalk Blue 4 rows, the numbers after them,
    and a + (ahead or level) or - (behind) after your number."""
    cv.rect(x, y, 20 * unit, 4, C('Bar Empty'))
    cv.rect(x, y, mine * unit, 4, C('Chalk Yellow'))
    cv.rect(x, y + 5, 20 * unit, 4, C('Bar Empty'))
    cv.rect(x, y + 5, theirs * unit, 4, C('Chalk Blue'))
    nx = x + 20 * unit + 4
    cv.small('%2d' % mine, nx, y, C('Chalk Yellow'))
    cv.small('%2d' % theirs, nx, y + 5, C('Chalk Blue'))
    if mine >= theirs:
        cv.small('+', nx + 9, y, C('Chalk Green'))
    else:
        cv.small('-', nx + 9, y, C('Chalk Red'))


# ---- the match ----------------------------------------------------------------------------------------------------------
# The pitch of the rules: 32 columns by 22 rows of cells, seen from the side in perspective. The picture is the view of
# the RIGHT goal (column - row = 9 is its goal line); the view of the left goal (column + row = 22) is the same picture
# mirrored (x becomes 319 - x), because cell (c, r) of the left view sits where cell (31 - c, r) sits in the right view.
PX, PY = 91, 36        # the top left pixel of cell (0, 0)
CW, RH = 8, 7          # a cell is 8 pixels wide and 7 tall
SHEAR = 3              # each row starts 3 pixels further left than the one above it
COLS, ROWS = 32, 22
GOAL_ROWS = (7, 13)    # the rows where a goal can be scored (the ball leaves at columns row + 10 to 24 at the right, 7 to 21 - row at the left)
SCORE = (0, 17)
TOP_STAND = (18, 33)
BOTTOM_STAND = (194, 205)
TICKER = (206, 227)


def cell_left(c, r):
    return PX + CW * c - SHEAR * r


def cell_xy(c, r, side='right'):
    """The feet of a figure on cell (c, r): the middle of the cell's bottom row. side 'left' is the mirrored view."""
    if side == 'left':
        x, y = cell_xy(31 - c, r)
        return 319 - x, y
    return cell_left(c, r) + 4, PY + RH * r + 6


def ball_xy(c, r, side='right'):
    """The ball's origin on cell (c, r): the middle of the cell."""
    if side == 'left':
        x, y = ball_xy(31 - c, r)
        return 319 - x, y
    return cell_left(c, r) + 4, PY + RH * r + 3


def line_x(y, k):
    """The x, on pixel row y, of the edge between cell columns (k - 1 + row) and (k + row): a line parallel to the goal line.
    k = 10 is the goal line itself (it lies after column 9 + row)."""
    t = y - PY
    return PX + CW * k + (CW - SHEAR) * t // RH


def ellipse_points(cx, cy, rx, ry):
    pts = set()
    import math
    for k in range(720):
        a = math.radians(k / 2)
        pts.add((int(round(cx + rx * math.cos(a))), int(round(cy + ry * math.sin(a)))))
    return pts


def stand(cv, y0, y1, frame=0, flip=False):
    """A strip of stand. Top: roof edge, 1 crowd tile, wall, hoardings. Bottom (flip): hoardings, crowd, wall."""
    cv.rect(0, y0, W, y1 - y0 + 1, C('Stand'))
    tile = SP.ALL['crowd_%d' % (frame + 1)]
    if not flip:
        cv.rect(0, y0, W, 2, C('Roof'))
        cv.rect(0, y0 + 2, W, 1, C('Roof Edge'))
        for x in range(0, W, 32):
            put(cv, tile, x, y0 + 3)
        cv.rect(0, y0 + 11, W, 1, C('Wall'))
        hoard(cv, y0 + 12)
    else:
        hoard(cv, y0)
        for x in range(0, W, 32):
            put(cv, tile, x, y0 + 4)
    return cv


def hoard(cv, y):
    """The advertising boards: 4 rows of Hoarding with blocks of lit lettering (no words, just the rhythm of them)."""
    cv.rect(0, y, W, 4, C('Hoarding'))
    x = 3
    k = 0
    while x < W:
        n = [10, 6, 14, 8, 12][k % 5]
        col = 'Hoarding Lit' if k % 3 else 'Hoarding Warm'
        cv.rect(x, y + 1, n, 2, C(col))
        x += n + 7
        k += 1


def floodlight(cv, x, y):
    """A floodlight lamp head 6 x 3 at (x, y), with its two glow rings."""
    for dx in range(-2, 8):
        for dy in range(-2, 5):
            if -1 <= dx <= 6 and -1 <= dy <= 3:
                cv.put(x + dx, y + dy, C('Flood Glow'))
            else:
                cv.put(x + dx, y + dy, C('Flood Haze'))
    cv.rect(x, y, 6, 3, C('Floodlight'))


Y_TOP, Y_BOTTOM = PY, PY + RH * ROWS - 1      # the touch lines: the top row of row 0 (y 36) and the bottom of row 21 (y 189)


def pitch(cv):
    """The right goal end of the pitch in perspective (the left goal view is this, mirrored)."""
    cv.rect(0, TOP_STAND[1] + 1, W, BOTTOM_STAND[0] - TOP_STAND[1] - 1, C('Run Off'))
    L = C('Line')
    for y in range(Y_TOP, Y_BOTTOM + 1):
        gx = line_x(y, 10)
        for x in range(0, gx):
            # mown stripes 16 pixels wide, parallel to the goal line, counted back from it
            k = (gx - 1 - x) // 16
            cv.put(x, y, C('Grass A' if k % 2 == 0 else 'Grass B'))
        cv.put(gx, y, L)                                   # the goal line
    for x in range(0, line_x(Y_TOP, 10) + 1):
        cv.put(x, Y_TOP, L)                                # the far touch line
    for x in range(0, line_x(Y_BOTTOM, 10) + 1):
        cv.put(x, Y_BOTTOM, L)                             # the near touch line
    # the penalty area (5 cells in front of the line, 4 rows either side of the goal) and the goal area (2 cells, 1 row either side)
    g0, g1 = GOAL_ROWS
    for k, r0, r1 in ((5, g0 - 4, g1 + 4), (8, g0 - 1, g1 + 1)):
        ya, yb = PY + RH * r0, PY + RH * (r1 + 1) - 1
        for y in range(ya, yb + 1):
            cv.put(line_x(y, k), y, L)
        for y in (ya, yb):
            for x in range(line_x(y, k), line_x(y, 10)):
                cv.put(x, y, L)
    # the penalty spot: 2 x 1, 3.5 cells out, level with the middle of the goal
    sy = PY + RH * (g0 + g1 + 1) // 2
    sx = (line_x(sy, 6) + line_x(sy, 7)) // 2
    cv.rect(sx, sy, 2, 1, L)
    goal(cv)


def goal_points():
    """The goal's foot points on the goal line: the far post at the top of the first goal row, the near post at the bottom of the last."""
    ya, yb = PY + RH * GOAL_ROWS[0], PY + RH * (GOAL_ROWS[1] + 1) - 1
    return (line_x(ya, 10), ya), (line_x(yb, 10), yb)


GOAL_H = 14      # post height in pixels
GOAL_D = 10      # depth of the net behind the line, in pixels to the right


def goal(cv):
    (xa, ya), (xb, yb) = goal_points()
    n = yb - ya
    # the net: between the goal line and the back line (GOAL_D to the right), from the ground up to the bar
    for i in range(n + 1):
        y = ya + i
        x0 = xa + (xb - xa) * i // n
        for dy in range(0, GOAL_H + 1):
            for dx in range(1, GOAL_D + 1):
                px, py = x0 + dx, y - dy
                col = 'Net' if (px + py) % 3 == 0 else 'Net Dark'
                cv.put(px, py, C(col))
    # back posts and the back of the roof of the net
    for (x, y) in ((xa, ya), (xb, yb)):
        cv.rect(x + GOAL_D, y - GOAL_H, 1, GOAL_H + 1, C('Net'))
        for dx in range(GOAL_D + 1):
            cv.put(x + dx, y - GOAL_H, C('Net'))
    # the front frame: two posts 2 pixels wide and the crossbar along the line, GOAL_H up
    for i in range(n + 1):
        cv.put(xa + (xb - xa) * i // n, ya + i - GOAL_H, C('Post'))
        cv.put(xa + (xb - xa) * i // n + 1, ya + i - GOAL_H, C('Silver 3'))
    for (x, y) in ((xa, ya), (xb, yb)):
        cv.rect(x, y - GOAL_H, 1, GOAL_H + 1, C('Post'))
        cv.rect(x + 1, y - GOAL_H, 1, GOAL_H + 1, C('Silver 3'))


def match_background(cv, frame=0, side='right'):
    cv.rect(0, 0, W, H, C('Night'))
    stand(cv, TOP_STAND[0], TOP_STAND[1], frame)
    pitch(cv)
    stand(cv, BOTTOM_STAND[0], BOTTOM_STAND[1], frame, flip=True)
    for x in (6, 308):
        floodlight(cv, x - 3, 19)
    if side == 'left':
        mirror_x(cv, 34, 193)
    return cv


def mirror_x(cv, y0, y1):
    for y in range(y0, y1 + 1):
        cv.px[y] = cv.px[y][::-1]


# ---- the goal mouth (96 x 64, face on from the penalty spot) -----------------------------------------------------------
GM_W, GM_H = 96, 64
GM_POSTS = (10, 83)        # the posts are 3 pixels wide: x 10 to 12 and 83 to 85; the net between is x 13 to 82
GM_BAR_Y = 15              # the crossbar, rows 15 to 17
GM_LINE_Y = 47             # the goal line row
# the nine targets: column x (left, middle, right) and row y (high, middle, low), the ball's centre
GM_TX = (24, 48, 72)
GM_TY = (22, 32, 42)
# outside the frame: wide left, wide right, over the bar
GM_WIDE = {'wide_left': (4, 38), 'wide_right': (91, 38), 'over': (48, 9), 'post_left': (13, 30), 'post_right': (83, 30)}
KEEPER_FEET = (48, 54)


def goal_mouth_rows():
    """The goal mouth picture as rows of letters (the legend is GM_LEGEND)."""
    g = [['.'] * GM_W for _ in range(GM_H)]
    tile = SP.ALL['crowd_1'].rows
    for y in range(GM_H):
        for x in range(GM_W):
            if y < 8:
                ch = tile[y][x % 32]
                g[y][x] = {'K': 'k', 'F': 'f', 'D': 'd'}.get(ch, 'c' if ch in 'RCBGP' else 'k')
            elif y < 10:
                g[y][x] = 'w'
            elif y < 14:
                g[y][x] = 'h' if not (2 <= y - 10 <= 2 and (x // 9) % 2 == 0 and x % 9 < 6) else 'l'
            elif y < GM_LINE_Y:
                g[y][x] = 's'
            else:
                band = [(47, 49, 'a'), (50, 53, 'b'), (54, 58, 'a'), (59, 63, 'b')]
                for a, b, ch in band:
                    if a <= y <= b:
                        g[y][x] = ch
    # the net inside the frame: back panel mesh (a diamond lattice every 4 pixels), darker at the bottom
    for y in range(GM_BAR_Y + 3, GM_LINE_Y):
        for x in range(13, 83):
            g[y][x] = 'n'
            if (x + y) % 4 == 0 or (x - y) % 4 == 0:
                g[y][x] = 'm'
    # the side nets: a lighter strip 2 pixels inside each post, mesh every 2 rows
    for y in range(GM_BAR_Y + 3, GM_LINE_Y):
        for x in (13, 14, 81, 82):
            g[y][x] = 't' if y % 2 == 0 else 'n'
    # the frame: posts 3 wide, crossbar 3 tall, white with a grey right and bottom side
    for y in range(GM_BAR_Y, GM_LINE_Y + 1):
        for x in (10, 11, 12, 83, 84, 85):
            g[y][x] = 'P' if x in (10, 11, 83, 84) else 'Q'
    for y in range(GM_BAR_Y, GM_BAR_Y + 3):
        for x in range(10, 86):
            g[y][x] = 'P' if y < GM_BAR_Y + 2 else 'Q'
    # the goal line and the six yard box: a line across, a line 8 rows nearer, slanting sides
    for x in range(GM_W):
        g[GM_LINE_Y][x] = 'e' if not (10 <= x <= 85 and g[GM_LINE_Y][x] in 'PQ') else g[GM_LINE_Y][x]
        g[56][x] = 'e'
    for k in range(9):
        y = GM_LINE_Y + k
        for x in (2 - k // 2 * 1 - 0, 93 + k // 2):
            if 0 <= x < GM_W:
                g[y][x] = 'e'
    # the frame's shadow on the grass, 1 row under the line inside the posts
    for x in range(13, 83):
        if g[GM_LINE_Y + 1][x] in 'ab':
            g[GM_LINE_Y + 1][x] = 'g'
    return [''.join(r) for r in g]


GM_LEGEND = {
    'k': 'Crowd Shadow', 'f': 'Crowd Face', 'd': 'Crowd Face Dark', 'c': 'Crowd Red', 'w': 'Wall', 'h': 'Hoarding',
    'l': 'Hoarding Lit', 's': 'Stand', 'n': 'Night Haze', 't': 'Net', 'm': 'Net Dark', 'P': 'Post', 'Q': 'Silver 3',
    'e': 'Line', 'a': 'Grass A', 'b': 'Grass B', 'g': 'Ball Shadow',
}


def goal_mouth(cv, x, y, frame=0):
    rows = goal_mouth_rows()
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            cv.put(x + i, y + j, C(GM_LEGEND[ch]))
    if frame:
        cheer = SP.ALL['crowd_2']
        for j in range(8):
            for i in range(GM_W):
                ch = cheer.rows[j][i % 32]
                cv.put(x + i, y + j, C(cheer.legend[ch]))
