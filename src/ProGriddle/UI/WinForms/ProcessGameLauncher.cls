/* Starts each game as a program of its own: the same prowin that is running now, run from the
   current folder with tools/launch.p and the game's run file. The arcade stays open, and the games
   it started are remembered by process id, so a game that is still running is not started twice. */
USING Progress.Lang.*.
USING System.Diagnostics.Process FROM ASSEMBLY.
USING System.Diagnostics.ProcessStartInfo FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ProcessGameLauncher FINAL IMPLEMENTS IGameLauncher:

    DEFINE PRIVATE TEMP-TABLE ttStarted NO-UNDO
        FIELD runFile AS CHARACTER
        FIELD pid     AS INTEGER
        INDEX ixFile IS UNIQUE PRIMARY runFile.

    METHOD PUBLIC VOID Launch(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE info    AS ProcessStartInfo NO-UNDO.
        DEFINE VARIABLE started AS Process          NO-UNDO.
        IF pcProgram = ? OR pcProgram = "" THEN UNDO, THROW NEW GridException("There is no program to launch").
        IF IsRunning(pcProgram) THEN RETURN.
        DO ON ERROR UNDO, THROW:
            info = NEW ProcessStartInfo(Process:GetCurrentProcess():MainModule:FileName,
                                        SUBSTITUTE('-p tools/launch.p -param "&1"', pcProgram)).
            info:WorkingDirectory = System.IO.Directory:GetCurrentDirectory().
            info:UseShellExecute = FALSE.
            started = Process:Start(info).
            FIND ttStarted WHERE ttStarted.runFile = pcProgram NO-ERROR.
            IF NOT AVAILABLE ttStarted THEN DO:
                CREATE ttStarted.
                ttStarted.runFile = pcProgram.
            END.
            ttStarted.pid = started:Id.
            CATCH e AS Progress.Lang.Error:
                UNDO, THROW NEW GridException(SUBSTITUTE("Could not start &1: &2", pcProgram, e:GetMessage(1))).
            END CATCH.
        END.
    END METHOD.

    METHOD PUBLIC LOGICAL IsRunning(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE found AS Process NO-UNDO.
        FIND ttStarted WHERE ttStarted.runFile = pcProgram NO-ERROR.
        IF NOT AVAILABLE ttStarted THEN RETURN FALSE.
        DO ON ERROR UNDO, THROW:
            found = Process:GetProcessById(ttStarted.pid).
            RETURN NOT found:HasExited.
            /* GetProcessById throws when there is no such process any more */
            CATCH e AS Progress.Lang.Error:
                DELETE ttStarted.
                RETURN FALSE.
            END CATCH.
        END.
    END METHOD.

END CLASS.
