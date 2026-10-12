USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheLayersAreShipShotMarkAndView():
        Assert:Equals("ship,shot,mark,view", BattleshipsFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesATwoBoardGridOnATableStore():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = BattleshipsFactory:CreateGrid(10, 10).
            Assert:Equals(21, g:Width).
            Assert:Equals(10, g:Height).
            Assert:Equals(4, g:Store:LayerCount).
            Assert:IsTrue(TYPE-OF(g:Store, TableStore)).
            Assert:IsFalse(g:Topology:Wraps).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameReadyForTheFleetToBePlaced():
        DEFINE VARIABLE g AS BattleshipsGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = BattleshipsFactory:Create(10, 10, "5,4,3,3,2", NEW SeededRandom(1), NEW ScriptedOpponent("")).
            Assert:Equals("Battleships", g:Name).
            Assert:Equals(5, g:FleetCount).
            Assert:Equals(5, g:ShipsToPlace).
            Assert:IsFalse(g:IsOver).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
