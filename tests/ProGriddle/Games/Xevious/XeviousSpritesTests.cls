/* The sprite cache of Xevious: a stamp for every sprite of the design (also turned by quarter turns), and the colours of the ground tiles
   for the family and the mood of an area. And the boxes things are hit in. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousSpritesTests:

    VAR PRIVATE XeviousSprites mSprites.

    @Setup.
    METHOD PUBLIC VOID BuildSprites():
        mSprites = NEW XeviousSprites().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseSprites():
        IF VALID-OBJECT(mSprites) THEN mSprites:Dispose().
        mSprites = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySpriteMakesAStampOfTheSizeInTheDesign():
        VAR INTEGER i.
        DO i = INTEGER(XeviousPicture:Lark) TO INTEGER(XeviousPicture:MiniLark):
            Assert:Equals(XeviousArt:Width(XeviousPicture:GetEnum(i)), mSprites:Stamp(XeviousPicture:GetEnum(i)):Width).
            Assert:Equals(XeviousArt:Height(XeviousPicture:GetEnum(i)), mSprites:Stamp(XeviousPicture:GetEnum(i)):Height).
            Assert:IsTrue(mSprites:Stamp(XeviousPicture:GetEnum(i)):Count > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStampIsMadeOnceAndKept():
        Assert:IsTrue(mSprites:Stamp(XeviousPicture:Lark) = mSprites:Stamp(XeviousPicture:Lark)).
        Assert:IsTrue(mSprites:Stamp(XeviousPicture:Lark) <> mSprites:Stamp(XeviousPicture:Whirl1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpriteTurnedAQuarterTurnHasItsCellsMovedRoundAndTheSizesSwap():
        VAR PixelStamp s0.
        VAR PixelStamp s1.
        VAR PixelStamp s2.
        VAR PixelStamp s3.
        VAR INTEGER x.
        VAR INTEGER y.
        s0 = mSprites:Stamp(XeviousPicture:ShieldN).
        s1 = mSprites:Turned(XeviousPicture:ShieldN, 1).
        s2 = mSprites:Turned(XeviousPicture:ShieldN, 2).
        s3 = mSprites:Turned(XeviousPicture:ShieldN, 3).
        Assert:Equals(16, s0:Width).
        Assert:Equals(12, s0:Height).
        Assert:Equals(12, s1:Width).
        Assert:Equals(16, s1:Height).
        Assert:Equals(16, s2:Width).
        Assert:Equals(12, s3:Width).
        Assert:Equals(s0:Count, s1:Count).
        Assert:Equals(s0:Count, s2:Count).
        Assert:Equals(s0:Count, s3:Count).
        /* a clockwise quarter turn takes the cell at (x, y) to (height - 1 - y, x) */
        DO y = 0 TO s0:Height - 1:
            DO x = 0 TO s0:Width - 1:
                Assert:Equals(s0:ColourAt(x, y), s1:ColourAt(s0:Height - 1 - y, x)).
                Assert:Equals(s0:ColourAt(x, y), s2:ColourAt(s0:Width - 1 - x, s0:Height - 1 - y)).
                Assert:Equals(s0:ColourAt(x, y), s3:ColourAt(y, s0:Width - 1 - x)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnOutsideZeroToThreeIsRefused():
        VAR INTEGER thrown.
        VAR PixelStamp s.
        DO ON ERROR UNDO, THROW:
            s = mSprites:Turned(XeviousPicture:Lark, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTilesAreMadeForAnAreaAndTheFamilyAndMoodChangeTheirColours():
        VAR INTEGER dry.
        VAR INTEGER grn.
        mSprites:ForArea(2).
        Assert:IsFalse(mSprites:Dry).
        Assert:Equals(0, mSprites:Mood).
        grn = mSprites:TilePixel(XeviousTilePicture:Open1, 5, 5).
        mSprites:ForArea(3).
        Assert:Equals(1, mSprites:Mood).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Meadow), mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0)).
        mSprites:ForArea(4).
        Assert:IsTrue(mSprites:Dry).
        dry = mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0).
        Assert:Equals(XeviousLook:Colour(XeviousTint:Ochre), dry).
        Assert:IsTrue(grn <> 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMoodTintsTheWholeGroundOnce():
        mSprites:ForArea(2).
        Assert:Equals(ColourMath:Mix(XeviousLook:Colour(XeviousTint:Meadow), XeviousLook:Colour(XeviousTint:GlowLight), 10, 100),
                      mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0)).
        mSprites:ForArea(13).
        Assert:Equals(ColourMath:Mix(XeviousLook:Colour(XeviousTint:Meadow), XeviousLook:Colour(XeviousTint:Ink), 18, 100),
                      mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineOfATileIsCopiedIntoMemory():
        VAR MEMPTR m.
        DO ON ERROR UNDO, THROW:
            SET-SIZE(m) = 128.
            mSprites:ForArea(3).
            mSprites:TileLine(XeviousTilePicture:Open2, 0, m, 1).
            mSprites:TileLine(XeviousTilePicture:Open2, 15, m, 65).
            Assert:Equals(mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0), GET-LONG(m, 1)).
            Assert:Equals(mSprites:TilePixel(XeviousTilePicture:Open2, 15, 0), GET-LONG(m, 61)).
            Assert:Equals(mSprites:TilePixel(XeviousTilePicture:Open2, 7, 15), GET-LONG(m, 65 + 28)).
            FINALLY:
                SET-SIZE(m) = 0.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TilesNeedAnAreaFirstAndALineOrPixelInsideTheTile():
        VAR MEMPTR m.
        VAR INTEGER thrown.
        VAR INTEGER c.
        DO ON ERROR UNDO, THROW:
            SET-SIZE(m) = 64.
            DO ON ERROR UNDO, THROW:
                mSprites:TileLine(XeviousTilePicture:Open1, 0, m, 1).
                CATCH e1 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
            mSprites:ForArea(1).
            DO ON ERROR UNDO, THROW:
                mSprites:TileLine(XeviousTilePicture:Open1, 16, m, 1).
                CATCH e2 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
            DO ON ERROR UNDO, THROW:
                c = mSprites:TilePixel(XeviousTilePicture:Open1, 16, 0).
                CATCH e3 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
            DO ON ERROR UNDO, THROW:
                mSprites:ForArea(0).
                CATCH e4 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
            FINALLY:
                SET-SIZE(m) = 0.
            END FINALLY.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoxesOfEnemiesAndTargetsComeFromTheirSprites():
        Assert:Equals(STRING(XeviousPicture:Whirl1), STRING(XeviousBoxes:AirPicture(XeviousAir:Toroid))).
        Assert:Equals(STRING(XeviousPicture:Cairn), STRING(XeviousBoxes:GroundPicture(XeviousGround:Barra))).
        Assert:Equals(STRING(XeviousPicture:Spire), STRING(XeviousBoxes:GroundPicture(XeviousGround:Sol))).
        /* a 12 x 12 picture sits 2 cells in its 16 x 16 place, and its box is placed within that */
        Assert:Equals(2, XeviousBoxes:SlotOffset(XeviousPicture:Midge1)).
        Assert:Equals(0, XeviousBoxes:SlotOffset(XeviousPicture:Lark)).
        Assert:Equals(6, XeviousBoxes:AirLeft(XeviousAir:Jara)).
        Assert:Equals(4, XeviousBoxes:AirTop(XeviousAir:Jara)).
        Assert:Equals(4, XeviousBoxes:AirWidth(XeviousAir:Jara)).
        Assert:Equals(8, XeviousBoxes:AirHeight(XeviousAir:Jara)).
        Assert:Equals(2, XeviousBoxes:GroundLeft(XeviousGround:Barra)).
        Assert:Equals(2, XeviousBoxes:GroundTop(XeviousGround:Barra)).
        Assert:Equals(12, XeviousBoxes:GroundWidth(XeviousGround:Barra)).
        Assert:Equals(12, XeviousBoxes:GroundHeight(XeviousGround:Barra)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVeilDarkensTheTilesTowardsInkAndIsKeptBetweenZeroAndOneHundred():
        VAR INTEGER plain.
        VAR INTEGER thrown.
        mSprites:ForArea(3).
        plain = mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0).
        Assert:Equals(0, mSprites:Veil).
        mSprites:Veil = 50.
        Assert:Equals(50, mSprites:Veil).
        Assert:Equals(ColourMath:Mix(plain, XeviousLook:Colour(XeviousTint:Ink), 50, 100), mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0)).
        mSprites:Veil = 0.
        Assert:Equals(plain, mSprites:TilePixel(XeviousTilePicture:Open2, 0, 0)).
        DO ON ERROR UNDO, THROW:
            mSprites:Veil = 101.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
