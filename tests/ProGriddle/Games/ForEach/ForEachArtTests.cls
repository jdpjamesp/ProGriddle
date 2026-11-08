/* The art of FOR EACH as the code holds it (generated from the design file): every picture is a good Tile that can be coloured with its own
   legend, its origin is inside it, there are 47 wall tiles of 8 x 8 and ten digits of 3 x 5, and the colours and the sounds are complete.
   Pixel by pixel the pictures are the designer's: what is checked here is that nothing was lost or broken on the way. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachArtTests:

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        VAR INTEGER n.
        VAR CHARACTER words.
        VAR ForEachPicture picture.
        VAR ForEachTint tint.
        VAR ForEachRow colourRow.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN words = ForEachArt:Rows(picture).
                WHEN 2 THEN n = ForEachArt:OriginX(picture).
                WHEN 3 THEN n = ForEachArt:OriginY(picture).
                WHEN 4 THEN words = ForEachArt:WallRows(20).
                WHEN 5 THEN words = ForEachArt:DigitRows(10).
                WHEN 6 THEN n = ForEachLook:Colour(tint).
                WHEN 7 THEN words = ForEachLook:Tones(colourRow).
                WHEN 8 THEN n = ForEachLook:Tone(ForEachRow:Dibby, 0).
                WHEN 9 THEN n = ForEachLook:Tone(ForEachRow:Dibby, 6).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPictureIsATileThatColoursWithItsOwnLegend():
        VAR INTEGER i.
        VAR ForEachPicture picture.
        VAR Tile tile.
        VAR PixelStamp stamp.
        VAR ForEachRow colourRow.
        VAR CHARACTER tones.
        DO i = INTEGER(ForEachPicture:DibbyClosed) TO INTEGER(ForEachPicture:DibbyGiant):
            picture = ForEachPicture:GetEnum(i).
            tile = NEW Tile(ForEachArt:Rows(picture)).
            colourRow = ForEachArt:ToneRow(picture).
            tones = (IF colourRow <> ? THEN ForEachLook:Tones(colourRow) ELSE SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor))).
            /* a picture drawn in a phantom's own row has none of its own: the phantom's tones will do for the check */
            IF colourRow = ? THEN tones = ForEachLook:Tones(ForEachRow:Mary).
            stamp = tile:Colourise(tones, ForEachArt:Legend(picture)).
            Assert:IsTrue(stamp:Count > 0).
            Assert:IsTrue(ForEachArt:OriginX(picture) >= 0 AND ForEachArt:OriginX(picture) < tile:Width).
            Assert:IsTrue(ForEachArt:OriginY(picture) >= 0 AND ForEachArt:OriginY(picture) < tile:Height).
            stamp:Dispose().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCharactersAre16By16AndTheCommitTokenIs6By6():
        Assert:Equals(16, NEW Tile(ForEachArt:Rows(ForEachPicture:DibbyClosed)):Width).
        Assert:Equals(16, NEW Tile(ForEachArt:Rows(ForEachPicture:PhantomBody1)):Height).
        Assert:Equals(16, NEW Tile(ForEachArt:Rows(ForEachPicture:Rolledback2)):Width).
        Assert:Equals(6, NEW Tile(ForEachArt:Rows(ForEachPicture:CommitOn)):Width).
        Assert:Equals(32, NEW Tile(ForEachArt:Rows(ForEachPicture:DibbyGiant)):Width).
        Assert:Equals(12, NEW Tile(ForEachArt:Rows(ForEachPicture:DibbyLife)):Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOriginsAreWhereTheDesignPutsThem():
        Assert:Equals(8, ForEachArt:OriginX(ForEachPicture:DibbyClosed)).
        Assert:Equals(8, ForEachArt:OriginY(ForEachPicture:PhantomBody1)).
        Assert:Equals(3, ForEachArt:OriginX(ForEachPicture:CommitOn)).
        Assert:Equals(16, ForEachArt:OriginX(ForEachPicture:DibbyGiant)).
        Assert:Equals(6, ForEachArt:OriginX(ForEachPicture:DibbyLife)).
        Assert:Equals(6, ForEachArt:OriginX(ForEachPicture:Pop200)).
        Assert:Equals(8, ForEachArt:OriginX(ForEachPicture:Pop1600)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheColourRowOfAPictureIsTheOneItsLegendNames():
        Assert:Equals(ForEachRow:Dibby, ForEachArt:ToneRow(ForEachPicture:DibbyWide)).
        Assert:Equals(ForEachRow:Rollback, ForEachArt:ToneRow(ForEachPicture:Rolledback1)).
        Assert:Equals(ForEachRow:Flash, ForEachArt:ToneRow(ForEachPicture:Flash2)).
        Assert:Equals(ForEachRow:Steel, ForEachArt:ToneRow(ForEachPicture:ItemFloppy)).
        Assert:Equals(ForEachRow:Mary, ForEachArt:ToneRow(ForEachPicture:MarkMary)).
        Assert:IsTrue(ForEachArt:ToneRow(ForEachPicture:PhantomEyesRight) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLegendOfAPictureGivesItsNamedColours():
        Assert:IsTrue(INDEX(ForEachArt:Legend(ForEachPicture:PhantomEyesLeft), "E=FFFFFF") > 0).
        Assert:IsTrue(INDEX(ForEachArt:Legend(ForEachPicture:PhantomEyesLeft), "P=1C2A8C") > 0).
        Assert:Equals("", ForEachArt:Legend(ForEachPicture:PhantomBody1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAre47WallTilesOf8By8():
        VAR INTEGER mask.
        VAR INTEGER count.
        DO mask = 0 TO 255:
            IF ForEachArt:IsWallMask(mask) THEN DO:
                count = count + 1.
                Assert:Equals(8, NEW Tile(ForEachArt:WallRows(mask)):Width).
                Assert:Equals(8, NEW Tile(ForEachArt:WallRows(mask)):Height).
            END.
        END.
        Assert:Equals(47, count).
        Assert:IsTrue(ForEachArt:IsWallMask(0)).
        Assert:IsTrue(ForEachArt:IsWallMask(255)).
        Assert:IsFalse(ForEachArt:IsWallMask(20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileOfAllWallIsAllFillAndATileWithNoWallNeighboursIsOnlyAGlow():
        Assert:Equals("FFFFFFFF/FFFFFFFF/FFFFFFFF/FFFFFFFF/FFFFFFFF/FFFFFFFF/FFFFFFFF/FFFFFFFF", ForEachArt:WallRows(255)).
        Assert:IsTrue(INDEX(ForEachArt:WallRows(0), "G") > 0).
        Assert:Equals(0, INDEX(ForEachArt:WallRows(0), "L")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDigitsAre3By5():
        Assert:Equals("###/#.#/#.#/#.#/###", ForEachArt:DigitRows(0)).
        Assert:Equals("###/..#/###/#../###", ForEachArt:DigitRows(2)).
        Assert:Equals(5, NUM-ENTRIES(ForEachArt:DigitRows(8), "/")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheColoursAreTheDesignersAndEveryRowHasFiveTones():
        VAR INTEGER i.
        Assert:Equals(395022, ForEachLook:Colour(ForEachTint:Floor)).
        Assert:Equals("06070E", ForEachLook:Hex(ForEachTint:Floor)).
        Assert:Equals("FFEDC2,FFD471,FFC234,AF8628,5F4B1C", ForEachLook:Tones(ForEachRow:Dibby)).
        Assert:Equals(16761396, ForEachLook:Tone(ForEachRow:Dibby, 3)).
        DO i = INTEGER(ForEachRow:Dibby) TO INTEGER(ForEachRow:Steel):
            Assert:Equals(5, NUM-ENTRIES(ForEachLook:Tones(ForEachRow:GetEnum(i)))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownPictureColourRowOrToneIsRefused():
        VAR INTEGER i.
        DO i = 1 TO 9:
            Assert:IsTrue(ThrowsGridException(i)).
        END.
    END METHOD.

END CLASS.
