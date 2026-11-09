/* The generated art of Football Manager: every sprite is as large as it says, every letter in it has a colour, and a few known colours and sprites are what the design says. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballArtTests:

    @Test.
    METHOD PUBLIC VOID ThereAreNinetySixSprites():
        Assert:Equals(96, FootballArt:Count()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySpriteHasAsManyCellsAsItsSizeAndAnOriginInside():
        VAR INTEGER i.
        VAR FootballSprite sprite.
        DO i = 0 TO FootballArt:Count() - 1:
            sprite = FootballSprite:GetEnum(i).
            Assert:Equals(FootballArt:Width(sprite) * FootballArt:Height(sprite), LENGTH(FootballArt:Cells(sprite))).
            Assert:IsTrue(FootballArt:OriginX(sprite) >= 0 AND FootballArt:OriginX(sprite) < FootballArt:Width(sprite)).
            Assert:IsTrue(FootballArt:OriginY(sprite) >= 0 AND FootballArt:OriginY(sprite) < FootballArt:Height(sprite)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryLetterOfASpriteHasAColourInItsPalette():
        VAR INTEGER i.
        VAR INTEGER c.
        VAR CHARACTER cells.
        VAR CHARACTER palette.
        VAR CHARACTER ch.
        VAR FootballSprite sprite.
        DO i = 0 TO FootballArt:Count() - 1:
            sprite = FootballSprite:GetEnum(i).
            cells = FootballArt:Cells(sprite).
            palette = ";" + FootballArt:Palette(sprite).
            DO c = 1 TO LENGTH(cells):
                ch = SUBSTRING(cells, c, 1).
                IF ch <> "." AND INDEX("12345", ch) = 0 THEN
                    Assert:IsTrue(INDEX(palette, ";" + ch + "=") > 0).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMatchFiguresAreEightByTwelveWithTheirFeetAtTheOrigin():
        Assert:Equals(8, FootballArt:Width(FootballSprite:FigStandWhite)).
        Assert:Equals(12, FootballArt:Height(FootballSprite:FigStandWhite)).
        Assert:Equals(4, FootballArt:OriginX(FootballSprite:FigStandWhite)).
        Assert:Equals(11, FootballArt:OriginY(FootballSprite:FigStandWhite)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGoalMouthIsNinetySixBySixtyFourAndTheBallFiveByFive():
        Assert:Equals(96, FootballArt:Width(FootballSprite:GoalMouth)).
        Assert:Equals(64, FootballArt:Height(FootballSprite:GoalMouth)).
        Assert:Equals(5, FootballArt:Width(FootballSprite:BallRoll1)).
        Assert:Equals(5, FootballArt:Height(FootballSprite:BallRoll1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpritesPaletteHoldsItsFixedColoursAsHex():
        /* the standing white figure has skin, hair, boots and the hoop among its letters */
        Assert:IsTrue(INDEX(FootballArt:Palette(FootballSprite:FigStandWhite), "A=F2C6A0") > 0).
        Assert:IsTrue(INDEX(FootballArt:Palette(FootballSprite:FigStandWhite), "O=17120E") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFixedColoursAreThoseOfThePalette():
        Assert:Equals(INTEGER(0x0C1311), FootballLook:Colour(FootballTint:Tunnel)).
        Assert:Equals(INTEGER(0x14231E), FootballLook:Colour(FootballTint:Board)).
        Assert:Equals(INTEGER(0xF1ECD9), FootballLook:Colour(FootballTint:Chalk)).
        Assert:Equals(INTEGER(0xFF6F61), FootballLook:Colour(FootballTint:ChalkRed)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheToneRowsRunFromHighlightToEdge():
        Assert:Equals(INTEGER(0xFFFFFF), FootballLook:Tone(FootballRow:White, 1)).
        Assert:Equals(INTEGER(0xE2E5EA), FootballLook:Tone(FootballRow:White, 3)).
        Assert:Equals(INTEGER(0x545A68), FootballLook:Tone(FootballRow:White, 5)).
        Assert:Equals(INTEGER(0xF2C230), FootballLook:Tone(FootballRow:Keeper, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATonePastFiveOrABackAndAnUnknownColourAreRefused():
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            FootballLook:Tone(FootballRow:White, 6).
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
        refused = FALSE.
        DO ON ERROR UNDO, THROW:
            FootballArt:Cells(?).
            CATCH e2 AS Progress.Lang.Error:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
    END METHOD.

END CLASS.
