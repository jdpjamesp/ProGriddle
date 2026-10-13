USING OpenEdge.Core.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeSizesTests:

    @Test.
    METHOD PUBLIC VOID TheLimitsAreFiveAndForty():
        Assert:Equals(5, SnakeSizes:MinSide()).
        Assert:Equals(40, SnakeSizes:MaxSide()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOfferedSizesAreSmallestFirstAndAllWithinTheLimits():
        DEFINE VARIABLE i             AS INTEGER NO-UNDO.
        DEFINE VARIABLE previousCells AS INTEGER NO-UNDO.
        DEFINE VARIABLE cells         AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(SnakeSizes:Names()):
            cells = SnakeSizes:WidthOf(ENTRY(i, SnakeSizes:Names())) * SnakeSizes:HeightOf(ENTRY(i, SnakeSizes:Names())).
            Assert:IsTrue(cells > previousCells).
            previousCells = cells.
        END.
        Assert:IsTrue(LOOKUP("20 x 20", SnakeSizes:Names()) > 0).
        Assert:IsTrue(LOOKUP("40 x 40", SnakeSizes:Names()) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALabelIsWidthByHeight():
        Assert:Equals("30 x 20", SnakeSizes:Label(30, 20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WidthAndHeightAreReadFromTheLabel():
        Assert:Equals(30, SnakeSizes:WidthOf("30 x 20")).
        Assert:Equals(20, SnakeSizes:HeightOf("30 x 20")).
        Assert:Equals(5, SnakeSizes:WidthOf("5x40")).
        Assert:Equals(40, SnakeSizes:HeightOf(" 5 x 40 ")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TextThatIsNotASizeIsRefused():
        SnakeSizes:WidthOf("big").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideBelowTheMinimumIsRefused():
        SnakeSizes:WidthOf("4 x 10").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideAboveTheMaximumIsRefused():
        SnakeSizes:HeightOf("10 x 41").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheUnknownValueIsRefused():
        SnakeSizes:HeightOf(?).
    END METHOD.

END CLASS.
