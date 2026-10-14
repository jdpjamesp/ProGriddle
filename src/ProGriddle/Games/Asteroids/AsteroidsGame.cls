/* Asteroids: the starting point of a new game. A steppable game on one layer called "state": a
   single lit cell moves along the board a cell at a time, row by row, and starts again at the top
   left when it gets to the end. It is here to show every part a game needs, so replace the rules
   with your own:

     Step           what happens on each tick of the clock
     OnInitialise   how a new game starts (Initialise has already put Generation back to 0)
     IsOver         set it to true when the game ends, and the controller stops the clock

   The game knows nothing about a window, a timer or any .NET type, so it is tested without one. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsGame INHERITS AbstractGame IMPLEMENTS ISteppableGame:

    DEFINE PRIVATE VARIABLE mPosition AS INTEGER NO-UNDO.

    /* The cell index the lit cell is on, 0 for the top left. */
    DEFINE PUBLIC PROPERTY Position AS INTEGER NO-UNDO
        GET():
            RETURN mPosition.
        END GET.

    /* The grid must have exactly one layer, named "state". */
    CONSTRUCTOR PUBLIC AsteroidsGame(INPUT poGrid AS Grid):
        SUPER("Asteroids", poGrid).
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "state" THEN
            UNDO, THROW NEW GridException("A Asteroids grid has exactly one layer, named state").
        Initialise().
    END CONSTRUCTOR.

    /* Moves the lit cell on by one and counts the generation. */
    METHOD PUBLIC VOID Step():
        Grid:Store:SetCellAt(1, mPosition, 0).
        mPosition = (mPosition + 1) MODULO Grid:CellCount.
        Grid:Store:SetCellAt(1, mPosition, 1).
        Generation = Generation + 1.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Grid:Store:FillLayer(1, 0).
        mPosition = 0.
        Grid:Store:SetCellAt(1, 0, 1).
    END METHOD.

END CLASS.
