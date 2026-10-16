/* Builds the pieces of a Blast Buddies game. The grid is 384 x 240 cells (16:10), an ArrayStore with three layers: "view" (the colour of
   each cell, 0xRRGGBB, which is what the window shows in direct colour), "kind" (what is in the cell, for the painter) and "back" (what
   shows when nothing is on it). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesFactory FINAL:

    /* The layers of a Blast Buddies grid, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view,kind,back".
    END METHOD.

    /* An empty 384 x 240 grid. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(Terrain:Width(), Terrain:Height(), Layers())).
    END METHOD.

    /* A new game that begins with the title screen. */
    METHOD PUBLIC STATIC BlastBuddiesGame CreateWithTitle(INPUT poRandom AS IRandom, INPUT poSetup AS BuddySetup):
        RETURN NEW BlastBuddiesGame(CreateGrid(), poRandom, poSetup, TRUE).
    END METHOD.

    /* A new game. poRandom makes the land, the starting places, the names and the wind, so a seeded one gives the same game every time. */
    METHOD PUBLIC STATIC BlastBuddiesGame Create(INPUT poRandom AS IRandom, INPUT poSetup AS BuddySetup):
        RETURN NEW BlastBuddiesGame(CreateGrid(), poRandom, poSetup).
    END METHOD.

END CLASS.
