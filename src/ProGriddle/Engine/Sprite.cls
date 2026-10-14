/* A small picture made of cells with up to three tones, read from text: rows separated by "/", one
   character per cell. "." is empty, "#" is tone 1, "+" is tone 2 and "*" is tone 3, so the squid of the
   arcade is "...##.../..####../.######./##.##.##/########/..#..#../.#.##.#./#.#..#.#". The picture is
   immutable. Rows may differ in length (a short row is empty to the right). The game draws a sprite by
   walking its cells with CellX, CellY and CellTone and giving each tone a colour. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.Sprite FINAL:

    DEFINE PRIVATE VARIABLE mXs    AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mYs    AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTones AS INTEGER NO-UNDO EXTENT.

    /* Width of the widest row, and the number of rows. */
    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Number of cells that are not empty. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no rows, a character that is not . # + or *, or a picture with no
       cell in it. */
    CONSTRUCTOR PUBLIC Sprite(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE row  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ch   AS CHARACTER NO-UNDO.
        IF pcRows = ? OR pcRows = "" THEN UNDO, THROW NEW GridException("A sprite needs at least one row").
        Height = NUM-ENTRIES(pcRows, "/").
        DO y = 1 TO Height:
            row = ENTRY(y, pcRows, "/").
            Width = MAXIMUM(Width, LENGTH(row)).
            DO x = 1 TO LENGTH(row):
                ch = SUBSTRING(row, x, 1).
                IF ch <> "." THEN DO:
                    IF ToneOf(ch) = 0 THEN UNDO, THROW NEW GridException("A sprite cell is . # + or *, not " + ch).
                    n = n + 1.
                END.
            END.
        END.
        IF n = 0 THEN UNDO, THROW NEW GridException("A sprite needs at least one cell").
        Count = n.
        EXTENT(mXs) = n.
        EXTENT(mYs) = n.
        EXTENT(mTones) = n.
        n = 0.
        DO y = 1 TO Height:
            row = ENTRY(y, pcRows, "/").
            DO x = 1 TO LENGTH(row):
                ch = SUBSTRING(row, x, 1).
                IF ch <> "." THEN DO:
                    n = n + 1.
                    mXs[n] = x - 1.
                    mYs[n] = y - 1.
                    mTones[n] = ToneOf(ch).
                END.
            END.
        END.
    END CONSTRUCTOR.

    /* Column of cell piIndex (0 to Count - 1), counting from the left, from 0. */
    METHOD PUBLIC INTEGER CellX(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mXs[piIndex + 1].
    END METHOD.

    /* Row of cell piIndex, counting from the top, from 0. */
    METHOD PUBLIC INTEGER CellY(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mYs[piIndex + 1].
    END METHOD.

    /* Tone of cell piIndex: 1, 2 or 3. */
    METHOD PUBLIC INTEGER CellTone(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mTones[piIndex + 1].
    END METHOD.

    /* The tone at a position of the picture, 0 for an empty cell or a position outside it. */
    METHOD PUBLIC INTEGER ToneAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO Count:
            IF mXs[i] = piX AND mYs[i] = piY THEN RETURN mTones[i].
        END.
        RETURN 0.
    END METHOD.

    /* The picture as text again, in the form the constructor reads, every row as wide as the widest. */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DEFINE VARIABLE row    AS CHARACTER NO-UNDO.
        DO y = 0 TO Height - 1:
            row = "".
            DO x = 0 TO Width - 1:
                row = row + SUBSTRING(".#+*", ToneAt(x, y) + 1, 1).
            END.
            result = result + (IF y > 0 THEN "/" ELSE "") + row.
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE STATIC INTEGER ToneOf(INPUT pcChar AS CHARACTER):
        CASE pcChar:
            WHEN "#" THEN RETURN 1.
            WHEN "+" THEN RETURN 2.
            WHEN "*" THEN RETURN 3.
        END CASE.
        RETURN 0.
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= Count THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A sprite cell is 0 to &1, not &2", Count - 1, piIndex)).
    END METHOD.

END CLASS.
