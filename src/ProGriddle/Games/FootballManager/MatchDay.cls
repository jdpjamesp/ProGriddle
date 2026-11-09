/* One fixture from the draw to the result, in the order the original does it: Begin (the third fixture is a cup tie while the club is still in the cup, the others league matches; the opponent, their numbers, the side and the gate are settled), then Squad:Prepare and the manager's picking of the team, then Play (the match and the gate money), then, for a drawn cup tie, Replay and Play again, and last Finish (the result goes into the table or the cup, morale changes, and the other clubs' matches of a league week are played and the table sorted). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchDay FINAL:

    METHOD PRIVATE STATIC INTEGER Roll(INPUT poRandom AS IRandom, INPUT piMost AS INTEGER):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A match day needs a random source").
        RETURN poRandom:NextInt(piMost) + 1.
    END METHOD.

    /* The name of the cup round the world is up to: its number, "Semi-Final" for the 7th and "Final" for the 8th. */
    METHOD PUBLIC STATIC CHARACTER RoundName(INPUT piRound AS INTEGER):
        IF piRound = ? OR piRound < 1 OR piRound > FootballRules:CupRounds() THEN UNDO, THROW NEW GridException("There is no cup round " + STRING(piRound)).
        IF piRound = FootballRules:CupRounds() THEN RETURN "Final".
        IF piRound = FootballRules:CupRounds() - 1 THEN RETURN "Semi-Final".
        RETURN STRING(piRound).
    END METHOD.

    /* Draws the next fixture and counts it (LeagueMatch or CupRound goes up by one). The third, sixth, and so on are cup ties while the club is in the cup. A league match is against the next club in the division, alternating home and away starting at home; a cup tie is against a club of the right band and at home or away by chance. */
    METHOD PUBLIC STATIC Fixture Begin(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        VAR Fixture fixture = NEW Fixture().
        VAR INTEGER i.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A match day needs a random source").
        poWorld:Cycle = poWorld:Cycle + 1.
        fixture:Kind = FixtureKind:League.
        IF poWorld:Cycle = 3 THEN
        DO:
            poWorld:Cycle = 0.
            fixture:Kind = FixtureKind:Cup.
        END.
        IF poWorld:CupOver THEN fixture:Kind = FixtureKind:League.
        IF fixture:Kind = FixtureKind:Cup THEN
        DO:
            poWorld:CupRound = poWorld:CupRound + 1.
            fixture:OpponentSlot = Opposition:CupSlot(poWorld, poRandom).
        END.
        ELSE
        DO:
            poWorld:LeagueMatch = poWorld:LeagueMatch + 1.
            fixture:OpponentSlot = Opposition:LeagueSlot(poWorld).
        END.
        DO i = 1 TO 5:
            fixture:SetOppositionNumber(i, Opposition:Number(poWorld, poRandom, fixture:Kind, fixture:OpponentSlot)).
        END.
        IF fixture:Kind = FixtureKind:Cup THEN fixture:ManagerSide = Roll(poRandom, 2).
        ELSE
        DO:
            /* home and away alternate: the side is 1 after a 2 and 2 after a 1 */
            fixture:ManagerSide = INTEGER(TRUNCATE(1.5 / poWorld:NextHome + 1, 0)).
            poWorld:NextHome = fixture:ManagerSide.
        END.
        fixture:Gate = Bank:GateFor(poWorld, fixture:Kind, fixture:ManagerIsHome, fixture:OpponentSlot).
        RETURN fixture.
    END METHOD.

    /* Plays the match: the manager's five numbers as the team stands now against the opposition's, and the gate money paid into the cash. */
    METHOD PUBLIC STATIC MatchResult Play(INPUT poWorld AS FootballWorld, INPUT poFixture AS Fixture, INPUT poRandom AS IRandom):
        VAR INTEGER[5] own.
        VAR INTEGER[5] opp.
        VAR INTEGER i.
        DO i = 1 TO 5:
            own[i] = TeamStrength:Value(poWorld, i).
            opp[i] = poFixture:OppositionNumber(i).
        END.
        poWorld:Cash = poWorld:Cash + poFixture:Gate.
        RETURN MatchEngine:Play(own, opp, poFixture:ManagerSide, poRandom).
    END METHOD.

    /* The manager's goals and the opposition's in a match. */
    METHOD PUBLIC STATIC INTEGER ManagerGoals(INPUT poFixture AS Fixture, INPUT poResult AS MatchResult):
        RETURN poResult:GoalsOf(poFixture:ManagerSide).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER OpponentGoals(INPUT poFixture AS Fixture, INPUT poResult AS MatchResult):
        RETURN poResult:GoalsOf(3 - poFixture:ManagerSide).
    END METHOD.

    /* A cup tie that ended level has to be played again. */
    METHOD PUBLIC STATIC LOGICAL NeedsReplay(INPUT poFixture AS Fixture, INPUT poResult AS MatchResult):
        RETURN poFixture:Kind = FixtureKind:Cup AND ManagerGoals(poFixture, poResult) = OpponentGoals(poFixture, poResult).
    END METHOD.

    /* Sets up the replay of a drawn cup tie: the sides change over and the gate is worked out again for the new venue. */
    METHOD PUBLIC STATIC VOID Replay(INPUT poWorld AS FootballWorld, INPUT poFixture AS Fixture):
        poFixture:ManagerSide = 3 - poFixture:ManagerSide.
        poFixture:Gate = Bank:GateFor(poWorld, poFixture:Kind, poFixture:ManagerIsHome, poFixture:OpponentSlot).
    END METHOD.

    /* Morale after a result: a win closes half the gap to 20, a defeat halves it, a draw leaves it. Always 1 to 20. */
    METHOD PRIVATE STATIC VOID Settle(INPUT poWorld AS FootballWorld, INPUT piGoals AS INTEGER, INPUT piAgainst AS INTEGER):
        IF piGoals > piAgainst THEN
            poWorld:Morale = poWorld:Morale + INTEGER(TRUNCATE((FootballRules:MaxEnergy() - poWorld:Morale) / 2, 0)).
        IF piGoals < piAgainst THEN poWorld:Morale = INTEGER(TRUNCATE(poWorld:Morale / 2, 0)).
        poWorld:Morale = MAXIMUM(1, MINIMUM(FootballRules:MaxEnergy(), poWorld:Morale)).
    END METHOD.

    /* Ends the fixture with its result. A league match goes into the table, then morale changes, then the other clubs play (the results are returned) and the table is sorted. A cup tie knocks the club out if it lost (the cup is over for it) and finishes the cup if it won the final; morale changes by the original's rules, which for a cup tie apply the change twice. A drawn cup tie must be replayed, not finished: throws GridException. */
    METHOD PUBLIC STATIC WeekResults Finish(INPUT poWorld AS FootballWorld, INPUT poFixture AS Fixture, INPUT poResult AS MatchResult, INPUT poRandom AS IRandom):
        VAR INTEGER mine = ManagerGoals(poFixture, poResult).
        VAR INTEGER theirs = OpponentGoals(poFixture, poResult).
        VAR WeekResults others = NEW WeekResults().
        IF NeedsReplay(poFixture, poResult) THEN UNDO, THROW NEW GridException("A drawn cup tie has to be replayed").
        IF poFixture:Kind = FixtureKind:Cup THEN
        DO:
            IF mine < theirs THEN poWorld:CupOver = TRUE.
            ELSE IF poWorld:CupRound = FootballRules:CupRounds() THEN poWorld:CupOver = TRUE.
            Settle(poWorld, mine, theirs).
            Settle(poWorld, mine, theirs).
            RETURN others.
        END.
        LeagueTable:RecordMatch(poWorld, mine, theirs, poFixture:OpponentSlot).
        Settle(poWorld, mine, theirs).
        others = LeagueTable:PlayOthers(poWorld, poRandom).
        LeagueTable:Sort(poWorld).
        RETURN others.
    END METHOD.

END CLASS.
