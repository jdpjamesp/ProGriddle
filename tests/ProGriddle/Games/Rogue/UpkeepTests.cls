/* What happens to the hero as turns go by: hunger, healing, timers and the rings that work by themselves. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.UpkeepTests:

    DEFINE PRIVATE VARIABLE mWorld AS RogueWorld NO-UNDO.

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

    METHOD PRIVATE VOID Wear(INPUT poKind AS RingKind):
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(Items:Make(ItemType:Ring, INTEGER(poKind))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStagesOfHungerStartAtThreeHundredOneFiftyAndFifty():
        Assert:Equals(0, Upkeep:StageOf(2000)).
        Assert:Equals(0, Upkeep:StageOf(300)).
        Assert:Equals(1, Upkeep:StageOf(299)).
        Assert:Equals(1, Upkeep:StageOf(150)).
        Assert:Equals(2, Upkeep:StageOf(149)).
        Assert:Equals(2, Upkeep:StageOf(50)).
        Assert:Equals(3, Upkeep:StageOf(49)).
        Assert:Equals(3, Upkeep:StageOf(1)).
        Assert:Equals(4, Upkeep:StageOf(0)).
        Assert:Equals(4, Upkeep:StageOf(-5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnCostsOnePointOfFood():
        Build("5").
        Upkeep:Tick(mWorld).
        Assert:Equals(1999, mWorld:Hero:Nutrition).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfSlowDigestionHalvesTheCost():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Build("5").
        Wear(RingKind:SlowDigestion).
        DO i = 0 TO 9:
            mWorld:Turns = i.
            Upkeep:Tick(mWorld).
        END.
        Assert:Equals(1995, mWorld:Hero:Nutrition).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HungerIsToldAtEachStageOnlyOnce():
        Build("6").
        mWorld:Hero:Nutrition = 300.
        Upkeep:Tick(mWorld).
        Assert:Equals("You are starting to feel hungry.", mWorld:Messages:At(0)).
        Upkeep:Tick(mWorld).
        Assert:Equals(1, mWorld:Messages:Count).
        mWorld:Hero:Nutrition = 150.
        Upkeep:Tick(mWorld).
        Assert:Equals("You are getting weak from hunger.", mWorld:Messages:At(0)).
        mWorld:Hero:Nutrition = 50.
        Upkeep:Tick(mWorld).
        Assert:Equals("You feel faint from lack of food.", mWorld:Messages:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroWithAnEmptyStomachStarves():
        Build("5").
        mWorld:Hero:Nutrition = 1.
        Upkeep:Tick(mWorld).
        Assert:IsTrue(mWorld:Dead).
        Assert:Equals("starvation", mWorld:Cause).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFaintHeroMayFallAsleep():
        Build("0").
        mWorld:Hero:Nutrition = 40.
        mWorld:Hero:HungerStage = 3.
        Upkeep:Tick(mWorld).
        Assert:Equals(3, mWorld:Hero:Asleep).
        Assert:Equals("You faint from lack of food.", mWorld:Messages:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HitPointsComeBackOneEveryTwentyTurnsAtTheFirstLevel():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Build("5").
        mWorld:Hero:Hp = 5.
        DO i = 1 TO 19:
            Upkeep:Tick(mWorld).
        END.
        Assert:Equals(5, mWorld:Hero:Hp).
        Upkeep:Tick(mWorld).
        Assert:Equals(6, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHealingPeriodShrinksWithExperienceAndHalvesWithARingOfRegeneration():
        Assert:Equals(20, Upkeep:HealEvery(1, FALSE)).
        Assert:Equals(8, Upkeep:HealEvery(7, FALSE)).
        Assert:Equals(3, Upkeep:HealEvery(8, FALSE)).
        Assert:Equals(3, Upkeep:HealEvery(15, FALSE)).
        Assert:Equals(10, Upkeep:HealEvery(1, TRUE)).
        Assert:Equals(1, Upkeep:HealEvery(8, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroAtFullHealthDoesNotStoreUpHealing():
        Build("5").
        mWorld:Hero:HealCounter = 15.
        Upkeep:Tick(mWorld).
        Assert:Equals(0, mWorld:Hero:HealCounter).
        Assert:Equals(12, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimersRunDownAndSayWhenTheyEnd():
        Build("5").
        mWorld:Hero:Confused = 1.
        mWorld:Hero:Blind = 1.
        mWorld:Hero:Levitating = 1.
        mWorld:Hero:Hallucinating = 1.
        mWorld:Hero:SeesInvisible = 1.
        mWorld:Hero:SensesMonsters = 2.
        mWorld:Hero:SensesMagic = 2.
        mWorld:Hero:SensesFood = 2.
        Upkeep:Tick(mWorld).
        Assert:Equals(0, mWorld:Hero:Confused).
        Assert:Equals(0, mWorld:Hero:Blind).
        Assert:Equals(0, mWorld:Hero:Levitating).
        Assert:Equals(0, mWorld:Hero:Hallucinating).
        Assert:Equals(0, mWorld:Hero:SeesInvisible).
        Assert:Equals(1, mWorld:Hero:SensesMonsters).
        Assert:Equals(1, mWorld:Hero:SensesMagic).
        Assert:Equals(1, mWorld:Hero:SensesFood).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(500), "less confused") > 0).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(500), "veil of darkness lifts") > 0).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(500), "float gently") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfSearchingSearchesEveryTurn():
        Build("0").
        mWorld:Cave:SetTerrain(15, 6, Terrain:SecretDown).
        mWorld:PlaceHero(14, 6).
        Wear(RingKind:Searching).
        Upkeep:Tick(mWorld).
        Assert:Equals(INTEGER(Terrain:Door), mWorld:Cave:TerrainAt(15, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingOfTeleportationMovesTheHeroNowAndThen():
        Build("0").
        Wear(RingKind:Teleportation).
        Upkeep:Tick(mWorld).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "drawn away") > 0).
        Assert:IsFalse(mWorld:Hero:X = 6 AND mWorld:Hero:Y = 6).
    END METHOD.

END CLASS.
