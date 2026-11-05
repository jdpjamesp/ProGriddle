/* The phases a Centipede game goes through, as the values of CentipedeGame:Phase.

     Title     the attract screen, waiting for the fire key
     Playing   the game proper
     Dying     the shooter has been hit and is breaking up: everything stands still
     Cleared   every segment is shot: a short pause, then the next wave
     GameOver  the lives are gone: waits for the fire key and returns to Title */
ENUM ProGriddle.Games.Centipede.GamePhase:

    DEFINE ENUM Title = 0
                Playing
                Dying
                Cleared
                GameOver.

END ENUM.
