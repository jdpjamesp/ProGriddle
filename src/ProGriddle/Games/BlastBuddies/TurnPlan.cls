/* The order of play in Blast Buddies: the teams take turns in order, skipping any team that has no living buddy, and each team plays
   its own buddies in rota (see Team). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.TurnPlan FINAL:

    DEFINE PRIVATE VARIABLE mTeams AS Team    NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mCount AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLast  AS INTEGER NO-UNDO.

    /* Adds a team to the end of the order. */
    METHOD PUBLIC VOID Add(INPUT poTeam AS Team):
        IF NOT VALID-OBJECT(poTeam) THEN UNDO, THROW NEW GridException("A plan needs a team to add").
        IF mCount = 4 THEN UNDO, THROW NEW GridException("A plan holds 4 teams").
        mCount = mCount + 1.
        mTeams[mCount] = poTeam.
    END METHOD.

    /* How many teams are in the plan. */
    METHOD PUBLIC INTEGER TeamCount():
        RETURN mCount.
    END METHOD.

    /* A team, 1 to TeamCount(), in the order of play. */
    METHOD PUBLIC Team TeamAt(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mCount THEN UNDO, THROW NEW GridException("There is no team " + STRING(piIndex) + " in the plan").
        RETURN mTeams[piIndex].
    END METHOD.

    /* How many teams still have a living buddy. */
    METHOD PUBLIC INTEGER TeamsAlive():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO mCount:
            IF mTeams[i]:AliveCount() > 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The buddy whose turn is next, from the next team that has one alive. Unknown when nobody is alive. */
    METHOD PUBLIC Buddy NextBuddy():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS Buddy   NO-UNDO.
        DO i = 1 TO mCount:
            k = ((mLast + i - 1) MODULO mCount) + 1.
            b = mTeams[k]:NextBuddy().
            IF VALID-OBJECT(b) THEN DO:
                mLast = k.
                RETURN b.
            END.
        END.
        RETURN ?.
    END METHOD.

END CLASS.
