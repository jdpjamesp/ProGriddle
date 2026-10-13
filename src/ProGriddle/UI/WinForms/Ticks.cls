/* The time source of the window code. System.Environment:TickCount is a 32 bit number that wraps
   after about 25 days of uptime, and subtracting two readings across the wrap overflows an ABL
   INTEGER, so the clock and the fading notice read the high resolution Stopwatch instead, as a
   64 bit count of milliseconds that only goes up. */
USING Progress.Lang.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.Ticks FINAL:

    /* Milliseconds from some fixed moment, never going backwards. Only differences mean anything. */
    METHOD PUBLIC STATIC INT64 Now():
        RETURN INT64(TRUNCATE(System.Diagnostics.Stopwatch:GetTimestamp() * 1000 / System.Diagnostics.Stopwatch:Frequency, 0)).
    END METHOD.

    /* The time a timer tick should report: the time that really passed, but at least 1 ms and at
       most four intervals, because a window being dragged can hold a timer up for a long time and
       a game must not then jump ahead by all of it. */
    METHOD PUBLIC STATIC INTEGER Clamp(INPUT piElapsedMs AS INT64, INPUT piIntervalMs AS INTEGER):
        IF piElapsedMs < 1 THEN RETURN 1.
        IF piElapsedMs > 4 * piIntervalMs THEN RETURN 4 * piIntervalMs.
        RETURN INTEGER(piElapsedMs).
    END METHOD.

END CLASS.
