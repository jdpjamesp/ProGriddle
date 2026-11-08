"""Writes the art and colour classes of Cuber from the designer's file, so the code and the design cannot disagree.

From the repository root:   python tools/gen-cuber-art.py

It reads docs/design/cuber-art.md (the tone rows, the single colours, the round themes, the stars and every sprite block) and
writes into src/ProGriddle/Games/Cuber: CuberTint, CuberRow, CuberLook, CuberSprite and CuberArt. Those five files are generated:
change the design file and run this again, do not edit them by hand. (The game keeps the name Cuber in its code. The names of the
design, Lamplighter, Pip, the Coil, Thorns and so on, appear in comments and on the game's page.)

A sprite is kept in CuberArt as one string of cells, row by row, one character a cell: '.' is transparent, the digits 1 to 5 are
the five tones of a tone row that the painter chooses when it draws the sprite (Pip's row, a lamp's theme and so on), and any other
character stands for one fixed colour of CuberTint (see CuberLook:CodeOf). Three characters are places the painter fills in from the
round: the spill colours of a lit lamp and the base tone of the round's done row."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'design', 'cuber-art.md')
OUT = os.path.join(ROOT, 'src', 'ProGriddle', 'Games', 'Cuber')

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
assert len(rows) == 19, len(rows)

# ---------------------------------------------------------------- the single colours (section 2.2)
singles = []   # (Name, hex)
for l in span(r'### 2\.2 ', r'### 2\.3 '):
    m = re.match(r'\| ([A-Za-z0-9 ]+?) \| `([0-9A-F]{6})` \|', l)
    if m and m.group(1) != 'Name':
        singles.append((pascal(m.group(1)), m.group(2)))
names = [n for n, _ in singles]
assert len(set(names)) == len(names), 'a colour name is used twice'
hex_to_name = {}
for n, h in singles:
    hex_to_name.setdefault(h, n)

# ---------------------------------------------------------------- the round themes (section 2.3)
THEMES = ['Mint', 'Rose', 'Sky', 'Lilac']
for t in THEMES:
    assert t in row_names and t + 'Half' in row_names, t
    assert 'Spill' + t in names and 'Spill' + t + 'Dark' in names, t

# ---------------------------------------------------------------- the stars (section 3.1)
stars = []
for l in span(r'### 3\.1 ', r'### 3\.2 '):
    if l.startswith('- **Stars**'):
        pass
    if "The generator's list" in l:
        for m in re.finditer(r'\((\d+), (\d+)\)(\*?)', l):
            stars.append((int(m.group(1)), int(m.group(2)), 1 if m.group(3) else 0))
assert len(stars) == 46, len(stars)

# ---------------------------------------------------------------- the sprites
# placeholders the painter fills in (they have no colour of their own)
PLACE = ['SpillLight', 'SpillDark', 'DoneBase']
extra = {}   # a colour a sprite names by value that is in no single colour: hex -> name


def tint_for(hex_):
    if hex_ in hex_to_name:
        return hex_to_name[hex_]
    extra.setdefault(hex_, 'Fixed' + hex_)
    return extra[hex_]


sprites = []   # (Name, w, h, ox, oy, picture rows as text, mapping letter -> tint name)
i = 0
while i < len(lines):
    m = re.match(r'#### (\w+) \((\d+) x (\d+)(?:, origin \((\d+), (\d+)\))?\)', lines[i])
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
        # a letter with a hex colour
        for lm in re.finditer(r'`([A-Za-z])` ([A-Za-z0-9\' ]+?) `([0-9A-Fa-f]{6})`', legend):
            mapping[lm.group(1)] = tint_for(lm.group(3).upper())
        # the letters that are places the painter fills in
        if re.search(r'`L` Spill \(theme\)', legend):
            mapping['L'] = 'SpillLight'
        if re.search(r'`R` Spill \(theme\) Dark', legend):
            mapping['R'] = 'SpillDark'
        if re.search(r"`D` the theme's Done tone 3", legend):
            mapping['D'] = 'DoneBase'
        # the lamps share their faces: the legend says which lamp a picture takes them from
        if name.startswith('lamp') and name != 'lamp_unlit':
            base = next(x[6] for x in sprites if x[0] == 'LampUnlit')
            for letter in 'MNSTE':
                mapping.setdefault(letter, base[letter])
            if re.search(r'faces as lamp_done|half size', legend):
                mapping.setdefault('L', 'SpillLight')
                mapping.setdefault('R', 'SpillDark')
            else:
                mapping.setdefault('L', base['L'])
                mapping.setdefault('R', base['R'])
        k = j + 1
        pic = []
        while not lines[k].startswith('```'):
            pic.append(lines[k])
            k += 1
        assert len(pic) == h and all(len(r) == w for r in pic), (name, len(pic), h)
        for r in pic:
            for ch in r:
                assert ch == '.' or ch in '12345' or ch in mapping, '%s: no colour for %s (%s)' % (name, ch, legend)
        sprites.append((pascal(name), w, h, ox, oy, pic, mapping))
        i = k
    i += 1
assert len(sprites) > 70, len(sprites)
assert len(set(s[0] for s in sprites)) == len(sprites), 'a sprite name is used twice'

tints = names + sorted(extra.values()) + PLACE
assert len(tints) <= len(ALPHABET), 'more colours (%d) than characters (%d)' % (len(tints), len(ALPHABET))
code_of = {n: ALPHABET[k] for k, n in enumerate(tints)}
extra_hex = {v: k for k, v in extra.items()}

HEADER = ('/* GENERATED by tools/gen-cuber-art.py from docs/design/cuber-art.md. Change the design file and run the script,\n'
          '   never edit this file by hand. */\n')


def write(fname, text):
    with open(os.path.join(OUT, fname), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(text)


# ---------------------------------------------------------------- CuberTint
t = HEADER + '/* The single colours of the Cuber look, by name, in the order of the palette of the design. The last three are not\n'
t += '   colours: they stand in a sprite for the light and dark spill of a lit lamp and the base tone of the done row of the round,\n'
t += '   which the painter fills in. Names that start Fixed are colours a sprite names that no palette entry has. */\n'
t += 'ENUM ProGriddle.Games.Cuber.CuberTint:\n\n    DEFINE ENUM '
t += '\n                '.join((n + ' = 0') if k == 0 else n for k, n in enumerate(tints))
t += '.\n\nEND ENUM.\n'
write('CuberTint.cls', t)

# ---------------------------------------------------------------- CuberRow
r = HEADER + '/* The tone rows of the Cuber look: five colours each, from the highlight (tone 1) to the edge (tone 5). A sprite uses the digits\n'
r += '   1 to 5 for the tones of whichever row the painter draws it with. */\n'
r += 'ENUM ProGriddle.Games.Cuber.CuberRow:\n\n    DEFINE ENUM '
r += '\n                '.join((n + ' = 0') if k == 0 else n for k, n in enumerate(row_names))
r += '.\n\nEND ENUM.\n'
write('CuberRow.cls', r)

# ---------------------------------------------------------------- CuberLook
L = HEADER + '''/* The colours of Cuber, in one place (as CuberRules holds the numbers). The look is "Dusk Lamps": a dusk sky over a bottomless dark,
   stone lamps that light up from the inside, and four pastel lights, one for each round of a level. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberLook FINAL:

    /* The 0xRRGGBB number of a colour. Throws GridException for one of the three places a painter fills in, which have no colour of their own. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS CuberTint):
        CASE poTint:
'''
for n, h in singles:
    L += '            WHEN CuberTint:%s THEN RETURN 0x%s.\n' % (n, h)
for n in sorted(extra.values()):
    L += '            WHEN CuberTint:%s THEN RETURN 0x%s.\n' % (n, extra_hex[n])
L += '''            OTHERWISE UNDO, THROW NEW GridException("Cuber has no colour for " + STRING(poTint)).
        END CASE.
    END METHOD.

    /* The colour of tone piTone (1 highlight to 5 edge) of a tone row. */
    METHOD PUBLIC STATIC INTEGER Tone(INPUT poRow AS CuberRow, INPUT piTone AS INTEGER):
        IF piTone = ? OR piTone < 1 OR piTone > 5 THEN UNDO, THROW NEW GridException("A tone is 1 to 5, not " + STRING(piTone)).
        CASE poRow:
'''
for n, hs in rows:
    L += '            WHEN CuberRow:%s THEN RETURN (IF piTone = 1 THEN 0x%s ELSE IF piTone = 2 THEN 0x%s ELSE IF piTone = 3 THEN 0x%s ELSE IF piTone = 4 THEN 0x%s ELSE 0x%s).\n' % ((n,) + tuple(hs))
L += '''            OTHERWISE UNDO, THROW NEW GridException("Cuber has no tone row " + STRING(poRow)).
        END CASE.
    END METHOD.

    /* How many rounds a level has, and so how many lights (themes). */
    METHOD PUBLIC STATIC INTEGER Themes():
        RETURN 4.
    END METHOD.

    /* The name of the light of round piRound (1 to 4): MINT, ROSE, SKY, LILAC. */
    METHOD PUBLIC STATIC CHARACTER ThemeName(INPUT piRound AS INTEGER):
        CASE piRound:
'''
for k, th in enumerate(THEMES):
    L += '            WHEN %d THEN RETURN "%s".\n' % (k + 1, th.upper())
L += '''            OTHERWISE UNDO, THROW NEW GridException("A round is 1 to 4, not " + STRING(piRound)).
        END CASE.
    END METHOD.

    /* The tone row of a lamp that is lit (the round's target colour), and of one that is half way, in round piRound (1 to 4). */
    METHOD PUBLIC STATIC CuberRow DoneRow(INPUT piRound AS INTEGER):
        CASE piRound:
'''
for k, th in enumerate(THEMES):
    L += '            WHEN %d THEN RETURN CuberRow:%s.\n' % (k + 1, th)
L += '''            OTHERWISE UNDO, THROW NEW GridException("A round is 1 to 4, not " + STRING(piRound)).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC CuberRow HalfRow(INPUT piRound AS INTEGER):
        CASE piRound:
'''
for k, th in enumerate(THEMES):
    L += '            WHEN %d THEN RETURN CuberRow:%sHalf.\n' % (k + 1, th)
L += '''            OTHERWISE UNDO, THROW NEW GridException("A round is 1 to 4, not " + STRING(piRound)).
        END CASE.
    END METHOD.

    /* The light (piShade 1) and the dark (2) colour that spills down the stone of a lit lamp in round piRound. */
    METHOD PUBLIC STATIC INTEGER Spill(INPUT piRound AS INTEGER, INPUT piShade AS INTEGER):
        IF piShade < 1 OR piShade > 2 THEN UNDO, THROW NEW GridException("A spill shade is 1 or 2, not " + STRING(piShade)).
        CASE piRound:
'''
for k, th in enumerate(THEMES):
    L += '            WHEN %d THEN RETURN (IF piShade = 1 THEN Colour(CuberTint:Spill%s) ELSE Colour(CuberTint:Spill%sDark)).\n' % (k + 1, th, th)
L += '''            OTHERWISE UNDO, THROW NEW GridException("A round is 1 to 4, not " + STRING(piRound)).
        END CASE.
    END METHOD.

    /* The character of a colour in a sprite string of CuberArt. */
    METHOD PUBLIC STATIC CHARACTER CodeOf(INPUT poTint AS CuberTint):
        CASE poTint:
'''
for n in tints:
    L += '            WHEN CuberTint:%s THEN RETURN "%s".\n' % (n, code_of[n])
L += '''            OTHERWISE RETURN ".".
        END CASE.
    END METHOD.

    /* The stars of the sky, baked into the background: x, y and 1 for a bright one (4 of them twinkle), as "x,y,b;x,y,b;...". */
    METHOD PUBLIC STATIC CHARACTER Stars():
        RETURN "%s".
    END METHOD.

END CLASS.
''' % ';'.join('%d,%d,%d' % s for s in stars)
write('CuberLook.cls', L)

# ---------------------------------------------------------------- CuberSprite and CuberArt
s = HEADER + '/* The sprites of the Cuber look, by name (an enum, so a sprite has a type and a number). CuberArt holds their cells. */\n'
s += 'ENUM ProGriddle.Games.Cuber.CuberSprite:\n\n    DEFINE ENUM '
s += '\n                '.join((sp[0] + ' = 0') if k == 0 else sp[0] for k, sp in enumerate(sprites))
s += '.\n\nEND ENUM.\n'
write('CuberSprite.cls', s)

A = HEADER + '''/* The cells of every sprite of Cuber, one string each, row by row: '.' is a cell with nothing in it, the digits 1 to 5 are the tones
   of the tone row the painter draws the sprite with, and any other character is a fixed colour (CuberLook:CodeOf says which).
   Sizes are in Width and Height, and OriginX and OriginY are the cell that goes on the place of the thing (the middle of the feet of
   whatever stands on a lamp). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberArt FINAL:

    /* How many sprites there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN %d.
    END METHOD.

''' % len(sprites)
for label, idx, what in (('Width', 1, 'The width of a sprite in cells.'), ('Height', 2, 'The height of a sprite in cells.'),
                         ('OriginX', 3, 'The column of the cell that goes on the sprite\'s place.'),
                         ('OriginY', 4, 'The row of the cell that goes on the sprite\'s place.')):
    A += '    /* %s */\n    METHOD PUBLIC STATIC INTEGER %s(INPUT poSprite AS CuberSprite):\n        CASE poSprite:\n' % (what, label)
    for sp in sprites:
        A += '            WHEN CuberSprite:%s THEN RETURN %d.\n' % (sp[0], sp[idx])
    A += '            OTHERWISE UNDO, THROW NEW GridException("Cuber has no sprite " + STRING(poSprite)).\n        END CASE.\n    END METHOD.\n\n'
A += '    /* The cells of a sprite, Width times Height characters. */\n    METHOD PUBLIC STATIC CHARACTER Cells(INPUT poSprite AS CuberSprite):\n        CASE poSprite:\n'
for nm, w, h, ox, oy, pic, mapping in sprites:
    cells = ''
    for row in pic:
        for ch in row:
            if ch == '.' or ch in '12345':
                cells += ch
            else:
                cells += code_of[mapping[ch]]
    A += '            WHEN CuberSprite:%s THEN RETURN "%s".\n' % (nm, cells)
A += '            OTHERWISE UNDO, THROW NEW GridException("Cuber has no sprite " + STRING(poSprite)).\n        END CASE.\n    END METHOD.\n\nEND CLASS.\n'
write('CuberArt.cls', A)
print('%d tone rows, %d colours (%d fixed extras), %d sprites, %d stars' % (len(rows), len(tints), len(extra), len(sprites), len(stars)))
