/* Plays the sounds of a game. A cue is the integer of one of the game's cue enums (1 to 64), and what it sounds like is the
   game's business (a SoundBank), so a player knows nothing about any game. Play never waits and never fails: a player that has
   no device, is muted or has no sound for the cue is silent. The real player (WaveOutPlayer) is in ProGriddle.UI.Audio and the
   silent one (NullSoundPlayer) is the default. The owner of a player calls Dispose. */
INTERFACE ProGriddle.Engine.ISoundPlayer:

    /* True when sound can really come out: false for the silent player, and for a real one that found no sound device. */
    DEFINE PUBLIC PROPERTY Working AS LOGICAL NO-UNDO
        GET.

    /* While true nothing is played. */
    DEFINE PUBLIC PROPERTY Muted AS LOGICAL NO-UNDO
        GET.
        SET.

    /* 0 to 100 percent. Throws GridException outside that. */
    DEFINE PUBLIC PROPERTY Volume AS INTEGER NO-UNDO
        GET.
        SET.

    /* Starts the sound of a cue at once and returns, mixing it with any that are still playing. */
    METHOD PUBLIC VOID Play(INPUT piCue AS INTEGER).

    /* Stops every sound and lets go of the device. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose().

END INTERFACE.
