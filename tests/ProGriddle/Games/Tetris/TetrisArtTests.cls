/* The shapes of Tetris: sixteen by sixteen blocks, one for each piece with a mark of its own, a hollow ghost and a floor cell. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisArtTests:

    /* The number of pixels of a character in a tile. */
    METHOD PRIVATE INTEGER CountOf(INPUT poTile AS Tile, INPUT pcChar AS CHARACTER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO poTile:Height - 1:
            DO x = 0 TO poTile:Width - 1:
                IF poTile:PixelAt(x, y) = pcChar THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* The two tiles differ in this many pixels. */
    METHOD PRIVATE INTEGER Differences(INPUT poA AS Tile, INPUT poB AS Tile):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO poA:Height - 1:
            DO x = 0 TO poA:Width - 1:
                IF poA:PixelAt(x, y) <> poB:PixelAt(x, y) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryBlockIsSixteenBySixteenAndUsesOnlyTheFiveTones():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO p = 1 TO 7:
            Assert:Equals(16, TetrisArt:Block(p):Width).
            Assert:Equals(16, TetrisArt:Block(p):Height).
            DO y = 0 TO 15:
                DO x = 0 TO 15:
                    Assert:IsTrue(INDEX("12345", TetrisArt:Block(p):PixelAt(x, y)) > 0, SUBSTITUTE("piece &1 at &2,&3", p, x, y)).
                END.
            END.
        END.
        Assert:Equals(16, TetrisArt:BlockBlank():Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachPieceHasAMarkOfItsOwnThatNoOtherPieceSharesAndTheBlankHasNone():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO 7:
            /* a mark is at least a dozen pixels that differ from the blank block, so it reads at 2x */
            Assert:IsTrue(Differences(TetrisArt:Block(i), TetrisArt:BlockBlank()) >= 12, "piece " + STRING(i)).
            DO j = i + 1 TO 7:
                Assert:IsTrue(Differences(TetrisArt:Block(i), TetrisArt:Block(j)) >= 12, SUBSTITUTE("pieces &1 and &2", i, j)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBlockIsBevelledWithAnEdgeAllRoundAndAGlint():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 15:
            Assert:Equals("5", TetrisArt:BlockBlank():PixelAt(i, 0)).
            Assert:Equals("5", TetrisArt:BlockBlank():PixelAt(i, 15)).
            Assert:Equals("5", TetrisArt:BlockBlank():PixelAt(0, i)).
            Assert:Equals("5", TetrisArt:BlockBlank():PixelAt(15, i)).
        END.
        Assert:Equals("1", TetrisArt:BlockBlank():PixelAt(1, 1)).
        Assert:Equals("1", TetrisArt:BlockBlank():PixelAt(4, 4)).
        Assert:Equals("4", TetrisArt:BlockBlank():PixelAt(14, 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGhostIsAHollowFrameWithItsFourCornersLeftOut():
        Assert:Equals(16, TetrisArt:Ghost():Width).
        Assert:Equals(".", TetrisArt:Ghost():PixelAt(0, 0)).
        Assert:Equals(".", TetrisArt:Ghost():PixelAt(15, 0)).
        Assert:Equals(".", TetrisArt:Ghost():PixelAt(0, 15)).
        Assert:Equals(".", TetrisArt:Ghost():PixelAt(15, 15)).
        Assert:Equals("D", TetrisArt:Ghost():PixelAt(1, 0)).
        Assert:Equals("D", TetrisArt:Ghost():PixelAt(0, 1)).
        /* the middle is mostly open so the floor shows through, with a hatch */
        Assert:IsTrue(CountOf(TetrisArt:Ghost(), "H") > 20).
        Assert:IsTrue(CountOf(TetrisArt:Ghost(), ".") > 100).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFloorCellIsFifteenByFifteenWithAGridLineOnItsRightAndBottom():
        Assert:Equals(16, TetrisArt:Floor():Width).
        Assert:Equals("F", TetrisArt:Floor():PixelAt(0, 0)).
        Assert:Equals("G", TetrisArt:Floor():PixelAt(15, 0)).
        Assert:Equals("G", TetrisArt:Floor():PixelAt(0, 15)).
        Assert:Equals(225, CountOf(TetrisArt:Floor(), "F")).
        Assert:Equals(31, CountOf(TetrisArt:Floor(), "G")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceOrBlockThatDoesNotExistIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            TetrisArt:Block(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            TetrisArt:Block(8).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
