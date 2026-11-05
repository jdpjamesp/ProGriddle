/* Wearing, wielding, putting on rings, dropping and picking up. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.GearTests:

    DEFINE PRIVATE VARIABLE mWorld AS RogueWorld NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildScene():
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom("5")).
        mWorld:NewHero().
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 10, 4).
        mWorld:PlaceHero(6, 6).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseScene():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
    END METHOD.

    METHOD PRIVATE INTEGER Carry(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        RETURN mWorld:Pack:Add(Items:Make(poType, piKind)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APackLineShowsTheLetterTheNameAndWhatIsInUse():
        Assert:Equals("a) a food ration", Gear:Line(mWorld, 0)).
        Assert:Equals("b) a +1 ring mail [AC 6] (being worn)", Gear:Line(mWorld, 1)).
        Assert:Equals("c) a +1,+1 mace (weapon in hand)", Gear:Line(mWorld, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APackLineShowsRingsOnTheHands():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        a = Carry(ItemType:Ring, INTEGER(RingKind:Stealth)).
        b = Carry(ItemType:Ring, INTEGER(RingKind:Searching)).
        Gear:PutOn(mWorld, a).
        Gear:PutOn(mWorld, b).
        Assert:IsTrue(INDEX(Gear:Line(mWorld, a), "(on left hand)") > 0).
        Assert:IsTrue(INDEX(Gear:Line(mWorld, b), "(on right hand)") > 0).
        Assert:Equals(2, Gear:RingsWorn(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeaponCanBeWieldedInPlaceOfTheOne():
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        slot = Carry(ItemType:Weapon, INTEGER(WeaponKind:Spear)).
        Assert:IsTrue(Gear:Wield(mWorld, slot)).
        Assert:Equals(slot, mWorld:Pack:WieldedSlot).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "You are now wielding") > 0).
        Assert:IsTrue(mWorld:Pack:At(slot):Known).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeaponAlreadyInHandIsNotWieldedAgain():
        Assert:IsFalse(Gear:Wield(mWorld, 2)).
        Assert:Equals("You are already wielding that.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACursedWeaponInHandCannotBeChanged():
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        mWorld:Pack:At(2):Cursed = TRUE.
        slot = Carry(ItemType:Weapon, INTEGER(WeaponKind:Spear)).
        Assert:IsFalse(Gear:Wield(mWorld, slot)).
        Assert:Equals(2, mWorld:Pack:WieldedSlot).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "cursed") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyWeaponsCanBeWieldedArmourWornAndRingsPutOn():
        DEFINE VARIABLE potion AS INTEGER NO-UNDO.
        potion = Carry(ItemType:Potion, 0).
        Assert:IsFalse(Gear:Wield(mWorld, potion)).
        Assert:IsFalse(Gear:Wear(mWorld, potion)).
        Assert:IsFalse(Gear:PutOn(mWorld, potion)).
        Assert:IsFalse(Gear:RemoveRing(mWorld, potion)).
        Assert:IsFalse(Gear:Wield(mWorld, 15)).
        Assert:Equals("You have nothing like that.", mWorld:Messages:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ArmourCannotBeWornOverArmourButCanAfterItIsTakenOff():
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        slot = Carry(ItemType:Armour, INTEGER(ArmourKind:PlateMail)).
        Assert:IsFalse(Gear:Wear(mWorld, slot)).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "already wearing") > 0).
        Assert:IsTrue(Gear:TakeOff(mWorld)).
        Assert:Equals(-1, mWorld:Pack:WornSlot).
        Assert:IsTrue(Gear:Wear(mWorld, slot)).
        Assert:Equals(slot, mWorld:Pack:WornSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CursedArmourStaysOnAndNoArmourMeansNothingToTakeOff():
        Assert:IsTrue(Gear:TakeOff(mWorld)).
        Assert:IsFalse(Gear:TakeOff(mWorld)).
        Assert:Equals("You aren't wearing any armor.", mWorld:Messages:At(0)).
        mWorld:Pack:WornSlot = 1.
        mWorld:Pack:At(1):Cursed = TRUE.
        Assert:IsFalse(Gear:TakeOff(mWorld)).
        Assert:Equals(1, mWorld:Pack:WornSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RingsGoOnTheLeftHandFirstThenTheRightAndNoMore():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        a = Carry(ItemType:Ring, INTEGER(RingKind:Stealth)).
        b = Carry(ItemType:Ring, INTEGER(RingKind:Searching)).
        c = Carry(ItemType:Ring, INTEGER(RingKind:Regeneration)).
        Assert:IsTrue(Gear:PutOn(mWorld, a)).
        Assert:IsTrue(Gear:PutOn(mWorld, b)).
        Assert:IsFalse(Gear:PutOn(mWorld, c)).
        Assert:Equals(a, mWorld:Pack:LeftRingSlot).
        Assert:Equals(b, mWorld:Pack:RightRingSlot).
        Assert:Equals("You already have a ring on each hand.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RingsWithAnObviousEffectAreLearntWhenWornAndTheOthersAreNot():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        a = Carry(ItemType:Ring, INTEGER(RingKind:Protection)).
        b = Carry(ItemType:Ring, INTEGER(RingKind:Stealth)).
        Gear:PutOn(mWorld, a).
        Gear:PutOn(mWorld, b).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Ring, INTEGER(RingKind:Protection))).
        Assert:IsTrue(mWorld:Pack:At(a):Known).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Ring, INTEGER(RingKind:Stealth))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingComesOffUnlessItIsCursed():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        a = Carry(ItemType:Ring, INTEGER(RingKind:Stealth)).
        b = Carry(ItemType:Ring, INTEGER(RingKind:Searching)).
        Gear:PutOn(mWorld, a).
        Gear:PutOn(mWorld, b).
        mWorld:Pack:At(a):Cursed = TRUE.
        Assert:IsFalse(Gear:RemoveRing(mWorld, a)).
        Assert:Equals(a, mWorld:Pack:LeftRingSlot).
        Assert:IsTrue(Gear:RemoveRing(mWorld, b)).
        Assert:Equals(-1, mWorld:Pack:RightRingSlot).
        Assert:IsFalse(Gear:RemoveRing(mWorld, b)).
        Assert:Equals("You are not wearing that ring.", mWorld:Messages:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DroppingPutsOneOfAStackOnTheFloor():
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        mWorld:Pack:Add(Items:Make(ItemType:Potion, 2)).
        slot = mWorld:Pack:Add(Items:Make(ItemType:Potion, 2)).
        Assert:Equals(2, mWorld:Pack:At(slot):Count).
        Assert:IsTrue(Gear:DropItem(mWorld, slot)).
        Assert:Equals(1, mWorld:Pack:At(slot):Count).
        Assert:Equals(INTEGER(ItemType:Potion), INTEGER(mWorld:FloorItemAt(6, 6):Category)).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "You dropped") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DroppingWhatIsWornTakesItOffFirst():
        Assert:IsTrue(Gear:DropItem(mWorld, 1)).
        Assert:Equals(-1, mWorld:Pack:WornSlot).
        Assert:IsFalse(mWorld:Pack:Holds(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACursedThingInUseCannotBeDropped():
        mWorld:Pack:At(2):Cursed = TRUE.
        Assert:IsFalse(Gear:DropItem(mWorld, 2)).
        Assert:IsTrue(mWorld:Pack:Holds(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingCanBeDroppedOnStairsOrOntoAnotherThing():
        mWorld:Cave:SetTerrain(6, 6, Terrain:Stairs).
        Assert:IsFalse(Gear:DropItem(mWorld, 0)).
        Assert:Equals("There is no room to put that here.", mWorld:Messages:Line(80)).
        mWorld:Cave:SetTerrain(6, 6, Terrain:Floor).
        Assert:IsTrue(Gear:DropItem(mWorld, 0)).
        mWorld:Pack:Add(Items:Make(ItemType:Food, 0)).
        Assert:IsFalse(Gear:DropItem(mWorld, 0)).
        Assert:IsFalse(Gear:DropItem(mWorld, 15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingOntoGoldPutsItInThePurse():
        DEFINE VARIABLE oGold AS Item NO-UNDO.
        oGold = Items:Make(ItemType:Gold, 0).
        oGold:Count = 25.
        mWorld:DropOnFloor(oGold, 6, 6).
        Assert:IsTrue(Gear:Pickup(mWorld)).
        Assert:Equals(25, mWorld:Hero:Gold).
        Assert:Equals(0, mWorld:FloorItemCount).
        Assert:Equals("You found 25 pieces of gold.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingOntoAThingPutsItInThePackWithItsLetter():
        mWorld:DropOnFloor(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear)), 6, 6).
        Assert:IsTrue(Gear:Pickup(mWorld)).
        Assert:Equals(6, mWorld:Pack:Count).
        Assert:Equals("You now have f) a spear.", mWorld:Messages:Line(80)).
        Assert:Equals(0, mWorld:FloorItemCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickedUpPotionJoinsItsStack():
        mWorld:Pack:Add(Items:Make(ItemType:Potion, 4)).
        mWorld:DropOnFloor(Items:Make(ItemType:Potion, 4), 6, 6).
        Gear:Pickup(mWorld).
        Assert:Equals(6, mWorld:Pack:Count).
        Assert:Equals(2, mWorld:Pack:At(5):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullPackLeavesTheThingWhereItLies():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 18:
            mWorld:Pack:Add(Items:Make(ItemType:Armour, 0)).
        END.
        Assert:Equals(23, mWorld:Pack:Count).
        mWorld:DropOnFloor(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear)), 6, 6).
        Assert:IsFalse(Gear:Pickup(mWorld)).
        Assert:Equals(1, mWorld:FloorItemCount).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "too full") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingToPickUpIsNothingDone():
        Assert:IsFalse(Gear:Pickup(mWorld)).
        Assert:Equals("", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldsChecksTheSlotAndTheSortOfThing():
        Assert:IsTrue(Gear:Holds(mWorld, 0, ItemType:Food, "No.")).
        Assert:IsFalse(Gear:Holds(mWorld, 0, ItemType:Potion, "That is not a potion.")).
        Assert:Equals("That is not a potion.", mWorld:Messages:Line(80)).
        Assert:IsFalse(Gear:Holds(mWorld, -1, ItemType:Potion, "No.")).
    END METHOD.

END CLASS.
