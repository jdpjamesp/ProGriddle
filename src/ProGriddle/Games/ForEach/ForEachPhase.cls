/* The phases a FOR EACH game goes through, as the values of ForEachGame:Phase.

     Title          the attract screen, waiting for a key
     Ready          the maze is up and READY! shows: nothing moves
     Playing        the game proper
     Caught         a phantom has caught Dibby: everything stands still for a moment
     Dying          Dibby crashes
     Cleared        the last bit is eaten: the maze flashes
     Intermission   a cartoon between some levels
     GameOver       the lives are gone */
ENUM ProGriddle.Games.ForEach.ForEachPhase:

    DEFINE ENUM Title = 1
                Ready
                Playing
                Caught
                Dying
                Cleared
                Intermission
                GameOver.

END ENUM.
