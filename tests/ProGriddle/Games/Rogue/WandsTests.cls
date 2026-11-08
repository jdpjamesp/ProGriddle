/* The table of wands: the count, the chances, the names and the worths, and a pick by chance. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.WandsTests:

    @Test.
    METHOD PUBLIC VOID ThereAre14KindsAndTheChancesAddUpToOneHundred():
        Assert:Equals(14, Wands:Count()).
        Assert:Equals(100, WeightedPick:Total(Wands:Chances())).
        Assert:Equals(14, NUM-ENTRIES(Wands:Chances())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindHasANameAChanceAndAWorth():
        VAR INTEGER i.
        VAR INTEGER j.
        DO i = 0 TO Wands:Count() - 1:
            Assert:IsTrue(LENGTH(Wands:NameOf(WandKind:GetEnum(i))) > 2).
            Assert:IsTrue(Wands:Chance(WandKind:GetEnum(i)) > 0).
            Assert:IsTrue(Wands:Worth(WandKind:GetEnum(i)) > 0).
            DO j = i + 1 TO Wands:Count() - 1:
                Assert:IsTrue(Wands:NameOf(WandKind:GetEnum(i)) <> Wands:NameOf(WandKind:GetEnum(j))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstAndLastKindsAreWhereTheEnumSaysTheyAre():
        Assert:Equals("light", Wands:NameOf(WandKind:GetEnum(0))).
        Assert:Equals("cancellation", Wands:NameOf(WandKind:GetEnum(13))).
        Assert:Equals(12, Wands:Chance(WandKind:GetEnum(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickFollowsTheChances():
        Assert:Equals(0, INTEGER(Wands:Roll(NEW ScriptedRandom("0")))).
        Assert:Equals(13, INTEGER(Wands:Roll(NEW ScriptedRandom("99")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManyPicksTurnUpEveryKind():
        VAR SeededRandom oRandom.
        VAR INTEGER[14] counts.
        VAR INTEGER i.
        VAR INTEGER k.
        oRandom = NEW SeededRandom(7).
        DO i = 1 TO 4000:
            k = INTEGER(Wands:Roll(oRandom)) + 1.
            counts[k] = counts[k] + 1.
        END.
        DO i = 1 TO 14:
            Assert:IsTrue(counts[i] > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyFiveWandsHurtAndTheyHaveFewerCharges():
        Assert:IsTrue(Wands:Hurts(WandKind:Lightning)).
        Assert:IsTrue(Wands:Hurts(WandKind:Fire)).
        Assert:IsTrue(Wands:Hurts(WandKind:Cold)).
        Assert:IsTrue(Wands:Hurts(WandKind:MagicMissile)).
        Assert:IsTrue(Wands:Hurts(WandKind:DrainLife)).
        Assert:IsFalse(Wands:Hurts(WandKind:Light)).
        Assert:IsFalse(Wands:Hurts(WandKind:Polymorph)).
        Assert:Equals(3, Wands:StartingCharges(WandKind:Fire, NEW ScriptedRandom("0"))).
        Assert:Equals(7, Wands:StartingCharges(WandKind:Fire, NEW ScriptedRandom("4"))).
        Assert:Equals(10, Wands:StartingCharges(WandKind:Light, NEW ScriptedRandom("0"))).
        Assert:Equals(19, Wands:StartingCharges(WandKind:Light, NEW ScriptedRandom("9"))).
    END METHOD.

END CLASS.
