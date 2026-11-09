"""Sample game state for the previews. The names are placeholders in the format of the game's data (a club at most
10 characters, a player at most 9, as INITIAL.SURNAME); the game draws whatever names its data holds."""

CLUB = 'MUDBURY'
CLUBS = [  # one division in slot order: name, slot (1 to 16); the badge is BADGES[(slot - 1) mod 8]
    'GRUBSWORTH', 'WOBBLEFORD', 'MUDBURY', 'PIEMOUTH', 'TOFFEETON', 'DRIZZLEBY', 'SNOOZEHAM', 'MIZZLE C.',
    'SLOWCOMBE', 'BRAMBLE U.', 'KETTLEWHIP', 'PUDDLEMOOR', 'CRUMBLETON', 'BOGWATER', 'NETTLE R.', 'HOPSWICH',
]
BADGE_NAMES = ['star', 'hoops', 'tower', 'anchor', 'tree', 'chevron', 'fish', 'kettle']


def badge_of(name, size='mini'):
    slot = CLUBS.index(name) + 1
    return '%s_%s' % (size, BADGE_NAMES[(slot - 1) % 8])


TABLE = [  # P W D L F A, in slot order
    (9, 7, 1, 1, 21, 8), (9, 6, 2, 1, 17, 9), (9, 6, 1, 2, 19, 11), (9, 5, 2, 2, 14, 10), (9, 4, 3, 2, 15, 12),
    (9, 4, 2, 3, 13, 12), (9, 4, 1, 4, 12, 13), (9, 3, 3, 3, 11, 11), (9, 3, 2, 4, 10, 12), (9, 3, 1, 5, 9, 14),
    (9, 2, 4, 3, 10, 13), (9, 2, 3, 4, 8, 12), (9, 2, 2, 5, 9, 15), (9, 2, 1, 6, 7, 16), (9, 1, 3, 5, 6, 15), (9, 1, 1, 7, 5, 19),
]

SQUAD = [  # name, position, skill, energy, state, value, mark (start, res, None)
    ('K.PUDDLE', 'df', 3, 17, 'fit', 30000, 'start'),
    ('N.BRISKET', 'df', 4, 12, 'fit', 40000, 'start'),
    ('O.DOLLOP', 'df', 2, 19, 'form', 20000, 'start'),
    ('W.GUBBINS', 'df', 3, 5, 'tired', 30000, 'start'),
    ('R.DUBBIN', 'df', 5, 14, 'fit', 50000, 'start'),
    ('F.WIMBLE', 'mf', 3, 9, 'fit', 30000, 'start'),
    ('L.CRUMPET', 'mf', 4, 18, 'form', 40000, 'start'),
    ('D.FIDGETT', 'mf', 1, 20, 'form', 10000, None),
    ('H.MUDGE', 'mf', 2, 11, 'injured', 20000, None),
    ('G.TWIDDLE', 'mf', 5, 7, 'fit', 50000, 'start'),
    ('M.SPRIGG', 'fw', 4, 13, 'fit', 40000, 'start'),
    ('A.KIPPER', 'fw', 3, 3, 'tired', 30000, 'start'),
    ('T.BRAMBLE', 'fw', 2, 16, 'form', 20000, None),
    ('J.BOBBINS', 'fw', 1, 20, 'form', 10000, 'res'),
]
STATUS = dict(club=CLUB, mini='mini_tower', week=10, div=3, cash=-18450, loan=212300, limit=500000, morale=14)
TITLE = 'GAME NAME'   # placeholder: the game's name comes from a text constant (section 6.5)
