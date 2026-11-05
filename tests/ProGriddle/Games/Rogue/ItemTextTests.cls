/* The words for items: unknown ones by their colour or title, known ones by name, counts and plurals, and the plus of what has been learnt. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ItemTextTests:

    DEFINE PRIVATE VARIABLE mDisguises AS Disguises NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildDisguises():
        mDisguises = NEW Disguises(NEW SeededRandom(9)).
    END METHOD.

    METHOD PRIVATE CHARACTER Say(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        RETURN ItemText:Describe(NEW Item(poType, piKind), mDisguises).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownPotionIsCalledByItsColourAndAKnownOneByItsName():
        DEFINE VARIABLE colour AS CHARACTER NO-UNDO.
        colour = mDisguises:Appearance(ItemType:Potion, INTEGER(PotionKind:Healing)).
        Assert:Equals(ItemText:Article(colour) + " " + colour + " potion", Say(ItemType:Potion, INTEGER(PotionKind:Healing))).
        mDisguises:Learn(ItemType:Potion, INTEGER(PotionKind:Healing)).
        Assert:Equals("a potion of healing", Say(ItemType:Potion, INTEGER(PotionKind:Healing))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStackSaysItsCountAndPutsTheSOnTheSort():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Potion, INTEGER(PotionKind:Healing)).
        oItem:Count = 3.
        mDisguises:Learn(ItemType:Potion, INTEGER(PotionKind:Healing)).
        Assert:Equals("3 potions of healing", ItemText:Describe(oItem, mDisguises)).
        oItem = NEW Item(ItemType:Food, INTEGER(FoodKind:Mango)).
        oItem:Count = 2.
        Assert:Equals("2 mangoes", ItemText:Describe(oItem, mDisguises)).
        oItem = NEW Item(ItemType:Food, INTEGER(FoodKind:Ration)).
        oItem:Count = 2.
        Assert:Equals("2 food rations", ItemText:Describe(oItem, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownScrollHasATitleAndAKnownOneAName():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        Assert:Equals("a scroll entitled '" + mDisguises:Appearance(ItemType:Scroll, 0) + "'", Say(ItemType:Scroll, 0)).
        oItem = NEW Item(ItemType:Scroll, 0).
        oItem:Count = 2.
        Assert:Equals("2 scrolls entitled '" + mDisguises:Appearance(ItemType:Scroll, 0) + "'", ItemText:Describe(oItem, mDisguises)).
        mDisguises:Learn(ItemType:Scroll, 0).
        Assert:Equals("a scroll of identify", Say(ItemType:Scroll, 0)).
        Assert:Equals("2 scrolls of identify", ItemText:Describe(oItem, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WandsAndRingsShowTheirMaterialUntilKnownAndTheirPlusWhenKnown():
        DEFINE VARIABLE oWand AS Item NO-UNDO.
        DEFINE VARIABLE oRing AS Item NO-UNDO.
        oWand = NEW Item(ItemType:Wand, INTEGER(WandKind:Fire)).
        oWand:Charges = 4.
        Assert:Equals(mDisguises:Appearance(ItemType:Wand, INTEGER(WandKind:Fire)) + " wand", ItemText:Noun(oWand, mDisguises)).
        mDisguises:Learn(ItemType:Wand, INTEGER(WandKind:Fire)).
        Assert:Equals("wand of fire", ItemText:Noun(oWand, mDisguises)).
        oWand:Known = TRUE.
        Assert:Equals("wand of fire [4 charges]", ItemText:Noun(oWand, mDisguises)).
        oRing = NEW Item(ItemType:Ring, INTEGER(RingKind:Protection)).
        oRing:Bonus = 2.
        Assert:Equals(mDisguises:Appearance(ItemType:Ring, INTEGER(RingKind:Protection)) + " ring", ItemText:Noun(oRing, mDisguises)).
        mDisguises:Learn(ItemType:Ring, INTEGER(RingKind:Protection)).
        oRing:Known = TRUE.
        Assert:Equals("ring of protection [+2]", ItemText:Noun(oRing, mDisguises)).
        oRing = NEW Item(ItemType:Ring, INTEGER(RingKind:Stealth)).
        mDisguises:Learn(ItemType:Ring, INTEGER(RingKind:Stealth)).
        oRing:Known = TRUE.
        Assert:Equals("ring of stealth", ItemText:Noun(oRing, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeaponShowsItsPlusOnlyOnceItIsKnown():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Mace)).
        oItem:Bonus = 1.
        oItem:DamageBonus = -1.
        Assert:Equals("a mace", ItemText:Describe(oItem, mDisguises)).
        oItem:Known = TRUE.
        Assert:Equals("a +1,-1 mace", ItemText:Describe(oItem, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ArrowsAreCountedAndShurikenKeepTheirName():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Arrow)).
        oItem:Count = 12.
        Assert:Equals("12 arrows", ItemText:Describe(oItem, mDisguises)).
        oItem = NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Shuriken)).
        oItem:Count = 5.
        Assert:Equals("5 shuriken", ItemText:Describe(oItem, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ArmourShowsItsClassAndItsPlusOnceKnown():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        oItem = NEW Item(ItemType:Armour, INTEGER(ArmourKind:RingMail)).
        oItem:Bonus = 1.
        Assert:Equals("a ring mail [AC 7]", ItemText:Describe(oItem, mDisguises)).
        oItem:Known = TRUE.
        Assert:Equals("a +1 ring mail [AC 6]", ItemText:Describe(oItem, mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GoldAndTheAmuletHaveTheirOwnWords():
        DEFINE VARIABLE oGold AS Item NO-UNDO.
        oGold = NEW Item(ItemType:Gold, 0).
        oGold:Count = 37.
        Assert:Equals("37 pieces of gold", ItemText:Describe(oGold, mDisguises)).
        Assert:Equals("the Amulet of Yendor", ItemText:Describe(Items:Amulet(), mDisguises)).
        Assert:Equals("pieces of gold", ItemText:Noun(oGold, mDisguises)).
        Assert:Equals("Amulet of Yendor", ItemText:Noun(Items:Amulet(), mDisguises)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ArticlesAndSignsAndPluralsFollowTheEnglish():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        Assert:Equals("an", ItemText:Article("iron wand")).
        Assert:Equals("a", ItemText:Article("mace")).
        Assert:Equals("a", ItemText:Article("")).
        Assert:Equals("+3", ItemText:Signed(3)).
        Assert:Equals("+0", ItemText:Signed(0)).
        Assert:Equals("-2", ItemText:Signed(-2)).
        oItem = NEW Item(ItemType:Food, INTEGER(FoodKind:Mango)).
        Assert:Equals("mangoes", ItemText:Plural("mango", oItem)).
        Assert:Equals("potions of healing", ItemText:Plural("potion of healing", NEW Item(ItemType:Potion, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyFourRingsHaveASize():
        Assert:IsTrue(ItemText:HasBonus(NEW Item(ItemType:Ring, INTEGER(RingKind:Protection)))).
        Assert:IsTrue(ItemText:HasBonus(NEW Item(ItemType:Ring, INTEGER(RingKind:AddStrength)))).
        Assert:IsTrue(ItemText:HasBonus(NEW Item(ItemType:Ring, INTEGER(RingKind:Dexterity)))).
        Assert:IsTrue(ItemText:HasBonus(NEW Item(ItemType:Ring, INTEGER(RingKind:IncreaseDamage)))).
        Assert:IsFalse(ItemText:HasBonus(NEW Item(ItemType:Ring, INTEGER(RingKind:Stealth)))).
        Assert:IsFalse(ItemText:HasBonus(NEW Item(ItemType:Potion, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoItemOrNoDisguisesIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            ItemText:Describe(?, mDisguises).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            ItemText:Describe(NEW Item(ItemType:Food, 0), ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            ItemText:Noun(?, mDisguises).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
