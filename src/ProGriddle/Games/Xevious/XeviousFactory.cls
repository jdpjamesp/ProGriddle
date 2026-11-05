/* Builds the pieces of a Xevious game. The grid is a screen of ground tiles, 14 x 16, with one layer, "ground", which the game
   itself does not use (the land is a function of the stage and the row, see XeviousMap). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousFactory FINAL:

    /* The layers of a Xevious grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "ground".
    END METHOD.

    /* An empty 14 x 16 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(XeviousRules:Cols(), 16, Layers())).
    END METHOD.

    /* A new game, showing the title screen. poRandom chooses the waves, so a seeded one gives the same game every time. */
    METHOD PUBLIC STATIC XeviousGame Create(INPUT poRandom AS IRandom):
        RETURN NEW XeviousGame(CreateGrid(), poRandom).
    END METHOD.

END CLASS.
