"""Writes the art and colour classes of Xevious from the designer's file, so the code and the design cannot disagree.

From the repository root:   python tools/gen-xevious-art.py

It reads docs/design/skylark-art.md (the palette tables, the tile letter table, every tile and sprite block, the boxes written in the
text, and the table of the 16 areas) and writes into src/ProGriddle/Games/Xevious: XeviousTint, XeviousPicture, XeviousTilePicture,
XeviousLook, XeviousArt, XeviousTileArt and XeviousAreas. Those seven files are generated: change the design file and run this
again, do not edit them by hand.

How a picture is stored: one character a cell, rows joined with a slash. "." is a cell left out, and any other character is a
colour: chr(48 + n) is the n th tint of XeviousTint (counting from 0). A tile written in the design's abstract letters stores the
three letters that change with the ground family (g, l and d) as "#", "$" and "%", which XeviousLook:FamilyColour resolves."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'design', 'skylark-art.md')
OUT = os.path.join(ROOT, 'src', 'ProGriddle', 'Games', 'Xevious')

lines = open(DOC, encoding='utf-8').read().split('\n')


def pascal(name):
    return ''.join(p[:1].upper() + p[1:] for p in re.split(r'[_ ]+', name.strip()) if p)


def find(pattern, start=0):
    return next(i for i in range(start, len(lines)) if re.match(pattern, lines[i]))


# ---------------------------------------------------------------- the palette (section 1)
s1 = find(r'## 1\. ')
s2 = find(r'## 2\. ')
tints = []   # (Pascal name, hex)
for l in lines[s1:s2]:
    m = re.match(r'\| ([A-Za-z ]+) \| `([0-9A-F]{6})` \|', l)
    if m and m.group(1) != 'Name':
        tints.append((pascal(m.group(1)), m.group(2)))
names = [t[0] for t in tints]
assert len(names) == len(set(names)) and len(names) <= 64 + 8, len(names)
index = {n: i for i, n in enumerate(names)}
CHARS = [chr(48 + i) for i in range(len(names))]
assert '~' not in CHARS and '"' not in CHARS


def code(name):
    return CHARS[index[name]]


# ---------------------------------------------------------------- the tile letters (section 2.1)
letters = {}
family = {}   # letter -> (green name, dry name)
t0 = find(r'\| Letter \| Green family')
for l in lines[t0 + 2:]:
    m = re.match(r'\| `(\w)` \| ([A-Za-z ]+) `[0-9A-F]{6}` \| (the same|[A-Za-z ]+ `[0-9A-F]{6}`) \|', l)
    if not m:
        break
    letter, green, dry = m.group(1), pascal(m.group(2)), m.group(3)
    if dry == 'the same':
        letters[letter] = code(green)
    else:
        family[letter] = (green, pascal(re.sub(r' `.*', '', dry)))
FAMILY_CODE = {'g': '#', 'l': '$', 'd': '%'}
for k in FAMILY_CODE:
    assert k in family, k
for k, v in FAMILY_CODE.items():
    letters[k] = v

# ---------------------------------------------------------------- the pictures
tile_start = find(r'### 2\.2 ')
sprite_start = find(r'## 3\. ')
end_marker = find(r'## 4\. ')

sprites = []    # dict
tiles = []
i = 0
while i < len(lines):
    m = re.match(r'#### (\w+) \((\d+) x (\d+)\)', lines[i])
    if not m:
        i += 1
        continue
    name, w, h = m.group(1), int(m.group(2)), int(m.group(3))
    j = i + 1
    prose = []
    legend_line = ''
    while not lines[j].startswith('```'):
        if lines[j].startswith('Legend:'):
            legend_line = lines[j]
        elif lines[j].strip():
            prose.append(lines[j])
        j += 1
    k = j + 1
    pic = []
    while not lines[k].startswith('```'):
        pic.append(lines[k])
        k += 1
    assert len(pic) == h and all(len(r) == w for r in pic), (name, len(pic), [len(r) for r in pic])
    is_tile = tile_start < i < sprite_start
    box = None
    bm = re.search(r'[Bb]ox,? (\d+) x (\d+) at \((\d+), (\d+)\)', ' '.join(prose))
    if bm:
        box = tuple(int(g) for g in bm.groups())
    if is_tile:
        row_codes = []
        for r in pic:
            row_codes.append(''.join(letters[c] for c in r))
        tiles.append(dict(name=name, w=w, h=h, rows=row_codes))
    else:
        row_codes = []
        sprites.append(dict(name=name, w=w, h=h, pic=pic, legend=legend_line, box=box, rows=None))
    i = k + 1

# resolve sprite legends ("as `lark`" reuses another sprite's legend, a legend lists `X` Name `HEX`)
legends = {}
for s in sprites:
    pairs = re.findall(r'`([A-Za-z])` ([A-Z][A-Za-z ]*?)(?= `[0-9A-F]{6}`|[,)]|\.|$)', s['legend'])
    lg = {c: pascal(n) for c, n in pairs}
    s['lg'] = lg
for s in sprites:
    if not s['lg'] and 'as `' in s['legend']:
        src = re.search(r'as `(\w+)`', s['legend']).group(1)
        s['lg'] = next(o['lg'] for o in sprites if o['name'] == src)
for s in sprites:
    rows = []
    for r in s['pic']:
        out = ''
        for c in r:
            if c == '.':
                out += '.'
            else:
                assert c in s['lg'], (s['name'], c)
                out += code(s['lg'][c])
        rows.append(out)
    s['rows'] = rows

# the 32 x 32 land lines are cut into four 16 x 16 tiles each
cut = []
for t in tiles:
    if t['w'] == 32:
        for q, (ox, oy) in (('nw', (0, 0)), ('ne', (16, 0)), ('sw', (0, 16)), ('se', (16, 16))):
            cut.append(dict(name=t['name'] + '_' + q, w=16, h=16, rows=[r[ox:ox + 16] for r in t['rows'][oy:oy + 16]]))
    else:
        cut.append(t)
tiles = cut

# ---------------------------------------------------------------- the areas (section 2.4)
a0 = find(r'\| Area \| Ground \| Mood')
areas = {}
for l in lines[a0 + 2:]:
    m = re.match(r'\| (\d+) \| (green|dry) \| (\w+) \|', l)
    if not m:
        break
    areas[int(m.group(1))] = (m.group(2), m.group(3))
assert len(areas) == 16
mood_names = []
moods = {}
m0 = find(r'\| Mood \| Tint \| Amount')
for l in lines[m0 + 2:]:
    m = re.match(r'\| (\w+) \| ([A-Za-z ]+|none) \| (\d+)% \|', l)
    if not m:
        break
    mood_names.append(m.group(1))
    moods[m.group(1)] = (None if m.group(2) == 'none' else pascal(m.group(2)), int(m.group(3)))

# ---------------------------------------------------------------- writing
BANNER = '/* Generated by tools/gen-xevious-art.py from docs/design/skylark-art.md: do not edit by hand, change the design and run it again. */\n'


def write(name, text):
    with open(os.path.join(OUT, name + '.cls'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(text)


def enum_text(name, doc, members):
    rest = ''.join('\n                %s' % m for m in members[1:])
    return '%s%s\nENUM ProGriddle.Games.Xevious.%s:\n\n    DEFINE ENUM %s = 0%s.\n\nEND ENUM.\n' % (BANNER, doc, name, members[0], rest)


write('XeviousTint', enum_text('XeviousTint',
      '/* The named colours of Xevious, in the order of the palette tables of the design (section 1), such as MeadowLight and HullInk.\n   XeviousLook gives each one as a number. */', names))
sprite_names = [pascal(s['name']) for s in sprites]
write('XeviousPicture', enum_text('XeviousPicture',
      '/* The sprites of Xevious, by name: every sprite block of the design file (section 3), such as Lark, Whirl1 and Citadel. XeviousArt says\n   what each one looks like. */', sprite_names))
tile_names = [pascal(t['name']) for t in tiles]
write('XeviousTilePicture', enum_text('XeviousTilePicture',
      '/* The ground tiles of Xevious, by name: every tile block of the design file (section 2.2 and 2.3), such as Open1, ForestNw and\n   LinesSpiralSe. XeviousTileArt says what each one looks like. */', tile_names))

look = [BANNER + '''/* The colours of Xevious, from the design (section 1): the named colours as 0xRRGGBB numbers, and the colour a picture character stands
   for. A picture stores chr(48 + n) for the n th member of XeviousTint, and "#", "$" and "%" for the three colours of a tile that
   depend on the ground family (see FamilyColour). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousLook FINAL:

    /* The colour of a named colour. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS XeviousTint):
        CASE poTint:
''']
for n, hx in tints:
    look.append('            WHEN XeviousTint:%s THEN RETURN %d.\n' % (n, int(hx, 16)))
look.append('''            OTHERWISE UNDO, THROW NEW GridException("A colour cannot be unknown").
        END CASE.
    END METHOD.

    /* The colour a picture character stands for, or -1 for ".", which is a cell left out. A tile letter that depends on the ground
       family (# $ %%) is read as the green family when plDry is false and the dry family when it is true. */
    METHOD PUBLIC STATIC INTEGER CodeColour(INPUT pcCode AS CHARACTER, INPUT plDry AS LOGICAL):
        IF pcCode = "." THEN RETURN -1.
        CASE pcCode:
            WHEN "#" THEN RETURN Colour(IF plDry THEN XeviousTint:%s ELSE XeviousTint:%s).
            WHEN "$" THEN RETURN Colour(IF plDry THEN XeviousTint:%s ELSE XeviousTint:%s).
            WHEN "%%" THEN RETURN Colour(IF plDry THEN XeviousTint:%s ELSE XeviousTint:%s).
        END CASE.
        IF ASC(pcCode) < 48 OR ASC(pcCode) >= 48 + %d THEN UNDO, THROW NEW GridException("No colour for picture character " + pcCode).
        RETURN Colour(XeviousTint:GetEnum(ASC(pcCode) - 48)).
    END METHOD.

END CLASS.
''' % (family['g'][1], family['g'][0], family['l'][1], family['l'][0], family['d'][1], family['d'][0], len(names)))
write('XeviousLook', ''.join(look))


def abl_text(text):
    """A picture row as the inside of an ABL string literal. A backslash is an escape character on Unix, so it is
    written as tilde backslash (the tilde is ABL's own escape and works on every platform)."""
    assert '~' not in text and '"' not in text
    return text.replace(chr(92), '~' + chr(92))


def art_class(cls, enum, items, doc):
    out = [BANNER + doc + '''
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.%s FINAL:

    /* The rows of a picture joined with a slash. */
    METHOD PUBLIC STATIC CHARACTER Rows(INPUT poPicture AS %s):
        CASE poPicture:
''' % (cls, enum)]
    for it in items:
        out.append('            WHEN %s:%s THEN RETURN "%s".\n' % (enum, pascal(it['name']), abl_text('/'.join(it['rows']))))
    out.append('''            OTHERWISE UNDO, THROW NEW GridException("A picture cannot be unknown").
        END CASE.
    END METHOD.
''')
    return out


art = art_class('XeviousArt', 'XeviousPicture', sprites,
                '/* The sprites of Xevious as the design draws them (section 3): rows of colour characters, "." for a cell left out. Placing: a\n   sprite is centred on the place of its thing. Box says where it can be hit, in cells from its top left. */')
art.append('''
    /* The collision box of a sprite: how far in from its left and top, and how wide and high. A sprite with no box in the design is
       all of it. */
    METHOD PUBLIC STATIC INTEGER BoxX(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    if s['box']:
        art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['box'][2]))
art.append('''            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BoxY(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    if s['box']:
        art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['box'][3]))
art.append('''            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BoxWidth(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    if s['box']:
        art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['box'][0]))
art.append('''            OTHERWISE RETURN Width(poPicture).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BoxHeight(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    if s['box']:
        art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['box'][1]))
art.append('''            OTHERWISE RETURN Height(poPicture).
        END CASE.
    END METHOD.

    /* The width and the height of a sprite in cells. */
    METHOD PUBLIC STATIC INTEGER Width(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['w']))
art.append('''            OTHERWISE UNDO, THROW NEW GridException("A picture cannot be unknown").
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Height(INPUT poPicture AS XeviousPicture):
        CASE poPicture:
''')
for s in sprites:
    art.append('            WHEN XeviousPicture:%s THEN RETURN %d.\n' % (pascal(s['name']), s['h']))
art.append('''            OTHERWISE UNDO, THROW NEW GridException("A picture cannot be unknown").
        END CASE.
    END METHOD.

END CLASS.
''')
write('XeviousArt', ''.join(art))

tile_art = art_class('XeviousTileArt', 'XeviousTilePicture', tiles,
                     '/* The ground tiles of Xevious as the design draws them (section 2): 16 x 16 rows of colour characters, where "#", "$" and "%" are the\n   three colours that change with the ground family. The land lines are cut into four tiles each (nw, ne, sw, se). */')
tile_art.append('\nEND CLASS.\n')
tile_art_text = ''.join(tile_art).replace('    END METHOD.\n\nEND CLASS.\n\nEND CLASS.\n', '    END METHOD.\n\nEND CLASS.\n')
write('XeviousTileArt', tile_art_text)

# the areas
ar = [BANNER + '''/* The 16 areas of Xevious as the design lists them (section 2.4): which ground family each has (green or dry) and its mood, a tint
   of the whole ground. The moods are numbered in the order of the design's table (%s). After area 16 the loop starts again at 1. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousAreas FINAL:

    /* True when the land of an area (1 up, going round after 16) is the dry family. */
    METHOD PUBLIC STATIC LOGICAL IsDry(INPUT piArea AS INTEGER):
        CASE (piArea - 1) MODULO 16 + 1:
''' % ', '.join(mood_names)]
dry = [a for a, v in areas.items() if v[0] == 'dry']
ar.append('            WHEN %s THEN RETURN TRUE.\n' % ' OR WHEN '.join(str(a) for a in dry))
ar.append('''            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

    /* The mood of an area as a number: 0 for %s and so on. */
    METHOD PUBLIC STATIC INTEGER Mood(INPUT piArea AS INTEGER):
        CASE (piArea - 1) MODULO 16 + 1:
''' % mood_names[0])
for a, v in areas.items():
    ar.append('            WHEN %d THEN RETURN %d.\n' % (a, mood_names.index(v[1])))
ar.append('''            OTHERWISE UNDO, THROW NEW GridException("An area is 1 or more").
        END CASE.
    END METHOD.

    /* The colour a mood tints the ground with, and how many percent of the way the ground goes to it (0 for no tint). */
    METHOD PUBLIC STATIC XeviousTint MoodTint(INPUT piMood AS INTEGER):
        CASE piMood:
''')
for n, mn in enumerate(mood_names):
    t = moods[mn][0]
    ar.append('            WHEN %d THEN RETURN %s.\n' % (n, 'XeviousTint:' + t if t else 'XeviousTint:Ink'))
ar.append('''            OTHERWISE UNDO, THROW NEW GridException("There is no mood " + STRING(piMood)).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MoodPercent(INPUT piMood AS INTEGER):
        CASE piMood:
''')
for n, mn in enumerate(mood_names):
    ar.append('            WHEN %d THEN RETURN %d.\n' % (n, moods[mn][1]))
ar.append('''            OTHERWISE UNDO, THROW NEW GridException("There is no mood " + STRING(piMood)).
        END CASE.
    END METHOD.

END CLASS.
''')
write('XeviousAreas', ''.join(ar))
print('tints', len(names), 'sprites', len(sprites), 'tiles', len(tiles), 'areas', len(areas), 'moods', mood_names)
