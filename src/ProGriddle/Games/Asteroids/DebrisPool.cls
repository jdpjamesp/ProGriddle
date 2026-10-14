/* The debris of Asteroids: a fixed pool of 48 pieces that fly apart when something breaks, slow down, and fade
   through a ramp of colours until their life is over. A piece is either a single cell or a chip, a short line that
   also spins about its middle. Positions and speeds are in 4096ths of a cell (and 4096ths of a cell a step), the
   same units as the game, an angle is in 16ths of a heading (1024 to a full turn), and the drag of a piece is
   a number of thousandths of its speed that it keeps each step (970 is a drag of 0.97). The screen wraps.

   The pool allocates nothing after it is built. AddCell and AddChip say whether there was room: effects are
   a luxury, so a full pool just drops the piece instead of throwing. The random source is for the recipes that
   build whole bursts (ship, rock and saucer break ups). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.DebrisPool FINAL:

    &SCOPED-DEFINE SLOTS 48
    &SCOPED-DEFINE UNIT 4096
    &SCOPED-DEFINE FREE 0
    &SCOPED-DEFINE CELL 1
    &SCOPED-DEFINE CHIP 2

    DEFINE PRIVATE VARIABLE mRandom AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mKind   AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mX      AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mY      AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVX     AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVY     AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mDrag   AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mAge    AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mLife   AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mAngle  AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mSpin   AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mHalf   AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mRamp   AS Ramp    NO-UNDO EXTENT {&SLOTS}.

    /* How many pieces are flying. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&SLOTS}:
                IF mKind[i] <> {&FREE} THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* A pool for a screen of piWidth by piHeight cells. */
    CONSTRUCTOR PUBLIC DebrisPool(INPUT poRandom AS IRandom, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Debris needs a random source").
        IF piWidth = ? OR piWidth < 1 OR piHeight = ? OR piHeight < 1 THEN UNDO, THROW NEW GridException("Debris needs a screen of 1 cell or more").
        mRandom = poRandom.
        mWidth = piWidth * {&UNIT}.
        mHeight = piHeight * {&UNIT}.
    END CONSTRUCTOR.

    /* How many pieces the pool holds. */
    METHOD PUBLIC STATIC INTEGER Capacity():
        RETURN {&SLOTS}.
    END METHOD.

    /* Every piece gone. */
    METHOD PUBLIC VOID Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            mKind[i] = {&FREE}.
        END.
    END METHOD.

    /* True when a slot (0 to 47) holds a piece. */
    METHOD PUBLIC LOGICAL Alive(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mKind[piSlot + 1] <> {&FREE}.
    END METHOD.

    /* Where a piece is, in whole cells. */
    METHOD PUBLIC INTEGER X(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN INTEGER(TRUNCATE(mX[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    METHOD PUBLIC INTEGER Y(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN INTEGER(TRUNCATE(mY[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    /* The speed of a piece across the screen, in 4096ths of a cell a step. */
    METHOD PUBLIC INTEGER VX(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVX[piSlot + 1].
    END METHOD.

    /* The colour a piece is drawn in now: its step of its ramp, from 0 at birth to the last step as its life runs out. */
    METHOD PUBLIC INTEGER ColourOf(INPUT piSlot AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE steps AS INTEGER NO-UNDO.
        CheckSlot(piSlot).
        i = piSlot + 1.
        IF mKind[i] = {&FREE} THEN UNDO, THROW NEW GridException("Debris slot " + STRING(piSlot) + " is empty").
        steps = AsteroidsLook:RampSteps(mRamp[i]).
        RETURN AsteroidsLook:RampColour(mRamp[i], MINIMUM(steps - 1, INTEGER(TRUNCATE(mAge[i] * steps / mLife[i], 0)))).
    END METHOD.

    /* A single cell at (piX, piY) moving at (piVX, piVY) a step, keeping piDrag thousandths of its speed each step, for
       piLife steps, in the colours of a ramp. False when the pool is full. Throws GridException for a life under 1 or
       no ramp. */
    METHOD PUBLIC LOGICAL AddCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER,
                                  INPUT piDrag AS INTEGER, INPUT piLife AS INTEGER, INPUT poRamp AS Ramp):
        RETURN Admit({&CELL}, piX, piY, piVX, piVY, piDrag, piLife, 0, 0, 0, poRamp).
    END METHOD.

    /* A chip: a line piHalf (4096ths of a cell) each way from its middle at (piX, piY), pointing along angle piAngle
       (16ths of a heading) and turning by piSpin of them a step. The rest as for a cell. */
    METHOD PUBLIC LOGICAL AddChip(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER,
                                  INPUT piDrag AS INTEGER, INPUT piLife AS INTEGER, INPUT piAngle AS INTEGER, INPUT piSpin AS INTEGER,
                                  INPUT piHalf AS INTEGER, INPUT poRamp AS Ramp):
        RETURN Admit({&CHIP}, piX, piY, piVX, piVY, piDrag, piLife, piAngle, piSpin, piHalf, poRamp).
    END METHOD.

    /* One step: every piece moves, slows, turns and ages, and the ones whose life is over go. */
    METHOD PUBLIC VOID Step():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            IF mKind[i] = {&FREE} THEN NEXT.
            mX[i] = Wrap(mX[i] + mVX[i], mWidth).
            mY[i] = Wrap(mY[i] + mVY[i], mHeight).
            mVX[i] = INTEGER(TRUNCATE(mVX[i] * mDrag[i] / 1000, 0)).
            mVY[i] = INTEGER(TRUNCATE(mVY[i] * mDrag[i] / 1000, 0)).
            mAngle[i] = (mAngle[i] + mSpin[i]) MODULO 1024.
            IF mAngle[i] < 0 THEN mAngle[i] = mAngle[i] + 1024.
            mAge[i] = mAge[i] + 1.
            IF mAge[i] >= mLife[i] THEN mKind[i] = {&FREE}.
        END.
    END METHOD.

    /* Draws every piece with DrawLine (so call it in a batch): a cell is a line of one cell, a chip a line across its
       middle. Core colour only, no glow. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE steps  AS INTEGER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ox     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE h      AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            IF mKind[i] = {&FREE} THEN NEXT.
            steps = AsteroidsLook:RampSteps(mRamp[i]).
            colour = AsteroidsLook:RampColour(mRamp[i], MINIMUM(steps - 1, INTEGER(TRUNCATE(mAge[i] * steps / mLife[i], 0)))).
            cx = INTEGER(TRUNCATE(mX[i] / {&UNIT}, 0)).
            cy = INTEGER(TRUNCATE(mY[i] / {&UNIT}, 0)).
            IF mKind[i] = {&CELL} THEN poCanvas:DrawLine(cx, cy, cx, cy, 0, colour).
            ELSE DO:
                h = INTEGER(TRUNCATE(mAngle[i] / 16, 0)).
                ox = INTEGER(TRUNCATE(mHalf[i] * Heading:DirX(h) / 1024 / {&UNIT}, 0)).
                oy = INTEGER(TRUNCATE(mHalf[i] * Heading:DirY(h) / 1024 / {&UNIT}, 0)).
                poCanvas:DrawLine(cx - ox, cy - oy, cx + ox, cy + oy, 0, colour).
            END.
        END.
    END METHOD.

    /* Puts a piece in the first free slot. */
    METHOD PRIVATE LOGICAL Admit(INPUT piKind AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER,
                               INPUT piDrag AS INTEGER, INPUT piLife AS INTEGER, INPUT piAngle AS INTEGER, INPUT piSpin AS INTEGER,
                               INPUT piHalf AS INTEGER, INPUT poRamp AS Ramp):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piLife = ? OR piLife < 1 THEN UNDO, THROW NEW GridException("A piece of debris lives 1 step or more, not " + STRING(piLife)).
        IF NOT VALID-OBJECT(poRamp) THEN UNDO, THROW NEW GridException("A piece of debris needs a ramp of colours").
        DO i = 1 TO {&SLOTS}:
            IF mKind[i] <> {&FREE} THEN NEXT.
            mKind[i] = piKind.
            mX[i] = Wrap(piX, mWidth).
            mY[i] = Wrap(piY, mHeight).
            mVX[i] = piVX.
            mVY[i] = piVY.
            mDrag[i] = piDrag.
            mAge[i] = 0.
            mLife[i] = piLife.
            mAngle[i] = piAngle MODULO 1024.
            IF mAngle[i] < 0 THEN mAngle[i] = mAngle[i] + 1024.
            mSpin[i] = piSpin.
            mHalf[i] = piHalf.
            mRamp[i] = poRamp.
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* A position brought back onto the screen. */
    METHOD PRIVATE INTEGER Wrap(INPUT piValue AS INTEGER, INPUT piSize AS INTEGER):
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        v = piValue MODULO piSize.
        IF v < 0 THEN v = v + piSize.
        RETURN v.
    END METHOD.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&SLOTS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A debris slot is 0 to &1, not &2", {&SLOTS} - 1, piSlot)).
    END METHOD.

END CLASS.
