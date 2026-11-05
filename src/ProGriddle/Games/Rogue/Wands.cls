/* The 14 wands of the game: each one's real name, how common it is (chances out of 100, as in the original) and what it is worth when the
   score is added up. The kinds are the members of WandKind, in the order of the lists here. Which unknown name a kind goes by in a given
   game (the colour of a potion) is not here: see Disguises. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Wands FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 14.
    END METHOD.

    /* The chances of every kind, in order, as a comma list that adds up to 100. */
    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "12,6,3,3,3,15,10,10,11,9,1,6,6,5".
    END METHOD.

    /* The real name of a kind, such as "light". */
    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS WandKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "light,invisibility,lightning,fire,cold,polymorph,magic missile,haste monster,slow monster,drain life,nothing,teleport away,teleport to,cancellation").
    END METHOD.

    /* How common a kind is, out of 100. */
    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS WandKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    /* What a kind adds to the score when it is in the pack at the end. */
    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS WandKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "100,5,250,330,330,210,170,5,350,300,5,340,50,280")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC WandKind Roll(INPUT poRandom AS IRandom):
        RETURN WandKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

    /* True for the wands that hurt what they hit: lightning, fire, cold, magic missile and drain life. */
    METHOD PUBLIC STATIC LOGICAL Hurts(INPUT poKind AS WandKind):
        CASE poKind:
            WHEN WandKind:Lightning OR WHEN WandKind:Fire OR WHEN WandKind:Cold OR WHEN WandKind:MagicMissile OR WHEN WandKind:DrainLife THEN RETURN TRUE.
            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

    /* How many charges a new wand has: 3 to 7 for the ones that hurt and 10 to 19 for the rest. */
    METHOD PUBLIC STATIC INTEGER StartingCharges(INPUT poKind AS WandKind, INPUT poRandom AS IRandom):
        RETURN (IF Hurts(poKind) THEN poRandom:NextInt(5) + 3 ELSE poRandom:NextInt(10) + 10).
    END METHOD.

END CLASS.
