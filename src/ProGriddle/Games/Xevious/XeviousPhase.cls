/* The phases a Xevious game goes through, as the values of XeviousGame:Phase.

     Title      the attract screen, waiting for the fire key
     Playing    the game proper
     Dying      the ship has been hit and is breaking up: everything stands still
     StageClear the stage is done: the bonus for the ground targets destroyed is counted, then the next stage starts
     GameOver   the ships are gone: waits for the fire key and returns to Title */
ENUM ProGriddle.Games.Xevious.XeviousPhase:

    DEFINE ENUM Title = 0
                Playing
                Dying
                StageClear
                GameOver.

END ENUM.
