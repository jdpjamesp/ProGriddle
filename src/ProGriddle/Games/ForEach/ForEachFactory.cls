/* Builds the pieces of a FOR EACH game. The grid is the maze at 8 pixels to a tile, with 24 rows of pixels above it for the score
   and 16 below it for the lives and the items: 224 x 288 for the real maze. It is an ArrayStore with one layer, "view" (the colour
   of each pixel, 0xRRGGBB), and the window shows it in direct colour. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachFactory FINAL:

    /* The layers of a FOR EACH grid. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "view".
    END METHOD.

    /* An empty grid for a maze. Throws GridException for no maze. */
    METHOD PUBLIC STATIC Grid CreateGrid(INPUT poMaze AS MazeMap):
        IF NOT VALID-OBJECT(poMaze) THEN UNDO, THROW NEW GridException("A grid needs a maze to fit").
        RETURN NEW Grid(NEW ArrayStore(poMaze:Cols * 8, poMaze:Rows * 8 + 40, Layers())).
    END METHOD.

    /* A new game on the maze of the design, showing the title screen. poRandom makes the rolled back phantoms' choices, so a
       seeded one gives the same game every time. */
    METHOD PUBLIC STATIC ForEachGame Create(INPUT poRandom AS IRandom):
        RETURN CreateOn(NEW MazeMap(ForEachMaze:Layout()), poRandom).
    END METHOD.

    /* A new game on any maze. */
    METHOD PUBLIC STATIC ForEachGame CreateOn(INPUT poMaze AS MazeMap, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poMaze) THEN UNDO, THROW NEW GridException("A game needs a maze").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A game needs a random source").
        RETURN NEW ForEachGame(CreateGrid(poMaze), poMaze, poRandom).
    END METHOD.

END CLASS.
