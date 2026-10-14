/* The word ASTEROIDS on the title screen, drawn the way a vector monitor would draw it: a beam traces the nine
   letters one after another, ten ticks for each, from tick 20 to tick 110, at 12 cells a tick along the strokes. Behind
   the beam a stroke stands in the title colour with a one cell glow, and the beam itself is a bright 2 x 2 head. The
   letters come from AsteroidsArt (the glyph of each) and are placed as the design says: x at 40, 68, 96, 124, 152, 180,
   208, 232 and 260, y at 58. The picture is a function of the tick, so nothing is kept between frames. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.TitleTrace FINAL:

    &SCOPED-DEFINE LETTERS 9
    &SCOPED-DEFINE TOP 58
    &SCOPED-DEFINE BEGIN 20
    &SCOPED-DEFINE PER-LETTER 10
    &SCOPED-DEFINE PER-TICK 12

    DEFINE PRIVATE VARIABLE mXs    AS INTEGER NO-UNDO EXTENT {&LETTERS}.
    DEFINE PRIVATE VARIABLE mGlyph AS Outline NO-UNDO EXTENT {&LETTERS}.
    DEFINE PRIVATE VARIABLE mHeadX AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeadY AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeadOn AS LOGICAL NO-UNDO.

    CONSTRUCTOR PUBLIC TitleTrace():
        DEFINE VARIABLE i  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE xs AS CHARACTER NO-UNDO.
        xs = "40,68,96,124,152,180,208,232,260".
        DO i = 1 TO {&LETTERS}:
            mXs[i] = INTEGER(ENTRY(i, xs)).
            mGlyph[i] = AsteroidsArt:Glyph(SUBSTRING("ASTEROIDS", i, 1)).
        END.
    END CONSTRUCTOR.

    /* True from tick 110 on: every letter is drawn and the beam is gone. */
    METHOD PUBLIC LOGICAL IsDone(INPUT piTick AS INTEGER):
        RETURN piTick >= {&BEGIN} + {&PER-LETTER} * {&LETTERS}.
    END METHOD.

    /* Draws the title as it is at a tick (counted from the start of the title screen) with DrawLine, so call it in a
       batch. Every glow goes down first, then every stroke, then the heads, so a glow never covers a line. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas, INPUT piTick AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE halo  AS INTEGER NO-UNDO.
        DEFINE VARIABLE core  AS INTEGER NO-UNDO.
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        DEFINE VARIABLE shown AS INTEGER NO-UNDO.
        DEFINE VARIABLE reach AS INTEGER NO-UNDO.
        halo = AsteroidsLook:Colour(Palette:TitleHalo).
        core = AsteroidsLook:Colour(Palette:TitleCore).
        white = AsteroidsLook:Colour(Palette:Flash).
        /* how many letters have started */
        shown = MINIMUM({&LETTERS}, INTEGER(TRUNCATE((piTick - {&BEGIN} + {&PER-LETTER} - 1) / {&PER-LETTER}, 0))).
        IF piTick <= {&BEGIN} OR shown < 1 THEN RETURN.
        DO i = 1 TO shown:
            reach = (piTick - ({&BEGIN} + {&PER-LETTER} * (i - 1))) * {&PER-TICK}.
            Stroke(poCanvas, i, reach, -1, 0, halo).
            Stroke(poCanvas, i, reach, 1, 0, halo).
            Stroke(poCanvas, i, reach, 0, -1, halo).
            Stroke(poCanvas, i, reach, 0, 1, halo).
        END.
        DO i = 1 TO shown:
            reach = (piTick - ({&BEGIN} + {&PER-LETTER} * (i - 1))) * {&PER-TICK}.
            Stroke(poCanvas, i, reach, 0, 0, core).
        END.
        DO i = 1 TO shown:
            reach = (piTick - ({&BEGIN} + {&PER-LETTER} * (i - 1))) * {&PER-TICK}.
            Stroke(poCanvas, i, reach, 0, 0, -1).
            IF mHeadOn THEN DO:
                poCanvas:DrawLine(mHeadX, mHeadY, mHeadX + 1, mHeadY, 0, white).
                poCanvas:DrawLine(mHeadX, mHeadY + 1, mHeadX + 1, mHeadY + 1, 0, white).
            END.
        END.
    END METHOD.

    /* The strokes of a letter as far as the beam has got (piReach cells along them, in the order they are drawn),
       moved by whole cells piOffsetX and piOffsetY, in a colour, or only walked when the colour is -1. Leaves where
       the beam is in mHeadX and mHeadY, and whether it is still on its way in mHeadOn. */
    METHOD PRIVATE VOID Stroke(INPUT poCanvas AS PixelCanvas, INPUT piLetter AS INTEGER, INPUT piReach AS INTEGER,
                               INPUT piOffsetX AS INTEGER, INPUT piOffsetY AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE g      AS Outline NO-UNDO.
        DEFINE VARIABLE l      AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE p      AS INTEGER NO-UNDO.
        DEFINE VARIABLE q      AS INTEGER NO-UNDO.
        DEFINE VARIABLE ax     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE ay     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE bx     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE by2    AS DECIMAL NO-UNDO.
        DEFINE VARIABLE span   AS DECIMAL NO-UNDO.
        DEFINE VARIABLE togo   AS DECIMAL NO-UNDO.
        DEFINE VARIABLE part   AS DECIMAL NO-UNDO.
        g = mGlyph[piLetter].
        togo = piReach.
        mHeadOn = FALSE.
        DO l = 1 TO g:LineCount:
            n = g:PointCount(l).
            DO p = 1 TO (IF g:IsClosed(l) THEN n ELSE n - 1):
                q = (IF p = n THEN 1 ELSE p + 1).
                ax = mXs[piLetter] + DECIMAL(g:PointX(l, p)) / 64.
                ay = {&TOP} + DECIMAL(g:PointY(l, p)) / 64.
                bx = mXs[piLetter] + DECIMAL(g:PointX(l, q)) / 64.
                by2 = {&TOP} + DECIMAL(g:PointY(l, q)) / 64.
                span = SQRT((bx - ax) * (bx - ax) + (by2 - ay) * (by2 - ay)).
                IF togo >= span THEN DO:
                    IF piColour >= 0 THEN
                        poCanvas:DrawLine(INTEGER(ROUND(ax, 0)) + piOffsetX, INTEGER(ROUND(ay, 0)) + piOffsetY,
                                          INTEGER(ROUND(bx, 0)) + piOffsetX, INTEGER(ROUND(by2, 0)) + piOffsetY, 0, piColour).
                    togo = togo - span.
                END.
                ELSE DO:
                    part = (IF span > 0 THEN togo / span ELSE 0).
                    bx = ax + (bx - ax) * part.
                    by2 = ay + (by2 - ay) * part.
                    IF piColour >= 0 THEN
                        poCanvas:DrawLine(INTEGER(ROUND(ax, 0)) + piOffsetX, INTEGER(ROUND(ay, 0)) + piOffsetY,
                                          INTEGER(ROUND(bx, 0)) + piOffsetX, INTEGER(ROUND(by2, 0)) + piOffsetY, 0, piColour).
                    mHeadX = INTEGER(ROUND(bx, 0)).
                    mHeadY = INTEGER(ROUND(by2, 0)).
                    mHeadOn = TRUE.
                    RETURN.
                END.
            END.
        END.
    END METHOD.

END CLASS.
