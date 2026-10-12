/* The arcade window needs the .NET bridge, so these run under prowin -b (tools/run-tests.ps1 -Gui). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ArcadeWindowTests:

    DEFINE PRIVATE VARIABLE mLauncher AS RecordingGameLauncher NO-UNDO.
    DEFINE PRIVATE VARIABLE mWindow   AS ArcadeWindow          NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildWindow():
        mLauncher = NEW RecordingGameLauncher().
        mWindow = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog("run/run-a.p|Alpha|The first;run/run-b.p|Beta|The second"), mLauncher).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseWindow():
        IF VALID-OBJECT(mWindow) THEN DO:
            mWindow:ReleaseResources().
            mWindow:Dispose().
        END.
        mWindow = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsOneButtonForEveryGameInTheCatalog():
        Assert:Equals("Arcade", mWindow:Text).
        Assert:Equals(2, mWindow:GameCount).
        Assert:Equals("Alpha", mWindow:ButtonFor("run/run-a.p"):Text).
        Assert:Equals("Beta", mWindow:ButtonFor("run/run-b.p"):Text).
        Assert:IsTrue(mWindow:ButtonFor("run/run-a.p"):Enabled).
        Assert:IsTrue(mWindow:ButtonFor("run/run-b.p"):Enabled).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlayStartsThatGameAndSaysSo():
        mWindow:Play("run/run-b.p").
        Assert:Equals("run/run-b.p", mLauncher:Launched).
        Assert:Equals("Started Beta", mWindow:StatusLine).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsRunningShowsAsPlaying():
        mWindow:Play("run/run-a.p").
        Assert:Equals("Alpha (playing)", mWindow:ButtonFor("run/run-a.p"):Text).
        Assert:Equals("Beta", mWindow:ButtonFor("run/run-b.p"):Text).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsRunningIsNotStartedAgainAndTheStatusSaysSo():
        mWindow:Play("run/run-a.p").
        mWindow:Play("run/run-a.p").
        Assert:Equals("run/run-a.p", mLauncher:Launched).
        Assert:Equals("Alpha is already running", mWindow:StatusLine).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatHasFinishedShowsAsReadyAgainOnTheNextUpdate():
        mWindow:Play("run/run-a.p").
        mLauncher:Finish("run/run-a.p").
        mWindow:Play("run/run-b.p").
        Assert:Equals("Alpha", mWindow:ButtonFor("run/run-a.p"):Text).
        Assert:Equals("Beta (playing)", mWindow:ButtonFor("run/run-b.p"):Text).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsStartedAtTheLauncherIsShownAsPlayingToo():
        mLauncher:Launch("run/run-b.p").
        mWindow:Play("run/run-a.p").
        Assert:Equals("Beta (playing)", mWindow:ButtonFor("run/run-b.p"):Text).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatFailsToStartLeavesItsButtonOnAndSaysWhy():
        mLauncher:FailWith = "No prowin here".
        mWindow:Play("run/run-a.p").
        Assert:Equals("", mLauncher:Launched).
        Assert:Equals("No prowin here", mWindow:StatusLine).
        Assert:IsTrue(mWindow:ButtonFor("run/run-a.p"):Enabled).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyCatalogShowsNoButtonsAndSaysSo():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(""), mLauncher).
            Assert:Equals(0, w:GameCount).
            Assert:Equals("No games found", w:StatusLine).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleaseResourcesCanBeCalledMoreThanOnce():
        mWindow:AutoClose(60).
        mWindow:ReleaseResources().
        mWindow:ReleaseResources().
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AskingForAGameThatIsNotThereThrows():
        mWindow:ButtonFor("run/run-zzz.p").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AutoCloseNeedsASecondOrMore():
        mWindow:AutoClose(0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsATitle():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("", NEW FixedGameCatalog(""), mLauncher).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsACatalog():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("Arcade", ?, mLauncher).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsALauncher():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(""), ?).
    END METHOD.

END CLASS.
