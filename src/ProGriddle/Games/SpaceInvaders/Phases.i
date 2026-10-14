/* The phases a Space Invaders game goes through, as the numbers of SpaceInvadersGame:Phase.

     TITLE     the attract screen, waiting for the fire key
     STARTING  a new wave: the rack draws itself in, one invader a frame, and nothing can be fired yet
     PLAYING   the game proper
     DYING     the cannon has been hit and is blowing up: the invaders stand still
     CLEARED   every invader is dead: a short pause, then the next wave
     GAMEOVER  the lives are gone, or the invaders have landed: waits for the fire key and returns to TITLE */
&GLOBAL-DEFINE PHASE-TITLE 0
&GLOBAL-DEFINE PHASE-STARTING 1
&GLOBAL-DEFINE PHASE-PLAYING 2
&GLOBAL-DEFINE PHASE-DYING 3
&GLOBAL-DEFINE PHASE-CLEARED 4
&GLOBAL-DEFINE PHASE-GAMEOVER 5
