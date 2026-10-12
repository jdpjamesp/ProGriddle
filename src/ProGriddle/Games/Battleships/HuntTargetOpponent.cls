/* A computer opponent that plays the way a careful person does.

   Hunting: with no unfinished hit on the board it fires at a random cell on one colour of a
   chessboard pattern (every ship is at least two cells long, so it must cross that pattern),
   preferring cells that still have an unfired neighbour, since a ship needs room.

   Targeting: once a ship has been hit it fires next to the hit. After two hits in a line it
   only extends that line, at its two ends, because ships are straight.

   Water: ships may not touch, so when a ship is sunk every cell round it is water and is never
   fired at.

   It keeps its own picture of the board in an ArrayStore with one layer, "known": 0 not fired
   at yet, 1 miss or known water, 2 hit on a ship not yet sunk, 3 part of a sunk ship. All
   randomness goes through the IRandom it is given, so a seeded one plays the same game every time. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.HuntTargetOpponent FINAL IMPLEMENTS IBattleshipsOpponent:

    DEFINE PRIVATE VARIABLE mRandom AS IRandom   NO-UNDO.
    DEFINE PRIVATE VARIABLE mKnown  AS ArrayStore NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mParity AS INTEGER   NO-UNDO.
    /* candidate cells for the next shot, and a work stack for finding a sunk ship */
    DEFINE PRIVATE VARIABLE mCandidates AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mStack      AS INTEGER NO-UNDO EXTENT.

    CONSTRUCTOR PUBLIC HuntTargetOpponent(INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("An opponent needs a random source").
        mRandom = poRandom.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC HuntTargetOpponent():
        IF VALID-OBJECT(mKnown) THEN mKnown:Dispose().
    END DESTRUCTOR.

    METHOD PUBLIC VOID Reset(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        IF piWidth = ? OR piHeight = ? OR piWidth < 2 OR piHeight < 2 OR piWidth * piHeight > 5000 THEN
            UNDO, THROW NEW GridException("An opponent needs a board of at least 2 x 2 and at most 5000 cells").
        IF VALID-OBJECT(mKnown) THEN mKnown:Dispose().
        mWidth = piWidth.
        mHeight = piHeight.
        mKnown = NEW ArrayStore(mWidth, mHeight, "known").
        EXTENT(mCandidates) = 4 * mWidth * mHeight + 4.
        EXTENT(mStack) = mWidth * mHeight.
        mParity = mRandom:NextInt(2).
    END METHOD.

    METHOD PUBLIC VOID NextShot(OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(mKnown) THEN UNDO, THROW NEW GridException("The opponent has not been reset to a board").

        /* targeting: next to a hit that is not part of a sunk ship */
        DO i = 0 TO mWidth * mHeight - 1:
            IF mKnown:GetCellAt(1, i) = 2 THEN n = AddTargets(i, n).
        END.

        /* hunting: the chessboard pattern, with room for a ship, then anything left */
        IF n = 0 THEN DO i = 0 TO mWidth * mHeight - 1:
            x = i MODULO mWidth.
            y = INTEGER(TRUNCATE(i / mWidth, 0)).
            IF mKnown:GetCellAt(1, i) = 0 AND (x + y) MODULO 2 = mParity AND HasRoom(x, y) THEN DO:
                n = n + 1.
                mCandidates[n] = i.
            END.
        END.
        IF n = 0 THEN DO i = 0 TO mWidth * mHeight - 1:
            IF mKnown:GetCellAt(1, i) = 0 THEN DO:
                n = n + 1.
                mCandidates[n] = i.
            END.
        END.
        IF n = 0 THEN UNDO, THROW NEW GridException("Every cell has been fired at").

        pick = mCandidates[mRandom:NextInt(n) + 1].
        piX = pick MODULO mWidth.
        piY = INTEGER(TRUNCATE(pick / mWidth, 0)).
    END METHOD.

    METHOD PUBLIC VOID Observe(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plHit AS LOGICAL, INPUT plSunk AS LOGICAL):
        IF NOT VALID-OBJECT(mKnown) THEN UNDO, THROW NEW GridException("The opponent has not been reset to a board").
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 board", piX, piY, mWidth, mHeight)).
        IF plSunk AND NOT plHit THEN UNDO, THROW NEW GridException("A shot that sinks a ship is a hit").
        mKnown:SetCell(1, piX, piY, (IF plHit THEN 2 ELSE 1)).
        IF plSunk THEN MarkSunk(piX, piY).
    END METHOD.

    /* What the opponent believes about a cell: 0 unknown, 1 miss or water, 2 hit, 3 sunk. For tests. */
    METHOD PUBLIC INTEGER KnownAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT VALID-OBJECT(mKnown) THEN UNDO, THROW NEW GridException("The opponent has not been reset to a board").
        RETURN mKnown:GetCell(1, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID Dispose():
        IF VALID-OBJECT(mKnown) THEN mKnown:Dispose().
        mKnown = ?.
    END METHOD.

    /* ---- private ---- */

    /* Adds the cells worth firing at because of the hit in cell piIdx and returns the new count.
       In a line of two or more hits only the two cells that extend the line count. A lone hit
       has up to four. */
    METHOD PRIVATE INTEGER AddTargets(INPUT piIdx AS INTEGER, INPUT piCount AS INTEGER):
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE a     AS INTEGER NO-UNDO.
        DEFINE VARIABLE b     AS INTEGER NO-UNDO.
        DEFINE VARIABLE found AS LOGICAL NO-UNDO.
        n = piCount.
        x = piIdx MODULO mWidth.
        y = INTEGER(TRUNCATE(piIdx / mWidth, 0)).
        IF IsHit(x - 1, y) OR IsHit(x + 1, y) THEN DO:
            a = x.
            DO WHILE IsHit(a - 1, y):
                a = a - 1.
            END.
            b = x.
            DO WHILE IsHit(b + 1, y):
                b = b + 1.
            END.
            IF IsUnknown(a - 1, y) THEN n = Push(n, y * mWidth + a - 1).
            IF IsUnknown(b + 1, y) THEN n = Push(n, y * mWidth + b + 1).
            found = TRUE.
        END.
        IF IsHit(x, y - 1) OR IsHit(x, y + 1) THEN DO:
            a = y.
            DO WHILE IsHit(x, a - 1):
                a = a - 1.
            END.
            b = y.
            DO WHILE IsHit(x, b + 1):
                b = b + 1.
            END.
            IF IsUnknown(x, a - 1) THEN n = Push(n, (a - 1) * mWidth + x).
            IF IsUnknown(x, b + 1) THEN n = Push(n, (b + 1) * mWidth + x).
            found = TRUE.
        END.
        IF NOT found THEN DO:
            IF IsUnknown(x - 1, y) THEN n = Push(n, y * mWidth + x - 1).
            IF IsUnknown(x + 1, y) THEN n = Push(n, y * mWidth + x + 1).
            IF IsUnknown(x, y - 1) THEN n = Push(n, (y - 1) * mWidth + x).
            IF IsUnknown(x, y + 1) THEN n = Push(n, (y + 1) * mWidth + x).
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE INTEGER Push(INPUT piCount AS INTEGER, INPUT piCell AS INTEGER):
        mCandidates[piCount + 1] = piCell.
        RETURN piCount + 1.
    END METHOD.

    /* The ship that includes the hit at piX, piY is sunk: it is the run of hits joined to that
       cell (two ships cannot touch, so nothing else is joined). Turn it into sunk cells and
       turn every unfired cell round it into water. */
    METHOD PRIVATE VOID MarkSunk(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE depth AS INTEGER NO-UNDO.
        DEFINE VARIABLE cur AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy  AS INTEGER NO-UNDO.
        mKnown:SetCell(1, piX, piY, 3).
        mStack[1] = piY * mWidth + piX.
        depth = 1.
        DO WHILE depth > 0:
            cur = mStack[depth].
            depth = depth - 1.
            cx = cur MODULO mWidth.
            cy = INTEGER(TRUNCATE(cur / mWidth, 0)).
            DO dy = -1 TO 1:
                DO dx = -1 TO 1:
                    IF (dx = 0 AND dy = 0) OR cx + dx < 0 OR cx + dx >= mWidth OR cy + dy < 0 OR cy + dy >= mHeight THEN NEXT.
                    IF mKnown:GetCell(1, cx + dx, cy + dy) = 0 THEN mKnown:SetCell(1, cx + dx, cy + dy, 1).
                    ELSE IF (dx = 0 OR dy = 0) AND mKnown:GetCell(1, cx + dx, cy + dy) = 2 THEN DO:
                        mKnown:SetCell(1, cx + dx, cy + dy, 3).
                        depth = depth + 1.
                        mStack[depth] = (cy + dy) * mWidth + cx + dx.
                    END.
                END.
            END.
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL IsHit(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN RETURN FALSE.
        RETURN mKnown:GetCell(1, piX, piY) = 2.
    END METHOD.

    METHOD PRIVATE LOGICAL IsUnknown(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN RETURN FALSE.
        RETURN mKnown:GetCell(1, piX, piY) = 0.
    END METHOD.

    /* True when a neighbour above, below, left or right is unfired, so a ship could fit there. */
    METHOD PRIVATE LOGICAL HasRoom(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN IsUnknown(piX - 1, piY) OR IsUnknown(piX + 1, piY) OR IsUnknown(piX, piY - 1) OR IsUnknown(piX, piY + 1).
    END METHOD.

END CLASS.
