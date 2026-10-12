/* Starts a game's program on its own, so the arcade stays open while a game is played. */
USING Progress.Lang.*.

INTERFACE ProGriddle.Engine.IGameLauncher:

    /* Starts the program, for example run/run-tetris.p. Does nothing when that program was started
       by this launcher and is still running. Throws GridException when it cannot be started. */
    METHOD PUBLIC VOID Launch(INPUT pcProgram AS CHARACTER).

    /* True while a program started by this launcher is still running. */
    METHOD PUBLIC LOGICAL IsRunning(INPUT pcProgram AS CHARACTER).

END INTERFACE.
