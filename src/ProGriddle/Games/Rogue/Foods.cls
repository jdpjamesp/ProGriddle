/* The two foods: a food ration (nine in ten) and a mango, with what each puts back in the hero's stomach. The kinds are the members of
   FoodKind. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Foods FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "90,10".
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS FoodKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "food ration,mango").
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS FoodKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS FoodKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "10,5")).
    END METHOD.

    /* How much eating one adds to the hero's stomach (see RogueRules:StomachSize). */
    METHOD PUBLIC STATIC INTEGER Nutrition(INPUT poKind AS FoodKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "1800,900")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC FoodKind Roll(INPUT poRandom AS IRandom):
        RETURN FoodKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
