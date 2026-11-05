/* One thing in the dungeon: gold, food, a weapon, a suit of armour, a potion, a scroll, a wand, a ring or the amulet. It is a record of
   what it is and its state, with no rules of its own (what a potion does is in the game). Kind is the number of the member of the enum
   of its sort (PotionKind and so on), 0 for gold and the amulet. Count is how many of a stack, or the pieces of a pile of gold.
   Bonus and DamageBonus are the plus of a weapon (to hit and to damage), the enchantment of armour, or the strength of a ring that has
   one; Charges is what a wand has left. A cursed thing is stuck to the hero once worn or wielded, and Known says that the hero has
   learnt its plus (the kind itself is learnt in Disguises). Warded armour cannot rust. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Item FINAL:

    DEFINE PUBLIC PROPERTY Category AS ItemType NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Kind AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO INITIAL 1
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Bonus AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY DamageBonus AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Charges AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Cursed AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Known AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Warded AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Throws GridException for no type. */
    CONSTRUCTOR PUBLIC Item(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        IF NOT VALID-OBJECT(poType) THEN UNDO, THROW NEW GridException("An item needs a type").
        IF piKind = ? OR piKind < 0 THEN UNDO, THROW NEW GridException("An item needs a kind of 0 or more").
        Category = poType.
        Kind = piKind.
    END CONSTRUCTOR.

    /* True for a sort that comes in stacks of the same kind: potions, scrolls and food, and the arrows, darts and shuriken. */
    METHOD PUBLIC LOGICAL Stackable():
        CASE Category:
            WHEN ItemType:Potion OR WHEN ItemType:Scroll OR WHEN ItemType:Food THEN RETURN TRUE.
            WHEN ItemType:Weapon THEN RETURN Weapons:Stacks(WeaponKind:GetEnum(Kind)).
            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

    /* True when the other item is the same sort, kind and plus, and can be joined to this one in a stack. */
    METHOD PUBLIC LOGICAL StacksWith(INPUT poOther AS Item):
        IF NOT VALID-OBJECT(poOther) OR NOT Stackable() THEN RETURN FALSE.
        RETURN poOther:Category = Category AND poOther:Kind = Kind AND poOther:Bonus = Bonus AND poOther:DamageBonus = DamageBonus AND poOther:Cursed = Cursed.
    END METHOD.

    /* A copy of this item with a count of piCount. */
    METHOD PUBLIC Item Duplicate(INPUT piCount AS INTEGER):
        DEFINE VARIABLE oCopy AS Item NO-UNDO.
        oCopy = NEW Item(Category, Kind).
        oCopy:Count = piCount.
        oCopy:Bonus = Bonus.
        oCopy:DamageBonus = DamageBonus.
        oCopy:Charges = Charges.
        oCopy:Cursed = Cursed.
        oCopy:Known = Known.
        oCopy:Warded = Warded.
        RETURN oCopy.
    END METHOD.

    /* What the item adds to the score when the game ends with it in the pack: gold is worth its pieces, everything else what its table says
       times its count, and the amulet a great deal. */
    METHOD PUBLIC INTEGER Worth():
        CASE Category:
            WHEN ItemType:Gold THEN RETURN Count.
            WHEN ItemType:Food THEN RETURN Foods:Worth(FoodKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Weapon THEN RETURN Weapons:Worth(WeaponKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Armour THEN RETURN Armours:Worth(ArmourKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Potion THEN RETURN Potions:Worth(PotionKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Scroll THEN RETURN Scrolls:Worth(ScrollKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Wand THEN RETURN Wands:Worth(WandKind:GetEnum(Kind)) * Count.
            WHEN ItemType:Ring THEN RETURN Rings:Worth(RingKind:GetEnum(Kind)) * Count.
            OTHERWISE RETURN 1000.
        END CASE.
    END METHOD.

END CLASS.
