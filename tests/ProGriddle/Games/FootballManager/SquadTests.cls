/* What happens to the squad around a match: tiredness, rest and injury before it, and picking the team. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.SquadTests:

    VAR PRIVATE FootballWorld mWorld.

    /* Players 1 to 11 are picked and 12 is in reserve, all with energy 1, and the club has played one league match so far. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        mWorld:LeagueMatch = 2.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "pickpicked" THEN Squad:Pick(mWorld, 1).
                WHEN "pickoutsider" THEN Squad:Pick(mWorld, 20).
                WHEN "pickinjured" THEN
                DO:
                    mWorld:SetRole(12, SquadRole:Injured).
                    Squad:Pick(mWorld, 12).
                END.
                WHEN "dropreserve" THEN Squad:Drop(mWorld, 12).
                WHEN "dropoutsider" THEN Squad:Drop(mWorld, 20).
                WHEN "preparerandom" THEN Squad:Prepare(mWorld, ?).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickedPlayerLosesOneEnergyAndAReserveGainsTen():
        mWorld:SetEnergy(1, 10).
        mWorld:SetEnergy(12, 5).
        Squad:Prepare(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(9, mWorld:EnergyOf(1)).
        Assert:Equals(15, mWorld:EnergyOf(12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerTheClubDoesNotOwnKeepsHisEnergy():
        mWorld:SetEnergy(13, 7).
        Squad:Prepare(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(7, mWorld:EnergyOf(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnergyStaysBetweenOneAndTwenty():
        mWorld:SetEnergy(12, 15).
        Squad:Prepare(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(20, mWorld:EnergyOf(12)).
        /* player 1 had 1 and loses one more: still 1 */
        Assert:Equals(1, mWorld:EnergyOf(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnInjuredPlayerRestsAndComesBackIntoReserve():
        mWorld:SetRole(3, SquadRole:Injured).
        mWorld:SetEnergy(3, 4).
        Squad:Prepare(mWorld, NEW ScriptedRandom("0")).
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(3))).
        Assert:Equals(14, mWorld:EnergyOf(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARollOfTwentyInjuresEveryPlayerTheClubOwnsAndNobodyElse():
        Squad:Prepare(mWorld, NEW ScriptedRandom("19")).
        Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(mWorld:RoleOf(1))).
        Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(mWorld:RoleOf(12))).
        Assert:Equals(INTEGER(SquadRole:NotOwned), INTEGER(mWorld:RoleOf(13))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnyOtherRollInjuresNobody():
        Squad:Prepare(mWorld, NEW ScriptedRandom("18")).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(1))).
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(12))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheVeryFirstMatchOfASeasonChangesNothing():
        mWorld:LeagueMatch = 1.
        mWorld:CupRound = 0.
        mWorld:SetEnergy(1, 10).
        Squad:Prepare(mWorld, NEW ScriptedRandom("19")).
        Assert:Equals(10, mWorld:EnergyOf(1)).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(1))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerInReserveCanBePickedAndAPickedPlayerCanBeDropped():
        Squad:Pick(mWorld, 12).
        Assert:Equals(12, mWorld:StarterCount()).
        Squad:Drop(mWorld, 1).
        Assert:Equals(11, mWorld:StarterCount()).
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(1))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerWhoCannotBePickedOrDroppedIsRefused():
        Assert:IsTrue(Refused("pickpicked")).
        Assert:IsTrue(Refused("pickoutsider")).
        Assert:IsTrue(Refused("pickinjured")).
        Assert:IsTrue(Refused("dropreserve")).
        Assert:IsTrue(Refused("dropoutsider")).
        Assert:IsTrue(Refused("preparerandom")).
    END METHOD.

END CLASS.
