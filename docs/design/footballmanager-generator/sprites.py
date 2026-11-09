"""Every sprite of the design, by name, built from the part files."""
from lib import Sprite, grid
import figures as F

ALL = {}

KIT_LEGEND = {
    'home': {'S': 'Home Shorts', 'T': 'Home Shorts Dark', 'C': 'Skin 1', 'P': 'Home Stripe'},
    'away': {'S': 'Away Shorts', 'T': 'Away Shorts Dark', 'C': 'Skin 1', 'P': 'Away Hoop'},
    'keeper': {'S': 'Keeper Shorts', 'T': 'Keeper Shorts Dark', 'C': 'Glove', 'P': 'Keeper 3'},
    'referee': {'S': 'Referee 4', 'T': 'Referee 5', 'C': 'Skin 1', 'P': 'Ref Collar'},
}
KIT_ROW = {'home': 'Home', 'away': 'Away', 'keeper': 'Keeper', 'referee': 'Referee'}
FIXED = {'A': 'Skin 1', 'B': 'Skin 1 Shade', 'H': 'Hair Dark', 'O': 'Boot', 'W': 'Ball 3'}
SKINS = [('Skin 1', 'Skin 1 Shade'), ('Skin 2', 'Skin 2 Shade'), ('Skin 3', 'Skin 3 Shade')]
HAIRS = ['Hair Dark', 'Hair Black', 'Hair Fair', 'Hair Ginger']


def shirt_rows(rows):
    """The rows of the torso: from the first row holding a 1 or 2 to the last row holding a 3 or 4 above the shorts."""
    top = next(j for j, r in enumerate(rows) if '1' in r)
    bottom = next(j for j, r in enumerate(rows) if 'S' in r) - 1
    return top, bottom


def pattern(rows, kit):
    """The kit pattern, applied before mirroring: home stripes on the torso columns 3 and 5, the away hoop on the torso's
    middle row, the referee's collar on the torso's top row. Only tone pixels 2, 3, 4 of the torso change."""
    if kit in ('keeper',):
        return rows
    top, bottom = shirt_rows(rows)
    out = [list(r) for r in rows]
    for j in range(top, bottom + 1):
        for i, ch in enumerate(out[j]):
            if ch not in '1234':
                continue
            if kit == 'home' and i in (3, 5) and j > top:
                out[j][i] = 'P'
            if kit == 'away' and j == top + 2:
                out[j][i] = 'P'
            if kit == 'referee' and j == top:
                out[j][i] = 'P'
    return [''.join(r) for r in out]


def fig_sprite(name, kit, rows=None):
    rows = rows or grid(F.FIG[name])
    rows = pattern(rows, kit)
    legend = dict(FIXED)
    legend.update(KIT_LEGEND[kit])
    for k in '12345':
        legend[k] = '%s %s' % (KIT_ROW[kit], k)
    leg = {k: v for k, v in legend.items() if any(k in r for r in rows)}
    s = Sprite(name, rows, leg, group='fig', origin=F.FIG_ORIGIN[name])
    s.row = KIT_ROW[kit]
    s.kit = kit
    return s


FIGS = {}
for kit in ('home', 'away', 'keeper', 'referee'):
    for n in F.FIG:
        if n.startswith('gk_') and kit != 'keeper':
            continue
        FIGS[(n, kit)] = fig_sprite(n, kit)

for n in F.FIG:
    kit = 'keeper' if n.startswith('gk_') else 'home'
    s = FIGS[(n, kit)]
    ALL[n] = s

for n, g in F.BALL.items():
    leg = {'S': 'Ball Shadow'} if n == 'ball_shadow' else {k: 'Ball %s' % k for k in '12345'}
    s = Sprite(n, grid(g), leg, group='ball', origin=(2, 2))
    s.row = None if n == 'ball_shadow' else 'Ball'
    ALL[n] = s

# ---- the referee (the figure shapes in the Referee kit) ------------------------------------------------------------
for n in ('fig_stand', 'fig_run_1', 'fig_run_3'):
    s = FIGS[(n, 'referee')]
    ref_name = {'fig_stand': 'ref_stand', 'fig_run_1': 'ref_run_1', 'fig_run_3': 'ref_run_2'}[n]
    r = Sprite(ref_name, s.rows, s.legend, group='fig', origin=s.origin)
    r.row = 'Referee'
    ALL[ref_name] = r

