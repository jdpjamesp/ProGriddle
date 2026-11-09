"""Sample game state for the previews. All names are invented for this design and are not the game's data lists."""

CLUB = 'MUDBURY TOWN'
CLUBS = [  # division 3 for the table preview: name, mini badge, P W D L F A points
    ('GRUBSWORTH', 'mini_star'), ('WOBBLEFORD', 'mini_hoops'), ('MUDBURY TOWN', 'mini_tower'), ('PIEMOUTH', 'mini_anchor'),
    ('TOFFEETON', 'mini_tree'), ('DRIZZLEBY', 'mini_chevron'), ('SNOOZEHAM', 'mini_fish'), ('MIZZLE CITY', 'mini_kettle'),
    ('SLOWCOMBE', 'mini_star'), ('BRAMBLE UTD', 'mini_hoops'), ('KETTLEWHIP', 'mini_kettle'), ('PUDDLEMOOR', 'mini_anchor'),
    ('CRUMBLETON', 'mini_tree'), ('BOGWATER', 'mini_fish'), ('NETTLE ROV', 'mini_chevron'), ('HOPSWICH', 'mini_tower'),
]
TABLE = [  # P W D L F A
    (9, 7, 1, 1, 21, 8), (9, 6, 2, 1, 17, 9), (9, 6, 1, 2, 19, 11), (9, 5, 2, 2, 14, 10), (9, 4, 3, 2, 15, 12),
    (9, 4, 2, 3, 13, 12), (9, 4, 1, 4, 12, 13), (9, 3, 3, 3, 11, 11), (9, 3, 2, 4, 10, 12), (9, 3, 1, 5, 9, 14),
    (9, 2, 4, 3, 10, 13), (9, 2, 3, 4, 8, 12), (9, 2, 2, 5, 9, 15), (9, 2, 1, 6, 7, 16), (9, 1, 3, 5, 6, 15), (9, 1, 1, 7, 5, 19),
]

SQUAD = [  # name, position, skill, energy, state, value, mark (start, res, None)
    ('K. PUDDLE', 'gk', 3, 17, 'fit', 30000, 'start'),
    ('N. BRISKET', 'df', 4, 12, 'fit', 40000, 'start'),
    ('O. DOLLOP', 'df', 2, 19, 'form', 20000, 'start'),
    ('W. GUBBINS', 'df', 3, 5, 'tired', 30000, 'start'),
    ('R. DUBBIN', 'df', 5, 14, 'fit', 50000, 'start'),
    ('F. WIMBLE', 'mf', 3, 9, 'fit', 30000, 'start'),
    ('L. CRUMPET', 'mf', 4, 18, 'form', 40000, 'start'),
    ('D. FIDGETT', 'mf', 1, 20, 'form', 10000, None),
    ('H. MUDGE', 'mf', 2, 11, 'injured', 20000, None),
    ('G. TWIDDLE', 'mf', 5, 7, 'fit', 50000, 'start'),
    ('M. SPROCKET', 'fw', 4, 13, 'fit', 40000, 'start'),
    ('A. KIPPER', 'fw', 3, 3, 'tired', 30000, 'start'),
    ('T. BRAMBLE', 'fw', 2, 16, 'form', 20000, 'start'),
    ('J. BOBBINS', 'fw', 1, 20, 'form', 10000, 'res'),
]
POOL = [  # 24 invented players for the set up grid: 8 defenders, 8 midfielders, 8 forwards
    'N. BRISKET', 'O. DOLLOP', 'W. GUBBINS', 'R. DUBBIN', 'P. NOGGIN', 'E. PLUMB', 'S. WAFFLE', 'B. CRANNY',
    'F. WIMBLE', 'L. CRUMPET', 'D. FIDGETT', 'H. MUDGE', 'G. TWIDDLE', 'C. HUMBUG', 'V. SCONE', 'Y. TATTER',
    'M. SPROCKET', 'A. KIPPER', 'T. BRAMBLE', 'J. BOBBINS', 'U. PARSNIP', 'I. WHISK', 'Z. DOODLE', 'Q. NIBBS',
]
STATUS = dict(club=CLUB, mini='mini_tower', week=10, div=3, cash=-18450, loan=212300, limit=500000, morale=14)
