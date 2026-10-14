/* What the "view" layer of a Snake grid holds for each cell: one number that says what is there, kept up to date by the game after every step. A cell holds INTEGER(ViewCode:Head) and so on. */
ENUM ProGriddle.Games.Snake.ViewCode:

    DEFINE ENUM Empty = 0
                Body
                Head
                Food.

END ENUM.
