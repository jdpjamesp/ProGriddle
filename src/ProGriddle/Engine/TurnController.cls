/* Binds a turn based game to a renderer. There is no clock and no stepping: the game changes
   when a move is made on it, and Refresh draws the result. Reset starts a new game. The
   controller draws the game once when it is built. It does not dispose the game or the
   renderer: its owner does. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TurnController FINAL IMPLEMENTS IGameController:

    DEFINE PRIVATE VARIABLE mGame     AS ITurnBasedGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer AS IGridRenderer  NO-UNDO.

    DEFINE PUBLIC PROPERTY Steppable AS LOGICAL NO-UNDO
        GET():
            RETURN FALSE.
        END GET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET():
            RETURN FALSE.
        END GET.

    DEFINE PUBLIC PROPERTY SpeedLevel AS INTEGER NO-UNDO
        GET():
            RETURN 0.
        END GET.

    CONSTRUCTOR PUBLIC TurnController(INPUT poGame AS ITurnBasedGame, INPUT poRenderer AS IGridRenderer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A controller needs a game").
        IF NOT VALID-OBJECT(poRenderer) THEN UNDO, THROW NEW GridException("A controller needs a renderer").
        mGame = poGame.
        mRenderer = poRenderer.
        Redraw().
    END CONSTRUCTOR.

    /* Starts a new game and redraws. */
    METHOD PUBLIC VOID Reset():
        mGame:Initialise().
        Redraw().
    END METHOD.

    METHOD PUBLIC VOID Refresh():
        Redraw().
    END METHOD.

    /* Nothing runs, so there is nothing to pause. */
    METHOD PUBLIC VOID PauseGame():
    END METHOD.

    METHOD PUBLIC VOID SetSpeedLevel(INPUT piLevel AS INTEGER):
        UNDO, THROW NEW GridException("A turn based game has no speed").
    END METHOD.

    /* Only Reset (a new game) is supported. */
    METHOD PUBLIC VOID Execute(INPUT poCommand AS GameCommand):
        IF poCommand = GameCommand:Reset THEN Reset().
        ELSE UNDO, THROW NEW GridException("Command not supported by a turn based game: " + STRING(poCommand)).
    END METHOD.

    METHOD PUBLIC VOID Dispose():
    END METHOD.

    METHOD PRIVATE VOID Redraw():
        mRenderer:Render(mGame:Grid, mGame).
    END METHOD.

END CLASS.
