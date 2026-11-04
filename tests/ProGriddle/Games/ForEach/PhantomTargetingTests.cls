/* Where each phantom is heading, tile by tile, as the rules work it out. Scatter: each phantom has a corner outside the maze.
   Chase: Mary aims at Dibby, Rich at the tile four ahead of him, Brian at a tile found from Mary and the tile two ahead
   of Dibby, Chip at Dibby until he is within 8 tiles and then at his own corner. Facing up, the "ahead" rule has a
   bug that also moves the tile that many tiles left, and it is kept on purpose. Rows are counted from the top of the maze, so
   the corners above and below it are rows -3 and 33. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.PhantomTargetingTests:

    METHOD PRIVATE LOGICAL ThrowsGridException():
        DEFINE VARIABLE target AS Coord    NO-UNDO.
        DEFINE VARIABLE kind   AS PhantomKind NO-UNDO.
        DO ON ERROR UNDO, THROW:
            target = PhantomTargeting:ScatterTarget(kind).
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* True when the target is the tile. */
    METHOD PRIVATE LOGICAL Aims(INPUT poTarget AS Coord, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN poTarget:X = piCol AND poTarget:Y = piRow.
    END METHOD.

    /* The chase target of a kind of phantom with Dibby at column 10 row 20 facing the way given, the phantom at 5, 5 and Mary at 8, 20. */
    METHOD PRIVATE Coord Chase(INPUT poKind AS PhantomKind, INPUT poDibbyDir AS MazeDir):
        RETURN PhantomTargeting:ChaseTarget(poKind, 5, 5, 10, 20, poDibbyDir, 8, 20).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachPhantomScattersToACornerOutsideTheMaze():
        Assert:IsTrue(Aims(PhantomTargeting:ScatterTarget(PhantomKind:Mary), 25, -3)).
        Assert:IsTrue(Aims(PhantomTargeting:ScatterTarget(PhantomKind:Rich), 2, -3)).
        Assert:IsTrue(Aims(PhantomTargeting:ScatterTarget(PhantomKind:Brian), 27, 33)).
        Assert:IsTrue(Aims(PhantomTargeting:ScatterTarget(PhantomKind:Chip), 0, 33)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownPhantomIsRefused():
        Assert:IsTrue(ThrowsGridException()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MaryAimsAtTheDibbyTileWhicheverWayHeFaces():
        Assert:IsTrue(Aims(Chase(PhantomKind:Mary, MazeDir:Left), 10, 20)).
        Assert:IsTrue(Aims(Chase(PhantomKind:Mary, MazeDir:Up), 10, 20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RichAimsFourTilesAheadOfDibby():
        Assert:IsTrue(Aims(Chase(PhantomKind:Rich, MazeDir:Right), 14, 20)).
        Assert:IsTrue(Aims(Chase(PhantomKind:Rich, MazeDir:Left), 6, 20)).
        Assert:IsTrue(Aims(Chase(PhantomKind:Rich, MazeDir:Down), 10, 24)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RichFacingUpAimsFourUpAndFourLeftBecauseOfAKnownBug():
        Assert:IsTrue(Aims(Chase(PhantomKind:Rich, MazeDir:Up), 6, 16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BrianAimsAsFarBeyondThePointTwoAheadOfDibbyAsMaryIsBehindIt():
        /* two ahead is 12, 20 and Mary is at 8, 20, so the target is 12 + (12 - 8), 20 + (20 - 20) */
        Assert:IsTrue(Aims(Chase(PhantomKind:Brian, MazeDir:Right), 16, 20)).
        /* two ahead is 8, 20: the target is 8 + (8 - 8), 20 */
        Assert:IsTrue(Aims(Chase(PhantomKind:Brian, MazeDir:Left), 8, 20)).
        /* two ahead is 10, 22: the target is 10 + (10 - 8), 22 + (22 - 20) */
        Assert:IsTrue(Aims(Chase(PhantomKind:Brian, MazeDir:Down), 12, 24)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BrianFacingUpHasTheSameBugWithTwoTilesLeft():
        /* two ahead is 8, 18 (two up and two left): the target is 8 + (8 - 8), 18 + (18 - 20) */
        Assert:IsTrue(Aims(Chase(PhantomKind:Brian, MazeDir:Up), 8, 16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChipChasesDibbyFromEightOrMoreTilesAwayAndGoesHomeWhenCloser():
        /* the phantom is at 5, 5: Dibby at 5, 12 is 7 tiles away and at 5, 13 is 8 */
        Assert:IsTrue(Aims(PhantomTargeting:ChaseTarget(PhantomKind:Chip, 5, 5, 5, 12, MazeDir:Left, 8, 20), 0, 33)).
        Assert:IsTrue(Aims(PhantomTargeting:ChaseTarget(PhantomKind:Chip, 5, 5, 5, 13, MazeDir:Left, 8, 20), 5, 13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChipMeasuresTheStraightLineDistanceAcrossTheDiagonalToo():
        /* 5 across and 6 down is a squared distance of 61, 6 across and 6 down is 72, and 8 tiles is 64 */
        Assert:IsTrue(Aims(PhantomTargeting:ChaseTarget(PhantomKind:Chip, 0, 0, 5, 6, MazeDir:Left, 8, 20), 0, 33)).
        Assert:IsTrue(Aims(PhantomTargeting:ChaseTarget(PhantomKind:Chip, 0, 0, 6, 6, MazeDir:Left, 8, 20), 6, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomThatHasBeenEatenHeadsForTheTileAboveTheLobbyDoor():
        Assert:IsTrue(Aims(PhantomTargeting:ReturningTarget(), 13, 11)).
    END METHOD.

END CLASS.
