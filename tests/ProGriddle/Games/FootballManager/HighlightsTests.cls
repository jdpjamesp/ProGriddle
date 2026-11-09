/* The timeline of a match's highlights: how long each kind of attack takes, which attack a time falls in and when a goal shows in the score. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.HighlightsTests:

    VAR PRIVATE MatchResult mResult.

    /* The scripted attacks of PitchAttackTests: a goal (one dribbled cell) and the save from column 31. */
    METHOD PRIVATE CHARACTER GoalScript():
        RETURN "6,4,0,9,17,11,2,9,11,7,14,6,6,0".
    END METHOD.

    METHOD PRIVATE CHARACTER SaveScript():
        RETURN "6,5,0,9,17,11,2,9,11,7,14,6,6,0".
    END METHOD.

    /* A goal for the away side, then a save for the home side. */
    @Setup.
    METHOD PUBLIC VOID BuildResult():
        mResult = NEW MatchResult().
        mResult:AddAttack(2, NEW ScriptedRandom(GoalScript())).
        mResult:AddAttack(1, NEW ScriptedRandom(SaveScript())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimingsAreThoseOfTheDesign():
        Assert:Equals(160, Highlights:DribbleMs()).
        Assert:Equals(200, Highlights:ShotMs()).
        Assert:Equals(60, Highlights:RunOnMs()).
        Assert:Equals(300, Highlights:BlockMs()).
        Assert:Equals(300, Highlights:ReadyMs()).
        Assert:Equals(240, Highlights:FlightMs()).
        Assert:Equals(900, Highlights:ResultMs()).
        Assert:Equals(1200, Highlights:CheerMs()).
        Assert:Equals(200, Highlights:PauseMs()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGoalTakesTheCloseUpAndTheCheeringAndASaveDoesNot():
        /* 160 dribble + 200 shot + 300 + 240 + 900 + 1200 + 200 pause */
        Assert:Equals(3200, Highlights:AttackMs(mResult:AttackAt(1))).
        /* the same without the cheering */
        Assert:Equals(2000, Highlights:AttackMs(mResult:AttackAt(2))).
        Assert:Equals(5200, Highlights:TotalMs(mResult)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlockedAttackRunsTheBallOnAndShowsTheBlockWithNoCloseUp():
        VAR INTEGER seed.
        VAR PitchAttack attack = NEW PitchAttack().
        VAR LOGICAL found.
        DO seed = 1 TO 400:
            attack:Run(1, NEW SeededRandom(seed)).
            IF attack:Outcome = AttackOutcome:Blocked THEN
            DO:
                found = TRUE.
                Assert:Equals(attack:DribbleSteps * 160 + 200 + (attack:PathLength - 1) * 60 + 300 + 200, Highlights:AttackMs(attack)).
                LEAVE.
            END.
        END.
        Assert:IsTrue(found).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATimeFallsInTheAttackWhoseSpanItIsIn():
        Assert:Equals(1, Highlights:AttackAtMs(mResult, 0)).
        Assert:Equals(1, Highlights:AttackAtMs(mResult, 3199)).
        Assert:Equals(2, Highlights:AttackAtMs(mResult, 3200)).
        Assert:Equals(2, Highlights:AttackAtMs(mResult, 5199)).
        Assert:Equals(0, Highlights:AttackAtMs(mResult, 5200)).
        Assert:Equals(0, Highlights:AttackAtMs(mResult, 99999)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLocalTimeIsTheTimeSinceTheStartOfThatAttack():
        Assert:Equals(0, Highlights:LocalMs(mResult, 0)).
        Assert:Equals(50, Highlights:LocalMs(mResult, 3250)).
        Assert:Equals(1999, Highlights:LocalMs(mResult, 5199)).
        Assert:Equals(0, Highlights:LocalMs(mResult, 5200)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGoalShowsInTheScoreOnceTheBallIsInTheNet():
        /* 160 + 200 + 300 + 240: the ball arrives at 900 ms */
        Assert:Equals(0, Highlights:GoalsAtMs(mResult, 899, 2)).
        Assert:Equals(1, Highlights:GoalsAtMs(mResult, 900, 2)).
        Assert:Equals(1, Highlights:GoalsAtMs(mResult, 99999, 2)).
        Assert:Equals(0, Highlights:GoalsAtMs(mResult, 99999, 1)).
    END METHOD.

END CLASS.
