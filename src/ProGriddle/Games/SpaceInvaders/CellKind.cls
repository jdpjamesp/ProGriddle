/* What is in a cell of the "kind" layer of a Space Invaders grid. The kind decides what a shot or a bomb hits: a cell has a colour (the "view" layer), but the colour says nothing about the rules. A cell holds INTEGER(CellKind:Alien) and so on; None is empty space.

     Fx is for things that are only to look at: explosions, score pop-ups, text */
ENUM ProGriddle.Games.SpaceInvaders.CellKind:

    DEFINE ENUM None = 0
                Shield
                Alien
                Bomb
                Saucer
                Player
                Shot
                Fx.

END ENUM.
