/* The league: recording the manager's result (points, goals and the effect on the home gate), playing the other clubs' matches of the week, sorting the table, and the end of the season (the prize, promotion and relegation, and a new season). Teams are numbered 1 to 16 within the manager's division; a team's slot is DivisionBase + its number. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.LeagueTable FINAL:

    /* Records a league match of the manager's against the club in slot piOpponent: three points for a win, one each for a draw, the goals for both, and the home gate follows the result (a tenth of the way up toward 10000 times the division's number after a win, a tenth down, never under 1000, after a defeat, whether the match was at home or away). */
    METHOD PUBLIC STATIC VOID RecordMatch(INPUT poWorld AS FootballWorld, INPUT piGoals AS INTEGER, INPUT piAgainst AS INTEGER, INPUT piOpponent AS INTEGER):
        VAR INTEGER me.
        VAR INTEGER them.
        me = poWorld:Slot - poWorld:DivisionBase.
        them = piOpponent - poWorld:DivisionBase.
        IF piGoals = piAgainst THEN
        DO:
            poWorld:AddResult(me, FootballRules:DrawPoints(), piGoals, piAgainst).
            poWorld:AddResult(them, FootballRules:DrawPoints(), piAgainst, piGoals).
        END.
        ELSE IF piGoals < piAgainst THEN
        DO:
            poWorld:AddResult(me, 0, piGoals, piAgainst).
            poWorld:AddResult(them, FootballRules:WinPoints(), piAgainst, piGoals).
            poWorld:Gate = poWorld:Gate - INTEGER(TRUNCATE(poWorld:Gate / 10, 0)).
            IF poWorld:Gate < FootballRules:GateFloor() THEN poWorld:Gate = FootballRules:GateFloor().
        END.
        ELSE
        DO:
            poWorld:AddResult(me, FootballRules:WinPoints(), piGoals, piAgainst).
            poWorld:AddResult(them, 0, piAgainst, piGoals).
            poWorld:Gate = poWorld:Gate + INTEGER(TRUNCATE((FootballRules:GateCeilingUnit() * poWorld:Multiplier - poWorld:Gate) / 10, 0)).
        END.
    END METHOD.

    /* The piNth (from 1) team that has not been used yet. */
    METHOD PRIVATE STATIC INTEGER NthFree(INPUT piUsed AS INTEGER EXTENT 16, INPUT piNth AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 16:
            IF piUsed[i] = 0 THEN
            DO:
                n = n + 1.
                IF n = piNth THEN RETURN i.
            END.
        END.
        UNDO, THROW NEW GridException("There is no free team number " + STRING(piNth)).
    END METHOD.

    /* A goal count for a team that has taken piPoints from the matches so far: its points a match plus a random 0 up to (not including) 4, whole. */
    METHOD PRIVATE STATIC INTEGER GoalsFor(INPUT poWorld AS FootballWorld, INPUT piTeam AS INTEGER, INPUT poRandom AS IRandom):
        RETURN INTEGER(TRUNCATE(poWorld:PointsOf(piTeam) / poWorld:LeagueMatch + poRandom:NextInt(4000) / 1000, 0)).
    END METHOD.

    /* Plays the seven matches between the other fourteen clubs of the division in a league week: pairs picked at random, each side scoring its points a match so far plus up to four, and the table updated. Call it after RecordMatch, with LeagueMatch counted. */
    METHOD PUBLIC STATIC WeekResults PlayOthers(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        VAR WeekResults results = NEW WeekResults().
        VAR INTEGER[16] used.
        VAR INTEGER n.
        VAR INTEGER a.
        VAR INTEGER b.
        VAR INTEGER ga.
        VAR INTEGER gb.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("The league needs a random source").
        IF poWorld:LeagueMatch < 1 THEN UNDO, THROW NEW GridException("There is no league week before the first match").
        used[poWorld:Slot - poWorld:DivisionBase] = 1.
        used[Opposition:LeagueSlot(poWorld) - poWorld:DivisionBase] = 1.
        DO n = 1 TO 7:
            a = NthFree(used, poRandom:NextInt(14 - 2 * (n - 1)) + 1).
            used[a] = 1.
            b = NthFree(used, poRandom:NextInt(13 - 2 * (n - 1)) + 1).
            used[b] = 1.
            ga = GoalsFor(poWorld, a, poRandom).
            gb = GoalsFor(poWorld, b, poRandom).
            IF ga > gb THEN
            DO:
                poWorld:AddResult(a, FootballRules:WinPoints(), ga, gb).
                poWorld:AddResult(b, 0, gb, ga).
            END.
            ELSE IF ga < gb THEN
            DO:
                poWorld:AddResult(a, 0, ga, gb).
                poWorld:AddResult(b, FootballRules:WinPoints(), gb, ga).
            END.
            ELSE
            DO:
                poWorld:AddResult(a, FootballRules:DrawPoints(), ga, gb).
                poWorld:AddResult(b, FootballRules:DrawPoints(), gb, ga).
            END.
            results:Add(a, ga, b, gb).
        END.
        RETURN results.
    END METHOD.

    /* True when team piA stays above team piB in the table: more points, or the same points and a better goal difference, or the same of both and more goals scored. */
    METHOD PRIVATE STATIC LOGICAL StaysAbove(INPUT poWorld AS FootballWorld, INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        VAR INTEGER diffA.
        VAR INTEGER diffB.
        IF poWorld:PointsOf(piA) > poWorld:PointsOf(piB) THEN RETURN TRUE.
        IF poWorld:PointsOf(piA) < poWorld:PointsOf(piB) THEN RETURN FALSE.
        diffA = poWorld:GoalsForOf(piA) - poWorld:GoalsAgainstOf(piA).
        diffB = poWorld:GoalsForOf(piB) - poWorld:GoalsAgainstOf(piB).
        IF diffA > diffB THEN RETURN TRUE.
        IF diffA < diffB THEN RETURN FALSE.
        RETURN poWorld:GoalsForOf(piA) > poWorld:GoalsForOf(piB).
    END METHOD.

    /* Sorts the table, as the original does: a bubble sort that starts from the order of the last sort (from the order of the teams at the first match of a season), puts a team below a neighbour it only ties with, and then gives every team its place. */
    METHOD PUBLIC STATIC VOID Sort(INPUT poWorld AS FootballWorld):
        VAR INTEGER i.
        VAR INTEGER pass = 1.
        VAR INTEGER q.
        VAR LOGICAL change = TRUE.
        IF poWorld:LeagueMatch <= 1 THEN
            DO i = 1 TO 16:
                poWorld:SetTeamAt(i, i).
            END.
        DO WHILE change:
            change = FALSE.
            DO i = 1 TO 16 - pass:
                IF NOT StaysAbove(poWorld, poWorld:TeamAt(i), poWorld:TeamAt(i + 1)) THEN
                DO:
                    q = poWorld:TeamAt(i).
                    poWorld:SetTeamAt(i, poWorld:TeamAt(i + 1)).
                    poWorld:SetTeamAt(i + 1, q).
                    change = TRUE.
                END.
            END.
            pass = pass + 1.
        END.
        DO i = 1 TO 16:
            poWorld:SetPlace(poWorld:TeamAt(i), i).
        END.
    END METHOD.

    /* True when the season is over: all 15 league matches are played and the cup is over for the club. */
    METHOD PUBLIC STATIC LOGICAL SeasonOver(INPUT poWorld AS FootballWorld):
        RETURN poWorld:LeagueMatch >= FootballRules:LeagueMatches() AND poWorld:CupOver.
    END METHOD.

    /* Ends the season (call it when SeasonOver and the table has been sorted). The prize is 5000 times the division's number for every place above 17 (the champions get 16 times), the manager's score for the season goes up, and in the manager's division the top three go up (in place of the clubs in the 13th to 15th slots above) and the bottom three go down (in place of the first three slots below), whoever is in those slots. Then a new season starts in the division the manager's club is in now (see FootballWorld:StartSeason). Returns what happened to the manager's club. */
    METHOD PUBLIC STATIC SeasonMove EndSeason(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        VAR INTEGER division = poWorld:Division.
        VAR INTEGER base = poWorld:DivisionBase.
        VAR INTEGER place = poWorld:PlaceOf(poWorld:Slot - poWorld:DivisionBase).
        VAR INTEGER prize.
        VAR INTEGER i.
        VAR INTEGER p.
        VAR INTEGER other.
        VAR SeasonMove move = SeasonMove:Stayed.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A new season needs a random source").
        IF place < 1 THEN UNDO, THROW NEW GridException("The table has not been sorted").
        prize = 17 - place.
        poWorld:SeasonScore = poWorld:SeasonScore + prize + poWorld:CupRound * 2 * division.
        poWorld:Cash = poWorld:Cash + prize * FootballRules:ValueUnit() * poWorld:Multiplier.
        poWorld:Seasons = poWorld:Seasons + 1.
        IF division > 1 AND place <= FootballRules:MovingClubs() THEN move = SeasonMove:Promoted.
        ELSE IF division = 1 AND place = 1 THEN move = SeasonMove:Champions.
        ELSE IF division < 4 AND place > FootballRules:ClubsPerDivision() - FootballRules:MovingClubs() THEN move = SeasonMove:Relegated.
        DO i = 1 TO 16:
            p = poWorld:PlaceOf(i).
            IF division > 1 AND p <= FootballRules:MovingClubs() THEN
            DO:
                other = base - p.
                poWorld:SwapClubs(other, base + i).
                IF base + i = poWorld:Slot THEN poWorld:Slot = other.
            END.
            IF division < 4 AND p > FootballRules:ClubsPerDivision() - FootballRules:MovingClubs() THEN
            DO:
                other = division * 16 + 17 - p.
                poWorld:SwapClubs(other, base + i).
                IF base + i = poWorld:Slot THEN poWorld:Slot = other.
            END.
        END.
        poWorld:StartSeason(poRandom).
        RETURN move.
    END METHOD.

END CLASS.
