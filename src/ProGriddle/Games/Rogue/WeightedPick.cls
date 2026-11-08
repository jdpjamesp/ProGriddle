/* Picks one of several things with different chances, the way the game's tables do: the chances are a comma list of whole numbers
   ("26,36,16,7,7,4,4"), and a thing with 36 has 36 chances in the total. The pick is made with the injectable random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.WeightedPick FINAL:

    /* The total of a list of chances. Throws GridException for a list that is empty or holds anything but whole numbers of 0 or more. */
    METHOD PUBLIC STATIC INTEGER Total(INPUT pcChances AS CHARACTER):
        VAR INTEGER i.
        VAR INTEGER n.
        VAR INTEGER t.
        IF pcChances = ? OR pcChances = "" THEN UNDO, THROW NEW GridException("A list of chances cannot be empty").
        DO i = 1 TO NUM-ENTRIES(pcChances):
            n = INTEGER(ENTRY(i, pcChances)) NO-ERROR.
            IF ERROR-STATUS:ERROR OR n = ? OR n < 0 THEN UNDO, THROW NEW GridException("Not a list of chances: " + pcChances).
            t = t + n.
        END.
        RETURN t.
    END METHOD.

    /* The position of the pick, from 0: the thing at position 0 for a roll in the first chances and so on. Throws GridException for a
       total of 0 or no random source. */
    METHOD PUBLIC STATIC INTEGER Choose(INPUT pcChances AS CHARACTER, INPUT poRandom AS IRandom):
        VAR INTEGER total.
        VAR INTEGER roll.
        VAR INTEGER i.
        total = Total(pcChances).
        IF total = 0 THEN UNDO, THROW NEW GridException("A list of chances needs a total above 0").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A pick needs a random source").
        roll = poRandom:NextInt(total).
        DO i = 1 TO NUM-ENTRIES(pcChances):
            roll = roll - INTEGER(ENTRY(i, pcChances)).
            IF roll < 0 THEN RETURN i - 1.
        END.
        RETURN NUM-ENTRIES(pcChances) - 1.
    END METHOD.

END CLASS.
