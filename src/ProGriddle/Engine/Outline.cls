/* A shape made of lines: one or more polylines, each a list of points that are joined in order, and closed
   (the last point joins back to the first) or open. It is read from text, polylines separated by "/", each one
   the word closed or open and then its points as x,y pairs separated by spaces, in cells, with decimals if you
   like and no space inside a pair. The ship is
       "closed 0,-6 3.6,3 1.6,1.6 -1.6,1.6 -3.6,3 / open 0,-4.4 0,1.6"
   The origin of a shape is its centre, x grows to the right and y grows down, so a shape that points up has
   its nose at a negative y. An outline is immutable. Points are kept as whole numbers, 64 to a cell (Scale),
   so that drawing is exact and the same every time. A closed line needs 3 points or more, an open one 2. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.Outline FINAL:

    DEFINE PRIVATE VARIABLE mStart  AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mCount  AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mClosed AS LOGICAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mXs     AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mYs     AS INTEGER NO-UNDO EXTENT.

    /* Number of polylines. */
    DEFINE PUBLIC PROPERTY LineCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Number of points in all of them. */
    DEFINE PUBLIC PROPERTY PointTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Number of straight segments drawn: a closed line of n points has n, an open one n - 1. */
    DEFINE PUBLIC PROPERTY SegmentCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The distance of the point furthest from the origin, in 64ths of a cell. */
    DEFINE PUBLIC PROPERTY MaxRadius AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for text that is not an outline. */
    CONSTRUCTOR PUBLIC Outline(INPUT pcSpec AS CHARACTER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE total  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE lineText AS CHARACTER NO-UNDO.
        DEFINE VARIABLE tokens AS CHARACTER NO-UNDO EXTENT.
        DEFINE VARIABLE word   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pair   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE d      AS DECIMAL   NO-UNDO.
        IF pcSpec = ? OR TRIM(pcSpec) = "" THEN UNDO, THROW NEW GridException("An outline needs at least one line").
        LineCount = NUM-ENTRIES(pcSpec, "/").
        EXTENT(mStart) = LineCount.
        EXTENT(mCount) = LineCount.
        EXTENT(mClosed) = LineCount.
        /* first pass: how many points in all */
        DO i = 1 TO LineCount:
            n = Tokens(ENTRY(i, pcSpec, "/")) - 1.
            IF n < 0 THEN n = 0.
            total = total + n.
        END.
        EXTENT(mXs) = MAXIMUM(1, total).
        EXTENT(mYs) = MAXIMUM(1, total).
        total = 0.
        DO i = 1 TO LineCount:
            lineText = ENTRY(i, pcSpec, "/").
            n = Tokens(lineText).
            IF n < 1 THEN UNDO, THROW NEW GridException("An outline has an empty line in it").
            word = Token(lineText, 1).
            IF word = "closed" THEN mClosed[i] = TRUE.
            ELSE IF word = "open" THEN mClosed[i] = FALSE.
            ELSE UNDO, THROW NEW GridException("An outline line starts with closed or open, not " + word).
            mStart[i] = total.
            mCount[i] = n - 1.
            IF mCount[i] < (IF mClosed[i] THEN 3 ELSE 2) THEN
                UNDO, THROW NEW GridException(SUBSTITUTE("A &1 line needs at least &2 points, not &3", word, (IF mClosed[i] THEN 3 ELSE 2), mCount[i])).
            DO j = 2 TO n:
                pair = Token(lineText, j).
                IF NUM-ENTRIES(pair, ",") <> 2 THEN UNDO, THROW NEW GridException("An outline point is x,y, not " + pair).
                total = total + 1.
                mXs[total] = Fixed(ENTRY(1, pair, ",")).
                mYs[total] = Fixed(ENTRY(2, pair, ",")).
                d = SQRT(DECIMAL(mXs[total]) * mXs[total] + DECIMAL(mYs[total]) * mYs[total]).
                MaxRadius = MAXIMUM(MaxRadius, INTEGER(ROUND(d, 0))).
            END.
            SegmentCount = SegmentCount + (IF mClosed[i] THEN mCount[i] ELSE mCount[i] - 1).
        END.
        PointTotal = total.
    END CONSTRUCTOR.

    /* How many 64ths of a cell make a cell. */
    METHOD PUBLIC STATIC INTEGER Scale():
        RETURN 64.
    END METHOD.

    /* Draws the outline on a canvas with its origin at (piX, piY), in 256ths of a cell, turned to heading
       piHeading (any whole number, it is wrapped to 0 to 63), every cell taking piKind and piColour. Each point
       is turned, moved and rounded to the nearest cell (halves go up), then joined to the one before it. piOffsetX
       and piOffsetY move the whole picture by whole cells. This is the work of OutlinePen, which adds wrapping
       at the edges of the board: it is here because it reads the points directly, which is a good deal faster
       than asking for each one. A line of more than 64 points is refused. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHeading AS INTEGER,
                              INPUT piKind AS INTEGER, INPUT piColour AS INTEGER, INPUT piOffsetX AS INTEGER, INPUT piOffsetY AS INTEGER):
        DEFINE VARIABLE sn     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cs     AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseX  AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseY  AS INTEGER NO-UNDO.
        DEFINE VARIABLE l      AS INTEGER NO-UNDO.
        DEFINE VARIABLE p      AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE origin AS INTEGER NO-UNDO.
        DEFINE VARIABLE v      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevX  AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevY  AS INTEGER NO-UNDO.
        DEFINE VARIABLE startX AS INTEGER NO-UNDO.
        DEFINE VARIABLE startY AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("There is no canvas to draw on").
        sn = Heading:Sin(piHeading).
        cs = Heading:Cos(piHeading).
        /* the position in 65536ths of a cell, with the rounding half and a lift of 1024 cells so that
           every value is positive and can be divided exactly with MODULO */
        baseX = piX * 256 + 32768 + 67108864.
        baseY = piY * 256 + 32768 + 67108864.
        DO l = 1 TO LineCount:
            n = mCount[l].
            IF n > 64 THEN UNDO, THROW NEW GridException("A line is drawn up to 64 points, not " + STRING(n)).
            origin = mStart[l].
            DO p = 1 TO n:
                v = baseX + mXs[origin + p] * cs - mYs[origin + p] * sn.
                x = (v - v MODULO 65536) / 65536 - 1024 + piOffsetX.
                v = baseY + mXs[origin + p] * sn + mYs[origin + p] * cs.
                y = (v - v MODULO 65536) / 65536 - 1024 + piOffsetY.
                IF p = 1 THEN ASSIGN startX = x
                                     startY = y.
                ELSE poCanvas:DrawLine(prevX, prevY, x, y, piKind, piColour).
                ASSIGN prevX = x
                       prevY = y.
            END.
            IF mClosed[l] THEN poCanvas:DrawLine(prevX, prevY, startX, startY, piKind, piColour).
        END.
    END METHOD.

    /* The same, with the shape stretched before it is turned: piScaleAcross percent of its width and piScaleAlong
       percent of its length (100 and 100 draw it as it is, 100 and 400 make it four times as long and no wider, 0
       squeezes it flat). Along and across are the shape's own, so they turn with it. For a ship stretching into
       hyperspace. */
    METHOD PUBLIC VOID DrawScaledTo(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHeading AS INTEGER,
                                    INPUT piScaleAcross AS INTEGER, INPUT piScaleAlong AS INTEGER,
                                    INPUT piKind AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE sn     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cs     AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseX  AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseY  AS INTEGER NO-UNDO.
        DEFINE VARIABLE l      AS INTEGER NO-UNDO.
        DEFINE VARIABLE p      AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE origin AS INTEGER NO-UNDO.
        DEFINE VARIABLE lx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ly     AS INTEGER NO-UNDO.
        DEFINE VARIABLE v      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevX  AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevY  AS INTEGER NO-UNDO.
        DEFINE VARIABLE startX AS INTEGER NO-UNDO.
        DEFINE VARIABLE startY AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("There is no canvas to draw on").
        IF piScaleAcross = ? OR piScaleAcross < 0 OR piScaleAlong = ? OR piScaleAlong < 0 THEN
            UNDO, THROW NEW GridException("A scale is 0 percent or more").
        sn = Heading:Sin(piHeading).
        cs = Heading:Cos(piHeading).
        baseX = piX * 256 + 32768 + 67108864.
        baseY = piY * 256 + 32768 + 67108864.
        DO l = 1 TO LineCount:
            n = mCount[l].
            IF n > 64 THEN UNDO, THROW NEW GridException("A line is drawn up to 64 points, not " + STRING(n)).
            origin = mStart[l].
            DO p = 1 TO n:
                lx = INTEGER(TRUNCATE(mXs[origin + p] * piScaleAcross / 100, 0)).
                ly = INTEGER(TRUNCATE(mYs[origin + p] * piScaleAlong / 100, 0)).
                v = baseX + lx * cs - ly * sn.
                x = (v - v MODULO 65536) / 65536 - 1024.
                v = baseY + lx * sn + ly * cs.
                y = (v - v MODULO 65536) / 65536 - 1024.
                IF p = 1 THEN ASSIGN startX = x
                                     startY = y.
                ELSE poCanvas:DrawLine(prevX, prevY, x, y, piKind, piColour).
                ASSIGN prevX = x
                       prevY = y.
            END.
            IF mClosed[l] THEN poCanvas:DrawLine(prevX, prevY, startX, startY, piKind, piColour).
        END.
    END METHOD.

    /* True when the last point of line piLine (1 to LineCount) joins back to the first. */
    METHOD PUBLIC LOGICAL IsClosed(INPUT piLine AS INTEGER):
        CheckLine(piLine).
        RETURN mClosed[piLine].
    END METHOD.

    /* Number of points of a line. */
    METHOD PUBLIC INTEGER PointCount(INPUT piLine AS INTEGER):
        CheckLine(piLine).
        RETURN mCount[piLine].
    END METHOD.

    /* The x of point piPoint (1 to PointCount) of a line, in 64ths of a cell. */
    METHOD PUBLIC INTEGER PointX(INPUT piLine AS INTEGER, INPUT piPoint AS INTEGER):
        CheckPoint(piLine, piPoint).
        RETURN mXs[mStart[piLine] + piPoint].
    END METHOD.

    /* The y of point piPoint of a line, in 64ths of a cell. */
    METHOD PUBLIC INTEGER PointY(INPUT piLine AS INTEGER, INPUT piPoint AS INTEGER):
        CheckPoint(piLine, piPoint).
        RETURN mYs[mStart[piLine] + piPoint].
    END METHOD.

    METHOD PRIVATE VOID CheckLine(INPUT piLine AS INTEGER):
        IF piLine = ? OR piLine < 1 OR piLine > LineCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("An outline line is 1 to &1, not &2", LineCount, piLine)).
    END METHOD.

    METHOD PRIVATE VOID CheckPoint(INPUT piLine AS INTEGER, INPUT piPoint AS INTEGER):
        CheckLine(piLine).
        IF piPoint = ? OR piPoint < 1 OR piPoint > mCount[piLine] THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A point of that line is 1 to &1, not &2", mCount[piLine], piPoint)).
    END METHOD.

    /* The number of words in a piece of text separated by spaces, not counting empty ones. */
    METHOD PRIVATE STATIC INTEGER Tokens(INPUT pcText AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(TRIM(pcText), " "):
            IF ENTRY(i, TRIM(pcText), " ") <> "" THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* Word number piIndex of a piece of text separated by spaces, not counting empty ones. */
    METHOD PRIVATE STATIC CHARACTER Token(INPUT pcText AS CHARACTER, INPUT piIndex AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(TRIM(pcText), " "):
            IF ENTRY(i, TRIM(pcText), " ") <> "" THEN DO:
                n = n + 1.
                IF n = piIndex THEN RETURN ENTRY(i, TRIM(pcText), " ").
            END.
        END.
        RETURN "".
    END METHOD.

    /* A number such as -3.6 as a whole number of 64ths. It is read digit by digit, so the way the machine
       writes decimals makes no difference. */
    METHOD PRIVATE STATIC INTEGER Fixed(INPUT pcNumber AS CHARACTER):
        DEFINE VARIABLE negative AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE whole    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE frac     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE num    AS DECIMAL   NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER   NO-UNDO.
        IF pcNumber BEGINS "-" THEN ASSIGN negative = TRUE
                                           pcNumber = SUBSTRING(pcNumber, 2).
        IF NUM-ENTRIES(pcNumber, ".") > 2 THEN UNDO, THROW NEW GridException("An outline number is not " + pcNumber).
        whole = ENTRY(1, pcNumber, ".").
        frac = (IF NUM-ENTRIES(pcNumber, ".") = 2 THEN ENTRY(2, pcNumber, ".") ELSE "").
        IF whole = "" AND frac = "" THEN UNDO, THROW NEW GridException("An outline number is missing").
        DO i = 1 TO LENGTH(whole):
            IF INDEX("0123456789", SUBSTRING(whole, i, 1)) = 0 THEN UNDO, THROW NEW GridException("An outline number is not " + pcNumber).
        END.
        DO i = 1 TO LENGTH(frac):
            IF INDEX("0123456789", SUBSTRING(frac, i, 1)) = 0 THEN UNDO, THROW NEW GridException("An outline number is not " + pcNumber).
        END.
        IF whole <> "" THEN num = DECIMAL(whole).
        IF frac <> "" THEN num = num + DECIMAL(frac) / EXP(10, LENGTH(frac)).
        num = ROUND(num * 64, 0).
        RETURN (IF negative THEN - INTEGER(num) ELSE INTEGER(num)).
    END METHOD.

END CLASS.
