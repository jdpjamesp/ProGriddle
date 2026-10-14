/* The phases an Asteroids game goes through, as the values of AsteroidsGame:Phase.

     Title     the attract screen, rocks drifting behind the name, waiting for the fire key
     Playing   the game proper: a wave starts, the ship flies, and when the last rock is gone the next wave comes
     GameOver  the lives are gone and the last ship has broken up: waits for the fire key and returns to Title */
ENUM ProGriddle.Games.Asteroids.GamePhase:

    DEFINE ENUM Title = 0
                Playing
                GameOver.

END ENUM.
