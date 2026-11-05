/* The 14 potions of the game: each one's real name, how common it is (chances out of 100, as in the original) and what it is worth when the
   score is added up. The kinds are the members of PotionKind, in the order of the lists here. Which unknown name a kind goes by in a given
   game (the colour of a potion) is not here: see Disguises. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Potions FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 14.
    END METHOD.

    /* The chances of every kind, in order, as a comma list that adds up to 100. */
    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "7,8,8,13,3,13,6,6,2,5,5,13,5,6".
    END METHOD.

    /* The real name of a kind, such as "confusion". */
    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS PotionKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "confusion,hallucination,poison,gain strength,see invisible,healing,monster detection,magic detection,raise level,extra healing,haste self,restore strength,blindness,levitation").
    END METHOD.

    /* How common a kind is, out of 100. */
    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS PotionKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    /* What a kind adds to the score when it is in the pack at the end. */
    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS PotionKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "5,5,5,150,100,130,130,105,250,200,190,130,5,75")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC PotionKind Roll(INPUT poRandom AS IRandom):
        RETURN PotionKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
