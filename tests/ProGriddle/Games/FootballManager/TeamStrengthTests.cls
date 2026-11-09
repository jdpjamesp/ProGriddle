/* The five numbers of a team: energy, morale and the sums of the picked players' skills in defence, midfield and attack. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.TeamStrengthTests:

    VAR PRIVATE FootballWorld mWorld.

    /* A new game where a scripted 0 picks players 1 to 11 to play and 12 as reserve, all with skill 1 and energy 1. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT piWhich AS INTEGER, INPUT plName AS LOGICAL):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            IF plName THEN TeamStrength:AttributeName(piWhich).
            ELSE TeamStrength:Raw(mWorld, piWhich).
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreFiveNumbersWithTheirNames():
        Assert:Equals(5, TeamStrength:Count()).
        Assert:Equals("Energy", TeamStrength:AttributeName(1)).
        Assert:Equals("Morale", TeamStrength:AttributeName(2)).
        Assert:Equals("Defence", TeamStrength:AttributeName(3)).
        Assert:Equals("Midfield", TeamStrength:AttributeName(4)).
        Assert:Equals("Attack", TeamStrength:AttributeName(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSkillsOfThePickedPlayersAddUpBlockByBlock():
        /* players 1 to 8 defend, 9 to 11 are the picked midfielders, nobody picked attacks */
        Assert:Equals(8, TeamStrength:Raw(mWorld, 3)).
        Assert:Equals(3, TeamStrength:Raw(mWorld, 4)).
        Assert:Equals(0, TeamStrength:Raw(mWorld, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyThePickedPlayersCount():
        mWorld:SetSkill(12, 5).
        mWorld:SetRole(17, SquadRole:Reserve).
        mWorld:SetSkill(17, 5).
        Assert:Equals(0, TeamStrength:Raw(mWorld, 5)).
        mWorld:SetRole(17, SquadRole:Starter).
        Assert:Equals(5, TeamStrength:Raw(mWorld, 5)).
        Squad:Drop(mWorld, 1).
        Assert:Equals(7, TeamStrength:Raw(mWorld, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnergyIsTheAverageOfThePickedPlayersRoundedDown():
        VAR INTEGER i.
        DO i = 1 TO 10:
            mWorld:SetEnergy(i, 10).
        END.
        mWorld:SetEnergy(11, 5).
        mWorld:SetEnergy(12, 20).
        Assert:Equals(9, TeamStrength:Raw(mWorld, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnergyDividesByElevenEvenWithFewerPicked():
        VAR INTEGER i.
        DO i = 1 TO 11:
            mWorld:SetEnergy(i, 20).
        END.
        Squad:Drop(mWorld, 11).
        /* ten players of energy 20 over 11 */
        Assert:Equals(18, TeamStrength:Raw(mWorld, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoraleIsTheTeamsMorale():
        mWorld:Morale = 14.
        Assert:Equals(14, TeamStrength:Raw(mWorld, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheValueIsKeptBetweenOneAndTwenty():
        VAR INTEGER i.
        Assert:Equals(1, TeamStrength:Value(mWorld, 5)).
        Assert:Equals(8, TeamStrength:Value(mWorld, 3)).
        DO i = 1 TO 8:
            mWorld:SetSkill(i, 5).
        END.
        Assert:Equals(40, TeamStrength:Raw(mWorld, 3)).
        Assert:Equals(20, TeamStrength:Value(mWorld, 3)).
        mWorld:Morale = 0.
        Assert:Equals(1, TeamStrength:Value(mWorld, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANumberThatIsNotOneToFiveIsRefused():
        Assert:IsTrue(Refused(0, FALSE)).
        Assert:IsTrue(Refused(6, FALSE)).
        Assert:IsTrue(Refused(0, TRUE)).
        Assert:IsTrue(Refused(6, TRUE)).
    END METHOD.

END CLASS.
