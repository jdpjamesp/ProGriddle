"""Quick look: every sprite on one sheet."""
import sys
from lib import Canvas, put
from palette import C
import sprites as SP


def sheet(scale=4, cols=10):
    items = list(SP.ALL.values())
    cw, ch = 20, 22
    rows = (len(items) + cols - 1) // cols
    cv = Canvas(cols * cw + 4, rows * ch + 4, C('Night'))
    for i, s in enumerate(items):
        x = 4 + (i % cols) * cw
        y = 4 + (i // cols) * ch
        put(cv, s, x, y)
    return cv


if __name__ == '__main__':
    sheet().image(int(sys.argv[2]) if len(sys.argv) > 2 else 6).save(sys.argv[1])
