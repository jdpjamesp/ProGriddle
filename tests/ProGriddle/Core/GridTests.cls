USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.GridTests:

    @Test.
    METHOD PUBLIC VOID TakesItsSizeFromTheStore():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            Assert:Equals(3, g:Width).
            Assert:Equals(5, g:Height).
            Assert:Equals(15, g:CellCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IndexMathsIsRowMajorOnANonSquareGrid():
        /* 3 wide, 5 high: corners, edges and the middle */
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            Assert:Equals(0, g:IndexOf(0, 0)).
            Assert:Equals(2, g:IndexOf(2, 0)).
            Assert:Equals(12, g:IndexOf(0, 4)).
            Assert:Equals(14, g:IndexOf(2, 4)).
            Assert:Equals(5, g:IndexOf(2, 1)).
            Assert:Equals(7, g:IndexOf(1, 2)).
            Assert:Equals(0, g:XOf(0)).
            Assert:Equals(0, g:YOf(0)).
            Assert:Equals(2, g:XOf(2)).
            Assert:Equals(0, g:YOf(2)).
            Assert:Equals(0, g:XOf(12)).
            Assert:Equals(4, g:YOf(12)).
            Assert:Equals(2, g:XOf(14)).
            Assert:Equals(4, g:YOf(14)).
            Assert:Equals(1, g:XOf(7)).
            Assert:Equals(2, g:YOf(7)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID XOfAndYOfInvertIndexOfForEveryCell():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(7, 4, "state")).
            DO y = 0 TO 3:
                DO x = 0 TO 6:
                    Assert:Equals(x, g:XOf(g:IndexOf(x, y))).
                    Assert:Equals(y, g:YOf(g:IndexOf(x, y))).
                END.
            END.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InBoundsCoversEveryEdge():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            Assert:IsTrue(g:InBounds(0, 0)).
            Assert:IsTrue(g:InBounds(2, 4)).
            Assert:IsFalse(g:InBounds(-1, 0)).
            Assert:IsFalse(g:InBounds(0, -1)).
            Assert:IsFalse(g:InBounds(3, 0)).
            Assert:IsFalse(g:InBounds(0, 5)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID IndexOfThrowsForAColumnOffTheGrid():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            g:IndexOf(3, 0).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID IndexOfThrowsForARowOffTheGrid():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            g:IndexOf(0, -1).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID XOfThrowsForAnIndexBelowZero():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            g:XOf(-1).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID YOfThrowsForAnIndexPastTheEnd():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 5, "state")).
            g:YOf(15).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutAStore():
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        NEW Grid(s).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridExposesItsStore():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(4, 4, "state").
            g = NEW Grid(s).
            Assert:IsTrue(g:Store = s).
            g:Store:SetCell(1, 1, 2, 9).
            Assert:Equals(9, s:GetCellAt(1, g:IndexOf(1, 2))).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DuplicateIsAnIndependentGridWithTheSameContents():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE d AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 3, "state")).
            g:Store:SetCell(1, 1, 1, 5).
            d = g:Duplicate().
            Assert:Equals(3, d:Width).
            Assert:Equals(3, d:Height).
            Assert:Equals(5, d:Store:GetCell(1, 1, 1)).
            d:Store:SetCell(1, 1, 1, 6).
            Assert:Equals(5, g:Store:GetCell(1, 1, 1)).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeDisposesTheStore():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        s = NEW SparseStore(3, 3, "state").
        g = NEW Grid(s).
        s:SetCell(1, 0, 0, 1).
        g:Dispose().
        Assert:Equals(0, s:OccupiedCount()).
    END METHOD.

END CLASS.
