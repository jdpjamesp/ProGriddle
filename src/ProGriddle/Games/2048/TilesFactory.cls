/* Builds the pieces of a 2048 game. The grid is an ArrayStore with the one layer "view", which holds
   for each cell the power of two of its tile: 0 for an empty cell, 1 for a 2, 2 for a 4, 3 for an 8
   and so on (see TilesLook). The board is any size from 2 x 2, and 4 x 4 is the usual one. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.2048.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesFactory FINAL:

    /* The layer of a 2048 grid. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view".
    END METHOD.

    /* An empty grid of piWidth x piHeight. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN NEW Grid(NEW ArrayStore(piWidth, piHeight, Layers())).
    END METHOD.

    /* A new game on a board of piWidth x piHeight, with two tiles on it. poRandom chooses the
       tiles, so a seeded one gives the same game every time. */
    METHOD PUBLIC STATIC TilesGame Create(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT poRandom AS IRandom):
        RETURN NEW TilesGame(CreateGrid(piWidth, piHeight), poRandom).
    END METHOD.

END CLASS.
