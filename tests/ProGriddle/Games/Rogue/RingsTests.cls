/* The table of rings: the count, the chances, the names and the worths, and a pick by chance. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RingsTests:

    @Test.
    METHOD PUBLIC VOID ThereAre14KindsAndTheChancesAddUpToOneHundred():
        Assert:Equals(14, Rings:Count()).
        Assert:Equals(100, WeightedPick:Total(Rings:Chances())).
        Assert:Equals(14, NUM-ENTRIES(Rings:Chances())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindHasANameAChanceAndAWorth():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 0 TO Rings:Count() - 1:
            Assert:IsTrue(LENGTH(Rings:NameOf(RingKind:GetEnum(i))) > 2).
            Assert:IsTrue(Rings:Chance(RingKind:GetEnum(i)) > 0).
            Assert:IsTrue(Rings:Worth(RingKind:GetEnum(i)) > 0).
            DO j = i + 1 TO Rings:Count() - 1:
                Assert:IsTrue(Rings:NameOf(RingKind:GetEnum(i)) <> Rings:NameOf(RingKind:GetEnum(j))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstAndLastKindsAreWhereTheEnumSaysTheyAre():
        Assert:Equals("protection", Rings:NameOf(RingKind:GetEnum(0))).
        Assert:Equals("maintain armor", Rings:NameOf(RingKind:GetEnum(13))).
        Assert:Equals(9, Rings:Chance(RingKind:GetEnum(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickFollowsTheChances():
        Assert:Equals(0, INTEGER(Rings:Roll(NEW ScriptedRandom("0")))).
        Assert:Equals(13, INTEGER(Rings:Roll(NEW ScriptedRandom("99")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManyPicksTurnUpEveryKind():
        DEFINE VARIABLE oRandom AS SeededRandom NO-UNDO.
        DEFINE VARIABLE counts  AS INTEGER      NO-UNDO EXTENT 14.
        DEFINE VARIABLE i       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER      NO-UNDO.
        oRandom = NEW SeededRandom(7).
        DO i = 1 TO 4000:
            k = INTEGER(Rings:Roll(oRandom)) + 1.
            counts[k] = counts[k] + 1.
        END.
        DO i = 1 TO 14:
            Assert:IsTrue(counts[i] > 0).
        END.
    END METHOD.

END CLASS.
