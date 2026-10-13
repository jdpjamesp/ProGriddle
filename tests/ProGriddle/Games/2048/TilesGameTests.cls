/* The rules of 2048, tested without a window. A ScriptedRandom decides which tile appears and
   where: each new tile asks for a number below 10 (0 gives a 4, anything else a 2) and then a
   number below the count of empty cells (the nth empty cell, counting along the rows). So "5,0"
   puts a 2 in the first empty cell. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.2048.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesGameTests:

    DEFINE PRIVATE VARIABLE mGame AS TilesGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("5,0")).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The board as text, one character per cell holding the power of two (. empty, 1 is a 2,
       2 is a 4, and so on up to 9 for a 512, then A for a 1024 and B for a 2048), rows
       separated by a slash. */
    METHOD PRIVATE CHARACTER Board():
        RETURN REPLACE(NEW TextGridRenderer("view", TilesLook:TextSymbols()):ToText(mGame:Grid), CHR(10), "/").
    END METHOD.

    /* Starts the game from a board written as 16 powers of two, row by row. */
    METHOD PRIVATE VOID Start(INPUT pcTiles AS CHARACTER):
        mGame:StartWith(pcTiles).
    END METHOD.

    METHOD PRIVATE INTEGER TileCount():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 0 TO mGame:Grid:CellCount - 1:
            IF mGame:Grid:Store:GetCellAt(1, i) > 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* ---- a new game ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameIsNamedAfterTheGameAndHasNoMovesOrScore():
        Assert:Equals("2048", mGame:Name).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(0, mGame:Generation).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:HasWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsWithTwoTilesPlacedByTheRandomSource():
        Assert:Equals("11../..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheKindOfTheFirstTilesFollowsTheRandomSource():
        mGame:Dispose().
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("0,3,7,0")).
        /* first tile: a 4 in the empty cell number 3, then a 2 in the first empty cell, which is 0 */
        Assert:Equals("1..2/..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseStartsAgainWithTwoTilesAndClearsTheScore():
        Start("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:IsTrue(mGame:Score > 0).
        mGame:Initialise().
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(2, TileCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeededRandomSourceGivesTheSameGameEveryTime():
        DEFINE VARIABLE other AS TilesGame NO-UNDO.
        mGame:Dispose().
        mGame = TilesFactory:Create(4, 4, NEW SeededRandom(7)).
        other = TilesFactory:Create(4, 4, NEW SeededRandom(7)).
        Assert:Equals(REPLACE(NEW TextGridRenderer("view", TilesLook:TextSymbols()):ToText(other:Grid), CHR(10), "/"), Board()).
        other:Dispose().
    END METHOD.

    /* ---- sliding and merging ---- */

    @Test.
    METHOD PUBLIC VOID MoveLeftSlidesATileToTheLeftEdge():
        Start("0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mGame:MoveLeft()).
        Assert:Equals("11../..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveRightSlidesATileToTheRightEdge():
        Start("1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mGame:MoveRight()).
        Assert:Equals("1..1/..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveUpSlidesATileToTheTopEdge():
        Start("0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0").
        Assert:IsTrue(mGame:MoveUp()).
        Assert:Equals("11../..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveDownSlidesATileToTheBottomEdge():
        Start("0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mGame:MoveDown()).
        Assert:Equals("1.../..../..../.1..", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoEqualTilesMergeIntoTheNextPowerAndScoreItsValue():
        Start("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mGame:MoveLeft()).
        Assert:Equals("21../..../..../....", Board()).
        Assert:Equals(4, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FourEqualTilesMakeTwoMergesNotOne():
        Start("1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:Equals("221./..../..../....", Board()).
        Assert:Equals(8, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileMadeByAMergeDoesNotMergeAgainInTheSameMove():
        Start("1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:Equals("221./..../..../....", Board()).
        Assert:Equals(4, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThreeEqualTilesMergeTheOnesNearestTheEdgeBeingMovedTo():
        Start("1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:Equals("211./..../..../....", Board()).
        Start("1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveRight().
        Assert:Equals("1.12/..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TilesSeparatedByAGapStillMerge():
        Start("0,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveRight().
        Assert:Equals("1..3/..../..../....", Board()).
        Assert:Equals(8, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MergingWorksDownAColumnToo():
        Start("1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveDown().
        Assert:Equals("1.../..../..../2...", Board()).
        Assert:Equals(4, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryRowAndColumnSlidesIndependently():
        Start("1,0,0,1,0,2,2,0,3,0,0,0,0,0,0,3").
        mGame:MoveLeft().
        Assert:Equals("21../3.../3.../3...", Board()).
        Assert:Equals(4 + 8, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoTilesOfTheHighestPowerDoNotMerge():
        Start("20,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:Equals(0, mGame:Score).
    END METHOD.

    /* ---- what a move does besides sliding ---- */

    @Test.
    METHOD PUBLIC VOID AMoveThatChangesNothingReturnsFalseAndDoesNotCountOrAddATile():
        Start("1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:IsFalse(mGame:MoveUp()).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(1, TileCount()).
        Assert:Equals("1.../..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMoveThatChangesTheBoardCountsATurnAndAddsOneTile():
        Start("0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, mGame:Generation).
        Assert:Equals(2, TileCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewTileIsATwoUnlessTheRandomSourceSaysOtherwise():
        mGame:Dispose().
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("0,0,5,0,0,2")).
        Start("0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        /* the move is left, so the tile slides to cell 0, then a 4 goes in empty cell number 2 */
        mGame:MoveLeft().
        Assert:Equals("1..2/..../..../....", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewTileGoesInTheNthEmptyCellCountingAlongTheRows():
        mGame:Dispose().
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("5,0,5,0,5,14")).
        Start("0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        /* 15 empty cells after the slide, number 14 is the last one */
        Assert:Equals("1.../..../..../...1", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreAddsUpOverSeveralMoves():
        Start("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:Equals(4, mGame:Score).
        Start("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:Equals(0, mGame:Score).
    END METHOD.

    /* ---- winning and losing ---- */

    @Test.
    METHOD PUBLIC VOID MakingA2048TileSetsHasWonButTheGameGoesOn():
        Start("10,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Assert:IsTrue(mGame:HasWon).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(11, mGame:TopTile).
        Assert:Equals(2048, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardStartedWith2048OnItHasWon():
        Start("11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mGame:HasWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTopTileIsTheLargestPowerOnTheBoard():
        Start("1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,2").
        Assert:Equals(3, mGame:TopTile).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullBoardWithNoEqualNeighboursIsGameOver():
        Start("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,1").
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:CanMove()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMoveThatFillsTheBoardLastEndsTheGame():
        mGame:Dispose().
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("0,0")).
        Start("1,2,1,2,2,1,2,1,1,2,1,2,1,2,1,0").
        Assert:IsFalse(mGame:IsOver).
        mGame:MoveRight().
        Assert:Equals("1212/2121/1212/2121", Board()).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullBoardWithAnEqualPairCanStillMove():
        Start("1,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16").
        Assert:IsTrue(mGame:CanMove()).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardWithAnEmptyCellCanMove():
        Start("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,0").
        Assert:IsTrue(mGame:CanMove()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMoveAfterTheGameIsOverThrows():
        Start("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,1").
        AssertThrows("MoveLeft").
        AssertThrows("MoveRight").
        AssertThrows("MoveUp").
        AssertThrows("MoveDown").
    END METHOD.

    METHOD PRIVATE VOID AssertThrows(INPUT pcMove AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE pcMove:
                WHEN "MoveLeft"  THEN mGame:MoveLeft().
                WHEN "MoveRight" THEN mGame:MoveRight().
                WHEN "MoveUp"    THEN mGame:MoveUp().
                WHEN "MoveDown"  THEN mGame:MoveDown().
            END CASE.
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown, pcMove + " should throw").
    END METHOD.

    /* ---- setting up a board ---- */

    @Test.
    METHOD PUBLIC VOID StartWithPlacesTheTilesAndClearsTheScoreAndTurn():
        Start("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mGame:MoveLeft().
        Start("0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:Equals("...3/..../..../....", Board()).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartWithTheWrongNumberOfTilesThrows():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:StartWith("1,2,3").
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartWithAPowerOutOfRangeThrows():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:StartWith("21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    /* ---- building the game ---- */

    @Test.
    METHOD PUBLIC VOID TheGameNeedsAGridWithTheOneViewLayer():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW TilesGame(NEW Grid(NEW ArrayStore(4, 4, "state")), NEW ScriptedRandom("5,0")).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameNeedsARandomSource():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW TilesGame(TilesFactory:CreateGrid(4, 4), ?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoardCanBeAnySizeFromTwoByTwo():
        mGame:Dispose().
        mGame = TilesFactory:Create(6, 5, NEW SeededRandom(3)).
        Assert:Equals(6, mGame:Grid:Width).
        Assert:Equals(5, mGame:Grid:Height).
        Assert:Equals(2, TileCount()).
    END METHOD.

END CLASS.
