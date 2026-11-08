/* Potions, scrolls, wands, food and traps, with a random source that says one number for ever. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.MagicTests:

    VAR PRIVATE RogueWorld mWorld.

    /* A lit room with floor (5, 5) to (14, 8), the hero in it at (6, 6) with the starting kit (slots 0 to 4). */
    METHOD PRIVATE VOID Build(INPUT pcScript AS CHARACTER):
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom(pcScript)).
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

    METHOD PRIVATE Monster Beside(INPUT poKind AS MonsterKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR Monster oMonster.
        oMonster = mWorld:AddMonster(poKind, piX, piY).
        oMonster:Hp = 30.
        oMonster:MaxHp = 30.
        RETURN oMonster.
    END METHOD.

    /* ============================== food ============================== */

    @Test.
    METHOD PUBLIC VOID EatingFillsTheStomachAndUsesTheFoodUp():
        Build("5").
        mWorld:Hero:Nutrition = 500.
        Assert:IsTrue(Magic:Eat(mWorld, 0)).
        Assert:Equals(2000, mWorld:Hero:Nutrition).
        Assert:IsFalse(mWorld:Pack:Holds(0)).
        Assert:Equals("Yum, that tasted good.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMangoFeedsLessAndNeverOverfills():
        VAR INTEGER slot.
        Build("5").
        slot = Carry(ItemType:Food, INTEGER(FoodKind:Mango)).
        mWorld:Hero:Nutrition = 100.
        Magic:Eat(mWorld, slot).
        Assert:Equals(1000, mWorld:Hero:Nutrition).
        slot = Carry(ItemType:Food, INTEGER(FoodKind:Mango)).
        mWorld:Hero:Nutrition = 1800.
        Magic:Eat(mWorld, slot).
        Assert:Equals(2000, mWorld:Hero:Nutrition).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyFoodCanBeEaten():
        VAR INTEGER slot.
        Build("5").
        slot = Carry(ItemType:Potion, 0).
        Assert:IsFalse(Magic:Eat(mWorld, slot)).
        Assert:IsTrue(mWorld:Pack:Holds(slot)).
    END METHOD.

    /* ============================== potions ============================== */

    METHOD PRIVATE LOGICAL Drink(INPUT poKind AS PotionKind):
        VAR INTEGER slot.
        slot = Carry(ItemType:Potion, INTEGER(poKind)).
        RETURN Magic:Quaff(mWorld, slot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrinkingUsesUpOnePotionAndLearnsItsKind():
        VAR INTEGER slot.
        Build("5").
        slot = Carry(ItemType:Potion, INTEGER(PotionKind:GainStrength)).
        Carry(ItemType:Potion, INTEGER(PotionKind:GainStrength)).
        Assert:IsTrue(Magic:Quaff(mWorld, slot)).
        Assert:Equals(1, mWorld:Pack:At(slot):Count).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Potion, INTEGER(PotionKind:GainStrength))).
        Assert:Equals(17, mWorld:Hero:Strength).
        Assert:Equals(17, mWorld:Hero:MaxStrength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyPotionsCanBeDrunk():
        Build("5").
        Assert:IsFalse(Magic:Quaff(mWorld, 0)).
        Assert:IsTrue(mWorld:Pack:Holds(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConfusionHallucinationAndBlindnessStartTheirTimers():
        Build("5").
        Drink(PotionKind:Confusion).
        Assert:IsTrue(mWorld:Hero:Confused >= 8).
        Drink(PotionKind:Hallucination).
        Assert:IsTrue(mWorld:Hero:Hallucinating >= 150).
        Drink(PotionKind:Blindness).
        Assert:IsTrue(mWorld:Hero:Blind >= 100).
        Drink(PotionKind:Levitation).
        Assert:IsTrue(mWorld:Hero:Levitating >= 30).
        Drink(PotionKind:HasteSelf).
        Assert:IsTrue(mWorld:Hero:Hasted >= 12).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PoisonWeakensTheHeroUnlessTheyAreSustained():
        VAR Item oRing.
        Build("5").
        Drink(PotionKind:Poison).
        Assert:IsTrue(mWorld:Hero:Strength < 16).
        mWorld:Hero:Strength = 16.
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:SustainStrength)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Drink(PotionKind:Poison).
        Assert:Equals(16, mWorld:Hero:Strength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestoreStrengthPutsBackWhatPoisonTook():
        Build("5").
        mWorld:Hero:Strength = 11.
        Drink(PotionKind:RestoreStrength).
        Assert:Equals(16, mWorld:Hero:Strength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SeeInvisibleStartsItsTimerAndCuresBlindness():
        Build("5").
        mWorld:Hero:Blind = 40.
        Drink(PotionKind:SeeInvisible).
        Assert:IsTrue(mWorld:Hero:SeesInvisible >= 150).
        Assert:Equals(0, mWorld:Hero:Blind).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HealingMendsAndRaisesTheMostHitPointsWhenAlreadyWell():
        Build("2").
        mWorld:Hero:Hp = 5.
        Drink(PotionKind:Healing).
        Assert:IsTrue(mWorld:Hero:Hp > 5).
        Assert:Equals(12, mWorld:Hero:MaxHp).
        mWorld:Hero:Hp = 12.
        Drink(PotionKind:Healing).
        Assert:Equals(13, mWorld:Hero:MaxHp).
        Assert:Equals(13, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExtraHealingCuresMoreAndRaisesTheMostByTwo():
        Build("2").
        mWorld:Hero:Hp = 12.
        mWorld:Hero:Confused = 5.
        mWorld:Hero:Hallucinating = 50.
        mWorld:Hero:Blind = 30.
        Drink(PotionKind:ExtraHealing).
        Assert:Equals(14, mWorld:Hero:MaxHp).
        Assert:Equals(0, mWorld:Hero:Confused).
        Assert:Equals(0, mWorld:Hero:Hallucinating).
        Assert:Equals(0, mWorld:Hero:Blind).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RaiseLevelGivesTheNextLevel():
        Build("5").
        Drink(PotionKind:RaiseLevel).
        Assert:Equals(2, mWorld:Hero:Rank).
        Assert:IsTrue(mWorld:Hero:MaxHp > 12).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MonsterDetectionNeedsMonstersToBeLearnt():
        Build("5").
        Drink(PotionKind:MonsterDetection).
        Assert:Equals(0, mWorld:Hero:SensesMonsters).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Potion, INTEGER(PotionKind:MonsterDetection))).
        Beside(MonsterKind:Orc, 12, 7).
        Drink(PotionKind:MonsterDetection).
        Assert:Equals(20, mWorld:Hero:SensesMonsters).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Potion, INTEGER(PotionKind:MonsterDetection))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MagicDetectionNeedsMagicOnTheFloorToBeLearnt():
        Build("5").
        Drink(PotionKind:MagicDetection).
        Assert:Equals(0, mWorld:Hero:SensesMagic).
        mWorld:DropOnFloor(Items:Make(ItemType:Scroll, 0), 12, 7).
        Drink(PotionKind:MagicDetection).
        Assert:Equals(20, mWorld:Hero:SensesMagic).
        Assert:IsTrue(Magic:AnyMagicOnTheFloor(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsMagicIsPotionsScrollsWandsRingsAndAnythingWithAPlus():
        VAR Item oMace.
        Assert:IsTrue(Magic:IsMagic(Items:Make(ItemType:Potion, 0))).
        Assert:IsTrue(Magic:IsMagic(Items:Make(ItemType:Scroll, 0))).
        Assert:IsTrue(Magic:IsMagic(Items:Make(ItemType:Wand, 0))).
        Assert:IsTrue(Magic:IsMagic(Items:Make(ItemType:Ring, 0))).
        Assert:IsFalse(Magic:IsMagic(Items:Make(ItemType:Food, 0))).
        Assert:IsFalse(Magic:IsMagic(Items:Make(ItemType:Gold, 0))).
        Assert:IsFalse(Magic:IsMagic(?)).
        oMace = Items:Make(ItemType:Weapon, 0).
        Assert:IsFalse(Magic:IsMagic(oMace)).
        oMace:DamageBonus = 2.
        Assert:IsTrue(Magic:IsMagic(oMace)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HealingByTheNumbers():
        Build("5").
        mWorld:Hero:Hp = 4.
        Magic:Heal(mWorld, 5, 1).
        Assert:Equals(9, mWorld:Hero:Hp).
        Magic:Heal(mWorld, 50, 3).
        Assert:Equals(15, mWorld:Hero:MaxHp).
        Assert:Equals(15, mWorld:Hero:Hp).
    END METHOD.

    /* ============================== scrolls ============================== */

    METHOD PRIVATE LOGICAL Read(INPUT poKind AS ScrollKind, OUTPUT plPick AS LOGICAL):
        VAR INTEGER slot.
        slot = Carry(ItemType:Scroll, INTEGER(poKind)).
        RETURN Magic:ReadScroll(mWorld, slot, OUTPUT plPick).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScrollIsUsedUpAndItsKindLearntOnReading():
        VAR LOGICAL pick.
        Build("5").
        Assert:IsTrue(Read(ScrollKind:RemoveCurse, OUTPUT pick)).
        Assert:IsFalse(pick).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:RemoveCurse))).
        Assert:Equals(5, mWorld:Pack:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyScrollsCanBeRead():
        VAR LOGICAL pick.
        Build("5").
        Assert:IsFalse(Magic:ReadScroll(mWorld, 0, OUTPUT pick)).
        Assert:IsFalse(pick).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IdentifyAsksWhichThingAndThenTellsTheHero():
        VAR LOGICAL pick.
        VAR INTEGER slot.
        Build("5").
        slot = Carry(ItemType:Potion, INTEGER(PotionKind:Healing)).
        Read(ScrollKind:Identify, OUTPUT pick).
        Assert:IsTrue(pick).
        Magic:IdentifyItem(mWorld, slot).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Potion, INTEGER(PotionKind:Healing))).
        Assert:IsTrue(mWorld:Pack:At(slot):Known).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(300), "potion of healing") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IdentifyingAWeaponShowsItsPlusWithoutNamingAKind():
        VAR INTEGER slot.
        Build("5").
        slot = Carry(ItemType:Weapon, INTEGER(WeaponKind:Spear)).
        mWorld:Pack:At(slot):Bonus = 2.
        Magic:IdentifyItem(mWorld, slot).
        Assert:IsTrue(mWorld:Pack:At(slot):Known).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(300), "+2,+0 spear") > 0).
        Magic:IdentifyItem(mWorld, 20).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(300), "nothing like that") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnchantArmourImprovesAndUncursesTheSuitWorn():
        VAR LOGICAL pick.
        Build("5").
        mWorld:Pack:Worn():Cursed = TRUE.
        Read(ScrollKind:EnchantArmour, OUTPUT pick).
        Assert:Equals(2, mWorld:Pack:Worn():Bonus).
        Assert:IsFalse(mWorld:Pack:Worn():Cursed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnchantingWithNothingWornIsNotLearnt():
        VAR LOGICAL pick.
        Build("5").
        mWorld:Pack:WornSlot = -1.
        Read(ScrollKind:EnchantArmour, OUTPUT pick).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:EnchantArmour))).
        mWorld:Pack:WieldedSlot = -1.
        Read(ScrollKind:EnchantWeapon, OUTPUT pick).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:EnchantWeapon))).
        mWorld:Pack:WornSlot = -1.
        Read(ScrollKind:ProtectArmour, OUTPUT pick).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:ProtectArmour))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnchantWeaponAddsOnePlusToHitOrToDamage():
        VAR LOGICAL pick.
        Build("0").
        Read(ScrollKind:EnchantWeapon, OUTPUT pick).
        Assert:Equals(2, mWorld:Pack:Weapon():Bonus).
        Assert:Equals(1, mWorld:Pack:Weapon():DamageBonus).
        mWorld:Dispose().
        Build("1").
        Read(ScrollKind:EnchantWeapon, OUTPUT pick).
        Assert:Equals(1, mWorld:Pack:Weapon():Bonus).
        Assert:Equals(2, mWorld:Pack:Weapon():DamageBonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RemoveCurseFreesEverythingInThePack():
        VAR LOGICAL pick.
        Build("5").
        mWorld:Pack:At(1):Cursed = TRUE.
        mWorld:Pack:At(2):Cursed = TRUE.
        Read(ScrollKind:RemoveCurse, OUTPUT pick).
        Assert:IsFalse(mWorld:Pack:At(1):Cursed).
        Assert:IsFalse(mWorld:Pack:At(2):Cursed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MonsterConfusionMakesTheNextHitConfuse():
        VAR LOGICAL pick.
        Build("5").
        Read(ScrollKind:MonsterConfusion, OUTPUT pick).
        Assert:IsTrue(mWorld:Hero:ConfusingTouch).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SleepPutsTheHeroToSleep():
        VAR LOGICAL pick.
        Build("5").
        Read(ScrollKind:SleepSpell, OUTPUT pick).
        Assert:IsTrue(mWorld:Hero:Asleep >= 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MagicMappingShowsEveryCellAndFindsSecretDoors():
        VAR LOGICAL pick.
        Build("5").
        mWorld:Cave:SetTerrain(15, 7, Terrain:SecretDown).
        mWorld:Cave:SetTerrain(16, 7, Terrain:Passage).
        Assert:IsFalse(mWorld:Cave:IsSeen(16, 7)).
        Read(ScrollKind:MagicMapping, OUTPUT pick).
        Assert:IsTrue(mWorld:Cave:IsSeen(16, 7)).
        Assert:IsTrue(mWorld:Cave:IsSeen(4, 4)).
        Assert:IsFalse(mWorld:Cave:IsSeen(50, 15)).
        Assert:Equals(INTEGER(Terrain:Door), mWorld:Cave:TerrainAt(15, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldMonsterFreezesTheMonstersNearbyAndIsNotLearntWithNobodyThere():
        VAR LOGICAL pick.
        VAR Monster oNear.
        VAR Monster oFar.
        Build("5").
        Read(ScrollKind:HoldMonster, OUTPUT pick).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:HoldMonster))).
        oNear = Beside(MonsterKind:Orc, 8, 6).
        oFar = Beside(MonsterKind:Orc, 14, 8).
        Read(ScrollKind:HoldMonster, OUTPUT pick).
        Assert:IsTrue(oNear:Held >= 12).
        Assert:Equals(0, oFar:Held).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:HoldMonster))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMonsterPutsOneNextToTheHero():
        VAR LOGICAL pick.
        Build("6").
        Read(ScrollKind:CreateMonster, OUTPUT pick).
        Assert:Equals(1, mWorld:MonsterCount).
        Assert:IsTrue(Magic:MakeMonsterNear(mWorld)).
        Assert:Equals(2, mWorld:MonsterCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewMonsterIsAwakeAndEveryOneOfEightSquaresCanTakeOne():
        VAR INTEGER i.
        VAR Monster oMon.
        VAR INTEGER awake.
        Build("3").
        mWorld:PlaceHero(10, 6).
        DO i = 1 TO 8:
            Magic:MakeMonsterNear(mWorld).
        END.
        Assert:Equals(8, mWorld:MonsterCount).
        Assert:IsFalse(Magic:MakeMonsterNear(mWorld)).
        DO i = 0 TO 63:
            oMon = mWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMon) AND oMon:Awake THEN awake = awake + 1.
        END.
        Assert:Equals(8, awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ScareMonsterReadFreezesTheMonstersInSight():
        VAR LOGICAL pick.
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 12, 7).
        mWorld:Cave:SetInView(12, 7, TRUE).
        Read(ScrollKind:ScareMonster, OUTPUT pick).
        Assert:IsTrue(oOrc:Held >= 12).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FoodDetectionNeedsFoodOnTheFloorToBeLearnt():
        VAR LOGICAL pick.
        Build("5").
        Read(ScrollKind:FoodDetection, OUTPUT pick).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Scroll, INTEGER(ScrollKind:FoodDetection))).
        Assert:IsFalse(Magic:AnyFoodOnTheFloor(mWorld)).
        mWorld:DropOnFloor(Items:Make(ItemType:Food, 0), 12, 7).
        Read(ScrollKind:FoodDetection, OUTPUT pick).
        Assert:Equals(20, mWorld:Hero:SensesFood).
        Assert:IsTrue(Magic:AnyFoodOnTheFloor(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AggravateWakesEveryMonster():
        VAR LOGICAL pick.
        VAR Monster oNymph.
        Build("5").
        oNymph = Beside(MonsterKind:Nymph, 14, 8).
        Assert:IsFalse(oNymph:Awake).
        Read(ScrollKind:Aggravate, OUTPUT pick).
        Assert:IsTrue(oNymph:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ProtectArmourWardsTheSuitAgainstRust():
        VAR LOGICAL pick.
        Build("5").
        Read(ScrollKind:ProtectArmour, OUTPUT pick).
        Assert:IsTrue(mWorld:Pack:Worn():Warded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TeleportationMovesTheHeroToAFreeSquareOfAnotherPlace():
        Build("5").
        mWorld:Cave:SetTerrain(40, 15, Terrain:Floor).
        Magic:Teleport(mWorld).
        /* in a test scene there is only the one room: the hero lands on its floor */
        Assert:IsTrue(mWorld:Cave:Walkable(mWorld:Hero:X, mWorld:Hero:Y)).
    END METHOD.

    /* ============================== wands ============================== */

    METHOD PRIVATE INTEGER Wand(INPUT poKind AS WandKind, INPUT piCharges AS INTEGER):
        VAR INTEGER slot.
        slot = Carry(ItemType:Wand, INTEGER(poKind)).
        mWorld:Pack:At(slot):Charges = piCharges.
        RETURN slot.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWandWithNoChargesDoesNothing():
        VAR INTEGER slot.
        Build("5").
        slot = Wand(WandKind:Fire, 0).
        Assert:IsTrue(Magic:Zap(mWorld, slot, 1, 0)).
        Assert:Equals("Nothing happens.", mWorld:Messages:Line(80)).
        Assert:Equals(0, mWorld:Pack:At(slot):Charges).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyWandsCanBeZapped():
        Build("5").
        Assert:IsFalse(Magic:Zap(mWorld, 0, 1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AZapUsesACharge():
        VAR INTEGER slot.
        Build("5").
        slot = Wand(WandKind:Nothing, 3).
        Magic:Zap(mWorld, slot, 1, 0).
        Assert:Equals(2, mWorld:Pack:At(slot):Charges).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FireHurtsTheFirstMonsterInTheWayAndIsLearnt():
        VAR INTEGER slot.
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        slot = Wand(WandKind:Fire, 4).
        Magic:Zap(mWorld, slot, 1, 0).
        /* 6d6 with every die a 6 (5 modulo 6, plus 1) is 36: the orc has 30 */
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Wand, INTEGER(WandKind:Fire))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MagicMissileDoesLessThanFire():
        VAR INTEGER slot.
        VAR Monster oOrc.
        Build("1").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        slot = Wand(WandKind:MagicMissile, 4).
        Magic:Zap(mWorld, slot, 1, 0).
        Assert:Equals(24, oOrc:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoltAtNothingHitsNothingAndIsNotLearnt():
        VAR INTEGER slot.
        Build("5").
        slot = Wand(WandKind:Cold, 4).
        Magic:Zap(mWorld, slot, 0, -1).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Wand, INTEGER(WandKind:Cold))).
        Assert:Equals("The bolt hits nothing.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoltStopsAtAWall():
        Build("5").
        Beside(MonsterKind:Orc, 14, 8).
        Assert:IsFalse(VALID-OBJECT(Magic:FirstInLine(mWorld, 0, -1))).
        Assert:IsFalse(VALID-OBJECT(Magic:FirstInLine(mWorld, -1, 0))).
        Assert:IsFalse(VALID-OBJECT(Magic:FirstInLine(mWorld, 1, 0))).
        mWorld:PlaceHero(8, 8).
        Assert:IsTrue(VALID-OBJECT(Magic:FirstInLine(mWorld, 1, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InvisibilitySlowAndHasteChangeTheMonster():
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        Magic:Zap(mWorld, Wand(WandKind:Invisibility, 3), 1, 0).
        Assert:IsTrue(oOrc:Invisible).
        Magic:Zap(mWorld, Wand(WandKind:SlowMonster, 3), 1, 0).
        Assert:IsTrue(oOrc:Slowed > 0).
        Magic:Zap(mWorld, Wand(WandKind:HasteMonster, 3), 1, 0).
        Assert:IsTrue(oOrc:Hasted > 0).
        Magic:Zap(mWorld, Wand(WandKind:Cancellation, 3), 1, 0).
        Assert:IsTrue(oOrc:Cancelled).
        Assert:IsFalse(oOrc:Invisible).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PolymorphMakesAnotherKindOfMonsterInTheSamePlace():
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        Magic:Zap(mWorld, Wand(WandKind:Polymorph, 3), 1, 0).
        Assert:Equals(1, mWorld:MonsterCount).
        Assert:IsTrue(VALID-OBJECT(mWorld:MonsterAtCell(10, 6))).
        Assert:IsTrue(mWorld:MonsterAtCell(10, 6):Kind <> MonsterKind:Orc).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TeleportAwaySendsTheMonsterOffAndTeleportToPullsItNear():
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 12, 6).
        Magic:Zap(mWorld, Wand(WandKind:TeleportTo, 3), 1, 0).
        Assert:Equals(1, RogueWorld:Distance(oOrc:X, oOrc:Y, 6, 6)).
        Magic:Zap(mWorld, Wand(WandKind:TeleportAway, 3), (oOrc:X - 6), (oOrc:Y - 6)).
        Assert:IsTrue(mWorld:Cave:Walkable(oOrc:X, oOrc:Y)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LightLightsADarkRoomButNotACorridor():
        VAR INTEGER slot.
        Build("5").
        mWorld:SetRoomLit(1, FALSE).
        slot = Wand(WandKind:Light, 5).
        Magic:Zap(mWorld, slot, 1, 0).
        Assert:IsTrue(mWorld:RoomLit(1)).
        Assert:IsTrue(mWorld:Names:IsKnown(ItemType:Wand, INTEGER(WandKind:Light))).
        mWorld:Cave:SetTerrain(20, 7, Terrain:Passage).
        mWorld:PlaceHero(20, 7).
        mWorld:Names:Shuffle(NEW ScriptedRandom("2")).
        Magic:Zap(mWorld, slot, 1, 0).
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Wand, INTEGER(WandKind:Light))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrainLifeCostsTheHeroHalfTheirHitPointsAndHurtsWhatIsInSight():
        VAR Monster oOrc.
        Build("5").
        mWorld:Hero:Hp = 12.
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        mWorld:Cave:SetInView(10, 6, TRUE).
        Magic:Zap(mWorld, Wand(WandKind:DrainLife, 3), 1, 0).
        Assert:Equals(6, mWorld:Hero:Hp).
        Assert:Equals(24, oOrc:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrainLifeIsRefusedByAHeroWithAHitPointLeft():
        VAR INTEGER slot.
        Build("5").
        mWorld:Hero:Hp = 1.
        slot = Wand(WandKind:DrainLife, 3).
        Magic:Zap(mWorld, slot, 1, 0).
        Assert:Equals(1, mWorld:Hero:Hp).
        Assert:Equals("You are too weak to use it.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFreeFloorSquareIsNeverTheHeroOrAMonster():
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER i.
        Build("7").
        Beside(MonsterKind:Orc, 7, 6).
        DO i = 1 TO 10:
            Assert:IsTrue(Magic:RandomFreeFloor(mWorld, OUTPUT x, OUTPUT y)).
            Assert:IsTrue(x >= 5 AND x <= 14 AND y >= 5 AND y <= 8).
            Assert:IsFalse(x = 6 AND y = 6).
            Assert:IsFalse(x = 7 AND y = 6).
        END.
        mWorld:ClearLevel().
        Assert:IsFalse(Magic:RandomFreeFloor(mWorld, OUTPUT x, OUTPUT y)).
    END METHOD.

    /* ============================== traps ============================== */

    @Test.
    METHOD PUBLIC VOID ATrapDoorTakesTheHeroDown():
        Build("5").
        Assert:IsTrue(Magic:SpringTrap(mWorld, TrapKind:TrapDoor)).
        Assert:IsTrue(mWorld:Cave:TrapFound(6, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnArrowTrapHurtsOrMissesByTheRoll():
        Build("19").
        Assert:IsFalse(Magic:SpringTrap(mWorld, TrapKind:Arrow)).
        Assert:IsTrue(mWorld:Hero:Hp < 12).
        mWorld:Dispose().
        Build("0").
        Assert:IsFalse(Magic:SpringTrap(mWorld, TrapKind:Arrow)).
        Assert:Equals(12, mWorld:Hero:Hp).
        Assert:Equals("An arrow shoots past you.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SleepingGasAndBearTrapsHoldTheHero():
        Build("5").
        Magic:SpringTrap(mWorld, TrapKind:SleepingGas).
        Assert:IsTrue(mWorld:Hero:Asleep >= 4).
        Magic:SpringTrap(mWorld, TrapKind:BearTrap).
        Assert:IsTrue(mWorld:Hero:Stuck >= 3).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APoisonDartHurtsAndWeakensAndRustRustsTheArmour():
        Build("19").
        Magic:SpringTrap(mWorld, TrapKind:PoisonDart).
        Assert:Equals(15, mWorld:Hero:Strength).
        Assert:IsTrue(mWorld:Hero:Hp < 12).
        Magic:SpringTrap(mWorld, TrapKind:Rust).
        Assert:Equals(0, mWorld:Pack:Worn():Bonus).
        mWorld:Pack:Worn():Warded = TRUE.
        Magic:SpringTrap(mWorld, TrapKind:Rust).
        Assert:Equals(0, mWorld:Pack:Worn():Bonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMysticTrapConfusesAndATeleportTrapMovesTheHero():
        Build("5").
        Magic:SpringTrap(mWorld, TrapKind:Mystic).
        Assert:Equals(3, mWorld:Hero:Confused).
        Assert:IsFalse(Magic:SpringTrap(mWorld, TrapKind:Teleport)).
    END METHOD.


    @Test.
    METHOD PUBLIC VOID MappingTheLevelShowsEverythingThatIsNotRock():
        Build("5").
        Magic:MapTheLevel(mWorld).
        Assert:IsTrue(mWorld:Cave:IsSeen(5, 5)).
        Assert:IsTrue(mWorld:Cave:IsSeen(4, 4)).
        Assert:IsFalse(mWorld:Cave:IsSeen(40, 12)).
    END METHOD.
END CLASS.
