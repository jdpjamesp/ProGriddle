"""The match figures (8 x 12), the match keeper's dives (12 x 12), the referee and the ball (5 x 5)."""
from lib import Sprite, grid

# Kit letters: 1 to 5 the kit's tone row; S shorts, T shorts shade; C hands (skin, or gloves for a keeper);
# A skin, B skin shade, H hair, O boot. The kit pattern (stripes, hoop, collar) is a rule on top: see KIT_PATTERN.
FIG = {}

FIG['fig_stand'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
.C2333C.
.C3334C.
..3344..
..SSST..
..S..T..
..3..4..
..3..4..
..OO.OO.
'''
FIG['fig_run_1'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
.22333C.
C.3334..
..3344..
..SSST..
.SS..T..
.3....4.
3.....4.
O.....OO
'''
FIG['fig_run_2'] = '''
........
...HHH..
...HAAA.
...BAA..
..2112..
.C2333..
..33342.
..3344C.
..SSST..
...ST...
...34...
...OO...
'''
FIG['fig_run_3'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
.C23332.
...334.C
..3344..
..SSST..
..S..TT.
.3.....4
.3.....4
OO......
'''
FIG['fig_run_4'] = '''
........
...HHH..
...HAAA.
...BAA..
..2112..
.22333..
.C3334C.
..3344..
..SSST..
...TS...
...43...
...OO...
'''
FIG['fig_kick_1'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
.22333C.
C.3334..
..3344..
..SSST..
.SS..T..
S....4..
3....4..
O....OO.
'''
FIG['fig_kick_2'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
C22333..
..3334C.
..3344..
..SSSTT.
..S...TT
..3....4
..3.....
..OO....
'''
FIG['fig_cheer_1'] = '''
.C....C.
.2HHH.2.
.2HAAA2.
..2AA2..
..2112..
..2333..
..3334..
..3344..
..SSST..
..S..T..
..3..4..
..OO.OO.
'''
FIG['fig_cheer_2'] = '''
C......C
.2.HHH2.
..2HAA2.
...2AA..
..2112..
..2333..
..3334..
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
'''
# the keeper on the match pitch: ready crouch (2 frames, a bob), dives (12 x 12), got it
FIG['gk_ready_1'] = '''
........
...HHH..
...HAAA.
...BAA..
..2112..
C223332C
..3334..
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
'''
FIG['gk_ready_2'] = '''
........
........
...HHH..
...HAAA.
...BAA..
C.2112.C
.223332.
..3344..
..SSST..
.S....T.
.3....4.
OO....OO
'''
FIG['gk_got_it'] = '''
...HHH..
...HAAA.
...BAA..
..2112..
.22333..
.C33WWC.
..3WWW..
..3344..
..SSST..
..S..T..
..3..4..
..OO.OO.
'''
# dive up the screen (toward the keeper's left when facing right) and down; 12 x 12, origin the middle of the bottom row
FIG['gk_dive_up_1'] = '''
.....C......
.....2..C...
....2HH2....
....HAAA....
....BAA.....
...2112.....
...23333....
...3334.....
...3344.....
...SSTT.....
..S...4.....
..O....O....
'''
FIG['gk_dive_up_2'] = '''
........C.C.
.......2.2..
......2HH...
.....HAAA...
.....BAA....
....2112....
...23333....
...3334.....
..3344......
..SST.......
.S..T.......
O....O......
'''
FIG['gk_dive_down_1'] = '''
............
............
............
...HHH......
...HAAA.....
...BAA.2....
..21123C....
..33334.....
..3344SS....
...SST..T4..
....34....O.
....O.......
'''
FIG['gk_dive_down_2'] = '''
............
............
............
............
............
............
...........O
..HHH...SS34
.HAAA233SST.
.BAA213344..
C22233344...
C2..........
'''

FIG_ORIGIN = {}
for n in FIG:
    FIG_ORIGIN[n] = (6, 11) if n.startswith('gk_dive') else (4, 11)

BALL = {
    'ball_roll_1': '''
.555.
51225
52235
53345
.555.
''',
    'ball_roll_2': '''
.555.
52135
53225
54335
.555.
''',
    'ball_air': '''
.555.
51125
51235
52345
.555.
''',
    'ball_shadow': '''
.....
.....
.....
.SSS.
SSSSS
''',
}
