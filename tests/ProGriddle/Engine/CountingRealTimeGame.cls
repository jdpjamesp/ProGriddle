/* Test double: a real time game that only adds up the time it is given. It is over once LimitMs
   milliseconds have passed, or never when the limit is 0. Not a test class itself (the name does
   not end in Tests). */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.CountingRealTimeGame INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    DEFINE PRIVATE VARIABLE mLimit AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Milliseconds and ticks received while running. */
    DEFINE PUBLIC PROPERTY TotalMs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY TickCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many times Initialise has run. */
    DEFINE PUBLIC PROPERTY InitialiseCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC CountingRealTimeGame(INPUT poGrid AS Grid, INPUT piLimitMs AS INTEGER):
        SUPER("counting real time", poGrid).
        mLimit = piLimitMs.
    END CONSTRUCTOR.

    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        IF Paused OR IsOver THEN RETURN FALSE.
        TotalMs = TotalMs + piElapsedMs.
        TickCount = TickCount + 1.
        IF mLimit > 0 AND TotalMs >= mLimit THEN IsOver = TRUE.
        RETURN piElapsedMs > 0.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        TotalMs = 0.
        TickCount = 0.
        InitialiseCount = InitialiseCount + 1.
    END METHOD.

END CLASS.
