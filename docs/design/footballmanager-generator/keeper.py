"""The goal mouth keeper (front view, the close up): built with the rasteriser, written into the design as grids.

Letters: 1 to 5 the Keeper row, S shorts, T shorts shade, A skin, B skin shade, H hair, K eye, C glove, O boot,
E the outline (Outline)."""
from raster import Grid, rot

STAND = dict(head=(0, -26), neck=(0, -22), sh_l=(-5.5, -20.5), sh_r=(5.5, -20.5), waist_l=(-3.5, -12), waist_r=(3.5, -12),
             el_l=(-9, -16), el_r=(9, -16), ha_l=(-10, -11), ha_r=(10, -11),
             hip_l=(-2.5, -9), hip_r=(2.5, -9), kn_l=(-5, -4.5), kn_r=(5, -4.5), ft_l=(-5.5, -1), ft_r=(5.5, -1))
STRETCH = dict(head=(0, -24), neck=(0, -20), sh_l=(-4.5, -18.5), sh_r=(4.5, -18.5), waist_l=(-3, -10), waist_r=(3, -10),
               el_l=(-4.5, -24), el_r=(4.5, -24), ha_l=(-4, -29), ha_r=(4, -29),
               hip_l=(-2, -7), hip_r=(2, -7), kn_l=(-2.5, -2), kn_r=(3, -2.5), ft_l=(-2.5, 3), ft_r=(4, 2))
HOLD = dict(STAND, el_l=(-6.5, -14), el_r=(6.5, -14), ha_l=(-2.5, -16), ha_r=(2.5, -16))


def draw(j, w, h, ox, oy, ball=None):
    g = Grid(w, h)

    def P(k):
        return (j[k][0] + ox, j[k][1] + oy)
    # legs (socks), then knees of skin, shorts over the top of the thighs
    for s in 'lr':
        g.capsule(P('hip_' + s), P('kn_' + s), 1.3, '3')
        g.capsule(P('kn_' + s), P('ft_' + s), 1.1, '3')
        g.disc(*P('kn_' + s), 0.9, 'A')
    # torso
    g.poly([P('sh_l'), P('sh_r'), P('waist_r'), P('waist_l')], '3')
    g.poly([P('waist_l'), P('waist_r'), ((P('hip_r')[0] + P('waist_r')[0]) / 2 + 1.2, P('hip_r')[1] + 1.5),
            ((P('hip_l')[0] + P('waist_l')[0]) / 2 - 1.2, P('hip_l')[1] + 1.5)], 'S')
    # arms (long sleeves) and gloves
    for s in 'lr':
        g.capsule(P('sh_' + s), P('el_' + s), 1.4, '3')
        g.capsule(P('el_' + s), P('ha_' + s), 1.2, '3')
    g.shade()
    for s in 'lr':
        g.disc(*P('ha_' + s), 1.6, 'C')
        fx, fy = P('ft_' + s)
        g.capsule((fx - 1, fy), (fx + 1, fy), 0.8, 'O')
    # shorts shade: the lower row and the right side
    src = [r[:] for r in g.g]
    for y in range(h):
        for x in range(w):
            if src[y][x] == 'S' and (y + 1 >= h or src[y + 1][x] != 'S' or x + 1 >= w or src[y][x + 1] != 'S'):
                g.g[y][x] = 'T'
    # head
    hx, hy = P('head')
    nx, ny = P('neck')
    g.capsule((hx, hy), (nx, ny), 1.0, 'B')
    g.disc(hx, hy, 3.1, 'A')
    g.disc(hx, hy - 1.6, 2.6, 'H')
    g.disc(hx, hy + 0.6, 2.4, 'A')
    # eyes on the line through the head's middle, across the body axis
    ax, ay = nx - hx, ny - hy
    ln = (ax * ax + ay * ay) ** 0.5
    ux, uy = -ay / ln, ax / ln
    for k in (-1.2, 1.2):
        g.set(hx + ux * k + ax / ln * 0.3, hy + uy * k + ay / ln * 0.3, 'K')
    if ball:
        bx, by = ball
        g.disc(bx + ox, by + oy, 2.6, 'W')
        g.disc(bx + ox + 0.6, by + oy + 0.6, 1.2, 'X')
        for s in 'lr':
            g.disc(*P('ha_' + s), 1.5, 'C')
    g.outline('E')
    return g.rows()


def pose(base, deg, pivot=(0, -12), lift=(0, 0)):
    return {k: (lambda p: (p[0] + lift[0], p[1] + lift[1]))(rot(v, pivot, deg)) for k, v in base.items()}


def build():
    out = {}
    out['gm_keeper_ready'] = (draw(STAND, 24, 32, 12, 31), (12, 31))
    out['gm_keeper_hold'] = (draw(HOLD, 24, 32, 12, 31, ball=(0, -16)), (12, 31))
    out['gm_keeper_jump'] = (draw(STRETCH, 24, 32, 12, 31 - 0), (12, 31))
    # dives to the right (the game mirrors for left): low, almost flat; high, on a slant and lifted
    for name, deg in (('gm_keeper_dive_right', 74), ('gm_keeper_high_right', 42)):
        rows = draw(pose(STRETCH, deg), 48, 48, 24, 24)
        xs = [x for r in rows for x, ch in enumerate(r) if ch != '.']
        ys = [y for y, r in enumerate(rows) if r.strip('.')]
        x0, y0 = min(xs), min(ys)
        rows = [r[x0:max(xs) + 1] for r in rows[y0:max(ys) + 1]]
        # origin: the middle of the waist (the pivot), so the dive table can place it
        out[name] = (rows, (24 - x0, 12 - y0))
    return out


KEEPER = build()


def glove_offset(name):
    """Where the middle of the two gloves is, from the sprite's origin (dx, dy), for the dive table."""
    if name == 'gm_keeper_jump':
        j = STRETCH
        return ((j['ha_l'][0] + j['ha_r'][0]) / 2, (j['ha_l'][1] + j['ha_r'][1]) / 2)
    deg = 74 if name == 'gm_keeper_dive_right' else 42
    j = pose(STRETCH, deg)
    return ((j['ha_l'][0] + j['ha_r'][0]) / 2, (j['ha_l'][1] + j['ha_r'][1]) / 2 + 12)
