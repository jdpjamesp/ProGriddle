/* What every game offers its controller and renderer. A game owns its grid. Game logic
   never touches rendering, input or .NET, so it runs the same in the GUI or under test. */
USING Prolif.Core.Grid.
USING Prolif.Engine.IGame.

INTERFACE Prolif.Engine.IGame:

    DEFINE PUBLIC PROPERTY Name AS CHARACTER NO-UNDO
        GET.

    DEFINE PUBLIC PROPERTY Grid AS Grid NO-UNDO
        GET.

    /* True once the game has been won, lost or can go no further. */
    DEFINE PUBLIC PROPERTY IsOver AS LOGICAL NO-UNDO
        GET.

    /* Puts the game back to its starting state. */
    METHOD PUBLIC VOID Initialise().

    /* Releases the grid and anything else the game holds. Call it when finished. */
    METHOD PUBLIC VOID Dispose().

END INTERFACE.
