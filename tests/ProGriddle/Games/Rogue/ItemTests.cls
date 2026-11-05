/* An item: a record of what a thing is, how it stacks, its copy and what it is worth. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ItemTests:

    @Test.
    METHOD PUBLIC VOID ANewItemIsOneOfItsKindAndPlain():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Potion, INTEGER(PotionKind:Healing)).
        Assert:Equals(ItemType:Potion, oItem:Category).
        Assert:Equals(INTEGER(PotionKind:Healing), oItem:Kind).
        Assert:Equals(1, oItem:Count).
        Assert:Equals(0, oItem:Bonus).
        Assert:Equals(0, oItem:DamageBonus).
        Assert:Equals(0, oItem:Charges).
        Assert:IsFalse(oItem:Cursed).
        Assert:IsFalse(oItem:Known).
        Assert:IsFalse(oItem:Warded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnItemWithNoTypeOrAMinusKindIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Item(?, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Item(ItemType:Potion, -1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PotionsScrollsFoodAndMissilesStackAndTheRestDoNot():
        Assert:IsTrue(NEW Item(ItemType:Potion, 0):Stackable()).
        Assert:IsTrue(NEW Item(ItemType:Scroll, 0):Stackable()).
        Assert:IsTrue(NEW Item(ItemType:Food, 0):Stackable()).
        Assert:IsTrue(NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Arrow)):Stackable()).
        Assert:IsTrue(NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Dart)):Stackable()).
        Assert:IsFalse(NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Mace)):Stackable()).
        Assert:IsFalse(NEW Item(ItemType:Armour, 0):Stackable()).
        Assert:IsFalse(NEW Item(ItemType:Wand, 0):Stackable()).
        Assert:IsFalse(NEW Item(ItemType:Ring, 0):Stackable()).
        Assert:IsFalse(NEW Item(ItemType:Amulet, 0):Stackable()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoItemsStackOnlyWhenTheyAreTheSameKindAndPlus():
        DEFINE VARIABLE a AS Item NO-UNDO.
        DEFINE VARIABLE b AS Item NO-UNDO.
        a = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Arrow)).
        b = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Arrow)).
        Assert:IsTrue(a:StacksWith(b)).
        b:Bonus = 1.
        Assert:IsFalse(a:StacksWith(b)).
        b = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Dart)).
        Assert:IsFalse(a:StacksWith(b)).
        Assert:IsFalse(a:StacksWith(?)).
        Assert:IsFalse(NEW Item(ItemType:Armour, 0):StacksWith(NEW Item(ItemType:Armour, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACopyKeepsEverythingButTheCount():
        DEFINE VARIABLE a AS Item NO-UNDO.
        DEFINE VARIABLE b AS Item NO-UNDO.
        a = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Dart)).
        a:Count = 9.
        a:Bonus = 2.
        a:DamageBonus = 1.
        a:Charges = 4.
        a:Cursed = TRUE.
        a:Known = TRUE.
        a:Warded = TRUE.
        b = a:Duplicate(3).
        Assert:Equals(3, b:Count).
        Assert:Equals(9, a:Count).
        Assert:Equals(2, b:Bonus).
        Assert:Equals(1, b:DamageBonus).
        Assert:Equals(4, b:Charges).
        Assert:IsTrue(b:Cursed).
        Assert:IsTrue(b:Known).
        Assert:IsTrue(b:Warded).
        Assert:Equals(INTEGER(WeaponKind:Dart), b:Kind).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatAnItemIsWorthIsItsTablePriceTimesItsCount():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Gold, 0).
        oItem:Count = 120.
        Assert:Equals(120, oItem:Worth()).
        oItem = NEW Item(ItemType:Potion, INTEGER(PotionKind:RaiseLevel)).
        oItem:Count = 2.
        Assert:Equals(500, oItem:Worth()).
        Assert:Equals(Foods:Worth(FoodKind:Ration), NEW Item(ItemType:Food, 0):Worth()).
        Assert:Equals(Weapons:Worth(WeaponKind:Mace), NEW Item(ItemType:Weapon, 0):Worth()).
        Assert:Equals(Armours:Worth(ArmourKind:Leather), NEW Item(ItemType:Armour, 0):Worth()).
        Assert:Equals(Scrolls:Worth(ScrollKind:Identify), NEW Item(ItemType:Scroll, 0):Worth()).
        Assert:Equals(Wands:Worth(WandKind:Light), NEW Item(ItemType:Wand, 0):Worth()).
        Assert:Equals(Rings:Worth(RingKind:Protection), NEW Item(ItemType:Ring, 0):Worth()).
        Assert:IsTrue(NEW Item(ItemType:Amulet, 0):Worth() >= 1000).
    END METHOD.

END CLASS.
