/* The cue source of Space Invaders, with real games driven frame by frame: each event is reported once, the title screen and a wave
   being drawn in are silent, the march is four notes in turn and the saucer hum is a loop. Cue numbers are INTEGER(InvadersCue:...). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersCuesTests:

    DEFINE PRIVATE VARIABLE mGame AS SpaceInvadersGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCues AS InvadersCues      NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = SpaceInvadersFactory:Create(NEW SeededRandom(7)).
        mCues = NEW InvadersCues().
        /* the first look takes the title screen as it is */
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS InvadersCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    /* True when the list of cues has the cue in it. */
    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS InvadersCue):
        RETURN LOOKUP(N(poCue), pcCues) > 0.
    END METHOD.

    /* From the title screen to a wave in play, with a look at every step so the title and the drawing in are seen to be silent. */
    METHOD PRIVATE VOID Play():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mCues:Poll(mGame).
        mGame:SkipIntro().
        mCues:Poll(mGame).
        /* the first look at the wave in play is also taken as it is */
        mGame:Advance().
        mCues:Poll(mGame).
    END METHOD.

    METHOD PRIVATE VOID EmptyField(INPUT piKeep AS INTEGER):
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE top AS INTEGER NO-UNDO INITIAL 60.
        IF piKeep > 0 THEN top = mGame:Rack:Y(piKeep - 1) + InvaderRack:SpriteHeight().
        DO i = piKeep TO InvaderRack:Total() - 1:
            IF mGame:Rack:Alive(i) THEN mGame:Rack:Kill(i).
        END.
        mGame:Canvas:ClearRect(0, top, 224, 184 - top).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenAndAWaveBeingDrawnInAreSilent():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 5:
            mGame:Advance().
            Assert:Equals("", mCues:Poll(mGame)).
        END.
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Assert:Equals(GamePhase:Starting, mGame:Phase).
        DO i = 1 TO 20:
            mGame:Advance().
            Assert:Equals("", mCues:Poll(mGame)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonsShotIsOneShootCueAndIsReportedOnce():
        Play().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Assert:Equals(N(InvadersCue:Shoot), mCues:Poll(mGame)).
        mGame:Advance().
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnInvaderThatDiesIsOneInvaderKilledCue():
        Play().
        mGame:Rack:Kill(54).
        Assert:Equals(N(InvadersCue:InvaderKilled), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRackMarchesInFourNotesInTurnOneForEachPass():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE notes AS CHARACTER NO-UNDO.
        Play().
        /* eleven invaders make a pass in eleven frames, so sixty frames are five passes, and it is before the first bomb */
        EmptyField(11).
        mCues:Poll(mGame).
        DO i = 1 TO 60:
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:March1) THEN notes = notes + "1".
            IF Has(cues, InvadersCue:March2) THEN notes = notes + "2".
            IF Has(cues, InvadersCue:March3) THEN notes = notes + "3".
            IF Has(cues, InvadersCue:March4) THEN notes = notes + "4".
        END.
        Assert:Equals("1234", SUBSTRING(notes, 1, 4)).
        Assert:Equals(mGame:Rack:Passes, LENGTH(notes)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMarchGoesRoundToTheFirstNoteAfterTheFourth():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE notes AS CHARACTER NO-UNDO.
        Play().
        /* with one invader left every frame is a pass, so five frames are five notes */
        EmptyField(1).
        mCues:Poll(mGame).
        DO i = 1 TO 5:
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:March1) THEN notes = notes + "1".
            IF Has(cues, InvadersCue:March2) THEN notes = notes + "2".
            IF Has(cues, InvadersCue:March3) THEN notes = notes + "3".
            IF Has(cues, InvadersCue:March4) THEN notes = notes + "4".
        END.
        Assert:Equals("12341", notes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonBlowingUpIsOnePlayerDiesCue():
        DEFINE VARIABLE n    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hits AS INTEGER   NO-UNDO.
        Play().
        mGame:DropBomb(0, mGame:PlayerX, 205).
        DO n = 1 TO 200:
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:PlayerDies) THEN hits = hits + 1.
            IF mGame:Phase = GamePhase:Playing AND n > 150 THEN LEAVE.
        END.
        Assert:Equals(1, hits).
        Assert:Equals(2, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatIsShotIsASaucerHitAndHumsWhileItIsOut():
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hit    AS INTEGER   NO-UNDO.
        Play().
        EmptyField(1).
        mGame:Canvas:ClearRect(0, 184, 224, 16).
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:LaunchSaucer(1).
        Assert:Equals(N(InvadersCue:SaucerHum), mCues:Loops(mGame)).
        DO n = 1 TO 40:
            mGame:Advance().
            mCues:Poll(mGame).
        END.
        mGame:SetPlayerX(mGame:SaucerX + 44 + 9 - 6).
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mCues:Poll(mGame).
        DO n = 1 TO 80:
            IF NOT mGame:SaucerActive THEN LEAVE.
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:SaucerHit) THEN hit = hit + 1.
        END.
        IF NOT mGame:SaucerActive AND hit = 0 THEN DO:
            /* the poll that saw the saucer go may have been the last one inside the loop */
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:SaucerHit) THEN hit = hit + 1.
        END.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(1, hit).
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatFliesAwayIsNotAHit():
        DEFINE VARIABLE n    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hit  AS INTEGER   NO-UNDO.
        Play().
        EmptyField(1).
        mGame:LaunchSaucer(1).
        mCues:Poll(mGame).
        DO n = 1 TO 260:
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF Has(cues, InvadersCue:SaucerHit) THEN hit = hit + 1.
            IF mGame:Phase <> GamePhase:Playing THEN LEAVE.
        END.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(0, hit).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePausedGameAndTheTitleScreenHaveNoLoops():
        Play().
        EmptyField(1).
        mGame:LaunchSaucer(1).
        Assert:Equals(N(InvadersCue:SaucerHum), mCues:Loops(mGame)).
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraCannonAtFifteenHundredPointsIsAFanfare():
        Play().
        mGame:AddScore(1499).
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:AddScore(1).
        Assert:Equals(N(InvadersCue:ExtraLife), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearingTheWaveIsAFanfareAndTheNextWaveIsSilent():
        DEFINE VARIABLE cues AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        Play().
        EmptyField(0).
        mGame:Advance().
        cues = mCues:Poll(mGame).
        Assert:Equals(GamePhase:Cleared, mGame:Phase).
        Assert:IsTrue(Has(cues, InvadersCue:WaveCleared)).
        Assert:IsTrue(Has(cues, InvadersCue:InvaderKilled)).
        Assert:Equals(N(InvadersCue:WaveCleared), ENTRY(1, cues)).
        DO i = 1 TO 100:
            mGame:Advance().
            cues = mCues:Poll(mGame).
            IF mGame:Phase = GamePhase:Starting THEN Assert:Equals("", cues).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroupsKeepTheKillsTogetherAndEverythingElseApart():
        Assert:Equals(mCues:GroupOf(INTEGER(InvadersCue:InvaderKilled)), mCues:GroupOf(INTEGER(InvadersCue:SaucerHit))).
        Assert:Equals(mCues:GroupOf(INTEGER(InvadersCue:March1)), mCues:GroupOf(INTEGER(InvadersCue:March4))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(InvadersCue:Shoot)) <> mCues:GroupOf(INTEGER(InvadersCue:InvaderKilled))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(InvadersCue:March1)) <> mCues:GroupOf(INTEGER(InvadersCue:Shoot))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(InvadersCue:PlayerDies)) <> mCues:GroupOf(INTEGER(InvadersCue:InvaderKilled))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(InvadersCue:ExtraLife)) <> mCues:GroupOf(INTEGER(InvadersCue:WaveCleared))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotSpaceInvadersThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE oOther AS CountingGame NO-UNDO.
        oOther = NEW CountingGame(NEW Grid(NEW ArrayStore(2, 2, "state")), 0).
        DO ON ERROR UNDO, THROW:
            mCues:Poll(oOther).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mCues:Loops(oOther).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    /* End to end: the cues and the saucer's loop of a real game, through the renderer, reach the player. */
    @Test.
    METHOD PUBLIC VOID TheSoundRendererPlaysTheShotAndLoopsTheHumOfARealGame():
        DEFINE VARIABLE oPlayer   AS RecordingSoundPlayer NO-UNDO.
        DEFINE VARIABLE oRenderer AS SoundRenderer        NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        oRenderer = NEW SoundRenderer(NEW RecordingRenderer(), mCues, oPlayer).
        Play().
        EmptyField(1).
        mCues:Poll(mGame).
        mGame:LaunchSaucer(1).
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        oRenderer:Render(mGame:Grid, mGame).
        Assert:IsTrue(LOOKUP(N(InvadersCue:Shoot), oPlayer:Played) > 0).
        Assert:Equals(N(InvadersCue:SaucerHum), oPlayer:Looping).
    END METHOD.

END CLASS.
