/* The four orthogonal cells, no diagonals, in reading order: up, left, right, down. */
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.VonNeumannNeighbourhood FINAL INHERITS CustomNeighbourhood:

    CONSTRUCTOR PUBLIC VonNeumannNeighbourhood():
        SUPER(NeighbourXs(), NeighbourYs()).
    END CONSTRUCTOR.

    METHOD PRIVATE STATIC INTEGER EXTENT 4 NeighbourXs():
        VAR INTEGER[4] xs = [0, -1, 1, 0].
        RETURN xs.
    END METHOD.

    METHOD PRIVATE STATIC INTEGER EXTENT 4 NeighbourYs():
        VAR INTEGER[4] ys = [-1, 0, 0, 1].
        RETURN ys.
    END METHOD.

END CLASS.
