/* The 64 directions a ship can face, and the sine and cosine of each, as whole numbers so that physics does
   the same thing every time. Step 0 points straight up, steps count clockwise on the screen, and one step is
   5.625 degrees, so 16 steps is a quarter turn. Sin and Cos are scaled by 1024 (Scale). ABL has no trig
   functions, so the table is the 17 values of a quarter turn, with the rest got by symmetry. A step outside 0
   to 63 is wrapped round, so 64 is 0 and -1 is 63.

   The direction of a heading on the screen (y grows downward) is DirX = Sin and DirY = -Cos. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.Heading FINAL:

    /* sine of 0, 1 ... 16 steps, times 1024 */
    DEFINE PRIVATE STATIC VARIABLE sQuarter AS INTEGER NO-UNDO EXTENT 17.

    CONSTRUCTOR STATIC Heading():
        sQuarter[1] = 0.
        sQuarter[2] = 100.
        sQuarter[3] = 200.
        sQuarter[4] = 297.
        sQuarter[5] = 392.
        sQuarter[6] = 483.
        sQuarter[7] = 569.
        sQuarter[8] = 650.
        sQuarter[9] = 724.
        sQuarter[10] = 792.
        sQuarter[11] = 851.
        sQuarter[12] = 903.
        sQuarter[13] = 946.
        sQuarter[14] = 980.
        sQuarter[15] = 1004.
        sQuarter[16] = 1019.
        sQuarter[17] = 1024.
    END CONSTRUCTOR.

    /* How many headings there are. */
    METHOD PUBLIC STATIC INTEGER Steps():
        RETURN 64.
    END METHOD.

    /* What Sin and Cos are multiplied by: 1024 stands for 1.0. */
    METHOD PUBLIC STATIC INTEGER Scale():
        RETURN 1024.
    END METHOD.

    /* A step brought into 0 to 63. */
    METHOD PUBLIC STATIC INTEGER Wrap(INPUT piStep AS INTEGER):
        DEFINE VARIABLE s AS INTEGER NO-UNDO.
        IF piStep = ? THEN UNDO, THROW NEW GridException("A heading cannot be unknown").
        s = piStep MODULO 64.
        IF s < 0 THEN s = s + 64.
        RETURN s.
    END METHOD.

    /* The sine of a heading, times 1024: 0 for straight up, 1024 for right, -1024 for left. */
    METHOD PUBLIC STATIC INTEGER Sin(INPUT piStep AS INTEGER):
        DEFINE VARIABLE s AS INTEGER NO-UNDO.
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        s = Wrap(piStep).
        r = s MODULO 16.
        CASE INTEGER(TRUNCATE(s / 16, 0)):
            WHEN 0 THEN RETURN sQuarter[r + 1].
            WHEN 1 THEN RETURN sQuarter[17 - r].
            WHEN 2 THEN RETURN - sQuarter[r + 1].
        END CASE.
        RETURN - sQuarter[17 - r].
    END METHOD.

    /* The cosine of a heading, times 1024: 1024 for straight up, -1024 for straight down. */
    METHOD PUBLIC STATIC INTEGER Cos(INPUT piStep AS INTEGER):
        RETURN Sin(piStep + 16).
    END METHOD.

    /* The way a heading points across the screen, times 1024: right is positive. */
    METHOD PUBLIC STATIC INTEGER DirX(INPUT piStep AS INTEGER):
        RETURN Sin(piStep).
    END METHOD.

    /* The way a heading points down the screen, times 1024: up is negative. */
    METHOD PUBLIC STATIC INTEGER DirY(INPUT piStep AS INTEGER):
        RETURN - Cos(piStep).
    END METHOD.

    /* The heading that points most nearly along (piDx, piDy), which need not be a unit vector. Straight
       up for no direction at all. */
    METHOD PUBLIC STATIC INTEGER Nearest(INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE best  AS INTEGER NO-UNDO.
        DEFINE VARIABLE score AS INT64   NO-UNDO.
        DEFINE VARIABLE top   AS INT64   NO-UNDO INITIAL -1.
        IF piDx = 0 AND piDy = 0 THEN RETURN 0.
        DO i = 0 TO 63:
            score = INT64(piDx) * DirX(i) + INT64(piDy) * DirY(i).
            IF score > top THEN ASSIGN top = score
                                       best = i.
        END.
        RETURN best.
    END METHOD.

END CLASS.
