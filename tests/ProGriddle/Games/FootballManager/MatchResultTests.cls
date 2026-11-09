/* What a match keeps: its attacks in order, the goals of each side, and the limit on how many attacks it can hold. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchResultTests:

    VAR PRIVATE MatchResult mResult.

    @Setup.
    METHOD PUBLIC VOID BuildResult():
        mResult = NEW MatchResult().
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        VAR INTEGER i.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "attack0" THEN mResult:AttackAt(0).
                WHEN "attack1" THEN mResult:AttackAt(1).
                WHEN "goals0" THEN mResult:GoalsOf(0).
                WHEN "goals3" THEN mResult:GoalsOf(3).
                WHEN "full" THEN
                DO i = 1 TO 23:
                    mResult:AddAttack(1, NEW ScriptedRandom("0")).
                END.
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewResultHasNoAttacksAndNoGoals():
        Assert:Equals(0, mResult:AttackCount).
        Assert:Equals(0, mResult:HomeGoals).
        Assert:Equals(0, mResult:AwayGoals).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAttackIsKeptInOrderAndAGoalCountsForItsTeam():
        /* the scripted attack of PitchAttackTests, a goal for the away side, then the same from the home side */
        mResult:AddAttack(2, NEW ScriptedRandom("6,4,0,9,17,11,2,9,11,7,14,6,6,0")).
        Assert:Equals(1, mResult:AttackCount).
        Assert:Equals(0, mResult:HomeGoals).
        Assert:Equals(1, mResult:AwayGoals).
        mResult:AddAttack(1, NEW ScriptedRandom("6,4,0,9,17,11,2,9,11,7,14,6,6,0")).
        Assert:Equals(2, mResult:AttackCount).
        Assert:Equals(1, mResult:HomeGoals).
        Assert:Equals(1, mResult:GoalsOf(1)).
        Assert:Equals(1, mResult:GoalsOf(2)).
        Assert:Equals(2, mResult:AttackAt(1):Team).
        Assert:Equals(1, mResult:AttackAt(2):Team).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASavedAttackScoresNothing():
        mResult:AddAttack(2, NEW ScriptedRandom("6,5,0,9,17,11,2,9,11,7,14,6,6,0")).
        Assert:Equals(0, mResult:AwayGoals).
        Assert:Equals(INTEGER(AttackOutcome:Saved), INTEGER(mResult:AttackAt(1):Outcome)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMatchHoldsNoMoreThanTwentyTwoAttacks():
        Assert:IsTrue(Refused("full")).
        Assert:Equals(22, mResult:AttackCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAttackOrATeamThatIsNotThereIsRefused():
        Assert:IsTrue(Refused("attack0")).
        Assert:IsTrue(Refused("attack1")).
        Assert:IsTrue(Refused("goals0")).
        Assert:IsTrue(Refused("goals3")).
    END METHOD.

END CLASS.
