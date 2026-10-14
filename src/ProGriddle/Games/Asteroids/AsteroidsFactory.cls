/* Builds the pieces of an Asteroids game. The grid is 320 x 240 cells (4:3), an ArrayStore with three layers: "view"
   (the colour of each cell, 0xRRGGBB), "kind" (kept for the canvas, Asteroids does not use it: its collisions are
   circles) and "back" (what shows when nothing is on it, the vignette and the dust). The window shows the view layer
   in direct colour. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsFactory FINAL:

    /* The layers of an Asteroids grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view,kind,back".
    END METHOD.

    /* An empty 320 x 240 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(320, 240, Layers())).
    END METHOD.

    /* A new game, showing the title screen. poRandom makes the rocks, the saucers and the dust, so a seeded one
       gives the same game every time. */
    METHOD PUBLIC STATIC AsteroidsGame Create(INPUT poRandom AS IRandom):
        RETURN NEW AsteroidsGame(CreateGrid(), poRandom).
    END METHOD.

END CLASS.
