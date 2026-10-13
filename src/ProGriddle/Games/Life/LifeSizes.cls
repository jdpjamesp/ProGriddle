/* The board sizes the Life window offers, and the text form "100 x 70" they are written in. The
   largest offered is 300 x 200, the most the window keeps responsive; the settings may still ask
   for any size from 5 to 400 (life.width and life.height). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeSizes FINAL:

    /* The smallest side of a board, in cells. */
    METHOD PUBLIC STATIC INTEGER MinSide():
        RETURN 5.
    END METHOD.

    /* The largest side of a board, in cells. */
    METHOD PUBLIC STATIC INTEGER MaxSide():
        RETURN 400.
    END METHOD.

    /* The sizes offered, comma separated, smallest first. */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "50 x 35,75 x 50,100 x 70,150 x 100,200 x 140,300 x 200".
    END METHOD.

    /* "100 x 70" for a width and a height. */
    METHOD PUBLIC STATIC CHARACTER Label(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN BoardSizes:Label(piWidth, piHeight).
    END METHOD.

    /* The width in a size such as "100 x 70". Throws GridException when the text is not a size or
       is outside MinSide to MaxSide. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcSize AS CHARACTER):
        RETURN BoardSizes:WidthOf(pcSize, MinSide(), MaxSide()).
    END METHOD.

    /* The height in a size such as "100 x 70", with the same checks. */
    METHOD PUBLIC STATIC INTEGER HeightOf(INPUT pcSize AS CHARACTER):
        RETURN BoardSizes:HeightOf(pcSize, MinSide(), MaxSide()).
    END METHOD.

END CLASS.
