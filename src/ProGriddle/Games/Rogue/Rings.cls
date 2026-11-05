/* The 14 rings of the game: each one's real name, how common it is (chances out of 100, as in the original) and what it is worth when the
   score is added up. The kinds are the members of RingKind, in the order of the lists here. Which unknown name a kind goes by in a given
   game (the colour of a potion) is not here: see Disguises. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Rings FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 14.
    END METHOD.

    /* The chances of every kind, in order, as a comma list that adds up to 100. */
    METHOD PUBLIC STATIC CHARACTER Chances():
        RETURN "9,9,5,10,10,1,10,8,8,4,9,5,7,5".
    END METHOD.

    /* The real name of a kind, such as "protection". */
    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS RingKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "protection,add strength,sustain strength,searching,see invisible,adornment,aggravate monster,dexterity,increase damage,regeneration,slow digestion,teleportation,stealth,maintain armor").
    END METHOD.

    /* How common a kind is, out of 100. */
    METHOD PUBLIC STATIC INTEGER Chance(INPUT poKind AS RingKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, Chances())).
    END METHOD.

    /* What a kind adds to the score when it is in the pack at the end. */
    METHOD PUBLIC STATIC INTEGER Worth(INPUT poKind AS RingKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "400,400,280,420,310,10,10,440,400,460,240,30,470,380")).
    END METHOD.

    /* A kind picked by its chance. */
    METHOD PUBLIC STATIC RingKind Roll(INPUT poRandom AS IRandom):
        RETURN RingKind:GetEnum(WeightedPick:Choose(Chances(), poRandom)).
    END METHOD.

END CLASS.
