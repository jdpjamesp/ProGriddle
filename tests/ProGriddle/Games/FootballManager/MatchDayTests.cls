/* One fixture from the draw to the result: which fixtures are cup ties, who is met and where, the gate, a drawn cup tie, and what a result does to the table, the cup and morale. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchDayTests:

    VAR PRIVATE FootballWorld mWorld.

    /* The manager's club is in the fourth division (team 16 of it) at level 3, with morale 10, cash 0 and a home gate of 5000. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 3, 0, NEW ScriptedRandom("0")).
    END METHOD.

    /* The numbers that make a scripted attack (see PitchAttackTests) end in a goal for either side. */
    METHOD PRIVATE CHARACTER GoalScript():
        RETURN "6,4,0,9,17,11,2,9,11,7,14,6,6,0".
    END METHOD.

    /* A fixture of pkKind in which the manager's club is on side piSide, with a gate of 7000. */
    METHOD PRIVATE Fixture MakeFixture(INPUT poKind AS FixtureKind, INPUT piSide AS INTEGER):
        VAR Fixture fixture = NEW Fixture().
        VAR INTEGER i.
        fixture:Kind = poKind.
        fixture:ManagerSide = piSide.
        fixture:OpponentSlot = 49.
        fixture:Gate = 7000.
        DO i = 1 TO 5:
            fixture:SetOppositionNumber(i, 4).
        END.
        RETURN fixture.
    END METHOD.

    /* A match that ended piHome goals to piAway, each goal a scripted attack. */
    METHOD PRIVATE MatchResult Score(INPUT piHome AS INTEGER, INPUT piAway AS INTEGER):
        VAR MatchResult result = NEW MatchResult().
        VAR INTEGER i.
        DO i = 1 TO piHome:
            result:AddAttack(1, NEW ScriptedRandom(GoalScript())).
        END.
        DO i = 1 TO piAway:
            result:AddAttack(2, NEW ScriptedRandom(GoalScript())).
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "round0" THEN MatchDay:RoundName(0).
                WHEN "round9" THEN MatchDay:RoundName(9).
                WHEN "beginrandom" THEN MatchDay:Begin(mWorld, ?).
                WHEN "finishdraw" THEN MatchDay:Finish(mWorld, MakeFixture(FixtureKind:Cup, 1), Score(1, 1), NEW ScriptedRandom("0")).
                WHEN "number0" THEN MakeFixture(FixtureKind:League, 1):OppositionNumber(0).
                WHEN "number6" THEN MakeFixture(FixtureKind:League, 1):SetOppositionNumber(6, 1).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRoundsOfTheCupAreNumberedExceptTheLastTwo():
        Assert:Equals("1", MatchDay:RoundName(1)).
        Assert:Equals("6", MatchDay:RoundName(6)).
        Assert:Equals("Semi-Final", MatchDay:RoundName(7)).
        Assert:Equals("Final", MatchDay:RoundName(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstFixtureIsALeagueMatchAtHomeAgainstTheFirstClubOfTheDivision():
        VAR Fixture fixture.
        VAR INTEGER i.
        fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(FixtureKind:League), INTEGER(fixture:Kind)).
        Assert:Equals(1, mWorld:LeagueMatch).
        Assert:Equals(49, fixture:OpponentSlot).
        Assert:Equals(1, fixture:ManagerSide).
        Assert:IsTrue(fixture:ManagerIsHome).
        Assert:Equals(5000, fixture:Gate).
        /* a scripted 0 is a 1, plus the level 3 and the club's points a match (none) */
        DO i = 1 TO 5:
            Assert:Equals(4, fixture:OppositionNumber(i)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSecondFixtureIsTheFirstCupTieAgainstAClubOfTheBottomEight():
        VAR Fixture fixture.
        MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(FixtureKind:Cup), INTEGER(fixture:Kind)).
        Assert:Equals(1, mWorld:CupRound).
        Assert:Equals(1, mWorld:LeagueMatch).
        Assert:Equals(57, fixture:OpponentSlot).
        /* the side is a scripted 0, a 1: at home */
        Assert:Equals(1, fixture:ManagerSide).
        Assert:Equals(5000, fixture:Gate).
        /* 1 + level 3 + 63/16 - (56/16 + 1) is 3.4375 */
        Assert:Equals(3, fixture:OppositionNumber(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThirdAndFourthFixturesAreLeagueMatchesAlternatingTheVenue():
        VAR Fixture fixture.
        MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(FixtureKind:League), INTEGER(fixture:Kind)).
        Assert:Equals(2, mWorld:LeagueMatch).
        Assert:Equals(50, fixture:OpponentSlot).
        /* the first league match was at home, so this one is away: 17 places times 500 before there is a table */
        Assert:Equals(2, fixture:ManagerSide).
        Assert:IsFalse(fixture:ManagerIsHome).
        Assert:Equals(8500, fixture:Gate).
        fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(FixtureKind:League), INTEGER(fixture:Kind)).
        Assert:Equals(1, fixture:ManagerSide).
        /* then the fifth is the next cup tie */
        fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(FixtureKind:Cup), INTEGER(fixture:Kind)).
        Assert:Equals(2, mWorld:CupRound).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnceTheClubIsOutOfTheCupEveryFixtureIsALeagueMatch():
        VAR Fixture fixture.
        VAR INTEGER i.
        mWorld:CupOver = TRUE.
        DO i = 1 TO 6:
            fixture = MatchDay:Begin(mWorld, NEW ScriptedRandom("0")).
            Assert:Equals(INTEGER(FixtureKind:League), INTEGER(fixture:Kind)).
        END.
        Assert:Equals(6, mWorld:LeagueMatch).
        Assert:Equals(0, mWorld:CupRound).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayedMatchBringsInTheGateAndUsesTheTeamsNumbers():
        VAR MatchResult result.
        mWorld:Cash = 100.
        result = MatchDay:Play(mWorld, MakeFixture(FixtureKind:League, 1), NEW SeededRandom(7)).
        Assert:Equals(7100, mWorld:Cash).
        Assert:IsTrue(result:AttackCount >= 2 AND result:AttackCount <= 22).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheManagersGoalsAreThoseOfHisSide():
        VAR MatchResult result.
        result = Score(0, 1).
        Assert:Equals(0, MatchDay:ManagerGoals(MakeFixture(FixtureKind:League, 1), result)).
        Assert:Equals(1, MatchDay:OpponentGoals(MakeFixture(FixtureKind:League, 1), result)).
        Assert:Equals(1, MatchDay:ManagerGoals(MakeFixture(FixtureKind:League, 2), result)).
        Assert:Equals(0, MatchDay:OpponentGoals(MakeFixture(FixtureKind:League, 2), result)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyALevelCupTieNeedsAReplay():
        Assert:IsTrue(MatchDay:NeedsReplay(MakeFixture(FixtureKind:Cup, 1), Score(1, 1))).
        Assert:IsTrue(MatchDay:NeedsReplay(MakeFixture(FixtureKind:Cup, 1), Score(0, 0))).
        Assert:IsFalse(MatchDay:NeedsReplay(MakeFixture(FixtureKind:Cup, 1), Score(1, 0))).
        Assert:IsFalse(MatchDay:NeedsReplay(MakeFixture(FixtureKind:League, 1), Score(1, 1))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AReplayChangesSidesAndWorksTheGateOutAgain():
        VAR Fixture fixture = MakeFixture(FixtureKind:Cup, 1).
        mWorld:CupRound = 2.
        fixture:OpponentSlot = 60.
        MatchDay:Replay(mWorld, fixture).
        Assert:Equals(2, fixture:ManagerSide).
        /* away at a fourth division club: one division below the fifth */
        Assert:Equals(10000, fixture:Gate).
        MatchDay:Replay(mWorld, fixture).
        Assert:Equals(1, fixture:ManagerSide).
        Assert:Equals(5000, fixture:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWonLeagueMatchGoesIntoTheTableRaisesMoraleAndPlaysTheOtherClubs():
        VAR WeekResults others.
        VAR INTEGER i.
        VAR INTEGER total.
        mWorld:LeagueMatch = 1.
        others = MatchDay:Finish(mWorld, MakeFixture(FixtureKind:League, 1), Score(1, 0), NEW SeededRandom(5)).
        Assert:Equals(3, mWorld:PointsOf(16)).
        Assert:Equals(1, mWorld:GoalsForOf(16)).
        Assert:Equals(5500, mWorld:Gate).
        /* morale 10 closes half the gap to 20 */
        Assert:Equals(15, mWorld:Morale).
        Assert:Equals(7, others:Count).
        DO i = 1 TO 16:
            total = total + mWorld:PlaceOf(i).
        END.
        Assert:Equals(136, total).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALostLeagueMatchHalvesMorale():
        mWorld:LeagueMatch = 1.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:League, 2), Score(1, 0), NEW SeededRandom(5)).
        Assert:Equals(0, mWorld:PointsOf(16)).
        Assert:Equals(5, mWorld:Morale).
        Assert:Equals(4500, mWorld:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrawnLeagueMatchLeavesMorale():
        mWorld:LeagueMatch = 1.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:League, 1), Score(1, 1), NEW SeededRandom(5)).
        Assert:Equals(10, mWorld:Morale).
        Assert:Equals(1, mWorld:PointsOf(16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoraleStaysBetweenOneAndTwenty():
        mWorld:LeagueMatch = 1.
        mWorld:Morale = 20.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:League, 1), Score(1, 0), NEW SeededRandom(5)).
        Assert:Equals(20, mWorld:Morale).
        mWorld:Morale = 1.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:League, 2), Score(1, 0), NEW SeededRandom(5)).
        Assert:Equals(1, mWorld:Morale).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALostCupTieEndsTheCupAndHalvesMoraleTwiceAsInTheOriginal():
        VAR WeekResults others.
        mWorld:CupRound = 3.
        others = MatchDay:Finish(mWorld, MakeFixture(FixtureKind:Cup, 1), Score(0, 1), NEW ScriptedRandom("0")).
        Assert:IsTrue(mWorld:CupOver).
        Assert:Equals(2, mWorld:Morale).
        Assert:Equals(0, others:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWonCupTieKeepsTheClubInTheCupAndRaisesMoraleTwice():
        mWorld:CupRound = 3.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:Cup, 1), Score(1, 0), NEW ScriptedRandom("0")).
        Assert:IsFalse(mWorld:CupOver).
        /* 10 to 15, then 15 to 17 */
        Assert:Equals(17, mWorld:Morale).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WinningTheFinalEndsTheCup():
        mWorld:CupRound = 8.
        MatchDay:Finish(mWorld, MakeFixture(FixtureKind:Cup, 1), Score(1, 0), NEW ScriptedRandom("0")).
        Assert:IsTrue(mWorld:CupOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("round0")).
        Assert:IsTrue(Refused("round9")).
        Assert:IsTrue(Refused("beginrandom")).
        Assert:IsTrue(Refused("finishdraw")).
        Assert:IsTrue(Refused("number0")).
        Assert:IsTrue(Refused("number6")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFixtureKeepsItsNumbersAndVenue():
        VAR Fixture fixture = NEW Fixture().
        fixture:ManagerSide = 2.
        fixture:SetOppositionNumber(4, 13).
        Assert:IsFalse(fixture:ManagerIsHome).
        Assert:Equals(13, fixture:OppositionNumber(4)).
        fixture:ManagerSide = 1.
        Assert:IsTrue(fixture:ManagerIsHome).
    END METHOD.

END CLASS.
