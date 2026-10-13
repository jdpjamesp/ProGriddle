USING OpenEdge.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeSizesTests:

    @Test.
    METHOD PUBLIC VOID TheOfferedSizesAreSmallestFirstAndAllWithinTheLimits():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE previousWidth AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(LifeSizes:Names()):
            Assert:IsTrue(LifeSizes:WidthOf(ENTRY(i, LifeSizes:Names())) > previousWidth).
            previousWidth = LifeSizes:WidthOf(ENTRY(i, LifeSizes:Names())).
            Assert:IsTrue(LifeSizes:HeightOf(ENTRY(i, LifeSizes:Names())) >= LifeSizes:MinSide()).
        END.
        Assert:IsTrue(LOOKUP("100 x 70", LifeSizes:Names()) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLimitsAreFiveAndFourHundred():
        Assert:Equals(5, LifeSizes:MinSide()).
        Assert:Equals(400, LifeSizes:MaxSide()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALabelIsWidthByHeight():
        Assert:Equals("100 x 70", LifeSizes:Label(100, 70)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WidthAndHeightAreReadFromTheLabel():
        Assert:Equals(150, LifeSizes:WidthOf("150 x 100")).
        Assert:Equals(100, LifeSizes:HeightOf("150 x 100")).
        Assert:Equals(7, LifeSizes:WidthOf("7x9")).
        Assert:Equals(9, LifeSizes:HeightOf(" 7 x 9 ")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TextThatIsNotASizeIsRefused():
        LifeSizes:WidthOf("big").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideThatIsNotANumberIsRefused():
        LifeSizes:HeightOf("10 x wide").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideBelowTheMinimumIsRefused():
        LifeSizes:WidthOf("4 x 10").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideAboveTheMaximumIsRefused():
        LifeSizes:HeightOf("10 x 401").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheUnknownValueIsRefused():
        LifeSizes:WidthOf(?).
    END METHOD.

END CLASS.
