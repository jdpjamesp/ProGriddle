/* The board sizes the Life window offers, and the text form "100 x 70" they are written in. The
   largest offered is 300 x 200, the most the window keeps responsive; the settings may still ask
   for any size from 5 to 400 (life.width and life.height). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
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
        RETURN SUBSTITUTE("&1 x &2", piWidth, piHeight).
    END METHOD.

    /* The width in a size such as "100 x 70". Throws GridException when the text is not a size or
       is outside MinSide to MaxSide. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcSize AS CHARACTER):
        RETURN Part(pcSize, 1).
    END METHOD.

    /* The height in a size such as "100 x 70", with the same checks. */
    METHOD PUBLIC STATIC INTEGER HeightOf(INPUT pcSize AS CHARACTER):
        RETURN Part(pcSize, 2).
    END METHOD.

    METHOD PRIVATE STATIC INTEGER Part(INPUT pcSize AS CHARACTER, INPUT piPart AS INTEGER):
        DEFINE VARIABLE sideCells AS INTEGER NO-UNDO.
        IF pcSize = ? OR NUM-ENTRIES(TRIM(pcSize), "x") <> 2 THEN
            UNDO, THROW NEW GridException("A board size looks like 100 x 70, not " + STRING(pcSize)).
        sideCells = INTEGER(TRIM(ENTRY(piPart, TRIM(pcSize), "x"))) NO-ERROR.
        IF ERROR-STATUS:ERROR OR sideCells = ? THEN
            UNDO, THROW NEW GridException("A board size looks like 100 x 70, not " + pcSize).
        IF sideCells < MinSide() OR sideCells > MaxSide() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A board side is &1 to &2 cells, not &3", MinSide(), MaxSide(), sideCells)).
        RETURN sideCells.
    END METHOD.

END CLASS.
