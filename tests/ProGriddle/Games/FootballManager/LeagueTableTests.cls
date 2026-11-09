/* The league: recording the manager's result and the gate that follows it, the other clubs' matches, the sort of the table, and the end of a season (the prize, promotion, relegation and a new season). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.LeagueTableTests:

    VAR PRIVATE FootballWorld mWorld.

    /* The manager's club (Arsenal) is in the fourth division, slot 64, which is team 16 of the division. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
    END METHOD.

    /* Every team in the place of its own number. */
    METHOD PRIVATE VOID IdentityPlaces():
        VAR INTEGER i.
        DO i = 1 TO 16:
            mWorld:SetPlace(i, i).
        END.
    END METHOD.

    /* A season that has been played to the end, with the manager's team in piPlace and the team that would have had that place in the manager's. */
    METHOD PRIVATE VOID FinishedSeason(INPUT piPlace AS INTEGER):
        VAR INTEGER me.
        me = mWorld:Slot - mWorld:DivisionBase.
        IdentityPlaces().
        mWorld:SetPlace(piPlace, me).
        mWorld:SetPlace(me, piPlace).
        mWorld:LeagueMatch = 15.
        mWorld:CupRound = 3.
        mWorld:CupOver = TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "othersrandom" THEN
                DO:
                    mWorld:LeagueMatch = 1.
                    LeagueTable:PlayOthers(mWorld, ?).
                END.
                WHEN "othersearly" THEN
                DO:
                    mWorld:LeagueMatch = 0.
                    LeagueTable:PlayOthers(mWorld, NEW ScriptedRandom("0")).
                END.
                WHEN "endrandom" THEN
                DO:
                    FinishedSeason(5).
                    LeagueTable:EndSeason(mWorld, ?).
                END.
                WHEN "endunsorted" THEN
                DO:
                    /* a new world has no table yet */
                    mWorld = NEW FootballWorld().
                    mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
                    LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
                END.
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWinGivesThreePointsAndTheGoalsAndRaisesTheGate():
        LeagueTable:RecordMatch(mWorld, 2, 1, 49).
        Assert:Equals(3, mWorld:PointsOf(16)).
        Assert:Equals(2, mWorld:GoalsForOf(16)).
        Assert:Equals(1, mWorld:GoalsAgainstOf(16)).
        Assert:Equals(0, mWorld:PointsOf(1)).
        Assert:Equals(1, mWorld:GoalsForOf(1)).
        Assert:Equals(2, mWorld:GoalsAgainstOf(1)).
        /* a tenth of the way from 5000 to 10000 */
        Assert:Equals(5500, mWorld:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADefeatGivesTheOtherSideThreePointsAndLowersTheGate():
        LeagueTable:RecordMatch(mWorld, 0, 1, 49).
        Assert:Equals(0, mWorld:PointsOf(16)).
        Assert:Equals(3, mWorld:PointsOf(1)).
        Assert:Equals(4500, mWorld:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGateNeverFallsBelowAThousand():
        mWorld:Gate = 1050.
        LeagueTable:RecordMatch(mWorld, 0, 1, 49).
        Assert:Equals(1000, mWorld:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrawGivesOnePointEachAndLeavesTheGate():
        LeagueTable:RecordMatch(mWorld, 1, 1, 49).
        Assert:Equals(1, mWorld:PointsOf(16)).
        Assert:Equals(1, mWorld:PointsOf(1)).
        Assert:Equals(5000, mWorld:Gate).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGateMovesTowardTheCeilingOfTheDivision():
        mWorld:Slot = 40.
        mWorld:Gate = 10000.
        LeagueTable:RecordMatch(mWorld, 1, 0, 34).
        /* the ceiling of the third division is 20000 */
        Assert:Equals(11000, mWorld:Gate).
        Assert:Equals(3, mWorld:PointsOf(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOtherFourteenClubsPlayInSevenPairsAndAllDrawNilNilFromAScriptedZero():
        VAR WeekResults results.
        VAR INTEGER i.
        mWorld:LeagueMatch = 1.
        results = LeagueTable:PlayOthers(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(7, results:Count).
        /* the manager (team 16) and the opposition (team 1) are left out: 2 v 3, 4 v 5, and so on */
        Assert:Equals(2, results:TeamA(1)).
        Assert:Equals(3, results:TeamB(1)).
        Assert:Equals(14, results:TeamA(7)).
        Assert:Equals(15, results:TeamB(7)).
        Assert:Equals(0, results:GoalsA(1)).
        Assert:Equals(0, results:GoalsB(1)).
        DO i = 2 TO 15:
            Assert:Equals(1, mWorld:PointsOf(i)).
        END.
        Assert:Equals(0, mWorld:PointsOf(1)).
        Assert:Equals(0, mWorld:PointsOf(16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryOtherClubPlaysOnceWhateverTheDraw():
        VAR WeekResults results.
        VAR INTEGER seed.
        VAR INTEGER i.
        VAR INTEGER played.
        VAR INTEGER totalFor.
        VAR INTEGER totalAgainst.
        DO seed = 1 TO 40:
            mWorld = NEW FootballWorld().
            mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
            mWorld:LeagueMatch = 1.
            results = LeagueTable:PlayOthers(mWorld, NEW SeededRandom(seed)).
            Assert:Equals(7, results:Count).
            played = 0.
            totalFor = 0.
            totalAgainst = 0.
            DO i = 1 TO 7:
                Assert:IsTrue(results:TeamA(i) <> 1 AND results:TeamA(i) <> 16 AND results:TeamB(i) <> 1 AND results:TeamB(i) <> 16).
                Assert:IsTrue(results:TeamA(i) <> results:TeamB(i)).
                Assert:IsTrue(results:GoalsA(i) >= 0 AND results:GoalsA(i) <= 3 AND results:GoalsB(i) >= 0 AND results:GoalsB(i) <= 3).
            END.
            DO i = 2 TO 15:
                totalFor = totalFor + mWorld:GoalsForOf(i).
                totalAgainst = totalAgainst + mWorld:GoalsAgainstOf(i).
                /* a win is 3 points and a draw 1, so a team that played once has 0, 1 or 3 */
                Assert:IsTrue(mWorld:PointsOf(i) = 0 OR mWorld:PointsOf(i) = 1 OR mWorld:PointsOf(i) = 3).
            END.
            Assert:Equals(totalFor, totalAgainst).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTableIsSortedByPointsThenGoalDifferenceThenGoalsScored():
        mWorld:LeagueMatch = 1.
        mWorld:AddResult(5, 12, 0, 0).
        mWorld:AddResult(3, 10, 0, 0).
        mWorld:AddResult(7, 6, 4, 2).
        mWorld:AddResult(8, 6, 2, 1).
        mWorld:AddResult(9, 6, 5, 4).
        LeagueTable:Sort(mWorld).
        Assert:Equals(1, mWorld:PlaceOf(5)).
        Assert:Equals(2, mWorld:PlaceOf(3)).
        /* goal difference +2 */
        Assert:Equals(3, mWorld:PlaceOf(7)).
        /* both +1, and 9 scored more */
        Assert:Equals(4, mWorld:PlaceOf(9)).
        Assert:Equals(5, mWorld:PlaceOf(8)).
        Assert:Equals(5, mWorld:TeamAt(1)).
        Assert:Equals(8, mWorld:TeamAt(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TeamsThatAreLevelInEverythingEndUpInReverseOrderAsInTheOriginal():
        mWorld:LeagueMatch = 1.
        LeagueTable:Sort(mWorld).
        Assert:Equals(1, mWorld:PlaceOf(16)).
        Assert:Equals(16, mWorld:PlaceOf(1)).
        Assert:Equals(16, mWorld:TeamAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTeamGetsAPlaceOfItsOwn():
        VAR INTEGER i.
        VAR INTEGER total.
        mWorld:LeagueMatch = 5.
        mWorld:AddResult(4, 7, 3, 1).
        mWorld:AddResult(11, 7, 3, 1).
        LeagueTable:Sort(mWorld).
        DO i = 1 TO 16:
            total = total + mWorld:PlaceOf(i).
        END.
        Assert:Equals(136, total).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSeasonIsOverWhenFifteenMatchesAreDoneAndTheCupIsOver():
        Assert:IsFalse(LeagueTable:SeasonOver(mWorld)).
        mWorld:LeagueMatch = 15.
        Assert:IsFalse(LeagueTable:SeasonOver(mWorld)).
        mWorld:CupOver = TRUE.
        Assert:IsTrue(LeagueTable:SeasonOver(mWorld)).
        mWorld:LeagueMatch = 14.
        Assert:IsFalse(LeagueTable:SeasonOver(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlaceInTheTopThreeOfTheFourthDivisionIsPromotedInPlaceOfAClubOfTheThirdDivision():
        VAR SeasonMove move.
        FinishedSeason(2).
        move = LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(SeasonMove:Promoted), INTEGER(move)).
        /* the club went to slot 46 (the 14th of the division above) and the club from there to 64 */
        Assert:Equals(46, mWorld:Slot).
        Assert:Equals("Arsenal", mWorld:ClubName(46)).
        Assert:Equals(FootballNames:Club(46), mWorld:ClubName(64)).
        Assert:Equals(3, mWorld:Division).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOtherPromotedClubsGoUpToo():
        FinishedSeason(2).
        LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        /* team 1 (slot 49, first) took slot 47 and team 3 (slot 51, third) took slot 45 */
        Assert:Equals(FootballNames:Club(49), mWorld:ClubName(47)).
        Assert:Equals(FootballNames:Club(47), mWorld:ClubName(49)).
        Assert:Equals(FootballNames:Club(51), mWorld:ClubName(45)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSeasonsPrizeAndScoreAndTheNewSeasonFollowTheDivisionOfTheManagerNow():
        FinishedSeason(2).
        LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        /* the prize is 15 places above 17, at 5000 in the fourth division */
        Assert:Equals(75000, mWorld:Cash).
        /* 15 for the place and 3 cup rounds at 2 times the fourth division's 4 */
        Assert:Equals(39, mWorld:SeasonScore).
        Assert:Equals(1, mWorld:Seasons).
        /* a new season, in the third division */
        Assert:Equals(0, mWorld:LeagueMatch).
        Assert:Equals(10000, mWorld:Gate).
        Assert:Equals(1000, mWorld:Rent).
        Assert:IsFalse(mWorld:CupOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlaceInTheBottomThreeIsRelegatedAndTakesTheFirstThreeSlotsBelow():
        VAR SeasonMove move.
        mWorld:Slot = 3.
        FinishedSeason(15).
        move = LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(SeasonMove:Relegated), INTEGER(move)).
        /* place 15 goes to the second slot of the division below: 16 + 2 */
        Assert:Equals(18, mWorld:Slot).
        Assert:Equals(2, mWorld:Division).
        /* the prize for place 15 is 2 times 5000 times the first division's 4 */
        Assert:Equals(40000, mWorld:Cash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChampionsOfTheFirstDivisionStayWhereTheyAreAndWinTheBiggestPrize():
        VAR SeasonMove move.
        mWorld:Slot = 3.
        FinishedSeason(1).
        move = LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(SeasonMove:Champions), INTEGER(move)).
        Assert:Equals(3, mWorld:Slot).
        Assert:Equals(320000, mWorld:Cash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMidTablePlaceStaysInTheDivision():
        VAR SeasonMove move.
        mWorld:Slot = 40.
        FinishedSeason(8).
        move = LeagueTable:EndSeason(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(SeasonMove:Stayed), INTEGER(move)).
        Assert:Equals(40, mWorld:Slot).
        /* 9 places above 17, at 5000 times the third division's 2 */
        Assert:Equals(90000, mWorld:Cash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("othersrandom")).
        Assert:IsTrue(Refused("othersearly")).
        Assert:IsTrue(Refused("endrandom")).
        Assert:IsTrue(Refused("endunsorted")).
    END METHOD.

END CLASS.
