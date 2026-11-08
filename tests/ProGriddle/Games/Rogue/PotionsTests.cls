/* The table of potions: the count, the chances, the names and the worths, and a pick by chance. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.PotionsTests:

    @Test.
    METHOD PUBLIC VOID ThereAre14KindsAndTheChancesAddUpToOneHundred():
        Assert:Equals(14, Potions:Count()).
        Assert:Equals(100, WeightedPick:Total(Potions:Chances())).
        Assert:Equals(14, NUM-ENTRIES(Potions:Chances())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindHasANameAChanceAndAWorth():
        VAR INTEGER i.
        VAR INTEGER j.
        DO i = 0 TO Potions:Count() - 1:
            Assert:IsTrue(LENGTH(Potions:NameOf(PotionKind:GetEnum(i))) > 2).
            Assert:IsTrue(Potions:Chance(PotionKind:GetEnum(i)) > 0).
            Assert:IsTrue(Potions:Worth(PotionKind:GetEnum(i)) > 0).
            DO j = i + 1 TO Potions:Count() - 1:
                Assert:IsTrue(Potions:NameOf(PotionKind:GetEnum(i)) <> Potions:NameOf(PotionKind:GetEnum(j))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstAndLastKindsAreWhereTheEnumSaysTheyAre():
        Assert:Equals("confusion", Potions:NameOf(PotionKind:GetEnum(0))).
        Assert:Equals("levitation", Potions:NameOf(PotionKind:GetEnum(13))).
        Assert:Equals(7, Potions:Chance(PotionKind:GetEnum(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickFollowsTheChances():
        Assert:Equals(0, INTEGER(Potions:Roll(NEW ScriptedRandom("0")))).
        Assert:Equals(13, INTEGER(Potions:Roll(NEW ScriptedRandom("99")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManyPicksTurnUpEveryKind():
        VAR SeededRandom oRandom.
        VAR INTEGER[14] counts.
        VAR INTEGER i.
        VAR INTEGER k.
        oRandom = NEW SeededRandom(7).
        DO i = 1 TO 4000:
            k = INTEGER(Potions:Roll(oRandom)) + 1.
            counts[k] = counts[k] + 1.
        END.
        DO i = 1 TO 14:
            Assert:IsTrue(counts[i] > 0).
        END.
    END METHOD.

END CLASS.
