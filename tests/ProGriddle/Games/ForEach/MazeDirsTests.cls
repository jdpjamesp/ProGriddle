/* The four directions of the maze: their order (the tie break order, up then left then down then right) and the way
   each one points, as whole tiles. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.MazeDirsTests:

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE dir AS MazeDir NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN MazeDirs:Dx(dir).
                WHEN 2 THEN MazeDirs:Dy(dir).
                WHEN 3 THEN MazeDirs:Opposite(dir).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDirectionsComeInTieBreakOrderUpLeftDownRight():
        Assert:Equals(1, INTEGER(MazeDir:Up)).
        Assert:Equals(2, INTEGER(MazeDir:Left)).
        Assert:Equals(3, INTEGER(MazeDir:Down)).
        Assert:Equals(4, INTEGER(MazeDir:Right)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DxIsAcrossTheMazeAndRightIsPositive():
        Assert:Equals(0, MazeDirs:Dx(MazeDir:Up)).
        Assert:Equals(-1, MazeDirs:Dx(MazeDir:Left)).
        Assert:Equals(0, MazeDirs:Dx(MazeDir:Down)).
        Assert:Equals(1, MazeDirs:Dx(MazeDir:Right)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DyIsDownTheMazeAndDownIsPositive():
        Assert:Equals(-1, MazeDirs:Dy(MazeDir:Up)).
        Assert:Equals(0, MazeDirs:Dy(MazeDir:Left)).
        Assert:Equals(1, MazeDirs:Dy(MazeDir:Down)).
        Assert:Equals(0, MazeDirs:Dy(MazeDir:Right)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OppositeTurnsADirectionRoundAndBackAgain():
        Assert:Equals(MazeDir:Down, MazeDirs:Opposite(MazeDir:Up)).
        Assert:Equals(MazeDir:Right, MazeDirs:Opposite(MazeDir:Left)).
        Assert:Equals(MazeDir:Up, MazeDirs:Opposite(MazeDir:Down)).
        Assert:Equals(MazeDir:Left, MazeDirs:Opposite(MazeDir:Right)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownDirectionIsRefused():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

END CLASS.
