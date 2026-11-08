USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.NeighbourhoodTests:

    /* The offsets as text, "x,y x,y ...", in the order the neighbourhood lists them. */
    METHOD PRIVATE CHARACTER OffsetsOf(INPUT poN AS INeighbourhood):
        VAR INTEGER i.
        VAR CHARACTER result.
        DO i = 1 TO poN:OffsetCount:
            result = result + (IF i > 1 THEN " " ELSE "") + SUBSTITUTE("&1,&2", poN:OffsetX(i), poN:OffsetY(i)).
        END.
        RETURN result.
    END METHOD.

    /* ---- Moore ---- */

    @Test.
    METHOD PUBLIC VOID MooreHasTheEightSurroundingCellsInReadingOrder():
        VAR INeighbourhood n = NEW MooreNeighbourhood().
        Assert:Equals(8, n:OffsetCount).
        Assert:Equals("-1,-1 0,-1 1,-1 -1,0 1,0 -1,1 0,1 1,1", OffsetsOf(n)).
        Assert:Equals(1, n:Reach).
    END METHOD.

    /* ---- Von Neumann ---- */

    @Test.
    METHOD PUBLIC VOID VonNeumannHasTheFourOrthogonalCellsInReadingOrder():
        VAR INeighbourhood n = NEW VonNeumannNeighbourhood().
        Assert:Equals(4, n:OffsetCount).
        Assert:Equals("0,-1 -1,0 1,0 0,1", OffsetsOf(n)).
        Assert:Equals(1, n:Reach).
    END METHOD.

    /* ---- custom ---- */

    @Test.
    METHOD PUBLIC VOID CustomKeepsItsOffsetsAndReportsItsReach():
        VAR INTEGER[3] xs = [1, -2, 0].
        VAR INTEGER[3] ys = [2, 1, -3].
        VAR INeighbourhood n = NEW CustomNeighbourhood(xs, ys).
        Assert:Equals(3, n:OffsetCount).
        Assert:Equals("1,2 -2,1 0,-3", OffsetsOf(n)).
        Assert:Equals(3, n:Reach).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomCopiesItsInput():
        VAR INTEGER[2] xs = [1, 2].
        VAR INTEGER[2] ys = [0, 0].
        VAR INeighbourhood n = NEW CustomNeighbourhood(xs, ys).
        xs[1] = 99.
        ys[2] = 99.
        Assert:Equals("1,0 2,0", OffsetsOf(n)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsTheCellItself():
        VAR INTEGER[2] xs = [1, 0].
        VAR INTEGER[2] ys = [0, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsARepeatedOffset():
        VAR INTEGER[3] xs = [1, 0, 1].
        VAR INTEGER[3] ys = [0, 1, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsMismatchedArrays():
        VAR INTEGER[2] xs = [1, 2].
        VAR INTEGER[3] ys = [0, 0, 0].
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CustomRejectsEmptyArrays():
        VAR INTEGER[] xs.
        VAR INTEGER[] ys.
        NEW CustomNeighbourhood(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID OffsetXThrowsBelowRange():
        NEW MooreNeighbourhood():OffsetX(0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID OffsetYThrowsAboveRange():
        NEW VonNeumannNeighbourhood():OffsetY(5).
    END METHOD.

END CLASS.
