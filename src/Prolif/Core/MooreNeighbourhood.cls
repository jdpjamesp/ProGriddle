/* The eight surrounding cells, including diagonals, in reading order:
   up left, up, up right, left, right, down left, down, down right. */
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.MooreNeighbourhood FINAL INHERITS CustomNeighbourhood:

    CONSTRUCTOR PUBLIC MooreNeighbourhood():
        SUPER(MooreXs(), MooreYs()).
    END CONSTRUCTOR.

    METHOD PRIVATE STATIC INTEGER EXTENT 8 MooreXs():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 8 INITIAL [-1, 0, 1, -1, 1, -1, 0, 1].
        RETURN xs.
    END METHOD.

    METHOD PRIVATE STATIC INTEGER EXTENT 8 MooreYs():
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 8 INITIAL [-1, -1, -1, 0, 0, 1, 1, 1].
        RETURN ys.
    END METHOD.

END CLASS.
