/* The Windows sound calls (winmm.dll waveOut) for ProGriddle.UI.Audio.WaveOutPlayer. This is the one procedure file in the
   framework, because an EXTERNAL procedure cannot be declared inside a class: WaveOutPlayer runs this file PERSISTENT and calls
   the internal procedures below, which wrap the calls and do nothing else. It holds no game knowledge and no state but the wave
   format, which FreeFormat releases before the player deletes the procedure. Every voice is one waveOut handle for 8 bit mono
   sound; two buffers on one handle queue, so the player keeps a pool of voices to mix sounds. */

PROCEDURE waveOutOpen EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER phwo AS MEMPTR.
    DEFINE INPUT PARAMETER uDeviceID AS INT64.
    DEFINE INPUT PARAMETER pwfx AS MEMPTR.
    DEFINE INPUT PARAMETER dwCallback AS INT64.
    DEFINE INPUT PARAMETER dwInstance AS INT64.
    DEFINE INPUT PARAMETER fdwOpen AS LONG.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutPrepareHeader EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE INPUT PARAMETER pwh AS MEMPTR.
    DEFINE INPUT PARAMETER cbwh AS LONG.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutUnprepareHeader EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE INPUT PARAMETER pwh AS MEMPTR.
    DEFINE INPUT PARAMETER cbwh AS LONG.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutWrite EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE INPUT PARAMETER pwh AS MEMPTR.
    DEFINE INPUT PARAMETER cbwh AS LONG.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutReset EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutClose EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

PROCEDURE waveOutSetVolume EXTERNAL "winmm.dll":
    DEFINE INPUT PARAMETER hwo AS INT64.
    DEFINE INPUT PARAMETER dwVolume AS UNSIGNED-LONG.
    DEFINE RETURN PARAMETER rc AS LONG.
END PROCEDURE.

DEFINE VARIABLE mFormat AS MEMPTR  NO-UNDO.
DEFINE VARIABLE mRate   AS INTEGER NO-UNDO.

/* Opens a voice for 8 bit mono sound at piRate Hz on the default device. pRc 0 is good and pHandle is 0 otherwise. */
PROCEDURE OpenVoice:
    DEFINE INPUT  PARAMETER piRate   AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pHandle  AS INT64   NO-UNDO.
    DEFINE OUTPUT PARAMETER pRc      AS INTEGER NO-UNDO.
    DEFINE VARIABLE mHandle AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE rc      AS INTEGER NO-UNDO.
    IF mRate <> piRate THEN DO:
        /* a WAVEFORMATEX: format 1 (PCM), 1 channel, the rate, bytes a second, 1 byte a block, 8 bits, no extra */
        SET-SIZE(mFormat) = 0.
        SET-SIZE(mFormat) = 18.
        PUT-SHORT(mFormat, 1) = 1.
        PUT-SHORT(mFormat, 3) = 1.
        PUT-LONG(mFormat, 5) = piRate.
        PUT-LONG(mFormat, 9) = piRate.
        PUT-SHORT(mFormat, 13) = 1.
        PUT-SHORT(mFormat, 15) = 8.
        PUT-SHORT(mFormat, 17) = 0.
        mRate = piRate.
    END.
    SET-SIZE(mHandle) = 8.
    /* 4294967295 is WAVE_MAPPER, the default device */
    RUN waveOutOpen(mHandle, 4294967295, mFormat, 0, 0, 0, OUTPUT rc).
    pRc = rc.
    pHandle = (IF rc = 0 THEN GET-INT64(mHandle, 1) ELSE 0).
    FINALLY:
        SET-SIZE(mHandle) = 0.
    END FINALLY.
END PROCEDURE.

/* Gets a 48 byte WAVEHDR ready for the voice. pRc 0 is good. */
PROCEDURE PrepareHeader:
    DEFINE INPUT  PARAMETER pHandle AS INT64  NO-UNDO.
    DEFINE INPUT  PARAMETER pmHdr   AS MEMPTR NO-UNDO.
    DEFINE OUTPUT PARAMETER pRc     AS INTEGER NO-UNDO.
    DEFINE VARIABLE rc AS INTEGER NO-UNDO.
    RUN waveOutPrepareHeader(pHandle, pmHdr, 48, OUTPUT rc).
    pRc = rc.
END PROCEDURE.

/* Starts the buffer of a prepared header. It queues behind anything already on the voice. pRc 0 is good. */
PROCEDURE WriteHeader:
    DEFINE INPUT  PARAMETER pHandle AS INT64  NO-UNDO.
    DEFINE INPUT  PARAMETER pmHdr   AS MEMPTR NO-UNDO.
    DEFINE OUTPUT PARAMETER pRc     AS INTEGER NO-UNDO.
    DEFINE VARIABLE rc AS INTEGER NO-UNDO.
    RUN waveOutWrite(pHandle, pmHdr, 48, OUTPUT rc).
    pRc = rc.
END PROCEDURE.

/* Lets go of a header whose buffer has finished (or been reset). */
PROCEDURE UnprepareHeader:
    DEFINE INPUT PARAMETER pHandle AS INT64  NO-UNDO.
    DEFINE INPUT PARAMETER pmHdr   AS MEMPTR NO-UNDO.
    DEFINE VARIABLE rc AS INTEGER NO-UNDO.
    RUN waveOutUnprepareHeader(pHandle, pmHdr, 48, OUTPUT rc).
END PROCEDURE.

/* Stops what the voice is playing, which marks every buffer on it done. */
PROCEDURE ResetVoice:
    DEFINE INPUT PARAMETER pHandle AS INT64 NO-UNDO.
    DEFINE VARIABLE rc AS INTEGER NO-UNDO.
    RUN waveOutReset(pHandle, OUTPUT rc).
END PROCEDURE.

/* Closes a voice. Its headers must be unprepared first. */
PROCEDURE CloseVoice:
    DEFINE INPUT PARAMETER pHandle AS INT64 NO-UNDO.
    DEFINE VARIABLE rc AS INTEGER NO-UNDO.
    RUN waveOutClose(pHandle, OUTPUT rc).
END PROCEDURE.

/* Sets the volume of a voice, 0 to 100 percent, on both channels. */
PROCEDURE SetVoiceVolume:
    DEFINE INPUT PARAMETER pHandle  AS INT64   NO-UNDO.
    DEFINE INPUT PARAMETER piPercent AS INTEGER NO-UNDO.
    DEFINE VARIABLE level AS INT64   NO-UNDO.
    DEFINE VARIABLE rc    AS INTEGER NO-UNDO.
    /* the low 16 bits are the left channel and the high 16 the right, each 0 to 65535 */
    level = TRUNCATE(piPercent * 65535 / 100, 0).
    RUN waveOutSetVolume(pHandle, level + level * 65536, OUTPUT rc).
END PROCEDURE.

/* Frees the wave format. Call it before deleting this procedure. */
PROCEDURE FreeFormat:
    SET-SIZE(mFormat) = 0.
    mRate = 0.
END PROCEDURE.
