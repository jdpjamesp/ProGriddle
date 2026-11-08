/* Builds the pieces of a FOR EACH game. The grid is the maze at 8 pixels a tile, with 24 rows of pixels above it for the score and 16
   below for the lives and the item: 224 x 288 for the real maze. A game on any other maze gets a grid to fit it. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachFactoryTests:

    VAR PRIVATE ForEachGame mGame.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        VAR ForEachGame other.
        VAR Grid grid.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = ForEachFactory:Create(?).
                WHEN 2 THEN other = ForEachFactory:CreateOn(?, NEW SeededRandom(1)).
                WHEN 3 THEN other = ForEachFactory:CreateOn(NEW MazeMap(ForEachMaze:Layout()), ?).
                WHEN 4 THEN grid = ForEachFactory:CreateGrid(?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClassicGridIs224By288WithTheLayersTheFactoryNames():
        mGame = ForEachFactory:Create(NEW SeededRandom(3)).
        Assert:Equals(224, mGame:Grid:Width).
        Assert:Equals(288, mGame:Grid:Height).
        Assert:IsTrue(ForEachFactory:Layers() <> "").
        Assert:Equals(NUM-ENTRIES(ForEachFactory:Layers()), mGame:Grid:Store:LayerCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameOnTheForEachMazeShowingTheTitleScreen():
        mGame = ForEachFactory:Create(NEW SeededRandom(3)).
        Assert:Equals(ForEachPhase:Title, mGame:Phase).
        Assert:Equals(244, mGame:BitsLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateOnMakesAGameOnAnyMazeWithAGridToFitIt():
        mGame = ForEachFactory:CreateOn(NEW MazeMap(ForEachKit:ClosedCorridor()), NEW SeededRandom(3)).
        Assert:Equals(160, mGame:Grid:Width).
        Assert:Equals(64, mGame:Grid:Height).
        Assert:Equals(ForEachPhase:Title, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesAnEmptyGridForAMaze():
        VAR Grid grid.
        grid = ForEachFactory:CreateGrid(NEW MazeMap(ForEachMaze:Layout())).
        Assert:Equals(224, grid:Width).
        Assert:Equals(288, grid:Height).
        grid:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFactoryNeedsARandomSourceAndAMaze():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
    END METHOD.

END CLASS.
