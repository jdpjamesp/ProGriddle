/* The table of scrolls: the count, the chances, the names and the worths, and a pick by chance. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ScrollsTests:

    @Test.
    METHOD PUBLIC VOID ThereAre14KindsAndTheChancesAddUpToOneHundred():
        Assert:Equals(14, Scrolls:Count()).
        Assert:Equals(100, WeightedPick:Total(Scrolls:Chances())).
        Assert:Equals(14, NUM-ENTRIES(Scrolls:Chances())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindHasANameAChanceAndAWorth():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 0 TO Scrolls:Count() - 1:
            Assert:IsTrue(LENGTH(Scrolls:NameOf(ScrollKind:GetEnum(i))) > 2).
            Assert:IsTrue(Scrolls:Chance(ScrollKind:GetEnum(i)) > 0).
            Assert:IsTrue(Scrolls:Worth(ScrollKind:GetEnum(i)) > 0).
            DO j = i + 1 TO Scrolls:Count() - 1:
                Assert:IsTrue(Scrolls:NameOf(ScrollKind:GetEnum(i)) <> Scrolls:NameOf(ScrollKind:GetEnum(j))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstAndLastKindsAreWhereTheEnumSaysTheyAre():
        Assert:Equals("identify", Scrolls:NameOf(ScrollKind:GetEnum(0))).
        Assert:Equals("protect armor", Scrolls:NameOf(ScrollKind:GetEnum(13))).
        Assert:Equals(30, Scrolls:Chance(ScrollKind:GetEnum(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickFollowsTheChances():
        Assert:Equals(0, INTEGER(Scrolls:Roll(NEW ScriptedRandom("0")))).
        Assert:Equals(13, INTEGER(Scrolls:Roll(NEW ScriptedRandom("99")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManyPicksTurnUpEveryKind():
        DEFINE VARIABLE oRandom AS SeededRandom NO-UNDO.
        DEFINE VARIABLE counts  AS INTEGER      NO-UNDO EXTENT 14.
        DEFINE VARIABLE i       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER      NO-UNDO.
        oRandom = NEW SeededRandom(7).
        DO i = 1 TO 4000:
            k = INTEGER(Scrolls:Roll(oRandom)) + 1.
            counts[k] = counts[k] + 1.
        END.
        DO i = 1 TO 14:
            Assert:IsTrue(counts[i] > 0).
        END.
    END METHOD.

END CLASS.
