/* Builds the pieces of a Tetris game. The grid the game shows is a TableStore with the one layer
   "view" on a bounded grid: the board, a divider column and a panel six cells wide. The playfield
   (settled blocks and the falling piece) is a separate TableStore the size of the board, with the layers
   locked and active, which the game builds with CreateField. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisFactory FINAL:

    /* The layer of a Tetris grid. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view".
    END METHOD.

    /* The layers of the playfield, in order. */
    METHOD PUBLIC STATIC CHARACTER FieldLayers():
        RETURN "locked,active".
    END METHOD.

    /* An empty playfield of piBoardWidth x piBoardHeight. */
    METHOD PUBLIC STATIC ICellStore CreateField(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER):
        RETURN NEW TableStore(piBoardWidth, piBoardHeight, FieldLayers()).
    END METHOD.

    /* An empty grid for a board of piBoardWidth x piBoardHeight. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER):
        RETURN NEW Grid(NEW TableStore(piBoardWidth + 7, piBoardHeight, Layers()), NEW BoundedTopology(), NEW MooreNeighbourhood()).
    END METHOD.

    /* A new game on a board of the usual 10 x 20. poRandom deals the pieces, so a seeded one deals
       the same pieces every time. */
    METHOD PUBLIC STATIC TetrisGame Create(INPUT poRandom AS IRandom):
        RETURN NEW TetrisGame(CreateGrid(10, 20), poRandom).
    END METHOD.

    /* A new game on a board of another size. */
    METHOD PUBLIC STATIC TetrisGame CreateSized(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER, INPUT poRandom AS IRandom):
        RETURN NEW TetrisGame(CreateGrid(piBoardWidth, piBoardHeight), poRandom).
    END METHOD.

END CLASS.
