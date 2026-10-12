/* What the "view" layer of a Battleships grid holds for each cell: one number that says what to
   draw, kept up to date by the game after every move. The grid holds both boards side by side:
   the computer's waters on the left (the enemy side, which the player shoots at) then one
   divider column, then the player's own fleet on the right. */

/* the enemy side: what the player knows about the computer's waters */
&GLOBAL-DEFINE VIEW-E-HIDDEN 0
&GLOBAL-DEFINE VIEW-E-MARK 1
&GLOBAL-DEFINE VIEW-E-MISS 2
&GLOBAL-DEFINE VIEW-E-HIT 3
&GLOBAL-DEFINE VIEW-E-SUNK 4
&GLOBAL-DEFINE VIEW-E-SHIP 5

/* the player's own side */
&GLOBAL-DEFINE VIEW-O-WATER 6
&GLOBAL-DEFINE VIEW-O-SHIP 7
&GLOBAL-DEFINE VIEW-O-HIT 8
&GLOBAL-DEFINE VIEW-O-SUNK 9
&GLOBAL-DEFINE VIEW-O-MISS 10
&GLOBAL-DEFINE VIEW-O-LAST-MISS 11
&GLOBAL-DEFINE VIEW-O-LAST-HIT 12

/* the column between the two boards */
&GLOBAL-DEFINE VIEW-DIVIDER 13
