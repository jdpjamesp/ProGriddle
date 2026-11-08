/* Dice written the way the game's tables write them: "2d4" is two four sided dice added up, and "1d2/1d5" is a list of dice (one for each
   attack of a monster) separated by a slash. Every roll goes through the injectable random source, so a seeded one gives the same
   rolls every time. Throws GridException for a spec that is not a number of dice, a d and a number of sides. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Dice FINAL:

    /* The dice of a spec like "2d4": the number of dice, then the sides of each. 0d0 is allowed and always rolls 0. */
    METHOD PRIVATE STATIC INTEGER Part(INPUT pcSpec AS CHARACTER, INPUT piWhich AS INTEGER):
        VAR INTEGER p.
        VAR INTEGER n.
        IF pcSpec = ? THEN UNDO, THROW NEW GridException("Dice need a spec such as 2d4").
        p = INDEX(pcSpec, "d").
        IF p < 2 OR p = LENGTH(pcSpec) THEN UNDO, THROW NEW GridException("Not a dice spec, such as 2d4: " + pcSpec).
        n = INTEGER(SUBSTRING(pcSpec, (IF piWhich = 1 THEN 1 ELSE p + 1), (IF piWhich = 1 THEN p - 1 ELSE LENGTH(pcSpec) - p))) NO-ERROR.
        IF ERROR-STATUS:ERROR OR n = ? OR n < 0 THEN UNDO, THROW NEW GridException("Not a dice spec, such as 2d4: " + pcSpec).
        RETURN n.
    END METHOD.

    /* The number of dice in a spec. */
    METHOD PUBLIC STATIC INTEGER Number(INPUT pcSpec AS CHARACTER):
        RETURN Part(pcSpec, 1).
    END METHOD.

    /* The sides of each die in a spec. */
    METHOD PUBLIC STATIC INTEGER Sides(INPUT pcSpec AS CHARACTER):
        RETURN Part(pcSpec, 2).
    END METHOD.

    /* The lowest and highest total a spec can give (a spec of no dice gives 0 for both). */
    METHOD PUBLIC STATIC INTEGER Lowest(INPUT pcSpec AS CHARACTER):
        IF Sides(pcSpec) = 0 THEN RETURN 0.
        RETURN Number(pcSpec).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Highest(INPUT pcSpec AS CHARACTER):
        RETURN Number(pcSpec) * Sides(pcSpec).
    END METHOD.

    /* Rolls a spec: each die from 1 to its sides, added up. */
    METHOD PUBLIC STATIC INTEGER Roll(INPUT pcSpec AS CHARACTER, INPUT poRandom AS IRandom):
        VAR INTEGER i.
        VAR INTEGER total.
        VAR INTEGER sides.
        sides = Sides(pcSpec).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Dice need a random source").
        IF sides = 0 THEN RETURN 0.
        DO i = 1 TO Number(pcSpec):
            total = total + poRandom:NextInt(sides) + 1.
        END.
        RETURN total.
    END METHOD.

    /* How many attacks a list of dice such as "1d2/1d5/1d5" holds. */
    METHOD PUBLIC STATIC INTEGER Attacks(INPUT pcList AS CHARACTER):
        IF pcList = ? OR pcList = "" THEN UNDO, THROW NEW GridException("A list of dice needs at least one spec").
        RETURN NUM-ENTRIES(pcList, "/").
    END METHOD.

    /* The spec of attack piIndex (1 to Attacks) of a list. */
    METHOD PUBLIC STATIC CHARACTER Attack(INPUT pcList AS CHARACTER, INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 1 OR piIndex > Attacks(pcList) THEN UNDO, THROW NEW GridException("There is no attack " + STRING(piIndex) + " in " + pcList).
        RETURN ENTRY(piIndex, pcList, "/").
    END METHOD.

END CLASS.
