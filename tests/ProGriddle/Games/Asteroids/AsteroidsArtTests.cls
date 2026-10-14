/* The shapes of Asteroids hold to the limits of the design brief: the collision radius, the number of lines. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsArtTests:

    /* The nearest and the furthest a point of the first line is from the middle, in 64ths of a cell, as a
       comma list. */
    METHOD PRIVATE CHARACTER Reach(INPUT poOutline AS Outline):
        DEFINE VARIABLE l   AS INTEGER NO-UNDO.
        DEFINE VARIABLE p   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d   AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo  AS INTEGER NO-UNDO INITIAL 999999.
        DEFINE VARIABLE hi  AS INTEGER NO-UNDO.
        DO l = 1 TO poOutline:LineCount:
            DO p = 1 TO poOutline:PointCount(l):
                d = INTEGER(ROUND(SQRT(DECIMAL(poOutline:PointX(l, p)) * poOutline:PointX(l, p) + DECIMAL(poOutline:PointY(l, p)) * poOutline:PointY(l, p)), 0)).
                lo = MINIMUM(lo, d).
                hi = MAXIMUM(hi, d).
            END.
        END.
        RETURN SUBSTITUTE("&1,&2", lo, hi).
    END METHOD.

    METHOD PRIVATE VOID CheckRocks(INPUT piSize AS INTEGER, INPUT piPoints AS INTEGER):
        DEFINE VARIABLE v     AS INTEGER NO-UNDO.
        DEFINE VARIABLE reach AS CHARACTER NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER NO-UNDO.
        r = AsteroidsArt:RockRadius(piSize) / 4.
        DO v = 0 TO AsteroidsArt:RockVariants(piSize) - 1:
            Assert:Equals(piPoints, AsteroidsArt:Rock(piSize, v):PointCount(1)).
            Assert:IsTrue(AsteroidsArt:Rock(piSize, v):IsClosed(1)).
            Assert:Equals(piPoints, AsteroidsArt:Rock(piSize, v):SegmentCount).
            reach = Reach(AsteroidsArt:Rock(piSize, v)).
            Assert:IsTrue(INTEGER(ENTRY(1, reach)) >= r * 0.85 - 2, SUBSTITUTE("rock &1 &2 is too near: &3 for &4", piSize, v, reach, r)).
            Assert:IsTrue(INTEGER(ENTRY(2, reach)) <= r * 1.15 + 2, SUBSTITUTE("rock &1 &2 is too far: &3 for &4", piSize, v, reach, r)).
            Assert:IsTrue(AsteroidsArt:Rock(piSize, v):MaxRadius <= AsteroidsArt:RockExtent(piSize) * 64).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LargeRocksHaveFiveOutlinesOf13PointsWithinFifteenPercentOfTheirRadius():
        Assert:Equals(5, AsteroidsArt:RockVariants(1)).
        CheckRocks(1, 13).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MediumRocksHaveFourOutlinesOf11PointsWithinFifteenPercentOfTheirRadius():
        Assert:Equals(4, AsteroidsArt:RockVariants(2)).
        CheckRocks(2, 11).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SmallRocksHaveFourOutlinesOf8PointsWithinFifteenPercentOfTheirRadius():
        Assert:Equals(4, AsteroidsArt:RockVariants(3)).
        CheckRocks(3, 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRockRadiiAre22And11And5AndAHalfCells():
        Assert:Equals(22 * 256, AsteroidsArt:RockRadius(1)).
        Assert:Equals(11 * 256, AsteroidsArt:RockRadius(2)).
        Assert:Equals(1408, AsteroidsArt:RockRadius(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnyVariantNumberPicksARockAndTheSameNumberPicksTheSameOne():
        Assert:IsTrue(AsteroidsArt:Rock(1, 0) = AsteroidsArt:Rock(1, 5)).
        Assert:IsTrue(AsteroidsArt:Rock(1, 0) = AsteroidsArt:Rock(1, -5)).
        Assert:IsTrue(AsteroidsArt:Rock(2, 1) = AsteroidsArt:Rock(2, 9)).
        Assert:IsTrue(AsteroidsArt:Rock(1, 0) <> AsteroidsArt:Rock(1, 1)).
        Assert:IsTrue(AsteroidsArt:Rock(1, 0) <> AsteroidsArt:Rock(2, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipIsANotchedArrowheadNineCellsTallWithItsSpine():
        DEFINE VARIABLE ship AS Outline NO-UNDO.
        ship = AsteroidsArt:Ship().
        Assert:Equals(5, ship:SegmentCount).
        Assert:Equals(1, AsteroidsArt:ShipSpine():SegmentCount).
        Assert:Equals(-6 * 64, ship:PointY(1, 1)).
        Assert:Equals(3 * 64, ship:PointY(1, 2)).
        Assert:IsTrue(ship:MaxRadius <= AsteroidsArt:ShipExtent() * 64).
        Assert:IsTrue(AsteroidsArt:ShipRadius() < ship:MaxRadius * 4).
        Assert:Equals(1152, AsteroidsArt:ShipRadius()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipBreaksIntoFiveLinesThatAreTheSidesOfTheShip():
        Assert:Equals(5, AsteroidsArt:ShipPieces():LineCount).
        Assert:Equals(5, AsteroidsArt:ShipPieces():SegmentCount).
        Assert:Equals(2, AsteroidsArt:ShipPieces():PointCount(3)).
        Assert:IsFalse(AsteroidsArt:ShipPieces():IsClosed(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFlameHasThreeFramesBehindTheShip():
        DEFINE VARIABLE f AS INTEGER NO-UNDO.
        DO f = 0 TO 2:
            Assert:IsTrue(AsteroidsArt:FlameOuter(f):PointY(1, 2) > 3 * 64).
            Assert:IsTrue(AsteroidsArt:FlameCore(f):PointY(1, 2) > 3 * 64).
            Assert:Equals(2, AsteroidsArt:FlameOuter(f):SegmentCount).
            Assert:Equals(1, AsteroidsArt:FlameCore(f):SegmentCount).
        END.
        Assert:IsTrue(AsteroidsArt:FlameOuter(0) <> AsteroidsArt:FlameOuter(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucersHaveTheirLinesAndSizes():
        Assert:Equals(10, AsteroidsArt:Saucer(TRUE):SegmentCount).
        Assert:Equals(11, AsteroidsArt:Saucer(FALSE):SegmentCount).
        Assert:Equals(3, AsteroidsArt:Saucer(TRUE):LineCount).
        Assert:Equals(14 * 64, AsteroidsArt:Saucer(TRUE):PointX(1, 6) - AsteroidsArt:Saucer(TRUE):PointX(1, 1)).
        Assert:Equals(9 * 64, AsteroidsArt:Saucer(FALSE):PointX(1, 6) - AsteroidsArt:Saucer(FALSE):PointX(1, 1)).
        Assert:Equals(1664, AsteroidsArt:SaucerRadius(TRUE)).
        Assert:Equals(1075, AsteroidsArt:SaucerRadius(FALSE)).
        Assert:IsTrue(AsteroidsArt:Saucer(TRUE):MaxRadius <= AsteroidsArt:SaucerExtent(TRUE) * 64).
        Assert:IsTrue(AsteroidsArt:Saucer(FALSE):MaxRadius <= AsteroidsArt:SaucerExtent(FALSE) * 64).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleLettersAre28CellsTallAndTheirTotalIs41Segments():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE total AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c     AS CHARACTER NO-UNDO.
        DO i = 1 TO 9:
            c = SUBSTRING("ASTEROIDS", i, 1).
            total = total + AsteroidsArt:Glyph(c):SegmentCount.
            Assert:IsTrue(AsteroidsArt:Glyph(c):MaxRadius > 0).
        END.
        Assert:Equals(41, total).
        Assert:Equals(16, AsteroidsArt:GlyphWidth("I")).
        Assert:Equals(20, AsteroidsArt:GlyphWidth("A")).
        Assert:Equals(20, AsteroidsArt:GlyphWidth("s")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadArgumentsAreRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:Rock(4, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:RockRadius(0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:RockExtent(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:FlameOuter(3).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:FlameCore(-1).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:Glyph("Q").
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:Glyph("AB").
            CATCH e7 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:Saucer(?).
            CATCH e8 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsArt:Rock(1, ?).
            CATCH e9 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(9, thrown).
    END METHOD.

END CLASS.
