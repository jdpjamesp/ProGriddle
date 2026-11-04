import sys
from lib import Canvas
from palette import C


def sheet(sprites, path, scale=6, cols=8, bg=None):
    cw = max(s.width for s in sprites) + 4
    ch = max(s.height for s in sprites) + 4
    rows = (len(sprites) + cols - 1) // cols
    cv = Canvas(cw * cols, ch * rows, bg or C("Floor"))
    for i, s in enumerate(sprites):
        x = (i % cols) * cw + 2
        y = (i // cols) * ch + 2
        cv.stamp(s, x, y)
    cv.image(scale).save(path)
