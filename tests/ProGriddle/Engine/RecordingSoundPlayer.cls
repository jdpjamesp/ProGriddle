/* Test double: remembers the cues it was asked to play (not while muted), in order, as a comma list. Not a test class itself
   (the name does not end in Tests). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.RecordingSoundPlayer IMPLEMENTS ISoundPlayer:

    DEFINE PUBLIC PROPERTY Working AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* The cues that are looping now, as a comma list ("" for none), and how many loops were started. */
    DEFINE PUBLIC PROPERTY Looping AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    /* Muting stops every loop. */
    DEFINE PUBLIC PROPERTY Muted AS LOGICAL NO-UNDO
        GET.
        SET(INPUT plValue AS LOGICAL):
            Muted = plValue.
            IF plValue THEN Looping = "".
        END SET.

    DEFINE PUBLIC PROPERTY Volume AS INTEGER NO-UNDO INITIAL 100
        GET.
        SET(INPUT piVolume AS INTEGER):
            IF piVolume = ? OR piVolume < 0 OR piVolume > 100 THEN UNDO, THROW NEW GridException("A volume is 0 to 100 percent, not " + STRING(piVolume)).
            Volume = piVolume.
        END SET.

    /* The cues played so far, in order, such as "3,1,1" ("" for none). */
    DEFINE PUBLIC PROPERTY Played AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PlayCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LoopStarts AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Disposed AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    METHOD PUBLIC VOID Play(INPUT piCue AS INTEGER):
        IF Muted THEN RETURN.
        Played = Played + (IF PlayCount > 0 THEN "," ELSE "") + STRING(piCue).
        PlayCount = PlayCount + 1.
    END METHOD.

    METHOD PUBLIC VOID StartLoop(INPUT piCue AS INTEGER):
        IF Muted OR LOOKUP(STRING(piCue), Looping) > 0 THEN RETURN.
        Looping = Looping + (IF Looping = "" THEN "" ELSE ",") + STRING(piCue).
        LoopStarts = LoopStarts + 1.
    END METHOD.

    METHOD PUBLIC VOID StopLoop(INPUT piCue AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        i = LOOKUP(STRING(piCue), Looping).
        IF i > 0 THEN ENTRY(i, Looping) = "".
        IF i > 0 THEN Looping = TRIM(REPLACE(REPLACE(Looping, ",,", ","), ",,", ","), ",").
    END METHOD.

    /* Forgets what was played. */
    METHOD PUBLIC VOID Forget():
        Played = "".
        PlayCount = 0.
    END METHOD.

    METHOD PUBLIC VOID Dispose():
        Disposed = TRUE.
    END METHOD.

END CLASS.
