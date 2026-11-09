/* What happens to the squad around a match: the update before it (tiredness, rest, injury) and the manager's picking of the team. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Squad FINAL:

    /* The update before a match, for every player of the pool in turn: one who is picked loses 1 energy, one in reserve or injured gains 10 (never outside 1 to 20), a player who was injured goes back into reserve, and each player the club owns has one chance in 20 of being injured now. The very first match of a season (nothing played yet) skips all this. */
    METHOD PUBLIC STATIC VOID Prepare(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        VAR INTEGER i.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("The squad update needs a random source").
        IF poWorld:LeagueMatch = 1 AND poWorld:CupRound = 0 THEN RETURN.
        DO i = 1 TO FootballRules:PoolSize():
            CASE poWorld:RoleOf(i):
                WHEN SquadRole:Starter THEN poWorld:SetEnergy(i, poWorld:EnergyOf(i) - 1).
                WHEN SquadRole:Reserve OR WHEN SquadRole:Injured THEN poWorld:SetEnergy(i, poWorld:EnergyOf(i) + FootballRules:RestEnergy()).
            END CASE.
            IF poWorld:RoleOf(i) = SquadRole:Injured THEN poWorld:SetRole(i, SquadRole:Reserve).
            IF poWorld:RoleOf(i) <> SquadRole:NotOwned THEN
                IF poRandom:NextInt(FootballRules:InjuryOdds()) = FootballRules:InjuryOdds() - 1 THEN poWorld:SetRole(i, SquadRole:Injured).
        END.
    END METHOD.

    /* Picks a player in reserve to play. Throws GridException for a player who is not in reserve (an injured player cannot be picked). */
    METHOD PUBLIC STATIC VOID Pick(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER):
        IF poWorld:RoleOf(piPlayer) <> SquadRole:Reserve THEN
            UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " cannot be picked: he is not in reserve").
        poWorld:SetRole(piPlayer, SquadRole:Starter).
    END METHOD.

    /* Takes a picked player out of the team, back to reserve. Throws GridException for a player who is not picked. */
    METHOD PUBLIC STATIC VOID Drop(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER):
        IF poWorld:RoleOf(piPlayer) <> SquadRole:Starter THEN
            UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " is not in the team").
        poWorld:SetRole(piPlayer, SquadRole:Reserve).
    END METHOD.

END CLASS.
