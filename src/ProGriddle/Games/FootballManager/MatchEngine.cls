/* Plays a match. For each of the five numbers (energy, morale, defence, midfield, attack) in turn, each side rolls 1 to 100 and adds 5 for every point its number is above the other side's: reaching 75 gives it two attacks on goal (see PitchAttack). So a side that is 5 ahead attacks half the time, one that is level a quarter of the time and one 15 ahead nearly always. If neither side has scored after all five, each gets one more attack, the home side first. The manager's side attacks first in each round. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchEngine FINAL:

    /* Whether a roll of 1 to 100 earns an attack for a side whose number is piOwn against piOther. */
    METHOD PUBLIC STATIC LOGICAL Attacks(INPUT piRoll AS INTEGER, INPUT piOwn AS INTEGER, INPUT piOther AS INTEGER):
        RETURN piRoll + (piOwn - piOther) * FootballRules:AttackWeight() >= FootballRules:AttackThreshold().
    END METHOD.

    /* Plays a match between the manager's team (numbers piOwn: energy, morale, defence, midfield, attack) and the opposition (piOpp, the same five). piSide is 1 when the manager's club is the home side and 2 when it is the away side. All the random numbers come from poRandom. Throws GridException for a side that is not 1 or 2 or for no random source. */
    METHOD PUBLIC STATIC MatchResult Play(INPUT piOwn AS INTEGER EXTENT 5, INPUT piOpp AS INTEGER EXTENT 5, INPUT piSide AS INTEGER, INPUT poRandom AS IRandom):
        VAR MatchResult result = NEW MatchResult().
        VAR INTEGER o.
        VAR INTEGER other.
        IF piSide <> 1 AND piSide <> 2 THEN UNDO, THROW NEW GridException("A side is 1 (home) or 2 (away), not " + STRING(piSide)).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A match needs a random source").
        other = 3 - piSide.
        DO o = 1 TO 5:
            IF Attacks(poRandom:NextInt(100) + 1, piOwn[o], piOpp[o]) THEN
            DO:
                result:AddAttack(piSide, poRandom).
                result:AddAttack(piSide, poRandom).
            END.
            IF Attacks(poRandom:NextInt(100) + 1, piOpp[o], piOwn[o]) THEN
            DO:
                result:AddAttack(other, poRandom).
                result:AddAttack(other, poRandom).
            END.
        END.
        IF result:HomeGoals + result:AwayGoals = 0 THEN
        DO:
            result:AddAttack(1, poRandom).
            result:AddAttack(2, poRandom).
        END.
        RETURN result.
    END METHOD.

END CLASS.
