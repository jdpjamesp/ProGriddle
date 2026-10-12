USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.CoordTests:

    @Test.
    METHOD PUBLIC VOID ConstructorStoresXAndY():
        DEFINE VARIABLE c AS Coord NO-UNDO.
        c = NEW Coord(3, 7).
        Assert:Equals(3, c:X).
        Assert:Equals(7, c:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlusReturnsNewMovedCoordAndLeavesOriginalUnchanged():
        DEFINE VARIABLE c AS Coord NO-UNDO.
        DEFINE VARIABLE m AS Coord NO-UNDO.
        c = NEW Coord(3, 7).
        m = c:Plus(-1, 2).
        Assert:Equals(2, m:X).
        Assert:Equals(9, m:Y).
        Assert:Equals(3, c:X).
        Assert:Equals(7, c:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EqualsComparesValues():
        Assert:IsTrue(NEW Coord(1, 2):Equals(NEW Coord(1, 2))).
        Assert:IsFalse(NEW Coord(1, 2):Equals(NEW Coord(2, 1))).
        Assert:IsFalse(NEW Coord(1, 2):Equals(NEW Coord(1, 3))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EqualsIsFalseForNullAndOtherTypes():
        DEFINE VARIABLE o AS Progress.Lang.Object NO-UNDO.
        Assert:IsFalse(NEW Coord(1, 2):Equals(o)).
        Assert:IsFalse(NEW Coord(1, 2):Equals(NEW Progress.Lang.Object())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToStringShowsBothValues():
        Assert:Equals("(4,-5)", NEW Coord(4, -5):ToString()).
    END METHOD.

END CLASS.
