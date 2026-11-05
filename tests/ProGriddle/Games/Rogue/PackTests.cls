/* The pack: 23 lettered slots, stacking, taking things out, and which slots are worn or wielded. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.PackTests:

    DEFINE PRIVATE VARIABLE mPack AS Pack NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPack():
        mPack = NEW Pack().
    END METHOD.

    METHOD PRIVATE Item Potion(INPUT poKind AS PotionKind):
        RETURN NEW Item(ItemType:Potion, INTEGER(poKind)).
    END METHOD.

    METHOD PRIVATE Item Armour(INPUT poKind AS ArmourKind):
        RETURN NEW Item(ItemType:Armour, INTEGER(poKind)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyPackHoldsNothingAndHasNothingInUse():
        Assert:Equals(0, mPack:Count).
        Assert:Equals(0, mPack:FreeSlot()).
        Assert:IsFalse(mPack:Holds(0)).
        Assert:IsFalse(VALID-OBJECT(mPack:At(0))).
        Assert:IsFalse(VALID-OBJECT(mPack:Weapon())).
        Assert:IsFalse(VALID-OBJECT(mPack:Worn())).
        Assert:IsFalse(VALID-OBJECT(mPack:LeftRing())).
        Assert:IsFalse(VALID-OBJECT(mPack:RightRing())).
        Assert:IsFalse(mPack:HasAmulet()).
        Assert:Equals(0, mPack:Worth()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsTakeTheFirstFreeLetter():
        Assert:Equals(0, mPack:Add(Armour(ArmourKind:Leather))).
        Assert:Equals(1, mPack:Add(Armour(ArmourKind:RingMail))).
        Assert:Equals(2, mPack:Count).
        Assert:Equals("a", mPack:LetterOf(0)).
        Assert:Equals("b", mPack:LetterOf(1)).
        Assert:Equals("w", mPack:LetterOf(22)).
        Assert:Equals(0, mPack:SlotOf("a")).
        Assert:Equals(22, mPack:SlotOf("w")).
        Assert:Equals(2, mPack:FreeSlot()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALetterOutsideAToWIsNoSlot():
        Assert:Equals(-1, mPack:SlotOf("x")).
        Assert:Equals(-1, mPack:SlotOf("A")).
        Assert:Equals(-1, mPack:SlotOf("ab")).
        Assert:Equals(-1, mPack:SlotOf("")).
        Assert:Equals(-1, mPack:SlotOf(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APotionJoinsTheStackOfItsKindAndAnotherKindStartsOne():
        Assert:Equals(0, mPack:Add(Potion(PotionKind:Healing))).
        Assert:Equals(1, mPack:Add(Potion(PotionKind:Confusion))).
        Assert:Equals(0, mPack:Add(Potion(PotionKind:Healing))).
        Assert:Equals(2, mPack:Count).
        Assert:Equals(2, mPack:At(0):Count).
        Assert:Equals(1, mPack:At(1):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullPackTakesNothingNewButStillTakesAStackedPotion():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 22:
            mPack:Add(NEW Item(ItemType:Armour, 0)).
        END.
        Assert:Equals(23, mPack:Count).
        Assert:Equals(-1, mPack:FreeSlot()).
        Assert:IsFalse(mPack:CanTake(Potion(PotionKind:Healing))).
        Assert:Equals(-1, mPack:Add(Potion(PotionKind:Healing))).
        Assert:Equals(23, mPack:Count).
        mPack:Take(5, 1).
        Assert:IsTrue(mPack:CanTake(Potion(PotionKind:Healing))).
        Assert:Equals(5, mPack:Add(Potion(PotionKind:Healing))).
        Assert:IsTrue(mPack:CanTake(Potion(PotionKind:Healing))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TakingPartOfAStackLeavesTheRest():
        DEFINE VARIABLE oTaken AS Item NO-UNDO.
        mPack:Add(Potion(PotionKind:Healing)).
        mPack:Add(Potion(PotionKind:Healing)).
        mPack:Add(Potion(PotionKind:Healing)).
        oTaken = mPack:Take(0, 2).
        Assert:Equals(2, oTaken:Count).
        Assert:Equals(1, mPack:At(0):Count).
        oTaken = mPack:Take(0, 1).
        Assert:Equals(1, oTaken:Count).
        Assert:IsFalse(mPack:Holds(0)).
        Assert:Equals(0, mPack:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APackOfSeveralThingsKeepsTheLettersOfTheRest():
        mPack:Add(Armour(ArmourKind:Leather)).
        mPack:Add(Armour(ArmourKind:RingMail)).
        mPack:Add(Armour(ArmourKind:ChainMail)).
        mPack:Take(1, 1).
        Assert:IsFalse(mPack:Holds(1)).
        Assert:Equals(INTEGER(ArmourKind:ChainMail), mPack:At(2):Kind).
        /* the gap is filled by the next thing */
        Assert:Equals(1, mPack:Add(Armour(ArmourKind:PlateMail))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsWornIsFoundBySlotAndForgottenWhenItLeavesThePack():
        DEFINE VARIABLE oRing AS Item NO-UNDO.
        mPack:Add(NEW Item(ItemType:Weapon, INTEGER(WeaponKind:Mace))).
        mPack:Add(Armour(ArmourKind:RingMail)).
        mPack:Add(NEW Item(ItemType:Ring, INTEGER(RingKind:Protection))).
        mPack:Add(NEW Item(ItemType:Ring, INTEGER(RingKind:Searching))).
        mPack:WieldedSlot = 0.
        mPack:WornSlot = 1.
        mPack:LeftRingSlot = 2.
        mPack:RightRingSlot = 3.
        Assert:Equals(INTEGER(WeaponKind:Mace), mPack:Weapon():Kind).
        Assert:Equals(INTEGER(ArmourKind:RingMail), mPack:Worn():Kind).
        Assert:Equals(INTEGER(RingKind:Protection), mPack:LeftRing():Kind).
        Assert:Equals(INTEGER(RingKind:Searching), mPack:RightRing():Kind).
        Assert:IsTrue(mPack:InUse(0)).
        Assert:IsTrue(mPack:InUse(3)).
        Assert:IsFalse(mPack:InUse(4)).
        oRing = mPack:Take(2, 1).
        Assert:Equals(-1, mPack:LeftRingSlot).
        Assert:IsFalse(mPack:InUse(2)).
        mPack:Take(0, 1).
        Assert:Equals(-1, mPack:WieldedSlot).
        mPack:Take(1, 1).
        Assert:Equals(-1, mPack:WornSlot).
        mPack:Take(3, 1).
        Assert:Equals(-1, mPack:RightRingSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WornRingsAddUpTheirBonusesByKind():
        DEFINE VARIABLE oA AS Item NO-UNDO.
        DEFINE VARIABLE oB AS Item NO-UNDO.
        oA = NEW Item(ItemType:Ring, INTEGER(RingKind:Protection)).
        oA:Bonus = 2.
        oB = NEW Item(ItemType:Ring, INTEGER(RingKind:Protection)).
        oB:Bonus = 1.
        mPack:Add(oA).
        mPack:Add(oB).
        Assert:IsFalse(mPack:WearingRing(RingKind:Protection)).
        Assert:Equals(0, mPack:RingBonus(RingKind:Protection)).
        mPack:LeftRingSlot = 0.
        Assert:IsTrue(mPack:WearingRing(RingKind:Protection)).
        Assert:Equals(2, mPack:RingBonus(RingKind:Protection)).
        mPack:RightRingSlot = 1.
        Assert:Equals(3, mPack:RingBonus(RingKind:Protection)).
        Assert:IsFalse(mPack:WearingRing(RingKind:Stealth)).
        Assert:Equals(0, mPack:RingBonus(RingKind:Stealth)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePackKnowsItsWorthAndWhetherItHoldsTheAmulet():
        mPack:Add(Potion(PotionKind:RaiseLevel)).
        Assert:Equals(250, mPack:Worth()).
        Assert:IsFalse(mPack:HasAmulet()).
        mPack:Add(Items:Amulet()).
        Assert:IsTrue(mPack:HasAmulet()).
        Assert:IsTrue(mPack:Worth() >= 1250).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GoldATakeOfTheWrongSizeAndABadSlotAreRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mPack:Add(Potion(PotionKind:Healing)).
        DO ON ERROR UNDO, THROW:
            mPack:Add(Items:Gold(1, NEW ScriptedRandom("1"))).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPack:Add(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPack:Take(0, 2).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPack:Take(4, 1).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPack:At(23).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPack:LetterOf(-1).
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(6, thrown).
    END METHOD.

END CLASS.
