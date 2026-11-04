"""The Night Shift palette for FOR EACH: tone rows and named colours."""
from lib import tones, hx

ROW_SPEC = [
    ('Dibby', 'FFC234', 'Dibby, the database drum'),
    ('Brian', 'F2443C', 'Brian, the unpredictable one (mark: glasses)'),
    ('Mary', 'B566FF', 'Mary, the chaser (mark: a hair bow)'),
    ('Chip', '7EDC3C', 'Chip, the shy one (mark: an antenna with a chip)'),
    ('Rich', 'FF7AB8', 'Rich, the ambusher (mark: a top hat and heavy eyelids)'),
    ('Rollback', '3A46E8', 'a rolled back phantom'),
    ('Flash', 'E8ECFF', 'a rolled back phantom about to recover (flashes with Rollback)'),
    ('Steel', '8C98AC', 'metal on the items: the floppy disk shutter'),
]
FIXED = {}
ROWS = {}
ROW_NOTES = {}
for n, b, note in ROW_SPEC:
    ROWS[n] = tones(b)
    ROW_NOTES[n] = (b, note)
# The flash row is not made by the formula: it must stay white all the way to tone 3.
ROWS['Flash'] = [hx(v) for v in ('FFFFFF', 'F4F6FF', 'E8ECFF', 'A8B0D8', '6A7098')]
ROW_NOTES['Flash'] = ('E8ECFF', 'a rolled back phantom about to recover (fixed ramp, not the formula)')

# in role order: chaser, ambusher, unpredictable, shy
PHANTOMS = ['Mary', 'Rich', 'Brian', 'Chip']

NAMED_SPEC = [
    # the floor and the maze
    ('Floor', '06070E', 'the floor of the maze and the HUD strips (drawn once)'),
    ('Floor Stud', '111522', 'the raised floor stud at each tile corner (drawn once)'),
    ('Tunnel', '0B0F1C', 'the tunnel floor, a shade lighter so the slow stretch reads'),
    ('Glow', '0D2E30', 'wall band 1: the dim glow beside the line'),
    ('Line', '35E0CF', 'wall band 2: the bright bus line'),
    ('Gap', '082022', 'wall band 3: the dark gap'),
    ('Inner', '1C8C86', 'wall band 4: the inner line'),
    ('Fill', '061416', 'wall band 5: the inside of a wall block'),
    ('Pulse', '6CF2E2', 'the bright line on the beat of the alarm (swaps with Line)'),
    ('Door', 'FFD23A', 'the lobby door bar (stripes)'),
    ('Door Shade', '3A2C10', 'the dark stripes of the door bar'),
    ('Flash Line', 'FFFFFF', 'end of level flash: replaces Line and Inner'),
    ('Flash Glow', '2A4A5A', 'end of level flash: replaces Glow'),
    # data
    ('Bit', 'FFE6B0', 'a data bit, 2 x 2'),
    ('Token', 'FFFFFF', 'the commit token core'),
    ('Token Ring', '7CF6A8', 'the commit token ring'),
    ('Token Dim', '2E8A5A', 'the commit token in its dim blink frame'),
    # characters
    ('Eye', 'FFFFFF', 'the white of every eye'),
    ('Pupil', '1C2A8C', 'the pupil of a phantom or of Dibby'),
    ('Ink', '140C1C', 'outlines, glasses, the hat, dark details'),
    ('Mouth', '5A1A2A', 'the inside of Dibby\'s mouth'),
    ('Tongue', 'FF7A8A', 'Dibby\'s tongue'),
    ('LED', '5CFF8A', 'the status light on Dibby'),
    ('Rolledback Face', 'FFE0C8', 'the eyes and the wavy mouth of a rolled back phantom'),
    ('Flash Face', 'F2343C', 'the eyes and the mouth of a flashing phantom'),
    ('Bow', 'FFD2F0', 'Mary\'s bow highlight'),
    ('Chip Body', '2A3038', 'the little chip on Chip\'s antenna'),
    ('Chip Pin', 'C8D0DC', 'the pins of that chip'),
    ('Hat', '565A80', 'Rich\'s top hat'),
    ('Hat Top', '8A8EB8', 'the lit top and brim edge of the hat'),
    ('Hat Band', 'F2443C', 'the band of Rich\'s hat'),
    ('Angry', 'FF2A2A', 'Mary\'s pupils when she is angry (second stage)'),
    ('Steam', 'C8D4E8', 'the steam puff when Mary is angry'),
    # items
    ('Disk Blue', '3A6AE8', 'the floppy disk'),
    ('Disk Dark', '22388A', 'the floppy disk shade'),
    ('Label', 'F4F2E8', 'labels on the floppy and the tape'),
    ('Tape', '3A2A24', 'the tape on the reel'),
    ('Reel', 'E8E8F0', 'the tape reel'),
    ('Gold', 'FFD24A', 'the key, the lock, the trigger gear'),
    ('Gold Shade', 'B0782A', 'their shade'),
    ('Grid', 'E0F4FF', 'the table grid lines'),
    ('Grid Head', '3AA0E8', 'the table header row'),
    ('Grid Cell', '1A3A5A', 'the table cells'),
    ('Glass', '9AE8FF', 'the magnifier glass'),
    ('Glass Shine', 'FFFFFF', 'the shine on the glass'),
    ('Handle', '8A4A2A', 'the magnifier handle'),
    ('Rack', '3A4258', 'the server body'),
    ('Rack Edge', '7A86A0', 'the server outline and shelves'),
    ('Rack LED', '5CFF8A', 'server lights (on)'),
    ('Rack Amber', 'FFB23A', 'server lights (busy)'),
    # text and HUD
    ('Text', 'F4F2FF', 'scores and words'),
    ('Label Text', '8FA8C0', 'HUD labels, hints'),
    ('Player', 'FFD23A', '1UP, READY!, the high score note'),
    ('Over', 'FF4A4A', 'GAME OVER'),
    ('Pop Phantom', '7FF0FF', 'points for a phantom'),
    ('Pop Item', 'FF9AD0', 'points for an item'),
    ('Title Top', 'FFF2A0', 'the title gradient, top'),
    ('Title Bottom', 'FF8A2A', 'the title gradient, bottom'),
    ('Outline', '000000', 'the 1 pixel outline behind text over the maze'),
    ('Target', 'FFFFFF', 'the centre pixel of a debug target marker'),
    ('Spark', 'FFFFFF', 'sparks and the first colour of every particle'),
    ('Sheet', '1A1E2A', 'background of the sprite sheet pictures only (not in the game)'),
]
NAMED = {n: h for n, h, _ in NAMED_SPEC}


def C(name):
    return hx(NAMED[name])


def T(row, k):
    return ROWS[row][k - 1]
