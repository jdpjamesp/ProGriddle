/* The silent sound player, the default for a game that has no sound or a machine that has no sound device. It remembers
   whether it is muted and the volume, so the settings and the controls work the same with any player. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.NullSoundPlayer FINAL IMPLEMENTS ISoundPlayer:

    DEFINE PUBLIC PROPERTY Working AS LOGICAL NO-UNDO
        GET():
            RETURN FALSE.
        END GET.

    DEFINE PUBLIC PROPERTY Muted AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Volume AS INTEGER NO-UNDO INITIAL 100
        GET.
        SET(INPUT piVolume AS INTEGER):
            IF piVolume = ? OR piVolume < 0 OR piVolume > 100 THEN UNDO, THROW NEW GridException("A volume is 0 to 100 percent, not " + STRING(piVolume)).
            Volume = piVolume.
        END SET.

    METHOD PUBLIC VOID Play(INPUT piCue AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID StartLoop(INPUT piCue AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID StopLoop(INPUT piCue AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID Dispose():
    END METHOD.

END CLASS.
