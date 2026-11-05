/* Builds the pieces of a Centipede game. The grid is the 30 x 30 board of tiles, an ArrayStore with two layers: "mushroom" (the hit
   points of the mushroom in the tile, 0 for none) and "poison" (1 when a scorpion has poisoned it). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeFactory FINAL:

    /* The layers of a Centipede grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "mushroom,poison".
    END METHOD.

    /* An empty 30 x 30 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(CentipedeRules:Cols(), CentipedeRules:Rows(), Layers())).
    END METHOD.

    /* A new game, showing the title screen. poRandom places the first mushrooms and the creatures, so a seeded one gives the same
       game every time. */
    METHOD PUBLIC STATIC CentipedeGame Create(INPUT poRandom AS IRandom):
        RETURN NEW CentipedeGame(CreateGrid(), poRandom).
    END METHOD.

END CLASS.
