/* A clock that only moves when told to, so tests are deterministic. Advance(ms) raises one
   Tick for every full Interval that has passed while the clock is running. Time that passes
   while the clock is stopped is ignored. A part interval is carried over to the next call. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.Text.FakeClock FINAL IMPLEMENTS IClock:

    DEFINE PRIVATE VARIABLE mInterval AS INTEGER NO-UNDO INITIAL 1000.
    DEFINE PRIVATE VARIABLE mRunning  AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mPending  AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Interval AS INTEGER NO-UNDO
        GET():
            RETURN mInterval.
        END GET.
        SET(INPUT piValue AS INTEGER):
            IF piValue < 1 THEN
                UNDO, THROW NEW GridException("A clock interval must be at least 1 ms").
            mInterval = piValue.
        END SET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET():
            RETURN mRunning.
        END GET.

    DEFINE PUBLIC EVENT Tick SIGNATURE VOID (INPUT piElapsedMs AS INTEGER).

    METHOD PUBLIC VOID Start():
        IF mRunning THEN RETURN.
        mRunning = TRUE.
        mPending = 0.
    END METHOD.

    METHOD PUBLIC VOID Stop():
        mRunning = FALSE.
        mPending = 0.
    END METHOD.

    /* Moves time on by piMs milliseconds and raises the ticks that fall due. A handler that
       stops the clock ends the run of ticks. */
    METHOD PUBLIC VOID Advance(INPUT piMs AS INTEGER):
        IF piMs < 0 THEN
            UNDO, THROW NEW GridException("Time cannot go backwards").
        IF NOT mRunning THEN RETURN.
        mPending = mPending + piMs.
        DO WHILE mRunning AND mPending >= mInterval:
            mPending = mPending - mInterval.
            Tick:Publish(mInterval).
        END.
    END METHOD.

END CLASS.
