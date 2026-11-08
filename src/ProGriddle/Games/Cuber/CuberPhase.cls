/* The phases a Cuber game goes through, as the values of CuberGame:Phase.
     Title     the attract screen, waiting for the fire key
     Ready     the READY banner at the start of every life and round: nothing moves yet
     Playing   the game proper
     Dying     Pip has been hit or has fallen: everything stands still while it plays out
     Cleared   every lamp is lit: the ripple and the bonus, then the next round
     GameOver  the lives are gone: waits for the fire key and returns to Title */
ENUM ProGriddle.Games.Cuber.CuberPhase:
    DEFINE ENUM Title = 0
                Ready
                Playing
                Dying
                Cleared
                GameOver.
END ENUM.
