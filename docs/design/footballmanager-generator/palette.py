"""The Chalk and Floodlights palette for Gaffer (working title FootballManager): every colour, by name, grouped by use.

Tone rows: five values from highlight (1) to edge (5). Most are made by tones(); a few are set by hand and say so.
"""
from lib import hx, mix, tohex

INK = '0A0D0C'


def tones(base, hi=0.60, lo=0.30, sh=0.34, ed=0.70, ink=INK):
    b = hx(base)
    w = (255, 255, 255)
    k = hx(ink)
    return [tohex(mix(b, w, hi)), tohex(mix(b, w, lo)), tohex(b), tohex(mix(b, k, sh)), tohex(mix(b, k, ed))]


# ---- tone rows: name -> five hex values, and a note --------------------------------------------------------------
ROWS = [
    ('Home', tones('E2493E', hi=0.55, lo=0.25), 'the home kit shirt and socks: coral red (the stripes are Home Stripe, the shorts Home Shorts)'),
    ('Away', tones('3FA6E8', hi=0.55, lo=0.25), 'the away kit shirt and socks: sky blue (the hoop is Away Hoop, the shorts Away Shorts)'),
    ('Keeper', tones('F2C230', hi=0.55, lo=0.25, sh=0.30), 'both goalkeepers: marigold (plain shirt, white gloves, black shorts)'),
    ('Referee', ['8E96A8', '5C6476', '343A48', '242833', '15181F'], 'the referee: charcoal (set by hand, a lighter highlight so the shape reads on the grass)'),
    ('Gold', ['FFF4C0', 'FFDD70', 'F2B630', 'B07A1C', '5A3A10'], 'coins, the trophy, the title (set by hand): gold is money and glory'),
    ('Silver', ['FFFFFF', 'E0E6EE', 'B4BECC', '7A8698', '3E4656'], 'the cup trophy, the bank and the lower medals (set by hand)'),
    ('Wood', ['E0A868', 'C89052', '9A6634', '6E4424', '2A170C'], 'the frame round every chalkboard, the trophy plinths, the desk (set by hand)'),
    ('Ball', ['FFFFFF', 'FFFFFF', 'EEF1F4', 'C4CAD4', '4A5060'], 'the ball (set by hand: tones 1 and 2 are both white so it stays bright in the air)'),
    ('Flash', ['FFFFFF', 'FFFFFF', 'FFF8DC', 'FFE07A', 'FFB23A'], 'the goal flash: any kit row is swapped for this one for 2 frames when its player scores'),
]

TONE = {n: t for n, t, _ in ROWS}
ROW_NOTE = {n: d for n, _, d in ROWS}

