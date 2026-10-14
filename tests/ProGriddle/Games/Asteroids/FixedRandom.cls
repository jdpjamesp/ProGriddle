/* A random source that always gives the same answer, so a test can make the game's luck good or bad: NextInt gives the
   value it was made with, or the highest number below the limit if that is smaller. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.FixedRandom FINAL IMPLEMENTS IRandom:

    DEFINE PRIVATE VARIABLE mValue AS INTEGER NO-UNDO.

    CONSTRUCTOR PUBLIC FixedRandom(INPUT piValue AS INTEGER):
        mValue = piValue.
    END CONSTRUCTOR.

    METHOD PUBLIC DECIMAL NextDecimal():
        RETURN 0.5.
    END METHOD.

    METHOD PUBLIC INTEGER NextInt(INPUT piBelow AS INTEGER):
        IF piBelow < 1 THEN UNDO, THROW NEW GridException("NextInt needs a limit of 1 or more").
        RETURN MINIMUM(mValue, piBelow - 1).
    END METHOD.

END CLASS.
