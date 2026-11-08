/* What Pip is doing, as the values of CuberGame:PipMode.
     Standing   on a lamp, waiting for a hop
     Hopping    in the air between two lamps (12 frames)
     Falling    off the edge of the pyramid, or off the back of it
     Riding     on a halo, being lifted to the top
     Hit        struck by an enemy
     Winning    the round is cleared */
ENUM ProGriddle.Games.Cuber.CuberPipMode:
    DEFINE ENUM Standing = 0
                Hopping
                Falling
                Riding
                Hit
                Winning.
END ENUM.
