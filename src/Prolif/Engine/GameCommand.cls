/* Things a player can ask for. Key and mouse input is translated into these. The names
   PauseGame and UndoMove avoid the ABL reserved words PAUSE and UNDO. */
ENUM Prolif.Engine.GameCommand:

    DEFINE ENUM Start
                PauseGame
                StepOnce
                Reset
                SpeedUp
                SlowDown
                UndoMove.

END ENUM.
