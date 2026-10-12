/* Test double: a steppable game that only counts. It is over after piLimit steps, or never
   when piLimit is 0. Not a test class itself (the name does not end in Tests). */
USING Prolif.Core.*.
USING Prolif.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.CountingGame INHERITS AbstractGame IMPLEMENTS ISteppableGame:

    DEFINE PRIVATE VARIABLE mLimit AS INTEGER NO-UNDO.

    /* How many times Initialise has run. */
    DEFINE PUBLIC PROPERTY InitialiseCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC CountingGame(INPUT poGrid AS Grid, INPUT piLimit AS INTEGER):
        SUPER("counting", poGrid).
        mLimit = piLimit.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Step():
        Generation = Generation + 1.
        IF mLimit > 0 AND Generation >= mLimit THEN IsOver = TRUE.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        InitialiseCount = InitialiseCount + 1.
    END METHOD.

END CLASS.
