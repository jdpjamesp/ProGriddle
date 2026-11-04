/* What a phantom is doing.

     Waiting      in the lobby, until it is let out
     Leaving      going to the middle of the lobby and up through the door
     Scatter      heading for its own corner outside the maze
     Chase        hunting Dibby by its own rule
     RolledBack   slow, random and good to eat, after a commit token
     Returning    eaten: running home to the lobby at speed, harmless */
ENUM ProGriddle.Games.ForEach.PhantomMode:

    DEFINE ENUM Waiting = 1
                Leaving
                Scatter
                Chase
                RolledBack
                Returning.

END ENUM.
