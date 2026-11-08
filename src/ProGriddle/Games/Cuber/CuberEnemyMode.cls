/* What an enemy is doing, as the values of CuberGame:EnemyMode.
     Dropping   falling in from above the pyramid onto its first lamp (8 frames)
     Resting    standing on a lamp until it is time to hop
     Hopping    in the air between two lamps (12 frames)
     Hatching   a seed that has reached the bottom row and is turning into a Coil
     Falling    off the edge of the pyramid (or following Pip off it) */
ENUM ProGriddle.Games.Cuber.CuberEnemyMode:
    DEFINE ENUM Dropping = 0
                Resting
                Hopping
                Hatching
                Falling.
END ENUM.
