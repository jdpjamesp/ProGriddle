/* The generated colours of Blast Buddies: the tone rows by name and the named colours as numbers, and the three terrain themes. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddiesLookTests:

    @Test.
    METHOD PUBLIC VOID TheTwelveToneRowsAreFiveColoursEachWithTheFourTeamsFirst():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(12, NUM-ENTRIES(BuddiesLook:ToneRowNames())).
        Assert:Equals("Reds", ENTRY(1, BuddiesLook:ToneRowNames())).
        Assert:Equals("Blues", ENTRY(2, BuddiesLook:ToneRowNames())).
        Assert:Equals("Teals", ENTRY(3, BuddiesLook:ToneRowNames())).
        Assert:Equals("Grapes", ENTRY(4, BuddiesLook:ToneRowNames())).
        DO i = 1 TO 12:
            Assert:IsTrue(NUM-ENTRIES(BuddiesLook:ToneRow(ENTRY(i, BuddiesLook:ToneRowNames()))) = 5, ENTRY(i, BuddiesLook:ToneRowNames())).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARowGivesItsFiveHexColoursFromTheLightestToTheDarkest():
        Assert:Equals("F8C8C4,EF7F76,E8483C,9F342E,571F1F", BuddiesLook:ToneRow("Reds")).
        Assert:Equals("C5D5F8,779EEE,3D74E6,2B51A1,192F5C", BuddiesLook:ToneRow("Blues")).
        Assert:Equals("FFF6C0,FFD54A,FF8A1E,E5402A,8A2A1E", BuddiesLook:ToneRow("Blast")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NamedColoursAreTheNumbersOfTheirHex():
        Assert:Equals(ColourMath:FromHex("1C1426"), BuddiesLook:Colour(BuddyTint:Ink)).
        Assert:Equals(ColourMath:FromHex("FFFFFF"), BuddiesLook:Colour(BuddyTint:Lens)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), BuddiesLook:Colour(BuddyTint:Accent)).
        Assert:Equals(ColourMath:FromHex("FFF2A0"), BuddiesLook:Colour(BuddyTint:TitleTop)).
        Assert:Equals(ColourMath:FromHex("FF6A2A"), BuddiesLook:Colour(BuddyTint:TitleBottom)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreFortySixNamedColoursAndTheyAreAllInTheTable():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(45, INTEGER(BuddyTint:Sheet)).
        DO i = 0 TO 45:
            Assert:IsTrue(BuddiesLook:Colour(BuddyTint:GetEnum(i)) >= 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANeededNameThatIsMissingOrUnknownThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            x = BuddiesLook:ToneRow("Purple").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            x = BuddiesLook:ToneRow(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            n = BuddiesLook:Colour(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThemeColoursAreTheDesignsForEachOfTheThreeThemes():
        Assert:Equals(ColourMath:FromHex("5AAEE8"), TerrainThemes:Colour(Theme:Meadow, ThemeKey:SkyTop)).
        Assert:Equals(ColourMath:FromHex("F2885E"), TerrainThemes:Colour(Theme:Canyon, ThemeKey:SkyTop)).
        Assert:Equals(ColourMath:FromHex("B48CE8"), TerrainThemes:Colour(Theme:Candy, ThemeKey:SkyTop)).
        Assert:Equals(ColourMath:FromHex("B8F060"), TerrainThemes:Colour(Theme:Meadow, ThemeKey:Top1)).
        Assert:Equals(ColourMath:FromHex("FFFFFF"), TerrainThemes:Colour(Theme:Candy, ThemeKey:Top1)).
        Assert:Equals(ColourMath:FromHex("A0663A"), TerrainThemes:Colour(Theme:Meadow, ThemeKey:Soil)).
        Assert:Equals(ColourMath:FromHex("86ECC0"), TerrainThemes:Colour(Theme:Candy, ThemeKey:WaterTop)).
        Assert:Equals(ColourMath:FromHex("D8F2FF"), TerrainThemes:Colour(Theme:Meadow, ThemeKey:Foam)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKeyOfEveryThemeHasAColourAndTheThemesDiffer():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE same AS INTEGER NO-UNDO.
        Assert:Equals(24, INTEGER(ThemeKey:Foam)).
        DO t = 0 TO 2:
            DO k = 0 TO 24:
                Assert:IsTrue(TerrainThemes:Colour(Theme:GetEnum(t), ThemeKey:GetEnum(k)) > 0).
            END.
        END.
        /* the three skies are three different colours */
        Assert:IsTrue(TerrainThemes:Colour(Theme:Meadow, ThemeKey:SkyLow) <> TerrainThemes:Colour(Theme:Canyon, ThemeKey:SkyLow)).
        Assert:IsTrue(TerrainThemes:Colour(Theme:Canyon, ThemeKey:SkyLow) <> TerrainThemes:Colour(Theme:Candy, ThemeKey:SkyLow)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANeededThemeOrKeyThatIsMissingThrowsGridException():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            n = TerrainThemes:Colour(?, ThemeKey:Top1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            n = TerrainThemes:Colour(Theme:Meadow, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
