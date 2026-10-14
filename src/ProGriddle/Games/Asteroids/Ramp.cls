/* A run of colours that something steps through as it fades. AsteroidsLook:RampColour(ramp, step) gives the colour of a step, counting from 0.

     Exhaust      4 steps, the flame's trail
     RockDebris   6 steps
     Ember        6 steps, the large saucer's debris
     Red          6 steps, the small saucer's debris
     ShipDebris   6 steps
     Spark        4 steps, white then the three shot trail colours: rings and sparks
     SparkIn      4 steps, the spark colours the other way round (the ring that closes in on a ship coming back)
     Warm         3 steps, the first three ember colours (the extra ring of a failed jump)
     Muzzle       3 steps, white and the first two shot trail colours (the spark at the nose when the ship fires) */
ENUM ProGriddle.Games.Asteroids.Ramp:

    DEFINE ENUM Exhaust = 0
                RockDebris
                Ember
                Red
                ShipDebris
                Spark
                SparkIn
                Warm
                Muzzle.

END ENUM.
