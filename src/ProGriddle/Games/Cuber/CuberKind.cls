/* The kinds of enemy of Cuber, as the values of CuberGame:EnemyKind. A Seed bounces down the pyramid and hatches into a Coil on
   the bottom row. A Thorn is a bouncing ball that hurts. A Frost is a bouncing ball that freezes every enemy when Pip touches it.
   Snuff (the left edge) and Puff (the right edge) are moths that climb an edge and put lamps out again. */
ENUM ProGriddle.Games.Cuber.CuberKind:
    DEFINE ENUM Seed = 0
                Coil
                Thorn
                Frost
                Snuff
                Puff.
END ENUM.
