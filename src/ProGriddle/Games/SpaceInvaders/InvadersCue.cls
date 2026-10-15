/* The sounds of Space Invaders, by name. INTEGER(InvadersCue:Shoot) is the cue number a sound player and a sound bank know it by
   (1 to 64). March1 to March4 are the four notes of the rack's march, and SaucerHum is the one sound that loops: it sounds for as
   long as the saucer is out. InvadersSounds says what each one sounds like and InvadersCues says when each one happens. */
ENUM ProGriddle.Games.SpaceInvaders.InvadersCue:

    DEFINE ENUM Shoot = 1
                InvaderKilled
                PlayerDies
                March1
                March2
                March3
                March4
                SaucerHit
                ExtraLife
                WaveCleared
                SaucerHum.

END ENUM.
