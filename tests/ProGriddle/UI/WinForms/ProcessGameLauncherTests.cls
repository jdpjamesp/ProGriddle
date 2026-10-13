/* Needs the .NET bridge, so it runs under prowin -b (tools/run-tests.ps1 -Gui). Starting a real game
   is left to the arcade smoke test, because it opens a window. */
USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ProcessGameLauncherTests:

    @Test.
    METHOD PUBLIC VOID AProgramThatWasNeverStartedIsNotRunning():
        Assert:IsFalse(NEW ProcessGameLauncher():IsRunning("run/run-life.p")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTempFilesGoToAProGriddleFolderThatIsCreated():
        DEFINE VARIABLE dir AS CHARACTER NO-UNDO.
        dir = NEW ProcessGameLauncher():TempDirectory().
        Assert:Equals("~\ProGriddle", SUBSTRING(dir, LENGTH(dir) - 10)).
        FILE-INFORMATION:FILE-NAME = dir.
        Assert:IsTrue(FILE-INFORMATION:FULL-PATHNAME <> ?).
        Assert:IsTrue(INDEX(FILE-INFORMATION:FILE-TYPE, "D") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryGameIsStartedWithTheTempFolderParameter():
        DEFINE VARIABLE args AS CHARACTER NO-UNDO.
        DEFINE VARIABLE tail AS CHARACTER NO-UNDO INITIAL '-p tools/launch.p -param "run/run-tetris.p"'.
        args = NEW ProcessGameLauncher():ArgumentsFor("run/run-tetris.p").
        Assert:IsTrue(args BEGINS '-T "').
        Assert:IsTrue(INDEX(args, "ProGriddle") > 0).
        Assert:Equals(tail, SUBSTRING(args, LENGTH(args) - LENGTH(tail) + 1)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ArgumentsForNothingThrows():
        NEW ProcessGameLauncher():ArgumentsFor("").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LaunchingNothingThrows():
        NEW ProcessGameLauncher():Launch("").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LaunchingTheUnknownValueThrows():
        NEW ProcessGameLauncher():Launch(?).
    END METHOD.

END CLASS.
