USING OpenEdge.Core.Assert.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.SparseStore.
USING Prolif.Games.Life.LifeFactory.
USING Prolif.Games.Life.LifeGame.
USING Prolif.Games.Life.LifePatterns.
USING Prolif.Games.Life.LifeRules.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheSwitchOverIsFivePercent():
        Assert:Equals(0.05, LifeFactory:SparseBelow()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UsesSparseBelowFivePercentAndDenseFromThere():
        Assert:IsTrue(LifeFactory:UsesSparse(0, LifeRules:Conway())).
        Assert:IsTrue(LifeFactory:UsesSparse(0.049, LifeRules:Conway())).
        Assert:IsFalse(LifeFactory:UsesSparse(0.05, LifeRules:Conway())).
        Assert:IsFalse(LifeFactory:UsesSparse(0.3, LifeRules:Conway())).
        Assert:IsFalse(LifeFactory:UsesSparse(1, LifeRules:Conway())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RulesWithABirthOnZeroAlwaysUseTheDenseEngine():
        Assert:IsFalse(LifeFactory:UsesSparse(0, NEW LifeRules("B0/S"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASparseChoiceBuildsASparseStoreAndADenseChoiceAnArrayStore():
        DEFINE VARIABLE a AS LifeGame NO-UNDO.
        DEFINE VARIABLE b AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = LifeFactory:Create(20, 10, FALSE, LifeRules:Conway(), 0.01).
            b = LifeFactory:Create(20, 10, FALSE, LifeRules:Conway(), 0.4).
            Assert:IsTrue(TYPE-OF(a:Grid:Store, SparseStore)).
            Assert:IsTrue(TYPE-OF(b:Grid:Store, ArrayStore)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameItBuildsRunsLife():
        DEFINE VARIABLE a AS LifeGame NO-UNDO.
        DEFINE VARIABLE b AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.01).
            b = LifeFactory:Create(10, 10, TRUE, LifeRules:HighLife(), 0.5).
            a:Place(LifePatterns:Blinker(), 3, 4).
            a:Step().
            Assert:IsTrue(a:IsAlive(4, 3)).
            Assert:IsTrue(a:IsAlive(4, 5)).
            Assert:IsFalse(b:Grid:Topology:Wraps = FALSE).
            Assert:Equals("B36/S23", b:Rules:Notation).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID RejectsALiveFractionOutsideZeroToOne():
        LifeFactory:UsesSparse(1.5, LifeRules:Conway()).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID RejectsMissingRules():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        LifeFactory:UsesSparse(0.1, r).
    END METHOD.

END CLASS.
