/* The ground of Blast Buddies: the map, the depth and the colour rule of the design for each band. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.TerrainTests:

    DEFINE PRIVATE VARIABLE mT AS Terrain NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID Setup():
        mT = NEW Terrain(Theme:Meadow).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mT:Dispose().
        DELETE OBJECT mT.
    END METHOD.

    METHOD PRIVATE INTEGER Look(INPUT poKey AS ThemeKey):
        RETURN TerrainThemes:Colour(Theme:Meadow, poKey).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewMapIsAllAirAndKnowsItsSizeAndTheme():
        Assert:Equals(384, Terrain:Width()).
        Assert:Equals(240, Terrain:Height()).
        Assert:Equals(0, mT:SolidCount()).
        Assert:IsFalse(mT:IsSolid(10, 10)).
        Assert:IsTrue(mT:MapTheme = Theme:Meadow).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMapNeedsATheme():
        DEFINE VARIABLE t       AS Terrain NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            t = NEW Terrain(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InBoundsIsTheMapRectangle():
        Assert:IsTrue(mT:InBounds(0, 0)).
        Assert:IsTrue(mT:InBounds(383, 239)).
        Assert:IsFalse(mT:InBounds(384, 0)).
        Assert:IsFalse(mT:InBounds(0, 240)).
        Assert:IsFalse(mT:InBounds(-1, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetSolidMakesGroundAndAirAndFillRectDoesARectangle():
        mT:SetSolid(5, 6, TRUE).
        Assert:IsTrue(mT:IsSolid(5, 6)).
        mT:SetSolid(5, 6, FALSE).
        Assert:IsFalse(mT:IsSolid(5, 6)).
        mT:FillRect(10, 10, 12, 11, TRUE).
        Assert:Equals(6, mT:SolidCount()).
        mT:FillRect(-5, 238, 2, 300, TRUE).
        Assert:IsTrue(mT:IsSolid(0, 239)).
        Assert:IsTrue(mT:IsSolid(2, 238)).
        Assert:IsFalse(mT:IsSolid(3, 238)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetSolidOutsideTheMapIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mT:SetSolid(384, 0, TRUE).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OutsideTheMapIsAirExceptBelowTheBottomRow():
        Assert:IsFalse(mT:IsSolid(-1, 100)).
        Assert:IsFalse(mT:IsSolid(384, 100)).
        Assert:IsFalse(mT:IsSolid(100, -1)).
        Assert:IsTrue(mT:IsSolid(100, 240)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ScorchIsKeptUntilTheGroundIsBlownAway():
        mT:SetSolid(7, 7, TRUE).
        Assert:Equals(0, mT:ScorchStep(7, 7)).
        mT:SetScorch(7, 7, 2).
        Assert:Equals(2, mT:ScorchStep(7, 7)).
        mT:SetSolid(7, 7, TRUE).
        Assert:Equals(2, mT:ScorchStep(7, 7)).
        mT:SetScorch(7, 7, 0).
        Assert:Equals(0, mT:ScorchStep(7, 7)).
        mT:SetScorch(7, 7, 3).
        mT:SetSolid(7, 7, FALSE).
        Assert:Equals(0, mT:ScorchStep(7, 7)).
        mT:SetScorch(7, 7, 1).
        Assert:IsFalse(mT:IsSolid(7, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScorchStepOutsideZeroToThreeIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mT:SetScorch(1, 1, 4).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DepthCountsSolidPixelsAboveAndAirHasNone():
        mT:FillRect(50, 100, 50, 120, TRUE).
        Assert:Equals(0, mT:Depth(50, 100)).
        Assert:Equals(5, mT:Depth(50, 105)).
        Assert:Equals(20, mT:Depth(50, 120)).
        Assert:IsTrue(mT:Depth(50, 99) = ?).
        mT:SetSolid(50, 110, FALSE).
        Assert:Equals(0, mT:Depth(50, 111)).
        Assert:Equals(1, mT:Depth(50, 112)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RockYIsTheBedrockLineWithASlowWave():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        Assert:Equals(200, mT:RockY(0)).
        DO x = 0 TO 383:
            Assert:IsTrue(mT:RockY(x) >= 197 AND mT:RockY(x) <= 203, "column " + STRING(x)).
        END.
        /* x / 23 reaches a quarter turn near x = 36, where the line is lowest, and three quarters near x = 108, where it is highest */
        Assert:Equals(203, mT:RockY(36)).
        Assert:Equals(197, mT:RockY(108)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeckleTileRepeatsEverySixteenPixelsOnTheScreen():
        Assert:IsTrue(mT:Speckled(2, 1)).
        Assert:IsFalse(mT:Speckled(0, 0)).
        Assert:IsTrue(mT:Speckled(2 + 16, 1 + 32)).
        Assert:IsTrue(mT:Speckled(0, 7)).
        Assert:IsTrue(mT:Speckled(1, 15)).
        Assert:IsFalse(mT:Speckled(1, 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AirHasNoColour():
        Assert:IsTrue(mT:ShadeAt(10, 10) = ?).
        Assert:IsTrue(mT:ShadeAt(-1, 10) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTopOfAHillIsGrassInThreeBands():
        mT:FillRect(100, 60, 200, 239, TRUE).
        Assert:Equals(Look(ThemeKey:Top1), mT:ShadeAt(150, 60)).
        Assert:Equals(Look(ThemeKey:Top2), mT:ShadeAt(150, 61)).
        Assert:Equals(Look(ThemeKey:Top3), mT:ShadeAt(150, 62)).
        Assert:Equals(Look(ThemeKey:Top3), mT:ShadeAt(150, 63)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BelowTheGrassIsSoilThenDeepThenRock():
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        mT:FillRect(100, 60, 200, 239, TRUE).
        DO y = 64 TO 73:
            Assert:IsTrue(mT:ShadeAt(150, y) = (IF mT:Speckled(150, y) THEN Look(ThemeKey:SoilSpeck) ELSE Look(ThemeKey:Soil)), "row " + STRING(y)).
        END.
        DO y = 74 TO mT:RockY(150) - 1:
            Assert:IsTrue(mT:ShadeAt(150, y) = (IF mT:Speckled(150, y) THEN Look(ThemeKey:DeepSpeck) ELSE Look(ThemeKey:Deep)), "row " + STRING(y)).
        END.
        DO y = mT:RockY(150) TO 238:
            Assert:IsTrue(mT:ShadeAt(150, y) = (IF mT:Speckled(150, y) THEN Look(ThemeKey:RockSpeck) ELSE Look(ThemeKey:Rock)), "row " + STRING(y)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeckleTilePicksTheSpeckleColourWhereThereIsAStone():
        mT:FillRect(100, 60, 200, 239, TRUE).
        /* (146, 65): tile column 2, row 1 is a stone, depth 5 is soil */
        Assert:IsTrue(mT:Speckled(146, 65)).
        Assert:Equals(Look(ThemeKey:SoilSpeck), mT:ShadeAt(146, 65)).
        /* (147, 100): no stone, depth 40 is deep */
        Assert:Equals(Look(ThemeKey:Deep), mT:ShadeAt(147, 100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACliffSideAndAnUndersideGetTheLitEdge():
        mT:FillRect(100, 60, 200, 100, TRUE).
        Assert:Equals(Look(ThemeKey:Edge), mT:ShadeAt(100, 80)).
        Assert:Equals(Look(ThemeKey:Edge), mT:ShadeAt(200, 80)).
        Assert:Equals(Look(ThemeKey:Edge), mT:ShadeAt(150, 100)).
        /* the grass bands come first, so the top corner is still grass */
        Assert:Equals(Look(ThemeKey:Top1), mT:ShadeAt(100, 60)).
        Assert:Equals(Look(ThemeKey:Top3), mT:ShadeAt(100, 62)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFloorOfACaveGetsGrassBecauseItsDepthStartsAgain():
        mT:FillRect(100, 60, 200, 239, TRUE).
        mT:FillRect(120, 100, 180, 110, FALSE).
        Assert:Equals(Look(ThemeKey:Top1), mT:ShadeAt(150, 111)).
        Assert:Equals(Look(ThemeKey:Top2), mT:ShadeAt(150, 112)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScorchedPixelShowsItsScorchWhateverItsDepth():
        mT:FillRect(100, 60, 200, 239, TRUE).
        mT:SetScorch(150, 60, 1).
        mT:SetScorch(150, 100, 2).
        mT:SetScorch(150, 150, 3).
        Assert:Equals(Look(ThemeKey:Scorch1), mT:ShadeAt(150, 60)).
        Assert:Equals(Look(ThemeKey:Scorch2), mT:ShadeAt(150, 100)).
        Assert:Equals(Look(ThemeKey:Scorch3), mT:ShadeAt(150, 150)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryThemeUsesItsOwnTable():
        DEFINE VARIABLE c AS Terrain NO-UNDO.
        c = NEW Terrain(Theme:Candy).
        c:FillRect(100, 60, 200, 239, TRUE).
        Assert:Equals(TerrainThemes:Colour(Theme:Candy, ThemeKey:Top1), c:ShadeAt(150, 60)).
        Assert:Equals(TerrainThemes:Colour(Theme:Candy, ThemeKey:Top3), c:ShadeAt(150, 62)).
        c:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledTwice():
        mT:Dispose().
        mT:Dispose().
    END METHOD.

END CLASS.
