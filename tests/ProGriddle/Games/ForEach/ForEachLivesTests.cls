/* Being caught: a phantom in the same tile as Dibby ends the turn, everything stops for a moment (Caught), the phantoms vanish and
   Dibby spins away (Dying), and then the game either starts the turn again with READY! or, with no lives left, ends. The
   bits Dibby ate stay eaten and the score stays, but the phantoms start again at the lobby and for a while leave it on a count
   shared between them (7, 17 and 32 things eaten for Rich, Brian and Chip) and not on their own counts. DeathCount goes up as
   the dying animation starts and never goes back. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachLivesTests:

    VAR PRIVATE ForEachGame mGame.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        ForEachKit:Play(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* Mary, hunting, lands on Dibby's tile. */
    METHOD PRIVATE VOID GetCaught():
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        mGame:Advance().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomOnDibbysTileCatchesHimAndTheGameStops():
        GetCaught().
        Assert:Equals(ForEachPhase:Caught, mGame:Phase).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomOnAnotherTileDoesNot():
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX + 40, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        mGame:Advance().
        Assert:Equals(ForEachPhase:Playing, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverythingStandsStillWhileDibbyIsCaught():
        VAR INTEGER x.
        VAR INTEGER g.
        GetCaught().
        x = mGame:DibbyX.
        g = mGame:PhantomX(PhantomKind:Rich).
        ForEachKit:Frames(mGame, 10).
        Assert:Equals(ForEachPhase:Caught, mGame:Phase).
        Assert:Equals(x, mGame:DibbyX).
        Assert:Equals(g, mGame:PhantomX(PhantomKind:Rich)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePauseAfterTheCatchLastsAboutOneSecond():
        GetCaught().
        ForEachKit:Frames(mGame, 55).
        Assert:Equals(ForEachPhase:Caught, mGame:Phase).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Dying, 15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheReadyAfterADeathLastsAboutOneSecond():
        GetCaught().
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        ForEachKit:Frames(mGame, 50).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCatchGoesOnToTheDyingAnimationAndCountsTheDeath():
        GetCaught().
        Assert:Equals(0, mGame:DeathCount).
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Dying, 300)).
        Assert:Equals(1, mGame:DeathCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithLivesLeftTheTurnStartsAgainWithReadyAndOneLifeLess():
        GetCaught().
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900)).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(1, mGame:DeathCount).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTurnStartsAgainWithEveryoneAtTheirStartAndTheWavesBeginningAgain():
        ForEachKit:Frames(mGame, 30).
        GetCaught().
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        Assert:Equals(112, mGame:DibbyX).
        Assert:Equals(188, mGame:DibbyY).
        Assert:Equals(MazeDir:Left, mGame:DibbyDir).
        Assert:Equals(112, mGame:PhantomX(PhantomKind:Mary)).
        Assert:Equals(92, mGame:PhantomY(PhantomKind:Mary)).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Brian)).
        Assert:Equals(1, mGame:WaveNumber).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBitsEatenAndTheScoreAreKeptAfterADeath():
        VAR INTEGER points.
        VAR INTEGER remaining.
        mGame:EatBits(40).
        GetCaught().
        points = mGame:Score.
        remaining = mGame:BitsLeft.
        Assert:IsTrue(points >= 400).
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        Assert:Equals(points, mGame:Score).
        Assert:Equals(remaining, mGame:BitsLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemOnShowIsGoneAfterADeath():
        mGame:EatBits(70).
        Assert:IsTrue(mGame:ItemActive).
        GetCaught().
        ForEachKit:RunUntil(mGame, ForEachPhase:Ready, 900).
        Assert:IsFalse(mGame:ItemActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterADeathThePhantomsLeaveOnASharedCountOfThingsEatenNotTheirOwn():
        GetCaught().
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        ForEachKit:Frames(mGame, 10).
        /* Rich's own count is 0, but now he waits for 7 on the shared count */
        mGame:EatBits(4).
        ForEachKit:Frames(mGame, 30).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Rich)).
        mGame:EatBits(5).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Rich) <> PhantomMode:Waiting).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Brian)).
        mGame:EatBits(10).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Brian) <> PhantomMode:Waiting).
        Assert:Equals(PhantomMode:Waiting, mGame:ModeOf(PhantomKind:Chip)).
        mGame:EatBits(15).
        ForEachKit:Frames(mGame, 30).
        Assert:IsTrue(mGame:ModeOf(PhantomKind:Chip) <> PhantomMode:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastLifeLostEndsTheGame():
        VAR INTEGER points.
        mGame:Lives = 1.
        mGame:AddScore(250).
        GetCaught().
        points = mGame:Score.
        Assert:IsTrue(ForEachKit:RunUntil(mGame, ForEachPhase:GameOver, 900)).
        Assert:Equals(0, mGame:Lives).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(points, mGame:Score).
        Assert:Equals(points, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEndedGameStartsAgainFromTheStart():
        VAR INTEGER points.
        mGame:Lives = 1.
        mGame:AddScore(250).
        GetCaught().
        points = mGame:Score.
        ForEachKit:RunUntil(mGame, ForEachPhase:GameOver, 900).
        mGame:StartGame().
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(points, mGame:HiScore).
        Assert:Equals(0, mGame:DeathCount).
    END METHOD.

END CLASS.
