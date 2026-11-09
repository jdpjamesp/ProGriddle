"""Writes the art and colour classes of Football Manager from the designer's file, so the code and the design cannot disagree.

From the repository root:   python tools/gen-footballmanager-art.py

It reads docs/design/footballmanager-art.md (the tone rows, the single colours and every sprite block) and writes into
src/ProGriddle/Games/FootballManager: FootballTint, FootballRow, FootballLook, FootballSprite and FootballArt. Those five files are
generated: change the design file and run this again, do not edit them by hand.

A sprite is kept in FootballArt as one string of cells, row by row, one character a cell, as the design draws it: '.' is transparent,
the digits 1 to 5 are the five tones of a tone row that the painter chooses when it draws the sprite (a kit, the keeper, a magnet), and
a letter is one fixed colour, which FootballArt:Palette gives for that sprite as "A=F2C6A0;B=C99474" (every sprite has its own letters)."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'design', 'footballmanager-art.md')
OUT = os.path.join(ROOT, 'src', 'ProGriddle', 'Games', 'FootballManager')

lines = open(DOC, encoding='utf-8').read().split('\n')

# the characters that stand for fixed colours in a sprite string: not the digits 1 to 5 (those are tones), and nothing that needs
# escaping in an ABL string (no quote, tilde or asterisk)
ALPHABET = '06789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%&@=+-!?^_<>:;,|'


def pascal(name):
    return ''.join(p[:1].upper() + p[1:] for p in re.split(r'[_ ]+', name.strip()) if p)


def span(start_pat, end_pat):
    a = next(i for i, l in enumerate(lines) if re.match(start_pat, l))
    b = next(i for i in range(a + 1, len(lines)) if re.match(end_pat, lines[i]))
    return lines[a:b]


# ---------------------------------------------------------------- the tone rows (section 2.1)
rows = []   # (Name, [5 hex])
for l in span(r'### 2\.1 ', r'### 2\.2 '):
    m = re.match(r'\| ([A-Za-z ]+?) \| `([0-9A-F]{6})` \| `([0-9A-F]{6})` \| `([0-9A-F]{6})` \| `([0-9A-F]{6})` \| `([0-9A-F]{6})` \|', l)
    if m and m.group(1) != 'Row':
        rows.append((pascal(m.group(1)), [m.group(i) for i in range(2, 7)]))
row_names = [n for n, _ in rows]
assert len(rows) >= 8, len(rows)

# ---------------------------------------------------------------- the single colours (section 2.2)
singles = []   # (Name, hex)
for l in span(r'### 2\.2 ', r'## 3\. '):
    m = re.match(r'\| ([A-Za-z0-9 ]+?) \| `([0-9A-F]{6})` \|', l)
    if m and m.group(1) != 'Name':
        singles.append((pascal(m.group(1)), m.group(2)))
names = [n for n, _ in singles]
assert len(set(names)) == len(names), 'a colour name is used twice: ' + str([n for n in names if names.count(n) > 1])
hex_to_name = {}
for n, h in singles:
    hex_to_name.setdefault(h, n)

extra = {}   # a colour a sprite names by value that is in no single colour: hex -> name


def tint_for(hex_):
    if hex_ in hex_to_name:
        return hex_to_name[hex_]
    extra.setdefault(hex_, 'Fixed' + hex_)
    return extra[hex_]


# ---------------------------------------------------------------- the sprites
sprites = []   # (Name, w, h, ox, oy, picture rows, mapping letter -> tint name)
i = 0
while i < len(lines):
    m = re.match(r'#### (\w+) \((\d+) x (\d+)(?:, (?:origin|top left) \((\d+), (\d+)\))?\)', lines[i])
    if m:
        name, w, h = m.group(1), int(m.group(2)), int(m.group(3))
        ox = int(m.group(4)) if m.group(4) else 0
        oy = int(m.group(5)) if m.group(5) else 0
        j = i + 1
        legend = ''
        while not lines[j].startswith('```'):
            if lines[j].startswith('Legend:'):
                legend = lines[j]
            j += 1
        mapping = {}
        for lm in re.finditer(r'`([A-Za-z])` ([A-Za-z0-9\' ]+?) `([0-9A-Fa-f]{6})`', legend):
            mapping[lm.group(1)] = tint_for(lm.group(3).upper())
        k = j + 1
        pic = []
        while not lines[k].startswith('```'):
            pic.append(lines[k])
            k += 1
        assert len(pic) == h and all(len(r) == w for r in pic), (name, len(pic), h, [len(r) for r in pic][:3])
        for r in pic:
            for ch in r:
                assert ch == '.' or ch in '12345' or ch in mapping, '%s: no colour for %s (%s)' % (name, ch, legend)
        # ABL compares strings without regard to case, so a sprite that uses a letter in both cases gets the lower case one renamed
        seen = {}
        spare = [c for c in '0678#$%&@=+-!?^_<>:;,|' if c not in mapping]
        rename = {}
        for ch in sorted(set(c for r in pic for c in r if c.isalpha())):
            if ch.upper() in seen:
                rename[ch] = spare.pop(0)
            seen[ch.upper()] = ch
        if rename:
            pic = [''.join(rename.get(c, c) for c in r) for r in pic]
            for old_ch, new_ch in rename.items():
                mapping[new_ch] = mapping.pop(old_ch)
        sprites.append((pascal(name), w, h, ox, oy, pic, mapping))
        i = k
    i += 1
assert len(sprites) > 80, len(sprites)
assert len(set(s[0] for s in sprites)) == len(sprites), 'a sprite name is used twice'

tints = names + sorted(extra.values())
extra_hex = {v: k for k, v in extra.items()}

HEADER = ('/* GENERATED by tools/gen-footballmanager-art.py from docs/design/footballmanager-art.md. Change the design file and run the\n'
          '   script, never edit this file by hand. */\n')


def write(fname, text):
    with open(os.path.join(OUT, fname), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(text)


# ---------------------------------------------------------------- FootballTint
t = HEADER + '/* The single colours of the Football Manager look, by name, in the order of the palette of the design. Names that start Fixed are\n'
t += '   colours a sprite names that no palette entry has. */\n'
t += 'ENUM ProGriddle.Games.FootballManager.FootballTint:\n\n    DEFINE ENUM '
t += '\n                '.join((n + ' = 0') if k == 0 else n for k, n in enumerate(tints))
t += '.\n\nEND ENUM.\n'
write('FootballTint.cls', t)

# ---------------------------------------------------------------- FootballRow
r = HEADER + '/* The tone rows of the Football Manager look: five colours each, from the highlight (tone 1) to the edge (tone 5). A sprite uses\n'
r += '   the digits 1 to 5 for the tones of whichever row the painter draws it with. */\n'
r += 'ENUM ProGriddle.Games.FootballManager.FootballRow:\n\n    DEFINE ENUM '
r += '\n                '.join((n + ' = 0') if k == 0 else n for k, n in enumerate(row_names))
r += '.\n\nEND ENUM.\n'
write('FootballRow.cls', r)

# ---------------------------------------------------------------- FootballLook
L = HEADER + '''/* The colours of Football Manager, in one place (as FootballRules holds the numbers). The look is "Chalk and Floodlights": a
   chalkboard in a wooden frame for the menus and a floodlit night match. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballLook FINAL:

    /* The 0xRRGGBB number of a colour. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS FootballTint):
        CASE poTint:
'''
for n, h in singles:
    L += '            WHEN FootballTint:%s THEN RETURN 0x%s.\n' % (n, h)
for n in sorted(extra.values()):
    L += '            WHEN FootballTint:%s THEN RETURN 0x%s.\n' % (n, extra_hex[n])
L += '''            OTHERWISE UNDO, THROW NEW GridException("Football Manager has no colour for " + STRING(poTint)).
        END CASE.
    END METHOD.

    /* The colour of tone piTone (1 highlight to 5 edge) of a tone row. */
    METHOD PUBLIC STATIC INTEGER Tone(INPUT poRow AS FootballRow, INPUT piTone AS INTEGER):
        IF piTone = ? OR piTone < 1 OR piTone > 5 THEN UNDO, THROW NEW GridException("A tone is 1 to 5, not " + STRING(piTone)).
        CASE poRow:
'''
for n, hs in rows:
    L += '            WHEN FootballRow:%s THEN RETURN (IF piTone = 1 THEN 0x%s ELSE IF piTone = 2 THEN 0x%s ELSE IF piTone = 3 THEN 0x%s ELSE IF piTone = 4 THEN 0x%s ELSE 0x%s).\n' % ((n,) + tuple(hs))
L += '''            OTHERWISE UNDO, THROW NEW GridException("Football Manager has no tone row " + STRING(poRow)).
        END CASE.
    END METHOD.

END CLASS.
'''
write('FootballLook.cls', L)

# ---------------------------------------------------------------- FootballSprite and FootballArt
s = HEADER + '/* The sprites of the Football Manager look, by name (an enum, so a sprite has a type and a number). FootballArt holds their cells. */\n'
s += 'ENUM ProGriddle.Games.FootballManager.FootballSprite:\n\n    DEFINE ENUM '
s += '\n                '.join((sp[0] + ' = 0') if k == 0 else sp[0] for k, sp in enumerate(sprites))
s += '.\n\nEND ENUM.\n'
write('FootballSprite.cls', s)

A = HEADER + '''/* The cells of every sprite of Football Manager, one string each, row by row: '.' is a cell with nothing in it, the digits 1 to 5 are
   the tones of the tone row the painter draws the sprite with, and any other character is a fixed colour (FootballLook:TintOf says
   which). Sizes are in Width and Height, and OriginX and OriginY are the cell that goes on the place of the thing (the middle of the
   feet of a figure, the middle of a ball). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballArt FINAL:

    /* How many sprites there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN %d.
    END METHOD.

''' % len(sprites)
for label, idx, what in (('Width', 1, 'The width of a sprite in cells.'), ('Height', 2, 'The height of a sprite in cells.'),
                         ('OriginX', 3, "The column of the cell that goes on the sprite's place."),
                         ('OriginY', 4, "The row of the cell that goes on the sprite's place.")):
    A += '    /* %s */\n    METHOD PUBLIC STATIC INTEGER %s(INPUT poSprite AS FootballSprite):\n        CASE poSprite:\n' % (what, label)
    for sp in sprites:
        A += '            WHEN FootballSprite:%s THEN RETURN %d.\n' % (sp[0], sp[idx])
    A += '            OTHERWISE UNDO, THROW NEW GridException("Football Manager has no sprite " + STRING(poSprite)).\n        END CASE.\n    END METHOD.\n\n'
A += '    /* The cells of a sprite, Width times Height characters. */\n    METHOD PUBLIC STATIC CHARACTER Cells(INPUT poSprite AS FootballSprite):\n        CASE poSprite:\n'
for nm, w, h, ox, oy, pic, mapping in sprites:
    A += '            WHEN FootballSprite:%s THEN RETURN "%s".\n' % (nm, ''.join(pic))
A += '            OTHERWISE UNDO, THROW NEW GridException("Football Manager has no sprite " + STRING(poSprite)).\n        END CASE.\n    END METHOD.\n\n'
A += '    /* The fixed colours of a sprite, as "letter=RRGGBB" pairs separated by semicolons (a sprite with no fixed colour gives an empty string). */\n    METHOD PUBLIC STATIC CHARACTER Palette(INPUT poSprite AS FootballSprite):\n        CASE poSprite:\n'
single_hex = dict(singles)
for nm, w, h, ox, oy, pic, mapping in sprites:
    letters = sorted(set(ch for row in pic for ch in row if ch != '.' and ch not in '12345'))
    pairs = []
    for ch in letters:
        tn = mapping[ch]
        pairs.append('%s=%s' % (ch, extra_hex[tn] if tn in extra_hex else single_hex[tn]))
    A += '            WHEN FootballSprite:%s THEN RETURN "%s".\n' % (nm, ';'.join(pairs))
A += '            OTHERWISE UNDO, THROW NEW GridException("Football Manager has no sprite " + STRING(poSprite)).\n        END CASE.\n    END METHOD.\n\nEND CLASS.\n'
write('FootballArt.cls', A)
print('%d tone rows, %d colours (%d fixed extras), %d sprites' % (len(rows), len(tints), len(extra), len(sprites)))
