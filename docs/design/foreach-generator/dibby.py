"""Dibby, the database drum: hand drawn 16 x 16 frames, facing right."""
from lib import Sprite

LEGEND = {'E': 'Eye', 'P': 'Pupil', 'L': 'LED', 'M': 'Mouth', 'T': 'Tongue'}


def rotate_rows(rows, turns):
    for _ in range(turns % 4):
        h, w = len(rows), len(rows[0])
        rows = [''.join(rows[h - 1 - y][x] for y in range(h)) for x in range(w)]
    return rows


CLOSED = [
    "................",
    "................",
    ".....555555.....",
    "...5511111155...",
    "..511111111115..",
    "..521111111125..",
    "..542222222245..",
    "..543322EE2EE5..",
    "..543322EP2EP5..",
    "..543322EP2EP5..",
    "..543322555555..",
    "..5LL322222345..",
    "..544444444445..",
    "..543322223345..",
    "...5543333455...",
    ".....555555.....",
]
HALF = [
    "................",
    "................",
    ".....555555.....",
    "...5511111155...",
    "..511111111115..",
    "..521111111125..",
    "..542222222245..",
    "..543322EE2EE5..",
    "..543322EP2EP5..",
    "..543322EP2EP5..",
    "..543322555555..",
    "..5LL3225MMMMM..",
    "..544444455555..",
    "..543322223345..",
    "...5543333455...",
    ".....555555.....",
]
WIDE = [
    "................",
    ".....555555.....",
    "...5511111155...",
    "..511111111115..",
    "..521111111125..",
    "..542222222245..",
    "..543322EE2EE5..",
    "..543322EP2EP5..",
    "..543322EP2EP5..",
    "..543322555555..",
    "..5433225MMMMM..",
    "..5LL325MMMMMM..",
    "..5444445TTTMM..",
    "..543322555555..",
    "...5543333455...",
    ".....555555.....",
]
HAPPY = [
    "................",
    "................",
    ".....555555.....",
    "...5511111155...",
    "..511111111115..",
    "..521111111125..",
    "..542222222245..",
    "..543322PP2PP5..",
    "..54332P22P225..",
    "..543322222225..",
    "..543322555555..",
    "..5LL3225TTT55..",
    "..544444455555..",
    "..543322223345..",
    "...5543333455...",
    ".....555555.....",
]
LIVES = [
    "............",
    "...555555...",
    ".5511111155.",
    ".5111111115.",
    ".5422222245.",
    ".54322E2E25.",
    ".54322P2P25.",
    ".5432255555.",
    ".5LL25MMMM5.",
    ".5444555555.",
    "..55333355..",
    "....5555....",
]


def build():
    out = []
    specs = [('dibby_closed', CLOSED, 'Closed: the jaw shut, a dark line along the split. The first frame of a level.'),
             ('dibby_half', HALF, 'Half open. Also the frame shown while Dibby is blocked by a wall.'),
             ('dibby_wide', WIDE, 'Wide open, the tongue showing. The lid lifts one pixel.'),
             ('dibby_happy', HAPPY, 'Title and attract only: happy eyes and a grin (used on the title and after a level is cleared).')]
    for name, rows, note in specs:
        out.append(Sprite(name, rows, tone='Dibby', legend=LEGEND, origin=(8, 8), note=note, group='dibby'))
    out.append(Sprite('dibby_life', [r[::-1] for r in LIVES], tone='Dibby', legend=LEGEND, origin=(6, 6),
                      note='The lives icon, 12 x 12, already facing left (it is the half frame drawn small).', group='dibby'))
    return out


if __name__ == '__main__':
    for s in build():
        print(s.name)
        print('\n'.join(s.rows))
