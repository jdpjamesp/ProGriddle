/* Builds the pieces of a Minesweeper game. The store is a TableStore with the layers mine,
   revealed, flag, adjacent and view, as named fields, on a bounded board with Moore (eight
   cell) neighbours. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperFactory FINAL:

    /* The layers of a Minesweeper board, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "mine,revealed,flag,adjacent,view".
    END METHOD.

    /* An empty board of the right shape. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN NEW Grid(NEW TableStore(piWidth, piHeight, Layers()), NEW BoundedTopology(), NEW MooreNeighbourhood()).
    END METHOD.

    /* A new game, ready for a first click. poRandom places the mines, so a seeded one gives
       the same board every time. poClock should tick once a second. */
    METHOD PUBLIC STATIC MinesweeperGame Create(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT piMines AS INTEGER,
                                                INPUT poRandom AS IRandom, INPUT poClock AS IClock):
        RETURN NEW MinesweeperGame(CreateGrid(piWidth, piHeight), piMines, poRandom, poClock).
    END METHOD.

END CLASS.
