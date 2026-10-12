/* A source of regular ticks. The WinForms clock wraps a Windows timer. The test clock is
   advanced by hand, so games that depend on time are deterministic under test. */
USING Prolif.Engine.*.

INTERFACE Prolif.Engine.IClock:

    /* Milliseconds between ticks. */
    DEFINE PUBLIC PROPERTY Interval AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY IsRunning AS LOGICAL NO-UNDO
        GET.

    /* Raised once per interval while running, with the milliseconds that have elapsed. */
    DEFINE PUBLIC EVENT Tick SIGNATURE VOID (INPUT piElapsedMs AS INTEGER).

    METHOD PUBLIC VOID Start().

    METHOD PUBLIC VOID Stop().

END INTERFACE.
