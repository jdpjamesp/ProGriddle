/* What a window needs from whatever drives a game. GameController drives a steppable game
   with a clock. TurnController drives a turn based game, where only a new game, a redraw and
   closing make sense, so Steppable and Pausable are false. RealTimeController drives a real
   time game: Pausable but not Steppable, so the window offers Start or Pause but no Step and
   no speed. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IGameController:

    /* True when Start and PauseGame apply: the game runs on a clock that can be paused. A
       steppable game and a real time game are both pausable, a turn based game is not. */
    DEFINE PUBLIC PROPERTY Pausable AS LOGICAL NO-UNDO
        GET.

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
