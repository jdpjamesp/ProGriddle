/* The cue source of Centipede, with real games driven by hand: each event is reported once, a head sounds different from a body segment,
   the title is silent and the loops follow the creatures. Cue numbers are INTEGER(CentipedeCue:...). The random source always says 1. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeCuesTests:

    DEFINE PRIVATE VARIABLE mGame AS CentipedeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCues AS CentipedeCues NO-UNDO.

    /* A game in play on an empty field with a segment kept out of the way, the shooter at 96, 224, and the cue source up to date. */
    @Setup.
    METHOD PUBLIC VOID BuildCues():
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        mGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        mCues = NEW CentipedeCues().
        /* the first look takes the title as it is, and the next the new game */
        mCues:Poll(mGame).
        mGame:StartGame().
        mGame:ClearField().
        mGame:ClearCentipede().
        mGame:ClearCreatures().
        mGame:PlacePlayer(96, 224).
        DO y = 0 TO 23:
            mGame:PlaceMushroom(26, y, 4).
        END.
        mGame:AddSegment(28, 0, -1, TRUE).
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS CentipedeCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    /* Advances piFrames frames, polling after each, and gives every cue that was reported as a comma list. */
    METHOD PRIVATE CHARACTER Collect(INPUT piFrames AS INTEGER):
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        DEFINE VARIABLE got  AS CHARACTER NO-UNDO.
        DO i = 1 TO piFrames:
            mGame:Advance().
            got = mCues:Poll(mGame).
            IF got <> "" THEN cues = cues + (IF cues = "" THEN "" ELSE ",") + got.
        END.
        RETURN cues.
    END METHOD.

    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS CentipedeCue):
        RETURN INDEX("," + pcCues + ",", "," + N(poCue) + ",") > 0.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenAndTheStartOfAGameAreSilent():
        DEFINE VARIABLE oGame AS CentipedeGame NO-UNDO.
        DEFINE VARIABLE oCues AS CentipedeCues NO-UNDO.
        oGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        oCues = NEW CentipedeCues().
        oGame:FireHeld = TRUE.
        oGame:Advance().
        Assert:Equals("", oCues:Poll(oGame)).
        oGame:StartGame().
        Assert:Equals("", oCues:Poll(oGame)).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFrameWithNothingHappeningIsSilent():
        Assert:Equals("", Collect(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringGivesOneFireCueAndItIsReportedOnce():
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:Equals(N(CentipedeCue:Fire), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABrokenMushroomGivesTheBreakCueAndTheFireCue():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        mGame:PlaceMushroom(12, 20, 1).
        mGame:FireHeld = TRUE.
        cues = Collect(12).
        Assert:IsTrue(Has(cues, CentipedeCue:MushroomBreak)).
        Assert:IsTrue(Has(cues, CentipedeCue:Fire)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABodySegmentAndAHeadSoundDifferent():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        mGame:AddSegment(12, 26, -1, FALSE).
        mGame:FireHeld = TRUE.
        cues = Collect(2).
        Assert:IsTrue(Has(cues, CentipedeCue:SegmentKill)).
        Assert:IsFalse(Has(cues, CentipedeCue:HeadKill)).
        mGame:FireHeld = FALSE.
        Collect(40).
        mGame:AddSegment(12, 26, -1, TRUE).
        mGame:FireHeld = TRUE.
        cues = Collect(2).
        Assert:IsTrue(Has(cues, CentipedeCue:HeadKill)).
        Assert:IsFalse(Has(cues, CentipedeCue:SegmentKill)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaGivesAHitCueAndThenAKillCue():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        mGame:SpawnFlea(12).
        mGame:FireHeld = TRUE.
        cues = Collect(80).
        Assert:IsTrue(Has(cues, CentipedeCue:FleaHit)).
        Assert:IsTrue(Has(cues, CentipedeCue:FleaKill)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorpionAndTheSpiderGiveTheirKillCues():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        mGame:PlacePlayer(120, 224).
        mGame:SpawnScorpion(10, TRUE).
        Collect(112).
        mGame:FireHeld = TRUE.
        cues = Collect(30).
        Assert:IsTrue(Has(cues, CentipedeCue:ScorpionKill)).
        mGame:ClearCreatures().
        mGame:FireHeld = FALSE.
        Collect(40).
        mGame:SpawnSpider(TRUE, 26).
        Collect(62).
        mGame:FireHeld = TRUE.
        cues = Collect(5).
        Assert:IsTrue(Has(cues, CentipedeCue:SpiderKill)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShootersDeathGivesTheDeathCue():
        mGame:AddSegment(12, 28, -1, TRUE).
        Assert:IsTrue(Has(Collect(2), CentipedeCue:PlayerDies)).
        Assert:Equals("", Collect(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraShooterGivesTheExtraLifeCue():
        mGame:AddScore(12000).
        Assert:IsTrue(Has(Collect(1), CentipedeCue:ExtraLife)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClearedWaveGivesTheWaveCue():
        mGame:ClearCentipede().
        Assert:IsTrue(Has(Collect(1), CentipedeCue:WaveClear)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDeathCueComesBeforeTheOthers():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        mGame:AddSegment(12, 28, -1, TRUE).
        mGame:AddScore(12000).
        mGame:Advance().
        cues = mCues:Poll(mGame).
        Assert:Equals(N(CentipedeCue:PlayerDies), ENTRY(1, cues)).
        Assert:Equals(N(CentipedeCue:ExtraLife), ENTRY(2, cues)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpiderAndTheScorpionHumWhileTheyAreOut():
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:SpawnSpider(TRUE, 26).
        Assert:Equals(N(CentipedeCue:SpiderLoop), mCues:Loops(mGame)).
        mGame:SpawnScorpion(5, TRUE).
        Assert:Equals(N(CentipedeCue:SpiderLoop) + "," + N(CentipedeCue:ScorpionLoop), mCues:Loops(mGame)).
        mGame:ClearCreatures().
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameHasNoLoops():
        mGame:SpawnSpider(TRUE, 26).
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDeathOfTheShooterAndTheTitleHaveNoLoops():
        DEFINE VARIABLE oGame AS CentipedeGame NO-UNDO.
        mGame:SpawnSpider(TRUE, 26).
        mGame:AddSegment(12, 28, -1, TRUE).
        mGame:Advance().
        Assert:Equals("", mCues:Loops(mGame)).
        oGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        Assert:Equals("", mCues:Loops(oGame)).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroupsKeepCuesThatShouldSoundTogetherApart():
        Assert:Equals(mCues:GroupOf(INTEGER(CentipedeCue:SpiderKill)), mCues:GroupOf(INTEGER(CentipedeCue:FleaKill))).
        Assert:Equals(mCues:GroupOf(INTEGER(CentipedeCue:SegmentKill)), mCues:GroupOf(INTEGER(CentipedeCue:MushroomBreak))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(CentipedeCue:Fire)) <> mCues:GroupOf(INTEGER(CentipedeCue:SegmentKill))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(CentipedeCue:PlayerDies)) <> mCues:GroupOf(INTEGER(CentipedeCue:ExtraLife))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(CentipedeCue:WaveClear)) <> mCues:GroupOf(INTEGER(CentipedeCue:ExtraLife))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotCentipedeIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mCues:Poll(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mCues:Loops(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
