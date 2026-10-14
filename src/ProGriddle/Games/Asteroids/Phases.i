/* The phases an Asteroids game goes through, as the numbers of AsteroidsGame:Phase.

     TITLE     the attract screen, rocks drifting behind the name, waiting for the fire key
     PLAYING   the game proper: a wave starts, the ship flies, and when the last rock is gone the next wave comes
     GAMEOVER  the lives are gone and the last ship has broken up: waits for the fire key and returns to TITLE */
&GLOBAL-DEFINE PHASE-TITLE 0
&GLOBAL-DEFINE PHASE-PLAYING 1
&GLOBAL-DEFINE PHASE-GAMEOVER 2
