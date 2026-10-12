/* A clock driven by a Windows timer, for the GUI. The timer raises its tick on the UI thread,
   so game code and drawing never race. Dispose stops the timer, stops listening to it and
   frees it: call it when the window closes. */
USING Progress.Lang.*.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING Prolif.Core.GridException.
USING Prolif.Engine.IClock.
USING Prolif.UI.WinForms.WinFormsClock.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.WinFormsClock FINAL IMPLEMENTS IClock:

    DEFINE PRIVATE VARIABLE mTimer    AS Timer   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed AS LOGICAL NO-UNDO.

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
        Tick:Publish(mTimer:Interval).
    END METHOD.

END CLASS.
