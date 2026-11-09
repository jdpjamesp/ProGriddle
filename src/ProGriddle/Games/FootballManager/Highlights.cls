/* The timeline of a match's highlights, in milliseconds from the start, worked out from the attacks alone so that the picture is a function of the clock and a test sees the same picture for the same time. Each attack runs:

     the dribble        160 ms for each cell the attacker carries the ball
     the shot           200 ms (two kick frames)
     then the ball runs along its path across the pitch, 60 ms a point (for a save only as far as the keeper)
     then, if a defender turned the ball back (Blocked): the block is shown for 300 ms
     otherwise the close up of the goal mouth: 300 ms ready, 240 ms for the ball's flight, 900 ms for the result, and after a goal
     another 1200 ms of cheering
     a pause of 200 ms before the next attack

   (section 7.2 of docs/design/footballmanager-art.md). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Highlights FINAL:

    /* Milliseconds for each cell dribbled, for the shot, for the ball to run on from a block, for the block to show, for the close up's ready, flight and result, for the cheering after a goal, and between attacks. */
    METHOD PUBLIC STATIC INTEGER DribbleMs():
        RETURN 160.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ShotMs():
        RETURN 200.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RunOnMs():
        RETURN 60.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BlockMs():
        RETURN 300.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ReadyMs():
        RETURN 300.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FlightMs():
        RETURN 240.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ResultMs():
        RETURN 900.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER CheerMs():
        RETURN 1200.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PauseMs():
        RETURN 200.
    END METHOD.

    /* How long the ball takes to cross the pitch after the shot: 60 ms for each point of its flight after the first. */
    METHOD PUBLIC STATIC INTEGER RunMs(INPUT poAttack AS PitchAttack):
        RETURN (poAttack:FlightPoints - 1) * RunOnMs().
    END METHOD.

    /* When the ball is in the net, in milliseconds from the start of the attack (for a goal). */
    METHOD PUBLIC STATIC INTEGER GoalAtMs(INPUT poAttack AS PitchAttack):
        RETURN poAttack:DribbleSteps * DribbleMs() + ShotMs() + RunMs(poAttack) + ReadyMs() + FlightMs().
    END METHOD.

    /* How long an attack takes, with the pause after it. */
    METHOD PUBLIC STATIC INTEGER AttackMs(INPUT poAttack AS PitchAttack):
        VAR INTEGER ms.
        ms = poAttack:DribbleSteps * DribbleMs() + ShotMs() + RunMs(poAttack).
        IF poAttack:Outcome = AttackOutcome:Blocked THEN ms = ms + BlockMs().
        ELSE
        DO:
            ms = ms + ReadyMs() + FlightMs() + ResultMs().
            IF poAttack:Outcome = AttackOutcome:Goal THEN ms = ms + CheerMs().
        END.
        RETURN ms + PauseMs().
    END METHOD.

    /* How long all the highlights of a match take. */
    METHOD PUBLIC STATIC INTEGER TotalMs(INPUT poResult AS MatchResult):
        VAR INTEGER a.
        VAR INTEGER total.
        DO a = 1 TO poResult:AttackCount:
            total = total + AttackMs(poResult:AttackAt(a)).
        END.
        RETURN total.
    END METHOD.

    /* The attack being shown at a time (1 to the number of attacks), or 0 when the time is past the last. */
    METHOD PUBLIC STATIC INTEGER AttackAtMs(INPUT poResult AS MatchResult, INPUT piMs AS INTEGER):
        VAR INTEGER a.
        VAR INTEGER remaining.
        remaining = piMs.
        DO a = 1 TO poResult:AttackCount:
            IF remaining < AttackMs(poResult:AttackAt(a)) THEN RETURN a.
            remaining = remaining - AttackMs(poResult:AttackAt(a)).
        END.
        RETURN 0.
    END METHOD.

    /* The time since the start of the attack that is being shown at a time (0 past the last attack). */
    METHOD PUBLIC STATIC INTEGER LocalMs(INPUT poResult AS MatchResult, INPUT piMs AS INTEGER):
        VAR INTEGER a.
        VAR INTEGER remaining.
        remaining = piMs.
        DO a = 1 TO poResult:AttackCount:
            IF remaining < AttackMs(poResult:AttackAt(a)) THEN RETURN remaining.
            remaining = remaining - AttackMs(poResult:AttackAt(a)).
        END.
        RETURN 0.
    END METHOD.

    /* The score at a time, as it shows in the score bar: the goals of the attacks whose result has been shown (a goal counts from the moment the ball is in the net). team 1 is the home side. */
    METHOD PUBLIC STATIC INTEGER GoalsAtMs(INPUT poResult AS MatchResult, INPUT piMs AS INTEGER, INPUT piTeam AS INTEGER):
        VAR INTEGER a.
        VAR INTEGER remaining.
        VAR INTEGER goals.
        VAR PitchAttack attack.
        remaining = piMs.
        DO a = 1 TO poResult:AttackCount:
            attack = poResult:AttackAt(a).
            IF attack:Scored AND attack:Team = piTeam AND remaining >= GoalAtMs(attack) THEN goals = goals + 1.
            IF remaining < AttackMs(attack) THEN RETURN goals.
            remaining = remaining - AttackMs(attack).
        END.
        RETURN goals.
    END METHOD.

END CLASS.
