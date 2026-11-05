/* The records of the game: the rules numbers, the monster, the hero. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RecordsTests:

    @Test.
    METHOD PUBLIC VOID TheMapIsEightyByTwentyOneOnAnEightyByTwentyFourScreen():
        Assert:Equals(80, RogueRules:MapWidth()).
        Assert:Equals(21, RogueRules:MapHeight()).
        Assert:Equals(80, RogueRules:ScreenColumns()).
        Assert:Equals(24, RogueRules:ScreenRows()).
        Assert:Equals(26, RogueRules:AmuletDepth()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePackHoldsTwentyThreeThingsAndTheLevelsHaveLimits():
        Assert:Equals(23, RogueRules:PackSize()).
        Assert:IsTrue(RogueRules:MostMonsters() >= 32).
        Assert:IsTrue(RogueRules:MostFloorItems() >= 60).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStomachFallsThroughHungryWeakAndFaint():
        Assert:Equals(2000, RogueRules:StomachSize()).
        Assert:IsTrue(RogueRules:HungryBelow() > RogueRules:WeakBelow()).
        Assert:IsTrue(RogueRules:WeakBelow() > RogueRules:FaintBelow()).
        Assert:IsTrue(RogueRules:FaintBelow() > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheExperienceTableRisesAndEndsAtTheLastLevel():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(10, RogueRules:ExperienceToPass(1)).
        Assert:Equals(8000000, RogueRules:ExperienceToPass(20)).
        Assert:Equals(0, RogueRules:ExperienceToPass(21)).
        Assert:Equals(0, RogueRules:ExperienceToPass(0)).
        Assert:Equals(0, RogueRules:ExperienceToPass(?)).
        Assert:Equals(21, RogueRules:HighestRank()).
        DO i = 2 TO 20:
            Assert:IsTrue(RogueRules:ExperienceToPass(i) > RogueRules:ExperienceToPass(i - 1)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StrengthAddsToHitAndDamageAbove16AndTakesAwayBelow():
        Assert:Equals(0, RogueRules:StrengthHit(16)).
        Assert:Equals(0, RogueRules:StrengthHit(17)).
        Assert:Equals(1, RogueRules:StrengthHit(18)).
        Assert:Equals(2, RogueRules:StrengthHit(20)).
        Assert:Equals(0, RogueRules:StrengthHit(15)).
        Assert:Equals(-1, RogueRules:StrengthHit(14)).
        Assert:Equals(-3, RogueRules:StrengthHit(10)).
        Assert:Equals(RogueRules:StrengthHit(19), RogueRules:StrengthDamage(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterStartsAsItsKindDoes():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        oMonster = NEW Monster(MonsterKind:Hobgoblin, 7).
        Assert:Equals(MonsterKind:Hobgoblin, oMonster:Kind).
        Assert:Equals(7, oMonster:Hp).
        Assert:Equals(7, oMonster:MaxHp).
        Assert:IsTrue(oMonster:Awake).
        Assert:IsFalse(oMonster:Invisible).
        Assert:Equals("H", oMonster:Letter()).
        Assert:Equals("hobgoblin", oMonster:Called()).
        oMonster = NEW Monster(MonsterKind:Nymph, 5).
        Assert:IsFalse(oMonster:Awake).
        oMonster = NEW Monster(MonsterKind:Phantom, 5).
        Assert:IsTrue(oMonster:Invisible).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterHasPlaceStateAndTimers():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        oMonster = NEW Monster(MonsterKind:Orc, 6).
        oMonster:X = 12.
        oMonster:Y = 5.
        oMonster:Gold = 40.
        oMonster:Held = 3.
        oMonster:Confused = 2.
        oMonster:Slowed = 4.
        oMonster:Hasted = 5.
        oMonster:Cancelled = TRUE.
        oMonster:Seen = TRUE.
        oMonster:Awake = TRUE.
        Assert:Equals(12, oMonster:X).
        Assert:Equals(5, oMonster:Y).
        Assert:Equals(40, oMonster:Gold).
        Assert:Equals(3, oMonster:Held).
        Assert:Equals(2, oMonster:Confused).
        Assert:Equals(4, oMonster:Slowed).
        Assert:Equals(5, oMonster:Hasted).
        Assert:IsTrue(oMonster:Cancelled).
        Assert:IsTrue(oMonster:Seen).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterNeedsAKindAndAHitPoint():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Monster(?, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Monster(MonsterKind:Bat, 0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroStartsWithTwelveHitPointsAStrengthOfSixteenAndAFullStomach():
        DEFINE VARIABLE oHero AS Hero NO-UNDO.
        oHero = NEW Hero().
        Assert:Equals(12, oHero:Hp).
        Assert:Equals(12, oHero:MaxHp).
        Assert:Equals(16, oHero:Strength).
        Assert:Equals(16, oHero:MaxStrength).
        Assert:Equals(1, oHero:Rank).
        Assert:Equals(0, oHero:Experience).
        Assert:Equals(0, oHero:Gold).
        Assert:Equals(RogueRules:StomachSize(), oHero:Nutrition).
        Assert:Equals(0, oHero:Confused).
        Assert:Equals(0, oHero:Blind).
        Assert:Equals(0, oHero:Hasted).
        Assert:Equals(0, oHero:Levitating).
        Assert:Equals(0, oHero:Asleep).
        Assert:Equals(0, oHero:Stuck).
        Assert:Equals(0, oHero:Hallucinating).
        Assert:Equals(0, oHero:SeesInvisible).
        Assert:IsFalse(oHero:ConfusingTouch).
        Assert:IsFalse(VALID-OBJECT(oHero:HeldBy)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroHasAPlace():
        DEFINE VARIABLE oHero AS Hero NO-UNDO.
        oHero = NEW Hero().
        oHero:X = 30.
        oHero:Y = 9.
        Assert:Equals(30, oHero:X).
        Assert:Equals(9, oHero:Y).
        oHero:HeldBy = NEW Monster(MonsterKind:VenusFlytrap, 8).
        Assert:IsTrue(VALID-OBJECT(oHero:HeldBy)).
    END METHOD.


    @Test.
    METHOD PUBLIC VOID TheStartingNumbersAreTwelveHitPointsAndSixteenStrength():
        Assert:Equals(12, RogueRules:StartHp()).
        Assert:Equals(16, RogueRules:StartStrength()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFlytrapsGripStartsAtNothing():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        oMonster = NEW Monster(MonsterKind:VenusFlytrap, 8).
        Assert:Equals(0, oMonster:Grip).
        oMonster:Grip = 3.
        Assert:Equals(3, oMonster:Grip).
    END METHOD.
END CLASS.
