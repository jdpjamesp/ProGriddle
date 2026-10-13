/* A clock driven by a Windows timer, for the GUI. The timer raises its tick on the UI thread,
   so game code and drawing never race. Each tick reports the milliseconds that really passed
   since the last one (at most four intervals, see Ticks), not the nominal interval, because a timer
   that is busy ticks late and a real time game must not run slow. Dispose stops the timer, stops listening to it and
   frees it: call it when the window closes. */
USING Progress.Lang.*.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.WinFormsClock FINAL IMPLEMENTS IClock:

    DEFINE PRIVATE VARIABLE mTimer    AS Timer   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed AS LOGICAL NO-UNDO.
    /* Ticks:Now at the previous tick, so a tick can report the time that really passed */
    DEFINE PRIVATE VARIABLE mLast     AS INT64   NO-UNDO.

    DEFINE PUBLIC PROPERTY Interval AS INTEGER NO-UNDO
        GET():
            RETURN mTimer:Interval.
        END GET.
        SET(INPUT piValue AS INTEGER):
            IF piValue < 1 THEN
                UNDO, THROW NEW GridException("A clock interval must be at least 1 ms").
            mTimer:Interval = piValue.
        END SET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET():
            RETURN mTimer:Enabled.
        END GET.

    DEFINE PUBLIC EVENT Tick SIGNATURE VOID (INPUT piElapsedMs AS INTEGER).

    /* Stopped, with a one second interval. */
    CONSTRUCTOR PUBLIC WinFormsClock():
        mTimer = NEW Timer().
        mTimer:Interval = 1000.
        mTimer:Enabled = FALSE.
        mTimer:Tick:Subscribe(OnTimerTick).
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC WinFormsClock():
        IF NOT mDisposed AND VALID-OBJECT(mTimer) THEN mTimer:Dispose().
    END DESTRUCTOR.

    METHOD PUBLIC VOID Start():
        IF mDisposed THEN RETURN.
        IF NOT mTimer:Enabled THEN mLast = Ticks:Now().
        mTimer:Start().
    END METHOD.

    METHOD PUBLIC VOID Stop():
        IF mDisposed THEN RETURN.
        mTimer:Stop().
    END METHOD.

    /* Safe to call more than once. A disposed clock ignores Start and Stop. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        mTimer:Stop().
        mTimer:Tick:Unsubscribe(OnTimerTick).
        mTimer:Dispose().
    END METHOD.

    METHOD PRIVATE VOID OnTimerTick(INPUT poSender AS System.Object, INPUT poArgs AS System.EventArgs):
        DEFINE VARIABLE tickNow AS INT64   NO-UNDO.
        DEFINE VARIABLE elapsed AS INTEGER NO-UNDO.
        tickNow = Ticks:Now().
        /* a window being dragged can hold the timer up for a long time: report at most four intervals,
           and at least one millisecond */
        elapsed = Ticks:Clamp(tickNow - mLast, mTimer:Interval).
        /* remembered before the handlers run, so the time they take counts towards the next tick */
        mLast = tickNow.
        Tick:Publish(elapsed).
    END METHOD.

END CLASS.
