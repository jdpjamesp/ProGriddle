/* Binds a real time game to a renderer and a clock. Each clock tick passes the milliseconds that
   have elapsed to the game and redraws when the game says something changed. Start and PauseGame
   run and stop the clock and set the game's Paused flag. Reset starts a new game and runs it
   straight away. The clock stops by itself when the game is over.

   The controller is built paused: call Start to begin. It does not dispose the game, the renderer
   or the clock: its owner does. Dispose unsubscribes from the clock. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.RealTimeController FINAL IMPLEMENTS IGameController:

    DEFINE PRIVATE VARIABLE mGame     AS IRealTimeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer AS IGridRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock    AS IClock        NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed AS LOGICAL       NO-UNDO.

    DEFINE PUBLIC PROPERTY Steppable AS LOGICAL NO-UNDO
        GET():
            RETURN FALSE.
        END GET.

    DEFINE PUBLIC PROPERTY Pausable AS LOGICAL NO-UNDO
        GET():
            RETURN TRUE.
        END GET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET():
            RETURN mClock:IsRunning.
        END GET.

    DEFINE PUBLIC PROPERTY SpeedLevel AS INTEGER NO-UNDO
        GET():
            RETURN 0.
        END GET.

    CONSTRUCTOR PUBLIC RealTimeController(INPUT poGame AS IRealTimeGame, INPUT poRenderer AS IGridRenderer, INPUT poClock AS IClock):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A controller needs a game").
        IF NOT VALID-OBJECT(poRenderer) THEN UNDO, THROW NEW GridException("A controller needs a renderer").
        IF NOT VALID-OBJECT(poClock) THEN UNDO, THROW NEW GridException("A controller needs a clock").
        mGame = poGame.
        mRenderer = poRenderer.
        mClock = poClock.
        mGame:Paused = TRUE.
        mClock:Tick:Subscribe(OnTick).
        Redraw().
    END CONSTRUCTOR.

    /* Runs the game. Does nothing when it is over. */
    METHOD PUBLIC VOID Start():
        IF mGame:IsOver THEN RETURN.
        mGame:Paused = FALSE.
        mClock:Start().
    END METHOD.

    /* Stops the clock and pauses the game, then redraws once so a game that shows something while paused (a dimmed
       picture, a banner of its own) can put it up. */
    METHOD PUBLIC VOID PauseGame():
        mGame:Paused = TRUE.
        mClock:Stop().
        Redraw().
    END METHOD.

    /* Starts a new game and runs it. */
    METHOD PUBLIC VOID Reset():
        mClock:Stop().
        mGame:Initialise().
        mGame:Paused = FALSE.
        mClock:Start().
        Redraw().
    END METHOD.

    METHOD PUBLIC VOID Refresh():
        Redraw().
    END METHOD.

    METHOD PUBLIC VOID SetSpeedLevel(INPUT piLevel AS INTEGER):
        UNDO, THROW NEW GridException("A real time game sets its own speed").
    END METHOD.

    /* Start, PauseGame and Reset are supported. */
    METHOD PUBLIC VOID Execute(INPUT poCommand AS GameCommand):
        IF poCommand = GameCommand:Start THEN Start().
        ELSE IF poCommand = GameCommand:PauseGame THEN PauseGame().
        ELSE IF poCommand = GameCommand:Reset THEN Reset().
        ELSE UNDO, THROW NEW GridException("Command not supported by a real time game: " + STRING(poCommand)).
    END METHOD.

    /* Stops the clock and stops listening to it. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        mClock:Stop().
        mClock:Tick:Unsubscribe(OnTick).
    END METHOD.

    METHOD PRIVATE VOID OnTick(INPUT piElapsedMs AS INTEGER):
        IF mGame:Tick(piElapsedMs) THEN Redraw().
        IF mGame:IsOver THEN mClock:Stop().
    END METHOD.

    METHOD PRIVATE VOID Redraw():
        mRenderer:Render(mGame:Grid, mGame).
    END METHOD.

END CLASS.
