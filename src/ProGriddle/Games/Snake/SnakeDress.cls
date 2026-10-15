/* The colours the snake can be drawn in: its own (Normal), white for a flash, the brighter body of the wave that runs down it
   when it eats (Bright), the five steps of the fade of a crash (Crash1 to Crash5, in order) and gold for the wave of a win. */
ENUM ProGriddle.Games.Snake.SnakeDress:

    DEFINE ENUM Normal = 0
                Flash
                Bright
                Crash1
                Crash2
                Crash3
                Crash4
                Crash5
                Gold.

END ENUM.
