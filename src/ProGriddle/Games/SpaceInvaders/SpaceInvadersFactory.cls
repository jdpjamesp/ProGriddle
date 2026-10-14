/* Builds the pieces of a Space Invaders game. The grid is the arcade's 224 x 256, an ArrayStore with three layers:
   "view" (the colour of each cell, 0xRRGGBB), "kind" (what is in it, see the CellKind enum) and "back" (what shows when
   nothing is on it). The window shows the view layer in direct colour. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersFactory FINAL:

    /* The layers of a Space Invaders grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view,kind,back".
    END METHOD.

    /* An empty 224 x 256 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(224, 256, Layers())).
    END METHOD.

    /* A new game, showing the title screen. poRandom makes the sparks and the marks on the shields, so a
       seeded one gives the same game every time. */
    METHOD PUBLIC STATIC SpaceInvadersGame Create(INPUT poRandom AS IRandom):
        RETURN NEW SpaceInvadersGame(CreateGrid(), poRandom).
    END METHOD.

END CLASS.
