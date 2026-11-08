/* Builds the pieces of a Cuber game. The grid is the 7 x 7 square the pyramid sits in (a lamp at row r and column c is the cell
   at column c, row r - 1), an ArrayStore with one layer: "lamp", 0 for a lamp not reached, 1 for half way, 2 for lit. The cells
   with a column past their row are never used. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberFactory FINAL:

    /* The layers of a Cuber grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "lamp".
    END METHOD.

    /* An empty 7 x 7 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(CuberRules:Rows(), CuberRules:Rows(), Layers())).
    END METHOD.

    /* A new game, showing the title screen. poRandom decides the halos and the enemies' hops, so a seeded one gives the same game
       every time. */
    METHOD PUBLIC STATIC CuberGame Create(INPUT poRandom AS IRandom):
        RETURN NEW CuberGame(CreateGrid(), poRandom).
    END METHOD.

END CLASS.
