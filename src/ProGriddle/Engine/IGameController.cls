/* What a window needs from whatever drives a game. GameController drives a steppable game
   with a clock. TurnController drives a turn based game, where only a new game, a redraw and
   closing make sense, so Steppable is false and the window leaves out Start, Step and speed. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IGameController:

    /* True when Start, StepOnce, PauseGame and the speed levels apply. */
    DEFINE PUBLIC PROPERTY Steppable AS LOGICAL NO-UNDO
        GET.

    /* True while the controller is stepping the game on a clock. Always false when not Steppable. */
    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET.

    /* 1 (slowest) to 6 (fastest) when Steppable, otherwise 0. */
    DEFINE PUBLIC PROPERTY SpeedLevel AS INTEGER NO-UNDO
        GET.

    /* Runs a command. Throws GridException for a command the game does not support. */
    METHOD PUBLIC VOID Execute(INPUT poCommand AS GameCommand).

    /* Puts the game back to its starting state and redraws. */
    METHOD PUBLIC VOID Reset().

    /* Draws the game again without changing it. */
    METHOD PUBLIC VOID Refresh().

    /* Stops anything running. Does nothing when not Steppable. */
    METHOD PUBLIC VOID PauseGame().

    /* Sets the speed level. Throws GridException when not Steppable. */
    METHOD PUBLIC VOID SetSpeedLevel(INPUT piLevel AS INTEGER).

    METHOD PUBLIC VOID Dispose().

END INTERFACE.
