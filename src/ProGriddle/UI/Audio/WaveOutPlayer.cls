/* The real sound player: plays the sounds of a SoundBank through the Windows waveOut calls (ProGriddle/UI/Audio/WinMm.p), with
   no files and no callbacks. It keeps a pool of 8 voices (a waveOut handle each) because two sounds on one handle queue one
   behind the other while sounds on separate handles mix, so up to 8 sounds overlap. A voice that has finished is noticed the
   next time something plays, by the done flag of its buffer's header. When all 8 are busy the new sound is dropped, which a
   game's short cues make rare. A play costs about 1.4 ms and never waits, so it is safe on the UI thread.

   If no voice can be opened (no sound card, a remote session) Working is false and every call is silent. The player borrows the
   bank and does not free it: Dispose the player first (it stops the sounds, which are read from the bank's memory), then the
   bank. The headers are the player's memory and Dispose frees them, with a destructor as a safety net. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Audio.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.Audio.WaveOutPlayer FINAL IMPLEMENTS ISoundPlayer:

    &SCOPED-DEFINE VOICES 8

    DEFINE PRIVATE VARIABLE mBank     AS SoundBank NO-UNDO.
    DEFINE PRIVATE VARIABLE mWinMm    AS HANDLE    NO-UNDO.
    DEFINE PRIVATE VARIABLE mHandle   AS INT64     NO-UNDO EXTENT {&VOICES}.
    DEFINE PRIVATE VARIABLE mHeader   AS MEMPTR    NO-UNDO EXTENT {&VOICES}.
    /* a buffer was written on the voice and not yet let go of */
    DEFINE PRIVATE VARIABLE mBusy     AS LOGICAL   NO-UNDO EXTENT {&VOICES}.
    /* the cue a voice is looping, 0 for none: a looping voice stays busy until it is stopped */
    DEFINE PRIVATE VARIABLE mLoopCue  AS INTEGER   NO-UNDO EXTENT {&VOICES}.
    DEFINE PRIVATE VARIABLE mMuted    AS LOGICAL   NO-UNDO.
    DEFINE PRIVATE VARIABLE mOpened   AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mVolume   AS INTEGER   NO-UNDO INITIAL 100.

    /* True when at least one voice opened. */
    DEFINE PUBLIC PROPERTY Working AS LOGICAL NO-UNDO
        GET():
            RETURN mOpened > 0.
        END GET.

    /* Muting stops every loop at once. */
    DEFINE PUBLIC PROPERTY Muted AS LOGICAL NO-UNDO
        GET():
            RETURN mMuted.
        END GET.
        SET(INPUT plValue AS LOGICAL):
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            mMuted = plValue.
            IF mMuted THEN
                DO i = 1 TO mOpened:
                    IF mLoopCue[i] <> 0 THEN ReleaseLoop(i).
                END.
        END SET.

    DEFINE PUBLIC PROPERTY Volume AS INTEGER NO-UNDO
        GET():
            RETURN mVolume.
        END GET.
        SET(INPUT piVolume AS INTEGER):
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            IF piVolume = ? OR piVolume < 0 OR piVolume > 100 THEN UNDO, THROW NEW GridException("A volume is 0 to 100 percent, not " + STRING(piVolume)).
            mVolume = piVolume.
            DO i = 1 TO mOpened:
                RUN SetVoiceVolume IN mWinMm(mHandle[i], mVolume).
            END.
        END SET.

    /* How many voices opened, 0 to 8. */
    DEFINE PUBLIC PROPERTY Voices AS INTEGER NO-UNDO
        GET():
            RETURN mOpened.
        END GET.

    /* How many sounds were started. */
    DEFINE PUBLIC PROPERTY Played AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many sounds were left out because every voice was busy. */
    DEFINE PUBLIC PROPERTY Dropped AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Opens the voices on the default device. poBank holds the sounds and must outlive the player's use of it. Throws GridException
       for no bank. */
    CONSTRUCTOR PUBLIC WaveOutPlayer(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE voice  AS INT64   NO-UNDO.
        DEFINE VARIABLE rc     AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poBank) THEN UNDO, THROW NEW GridException("A wave out player needs a sound bank").
        mBank = poBank.
        RUN ProGriddle/UI/Audio/WinMm.p PERSISTENT SET mWinMm.
        DO i = 1 TO {&VOICES}:
            RUN OpenVoice IN mWinMm(ToneSynth:SampleRate(), OUTPUT voice, OUTPUT rc).
            IF rc <> 0 THEN LEAVE.
            mOpened = mOpened + 1.
            mHandle[mOpened] = voice.
            SET-SIZE(mHeader[mOpened]) = 48.
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC WaveOutPlayer():
        Dispose().
    END DESTRUCTOR.

    /* How many sounds are playing now (after letting go of the ones that have finished). */
    METHOD PUBLIC INTEGER BusyVoices():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE busy  AS INTEGER NO-UNDO.
        Reap().
        DO i = 1 TO mOpened:
            IF mBusy[i] THEN busy = busy + 1.
        END.
        RETURN busy.
    END METHOD.

    /* Starts the sound of a cue on a free voice. Nothing happens when the player is muted or not working, when the bank has no
       sound for the cue, or when every voice is busy (the sound is dropped and counted). */
    METHOD PUBLIC VOID Play(INPUT piCue AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE v  AS INTEGER NO-UNDO.
        DEFINE VARIABLE rc AS INTEGER NO-UNDO.
        IF Muted OR mOpened = 0 OR NOT mBank:Has(piCue) THEN RETURN.
        Reap().
        DO i = 1 TO mOpened:
            IF NOT mBusy[i] THEN DO:
                v = i.
                LEAVE.
            END.
        END.
        IF v = 0 THEN DO:
            Dropped = Dropped + 1.
            RETURN.
        END.
        /* a WAVEHDR: lpData at 0, dwBufferLength at 8, dwFlags at 24 (0 before preparing), dwLoops at 28 */
        PUT-INT64(mHeader[v], 1) = mBank:PointerOf(piCue).
        PUT-LONG(mHeader[v], 9) = mBank:SizeOf(piCue).
        PUT-LONG(mHeader[v], 25) = 0.
        PUT-LONG(mHeader[v], 29) = 0.
        RUN PrepareHeader IN mWinMm(mHandle[v], mHeader[v], OUTPUT rc).
        IF rc <> 0 THEN RETURN.
        mBusy[v] = TRUE.
        RUN WriteHeader IN mWinMm(mHandle[v], mHeader[v], OUTPUT rc).
        IF rc <> 0 THEN DO:
            RUN UnprepareHeader IN mWinMm(mHandle[v], mHeader[v]).
            mBusy[v] = FALSE.
            RETURN.
        END.
        Played = Played + 1.
    END METHOD.

    /* Starts the sound of a cue over and over on a voice of its own, until StopLoop, Muted or Dispose. Nothing happens when that cue
       is already looping, when the player is muted or not working, or when the bank has no sound for the cue. The sound should be
       made from a recipe that loops (see ToneSynth). When every voice is busy the loop is not started (and counted as dropped). */
    METHOD PUBLIC VOID StartLoop(INPUT piCue AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE v  AS INTEGER NO-UNDO.
        DEFINE VARIABLE rc AS INTEGER NO-UNDO.
        IF Muted OR mOpened = 0 OR NOT mBank:Has(piCue) THEN RETURN.
        IF LoopVoice(piCue) > 0 THEN RETURN.
        Reap().
        DO i = 1 TO mOpened:
            IF NOT mBusy[i] THEN DO:
                v = i.
                LEAVE.
            END.
        END.
        IF v = 0 THEN DO:
            Dropped = Dropped + 1.
            RETURN.
        END.
        PUT-INT64(mHeader[v], 1) = mBank:PointerOf(piCue).
        PUT-LONG(mHeader[v], 9) = mBank:SizeOf(piCue).
        PUT-LONG(mHeader[v], 25) = 0.
        PUT-LONG(mHeader[v], 29) = 0.
        RUN PrepareHeader IN mWinMm(mHandle[v], mHeader[v], OUTPUT rc).
        IF rc <> 0 THEN RETURN.
        /* WHDR_BEGINLOOP (4) and WHDR_ENDLOOP (8) on the one buffer, played a million times (hours) unless it is reset */
        PUT-LONG(mHeader[v], 25) = GET-LONG(mHeader[v], 25) + 12.
        PUT-LONG(mHeader[v], 29) = 1000000.
        mBusy[v] = TRUE.
        RUN WriteHeader IN mWinMm(mHandle[v], mHeader[v], OUTPUT rc).
        IF rc <> 0 THEN DO:
            RUN UnprepareHeader IN mWinMm(mHandle[v], mHeader[v]).
            mBusy[v] = FALSE.
            RETURN.
        END.
        mLoopCue[v] = piCue.
    END METHOD.

    /* Stops the looping sound of a cue at once. Nothing happens when it is not looping. */
    METHOD PUBLIC VOID StopLoop(INPUT piCue AS INTEGER):
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        v = LoopVoice(piCue).
        IF v > 0 THEN ReleaseLoop(v).
    END METHOD.

    /* Stops every sound, closes the voices and frees the headers. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF VALID-HANDLE(mWinMm) THEN DO:
            DO i = 1 TO mOpened:
                /* a reset marks every buffer done, and a header must be unprepared before its voice is closed */
                RUN ResetVoice IN mWinMm(mHandle[i]).
                IF mBusy[i] THEN RUN UnprepareHeader IN mWinMm(mHandle[i], mHeader[i]).
                mBusy[i] = FALSE.
                mLoopCue[i] = 0.
                RUN CloseVoice IN mWinMm(mHandle[i]).
            END.
            RUN FreeFormat IN mWinMm.
            DELETE PROCEDURE mWinMm.
        END.
        DO i = 1 TO {&VOICES}:
            SET-SIZE(mHeader[i]) = 0.
        END.
        mOpened = 0.
    END METHOD.

    /* The voice that is looping a cue, 0 for none. */
    METHOD PRIVATE INTEGER LoopVoice(INPUT piCue AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piCue = ? OR piCue < 1 THEN RETURN 0.
        DO i = 1 TO mOpened:
            IF mLoopCue[i] = piCue THEN RETURN i.
        END.
        RETURN 0.
    END METHOD.

    /* Stops what a voice is looping: a reset ends the loop and marks the buffer done, then its header is let go of. */
    METHOD PRIVATE VOID ReleaseLoop(INPUT piVoice AS INTEGER):
        RUN ResetVoice IN mWinMm(mHandle[piVoice]).
        RUN UnprepareHeader IN mWinMm(mHandle[piVoice], mHeader[piVoice]).
        mBusy[piVoice] = FALSE.
        mLoopCue[piVoice] = 0.
    END METHOD.

    /* Lets go of the voices whose buffer has finished: the done flag (1) of dwFlags is set. */
    METHOD PRIVATE VOID Reap():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mOpened:
            IF mBusy[i] AND GET-LONG(mHeader[i], 25) MODULO 2 = 1 THEN DO:
                RUN UnprepareHeader IN mWinMm(mHandle[i], mHeader[i]).
                mBusy[i] = FALSE.
            END.
        END.
    END METHOD.

END CLASS.
