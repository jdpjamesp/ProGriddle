/* Test double: a random source that returns the numbers it was given, in order, and starts again
   at the first when it runs out. NextInt returns the next number, taken modulo piBelow, so a
   test can choose exactly which empty cell and which kind of tile a game picks. NextDecimal is
   not used by 2048 and throws. Not a test class itself (the name does not end in Tests). */
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.ScriptedRandom IMPLEMENTS IRandom:

    DEFINE PRIVATE VARIABLE mValues AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mNext   AS INTEGER   NO-UNDO.

    /* How many numbers have been asked for. */
    DEFINE PUBLIC PROPERTY Calls AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* pcValues is a comma separated list of whole numbers, such as "5,0,5,0". */
    CONSTRUCTOR PUBLIC ScriptedRandom(INPUT pcValues AS CHARACTER):
        mValues = pcValues.
        mNext = 1.
    END CONSTRUCTOR.

    METHOD PUBLIC DECIMAL NextDecimal():
        UNDO, THROW NEW GridException("ScriptedRandom has no decimals").
    END METHOD.

    METHOD PUBLIC INTEGER NextInt(INPUT piBelow AS INTEGER):
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        IF piBelow < 1 THEN UNDO, THROW NEW GridException("NextInt needs a limit of at least 1").
        v = INTEGER(ENTRY(mNext, mValues)).
        mNext = (IF mNext >= NUM-ENTRIES(mValues) THEN 1 ELSE mNext + 1).
        Calls = Calls + 1.
        RETURN v MODULO piBelow.
    END METHOD.

END CLASS.
