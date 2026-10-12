/* Tests for what is particular to ArrayStore. The shared contract is in CellStoreContractTests. */
USING OpenEdge.Core.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.ArrayStoreTests:

    @Test.
    METHOD PUBLIC VOID HoldsABoardFarLargerThanTheExtentLimit():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(1000, 1000, "state").
            s:SetCell(1, 999, 999, 42).
            s:SetCell(1, 0, 0, 7).
            Assert:Equals(42, s:GetCellAt(1, 999999)).
            Assert:Equals(7, s:GetCellAt(1, 0)).
            Assert:Equals(999998, s:CountOf(1, 0)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DuplicateCopiesEveryCellOfEveryLayerOfALargeStore():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DEFINE VARIABLE d AS ICellStore NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(200, 200, "a,b").
            DO i = 0 TO 39999:
                s:SetCellAt(1, i, i).
                s:SetCellAt(2, i, - i).
            END.
            d = s:Duplicate().
            DO i = 0 TO 39999 BY 997:
                Assert:Equals(i, d:GetCellAt(1, i)).
                Assert:Equals(- i, d:GetCellAt(2, i)).
            END.
            Assert:Equals(39999, d:GetCellAt(1, 39999)).
            Assert:Equals(-39999, d:GetCellAt(2, 39999)).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWhenTheStoreWouldNeedOverTwoGigabytes():
        /* 49,000,000 cells x 20 layers x 4 bytes is about 3.9 GB. Nothing is allocated. */
        NEW ArrayStore(7000, 7000, "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsForMoreThanFiftyMillionCells():
        NEW ArrayStore(8000, 8000, "a").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CopyBytesToRejectsATargetOfTheWrongSize():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DEFINE VARIABLE m AS MEMPTR     NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(2, 2, "a").
            SET-SIZE(m) = 10.
            s:CopyBytesTo(m).
            FINALLY:
                SET-SIZE(m) = 0.
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyBytesToFillsTheTargetMemory():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DEFINE VARIABLE m AS MEMPTR     NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(2, 2, "a").
            s:SetCell(1, 1, 1, 123).
            SET-SIZE(m) = 16.
            s:CopyBytesTo(m).
            Assert:Equals(123, GET-LONG(m, 13)).
            Assert:Equals(0, GET-LONG(m, 1)).
            FINALLY:
                SET-SIZE(m) = 0.
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyBytesFromReplacesTheStoreContents():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DEFINE VARIABLE m AS MEMPTR     NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(2, 2, "a").
            s:SetCell(1, 0, 0, 5).
            SET-SIZE(m) = 16.
            PUT-LONG(m, 5) = 77.
            s:CopyBytesFrom(m).
            Assert:Equals(0, s:GetCell(1, 0, 0)).
            Assert:Equals(77, s:GetCell(1, 1, 0)).
            /* the source memory is left as it was */
            Assert:Equals(77, GET-LONG(m, 5)).
            FINALLY:
                SET-SIZE(m) = 0.
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CopyBytesFromRejectsASourceOfTheWrongSize():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DEFINE VARIABLE m AS MEMPTR     NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(2, 2, "a").
            SET-SIZE(m) = 8.
            s:CopyBytesFrom(m).
            FINALLY:
                SET-SIZE(m) = 0.
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyingAStoreOntoItselfChangesNothing():
        DEFINE VARIABLE s AS ArrayStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW ArrayStore(3, 3, "a").
            s:SetCell(1, 2, 2, 9).
            s:CopyFrom(s).
            Assert:Equals(9, s:GetCell(1, 2, 2)).
            Assert:Equals(8, s:CountOf(1, 0)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
