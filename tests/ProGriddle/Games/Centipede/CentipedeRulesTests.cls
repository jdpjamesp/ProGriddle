/* The numbers of Centipede: the shape of the board, the points, the speeds and the limits. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeRulesTests:

    @Test.
    METHOD PUBLIC VOID TheBoardIsThirtyBySixThirtyTilesOfEightPixels():
        Assert:Equals(30, CentipedeRules:Cols()).
        Assert:Equals(30, CentipedeRules:Rows()).
        Assert:Equals(8, CentipedeRules:Tile()).
        Assert:Equals(240, CentipedeRules:BoardPixels()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePlayerZoneIsTheBottomSixRows():
        Assert:Equals(24, CentipedeRules:PlayerTop()).
        Assert:Equals(6, CentipedeRules:Rows() - CentipedeRules:PlayerTop()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWaveIsTwelveSegmentsAndNeverMoreThanEightOfThemLooseHeads():
        Assert:Equals(12, CentipedeRules:SegmentsPerWave()).
        Assert:Equals(8, CentipedeRules:MostExtraHeads()).
        Assert:Equals(4, CentipedeRules:MushroomHp()).
        Assert:Equals(3, CentipedeRules:StartLives()).
        Assert:Equals(12000, CentipedeRules:ExtraLifeEvery()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePointsAreThoseOfTheArcade():
        Assert:Equals(10, CentipedeRules:PointsSegment()).
        Assert:Equals(100, CentipedeRules:PointsHead()).
        Assert:Equals(1, CentipedeRules:PointsMushroom()).
        Assert:Equals(5, CentipedeRules:PointsRepair()).
        Assert:Equals(200, CentipedeRules:PointsFlea()).
        Assert:Equals(1000, CentipedeRules:PointsScorpion()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpiderPaysMoreTheCloserItIsShot():
        Assert:Equals(900, CentipedeRules:PointsSpider(0)).
        Assert:Equals(900, CentipedeRules:PointsSpider(23)).
        Assert:Equals(600, CentipedeRules:PointsSpider(24)).
        Assert:Equals(600, CentipedeRules:PointsSpider(55)).
        Assert:Equals(300, CentipedeRules:PointsSpider(56)).
        Assert:Equals(300, CentipedeRules:PointsSpider(500)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedsAreInPixelsAFrame():
        Assert:Equals(3, CentipedeRules:PlayerSpeed()).
        Assert:Equals(8, CentipedeRules:ShotSpeed()).
        Assert:Equals(2, CentipedeRules:SegmentSpeed(1)).
        Assert:Equals(3, CentipedeRules:SegmentSpeed(9)).
    END METHOD.

END CLASS.
