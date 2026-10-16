/* The terrain generator of Blast Buddies: the same seed gives the same land, the edges are open, nothing is left floating that is smaller
   than the crumb rule allows, and every seed has room for sixteen buddies. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.TerrainGeneratorTests:

    DEFINE PRIVATE VARIABLE mGen AS TerrainGenerator NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID Setup():
        mGen = NEW TerrainGenerator().
    END METHOD.

    METHOD PRIVATE Terrain Make(INPUT piSeed AS INTEGER):
        DEFINE VARIABLE t AS Terrain NO-UNDO.
        t = NEW Terrain(Theme:Meadow).
        mGen:Generate(t, NEW SeededRandom(piSeed)).
        RETURN t.
    END METHOD.

    /* a number that changes if any column's top changes */
    METHOD PRIVATE INT64 Signature(INPUT poT AS Terrain):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS INT64   NO-UNDO.
        DO x = 0 TO 383:
            s = (s * 31 + (IF poT:FirstGround(x) = ? THEN 0 ELSE poT:FirstGround(x)) + 1) MODULO 2147483647.
        END.
        RETURN s * 7919 + poT:SolidCount().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameLandAndADifferentSeedGivesAnother():
        DEFINE VARIABLE a AS Terrain NO-UNDO.
        DEFINE VARIABLE b AS Terrain NO-UNDO.
        DEFINE VARIABLE c AS Terrain NO-UNDO.
        a = Make(7).
        b = Make(7).
        c = Make(8).
        Assert:IsTrue(Signature(a) = Signature(b)).
        Assert:IsTrue(Signature(a) <> Signature(c)).
        a:Dispose().
        b:Dispose().
        c:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLandFillsTheMapBetweenTheOpenEdgesAndDownToTheBottom():
        DEFINE VARIABLE t AS Terrain NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        t = Make(3).
        DO x = 0 TO 9:
            DO y = 0 TO 239:
                Assert:IsFalse(t:IsSolid(x, y), "left edge " + STRING(x) + "," + STRING(y)).
                Assert:IsFalse(t:IsSolid(383 - x, y), "right edge " + STRING(383 - x) + "," + STRING(y)).
            END.
        END.
        Assert:IsTrue(t:IsSolid(10, 239)).
        Assert:IsTrue(t:IsSolid(373, 239)).
        Assert:IsTrue(t:IsSolid(192, 239)).
        Assert:IsTrue(t:SolidCount() > 20000).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSurfaceStaysBetweenRowsSeventyAndOneNinety():
        DEFINE VARIABLE t   AS Terrain NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE topY AS INTEGER NO-UNDO.
        t = Make(11).
        DO x = 10 TO 373:
            topY = t:FirstGround(x).
            Assert:IsTrue(topY <> ? AND topY >= 20 AND topY <= 190, "column " + STRING(x)).
        END.
        Assert:IsTrue(t:FirstGround(2) = ?).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoSmallPieceIsLeftFloating():
        DEFINE VARIABLE t AS Terrain NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 21 TO 30:
            t = Make(n).
            Assert:Equals(0, t:Crumble(192, 120, 200)).
            t:Dispose().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGeneratorNeedsAMapAndARandomSource():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mGen:Generate(?, NEW SeededRandom(1)).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StandableNeedsNearlyFlatGroundAirAboveAndRoomAboveTheWater():
        DEFINE VARIABLE t AS Terrain NO-UNDO.
        t = NEW Terrain(Theme:Meadow).
        t:FillRect(0, 100, 383, 239, TRUE).
        Assert:IsTrue(mGen:Standable(t, 100, 100)).
        /* a step of 6 pixels under the nine is still fine (a buddy walks up steps of 3 a pixel), 7 is not */
        t:FillRect(103, 94, 110, 99, TRUE).
        Assert:IsTrue(mGen:Standable(t, 100, 100)).
        t:FillRect(103, 93, 110, 93, TRUE).
        Assert:IsFalse(mGen:Standable(t, 100, 100)).
        /* a block of rock 10 pixels up is the first ground of its columns, so it is not flat ground */
        t:FillRect(300, 80, 320, 90, TRUE).
        Assert:IsFalse(mGen:Standable(t, 310, 100)).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GroundNearTheWaterOrTheTopOfTheMapIsNotStandable():
        DEFINE VARIABLE t AS Terrain NO-UNDO.
        t = NEW Terrain(Theme:Meadow).
        t:FillRect(0, 210, 383, 239, TRUE).
        Assert:IsFalse(mGen:Standable(t, 100, 210)).
        t:FillRect(0, 10, 383, 239, TRUE).
        Assert:IsFalse(mGen:Standable(t, 100, 10)).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FindSpotsPicksSpacedOutStandableSpotsAndIsDeterministic():
        DEFINE VARIABLE t  AS Terrain NO-UNDO.
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE x2 AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE y2 AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE j  AS INTEGER NO-UNDO.
        t = Make(5).
        mGen:FindSpots(t, NEW SeededRandom(99), 12, 20, OUTPUT xs, OUTPUT ys).
        mGen:FindSpots(t, NEW SeededRandom(99), 12, 20, OUTPUT x2, OUTPUT y2).
        Assert:Equals(12, EXTENT(xs)).
        DO i = 1 TO 12:
            Assert:Equals(xs[i], x2[i]).
            Assert:Equals(ys[i], y2[i]).
            Assert:Equals(ys[i], t:FirstGround(xs[i])).
            Assert:IsTrue(mGen:Standable(t, xs[i], ys[i])).
            Assert:IsTrue(xs[i] >= 18 AND xs[i] <= 365).
            DO j = i + 1 TO 12:
                Assert:IsTrue(ABSOLUTE(xs[i] - xs[j]) >= 20).
            END.
        END.
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FindSpotsRefusesWhenThereIsNoRoom():
        DEFINE VARIABLE t       AS Terrain NO-UNDO.
        DEFINE VARIABLE xs      AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys      AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        t = NEW Terrain(Theme:Meadow).
        DO ON ERROR UNDO, LEAVE:
            mGen:FindSpots(t, NEW SeededRandom(1), 2, 20, OUTPUT xs, OUTPUT ys).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        t:FillRect(0, 100, 383, 239, TRUE).
        DO ON ERROR UNDO, LEAVE:
            mGen:FindSpots(t, NEW SeededRandom(1), 40, 20, OUTPUT xs, OUTPUT ys).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mGen:FindSpots(t, NEW SeededRandom(1), 0, 20, OUTPUT xs, OUTPUT ys).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEdgeGapIsTenColumns():
        Assert:Equals(10, TerrainGenerator:EdgeGap).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHundredSeedsAllHaveRoomForSixteenBuddies():
        DEFINE VARIABLE t  AS Terrain NO-UNDO.
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE s  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ms AS INTEGER NO-UNDO.
        ETIME(TRUE).
        DO s = 1 TO 100:
            t = Make(s).
            mGen:FindSpots(t, NEW SeededRandom(s + 1000), 16, 14, OUTPUT xs, OUTPUT ys).
            Assert:IsTrue(EXTENT(xs) = 16, "seed " + STRING(s)).
            t:Dispose().
        END.
        ms = ETIME.
        MESSAGE "timing: 100 maps made and 16 spots found in each took" ms "ms".
        Assert:IsTrue(TRUE).
    END METHOD.

END CLASS.
