USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.PixelFontTests:

    @Test.
    METHOD PUBLIC VOID AGlyphIsFiveCellsWideAndSevenHigh():
        Assert:Equals(5, PixelFont:GlyphWidth()).
        Assert:Equals(7, PixelFont:GlyphHeight()).
        Assert:Equals(1, PixelFont:Gap()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryGlyphIsSevenRowsOfFiveCells():
        DEFINE VARIABLE chars AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE glyph AS CHARACTER NO-UNDO.
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-<>=?.:!+ ".
        DO i = 1 TO LENGTH(chars):
            Assert:IsTrue(PixelFont:HasGlyph(SUBSTRING(chars, i, 1)), SUBSTRING(chars, i, 1)).
            glyph = PixelFont:Glyph(SUBSTRING(chars, i, 1)).
            Assert:IsTrue(NUM-ENTRIES(glyph, "/") = 7, SUBSTRING(chars, i, 1)).
            DO r = 1 TO 7:
                Assert:IsTrue(LENGTH(ENTRY(r, glyph, "/")) = 5, SUBSTRING(chars, i, 1)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLetterIIsABarWithSerifs():
        Assert:Equals(".###./..#../..#../..#../..#../..#../.###.", PixelFont:Glyph("I")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDigitOneAndTheSpaceLookRight():
        Assert:Equals("..#../.##../..#../..#../..#../..#../.###.", PixelFont:Glyph("1")).
        Assert:Equals(".....f.....f.....f.....f.....f.....f.....", REPLACE(PixelFont:Glyph(" "), "/", "f")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LowerCaseIsDrawnAsCapitals():
        Assert:Equals(PixelFont:Glyph("S"), PixelFont:Glyph("s")).
        Assert:IsTrue(PixelFont:HasGlyph("q")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACharacterWithNoGlyphIsDrawnAsAQuestionMark():
        Assert:IsFalse(PixelFont:HasGlyph("%")).
        Assert:IsFalse(PixelFont:HasGlyph("")).
        Assert:IsFalse(PixelFont:HasGlyph(?)).
        Assert:IsFalse(PixelFont:HasGlyph("AB")).
        Assert:Equals(PixelFont:Glyph("?"), PixelFont:Glyph("%")).
        Assert:Equals(PixelFont:Glyph("?"), PixelFont:Glyph(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoTwoLettersOrDigitsLookTheSame():
        DEFINE VARIABLE chars AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER   NO-UNDO.
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".
        DO i = 1 TO LENGTH(chars):
            DO j = i + 1 TO LENGTH(chars):
                Assert:IsTrue(PixelFont:Glyph(SUBSTRING(chars, i, 1)) <> PixelFont:Glyph(SUBSTRING(chars, j, 1)),
                              SUBSTRING(chars, i, 1) + " and " + SUBSTRING(chars, j, 1) + " are the same").
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWidthOfTextIsTheGlyphsAndTheGapsBetweenThem():
        Assert:Equals(0, PixelFont:WidthOf("")).
        Assert:Equals(0, PixelFont:WidthOf(?)).
        Assert:Equals(5, PixelFont:WidthOf("A")).
        Assert:Equals(11, PixelFont:WidthOf("AB")).
        Assert:Equals(47, PixelFont:WidthOf("SCORE<1>")).
    END METHOD.

END CLASS.
