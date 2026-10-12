/* How a Tetris grid is drawn: a colour for each value of the "view" layer (see ViewCodes.i), in view
   code order 0 to 10. The pieces use the familiar colours (I cyan, O yellow, T purple, S green, Z red,
   J blue, L orange), the ghost is a dim blue grey, and the panel beside the board is a shade lighter
   than the empty board. There are no glyphs: a piece is only colour. */
USING Progress.Lang.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisLook FINAL:

    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "12161B,3CC9D6,F2C14E,A06BE0,4CC38A,E5533D,4F7DE8,F0883E,2A3441,181C20,1A1F25".
    END METHOD.

    /* One character per view code, for drawing a grid as text in tests: . empty, the letters I O T S Z
       J L for the pieces, : for the ghost, | for the divider and _ for the panel. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN ".IOTSZJL:|_".
    END METHOD.

END CLASS.
