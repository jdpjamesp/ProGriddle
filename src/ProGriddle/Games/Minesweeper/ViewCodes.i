/* What the "view" layer of a Minesweeper board holds for each cell: one number that says what
   to draw, kept up to date by the game after every move. The renderer turns it into a colour
   and a glyph, so it never needs to know the rules. An open cell is 3 plus the number of mines
   around it, so 3 is a blank open cell and 4 to 11 show the digits 1 to 8. */
&GLOBAL-DEFINE VIEW-HIDDEN 0
&GLOBAL-DEFINE VIEW-FLAG 1
&GLOBAL-DEFINE VIEW-QUESTION 2
&GLOBAL-DEFINE VIEW-OPEN 3
&GLOBAL-DEFINE VIEW-MINE 12
&GLOBAL-DEFINE VIEW-EXPLODED 13
&GLOBAL-DEFINE VIEW-WRONG-FLAG 14
