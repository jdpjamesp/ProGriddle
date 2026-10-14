/* What the ship is doing in an Asteroids game.

     Alive      flying: it turns, thrusts, fires and can be hit
     Dying      breaking up, for a second and a half
     Waiting    gone, until the middle of the screen is clear
     HyperOut   leaving through hyperspace, stretching away
     HyperGap   gone in hyperspace, and out of reach of everything
     HyperBack  coming back from hyperspace */
ENUM ProGriddle.Games.Asteroids.ShipMode:

    DEFINE ENUM Alive = 0
                Dying
                Waiting
                HyperOut
                HyperGap
                HyperBack.

END ENUM.
