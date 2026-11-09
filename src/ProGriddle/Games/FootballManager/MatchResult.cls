/* What happened in a match: its attacks in the order they were played (each kept so that it can be replayed as a highlight) and the score. Team 1 is the home side, team 2 the away side. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchResult FINAL:

    VAR PRIVATE PitchAttack[22] mAttacks.
    VAR PRIVATE INTEGER[2] mGoals.

    /* How many attacks there were. */
    DEFINE PUBLIC PROPERTY AttackCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HomeGoals AS INTEGER NO-UNDO
        GET():
            RETURN mGoals[1].
        END GET.

    DEFINE PUBLIC PROPERTY AwayGoals AS INTEGER NO-UNDO
        GET():
            RETURN mGoals[2].
        END GET.

    CONSTRUCTOR PUBLIC MatchResult():
        VAR INTEGER i.
        DO i = 1 TO FootballRules:MostAttacks():
            mAttacks[i] = NEW PitchAttack().
        END.
    END CONSTRUCTOR.

    /* Plays the next attack for piTeam (1 home, 2 away) with the random numbers given, and scores it if it is a goal. Throws GridException when the match already holds the most attacks it can. */
    METHOD PUBLIC VOID AddAttack(INPUT piTeam AS INTEGER, INPUT poRandom AS IRandom):
        IF AttackCount >= FootballRules:MostAttacks() THEN UNDO, THROW NEW GridException("A match has at most " + STRING(FootballRules:MostAttacks()) + " attacks").
        mAttacks[AttackCount + 1]:Run(piTeam, poRandom).
        AttackCount = AttackCount + 1.
        IF mAttacks[AttackCount]:Scored THEN mGoals[piTeam] = mGoals[piTeam] + 1.
    END METHOD.

    /* An attack of the match, from 1 to AttackCount. */
    METHOD PUBLIC PitchAttack AttackAt(INPUT piAttack AS INTEGER):
        IF piAttack = ? OR piAttack < 1 OR piAttack > AttackCount THEN
            UNDO, THROW NEW GridException("The match had attacks 1 to " + STRING(AttackCount) + ", not " + STRING(piAttack)).
        RETURN mAttacks[piAttack].
    END METHOD.

    /* The goals of a team (1 home, 2 away). */
    METHOD PUBLIC INTEGER GoalsOf(INPUT piTeam AS INTEGER):
        IF piTeam <> 1 AND piTeam <> 2 THEN UNDO, THROW NEW GridException("A team is 1 (home) or 2 (away), not " + STRING(piTeam)).
        RETURN mGoals[piTeam].
    END METHOD.

END CLASS.
