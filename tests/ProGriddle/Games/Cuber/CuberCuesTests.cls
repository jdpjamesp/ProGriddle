/* The cue source of Cuber, with real games driven by hand: each event is reported once, the title is silent, a new game has its
   fanfare and the groups say which sounds do not play together. Cue numbers are INTEGER(CuberCue:...). The random source always says 1. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberCuesTests:

    VAR PRIVATE CuberGame mGame.
    VAR PRIVATE CuberCues mCues.

    /* A game in play with no enemies and none coming, Pip on the apex, and the cue source up to date. */
    @Setup.
    METHOD PUBLIC VOID BuildCues():
        VAR INTEGER i.
        mGame = CuberFactory:Create(NEW ScriptedRandom("1")).
        mCues = NEW CuberCues().
        /* the first look takes the title as it is, and the next the new game */
        mCues:Poll(mGame).
        mGame:StartGame().
        mCues:Poll(mGame).
        DO i = 1 TO CuberRules:ReadyFrames():
            mGame:Advance().
        END.
        mGame:ClearEnemies().
        mGame:StopSpawns().
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS CuberCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    /* Advances piFrames frames, polling after each, and gives every cue that was reported as a comma list. */
    METHOD PRIVATE CHARACTER Collect(INPUT piFrames AS INTEGER):
        VAR INTEGER i.
        VAR CHARACTER cues.
        VAR CHARACTER got.
        DO i = 1 TO piFrames:
            mGame:Advance().
            got = mCues:Poll(mGame).
            IF got <> "" THEN cues = cues + (IF cues = "" THEN "" ELSE ",") + got.
        END.
        RETURN cues.
    END METHOD.

    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS CuberCue):
        RETURN LOOKUP(N(poCue), pcCues) > 0.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleAndAQuietGameSayNothing():
        VAR CuberGame titleGame.
        VAR CuberCues cues.
        titleGame = CuberFactory:Create(NEW ScriptedRandom("1")).
        cues = NEW CuberCues().
        Assert:Equals("", cues:Poll(titleGame)).
        titleGame:Advance().
        Assert:Equals("", cues:Poll(titleGame)).
        Assert:Equals("", Collect(30)).
        titleGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameHasItsOwnFanfareAndNothingElse():
        VAR CuberGame fresh.
        VAR CuberCues cues.
        fresh = CuberFactory:Create(NEW ScriptedRandom("1")).
        cues = NEW CuberCues().
        cues:Poll(fresh).
        fresh:StartGame().
        Assert:Equals(N(CuberCue:GameStart), cues:Poll(fresh)).
        Assert:Equals("", cues:Poll(fresh)).
        fresh:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopSoundsOnceAndALampItLightsSoundsWithIt():
        VAR CHARACTER cues.
        mGame:RequestHop(CuberDir:DownLeft).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:Hop)).
        Assert:IsTrue(Has(cues, CuberCue:LampDone)).
        Assert:Equals(2, NUM-ENTRIES(cues)).
        Assert:Equals("", Collect(30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingAndALampPutOutHaveTheirOwnSounds():
        VAR CHARACTER cues.
        mGame:BeginRound(3, 1).
        mCues:Poll(mGame).
        Collect(CuberRules:ReadyFrames()).
        mGame:ClearEnemies().
        mGame:StopSpawns().
        mGame:RequestHop(CuberDir:DownLeft).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:LampHalf)).
        Assert:IsFalse(Has(cues, CuberCue:LampDone)).
        mGame:SpawnEnemy(CuberKind:Snuff, 3, 0).
        mGame:SetLamp(2, 0, 1).
        mGame:SetEnemyRest(0, 1).
        cues = Collect(14).
        Assert:IsFalse(Has(cues, CuberCue:LampOut)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFallSoundsAndSoDoesALosingHit():
        VAR CHARACTER cues.
        mGame:RequestHop(CuberDir:UpRight).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:Fall)).
        Assert:IsTrue(Has(cues, CuberCue:Hop)).
        Collect(CuberRules:FallFrames() + CuberRules:ReadyFrames()).
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        cues = Collect(2).
        Assert:IsTrue(Has(cues, CuberCue:Hit)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFrostAMothAHatchingAndARideAreHeard():
        VAR CHARACTER cues.
        mGame:SpawnEnemy(CuberKind:Seed, 6, 3).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:Hatch)).
        mGame:ClearEnemies().
        mGame:SpawnEnemy(CuberKind:Frost, 1, 0).
        cues = Collect(2).
        Assert:IsTrue(Has(cues, CuberCue:FrostPop)).
        mGame:SpawnEnemy(CuberKind:Snuff, 1, 0).
        cues = Collect(2).
        Assert:IsTrue(Has(cues, CuberCue:MothCaught)).
        mGame:ClearEnemies().
        mGame:SetHalo(1, TRUE).
        mGame:PlacePip(4, 0).
        mGame:RequestHop(CuberDir:UpLeft).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:HaloRide)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCoilFallingOffWithPipOnAHaloIsHeard():
        VAR CHARACTER cues.
        mGame:SetHalo(1, TRUE).
        mGame:PlacePip(4, 0).
        mGame:SpawnEnemy(CuberKind:Coil, 7, 3).
        mGame:SetEnemyRest(0, 500).
        mGame:RequestHop(CuberDir:UpLeft).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:CoilFalls)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClearedRoundAndAnExtraPipAreHeard():
        VAR CHARACTER cues.
        VAR INTEGER r.
        VAR INTEGER c.
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        mGame:AddScore(8000).
        mGame:RequestHop(CuberDir:DownRight).
        cues = Collect(14).
        Assert:IsTrue(Has(cues, CuberCue:ExtraLife)).
        Collect(CuberRules:ClearFrames()).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelClearReplacesTheRoundClear():
        VAR CHARACTER cues.
        VAR INTEGER r.
        VAR INTEGER c.
        mGame:BeginRound(1, 4).
        mCues:Poll(mGame).
        Collect(CuberRules:ReadyFrames()).
        mGame:ClearEnemies().
        mGame:StopSpawns().
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        mGame:RequestHop(CuberDir:DownRight).
        Collect(14).
        cues = Collect(CuberRules:ClearFrames()).
        Assert:IsTrue(Has(cues, CuberCue:LevelClear)).
        Assert:IsFalse(Has(cues, CuberCue:RoundClear)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARoundClearIsHeardWhenTheRoundIsNotTheLastOfALevel():
        VAR CHARACTER cues.
        VAR INTEGER r.
        VAR INTEGER c.
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        mGame:RequestHop(CuberDir:DownRight).
        Collect(14).
        cues = Collect(CuberRules:ClearFrames()).
        Assert:IsTrue(Has(cues, CuberCue:RoundClear)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueBelongsToAGroupAndTheGroupsKeepTheBigThingsApart():
        VAR INTEGER i.
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            Assert:IsTrue(mCues:GroupOf(i) >= 1).
        END.
        Assert:Equals(mCues:GroupOf(INTEGER(CuberCue:Hit)), mCues:GroupOf(INTEGER(CuberCue:Fall))).
        Assert:Equals(mCues:GroupOf(INTEGER(CuberCue:LampDone)), mCues:GroupOf(INTEGER(CuberCue:LampOut))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(CuberCue:Hop)) <> mCues:GroupOf(INTEGER(CuberCue:LampDone))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(CuberCue:Hit)) <> mCues:GroupOf(INTEGER(CuberCue:RoundClear))).
        Assert:Equals(mCues:GroupOf(INTEGER(CuberCue:RoundClear)), mCues:GroupOf(INTEGER(CuberCue:LevelClear))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APollOfAnotherGameIsRefused():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            mCues:Poll(?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

END CLASS.
