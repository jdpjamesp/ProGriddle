/* Immutable set of cell offsets. Shared by Life patterns, Battleships ships and
   Tetris pieces.

   Offsets are always normalised: the smallest x and the smallest y are both 0,
   so a shape placed at (x, y) has its top left bounding box corner there.
   Rotate and Flip return new, normalised shapes and never change this one.
   Rotation is clockwise as seen on screen, where y grows downwards.

   Text form (Parse and ToString): rows separated by "/", "X" is a cell and
   any other character is empty. For example "XX/.X". */
USING Progress.Lang.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.Shape FINAL:

    DEFINE PRIVATE VARIABLE mXs AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mYs AS INTEGER NO-UNDO EXTENT.

    /* Number of cells in the shape. */
    DEFINE PUBLIC PROPERTY Size AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Bounding box size. */
    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Builds a shape from parallel arrays of x and y offsets. The arrays are copied,
       so later changes to them do not affect the shape. Throws GridException when
       the arrays are empty, differ in length, or name the same cell twice. */
    CONSTRUCTOR PUBLIC Shape(INPUT piXs AS INTEGER EXTENT, INPUT piYs AS INTEGER EXTENT):
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE j    AS INTEGER NO-UNDO.
        DEFINE VARIABLE minX AS INTEGER NO-UNDO.
        DEFINE VARIABLE minY AS INTEGER NO-UNDO.
        DEFINE VARIABLE maxX AS INTEGER NO-UNDO.
        DEFINE VARIABLE maxY AS INTEGER NO-UNDO.

        IF EXTENT(piXs) = ? OR EXTENT(piYs) = ? THEN
            UNDO, THROW NEW GridException("Shape offsets must not be empty").
        IF EXTENT(piXs) <> EXTENT(piYs) THEN
            UNDO, THROW NEW GridException("Shape x and y offset arrays differ in length").

        Size = EXTENT(piXs).
        EXTENT(mXs) = Size.
        EXTENT(mYs) = Size.
        DO i = 1 TO Size:
            mXs[i] = piXs[i].
            mYs[i] = piYs[i].
        END.

        DO i = 1 TO Size - 1:
            DO j = i + 1 TO Size:
                IF mXs[i] = mXs[j] AND mYs[i] = mYs[j] THEN
                    UNDO, THROW NEW GridException(SUBSTITUTE("Shape names cell (&1,&2) twice", mXs[i], mYs[i])).
            END.
        END.

        minX = mXs[1].
        minY = mYs[1].
        maxX = mXs[1].
        maxY = mYs[1].
        DO i = 2 TO Size:
            minX = MINIMUM(minX, mXs[i]).
            minY = MINIMUM(minY, mYs[i]).
            maxX = MAXIMUM(maxX, mXs[i]).
            maxY = MAXIMUM(maxY, mYs[i]).
        END.
        DO i = 1 TO Size:
            mXs[i] = mXs[i] - minX.
            mYs[i] = mYs[i] - minY.
        END.
        Width  = maxX - minX + 1.
        Height = maxY - minY + 1.
    END CONSTRUCTOR.

    /* Builds a shape from text such as "XX/.X". Throws GridException when there is no cell. */
    METHOD PUBLIC STATIC Shape Parse(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE xs  AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys  AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE r   AS INTEGER NO-UNDO.
        DEFINE VARIABLE c   AS INTEGER NO-UNDO.
        DEFINE VARIABLE row AS CHARACTER NO-UNDO.

        DO r = 1 TO NUM-ENTRIES(pcRows, "/"):
            row = ENTRY(r, pcRows, "/").
            DO c = 1 TO LENGTH(row):
                IF SUBSTRING(row, c, 1) = "X" THEN n = n + 1.
            END.
        END.
        IF n = 0 THEN UNDO, THROW NEW GridException("Shape text has no cells: " + pcRows).

        EXTENT(xs) = n.
        EXTENT(ys) = n.
        n = 0.
        DO r = 1 TO NUM-ENTRIES(pcRows, "/"):
            row = ENTRY(r, pcRows, "/").
            DO c = 1 TO LENGTH(row):
                IF SUBSTRING(row, c, 1) = "X" THEN DO:
                    n = n + 1.
                    xs[n] = c - 1.
                    ys[n] = r - 1.
                END.
            END.
        END.
        RETURN NEW Shape(xs, ys).
    END METHOD.

    /* X offset of cell piIndex, for piIndex from 1 to Size. */
    METHOD PUBLIC INTEGER OffsetX(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mXs[piIndex].
    END METHOD.

    /* Y offset of cell piIndex, for piIndex from 1 to Size. */
    METHOD PUBLIC INTEGER OffsetY(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mYs[piIndex].
    END METHOD.

    /* True when the shape has a cell at the given offset. */
    METHOD PUBLIC LOGICAL Contains(INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO Size:
            IF mXs[i] = piDx AND mYs[i] = piDy THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* New shape turned 90 degrees clockwise. */
    METHOD PUBLIC Shape Rotate():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        EXTENT(xs) = Size.
        EXTENT(ys) = Size.
        DO i = 1 TO Size:
            xs[i] = - mYs[i].
            ys[i] = mXs[i].
        END.
        RETURN NEW Shape(xs, ys).
    END METHOD.

    /* New shape mirrored left to right. */
    METHOD PUBLIC Shape Flip():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        EXTENT(xs) = Size.
        EXTENT(ys) = Size.
        DO i = 1 TO Size:
            xs[i] = - mXs[i].
            ys[i] = mYs[i].
        END.
        RETURN NEW Shape(xs, ys).
    END METHOD.

    /* Two shapes are equal when they have the same cells, whatever their order. */
    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        DEFINE VARIABLE other AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, Shape) THEN RETURN FALSE.
        other = CAST(poOther, Shape).
        IF other:Size <> Size THEN RETURN FALSE.
        DO i = 1 TO Size:
            IF NOT other:Contains(mXs[i], mYs[i]) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* Text form that Parse accepts, for example "XX/.X". */
    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DO y = 0 TO Height - 1:
            IF y > 0 THEN result = result + "/".
            DO x = 0 TO Width - 1:
                result = result + (IF Contains(x, y) THEN "X" ELSE ".").
            END.
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > Size THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Shape cell &1 is outside 1 to &2", piIndex, Size)).
    END METHOD.

END CLASS.
