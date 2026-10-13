/* Builds the pieces of a Snake game. The grid is an ArrayStore with the one layer "view" (see
   ViewCodes.i): 0 empty, 1 the snake's body, 2 its head, 3 the food. The board is bounded, so
   the walls are deadly, and any size from 5 x 5 will do. 20 x 20 is the usual one. Rebuild changes the
   size of a game that is running, which is how the window changes it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeFactory FINAL:

    /* The layer of a Snake grid. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view".
    END METHOD.

    /* An empty grid of piWidth x piHeight. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN NEW Grid(NEW ArrayStore(piWidth, piHeight, Layers()), NEW BoundedTopology(), NEW VonNeumannNeighbourhood()).
    END METHOD.

    /* A new game on a board of piWidth x piHeight. poRandom places the food, so a seeded one
       gives the same game every time. */
    METHOD PUBLIC STATIC SnakeGame Create(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT poRandom AS IRandom):
        RETURN NEW SnakeGame(CreateGrid(piWidth, piHeight), poRandom).
    END METHOD.

    /* Changes the board of a game to piWidth x piHeight and starts a new game on it, which is how the
       window changes the board size. The old board is disposed. Throws GridException, and changes
       nothing, for a side outside SnakeSizes:MinSide to MaxSide. */
    METHOD PUBLIC STATIC VOID Rebuild(INPUT poGame AS SnakeGame, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("There is no game to rebuild").
        IF piWidth = ? OR piHeight = ? OR piWidth < SnakeSizes:MinSide() OR piWidth > SnakeSizes:MaxSide()
           OR piHeight < SnakeSizes:MinSide() OR piHeight > SnakeSizes:MaxSide() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A Snake board side is &1 to &2 cells", SnakeSizes:MinSide(), SnakeSizes:MaxSide())).
        poGame:Replace(CreateGrid(piWidth, piHeight)).
    END METHOD.

END CLASS.
