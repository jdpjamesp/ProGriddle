/* The Xevious factory builds a game of the right shape that shows the title. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousFactoryTests:

    @Test.
    METHOD PUBLIC VOID TheGridIs14By16WithOneGroundLayer():
        DEFINE VARIABLE oGrid AS Grid NO-UNDO.
        oGrid = XeviousFactory:CreateGrid().
        Assert:Equals("ground", XeviousFactory:Layers()).
        Assert:Equals(14, oGrid:Width).
        Assert:Equals(16, oGrid:Height).
        Assert:Equals(1, oGrid:Store:LayerCount).
        oGrid:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameShowsTheTitle():
        DEFINE VARIABLE oGame AS XeviousGame NO-UNDO.
        oGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        Assert:Equals(STRING(XeviousPhase:Title), STRING(oGame:Phase)).
        oGame:Dispose().
    END METHOD.

END CLASS.