# ---- the close up keeper, ball and ripple --------------------------------------------------------------------------
import keeper as K
import items as I

GK_LEGEND = {'S': 'Keeper Shorts', 'T': 'Keeper Shorts Dark', 'A': 'Skin 2', 'B': 'Skin 2 Shade', 'H': 'Hair Black',
             'K': 'Eye', 'C': 'Glove', 'O': 'Boot', 'E': 'Outline', 'W': 'Ball 3', 'X': 'Ball 4'}
for k in '12345':
    GK_LEGEND[k] = 'Keeper %s' % k
for n, (rows, origin) in K.KEEPER.items():
    leg = {k: v for k, v in GK_LEGEND.items() if any(k in r for r in rows)}
    s = Sprite(n, rows, leg, group='gm_keeper', origin=origin)
    s.row = 'Keeper'
    ALL[n] = s
for n, g in I.GM_BALL.items():
    rows = g.split(',')
    s = Sprite(n, rows, {k: 'Ball %s' % k for k in '12345' if any(k in r for r in rows)}, group='gm_ball',
               origin=(len(rows[0]) // 2, len(rows) // 2))
    s.row = 'Ball'
    ALL[n] = s
for k in (1, 2, 3):
    rows = I.ripple(k)
    leg = {c: v for c, v in (('L', 'Spark'), ('N', 'Net')) if any(c in r for r in rows)}
    s = Sprite('gm_ripple_%d' % k, rows, leg, group='ripple', origin=(12, 8))
    s.row = None
    ALL[s.name] = s

# ---- badges -------------------------------------------------------------------------------------------------------
BADGE_NOTE = {}
for b in I.BADGES:
    rows, leg = I.badge(*b[:7])
    s = Sprite(b[0], rows, leg, group='badge', origin=(0, 0))
    s.row = None
    s.note = b[7]
    ALL[b[0]] = s
for b in I.BADGES:
    rows = I.mini(ALL[b[0]].rows)
    leg = {k: v for k, v in ALL[b[0]].legend.items() if any(k in r for r in rows)}
    s = Sprite(b[0].replace('badge_', 'mini_'), rows, leg, group='icon', origin=(0, 0))
    s.row = None
    s.note = 'the 8 x 8 ' + b[0] + ' for the status bar and the tables'
    ALL[s.name] = s

# ---- faces --------------------------------------------------------------------------------------------------------
for f in I.FACES:
    rows, leg = I.face(*f[1:6])
    s = Sprite(f[0], rows, leg, group='face', origin=(0, 0))
    s.row = 'Home'
    s.note = f[6]
    ALL[f[0]] = s

# ---- icons --------------------------------------------------------------------------------------------------------
for n, (shape, leg, note) in I.ICONS.items():
    rows, lg = I.icon(shape.replace(',', '\n'), leg, I.ICON_OUTLINE.get(n, True))
    s = Sprite(n, rows, lg, group='icon', origin=(0, 0))
    s.row = None
    s.note = note
    ALL[n] = s

# ---- trophies -----------------------------------------------------------------------------------------------------
for n, w, h, metal, big, note in (('trophy_league', 32, 32, 'Gold', True, 'the league trophy: a gold cup on a wooden plinth'),
                                  ('trophy_cup', 32, 32, 'Silver', True, 'the cup: the same shape in silver'),
                                  ('cab_league', 12, 16, 'Gold', False, 'the league trophy in the cabinet'),
                                  ('cab_cup', 12, 16, 'Silver', False, 'the cup in the cabinet')):
    rows, leg = I.trophy(w, h, metal, big)
    s = Sprite(n, rows, leg, group='trophy', origin=(w // 2, h - 1))
    s.row = metal
    s.note = note
    ALL[n] = s

# ---- crowd --------------------------------------------------------------------------------------------------------
for k in (0, 1):
    rows = I.crowd(k)
    leg = {c: v for c, v in I.CROWD_NAMES.items() if any(c in r for r in rows)}
    s = Sprite('crowd_%d' % (k + 1), rows, leg, group='crowd', origin=(0, 0))
    s.row = None
    s.note = 'a 32 x 8 tile of fans, repeated along a stand' + (', cheering (heads up, arms up)' if k else ', sitting')
    ALL[s.name] = s
