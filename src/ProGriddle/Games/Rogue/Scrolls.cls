/* The 14 scrolls of the game: each one's real name, how common it is (chances out of 100, as in the original) and what it is worth when the
   score is added up. The kinds are the members of ScrollKind, in the order of the lists here. Which unknown name a kind goes by in a given
   game (the colour of a potion) is not here: see Disguises. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Scrolls FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 14.
    END METHOD.

    /* The chances of every kind, in order, as a comma list that adds up to 100. */
    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "30,8,10,7,7,7,5,4,3,4,4,3,4,4".
    END METHOD.

    /* The real name of a kind, such as "identify". */
    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS ScrollKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "identify,enchant armor,enchant weapon,remove curse,monster confusion,teleportation,magic mapping,sleep,hold monster,create monster,scare monster,food detection,aggravate monsters,protect armor").
    END METHOD.

    /* How common a kind is, out of 100. */
    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS ScrollKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    /* What a kind adds to the score when it is in the pack at the end. */
    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS ScrollKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "100,160,150,90,140,120,150,5,180,50,200,100,10,130")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC ScrollKind Roll(INPUT poRandom AS IRandom):
        RETURN ScrollKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
