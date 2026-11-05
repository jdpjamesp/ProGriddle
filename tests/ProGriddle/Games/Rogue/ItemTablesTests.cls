/* The tables that are not made from the plain pattern: weapons, armour, food, traps and the monsters. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ItemTablesTests:

    @Test.
    METHOD PUBLIC VOID TheNineWeaponsHaveDamageAChanceAndAWorth():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(9, Weapons:Count()).
        Assert:Equals(100, WeightedPick:Total(Weapons:Chances())).
        DO i = 0 TO 8:
            Assert:IsTrue(Dice:Highest(Weapons:Swing(WeaponKind:GetEnum(i))) >= 1).
            Assert:IsTrue(Dice:Highest(Weapons:Hurled(WeaponKind:GetEnum(i))) >= 1).
            Assert:IsTrue(Weapons:Chance(WeaponKind:GetEnum(i)) > 0).
            Assert:IsTrue(Weapons:Worth(WeaponKind:GetEnum(i)) > 0).
            Assert:IsTrue(LENGTH(Weapons:NameOf(WeaponKind:GetEnum(i))) > 2).
        END.
        Assert:Equals("mace", Weapons:NameOf(WeaponKind:Mace)).
        Assert:Equals("2d4", Weapons:Swing(WeaponKind:Mace)).
        Assert:Equals("3d6", Weapons:Swing(WeaponKind:TwoHandedSword)).
        Assert:Equals("1d6", Weapons:Hurled(WeaponKind:Arrow)).
        Assert:Equals(WeaponKind:Mace, Weapons:Roll(NEW ScriptedRandom("0"))).
        Assert:Equals(WeaponKind:Shuriken, Weapons:Roll(NEW ScriptedRandom("99"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyArrowsDartsAndShurikenComeInStacks():
        Assert:IsFalse(Weapons:Stacks(WeaponKind:Mace)).
        Assert:IsFalse(Weapons:Stacks(WeaponKind:Bow)).
        Assert:IsFalse(Weapons:Stacks(WeaponKind:Spear)).
        Assert:IsTrue(Weapons:Stacks(WeaponKind:Arrow)).
        Assert:IsTrue(Weapons:Stacks(WeaponKind:Dart)).
        Assert:IsTrue(Weapons:Stacks(WeaponKind:Shuriken)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEightSuitsOfArmourGetBetterTheHeavierTheyAre():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(8, Armours:Count()).
        Assert:Equals(100, WeightedPick:Total(Armours:Chances())).
        Assert:Equals(8, Armours:ArmourClass(ArmourKind:Leather)).
        Assert:Equals(3, Armours:ArmourClass(ArmourKind:PlateMail)).
        DO i = 0 TO 7:
            Assert:IsTrue(Armours:ArmourClass(ArmourKind:GetEnum(i)) >= 3 AND Armours:ArmourClass(ArmourKind:GetEnum(i)) <= 8).
            Assert:IsTrue(Armours:Chance(ArmourKind:GetEnum(i)) > 0).
            Assert:IsTrue(Armours:Worth(ArmourKind:GetEnum(i)) > 0).
            Assert:IsTrue(LENGTH(Armours:NameOf(ArmourKind:GetEnum(i))) > 3).
        END.
        Assert:Equals("ring mail", Armours:NameOf(ArmourKind:RingMail)).
        Assert:Equals(ArmourKind:Leather, Armours:Roll(NEW ScriptedRandom("0"))).
        Assert:Equals(ArmourKind:PlateMail, Armours:Roll(NEW ScriptedRandom("99"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FoodIsMostlyRationsAndARationFeedsMoreThanAMango():
        Assert:Equals(2, Foods:Count()).
        Assert:Equals(100, WeightedPick:Total(Foods:Chances())).
        Assert:Equals("food ration", Foods:NameOf(FoodKind:Ration)).
        Assert:Equals("mango", Foods:NameOf(FoodKind:Mango)).
        Assert:Equals(90, Foods:Chance(FoodKind:Ration)).
        Assert:IsTrue(Foods:Nutrition(FoodKind:Ration) > Foods:Nutrition(FoodKind:Mango)).
        Assert:IsTrue(Foods:Worth(FoodKind:Ration) > 0).
        Assert:Equals(FoodKind:Ration, Foods:Roll(NEW ScriptedRandom("0"))).
        Assert:Equals(FoodKind:Mango, Foods:Roll(NEW ScriptedRandom("99"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEightTrapsHaveNamesAndChances():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(8, Traps:Count()).
        Assert:Equals(100, WeightedPick:Total(Traps:Chances())).
        DO i = 0 TO 7:
            Assert:IsTrue(Traps:Chance(TrapKind:GetEnum(i)) > 0).
            Assert:IsTrue(INDEX(Traps:NameOf(TrapKind:GetEnum(i)), "trap") > 0).
        END.
        Assert:Equals("trap door", Traps:NameOf(TrapKind:TrapDoor)).
        Assert:Equals(TrapKind:TrapDoor, Traps:Roll(NEW ScriptedRandom("0"))).
        Assert:Equals(TrapKind:Mystic, Traps:Roll(NEW ScriptedRandom("99"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryMonsterIsALetterAToZWithFightingNumbers():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(26, Bestiary:Count()).
        DO i = 0 TO 25:
            Assert:Equals(CHR(65 + i), Bestiary:Letter(MonsterKind:GetEnum(i))).
            Assert:Equals(MonsterKind:GetEnum(i), Bestiary:OfLetter(CHR(65 + i))).
            Assert:IsTrue(Bestiary:Level(MonsterKind:GetEnum(i)) >= 1).
            Assert:IsTrue(Bestiary:Experience(MonsterKind:GetEnum(i)) >= 1).
            Assert:IsTrue(Bestiary:ArmourClass(MonsterKind:GetEnum(i)) >= -2 AND Bestiary:ArmourClass(MonsterKind:GetEnum(i)) <= 9).
            Assert:IsTrue(Bestiary:Carry(MonsterKind:GetEnum(i)) >= 0 AND Bestiary:Carry(MonsterKind:GetEnum(i)) <= 100).
            Assert:IsTrue(LENGTH(Bestiary:NameOf(MonsterKind:GetEnum(i))) > 2).
            Assert:IsTrue(Dice:Attacks(Bestiary:Damage(MonsterKind:GetEnum(i))) >= 1).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMonstersAreWhoTheOriginalSays():
        Assert:Equals("bat", Bestiary:NameOf(MonsterKind:Bat)).
        Assert:Equals("D", Bestiary:Letter(MonsterKind:Dragon)).
        Assert:Equals(5000, Bestiary:Experience(MonsterKind:Dragon)).
        Assert:Equals("1d8/1d8/3d10", Bestiary:Damage(MonsterKind:Dragon)).
        Assert:Equals(-2, Bestiary:ArmourClass(MonsterKind:UrVile)).
        Assert:Equals(15, Bestiary:Level(MonsterKind:Jabberwock)).
        Assert:Equals(MonsterKind:Zombie, Bestiary:OfLetter("z")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFlagsSayHowAMonsterBehaves():
        Assert:IsTrue(Bestiary:Has(MonsterKind:Hobgoblin, "M")).
        Assert:IsFalse(Bestiary:Has(MonsterKind:Nymph, "M")).
        Assert:IsTrue(Bestiary:Has(MonsterKind:Bat, "F")).
        Assert:IsTrue(Bestiary:Has(MonsterKind:Troll, "R")).
        Assert:IsTrue(Bestiary:Has(MonsterKind:Phantom, "I")).
        Assert:IsTrue(Bestiary:Has(MonsterKind:Orc, "G")).
        Assert:IsTrue(Bestiary:Has(MonsterKind:VenusFlytrap, "S")).
        Assert:Equals("", Bestiary:Flags(MonsterKind:Nymph)).
        Assert:Equals("MR", Bestiary:Flags(MonsterKind:Troll)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDepthOrderHoldsEveryLetterOnce():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(26, LENGTH(Bestiary:DepthOrder())).
        DO i = 0 TO 25:
            Assert:IsTrue(INDEX(Bestiary:DepthOrder(), CHR(65 + i)) > 0).
        END.
        Assert:Equals("K", SUBSTRING(Bestiary:DepthOrder(), 1, 1)).
        Assert:Equals("D", SUBSTRING(Bestiary:DepthOrder(), 26, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMonsterOfADepthIsNearItsPlaceInTheOrder():
        /* a roll of 6 (index 6 - 6 = 0) gives exactly the depth's own monster */
        Assert:Equals(MonsterKind:Kestrel, Bestiary:ForDepth(1, NEW ScriptedRandom("6"))).
        Assert:Equals(MonsterKind:Emu, Bestiary:ForDepth(2, NEW ScriptedRandom("6"))).
        Assert:Equals(MonsterKind:Dragon, Bestiary:ForDepth(26, NEW ScriptedRandom("6"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRollMovesTheMonsterAndTheEndsAreBrought():
        DEFINE VARIABLE i       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE oRandom AS SeededRandom NO-UNDO.
        DEFINE VARIABLE thrown  AS INTEGER      NO-UNDO.
        oRandom = NEW SeededRandom(5).
        /* the lowest roll on depth 1 and the highest on 26 never leave the list */
        Assert:Equals(MonsterKind:Kestrel, Bestiary:ForDepth(1, NEW ScriptedRandom("0,0"))).
        Assert:Equals(MonsterKind:Dragon, Bestiary:ForDepth(26, NEW ScriptedRandom("9,0"))).
        DO i = 1 TO 300:
            Bestiary:ForDepth(1 + i MODULO 26, oRandom).
        END.
        DO ON ERROR UNDO, THROW:
            Bestiary:ForDepth(3, ?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            Bestiary:OfLetter("1").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            Bestiary:OfLetter("AB").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterHasAVerbAPhraseAndAnArticle():
        Assert:Equals("bites", Bestiary:Verb(MonsterKind:Bat)).
        Assert:Equals("kicks", Bestiary:Verb(MonsterKind:Emu)).
        Assert:Equals("the bat", Bestiary:Phrase(MonsterKind:Bat, FALSE)).
        Assert:Equals("The bat", Bestiary:Phrase(MonsterKind:Bat, TRUE)).
        Assert:Equals("a bat", Bestiary:WithArticle(MonsterKind:Bat)).
        Assert:Equals("an orc", Bestiary:WithArticle(MonsterKind:Orc)).
        Assert:Equals("an ice monster", Bestiary:WithArticle(MonsterKind:IceMonster)).
        Assert:Equals(26, NUM-ENTRIES("hits,bites,kicks,claws,kicks,grabs,claws,hits,touches,bites,pecks,hits,hits,touches,hits,hits,kicks,bites,bites,hits,claws,bites,hits,hits,claws,hits")).
    END METHOD.

END CLASS.
