USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.RealTimeControllerTests:

    DEFINE PRIVATE VARIABLE mGame       AS CountingRealTimeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer   AS RecordingRenderer    NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock      AS FakeClock            NO-UNDO.
    DEFINE PRIVATE VARIABLE mController AS RealTimeController   NO-UNDO.

    /* A game that is over after 2500 ms of running, on a clock that ticks every 100 ms. */
    @Setup.
    METHOD PUBLIC VOID BuildController():
        mGame = NEW CountingRealTimeGame(NEW Grid(NEW ArrayStore(3, 3, "s")), 2500).
        mRenderer = NEW RecordingRenderer().
        mClock = NEW FakeClock().
        mClock:Interval = 100.
        mController = NEW RealTimeController(mGame, mRenderer, mClock).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseController():
        IF VALID-OBJECT(mController) THEN mController:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mController = ?.
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItIsBuiltPausedAndDrawsTheGameOnce():
        Assert:IsTrue(mGame:Paused).
        Assert:IsFalse(mController:IsRunning).
        Assert:Equals(1, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItIsPausableButNotSteppableAndHasNoSpeed():
        Assert:IsTrue(mController:Pausable).
        Assert:IsFalse(mController:Steppable).
        Assert:Equals(0, mController:SpeedLevel).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingHappensUntilItIsStarted():
        mClock:Advance(1000).
        Assert:Equals(0, mGame:TotalMs).
        Assert:Equals(1, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartRunsTheClockAndPassesEachTicksElapsedTimeToTheGame():
        mController:Start().
        Assert:IsTrue(mController:IsRunning).
        Assert:IsFalse(mGame:Paused).
        mClock:Advance(500).
        Assert:Equals(500, mGame:TotalMs).
        Assert:Equals(5, mGame:TickCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameIsRedrawnOnlyWhenItSaysSomethingChanged():
        mController:Start().
        mClock:Advance(300).
        Assert:Equals(4, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PauseGameStopsTheClockAndPausesTheGame():
        mController:Start().
        mClock:Advance(200).
        mController:PauseGame().
        Assert:IsFalse(mController:IsRunning).
        Assert:IsTrue(mGame:Paused).
        mClock:Advance(1000).
        Assert:Equals(200, mGame:TotalMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PauseGameRedrawsOnceSoAPausedPictureCanShow():
        mController:Start().
        mClock:Advance(200).
        Assert:Equals(3, mRenderer:RenderCount).
        mController:PauseGame().
        Assert:Equals(4, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartAfterPauseCarriesOn():
        mController:Start().
        mClock:Advance(200).
        mController:PauseGame().
        mController:Start().
        mClock:Advance(300).
        Assert:Equals(500, mGame:TotalMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetStartsANewGameAndRunsItStraightAway():
        mController:Start().
        mClock:Advance(700).
        mController:Reset().
        Assert:Equals(1, mGame:InitialiseCount).
        Assert:Equals(0, mGame:TotalMs).
        Assert:IsTrue(mController:IsRunning).
        Assert:IsFalse(mGame:Paused).
        mClock:Advance(200).
        Assert:Equals(200, mGame:TotalMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetAfterGameOverRunsAgain():
        mController:Start().
        mClock:Advance(5000).
        Assert:IsTrue(mGame:IsOver).
        mController:Reset().
        Assert:IsFalse(mGame:IsOver).
        Assert:IsTrue(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClockStopsByItselfWhenTheGameIsOver():
        mController:Start().
        mClock:Advance(5000).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mController:IsRunning).
        Assert:Equals(2500, mGame:TotalMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsOverButStillAnimatingKeepsTheClockRunningAndBeingRedrawnUntilItStops():
        DEFINE VARIABLE game       AS AnimatedRealTimeGame NO-UNDO.
        DEFINE VARIABLE renderer   AS RecordingRenderer    NO-UNDO.
        DEFINE VARIABLE clock      AS FakeClock            NO-UNDO.
        DEFINE VARIABLE controller AS RealTimeController   NO-UNDO.
        DEFINE VARIABLE before     AS INTEGER              NO-UNDO.
        DO ON ERROR UNDO, THROW:
            /* over at 500 ms, animating for 300 ms more */
            game = NEW AnimatedRealTimeGame(NEW Grid(NEW ArrayStore(3, 3, "s")), 500, 300).
            renderer = NEW RecordingRenderer().
            clock = NEW FakeClock().
            clock:Interval = 100.
            controller = NEW RealTimeController(game, renderer, clock).
            controller:Start().
            clock:Advance(500).
            Assert:IsTrue(game:IsOver).
            Assert:IsTrue(controller:IsRunning).
            before = renderer:RenderCount.
            clock:Advance(100).
            Assert:Equals(before + 1, renderer:RenderCount).
            Assert:IsTrue(controller:IsRunning).
            clock:Advance(200).
            Assert:IsFalse(game:Animating).
            Assert:IsFalse(controller:IsRunning).
            Assert:Equals(800, game:TotalMs).
            FINALLY:
                IF VALID-OBJECT(controller) THEN controller:Dispose().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartDoesNothingOnceTheGameIsOver():
        mController:Start().
        mClock:Advance(5000).
        mController:Start().
        Assert:IsFalse(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RefreshDrawsAgainWithoutChangingTheGame():
        mController:Refresh().
        Assert:Equals(2, mRenderer:RenderCount).
        Assert:Equals(0, mGame:TotalMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExecuteRunsStartPauseAndReset():
        mController:Execute(GameCommand:Start).
        Assert:IsTrue(mController:IsRunning).
        mController:Execute(GameCommand:PauseGame).
        Assert:IsFalse(mController:IsRunning).
        mController:Execute(GameCommand:Reset).
        Assert:IsTrue(mController:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SteppingAndSpeedAreNotSupported():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mController:Execute(GameCommand:StepOnce).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mController:Execute(GameCommand:SpeedUp).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mController:SetSpeedLevel(3).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsTheClockAndStopsListeningToIt():
        mController:Start().
        mController:Dispose().
        Assert:IsFalse(mClock:IsRunning).
        mClock:Start().
        mClock:Advance(500).
        Assert:Equals(0, mGame:TotalMs).
        mController:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheConstructorRejectsMissingParts():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE rc     AS RealTimeController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            rc = NEW RealTimeController(?, mRenderer, mClock).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            rc = NEW RealTimeController(mGame, ?, mClock).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            rc = NEW RealTimeController(mGame, mRenderer, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
