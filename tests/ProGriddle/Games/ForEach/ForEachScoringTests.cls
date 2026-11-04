/* What Dibby earns and what it leads to: points for bits and commits, the item that comes twice a level, clearing the maze, the
   cartoons between some levels and the next level. BitsEaten counts the bits and commits eaten on this level (both count), BitsEatenTotal and CommitsEatenTotal count each kind over the whole game and never go back. EatBits eats that many
   bits at once as if Dibby had walked over them, so a test need not walk the maze. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachScoringTests:

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

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN mGame:EatBits(-1).
                WHEN 2 THEN mGame:EatBits(241).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- bits and commits ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ABitIsWorthTenPoints():
        PlayOn(ForEachKit:DataCorridor()).
        ForEachKit:Frames(mGame, 5).
        Assert:Equals(1, mGame:BitsEatenTotal).
        Assert:Equals(10, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACommitIsWorthFiftyPoints():
        PlayOn(ForEachKit:DataCorridor()).
        mGame:PlaceDibby(140, 12, MazeDir:Right).
        ForEachKit:Frames(mGame, 8).
        Assert:Equals(1, mGame:CommitsEatenTotal).
        Assert:IsTrue(mGame:Score >= 50).
        Assert:IsTrue(mGame:Score <= 100).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatBitsEatsThatManyBitsScoresThemAndCountsThem():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        mGame:StartGame().
        mGame:EatBits(25).
        Assert:Equals(250, mGame:Score).
        Assert:Equals(25, mGame:BitsEaten).
        Assert:Equals(25, mGame:BitsEatenTotal).
        Assert:Equals(219, mGame:BitsLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatBitsNeverEatsCommitsAndRefusesMoreThanThereAre():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        mGame:StartGame().
        mGame:EatBits(240).
        Assert:Equals(4, mGame:BitsLeft).
        Assert:Equals(0, mGame:CommitsEatenTotal).
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCountsOfThingsEatenStartAgainWithANewGame():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        mGame:StartGame().
        mGame:EatBits(10).
        mGame:StartGame().
        Assert:Equals(0, mGame:BitsEaten).
        Assert:Equals(0, mGame:BitsEatenTotal).
    END METHOD.

    /* ---------------------------------- item ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheFirstItemAppearsWhenThe70thThingIsEatenNotBefore():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        ForEachKit:Play(mGame).
        mGame:EatBits(69).
        Assert:IsFalse(mGame:ItemActive).
        mGame:EatBits(1).
        Assert:IsTrue(mGame:ItemActive).
        Assert:Equals(ItemKind:Floppy, mGame:ItemOnShow).
        Assert:Equals(112, mGame:ItemX).
        Assert:Equals(140, mGame:ItemY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSecondItemAppearsWhenThe170thThingIsEaten():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        ForEachKit:Play(mGame).
        mGame:EatBits(70).
        mGame:PlaceDibby(mGame:ItemX, mGame:ItemY, MazeDir:Left).
        mGame:Advance().
        Assert:IsFalse(mGame:ItemActive).
        mGame:EatBits(99).
        Assert:IsFalse(mGame:ItemActive).
        mGame:EatBits(1).
        Assert:IsTrue(mGame:ItemActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoMoreItemComesAfterTheSecondOne():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        ForEachKit:Play(mGame).
        mGame:EatBits(70).
        mGame:PlaceDibby(mGame:ItemX, mGame:ItemY, MazeDir:Left).
        mGame:Advance().
        mGame:EatBits(100).
        mGame:PlaceDibby(mGame:ItemX, mGame:ItemY, MazeDir:Left).
        mGame:Advance().
        Assert:IsFalse(mGame:ItemActive).
        mGame:EatBits(70).
        Assert:IsFalse(mGame:ItemActive).
        Assert:Equals(2, mGame:ItemsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowItemPutsTheItemOutAsIfTheThresholdHadBeenReached():
        PlayOn(ForEachKit:ItemCorridor()).
        Assert:IsFalse(mGame:ItemActive).
        mGame:ShowItem().
        Assert:IsTrue(mGame:ItemActive).
        Assert:Equals(24, mGame:ItemX).
        Assert:Equals(12, mGame:ItemY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AItemStaysAboutTenSecondsThenGoesAway():
        PlayOn(ForEachKit:ItemCorridor()).
        mGame:ShowItem().
        Assert:IsTrue(mGame:ItemFramesLeft >= 540).
        Assert:IsTrue(mGame:ItemFramesLeft <= 600).
        mGame:PlaceDibby(150, 12, MazeDir:Right).
        ForEachKit:Frames(mGame, 100).
        Assert:IsTrue(mGame:ItemActive).
        Assert:IsTrue(mGame:ItemFramesLeft <= 500).
        ForEachKit:Frames(mGame, 520).
        Assert:IsFalse(mGame:ItemActive).
        Assert:Equals(0, mGame:ItemsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyEatsTheItemByWalkingOntoItForItsPoints():
        PlayOn(ForEachKit:ItemCorridor()).
        mGame:ShowItem().
        mGame:PlaceDibby(34, 12, MazeDir:Left).
        ForEachKit:Frames(mGame, 6).
        Assert:IsFalse(mGame:ItemActive).
        Assert:Equals(100, mGame:Score).
        Assert:Equals(1, mGame:ItemsEatenTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemAndItsPointsGoWithTheLevel():
        PlayOn(ForEachKit:ItemCorridor()).
        mGame:StartLevel(3).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        mGame:ShowItem().
        Assert:Equals(ItemKind:Key, mGame:ItemOnShow).
        mGame:PlaceDibby(34, 12, MazeDir:Left).
        ForEachKit:Frames(mGame, 6).
        Assert:Equals(500, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemIsGoneWhenALevelStartsAgain():
        PlayOn(ForEachKit:ItemCorridor()).
        mGame:ShowItem().
        mGame:StartLevel(2).
        Assert:IsFalse(mGame:ItemActive).
    END METHOD.

    /* ---------------------------------- clearing the maze ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID EatingTheLastBitClearsTheLevelAndTheMazeFlashes():
        PlayOn(ForEachKit:FewBits()).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200)).
        Assert:Equals(0, mGame:BitsLeft).
        Assert:Equals(30, mGame:Score).
        Assert:Equals(ForEachPhase:Cleared, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClearedMazeStaysUpForAboutThreeSecondsOfStillnessAndFlashes():
        PlayOn(ForEachKit:FewBits()).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200)).
        ForEachKit:Frames(mGame, 160).
        Assert:Equals(ForEachPhase:Cleared, mGame:Phase).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheFlashTheNextLevelStartsWithAFullMazeAndDibbyAtHisStart():
        PlayOn(ForEachKit:FewBits()).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200)).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900)).
        Assert:Equals(2, mGame:Level).
        Assert:Equals(3, mGame:BitsLeft).
        Assert:Equals(0, mGame:BitsEaten).
        Assert:Equals(30, mGame:Score).
        Assert:Equals(32, mGame:DibbyX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACartoonPlaysAfterLevelTwoAndIsFollowedByLevelThree():
        PlayOn(ForEachKit:FewBits()).
        mGame:StartLevel(2).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200)).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Intermission, 900)).
        Assert:Equals(1, mGame:IntermissionAct).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 3000)).
        Assert:Equals(3, mGame:Level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoCartoonPlaysAfterLevelOne():
        PlayOn(ForEachKit:FewBits()).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200)).
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        Assert:Equals(0, mGame:IntermissionAct).
    END METHOD.

END CLASS.
