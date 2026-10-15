/* The sound bank: the made sounds of a game, kept by cue number (the integer of a cue enum, 1 to 64). Define makes a sound from
   a recipe with ToneSynth and keeps it. A player reads a sound through PointerOf and SizeOf, so nothing is copied. The bank owns
   the memory: Dispose frees every sound (a destructor does it as a safety net), and the owner of the bank calls Dispose. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundBank FINAL:

    DEFINE PRIVATE VARIABLE mSynth AS ToneSynth NO-UNDO.
    DEFINE PRIVATE VARIABLE mData  AS MEMPTR    NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mHeld  AS LOGICAL   NO-UNDO EXTENT 64.

    /* How many sounds the bank holds. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC SoundBank():
        mSynth = NEW ToneSynth().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC SoundBank():
        Dispose().
    END DESTRUCTOR.

    /* Makes the sound of a recipe (see ToneSynth) at a volume of 0 to 100 percent and keeps it as cue piCue, replacing and freeing
       the one that was there. Throws GridException for a cue outside 1 to 64 or a recipe or volume ToneSynth refuses (the old
       sound is kept then). */
    METHOD PUBLIC VOID Define(INPUT piCue AS INTEGER, INPUT pcRecipe AS CHARACTER, INPUT piVolume AS INTEGER):
        DEFINE VARIABLE mNew AS MEMPTR NO-UNDO.
        IF piCue = ? OR piCue < 1 OR piCue > 64 THEN UNDO, THROW NEW GridException("A cue number is 1 to 64, not " + STRING(piCue)).
        mSynth:Make(pcRecipe, piVolume, OUTPUT mNew).
        IF mHeld[piCue] THEN SET-SIZE(mData[piCue]) = 0.
        ELSE ASSIGN
            mHeld[piCue] = TRUE
            Count = Count + 1.
        SET-SIZE(mData[piCue]) = GET-SIZE(mNew).
        COPY-LOB FROM mNew TO mData[piCue].
        FINALLY:
            SET-SIZE(mNew) = 0.
        END FINALLY.
    END METHOD.

    /* True when a sound is kept for the cue. Not a number from 1 to 64, or unknown, is just false. */
    METHOD PUBLIC LOGICAL Has(INPUT piCue AS INTEGER):
        IF piCue = ? OR piCue < 1 OR piCue > 64 THEN RETURN FALSE.
        RETURN mHeld[piCue].
    END METHOD.

    /* The number of samples (bytes) of a cue's sound. Throws GridException when there is none. */
    METHOD PUBLIC INTEGER SizeOf(INPUT piCue AS INTEGER):
        MustHave(piCue).
        RETURN INTEGER(GET-SIZE(mData[piCue])).
    END METHOD.

    /* The address of a cue's sound, valid until the cue is defined again or the bank is disposed. Throws GridException when there is none. */
    METHOD PUBLIC INT64 PointerOf(INPUT piCue AS INTEGER):
        MustHave(piCue).
        RETURN GET-POINTER-VALUE(mData[piCue]).
    END METHOD.

    /* Frees every sound. Safe to call more than once, and the bank can be filled again. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 64:
            IF mHeld[i] THEN SET-SIZE(mData[i]) = 0.
            mHeld[i] = FALSE.
        END.
        Count = 0.
    END METHOD.

    METHOD PRIVATE VOID MustHave(INPUT piCue AS INTEGER):
        IF NOT Has(piCue) THEN UNDO, THROW NEW GridException("There is no sound for cue " + STRING(piCue)).
    END METHOD.

END CLASS.
