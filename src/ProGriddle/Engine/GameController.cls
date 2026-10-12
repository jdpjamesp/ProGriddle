/* Binds a steppable game to a renderer and a clock: start, pause, single step, reset and
   speed. Each clock tick steps the game once and re-renders. The controller draws the game
   once when it is built, and again after every change.

   Speed is a level from 1 (slowest) to 6 (fastest) that maps to a clock interval. The game
   stops the clock itself when it is over. Dispose unsubscribes from the clock. The
   controller does not dispose the game, the renderer or the clock: its owner does. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.GameController FINAL IMPLEMENTS IGameController:

    DEFINE PRIVATE VARIABLE mGame      AS ISteppableGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer  AS IGridRenderer  NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock     AS IClock         NO-UNDO.
    DEFINE PRIVATE VARIABLE mIntervals AS INTEGER        NO-UNDO EXTENT 6 INITIAL [1000, 500, 250, 125, 60, 30].
    DEFINE PRIVATE VARIABLE mDisposed  AS LOGICAL        NO-UNDO.

    /* 1 (slowest) to 6 (fastest). Starts at 3, one step every 250 ms. */
    DEFINE PUBLIC PROPERTY SpeedLevel AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET():
            RETURN mClock:IsRunning.
        END GET.

    DEFINE PUBLIC PROPERTY Steppable AS LOGICAL NO-UNDO
        GET():
            RETURN TRUE.
        END GET.

    CONSTRUCTOR PUBLIC GameController(INPUT poGame AS ISteppableGame, INPUT poRenderer AS IGridRenderer, INPUT poClock AS IClock):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A controller needs a game").
        IF NOT VALID-OBJECT(poRenderer) THEN UNDO, THROW NEW GridException("A controller needs a renderer").
        IF NOT VALID-OBJECT(poClock) THEN UNDO, THROW NEW GridException("A controller needs a clock").
        mGame = poGame.
        mRenderer = poRenderer.
        mClock = poClock.
        SpeedLevel = 3.
        mClock:Interval = mIntervals[SpeedLevel].
        mClock:Tick:Subscribe(OnTick).
        Redraw().
    END CONSTRUCTOR.

    /* Starts stepping on every tick. Does nothing when the game is over. */
    METHOD PUBLIC VOID Start():
        IF mGame:IsOver THEN RETURN.
        mClock:Start().
    END METHOD.

    METHOD PUBLIC VOID PauseGame():
        mClock:Stop().
    END METHOD.

    /* One step now, whether running or paused. Does nothing when the game is over. */
    METHOD PUBLIC VOID StepOnce():
        IF mGame:IsOver THEN RETURN.
        mGame:Step().
        IF mGame:IsOver THEN mClock:Stop().
        Redraw().
    END METHOD.

    /* Stops the clock, puts the game back to its starting state and redraws. */
    METHOD PUBLIC VOID Reset():
        mClock:Stop().
        mGame:Initialise().
        Redraw().
    END METHOD.

    /* Draws the game again without changing it. Call it after the game was changed from
       outside, for example by a click on a cell. */
    METHOD PUBLIC VOID Refresh():
        Redraw().
    END METHOD.

    METHOD PUBLIC VOID SpeedUp():
        SetSpeed(SpeedLevel + 1).
    END METHOD.

    /* Sets the speed level directly, for a slider or a saved setting. Values outside 1 to 6
       are brought back to the nearest end. */
    METHOD PUBLIC VOID SetSpeedLevel(INPUT piLevel AS INTEGER):
        SetSpeed(piLevel).
    END METHOD.

    METHOD PUBLIC VOID SlowDown():
        SetSpeed(SpeedLevel - 1).
    END METHOD.

    /* Runs a command. UndoMove is not available for a steppable game and throws. */
    METHOD PUBLIC VOID Execute(INPUT poCommand AS GameCommand):
        IF poCommand = GameCommand:Start THEN Start().
        ELSE IF poCommand = GameCommand:PauseGame THEN PauseGame().
        ELSE IF poCommand = GameCommand:StepOnce THEN StepOnce().
        ELSE IF poCommand = GameCommand:Reset THEN Reset().
        ELSE IF poCommand = GameCommand:SpeedUp THEN SpeedUp().
        ELSE IF poCommand = GameCommand:SlowDown THEN SlowDown().
        ELSE UNDO, THROW NEW GridException("Command not supported by a steppable game: " + STRING(poCommand)).
    END METHOD.

    /* Stops the clock and stops listening to it. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        mClock:Stop().
        mClock:Tick:Unsubscribe(OnTick).
    END METHOD.

    METHOD PRIVATE VOID OnTick(INPUT piElapsedMs AS INTEGER):
        StepOnce().
    END METHOD.

    METHOD PRIVATE VOID SetSpeed(INPUT piLevel AS INTEGER):
        SpeedLevel = MAXIMUM(1, MINIMUM(6, piLevel)).
        mClock:Interval = mIntervals[SpeedLevel].
    END METHOD.

    METHOD PRIVATE VOID Redraw():
        mRenderer:Render(mGame:Grid, mGame).
    END METHOD.

END CLASS.
