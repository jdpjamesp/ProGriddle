/* How a Battleships grid is drawn: a colour and a glyph for each value of the "view" layer (see
   the ViewCode enum). The lists are in view code order, 0 to 13. The computer's waters are a blue grey
   and the player's own sea a darker teal, so the two boards are told apart at a glance. A miss
   is a dot, a hit a cross, a marked cell a wave, and the computer's most recent shot is lit. */
USING Progress.Lang.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsLook FINAL:

    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "2E4F6E,2E4F6E,1F3346,8F2D2D,5A1F24,6B7684,24464A,7F93A8,B3261E,5A1F24,1C3236,3E6C73,E5533D,181C20".
    END METHOD.

    /* U+2248 is a wave, U+2022 a dot and U+2716 a cross. They are code points because a string here
       cannot hold them. */
    METHOD PUBLIC STATIC CHARACTER Glyphs():
        RETURN ",U+2248,U+2022,U+2716,U+2716,,,,U+2716,U+2716,U+2022,U+2022,U+2716,".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER GlyphColors():
        RETURN "FFFFFF,9CC3E4,7FA3C2,FFD7D7,FF8A8A,FFFFFF,FFFFFF,FFFFFF,FFD7D7,FF8A8A,6F9AA0,FFFFFF,FFFFFF,FFFFFF".
    END METHOD.

    /* One character per view code, for drawing a grid as text in tests: # unknown water, = marked
       water, o miss, * hit, X sunk, @ revealed ship, . your water, S your ship, ! your hit, & your
       sunk ship, a comma for a miss on you, a semicolon for the latest miss on you, + the latest
       hit on you, | the divider. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN "#=o*X@.S!&,;+|".
    END METHOD.

END CLASS.
