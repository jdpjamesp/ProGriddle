/* The words for an item, the way the original says them: "a red potion" until the colour is known and then "a potion of healing", "a
   scroll entitled 'ab ga'", "3 food rations", "a +1,+1 mace", "ring mail [AC 6]", "an iron wand", "a ruby ring". What the hero has learnt
   comes from Disguises (the kind) and from the item itself (Known: the plus of a weapon, armour, ring or wand). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ItemText FINAL:

    /* "a" or "an" for a word. */
    METHOD PUBLIC STATIC CHARACTER Article(INPUT pcWord AS CHARACTER):
        IF pcWord = ? OR pcWord = "" THEN RETURN "a".
        RETURN (IF INDEX("aeiou", SUBSTRING(pcWord, 1, 1)) > 0 THEN "an" ELSE "a").
    END METHOD.

    /* The item in words, with its count or an article in front, and nothing about whether it is worn or wielded (the pack list adds that). */
    METHOD PUBLIC STATIC CHARACTER Describe(INPUT poItem AS Item, INPUT poDisguises AS Disguises):
        DEFINE VARIABLE noun AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poItem) THEN UNDO, THROW NEW GridException("There is no item to describe").
        IF NOT VALID-OBJECT(poDisguises) THEN UNDO, THROW NEW GridException("Describing an item needs the disguises of the game").
        CASE poItem:Category:
            WHEN ItemType:Gold THEN RETURN SUBSTITUTE("&1 pieces of gold", poItem:Count).
            WHEN ItemType:Amulet THEN RETURN "the Amulet of Yendor".
            OTHERWISE DO:
                noun = Noun(poItem, poDisguises).
                IF poItem:Count > 1 THEN RETURN STRING(poItem:Count) + " " + Plural(noun, poItem).
                RETURN Article(noun) + " " + noun.
            END.
        END CASE.
    END METHOD.

    /* The item without a count or an article: "potion of healing", "red potion", "+1,+1 mace", "iron wand [3 charges]". */
    METHOD PUBLIC STATIC CHARACTER Noun(INPUT poItem AS Item, INPUT poDisguises AS Disguises):
        DEFINE VARIABLE known AS LOGICAL NO-UNDO.
        IF NOT VALID-OBJECT(poItem) THEN UNDO, THROW NEW GridException("There is no item to describe").
        IF NOT VALID-OBJECT(poDisguises) THEN UNDO, THROW NEW GridException("Describing an item needs the disguises of the game").
        CASE poItem:Category:
            WHEN ItemType:Gold THEN RETURN "pieces of gold".
            WHEN ItemType:Amulet THEN RETURN "Amulet of Yendor".
            WHEN ItemType:Food THEN RETURN Foods:NameOf(FoodKind:GetEnum(poItem:Kind)).
            WHEN ItemType:Weapon THEN RETURN (IF poItem:Known THEN SUBSTITUTE("&1,&2 &3", Signed(poItem:Bonus), Signed(poItem:DamageBonus), Weapons:NameOf(WeaponKind:GetEnum(poItem:Kind)))
                                              ELSE Weapons:NameOf(WeaponKind:GetEnum(poItem:Kind))).
            WHEN ItemType:Armour THEN RETURN (IF poItem:Known THEN SUBSTITUTE("&1 &2 [AC &3]", Signed(poItem:Bonus), Armours:NameOf(ArmourKind:GetEnum(poItem:Kind)), Armours:ArmourClass(ArmourKind:GetEnum(poItem:Kind)) - poItem:Bonus)
                                              ELSE Armours:NameOf(ArmourKind:GetEnum(poItem:Kind)) + " [AC " + STRING(Armours:ArmourClass(ArmourKind:GetEnum(poItem:Kind))) + "]").
            WHEN ItemType:Potion THEN DO:
                known = poDisguises:IsKnown(ItemType:Potion, poItem:Kind).
                RETURN (IF known THEN "potion of " + Potions:NameOf(PotionKind:GetEnum(poItem:Kind)) ELSE poDisguises:Appearance(ItemType:Potion, poItem:Kind) + " potion").
            END.
            WHEN ItemType:Scroll THEN DO:
                known = poDisguises:IsKnown(ItemType:Scroll, poItem:Kind).
                RETURN (IF known THEN "scroll of " + Scrolls:NameOf(ScrollKind:GetEnum(poItem:Kind)) ELSE "scroll entitled '" + poDisguises:Appearance(ItemType:Scroll, poItem:Kind) + "'").
            END.
            WHEN ItemType:Wand THEN DO:
                known = poDisguises:IsKnown(ItemType:Wand, poItem:Kind).
                IF NOT known THEN RETURN poDisguises:Appearance(ItemType:Wand, poItem:Kind) + " wand".
                RETURN "wand of " + Wands:NameOf(WandKind:GetEnum(poItem:Kind)) + (IF poItem:Known THEN SUBSTITUTE(" [&1 charges]", poItem:Charges) ELSE "").
            END.
            WHEN ItemType:Ring THEN DO:
                known = poDisguises:IsKnown(ItemType:Ring, poItem:Kind).
                IF NOT known THEN RETURN poDisguises:Appearance(ItemType:Ring, poItem:Kind) + " ring".
                RETURN "ring of " + Rings:NameOf(RingKind:GetEnum(poItem:Kind)) + (IF poItem:Known AND HasBonus(poItem) THEN " [" + Signed(poItem:Bonus) + "]" ELSE "").
            END.
        END CASE.
        RETURN "thing".
    END METHOD.

    /* The noun of a stack in the plural: "potions of healing", "red potions", "mangoes", "arrows", "shuriken". */
    METHOD PUBLIC STATIC CHARACTER Plural(INPUT pcNoun AS CHARACTER, INPUT poItem AS Item):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        IF poItem:Category = ItemType:Weapon AND poItem:Kind = INTEGER(WeaponKind:Shuriken) THEN RETURN pcNoun.
        /* the noun of a potion or a scroll has more words after the sort ("potion of healing"): the s goes on the sort */
        p = INDEX(pcNoun, " of ").
        IF p = 0 THEN p = INDEX(pcNoun, " entitled ").
        IF p > 0 THEN RETURN Pluralise(SUBSTRING(pcNoun, 1, p - 1)) + SUBSTRING(pcNoun, p).
        RETURN Pluralise(pcNoun).
    END METHOD.

    METHOD PRIVATE STATIC CHARACTER Pluralise(INPUT pcWord AS CHARACTER):
        IF pcWord MATCHES "*mango" THEN RETURN pcWord + "es".
        RETURN pcWord + "s".
    END METHOD.

    /* A number with its sign: "+1", "-2", "+0". */
    METHOD PUBLIC STATIC CHARACTER Signed(INPUT piValue AS INTEGER):
        RETURN (IF piValue >= 0 THEN "+" ELSE "") + STRING(piValue).
    END METHOD.

    /* True for the rings that have a size: protection, strength, dexterity and damage. */
    METHOD PUBLIC STATIC LOGICAL HasBonus(INPUT poItem AS Item):
        IF poItem:Category <> ItemType:Ring THEN RETURN FALSE.
        CASE RingKind:GetEnum(poItem:Kind):
            WHEN RingKind:Protection OR WHEN RingKind:AddStrength OR WHEN RingKind:Dexterity OR WHEN RingKind:IncreaseDamage THEN RETURN TRUE.
            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

END CLASS.
