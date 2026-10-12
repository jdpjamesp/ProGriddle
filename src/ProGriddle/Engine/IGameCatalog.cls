/* A list of the games that can be started from the arcade, in the order they are shown. Places run
   from 1 to Count. */
USING Progress.Lang.*.

INTERFACE ProGriddle.Engine.IGameCatalog:

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.

    /* The name to show on the button. */
    METHOD PUBLIC CHARACTER TitleAt(INPUT piPlace AS INTEGER).

    /* One line about the game, or an empty string. */
    METHOD PUBLIC CHARACTER BlurbAt(INPUT piPlace AS INTEGER).

    /* The program that starts the game, as it is passed to tools/launch.p: run/run-tetris.p. */
    METHOD PUBLIC CHARACTER ProgramAt(INPUT piPlace AS INTEGER).

END INTERFACE.
