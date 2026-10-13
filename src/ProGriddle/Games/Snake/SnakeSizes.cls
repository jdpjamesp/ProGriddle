/* The board sizes the Snake window offers, and the limits on a board side. The largest offered is
   40 x 40, which is also the largest the settings may ask for (snake.width and snake.height): a
   bigger board makes the cells too small to see. */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeSizes FINAL:

    /* The smallest side of a board, in cells. */
    METHOD PUBLIC STATIC INTEGER MinSide():
        RETURN 5.
    END METHOD.

    /* The largest side of a board, in cells. */
    METHOD PUBLIC STATIC INTEGER MaxSide():
        RETURN 40.
    END METHOD.

    /* The sizes offered, comma separated, smallest first. */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "10 x 10,15 x 15,20 x 20,30 x 20,30 x 30,40 x 30,40 x 40".
    END METHOD.

    /* "20 x 20" for a width and a height. */
    METHOD PUBLIC STATIC CHARACTER Label(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN BoardSizes:Label(piWidth, piHeight).
    END METHOD.

    /* The width in a size such as "30 x 20". Throws GridException when the text is not a size or is
       outside MinSide to MaxSide. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcSize AS CHARACTER):
        RETURN BoardSizes:WidthOf(pcSize, MinSide(), MaxSide()).
    END METHOD.

    /* The height in a size such as "30 x 20", with the same checks. */
    METHOD PUBLIC STATIC INTEGER HeightOf(INPUT pcSize AS CHARACTER):
        RETURN BoardSizes:HeightOf(pcSize, MinSide(), MaxSide()).
    END METHOD.

END CLASS.
