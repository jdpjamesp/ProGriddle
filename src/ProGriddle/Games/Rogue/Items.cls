/* Makes items: the ones lying about a level and the hero's kit. A random item is a potion (26 chances in 100), a scroll (36), food (16),
   a weapon (7), a suit of armour (7), a ring (4) or a wand (4), then of a kind by that sort's own table. Weapons and armour are cursed
   now and then (a minus) and sometimes better than plain (a plus); rings of the kinds with a size have one, and some are cursed;
   wands have charges. Stacks of arrows, darts and shuriken are 8 to 15. Everything goes through the random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Items FINAL:

    /* The sorts of a random item in the order of the chances "26,36,16,7,7,4,4". */
    METHOD PRIVATE STATIC ItemType SortAt(INPUT piIndex AS INTEGER):
        CASE piIndex:
            WHEN 0 THEN RETURN ItemType:Potion.
            WHEN 1 THEN RETURN ItemType:Scroll.
            WHEN 2 THEN RETURN ItemType:Food.
            WHEN 3 THEN RETURN ItemType:Weapon.
            WHEN 4 THEN RETURN ItemType:Armour.
            WHEN 5 THEN RETURN ItemType:Ring.
            OTHERWISE RETURN ItemType:Wand.
        END CASE.
    END METHOD.

    /* A plain item of a sort and a kind: one of it, no plus, not cursed. */
    METHOD PUBLIC STATIC Item Make(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        RETURN NEW Item(poType, piKind).
    END METHOD.

    /* A pile of gold for a depth: from 2 to 51 pieces on the first level and 10 more at most for each level below. */
    METHOD PUBLIC STATIC Item Gold(INPUT piDepth AS INTEGER, INPUT poRandom AS IRandom):
        VAR Item oGold = NEW Item(ItemType:Gold, 0).
        oGold:Count = poRandom:NextInt(50 + 10 * MAXIMUM(1, piDepth)) + 2.
        RETURN oGold.
    END METHOD.

    /* The Amulet of Yendor. */
    METHOD PUBLIC STATIC Item Amulet():
        RETURN NEW Item(ItemType:Amulet, 0).
    END METHOD.

    /* A random item. */
    METHOD PUBLIC STATIC Item Roll(INPUT poRandom AS IRandom):
        VAR ItemType oType.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("An item roll needs a random source").
        oType = SortAt(WeightedPick:Choose("26,36,16,7,7,4,4", poRandom)).
        RETURN OfSort(oType, poRandom).
    END METHOD.

    /* A random item of a sort (not gold or the amulet). */
    METHOD PUBLIC STATIC Item OfSort(INPUT poType AS ItemType, INPUT poRandom AS IRandom):
        VAR Item oItem.
        CASE poType:
            WHEN ItemType:Potion THEN RETURN NEW Item(ItemType:Potion, INTEGER(Potions:Roll(poRandom))).
            WHEN ItemType:Scroll THEN RETURN NEW Item(ItemType:Scroll, INTEGER(Scrolls:Roll(poRandom))).
            WHEN ItemType:Food THEN RETURN NEW Item(ItemType:Food, INTEGER(Foods:Roll(poRandom))).
            WHEN ItemType:Weapon THEN DO:
                oItem = NEW Item(ItemType:Weapon, INTEGER(Weapons:Roll(poRandom))).
                IF Weapons:Stacks(WeaponKind:GetEnum(oItem:Kind)) THEN oItem:Count = 8 + poRandom:NextInt(8).
                IF poRandom:NextInt(100) < 10 THEN DO:
                    oItem:Cursed = TRUE.
                    oItem:Bonus = - (poRandom:NextInt(3) + 1).
                END.
                ELSE IF poRandom:NextInt(100) < 5 THEN oItem:Bonus = poRandom:NextInt(3) + 1.
                IF poRandom:NextInt(100) < 5 THEN oItem:DamageBonus = poRandom:NextInt(3) + 1.
                RETURN oItem.
            END.
            WHEN ItemType:Armour THEN DO:
                oItem = NEW Item(ItemType:Armour, INTEGER(Armours:Roll(poRandom))).
                IF poRandom:NextInt(100) < 20 THEN DO:
                    oItem:Cursed = TRUE.
                    oItem:Bonus = - (poRandom:NextInt(3) + 1).
                END.
                ELSE IF poRandom:NextInt(100) < 28 THEN oItem:Bonus = poRandom:NextInt(3) + 1.
                RETURN oItem.
            END.
            WHEN ItemType:Ring THEN DO:
                oItem = NEW Item(ItemType:Ring, INTEGER(Rings:Roll(poRandom))).
                CASE RingKind:GetEnum(oItem:Kind):
                    WHEN RingKind:Protection OR WHEN RingKind:AddStrength OR WHEN RingKind:Dexterity OR WHEN RingKind:IncreaseDamage THEN DO:
                        oItem:Bonus = poRandom:NextInt(3) + 1.
                        IF poRandom:NextInt(100) < 30 THEN DO:
                            oItem:Bonus = - oItem:Bonus.
                            oItem:Cursed = TRUE.
                        END.
                    END.
                    WHEN RingKind:Aggravation OR WHEN RingKind:Teleportation THEN oItem:Cursed = TRUE.
                END CASE.
                RETURN oItem.
            END.
            WHEN ItemType:Wand THEN DO:
                oItem = NEW Item(ItemType:Wand, INTEGER(Wands:Roll(poRandom))).
                oItem:Charges = Wands:StartingCharges(WandKind:GetEnum(oItem:Kind), poRandom).
                RETURN oItem.
            END.
            OTHERWISE UNDO, THROW NEW GridException("A random item is not made of " + STRING(poType)).
        END CASE.
    END METHOD.

END CLASS.
