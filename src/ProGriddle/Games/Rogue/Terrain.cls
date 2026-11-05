/* What a cell of the map is made of, as stored in the terrain layer. SecretAcross and SecretDown are doors that look like wall until they are found (searching turns them into Door). */
ENUM ProGriddle.Games.Rogue.Terrain:

    DEFINE ENUM Rock = 0
                Floor
                WallAcross
                WallDown
                CornerTopLeft
                CornerTopRight
                CornerBottomLeft
                CornerBottomRight
                Door
                SecretAcross
                SecretDown
                Passage
                Stairs.

END ENUM.
