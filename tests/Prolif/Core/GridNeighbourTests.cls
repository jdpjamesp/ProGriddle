USING OpenEdge.Core.Assert.
USING Progress.Lang.*.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.BoundedTopology.
USING Prolif.Core.CustomNeighbourhood.
USING Prolif.Core.Grid.
USING Prolif.Core.INeighbourhood.
USING Prolif.Core.ITopology.
USING Prolif.Core.MooreNeighbourhood.
USING Prolif.Core.ToroidalTopology.
USING Prolif.Core.VonNeumannNeighbourhood.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.GridNeighbourTests:

    /* ---- helpers ---- */

    /* piTopology: 1 bounded, 2 toroidal. piNeighbourhood: 1 Moore, 2 Von Neumann, 3 a custom
       ring with a reach of 2. */
    METHOD PRIVATE Grid MakeGrid(INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piTopology AS INTEGER, INPUT piNeighbourhood AS INTEGER):
        DEFINE VARIABLE topo AS ITopology      NO-UNDO.
        DEFINE VARIABLE nbh  AS INeighbourhood NO-UNDO.
        DEFINE VARIABLE xs   AS INTEGER NO-UNDO EXTENT 12 INITIAL [2, -2, 0, 0, 2, 2, -2, -2, 1, 1, -1, -1].
        DEFINE VARIABLE ys   AS INTEGER NO-UNDO EXTENT 12 INITIAL [0, 0, 2, -2, 1, -1, 1, -1, 2, -2, 2, -2].
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
        DEFINE VARIABLE a      AS INTEGER   NO-UNDO EXTENT 24.
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        n = poGrid:GetNeighbourIndexes(piX, piY, a).
        DO i = 1 TO n:
            result = result + (IF i > 1 THEN "," ELSE "") + STRING(a[i]).
        END.
        RETURN result.
    END METHOD.

    /* An independent, deliberately simple version of the same rule: resolve every offset
       through the topology, drop missing cells, the cell itself and repeats. */
    METHOD PRIVATE CHARACTER ExpectedNeighbours(INPUT poGrid AS Grid, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE idx    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT 8 INITIAL -7.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT 8.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            Assert:Equals(8, g:GetNeighbourIndexes(1, 1, a)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ThrowsWhenTheArrayIsTooSmall():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT 7.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            g:GetNeighbourIndexes(1, 1, a).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ThrowsWhenTheArrayHasNoSize():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT.
        DO ON ERROR UNDO, THROW:
            g = MakeGrid(3, 3, 1, 1).
            g:GetNeighbourIndexes(1, 1, a).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ThrowsForACellOffTheGrid():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT 8.
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
        DEFINE VARIABLE ws AS INTEGER NO-UNDO EXTENT 11 INITIAL [1, 1, 5, 2, 2, 3, 3, 4, 5, 7, 9].
        DEFINE VARIABLE hs AS INTEGER NO-UNDO EXTENT 11 INITIAL [1, 5, 1, 2, 3, 2, 3, 4, 5, 4, 9].
        DEFINE VARIABLE s  AS INTEGER NO-UNDO.
        DEFINE VARIABLE t  AS INTEGER NO-UNDO.
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER NO-UNDO.
        DEFINE VARIABLE g  AS Grid NO-UNDO.
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
        DEFINE VARIABLE ws AS INTEGER NO-UNDO EXTENT 6 INITIAL [1, 2, 3, 2, 4, 9].
        DEFINE VARIABLE hs AS INTEGER NO-UNDO EXTENT 6 INITIAL [1, 2, 1, 3, 4, 9].
        DEFINE VARIABLE s  AS INTEGER NO-UNDO.
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE n  AS INTEGER NO-UNDO.
        DEFINE VARIABLE a  AS INTEGER NO-UNDO EXTENT 24.
        DEFINE VARIABLE g  AS Grid NO-UNDO.
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
        DEFINE VARIABLE b AS Grid NO-UNDO.
        DEFINE VARIABLE t AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE a AS INTEGER NO-UNDO EXTENT 8.
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
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE d AS Grid NO-UNDO.
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

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutATopology():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        NEW Grid(NEW ArrayStore(3, 3, "s"), t, NEW MooreNeighbourhood()).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutANeighbourhood():
        DEFINE VARIABLE n AS INeighbourhood NO-UNDO.
        NEW Grid(NEW ArrayStore(3, 3, "s"), NEW BoundedTopology(), n).
    END METHOD.

END CLASS.
