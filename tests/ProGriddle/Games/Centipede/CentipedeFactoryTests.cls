/* The factory: the grid has the two layers and the 30 x 30 shape, and a created game shows the title. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheLayersAreMushroomAndPoison():
        Assert:Equals("mushroom,poison", CentipedeFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesAnEmptyThirtyByThirtyBoard():
        VAR Grid g.
        g = CentipedeFactory:CreateGrid().
        Assert:Equals(30, g:Width).
        Assert:Equals(30, g:Height).
        Assert:Equals(2, g:Store:LayerCount).
        Assert:Equals("mushroom", g:Store:LayerName(1)).
        Assert:Equals("poison", g:Store:LayerName(2)).
        Assert:Equals(900, g:Store:CountOf(1, 0)).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameOnTheTitleScreen():
        VAR CentipedeGame oGame.
        oGame = CentipedeFactory:Create(NEW SeededRandom(3)).
        Assert:IsTrue(oGame:Phase = GamePhase:Title).
        Assert:Equals(3, oGame:Lives).
        oGame:Dispose().
    END METHOD.

END CLASS.
