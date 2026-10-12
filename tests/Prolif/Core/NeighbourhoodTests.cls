USING OpenEdge.Core.Assert.
USING Prolif.Core.CustomNeighbourhood.
USING Prolif.Core.INeighbourhood.
USING Prolif.Core.MooreNeighbourhood.
USING Prolif.Core.VonNeumannNeighbourhood.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.NeighbourhoodTests:

    /* The offsets as text, "x,y x,y ...", in the order the neighbourhood lists them. */
    METHOD PRIVATE CHARACTER OffsetsOf(INPUT poN AS INeighbourhood):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO poN:OffsetCount:
            result = result + (IF i > 1 THEN " " ELSE "") + SUBSTITUTE("&1,&2", poN:OffsetX(i), poN:OffsetY(i)).
        END.
        RETURN result.
    END METHOD.

    /* ---- Moore ---- */

    @Test.
    METHOD PUBLIC VOID MooreHasTheEightSurroundingCellsInReadingOrder():
        DEFINE VARIABLE n AS INeighbourhood NO-UNDO.
        n = NEW MooreNeighbourhood().
        Assert:Equals(8, n:OffsetCount).
        Assert:Equals("-1,-1 0,-1 1,-1 -1,0 1,0 -1,1 0,1 1,1", OffsetsOf(n)).
        Assert:Equals(1, n:Reach).
    END METHOD.

    /* ---- Von Neumann ---- */

    @Test.
    METHOD PUBLIC VOID VonNeumannHasTheFourOrthogonalCellsInReadingOrder():
        DEFINE VARIABLE n AS INeighbourhood NO-UNDO.
        n = NEW VonNeumannNeighbourhood().
        Assert:Equals(4, n:OffsetCount).
        Assert:Equals("0,-1 -1,0 1,0 0,1", OffsetsOf(n)).
        Assert:Equals(1, n:Reach).
    END METHOD.

    /* ---- custom ---- */

    @Test.
    METHOD PUBLIC VOID CustomKeepsItsOffsetsAndReportsItsReach():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 3 INITIAL [1, -2, 0].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 3 INITIAL [2, 1, -3].
        DEFINE VARIABLE n  AS INeighbourhood NO-UNDO.
        n = NEW CustomNeighbourhood(xs, ys).
        Assert:Equals(3, n:OffsetCount).
        Assert:Equals("1,2 -2,1 0,-3", OffsetsOf(n)).
        Assert:Equals(3, n:Reach).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomCopiesItsInput():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [1, 2].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 0].
        DEFINE VARIABLE n  AS INeighbourhood NO-UNDO.
        n = NEW CustomNeighbourhood(xs, ys).
        xs[1] = 99.
        ys[2] = 99.
        Assert:Equals("1,0 2,0", OffsetsOf(n)).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsTheCellItself():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [1, 0].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsARepeatedOffset():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 3 INITIAL [1, 0, 1].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 3 INITIAL [0, 1, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsMismatchedArrays():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [1, 2].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 3 INITIAL [0, 0, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsEmptyArrays():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID OffsetXThrowsBelowRange():
        NEW MooreNeighbourhood():OffsetX(0).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID OffsetYThrowsAboveRange():
        NEW VonNeumannNeighbourhood():OffsetY(5).
    END METHOD.

END CLASS.
