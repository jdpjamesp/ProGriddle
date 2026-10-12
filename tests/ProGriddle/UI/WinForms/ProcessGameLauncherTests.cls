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

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LaunchingNothingThrows():
        NEW ProcessGameLauncher():Launch("").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LaunchingTheUnknownValueThrows():
        NEW ProcessGameLauncher():Launch(?).
    END METHOD.

END CLASS.
