/* The numbers of the original that the rest of FootballManager leans on: they must not drift. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballRulesTests:

    @Test.
    METHOD PUBLIC VOID TheLeagueIsFourDivisionsOfSixteenWithFifteenMatchesAndEightCupRounds():
        Assert:Equals(4, FootballRules:Divisions()).
        Assert:Equals(16, FootballRules:ClubsPerDivision()).
        Assert:Equals(64, FootballRules:ClubCount()).
        Assert:Equals(15, FootballRules:LeagueMatches()).
        Assert:Equals(8, FootballRules:CupRounds()).
        Assert:Equals(3, FootballRules:MovingClubs()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSquadNumbersAreThoseOfThePool():
        Assert:Equals(24, FootballRules:PoolSize()).
        Assert:Equals(16, FootballRules:SquadMax()).
        Assert:Equals(11, FootballRules:TeamSize()).
        Assert:Equals(12, FootballRules:StartingSquad()).
        Assert:Equals(7, FootballRules:LevelCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SkillEnergyAndMoraleRangesAreThoseOfTheOriginal():
        Assert:Equals(5, FootballRules:MaxSkill()).
        Assert:Equals(20, FootballRules:MaxEnergy()).
        Assert:Equals(10, FootballRules:StartMorale()).
        Assert:Equals(10, FootballRules:RestEnergy()).
        Assert:Equals(20, FootballRules:InjuryOdds()).
        Assert:Equals(3, FootballRules:WinPoints()).
        Assert:Equals(1, FootballRules:DrawPoints()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMatchEngineThresholdsAreThoseOfTheOriginal():
        Assert:Equals(75, FootballRules:AttackThreshold()).
        Assert:Equals(5, FootballRules:AttackWeight()).
        Assert:Equals(32, FootballRules:PitchWidth()).
        Assert:Equals(22, FootballRules:PitchHeight()).
        Assert:IsTrue(FootballRules:MaxBallSteps() > 0).
        Assert:IsTrue(FootballRules:SetupTries() > 0).
        Assert:Equals(22, FootballRules:MostAttacks()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMoneyUnitsAreThoseOfTheOriginal():
        Assert:Equals(5000, FootballRules:ValueUnit()).
        Assert:Equals(100, FootballRules:WageUnit()).
        Assert:Equals(500, FootballRules:RentUnit()).
        Assert:Equals(5000, FootballRules:GateUnit()).
        Assert:Equals(10000, FootballRules:GateCeilingUnit()).
        Assert:Equals(1000, FootballRules:GateFloor()).
        Assert:Equals(500, FootballRules:AwayGateUnit()).
        Assert:Equals(10000, FootballRules:CupAwayUnit()).
        Assert:Equals(50000, FootballRules:SemiFinalGate()).
        Assert:Equals(100000, FootballRules:FinalGate()).
        Assert:Equals(250000, FootballRules:LoanUnit()).
        Assert:Equals(100, FootballRules:InterestDivisor()).
    END METHOD.

END CLASS.
