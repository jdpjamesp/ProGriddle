/* Making items: plain ones, gold for a depth, the amulet and random ones with their pluses, curses and charges. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ItemsTests:

    @Test.
    METHOD PUBLIC VOID APlainItemIsOneOfItsKindWithNoPlus():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = Items:Make(ItemType:Armour, INTEGER(ArmourKind:ChainMail)).
        Assert:Equals(ItemType:Armour, oItem:Category).
        Assert:Equals(INTEGER(ArmourKind:ChainMail), oItem:Kind).
        Assert:Equals(0, oItem:Bonus).
        Assert:Equals(1, oItem:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GoldGrowsWithTheDepth():
        Assert:Equals(2, Items:Gold(1, NEW ScriptedRandom("0")):Count).
        Assert:Equals(61, Items:Gold(1, NEW ScriptedRandom("59")):Count).
        Assert:Equals(2, Items:Gold(10, NEW ScriptedRandom("0")):Count).
        Assert:Equals(151, Items:Gold(10, NEW ScriptedRandom("149")):Count).
        Assert:Equals(ItemType:Gold, Items:Gold(3, NEW ScriptedRandom("5")):Category).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAmuletIsTheAmulet():
        Assert:Equals(ItemType:Amulet, Items:Amulet():Category).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSortOfARandomItemFollowsTheChances():
        /* 26 potions, 36 scrolls, 16 food, 7 weapons, 7 armour, 4 rings, 4 wands */
        Assert:Equals(ItemType:Potion, Items:Roll(NEW ScriptedRandom("0,0")):Category).
        Assert:Equals(ItemType:Scroll, Items:Roll(NEW ScriptedRandom("26,0")):Category).
        Assert:Equals(ItemType:Food, Items:Roll(NEW ScriptedRandom("62,0")):Category).
        Assert:Equals(ItemType:Weapon, Items:Roll(NEW ScriptedRandom("78,0,99,99,99")):Category).
        Assert:Equals(ItemType:Armour, Items:Roll(NEW ScriptedRandom("85,0,99,99")):Category).
        Assert:Equals(ItemType:Ring, Items:Roll(NEW ScriptedRandom("92,0,99,99")):Category).
        Assert:Equals(ItemType:Wand, Items:Roll(NEW ScriptedRandom("96,0")):Category).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManyRandomItemsAreSensible():
        DEFINE VARIABLE oRandom AS SeededRandom NO-UNDO.
        DEFINE VARIABLE oItem   AS Item         NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER      NO-UNDO.
        oRandom = NEW SeededRandom(21).
        DO i = 1 TO 600:
            oItem = Items:Roll(oRandom).
            Assert:IsTrue(oItem:Count >= 1).
            Assert:IsTrue(oItem:Bonus >= -3 AND oItem:Bonus <= 3).
            IF oItem:Cursed AND oItem:Category = ItemType:Weapon THEN Assert:IsTrue(oItem:Bonus < 0).
            IF oItem:Category = ItemType:Weapon AND Weapons:Stacks(WeaponKind:GetEnum(oItem:Kind)) THEN Assert:IsTrue(oItem:Count >= 8 AND oItem:Count <= 15).
            IF oItem:Category = ItemType:Wand THEN Assert:IsTrue(oItem:Charges >= 3 AND oItem:Charges <= 19).
            Assert:IsTrue(oItem:Category <> ItemType:Gold AND oItem:Category <> ItemType:Amulet).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACursedSuitOfArmourHasAMinus():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        /* armour kind 0, then 5 under 20: cursed, bonus -(2 + 1) */
        oItem = Items:OfSort(ItemType:Armour, NEW ScriptedRandom("0,5,2")).
        Assert:IsTrue(oItem:Cursed).
        Assert:Equals(-3, oItem:Bonus).
        /* not cursed (50), then 10 under 28: a plus of 1 + 1 */
        oItem = Items:OfSort(ItemType:Armour, NEW ScriptedRandom("0,50,10,1")).
        Assert:IsFalse(oItem:Cursed).
        Assert:Equals(2, oItem:Bonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStackOfArrowsHasEightToFifteen():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        /* kind roll 80 lands on arrows (chances 11,11,8,10,8,12,12,...), then count 3, then no curse and no plus */
        oItem = Items:OfSort(ItemType:Weapon, NEW ScriptedRandom("60,3,50,50,50")).
        Assert:Equals(INTEGER(WeaponKind:Arrow), oItem:Kind).
        Assert:Equals(11, oItem:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfProtectionHasASizeAndMayBeCursed():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        /* kind 0, size 2 + 1, then 10 under 30: cursed, so -3 */
        oItem = Items:OfSort(ItemType:Ring, NEW ScriptedRandom("0,2,10")).
        Assert:Equals(INTEGER(RingKind:Protection), oItem:Kind).
        Assert:Equals(-3, oItem:Bonus).
        Assert:IsTrue(oItem:Cursed).
        oItem = Items:OfSort(ItemType:Ring, NEW ScriptedRandom("0,0,90")).
        Assert:Equals(1, oItem:Bonus).
        Assert:IsFalse(oItem:Cursed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RingsOfAggravationAndTeleportationAreAlwaysCursed():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        /* roll 40 falls in aggravate monster (chances 9,9,5,10,10,1,10,...: 0-8, 9-17, 18-22, 23-32, 33-42, 43, 44-53) */
        oItem = Items:OfSort(ItemType:Ring, NEW ScriptedRandom("44")).
        Assert:Equals(INTEGER(RingKind:Aggravation), oItem:Kind).
        Assert:IsTrue(oItem:Cursed).
        Assert:Equals(0, oItem:Bonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWandGetsItsStartingCharges():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = Items:OfSort(ItemType:Wand, NEW ScriptedRandom("0,9")).
        Assert:Equals(INTEGER(WandKind:Light), oItem:Kind).
        Assert:Equals(19, oItem:Charges).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APotionScrollOrFoodIsOneOfItsKind():
        Assert:Equals(INTEGER(PotionKind:Confusion), Items:OfSort(ItemType:Potion, NEW ScriptedRandom("0")):Kind).
        Assert:Equals(INTEGER(ScrollKind:Identify), Items:OfSort(ItemType:Scroll, NEW ScriptedRandom("0")):Kind).
        Assert:Equals(INTEGER(FoodKind:Ration), Items:OfSort(ItemType:Food, NEW ScriptedRandom("0")):Kind).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GoldTheAmuletAndNoRandomSourceAreRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            Items:OfSort(ItemType:Gold, NEW ScriptedRandom("0")).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            Items:Roll(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
