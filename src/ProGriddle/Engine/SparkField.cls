/* A handful of sparks: single pixels that fly on a straight line, fall under gravity, change through four colours over their
   life and go. A spark is born at a place and a time with a speed in pixels a frame (60 frames a second), a gravity in pixels
   a frame a frame, a life in frames and four colours, which it wears for a quarter of its life each. Where it is at a time is
   worked out from those and the time (x = x0 + vx f, y = y0 + vy f + g f f / 2, with f the frames since it was born), so the
   field keeps nothing from frame to frame, and a game that is paused or that draws late still shows each spark in the right
   place. Draw puts the live ones on a canvas that is in a batch. When the field is full Add says so and the spark is
   dropped: sparks are a luxury. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SparkField FINAL:

    DEFINE PRIVATE VARIABLE mSlots  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mX      AS DECIMAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mY      AS DECIMAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mVX     AS DECIMAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mVY     AS DECIMAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mGravity AS DECIMAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mBorn   AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mLife   AS INTEGER NO-UNDO EXTENT.
    /* four colours a spark, one after another: slot * 4 + stage + 1 */
    DEFINE PRIVATE VARIABLE mColour AS INTEGER NO-UNDO EXTENT.
    /* the time the spark last needed (its death), and whether the slot holds one */
    DEFINE PRIVATE VARIABLE mUsed   AS LOGICAL NO-UNDO EXTENT.

    /* Throws GridException for a field of no slots. */
    CONSTRUCTOR PUBLIC SparkField(INPUT piSlots AS INTEGER):
        IF piSlots = ? OR piSlots < 1 THEN UNDO, THROW NEW GridException("A spark field has 1 slot or more, not " + STRING(piSlots)).
        mSlots = piSlots.
        EXTENT(mX) = piSlots.
        EXTENT(mY) = piSlots.
        EXTENT(mVX) = piSlots.
        EXTENT(mVY) = piSlots.
        EXTENT(mGravity) = piSlots.
        EXTENT(mBorn) = piSlots.
        EXTENT(mLife) = piSlots.
        EXTENT(mColour) = piSlots * 4.
        EXTENT(mUsed) = piSlots.
    END CONSTRUCTOR.

    /* Adds a spark that was born at (piX, piY) at time piBornMs, moving (pdVX, pdVY) pixels a frame, falling pdGravity pixels a
       frame a frame, living piLife frames, in four colours. False when the field is full of live sparks (the time is not
       known here, so a spark that has gone is made room for by Draw or CountAt). Throws GridException for a life under 1. */
    METHOD PUBLIC LOGICAL Add(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT pdVX AS DECIMAL, INPUT pdVY AS DECIMAL, INPUT pdGravity AS DECIMAL,
                              INPUT piBornMs AS INTEGER, INPUT piLife AS INTEGER, INPUT piC1 AS INTEGER, INPUT piC2 AS INTEGER, INPUT piC3 AS INTEGER, INPUT piC4 AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piLife = ? OR piLife < 1 THEN UNDO, THROW NEW GridException("A spark lives 1 frame or more, not " + STRING(piLife)).
        DO i = 1 TO mSlots:
            IF mUsed[i] THEN NEXT.
            mUsed[i] = TRUE.
            mX[i] = piX.
            mY[i] = piY.
            mVX[i] = pdVX.
            mVY[i] = pdVY.
            mGravity[i] = pdGravity.
            mBorn[i] = piBornMs.
            mLife[i] = piLife.
            mColour[(i - 1) * 4 + 1] = piC1.
            mColour[(i - 1) * 4 + 2] = piC2.
            mColour[(i - 1) * 4 + 3] = piC3.
            mColour[(i - 1) * 4 + 4] = piC4.
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* Every spark gone. */
    METHOD PUBLIC VOID Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mSlots:
            mUsed[i] = FALSE.
        END.
    END METHOD.

    /* How many sparks are alive at a time (born, and not yet at the end of their life). A spark that is over is let go; one
       that has not been born yet is kept but not counted. */
    METHOD PUBLIC INTEGER CountAt(INPUT piNowMs AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE f AS DECIMAL NO-UNDO.
        DO i = 1 TO mSlots:
            IF NOT mUsed[i] THEN NEXT.
            f = (piNowMs - mBorn[i]) * 0.06.
            IF f >= mLife[i] THEN mUsed[i] = FALSE.
            ELSE IF f >= 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* Puts every spark that is alive at a time on a canvas that is in a batch, as one pixel in its colour of the moment. Pixels off
       the canvas are skipped. A spark that is over is let go, and one that has not been born yet is not drawn. */
    METHOD PUBLIC VOID Draw(INPUT poCanvas AS PixelCanvas, INPUT piNowMs AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE f      AS DECIMAL NO-UNDO.
        DEFINE VARIABLE px     AS INTEGER NO-UNDO.
        DEFINE VARIABLE py     AS INTEGER NO-UNDO.
        DEFINE VARIABLE stage  AS INTEGER NO-UNDO.
        DO i = 1 TO mSlots:
            IF NOT mUsed[i] THEN NEXT.
            f = (piNowMs - mBorn[i]) * 0.06.
            IF f >= mLife[i] THEN DO:
                mUsed[i] = FALSE.
                NEXT.
            END.
            IF f < 0 THEN NEXT.
            px = INTEGER(ROUND(mX[i] + mVX[i] * f, 0)).
            py = INTEGER(ROUND(mY[i] + mVY[i] * f + mGravity[i] * f * f / 2, 0)).
            stage = MINIMUM(3, INTEGER(TRUNCATE(f * 4 / mLife[i], 0))).
            poCanvas:DrawLine(px, py, px, py, 0, mColour[(i - 1) * 4 + stage + 1]).
        END.
    END METHOD.

END CLASS.
