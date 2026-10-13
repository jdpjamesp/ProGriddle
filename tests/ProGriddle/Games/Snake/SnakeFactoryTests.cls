USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeFactoryTests:

    DEFINE PRIVATE VARIABLE mGame AS SnakeGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = SnakeFactory:Create(20, 20, NEW SeededRandom(3)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLayerIsCalledView():
        Assert:Equals("view", SnakeFactory:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateGridMakesAnEmptyBoardOfTheSizeAskedFor():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = SnakeFactory:CreateGrid(14, 9).
        Assert:Equals(14, g:Width).
        Assert:Equals(9, g:Height).
        Assert:Equals(1, g:Store:LayerCount).
        Assert:Equals("view", g:Store:LayerName(1)).
        Assert:Equals(14 * 9, g:Store:CountOf(1, 0)).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CreateMakesAGameWithTheSnakeInTheMiddle():
        Assert:Equals(20, mGame:Grid:Width).
        Assert:Equals(10, mGame:HeadX).
        Assert:Equals(10, mGame:HeadY).
        Assert:Equals(3, mGame:Length).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RebuildChangesTheBoardOfARunningGame():
        mGame:SetFood(11, 10).
        mGame:Tick(150).
        SnakeFactory:Rebuild(mGame, 30, 20).
        Assert:Equals(30, mGame:Grid:Width).
        Assert:Equals(20, mGame:Grid:Height).
        Assert:Equals(15, mGame:HeadX).
        Assert:Equals(0, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RebuildRefusesASideOutOfRangeAndChangesNothing():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            SnakeFactory:Rebuild(mGame, 4, 20).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeFactory:Rebuild(mGame, 20, 41).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeFactory:Rebuild(mGame, ?, 20).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeFactory:Rebuild(?, 20, 20).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
        Assert:Equals(20, mGame:Grid:Width).
    END METHOD.

END CLASS.
