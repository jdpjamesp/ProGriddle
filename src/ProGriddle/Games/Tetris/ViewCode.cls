/* What the "view" layer of a Tetris grid holds for each cell: one number that says what to draw, kept up to date by the game after every change. A cell of a piece, settled or falling, is the number of the piece (1 to 7: I, O, T, S, Z, J, L), so the colours follow the piece. The grid is the board on the left (columns 0 to width - 1), one divider column, then a panel six cells wide that shows the next piece. A cell holds INTEGER(ViewCode:Ghost) and so on. */
ENUM ProGriddle.Games.Tetris.ViewCode:

    DEFINE ENUM Empty = 0
                PieceI = 1
                PieceO = 2
                PieceT = 3
                PieceS = 4
                PieceZ = 5
                PieceJ = 6
                PieceL = 7
                Ghost
                Divider
                Panel.

END ENUM.
