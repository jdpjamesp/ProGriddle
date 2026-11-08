/* Looking for what is hidden. Searching looks at the eight squares round the hero and finds each secret door (it becomes an ordinary
   door) and each hidden trap (it is shown from then on) with a chance of one in three; a ring of searching does it by itself every turn.
   A trap that has been found is not sprung by walking on it only if the hero floats over it: it is still there. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Exploring FINAL:

    /* Searches round the hero once. Gives how many things were found (each is said to the hero). */
    METHOD PUBLIC STATIC INTEGER Search(INPUT poWorld AS RogueWorld):
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER found.
        DO dy = -1 TO 1:
            DO dx = -1 TO 1:
                x = poWorld:Hero:X + dx.
                y = poWorld:Hero:Y + dy.
                IF poWorld:Cave:IsSecret(x, y) AND poWorld:Random:NextInt(3) = 0 THEN DO:
                    poWorld:Cave:SetTerrain(x, y, Terrain:Door).
                    poWorld:Cave:SetSeen(x, y, TRUE).
                    poWorld:Say("You find a secret door.").
                    found = found + 1.
                END.
                IF poWorld:Cave:TrapAt(x, y) > 0 AND NOT poWorld:Cave:TrapFound(x, y) AND poWorld:Random:NextInt(3) = 0 THEN DO:
                    poWorld:Cave:SetTrapFound(x, y, TRUE).
                    poWorld:Say("You find " + ItemText:Article(Traps:NameOf(TrapKind:GetEnum(poWorld:Cave:TrapAt(x, y) - 1))) + " " + Traps:NameOf(TrapKind:GetEnum(poWorld:Cave:TrapAt(x, y) - 1)) + ".").
                    found = found + 1.
                END.
            END.
        END.
        RETURN found.
    END METHOD.

END CLASS.