# ---- single colours ------------------------------------------------------------------------------------------------
GROUPS = [
    ('The tunnel (status bar and key bar)', [
        ('Tunnel', '0C1311', 'the status bar (rows 0 to 13) and the key bar (rows 228 to 239)'),
        ('Tunnel Rule', '2A3A33', 'the 1 pixel rule under the status bar and over the key bar'),
    ]),
    ('The chalkboard (every menu screen)', [
        ('Board', '14231E', 'the board: a deep bottle green slate'),
        ('Board Stripe', '1A2C26', 'every second row of a table (a faint wipe of the board)'),
        ('Board Dust', '20332C', 'chalk dust: single baked pixels on the board, 1 in about 70'),
        ('Board Rule', '3C5449', 'a chalk rule drawn faint: under a table head, between panels'),
        ('Board Head', '0F1B17', 'the title band at the top of a board (a darker strip)'),
        ('Your Row', '3D3A16', 'the band behind your club\'s row in every table'),
        ('Cursor Row', '2E4A40', 'the band behind the row under the cursor'),
    ]),
    ('Chalk (text)', [
        ('Chalk', 'F1ECD9', 'normal text: names, numbers'),
        ('Chalk Dim', '93A89A', 'labels, column heads, key hints, things you cannot pick'),
        ('Chalk Yellow', 'FFDA5C', 'highlight: your club, the cursor, the selected item, titles'),
        ('Chalk Green', '7FE39A', 'good: money in credit, promotion, fresh, a win (W)'),
        ('Chalk Amber', 'FFAA33', 'take care: weary, a draw is not this colour, a warning that is not yet bad'),
        ('Chalk Red', 'FF6F61', 'bad: money in debt, relegation, spent, a defeat (L), injury, the sack'),
        ('Chalk Blue', '8CC8FF', 'information: morale, the cup, the week and division'),
        ('Outline', '0A0D0C', 'the 1 pixel outline behind text over the pitch, the title and the goal mouth'),
    ]),
    ('Bars', [
        ('Bar Empty', '2B3F37', 'the empty part of every bar'),
        ('Bar Tick', '6E8A7C', 'the threshold ticks under a bar (at 6 and 12 of 20)'),
        ('Bar Plain', 'D8D2BC', 'a bar with no warning level (Defence, Midfield, Attack, skill)'),
        ('Bar Plain Dark', 'A49E86', 'the dashes of a plain bar'),
        ('Fresh Dark', '3E9E5C', 'the shadow row of a fresh bar'),
        ('Weary Dark', 'B8701C', 'the gaps of a weary bar'),
        ('Spent Dark', 'A83A32', 'the checks of a spent bar'),
    ]),
    ('Night and stadium', [
        ('Night', '070B14', 'the sky over the ground (title, ground screen)'),
        ('Night Haze', '0E1626', 'the sky near the floodlights and the roof'),
        ('Star', '3E4C6A', 'a far star (baked, 1 pixel)'),
        ('Roof', '343C50', 'the stand roof and the floodlight pylons'),
        ('Roof Edge', '545E78', 'the lit edge of the roof'),
        ('Stand', '1A2030', 'the back of the stand behind the crowd'),
        ('Crowd Shadow', '111522', 'the gaps between heads in the crowd'),
        ('Crowd Face', 'D7A27E', 'a face in the crowd'),
        ('Crowd Face Dark', '9A6A4C', 'a face in the crowd, the other tone'),
        ('Crowd Red', 'B34A44', 'crowd shirts and scarves'),
        ('Crowd Cream', 'CFC5A8', 'crowd shirts and scarves'),
        ('Crowd Blue', '4A74AA', 'crowd shirts and scarves'),
        ('Crowd Gold', 'C2903A', 'crowd shirts and scarves'),
        ('Crowd Plum', '74508C', 'crowd shirts and scarves'),
        ('Wall', '262C3C', 'the wall at the front of the stand'),
        ('Hoarding', '102A44', 'the advertising boards round the pitch'),
        ('Hoarding Lit', '3E8CC4', 'the lit lettering blocks on the boards'),
        ('Hoarding Warm', 'D08A34', 'the warm lettering blocks on the boards'),
        ('Floodlight', 'FFF6D2', 'a floodlight lamp'),
        ('Flood Glow', '6E6A54', 'the glow ring round a floodlight lamp'),
        ('Flood Haze', '2A2C30', 'the outer glow ring round a floodlight'),
    ]),
    ('The pitch', [
        ('Grass A', '3E9440', 'mown stripe A'),
        ('Grass B', '378A3A', 'mown stripe B'),
        ('Run Off', '2C6E30', 'the grass outside the lines'),
        ('Line', 'E6EFDA', 'the pitch lines (slightly green so a white ball is whiter)'),
        ('Post', 'FFFFFF', 'the goal posts and crossbar'),
        ('Net', 'B8C4C0', 'the net mesh'),
        ('Net Dark', '6C7A76', 'the net in shade, and the back of the goal seen from above'),
        ('Spot', 'E6EFDA', 'the penalty and centre spots (same as Line)'),
        ('Ball Shadow', '24602A', 'the shadow under the ball and under each figure'),
        ('Trail 1', 'C4E2BC', 'the ball trail, the pixel nearest the ball'),
        ('Trail 2', '8CC488', 'the ball trail, the middle pixel'),
        ('Trail 3', '5CA45C', 'the ball trail, the far pixel'),
    ]),
    ('Kits (the fixed parts)', [
        ('Home Stripe', 'F4EEDC', 'the white stripes on the home shirt'),
        ('Home Shorts', 'F4EEDC', 'the home shorts (same as Home Stripe on purpose)'),
        ('Home Shorts Dark', 'BDB5A0', 'the shade side of the home shorts'),
        ('Away Hoop', '16305E', 'the navy hoop on the away shirt'),
        ('Away Shorts', '16305E', 'the away shorts (same as Away Hoop on purpose)'),
        ('Away Shorts Dark', '0C1C3A', 'the shade side of the away shorts'),
        ('Glove', 'F4EEDC', 'the keeper\'s gloves'),
        ('Keeper Shorts', '20242C', 'the keepers\' shorts'),
        ('Keeper Shorts Dark', '121418', 'the shade side'),
        ('Ref Collar', 'E6EFDA', 'the referee\'s collar and cuffs'),
        ('Boot', '17120E', 'every boot'),
        ('Skin 1', 'F2C6A0', 'skin, light (base)'),
        ('Skin 1 Shade', 'C99474', 'skin, light (shade)'),
        ('Skin 2', 'C98A5C', 'skin, medium (base)'),
        ('Skin 2 Shade', '9C6640', 'skin, medium (shade)'),
        ('Skin 3', '8A5634', 'skin, deep (base)'),
        ('Skin 3 Shade', '633A20', 'skin, deep (shade)'),
        ('Hair Dark', '2E1C12', 'hair, dark brown'),
        ('Hair Black', '141016', 'hair, black'),
        ('Hair Fair', 'E2B85A', 'hair, fair'),
        ('Hair Ginger', 'B8542A', 'hair, ginger'),
        ('Hair Grey', 'B4B4B0', 'hair, grey (managers and old pros)'),
    ]),
    ('Faces', [
        ('Eye', '141016', 'pupils and brows'),
        ('Eye White', 'F6F2EA', 'eye whites and teeth'),
        ('Mouth', '7A2E26', 'a mouth'),
        ('Cheek', 'E58A72', 'a ruddy cheek'),
        ('Face Back', '22342D', 'the square behind a face (one step lighter than Board)'),
    ]),
    ('Badges and cards', [
        ('Badge Edge', '0E0B0A', 'the outline of every badge'),
        ('Badge Red', 'D8433A', 'a badge colour'),
        ('Badge White', 'F3EEE0', 'a badge colour'),
        ('Badge Navy', '203A6E', 'a badge colour'),
        ('Badge Gold', 'F2B630', 'a badge colour (same as Gold 3)'),
        ('Badge Black', '22222A', 'a badge colour'),
        ('Badge Green', '2F8A4A', 'a badge colour'),
        ('Badge Purple', '7046AE', 'a badge colour'),
        ('Badge Teal', '1E9A9A', 'a badge colour'),
        ('Badge Sky', '62BAF0', 'a badge colour'),
        ('Badge Maroon', '7E2236', 'a badge colour'),
        ('Badge Brown', '8A5A2E', 'a badge colour'),
        ('Badge Orange', 'EE8A2E', 'a badge colour'),
        ('Card Yellow', 'FFD23A', 'a yellow card'),
        ('Card Red', 'E4302C', 'a red card'),
        ('Card Edge', '3A0E0C', 'the edge of a card'),
    ]),
    ('Icons', [
        ('Pos GK', 'F2C230', 'the goalkeeper icon (same as Keeper tone 3 on purpose)'),
        ('Pos DF', '62BAF0', 'the defender icon'),
        ('Pos MF', '7FE39A', 'the midfielder icon (same as Chalk Green)'),
        ('Pos FW', 'FF8A3D', 'the forward icon'),
        ('Icon Edge', '0A0D0C', 'the dark edge of an 8 x 8 icon (same as Outline)'),
        ('Plaster', 'F4E2C4', 'the injury plaster'),
        ('Plaster Dot', 'C8A880', 'the holes in the plaster'),
        ('Envelope', 'E8DCC0', 'the wage packet'),
        ('Envelope Shade', 'B0A280', 'the wage packet, flap and shade'),
        ('Brick', 'B0563C', 'the stadium icon walls and the ground screen bricks'),
        ('Brick Dark', '7A3424', 'the mortar'),
        ('Turf', '3E9440', 'the stadium icon grass (same as Grass A)'),
        ('Flame', 'FF8A3D', 'the in form flame, outer (same as Pos FW)'),
        ('Flame Core', 'FFE07A', 'the in form flame, core'),
        ('Zzz', '8CC8FF', 'the tired icon letters (same as Chalk Blue)'),
    ]),
    ('Effects', [
        ('Spark', 'FFFFFF', 'the first colour of every sparkle'),
        ('Spark Warm', 'FFF2A8', 'the second colour of a sparkle'),
        ('Spark Gold', 'FFC93C', 'the last colour of a sparkle'),
        ('Title Top', 'FFF4C0', 'the title lettering, top of the gradient (same as Gold 1)'),
        ('Title Bottom', 'F2A230', 'the title lettering, bottom of the gradient'),
        ('Title Shadow', '3A2408', 'the 2 pixel drop under the title lettering'),
    ]),
]

NAMED = {}
NOTE = {}
for _, items in GROUPS:
    for n, h, d in items:
        NAMED[n] = h
        NOTE[n] = d
for n, t, _ in ROWS:
    for i, h in enumerate(t):
        NAMED['%s %d' % (n, i + 1)] = h


def C(name):
    return hx(NAMED[name])


def count_distinct():
    return len(set(v.upper() for v in NAMED.values()))
