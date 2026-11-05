/* What the game is waiting for: Play (a command), PickItem (a pack letter for the action being done), PickDirection (a direction for it), Overlay (any key closes the screen on show), Over (the hero is dead or has won), Confirm (a yes or no, for giving up). */
ENUM ProGriddle.Games.Rogue.RogueMode:

    DEFINE ENUM Play = 0
                PickItem
                PickDirection
                Overlay
                Over
                Confirm.

END ENUM.
