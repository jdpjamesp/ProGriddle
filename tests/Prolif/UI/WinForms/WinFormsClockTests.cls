/* WinFormsClock wraps a Windows timer. Under prowin -b there is no .NET message loop (ABL
   says "You can only use the .NET event loop in a GUI application"), so the timer can never
   tick in these tests and they only cover the clock's own state. Real ticks are checked in
   the windowed end to end run of run-life.p (see the manual checklist in README.md). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING Prolif.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.WinFormsClockTests:

    DEFINE PRIVATE VARIABLE mClock AS WinFormsClock NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildClock():
        mClock = NEW WinFormsClock().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseClock():
        IF VALID-OBJECT(mClock) THEN mClock:Dispose().
        mClock = ?.
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
    METHOD PUBLIC VOID StartingARunningClockKeepsItRunning():
        mClock:Start().
        mClock:Start().
        Assert:IsTrue(mClock:IsRunning).
        mClock:Stop().
        mClock:Stop().
        Assert:IsFalse(mClock:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheIntervalCanBeChangedWhileStoppedOrRunning():
        mClock:Interval = 125.
        Assert:Equals(125, mClock:Interval).
        mClock:Start().
        mClock:Interval = 60.
        Assert:Equals(60, mClock:Interval).
        Assert:IsTrue(mClock:IsRunning).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID TheIntervalMustBeAtLeastOneMillisecond():
        mClock:Interval = 0.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsTheClockAndCanBeCalledTwice():
        mClock:Start().
        mClock:Dispose().
        Assert:IsFalse(mClock:IsRunning).
        mClock:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADisposedClockIgnoresStartAndStop():
        mClock:Dispose().
        mClock:Start().
        mClock:Stop().
    END METHOD.

END CLASS.
