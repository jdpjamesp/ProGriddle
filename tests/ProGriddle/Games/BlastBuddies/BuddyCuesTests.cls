/* The sounds of Blast Buddies: what each cue sounds like, and when each one happens. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyCuesTests:

    DEFINE PRIVATE VARIABLE mGame AS BlastBuddiesGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCues AS BuddyCues        NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID Setup():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        mCues = NEW BuddyCues().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mGame:Dispose().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* whether a poll's comma list has a cue */
    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS BuddyCue):
        RETURN INDEX("," + pcCues + ",", "," + STRING(INTEGER(poCue)) + ",") > 0.
    END METHOD.

    /* flat ground, the buddies spread out on it, the game run to the first turn (a person's) and the cues primed with a first poll */
    METHOD PRIVATE VOID ToTheFirstTurn():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        mGame:Land:FillRect(0, 150, 383, 239, TRUE).
        DO k = 0 TO 5:
            mGame:Plan:TeamAt(k MODULO 2 + 1):BuddyAt(INTEGER(TRUNCATE(k / 2, 0)) + 1):PlaceAt(100 + 40 * k, 150).
        END.
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mGame:Plan:TeamAt(2):BuddyAt(1):PlaceAt(136, 150).
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:CurrentBuddy:Facing = 1.
        mCues:Poll(mGame).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(BuddyCue:WalkTick) TO INTEGER(BuddyCue:Draw):
            oSynth:Make(BuddySounds:Recipe(BuddyCue:GetEnum(i)), 100, OUTPUT mData).
            loud = 0.
            DO j = 1 TO GET-SIZE(mData):
                IF ABSOLUTE(GET-BYTE(mData, j) - 128) > 10 THEN loud = loud + 1.
            END.
            Assert:IsTrue(loud > 50, "cue " + STRING(i)).
            SET-SIZE(mData) = 0.
        END.
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheRocketHissLoopsAndABigBlastIsLouderAndLongerThanASmallOne():
        DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth  AS ToneSynth NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL   NO-UNDO.
        DO i = INTEGER(BuddyCue:WalkTick) TO INTEGER(BuddyCue:Draw):
            IF i = INTEGER(BuddyCue:FlightLoop) THEN Assert:Equals("@", SUBSTRING(BuddySounds:Recipe(BuddyCue:GetEnum(i)), 1, 1)).
            ELSE Assert:IsFalse(SUBSTRING(BuddySounds:Recipe(BuddyCue:GetEnum(i)), 1, 1) = "@").
        END.
        oSynth = NEW ToneSynth().
        Assert:IsTrue(oSynth:SampleCount(BuddySounds:Recipe(BuddyCue:BlastLarge)) > oSynth:SampleCount(BuddySounds:Recipe(BuddyCue:BlastMedium))).
        Assert:IsTrue(oSynth:SampleCount(BuddySounds:Recipe(BuddyCue:BlastMedium)) > oSynth:SampleCount(BuddySounds:Recipe(BuddyCue:BlastSmall))).
        Assert:IsTrue(BuddySounds:VolumeOf(BuddyCue:BlastLarge) > BuddySounds:VolumeOf(BuddyCue:WalkTick)).
        Assert:IsTrue(BuddySounds:VolumeOf(BuddyCue:FlightLoop) < BuddySounds:VolumeOf(BuddyCue:Fire)).
        DO ON ERROR UNDO, LEAVE:
            BuddySounds:Recipe(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillPutsEveryCueInABankUnderItsNumber():
        DEFINE VARIABLE bank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        bank = NEW SoundBank().
        BuddySounds:Fill(bank).
        DO i = INTEGER(BuddyCue:WalkTick) TO INTEGER(BuddyCue:Draw):
            Assert:IsTrue(bank:Has(i), "cue " + STRING(i)).
        END.
        Assert:IsFalse(bank:Has(INTEGER(BuddyCue:Draw) + 1)).
        bank:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstLookAndANewGameSayNothing():
        Assert:Equals("", mCues:Poll(mGame)).
        ToTheFirstTurn().
        mGame:Jump().
        mGame:Initialise().
        Assert:Equals("", mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACuesSourceNeedsABlastBuddiesGame():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mCues:Poll(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mCues:Loops(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewTurnHasItsCallAndOnlyOnce():
        Frames(BuddyRules:ArrivalFrames() - 1).
        mCues:Poll(mGame).
        Frames(1).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:TurnStart)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopAndABackflipHaveTheirOwnBlipsAndAnotherSoundForTheLanding():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        ToTheFirstTurn().
        mGame:Jump().
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:Hop)).
        Frames(4).
        mGame:Jump().
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, BuddyCue:Flip)).
        Assert:IsFalse(Has(cues, BuddyCue:Hop)).
        Frames(60).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:Land)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingTicksEveryThirdPixelAndAimingEveryFourthStep():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        ToTheFirstTurn().
        mGame:SetWalk(1).
        Frames(10).
        mGame:SetWalk(0).
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, BuddyCue:WalkTick)).
        mGame:SetAim(1).
        Frames(15).
        mGame:SetAim(0).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:AimTick)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingFireTicksAsThePowerRisesInHigherPitches():
        ToTheFirstTurn().
        mGame:StartCharge().
        Frames(10).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:ChargeA)).
        Frames(70).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:ChargeD)).
        Frames(1).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotWhooshesAndHissesWhileItFliesAndAnExplosionAnswersIt():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        ToTheFirstTurn().
        mGame:StartCharge().
        Frames(45).
        mCues:Poll(mGame).
        mGame:ReleaseCharge().
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, BuddyCue:Fire)).
        Assert:Equals(STRING(INTEGER(BuddyCue:FlightLoop)), mCues:Loops(mGame)).
        Frames(120).
        Assert:Equals("", mCues:Loops(mGame)).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:BlastMedium) OR mGame:WaterHits > 0 OR mGame:BlastCount = 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastThatHurtsABuddyMakesItSqueal():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        ToTheFirstTurn().
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 136 * 256, 100 * 256, 0, 2048).
        Frames(10).
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, BuddyCue:BlastMedium)).
        Assert:IsTrue(Has(cues, BuddyCue:Squeal)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyThatDiesAndOneThatDrownsHaveTheirSounds():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        ToTheFirstTurn().
        mGame:Plan:TeamAt(2):BuddyAt(1):Hurt(100).
        mGame:Land:FillRect(190, 150, 230, 239, FALSE).
        mGame:Plan:TeamAt(2):BuddyAt(2):PlaceAt(210, 150).
        mGame:EndTurn().
        Frames(400).
        cues = mCues:Poll(mGame).
        Assert:IsTrue(Has(cues, BuddyCue:Death)).
        Assert:IsTrue(Has(cues, BuddyCue:Splash)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastTenSecondsOfATurnTickOffAndWinnerAndDrawHaveEndings():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        Frames(BuddyRules:TurnFrames() - 11 * 60).
        mCues:Poll(mGame).
        Frames(60).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:Countdown)).
        Frames(10).
        Assert:IsFalse(Has(mCues:Poll(mGame), BuddyCue:Countdown)).
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(500).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Winner).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:Winner)).
        Assert:IsFalse(Has(mCues:Poll(mGame), BuddyCue:Winner)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrawHasItsFallingPairAndAFinishedOrPausedGameHasNoLoops():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(1):BuddyAt(i):Hurt(100).
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(800).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Draw).
        Assert:IsTrue(Has(mCues:Poll(mGame), BuddyCue:Draw)).
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 50 * 256, 5 * 256, 0, -3000).
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameHasNoLoopAndTheSizesOfBlastShareAGroup():
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 50 * 256, 5 * 256, 0, -3000).
        Assert:Equals(STRING(INTEGER(BuddyCue:FlightLoop)), mCues:Loops(mGame)).
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
        Assert:Equals(mCues:GroupOf(INTEGER(BuddyCue:BlastSmall)), mCues:GroupOf(INTEGER(BuddyCue:BlastLarge))).
        Assert:Equals(mCues:GroupOf(INTEGER(BuddyCue:Winner)), mCues:GroupOf(INTEGER(BuddyCue:Draw))).
        Assert:Equals(mCues:GroupOf(INTEGER(BuddyCue:ChargeA)), mCues:GroupOf(INTEGER(BuddyCue:ChargeD))).
        Assert:Equals(mCues:GroupOf(INTEGER(BuddyCue:Hop)), mCues:GroupOf(INTEGER(BuddyCue:Flip))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(BuddyCue:Fire)) <> mCues:GroupOf(INTEGER(BuddyCue:Squeal))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(BuddyCue:Death)) <> mCues:GroupOf(INTEGER(BuddyCue:Splash))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(BuddyCue:Land)) <> mCues:GroupOf(INTEGER(BuddyCue:WalkTick))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(BuddyCue:AimTick)) <> mCues:GroupOf(INTEGER(BuddyCue:TurnStart))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(BuddyCue:Countdown)) <> mCues:GroupOf(INTEGER(BuddyCue:FlightLoop))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSoundCommandSwitchesTheSoundOnAndOffWhenThereIsADevice():
        DEFINE VARIABLE player   AS RecordingSoundPlayer NO-UNDO.
        DEFINE VARIABLE settings AS ISettings            NO-UNDO.
        DEFINE VARIABLE input1   AS BlastBuddiesInput    NO-UNDO.
        DEFINE VARIABLE lThrown  AS LOGICAL              NO-UNDO.
        player = NEW RecordingSoundPlayer().
        settings = NEW MemorySettings().
        input1 = NEW BlastBuddiesInput(mGame, settings, player).
        Assert:Equals("Sound:M", input1:CommandNames).
        input1:Perform("Sound").
        Assert:IsTrue(player:Muted).
        Assert:IsTrue(input1:TakeNotice() <> "").
        input1:Perform("Sound").
        Assert:IsFalse(player:Muted).
        player:Working = FALSE.
        Assert:Equals("", input1:CommandNames).
        DO ON ERROR UNDO, LEAVE:
            input1 = NEW BlastBuddiesInput(mGame, settings, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

END CLASS.
