/* The five numbers that decide a match, for the manager's team: 1 Energy (the picked players' energy added up and divided by 11, whole), 2 Morale, 3 Defence, 4 Midfield, 5 Attack (the skills of the picked players in that block of the pool added up). Only the picked players count. Each is kept between 1 and 20. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.TeamStrength FINAL:

    /* How many numbers there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 5.
    END METHOD.

    /* The name of number 1 to 5: Energy, Morale, Defence, Midfield, Attack. Throws GridException for any other. */
    METHOD PUBLIC STATIC CHARACTER AttributeName(INPUT piWhich AS INTEGER):
        IF piWhich = ? OR piWhich < 1 OR piWhich > 5 THEN
            UNDO, THROW NEW GridException("There is no team number " + STRING(piWhich)).
        RETURN ENTRY(piWhich, "Energy,Morale,Defence,Midfield,Attack").
    END METHOD.

    /* A number as it adds up, before it is kept between 1 and 20 (so Defence can be 40 with a team of fives). */
    METHOD PUBLIC STATIC INTEGER Raw(INPUT poWorld AS FootballWorld, INPUT piWhich AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER total.
        VAR INTEGER lo.
        IF piWhich = ? OR piWhich < 1 OR piWhich > 5 THEN
            UNDO, THROW NEW GridException("There is no team number " + STRING(piWhich)).
        CASE piWhich:
            WHEN 2 THEN RETURN poWorld:Morale.
            WHEN 1 THEN
            DO:
                DO i = 1 TO FootballRules:PoolSize():
                    IF poWorld:RoleOf(i) = SquadRole:Starter THEN total = total + poWorld:EnergyOf(i).
                END.
                RETURN INTEGER(TRUNCATE(total / FootballRules:TeamSize(), 0)).
            END.
            OTHERWISE
            DO:
                /* defenders are 1 to 8, midfielders 9 to 16, forwards 17 to 24 */
                lo = (piWhich - 3) * 8 + 1.
                DO i = lo TO lo + 7:
                    IF poWorld:RoleOf(i) = SquadRole:Starter THEN total = total + poWorld:SkillOf(i).
                END.
                RETURN total.
            END.
        END CASE.
    END METHOD.

    /* A number kept between 1 and 20, as the match uses it. */
    METHOD PUBLIC STATIC INTEGER Value(INPUT poWorld AS FootballWorld, INPUT piWhich AS INTEGER):
        RETURN MAXIMUM(1, MINIMUM(FootballRules:MaxEnergy(), Raw(poWorld, piWhich))).
    END METHOD.

END CLASS.
