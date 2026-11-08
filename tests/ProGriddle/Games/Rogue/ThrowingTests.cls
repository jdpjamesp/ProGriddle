/* Throwing a thing from the pack: where it flies, what it hits, and where it lands. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ThrowingTests:

    VAR PRIVATE RogueWorld mWorld.

    /* A lit room with floor (5, 5) to (14, 8), the hero at (6, 6), the starting kit: a food ration, ring mail, a mace, a bow, arrows (slot 4) */
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

    METHOD PRIVATE Monster Beside(INPUT poKind AS MonsterKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR Monster oMonster.
        oMonster = mWorld:AddMonster(poKind, piX, piY).
        oMonster:Hp = 30.
        oMonster:MaxHp = 30.
        oMonster:Awake = TRUE.
        RETURN oMonster.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThrownThingLandsAgainstTheWallOrTenSquaresOff():
        Build("5").
        mWorld:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear))).
        Assert:IsTrue(Throwing:Throw(mWorld, 5, 1, 0)).
        Assert:IsFalse(mWorld:Pack:Holds(5)).
        Assert:IsTrue(VALID-OBJECT(mWorld:FloorItemAt(14, 6))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThrownThingUpAgainstAWallLandsInFrontOfIt():
        Build("5").
        mWorld:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear))).
        Throwing:Throw(mWorld, 5, 0, -1).
        Assert:IsTrue(VALID-OBJECT(mWorld:FloorItemAt(6, 5))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OneOfAStackIsThrown():
        VAR INTEGER before.
        Build("5").
        before = mWorld:Pack:At(4):Count.
        Throwing:Throw(mWorld, 4, 1, 0).
        Assert:Equals(before - 1, mWorld:Pack:At(4):Count).
        Assert:Equals(1, mWorld:FloorItemAt(14, 6):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADartThatHitsDoesItsDamageAndThenLies():
        VAR Monster oOrc.
        VAR INTEGER slot.
        Build("19").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        slot = mWorld:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Dart))).
        Throwing:Throw(mWorld, slot, 1, 0).
        Assert:IsTrue(oOrc:Hp < 30).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "hits the orc") > 0).
        Assert:IsTrue(VALID-OBJECT(mWorld:FloorItemAt(10, 6))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMissFallsAtTheMonstersFeet():
        VAR Monster oOrc.
        VAR INTEGER slot.
        Build("0").
        oOrc = Beside(MonsterKind:Orc, 10, 6).
        slot = mWorld:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Dart))).
        Throwing:Throw(mWorld, slot, 1, 0).
        Assert:Equals(30, oOrc:Hp).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "misses the orc") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnArrowNeedsTheBowInHandToDoItsFullDamage():
        Build("5").
        Assert:Equals("1d1", Throwing:DiceOf(mWorld, mWorld:Pack:At(4))).
        mWorld:Pack:WieldedSlot = 3.
        Assert:Equals("1d6", Throwing:DiceOf(mWorld, mWorld:Pack:At(4))).
        Assert:Equals("1d4", Throwing:DiceOf(mWorld, Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Dagger)))).
        Assert:Equals("1d2", Throwing:DiceOf(mWorld, Items:Make(ItemType:Potion, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APotionThrownBreaksAndIsGone():
        Build("5").
        mWorld:Pack:Add(Items:Make(ItemType:Potion, 3)).
        Throwing:Throw(mWorld, 5, 1, 0).
        Assert:Equals(0, mWorld:FloorItemCount).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "shatters") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingCanBeThrownThatIsNotThereOrIsACursedThingInUse():
        Build("5").
        Assert:IsFalse(Throwing:Throw(mWorld, 15, 1, 0)).
        Assert:IsTrue(mWorld:Pack:Holds(2)).
        mWorld:Pack:At(2):Cursed = TRUE.
        Assert:IsFalse(Throwing:Throw(mWorld, 2, 1, 0)).
        Assert:IsTrue(mWorld:Pack:Holds(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThrownWeaponThatKillsGivesTheExperience():
        VAR Monster oBat.
        VAR INTEGER slot.
        Build("19").
        oBat = Beside(MonsterKind:Bat, 9, 6).
        oBat:Hp = 1.
        slot = mWorld:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Dart))).
        Throwing:Throw(mWorld, slot, 1, 0).
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:IsTrue(mWorld:Hero:Experience >= 1).
    END METHOD.

END CLASS.
