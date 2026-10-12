USING OpenEdge.Core.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.TopologyTests:

    /* ---- bounded ---- */

    @Test.
    METHOD PUBLIC VOID BoundedDoesNotWrap():
        Assert:IsFalse(NEW BoundedTopology():Wraps).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedResolvesCellsOnTheBoardToTheirIndex():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW BoundedTopology().
        Assert:Equals(0, t:Resolve(3, 5, 0, 0)).
        Assert:Equals(2, t:Resolve(3, 5, 2, 0)).
        Assert:Equals(12, t:Resolve(3, 5, 0, 4)).
        Assert:Equals(14, t:Resolve(3, 5, 2, 4)).
        Assert:Equals(7, t:Resolve(3, 5, 1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedResolvesEveryEdgeCrossingToUnknown():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW BoundedTopology().
        Assert:IsTrue(t:Resolve(3, 5, -1, 0) = ?).
        Assert:IsTrue(t:Resolve(3, 5, 3, 0) = ?).
        Assert:IsTrue(t:Resolve(3, 5, 0, -1) = ?).
        Assert:IsTrue(t:Resolve(3, 5, 0, 5) = ?).
        Assert:IsTrue(t:Resolve(3, 5, -1, -1) = ?).
        Assert:IsTrue(t:Resolve(3, 5, 3, 5) = ?).
        Assert:IsTrue(t:Resolve(3, 5, 100, -100) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BoundedIsValidMatchesTheBoard():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW BoundedTopology().
        Assert:IsTrue(t:IsValid(3, 5, 0, 0)).
        Assert:IsTrue(t:IsValid(3, 5, 2, 4)).
        Assert:IsFalse(t:IsValid(3, 5, -1, 0)).
        Assert:IsFalse(t:IsValid(3, 5, 3, 4)).
        Assert:IsFalse(t:IsValid(3, 5, 2, 5)).
        Assert:IsFalse(t:IsValid(3, 5, 0, -1)).
    END METHOD.

    /* ---- toroidal ---- */

    @Test.
    METHOD PUBLIC VOID ToroidalWraps():
        Assert:IsTrue(NEW ToroidalTopology():Wraps).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalResolvesCellsOnTheBoardToTheirIndex():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        Assert:Equals(0, t:Resolve(3, 5, 0, 0)).
        Assert:Equals(14, t:Resolve(3, 5, 2, 4)).
        Assert:Equals(7, t:Resolve(3, 5, 1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalWrapsEachSide():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        /* left of column 0 is the last column, right of the last column is column 0 */
        Assert:Equals(2, t:Resolve(3, 5, -1, 0)).
        Assert:Equals(0, t:Resolve(3, 5, 3, 0)).
        /* above row 0 is the last row, below the last row is row 0 */
        Assert:Equals(12, t:Resolve(3, 5, 0, -1)).
        Assert:Equals(0, t:Resolve(3, 5, 0, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalWrapsCornersDiagonally():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        Assert:Equals(14, t:Resolve(3, 5, -1, -1)).
        Assert:Equals(0, t:Resolve(3, 5, 3, 5)).
        Assert:Equals(12, t:Resolve(3, 5, 3, -1)).
        Assert:Equals(2, t:Resolve(3, 5, -1, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalWrapsFarOffCoordinatesIncludingNegativeOnes():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        Assert:Equals(Resolve5x5(t, 1, 1), t:Resolve(5, 5, 6, 6)).
        Assert:Equals(Resolve5x5(t, 1, 1), t:Resolve(5, 5, -4, -4)).
        Assert:Equals(Resolve5x5(t, 1, 1), t:Resolve(5, 5, 101, -99)).
        Assert:Equals(Resolve5x5(t, 4, 4), t:Resolve(5, 5, -6, -11)).
        Assert:Equals(0, t:Resolve(5, 5, -5, 5)).
    END METHOD.

    METHOD PRIVATE INTEGER Resolve5x5(INPUT poTopology AS ITopology, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN poTopology:Resolve(5, 5, piX, piY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalIsValidForEveryCoordinate():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        Assert:IsTrue(t:IsValid(3, 5, 0, 0)).
        Assert:IsTrue(t:IsValid(3, 5, -1, -1)).
        Assert:IsTrue(t:IsValid(3, 5, 50, 70)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToroidalOnAOneByOneBoardAlwaysResolvesToTheOnlyCell():
        DEFINE VARIABLE t AS ITopology NO-UNDO.
        t = NEW ToroidalTopology().
        Assert:Equals(0, t:Resolve(1, 1, 0, 0)).
        Assert:Equals(0, t:Resolve(1, 1, -1, 1)).
        Assert:Equals(0, t:Resolve(1, 1, 7, -3)).
    END METHOD.

END CLASS.
