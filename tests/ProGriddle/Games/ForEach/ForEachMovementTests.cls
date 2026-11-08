/* How Dibby moves: on his own, along the lanes, at the speed of the level, turning when he is told to and the way is open,
   reversing at once, stopping at a wall, coming out of the other side of a tunnel, and pausing a moment for every bit and
   commit he eats. The tests use small mazes without phantoms (see ForEachKit), so only Dibby is in play. Dibby's tile centre
   is at 4 pixels in from the tile's left and top edge (tile 5 is centred on x 44). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachMovementTests:

    VAR PRIVATE ForEachGame mGame.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* A game in play on a maze, ready to move. */
    METHOD PRIVATE VOID PlayOn(INPUT pcMaze AS CHARACTER):
        mGame = ForEachKit:GameOn(pcMaze).
        ForEachKit:Play(mGame).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyStartsOnHisMarkerFacingLeftAndWalksWithoutBeingTold():
        PlayOn(ForEachKit:ClosedCorridor()).
        Assert:Equals(88, mGame:DibbyX).
        Assert:Equals(12, mGame:DibbyY).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
        ForEachKit:Frames(mGame, 10).
        Assert:IsTrue(mGame:DibbyX < 88).
        Assert:IsTrue(mGame:DibbyMoving).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelOneHeWalksAboutSixtyOnePixelsASecond():
        PlayOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(88 - mGame:DibbyX >= 59).
        Assert:IsTrue(88 - mGame:DibbyX <= 62).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HeIsFasterOnLevelFiveThanOnLevelOne():
        VAR INTEGER slow.
        PlayOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Frames(mGame, 40).
        slow = 88 - mGame:DibbyX.
        mGame:StartLevel(5).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        ForEachKit:Frames(mGame, 40).
        Assert:IsTrue(88 - mGame:DibbyX > slow).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HeStopsAtAWallInTheMiddleOfTheTileAndSaysSo():
        PlayOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Frames(mGame, 200).
        Assert:Equals(12, mGame:DibbyX).
        Assert:Equals(1, mGame:DibbyCol).
        Assert:IsFalse(mGame:DibbyMoving).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningRoundHappensAtOnceEvenInTheMiddleOfATile():
        VAR INTEGER x.
        PlayOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Frames(mGame, 10).
        mGame:Steer(MazeDir:Right).
        ForEachKit:Frames(mGame, 1).
        x = mGame:DibbyX.
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(MazeDir:Right, mGame:DibbyDir).
        Assert:IsTrue(mGame:DibbyX > x).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APressTowardsAWallIsKeptUntilTheWayOpensAndNeverStopsHim():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:Steer(MazeDir:Up).
        ForEachKit:Frames(mGame, 20).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
        Assert:Equals(MazeDir:Up, mGame:WantedDir).
        Assert:IsTrue(mGame:DibbyX < 88).
        Assert:Equals(12, mGame:DibbyY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnIntoAnOpeningIsTakenAtTheOpeningAndHeKeepsGoingDown():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(76, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 80).
        Assert:Equals(MazeDir:Down, mGame:DibbyDir).
        Assert:Equals(5, mGame:DibbyCol).
        Assert:IsTrue(mGame:DibbyRow >= 2).
        Assert:Equals(44, mGame:DibbyX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnPressedAFewPixelsBeforeTheOpeningIsStillTaken():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(47, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(MazeDir:Down, mGame:DibbyDir).
        Assert:Equals(5, mGame:DibbyCol).
        Assert:IsTrue(mGame:DibbyRow >= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnPressedAFewPixelsAfterTheOpeningIsMissedButIsKeptForTheNextOne():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(41, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 6).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
        Assert:Equals(1, mGame:DibbyRow).
        Assert:Equals(MazeDir:Down, mGame:WantedDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlaceDibbyPutsHimWhereTheTestSaysFacingTheWayItSays():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:PlaceDibby(100, 12, MazeDir:Right).
        Assert:Equals(100, mGame:DibbyX).
        Assert:Equals(12, mGame:DibbyY).
        Assert:Equals(12, mGame:DibbyCol).
        Assert:Equals(1, mGame:DibbyRow).
        Assert:Equals(MazeDir:Right, mGame:DibbyDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APressBeforeThePlayStartsIsKeptAsTheWantedDirection():
        mGame = ForEachKit:GameOn(ForEachKit:ClosedCorridor()).
        mGame:Steer(MazeDir:Right).
        Assert:Equals(MazeDir:Right, mGame:WantedDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlaceWithNoOpeningSidewaysKeepsHimOnHisLane():
        PlayOn(ForEachKit:SideDoor()).
        mGame:Steer(MazeDir:Up).
        ForEachKit:Frames(mGame, 100).
        Assert:Equals(1, mGame:DibbyRow).
        Assert:Equals(12, mGame:DibbyY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingOutOfATunnelHeComesOutOnTheOtherSide():
        PlayOn(ForEachKit:TunnelCorridor()).
        ForEachKit:Frames(mGame, 100).
        Assert:IsTrue(mGame:DibbyX >= 0).
        Assert:IsTrue(mGame:DibbyX < 160).
        Assert:IsTrue(mGame:DibbyX > 40).
        Assert:Equals(1, mGame:DibbyRow).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingABitTakesItOffTheMazeAndCountsIt():
        PlayOn(ForEachKit:DataCorridor()).
        Assert:Equals(17, mGame:BitsLeft).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(TileKind:Path, mGame:Maze:KindAt(10, 1)).
        Assert:Equals(16, mGame:BitsLeft).
        Assert:Equals(1, mGame:BitsEaten).
        Assert:Equals(1, mGame:BitsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACommitIsEatenToo():
        PlayOn(ForEachKit:DataCorridor()).
        mGame:PlaceDibby(140, 12, MazeDir:Right).
        ForEachKit:Frames(mGame, 8).
        Assert:Equals(TileKind:Path, mGame:Maze:KindAt(18, 1)).
        Assert:Equals(1, mGame:CommitsEatenTotal).
        Assert:Equals(0, mGame:BitsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachBitCostsHimAFrameSoHeIsSlowerOverADataLane():
        VAR INTEGER bare.
        PlayOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Frames(mGame, 60).
        bare = mGame:DibbyX.
        mGame:Dispose().
        PlayOn(ForEachKit:DataCorridor()).
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(mGame:DibbyX - bare >= 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACommitMakesHimStandStillForThreeFramesAfterIt():
        VAR INTEGER x.
        VAR INTEGER n.
        PlayOn(ForEachKit:DataCorridor()).
        mGame:PlaceDibby(140, 12, MazeDir:Right).
        DO WHILE mGame:CommitsEatenTotal = 0 AND n < 20:
            mGame:Advance().
            n = n + 1.
        END.
        Assert:Equals(1, mGame:CommitsEatenTotal).
        x = mGame:DibbyX.
        ForEachKit:Frames(mGame, 3).
        Assert:Equals(x, mGame:DibbyX).
        ForEachKit:Frames(mGame, 6).
        Assert:IsTrue(mGame:DibbyX > x).
    END METHOD.

    /* ---------------------------------- cutting corners ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ATurnAskedForUpToFourPixelsBeforeAnOpeningCutsTheCornerGoingBothWaysAtOnce():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(47, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 3).
        /* three pixels to the middle of the tile: three steps that each go on along the lane and down into the turn */
        Assert:Equals(44, mGame:DibbyX).
        Assert:Equals(15, mGame:DibbyY).
        Assert:Equals(MazeDir:Down, mGame:DibbyDir).
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(44, mGame:DibbyX).
        Assert:Equals(5, mGame:DibbyCol).
        Assert:IsTrue(mGame:DibbyRow >= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CuttingTheCornerGetsHimIntoTheNewLaneSoonerThanWaitingForTheMiddle():
        VAR INTEGER cut.
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(48, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 8).
        cut = mGame:DibbyY.
        /* the same stretch, but the turn asked for only at the middle of the tile: four steps along the lane, then four down */
        mGame:PlaceDibby(48, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Left).
        ForEachKit:Frames(mGame, 4).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 4).
        Assert:Equals(20, cut).
        Assert:Equals(16, mGame:DibbyY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnAskedForMoreThanFourPixelsAheadWaitsForTheMiddle():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(50, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 2).
        Assert:Equals(12, mGame:DibbyY).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
        ForEachKit:Frames(mGame, 20).
        Assert:Equals(44, mGame:DibbyX).
        Assert:IsTrue(mGame:DibbyY > 12).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoCornerIsCutIntoAWallOrByATurnBackAndItEndsInTheMiddleOfTheNewLane():
        PlayOn(ForEachKit:SideDoor()).
        /* up from the top lane is a wall: he keeps going along the lane */
        mGame:PlaceDibby(47, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Up).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(12, mGame:DibbyY).
        /* a corner cut ends exactly on the middle of the new lane's tile column and Dibby goes straight down it */
        mGame:PlaceDibby(46, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(44, mGame:DibbyX).
        Assert:Equals(MazeDir:Down, mGame:DibbyDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AComingBackToTheLaneAfterACornerLeavesHimOnItsMiddle():
        PlayOn(ForEachKit:SideDoor()).
        mGame:PlaceDibby(47, 12, MazeDir:Left).
        mGame:Steer(MazeDir:Down).
        ForEachKit:Frames(mGame, 40).
        /* down the opening and into the lower lane, then he turns right along it: his row is the middle of that lane */
        mGame:Steer(MazeDir:Right).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(28, mGame:DibbyY).
        Assert:Equals(MazeDir:Right, mGame:DibbyDir).
    END METHOD.

END CLASS.
