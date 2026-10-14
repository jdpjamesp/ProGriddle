/* The cells on a line between two cells, as a drag fills them in. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.CellPathTests:

    DEFINE PRIVATE VARIABLE mPath AS CellPath NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPath():
        mPath = NEW CellPath().
    END METHOD.

    /* The cells as text, "x,y" separated by a space. */
    METHOD PRIVATE CHARACTER Cells():
        DEFINE VARIABLE i   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE out AS CHARACTER NO-UNDO.
        DO i = 0 TO mPath:Count - 1:
            out = out + (IF out = "" THEN "" ELSE " ") + SUBSTITUTE("&1,&2", mPath:X(i), mPath:Y(i)).
        END.
        RETURN out.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN n = mPath:Plan(?, 0, 1, 1).
                WHEN 2 THEN n = mPath:X(0).
                WHEN 3 THEN DO:
                    mPath:Plan(0, 0, 2, 0).
                    n = mPath:Y(2).
                END.
                WHEN 4 THEN DO:
                    mPath:Plan(0, 0, 2, 0).
                    n = mPath:X(-1).
                END.
                WHEN 5 THEN n = mPath:Plan(0, 0, 1, ?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameCellIsAPathOfNothing():
        Assert:Equals(0, mPath:Plan(4, 4, 4, 4)).
        Assert:Equals(0, mPath:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANeighbouringCellIsAPathOfThatOneCell():
        Assert:Equals(1, mPath:Plan(4, 4, 5, 4)).
        Assert:Equals("5,4", Cells()).
        Assert:Equals(1, mPath:Plan(4, 4, 5, 5)).
        Assert:Equals("5,5", Cells()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStraightRunLeavesOutTheStartAndKeepsTheEnd():
        Assert:Equals(4, mPath:Plan(2, 7, 6, 7)).
        Assert:Equals("3,7 4,7 5,7 6,7", Cells()).
        Assert:Equals(3, mPath:Plan(2, 7, 2, 4)).
        Assert:Equals("2,6 2,5 2,4", Cells()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADiagonalGoesCornerToCorner():
        Assert:Equals(3, mPath:Plan(0, 0, 3, 3)).
        Assert:Equals("1,1 2,2 3,3", Cells()).
        Assert:Equals(3, mPath:Plan(3, 3, 0, 0)).
        Assert:Equals("2,2 1,1 0,0", Cells()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlopeStepsAlongTheLongerSideSoNoCellIsSkipped():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE px AS INTEGER NO-UNDO.
        DEFINE VARIABLE py AS INTEGER NO-UNDO.
        Assert:Equals(10, mPath:Plan(0, 0, 10, 3)).
        px = 0.
        py = 0.
        DO i = 0 TO mPath:Count - 1:
            Assert:IsTrue(ABSOLUTE(mPath:X(i) - px) <= 1 AND ABSOLUTE(mPath:Y(i) - py) <= 1, "cell " + STRING(i)).
            Assert:Equals(i + 1, mPath:X(i)).
            px = mPath:X(i).
            py = mPath:Y(i).
        END.
        Assert:Equals(3, py).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASteepSlopeStepsAlongTheRows():
        Assert:Equals(6, mPath:Plan(5, 1, 7, 7)).
        Assert:Equals(7, mPath:Y(5)).
        Assert:Equals(7, mPath:X(5)).
        Assert:Equals(2, mPath:Y(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APathCanRunLeftAndUpAndBeReusedForTheNextOne():
        Assert:Equals(3, mPath:Plan(9, 9, 6, 8)).
        Assert:Equals(6, mPath:X(2)).
        Assert:Equals(8, mPath:Y(2)).
        Assert:Equals(1, mPath:Plan(0, 0, 0, 1)).
        Assert:Equals("0,1", Cells()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCellsOfAPathAreReadByNumberAndABadNumberIsRefused():
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCellIsRefused():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(5)).
    END METHOD.

END CLASS.
