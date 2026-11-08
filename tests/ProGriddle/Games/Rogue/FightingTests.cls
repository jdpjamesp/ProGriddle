/* The rules of a fight, with a random source that says the same number every time ("19" for the best rolls, "0" for the worst). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.FightingTests:

    VAR PRIVATE RogueWorld mWorld.

    /* A world whose random source always says the same number, with the usual kit and a lit room: floor (5, 5) to (14, 8), the hero at (6, 6). */
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

    /* a monster next to the hero with a fixed number of hit points */
    METHOD PRIVATE Monster Beside(INPUT poKind AS MonsterKind, INPUT piHp AS INTEGER):
        VAR Monster oMonster.
        oMonster = mWorld:AddMonster(poKind, 7, 6).
        oMonster:Hp = piHp.
        oMonster:MaxHp = piHp.
        oMonster:Awake = TRUE.
        RETURN oMonster.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlowLandsWhenTheRollAndBonusReachTheNeed():
        Build("0").
        /* need 20 - 1 - 5 = 14: a roll of 1 does not land, with a bonus of 13 it does */
        Assert:IsFalse(Fighting:Swing(mWorld, 1, 5, 0)).
        Assert:IsFalse(Fighting:Swing(mWorld, 1, 5, 12)).
        Assert:IsTrue(Fighting:Swing(mWorld, 1, 5, 13)).
        mWorld:Dispose().
        Build("19").
        Assert:IsTrue(Fighting:Swing(mWorld, 1, 5, 0)).
        Assert:IsFalse(Fighting:Swing(mWorld, 1, -2, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroArmourClassStartsAtSixInTheStartingRingMailAndTenInNothing():
        Build("5").
        Assert:Equals(6, Fighting:ArmourClass(mWorld)).
        mWorld:Pack:WornSlot = -1.
        Assert:Equals(10, Fighting:ArmourClass(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfProtectionLowersTheArmourClass():
        VAR Item oRing.
        Build("5").
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:Protection)).
        oRing:Bonus = 2.
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Assert:Equals(4, Fighting:ArmourClass(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StrengthAndRingsChangeTheBonusesOfTheHand():
        VAR Item oRing.
        Build("5").
        /* the mace is +1,+1 and the strength 16 */
        Assert:Equals(1, Fighting:HitBonus(mWorld)).
        Assert:Equals(1, Fighting:DamageBonus(mWorld)).
        Assert:Equals(16, Fighting:EffectiveStrength(mWorld)).
        mWorld:Hero:Strength = 18.
        Assert:Equals(2, Fighting:HitBonus(mWorld)).
        Assert:Equals(2, Fighting:DamageBonus(mWorld)).
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:Dexterity)).
        oRing:Bonus = 3.
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Assert:Equals(5, Fighting:HitBonus(mWorld)).
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:AddStrength)).
        oRing:Bonus = 2.
        mWorld:Pack:RightRingSlot = mWorld:Pack:Add(oRing).
        Assert:Equals(20, Fighting:EffectiveStrength(mWorld)).
        Assert:Equals(6, Fighting:HitBonus(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BareHandsDoOneDFour():
        Build("5").
        Assert:Equals("2d4", Fighting:HandDice(mWorld)).
        mWorld:Pack:WieldedSlot = -1.
        Assert:Equals("1d4", Fighting:HandDice(mWorld)).
        Assert:Equals(0, Fighting:HitBonus(mWorld)).
        Assert:Equals(0, Fighting:DamageBonus(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroHitsAMonsterAndItLosesHitPoints():
        VAR Monster oBat.
        Build("19").
        oBat = Beside(MonsterKind:Bat, 30).
        oBat:Awake = FALSE.
        Fighting:HeroAttack(mWorld, oBat).
        /* 2d4 with every die a 4 is 8, plus 1 for the mace */
        Assert:Equals(21, oBat:Hp).
        Assert:Equals("You hit the bat.", mWorld:Messages:Line(80)).
        Assert:IsTrue(oBat:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroMissesAndSaysSo():
        VAR Monster oBat.
        Build("0").
        oBat = Beside(MonsterKind:Emu, 30).
        Fighting:HeroAttack(mWorld, oBat).
        Assert:Equals(30, oBat:Hp).
        Assert:Equals("You miss the emu.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASleepingMonsterIsEasierToHit():
        VAR Monster oOrc.
        /* an orc has armour class 6 and the hero needs 13 + 0 : a roll of 1 + the bonus 1 misses, with +4 for sleep it is still short, so use a roll of 8 */
        Build("7").
        oOrc = Beside(MonsterKind:Orc, 30).
        oOrc:Awake = TRUE.
        Fighting:HeroAttack(mWorld, oOrc).
        Assert:Equals(30, oOrc:Hp).
        oOrc:Awake = FALSE.
        Fighting:HeroAttack(mWorld, oOrc).
        Assert:IsTrue(oOrc:Hp < 30).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKillGivesExperienceAndDropsWhatTheMonsterCarried():
        VAR Monster oBat.
        VAR Item oPotion.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER gold.
        Build("19").
        oBat = Beside(MonsterKind:Bat, 1).
        oPotion = Items:Make(ItemType:Potion, 3).
        oBat:Carried = oPotion.
        oBat:Gold = 40.
        Fighting:HeroAttack(mWorld, oBat).
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:Equals(1, mWorld:Hero:Experience).
        Assert:IsTrue(mWorld:Messages:Line(80) = "You hit the bat.  You killed the bat.").
        Assert:IsTrue(mWorld:FloorItemAt(7, 6) = oPotion).
        Assert:Equals(2, mWorld:FloorItemCount).
        /* the gold lands on the nearest free square */
        DO y = 5 TO 7:
            DO x = 6 TO 8:
                IF VALID-OBJECT(mWorld:FloorItemAt(x, y)) AND mWorld:FloorItemAt(x, y):Category = ItemType:Gold THEN gold = gold + mWorld:FloorItemAt(x, y):Count.
            END.
        END.
        Assert:Equals(40, gold).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnoughExperienceMakesAHigherLevelAndMoreHitPoints():
        Build("19").
        mWorld:Hero:Experience = 9.
        Fighting:GainExperience(mWorld, 1).
        Assert:Equals(2, mWorld:Hero:Rank).
        /* the extra hit points are 1d10 (here 10: 19 modulo 10 is 9, plus 1) */
        Assert:Equals(22, mWorld:Hero:MaxHp).
        Assert:Equals(22, mWorld:Hero:Hp).
        Assert:Equals("Welcome to level 2!", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GreatExperienceCanMakeSeveralLevelsAtOnceButNeverPastTheLast():
        Build("19").
        Fighting:GainExperience(mWorld, 100).
        Assert:Equals(5, mWorld:Hero:Rank).
        mWorld:Hero:Rank = 21.
        Fighting:GainExperience(mWorld, 99999999).
        Assert:Equals(21, mWorld:Hero:Rank).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterHitsAndTheHeroLosesHitPoints():
        VAR Monster oHob.
        Build("19").
        oHob = Beside(MonsterKind:Hobgoblin, 8).
        Fighting:MonsterAttack(mWorld, oHob).
        /* 1d8 with a die of 8 less the roll 19 modulo 8 = 3, plus 1: 4 points */
        Assert:Equals(8, mWorld:Hero:Hp).
        Assert:Equals("The hobgoblin hits you.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterMissesWhenTheRollIsLow():
        VAR Monster oHob.
        Build("0").
        oHob = Beside(MonsterKind:Hobgoblin, 8).
        Fighting:MonsterAttack(mWorld, oHob).
        Assert:Equals(12, mWorld:Hero:Hp).
        Assert:Equals("The hobgoblin misses you.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterWithThreeAttacksHasThreeBlows():
        VAR Monster oCentaur.
        Build("19").
        mWorld:Hero:Hp = 99.
        mWorld:Hero:MaxHp = 99.
        oCentaur = Beside(MonsterKind:Centaur, 8).
        Fighting:MonsterAttack(mWorld, oCentaur).
        Assert:Equals("The centaur kicks you.  The centaur kicks you.  The centaur kicks you.", mWorld:Messages:Line(80)).
        Assert:IsTrue(mWorld:Hero:Hp < 99).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroDiesAtZeroHitPointsAndTheCauseIsKept():
        VAR Monster oHob.
        Build("19").
        mWorld:Hero:Hp = 3.
        oHob = Beside(MonsterKind:Hobgoblin, 8).
        Fighting:MonsterAttack(mWorld, oHob).
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals("a hobgoblin", mWorld:Cause).
        Assert:IsTrue(mWorld:Hero:Hp <= 0).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "You die...") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadHeroIsNotKilledAgainAndGetsNoMoreBlows():
        VAR Monster oCentaur.
        Build("19").
        mWorld:Hero:Hp = 1.
        oCentaur = Beside(MonsterKind:Centaur, 8).
        Fighting:MonsterAttack(mWorld, oCentaur).
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals("The centaur kicks you.  You die...", mWorld:Messages:Line(200)).
        Fighting:Die(mWorld, "something else").
        Assert:Equals("a centaur", mWorld:Cause).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterYouCannotSeeIsSomethingToYou():
        VAR Monster oPhantom.
        Build("19").
        oPhantom = Beside(MonsterKind:Phantom, 8).
        Assert:Equals("something", Fighting:Name(mWorld, oPhantom, FALSE)).
        Assert:Equals("Something", Fighting:Name(mWorld, oPhantom, TRUE)).
        mWorld:Hero:SeesInvisible = 5.
        Assert:Equals("the phantom", Fighting:Name(mWorld, oPhantom, FALSE)).
        mWorld:Hero:Blind = 5.
        Assert:Equals("something", Fighting:Name(mWorld, oPhantom, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAquatorRustsTheArmour():
        VAR Monster oAquator.
        Build("19").
        oAquator = Beside(MonsterKind:Aquator, 8).
        Fighting:MonsterAttack(mWorld, oAquator).
        Assert:Equals(0, mWorld:Pack:Worn():Bonus).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "Your armor weakens.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WardedArmourOrARingOfMaintainArmourDoesNotRust():
        VAR Monster oAquator.
        VAR Item oRing.
        Build("19").
        oAquator = Beside(MonsterKind:Aquator, 8).
        mWorld:Pack:Worn():Warded = TRUE.
        Fighting:MonsterAttack(mWorld, oAquator).
        Assert:Equals(1, mWorld:Pack:Worn():Bonus).
        mWorld:Pack:Worn():Warded = FALSE.
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:MaintainArmour)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Fighting:MonsterAttack(mWorld, oAquator).
        Assert:Equals(1, mWorld:Pack:Worn():Bonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnIceMonsterFreezesTheHero():
        VAR Monster oIce.
        Build("19").
        oIce = Beside(MonsterKind:IceMonster, 8).
        Fighting:MonsterAttack(mWorld, oIce).
        Assert:IsTrue(mWorld:Hero:Asleep > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVenusFlytrapHoldsTheHeroAndSqueezesHarderEachTurn():
        VAR Monster oPlant.
        Build("19").
        oPlant = Beside(MonsterKind:VenusFlytrap, 8).
        Fighting:MonsterAttack(mWorld, oPlant).
        Assert:IsTrue(mWorld:Hero:HeldBy = oPlant).
        Assert:Equals(11, mWorld:Hero:Hp).
        Fighting:MonsterAttack(mWorld, oPlant).
        Assert:Equals(9, mWorld:Hero:Hp).
        Fighting:MonsterAttack(mWorld, oPlant).
        Assert:Equals(6, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARattlesnakeWeakensTheHeroUnlessTheyAreSustained():
        VAR Monster oSnake.
        VAR Item oRing.
        Build("19").
        mWorld:Hero:Hp = 99.
        oSnake = Beside(MonsterKind:Rattlesnake, 8).
        Fighting:MonsterAttack(mWorld, oSnake).
        Assert:Equals(15, mWorld:Hero:Strength).
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:SustainStrength)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Fighting:MonsterAttack(mWorld, oSnake).
        Assert:Equals(15, mWorld:Hero:Strength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVampireDrainsTheMostHitPoints():
        VAR Monster oVamp.
        Build("19").
        mWorld:Hero:MaxHp = 40.
        mWorld:Hero:Hp = 40.
        oVamp = Beside(MonsterKind:Vampire, 8).
        Fighting:MonsterAttack(mWorld, oVamp).
        Assert:IsTrue(mWorld:Hero:MaxHp < 40).
        Assert:IsTrue(mWorld:Hero:Hp <= mWorld:Hero:MaxHp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWraithDrainsALevelAndKillsAHeroOfTheFirst():
        VAR Monster oWraith.
        Build("19").
        mWorld:Hero:Rank = 3.
        mWorld:Hero:Experience = 50.
        mWorld:Hero:MaxHp = 50.
        mWorld:Hero:Hp = 50.
        oWraith = Beside(MonsterKind:Wraith, 8).
        Fighting:MonsterAttack(mWorld, oWraith).
        Assert:Equals(2, mWorld:Hero:Rank).
        Assert:Equals(10, mWorld:Hero:Experience).
        Assert:IsFalse(mWorld:Dead).
        mWorld:Hero:Rank = 1.
        Fighting:MonsterAttack(mWorld, oWraith).
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals("a wraith", mWorld:Cause).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMedusaConfusesTheHero():
        VAR Monster oMedusa.
        Build("19").
        mWorld:Hero:Hp = 99.
        oMedusa = Beside(MonsterKind:Medusa, 8).
        Fighting:MonsterAttack(mWorld, oMedusa).
        Assert:IsTrue(mWorld:Hero:Confused > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeprechaunStealsGoldAndVanishes():
        VAR Monster oLep.
        Build("19").
        mWorld:Hero:Gold = 500.
        oLep = Beside(MonsterKind:Leprechaun, 8).
        Fighting:MonsterAttack(mWorld, oLep).
        Assert:IsTrue(mWorld:Hero:Gold < 500).
        Assert:Equals(0, mWorld:MonsterCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeprechaunWithNothingToStealStaysAndHits():
        VAR Monster oLep.
        Build("19").
        oLep = Beside(MonsterKind:Leprechaun, 8).
        Fighting:MonsterAttack(mWorld, oLep).
        Assert:Equals(1, mWorld:MonsterCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANymphStealsSomethingThatIsNotInUseAndVanishes():
        VAR Monster oNymph.
        VAR INTEGER before.
        Build("19").
        oNymph = Beside(MonsterKind:Nymph, 8).
        before = mWorld:Pack:Count.
        Fighting:MonsterAttack(mWorld, oNymph).
        Assert:Equals(before - 1, mWorld:Pack:Count).
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "She stole") > 0).
        /* what is worn or wielded is never taken */
        Assert:IsTrue(mWorld:Pack:Holds(1)).
        Assert:IsTrue(mWorld:Pack:Holds(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACancelledMonsterHasNoSpecial():
        VAR Monster oAquator.
        Build("19").
        oAquator = Beside(MonsterKind:Aquator, 8).
        oAquator:Cancelled = TRUE.
        Fighting:MonsterAttack(mWorld, oAquator).
        Assert:Equals(1, mWorld:Pack:Worn():Bonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroAsleepIsEasyToHit():
        VAR Monster oHob.
        /* a hobgoblin needs 20 - 1 - 6 = 13; a roll of 9 plus 4 for a sleeping hero lands, 9 alone does not */
        Build("8").
        oHob = Beside(MonsterKind:Hobgoblin, 8).
        Fighting:MonsterAttack(mWorld, oHob).
        Assert:Equals(12, mWorld:Hero:Hp).
        mWorld:Hero:Asleep = 3.
        Fighting:MonsterAttack(mWorld, oHob).
        Assert:IsTrue(mWorld:Hero:Hp < 12).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroTakesDamageAndDiesOnlyAtZero():
        Build("5").
        Fighting:Hurt(mWorld, 5, "an arrow trap").
        Assert:Equals(7, mWorld:Hero:Hp).
        Assert:IsFalse(mWorld:Dead).
        Fighting:Hurt(mWorld, 7, "an arrow trap").
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals("an arrow trap", mWorld:Cause).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DamagingAMonsterKillsItAtZero():
        VAR Monster oOrc.
        Build("5").
        oOrc = Beside(MonsterKind:Orc, 10).
        Assert:IsFalse(Fighting:DamageMonster(mWorld, oOrc, 4)).
        Assert:Equals(6, oOrc:Hp).
        Assert:IsTrue(Fighting:DamageMonster(mWorld, oOrc, 6)).
        Assert:Equals(0, mWorld:MonsterCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AConfusingTouchConfusesTheMonsterOnceThenWearsOff():
        VAR Monster oOrc.
        Build("19").
        oOrc = Beside(MonsterKind:Orc, 99).
        mWorld:Hero:ConfusingTouch = TRUE.
        Fighting:HeroAttack(mWorld, oOrc).
        Assert:IsTrue(oOrc:Confused > 0).
        Assert:IsFalse(mWorld:Hero:ConfusingTouch).
    END METHOD.


    @Test.
    METHOD PUBLIC VOID LosingALevelLowersTheRankTheExperienceAndTheMostHitPoints():
        Build("5").
        mWorld:Hero:Rank = 4.
        mWorld:Hero:Experience = 100.
        mWorld:Hero:MaxHp = 40.
        mWorld:Hero:Hp = 40.
        Fighting:LoseLevel(mWorld, "a wraith").
        Assert:Equals(3, mWorld:Hero:Rank).
        Assert:Equals(20, mWorld:Hero:Experience).
        Assert:IsTrue(mWorld:Hero:MaxHp < 40).
        Assert:IsFalse(mWorld:Dead).
    END METHOD.
END CLASS.
