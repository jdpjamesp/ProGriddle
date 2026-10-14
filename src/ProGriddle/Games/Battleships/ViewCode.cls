/* What the "view" layer of a Battleships grid holds for each cell: one number that says what to draw, kept up to date by the game after every move. The grid holds both boards side by side: the computer's waters on the left (the enemy side, which the player shoots at), one divider column, then the player's own fleet on the right. A cell holds INTEGER(ViewCode:EnemyHit) and so on. */
ENUM ProGriddle.Games.Battleships.ViewCode:

    DEFINE ENUM EnemyHidden = 0
                EnemyMark
                EnemyMiss
                EnemyHit
                EnemySunk
                EnemyShip
                OwnWater
                OwnShip
                OwnHit
                OwnSunk
                OwnMiss
                OwnLastMiss
                OwnLastHit
                Divider.

END ENUM.
