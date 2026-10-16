/* Sine for the painter of Blast Buddies, which needs it for the far hills and the clouds. ABL has no trigonometry, so it is worked out
   from the 64 step table of Heading, with a straight line between the steps, which is close enough for a picture (a pixel off). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyMath FINAL:

    /* The sine of an angle in radians, as a decimal between -1 and 1. */
    METHOD PUBLIC STATIC DECIMAL SinRad(INPUT pdRadians AS DECIMAL):
        DEFINE VARIABLE t  AS DECIMAL NO-UNDO.
        DEFINE VARIABLE i0 AS INTEGER NO-UNDO.
        DEFINE VARIABLE f  AS DECIMAL NO-UNDO.
        /* a full turn of 2 pi radians is 64 steps */
        t = pdRadians * 10.185916357881302.
        t = t - 64 * TRUNCATE(t / 64, 0).
        IF t < 0 THEN t = t + 64.
        i0 = INTEGER(TRUNCATE(t, 0)).
        f = t - i0.
        RETURN (Heading:Sin(i0) * (1 - f) + Heading:Sin(i0 + 1) * f) / Heading:Scale().
    END METHOD.

END CLASS.
