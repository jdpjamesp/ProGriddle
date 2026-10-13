USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.BoardSizesTests:

    @Test.
    METHOD PUBLIC VOID ALabelIsWidthByHeight():
        Assert:Equals("100 x 70", BoardSizes:Label(100, 70)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WidthAndHeightAreReadFromTheLabel():
        Assert:Equals(150, BoardSizes:WidthOf("150 x 100", 5, 400)).
        Assert:Equals(100, BoardSizes:HeightOf("150 x 100", 5, 400)).
        Assert:Equals(7, BoardSizes:WidthOf("7x9", 5, 400)).
        Assert:Equals(9, BoardSizes:HeightOf(" 7 x 9 ", 5, 400)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLimitsAreInclusive():
        Assert:Equals(5, BoardSizes:WidthOf("5 x 40", 5, 40)).
        Assert:Equals(40, BoardSizes:HeightOf("5 x 40", 5, 40)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TextThatIsNotASizeIsRefused():
        BoardSizes:WidthOf("big", 5, 400).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideThatIsNotANumberIsRefused():
        BoardSizes:HeightOf("10 x wide", 5, 400).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideBelowTheMinimumIsRefused():
        BoardSizes:WidthOf("4 x 10", 5, 400).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASideAboveTheMaximumIsRefused():
        BoardSizes:HeightOf("10 x 41", 5, 40).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheUnknownValueIsRefused():
        BoardSizes:WidthOf(?, 5, 400).
    END METHOD.

END CLASS.
