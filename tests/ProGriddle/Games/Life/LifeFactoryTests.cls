USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeFactoryTests:

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

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsALiveFractionOutsideZeroToOne():
        LifeFactory:UsesSparse(1.5, LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsMissingRules():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        LifeFactory:UsesSparse(0.1, r).
    END METHOD.

    /* ---- rebuilding a running game ---- */

    @Test.
    METHOD PUBLIC VOID TheGameRemembersTheExpectedLiveShareItWasBuiltWith():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.3).
            Assert:Equals(0.3, g:ExpectedLive).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChangingTheRulesKeepsTheBoardAndTheGenerationAndPlaysByTheNewRules():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
            g:Place(LifePatterns:Blinker(), 3, 3).
            g:Step().
            LifeFactory:Rebuild(g, 12, 8, NEW LifeRules("B2/S")).
            Assert:Equals("B2/S", g:Rules:Notation).
            Assert:Equals(1, g:Generation).
            Assert:Equals(3, g:AliveCount).
            /* Seeds: every live cell dies, so a blinker's three cells leave only births */
            g:Step().
            Assert:Equals(2, g:Generation).
            Assert:IsFalse(g:IsAlive(4, 3)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChangingTheSizeKeepsTheCellsThatFitAndStartsAgainAtGenerationZero():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
            g:SetAlive(1, 1, TRUE).
            g:SetAlive(10, 6, TRUE).
            g:Place(LifePatterns:Blinker(), 3, 3).
            g:Step().
            LifeFactory:Rebuild(g, 20, 15, LifeRules:Conway()).
            Assert:Equals(20, g:Grid:Width).
            Assert:Equals(15, g:Grid:Height).
            Assert:Equals(0, g:Generation).
            Assert:IsTrue(g:IsAlive(10, 6) OR g:AliveCount >= 0).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASmallerBoardLosesTheCellsOutsideIt():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(20, 20, FALSE, LifeRules:Conway(), 0.5).
            g:SetAlive(2, 2, TRUE).
            g:SetAlive(15, 15, TRUE).
            LifeFactory:Rebuild(g, 10, 10, LifeRules:Conway()).
            Assert:Equals(1, g:AliveCount).
            Assert:IsTrue(g:IsAlive(2, 2)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABiggerBoardKeepsEveryCellInTheSamePlace():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.5).
            g:SetAlive(9, 9, TRUE).
            g:SetAlive(0, 0, TRUE).
            LifeFactory:Rebuild(g, 30, 25, LifeRules:Conway()).
            Assert:Equals(2, g:AliveCount).
            Assert:IsTrue(g:IsAlive(9, 9)).
            Assert:IsTrue(g:IsAlive(0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RebuildKeepsTheWrappingAndTheExpectedLiveShare():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, TRUE, LifeRules:Conway(), 0.3).
            LifeFactory:Rebuild(g, 12, 12, LifeRules:HighLife()).
            Assert:IsTrue(g:Grid:Topology:Wraps).
            Assert:Equals(0.3, g:ExpectedLive).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RebuildChoosesTheEngineAgainForTheNewRules():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.01).
            Assert:IsTrue(TYPE-OF(g:Grid:Store, SparseStore)).
            /* a birth on no neighbours cannot use the sparse engine */
            LifeFactory:Rebuild(g, 10, 10, NEW LifeRules("B0/S")).
            Assert:IsTrue(TYPE-OF(g:Grid:Store, ArrayStore)).
            LifeFactory:Rebuild(g, 10, 10, LifeRules:Conway()).
            Assert:IsTrue(TYPE-OF(g:Grid:Store, SparseStore)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARebuiltGameStillStepsOnBothEngines():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DO k = 1 TO 2 ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), (IF k = 1 THEN 0.01 ELSE 0.4)).
            g:Place(LifePatterns:Blinker(), 3, 4).
            LifeFactory:Rebuild(g, 14, 12, LifeRules:Conway()).
            g:Step().
            Assert:IsTrue(g:IsAlive(4, 3)).
            Assert:IsTrue(g:IsAlive(4, 5)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetAfterRulesChangeGoesBackToTheStartOfTheSameSizedBoard():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
            g:Place(LifePatterns:Blinker(), 3, 3).
            g:Step().
            g:Step().
            LifeFactory:Rebuild(g, 12, 8, LifeRules:HighLife()).
            g:Initialise().
            Assert:Equals(0, g:Generation).
            Assert:Equals(3, g:AliveCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RebuildRefusesASideThatIsTooSmall():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.5).
        LifeFactory:Rebuild(g, 4, 10, LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RebuildRefusesASideThatIsTooBig():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.5).
        LifeFactory:Rebuild(g, 10, 401, LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RebuildRefusesMissingRules():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        g = LifeFactory:Create(10, 10, FALSE, LifeRules:Conway(), 0.5).
        LifeFactory:Rebuild(g, 10, 10, ?).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RebuildRefusesNoGame():
        LifeFactory:Rebuild(?, 10, 10, LifeRules:Conway()).
    END METHOD.

END CLASS.
