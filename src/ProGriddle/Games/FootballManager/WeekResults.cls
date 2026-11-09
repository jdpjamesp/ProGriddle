/* The results of the matches between the other clubs of the division in a league week (seven of them), as they are shown after the manager's own. Teams are numbered 1 to 16 in the division. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.WeekResults FINAL:

    VAR PRIVATE INTEGER[8] mTeamA.
    VAR PRIVATE INTEGER[8] mTeamB.
    VAR PRIVATE INTEGER[8] mGoalsA.
    VAR PRIVATE INTEGER[8] mGoalsB.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Adds a result: team A scored piGoalsA against team B's piGoalsB. Throws GridException for a team that is not 1 to 16 or when there are eight already. */
    METHOD PUBLIC VOID Add(INPUT piTeamA AS INTEGER, INPUT piGoalsA AS INTEGER, INPUT piTeamB AS INTEGER, INPUT piGoalsB AS INTEGER):
        IF Count >= 8 THEN UNDO, THROW NEW GridException("A week has at most 8 other results").
        IF piTeamA = ? OR piTeamA < 1 OR piTeamA > 16 OR piTeamB = ? OR piTeamB < 1 OR piTeamB > 16 THEN
            UNDO, THROW NEW GridException("A team is 1 to 16").
        Count = Count + 1.
        mTeamA[Count] = piTeamA.
        mTeamB[Count] = piTeamB.
        mGoalsA[Count] = piGoalsA.
        mGoalsB[Count] = piGoalsB.
    END METHOD.

    METHOD PRIVATE VOID CheckResult(INPUT piResult AS INTEGER):
        IF piResult = ? OR piResult < 1 OR piResult > Count THEN
            UNDO, THROW NEW GridException("There are results 1 to " + STRING(Count) + ", not " + STRING(piResult)).
    END METHOD.

    METHOD PUBLIC INTEGER TeamA(INPUT piResult AS INTEGER):
        CheckResult(piResult).
        RETURN mTeamA[piResult].
    END METHOD.

    METHOD PUBLIC INTEGER GoalsA(INPUT piResult AS INTEGER):
        CheckResult(piResult).
        RETURN mGoalsA[piResult].
    END METHOD.

    METHOD PUBLIC INTEGER TeamB(INPUT piResult AS INTEGER):
        CheckResult(piResult).
        RETURN mTeamB[piResult].
    END METHOD.

    METHOD PUBLIC INTEGER GoalsB(INPUT piResult AS INTEGER):
        CheckResult(piResult).
        RETURN mGoalsB[piResult].
    END METHOD.

END CLASS.
