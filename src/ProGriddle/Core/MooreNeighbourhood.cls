/* The eight surrounding cells, including diagonals, in reading order:
   up left, up, up right, left, right, down left, down, down right. */
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.MooreNeighbourhood FINAL INHERITS CustomNeighbourhood:

    CONSTRUCTOR PUBLIC MooreNeighbourhood():
        SUPER(MooreXs(), MooreYs()).
    END CONSTRUCTOR.

    METHOD PRIVATE STATIC INTEGER EXTENT 8 MooreXs():
        VAR INTEGER[8] xs = [-1, 0, 1, -1, 1, -1, 0, 1].
        RETURN xs.
    END METHOD.

    METHOD PRIVATE STATIC INTEGER EXTENT 8 MooreYs():
        VAR INTEGER[8] ys = [-1, -1, -1, 0, 0, 1, 1, 1].
        RETURN ys.
    END METHOD.

END CLASS.
