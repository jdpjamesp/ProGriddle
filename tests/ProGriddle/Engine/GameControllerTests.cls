USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.GameControllerTests:

    DEFINE PRIVATE VARIABLE mGame       AS CountingGame     NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer   AS RecordingRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock      AS FakeClock        NO-UNDO.
    DEFINE PRIVATE VARIABLE mController AS GameController   NO-UNDO.

    /* A fresh game that is over after 5 steps, with the controller built around it. */
    @Setup.
    METHOD PUBLIC VOID BuildController():
        mGame = NEW CountingGame(NEW Grid(NEW ArrayStore(3, 3, "s")), 5).
        mRenderer = NEW RecordingRenderer().
        mClock = NEW FakeClock().
        mController = NEW GameController(mGame, mRenderer, mClock).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseController():
        IF VALID-OBJECT(mController) THEN mController:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mController = ?.
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawsTheStartingStateWhenBuilt():
        Assert:Equals(1, mRenderer:RenderCount).
        Assert:Equals(0, mRenderer:LastGeneration).
        Assert:IsFalse(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartsAtSpeedLevelThreeWithA250MillisecondClock():
        Assert:Equals(3, mController:SpeedLevel).
        Assert:Equals(250, mClock:Interval).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingHappensUntilItIsStarted():
        mClock:Advance(5000).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(1, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartStepsOncePerIntervalAndRedrawsEachTime():
        mController:Start().
        Assert:IsTrue(mController:IsRunning).
        mClock:Advance(750).
        Assert:Equals(3, mGame:Generation).
        Assert:Equals(4, mRenderer:RenderCount).
        Assert:Equals(3, mRenderer:LastGeneration).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PauseGameStopsTheStepping():
        mController:Start().
        mClock:Advance(500).
        mController:PauseGame().
        Assert:IsFalse(mController:IsRunning).
        mClock:Advance(5000).
        Assert:Equals(2, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartAfterPauseCarriesOn():
        mController:Start().
        mClock:Advance(250).
        mController:PauseGame().
        mController:Start().
        mClock:Advance(250).
        Assert:Equals(2, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StepOnceStepsAndRedrawsWhilePaused():
        mController:StepOnce().
        Assert:Equals(1, mGame:Generation).
        Assert:Equals(2, mRenderer:RenderCount).
        Assert:Equals(1, mRenderer:LastGeneration).
        Assert:IsFalse(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetStopsTheClockReinitialisesAndRedraws():
        mController:Start().
        mClock:Advance(750).
        mController:Reset().
        Assert:IsFalse(mController:IsRunning).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(1, mGame:InitialiseCount).
        Assert:Equals(0, mRenderer:LastGeneration).
        Assert:Equals(5, mRenderer:RenderCount).
        mClock:Advance(5000).
        Assert:Equals(0, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RefreshDrawsAgainWithoutChangingTheGame():
        mController:Refresh().
        Assert:Equals(2, mRenderer:RenderCount).
        Assert:Equals(0, mGame:Generation).
        Assert:IsFalse(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpeedUpAndSlowDownMoveThroughTheSixLevels():
        mController:SpeedUp().
        Assert:Equals(4, mController:SpeedLevel).
        Assert:Equals(125, mClock:Interval).
        mController:SpeedUp().
        Assert:Equals(60, mClock:Interval).
        mController:SpeedUp().
        Assert:Equals(6, mController:SpeedLevel).
        Assert:Equals(30, mClock:Interval).
        mController:SlowDown().
        mController:SlowDown().
        mController:SlowDown().
        mController:SlowDown().
        mController:SlowDown().
        Assert:Equals(1, mController:SpeedLevel).
        Assert:Equals(1000, mClock:Interval).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetSpeedLevelJumpsStraightToALevelAndClampsOutOfRangeValues():
        mController:SetSpeedLevel(5).
        Assert:Equals(5, mController:SpeedLevel).
        Assert:Equals(60, mClock:Interval).
        mController:SetSpeedLevel(99).
        Assert:Equals(6, mController:SpeedLevel).
        mController:SetSpeedLevel(-3).
        Assert:Equals(1, mController:SpeedLevel).
        Assert:Equals(1000, mClock:Interval).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpeedStaysWithinTheLimits():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 10:
            mController:SpeedUp().
        END.
        Assert:Equals(6, mController:SpeedLevel).
        Assert:Equals(30, mClock:Interval).
        DO i = 1 TO 10:
            mController:SlowDown().
        END.
        Assert:Equals(1, mController:SpeedLevel).
        Assert:Equals(1000, mClock:Interval).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewSpeedChangesHowOftenItSteps():
        mController:Start().
        mController:SpeedUp().
        mController:SpeedUp().
        mClock:Advance(240).
        Assert:Equals(4, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItStopsTheClockWhenTheGameIsOver():
        mController:Start().
        mClock:Advance(10000).
        Assert:Equals(5, mGame:Generation).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mController:IsRunning).
        Assert:Equals(6, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnceOverStepAndStartDoNothing():
        mController:Start().
        mClock:Advance(10000).
        mController:StepOnce().
        Assert:Equals(5, mGame:Generation).
        Assert:Equals(6, mRenderer:RenderCount).
        mController:Start().
        Assert:IsFalse(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetAfterGameOverLetsItRunAgain():
        mController:Start().
        mClock:Advance(10000).
        mController:Reset().
        Assert:IsFalse(mGame:IsOver).
        mController:Start().
        Assert:IsTrue(mController:IsRunning).
        mClock:Advance(250).
        Assert:Equals(1, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExecuteRunsEachCommand():
        mController:Execute(GameCommand:Start).
        Assert:IsTrue(mController:IsRunning).
        mController:Execute(GameCommand:PauseGame).
        Assert:IsFalse(mController:IsRunning).
        mController:Execute(GameCommand:StepOnce).
        Assert:Equals(1, mGame:Generation).
        mController:Execute(GameCommand:SpeedUp).
        Assert:Equals(4, mController:SpeedLevel).
        mController:Execute(GameCommand:SlowDown).
        Assert:Equals(3, mController:SpeedLevel).
        mController:Execute(GameCommand:Reset).
        Assert:Equals(0, mGame:Generation).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ExecuteRejectsUndoMove():
        mController:Execute(GameCommand:UndoMove).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsTheClockAndStopsListening():
        mController:Start().
        mController:Dispose().
        Assert:IsFalse(mClock:IsRunning).
        mClock:Start().
        mClock:Advance(5000).
        Assert:Equals(0, mGame:Generation).
        /* a second call is harmless */
        mController:Dispose().
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutAGame():
        DEFINE VARIABLE g AS ISteppableGame NO-UNDO.
        NEW GameController(g, mRenderer, mClock).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutARenderer():
        DEFINE VARIABLE r AS IGridRenderer NO-UNDO.
        NEW GameController(mGame, r, mClock).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutAClock():
        DEFINE VARIABLE c AS IClock NO-UNDO.
        NEW GameController(mGame, mRenderer, c).
    END METHOD.

END CLASS.
