/* The Life rules proved against both engines. Every test runs once per engine kind (dense
   and sparse) and the engines are also compared with each other and with a slow, obvious
   reference. A failure names the engine. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeEngineTests:

    VAR PRIVATE CHARACTER LF.

    CONSTRUCTOR PUBLIC LifeEngineTests():
        LF = CHR(10).
    END CONSTRUCTOR.

    /* Steps the game piSteps times. */
    METHOD PRIVATE VOID StepTimes(INPUT poGame AS LifeGame, INPUT piSteps AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piSteps:
            poGame:Step().
        END.
    END METHOD.

    /* ---- basic rules ---- */

    @Test.
    METHOD PUBLIC VOID AnEmptyBoardStaysEmpty():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 6, 5, FALSE, LifeRules:Conway()).
            StepTimes(g, 5).
            Assert:Equals(0, g:AliveCount).
            Assert:Equals(5, g:Generation).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASingleCellDies():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 5, 5, FALSE, LifeRules:Conway()).
            g:SetAlive(2, 2, TRUE).
            g:Step().
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
    METHOD PUBLIC VOID ABlockIsAStillLife():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR CHARACTER before.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 6, 6, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Block(), 2, 2).
            before = LifeTestKit:Board(g).
            StepTimes(g, 6).
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
    METHOD PUBLIC VOID ABeehiveIsAStillLife():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR CHARACTER before.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 8, 7, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Beehive(), 2, 2).
            before = LifeTestKit:Board(g).
            StepTimes(g, 4).
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
    METHOD PUBLIC VOID ABlinkerOscillatesWithPeriodTwo():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 5, 5, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Blinker(), 1, 2).
            Assert:Equals("....." + LF + "....." + LF + ".###." + LF + "....." + LF + ".....", LifeTestKit:Board(g)).
            g:Step().
            Assert:Equals("....." + LF + "..#.." + LF + "..#.." + LF + "..#.." + LF + ".....", LifeTestKit:Board(g)).
            g:Step().
            Assert:Equals("....." + LF + "....." + LF + ".###." + LF + "....." + LF + ".....", LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AToadAndABeaconHavePeriodTwo():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR CHARACTER start.
        VAR CHARACTER middle.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 8, 8, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Toad(), 1, 1).
            start = LifeTestKit:Board(g).
            g:Step().
            middle = LifeTestKit:Board(g).
            Assert:IsTrue(middle <> start).
            g:Step().
            Assert:Equals(start, LifeTestKit:Board(g)).
            g:Dispose().

            g = LifeTestKit:Make(k, 8, 8, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Beacon(), 2, 2).
            start = LifeTestKit:Board(g).
            g:Step().
            Assert:IsTrue(LifeTestKit:Board(g) <> start).
            g:Step().
            Assert:Equals(start, LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- gliders ---- */

    @Test.
    METHOD PUBLIC VOID AGliderMovesOneCellDiagonallyEveryFourGenerations():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR LifeGame expected.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 12, 12, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Glider(), 1, 1).
            StepTimes(g, 4).
            expected = LifeTestKit:Make(k, 12, 12, FALSE, LifeRules:Conway()).
            expected:Place(LifePatterns:Glider(), 2, 2).
            Assert:Equals(LifeTestKit:Board(expected), LifeTestKit:Board(g)).
            StepTimes(g, 8).
            expected:Dispose().
            expected = LifeTestKit:Make(k, 12, 12, FALSE, LifeRules:Conway()).
            expected:Place(LifePatterns:Glider(), 4, 4).
            Assert:Equals(LifeTestKit:Board(expected), LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(expected) THEN expected:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGliderOnATorusComesBackToItsStartAfterFourTimesTheWidth():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR CHARACTER start.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 8, 8, TRUE, LifeRules:Conway()).
            g:Place(LifePatterns:Glider(), 1, 1).
            start = LifeTestKit:Board(g).
            StepTimes(g, 31).
            Assert:IsTrue(LifeTestKit:Board(g) <> start).
            g:Step().
            Assert:Equals(start, LifeTestKit:Board(g)).
            Assert:Equals(32, g:Generation).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGliderCrossesTheEdgeOfATorusButNotOfABoundedBoard():
        VAR INTEGER k.
        VAR LifeGame t.
        VAR LifeGame b.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            t = LifeTestKit:Make(k, 10, 10, TRUE, LifeRules:Conway()).
            b = LifeTestKit:Make(k, 10, 10, FALSE, LifeRules:Conway()).
            t:Place(LifePatterns:Glider(), 6, 6).
            b:Place(LifePatterns:Glider(), 6, 6).
            StepTimes(t, 60).
            StepTimes(b, 60).
            /* the torus still has a glider (5 cells), the bounded board ends as a block */
            Assert:Equals(5, t:AliveCount).
            Assert:Equals(4, b:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(t) THEN t:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALightweightSpaceshipTravelsTwoCellsEveryFourGenerations():
        VAR INTEGER k.
        VAR LifeGame g.
        VAR LifeGame expected.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 24, 8, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:LightweightSpaceship(), 1, 2).
            StepTimes(g, 8).
            expected = LifeTestKit:Make(k, 24, 8, FALSE, LifeRules:Conway()).
            expected:Place(LifePatterns:LightweightSpaceship(), 5, 2).
            Assert:Equals(LifeTestKit:Board(expected), LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(expected) THEN expected:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the update is simultaneous ---- */

    @Test.
    METHOD PUBLIC VOID EveryGenerationMatchesTheSlowReferenceOnRandomBoards():
        VAR INTEGER k.
        VAR INTEGER wrap.
        VAR INTEGER seed.
        VAR INTEGER gen.
        VAR LifeGame g.
        VAR CHARACTER want.
        DO k = 1 TO LifeTestKit:KindCount():
            DO wrap = 0 TO 1:
                DO seed = 1 TO 4:
                    DO ON ERROR UNDO, THROW:
                        g = LifeTestKit:Make(k, 13, 9, wrap = 1, (IF seed MODULO 2 = 0 THEN LifeRules:HighLife() ELSE LifeRules:Conway())).
                        g:Randomise(NEW SeededRandom(seed * 101), 0.2 + seed * 0.1).
                        DO gen = 1 TO 8:
                            want = LifeTestKit:Reference(g).
                            g:Step().
                            IF LifeTestKit:Board(g) <> want THEN
                                UNDO, THROW NEW AppError(SUBSTITUTE("[&1] wrap &2 seed &3 generation &4 differs from the reference",
                                    LifeTestKit:KindName(k), wrap, seed, gen), 0).
                        END.
                        FINALLY:
                            IF VALID-OBJECT(g) THEN g:Dispose().
                        END FINALLY.
                    END.
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TinyBoardsMatchTheSlowReference():
        VAR INTEGER[7] ws = [1, 1, 5, 2, 2, 3, 2].
        VAR INTEGER[7] hs = [1, 5, 1, 2, 3, 2, 2].
        VAR INTEGER k.
        VAR INTEGER s.
        VAR INTEGER wrap.
        VAR INTEGER gen.
        VAR LifeGame g.
        VAR CHARACTER want.
        DO k = 1 TO LifeTestKit:KindCount():
            DO s = 1 TO 7:
                DO wrap = 0 TO 1:
                    DO ON ERROR UNDO, THROW:
                        g = LifeTestKit:Make(k, ws[s], hs[s], wrap = 1, LifeRules:Conway()).
                        g:Randomise(NEW SeededRandom(s * 7 + wrap), 0.6).
                        DO gen = 1 TO 6:
                            want = LifeTestKit:Reference(g).
                            g:Step().
                            IF LifeTestKit:Board(g) <> want THEN
                                UNDO, THROW NEW AppError(SUBSTITUTE("[&1] &2 x &3 wrap &4 generation &5 differs from the reference",
                                    LifeTestKit:KindName(k), ws[s], hs[s], wrap, gen), 0).
                        END.
                        FINALLY:
                            IF VALID-OBJECT(g) THEN g:Dispose().
                        END FINALLY.
                    END.
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTwoEnginesGiveIdenticalGenerations():
        VAR LifeGame dense.
        VAR LifeGame sparse.
        VAR INTEGER wrap.
        VAR INTEGER seed.
        VAR INTEGER gen.
        DO wrap = 0 TO 1:
            DO seed = 1 TO 3:
                DO ON ERROR UNDO, THROW:
                    dense = LifeTestKit:Make(1, 24, 17, wrap = 1, LifeRules:Conway()).
                    sparse = LifeTestKit:Make(2, 24, 17, wrap = 1, LifeRules:Conway()).
                    dense:Randomise(NEW SeededRandom(seed), 0.1 * seed + 0.1).
                    sparse:Randomise(NEW SeededRandom(seed), 0.1 * seed + 0.1).
                    Assert:Equals(LifeTestKit:Board(dense), LifeTestKit:Board(sparse)).
                    DO gen = 1 TO 25:
                        dense:Step().
                        sparse:Step().
                        IF LifeTestKit:Board(dense) <> LifeTestKit:Board(sparse) THEN
                            UNDO, THROW NEW AppError(SUBSTITUTE("wrap &1 seed &2: engines differ at generation &3", wrap, seed, gen), 0).
                        Assert:Equals(dense:AliveCount, sparse:AliveCount).
                    END.
                    FINALLY:
                        IF VALID-OBJECT(sparse) THEN sparse:Dispose().
                        IF VALID-OBJECT(dense) THEN dense:Dispose().
                    END FINALLY.
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRPentominoRunsTheSameOnBothEnginesForAHundredGenerations():
        VAR LifeGame dense.
        VAR LifeGame sparse.
        DO ON ERROR UNDO, THROW:
            dense = LifeTestKit:Make(1, 60, 60, FALSE, LifeRules:Conway()).
            sparse = LifeTestKit:Make(2, 60, 60, FALSE, LifeRules:Conway()).
            dense:Place(LifePatterns:RPentomino(), 28, 28).
            sparse:Place(LifePatterns:RPentomino(), 28, 28).
            StepTimes(dense, 100).
            StepTimes(sparse, 100).
            Assert:Equals(LifeTestKit:Board(dense), LifeTestKit:Board(sparse)).
            Assert:IsTrue(dense:AliveCount > 5).
            FINALLY:
                IF VALID-OBJECT(sparse) THEN sparse:Dispose().
                IF VALID-OBJECT(dense) THEN dense:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- other rule sets ---- */

    @Test.
    METHOD PUBLIC VOID HighLifeGivesBirthOnSixNeighboursButConwayDoesNot():
        VAR INTEGER k.
        VAR LifeGame conway.
        VAR LifeGame high.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            /* the centre cell is dead and has exactly six live neighbours */
            conway = LifeTestKit:Make(k, 3, 3, FALSE, LifeRules:Conway()).
            high = LifeTestKit:Make(k, 3, 3, FALSE, LifeRules:HighLife()).
            conway:Place(Shape:Parse("XXX/X.X/.X."), 0, 0).
            high:Place(Shape:Parse("XXX/X.X/.X."), 0, 0).
            Assert:Equals(6, conway:AliveCount).
            conway:Step().
            high:Step().
            Assert:IsFalse(conway:IsAlive(1, 1)).
            Assert:IsTrue(high:IsAlive(1, 1)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(high) THEN high:Dispose().
                IF VALID-OBJECT(conway) THEN conway:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SwappingTheRulesChangesHowAPatternEvolves():
        VAR INTEGER k.
        VAR LifeGame conway.
        VAR LifeGame high.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            conway = LifeTestKit:Make(k, 40, 40, FALSE, LifeRules:Conway()).
            high = LifeTestKit:Make(k, 40, 40, FALSE, LifeRules:HighLife()).
            conway:Place(LifePatterns:RPentomino(), 19, 19).
            high:Place(LifePatterns:RPentomino(), 19, 19).
            StepTimes(conway, 30).
            StepTimes(high, 30).
            Assert:IsTrue(LifeTestKit:Board(conway) <> LifeTestKit:Board(high)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(high) THEN high:Dispose().
                IF VALID-OBJECT(conway) THEN conway:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RulesWithSurvivalOnZeroKeepAnIsolatedCellAlive():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 5, 5, FALSE, NEW LifeRules("B3/S023")).
            g:SetAlive(2, 2, TRUE).
            StepTimes(g, 3).
            Assert:IsTrue(g:IsAlive(2, 2)).
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
    METHOD PUBLIC VOID TheDenseEngineRunsRulesThatGiveBirthOnZeroNeighbours():
        VAR LifeGame g.
        DO ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(1, 3, 3, FALSE, NEW LifeRules("B0/S")).
            g:Step().
            Assert:Equals(9, g:AliveCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheSparseEngineRefusesRulesThatGiveBirthOnZeroNeighbours():
        LifeTestKit:Make(2, 3, 3, FALSE, NEW LifeRules("B0/S")).
    END METHOD.

    /* ---- shape of the board ---- */

    @Test.
    METHOD PUBLIC VOID ANonSquareBoardWorks():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 9, 3, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:Blinker(), 3, 1).
            g:Step().
            Assert:Equals("....#...." + LF + "....#...." + LF + "....#....", LifeTestKit:Board(g)).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGosperGunFiresAGliderEveryThirtyGenerations():
        VAR INTEGER k.
        VAR LifeGame g.
        DO k = 1 TO LifeTestKit:KindCount() ON ERROR UNDO, THROW:
            g = LifeTestKit:Make(k, 60, 30, FALSE, LifeRules:Conway()).
            g:Place(LifePatterns:GosperGliderGun(), 1, 1).
            Assert:Equals(36, g:AliveCount).
            StepTimes(g, 30).
            /* the gun is back in its starting phase plus one glider (5 cells) */
            Assert:Equals(41, g:AliveCount).
            CATCH e AS Progress.Lang.Error:
                LifeTestKit:Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
