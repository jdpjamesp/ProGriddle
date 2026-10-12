/* Shared plumbing for games: the name, the grid, the over flag and a counter. The counter is
   the generation for a steppable game and can count turns for a turn based one.
   A subclass overrides OnInitialise to set up its starting position and sets IsOver and
   Generation as play proceeds. */
USING Progress.Lang.*.
USING Prolif.Core.Grid.
USING Prolif.Core.GridException.
USING Prolif.Engine.AbstractGame.
USING Prolif.Engine.IGame.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.AbstractGame ABSTRACT IMPLEMENTS IGame:

    DEFINE PUBLIC PROPERTY Name AS CHARACTER NO-UNDO
        GET.
        PROTECTED SET.

    DEFINE PUBLIC PROPERTY Grid AS Grid NO-UNDO
        GET.
        PROTECTED SET.

    DEFINE PUBLIC PROPERTY IsOver AS LOGICAL NO-UNDO
        GET.
        PROTECTED SET.

    DEFINE PUBLIC PROPERTY Generation AS INTEGER NO-UNDO
        GET.
        PROTECTED SET.

    CONSTRUCTOR PROTECTED AbstractGame(INPUT pcName AS CHARACTER, INPUT poGrid AS Grid):
        IF pcName = ? OR pcName = "" THEN
            UNDO, THROW NEW GridException("A game needs a name").
        IF NOT VALID-OBJECT(poGrid) THEN
            UNDO, THROW NEW GridException("A game needs a grid").
        Name = pcName.
        Grid = poGrid.
    END CONSTRUCTOR.

    /* Resets the counter and the over flag, then calls OnInitialise. */
    METHOD PUBLIC VOID Initialise():
        Generation = 0.
        IsOver = FALSE.
        OnInitialise().
    END METHOD.

    /* Override to set up the starting position. The base version does nothing. */
    METHOD PROTECTED VOID OnInitialise():
    END METHOD.

    /* Disposes the grid, which disposes its store. */
    METHOD PUBLIC VOID Dispose():
        IF VALID-OBJECT(Grid) THEN Grid:Dispose().
    END METHOD.

END CLASS.
