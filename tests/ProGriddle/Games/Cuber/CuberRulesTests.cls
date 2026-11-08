/* The numbers and the geometry of Cuber: where a lamp is on the 256 x 256 picture, which rows and columns are lamps, where the
   halos are, and how the level changes the rules. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberRulesTests:

    @Test.
    METHOD PUBLIC VOID ThePyramidHasSevenRowsAndTwentyEightLampsOnA256Canvas():
        Assert:Equals(7, CuberRules:Rows()).
        Assert:Equals(28, CuberRules:LampTotal()).
        Assert:Equals(256, CuberRules:CanvasSize()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LampPlacesAreTheDesignersNumbers():
        Assert:Equals(112, CuberRules:LampX(1, 0)).
        Assert:Equals(48, CuberRules:LampY(1)).
        Assert:Equals(96, CuberRules:LampX(2, 0)).
        Assert:Equals(128, CuberRules:LampX(2, 1)).
        Assert:Equals(72, CuberRules:LampY(2)).
        Assert:Equals(16, CuberRules:LampX(7, 0)).
        Assert:Equals(208, CuberRules:LampX(7, 6)).
        Assert:Equals(192, CuberRules:LampY(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFootPointIsTheMiddleOfTheTopDiamond():
        Assert:Equals(128, CuberRules:FootX(1, 0)).
        Assert:Equals(56, CuberRules:FootY(1)).
        Assert:Equals(224, CuberRules:FootX(7, 6)).
        Assert:Equals(200, CuberRules:FootY(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopMovesTheFootSixteenAcrossAndTwentyFourDown():
        Assert:Equals(16, CuberRules:FootX(2, 1) - CuberRules:FootX(1, 0)).
        Assert:Equals(-16, CuberRules:FootX(2, 0) - CuberRules:FootX(1, 0)).
        Assert:Equals(24, CuberRules:FootY(2) - CuberRules:FootY(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsLampIsTrueOnlyInsideThePyramid():
        Assert:IsTrue(CuberRules:IsLamp(1, 0)).
        Assert:IsTrue(CuberRules:IsLamp(7, 6)).
        Assert:IsFalse(CuberRules:IsLamp(0, 0)).
        Assert:IsFalse(CuberRules:IsLamp(8, 0)).
        Assert:IsFalse(CuberRules:IsLamp(3, -1)).
        Assert:IsFalse(CuberRules:IsLamp(3, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSixHalosSitOneColumnOutsideRowsThreeFourAndFive():
        Assert:Equals(6, CuberRules:HaloSpots()).
        Assert:Equals(3, CuberRules:HaloRow(1)).
        Assert:Equals(-1, CuberRules:HaloCol(1)).
        Assert:Equals(3, CuberRules:HaloRow(2)).
        Assert:Equals(3, CuberRules:HaloCol(2)).
        Assert:Equals(5, CuberRules:HaloRow(5)).
        Assert:Equals(5, CuberRules:HaloCol(6)).
        Assert:Equals(-1, CuberRules:HaloCol(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HaloFootPointsAreTheDesignersNumbers():
        Assert:Equals(64, CuberRules:FootX(CuberRules:HaloRow(1), CuberRules:HaloCol(1))).
        Assert:Equals(104, CuberRules:FootY(CuberRules:HaloRow(1))).
        Assert:Equals(192, CuberRules:FootX(CuberRules:HaloRow(2), CuberRules:HaloCol(2))).
        Assert:Equals(48, CuberRules:FootX(CuberRules:HaloRow(3), CuberRules:HaloCol(3))).
        Assert:Equals(224, CuberRules:FootX(CuberRules:HaloRow(6), CuberRules:HaloCol(6))).
        Assert:Equals(152, CuberRules:FootY(CuberRules:HaloRow(6))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HaloSpotAtFindsTheSpotOfARowAndColumnOrZero():
        VAR INTEGER s.
        DO s = 1 TO 6:
            Assert:Equals(s, CuberRules:HaloSpotAt(CuberRules:HaloRow(s), CuberRules:HaloCol(s))).
        END.
        Assert:Equals(0, CuberRules:HaloSpotAt(2, -1)).
        Assert:Equals(0, CuberRules:HaloSpotAt(6, 6)).
        Assert:Equals(0, CuberRules:HaloSpotAt(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHaloSpotOutsideOneToSixThrows():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            CuberRules:HaloRow(0).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHopHasTwelveFramesAndAnArcThatPeaksInTheMiddle():
        Assert:Equals(12, CuberRules:HopFrames()).
        Assert:Equals(0, CuberRules:HopLift(0, 12)).
        Assert:Equals(12, CuberRules:HopLift(6, 12)).
        Assert:Equals(0, CuberRules:HopLift(12, 12)).
        Assert:Equals(10, CuberRules:HopLift(6, 10)).
        Assert:IsTrue(CuberRules:HopLift(3, 12) < CuberRules:HopLift(6, 12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimingsAreInFrames():
        Assert:Equals(2, CuberRules:LandingFrames()).
        Assert:Equals(14, CuberRules:WantFrames()).
        Assert:Equals(90, CuberRules:ReadyFrames()).
        Assert:Equals(58, CuberRules:HitFrames()).
        Assert:Equals(70, CuberRules:FallFrames()).
        Assert:Equals(72, CuberRules:RideFrames()).
        Assert:Equals(180, CuberRules:ClearFrames()).
        Assert:Equals(30, CuberRules:HatchFrames()).
        Assert:Equals(8, CuberRules:EnemySlots()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThreePipsAndAnExtraOneEveryEightThousand():
        Assert:Equals(2, CuberRules:StartLives()).
        Assert:Equals(8000, CuberRules:ExtraLifeEvery()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePointsAreTheDesignersScores():
        Assert:Equals(25, CuberRules:PointsLamp()).
        Assert:Equals(10, CuberRules:PointsHalfLamp()).
        Assert:Equals(50, CuberRules:PointsHalo()).
        Assert:Equals(100, CuberRules:PointsFrost()).
        Assert:Equals(300, CuberRules:PointsMoth()).
        Assert:Equals(500, CuberRules:PointsCoil()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelChangesTheRules():
        Assert:Equals(1, CuberRules:HitsToLight(1)).
        Assert:Equals(1, CuberRules:HitsToLight(2)).
        Assert:Equals(2, CuberRules:HitsToLight(3)).
        Assert:IsFalse(CuberRules:UndoOnLand(4)).
        Assert:IsTrue(CuberRules:UndoOnLand(5)).
        Assert:IsFalse(CuberRules:MothsCome(1)).
        Assert:IsTrue(CuberRules:MothsCome(2)).
        Assert:Equals(4, CuberRules:HalosIn(1)).
        Assert:Equals(3, CuberRules:HalosIn(3)).
        Assert:Equals(2, CuberRules:HalosIn(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TempoGrowsWithLevelAndRoundAndStopsAtTwelve():
        Assert:Equals(0, CuberRules:Tempo(1, 1)).
        Assert:Equals(3, CuberRules:Tempo(1, 4)).
        Assert:Equals(3, CuberRules:Tempo(2, 1)).
        Assert:Equals(12, CuberRules:Tempo(9, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverythingQuickensWithTheTempo():
        Assert:IsTrue(CuberRules:CoilRest(12) < CuberRules:CoilRest(0)).
        Assert:IsTrue(CuberRules:BallRest(12) < CuberRules:BallRest(0)).
        Assert:IsTrue(CuberRules:MothRest(12) < CuberRules:MothRest(0)).
        Assert:IsTrue(CuberRules:ThornEvery(12) < CuberRules:ThornEvery(0)).
        Assert:IsTrue(CuberRules:MothEvery(12) < CuberRules:MothEvery(0)).
        Assert:IsTrue(CuberRules:CoilAim(12) > CuberRules:CoilAim(0)).
        Assert:IsTrue(CuberRules:FreezeFrames(12) < CuberRules:FreezeFrames(0)).
        Assert:Equals(150, CuberRules:SeedDelay()).
        Assert:Equals(900, CuberRules:FrostEvery()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACoilIsNeverSlowerThanAFiveFrameRestOrAimBetterThanCertain():
        Assert:IsTrue(CuberRules:CoilRest(12) >= 10).
        Assert:IsTrue(CuberRules:CoilAim(12) <= 100).
        Assert:IsTrue(CuberRules:FreezeFrames(12) >= 90).
    END METHOD.

END CLASS.
