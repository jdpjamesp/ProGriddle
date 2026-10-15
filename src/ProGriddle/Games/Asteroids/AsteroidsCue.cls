/* The sounds of Asteroids, by name. INTEGER(AsteroidsCue:Fire) is the cue number a sound player and a sound bank know it by
   (1 to 64). ThrustLoop, SaucerLargeHum and SaucerSmallHum are the sounds that loop: they sound for as long as the ship
   thrusts or a saucer is out. AsteroidsSounds says what each one sounds like and AsteroidsCues says when each one happens. */
ENUM ProGriddle.Games.Asteroids.AsteroidsCue:

    DEFINE ENUM Fire = 1
                RockLarge
                RockMedium
                RockSmall
                ShipDies
                SaucerFire
                SaucerDies
                Hyperspace
                ExtraShip
                ThrustLoop
                SaucerLargeHum
                SaucerSmallHum.

END ENUM.
