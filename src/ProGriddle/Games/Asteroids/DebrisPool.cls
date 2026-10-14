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

    /* The ship breaks up at (piX, piY) with the speed (piVX, piVY), pointing along heading piHeading: its five lines fly
       apart, half the ship's speed plus 0.25 to 0.45 of a cell a step away from its middle, drifting and spinning for 90
       steps in the ship debris colours, with six single cells flying off at random (40 steps) and a ring of eight sparks
       leaving from three cells out (14 steps). 19 pieces. */
    METHOD PUBLIC VOID ShipBreakup(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER, INPUT piHeading AS INTEGER):
        DEFINE VARIABLE pieces AS Outline NO-UNDO.
        DEFINE VARIABLE l      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sn     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cs     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x1     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y1     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE mx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE my     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE away   AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed  AS INTEGER NO-UNDO.
        DEFINE VARIABLE spin   AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir    AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        pieces = AsteroidsArt:ShipPieces().
        sn = Heading:Sin(piHeading).
        cs = Heading:Cos(piHeading).
        DO l = 1 TO pieces:LineCount:
            /* the ends of the line in units: its points are 64ths of a cell and the turn is times 1024, so a sixteenth */
            x1 = INTEGER(TRUNCATE((pieces:PointX(l, 1) * cs - pieces:PointY(l, 1) * sn) / 16, 0)).
            y1 = INTEGER(TRUNCATE((pieces:PointX(l, 1) * sn + pieces:PointY(l, 1) * cs) / 16, 0)).
            x2 = INTEGER(TRUNCATE((pieces:PointX(l, 2) * cs - pieces:PointY(l, 2) * sn) / 16, 0)).
            y2 = INTEGER(TRUNCATE((pieces:PointX(l, 2) * sn + pieces:PointY(l, 2) * cs) / 16, 0)).
            mx = INTEGER(TRUNCATE((x1 + x2) / 2, 0)).
            my = INTEGER(TRUNCATE((y1 + y2) / 2, 0)).
            hx = INTEGER(TRUNCATE((x2 - x1) / 2, 0)).
            hy = INTEGER(TRUNCATE((y2 - y1) / 2, 0)).
            away = Heading:Nearest(mx, my).
            speed = 1024 + mRandom:NextInt(820).
            spin = 6 + mRandom:NextInt(9).
            IF mRandom:NextInt(2) = 0 THEN spin = - spin.
            AddChip(piX + mx, piY + my,
                    INTEGER(TRUNCATE(piVX / 2, 0)) + INTEGER(TRUNCATE(Heading:DirX(away) * speed / 1024, 0)),
                    INTEGER(TRUNCATE(piVY / 2, 0)) + INTEGER(TRUNCATE(Heading:DirY(away) * speed / 1024, 0)),
                    985, 90, Heading:Nearest(hx, hy) * 16, spin, INTEGER(ROUND(SQRT(DECIMAL(hx) * hx + DECIMAL(hy) * hy), 0)), Ramp:ShipDebris).
        END.
        /* six cells in any direction, 0.4 to 0.8 of a cell a step */
        DO k = 1 TO 6:
            dir = mRandom:NextInt(64).
            speed = 1638 + mRandom:NextInt(1639).
            AddCell(piX, piY, INTEGER(TRUNCATE(Heading:DirX(dir) * speed / 1024, 0)), INTEGER(TRUNCATE(Heading:DirY(dir) * speed / 1024, 0)),
                    970, 40, Ramp:ShipDebris).
        END.
        /* the ring: eight cells 45 degrees apart from straight up, three cells out, moving out at 0.6 of a cell a step */
        DO k = 0 TO 7:
            dir = k * 8.
            AddCell(piX + INTEGER(TRUNCATE(Heading:DirX(dir) * 3 * {&UNIT} / 1024, 0)), piY + INTEGER(TRUNCATE(Heading:DirY(dir) * 3 * {&UNIT} / 1024, 0)),
                    INTEGER(TRUNCATE(Heading:DirX(dir) * 2458 / 1024, 0)), INTEGER(TRUNCATE(Heading:DirY(dir) * 2458 / 1024, 0)),
                    1000, 14, Ramp:Spark).
        END.
    END METHOD.

    /* A rock of a size (1 large, 2 medium, 3 small) bursts at (piX, piY), turned to heading piHeading and of outline
       variant piVariant. Large: ten cells at random angles (0.35 to 0.9 of a cell a step, 30 to 44 steps) and three
       chips of 3 cells that start on a vertex of the outline and move outward. Medium: eight cells (to 0.8, 24 to 36
       steps) and two chips of 2.4 cells (28 steps). Small: eight cells in an even ring from a random start, 0.75 of a
       cell a step, 16 to 22 steps. All in the rock debris colours. Throws GridException for any other size. */
    METHOD PUBLIC VOID RockBurst(INPUT piSize AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHeading AS INTEGER, INPUT piVariant AS INTEGER):
        DEFINE VARIABLE rock   AS Outline NO-UNDO.
        DEFINE VARIABLE cells  AS INTEGER NO-UNDO.
        DEFINE VARIABLE chips  AS INTEGER NO-UNDO.
        DEFINE VARIABLE fastest AS INTEGER NO-UNDO.
        DEFINE VARIABLE lifeLow AS INTEGER NO-UNDO.
        DEFINE VARIABLE lifeSpan AS INTEGER NO-UNDO.
        DEFINE VARIABLE chipHalf AS INTEGER NO-UNDO.
        DEFINE VARIABLE chipLife AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir    AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sn     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cs     AS INTEGER NO-UNDO.
        DEFINE VARIABLE v      AS INTEGER NO-UNDO.
        DEFINE VARIABLE vx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE vy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE spin   AS INTEGER NO-UNDO.
        IF piSize = ? OR piSize < 1 OR piSize > 3 THEN UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
        IF piSize = 3 THEN DO:
            dir = mRandom:NextInt(8).
            DO k = 0 TO 7:
                AddCell(piX, piY, INTEGER(TRUNCATE(Heading:DirX(dir + k * 8) * 3072 / 1024, 0)), INTEGER(TRUNCATE(Heading:DirY(dir + k * 8) * 3072 / 1024, 0)),
                        960, 16 + mRandom:NextInt(7), Ramp:RockDebris).
            END.
            RETURN.
        END.
        IF piSize = 1 THEN ASSIGN cells = 10 chips = 3 fastest = 2253 lifeLow = 30 lifeSpan = 15 chipHalf = 6144 chipLife = 36.
        ELSE ASSIGN cells = 8 chips = 2 fastest = 1844 lifeLow = 24 lifeSpan = 13 chipHalf = 4915 chipLife = 28.
        DO k = 1 TO cells:
            dir = mRandom:NextInt(64).
            speed = 1434 + mRandom:NextInt(fastest).
            AddCell(piX, piY, INTEGER(TRUNCATE(Heading:DirX(dir) * speed / 1024, 0)), INTEGER(TRUNCATE(Heading:DirY(dir) * speed / 1024, 0)),
                    970, lifeLow + mRandom:NextInt(lifeSpan), Ramp:RockDebris).
        END.
        /* the chips: from a vertex of the rock's outline (its points are 64ths of a cell, the turn is times 1024),
           moving outward, turning 2 to 4 degrees a step */
        rock = AsteroidsArt:Rock(piSize, piVariant).
        sn = Heading:Sin(piHeading).
        cs = Heading:Cos(piHeading).
        DO k = 1 TO chips:
            v = 1 + mRandom:NextInt(rock:PointCount(1)).
            vx = INTEGER(TRUNCATE((rock:PointX(1, v) * cs - rock:PointY(1, v) * sn) / 16, 0)).
            vy = INTEGER(TRUNCATE((rock:PointX(1, v) * sn + rock:PointY(1, v) * cs) / 16, 0)).
            dir = Heading:Nearest(vx, vy).
            speed = 1638 + mRandom:NextInt(1230).
            spin = 6 + mRandom:NextInt(6).
            IF mRandom:NextInt(2) = 0 THEN spin = - spin.
            AddChip(piX + vx, piY + vy, INTEGER(TRUNCATE(Heading:DirX(dir) * speed / 1024, 0)), INTEGER(TRUNCATE(Heading:DirY(dir) * speed / 1024, 0)),
                    985, chipLife, 256, spin, chipHalf, Ramp:RockDebris).
        END.
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
            IF mKind[i] = {&CELL} THEN DO:
                cx = INTEGER(TRUNCATE(mX[i] / {&UNIT}, 0)).
                cy = INTEGER(TRUNCATE(mY[i] / {&UNIT}, 0)).
                poCanvas:DrawLine(cx, cy, cx, cy, 0, colour).
            END.
            ELSE DO:
                /* the two ends, each rounded to the nearest cell like the ship's lines (halves go up) */
                h = INTEGER(TRUNCATE(mAngle[i] / 16, 0)).
                ox = INTEGER(TRUNCATE(mHalf[i] * Heading:DirX(h) / 1024, 0)).
                oy = INTEGER(TRUNCATE(mHalf[i] * Heading:DirY(h) / 1024, 0)).
                poCanvas:DrawLine(NearestCell(mX[i] - ox), NearestCell(mY[i] - oy), NearestCell(mX[i] + ox), NearestCell(mY[i] + oy), 0, colour).
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

    /* The cell nearest a position in units, halves going up. A position may be a little off the screen, so it is lifted by
       256 cells to keep the division exact. */
    METHOD PRIVATE INTEGER NearestCell(INPUT piValue AS INTEGER):
        RETURN INTEGER(TRUNCATE((piValue + 256 * {&UNIT} + {&UNIT} / 2) / {&UNIT}, 0)) - 256.
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
