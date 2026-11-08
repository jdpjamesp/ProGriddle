USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.GridNeighbourTests:

    /* ---- helpers ---- */

    /* piTopology: 1 bounded, 2 toroidal. piNeighbourhood: 1 Moore, 2 Von Neumann, 3 a custom
       ring with a reach of 2. */
    METHOD PRIVATE Grid MakeGrid(INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piTopology AS INTEGER, INPUT piNeighbourhood AS INTEGER):
        VAR ITopology topo.
        VAR INeighbourhood nbh.
        VAR INTEGER[12] xs = [2, -2, 0, 0, 2, 2, -2, -2, 1, 1, -1, -1].
        VAR INTEGER[12] ys = [0, 0, 2, -2, 1, -1, 1, -1, 2, -2, 2, -2].
        topo = (IF piTopology = 1 THEN CAST(NEW BoundedTopology(), ITopology) ELSE CAST(NEW ToroidalTopology(), ITopology)).
        CASE piNeighbourhood:
            WHEN 1 THEN nbh = NEW MooreNeighbourhood().
            WHEN 2 THEN nbh = NEW VonNeumannNeighbourhood().
            OTHERWISE nbh = NEW CustomNeighbourhood(xs, ys).
        END CASE.
        RETURN NEW Grid(NEW ArrayStore(piW, piH, "s"), topo, nbh).
    END METHOD.

    /* The neighbour indexes the grid reports for a cell, comma separated, in its order. */
    METHOD PRIVATE CHARACTER NeighboursOf(INPUT poGrid AS Grid, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER[24] a.
        VAR INTEGER n.
        VAR INTEGER i.
        VAR CHARACTER result.
        n = poGrid:GetNeighbourIndexes(piX, piY, a).
        DO i = 1 TO n:
            result = result + (IF i > 1 THEN "," ELSE "") + STRING(a[i]).
        END.
        RETURN result.
    END METHOD.

    /* An independent, deliberately simple version of the same rule: resolve every offset
       through the topology, drop missing cells, the cell itself and repeats. */
    METHOD PRIVATE CHARACTER ExpectedNeighbours(INPUT poGrid AS Grid, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER r.
        VAR INTEGER idx.
        VAR CHARACTER result.
        idx = piY * poGrid:Width + piX.
        DO i = 1 TO poGrid:Neighbourhood:OffsetCount:
            r = poGrid:Resolve(piX + poGrid:Neighbourhood:OffsetX(i), piY + poGrid:Neighbourhood:OffsetY(i)).
            IF r = ? THEN NEXT.
            IF r = idx THEN NEXT.
            IF LOOKUP(STRING(r), result) > 0 THEN NEXT.
            result = result + (IF result = "" THEN "" ELSE ",") + STRING(r).
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE INTEGER CountOf(INPUT pcList AS CHARACTER):
        IF pcList = "" THEN RETURN 0.
        RETURN NUM-ENTRIES(pcList).
    END METHOD.

    /* ---- bounded boards ---- */

    @Test.
    METHOD PUBLIC VOID BoundedMooreCornerHasThreeEdgeHasFiveInteriorHasEight():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            Assert:Equals("1,3,4", NeighboursOf(g, 0, 0)).
            Assert:Equals("4,5,7", NeighboursOf(g, 2, 2)).
            Assert:Equals(5, CountOf(NeighboursOf(g, 1, 0))).
            Assert:Equals(5, CountOf(NeighboursOf(g, 0, 1))).
            Assert:Equals("0,1,2,3,5,6,7,8", NeighboursOf(g, 1, 1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedVonNeumannCornerHasTwoInteriorHasFour():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 2).
            Assert:Equals("1,3", NeighboursOf(g, 0, 0)).
            Assert:Equals("1,3,5,7", NeighboursOf(g, 1, 1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedNeighboursFollowTheOffsetOrderOnANonSquareBoard():
        /* 3 wide, 5 high, cell (1, 2) has index 7 */
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 5, 1, 1).
            Assert:Equals("3,4,5,6,8,9,10,11", NeighboursOf(g, 1, 2)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedTinyBoards():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(1, 1, 1, 1).
            Assert:Equals("", NeighboursOf(g, 0, 0)).
            g:Dispose().
            g = MakeGrid(2, 2, 1, 1).
            Assert:Equals("1,2,3", NeighboursOf(g, 0, 0)).
            Assert:Equals(3, CountOf(NeighboursOf(g, 1, 1))).
            g:Dispose().
            g = MakeGrid(1, 5, 1, 1).
            Assert:Equals("1,3", NeighboursOf(g, 0, 2)).
            Assert:Equals("1", NeighboursOf(g, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- toroidal boards ---- */

    @Test.
    METHOD PUBLIC VOID ToroidalMooreCornerHasEightNeighboursThatWrapAround():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(5, 5, 2, 1).
            Assert:Equals("24,20,21,4,1,9,5,6", NeighboursOf(g, 0, 0)).
            Assert:Equals(8, CountOf(NeighboursOf(g, 4, 4))).
            Assert:Equals(8, CountOf(NeighboursOf(g, 2, 0))).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalVonNeumannCornerHasFourNeighbours():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(5, 5, 2, 2).
            Assert:Equals("20,4,1,5", NeighboursOf(g, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* Each distinct neighbouring cell counts once, and a cell is never its own neighbour. */

    @Test.
    METHOD PUBLIC VOID ToroidalOneByOneHasNoNeighbours():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(1, 1, 2, 1).
            Assert:Equals("", NeighboursOf(g, 0, 0)).
            g:Dispose().
            g = MakeGrid(1, 1, 2, 2).
            Assert:Equals("", NeighboursOf(g, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalTwoByTwoGivesEveryCellThreeMooreNeighboursOnce():
        VAR Grid g.
        VAR INTEGER x.
        VAR INTEGER y.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(2, 2, 2, 1).
            DO y = 0 TO 1:
                DO x = 0 TO 1:
                    Assert:Equals(3, CountOf(NeighboursOf(g, x, y))).
                END.
            END.
            Assert:Equals("3,2,1", NeighboursOf(g, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalTwoByTwoGivesEveryCellTwoVonNeumannNeighbours():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(2, 2, 2, 2).
            Assert:Equals("2,1", NeighboursOf(g, 0, 0)).
            Assert:Equals(2, CountOf(NeighboursOf(g, 1, 1))).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalSingleColumnAndSingleRowCountAboveAndBelowOnce():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(1, 5, 2, 1).
            Assert:Equals("1,3", NeighboursOf(g, 0, 2)).
            Assert:Equals("4,1", NeighboursOf(g, 0, 0)).
            g:Dispose().
            g = MakeGrid(5, 1, 2, 1).
            Assert:Equals("1,3", NeighboursOf(g, 2, 0)).
            g:Dispose().
            g = MakeGrid(1, 2, 2, 1).
            Assert:Equals("1", NeighboursOf(g, 0, 0)).
            Assert:Equals("0", NeighboursOf(g, 0, 1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalTwoByThreeCountsTheOtherColumnAndTheCellsAboveAndBelow():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(2, 3, 2, 1).
            Assert:Equals(5, CountOf(NeighboursOf(g, 0, 0))).
            Assert:Equals(5, CountOf(NeighboursOf(g, 1, 2))).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalThreeByThreeStillHasEightDistinctNeighbours():
        VAR Grid g.
        VAR INTEGER x.
        VAR INTEGER y.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 2, 1).
            DO y = 0 TO 2:
                DO x = 0 TO 2:
                    Assert:Equals(8, CountOf(NeighboursOf(g, x, y))).
                END.
            END.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the array contract ---- */

    @Test.
    METHOD PUBLIC VOID ReturnsTheCountAndLeavesLaterElementsAlone():
        VAR Grid g.
        VAR INTEGER[8] a = -7.
        VAR INTEGER i.
        VAR INTEGER n.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            n = g:GetNeighbourIndexes(0, 0, a).
            Assert:Equals(3, n).
            Assert:Equals(1, a[1]).
            Assert:Equals(3, a[2]).
            Assert:Equals(4, a[3]).
            DO i = 4 TO 8:
                Assert:Equals(-7, a[i]).
            END.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnArrayExactlyAsBigAsTheNeighbourhoodIsEnough():
        VAR Grid g.
        VAR INTEGER[8] a.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            Assert:Equals(8, g:GetNeighbourIndexes(1, 1, a)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ThrowsWhenTheArrayIsTooSmall():
        VAR Grid g.
        VAR INTEGER[7] a.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            g:GetNeighbourIndexes(1, 1, a).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ThrowsWhenTheArrayHasNoSize():
        VAR Grid g.
        VAR INTEGER[] a.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            g:GetNeighbourIndexes(1, 1, a).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ThrowsForACellOffTheGrid():
        VAR Grid g.
        VAR INTEGER[8] a.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 2, 1).
            g:GetNeighbourIndexes(3, 0, a).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- every cell of many grids against the simple version of the rule ---- */

    @Test.
    METHOD PUBLIC VOID EveryCellOfManyGridsMatchesTheSimpleRule():
        VAR INTEGER[11] ws = [1, 1, 5, 2, 2, 3, 3, 4, 5, 7, 9].
        VAR INTEGER[11] hs = [1, 5, 1, 2, 3, 2, 3, 4, 5, 4, 9].
        VAR INTEGER s.
        VAR INTEGER t.
        VAR INTEGER k.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR Grid g.
        DO s = 1 TO 11:
            DO t = 1 TO 2:
                DO k = 1 TO 3:
                    DO ON ERROR UNDO, THROW:
                        g = MakeGrid(ws[s], hs[s], t, k).
                        DO y = 0 TO hs[s] - 1:
                            DO x = 0 TO ws[s] - 1:
                                IF NeighboursOf(g, x, y) <> ExpectedNeighbours(g, x, y) THEN
                                    UNDO, THROW NEW AppError(SUBSTITUTE("&1 x &2, topology &3, neighbourhood &4, cell (&5,&6): got '&7' expected '&8'",
                                        ws[s], hs[s], t, k, x, y, NeighboursOf(g, x, y), ExpectedNeighbours(g, x, y)), 0).
                            END.
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
    METHOD PUBLIC VOID NeighbourListsNeverHaveRepeatsOrTheCellItself():
        VAR INTEGER[6] ws = [1, 2, 3, 2, 4, 9].
        VAR INTEGER[6] hs = [1, 2, 1, 3, 4, 9].
        VAR INTEGER s.
        VAR INTEGER k.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER i.
        VAR INTEGER n.
        VAR INTEGER[24] a.
        VAR Grid g.
        DO s = 1 TO 6:
            DO k = 1 TO 3:
                DO ON ERROR UNDO, THROW:
                    g = MakeGrid(ws[s], hs[s], 2, k).
                    DO y = 0 TO hs[s] - 1:
                        DO x = 0 TO ws[s] - 1:
                            n = g:GetNeighbourIndexes(x, y, a).
                            DO i = 1 TO n:
                                Assert:IsTrue(a[i] >= 0 AND a[i] < g:CellCount).
                                Assert:IsTrue(a[i] <> y * ws[s] + x).
                                Assert:Equals(i, LOOKUP(STRING(a[i]), NeighboursOf(g, x, y))).
                            END.
                        END.
                    END.
                    FINALLY:
                        IF VALID-OBJECT(g) THEN g:Dispose().
                    END FINALLY.
                END.
            END.
        END.
    END METHOD.

    /* ---- grid properties ---- */

    @Test.
    METHOD PUBLIC VOID ResolveAppliesTheTopology():
        VAR Grid b.
        VAR Grid t.
        DO ON ERROR UNDO, THROW:
            b = MakeGrid(3, 5, 1, 1).
            t = MakeGrid(3, 5, 2, 1).
            Assert:IsTrue(b:Resolve(-1, 0) = ?).
            Assert:Equals(2, t:Resolve(-1, 0)).
            Assert:Equals(7, b:Resolve(1, 2)).
            FINALLY:
                IF VALID-OBJECT(t) THEN t:Dispose().
                IF VALID-OBJECT(b) THEN b:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GridExposesItsTopologyAndNeighbourhood():
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 2, 2).
            Assert:IsTrue(g:Topology:Wraps).
            Assert:Equals(4, g:Neighbourhood:OffsetCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSingleArgumentConstructorIsBoundedWithMooreNeighbours():
        VAR Grid g.
        VAR INTEGER[8] a.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 3, "s")).
            Assert:IsFalse(g:Topology:Wraps).
            Assert:Equals(8, g:Neighbourhood:OffsetCount).
            Assert:Equals(3, g:GetNeighbourIndexes(0, 0, a)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DuplicateKeepsTheTopologyAndNeighbourhood():
        VAR Grid g.
        VAR Grid d.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(5, 5, 2, 2).
            d = g:Duplicate().
            Assert:IsTrue(d:Topology:Wraps).
            Assert:Equals(4, d:Neighbourhood:OffsetCount).
            Assert:Equals(NeighboursOf(g, 0, 0), NeighboursOf(d, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutATopology():
        VAR ITopology t.
        NEW Grid(NEW ArrayStore(3, 3, "s"), t, NEW MooreNeighbourhood()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutANeighbourhood():
        VAR INeighbourhood n.
        NEW Grid(NEW ArrayStore(3, 3, "s"), NEW BoundedTopology(), n).
    END METHOD.

END CLASS.
