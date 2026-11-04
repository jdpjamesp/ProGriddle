/* What the game tells the picture: the age of the phase, the number of times the maze has been filled, the last tiles eaten, the pop-up of the
   points just earned, the length of READY! and whether the score has beaten the best. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachPictureHooksTests:

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
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN n = mGame:EatenColAt(1).
                WHEN 2 THEN n = mGame:EatenRowAt(0).
                WHEN 3 THEN DO:
                    mGame:EatBits(1).
                    n = mGame:EatenColAt(2).
                END.
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhaseAgeCountsTheFramesInThePhaseAndStartsAgainWithEachNewPhase():
        Assert:Equals(0, mGame:PhaseAge).
        mGame:StartGame().
        Assert:Equals(0, mGame:PhaseAge).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(30, mGame:PhaseAge).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        Assert:Equals(0, mGame:PhaseAge).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(5, mGame:PhaseAge).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReadyLastsFourSecondsAtTheStartOfALevelAndOneAfterALife():
        mGame:StartGame().
        Assert:Equals(240, mGame:ReadyLength).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        Assert:Equals(60, mGame:ReadyLength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LevelSerialGoesUpEachTimeTheMazeIsFilled():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        before = mGame:LevelSerial.
        mGame:StartGame().
        Assert:Equals(before + 1, mGame:LevelSerial).
        mGame:StartLevel(2).
        Assert:Equals(before + 2, mGame:LevelSerial).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTilesEatenAreRememberedInOrderAndOnlyTheLast256():
        mGame:StartGame().
        mGame:EatBits(3).
        Assert:Equals(3, mGame:EatenSerial).
        Assert:Equals(1, mGame:EatenColAt(1)).
        Assert:Equals(1, mGame:EatenRowAt(1)).
        Assert:Equals(2, mGame:EatenColAt(2)).
        Assert:Equals(3, mGame:EatenColAt(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileThatWasNeverEatenIsRefused():
        Assert:IsTrue(ThrowsGridException(1)).
        mGame:StartGame().
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomEatenLeavesAPopUpOfItsPointsWhereItWas():
        DEFINE VARIABLE lane AS ForEachGame NO-UNDO.
        lane = ForEachKit:GameOn(ForEachKit:ClosedCorridor()).
        ForEachKit:Play(lane).
        lane:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        lane:Rollback().
        lane:PlaceDibby(80, 12, MazeDir:Left).
        lane:Advance().
        Assert:Equals(200, lane:PopupPoints).
        Assert:IsFalse(lane:PopupIsItem).
        Assert:IsTrue(lane:PopupFramesLeft > 50).
        Assert:IsTrue(ABSOLUTE(lane:PopupX - 80) < 4).
        Assert:Equals(12, lane:PopupY).
        lane:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnItemEatenLeavesAPopUpThatLastsTwoSeconds():
        DEFINE VARIABLE lane AS ForEachGame NO-UNDO.
        lane = ForEachKit:GameOn(ForEachKit:ItemCorridor()).
        ForEachKit:Play(lane).
        lane:ShowItem().
        lane:PlaceDibby(34, 12, MazeDir:Left).
        ForEachKit:Frames(lane, 6).
        Assert:Equals(100, lane:PopupPoints).
        Assert:IsTrue(lane:PopupIsItem).
        Assert:IsTrue(lane:PopupFramesLeft > 100).
        ForEachKit:Frames(lane, 120).
        Assert:Equals(0, lane:PopupFramesLeft).
        lane:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartIntermissionPlaysACartoonForFiveSecondsAndThenTheNextLevelStarts():
        mGame:StartLevel(4).
        mGame:StartIntermission(2).
        Assert:Equals(ForEachPhase:Intermission, mGame:Phase).
        Assert:Equals(2, mGame:IntermissionAct).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 400)).
        Assert:Equals(5, mGame:Level).
        Assert:Equals(0, mGame:IntermissionAct).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreOnlyThreeCartoons():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:StartIntermission(4).
            CATCH e AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:StartIntermission(0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItemsShownTotalCountsEveryItemThatComesOutAndStartsAgainWithAGame():
        mGame:StartGame().
        Assert:Equals(0, mGame:ItemsShownTotal).
        mGame:EatBits(70).
        Assert:Equals(1, mGame:ItemsShownTotal).
        mGame:EatBits(100).
        Assert:Equals(2, mGame:ItemsShownTotal).
        mGame:StartGame().
        Assert:Equals(0, mGame:ItemsShownTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewHiScoreIsAScoreThatBeatsTheBestTheGameStartedWith():
        mGame:HiScore = 500.
        mGame:StartGame().
        Assert:IsFalse(mGame:NewHiScore).
        mGame:AddScore(400).
        Assert:IsFalse(mGame:NewHiScore).
        mGame:AddScore(200).
        Assert:IsTrue(mGame:NewHiScore).
        mGame:StartGame().
        Assert:IsFalse(mGame:NewHiScore).
    END METHOD.

END CLASS.
