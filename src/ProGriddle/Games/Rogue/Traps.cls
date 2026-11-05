/* The eight traps: name and how common (out of 100). A trap is hidden until the hero steps on it or finds it by searching. The kinds
   are the members of TrapKind, in the order of the lists here. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Traps FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "12,13,12,13,12,13,12,13".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS TrapKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "trap door,arrow trap,sleeping gas trap,bear trap,teleport trap,poison dart trap,rust trap,mystic trap").
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS TrapKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC TrapKind Roll(INPUT poRandom AS IRandom):
        RETURN TrapKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
