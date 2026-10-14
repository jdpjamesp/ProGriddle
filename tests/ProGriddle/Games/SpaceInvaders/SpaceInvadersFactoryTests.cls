/* The Space Invaders factory builds the grid and the game: the arcade's 224 x 256 on three layers. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersFactoryTests:


    @Test.
    METHOD PUBLIC VOID TheLayersAreViewKindAndBackInThatOrder():
        Assert:Equals("view,kind,back", SpaceInvadersFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridIsTwoHundredTwentyFourByTwoHundredFiftySixWithTheThreeLayers():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = SpaceInvadersFactory:CreateGrid().
        Assert:Equals(224, g:Width).
        Assert:Equals(256, g:Height).
        Assert:Equals(3, g:Store:LayerCount).
        Assert:Equals("view", g:Store:LayerName(1)).
        Assert:Equals("kind", g:Store:LayerName(2)).
        Assert:Equals("back", g:Store:LayerName(3)).
        Assert:Equals(0, g:Store:GetCell(g:Store:LayerIndex("kind"), 223, 255)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameShowsTheTitleScreen():
        DEFINE VARIABLE game AS SpaceInvadersGame NO-UNDO.
        game = SpaceInvadersFactory:Create(NEW SeededRandom(1)).
        Assert:Equals(GamePhase:Title, game:Phase).
        Assert:Equals(224, game:Grid:Width).
        game:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameStarsAndTheDifferentSeedDoesNot():
        DEFINE VARIABLE a AS SpaceInvadersGame NO-UNDO.
        DEFINE VARIABLE b AS SpaceInvadersGame NO-UNDO.
        DEFINE VARIABLE c AS SpaceInvadersGame NO-UNDO.
        DEFINE VARIABLE same  AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE other AS LOGICAL NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        a = SpaceInvadersFactory:Create(NEW SeededRandom(11)).
        b = SpaceInvadersFactory:Create(NEW SeededRandom(11)).
        c = SpaceInvadersFactory:Create(NEW SeededRandom(12)).
        DO y = 25 TO 200:
            DO x = 0 TO 223:
                IF a:Canvas:ColourAt(x, y) <> b:Canvas:ColourAt(x, y) THEN same = FALSE.
                IF a:Canvas:ColourAt(x, y) <> c:Canvas:ColourAt(x, y) THEN other = TRUE.
            END.
        END.
        Assert:IsTrue(same).
        Assert:IsTrue(other).
        a:Dispose().
        b:Dispose().
        c:Dispose().
    END METHOD.

END CLASS.
