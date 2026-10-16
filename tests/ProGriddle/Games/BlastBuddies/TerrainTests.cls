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
    METHOD PUBLIC VOID FirstGroundIsTheTopMostGroundOfAColumnAndUnknownWithNone():
        mT:FillRect(50, 90, 60, 239, TRUE).
        mT:SetSolid(70, 20, TRUE).
        Assert:Equals(90, mT:FirstGround(55)).
        Assert:Equals(20, mT:FirstGround(70)).
        Assert:Equals(90, mT:FirstGround(60)).
        Assert:IsTrue(mT:FirstGround(100) = ?).
        Assert:IsTrue(mT:FirstGround(-1) = ?).
        Assert:IsTrue(mT:FirstGround(384) = ?).
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
    METHOD PUBLIC VOID CarveTurnsTheDiscToAirAndCountsWhatItRemoved():
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE want AS INTEGER NO-UNDO.
        mT:FillRect(0, 50, 383, 239, TRUE).
        DO y = -20 TO 20:
            DO x = -20 TO 20:
                IF x * x + y * y <= 400 THEN want = want + 1.
            END.
        END.
        Assert:Equals(want, mT:Carve(100, 100, 20)).
        Assert:IsFalse(mT:IsSolid(100, 100)).
        Assert:IsFalse(mT:IsSolid(120, 100)).
        Assert:IsFalse(mT:IsSolid(100, 80)).
        Assert:IsTrue(mT:IsSolid(121, 100)).
        Assert:IsTrue(mT:IsSolid(100, 121)).
        Assert:Equals(want, 384 * 190 - mT:SolidCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CarveScorchesThreePixelsOfRingByDistance():
        mT:FillRect(0, 50, 383, 239, TRUE).
        mT:Carve(100, 100, 20).
        Assert:Equals(1, mT:ScorchStep(121, 100)).
        Assert:Equals(2, mT:ScorchStep(122, 100)).
        Assert:Equals(3, mT:ScorchStep(123, 100)).
        Assert:Equals(0, mT:ScorchStep(124, 100)).
        Assert:Equals(1, mT:ScorchStep(100, 79)).
        Assert:Equals(3, mT:ScorchStep(100, 77)).
        Assert:Equals(0, mT:ScorchStep(100, 76)).
        /* 14 across and 15 down is 20.5 from the centre, so a step 1 pixel */
        Assert:Equals(1, mT:ScorchStep(114, 115)).
        Assert:Equals(Look(ThemeKey:Scorch1), mT:ShadeAt(121, 100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASecondBlastKeepsTheSmallerStepAndAirTakesNoScorch():
        mT:FillRect(0, 50, 383, 239, TRUE).
        mT:Carve(100, 100, 20).
        /* the second ring passes over pixels of the first: a pixel 13 from the new centre is step 3 and was step 3, 12 away is step 2 and was step 2 */
        mT:Carve(110, 100, 10).
        Assert:Equals(3, mT:ScorchStep(123, 100)).
        Assert:Equals(2, mT:ScorchStep(122, 100)).
        Assert:Equals(1, mT:ScorchStep(121, 100)).
        Assert:Equals(0, mT:ScorchStep(110, 100)).
        /* a pixel outside the first ring (24 from its centre) that the new ring reaches at step 3 gets that step */
        Assert:Equals(0, mT:ScorchStep(124, 100)).
        Assert:Equals(0, mT:ScorchStep(125, 100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CarveNearTheEdgeOfTheMapIsClipped():
        mT:FillRect(0, 50, 383, 239, TRUE).
        mT:Carve(2, 60, 20).
        Assert:IsFalse(mT:IsSolid(0, 60)).
        Assert:IsFalse(mT:IsSolid(21, 60)).
        mT:Carve(380, 238, 30).
        Assert:IsFalse(mT:IsSolid(383, 239)).
        Assert:IsTrue(mT:IsSolid(300, 239)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACarveWithNoRadiusIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mT:Carve(10, 10, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CarveMarksTheReshadeBoxAndClearDirtyEmptiesIt():
        Assert:IsFalse(mT:HasDirty()).
        Assert:IsTrue(mT:DirtyLeft() = ?).
        Assert:IsTrue(mT:DirtyTop() = ?).
        Assert:IsTrue(mT:DirtyRight() = ?).
        Assert:IsTrue(mT:DirtyBottom() = ?).
        mT:Carve(100, 100, 20).
        Assert:IsTrue(mT:HasDirty()).
        Assert:Equals(76, mT:DirtyLeft()).
        Assert:Equals(76, mT:DirtyTop()).
        Assert:Equals(124, mT:DirtyRight()).
        Assert:Equals(138, mT:DirtyBottom()).
        mT:Carve(200, 100, 10).
        Assert:Equals(76, mT:DirtyLeft()).
        Assert:Equals(214, mT:DirtyRight()).
        mT:ClearDirty().
        Assert:IsFalse(mT:HasDirty()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheReshadeBoxIsClippedToTheMap():
        mT:Carve(3, 5, 20).
        Assert:Equals(0, mT:DirtyLeft()).
        Assert:Equals(0, mT:DirtyTop()).
        mT:ClearDirty().
        mT:Carve(380, 235, 20).
        Assert:Equals(383, mT:DirtyRight()).
        Assert:Equals(239, mT:DirtyBottom()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACutSurfaceGetsItsGrassAndEdgeFromTheRuleWithNobodyDrawingIt():
        mT:FillRect(0, 100, 383, 239, TRUE).
        mT:Carve(100, 100, 20).
        /* the crater floor is scorched, and the grass bands carry on under the scorch: row 124 is the fourth pixel down */
        Assert:Equals(Look(ThemeKey:Scorch1), mT:ShadeAt(100, 121)).
        Assert:Equals(Look(ThemeKey:Top3), mT:ShadeAt(100, 124)).
        Assert:Equals(Look(ThemeKey:Soil), mT:ShadeAt(100, 125)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorchGlowsInTheBlastRampAndCoolsInThreeStepsOverSixHundredMilliseconds():
        DEFINE VARIABLE blast AS CHARACTER NO-UNDO.
        blast = BuddiesLook:ToneRow("Blast").
        Assert:Equals(ColourMath:FromHex(ENTRY(3, blast)), mT:ScorchColour(1, 0)).
        Assert:Equals(ColourMath:FromHex(ENTRY(4, blast)), mT:ScorchColour(2, 199)).
        Assert:Equals(ColourMath:FromHex(ENTRY(5, blast)), mT:ScorchColour(3, 100)).
        Assert:Equals(ColourMath:FromHex(ENTRY(4, blast)), mT:ScorchColour(1, 200)).
        Assert:Equals(ColourMath:FromHex(ENTRY(5, blast)), mT:ScorchColour(2, 200)).
        Assert:Equals(Look(ThemeKey:Scorch3), mT:ScorchColour(3, 200)).
        Assert:Equals(ColourMath:FromHex(ENTRY(5, blast)), mT:ScorchColour(1, 400)).
        Assert:Equals(Look(ThemeKey:Scorch2), mT:ScorchColour(2, 400)).
        Assert:Equals(Look(ThemeKey:Scorch1), mT:ScorchColour(1, 600)).
        Assert:Equals(Look(ThemeKey:Scorch1), mT:ScorchColour(1, 5000)).
        Assert:Equals(Look(ThemeKey:Scorch2), mT:ScorchColour(2, 600)).
        Assert:Equals(Look(ThemeKey:Scorch3), mT:ScorchColour(3, 600)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScorchColourNeedsAStepFromOneToThree():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mT:ScorchColour(0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastOfRadiusThirtyAndItsReshadeTakesWellUnderFiftyMilliseconds():
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE c   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ms  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sum AS INT64   NO-UNDO.
        mT:FillRect(0, 100, 383, 239, TRUE).
        ETIME(TRUE).
        mT:Carve(200, 110, 30).
        DO y = mT:DirtyTop() TO mT:DirtyBottom():
            DO x = mT:DirtyLeft() TO mT:DirtyRight():
                c = mT:ShadeAt(x, y).
                IF c <> ? THEN sum = sum + c.
            END.
        END.
        ms = ETIME.
        MESSAGE "timing: carve radius 30 and reshade the box took" ms "ms".
        Assert:IsTrue(ms < 150, "took " + STRING(ms) + " ms").
        Assert:IsTrue(sum > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpeckOfOnePixelInTheSkyNearABlastCrumblesAndKeepsItsColour():
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        mT:SetSolid(200, 100, TRUE).
        colour = mT:ShadeAt(200, 100).
        Assert:Equals(1, mT:Crumble(200, 100, 20)).
        Assert:Equals(1, mT:CrumbCount()).
        Assert:IsFalse(mT:IsSolid(200, 100)).
        Assert:Equals(200, mT:CrumbX(1)).
        Assert:Equals(100, mT:CrumbY(1)).
        Assert:Equals(colour, mT:CrumbColour(1)).
        Assert:Equals(Look(ThemeKey:Top1), mT:CrumbColour(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceOfTwentyFourPixelsCrumblesButOneOfTwentyFiveStays():
        mT:FillRect(180, 80, 185, 83, TRUE).
        mT:FillRect(190, 90, 194, 94, TRUE).
        Assert:Equals(24, mT:Crumble(200, 100, 20)).
        Assert:IsFalse(mT:IsSolid(180, 80)).
        Assert:IsFalse(mT:IsSolid(185, 83)).
        Assert:IsTrue(mT:IsSolid(190, 90)).
        Assert:IsTrue(mT:IsSolid(194, 94)).
        Assert:Equals(25, mT:SolidCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABiggerFloatingIslandAndGroundAndAnythingJoinedToThemStay():
        mT:FillRect(0, 150, 383, 239, TRUE).
        mT:FillRect(210, 100, 260, 110, TRUE).
        mT:FillRect(150, 148, 152, 149, TRUE).
        Assert:Equals(0, mT:Crumble(200, 100, 20)).
        Assert:IsTrue(mT:IsSolid(210, 100)).
        Assert:IsTrue(mT:IsSolid(260, 110)).
        Assert:IsTrue(mT:IsSolid(151, 148)).
        Assert:Equals(384 * 90 + 51 * 11 + 6, mT:SolidCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongThinLineIsOneBigPieceEvenWhenMostOfItIsOutsideTheBox():
        mT:FillRect(100, 100, 300, 100, TRUE).
        Assert:Equals(0, mT:Crumble(200, 100, 20)).
        Assert:Equals(201, mT:SolidCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyPiecesInsideTheBoxEightPixelsPastTheBlastAreLookedAt():
        mT:SetSolid(228, 100, TRUE).
        mT:SetSolid(229, 120, TRUE).
        mT:SetSolid(200, 128, TRUE).
        mT:SetSolid(200, 130, TRUE).
        Assert:Equals(2, mT:Crumble(200, 100, 20)).
        Assert:IsFalse(mT:IsSolid(228, 100)).
        Assert:IsTrue(mT:IsSolid(229, 120)).
        Assert:IsTrue(mT:IsSolid(200, 130)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceThatCrossesTheBoxEdgeIsMeasuredWhole():
        /* 10 pixels in a row starting in the box and going out of it: only 10, so it crumbles even though the box ends in the middle of it */
        mT:FillRect(224, 100, 233, 100, TRUE).
        Assert:Equals(10, mT:Crumble(200, 100, 20)).
        Assert:Equals(0, mT:SolidCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARoundHoleCutsNothingOffButAnIslandLeftInAHoleCrumbles():
        mT:FillRect(0, 100, 383, 239, TRUE).
        mT:Carve(100, 130, 15).
        Assert:Equals(0, mT:Crumble(100, 130, 15)).
        /* a chunk of 3 x 5 left floating in a hollow */
        mT:FillRect(240, 140, 262, 160, FALSE).
        mT:FillRect(250, 150, 252, 154, TRUE).
        Assert:Equals(15, mT:Crumble(251, 150, 10)).
        Assert:IsFalse(mT:IsSolid(251, 152)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CrumbleMarksTheReshadeBoxAroundWhatItRemovedOnlyWhenItRemovedSomething():
        mT:Crumble(100, 100, 20).
        Assert:IsFalse(mT:HasDirty()).
        mT:SetSolid(105, 100, TRUE).
        mT:Crumble(100, 100, 20).
        Assert:IsTrue(mT:HasDirty()).
        Assert:Equals(104, mT:DirtyLeft()).
        Assert:Equals(99, mT:DirtyTop()).
        Assert:Equals(106, mT:DirtyRight()).
        Assert:Equals(118, mT:DirtyBottom()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CrumbsAreOnlyThereForTheLastCrumble():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        mT:SetSolid(100, 100, TRUE).
        mT:Crumble(100, 100, 20).
        mT:Crumble(100, 100, 20).
        DO ON ERROR UNDO, LEAVE:
            mT:CrumbX(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mT:CrumbY(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mT:CrumbColour(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACrumbleWithNoRadiusIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mT:Crumble(10, 10, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACrumbleOnTheMapEdgeIsClippedAndTheTimeOfABigOneIsShort():
        DEFINE VARIABLE ms AS INTEGER NO-UNDO.
        mT:FillRect(0, 100, 383, 239, TRUE).
        mT:Carve(200, 110, 30).
        ETIME(TRUE).
        mT:Crumble(200, 110, 30).
        ms = ETIME.
        MESSAGE "timing: crumble box for radius 30 took" ms "ms".
        Assert:IsTrue(ms < 150, "took " + STRING(ms) + " ms").
        Assert:Equals(0, mT:Crumble(0, 0, 5)).
        Assert:Equals(0, mT:Crumble(383, 239, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledTwice():
        mT:Dispose().
        mT:Dispose().
    END METHOD.

END CLASS.
