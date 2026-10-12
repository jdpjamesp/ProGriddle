/* Test double: remembers which programs it was asked to start and treats each as running until
   Finish is called. FailWith makes the next Launch throw. Not a test class itself. */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.RecordingGameLauncher IMPLEMENTS IGameLauncher:

    DEFINE PRIVATE VARIABLE mRunning AS CHARACTER NO-UNDO INITIAL ",".

    /* Every program started, in order, separated by commas. */
    DEFINE PUBLIC PROPERTY Launched AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    /* When not empty the next Launch throws a GridException with this text, then clears it. */
    DEFINE PUBLIC PROPERTY FailWith AS CHARACTER NO-UNDO
        GET.
        SET.

    METHOD PUBLIC VOID Launch(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE reason AS CHARACTER NO-UNDO.
        IF FailWith <> "" THEN DO:
            reason = FailWith.
            FailWith = "".
            UNDO, THROW NEW GridException(reason).
        END.
        IF IsRunning(pcProgram) THEN RETURN.
        Launched = Launched + (IF Launched = "" THEN "" ELSE ",") + pcProgram.
        mRunning = mRunning + pcProgram + ",".
    END METHOD.

    METHOD PUBLIC LOGICAL IsRunning(INPUT pcProgram AS CHARACTER):
        RETURN INDEX(mRunning, "," + pcProgram + ",") > 0.
    END METHOD.

    /* The game was closed. */
    METHOD PUBLIC VOID Finish(INPUT pcProgram AS CHARACTER):
        mRunning = REPLACE(mRunning, "," + pcProgram + ",", ",").
    END METHOD.

END CLASS.
