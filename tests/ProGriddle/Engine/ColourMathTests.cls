/* The colour maths: hex text, the three parts of a colour and mixing. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.ColourMathTests:

    METHOD PRIVATE LOGICAL Refused(INPUT pcHex AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            ColourMath:FromHex(pcHex).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextThatIsNotAColourIsRefused():
        Assert:IsTrue(Refused("FFF")).
        Assert:IsTrue(Refused("FFFFFFF")).
        Assert:IsTrue(Refused("GG0000")).
        Assert:IsTrue(Refused("")).
        Assert:IsTrue(Refused(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePartsOfAColourAreItsRedGreenAndBlue():
        Assert:Equals(255, ColourMath:Red(16744448)).
        Assert:Equals(128, ColourMath:Green(16744448)).
        Assert:Equals(0, ColourMath:Blue(16744448)).
        Assert:Equals(7, ColourMath:Blue(ColourMath:FromHex("010207"))).
        Assert:Equals(1, ColourMath:Red(ColourMath:FromHex("010207"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RgbPutsThePartsBackTogetherAndKeepsThemInRange():
        Assert:Equals(16744448, ColourMath:Rgb(255, 128, 0)).
        Assert:Equals(16777215, ColourMath:Rgb(300, 255, 999)).
        Assert:Equals(0, ColourMath:Rgb(-5, -1, -300)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixGoesFromOneColourToTheOtherInEvenSteps():
        DEFINE VARIABLE black AS INTEGER NO-UNDO.
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        black = 0.
        white = 16777215.
        Assert:Equals(black, ColourMath:Mix(black, white, 0, 10)).
        Assert:Equals(white, ColourMath:Mix(black, white, 10, 10)).
        Assert:Equals(ColourMath:Rgb(128, 128, 128), ColourMath:Mix(black, white, 5, 10)).
        Assert:Equals(ColourMath:Rgb(51, 51, 51), ColourMath:Mix(black, white, 2, 10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixKeepsItsPartInRangeAndAZeroStepCountGivesTheFirstColour():
        Assert:Equals(16777215, ColourMath:Mix(0, 16777215, 99, 10)).
        Assert:Equals(0, ColourMath:Mix(0, 16777215, -4, 10)).
        Assert:Equals(0, ColourMath:Mix(0, 16777215, 3, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixWorksOnEachPartSeparatelyAndGoingDown():
        DEFINE VARIABLE start AS INTEGER NO-UNDO.
        DEFINE VARIABLE dest AS INTEGER NO-UNDO.
        start = ColourMath:Rgb(200, 100, 0).
        dest = ColourMath:Rgb(0, 100, 200).
        Assert:Equals(ColourMath:Rgb(100, 100, 100), ColourMath:Mix(start, dest, 1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToHexIsTheSixDigitsFromHexBackAgain():
        Assert:Equals("000000", ColourMath:ToHex(0)).
        Assert:Equals("FFFFFF", ColourMath:ToHex(16777215)).
        Assert:Equals("0A0E16", ColourMath:ToHex(ColourMath:FromHex("0A0E16"))).
        Assert:Equals("FFA24A", ColourMath:ToHex(ColourMath:FromHex("ffa24a"))).
        Assert:Equals("123456", ColourMath:ToHex(ColourMath:Rgb(18, 52, 86))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ScaleMultipliesEachPartByAPercentage():
        Assert:Equals(ColourMath:Rgb(100, 50, 0), ColourMath:Scale(ColourMath:Rgb(200, 100, 0), 50)).
        Assert:Equals(ColourMath:Rgb(20, 40, 60), ColourMath:Scale(ColourMath:Rgb(20, 40, 60), 100)).
        Assert:Equals(0, ColourMath:Scale(ColourMath:Rgb(20, 40, 60), 0)).
        /* 244 * 45 percent is 109.8, which rounds to 110 */
        Assert:Equals(ColourMath:Rgb(110, 0, 0), ColourMath:Scale(ColourMath:Rgb(244, 0, 0), 45)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ScaleKeepsEachPartInRange():
        Assert:Equals(ColourMath:Rgb(255, 255, 255), ColourMath:Scale(ColourMath:Rgb(200, 200, 200), 500)).
        Assert:Equals(0, ColourMath:Scale(ColourMath:Rgb(200, 200, 200), -20)).
    END METHOD.

END CLASS.
