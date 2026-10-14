/* The cells on a straight line from one cell to another, for a mouse drag that moved faster than the window was told
   about it: the pointer may have jumped several cells between two events, and every cell in between should count.

   Plan works the line out and says how many cells there are; X and Y give them in order, counting from 0. The
   line leaves out the cell it starts from (the caller has dealt with it already) and includes the cell it ends on.
   Each cell is one step along the longer side, so consecutive cells always touch, side or corner, and none is
   skipped. Plan again to reuse the object. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.CellPath FINAL:

    DEFINE PRIVATE VARIABLE mXs AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mYs AS INTEGER NO-UNDO EXTENT.

    /* How many cells the last Plan found. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Finds the cells after piX0, piY0 up to and including piX1, piY1, and returns how many there are (0 when the
       two are the same cell). Throws GridException for an unknown value. */
    METHOD PUBLIC INTEGER Plan(INPUT piX0 AS INTEGER, INPUT piY0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER):
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DEFINE VARIABLE n  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        IF piX0 = ? OR piY0 = ? OR piX1 = ? OR piY1 = ? THEN UNDO, THROW NEW GridException("A cell path needs known cells").
        dx = piX1 - piX0.
        dy = piY1 - piY0.
        n = MAXIMUM(ABSOLUTE(dx), ABSOLUTE(dy)).
        Count = n.
        IF n = 0 THEN RETURN 0.
        EXTENT(mXs) = n.
        EXTENT(mYs) = n.
        DO i = 1 TO n:
            mXs[i] = piX0 + INTEGER(ROUND(dx * i / n, 0)).
            mYs[i] = piY0 + INTEGER(ROUND(dy * i / n, 0)).
        END.
        RETURN n.
    END METHOD.

    /* The column and row of cell piIndex (0 to Count - 1) of the last path. */
    METHOD PUBLIC INTEGER X(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mXs[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER Y(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mYs[piIndex + 1].
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= Count THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A path cell is 0 to &1, not &2", Count - 1, piIndex)).
    END METHOD.

END CLASS.
