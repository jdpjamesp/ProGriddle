/* The sounds of FOR EACH, by name. INTEGER(ForEachCue:Start) is the cue number a sound player and a sound bank know it by (1 to 64).
   The Alarm sounds, RollbackLoop and ReturningLoop are loops: they sound for as long as the game is in that state. ForEachCues says
   when each one happens. */
ENUM ProGriddle.Games.ForEach.ForEachCue:

    DEFINE ENUM Start = 1
                Crunch1
                Crunch2
                PhantomEaten
                ItemEaten
                Death
                ExtraLife
                Alarm1
                Alarm2
                Alarm3
                Alarm4
                Alarm5
                RollbackLoop
                ReturningLoop
                ItemAppears.

END ENUM.
