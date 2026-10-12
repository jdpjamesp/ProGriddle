/* The contract every ICellStore must meet. ABLUnit does not run test methods inherited
   from a base class, so instead of subclassing, each test here loops over every store
   kind and names the failing store in its error message. A new store only needs a new
   branch in Make and StoreName, and a higher KindCount. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.CellStoreContractTests:

    DEFINE PRIVATE VARIABLE KindCount AS INTEGER NO-UNDO INITIAL 3.

    /* ---- helpers ---- */

    METHOD PRIVATE ICellStore Make(INPUT piKind AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT pcLayers AS CHARACTER):
        CASE piKind:
            WHEN 1 THEN RETURN NEW ArrayStore(piW, piH, pcLayers).
            WHEN 2 THEN RETURN NEW SparseStore(piW, piH, pcLayers).
            WHEN 3 THEN RETURN NEW TableStore(piW, piH, pcLayers).
        END CASE.
        UNDO, THROW NEW AppError("Unknown store kind " + STRING(piKind), 0).
    END METHOD.

    METHOD PRIVATE CHARACTER StoreName(INPUT piKind AS INTEGER):
        CASE piKind:
            WHEN 1 THEN RETURN "ArrayStore".
            WHEN 2 THEN RETURN "SparseStore".
            WHEN 3 THEN RETURN "TableStore".
        END CASE.
        RETURN "kind " + STRING(piKind).
    END METHOD.

    /* Rethrows with the store name in front so a failure says which store broke the contract. */
    METHOD PRIVATE VOID Rethrow(INPUT piKind AS INTEGER, INPUT poError AS Progress.Lang.Error):
        UNDO, THROW NEW AppError(SUBSTITUTE("[&1] &2", StoreName(piKind), poError:GetMessage(1)), 0).
    END METHOD.

    /* Runs one named operation and says whether it threw GridException. Any other error escapes.
       get, set: layer, x, y. getat, setat: layer, index. fill, count: layer.
       isfull, clearrow, shift: layer, row. */
    METHOD PRIVATE LOGICAL Throws(INPUT poStore AS ICellStore, INPUT pcOp AS CHARACTER,
                                  INPUT piA AS INTEGER, INPUT piB AS INTEGER, INPUT piC AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE l AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE pcOp:
                WHEN "get"      THEN n = poStore:GetCell(piA, piB, piC).
                WHEN "set"      THEN poStore:SetCell(piA, piB, piC, 1).
                WHEN "getat"    THEN n = poStore:GetCellAt(piA, piB).
                WHEN "setat"    THEN poStore:SetCellAt(piA, piB, 1).
                WHEN "fill"     THEN poStore:FillLayer(piA, 1).
                WHEN "count"    THEN n = poStore:CountOf(piA, 0).
                WHEN "isfull"   THEN l = poStore:IsRowFull(piA, piB).
                WHEN "clearrow" THEN poStore:ClearRow(piA, piB).
                WHEN "shift"    THEN poStore:ShiftRowsDown(piA, piB).
                OTHERWISE UNDO, THROW NEW AppError("Unknown operation " + pcOp, 0).
            END CASE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE LOGICAL ConstructThrows(INPUT piKind AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT pcLayers AS CHARACTER):
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = Make(piKind, piW, piH, pcLayers).
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
        RETURN FALSE.
    END METHOD.

    /* ---- construction and layers ---- */

    @Test.
    METHOD PUBLIC VOID ReportsWidthHeightAndLayerCount():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 5, "a,b").
            Assert:Equals(3, s:Width).
            Assert:Equals(5, s:Height).
            Assert:Equals(2, s:LayerCount).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LayersAreNumberedFromOneAndNamesAreCaseInsensitive():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 2, 2, "mine, Revealed ,flag").
            Assert:Equals(1, s:LayerIndex("mine")).
            Assert:Equals(2, s:LayerIndex("revealed")).
            Assert:Equals(3, s:LayerIndex("FLAG")).
            Assert:Equals("mine", s:LayerName(1)).
            Assert:Equals("Revealed", s:LayerName(2)).
            Assert:Equals("flag", s:LayerName(3)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UnknownLayerNameAndBadLayerNumbersThrow():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE s      AS ICellStore NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 2, 2, "a,b").
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:LayerIndex("nope").
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:LayerName(0).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:LayerName(3).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConstructorRejectsBadSizesAndBadLayerLists():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            Assert:IsTrue(ConstructThrows(k, 0, 3, "a")).
            Assert:IsTrue(ConstructThrows(k, 3, 0, "a")).
            Assert:IsTrue(ConstructThrows(k, -1, 3, "a")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "a,,b")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "a,A")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "a,b,a")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "1abc")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "has space")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "x")).
            Assert:IsTrue(ConstructThrows(k, 3, 3, "ok,Y")).
            Assert:IsFalse(ConstructThrows(k, 1, 1, "ok_1")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NewStoreIsEmptyAndEveryCellIsZero():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE l AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 5, "a,b").
            Assert:IsTrue(s:IsEmpty()).
            DO l = 1 TO 2:
                DO i = 0 TO 14:
                    Assert:Equals(0, s:GetCellAt(l, i)).
                END.
                Assert:Equals(15, s:CountOf(l, 0)).
            END.
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- index maths ---- */

    @Test.
    METHOD PUBLIC VOID IndexIsRowMajorOnANonSquareGrid():
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        DEFINE VARIABLE s  AS ICellStore NO-UNDO.
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 5 INITIAL [0, 2, 0, 2, 1].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 5 INITIAL [0, 0, 4, 4, 2].
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 5, "a").
            DO i = 1 TO 5:
                s:SetCell(1, xs[i], ys[i], 10 + i).
            END.
            Assert:Equals(11, s:GetCellAt(1, 0)).
            Assert:Equals(12, s:GetCellAt(1, 2)).
            Assert:Equals(13, s:GetCellAt(1, 12)).
            Assert:Equals(14, s:GetCellAt(1, 14)).
            Assert:Equals(15, s:GetCellAt(1, 7)).
            s:SetCellAt(1, 5, 99).
            Assert:Equals(99, s:GetCell(1, 2, 1)).
            Assert:Equals(9, s:CountOf(1, 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LayersAreIndependent():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            s:SetCell(1, 1, 1, 7).
            Assert:Equals(7, s:GetCell(1, 1, 1)).
            Assert:Equals(0, s:GetCell(2, 1, 1)).
            s:SetCell(2, 1, 1, 8).
            Assert:Equals(7, s:GetCell(1, 1, 1)).
            Assert:Equals(8, s:GetCell(2, 1, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StoresNegativeAndLargeValuesAndAllowsOverwriting():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 2, 2, "a").
            s:SetCell(1, 0, 0, -5).
            s:SetCell(1, 1, 0, 2147483647).
            s:SetCell(1, 0, 1, -2147483647).
            Assert:Equals(-5, s:GetCell(1, 0, 0)).
            Assert:Equals(2147483647, s:GetCell(1, 1, 0)).
            Assert:Equals(-2147483647, s:GetCell(1, 0, 1)).
            s:SetCell(1, 0, 0, 3).
            Assert:Equals(3, s:GetCell(1, 0, 0)).
            s:SetCell(1, 0, 0, 0).
            Assert:Equals(0, s:GetCell(1, 0, 0)).
            Assert:Equals(2, s:CountOf(1, 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OutOfRangeAccessThrows():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 5, "a,b").
            /* x or y off the board */
            Assert:IsTrue(Throws(s, "get", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "get", 1, 3, 0)).
            Assert:IsTrue(Throws(s, "get", 1, 0, -1)).
            Assert:IsTrue(Throws(s, "get", 1, 0, 5)).
            Assert:IsTrue(Throws(s, "set", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "set", 1, 3, 4)).
            Assert:IsTrue(Throws(s, "set", 1, 2, 5)).
            /* index off the board */
            Assert:IsTrue(Throws(s, "getat", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "getat", 1, 15, 0)).
            Assert:IsTrue(Throws(s, "setat", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "setat", 1, 15, 0)).
            /* layer off the range */
            Assert:IsTrue(Throws(s, "get", 0, 0, 0)).
            Assert:IsTrue(Throws(s, "get", 3, 0, 0)).
            Assert:IsTrue(Throws(s, "set", 0, 0, 0)).
            Assert:IsTrue(Throws(s, "set", 3, 0, 0)).
            Assert:IsTrue(Throws(s, "getat", 0, 0, 0)).
            Assert:IsTrue(Throws(s, "setat", 3, 0, 0)).
            Assert:IsTrue(Throws(s, "fill", 0, 0, 0)).
            Assert:IsTrue(Throws(s, "count", 3, 0, 0)).
            /* the last valid cells do not throw */
            Assert:IsFalse(Throws(s, "get", 2, 2, 4)).
            Assert:IsFalse(Throws(s, "set", 1, 0, 0)).
            Assert:IsFalse(Throws(s, "getat", 2, 14, 0)).
            Assert:IsFalse(Throws(s, "setat", 1, 0, 0)).
            /* a failed write changed nothing */
            Assert:IsTrue(s:IsEmpty() OR s:CountOf(1, 0) = 14).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- whole store operations ---- */

    @Test.
    METHOD PUBLIC VOID FillLayerAndCountOfWorkPerLayer():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 4, "a,b").
            s:FillLayer(1, 5).
            Assert:Equals(12, s:CountOf(1, 5)).
            Assert:Equals(0, s:CountOf(1, 0)).
            Assert:Equals(12, s:CountOf(2, 0)).
            Assert:Equals(0, s:CountOf(2, 5)).
            s:SetCell(1, 2, 3, 6).
            Assert:Equals(11, s:CountOf(1, 5)).
            Assert:Equals(1, s:CountOf(1, 6)).
            s:FillLayer(1, 0).
            Assert:Equals(12, s:CountOf(1, 0)).
            Assert:IsTrue(s:IsEmpty()).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsEmptyTracksEveryLayer():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            Assert:IsTrue(s:IsEmpty()).
            s:SetCell(2, 2, 2, 1).
            Assert:IsFalse(s:IsEmpty()).
            s:SetCell(2, 2, 2, 0).
            Assert:IsTrue(s:IsEmpty()).
            s:SetCell(1, 0, 0, 1).
            Assert:IsFalse(s:IsEmpty()).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DuplicateHasTheSameContentsAndIsIndependent():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DEFINE VARIABLE d AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            s:SetCell(1, 1, 1, 4).
            s:SetCell(2, 2, 0, 9).
            d = s:Duplicate().
            Assert:IsTrue(TYPE-OF(d, ICellStore)).
            Assert:Equals(3, d:Width).
            Assert:Equals(3, d:Height).
            Assert:Equals(2, d:LayerCount).
            Assert:Equals("b", d:LayerName(2)).
            Assert:Equals(4, d:GetCell(1, 1, 1)).
            Assert:Equals(9, d:GetCell(2, 2, 0)).
            Assert:Equals(8, d:CountOf(1, 0)).
            /* changing either side leaves the other alone */
            s:SetCell(1, 1, 1, 5).
            d:SetCell(2, 0, 0, 6).
            Assert:Equals(4, d:GetCell(1, 1, 1)).
            Assert:Equals(0, s:GetCell(2, 0, 0)).
            d:FillLayer(1, 7).
            Assert:Equals(5, s:GetCell(1, 1, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyFromOverwritesEveryCell():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DEFINE VARIABLE t AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            t = Make(k, 3, 3, "a,b").
            s:SetCell(1, 0, 2, 3).
            s:SetCell(2, 2, 2, 8).
            t:FillLayer(1, 1).
            t:SetCell(2, 1, 1, 2).
            t:CopyFrom(s).
            Assert:Equals(3, t:GetCell(1, 0, 2)).
            Assert:Equals(8, t:GetCell(2, 2, 2)).
            Assert:Equals(0, t:GetCell(1, 1, 1)).
            Assert:Equals(0, t:GetCell(2, 1, 1)).
            Assert:Equals(8, t:CountOf(1, 0)).
            /* the source is untouched and still independent */
            t:SetCell(1, 0, 2, 0).
            Assert:Equals(3, s:GetCell(1, 0, 2)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(t) THEN t:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyFromRejectsADifferentSizeOrDifferentLayers():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE s      AS ICellStore NO-UNDO.
        DEFINE VARIABLE other  AS ICellStore NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            other = Make(k, 3, 4, "a,b").
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:CopyFrom(other).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            other:Dispose().
            other = Make(k, 3, 3, "a,c").
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:CopyFrom(other).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            other:Dispose().
            other = Make(k, 3, 3, "a").
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:CopyFrom(other).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(other) THEN other:Dispose().
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CopyFromWorksBetweenAnyTwoStoreKinds():
        DEFINE VARIABLE k1 AS INTEGER NO-UNDO.
        DEFINE VARIABLE k2 AS INTEGER NO-UNDO.
        DEFINE VARIABLE s  AS ICellStore NO-UNDO.
        DEFINE VARIABLE t  AS ICellStore NO-UNDO.
        DO k1 = 1 TO KindCount ON ERROR UNDO, THROW:
            DO k2 = 1 TO KindCount ON ERROR UNDO, THROW:
                s = Make(k1, 3, 3, "a,b").
                t = Make(k2, 3, 3, "a,b").
                s:SetCell(1, 2, 1, 5).
                s:SetCell(2, 0, 0, 6).
                t:SetCell(1, 1, 1, 9).
                t:CopyFrom(s).
                Assert:Equals(5, t:GetCell(1, 2, 1)).
                Assert:Equals(6, t:GetCell(2, 0, 0)).
                Assert:Equals(0, t:GetCell(1, 1, 1)).
                Assert:Equals(7, t:CountOf(1, 0) - 1).
                CATCH e AS Progress.Lang.Error:
                    UNDO, THROW NEW AppError(SUBSTITUTE("[&1 into &2] &3", StoreName(k1), StoreName(k2), e:GetMessage(1)), 0).
                END CATCH.
                FINALLY:
                    IF VALID-OBJECT(t) THEN t:Dispose().
                    IF VALID-OBJECT(s) THEN s:Dispose().
                END FINALLY.
            END.
        END.
    END METHOD.

    /* ---- shapes ---- */

    @Test.
    METHOD PUBLIC VOID CanPlaceChecksTheBoardEdgesAndOccupiedCells():
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        DEFINE VARIABLE s  AS ICellStore NO-UNDO.
        DEFINE VARIABLE el AS Shape NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 4, 4, "locked,other").
            el = Shape:Parse("X./XX").
            Assert:IsTrue(s:CanPlace(1, el, 0, 0)).
            Assert:IsTrue(s:CanPlace(1, el, 2, 2)).
            Assert:IsFalse(s:CanPlace(1, el, 3, 2)).
            Assert:IsFalse(s:CanPlace(1, el, 2, 3)).
            Assert:IsFalse(s:CanPlace(1, el, -1, 0)).
            Assert:IsFalse(s:CanPlace(1, el, 0, -1)).
            s:SetCell(1, 1, 1, 1).
            Assert:IsFalse(s:CanPlace(1, el, 0, 0)).
            Assert:IsTrue(s:CanPlace(1, el, 0, 2)).
            Assert:IsTrue(s:CanPlace(2, el, 0, 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StampWritesTheShapeAndEraseClearsIt():
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        DEFINE VARIABLE s  AS ICellStore NO-UNDO.
        DEFINE VARIABLE el AS Shape NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 4, 4, "a,b").
            el = Shape:Parse("X./XX").
            s:Stamp(1, el, 1, 2, 7).
            Assert:Equals(7, s:GetCell(1, 1, 2)).
            Assert:Equals(7, s:GetCell(1, 1, 3)).
            Assert:Equals(7, s:GetCell(1, 2, 3)).
            Assert:Equals(0, s:GetCell(1, 2, 2)).
            Assert:Equals(3, s:CountOf(1, 7)).
            Assert:Equals(0, s:CountOf(2, 7)).
            s:Erase(1, el, 1, 2).
            Assert:IsTrue(s:IsEmpty()).
            /* a shape that exactly fits the corner */
            s:Stamp(1, el, 2, 2, 1).
            Assert:Equals(3, s:CountOf(1, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StampOffTheBoardThrowsAndWritesNothing():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE s      AS ICellStore NO-UNDO.
        DEFINE VARIABLE el     AS Shape NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 4, 4, "a").
            el = Shape:Parse("X./XX").
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:Stamp(1, el, 3, 3, 1).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:Erase(1, el, -1, 0).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            Assert:IsTrue(s:IsEmpty()).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- rows ---- */

    METHOD PRIVATE VOID SetRow(INPUT poStore AS ICellStore, INPUT piLayer AS INTEGER, INPUT piY AS INTEGER,
                               INPUT pcValues AS CHARACTER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DO x = 1 TO NUM-ENTRIES(pcValues):
            poStore:SetCell(piLayer, x - 1, piY, INTEGER(ENTRY(x, pcValues))).
        END.
    END METHOD.

    METHOD PRIVATE CHARACTER RowText(INPUT poStore AS ICellStore, INPUT piLayer AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO x = 0 TO poStore:Width - 1:
            result = result + (IF x > 0 THEN "," ELSE "") + STRING(poStore:GetCell(piLayer, x, piY)).
        END.
        RETURN result.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsRowFullNeedsEveryCellNonZero():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            Assert:IsFalse(s:IsRowFull(1, 1)).
            SetRow(s, 1, 1, "1,2,3").
            Assert:IsTrue(s:IsRowFull(1, 1)).
            Assert:IsFalse(s:IsRowFull(1, 0)).
            Assert:IsFalse(s:IsRowFull(2, 1)).
            s:SetCell(1, 1, 1, 0).
            Assert:IsFalse(s:IsRowFull(1, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearRowEmptiesOnlyThatRowOfThatLayer():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a,b").
            SetRow(s, 1, 0, "1,1,1").
            SetRow(s, 1, 1, "2,2,2").
            SetRow(s, 2, 1, "3,3,3").
            s:ClearRow(1, 1).
            Assert:Equals("1,1,1", RowText(s, 1, 0)).
            Assert:Equals("0,0,0", RowText(s, 1, 1)).
            Assert:Equals("3,3,3", RowText(s, 2, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShiftRowsDownRemovesTheRowAndMovesTheRowsAboveIt():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 4, "a,b").
            SetRow(s, 1, 0, "1,0,0").
            SetRow(s, 1, 1, "0,2,0").
            SetRow(s, 1, 2, "3,3,3").
            SetRow(s, 1, 3, "4,0,4").
            SetRow(s, 2, 1, "9,9,9").
            s:ShiftRowsDown(1, 2).
            Assert:Equals("0,0,0", RowText(s, 1, 0)).
            Assert:Equals("1,0,0", RowText(s, 1, 1)).
            Assert:Equals("0,2,0", RowText(s, 1, 2)).
            Assert:Equals("4,0,4", RowText(s, 1, 3)).
            /* the other layer is untouched */
            Assert:Equals("9,9,9", RowText(s, 2, 1)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShiftRowsDownOnTheTopAndBottomRows():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 2, 3, "a").
            SetRow(s, 1, 0, "1,1").
            SetRow(s, 1, 1, "2,2").
            SetRow(s, 1, 2, "3,3").
            s:ShiftRowsDown(1, 0).
            Assert:Equals("0,0", RowText(s, 1, 0)).
            Assert:Equals("2,2", RowText(s, 1, 1)).
            Assert:Equals("3,3", RowText(s, 1, 2)).
            SetRow(s, 1, 0, "1,1").
            s:ShiftRowsDown(1, 2).
            Assert:Equals("0,0", RowText(s, 1, 0)).
            Assert:Equals("1,1", RowText(s, 1, 1)).
            Assert:Equals("2,2", RowText(s, 1, 2)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RowOperationsThrowForABadRowOrLayer():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a").
            Assert:IsTrue(Throws(s, "isfull", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "isfull", 1, 3, 0)).
            Assert:IsTrue(Throws(s, "isfull", 2, 0, 0)).
            Assert:IsTrue(Throws(s, "clearrow", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "clearrow", 1, 3, 0)).
            Assert:IsTrue(Throws(s, "clearrow", 0, 0, 0)).
            Assert:IsTrue(Throws(s, "shift", 1, -1, 0)).
            Assert:IsTrue(Throws(s, "shift", 1, 3, 0)).
            Assert:IsTrue(Throws(s, "shift", 2, 1, 0)).
            Assert:IsFalse(Throws(s, "isfull", 1, 2, 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- lifetime ---- */

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledMoreThanOnce():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO k = 1 TO KindCount ON ERROR UNDO, THROW:
            s = Make(k, 3, 3, "a").
            s:SetCell(1, 1, 1, 1).
            s:Dispose().
            s:Dispose().
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

END CLASS.
