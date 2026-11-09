/* The numbers of FootballManager that more than one class needs: the size of the league, the squad, the money, the odds. They are the numbers of the original game (see docs/design/footballmanager-rules.md). Everything here is a plain quantity. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballRules FINAL:

    /* Four divisions of 16 clubs, 64 in all. */
    METHOD PUBLIC STATIC INTEGER Divisions():
        RETURN 4.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ClubsPerDivision():
        RETURN 16.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ClubCount():
        RETURN 64.
    END METHOD.

    /* A season is 15 league matches (each other club once) and the cup, which has 8 rounds, the 7th the semi-final and the 8th the final. */
    METHOD PUBLIC STATIC INTEGER LeagueMatches():
        RETURN 15.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER CupRounds():
        RETURN 8.
    END METHOD.

    /* The pool of 24 named players, the most a club may hold (16), the most who play (11) and how many the club starts with (12: eleven starters and a reserve). */
    METHOD PUBLIC STATIC INTEGER PoolSize():
        RETURN 24.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER SquadMax():
        RETURN 16.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER TeamSize():
        RETURN 11.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StartingSquad():
        RETURN 12.
    END METHOD.

    /* The skill levels (1 to 7: Beginner to Genius). */
    METHOD PUBLIC STATIC INTEGER LevelCount():
        RETURN 7.
    END METHOD.

    /* Skill runs 1 to 5 and the team's five numbers (Energy, Morale, Defence, Midfield, Attack) and a player's energy run 1 to 20. */
    METHOD PUBLIC STATIC INTEGER MaxSkill():
        RETURN 5.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MaxEnergy():
        RETURN 20.
    END METHOD.

    /* Morale starts each season at 10. */
    METHOD PUBLIC STATIC INTEGER StartMorale():
        RETURN 10.
    END METHOD.

    /* A rested player gains 10 energy for a match, one who plays loses 1. One player in 20 is injured by each match. */
    METHOD PUBLIC STATIC INTEGER RestEnergy():
        RETURN 10.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER InjuryOdds():
        RETURN 20.
    END METHOD.

    /* The league points for a win and a draw. */
    METHOD PUBLIC STATIC INTEGER WinPoints():
        RETURN 3.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER DrawPoints():
        RETURN 1.
    END METHOD.

    /* The top three of a division go up and the bottom three go down. */
    METHOD PUBLIC STATIC INTEGER MovingClubs():
        RETURN 3.
    END METHOD.

    /* A chance of an attack: the roll of 1 to 100 plus 5 for every point the team's number is above the other side's must reach 75. */
    METHOD PUBLIC STATIC INTEGER AttackThreshold():
        RETURN 75.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER AttackWeight():
        RETURN 5.
    END METHOD.

    /* Money is scaled by the division: 1 in the fourth up to 4 in the first. The unit of a player's value, and so of the season prize. */
    METHOD PUBLIC STATIC INTEGER ValueUnit():
        RETURN 5000.
    END METHOD.

    /* A week's wage for each point of skill, and the ground rent, each times the division's number. */
    METHOD PUBLIC STATIC INTEGER WageUnit():
        RETURN 100.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RentUnit():
        RETURN 500.
    END METHOD.

    /* The home gate starts a season at 5000 and moves a tenth of the way toward 10000 for a win or a tenth down for a defeat (never under 1000), each times the division's number. */
    METHOD PUBLIC STATIC INTEGER GateUnit():
        RETURN 5000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GateCeilingUnit():
        RETURN 10000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GateFloor():
        RETURN 1000.
    END METHOD.

    /* An away league gate pays 500 for each place the other club is above the bottom of the table plus one, an away cup gate 10000 for each division below the fifth. */
    METHOD PUBLIC STATIC INTEGER AwayGateUnit():
        RETURN 500.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER CupAwayUnit():
        RETURN 10000.
    END METHOD.

    /* The semi-final and the final pay the same at home and away. */
    METHOD PUBLIC STATIC INTEGER SemiFinalGate():
        RETURN 50000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FinalGate():
        RETURN 100000.
    END METHOD.

    /* The bank will lend up to 250000 times the division's number. Interest is a hundredth of the loan a week. */
    METHOD PUBLIC STATIC INTEGER LoanUnit():
        RETURN 250000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER InterestDivisor():
        RETURN 100.
    END METHOD.

    /* The pitch is 32 columns by 22 rows of cells. A ball that has not left it after MaxBallSteps steps is counted as out, so that an attack always ends. */
    METHOD PUBLIC STATIC INTEGER PitchWidth():
        RETURN 32.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PitchHeight():
        RETURN 22.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MaxBallSteps():
        RETURN 40.
    END METHOD.

    /* The most tries to find a free cell for a player on the pitch before the last try is used as it is. */
    METHOD PUBLIC STATIC INTEGER SetupTries():
        RETURN 100.
    END METHOD.

    /* The most attacks a match can hold: two for each of the five numbers of each side, and one more each when it is still 0 to 0 after those. */
    METHOD PUBLIC STATIC INTEGER MostAttacks():
        RETURN 22.
    END METHOD.

END CLASS.
