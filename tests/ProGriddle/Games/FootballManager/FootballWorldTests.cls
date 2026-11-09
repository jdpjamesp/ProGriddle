/* The state of a game of FootballManager: a new game (club, squad, kit, season), what each piece of state allows, and the table lines. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballWorldTests:

    VAR PRIVATE FootballWorld mWorld.

    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
    END METHOD.

    /* Runs one thing a world refuses, named by pcWhat, and says whether it threw a GridException. */
    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "name0" THEN mWorld:NewGame("", 1, 1, 0, NEW ScriptedRandom("0")).
                WHEN "name21" THEN mWorld:NewGame("123456789012345678901", 1, 1, 0, NEW ScriptedRandom("0")).
                WHEN "club0" THEN mWorld:NewGame("Bob", 0, 1, 0, NEW ScriptedRandom("0")).
                WHEN "club65" THEN mWorld:NewGame("Bob", 65, 1, 0, NEW ScriptedRandom("0")).
                WHEN "level0" THEN mWorld:NewGame("Bob", 1, 0, 0, NEW ScriptedRandom("0")).
                WHEN "level8" THEN mWorld:NewGame("Bob", 1, 8, 0, NEW ScriptedRandom("0")).
                WHEN "kit3" THEN mWorld:NewGame("Bob", 1, 1, 3, NEW ScriptedRandom("0")).
                WHEN "norandom" THEN mWorld:NewGame("Bob", 1, 1, 0, ?).
                WHEN "seasonnorandom" THEN mWorld:StartSeason(?).
                WHEN "club" THEN mWorld:ClubName(0).
                WHEN "swap" THEN mWorld:SwapClubs(1, 65).
                WHEN "role" THEN mWorld:RoleOf(25).
                WHEN "setrole" THEN mWorld:SetRole(0, SquadRole:Starter).
                WHEN "skill" THEN mWorld:SkillOf(0).
                WHEN "setskill0" THEN mWorld:SetSkill(1, 0).
                WHEN "setskill6" THEN mWorld:SetSkill(1, 6).
                WHEN "energy" THEN mWorld:EnergyOf(25).
                WHEN "setenergy" THEN mWorld:SetEnergy(0, 5).
                WHEN "worth" THEN mWorld:WorthOf(0).
                WHEN "setworth" THEN mWorld:SetWorth(1, -1).
                WHEN "points" THEN mWorld:PointsOf(0).
                WHEN "for" THEN mWorld:GoalsForOf(17).
                WHEN "against" THEN mWorld:GoalsAgainstOf(0).
                WHEN "result" THEN mWorld:AddResult(17, 1, 1, 1).
                WHEN "place" THEN mWorld:PlaceOf(0).
                WHEN "setplace" THEN mWorld:SetPlace(17, 1).
                WHEN "teamat" THEN mWorld:TeamAt(0).
                WHEN "setteamat" THEN mWorld:SetTeamAt(1, 17).
                WHEN "outsider" THEN mWorld:NthOutsider(25).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewWorldHasTheOriginalClubsInTheirSlots():
        Assert:Equals("Arsenal", mWorld:ClubName(1)).
        Assert:Equals("York City", mWorld:ClubName(64)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameTakesTheChosenClubIntoTheFourthDivisionAndSendsTheOldOneToItsPlace():
        mWorld:NewGame("Bob", 1, 4, 7, NEW ScriptedRandom("0")).
        Assert:Equals("Arsenal", mWorld:ClubName(64)).
        Assert:Equals("York City", mWorld:ClubName(1)).
        Assert:Equals(64, mWorld:Slot).
        Assert:Equals(4, mWorld:Division).
        Assert:Equals(48, mWorld:DivisionBase).
        Assert:Equals(1, mWorld:Multiplier).
        Assert:Equals("Bob", mWorld:ManagerName).
        Assert:Equals(4, mWorld:Level).
        Assert:Equals(7, mWorld:KitColour).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingTheLastClubChangesNothing():
        mWorld:NewGame("Bob", 64, 1, 0, NEW ScriptedRandom("0")).
        Assert:Equals("York City", mWorld:ClubName(64)).
        Assert:Equals("Arsenal", mWorld:ClubName(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsWithTwelvePlayersElevenPickedAndOneInReserve():
        VAR INTEGER i.
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        Assert:Equals(12, mWorld:OwnedCount()).
        Assert:Equals(11, mWorld:StarterCount()).
        Assert:Equals(12, mWorld:OutsiderCount()).
        /* a scripted 0 always takes the first player not owned yet: players 1 to 12 in turn */
        DO i = 1 TO 11:
            Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(i))).
        END.
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(12))).
        Assert:Equals(INTEGER(SquadRole:NotOwned), INTEGER(mWorld:RoleOf(13))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTwelveAreDrawnFromThoseNotYetTaken():
        /* 23 is the last of the 24, then the last of the 23 left (player 23), and so on down */
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("23,22,21,20,19,18,17,16,15,14,13,12,0")).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(24))).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(23))).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(14))).
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(13))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsWithNoMoneyAndNoLoan():
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        Assert:Equals(0, mWorld:Cash).
        Assert:Equals(0, mWorld:Loan).
        Assert:Equals(0, mWorld:LastBalance).
        Assert:Equals(0, mWorld:Seasons).
        Assert:Equals(0, mWorld:ManagerRating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeasonStartGivesEveryPlayerASkillAnEnergyAndAValue():
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        /* a scripted 0 is the lowest of each roll: skill 1 and energy 1 */
        Assert:Equals(1, mWorld:SkillOf(5)).
        Assert:Equals(1, mWorld:EnergyOf(5)).
        Assert:Equals(5000, mWorld:WorthOf(5)).
        mWorld:StartSeason(NEW ScriptedRandom("4,19")).
        Assert:Equals(5, mWorld:SkillOf(5)).
        Assert:Equals(20, mWorld:EnergyOf(5)).
        Assert:Equals(25000, mWorld:WorthOf(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeasonStartScalesValueGateAndRentByTheDivision():
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        Assert:Equals(5000, mWorld:Gate).
        Assert:Equals(500, mWorld:Rent).
        mWorld:Slot = 3.
        mWorld:StartSeason(NEW ScriptedRandom("4,19")).
        Assert:Equals(1, mWorld:Division).
        Assert:Equals(4, mWorld:Multiplier).
        Assert:Equals(20000, mWorld:Gate).
        Assert:Equals(2000, mWorld:Rent).
        Assert:Equals(100000, mWorld:WorthOf(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeasonStartClearsTheTableTheCountersAndMorale():
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        mWorld:AddResult(3, 3, 2, 1).
        mWorld:SetPlace(3, 1).
        mWorld:LeagueMatch = 9.
        mWorld:CupRound = 4.
        mWorld:CupOver = TRUE.
        mWorld:Cycle = 0.
        mWorld:NextHome = 1.
        mWorld:Morale = 3.
        mWorld:StartSeason(NEW ScriptedRandom("0")).
        Assert:Equals(0, mWorld:PointsOf(3)).
        Assert:Equals(0, mWorld:GoalsForOf(3)).
        Assert:Equals(0, mWorld:GoalsAgainstOf(3)).
        Assert:Equals(0, mWorld:PlaceOf(3)).
        Assert:Equals(3, mWorld:TeamAt(3)).
        Assert:Equals(0, mWorld:LeagueMatch).
        Assert:Equals(0, mWorld:CupRound).
        Assert:IsFalse(mWorld:CupOver).
        Assert:Equals(1, mWorld:Cycle).
        Assert:Equals(2, mWorld:NextHome).
        Assert:Equals(10, mWorld:Morale).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeasonStartKeepsTheSquadAsItWas():
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        mWorld:SetRole(3, SquadRole:Injured).
        mWorld:StartSeason(NEW ScriptedRandom("0")).
        Assert:Equals(12, mWorld:OwnedCount()).
        Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(mWorld:RoleOf(3))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDivisionAndMultiplierFollowTheSlot():
        mWorld:Slot = 1.
        Assert:Equals(1, mWorld:Division).
        Assert:Equals(0, mWorld:DivisionBase).
        Assert:Equals(4, mWorld:Multiplier).
        mWorld:Slot = 16.
        Assert:Equals(1, mWorld:Division).
        mWorld:Slot = 17.
        Assert:Equals(2, mWorld:Division).
        Assert:Equals(16, mWorld:DivisionBase).
        Assert:Equals(3, mWorld:Multiplier).
        mWorld:Slot = 40.
        Assert:Equals(3, mWorld:Division).
        Assert:Equals(32, mWorld:DivisionBase).
        Assert:Equals(2, mWorld:Multiplier).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheManagerRatingIsTheAverageSeasonScoreDoubledAndAtMostAHundred():
        mWorld:Seasons = 2.
        mWorld:SeasonScore = 25.
        Assert:Equals(24, mWorld:ManagerRating).
        mWorld:SeasonScore = 400.
        Assert:Equals(100, mWorld:ManagerRating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSettableStateKeepsWhatItIsGiven():
        mWorld:Cash = 12.
        mWorld:Loan = 34.
        mWorld:LastBalance = -5.
        mWorld:Gate = 6000.
        mWorld:Rent = 700.
        mWorld:Morale = 15.
        mWorld:LeagueMatch = 4.
        mWorld:CupRound = 2.
        mWorld:CupOver = TRUE.
        mWorld:Cycle = 2.
        mWorld:NextHome = 1.
        mWorld:Level = 5.
        mWorld:KitColour = 7.
        mWorld:ManagerName = "Ann".
        Assert:Equals(12, mWorld:Cash).
        Assert:Equals(34, mWorld:Loan).
        Assert:Equals(-5, mWorld:LastBalance).
        Assert:Equals(6000, mWorld:Gate).
        Assert:Equals(700, mWorld:Rent).
        Assert:Equals(15, mWorld:Morale).
        Assert:Equals(4, mWorld:LeagueMatch).
        Assert:Equals(2, mWorld:CupRound).
        Assert:IsTrue(mWorld:CupOver).
        Assert:Equals(2, mWorld:Cycle).
        Assert:Equals(1, mWorld:NextHome).
        Assert:Equals(5, mWorld:Level).
        Assert:Equals(7, mWorld:KitColour).
        Assert:Equals("Ann", mWorld:ManagerName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SwapClubsExchangesTwoSlots():
        mWorld:SwapClubs(1, 17).
        Assert:Equals("Blackburn", mWorld:ClubName(1)).
        Assert:Equals("Arsenal", mWorld:ClubName(17)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayersRoleSkillEnergyAndValueCanBeSet():
        mWorld:SetRole(7, SquadRole:Starter).
        mWorld:SetSkill(7, 4).
        mWorld:SetEnergy(7, 12).
        mWorld:SetWorth(7, 31000).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(7))).
        Assert:Equals(4, mWorld:SkillOf(7)).
        Assert:Equals(12, mWorld:EnergyOf(7)).
        Assert:Equals(31000, mWorld:WorthOf(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnergyIsKeptBetweenOneAndTwenty():
        mWorld:SetEnergy(2, 35).
        Assert:Equals(20, mWorld:EnergyOf(2)).
        mWorld:SetEnergy(2, -4).
        Assert:Equals(1, mWorld:EnergyOf(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CountsSeeTheRolesGivenToPlayers():
        mWorld:SetRole(1, SquadRole:Starter).
        mWorld:SetRole(2, SquadRole:Starter).
        mWorld:SetRole(3, SquadRole:Reserve).
        mWorld:SetRole(4, SquadRole:Injured).
        Assert:Equals(4, mWorld:OwnedCount()).
        Assert:Equals(2, mWorld:StarterCount()).
        Assert:Equals(20, mWorld:OutsiderCount()).
        Assert:Equals(5, mWorld:NthOutsider(1)).
        Assert:Equals(24, mWorld:NthOutsider(20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AResultAddsToATeamsLineOfTheTable():
        mWorld:AddResult(5, 3, 2, 1).
        mWorld:AddResult(5, 1, 0, 0).
        Assert:Equals(4, mWorld:PointsOf(5)).
        Assert:Equals(2, mWorld:GoalsForOf(5)).
        Assert:Equals(1, mWorld:GoalsAgainstOf(5)).
        Assert:Equals(0, mWorld:PointsOf(6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlacesAndTheSortedOrderCanBeSet():
        mWorld:SetPlace(9, 2).
        Assert:Equals(2, mWorld:PlaceOf(9)).
        mWorld:SetTeamAt(1, 9).
        Assert:Equals(9, mWorld:TeamAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsOutOfRangeAreRefused():
        Assert:IsTrue(Refused("name0")).
        Assert:IsTrue(Refused("name21")).
        Assert:IsTrue(Refused("club0")).
        Assert:IsTrue(Refused("club65")).
        Assert:IsTrue(Refused("level0")).
        Assert:IsTrue(Refused("level8")).
        Assert:IsTrue(Refused("kit3")).
        Assert:IsTrue(Refused("norandom")).
        Assert:IsTrue(Refused("seasonnorandom")).
        Assert:IsTrue(Refused("club")).
        Assert:IsTrue(Refused("swap")).
        Assert:IsTrue(Refused("role")).
        Assert:IsTrue(Refused("setrole")).
        Assert:IsTrue(Refused("skill")).
        Assert:IsTrue(Refused("setskill0")).
        Assert:IsTrue(Refused("setskill6")).
        Assert:IsTrue(Refused("energy")).
        Assert:IsTrue(Refused("setenergy")).
        Assert:IsTrue(Refused("worth")).
        Assert:IsTrue(Refused("setworth")).
        Assert:IsTrue(Refused("points")).
        Assert:IsTrue(Refused("for")).
        Assert:IsTrue(Refused("against")).
        Assert:IsTrue(Refused("result")).
        Assert:IsTrue(Refused("place")).
        Assert:IsTrue(Refused("setplace")).
        Assert:IsTrue(Refused("teamat")).
        Assert:IsTrue(Refused("setteamat")).
        Assert:IsTrue(Refused("outsider")).
    END METHOD.

END CLASS.
