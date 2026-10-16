/* The generated pictures of Blast Buddies: all 72 sprites of the design are there with the sizes and origins the design gives,
   every one turns into a Tile and into coloured pixels with its own tone row and legend, and the legends stay within 16 colours. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddiesArtTests:

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN BuddiesArt:NameAt(0).
                WHEN 2 THEN BuddiesArt:NameAt(BuddiesArt:Count() + 1).
                WHEN 3 THEN n = BuddiesArt:Width("no_such_sprite").
                WHEN 4 THEN BuddiesArt:Rows(?).
                WHEN 5 THEN BuddiesArt:TileOf("").
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDesignHasSeventyTwoSpritesFromTheGoonToTheSqueal():
        Assert:Equals(72, BuddiesArt:Count()).
        Assert:Equals("goon_idle_1", BuddiesArt:NameAt(1)).
        Assert:IsTrue(BuddiesArt:Has("goon_idle_1")).
        Assert:IsTrue(BuddiesArt:Has("bubble_oof")).
        Assert:IsTrue(BuddiesArt:Has("crate_health")).
        Assert:IsFalse(BuddiesArt:Has("no_such_sprite")).
        Assert:IsFalse(BuddiesArt:Has("")).
        Assert:IsFalse(BuddiesArt:Has(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpritesHaveTheSizesAndOriginsOfTheDesign():
        Assert:Equals(11, BuddiesArt:Width("goon_idle_1")).
        Assert:Equals(12, BuddiesArt:Height("goon_idle_1")).
        Assert:Equals(5, BuddiesArt:OriginX("goon_idle_1")).
        Assert:Equals(12, BuddiesArt:OriginY("goon_idle_1")).
        Assert:Equals(12, BuddiesArt:Width("goon_aim")).
        Assert:Equals(13, BuddiesArt:Width("goon_flip_2")).
        Assert:Equals(10, BuddiesArt:Height("goon_flip_2")).
        Assert:Equals(14, BuddiesArt:Width("crate_health")).
        Assert:Equals(16, BuddiesArt:Width("icon_selected")).
        Assert:Equals(18, BuddiesArt:Width("chute_0")).
        Assert:Equals(21, BuddiesArt:Width("bubble_oof")).
        Assert:Equals(12, BuddiesArt:Height("bubble_oof")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpriteHasItsToneRowItsLegendAndItsRows():
        Assert:Equals("Reds", BuddiesArt:ToneRow("goon_idle_1")).
        Assert:IsTrue(INDEX(BuddiesArt:Legend("goon_idle_1"), "I=1C1426") > 0).
        Assert:IsTrue(INDEX(BuddiesArt:Legend("goon_idle_1"), "B=FFFFFF") > 0).
        Assert:Equals(12, NUM-ENTRIES(BuddiesArt:Rows("goon_idle_1"), "/")).
        Assert:Equals("", BuddiesArt:ToneRow("bubble_oof")).
        Assert:Equals(11, BuddiesArt:TileOf("goon_idle_1"):Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySpriteIsATileOfItsSizeWithItsOriginInsideOrJustBelowIt():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oTile  AS Tile NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            oTile = BuddiesArt:TileOf(sprite).
            Assert:IsTrue(BuddiesArt:Width(sprite) = oTile:Width, sprite).
            Assert:IsTrue(BuddiesArt:Height(sprite) = oTile:Height, sprite).
            Assert:IsTrue(BuddiesArt:OriginX(sprite) >= 0 AND BuddiesArt:OriginX(sprite) <= oTile:Width, sprite).
            Assert:IsTrue(BuddiesArt:OriginY(sprite) >= 0 AND BuddiesArt:OriginY(sprite) <= oTile:Height, sprite).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySpriteTurnsIntoColouredPixelsWithItsOwnToneRowAndLegend():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DEFINE VARIABLE row    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oStamp AS PixelStamp NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            row = BuddiesArt:ToneRow(sprite).
            /* a sprite with no tone row uses no digits, so any row will do */
            oStamp = BuddiesArt:TileOf(sprite):Colourise(BuddiesLook:ToneRow(IF row = "" THEN "Metal" ELSE row), BuddiesArt:Legend(sprite)).
            Assert:IsTrue(oStamp:Count > 0, sprite).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryGoonFrameIsDrawnInAllFourTeamColours():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE t      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oStamp AS PixelStamp NO-UNDO.
        DEFINE VARIABLE rows   AS CHARACTER NO-UNDO INITIAL "Reds,Blues,Teals,Grapes".
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            IF NOT sprite BEGINS "goon_" THEN NEXT.
            Assert:IsTrue("Reds" = BuddiesArt:ToneRow(sprite), sprite).
            DO t = 1 TO 4:
                oStamp = BuddiesArt:TileOf(sprite):Colourise(BuddiesLook:ToneRow(ENTRY(t, rows)), BuddiesArt:Legend(sprite)).
                Assert:IsTrue(oStamp:Count > 0, sprite).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGoonFramesFitTheBodyOfNineByElevenInsideTheOutline():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            IF NOT sprite BEGINS "goon_" THEN NEXT.
            /* the two turned backflip frames and the aiming frame (which holds the weapon arm out) are the exceptions the design states */
            IF sprite = "goon_flip_2" OR sprite = "goon_flip_4" OR sprite = "goon_aim" THEN NEXT.
            Assert:IsTrue(11 = BuddiesArt:Width(sprite), sprite).
            Assert:IsTrue(12 = BuddiesArt:Height(sprite), sprite).
            Assert:IsTrue(5 = BuddiesArt:OriginX(sprite), sprite).
            Assert:IsTrue(12 = BuddiesArt:OriginY(sprite), sprite).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoLegendNeedsMoreThanSixteenColours():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            n = (IF BuddiesArt:Legend(sprite) = "" THEN 0 ELSE NUM-ENTRIES(BuddiesArt:Legend(sprite))) + (IF BuddiesArt:ToneRow(sprite) = "" THEN 0 ELSE 5).
            Assert:IsTrue(n <= 16, sprite + " has " + STRING(n)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryToneRowASpriteNamesExists():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS CHARACTER NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            sprite = BuddiesArt:NameAt(i).
            IF BuddiesArt:ToneRow(sprite) <> "" THEN Assert:IsTrue(LOOKUP(BuddiesArt:ToneRow(sprite), BuddiesLook:ToneRowNames()) > 0, sprite).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadIndexOrNameThrowsGridException():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
        Assert:IsTrue(ThrowsGridException(5)).
    END METHOD.

END CLASS.
