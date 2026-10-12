USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Minesweeper.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheLayersAreMineRevealedFlagAdjacentAndView():
        Assert:Equals("mine,revealed,flag,adjacent,view", MinesweeperFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesABoundedMooreGridOnATableStore():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:CreateGrid(12, 7).
            Assert:Equals(12, g:Width).
            Assert:Equals(7, g:Height).
            Assert:Equals(5, g:Store:LayerCount).
            Assert:IsTrue(TYPE-OF(g:Store, TableStore)).
            Assert:IsFalse(g:Topology:Wraps).
            Assert:Equals(8, g:Neighbourhood:OffsetCount).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameReadyForAFirstClick():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(16, 16, 40, NEW SeededRandom(1), NEW FakeClock()).
            Assert:Equals("Minesweeper", g:Name).
            Assert:Equals(40, g:MineCount).
            Assert:Equals(40, g:Grid:Store:CountOf(g:Grid:Store:LayerIndex("mine"), 1)).
            Assert:IsFalse(g:IsOver).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
