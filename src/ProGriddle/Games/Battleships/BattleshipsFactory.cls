/* Builds the pieces of a Battleships game. The store is a TableStore with the layers ship, shot,
   mark and view, as named fields, on a bounded grid. The grid holds both boards: the computer's
   waters, one divider column, and the player's fleet, so it is 2 * width + 1 cells wide. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsFactory FINAL:

    /* The layers of a Battleships grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "ship,shot,mark,view".
    END METHOD.

    /* An empty grid for two boards of piBoardWidth x piBoardHeight. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER):
        RETURN NEW Grid(NEW TableStore(2 * piBoardWidth + 1, piBoardHeight, Layers()), NEW BoundedTopology(), NEW MooreNeighbourhood()).
    END METHOD.

    /* A new game ready for the player to place a fleet. poRandom places the fleets, so a seeded
       one gives the same placements every time. poOpponent chooses the computer's shots. */
    METHOD PUBLIC STATIC BattleshipsGame Create(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER, INPUT pcFleet AS CHARACTER,
                                                INPUT poRandom AS IRandom, INPUT poOpponent AS IBattleshipsOpponent):
        RETURN NEW BattleshipsGame(CreateGrid(piBoardWidth, piBoardHeight), pcFleet, poRandom, poOpponent).
    END METHOD.

END CLASS.
