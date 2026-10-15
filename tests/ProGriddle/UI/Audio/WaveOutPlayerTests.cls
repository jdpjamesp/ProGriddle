/* The Windows sound player. A test machine may have no sound device, and then the player must be silent and safe, so the tests that
   need a device check Working first. The sounds they play are rests (silence) at volume 0: nothing is heard. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Audio.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.Audio.WaveOutPlayerTests:

    DEFINE PRIVATE VARIABLE mBank   AS SoundBank     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayer AS WaveOutPlayer NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPlayer():
        mBank = NEW SoundBank().
        /* cue 1 is a tenth of a second of silence, cue 2 is three tenths */
        mBank:Define(1, "r:100", 0).
        mBank:Define(2, "r:300", 0).
        /* cue 3 is a loop of silence */
        mBank:Define(3, "@r:100", 0).
        mPlayer = NEW WaveOutPlayer(mBank).
        mPlayer:Volume = 0.
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePlayer():
        IF VALID-OBJECT(mPlayer) THEN mPlayer:Dispose().
        mPlayer = ?.
        IF VALID-OBJECT(mBank) THEN mBank:Dispose().
        mBank = ?.
    END METHOD.

    /* Waits for piMs milliseconds, which is a busy loop: the test has no timer to wait on. */
    METHOD PRIVATE VOID PauseFor(INPUT piMs AS INTEGER):
        DEFINE VARIABLE start AS INTEGER NO-UNDO.
        start = ETIME.
        DO WHILE ETIME - start < piMs:
        END.
    END METHOD.

    /* Waits up to two seconds for every sound to finish and says whether they did. */
    METHOD PRIVATE LOGICAL WaitUntilQuiet():
        DEFINE VARIABLE start AS INTEGER NO-UNDO.
        start = ETIME.
        DO WHILE ETIME - start < 2000:
            IF mPlayer:BusyVoices() = 0 THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerNeedsABank():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW WaveOutPlayer(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItIsWorkingExactlyWhenAVoiceOpenedAndHasAtMostEight():
        Assert:IsTrue(mPlayer:Voices >= 0 AND mPlayer:Voices <= 8).
        Assert:Equals(mPlayer:Voices > 0, mPlayer:Working).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheVolumeIsKeptAndOutsideZeroToOneHundredThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mPlayer:Volume = 60.
        Assert:Equals(60, mPlayer:Volume).
        DO ON ERROR UNDO, THROW:
            mPlayer:Volume = 101.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPlayer:Volume = -1.
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
        Assert:Equals(60, mPlayer:Volume).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASilentSoundIsStartedAndSeenToFinish():
        IF NOT mPlayer:Working THEN RETURN.
        mPlayer:Play(1).
        Assert:Equals(1, mPlayer:Played).
        Assert:Equals(1, mPlayer:BusyVoices()).
        Assert:IsTrue(WaitUntilQuiet()).
        Assert:Equals(0, mPlayer:Dropped).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MutedOrUnknownCuesPlayNothing():
        mPlayer:Muted = TRUE.
        mPlayer:Play(1).
        Assert:Equals(0, mPlayer:Played).
        mPlayer:Muted = FALSE.
        mPlayer:Play(9).
        Assert:Equals(0, mPlayer:Played).
        Assert:Equals(0, mPlayer:Dropped).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SoundsOverlapOnSeparateVoicesAndAreDroppedWhenEveryVoiceIsBusy():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT mPlayer:Working THEN RETURN.
        DO i = 1 TO mPlayer:Voices + 1:
            mPlayer:Play(2).
        END.
        Assert:Equals(mPlayer:Voices, mPlayer:Played).
        Assert:Equals(mPlayer:Voices, mPlayer:BusyVoices()).
        Assert:Equals(1, mPlayer:Dropped).
        Assert:IsTrue(WaitUntilQuiet()).
        /* the voices are free again */
        mPlayer:Play(1).
        Assert:Equals(mPlayer:Voices + 1, mPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoopKeepsItsVoiceUntilStoppedAndIsStartedOnlyOnce():
        IF NOT mPlayer:Working THEN RETURN.
        mPlayer:StartLoop(3).
        mPlayer:StartLoop(3).
        Assert:Equals(1, mPlayer:BusyVoices()).
        /* well past the hundred milliseconds of the sound: it is still going round */
        PauseFor(300).
        Assert:Equals(1, mPlayer:BusyVoices()).
        /* the other voices still play sounds */
        mPlayer:Play(1).
        Assert:Equals(2, mPlayer:BusyVoices()).
        mPlayer:StopLoop(3).
        mPlayer:StopLoop(3).
        mPlayer:StopLoop(0).
        Assert:IsTrue(WaitUntilQuiet()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MutingStopsLoopsAndAMutedPlayerStartsNone():
        IF NOT mPlayer:Working THEN RETURN.
        mPlayer:StartLoop(3).
        Assert:Equals(1, mPlayer:BusyVoices()).
        mPlayer:Muted = TRUE.
        Assert:Equals(0, mPlayer:BusyVoices()).
        mPlayer:StartLoop(3).
        Assert:Equals(0, mPlayer:BusyVoices()).
        mPlayer:Muted = FALSE.
        mPlayer:StartLoop(9).
        Assert:Equals(0, mPlayer:BusyVoices()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsALoopToo():
        IF NOT mPlayer:Working THEN RETURN.
        mPlayer:StartLoop(3).
        mPlayer:Dispose().
        Assert:Equals(0, mPlayer:BusyVoices()).
        Assert:IsFalse(mPlayer:Working).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsTheSoundsCanBeCalledAgainAndLeavesThePlayerSilent():
        IF mPlayer:Working THEN DO:
            mPlayer:Play(2).
            Assert:Equals(1, mPlayer:BusyVoices()).
        END.
        mPlayer:Dispose().
        mPlayer:Dispose().
        Assert:IsFalse(mPlayer:Working).
        Assert:Equals(0, mPlayer:Voices).
        mPlayer:Play(1).
        Assert:Equals(0, mPlayer:BusyVoices()).
    END METHOD.

END CLASS.
