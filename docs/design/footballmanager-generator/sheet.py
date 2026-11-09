"""Every sprite on one sheet, alternate rows on the board and on the grass, so both reads can be checked."""
import sys
from lib import Canvas, put
from palette import C
import sprites as SP


def sheet(scale=4):
    items = list(SP.ALL.values())
    x, y, rowh, rows = 4, 4, 0, []
    W = 400
    placed = []
    line = 0
    for s in items:
        if x + s.width + 4 > W:
            x, y, line = 4, y + rowh + 6, line + 1
            rowh = 0
        placed.append((s, x, y, line))
        x += s.width + 5
        rowh = max(rowh, s.height)
    H = y + rowh + 6
    cv = Canvas(W, H, C('Board'))
    lines = {}
    for s, x, yy, ln in placed:
        lines.setdefault(ln, [yy, yy])
        lines[ln][1] = max(lines[ln][1], yy + s.height)
    for ln, (a, b) in lines.items():
        if ln % 2:
            cv.rect(0, a - 3, W, b - a + 6, C('Grass A'))
    for s, x, yy, ln in placed:
        put(cv, s, x, yy)
    return cv


if __name__ == '__main__':
    sheet().image(int(sys.argv[2]) if len(sys.argv) > 2 else 4).save(sys.argv[1])
