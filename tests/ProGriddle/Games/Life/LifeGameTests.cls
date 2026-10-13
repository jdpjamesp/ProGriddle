/* The LifeGame API: editing cells, placing patterns, randomising, reset, validation.
   The Life rules themselves are in LifeEngineTests. Each test runs once per engine kind. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeGameTests:

    /* ---- identity ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameIsNamedLifeAndStartsEmptyAtGenerationZero():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 4, 4, FALSE, LifeRules:HighLife()).
            Assert:Equals("Life", g:Name).
            Assert:Equals(0, g:Generation).
            Assert:Equals(0, g:AliveCount).
            Assert:IsFalse(g:IsOver).
            Assert:Equals("B36/S23", g:Rules:Notation).
            Assert:Equals(4, g:Grid:Width).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- editing cells ---- */

    @Test.
    METHOD PUBLIC VOID SetAliveIsAliveAndAliveCountAgree():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 4, 4, FALSE, LifeRules:Conway()).
            g:SetAlive(1, 2, TRUE).
            g:SetAlive(3, 0, TRUE).
            Assert:IsTrue(g:IsAlive(1, 2)).
            Assert:IsTrue(g:IsAlive(3, 0)).
            Assert:IsFalse(g:IsAlive(0, 0)).
            Assert:Equals(2, g:AliveCount).
            g:SetAlive(1, 2, FALSE).
            Assert:IsFalse(g:IsAlive(1, 2)).
            Assert:Equals(1, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToggleCellFlipsOneCellEachTime():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 4, 4, FALSE, LifeRules:Conway()).
            g:ToggleCell(2, 2).
            Assert:IsTrue(g:IsAlive(2, 2)).
            Assert:Equals(1, g:AliveCount).
            g:ToggleCell(2, 2).
            Assert:IsFalse(g:IsAlive(2, 2)).
            Assert:Equals(0, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID SetAliveThrowsOffTheBoard():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
            g:SetAlive(4, 0, TRUE).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID IsAliveThrowsOffTheBoard():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(2, 4, 4, FALSE, LifeRules:Conway()).
            g:IsAlive(0, -1).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlaceMakesThePatternAliveAndKeepsOtherCells():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 6, 6, FALSE, LifeRules:Conway()).
            g:SetAlive(5, 5, TRUE).
            g:Place(LifePatterns:Glider(), 1, 1).
            Assert:Equals(6, g:AliveCount).
            Assert:IsTrue(g:IsAlive(2, 1)).
            Assert:IsTrue(g:IsAlive(3, 2)).
            Assert:IsTrue(g:IsAlive(1, 3)).
            Assert:IsTrue(g:IsAlive(2, 3)).
            Assert:IsTrue(g:IsAlive(3, 3)).
            Assert:IsTrue(g:IsAlive(5, 5)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlaceThatDoesNotFitThrowsAndChangesNothing():
        DEFINE VARIABLE k      AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g      AS LifeGame NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL  NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 4, 4, FALSE, LifeRules:Conway()).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                g:Place(LifePatterns:Glider(), 2, 2).
                CATCH ge AS ProGriddle.Core.GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            Assert:Equals(0, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearBoardKillsEveryCell():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 5, 5, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Block(), 1, 1).
            g:ClearBoard().
            Assert:Equals(0, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- randomise ---- */

    @Test.
    METHOD PUBLIC VOID RandomiseWithTheSameSeedGivesTheSameBoardOnEveryEngine():
        DEFINE VARIABLE dense  AS LifeGame NO-UNDO.
        DEFINE VARIABLE sparse AS LifeGame NO-UNDO.
        DEFINE VARIABLE again  AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            dense = LifeTestKit:Make(1, 20, 15, FALSE, LifeRules:Conway()).
            sparse = LifeTestKit:Make(2, 20, 15, FALSE, LifeRules:Conway()).
            again = LifeTestKit:Make(1, 20, 15, FALSE, LifeRules:Conway()).
            dense:Randomise(NEW SeededRandom(99), 0.3).
            sparse:Randomise(NEW SeededRandom(99), 0.3).
            again:Randomise(NEW SeededRandom(99), 0.3).
            Assert:Equals(LifeTestKit:Board(dense), LifeTestKit:Board(sparse)).
            Assert:Equals(LifeTestKit:Board(dense), LifeTestKit:Board(again)).
            FINALLY:
                IF VALID-OBJECT(again) THEN again:Dispose().
                IF VALID-OBJECT(sparse) THEN sparse:Dispose().
                IF VALID-OBJECT(dense) THEN dense:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomiseWithDifferentSeedsGivesDifferentBoards():
        DEFINE VARIABLE a AS LifeGame NO-UNDO.
        DEFINE VARIABLE b AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = LifeTestKit:Make(1, 20, 15, FALSE, LifeRules:Conway()).
            b = LifeTestKit:Make(1, 20, 15, FALSE, LifeRules:Conway()).
            a:Randomise(NEW SeededRandom(1), 0.3).
            b:Randomise(NEW SeededRandom(2), 0.3).
            Assert:IsTrue(LifeTestKit:Board(a) <> LifeTestKit:Board(b)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomiseFollowsTheDensityAndClearsWhatWasThere():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 20, 20, FALSE, LifeRules:Conway()).
            g:Randomise(NEW SeededRandom(5), 0).
            Assert:Equals(0, g:AliveCount).
            g:Randomise(NEW SeededRandom(5), 1).
            Assert:Equals(400, g:AliveCount).
            g:Randomise(NEW SeededRandom(5), 0.25).
            Assert:IsTrue(g:AliveCount > 60 AND g:AliveCount < 140).
            g:SetAlive(0, 0, TRUE).
            g:Randomise(NEW SeededRandom(5), 0).
            Assert:Equals(0, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RandomiseRejectsADensityAboveOne():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
            g:Randomise(NEW SeededRandom(1), 1.5).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RandomiseRejectsANegativeDensity():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
            g:Randomise(NEW SeededRandom(1), -0.1).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RandomiseNeedsARandomSource():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DEFINE VARIABLE r AS IRandom  NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
            g:Randomise(r, 0.5).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- reset ---- */

    @Test.
    METHOD PUBLIC VOID InitialiseReturnsToTheBoardAtTheFirstStep():
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE g      AS LifeGame  NO-UNDO.
        DEFINE VARIABLE before AS CHARACTER NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 10, 10, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Glider(), 1, 1).
            before = LifeTestKit:Board(g).
            g:Step().
            g:Step().
            g:Step().
            Assert:Equals(3, g:Generation).
            Assert:IsTrue(LifeTestKit:Board(g) <> before).
            g:Initialise().
            Assert:Equals(0, g:Generation).
            Assert:Equals(before, LifeTestKit:Board(g)).
            /* and it runs the same again */
            g:Step().
            g:Step().
            g:Step().
            g:Initialise().
            Assert:Equals(before, LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EditingAtGenerationZeroThenSteppingMakesTheEditTheNewStart():
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE g      AS LifeGame  NO-UNDO.
        DEFINE VARIABLE edited AS CHARACTER NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 8, 8, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Blinker(), 1, 1).
            g:Step().
            g:Initialise().
            g:ClearBoard().
            g:Place(LifePatterns:Block(), 3, 3).
            edited = LifeTestKit:Board(g).
            g:Step().
            g:Step().
            g:Initialise().
            Assert:Equals(edited, LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseWithNothingCapturedEmptiesTheBoard():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 5, 5, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Block(), 1, 1).
            g:Initialise().
            Assert:Equals(0, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CaptureStartSavesTheBoardForInitialise():
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE g      AS LifeGame  NO-UNDO.
        DEFINE VARIABLE saved  AS CHARACTER NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 6, 6, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Block(), 2, 2).
            g:CaptureStart().
            saved = LifeTestKit:Board(g).
            g:ClearBoard().
            g:Place(LifePatterns:Blinker(), 0, 0).
            g:Initialise().
            Assert:Equals(saved, LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- validation ---- */

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheGridMustHaveALayerCalledState():
        DEFINE VARIABLE grid AS Grid NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(4, 4, "cells")).
        NEW LifeGame(grid, LifeRules:Conway(), NEW DenseLifeEngine(grid, LifeRules:Conway())).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheGridMustHaveExactlyOneLayer():
        DEFINE VARIABLE grid AS Grid NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(4, 4, "state,extra")).
        NEW DenseLifeEngine(grid, LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheDenseEngineNeedsAnArrayStore():
        NEW DenseLifeEngine(NEW Grid(NEW SparseStore(4, 4, "state")), LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheSparseEngineNeedsASparseStore():
        NEW SparseLifeEngine(NEW Grid(NEW ArrayStore(4, 4, "state")), LifeRules:Conway()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ALifeGameNeedsRules():
        DEFINE VARIABLE grid  AS Grid NO-UNDO.
        DEFINE VARIABLE rules AS LifeRules NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(4, 4, "state")).
        NEW LifeGame(grid, rules, NEW DenseLifeEngine(grid, LifeRules:Conway())).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ALifeGameNeedsAnEngine():
        DEFINE VARIABLE engine AS ProGriddle.Games.Life.ILifeEngine NO-UNDO.
        NEW LifeGame(NEW Grid(NEW ArrayStore(4, 4, "state")), LifeRules:Conway(), engine).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeIsSafeToCallTwice():
        DEFINE VARIABLE k AS INTEGER  NO-UNDO.
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 4, 4, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Block(), 1, 1).
            g:Step().
            g:Dispose().
            g:Dispose().
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    /* ---- replacing the grid, the rules and the engine ---- */

    @Test.
    METHOD PUBLIC VOID TheExpectedLiveShareStartsAtTenPercentAndCanBeSet():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
            Assert:Equals(0.1, g:ExpectedLive).
            g:ExpectedLive = 0.5.
            Assert:Equals(0.5, g:ExpectedLive).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnExpectedLiveShareOverOneIsRefused():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        g = LifeTestKit:Make(1, 4, 4, FALSE, LifeRules:Conway()).
        g:ExpectedLive = 1.5.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceSwapsTheGridTheRulesAndTheEngineAndKeepsTheGeneration():
        DEFINE VARIABLE g      AS LifeGame NO-UNDO.
        DEFINE VARIABLE other  AS LifeGame NO-UNDO.
        DEFINE VARIABLE newGrid AS Grid    NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
            other = LifeTestKit:Make(1, 8, 5, FALSE, LifeRules:HighLife()).
            g:Place(LifePatterns:Blinker(), 1, 1).
            g:Step().
            newGrid = other:Grid.
            g:Replace(newGrid, LifeRules:HighLife(), NEW DenseLifeEngine(newGrid, LifeRules:HighLife()), TRUE).
            Assert:Equals(8, g:Grid:Width).
            Assert:Equals(5, g:Grid:Height).
            Assert:Equals("B36/S23", g:Rules:Notation).
            Assert:Equals(1, g:Generation).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceWithoutKeepingTheStartGoesBackToGenerationZeroAndResetClears():
        DEFINE VARIABLE g      AS LifeGame NO-UNDO.
        DEFINE VARIABLE other  AS LifeGame NO-UNDO.
        DEFINE VARIABLE newGrid AS Grid    NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
            other = LifeTestKit:Make(1, 9, 9, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Blinker(), 1, 1).
            g:Step().
            newGrid = other:Grid.
            newGrid:Store:SetCell(1, 4, 4, 1).
            g:Replace(newGrid, LifeRules:Conway(), NEW DenseLifeEngine(newGrid, LifeRules:Conway()), FALSE).
            Assert:Equals(0, g:Generation).
            Assert:IsTrue(g:IsAlive(4, 4)).
            g:Initialise().
            Assert:Equals(0, g:AliveCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceKeepingTheStartLetsResetReturnToIt():
        DEFINE VARIABLE g      AS LifeGame NO-UNDO.
        DEFINE VARIABLE other  AS LifeGame NO-UNDO.
        DEFINE VARIABLE newGrid AS Grid    NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
            other = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Blinker(), 1, 2).
            g:Step().
            newGrid = other:Grid.
            g:Replace(newGrid, LifeRules:Conway(), NEW DenseLifeEngine(newGrid, LifeRules:Conway()), TRUE).
            g:Initialise().
            Assert:Equals(3, g:AliveCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ReplaceRefusesAGridWithoutTheStateLayer():
        DEFINE VARIABLE g      AS LifeGame NO-UNDO.
        DEFINE VARIABLE bad    AS Grid     NO-UNDO.
        g = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
        bad = NEW Grid(NEW ArrayStore(6, 6, "other"), NEW BoundedTopology(), NEW MooreNeighbourhood()).
        g:Replace(bad, LifeRules:Conway(), NEW DenseLifeEngine(bad, LifeRules:Conway()), TRUE).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ReplaceRefusesMissingParts():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        g = LifeTestKit:Make(1, 6, 6, FALSE, LifeRules:Conway()).
        g:Replace(?, LifeRules:Conway(), ?, TRUE).
    END METHOD.

END CLASS.
