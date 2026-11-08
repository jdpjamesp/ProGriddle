/* The cue source of FOR EACH, with real games driven by hand: each event is reported once, the title screen is silent, and the
   alarm, the rolled back drone and returning phantoms are loops. Cue numbers are INTEGER(ForEachCue:...). Eating alternates two crunches (a bit or
   a commit, or several in one look, make one crunch). The alarm speeds up as the things to eat run out: Alarm1 above 150 left,
   Alarm2 at 150 or fewer, Alarm3 at 100, Alarm4 at 50 and Alarm5 at 20. A rolled back phantom silences the alarm and returning running
   home silence both. The cues come most important first: death, extra life, phantom eaten, item eaten, crunch. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachCuesTests:

    VAR PRIVATE ForEachGame mGame.
    VAR PRIVATE ForEachCues mCues.

    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = ForEachFactory:Create(NEW SeededRandom(7)).
        mCues = NEW ForEachCues().
        /* the first look takes the title screen as it is */
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS ForEachCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS ForEachCue):
        RETURN LOOKUP(N(poCue), pcCues) > 0.
    END METHOD.

    /* A game in play with the cues up to date. */
    METHOD PRIVATE VOID PlayNow():
        ForEachKit:Play(mGame).
        mCues:Poll(mGame).
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        VAR CHARACTER c.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN c = mCues:Poll(?).
                WHEN 2 THEN c = mCues:Loops(?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCuesNeedAForEachGame():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingSoundsOnTheTitleScreen():
        Assert:Equals("", mCues:Poll(mGame)).
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameSoundsTheStartJingleOnce():
        mGame:StartGame().
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:Start)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingSoundsTheTwoCrunchesInTurn():
        PlayNow().
        mGame:EatBits(1).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:Crunch1)).
        mGame:EatBits(1).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:Crunch2)).
        mGame:EatBits(1).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:Crunch1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SeveralBitsInOneLookMakeOneCrunchAndNothingEatenMakesNone():
        PlayNow().
        mGame:EatBits(3).
        Assert:Equals(1, NUM-ENTRIES(mCues:Poll(mGame))).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACommitSoundsACrunchToo():
        VAR CHARACTER cues.
        mGame:Dispose().
        mGame = ForEachKit:GameOn(ForEachKit:DataCorridor()).
        mCues:Poll(mGame).
        ForEachKit:Play(mGame).
        mCues:Poll(mGame).
        mGame:PlaceDibby(140, 12, MazeDir:Right).
        ForEachKit:Frames(mGame, 8).
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, ForEachCue:Crunch1) OR Has(cues, ForEachCue:Crunch2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingAPhantomSoundsItsOwnCue():
        mGame:Dispose().
        mGame = ForEachKit:GameOn(ForEachKit:ClosedCorridor()).
        mCues:Poll(mGame).
        PlayNow().
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        mGame:Advance().
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:PhantomEaten)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnItemComingOutSoundsACueSoThePlayerKnowsItIsThere():
        PlayNow().
        mGame:EatBits(69).
        mCues:Poll(mGame).
        mGame:EatBits(1).
        Assert:IsTrue(mGame:ItemActive).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:ItemAppears)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingTheItemSoundsItsOwnCue():
        mGame:Dispose().
        mGame = ForEachKit:GameOn(ForEachKit:ItemCorridor()).
        mCues:Poll(mGame).
        PlayNow().
        mGame:ShowItem().
        mGame:PlaceDibby(34, 12, MazeDir:Left).
        ForEachKit:Frames(mGame, 6).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:ItemEaten)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDyingAnimationSoundsTheDeathCue():
        PlayNow().
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        ForEachKit:RunUntil(mGame, ForEachPhase:Dying, 300).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:Death)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraLifeSoundsItsOwnCue():
        PlayNow().
        mGame:AddScore(10000).
        Assert:IsTrue(Has(mCues:Poll(mGame), ForEachCue:ExtraLife)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameWhoseCountsStartAgainMakesNoNoiseForTheOldOnes():
        PlayNow().
        mGame:EatBits(20).
        mCues:Poll(mGame).
        mGame:StartGame().
        mCues:Poll(mGame).
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMostImportantCueComesFirstAndTheCrunchesShareAGroup():
        Assert:Equals(mCues:GroupOf(INTEGER(ForEachCue:Crunch1)), mCues:GroupOf(INTEGER(ForEachCue:Crunch2))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(ForEachCue:Death)) <> mCues:GroupOf(INTEGER(ForEachCue:Crunch1))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(ForEachCue:PhantomEaten)) <> mCues:GroupOf(INTEGER(ForEachCue:ItemEaten))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(ForEachCue:ExtraLife)) <> mCues:GroupOf(INTEGER(ForEachCue:Death))).
    END METHOD.

    /* ---------------------------------- loops ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheAlarmWailsDuringPlayAndGetsFasterAsTheBitsRunOut():
        PlayNow().
        Assert:Equals(N(ForEachCue:Alarm1), mCues:Loops(mGame)).
        mGame:EatBits(93).
        Assert:Equals(N(ForEachCue:Alarm1), mCues:Loops(mGame)).
        mGame:EatBits(1).
        Assert:Equals(N(ForEachCue:Alarm2), mCues:Loops(mGame)).
        mGame:EatBits(50).
        Assert:Equals(N(ForEachCue:Alarm3), mCues:Loops(mGame)).
        mGame:EatBits(50).
        Assert:Equals(N(ForEachCue:Alarm4), mCues:Loops(mGame)).
        mGame:EatBits(30).
        Assert:Equals(N(ForEachCue:Alarm5), mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RolledBackPhantomsReplaceTheAlarmWithTheirDrone():
        PlayNow().
        mGame:Rollback().
        Assert:Equals(N(ForEachCue:RollbackLoop), mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhantomsReturningHomeReplaceEverythingElse():
        PlayNow().
        mGame:Rollback().
        mGame:PlacePhantom(PhantomKind:Chip, 128, 116, MazeDir:Up, PhantomMode:Returning).
        Assert:Equals(N(ForEachCue:ReturningLoop), mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreNoLoopsOnTheTitleWhilePausedOrWhenTheGameIsOver():
        Assert:Equals("", mCues:Loops(mGame)).
        PlayNow().
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:Paused = FALSE.
        mGame:Lives = 1.
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        ForEachKit:RunUntil(mGame, ForEachPhase:GameOver, 900).
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

END CLASS.
