/* Conway's Life, or any Life-like rule set, as a steppable game. The grid has a single layer
   called "state" holding 0 (dead) or 1 (alive). The game hands each generation to an
   ILifeEngine, so the same game runs on a dense or a sparse engine.

   Reset (Initialise) returns the board to the state it had when the first step was taken, or
   to the state saved by CaptureStart, or to empty when neither has happened. Editing the
   board while Generation is 0 and then stepping saves the edited board as the new start.

   The game owns its grid and its engine: Dispose releases both. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeGame INHERITS AbstractGame IMPLEMENTS ISteppableGame:

    DEFINE PRIVATE VARIABLE mEngine AS ILifeEngine NO-UNDO.
    DEFINE PRIVATE VARIABLE mStart  AS ICellStore  NO-UNDO.

    DEFINE PUBLIC PROPERTY Rules AS LifeRules NO-UNDO
        GET.
        PRIVATE SET.

    /* The share of cells expected to be alive, 0 to 1. LifeFactory sets it when it builds the game
       and uses it to choose the engine again when the rules or the size change. */
    DEFINE PUBLIC PROPERTY ExpectedLive AS DECIMAL NO-UNDO INITIAL 0.1
        GET.
        SET(INPUT pdValue AS DECIMAL):
            IF pdValue = ? OR pdValue < 0 OR pdValue > 1 THEN
                UNDO, THROW NEW GridException("The expected live share must be from 0 to 1, not " + STRING(pdValue)).
            ExpectedLive = pdValue.
        END SET.

    /* Number of live cells now. */
    DEFINE PUBLIC PROPERTY AliveCount AS INTEGER NO-UNDO
        GET():
            RETURN Grid:Store:CountOf(1, 1).
        END GET.

    /* The grid must have exactly one layer, named "state". The engine must have been built
       for the same grid and rules. */
    CONSTRUCTOR PUBLIC LifeGame(INPUT poGrid AS Grid, INPUT poRules AS LifeRules, INPUT poEngine AS ILifeEngine):
        SUPER("Life", poGrid).
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("A Life game needs rules").
        IF NOT VALID-OBJECT(poEngine) THEN UNDO, THROW NEW GridException("A Life game needs an engine").
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "state" THEN
            UNDO, THROW NEW GridException("A Life grid has exactly one layer, named state").
        Rules = poRules.
        mEngine = poEngine.
    END CONSTRUCTOR.

    /* Advances one generation. The first step from generation 0 saves the board as the start
       for Reset. */
    METHOD PUBLIC VOID Step():
        IF Generation = 0 THEN CaptureStart().
        mEngine:Step().
        Generation = Generation + 1.
    END METHOD.

    METHOD PUBLIC LOGICAL IsAlive(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(1, piX, piY) <> 0.
    END METHOD.

    METHOD PUBLIC VOID SetAlive(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plAlive AS LOGICAL):
        Grid:Store:SetCell(1, piX, piY, (IF plAlive THEN 1 ELSE 0)).
    END METHOD.

    /* Flips one cell, for clicking on the board. */
    METHOD PUBLIC VOID ToggleCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        SetAlive(piX, piY, NOT IsAlive(piX, piY)).
    END METHOD.

    /* Makes every cell the shape covers alive, with its top left corner at piX, piY. Other
       live cells stay alive. Throws GridException, and changes nothing, when the shape does
       not fit on the board. */
    METHOD PUBLIC VOID Place(INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        Grid:Store:Stamp(1, poShape, piX, piY, 1).
    END METHOD.

    /* Kills every cell. */
    METHOD PUBLIC VOID ClearBoard():
        Grid:Store:FillLayer(1, 0).
    END METHOD.

    /* Clears the board, then makes each cell alive with probability pdDensity (0 to 1). The same
       seeded random source gives the same board. */
    METHOD PUBLIC VOID Randomise(INPUT poRandom AS IRandom, INPUT pdDensity AS DECIMAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Randomise needs a random source").
        IF pdDensity < 0 OR pdDensity > 1 THEN
            UNDO, THROW NEW GridException("Density must be from 0 to 1, not " + STRING(pdDensity)).
        ClearBoard().
        DO i = 0 TO Grid:CellCount - 1:
            IF poRandom:NextDecimal() < pdDensity THEN Grid:Store:SetCellAt(1, i, 1).
        END.
    END METHOD.

    /* Swaps in a new grid, rules and engine (built by LifeFactory:Rebuild, which has already copied the
       board across) and frees the old grid and engine. With plKeepStart the state Reset returns to is
       kept, which is only right when the board is the same size. Without it that state is dropped and
       the generation goes back to 0, because a smaller or larger board has no start to go back to.
       Throws GridException, and changes nothing, when the grid does not have the one layer "state". */
    METHOD PUBLIC VOID Replace(INPUT poGrid AS Grid, INPUT poRules AS LifeRules, INPUT poEngine AS ILifeEngine, INPUT plKeepStart AS LOGICAL):
        DEFINE VARIABLE oldGrid   AS Grid        NO-UNDO.
        DEFINE VARIABLE oldEngine AS ILifeEngine NO-UNDO.
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("A Life game needs a grid").
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("A Life game needs rules").
        IF NOT VALID-OBJECT(poEngine) THEN UNDO, THROW NEW GridException("A Life game needs an engine").
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "state" THEN
            UNDO, THROW NEW GridException("A Life grid has exactly one layer, named state").
        oldGrid = Grid.
        oldEngine = mEngine.
        Grid = poGrid.
        Rules = poRules.
        mEngine = poEngine.
        IF NOT plKeepStart THEN DO:
            IF VALID-OBJECT(mStart) THEN mStart:Dispose().
            mStart = ?.
            Generation = 0.
        END.
        oldEngine:Dispose().
        oldGrid:Dispose().
    END METHOD.

    /* Saves the board as the state Reset returns to. */
    METHOD PUBLIC VOID CaptureStart():
        IF VALID-OBJECT(mStart) THEN mStart:Dispose().
        mStart = Grid:Store:Duplicate().
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        IF VALID-OBJECT(mStart) THEN Grid:Store:CopyFrom(mStart).
        ELSE ClearBoard().
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Dispose():
        IF VALID-OBJECT(mStart) THEN mStart:Dispose().
        mStart = ?.
        IF VALID-OBJECT(mEngine) THEN mEngine:Dispose().
        SUPER:Dispose().
    END METHOD.

END CLASS.
