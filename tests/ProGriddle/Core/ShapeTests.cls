USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.ShapeTests:

    @Test.
    METHOD PUBLIC VOID ParseBuildsExpectedCells():
        DEFINE VARIABLE s AS Shape NO-UNDO.
        s = Shape:Parse("XX/.X").
        Assert:Equals(3, s:Size).
        Assert:Equals(2, s:Width).
        Assert:Equals(2, s:Height).
        Assert:IsTrue(s:Contains(0, 0)).
        Assert:IsTrue(s:Contains(1, 0)).
        Assert:IsTrue(s:Contains(1, 1)).
        Assert:IsFalse(s:Contains(0, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToStringRoundTripsParse():
        Assert:Equals("XX/.X", Shape:Parse("XX/.X"):ToString()).
        Assert:Equals("X.X/.X.", Shape:Parse("X.X/.X."):ToString()).
        Assert:Equals("XXXX", Shape:Parse("XXXX"):ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConstructorNormalisesToOrigin():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [5, 6].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 2 INITIAL [-3, -3].
        DEFINE VARIABLE s  AS Shape   NO-UNDO.
        s = NEW Shape(xs, ys).
        Assert:Equals("XX", s:ToString()).
        Assert:IsTrue(s:Contains(0, 0)).
        Assert:IsTrue(s:Contains(1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConstructorCopiesItsInput():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 1].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 0].
        DEFINE VARIABLE s  AS Shape   NO-UNDO.
        s = NEW Shape(xs, ys).
        xs[2] = 9.
        ys[1] = 9.
        Assert:Equals("XX", s:ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OffsetsAreReadableByIndex():
        DEFINE VARIABLE s AS Shape NO-UNDO.
        s = Shape:Parse("X./XX").
        Assert:Equals(0, s:OffsetX(1)).
        Assert:Equals(0, s:OffsetY(1)).
        Assert:Equals(0, s:OffsetX(2)).
        Assert:Equals(1, s:OffsetY(2)).
        Assert:Equals(1, s:OffsetX(3)).
        Assert:Equals(1, s:OffsetY(3)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID OffsetXThrowsBelowRange():
        Shape:Parse("X"):OffsetX(0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID OffsetYThrowsAboveRange():
        Shape:Parse("XX"):OffsetY(3).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RotateTurnsClockwise():
        Assert:Equals(".X/XX", Shape:Parse("XX/.X"):Rotate():ToString()).
        Assert:Equals("XXX", Shape:Parse("X/X/X"):Rotate():ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RotateDoesNotChangeTheOriginal():
        DEFINE VARIABLE s AS Shape NO-UNDO.
        s = Shape:Parse("XX/.X").
        s:Rotate().
        Assert:Equals("XX/.X", s:ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FourRotationsReturnTheOriginal():
        DEFINE VARIABLE names AS CHARACTER NO-UNDO EXTENT 4 INITIAL ["XX/.X", "XXXX", "X./X./XX", ".X./XXX"].
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE s     AS Shape   NO-UNDO.
        DO i = 1 TO 4:
            s = Shape:Parse(names[i]).
            Assert:IsTrue(s:Rotate():Rotate():Rotate():Rotate():Equals(s)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RotateSwapsWidthAndHeight():
        DEFINE VARIABLE r AS Shape NO-UNDO.
        r = Shape:Parse("XXXX"):Rotate().
        Assert:Equals(1, r:Width).
        Assert:Equals(4, r:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FlipMirrorsLeftToRight():
        Assert:Equals(".X/XX", Shape:Parse("X./XX"):Flip():ToString()).
        Assert:Equals("XX/.X", Shape:Parse("XX/.X"):Flip():Flip():ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EqualsIgnoresCellOrder():
        DEFINE VARIABLE xa AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 1].
        DEFINE VARIABLE ya AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 0].
        DEFINE VARIABLE xb AS INTEGER NO-UNDO EXTENT 2 INITIAL [1, 0].
        DEFINE VARIABLE yb AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 0].
        Assert:IsTrue(NEW Shape(xa, ya):Equals(NEW Shape(xb, yb))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EqualsIsFalseForDifferentShapesNullAndOtherTypes():
        DEFINE VARIABLE o AS Progress.Lang.Object NO-UNDO.
        Assert:IsFalse(Shape:Parse("XX"):Equals(Shape:Parse("X/X"))).
        Assert:IsFalse(Shape:Parse("XX"):Equals(Shape:Parse("XXX"))).
        Assert:IsFalse(Shape:Parse("XX"):Equals(o)).
        Assert:IsFalse(Shape:Parse("XX"):Equals(NEW Progress.Lang.Object())).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ParseThrowsWhenThereIsNoCell():
        Shape:Parse("../..").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsOnDuplicateCells():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [1, 1].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 2 INITIAL [2, 2].
        NEW Shape(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsOnMismatchedLengths():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT 2 INITIAL [0, 1].
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT 3 INITIAL [0, 0, 0].
        NEW Shape(xs, ys).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsOnEmptyArrays():
        DEFINE VARIABLE xs AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys AS INTEGER NO-UNDO EXTENT.
        NEW Shape(xs, ys).
    END METHOD.

END CLASS.
