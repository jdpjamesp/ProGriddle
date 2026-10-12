USING OpenEdge.Core.Assert.
USING Prolif.UI.Text.FakeClock.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.Text.FakeClockTests:

    DEFINE PRIVATE VARIABLE mTicks   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastMs  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mStopAt  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock   AS FakeClock NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID CreateClockBeforeEachTest():
        mTicks = 0.
        mLastMs = 0.
        mStopAt = 0.
        mClock = NEW FakeClock().
        mClock:Tick:Subscribe(OnTick).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID DisposeClockAfterEachTest():
        mClock:Tick:Unsubscribe(OnTick).
    END METHOD.

    METHOD PRIVATE VOID OnTick(INPUT piElapsedMs AS INTEGER):
        mTicks = mTicks + 1.
        mLastMs = piElapsedMs.
        IF mStopAt > 0 AND mTicks >= mStopAt THEN mClock:Stop().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartsStoppedWithAOneSecondInterval():
        Assert:IsFalse(mClock:IsRunning).
        Assert:Equals(1000, mClock:Interval).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartAndStopSwitchIsRunning():
        mClock:Start().
        Assert:IsTrue(mClock:IsRunning).
        mClock:Stop().
        Assert:IsFalse(mClock:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RaisesOneTickPerFullInterval():
        mClock:Interval = 250.
        mClock:Start().
        mClock:Advance(1000).
        Assert:Equals(4, mTicks).
        Assert:Equals(250, mLastMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CarriesAPartIntervalOverToTheNextCall():
        mClock:Interval = 100.
        mClock:Start().
        mClock:Advance(60).
        Assert:Equals(0, mTicks).
        mClock:Advance(60).
        Assert:Equals(1, mTicks).
        mClock:Advance(80).
        Assert:Equals(2, mTicks).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IgnoresTimeWhileStopped():
        mClock:Interval = 100.
        mClock:Advance(1000).
        Assert:Equals(0, mTicks).
        mClock:Start().
        mClock:Stop().
        mClock:Advance(1000).
        Assert:Equals(0, mTicks).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAgainDiscardsAPartInterval():
        mClock:Interval = 100.
        mClock:Start().
        mClock:Advance(90).
        mClock:Stop().
        mClock:Start().
        mClock:Advance(90).
        Assert:Equals(0, mTicks).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingARunningClockDoesNotResetIt():
        mClock:Interval = 100.
        mClock:Start().
        mClock:Advance(90).
        mClock:Start().
        mClock:Advance(10).
        Assert:Equals(1, mTicks).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHandlerThatStopsTheClockEndsTheRunOfTicks():
        mClock:Interval = 100.
        mStopAt = 2.
        mClock:Start().
        mClock:Advance(1000).
        Assert:Equals(2, mTicks).
        Assert:IsFalse(mClock:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewIntervalAppliesToLaterTicks():
        mClock:Interval = 100.
        mClock:Start().
        mClock:Advance(300).
        Assert:Equals(3, mTicks).
        mClock:Interval = 50.
        mClock:Advance(100).
        Assert:Equals(5, mTicks).
        Assert:Equals(50, mLastMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AdvancingByZeroRaisesNothing():
        mClock:Start().
        mClock:Advance(0).
        Assert:Equals(0, mTicks).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID AdvanceThrowsForNegativeTime():
        mClock:Advance(-1).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID IntervalThrowsBelowOneMillisecond():
        mClock:Interval = 0.
    END METHOD.

END CLASS.
