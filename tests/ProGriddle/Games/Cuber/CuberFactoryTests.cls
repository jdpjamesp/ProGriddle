/* The Cuber factory builds the 7 x 7 grid with its one layer and a game on the title screen. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheLayerIsCalledLamp():
        Assert:Equals("lamp", CuberFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesASevenBySevenGridWithOneLayer():
        VAR Grid g = CuberFactory:CreateGrid().
        Assert:Equals(7, g:Width).
        Assert:Equals(7, g:Height).
        Assert:Equals(1, g:Store:LayerCount).
        Assert:Equals("lamp", g:Store:LayerName(1)).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameOnTheTitleScreen():
        VAR CuberGame game = CuberFactory:Create(NEW SeededRandom(3)).
        Assert:Equals(STRING(CuberPhase:Title), STRING(game:Phase)).
        Assert:Equals("Cuber", game:Name).
        game:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateRefusesNoRandomSource():
        VAR LOGICAL thrown.
        VAR CuberGame game.
        DO ON ERROR UNDO, LEAVE:
            game = CuberFactory:Create(?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

END CLASS.
