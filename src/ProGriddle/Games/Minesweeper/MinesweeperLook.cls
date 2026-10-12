/* How a Minesweeper board is drawn: a colour and a glyph for each value of the "view" layer
   (see ViewCodes.i). The lists are in view code order, 0 to 14, so a window gives them straight
   to its view. The look is a dark board with raised looking hidden cells, and the classic
   number colours (1 blue, 2 green, 3 red, 4 dark blue, 5 maroon, 6 teal, 7 black, 8 grey)
   brightened so they read on a dark background. */
USING Progress.Lang.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperLook FINAL:

    /* Cell colours: hidden, flag and question share one, open cells another, then the
       revealed mine, the exploded mine and the wrongly flagged cell. */
    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "3E4C61,3E4C61,3E4C61,161A20,161A20,161A20,161A20,161A20,161A20,161A20,161A20,161A20,4A2328,B3261E,4A2328".
    END METHOD.

    /* Glyphs: a flag, a question mark, the digits 1 to 8, and a mine for a revealed or
       exploded mine, a cross for a wrong flag. U+2691 is a flag, U+2739 a burst and U+2716 a cross. */
    METHOD PUBLIC STATIC CHARACTER Glyphs():
        RETURN ",U+2691,?,,1,2,3,4,5,6,7,8,U+2739,U+2739,U+2716".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER GlyphColors():
        RETURN "FFFFFF,FF8A5B,C9D1DB,FFFFFF,5B9DFF,4CC38A,FF6B6B,9B8CFF,FF9F5B,3CC9D6,E6E6E6,9AA4AF,E6E9EE,FFFFFF,FF6B6B".
    END METHOD.

    /* One character per view code, for drawing a board as text in tests: # hidden, F flag,
       ? question, . blank open cell, 1 to 8, * mine, X exploded mine, ! wrong flag. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN "#F?.12345678*X!".
    END METHOD.

END CLASS.
