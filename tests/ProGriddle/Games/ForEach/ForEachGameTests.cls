/* The shape of a FOR EACH game, tested without a window: how it is built, how a game starts, runs on the clock and stops, and how
   score, lives and the best score behave. The rules of moving, eating, the phantoms and dying are in the other FOR EACH game test
   classes. The game runs at 60 frames a second whatever the clock does, so a test plays frame by frame with
   Advance. Its grid is the maze at 8 pixels a tile with 24 rows of pixels above it and 16 below (224 x 288 for the real maze). A
   position is the middle of a character in pixels, and the tile a character is in is its pixel divided by 8, rounded down. The
   game's phases are the title, READY! (Ready), play (Playing), caught (Caught, everything stopped for a moment), the dying
   animation (Dying), the maze flashing after the last bit (Cleared), a cartoon (Intermission) and GameOver. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachGameTests:

    DEFINE PRIVATE VARIABLE mGame AS ForEachGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS ForEachGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW ForEachGame(?, NEW MazeMap(ForEachMaze:Layout()), NEW SeededRandom(1)).
                WHEN 2 THEN other = NEW ForEachGame(ForEachFactory:CreateGrid(NEW MazeMap(ForEachMaze:Layout())), ?, NEW SeededRandom(1)).
                WHEN 3 THEN other = NEW ForEachGame(ForEachFactory:CreateGrid(NEW MazeMap(ForEachMaze:Layout())), NEW MazeMap(ForEachMaze:Layout()), ?).
                WHEN 4 THEN other = NEW ForEachGame(NEW Grid(NEW ArrayStore(40, 30, ForEachFactory:Layers())), NEW MazeMap(ForEachMaze:Layout()), NEW SeededRandom(1)).
                WHEN 5 THEN mGame:AddScore(-1).
                WHEN 6 THEN mGame:StartLevel(0).
                WHEN 7 THEN mGame:Steer(?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- building it ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheGameStartsOnTheTitleScreenWithNothingScored():
        Assert:Equals(ForEachPhase:Title, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Level).
        Assert:Equals("FOR EACH", mGame:Name).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameNeedsAGridTheSizeOfItsMazeAMazeAndARandomSource():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRealGameHasTheForEachMazeAndAllFourPhantoms():
        Assert:Equals(28, mGame:Maze:Cols).
        Assert:Equals(31, mGame:Maze:Rows).
        Assert:Equals(244, mGame:BitsLeft).
        Assert:IsTrue(mGame:PhantomPresent(PhantomKind:Mary)).
        Assert:IsTrue(mGame:PhantomPresent(PhantomKind:Rich)).
        Assert:IsTrue(mGame:PhantomPresent(PhantomKind:Brian)).
        Assert:IsTrue(mGame:PhantomPresent(PhantomKind:Chip)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMazeWithoutPhantomStartsHasNoPhantoms():
        DEFINE VARIABLE lane AS ForEachGame NO-UNDO.
        lane = ForEachKit:GameOn(ForEachKit:ClosedCorridor()).
        Assert:IsFalse(lane:PhantomPresent(PhantomKind:Mary)).
        Assert:IsFalse(lane:PhantomPresent(PhantomKind:Chip)).
        lane:Dispose().
    END METHOD.

    /* ---------------------------------- starting ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID StartGameShowsReadyWithThreeLivesAndNothingScored():
        mGame:AddScore(500).
        mGame:StartGame().
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Level).
        Assert:Equals(244, mGame:BitsLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingMovesWhileReadyIsOnTheScreen():
        mGame:StartGame().
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:Equals(112, mGame:DibbyX).
        Assert:Equals(188, mGame:DibbyY).
        Assert:Equals(92, mGame:PhantomY(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheReadyAtTheStartOfAGameLastsFourSeconds():
        mGame:StartGame().
        ForEachKit:Frames(mGame, 230).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 40)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReadyGivesWayToPlayWithDibbyFacingLeftAtHisStart():
        ForEachKit:Play(mGame).
        Assert:Equals(ForEachPhase:Playing, mGame:Phase).
        Assert:Equals(112, mGame:DibbyX).
        Assert:Equals(188, mGame:DibbyY).
        Assert:Equals(14, mGame:DibbyCol).
        Assert:Equals(23, mGame:DibbyRow).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePhantomsStartAtTheirPlacesMaryOutsideAndTheRestInTheLobby():
        ForEachKit:Play(mGame).
        Assert:Equals(112, mGame:PhantomX(PhantomKind:Mary)).
        Assert:Equals(92, mGame:PhantomY(PhantomKind:Mary)).
        Assert:Equals(PhantomMode:Scatter, mGame:ModeOf(PhantomKind:Mary)).
        Assert:Equals(MazeDir:Left, mGame:PhantomDir(PhantomKind:Mary)).
        Assert:Equals(96, mGame:PhantomX(PhantomKind:Brian)).
        Assert:Equals(116, mGame:PhantomY(PhantomKind:Brian)).
        Assert:Equals(128, mGame:PhantomX(PhantomKind:Chip)).
        Assert:Equals(116, mGame:PhantomY(PhantomKind:Chip)).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Brian)).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Chip)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartGameWorksFromAnyPhaseAndAnEndedGameStartsAgain():
        ForEachKit:Play(mGame).
        mGame:AddScore(300).
        mGame:StartGame().
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartLevelBeginsAnyLevelKeepingTheScoreAndTheLives():
        ForEachKit:Play(mGame).
        mGame:AddScore(300).
        mGame:StartLevel(5).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:Equals(5, mGame:Level).
        Assert:Equals(300, mGame:Score).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(244, mGame:BitsLeft).
        Assert:IsTrue(ThrowsGridException(6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFrameCountGrowsByOneForEveryFrame():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        ForEachKit:Play(mGame).
        before = mGame:FrameCount.
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(5, mGame:FrameCount - before).
    END METHOD.

    /* ---------------------------------- the clock ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TickMakesAFrameForEverySixtiethOfASecondAtFullSpeed():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        ForEachKit:Play(mGame).
        before = mGame:FrameCount.
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(16)).
        Assert:Equals(0, mGame:FrameCount - before).
        Assert:IsTrue(mGame:Tick(1)).
        Assert:Equals(1, mGame:FrameCount - before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickNeverMakesMoreThanFourFramesAtOnceSoAStallIsNotABurst():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        ForEachKit:Play(mGame).
        before = mGame:FrameCount.
        Assert:IsTrue(mGame:Tick(1000)).
        Assert:Equals(4, mGame:FrameCount - before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameStartsAtFullSpeedAndASlowerSpeedMakesFewerFrames():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Assert:Equals(100, mGame:SpeedPercent).
        ForEachKit:Play(mGame).
        mGame:SpeedPercent = 50.
        before = mGame:FrameCount.
        mGame:Tick(34).
        Assert:Equals(1, mGame:FrameCount - before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingHappensWhilePausedAndPlayCarriesOnWhenItIsNot():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        ForEachKit:Play(mGame).
        mGame:Paused = TRUE.
        before = mGame:FrameCount.
        x = mGame:DibbyX.
        Assert:IsFalse(mGame:Tick(100)).
        Assert:Equals(0, mGame:FrameCount - before).
        Assert:Equals(x, mGame:DibbyX).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:Tick(17)).
    END METHOD.

    /* ---------------------------------- score ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AddScoreAddsPointsAndTheBestScoreFollowsAScoreThatBeatsIt():
        mGame:HiScore = 100.
        mGame:AddScore(40).
        Assert:Equals(40, mGame:Score).
        Assert:Equals(100, mGame:HiScore).
        mGame:AddScore(80).
        Assert:Equals(120, mGame:Score).
        Assert:Equals(120, mGame:HiScore).
        Assert:IsTrue(ThrowsGridException(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameKeepsTheBestScore():
        mGame:AddScore(900).
        mGame:StartGame().
        Assert:Equals(0, mGame:Score).
        Assert:Equals(900, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraLifeComesAt10000AndOnlyThatOnce():
        mGame:StartGame().
        mGame:AddScore(9990).
        Assert:Equals(3, mGame:Lives).
        mGame:AddScore(10).
        Assert:Equals(4, mGame:Lives).
        mGame:AddScore(20000).
        Assert:Equals(4, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASteerNeedsADirection():
        Assert:IsTrue(ThrowsGridException(7)).
    END METHOD.

END CLASS.
