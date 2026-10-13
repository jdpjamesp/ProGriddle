/* The text form of a board size, "100 x 70", for the board size drop down lists of the games
   (Life, Snake). A game keeps its own list of the sizes it offers and its own limits, and uses
   this to write a size and to read one back, checking it is a size and inside the limits. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.BoardSizes FINAL:

    /* "100 x 70" for a width and a height. */
    METHOD PUBLIC STATIC CHARACTER Label(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN SUBSTITUTE("&1 x &2", piWidth, piHeight).
    END METHOD.

    /* The width in a size such as "100 x 70". Throws GridException when the text is not a size or
       a side is outside piMin to piMax. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcSize AS CHARACTER, INPUT piMin AS INTEGER, INPUT piMax AS INTEGER):
        RETURN Part(pcSize, 1, piMin, piMax).
    END METHOD.

    /* The height in a size such as "100 x 70", with the same checks. */
    METHOD PUBLIC STATIC INTEGER HeightOf(INPUT pcSize AS CHARACTER, INPUT piMin AS INTEGER, INPUT piMax AS INTEGER):
        RETURN Part(pcSize, 2, piMin, piMax).
    END METHOD.

    METHOD PRIVATE STATIC INTEGER Part(INPUT pcSize AS CHARACTER, INPUT piPart AS INTEGER, INPUT piMin AS INTEGER, INPUT piMax AS INTEGER):
        DEFINE VARIABLE sideCells AS INTEGER NO-UNDO.
        IF pcSize = ? OR NUM-ENTRIES(TRIM(pcSize), "x") <> 2 THEN
            UNDO, THROW NEW GridException("A board size looks like 100 x 70, not " + STRING(pcSize)).
        sideCells = INTEGER(TRIM(ENTRY(piPart, TRIM(pcSize), "x"))) NO-ERROR.
        IF ERROR-STATUS:ERROR OR sideCells = ? THEN
            UNDO, THROW NEW GridException("A board size looks like 100 x 70, not " + pcSize).
        IF sideCells < piMin OR sideCells > piMax THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A board side is &1 to &2 cells, not &3", piMin, piMax, sideCells)).
        RETURN sideCells.
    END METHOD.

END CLASS.
