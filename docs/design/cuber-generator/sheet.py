"""Every sprite on one sheet, on a dusk ground and on a lit lamp colour, so both reads can be checked."""
import sys
from lib import Canvas, put
from palette import C
import sprites as SP


def sheet(cols=9, cw=36, ch=34):
    items = list(SP.ALL.values())
    rows = (len(items) + cols - 1) // cols
    cv = Canvas(cols * cw + 4, rows * ch + 4, C('Dusk B'))
    for i, s in enumerate(items):
        x = 4 + (i % cols) * cw
        y = 4 + (i // cols) * ch
        if (i // cols) % 2:
            cv.rect(x - 2, y - 2, cw - 2, ch - 2, C('Mint 3'))
        put(cv, s, x, y)
    return cv


if __name__ == '__main__':
    sheet().image(int(sys.argv[2]) if len(sys.argv) > 2 else 4).save(sys.argv[1])
