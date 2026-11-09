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
    loan_col = 'Chalk Red' if loan > st['limit'] * 8 // 10 else 'Chalk'
    s = str(loan)
    # the loan has no sign: draw the digits with the group gaps (amount() without its sign)
    cv.amount(loan, 238, 4, C(loan_col), sign=False)
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
    ('the loan: digits with group gaps, no sign, ends by x 284', '5 x 7, 1x', 'Chalk, or Chalk Red above 80% of the limit', 238, 4),
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


# ---- the match --------------------------------------------------------------------------------------------------------
PITCH_X, PITCH_Y = 32, 34      # the top left of cell (0, 0)
CELL = 8
COLS, ROWS = 32, 20
GOAL_ROWS = (8, 11)            # the goal mouth: cell rows 8 to 11 at both ends (32 pixels)
SCORE = (0, 17)
TOP_STAND = (18, 33)
BOTTOM_STAND = (194, 205)
TICKER = (206, 227)


def cell_xy(c, r):
    """The pixel at the middle of the bottom of a cell: the feet of a figure standing on it."""
    return PITCH_X + c * CELL + 4, PITCH_Y + r * CELL + 7


def ball_xy(c, r):
    """The middle of a cell: the ball's origin when it is on that cell."""
    return PITCH_X + c * CELL + 4, PITCH_Y + r * CELL + 4


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


def pitch(cv):
    """The pitch, from above. Run off round it, mown stripes 16 pixels wide, the lines, the goals."""
    x0, y0 = PITCH_X, PITCH_Y
    pw, ph = COLS * CELL, ROWS * CELL
    cv.rect(0, TOP_STAND[1] + 1, W, BOTTOM_STAND[0] - TOP_STAND[1] - 1, C('Run Off'))
    for s in range(COLS // 2):
        cv.rect(x0 + s * 16, y0, 16, ph, C('Grass A' if s % 2 == 0 else 'Grass B'))
    L = C('Line')
    # touch lines and goal lines on the outermost pixels of the cells
    cv.rect(x0, y0, pw, 1, L)
    cv.rect(x0, y0 + ph - 1, pw, 1, L)
    cv.rect(x0, y0, 1, ph, L)
    cv.rect(x0 + pw - 1, y0, 1, ph, L)
    # halfway line: two pixels, the edge between cell 15 and 16
    cv.rect(x0 + 16 * CELL - 1, y0, 2, ph, L)
    cx, cy = x0 + 16 * CELL - 1, y0 + 10 * CELL - 1
    for (px, py) in ellipse_points(cx + 0.5, cy + 0.5, 22, 22):
        cv.put(px, py, L)
    cv.rect(cx, cy, 2, 2, L)
    # penalty areas: 5 cells deep, rows 4 to 15; goal areas 2 cells deep, rows 7 to 12; spots 3.5 cells out
    for side in (0, 1):
        def bx(c):
            return x0 + c * CELL if side == 0 else x0 + pw - c * CELL - 1
        for (d, r0, r1) in ((5, 4, 16), (2, 7, 13)):
            yA, yB = y0 + r0 * CELL, y0 + r1 * CELL - 1
            xa, xb = sorted((bx(0), bx(d)))
            cv.rect(xa, yA, xb - xa + 1, 1, L)
            cv.rect(xa, yB, xb - xa + 1, 1, L)
            cv.rect(bx(d), yA, 1, yB - yA + 1, L)
        sx = bx(4) - (1 if side == 0 else -1) * 4
        cv.rect(sx, cy, 2, 2, L)
        # the arc at the edge of the box: points of a circle radius 18 round the spot, outside the box
        for (px, py) in ellipse_points(sx + 0.5, cy + 0.5, 18, 18):
            if (side == 0 and px > bx(5)) or (side == 1 and px < bx(5)):
                cv.put(px, py, L)
        # the goal, from above: 8 pixels deep outside the line, rows 8 to 11 of the cells
        gy0, gy1 = y0 + GOAL_ROWS[0] * CELL, y0 + (GOAL_ROWS[1] + 1) * CELL - 1
        gx = x0 - 8 if side == 0 else x0 + pw
        cv.rect(gx, gy0, 8, gy1 - gy0 + 1, C('Net Dark'))
        for yy in range(gy0, gy1 + 1):
            for xx in range(gx, gx + 8):
                if (xx + yy) % 3 == 0:
                    cv.put(xx, yy, C('Net'))
        post = gx + 7 if side == 0 else gx
        cv.rect(post, gy0 - 1, 1, gy1 - gy0 + 3, C('Post'))
        back = gx if side == 0 else gx + 7
        cv.rect(back, gy0, 1, gy1 - gy0 + 1, C('Net'))
        cv.rect(gx, gy0 - 1, 8, 1, C('Post'))
        cv.rect(gx, gy1 + 1, 8, 1, C('Post'))
    # corner flags: a 1 x 3 post and a 2 pixel flag
    for (fx, fy, d) in ((x0, y0, 1), (x0 + pw - 1, y0, -1), (x0, y0 + ph - 1, 1), (x0 + pw - 1, y0 + ph - 1, -1)):
        cv.rect(fx, fy - 3, 1, 3, C('Post'))
        cv.put(fx + d, fy - 3, C('Chalk Yellow'))
        cv.put(fx + d, fy - 2, C('Chalk Yellow'))


def match_background(cv, frame=0):
    cv.rect(0, 0, W, H, C('Night'))
    stand(cv, TOP_STAND[0], TOP_STAND[1], frame)
    pitch(cv)
    stand(cv, BOTTOM_STAND[0], BOTTOM_STAND[1], frame, flip=True)
    # floodlights over the corners of the top stand
    for x in (6, 308):
        floodlight(cv, x - 3, 19)
    return cv


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
            g[y][x] = 'N' if y % 2 == 0 else 'n'
    # the frame: posts 3 wide, crossbar 3 tall, white with a grey right and bottom side
    for y in range(GM_BAR_Y, GM_LINE_Y + 1):
        for x in (10, 11, 12, 83, 84, 85):
            g[y][x] = 'P' if x in (10, 11, 83, 84) else 'Q'
    for y in range(GM_BAR_Y, GM_BAR_Y + 3):
        for x in range(10, 86):
            g[y][x] = 'P' if y < GM_BAR_Y + 2 else 'Q'
    # the goal line and the six yard box: a line across, a line 8 rows nearer, slanting sides
    for x in range(GM_W):
        g[GM_LINE_Y][x] = 'L' if not (10 <= x <= 85 and g[GM_LINE_Y][x] in 'PQ') else g[GM_LINE_Y][x]
        g[56][x] = 'L'
    for k in range(9):
        y = GM_LINE_Y + k
        for x in (2 - k // 2 * 1 - 0, 93 + k // 2):
            if 0 <= x < GM_W:
                g[y][x] = 'L'
    # the frame's shadow on the grass, 1 row under the line inside the posts
    for x in range(13, 83):
        if g[GM_LINE_Y + 1][x] in 'ab':
            g[GM_LINE_Y + 1][x] = 'g'
    return [''.join(r) for r in g]


GM_LEGEND = {
    'k': 'Crowd Shadow', 'f': 'Crowd Face', 'd': 'Crowd Face Dark', 'c': 'Crowd Red', 'w': 'Wall', 'h': 'Hoarding',
    'l': 'Hoarding Lit', 's': 'Stand', 'n': 'Night Haze', 'N': 'Net', 'm': 'Net Dark', 'P': 'Post', 'Q': 'Silver 3',
    'L': 'Line', 'a': 'Grass A', 'b': 'Grass B', 'g': 'Ball Shadow',
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
