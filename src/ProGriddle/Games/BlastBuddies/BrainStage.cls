/* What the computer player is doing in its turn: Idle before it starts, Thinking while it tries shots, then Walking to its place, Aiming,
   Charging the shot, and Done once it has fired. */
ENUM ProGriddle.Games.BlastBuddies.BrainStage:

    DEFINE ENUM Idle = 0
                Thinking
                Walking
                Aiming
                Charging
                Done.

END ENUM.
