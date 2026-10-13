/* Ticks reads the Stopwatch, so these run under prowin -b with the other WinForms tests. */
USING OpenEdge.Core.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.TicksTests:

    @Test.
    METHOD PUBLIC VOID TimeNeverGoesBackwards():
        DEFINE VARIABLE a AS INT64 NO-UNDO.
        DEFINE VARIABLE b AS INT64 NO-UNDO.
        a = Ticks:Now().
        b = Ticks:Now().
        Assert:IsTrue(b >= a).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimeAdvancesAtAboutOneMillisecondAMillisecond():
        DEFINE VARIABLE a AS INT64 NO-UNDO.
        DEFINE VARIABLE b AS INT64 NO-UNDO.
        a = Ticks:Now().
        ETIME(TRUE).
        DO WHILE ETIME < 120:
        END.
        b = Ticks:Now().
        Assert:IsTrue(b - a >= 100).
        Assert:IsTrue(b - a < 400).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClockTickReportsAtLeastOneMillisecond():
        Assert:Equals(1, Ticks:Clamp(0, 30)).
        Assert:Equals(1, Ticks:Clamp(-5, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClockTickReportsWhatReallyPassedWhenThatIsReasonable():
        Assert:Equals(30, Ticks:Clamp(30, 30)).
        Assert:Equals(47, Ticks:Clamp(47, 30)).
        Assert:Equals(120, Ticks:Clamp(120, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClockTickReportsAtMostFourIntervals():
        Assert:Equals(120, Ticks:Clamp(121, 30)).
        Assert:Equals(120, Ticks:Clamp(60000, 30)).
        Assert:Equals(4000, Ticks:Clamp(9000000000, 1000)).
    END METHOD.

END CLASS.
