/* What the "view" layer of a Minesweeper board holds for each cell: one number that says what to draw, kept up to date by the game after every move. The renderer turns it into a colour and a glyph, so it never needs to know the rules. An open cell is INTEGER(ViewCode:Open) plus the number of mines around it, so Open is a blank open cell and the next eight numbers show the digits 1 to 8. */
ENUM ProGriddle.Games.Minesweeper.ViewCode:

    DEFINE ENUM Hidden = 0
                Flag
                Question
                Open
                Mine = 12
                Exploded
                WrongFlag.

END ENUM.
