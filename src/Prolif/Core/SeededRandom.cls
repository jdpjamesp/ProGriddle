/* A small linear congruential generator: the same seed always gives the same sequence, on
   every machine. It is fast and good enough for games and tests, not for security.
   x(next) = (x * 1103515245 + 12345) modulo 2^31. */
USING Progress.Lang.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.SeededRandom FINAL IMPLEMENTS IRandom:

    DEFINE PRIVATE VARIABLE mState AS INT64 NO-UNDO.

    /* Any whole number is a valid seed. */
    CONSTRUCTOR PUBLIC SeededRandom(INPUT piSeed AS INT64):
        mState = ABSOLUTE(piSeed) MODULO 2147483648.
    END CONSTRUCTOR.

    METHOD PUBLIC DECIMAL NextDecimal():
        mState = (mState * 1103515245 + 12345) MODULO 2147483648.
        RETURN DECIMAL(mState) / 2147483648.
    END METHOD.

    METHOD PUBLIC INTEGER NextInt(INPUT piBelow AS INTEGER):
        IF piBelow < 1 THEN
            UNDO, THROW NEW GridException("NextInt needs a limit of at least 1, not " + STRING(piBelow)).
        RETURN INTEGER(TRUNCATE(NextDecimal() * piBelow, 0)).
    END METHOD.

END CLASS.
