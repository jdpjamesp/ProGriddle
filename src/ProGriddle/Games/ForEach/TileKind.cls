/* What a tile of the maze is.

     Wall     nothing can enter
     Path     an empty lane
     Bit      a lane with a bit of data on it (10 points)
     Commit   a lane with a commit token on it (50 points, rolls the phantoms back)
     Door     the door of the lobby, which only phantoms can use
     Lobby    the floor inside the lobby, which only phantoms can enter */
ENUM ProGriddle.Games.ForEach.TileKind:

    DEFINE ENUM Wall = 1
                Path
                Bit
                Commit
                Door
                Lobby.

END ENUM.
