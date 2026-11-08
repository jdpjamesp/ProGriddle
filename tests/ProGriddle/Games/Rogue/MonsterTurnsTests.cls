/* What the monsters do on their turn: sleep, wake, hunt, hit, flutter, hold, breathe, and keep off a scroll of scare monster. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.MonsterTurnsTests:

    VAR PRIVATE RogueWorld mWorld.
    VAR PRIVATE MonsterTurns mTurns.

    /* A world whose random source says one number for ever; a lit room with floor (5, 5) to (24, 8), and the hero at (6, 6) */
    METHOD PRIVATE VOID Build(INPUT pcScript AS CHARACTER):
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom(pcScript)).
        mWorld:NewHero().
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 20, 4).
        mWorld:PlaceHero(6, 6).
        mTurns = NEW MonsterTurns().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseScene():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
        mTurns = ?.
    END METHOD.

    METHOD PRIVATE Monster Spawn(INPUT poKind AS MonsterKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plAwake AS LOGICAL):
        VAR Monster oMonster.
        oMonster = mWorld:AddMonster(poKind, piX, piY).
        oMonster:Awake = plAwake.
        oMonster:Hp = 20.
        oMonster:MaxHp = 20.
        RETURN oMonster.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASleepingMonsterStaysAsleepWhenTheRollIsHigh():
        VAR Monster oOrc.
        Build("3").
        oOrc = Spawn(MonsterKind:Nymph, 9, 6, FALSE).
        mTurns:Take(mWorld).
        Assert:IsFalse(oOrc:Awake).
        Assert:Equals(9, oOrc:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASleepingMonsterInTheHerosRoomWakesOnALowRoll():
        VAR Monster oOrc.
        Build("0").
        oOrc = Spawn(MonsterKind:Nymph, 20, 7, FALSE).
        mTurns:Take(mWorld).
        Assert:IsTrue(oOrc:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASleepingMonsterFarFromTheHeroInAnotherRoomDoesNotWake():
        VAR Monster oOrc.
        Build("0").
        mWorld:Cave:SetTerrain(40, 15, Terrain:Floor).
        mWorld:Cave:SetRoom(40, 15, 2).
        oOrc = Spawn(MonsterKind:Nymph, 40, 15, FALSE).
        mTurns:Take(mWorld).
        Assert:IsFalse(oOrc:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfStealthMakesSleepersWakeLessOften():
        VAR Monster oNymph.
        VAR Item oRing.
        /* a roll of 6: wakes when the chance is 1 in 4 only if the roll is 0 modulo 4; with stealth the limit is 12, so 6 does not either */
        Build("4").
        oNymph = Spawn(MonsterKind:Nymph, 20, 7, FALSE).
        mTurns:Take(mWorld).
        Assert:IsTrue(oNymph:Awake).
        mWorld:Dispose().
        Build("4").
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:Stealth)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        oNymph = Spawn(MonsterKind:Nymph, 20, 7, FALSE).
        mTurns:Take(mWorld).
        Assert:IsFalse(oNymph:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfAggravationWakesEverythingAtOnce():
        VAR Monster oNymph.
        VAR Item oRing.
        Build("3").
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:Aggravation)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        oNymph = Spawn(MonsterKind:Nymph, 20, 7, FALSE).
        mTurns:Take(mWorld).
        Assert:IsTrue(oNymph:Awake).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAwakeMonsterNextToTheHeroHitsThem():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 7, 6, TRUE).
        mTurns:Take(mWorld).
        Assert:Equals("The hobgoblin hits you.", mWorld:Messages:Line(80)).
        Assert:Equals(7, oHob:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAwakeMonsterFarAwayStepsTowardsTheHero():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        mTurns:Take(mWorld).
        Assert:Equals(13, oHob:X).
        Assert:Equals("", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterKeepsComingUntilItIsNextToTheHero():
        VAR Monster oHob.
        VAR INTEGER i.
        Build("19").
        mWorld:Hero:Hp = 99.
        mWorld:Hero:MaxHp = 99.
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        DO i = 1 TO 7:
            mTurns:Take(mWorld).
        END.
        Assert:Equals(1, RogueWorld:Distance(oHob:X, oHob:Y, 6, 6)).
        Assert:Equals("", mWorld:Messages:Line(80)).
        mTurns:Take(mWorld).
        Assert:Equals("The hobgoblin hits you.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterThatCannotReachTheHeroWandersOrStaysButNeverWalksThroughWalls():
        VAR Monster oHob.
        VAR INTEGER i.
        Build("19").
        mWorld:Cave:SetTerrain(40, 15, Terrain:Floor).
        mWorld:Cave:SetTerrain(41, 15, Terrain:Floor).
        oHob = Spawn(MonsterKind:Hobgoblin, 40, 15, TRUE).
        DO i = 1 TO 10:
            mTurns:Take(mWorld).
            Assert:IsTrue(mWorld:Cave:Walkable(oHob:X, oHob:Y)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVenusFlytrapNeverMovesButHitsWhenTheHeroIsNext():
        VAR Monster oPlant.
        Build("19").
        oPlant = Spawn(MonsterKind:VenusFlytrap, 14, 6, TRUE).
        mTurns:Take(mWorld).
        Assert:Equals(14, oPlant:X).
        mWorld:PlaceHero(13, 6).
        mTurns:Take(mWorld).
        Assert:IsTrue(mWorld:Hero:HeldBy = oPlant).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeldMonsterMissesItsTurnAndASlowedOneEveryOther():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        oHob:Held = 2.
        mTurns:Take(mWorld).
        Assert:Equals(14, oHob:X).
        Assert:Equals(1, oHob:Held).
        mTurns:Take(mWorld).
        Assert:Equals(14, oHob:X).
        mTurns:Take(mWorld).
        Assert:Equals(13, oHob:X).
        oHob:Slowed = 6.
        mWorld:Turns = 1.
        mTurns:Take(mWorld).
        Assert:Equals(12, oHob:X).
        mWorld:Turns = 2.
        mTurns:Take(mWorld).
        Assert:Equals(12, oHob:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHastedMonsterMovesTwice():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        oHob:Hasted = 3.
        mTurns:Take(mWorld).
        Assert:Equals(12, oHob:X).
        Assert:Equals(2, oHob:Hasted).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABatFlutterAboutInsteadOfComingStraight():
        VAR Monster oBat.
        Build("0").
        oBat = Spawn(MonsterKind:Bat, 14, 6, TRUE).
        mTurns:Take(mWorld).
        /* the roll of 0 says flutter, and a direction of (-1, -1) from the random source: up and to the left is a wall, so it stays or tries again */
        Assert:IsTrue(oBat:X >= 13 AND oBat:X <= 15).
        Assert:IsTrue(oBat:Y >= 5 AND oBat:Y <= 7).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AConfusedMonsterStumblesAndThenRecovers():
        VAR Monster oHob.
        Build("0").
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        oHob:Confused = 2.
        mTurns:Take(mWorld).
        Assert:Equals(1, oHob:Confused).
        mTurns:Take(mWorld).
        Assert:Equals(0, oHob:Confused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATrollHealsAsItGoes():
        VAR Monster oTroll.
        Build("19").
        oTroll = Spawn(MonsterKind:Troll, 20, 8, FALSE).
        oTroll:Hp = 5.
        mWorld:Turns = 4.
        mTurns:Take(mWorld).
        Assert:Equals(6, oTroll:Hp).
        mWorld:Turns = 5.
        mTurns:Take(mWorld).
        Assert:Equals(6, oTroll:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADragonBreathesFireDownAClearLine():
        VAR Monster oDragon.
        Build("0").
        mWorld:Hero:Hp = 99.
        mWorld:Hero:MaxHp = 99.
        oDragon = Spawn(MonsterKind:Dragon, 11, 6, TRUE).
        mTurns:Take(mWorld).
        Assert:Equals("The dragon breathes fire!", mWorld:Messages:Line(80)).
        /* 6d6 with every die a 1 is 6 */
        Assert:Equals(93, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADragonDoesNotBreatheOffTheLineOrTooFarOrWhenCancelled():
        VAR Monster oDragon.
        Build("0").
        mWorld:Hero:Hp = 99.
        mWorld:Hero:MaxHp = 99.
        oDragon = Spawn(MonsterKind:Dragon, 11, 7, TRUE).
        mTurns:Take(mWorld).
        Assert:Equals(99, mWorld:Hero:Hp).
        mWorld:MoveMonster(oDragon, 20, 6).
        mTurns:Take(mWorld).
        Assert:Equals(99, mWorld:Hero:Hp).
        mWorld:MoveMonster(oDragon, 11, 6).
        oDragon:Cancelled = TRUE.
        mTurns:Take(mWorld).
        Assert:Equals(99, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterWillNotHitAHeroStandingOnAScrollOfScareMonster():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 7, 6, TRUE).
        mWorld:DropOnFloor(Items:Make(ItemType:Scroll, INTEGER(ScrollKind:ScareMonster)), 6, 6).
        Assert:IsTrue(MonsterTurns:Scared(mWorld, 6, 6)).
        mTurns:Take(mWorld).
        Assert:Equals("", mWorld:Messages:Line(80)).
        Assert:Equals(12, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterWillNotStepOntoAScrollOfScareMonster():
        VAR Monster oHob.
        Build("19").
        oHob = Spawn(MonsterKind:Hobgoblin, 14, 6, TRUE).
        mWorld:DropOnFloor(Items:Make(ItemType:Scroll, INTEGER(ScrollKind:ScareMonster)), 13, 6).
        mWorld:DropOnFloor(Items:Make(ItemType:Scroll, INTEGER(ScrollKind:ScareMonster)), 13, 5).
        mWorld:DropOnFloor(Items:Make(ItemType:Scroll, INTEGER(ScrollKind:ScareMonster)), 13, 7).
        mTurns:Take(mWorld).
        Assert:Equals(14, oHob:X).
        Assert:IsFalse(MonsterTurns:Scared(mWorld, 14, 6)).
        Assert:IsFalse(MonsterTurns:Scared(mWorld, 3, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMonstersStopWhenTheHeroIsDead():
        VAR Monster oHob.
        VAR Monster oOrc.
        Build("19").
        mWorld:Hero:Hp = 1.
        oHob = Spawn(MonsterKind:Hobgoblin, 7, 6, TRUE).
        oOrc = Spawn(MonsterKind:Orc, 14, 6, TRUE).
        mTurns:Take(mWorld).
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals(14, oOrc:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePreparedChaseMapIsTheOneForTheHero():
        Build("19").
        mTurns:Prepare(mWorld).
        Assert:Equals(0, mTurns:Map:DistanceAt(6, 6)).
        Assert:Equals(5, mTurns:Map:DistanceAt(11, 6)).
    END METHOD.

END CLASS.
