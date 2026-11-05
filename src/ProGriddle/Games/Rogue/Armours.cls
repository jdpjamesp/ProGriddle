/* The eight suits of armour: name, armour class (lower is better, as in the original: an unarmoured hero has 10), how common and what
   it is worth. The kinds are the members of ArmourKind, in the order of the lists here. Each point of enchantment lowers the armour
   class by one. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Armours FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "20,15,15,13,12,10,8,7".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS ArmourKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "leather armor,ring mail,studded leather armor,scale mail,chain mail,splint mail,banded mail,plate mail").
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS ArmourKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS ArmourKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "20,25,20,30,75,80,90,400")).
    END METHOD.

    /* The armour class of the suit when it is plain (no enchantment): 8 for leather down to 3 for plate. */
    METHOD PUBLIC STATIC INTEGER ArmourClass(INPUT poKind AS ArmourKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "8,7,7,6,5,4,4,3")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC ArmourKind Roll(INPUT poRandom AS IRandom):
        RETURN ArmourKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
