/* The colours and the art of Xevious, which are generated from the design file: every colour is in range, the palette has the seen of the
   design, a picture character stands for its colour, the family letters change with the ground, and every picture is the size the design
   says. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousLookTests:

    @Test.
    METHOD PUBLIC VOID EveryTintHasAColourInRangeAndThePaletteHasAtMostSixtyFourValues():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen AS CHARACTER NO-UNDO.
        DEFINE VARIABLE kinds AS INTEGER NO-UNDO.
        DO i = INTEGER(XeviousTint:Meadow) TO INTEGER(XeviousTint:Haze):
            c = XeviousLook:Colour(XeviousTint:GetEnum(i)).
            Assert:IsTrue(c >= 0 AND c <= 16777215).
            IF LOOKUP(STRING(c), seen) = 0 THEN ASSIGN seen = seen + (IF seen = "" THEN "" ELSE ",") + STRING(c) kinds = kinds + 1.
        END.
        Assert:IsTrue(kinds <= 64).
        Assert:Equals(67, INTEGER(XeviousTint:Haze) + 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheColoursAreTheValuesOfTheDesign():
        Assert:Equals(0x6E9A52, XeviousLook:Colour(XeviousTint:Meadow)).
        Assert:Equals(0xFF3D8E, XeviousLook:Colour(XeviousTint:Hot)).
        Assert:Equals(0x7CFFB4, XeviousLook:Colour(XeviousTint:Eye)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Eye), XeviousLook:Colour(XeviousTint:Core)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Zap), XeviousLook:Colour(XeviousTint:Flash)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:GlowLight), XeviousLook:Colour(XeviousTint:DawnTop)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Foam), XeviousLook:Colour(XeviousTint:Haze)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APictureCharacterStandsForItsColourAndADotForNone():
        Assert:Equals(-1, XeviousLook:CodeColour(".", FALSE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Meadow), XeviousLook:CodeColour(CHR(48 + INTEGER(XeviousTint:Meadow)), FALSE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Haze), XeviousLook:CodeColour(CHR(48 + INTEGER(XeviousTint:Haze)), TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFamilyLettersTurnGreenOrDryWithTheGround():
        Assert:Equals(XeviousLook:Colour(XeviousTint:Meadow), XeviousLook:CodeColour("#", FALSE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Ochre), XeviousLook:CodeColour("#", TRUE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:MeadowLight), XeviousLook:CodeColour("$", FALSE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:OchreLight), XeviousLook:CodeColour("$", TRUE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:MeadowDark), XeviousLook:CodeColour("%", FALSE)).
        Assert:Equals(XeviousLook:Colour(XeviousTint:OchreDark), XeviousLook:CodeColour("%", TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACharacterThatIsNotAColourIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            c = XeviousLook:CodeColour("~~", FALSE).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySpriteIsTheSizeTheDesignSaysAndHasItsRows():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rows AS CHARACTER NO-UNDO.
        DO i = INTEGER(XeviousPicture:Lark) TO INTEGER(XeviousPicture:MiniLark):
            rows = XeviousArt:Rows(XeviousPicture:GetEnum(i)).
            Assert:Equals(XeviousArt:Height(XeviousPicture:GetEnum(i)), NUM-ENTRIES(rows, "/")).
            Assert:Equals(XeviousArt:Width(XeviousPicture:GetEnum(i)), LENGTH(ENTRY(1, rows, "/"))).
        END.
        Assert:Equals(16, XeviousArt:Width(XeviousPicture:Lark)).
        Assert:Equals(32, XeviousArt:Width(XeviousPicture:CitadelCore)).
        Assert:Equals(12, XeviousArt:Width(XeviousPicture:Midge1)).
        Assert:Equals(3, XeviousArt:Width(XeviousPicture:Zap)).
        Assert:Equals(6, XeviousArt:Height(XeviousPicture:Zap)).
        Assert:Equals(7, XeviousArt:Width(XeviousPicture:MiniLark)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoxesAreTheOnesTheDesignGives():
        Assert:Equals(2, XeviousArt:BoxX(XeviousPicture:Lark)).
        Assert:Equals(12, XeviousArt:BoxWidth(XeviousPicture:Lark)).
        Assert:Equals(1, XeviousArt:BoxX(XeviousPicture:Zap)).
        Assert:Equals(1, XeviousArt:BoxWidth(XeviousPicture:Zap)).
        Assert:Equals(4, XeviousArt:BoxHeight(XeviousPicture:Zap)).
        Assert:Equals(0, XeviousArt:BoxY(XeviousPicture:Zap)).
        Assert:Equals(4, XeviousArt:BoxWidth(XeviousPicture:Midge1)).
        Assert:Equals(8, XeviousArt:BoxHeight(XeviousPicture:Midge1)).
        Assert:Equals(16, XeviousArt:BoxWidth(XeviousPicture:Whirl1)).
        Assert:Equals(10, XeviousArt:BoxWidth(XeviousPicture:CitadelCore)).
        Assert:Equals(11, XeviousArt:BoxX(XeviousPicture:CitadelCore)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTileIs16By16():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rows AS CHARACTER NO-UNDO.
        DO i = INTEGER(XeviousTilePicture:Open1) TO INTEGER(XeviousTilePicture:LinesLarkSe):
            rows = XeviousTileArt:Rows(XeviousTilePicture:GetEnum(i)).
            Assert:Equals(16, NUM-ENTRIES(rows, "/")).
            Assert:Equals(16, LENGTH(ENTRY(16, rows, "/"))).
        END.
        Assert:Equals(53, INTEGER(XeviousTilePicture:LinesLarkSe) + 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAreasHaveAFamilyAndAMoodAndGoRoundAfterSixteen():
        Assert:IsTrue(XeviousAreas:IsDry(1)).
        Assert:IsFalse(XeviousAreas:IsDry(2)).
        Assert:IsTrue(XeviousAreas:IsDry(17)).
        Assert:Equals(0, XeviousAreas:Mood(1)).
        Assert:Equals(1, XeviousAreas:Mood(3)).
        Assert:Equals(4, XeviousAreas:Mood(13)).
        Assert:Equals(XeviousAreas:Mood(1), XeviousAreas:Mood(17)).
        Assert:Equals(10, XeviousAreas:MoodPercent(0)).
        Assert:Equals(0, XeviousAreas:MoodPercent(1)).
        Assert:Equals(18, XeviousAreas:MoodPercent(4)).
        Assert:Equals(STRING(XeviousTint:GlowLight), STRING(XeviousAreas:MoodTint(0))).
        Assert:Equals(STRING(XeviousTint:Ink), STRING(XeviousAreas:MoodTint(4))).
    END METHOD.

END CLASS.
