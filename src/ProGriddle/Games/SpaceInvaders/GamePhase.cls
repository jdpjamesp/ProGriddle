/* The phases a Space Invaders game goes through, as the values of SpaceInvadersGame:Phase.

     Title     the attract screen, waiting for the fire key
     Starting  a new wave: the rack draws itself in, one invader a frame, and nothing can be fired yet
     Playing   the game proper
     Dying     the cannon has been hit and is blowing up: the invaders stand still
     Cleared   every invader is dead: a short pause, then the next wave
     GameOver  the lives are gone, or the invaders have landed: waits for the fire key and returns to Title */
ENUM ProGriddle.Games.SpaceInvaders.GamePhase:

    DEFINE ENUM Title = 0
                Starting
                Playing
                Dying
                Cleared
                GameOver.

END ENUM.
