/* The land of Xevious: the same targets and tiles every time, the hidden towers and the flag where they are said to be, the river and the
   road that wind down the land and the tiles that join the way the design says. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousMapTests:

    @Test.
    METHOD PUBLIC VOID TheHashIsTheSameForTheSameNumbersAndStaysInRange():
        VAR INTEGER i.
        VAR INTEGER h.
        Assert:Equals(XeviousMap:Hash(3, 40, 1), XeviousMap:Hash(3, 40, 1)).
        DO i = 0 TO 200:
            h = XeviousMap:Hash(i, i * 7, i * 13).
            Assert:IsTrue(h >= 0 AND h < 32768).
        END.
        Assert:IsTrue(XeviousMap:Hash(1, 2, 3) <> XeviousMap:Hash(3, 2, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameRowOfTheSameStageAlwaysHoldsTheSameTarget():
        VAR INTEGER row.
        DO row = 0 TO 119:
            Assert:Equals(STRING(XeviousMap:KindAt(5, row)), STRING(XeviousMap:KindAt(5, row))).
            Assert:Equals(XeviousMap:ColAt(5, row), XeviousMap:ColAt(5, row)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstFourRowsAndTheLastTwelveAreEmpty():
        VAR INTEGER row.
        DO row = 0 TO 3:
            Assert:IsFalse(VALID-OBJECT(XeviousMap:KindAt(1, row))).
        END.
        DO row = 108 TO 119:
            Assert:IsFalse(VALID-OBJECT(XeviousMap:KindAt(1, row))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryStageHasThreeHiddenTowersWhereTheMapSays():
        VAR INTEGER stage.
        VAR INTEGER i.
        DO stage = 1 TO 16:
            DO i = 0 TO 2:
                Assert:Equals(STRING(XeviousGround:Sol), STRING(XeviousMap:KindAt(stage, XeviousMap:SolRow(stage, i)))).
                Assert:IsTrue(XeviousMap:SolRow(stage, i) >= 14 AND XeviousMap:SolRow(stage, i) < 98).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheOddStagesHideAFlag():
        Assert:IsTrue(XeviousMap:HasFlag(1)).
        Assert:IsFalse(XeviousMap:HasFlag(2)).
        Assert:IsTrue(XeviousMap:HasFlag(17)).
        Assert:IsTrue(XeviousMap:FlagRow(1) >= 30 AND XeviousMap:FlagRow(1) < 100).
        Assert:Equals(STRING(XeviousGround:Flag), STRING(XeviousMap:KindAt(3, XeviousMap:FlagRow(3)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFlagIsOnTheMapOfAnOddStageExactlyOnce():
        VAR INTEGER row.
        VAR INTEGER flags.
        DO row = 0 TO 119:
            IF VALID-OBJECT(XeviousMap:KindAt(3, row)) AND XeviousMap:KindAt(3, row) = XeviousGround:Flag THEN flags = flags + 1.
        END.
        Assert:Equals(1, flags).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstStageHasNoTurretsAndTheLaterOnesDo():
        VAR INTEGER row.
        VAR INTEGER turrets.
        VAR INTEGER later.
        DO row = 0 TO 119:
            IF VALID-OBJECT(XeviousMap:KindAt(1, row)) AND XeviousMap:KindAt(1, row) = XeviousGround:Logram THEN turrets = turrets + 1.
            IF VALID-OBJECT(XeviousMap:KindAt(12, row)) AND XeviousMap:KindAt(12, row) = XeviousGround:Logram THEN later = later + 1.
        END.
        Assert:Equals(0, turrets).
        Assert:IsTrue(later > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDensityRisesWithTheStage():
        Assert:Equals(14, XeviousMap:Density(1)).
        Assert:Equals(44, XeviousMap:Density(16)).
        Assert:Equals(14, XeviousMap:Density(17)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATargetNeverStandsOnARiverOrARoadOrBesideOne():
        VAR INTEGER stage.
        VAR INTEGER row.
        VAR INTEGER c.
        DO stage = 1 TO 16:
            DO row = 4 TO 107:
                IF VALID-OBJECT(XeviousMap:KindAt(stage, row)) THEN DO:
                    c = XeviousMap:ColAt(stage, row).
                    Assert:IsTrue(c >= 0 AND c <= 13).
                    Assert:IsFalse(XeviousMap:IsPath(stage, c, row)).
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRiverAndTheRoadKeepToTheirColumnsAndMoveOneColumnAtATime():
        VAR INTEGER stage.
        VAR INTEGER row.
        DO stage = 1 TO 16:
            DO row = 0 TO 118:
                Assert:IsTrue(XeviousMap:RiverCol(stage, row) >= 2 AND XeviousMap:RiverCol(stage, row) <= 6).
                Assert:IsTrue(XeviousMap:RoadCol(stage, row) >= 9 AND XeviousMap:RoadCol(stage, row) <= 11).
                Assert:IsTrue(ABSOLUTE(XeviousMap:RiverCol(stage, row + 1) - XeviousMap:RiverCol(stage, row)) <= 1).
                Assert:IsTrue(ABSOLUTE(XeviousMap:RoadCol(stage, row + 1) - XeviousMap:RoadCol(stage, row)) <= 1).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhichStagesHaveARiverAndARoad():
        Assert:IsFalse(XeviousMap:RiverOn(1)).
        Assert:IsTrue(XeviousMap:RiverOn(2)).
        Assert:IsTrue(XeviousMap:RiverOn(18)).
        Assert:IsTrue(XeviousMap:RoadOn(1)).
        Assert:IsFalse(XeviousMap:RoadOn(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStraightRiverIsANorthSouthTileAndAShiftIsTwoBends():
        VAR INTEGER row.
        VAR INTEGER a.
        VAR INTEGER b.
        VAR INTEGER shift.
        DO row = 0 TO 100:
            a = XeviousMap:RiverCol(2, row).
            b = XeviousMap:RiverCol(2, row + 1).
            IF XeviousMap:IsCrossing(2, row) THEN NEXT.
            IF a = b THEN
                Assert:IsTrue(STRING(XeviousMap:PictureAt(2, a, row)) BEGINS "RiverNs").
            ELSE DO:
                shift = shift + 1.
                Assert:IsTrue(INDEX("RiverSe,RiverSw", STRING(XeviousMap:PictureAt(2, a, row))) > 0).
                Assert:IsTrue(INDEX("RiverNw,RiverNe", STRING(XeviousMap:PictureAt(2, b, row))) > 0).
            END.
        END.
        Assert:IsTrue(shift > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARoadCrossesTheRiverOverABridgeEveryTwentyFourRows():
        Assert:IsTrue(XeviousMap:IsCrossing(2, 9)).
        Assert:IsTrue(XeviousMap:IsCrossing(2, 33)).
        Assert:IsFalse(XeviousMap:IsCrossing(2, 10)).
        Assert:IsFalse(XeviousMap:IsCrossing(1, 9)).
        Assert:Equals(STRING(XeviousTilePicture:BridgeEw), STRING(XeviousMap:PictureAt(2, XeviousMap:RiverCol(2, 9), 9))).
        Assert:Equals(STRING(XeviousTilePicture:RoadTW), STRING(XeviousMap:PictureAt(2, XeviousMap:RoadCol(2, 9), 9))).
        Assert:Equals(STRING(XeviousTilePicture:RoadEw), STRING(XeviousMap:PictureAt(2, 0, 9))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTileOfEveryStageIsAPictureAndForestEdgesMeetTheirNeighbours():
        VAR INTEGER stage.
        VAR INTEGER row.
        VAR INTEGER c.
        VAR INTEGER forest.
        DO stage = 1 TO 16:
            DO row = 0 TO 119:
                DO c = 0 TO 13:
                    Assert:IsTrue(VALID-OBJECT(XeviousMap:PictureAt(stage, c, row))).
                    IF STRING(XeviousMap:PictureAt(stage, c, row)) BEGINS "Forest" THEN forest = forest + 1.
                END.
            END.
        END.
        Assert:IsTrue(forest > 500).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ForestIsNeverNextToAPathOrAPad():
        VAR INTEGER stage.
        VAR INTEGER row.
        VAR INTEGER c.
        DO stage = 1 TO 16:
            DO row = 1 TO 110:
                DO c = 1 TO 13:
                    IF XeviousMap:IsForestCorner(stage, c, row) THEN DO:
                        Assert:IsFalse(XeviousMap:IsPath(stage, c - 1, row)).
                        Assert:IsFalse(XeviousMap:IsPath(stage, c, row)).
                        Assert:IsFalse(XeviousMap:IsPath(stage, c - 1, row - 1)).
                        Assert:IsFalse(XeviousMap:IsPath(stage, c, row - 1)).
                        Assert:IsFalse(XeviousMap:IsPad(stage, c, row)).
                    END.
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundTargetStandsOnAPadAndAHiddenOneDoesNot():
        VAR INTEGER row.
        VAR INTEGER found.
        DO row = 4 TO 107:
            IF VALID-OBJECT(XeviousMap:KindAt(3, row)) AND NOT XeviousRules:IsHidden(XeviousMap:KindAt(3, row)) THEN DO:
                Assert:IsTrue(XeviousMap:IsPad(3, XeviousMap:ColAt(3, row), row)).
                Assert:Equals(STRING(XeviousTilePicture:Pad), STRING(XeviousMap:PictureAt(3, XeviousMap:ColAt(3, row), row))).
                found = found + 1.
            END.
        END.
        Assert:IsTrue(found > 5).
        Assert:IsFalse(XeviousMap:IsPad(3, XeviousMap:ColAt(3, XeviousMap:SolRow(3, 0)), XeviousMap:SolRow(3, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LandLinesAreCutIntoFourTilesAndOnlyOnOpenGround():
        VAR INTEGER stage.
        VAR INTEGER band.
        VAR INTEGER c0.
        VAR INTEGER r0.
        VAR INTEGER lines.
        DO band = 1 TO 8:
            r0 = XeviousMap:LineRow(10, band).
            c0 = XeviousMap:LineCol(10, band).
            Assert:IsTrue(c0 >= 1 AND c0 <= 11).
            IF XeviousMap:LineDesign(10, r0) >= 0 THEN DO:
                lines = lines + 1.
                Assert:IsTrue(STRING(XeviousMap:PictureAt(10, c0, r0)) BEGINS "Lines").
                Assert:IsTrue(STRING(XeviousMap:PictureAt(10, c0 + 1, r0 + 1)) BEGINS "Lines").
                Assert:IsFalse(XeviousMap:IsPath(10, c0, r0)).
            END.
        END.
        Assert:IsTrue(lines >= 2).
        Assert:IsTrue(XeviousMap:LinesPercent(10) > XeviousMap:LinesPercent(3)).
        Assert:IsTrue(XeviousMap:ForestPercent(9) > XeviousMap:ForestPercent(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileOffTheFieldIsRefused():
        VAR INTEGER thrown.
        VAR XeviousTilePicture pic.
        DO ON ERROR UNDO, THROW:
            pic = XeviousMap:PictureAt(1, 14, 3).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
