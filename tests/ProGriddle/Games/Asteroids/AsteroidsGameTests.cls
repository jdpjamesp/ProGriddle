/* The rules of Asteroids, tested without a window. Write the test first, then the rule: that is how
   the real games were built. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Asteroids.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsGameTests:

    DEFINE PRIVATE VARIABLE mGame AS AsteroidsGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(4, 3, "state"))).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The board as text, "#" for a lit cell, "." for a dark one, rows separated by a slash. */
    METHOD PRIVATE CHARACTER Board():
        RETURN REPLACE(NEW TextGridRenderer("state", ".#"):ToText(mGame:Grid), CHR(10), "/").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameIsNamedAfterTheGameAndStartsAtGenerationZero():
        Assert:Equals("Asteroids", mGame:Name).
        Assert:Equals(0, mGame:Generation).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameHasOneLitCellInTheTopLeft():
        Assert:Equals(0, mGame:Position).
        Assert:Equals("#.../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StepMovesTheLitCellOneAlongAndCountsTheGeneration():
        mGame:Step().
        Assert:Equals(1, mGame:Position).
        Assert:Equals(1, mGame:Generation).
        Assert:Equals(".#../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLitCellGoesOnToTheNextRowAtTheEndOfARow():
        mGame:Step().
        mGame:Step().
        mGame:Step().
        mGame:Step().
        Assert:Equals("..../#.../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLitCellStartsAgainAtTheTopLeftAtTheEndOfTheBoard():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 12:
            mGame:Step().
        END.
        Assert:Equals(0, mGame:Position).
        Assert:Equals(12, mGame:Generation).
        Assert:Equals("#.../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsAlwaysExactlyOneLitCell():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 30:
            mGame:Step().
            Assert:Equals(1, mGame:Grid:Store:CountOf(1, 1)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseStartsANewGame():
        mGame:Step().
        mGame:Step().
        mGame:Initialise().
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(0, mGame:Position).
        Assert:Equals("#.../..../....", Board()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AGridWithTheWrongLayerIsRefused():
        DEFINE VARIABLE g AS AsteroidsGame NO-UNDO.
        g = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(4, 3, "other"))).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AGridWithTwoLayersIsRefused():
        DEFINE VARIABLE g AS AsteroidsGame NO-UNDO.
        g = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(4, 3, "state,extra"))).
    END METHOD.

END CLASS.
