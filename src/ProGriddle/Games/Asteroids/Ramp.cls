/* A run of colours that something steps through as it fades. AsteroidsLook:RampColour(ramp, step) gives the colour of a step, counting from 0.

     Exhaust      4 steps, the flame's trail
     RockDebris   6 steps
     Ember        6 steps, the large saucer's debris
     Red          6 steps, the small saucer's debris
     ShipDebris   6 steps */
ENUM ProGriddle.Games.Asteroids.Ramp:

    DEFINE ENUM Exhaust = 0
                RockDebris
                Ember
                Red
                ShipDebris.

END ENUM.
