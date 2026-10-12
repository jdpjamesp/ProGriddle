/* Tests for what is particular to SparseStore. The shared contract is in CellStoreContractTests. */
USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.SparseStoreTests:

    {ProGriddle/Core/SparseCells.i &NAME=ttIn &ACCESS=PRIVATE}

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
    METHOD PUBLIC VOID ExportCellsGivesACopyOfEveryStoredCell():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(4, 4, "a,b").
            s:SetCell(1, 1, 1, 5).
            s:SetCell(2, 3, 3, 6).
            s:ExportCells(OUTPUT TABLE ttIn).
            FIND ttIn WHERE ttIn.layerNo = 1 AND ttIn.cellIdx = 5.
            Assert:Equals(5, ttIn.cellVal).
            FIND ttIn WHERE ttIn.layerNo = 2 AND ttIn.cellIdx = 15.
            Assert:Equals(6, ttIn.cellVal).
            /* changing the copy leaves the store alone */
            EMPTY TEMP-TABLE ttIn.
            Assert:Equals(2, s:OccupiedCount()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ImportCellsReplacesEverythingInTheStore():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(4, 4, "a").
            s:SetCell(1, 0, 0, 9).
            s:SetCell(1, 1, 0, 9).
            s:SetCell(1, 2, 0, 9).
            EMPTY TEMP-TABLE ttIn.
            CREATE ttIn.
            ASSIGN ttIn.layerNo = 1 ttIn.cellIdx = 10 ttIn.cellVal = 4.
            s:ImportCells(INPUT TABLE ttIn).
            Assert:Equals(1, s:OccupiedCount()).
            Assert:Equals(4, s:GetCellAt(1, 10)).
            Assert:Equals(0, s:GetCell(1, 0, 0)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExportThenImportRoundTrips():
        DEFINE VARIABLE a AS SparseStore NO-UNDO.
        DEFINE VARIABLE b AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = NEW SparseStore(5, 5, "a").
            b = NEW SparseStore(5, 5, "a").
            a:SetCell(1, 4, 4, 2).
            a:SetCell(1, 0, 1, 3).
            a:ExportCells(OUTPUT TABLE ttIn).
            b:ImportCells(INPUT TABLE ttIn).
            Assert:Equals(2, b:OccupiedCount()).
            Assert:Equals(2, b:GetCell(1, 4, 4)).
            Assert:Equals(3, b:GetCell(1, 0, 1)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ImportingAnEmptyTableEmptiesTheStore():
        DEFINE VARIABLE s AS SparseStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(3, 3, "a").
            s:SetCell(1, 1, 1, 1).
            EMPTY TEMP-TABLE ttIn.
            s:ImportCells(INPUT TABLE ttIn).
            Assert:IsTrue(s:IsEmpty()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ImportCellsRejectsABadCellAndEmptiesTheStore():
        DEFINE VARIABLE s      AS SparseStore NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW SparseStore(3, 3, "a").
            s:SetCell(1, 1, 1, 1).
            EMPTY TEMP-TABLE ttIn.
            CREATE ttIn.
            ASSIGN ttIn.layerNo = 1 ttIn.cellIdx = 9 ttIn.cellVal = 1.
            DO ON ERROR UNDO, THROW:
                s:ImportCells(INPUT TABLE ttIn).
                CATCH ge AS ProGriddle.Core.GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            Assert:IsTrue(s:IsEmpty()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
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
