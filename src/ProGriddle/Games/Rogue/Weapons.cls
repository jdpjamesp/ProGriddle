/* The nine weapons: name, damage swung (wielded), damage thrown, how common, what it is worth, and whether it comes in stacks that are
   thrown (arrows, darts and shuriken). The bow does almost nothing in the hand: it is wielded to shoot arrows, which do their
   real damage only when fired from it. The kinds are the members of WeaponKind, in the order of the lists here. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Weapons FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 9.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "11,11,8,10,8,12,12,14,14".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS WeaponKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "mace,long sword,dagger,two-handed sword,spear,bow,arrow,dart,shuriken").
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS WeaponKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS WeaponKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "8,15,3,30,5,15,1,2,5")).
    END METHOD.

    /* The dice of a blow in the hand, such as "2d4". */
    METHOD PUBLIC STATIC CHARACTER Swing(INPUT poKind AS WeaponKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "2d4,1d10,1d6,3d6,1d8,1d1,1d1,1d1,1d2").
    END METHOD.

    /* The dice of a hit when the thing is thrown. An arrow does this only when shot from a wielded bow: thrown by hand it does its swing (1d1). */
    METHOD PUBLIC STATIC CHARACTER Hurled(INPUT poKind AS WeaponKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "1d3,1d2,1d4,1d2,1d6,1d1,1d6,1d3,1d4").
    END METHOD.

    /* True for the kinds that come in stacks: arrows, darts and shuriken. */
    METHOD PUBLIC STATIC LOGICAL Stacks(INPUT poKind AS WeaponKind):
        RETURN INTEGER(poKind) >= INTEGER(WeaponKind:Arrow).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC WeaponKind Roll(INPUT poRandom AS IRandom):
        RETURN WeaponKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
