/* Tests for what is particular to SparseStore. The shared contract is in CellStoreContractTests. */
USING OpenEdge.Core.Assert.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.ICellStore.
USING Prolif.Core.SparseStore.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.SparseStoreTests:

    @Test.
    METHOD PUBLIC VOID OnlyNonZeroCellsAreStored():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(10, 10, "a,b").
            Assert:Equals(0, s:OccupiedCount()).
            s:SetCell(1, 3, 3, 5).
            s:SetCell(2, 3, 3, 6).
            Assert:Equals(2, s:OccupiedCount()).
            s:SetCell(1, 3, 3, 9).
            Assert:Equals(2, s:OccupiedCount()).
            s:SetCell(1, 3, 3, 0).
            Assert:Equals(1, s:OccupiedCount()).
            s:SetCell(1, 4, 4, 0).
            Assert:Equals(1, s:OccupiedCount()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillLayerStoresEveryCellOnlyForANonZeroValue():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(4, 4, "a,b").
            s:SetCell(2, 0, 0, 1).
            s:FillLayer(1, 3).
            Assert:Equals(17, s:OccupiedCount()).
            s:FillLayer(1, 0).
            Assert:Equals(1, s:OccupiedCount()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardOfAMillionCellsCostsOnlyItsOccupiedCells():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(1000, 1000, "state").
            s:SetCell(1, 999, 999, 1).
            s:SetCell(1, 0, 0, 1).
            s:SetCell(1, 500, 500, 2).
            Assert:Equals(3, s:OccupiedCount()).
            Assert:Equals(999997, s:CountOf(1, 0)).
            Assert:Equals(2, s:CountOf(1, 1)).
            Assert:Equals(2, s:GetCellAt(1, 500500)).
            Assert:IsFalse(s:IsEmpty()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DuplicateKeepsTheOccupiedCellsAndIsIndependent():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DEFINE VARIABLE d AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(5, 5, "a").
            s:SetCell(1, 1, 1, 4).
            s:SetCell(1, 4, 4, 5).
            d = CAST(s:Duplicate(), SparseStore).
            Assert:Equals(2, d:OccupiedCount()).
            d:SetCell(1, 1, 1, 0).
            Assert:Equals(1, d:OccupiedCount()).
            Assert:Equals(2, s:OccupiedCount()).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyFromReplacesWhatWasThereBefore():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DEFINE VARIABLE t AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(5, 5, "a").
            t = NEW SparseStore(5, 5, "a").
            s:SetCell(1, 0, 0, 1).
            t:SetCell(1, 3, 3, 1).
            t:SetCell(1, 4, 4, 1).
            t:CopyFrom(s).
            Assert:Equals(1, t:OccupiedCount()).
            Assert:Equals(1, t:GetCell(1, 0, 0)).
            Assert:Equals(0, t:GetCell(1, 3, 3)).
            FINALLY:
                IF VALID-OBJECT(t) THEN t:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyFromAnArrayStoreKeepsOnlyTheNonZeroCells():
        DEFINE VARIABLE a AS ArrayStore  NO-UNDO.
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = NEW ArrayStore(6, 6, "a").
            s = NEW SparseStore(6, 6, "a").
            s:SetCell(1, 5, 5, 8).
            a:SetCell(1, 2, 3, 7).
            s:CopyFrom(a).
            Assert:Equals(1, s:OccupiedCount()).
            Assert:Equals(7, s:GetCell(1, 2, 3)).
            Assert:Equals(0, s:GetCell(1, 5, 5)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeEmptiesTheStore():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        s = NEW SparseStore(3, 3, "a").
        s:SetCell(1, 1, 1, 1).
        s:Dispose().
        Assert:Equals(0, s:OccupiedCount()).
    END METHOD.

END CLASS.
