/* Test double: a turn based game that only counts moves. Not a test class itself (the name
   does not end in Tests). */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.CountingTurnGame INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:

    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN Generation.
        END GET.

    /* How many times Initialise has run. */
    DEFINE PUBLIC PROPERTY InitialiseCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC CountingTurnGame(INPUT poGrid AS Grid):
        SUPER("counting turns", poGrid).
    END CONSTRUCTOR.

    /* A move: counts a turn. */
    METHOD PUBLIC VOID MakeMove():
        Generation = Generation + 1.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        InitialiseCount = InitialiseCount + 1.
    END METHOD.

END CLASS.
