/* The sounds of Blast Buddies, by name. INTEGER(BuddyCue:Fire) is the cue number a sound player and a sound bank know it by (1 to 64).
   FlightLoop is the one sound that loops: it sounds for as long as a rocket is in the air. BuddySounds says what each one sounds like and
   BuddyCues says when each one happens. */
ENUM ProGriddle.Games.BlastBuddies.BuddyCue:

    DEFINE ENUM WalkTick = 1
                Hop
                Flip
                Land
                AimTick
                ChargeA
                ChargeB
                ChargeC
                ChargeD
                Fire
                FlightLoop
                BlastSmall
                BlastMedium
                BlastLarge
                Squeal
                Death
                Splash
                TurnStart
                Countdown
                Winner
                Draw.

END ENUM.
