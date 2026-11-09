/* Keeps a game of FootballManager between runs, in the settings under the prefix footballmanager.save. There is one save. It holds all of a FootballWorld (the manager, the clubs in their slots, the 24 players, the table, the money and the season) and the game's turn counter. Lists are one key each: numbers joined by commas, the clubs joined by bars. A save from another shape (version) is ignored, and so is a damaged one: Restore says FALSE and changes nothing, so the game starts a new one. Only a game waiting in the manager's office is kept (see FootballGame), because a fixture only means something inside a week. The random source is not state. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballSave FINAL:

    &SCOPED-DEFINE Prefix footballmanager.save.

    VAR PRIVATE ISettings mSettings.

    /* The shape of a save: raise it when FootballWorld gains state. */
    METHOD PUBLIC STATIC INTEGER Version():
        RETURN 1.
    END METHOD.

    /* Throws GridException for no settings. */
    CONSTRUCTOR PUBLIC FootballSave(INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("A saved game needs settings to be kept in").
        mSettings = poSettings.
    END CONSTRUCTOR.

    /* True when a save is there (it may still be damaged or of another shape: Restore says). */
    METHOD PUBLIC LOGICAL HasSave():
        RETURN mSettings:GetInteger("{&Prefix}version", 0) > 0.
    END METHOD.

    /* Writes the world and the turn counter and saves the settings. Throws GridException for no world. */
    METHOD PUBLIC VOID Keep(INPUT poWorld AS FootballWorld, INPUT piTurn AS INTEGER):
        VAR INTEGER i.
        VAR CHARACTER clubs.
        VAR CHARACTER role.
        VAR CHARACTER skill.
        VAR CHARACTER energy.
        VAR CHARACTER worth.
        VAR CHARACTER points.
        VAR CHARACTER goalsFor.
        VAR CHARACTER goalsAgainst.
        VAR CHARACTER place.
        VAR CHARACTER orderText.
        IF NOT VALID-OBJECT(poWorld) THEN UNDO, THROW NEW GridException("There is no world to save").
        DO i = 1 TO 64:
            clubs = clubs + (IF i > 1 THEN "|" ELSE "") + poWorld:ClubName(i).
        END.
        DO i = 1 TO 24:
            role = role + (IF i > 1 THEN "," ELSE "") + STRING(INTEGER(poWorld:RoleOf(i))).
            skill = skill + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:SkillOf(i)).
            energy = energy + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:EnergyOf(i)).
            worth = worth + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:WorthOf(i)).
        END.
        DO i = 1 TO 16:
            points = points + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:PointsOf(i)).
            goalsFor = goalsFor + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:GoalsForOf(i)).
            goalsAgainst = goalsAgainst + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:GoalsAgainstOf(i)).
            place = place + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:PlaceOf(i)).
            orderText = orderText + (IF i > 1 THEN "," ELSE "") + STRING(poWorld:TeamAt(i)).
        END.
        mSettings:SetString("{&Prefix}manager", poWorld:ManagerName).
        mSettings:SetString("{&Prefix}clubs", clubs).
        mSettings:SetString("{&Prefix}role", role).
        mSettings:SetString("{&Prefix}skill", skill).
        mSettings:SetString("{&Prefix}energy", energy).
        mSettings:SetString("{&Prefix}worth", worth).
        mSettings:SetString("{&Prefix}points", points).
        mSettings:SetString("{&Prefix}for", goalsFor).
        mSettings:SetString("{&Prefix}against", goalsAgainst).
        mSettings:SetString("{&Prefix}place", place).
        mSettings:SetString("{&Prefix}order", orderText).
        mSettings:SetString("{&Prefix}slot", STRING(poWorld:Slot)).
        mSettings:SetString("{&Prefix}level", STRING(poWorld:Level)).
        mSettings:SetString("{&Prefix}kit", STRING(poWorld:KitColour)).
        mSettings:SetString("{&Prefix}cash", STRING(poWorld:Cash)).
        mSettings:SetString("{&Prefix}loan", STRING(poWorld:Loan)).
        mSettings:SetString("{&Prefix}lastbalance", STRING(poWorld:LastBalance)).
        mSettings:SetString("{&Prefix}gate", STRING(poWorld:Gate)).
        mSettings:SetString("{&Prefix}rent", STRING(poWorld:Rent)).
        mSettings:SetString("{&Prefix}morale", STRING(poWorld:Morale)).
        mSettings:SetString("{&Prefix}leaguematch", STRING(poWorld:LeagueMatch)).
        mSettings:SetString("{&Prefix}cupround", STRING(poWorld:CupRound)).
        mSettings:SetString("{&Prefix}cupover", STRING((IF poWorld:CupOver THEN 1 ELSE 0))).
        mSettings:SetString("{&Prefix}cycle", STRING(poWorld:Cycle)).
        mSettings:SetString("{&Prefix}nexthome", STRING(poWorld:NextHome)).
        mSettings:SetString("{&Prefix}seasonscore", STRING(poWorld:SeasonScore)).
        mSettings:SetString("{&Prefix}seasons", STRING(poWorld:Seasons)).
        mSettings:SetString("{&Prefix}turn", STRING(piTurn)).
        mSettings:SetInteger("{&Prefix}version", Version()).
        mSettings:Save().
    END METHOD.

    /* Reads the save into poWorld and the turn counter into piTurn. TRUE when it was loaded. FALSE when there is no save, it is of another shape or any part of it is damaged: then poWorld is left as it was. Throws GridException for no world. */
    METHOD PUBLIC LOGICAL Restore(INPUT poWorld AS FootballWorld, OUTPUT piTurn AS INTEGER):
        VAR FootballWorld scratch.
        VAR INTEGER turnRead.
        piTurn = 0.
        IF NOT VALID-OBJECT(poWorld) THEN UNDO, THROW NEW GridException("There is no world to load into").
        IF NOT HasSave() THEN RETURN FALSE.
        /* the whole save is checked on a scratch world first, so that a damaged one never leaves poWorld half changed */
        DO ON ERROR UNDO, THROW:
            scratch = NEW FootballWorld().
            LoadInto(scratch, OUTPUT turnRead).
            LoadInto(poWorld, OUTPUT turnRead).
            CATCH eDamaged AS Progress.Lang.Error:
                RETURN FALSE.
            END CATCH.
        END.
        piTurn = turnRead.
        RETURN TRUE.
    END METHOD.

    /* Forgets the save (a manager who is sacked has nothing to go back to). */
    METHOD PUBLIC VOID Erase():
        mSettings:SetInteger("{&Prefix}version", 0).
        mSettings:Save().
    END METHOD.

    /* A whole number in a key, or a GridException when it is missing or not a number. */
    METHOD PRIVATE INTEGER Whole(INPUT pcKey AS CHARACTER, INPUT piLow AS INTEGER, INPUT piHigh AS INTEGER):
        RETURN ParsedWhole(mSettings:GetString(pcKey, ""), pcKey, piLow, piHigh).
    END METHOD.

    METHOD PRIVATE INTEGER ParsedWhole(INPUT pcText AS CHARACTER, INPUT pcWhat AS CHARACTER, INPUT piLow AS INTEGER, INPUT piHigh AS INTEGER):
        VAR INTEGER n.
        IF NOT mSettings:Has("{&Prefix}version") THEN UNDO, THROW NEW GridException("There is no save").
        IF LENGTH(TRIM(pcText)) = 0 THEN UNDO, THROW NEW GridException("The save lacks " + pcWhat).
        n = INTEGER(pcText) NO-ERROR.
        IF ERROR-STATUS:ERROR OR n = ? OR n < piLow OR n > piHigh THEN UNDO, THROW NEW GridException("The save has a bad " + pcWhat).
        RETURN n.
    END METHOD.

    /* A number from one of the saved lists: the list must have piCount items. */
    METHOD PRIVATE INTEGER ListItem(INPUT pcKey AS CHARACTER, INPUT piItem AS INTEGER, INPUT piCount AS INTEGER, INPUT piLow AS INTEGER, INPUT piHigh AS INTEGER):
        VAR CHARACTER listText.
        listText = mSettings:GetString(pcKey, "").
        IF NUM-ENTRIES(listText) <> piCount THEN UNDO, THROW NEW GridException("The save has a list of the wrong length: " + pcKey).
        RETURN ParsedWhole(ENTRY(piItem, listText), pcKey, piLow, piHigh).
    END METHOD.

    /* Loads every part of the save into a world, throwing GridException at the first thing wrong with it. */
    METHOD PRIVATE VOID LoadInto(INPUT poWorld AS FootballWorld, OUTPUT piTurn AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER n.
        VAR INTEGER owned.
        VAR CHARACTER clubs.
        VAR CHARACTER manager.
        VAR LOGICAL[16] seen.
        IF mSettings:GetInteger("{&Prefix}version", 0) <> Version() THEN UNDO, THROW NEW GridException("The save is of another shape").
        manager = mSettings:GetString("{&Prefix}manager", "").
        IF LENGTH(manager) < 1 OR LENGTH(manager) > 20 THEN UNDO, THROW NEW GridException("The save has a bad manager").
        poWorld:ManagerName = manager.
        poWorld:Slot = Whole("{&Prefix}slot", 1, FootballRules:ClubCount()).
        poWorld:Level = Whole("{&Prefix}level", 1, FootballRules:LevelCount()).
        poWorld:KitColour = Whole("{&Prefix}kit", 0, 7).
        IF poWorld:KitColour <> 0 AND poWorld:KitColour <> 7 THEN UNDO, THROW NEW GridException("The save has a bad kit").
        poWorld:Cash = Whole("{&Prefix}cash", -2000000000, 2000000000).
        poWorld:Loan = Whole("{&Prefix}loan", 0, 2000000000).
        poWorld:LastBalance = Whole("{&Prefix}lastbalance", -2000000000, 2000000000).
        poWorld:Gate = Whole("{&Prefix}gate", 0, 2000000000).
        poWorld:Rent = Whole("{&Prefix}rent", 0, 2000000000).
        poWorld:Morale = Whole("{&Prefix}morale", 1, FootballRules:MaxEnergy()).
        poWorld:LeagueMatch = Whole("{&Prefix}leaguematch", 0, FootballRules:LeagueMatches()).
        poWorld:CupRound = Whole("{&Prefix}cupround", 0, FootballRules:CupRounds()).
        poWorld:CupOver = Whole("{&Prefix}cupover", 0, 1) = 1.
        poWorld:Cycle = Whole("{&Prefix}cycle", 0, 3).
        poWorld:NextHome = Whole("{&Prefix}nexthome", 1, 2).
        poWorld:SeasonScore = Whole("{&Prefix}seasonscore", 0, 2000000000).
        poWorld:Seasons = Whole("{&Prefix}seasons", 0, 2000000000).
        piTurn = Whole("{&Prefix}turn", 0, 2000000000).

        /* the clubs must be the 64 names in some order: each slot is brought into place by a swap */
        clubs = mSettings:GetString("{&Prefix}clubs", "").
        IF NUM-ENTRIES(clubs, "|") <> 64 THEN UNDO, THROW NEW GridException("The save has the wrong number of clubs").
        DO i = 1 TO 64:
            n = 0.
            DO j = i TO 64:
                IF poWorld:ClubName(j) = ENTRY(i, clubs, "|") THEN DO:
                    n = j.
                    LEAVE.
                END.
            END.
            IF n = 0 THEN UNDO, THROW NEW GridException("The save has a club that is not one of the 64: " + ENTRY(i, clubs, "|")).
            poWorld:SwapClubs(i, n).
        END.

        DO i = 1 TO 24:
            poWorld:SetRole(i, SquadRole:GetEnum(ListItem("{&Prefix}role", i, 24, 0, 3))).
            poWorld:SetSkill(i, ListItem("{&Prefix}skill", i, 24, 1, FootballRules:MaxSkill())).
            poWorld:SetEnergy(i, ListItem("{&Prefix}energy", i, 24, 1, FootballRules:MaxEnergy())).
            poWorld:SetWorth(i, ListItem("{&Prefix}worth", i, 24, 0, 2000000000)).
        END.
        IF poWorld:OwnedCount() > FootballRules:SquadMax() THEN UNDO, THROW NEW GridException("The save has too many players in the squad").

        DO i = 1 TO 16:
            /* a fresh world has an empty table, so the lines are added to nothing */
            poWorld:AddResult(i, ListItem("{&Prefix}points", i, 16, 0, 1000) - poWorld:PointsOf(i),
                              ListItem("{&Prefix}for", i, 16, 0, 100000) - poWorld:GoalsForOf(i),
                              ListItem("{&Prefix}against", i, 16, 0, 100000) - poWorld:GoalsAgainstOf(i)).
            poWorld:SetPlace(i, ListItem("{&Prefix}place", i, 16, 0, 16)).
            n = ListItem("{&Prefix}order", i, 16, 1, 16).
            IF seen[n] THEN UNDO, THROW NEW GridException("The save has a team twice in the sorted table").
            seen[n] = TRUE.
            poWorld:SetTeamAt(i, n).
        END.
    END METHOD.

END CLASS.
