/* The sounds of Snake, by name. INTEGER(SnakeCue:Eat) is the cue number a sound player and a sound bank know it by (1 to 64);
   SnakeSounds says what each one sounds like and SnakeCues says when each one happens. */
ENUM ProGriddle.Games.Snake.SnakeCue:

    DEFINE ENUM Eat = 1
                Crash
                Win.

END ENUM.
