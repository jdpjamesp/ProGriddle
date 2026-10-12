/* Tests for what is particular to TableStore. The shared contract is in CellStoreContractTests. */
USING OpenEdge.Core.Assert.
USING Prolif.Core.ICellStore.
USING Prolif.Core.TableStore.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.TableStoreTests:

    /* Runs a query over the store's buffer and returns the number of rows it finds. */
    METHOD PRIVATE INTEGER RowsMatching(INPUT poStore AS TableStore, INPUT pcWhere AS CHARACTER):
        DEFINE VARIABLE hQuery AS HANDLE  NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CREATE QUERY hQuery.
            hQuery:SET-BUFFERS(poStore:BufferHandle()).
            hQuery:QUERY-PREPARE("FOR EACH cells " + pcWhere).
            hQuery:QUERY-OPEN().
            hQuery:GET-FIRST().
            DO WHILE NOT hQuery:QUERY-OFF-END:
                n = n + 1.
                hQuery:GET-NEXT().
            END.
            hQuery:QUERY-CLOSE().
            FINALLY:
                IF VALID-HANDLE(hQuery) THEN DELETE OBJECT hQuery.
            END FINALLY.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HasOneRecordPerCellAndNamedFieldsPerLayer():
        DEFINE VARIABLE s AS TableStore NO-UNDO.
        DEFINE VARIABLE b AS HANDLE     NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW TableStore(10, 20, "locked,ghost").
            b = s:BufferHandle().
            Assert:Equals(200, RowsMatching(s, "")).
            Assert:IsTrue(VALID-HANDLE(b:BUFFER-FIELD("x"))).
            Assert:IsTrue(VALID-HANDLE(b:BUFFER-FIELD("y"))).
            Assert:IsTrue(VALID-HANDLE(b:BUFFER-FIELD("locked"))).
            Assert:IsTrue(VALID-HANDLE(b:BUFFER-FIELD("ghost"))).
            Assert:Equals("INTEGER", b:BUFFER-FIELD("locked"):DATA-TYPE).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LayerValuesCanBeQueriedByNameAndPosition():
        DEFINE VARIABLE s AS TableStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW TableStore(5, 5, "mine,revealed").
            s:SetCell(1, 2, 1, 1).
            s:SetCell(1, 4, 4, 1).
            s:SetCell(2, 2, 1, 1).
            Assert:Equals(2, RowsMatching(s, "WHERE mine = 1")).
            Assert:Equals(1, RowsMatching(s, "WHERE mine = 1 AND revealed = 1")).
            Assert:Equals(1, RowsMatching(s, "WHERE x = 2 AND y = 1 AND mine = 1")).
            Assert:Equals(5, RowsMatching(s, "WHERE y = 3")).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GameStyleLayerNamesWorkAsFields():
        DEFINE VARIABLE s AS TableStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW TableStore(3, 3, "mine,revealed,flag,adjacent,ship,shot,locked,state,count,value,label").
            s:SetCell(s:LayerIndex("value"), 1, 1, 5).
            s:SetCell(s:LayerIndex("count"), 1, 1, 6).
            Assert:Equals(5, s:GetCell(s:LayerIndex("value"), 1, 1)).
            Assert:Equals(6, s:GetCell(s:LayerIndex("count"), 1, 1)).
            Assert:Equals(0, s:GetCell(s:LayerIndex("label"), 1, 1)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WorksPastTheOldExtentLimits():
        /* 40,000 cells is beyond both the 28,000 element extent limit and the few thousand
           element limit of a ROWID extent. */
        DEFINE VARIABLE s AS TableStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = NEW TableStore(200, 200, "a").
            s:SetCell(1, 199, 199, 3).
            s:SetCell(1, 0, 0, 4).
            Assert:Equals(3, s:GetCellAt(1, 39999)).
            Assert:Equals(4, s:GetCell(1, 0, 0)).
            Assert:Equals(39998, s:CountOf(1, 0)).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID RejectsMoreThanAHundredThousandCells():
        NEW TableStore(501, 200, "a").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeDeletesTheTable():
        DEFINE VARIABLE s AS TableStore NO-UNDO.
        s = NEW TableStore(3, 3, "a").
        Assert:IsTrue(VALID-HANDLE(s:BufferHandle())).
        s:Dispose().
        Assert:IsFalse(VALID-HANDLE(s:BufferHandle())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoStoresDoNotShareRecords():
        DEFINE VARIABLE a AS TableStore NO-UNDO.
        DEFINE VARIABLE b AS TableStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = NEW TableStore(3, 3, "v").
            b = NEW TableStore(3, 3, "v").
            a:SetCell(1, 1, 1, 9).
            Assert:Equals(0, b:GetCell(1, 1, 1)).
            b:SetCell(1, 1, 1, 4).
            Assert:Equals(9, a:GetCell(1, 1, 1)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
