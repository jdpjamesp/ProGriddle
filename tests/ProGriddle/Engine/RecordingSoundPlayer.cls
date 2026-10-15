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

    DEFINE PUBLIC PROPERTY Muted AS LOGICAL NO-UNDO
        GET.
        SET.

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

    DEFINE PUBLIC PROPERTY Disposed AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    METHOD PUBLIC VOID Play(INPUT piCue AS INTEGER):
        IF Muted THEN RETURN.
        Played = Played + (IF PlayCount > 0 THEN "," ELSE "") + STRING(piCue).
        PlayCount = PlayCount + 1.
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
