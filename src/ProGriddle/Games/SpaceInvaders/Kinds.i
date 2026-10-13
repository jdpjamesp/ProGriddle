/* What is in a cell of the "kind" layer of a Space Invaders grid. The kind decides what a shot or a
   bomb hits: a cell has a colour (the "view" layer), but the colour says nothing about the rules.
   0 is empty space. */
&GLOBAL-DEFINE KIND-NONE 0
&GLOBAL-DEFINE KIND-SHIELD 1
&GLOBAL-DEFINE KIND-ALIEN 2
&GLOBAL-DEFINE KIND-BOMB 3
&GLOBAL-DEFINE KIND-SAUCER 4
&GLOBAL-DEFINE KIND-PLAYER 5
&GLOBAL-DEFINE KIND-SHOT 6
/* things that are only to look at: explosions, score pop-ups, text */
&GLOBAL-DEFINE KIND-FX 7
