/* How an attack on goal ended: Goal (the ball went in), Saved (it ran into the keeper), Blocked (a defender turned it back) or Wide (it left the pitch without going in or meeting anyone). */
ENUM ProGriddle.Games.FootballManager.AttackOutcome:

    DEFINE ENUM Goal = 1
                Saved
                Blocked
                Wide.

END ENUM.
