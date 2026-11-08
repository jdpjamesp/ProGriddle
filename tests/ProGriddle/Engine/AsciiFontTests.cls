/* The ASCII font: every printable character as an 8 x 14 bitmap, and the extras for the dungeon. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.AsciiFontTests:

    METHOD PRIVATE INTEGER OnPixels(INPUT piCode AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER n.
        DO y = 0 TO AsciiFont:GlyphHeight() - 1:
            DO x = 0 TO AsciiFont:GlyphWidth() - 1:
                IF AsciiFont:PixelOn(piCode, x, y) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGlyphIsEightByFourteen():
        Assert:Equals(8, AsciiFont:GlyphWidth()).
        Assert:Equals(14, AsciiFont:GlyphHeight()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPrintableAsciiCharacterAndEveryExtraHasAGlyph():
        VAR INTEGER c.
        Assert:Equals(32, AsciiFont:FirstCode()).
        Assert:IsTrue(AsciiFont:LastCode() >= INTEGER(AsciiExtra:Shade)).
        DO c = 32 TO 126:
            Assert:IsTrue(AsciiFont:HasGlyph(c)).
            Assert:Equals(28, LENGTH(AsciiFont:Rows(c))).
        END.
        Assert:IsTrue(AsciiFont:HasGlyph(INTEGER(AsciiExtra:WallAcross))).
        Assert:IsTrue(AsciiFont:HasGlyph(INTEGER(AsciiExtra:Shade))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CodesOutsideTheTableHaveNoGlyph():
        Assert:IsFalse(AsciiFont:HasGlyph(31)).
        Assert:IsFalse(AsciiFont:HasGlyph(AsciiFont:LastCode() + 1)).
        Assert:IsFalse(AsciiFont:HasGlyph(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACodeWithNoGlyphDrawsAsAQuestionMark():
        Assert:Equals(AsciiFont:Rows(ASC("?")), AsciiFont:Rows(5)).
        Assert:Equals(AsciiFont:Rows(ASC("?")), AsciiFont:Rows(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpaceIsEmptyAndTheLettersAreNot():
        Assert:Equals(0, OnPixels(32)).
        Assert:IsTrue(OnPixels(ASC("@")) > 10).
        Assert:IsTrue(OnPixels(ASC("W")) > 10).
        Assert:IsTrue(OnPixels(ASC("g")) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCharactersAreToldApart():
        Assert:IsTrue(AsciiFont:Rows(ASC("a")) <> AsciiFont:Rows(ASC("b"))).
        Assert:IsTrue(AsciiFont:Rows(ASC("l")) <> AsciiFont:Rows(ASC("I"))).
        Assert:IsTrue(AsciiFont:Rows(ASC("#")) <> AsciiFont:Rows(ASC("%"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWallAcrossRunsEdgeToEdgeAndTheWallDownTopToBottom():
        VAR INTEGER x.
        VAR INTEGER y.
        DO x = 0 TO 7:
            Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:WallAcross), x, 6)).
        END.
        DO y = 0 TO 13:
            Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:WallDown), 3, y)).
        END.
        Assert:IsFalse(AsciiFont:PixelOn(INTEGER(AsciiExtra:WallAcross), 0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCornersJoinTheWallsAroundThem():
        /* top left: a line goes right from the middle and down from the middle */
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerTopLeft), 7, 6)).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerTopLeft), 3, 13)).
        Assert:IsFalse(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerTopLeft), 0, 6)).
        /* bottom right: a line comes from the left and from above */
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerBottomRight), 0, 6)).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerBottomRight), 3, 0)).
        Assert:IsFalse(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerBottomRight), 3, 13)).
        /* top right and bottom left */
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerTopRight), 0, 6)).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerTopRight), 3, 13)).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerBottomLeft), 7, 6)).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:CornerBottomLeft), 3, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDotSitsInTheMiddleOfTheCell():
        Assert:Equals(4, OnPixels(INTEGER(AsciiExtra:Dot))).
        Assert:IsTrue(AsciiFont:PixelOn(INTEGER(AsciiExtra:Dot), 3, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBlockIsSolidAndTheShadeIsHalfFilled():
        Assert:Equals(112, OnPixels(INTEGER(AsciiExtra:Block))).
        Assert:Equals(56, OnPixels(INTEGER(AsciiExtra:Shade))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APixelOutsideTheGlyphIsRefused():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, THROW:
            AsciiFont:PixelOn(65, 8, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsciiFont:PixelOn(65, 0, 14).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsciiFont:PixelOn(65, -1, 0).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
