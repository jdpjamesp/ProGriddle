/* The results of the other clubs' matches in a league week: adding them, reading them back and the limits. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.WeekResultsTests:

    VAR PRIVATE WeekResults mResults.

    @Setup.
    METHOD PUBLIC VOID BuildResults():
        mResults = NEW WeekResults().
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        VAR INTEGER i.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "team0" THEN mResults:Add(0, 1, 2, 1).
                WHEN "team17" THEN mResults:Add(1, 1, 17, 1).
                WHEN "ninth" THEN
                DO i = 1 TO 9:
                    mResults:Add(1, 0, 2, 0).
                END.
                WHEN "teama" THEN mResults:TeamA(1).
                WHEN "goalsa" THEN mResults:GoalsA(0).
                WHEN "teamb" THEN mResults:TeamB(1).
                WHEN "goalsb" THEN mResults:GoalsB(0).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewSetOfResultsIsEmpty():
        Assert:Equals(0, mResults:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AResultCanBeReadBack():
        mResults:Add(3, 2, 9, 1).
        mResults:Add(4, 0, 5, 0).
        Assert:Equals(2, mResults:Count).
        Assert:Equals(3, mResults:TeamA(1)).
        Assert:Equals(2, mResults:GoalsA(1)).
        Assert:Equals(9, mResults:TeamB(1)).
        Assert:Equals(1, mResults:GoalsB(1)).
        Assert:Equals(4, mResults:TeamA(2)).
        Assert:Equals(5, mResults:TeamB(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TeamsMustBeInTheDivisionAndThereAreAtMostEightResults():
        Assert:IsTrue(Refused("team0")).
        Assert:IsTrue(Refused("team17")).
        Assert:IsTrue(Refused("ninth")).
        Assert:Equals(8, mResults:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AResultThatIsNotThereIsRefused():
        Assert:IsTrue(Refused("teama")).
        Assert:IsTrue(Refused("goalsa")).
        Assert:IsTrue(Refused("teamb")).
        Assert:IsTrue(Refused("goalsb")).
    END METHOD.

END CLASS.
