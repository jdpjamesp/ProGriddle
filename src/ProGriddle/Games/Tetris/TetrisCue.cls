/* The sounds of Tetris, by name. INTEGER(TetrisCue:Lock) is the cue number a sound player and a sound bank know it by (1 to 64);
   TetrisSounds says what each one sounds like and TetrisCues says when each one happens. */
ENUM ProGriddle.Games.Tetris.TetrisCue:

    DEFINE ENUM Lock = 1
                Clear
                Tetris
                LevelUp
                GameOver
                Danger.

END ENUM.
