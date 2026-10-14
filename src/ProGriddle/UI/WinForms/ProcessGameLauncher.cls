/* Starts each game as a program of its own: the same prowin that is running now, run from the
   current folder with tools/launch.p and the game's run file. The arcade stays open, and the games
   it started are remembered by process id, so a game that is still running is not started twice.
   Every game is started with -T, so its OpenEdge temp files go to the ProGriddle folder under the
   user's TEMP folder (C:\temp when TEMP is not set), created when it is missing. */
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

    /* The folder the games' temp files go to, created when it does not exist yet. */
    METHOD PUBLIC CHARACTER TempDirectory():
        DEFINE VARIABLE base AS CHARACTER NO-UNDO.
        DEFINE VARIABLE dir  AS CHARACTER NO-UNDO.
        base = OS-GETENV("TEMP").
        IF base = ? OR base = "" THEN base = "C:\temp".
        dir = RIGHT-TRIM(base, "\") + "\ProGriddle".
        System.IO.Directory:CreateDirectory(dir).
        RETURN dir.
    END METHOD.

    /* The startup parameters that run a program in a prowin of its own. -l 1024 gives it a local buffer pool of a
       megabyte: the program code of a game and the framework is more than the default, and prowin would otherwise grow
       the pool in steps of 10 and show a warning (5408) for each step. */
    METHOD PUBLIC CHARACTER ArgumentsFor(INPUT pcProgram AS CHARACTER):
        IF pcProgram = ? OR pcProgram = "" THEN UNDO, THROW NEW GridException("There is no program to launch").
        RETURN SUBSTITUTE('-T "&1" -l 1024 -p tools/launch.p -param "&2"', TempDirectory(), pcProgram).
    END METHOD.

    METHOD PUBLIC VOID Launch(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE info    AS ProcessStartInfo NO-UNDO.
        DEFINE VARIABLE started AS Process          NO-UNDO.
        IF pcProgram = ? OR pcProgram = "" THEN UNDO, THROW NEW GridException("There is no program to launch").
        IF IsRunning(pcProgram) THEN RETURN.
        DO ON ERROR UNDO, THROW:
            info = NEW ProcessStartInfo(Process:GetCurrentProcess():MainModule:FileName, ArgumentsFor(pcProgram)).
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
