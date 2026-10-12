USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheGridHasTheOneLayerViewAndThePlayfieldLockedAndActive():
        Assert:Equals("view", TetrisFactory:Layers()).
        Assert:Equals("locked,active", TetrisFactory:FieldLayers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateFieldMakesAnEmptyBoardSizedStoreWithBothLayers():
        DEFINE VARIABLE s AS ICellStore NO-UNDO.
        DO ON ERROR UNDO, THROW:
            s = TetrisFactory:CreateField(10, 20).
            Assert:Equals(10, s:Width).
            Assert:Equals(20, s:Height).
            Assert:Equals(2, s:LayerCount).
            Assert:Equals("locked", s:LayerName(1)).
            Assert:Equals("active", s:LayerName(2)).
            Assert:IsTrue(s:IsEmpty()).
            FINALLY:
                IF VALID-OBJECT(s) THEN s:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridIsTheBoardPlusADividerAndAPanelOfSixAndDoesNotWrap():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = TetrisFactory:CreateGrid(8, 12).
            Assert:Equals(15, g:Width).
            Assert:Equals(12, g:Height).
            Assert:Equals(1, g:Store:LayerCount).
            Assert:Equals("view", g:Store:LayerName(1)).
            Assert:IsTrue(TYPE-OF(g:Store, TableStore)).
            Assert:IsFalse(g:Topology:Wraps).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesTheUsualTenByTwentyGameReadyToPlay():
        DEFINE VARIABLE g AS TetrisGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = TetrisFactory:Create(NEW SeededRandom(1)).
            Assert:Equals("Tetris", g:Name).
            Assert:Equals(10, g:BoardWidth).
            Assert:Equals(20, g:BoardHeight).
            Assert:Equals(17, g:Grid:Width).
            Assert:IsFalse(g:IsOver).
            Assert:IsTrue(g:CurrentPiece > 0).
            Assert:IsTrue(g:NextPiece > 0).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateSizedMakesABoardOfAnotherSize():
        DEFINE VARIABLE g AS TetrisGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = TetrisFactory:CreateSized(12, 24, NEW SeededRandom(1)).
            Assert:Equals(12, g:BoardWidth).
            Assert:Equals(24, g:BoardHeight).
            Assert:Equals(19, g:Grid:Width).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardTooSmallIsRefused():
        DEFINE VARIABLE g AS TetrisGame NO-UNDO.
        g = TetrisFactory:CreateSized(4, 20, NEW SeededRandom(1)).
    END METHOD.

END CLASS.
