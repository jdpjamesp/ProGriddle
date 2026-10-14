/* Draws outlines on a PixelCanvas: it turns a shape to one of the 64 headings, puts it at a position, rounds
   every point to the nearest cell and joins the points with lines. A position is in 256ths of a cell, so an
   object can drift a fraction of a cell a frame and the maths stays whole numbers. The shape's own points are
   64ths of a cell and the sine table is scaled by 1024, so the sum is exact and the same on every machine.

   Rotation is the usual (x cos a - y sin a, x sin a + y cos a) with y growing down, so heading 0 leaves a
   shape as it is (its nose, at a negative y, pointing up) and heading 16 turns it a quarter turn clockwise.
   After the position is added each coordinate is rounded to the nearest cell, halves going up.

   DrawWrapped is for a board whose edges join up: a shape that comes within its extent of an edge is drawn
   again on the other side, up to four times in a corner. The pen keeps no picture of its own, it needs a
   canvas to draw on, and it allocates nothing while drawing. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.OutlinePen FINAL:

    /* adds a whole number of cells so every value is positive before it is divided and rounded */
    &SCOPED-DEFINE LIFT 1024

    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mWx     AS INTEGER     NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mWy     AS INTEGER     NO-UNDO EXTENT 64.

    CONSTRUCTOR PUBLIC OutlinePen(INPUT poCanvas AS PixelCanvas):
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("A pen needs a canvas").
        mCanvas = poCanvas.
    END CONSTRUCTOR.

    /* Draws an outline with its origin at (piX, piY), in 256ths of a cell, turned to heading piHeading (any whole
       number, it is wrapped to 0 to 63). Every cell takes piKind and piColour. piOffsetX and piOffsetY move the
       whole picture by whole cells: draw the same shape four times with offsets of one cell for a halo. */
    METHOD PUBLIC VOID Draw(INPUT poOutline AS Outline, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHeading AS INTEGER,
                            INPUT piKind AS INTEGER, INPUT piColour AS INTEGER, INPUT piOffsetX AS INTEGER, INPUT piOffsetY AS INTEGER):
        DEFINE VARIABLE sn    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cs    AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseX AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseY AS INTEGER NO-UNDO.
        DEFINE VARIABLE l     AS INTEGER NO-UNDO.
        DEFINE VARIABLE p     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE lx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ly    AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poOutline) THEN UNDO, THROW NEW GridException("There is no outline to draw").
        sn = Heading:Sin(piHeading).
        cs = Heading:Cos(piHeading).
        /* position in 65536ths of a cell, with the rounding half and the lift added */
        baseX = piX * 256 + 32768 + {&LIFT} * 65536.
        baseY = piY * 256 + 32768 + {&LIFT} * 65536.
        DO l = 1 TO poOutline:LineCount:
            n = poOutline:PointCount(l).
            IF n > 64 THEN UNDO, THROW NEW GridException("A pen draws lines of up to 64 points, not " + STRING(n)).
            DO p = 1 TO n:
                lx = poOutline:PointX(l, p).
                ly = poOutline:PointY(l, p).
                mWx[p] = INTEGER(TRUNCATE((baseX + lx * cs - ly * sn) / 65536, 0)) - {&LIFT} + piOffsetX.
                mWy[p] = INTEGER(TRUNCATE((baseY + lx * sn + ly * cs) / 65536, 0)) - {&LIFT} + piOffsetY.
                IF p > 1 THEN mCanvas:DrawLine(mWx[p - 1], mWy[p - 1], mWx[p], mWy[p], piKind, piColour).
            END.
            IF poOutline:IsClosed(l) THEN mCanvas:DrawLine(mWx[n], mWy[n], mWx[1], mWy[1], piKind, piColour).
        END.
    END METHOD.

    /* The same, and again on the far side of every edge it comes within piExtent cells of (the board wraps).
       Give the extent as a distance that covers the whole shape from its origin. */
    METHOD PUBLIC VOID DrawWrapped(INPUT poOutline AS Outline, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHeading AS INTEGER,
                                   INPUT piExtent AS INTEGER, INPUT piKind AS INTEGER, INPUT piColour AS INTEGER,
                                   INPUT piOffsetX AS INTEGER, INPUT piOffsetY AS INTEGER):
        DEFINE VARIABLE w     AS INTEGER NO-UNDO.
        DEFINE VARIABLE h     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE shiftX AS INTEGER NO-UNDO.
        DEFINE VARIABLE shiftY AS INTEGER NO-UNDO.
        w = mCanvas:Width.
        h = mCanvas:Height.
        cx = INTEGER(TRUNCATE((piX + 128 + {&LIFT} * 256) / 256, 0)) - {&LIFT}.
        cy = INTEGER(TRUNCATE((piY + 128 + {&LIFT} * 256) / 256, 0)) - {&LIFT}.
        Draw(poOutline, piX, piY, piHeading, piKind, piColour, piOffsetX, piOffsetY).
        shiftX = (IF cx - piExtent < 0 THEN w ELSE IF cx + piExtent >= w THEN - w ELSE 0).
        shiftY = (IF cy - piExtent < 0 THEN h ELSE IF cy + piExtent >= h THEN - h ELSE 0).
        IF shiftX <> 0 THEN Draw(poOutline, piX, piY, piHeading, piKind, piColour, piOffsetX + shiftX, piOffsetY).
        IF shiftY <> 0 THEN Draw(poOutline, piX, piY, piHeading, piKind, piColour, piOffsetX, piOffsetY + shiftY).
        IF shiftX <> 0 AND shiftY <> 0 THEN Draw(poOutline, piX, piY, piHeading, piKind, piColour, piOffsetX + shiftX, piOffsetY + shiftY).
    END METHOD.

END CLASS.
