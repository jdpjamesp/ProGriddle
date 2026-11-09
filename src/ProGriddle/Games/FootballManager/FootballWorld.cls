/* All the state of a game of FootballManager: the manager, the 64 clubs in their slots, the pool of 24 players (what each is to the club, his skill, energy and value), the division's league table and the money. The rules are in static helper classes that work on one of these (TeamStrength, Opposition, Bank, Market, LeagueTable, MatchEngine), so a test builds any position by hand.

   Slots: 1 to 16 are the first division, 17 to 32 the second, 33 to 48 the third and 49 to 64 the fourth. The manager's club is in Slot. A club's place in its division's table is its index 1 to 16 (its slot minus DivisionBase). All the random numbers of a new game and a new season come from the random source given. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballWorld FINAL:

    VAR PRIVATE CHARACTER[64] mClub.
    VAR PRIVATE INTEGER[24] mRole.
    VAR PRIVATE INTEGER[24] mSkill.
    VAR PRIVATE INTEGER[24] mEnergy.
    VAR PRIVATE INTEGER[24] mWorth.
    VAR PRIVATE INTEGER[16] mPoints.
    VAR PRIVATE INTEGER[16] mFor.
    VAR PRIVATE INTEGER[16] mAgainst.
    VAR PRIVATE INTEGER[16] mPlace.
    VAR PRIVATE INTEGER[16] mOrder.

    DEFINE PUBLIC PROPERTY ManagerName AS CHARACTER NO-UNDO
        GET.
        SET.

    /* The skill level 1 to 7: it only changes the other clubs' numbers. */
    DEFINE PUBLIC PROPERTY Level AS INTEGER NO-UNDO
        GET.
        SET.

    /* The manager's kit: 0 (black) or 7 (white). The other side wears the other. */
    DEFINE PUBLIC PROPERTY KitColour AS INTEGER NO-UNDO
        GET.
        SET.

    /* The slot of the manager's club. */
    DEFINE PUBLIC PROPERTY Slot AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Cash AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Loan AS INTEGER NO-UNDO
        GET.
        SET.

    /* Cash minus loan when the last week's accounts were done, so the next report can say what changed. */
    DEFINE PUBLIC PROPERTY LastBalance AS INTEGER NO-UNDO
        GET.
        SET.

    /* The home gate (what a home league match brings in), which follows the results. */
    DEFINE PUBLIC PROPERTY Gate AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Rent AS INTEGER NO-UNDO
        GET.
        SET.

    /* The team's morale, 1 to 20. */
    DEFINE PUBLIC PROPERTY Morale AS INTEGER NO-UNDO
        GET.
        SET.

    /* The number of league matches played this season, 0 to 15. */
    DEFINE PUBLIC PROPERTY LeagueMatch AS INTEGER NO-UNDO
        GET.
        SET.

    /* The cup round last played, 0 before the first and up to 8. */
    DEFINE PUBLIC PROPERTY CupRound AS INTEGER NO-UNDO
        GET.
        SET.

    /* True once the club has been knocked out of the cup or has played the final. */
    DEFINE PUBLIC PROPERTY CupOver AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Counts the fixtures so that the third is a cup tie (1, 2, then 3 becomes 0: cup). */
    DEFINE PUBLIC PROPERTY Cycle AS INTEGER NO-UNDO
        GET.
        SET.

    /* Which side of the home and away alternation is next: 1 means the next league match is at home. */
    DEFINE PUBLIC PROPERTY NextHome AS INTEGER NO-UNDO
        GET.
        SET.

    /* The manager's score over the seasons played, and how many there have been. */
    DEFINE PUBLIC PROPERTY SeasonScore AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Seasons AS INTEGER NO-UNDO
        GET.
        SET.

    /* The manager's division, 1 (top) to 4. */
    DEFINE PUBLIC PROPERTY Division AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE((Slot - 1) / 16, 0)) + 1.
        END GET.

    /* The slot before the first of the manager's division: add a club's place (1 to 16) to get its slot. */
    DEFINE PUBLIC PROPERTY DivisionBase AS INTEGER NO-UNDO
        GET():
            RETURN (Division - 1) * 16.
        END GET.

    /* Money is scaled by this: 1 in the fourth division up to 4 in the first. */
    DEFINE PUBLIC PROPERTY Multiplier AS INTEGER NO-UNDO
        GET():
            RETURN 5 - Division.
        END GET.

    /* The manager's rating, the average season score doubled and at most 100 (0 before the first season ends). */
    DEFINE PUBLIC PROPERTY ManagerRating AS INTEGER NO-UNDO
        GET():
            IF Seasons < 1 THEN RETURN 0.
            RETURN MINIMUM(100, INTEGER(TRUNCATE(SeasonScore / Seasons, 0)) * 2).
        END GET.

    /* Names the 64 clubs of the original, each in its own slot. */
    CONSTRUCTOR PUBLIC FootballWorld():
        VAR INTEGER i.
        DO i = 1 TO 64:
            mClub[i] = FootballNames:Club(i).
        END.
        Slot = 64.
        Level = 1.
        KitColour = 0.
        ManagerName = "".
        Morale = FootballRules:StartMorale().
        NextHome = 2.
    END CONSTRUCTOR.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 1 OR piSlot > FootballRules:ClubCount() THEN
            UNDO, THROW NEW GridException("There is no club in slot " + STRING(piSlot)).
    END METHOD.

    METHOD PRIVATE VOID CheckPlayer(INPUT piPlayer AS INTEGER):
        IF piPlayer = ? OR piPlayer < 1 OR piPlayer > FootballRules:PoolSize() THEN
            UNDO, THROW NEW GridException("There is no player " + STRING(piPlayer)).
    END METHOD.

    METHOD PRIVATE VOID CheckTeam(INPUT piTeam AS INTEGER):
        IF piTeam = ? OR piTeam < 1 OR piTeam > FootballRules:ClubsPerDivision() THEN
            UNDO, THROW NEW GridException("There is no team " + STRING(piTeam) + " in a division").
    END METHOD.

    /* The name of the club in a slot (clubs move between slots when they are promoted or relegated). */
    METHOD PUBLIC CHARACTER ClubName(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mClub[piSlot].
    END METHOD.

    /* Swaps the clubs in two slots. */
    METHOD PUBLIC VOID SwapClubs(INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        VAR CHARACTER keep.
        CheckSlot(piA).
        CheckSlot(piB).
        keep = mClub[piA].
        mClub[piA] = mClub[piB].
        mClub[piB] = keep.
    END METHOD.

    /* What a player is to the club. */
    METHOD PUBLIC SquadRole RoleOf(INPUT piPlayer AS INTEGER):
        CheckPlayer(piPlayer).
        RETURN SquadRole:GetEnum(mRole[piPlayer]).
    END METHOD.

    METHOD PUBLIC VOID SetRole(INPUT piPlayer AS INTEGER, INPUT poRole AS SquadRole):
        CheckPlayer(piPlayer).
        mRole[piPlayer] = INTEGER(poRole).
    END METHOD.

    /* A player's skill, 1 to 5. */
    METHOD PUBLIC INTEGER SkillOf(INPUT piPlayer AS INTEGER):
        CheckPlayer(piPlayer).
        RETURN mSkill[piPlayer].
    END METHOD.

    METHOD PUBLIC VOID SetSkill(INPUT piPlayer AS INTEGER, INPUT piSkill AS INTEGER):
        CheckPlayer(piPlayer).
        IF piSkill = ? OR piSkill < 1 OR piSkill > FootballRules:MaxSkill() THEN
            UNDO, THROW NEW GridException("Skill runs from 1 to 5, not " + STRING(piSkill)).
        mSkill[piPlayer] = piSkill.
    END METHOD.

    /* A player's energy, 1 to 20. SetEnergy keeps it inside that range. */
    METHOD PUBLIC INTEGER EnergyOf(INPUT piPlayer AS INTEGER):
        CheckPlayer(piPlayer).
        RETURN mEnergy[piPlayer].
    END METHOD.

    METHOD PUBLIC VOID SetEnergy(INPUT piPlayer AS INTEGER, INPUT piEnergy AS INTEGER):
        CheckPlayer(piPlayer).
        IF piEnergy = ? THEN UNDO, THROW NEW GridException("Energy needs a number").
        mEnergy[piPlayer] = MAXIMUM(1, MINIMUM(FootballRules:MaxEnergy(), piEnergy)).
    END METHOD.

    /* A player's value in pounds. */
    METHOD PUBLIC INTEGER WorthOf(INPUT piPlayer AS INTEGER):
        CheckPlayer(piPlayer).
        RETURN mWorth[piPlayer].
    END METHOD.

    METHOD PUBLIC VOID SetWorth(INPUT piPlayer AS INTEGER, INPUT piWorth AS INTEGER):
        CheckPlayer(piPlayer).
        IF piWorth = ? OR piWorth < 0 THEN UNDO, THROW NEW GridException("A value cannot be " + STRING(piWorth)).
        mWorth[piPlayer] = piWorth.
    END METHOD.

    /* How many players the club has (reserves, starters and injured). */
    METHOD PUBLIC INTEGER OwnedCount():
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 24:
            IF mRole[i] > 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* How many are picked to play. */
    METHOD PUBLIC INTEGER StarterCount():
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 24:
            IF mRole[i] = INTEGER(SquadRole:Starter) THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The league table of the manager's division, by team 1 to 16: points, goals for and against. */
    METHOD PUBLIC INTEGER PointsOf(INPUT piTeam AS INTEGER):
        CheckTeam(piTeam).
        RETURN mPoints[piTeam].
    END METHOD.

    METHOD PUBLIC INTEGER GoalsForOf(INPUT piTeam AS INTEGER):
        CheckTeam(piTeam).
        RETURN mFor[piTeam].
    END METHOD.

    METHOD PUBLIC INTEGER GoalsAgainstOf(INPUT piTeam AS INTEGER):
        CheckTeam(piTeam).
        RETURN mAgainst[piTeam].
    END METHOD.

    /* Adds a result to a team's line of the table: its points and the goals it scored and let in. */
    METHOD PUBLIC VOID AddResult(INPUT piTeam AS INTEGER, INPUT piPoints AS INTEGER, INPUT piFor AS INTEGER, INPUT piAgainst AS INTEGER):
        CheckTeam(piTeam).
        mPoints[piTeam] = mPoints[piTeam] + piPoints.
        mFor[piTeam] = mFor[piTeam] + piFor.
        mAgainst[piTeam] = mAgainst[piTeam] + piAgainst.
    END METHOD.

    /* The place of a team in the table as it stood after the last league match (0 before the first). */
    METHOD PUBLIC INTEGER PlaceOf(INPUT piTeam AS INTEGER):
        CheckTeam(piTeam).
        RETURN mPlace[piTeam].
    END METHOD.

    METHOD PUBLIC VOID SetPlace(INPUT piTeam AS INTEGER, INPUT piPlace AS INTEGER):
        CheckTeam(piTeam).
        mPlace[piTeam] = piPlace.
    END METHOD.

    /* The team in a place of the sorted table (place 1 is the top). */
    METHOD PUBLIC INTEGER TeamAt(INPUT piPlace AS INTEGER):
        CheckTeam(piPlace).
        RETURN mOrder[piPlace].
    END METHOD.

    METHOD PUBLIC VOID SetTeamAt(INPUT piPlace AS INTEGER, INPUT piTeam AS INTEGER):
        CheckTeam(piPlace).
        CheckTeam(piTeam).
        mOrder[piPlace] = piTeam.
    END METHOD.

    /* A number from 1 to piMost. */
    METHOD PRIVATE INTEGER Roll(INPUT poRandom AS IRandom, INPUT piMost AS INTEGER):
        RETURN poRandom:NextInt(piMost) + 1.
    END METHOD.

    /* The player who is the piNth (from 1) of those the club does not own. Throws GridException if there are not that many. */
    METHOD PUBLIC INTEGER NthOutsider(INPUT piNth AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 24:
            IF mRole[i] = 0 THEN
            DO:
                n = n + 1.
                IF n = piNth THEN RETURN i.
            END.
        END.
        UNDO, THROW NEW GridException("There is no outsider number " + STRING(piNth)).
    END METHOD.

    /* How many players the club does not own. */
    METHOD PUBLIC INTEGER OutsiderCount():
        RETURN FootballRules:PoolSize() - OwnedCount().
    END METHOD.

    /* Starts a game: the manager takes the club in piClub (1 to 64), who change places with the club in slot 64 and start in the fourth division. Twelve players of the pool at random make the squad, the first eleven picked playing and the twelfth in reserve. Cash and loan start at nothing, then the season begins (see StartSeason).
       Throws GridException for a club, level, kit or name that is not allowed. */
    METHOD PUBLIC VOID NewGame(INPUT pcManager AS CHARACTER, INPUT piClub AS INTEGER, INPUT piLevel AS INTEGER, INPUT piKit AS INTEGER, INPUT poRandom AS IRandom):
        VAR INTEGER i.
        VAR INTEGER p.
        IF pcManager = ? OR LENGTH(pcManager) < 1 OR LENGTH(pcManager) > 20 THEN
            UNDO, THROW NEW GridException("A manager's name is 1 to 20 characters").
        CheckSlot(piClub).
        IF piLevel = ? OR piLevel < 1 OR piLevel > FootballRules:LevelCount() THEN
            UNDO, THROW NEW GridException("The level runs from 1 to 7, not " + STRING(piLevel)).
        IF piKit <> 0 AND piKit <> 7 THEN
            UNDO, THROW NEW GridException("The kit is 0 (black) or 7 (white), not " + STRING(piKit)).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A game needs a random source").
        DO i = 1 TO 64:
            mClub[i] = FootballNames:Club(i).
        END.
        SwapClubs(64, piClub).
        Slot = 64.
        ManagerName = pcManager.
        Level = piLevel.
        KitColour = piKit.
        Cash = 0.
        Loan = 0.
        LastBalance = 0.
        Seasons = 0.
        SeasonScore = 0.
        DO i = 1 TO 24:
            mRole[i] = 0.
        END.
        DO i = 1 TO FootballRules:StartingSquad():
            p = NthOutsider(Roll(poRandom, OutsiderCount())).
            IF i = FootballRules:StartingSquad() THEN mRole[p] = INTEGER(SquadRole:Reserve).
            ELSE mRole[p] = INTEGER(SquadRole:Starter).
        END.
        StartSeason(poRandom).
    END METHOD.

    /* Begins a season in the manager's present division: the table is cleared, every player of the pool gets a new skill (1 to 5, his value 5000 times that and the division's number) and a new energy (1 to 20), morale goes back to 10 and the gate and the rent to the division's. Who is in the squad does not change. */
    METHOD PUBLIC VOID StartSeason(INPUT poRandom AS IRandom):
        VAR INTEGER i.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A season needs a random source").
        Cycle = 1.
        LeagueMatch = 0.
        CupRound = 0.
        CupOver = FALSE.
        NextHome = 2.
        DO i = 1 TO 16:
            mPoints[i] = 0.
            mFor[i] = 0.
            mAgainst[i] = 0.
            mPlace[i] = 0.
            mOrder[i] = i.
        END.
        DO i = 1 TO 24:
            mSkill[i] = Roll(poRandom, FootballRules:MaxSkill()).
            mWorth[i] = FootballRules:ValueUnit() * Multiplier * mSkill[i].
            mEnergy[i] = Roll(poRandom, FootballRules:MaxEnergy()).
        END.
        Morale = FootballRules:StartMorale().
        Gate = FootballRules:GateUnit() * Multiplier.
        Rent = FootballRules:RentUnit() * Multiplier.
    END METHOD.

END CLASS.
