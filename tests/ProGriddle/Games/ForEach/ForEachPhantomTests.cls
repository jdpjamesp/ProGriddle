/* The phantoms in play: where they stand, when they leave the lobby, how fast they go, the scatter and chase waves, the
   rolled back time after a commit, being eaten for 200 400 800 and 1600, returning running home, and Mary speeding up. A phantom is
   in one PhantomMode: Waiting in the lobby, Leaving through the door, Scatter, Chase, RolledBack or Returning. The tests place phantoms
   with PlacePhantom, which also brings a phantom that is not in the maze into play, and use small mazes so that nothing else is
   going on. Rollback does what eating a commit does to the phantoms, and SwitchWave does what the wave timer running out does. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachPhantomTests:

    DEFINE PRIVATE VARIABLE mGame AS ForEachGame NO-UNDO.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE VOID PlayOn(INPUT pcMaze AS CHARACTER):
        mGame = ForEachKit:GameOn(pcMaze).
        ForEachKit:Play(mGame).
    END METHOD.

    METHOD PRIVATE VOID PlayFull():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        ForEachKit:Play(mGame).
    END METHOD.

    /* A phantom in the upper lane of the two lanes, heading right in the mode, with Dibby on the lower lane out of its way. */
    METHOD PRIVATE VOID LanePhantom(INPUT poKind AS PhantomKind, INPUT piX AS INTEGER, INPUT poMode AS PhantomMode):
        PlayOn(ForEachKit:TwoLanes()).
        mGame:PlacePhantom(poKind, piX, 12, MazeDir:Right, poMode).
    END METHOD.

    /* ---------------------------------- the lobby ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID PlacePhantomBringsAPhantomIntoPlayAndSetsItsPositionDirectionAndMode():
        PlayOn(ForEachKit:TwoLanes()).
        Assert:IsFalse(mGame:PhantomPresent(PhantomKind:Rich)).
        mGame:PlacePhantom(PhantomKind:Rich, 60, 12, MazeDir:Left, PhantomMode:Chase).
        Assert:IsTrue(mGame:PhantomPresent(PhantomKind:Rich)).
        Assert:Equals(60, mGame:PhantomX(PhantomKind:Rich)).
        Assert:Equals(12, mGame:PhantomY(PhantomKind:Rich)).
        Assert:Equals(7, mGame:PhantomCol(PhantomKind:Rich)).
        Assert:Equals(1, mGame:PhantomRow(PhantomKind:Rich)).
        Assert:Equals(MazeDir:Left, mGame:PhantomDir(PhantomKind:Rich)).
        Assert:Equals(PhantomMode:Chase, mGame:ModeOf(PhantomKind:Rich)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelOneRichLeavesTheLobbyAtOnceAndBrianAndChipWait():
        PlayFull().
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Rich) <> PhantomMode:Waiting).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Brian)).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Chip)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BrianLeavesAfterDibbyHasEaten30ThingsAndChipAfterAnother60():
        PlayFull().
        mGame:EatBits(29).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Brian)).
        mGame:EatBits(1).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Brian) <> PhantomMode:Waiting).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Chip)).
        /* each phantom's own count starts when the one before it has gone, so Chip needs 60 more */
        mGame:EatBits(50).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Chip)).
        mGame:EatBits(10).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Chip) <> PhantomMode:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomThatLeavesGoesUpThroughTheDoorAndOutToTheWaveMode():
        PlayFull().
        ForEachKit:Frames(mGame, 200).
        Assert:Equals(PhantomMode:Scatter, mGame:ModeOf(PhantomKind:Rich)).
        Assert:IsTrue(mGame:PhantomRow(PhantomKind:Rich) <= 11).
    END METHOD.

    /* ---------------------------------- speed ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID OnLevelOneAPhantomRunsAtSevenTenthsOfFullSpeedAndSoSlowerThanDibby():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        x = mGame:PhantomX(PhantomKind:Mary).
        ForEachKit:Frames(mGame, 60).
        /* it may turn round only at a wall, and the lane has none, so it kept going */
        Assert:IsTrue(mGame:PhantomX(PhantomKind:Mary) - x >= 51).
        Assert:IsTrue(mGame:PhantomX(PhantomKind:Mary) - x <= 54).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InTheTunnelAPhantomRunsAtFortyPercent():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        PlayOn(ForEachKit:SlowCorridor()).
        mGame:PlaceDibby(100, 12, MazeDir:Right).
        mGame:PlacePhantom(PhantomKind:Mary, 20, 12, MazeDir:Right, PhantomMode:Scatter).
        x = mGame:PhantomX(PhantomKind:Mary).
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(mGame:PhantomX(PhantomKind:Mary) - x >= 28).
        Assert:IsTrue(mGame:PhantomX(PhantomKind:Mary) - x <= 32).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARolledBackPhantomRunsAtHalfSpeed():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        mGame:Rollback().
        x = mGame:PhantomX(PhantomKind:Mary).
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(ABSOLUTE(mGame:PhantomX(PhantomKind:Mary) - x) >= 34).
        Assert:IsTrue(ABSOLUTE(mGame:PhantomX(PhantomKind:Mary) - x) <= 42).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhantomsReturningRunFasterThanAnythingElse():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        LanePhantom(PhantomKind:Mary, 20, PhantomMode:Returning).
        x = mGame:PhantomX(PhantomKind:Mary).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(ABSOLUTE(mGame:PhantomX(PhantomKind:Mary) - x) >= 35).
    END METHOD.

    /* ---------------------------------- the waves ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheWavesStartWithAScatterAndTheTimerRunsDown():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        Assert:Equals(1, mGame:WaveNumber).
        Assert:Equals(420, mGame:WaveFramesLeft).
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(410, mGame:WaveFramesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheScatterTimeIsUpThePhantomsChase():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        ForEachKit:Frames(mGame, 421).
        Assert:Equals(2, mGame:WaveNumber).
        Assert:Equals(PhantomMode:Chase, mGame:ModeOf(PhantomKind:Mary)).
        Assert:IsTrue(mGame:WaveFramesLeft >= 1196 AND mGame:WaveFramesLeft <= 1200).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SwitchWaveDoesWhatTheTimerRunningOutDoes():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        mGame:SwitchWave().
        Assert:Equals(2, mGame:WaveNumber).
        Assert:Equals(PhantomMode:Chase, mGame:ModeOf(PhantomKind:Mary)).
        mGame:SwitchWave().
        Assert:Equals(3, mGame:WaveNumber).
        Assert:Equals(PhantomMode:Scatter, mGame:ModeOf(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomTurnsRoundWhenTheWaveChanges():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(MazeDir:Right, mGame:PhantomDir(PhantomKind:Mary)).
        mGame:SwitchWave().
        ForEachKit:Frames(mGame, 12).
        Assert:Equals(MazeDir:Left, mGame:PhantomDir(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastWaveIsAChaseThatNeverEnds():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        DO n = 1 TO 7:
            mGame:SwitchWave().
        END.
        Assert:Equals(8, mGame:WaveNumber).
        Assert:Equals(PhantomMode:Chase, mGame:ModeOf(PhantomKind:Mary)).
        mGame:SwitchWave().
        Assert:Equals(8, mGame:WaveNumber).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachPhantomShowsWhereItIsHeadingScatterToItsCornerAndChaseToDibby():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        Assert:Equals(25, mGame:PhantomTargetCol(PhantomKind:Mary)).
        Assert:Equals(-3, mGame:PhantomTargetRow(PhantomKind:Mary)).
        mGame:SwitchWave().
        Assert:Equals(mGame:DibbyCol, mGame:PhantomTargetCol(PhantomKind:Mary)).
        Assert:Equals(mGame:DibbyRow, mGame:PhantomTargetRow(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowTargetsIsOffUntilSwitchedOn():
        PlayOn(ForEachKit:TwoLanes()).
        Assert:IsFalse(mGame:ShowTargets).
        mGame:ShowTargets = TRUE.
        Assert:IsTrue(mGame:ShowTargets).
    END METHOD.

    /* ---------------------------------- rolled back ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ACommitMakesPhantomsOutInTheMazeRolledBackAndTurnsThemRound():
        PlayOn(ForEachKit:DataCorridor()).
        mGame:PlacePhantom(PhantomKind:Mary, 60, 12, MazeDir:Right, PhantomMode:Scatter).
        mGame:PlaceDibby(140, 12, MazeDir:Right).
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(1, mGame:CommitsEatenTotal).
        Assert:Equals(PhantomMode:RolledBack, mGame:ModeOf(PhantomKind:Mary)).
        Assert:Equals(MazeDir:Left, mGame:PhantomDir(PhantomKind:Mary)).
        Assert:IsTrue(mGame:RollbackFramesLeft > 330).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RollbackIsTheSameAsEatingACommitAndTheTimeIsSixSecondsOnLevelOne():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Chase).
        mGame:Rollback().
        Assert:Equals(PhantomMode:RolledBack, mGame:ModeOf(PhantomKind:Mary)).
        Assert:Equals(360, mGame:RollbackFramesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRolledBackTimeRunsOutAndThePhantomGoesBackToTheWaveMode():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        mGame:Rollback().
        ForEachKit:Frames(mGame, 361).
        Assert:Equals(0, mGame:RollbackFramesLeft).
        Assert:Equals(PhantomMode:Scatter, mGame:ModeOf(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWaveTimerStandsStillWhilePhantomsAreRolledBack():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        mGame:Rollback().
        ForEachKit:Frames(mGame, 100).
        Assert:Equals(420, mGame:WaveFramesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FromLevelNineteenACommitOnlyTurnsThePhantomsRound():
        LanePhantom(PhantomKind:Mary, 100, PhantomMode:Scatter).
        mGame:StartLevel(19).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        mGame:PlacePhantom(PhantomKind:Mary, 100, 12, MazeDir:Right, PhantomMode:Scatter).
        mGame:Rollback().
        ForEachKit:Frames(mGame, 12).
        Assert:Equals(PhantomMode:Scatter, mGame:ModeOf(PhantomKind:Mary)).
        Assert:Equals(MazeDir:Left, mGame:PhantomDir(PhantomKind:Mary)).
        Assert:Equals(0, mGame:RollbackFramesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReturningPhantomsAreLeftAloneByACommit():
        PlayOn(ForEachKit:TwoLanes()).
        mGame:PlacePhantom(PhantomKind:Mary, 100, 12, MazeDir:Right, PhantomMode:Returning).
        mGame:Rollback().
        Assert:Equals(PhantomMode:Returning, mGame:ModeOf(PhantomKind:Mary)).
    END METHOD.

    /* ---------------------------------- being eaten ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID DibbyEatsARolledBackPhantomByTouchingItForTwoHundredPoints():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        mGame:Advance().
        Assert:Equals(200, mGame:Score).
        Assert:Equals(1, mGame:PhantomsEatenTotal).
        Assert:Equals(200, mGame:LastPhantomPoints).
        Assert:Equals(PhantomMode:Returning, mGame:ModeOf(PhantomKind:Mary)).
        Assert:Equals(ForEachPhase:Playing, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePointsDoubleForEveryPhantomEatenOnTheSameCommit():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:PlacePhantom(PhantomKind:Rich, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:PlacePhantom(PhantomKind:Brian, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:PlacePhantom(PhantomKind:Chip, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        /* every phantom that touches him in the same frame is eaten in that frame, one after the other */
        mGame:Advance().
        Assert:Equals(3000, mGame:Score).
        Assert:Equals(4, mGame:PhantomsEatenTotal).
        Assert:Equals(1600, mGame:LastPhantomPoints).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewCommitStartsTheTwoHundredBeforeAgain():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        mGame:Advance().
        /* the game stands still for a moment after a phantom is eaten */
        Assert:IsTrue(mGame:FreezeFramesLeft >= 55).
        DO WHILE mGame:FreezeFramesLeft > 0:
            mGame:Advance().
        END.
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        mGame:Advance().
        Assert:Equals(400, mGame:Score).
        Assert:Equals(200, mGame:LastPhantomPoints).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReturningPhantomsDoNotHurtTheDatabaseAndCannotBeEatenAgain():
        PlayOn(ForEachKit:ClosedCorridor()).
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Returning).
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(ForEachPhase:Playing, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:PhantomsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReturningPhantomsRunBackToTheLobbyAndComeOutAsAPhantomAgain():
        PlayFull().
        mGame:PlacePhantom(PhantomKind:Mary, 112, 92, MazeDir:Down, PhantomMode:Returning).
        ForEachKit:Frames(mGame, 240).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Mary) <> PhantomMode:Returning).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Mary) <> PhantomMode:RolledBack).
    END METHOD.

    /* ---------------------------------- Mary speeds up ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID MaryIsAtStageZeroUntil20ThingsAreLeftThenStageOneThenTwo():
        PlayFull().
        Assert:Equals(0, mGame:RageStage).
        mGame:EatBits(223).
        Assert:Equals(0, mGame:RageStage).
        mGame:EatBits(1).
        Assert:Equals(1, mGame:RageStage).
        mGame:EatBits(10).
        Assert:Equals(2, mGame:RageStage).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RageStartsEarlierOnLaterLevels():
        PlayFull().
        mGame:StartLevel(2).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        mGame:EatBits(213).
        Assert:Equals(0, mGame:RageStage).
        mGame:EatBits(1).
        Assert:Equals(1, mGame:RageStage).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWoundUpMaryRunsFasterThanTheOthers():
        DEFINE VARIABLE maryX AS INTEGER NO-UNDO.
        DEFINE VARIABLE richX  AS INTEGER NO-UNDO.
        PlayOn(ForEachKit:TwoLanes()).
        mGame:PlacePhantom(PhantomKind:Mary, 20, 12, MazeDir:Right, PhantomMode:Scatter).
        mGame:PlacePhantom(PhantomKind:Rich, 20, 12, MazeDir:Right, PhantomMode:Scatter).
        mGame:SetRage(2).
        Assert:Equals(2, mGame:RageStage).
        maryX = mGame:PhantomX(PhantomKind:Mary).
        richX = mGame:PhantomX(PhantomKind:Rich).
        ForEachKit:Frames(mGame, 60).
        Assert:IsTrue(mGame:PhantomX(PhantomKind:Mary) - maryX > mGame:PhantomX(PhantomKind:Rich) - richX).
    END METHOD.

END CLASS.
