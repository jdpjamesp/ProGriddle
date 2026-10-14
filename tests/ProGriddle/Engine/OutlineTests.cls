/* The outline: a shape of closed and open lines, read from text. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.OutlineTests:

    METHOD PRIVATE LOGICAL Refused(INPUT pcSpec AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Outline(pcSpec).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellIs64Units():
        Assert:Equals(64, Outline:Scale()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipIsOneClosedLineOfFivePointsAndAnOpenOneOfTwo():
        DEFINE VARIABLE o AS Outline NO-UNDO.
        o = NEW Outline("closed 0,-6 3.6,3 1.6,1.6 -1.6,1.6 -3.6,3 / open 0,-4.4 0,1.6").
        Assert:Equals(2, o:LineCount).
        Assert:Equals(7, o:PointTotal).
        Assert:Equals(6, o:SegmentCount).
        Assert:IsTrue(o:IsClosed(1)).
        Assert:IsFalse(o:IsClosed(2)).
        Assert:Equals(5, o:PointCount(1)).
        Assert:Equals(2, o:PointCount(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PointsAreKeptAs64thsOfACellAndRoundedToTheNearest():
        DEFINE VARIABLE o AS Outline NO-UNDO.
        o = NEW Outline("closed 0,-6 3.6,3 -1.6,1.6").
        Assert:Equals(0, o:PointX(1, 1)).
        Assert:Equals(-384, o:PointY(1, 1)).
        Assert:Equals(230, o:PointX(1, 2)).
        Assert:Equals(192, o:PointY(1, 2)).
        Assert:Equals(-102, o:PointX(1, 3)).
        Assert:Equals(102, o:PointY(1, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WholeNumbersAndNumbersStartingWithADotAreRead():
        DEFINE VARIABLE o AS Outline NO-UNDO.
        o = NEW Outline("open 2,-3 .5,-.25").
        Assert:Equals(128, o:PointX(1, 1)).
        Assert:Equals(-192, o:PointY(1, 1)).
        Assert:Equals(32, o:PointX(1, 2)).
        Assert:Equals(-16, o:PointY(1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClosedLineHasAsManySegmentsAsPointsAndAnOpenOneHasOneFewer():
        Assert:Equals(3, NEW Outline("closed 0,0 4,0 4,4"):SegmentCount).
        Assert:Equals(2, NEW Outline("open 0,0 4,0 4,4"):SegmentCount).
        Assert:Equals(1, NEW Outline("open 0,0 4,0"):SegmentCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMaxRadiusIsTheFurthestPointFromTheOrigin():
        Assert:Equals(384, NEW Outline("closed 0,-6 3,3 -3,3"):MaxRadius).
        Assert:Equals(320, NEW Outline("open 3,4 -3.5,0 0,0"):MaxRadius).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExtraSpacesDoNotMatter():
        DEFINE VARIABLE o AS Outline NO-UNDO.
        o = NEW Outline("  closed   0,0   4,0  4,4  /  open 1,1   2,2 ").
        Assert:Equals(2, o:LineCount).
        Assert:Equals(3, o:PointCount(1)).
        Assert:Equals(2, o:PointCount(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextThatIsNotAnOutlineIsRefused():
        Assert:IsTrue(Refused("")).
        Assert:IsTrue(Refused(?)).
        Assert:IsTrue(Refused("closed")).
        Assert:IsTrue(Refused("closed 0,0 4,0")).
        Assert:IsTrue(Refused("open 0,0")).
        Assert:IsTrue(Refused("wiggly 0,0 4,0 4,4")).
        Assert:IsTrue(Refused("open 0,0 4")).
        Assert:IsTrue(Refused("open 0,0 4,x")).
        Assert:IsTrue(Refused("open 0,0 1.2.3,4")).
        Assert:IsTrue(Refused("open 0,0 4,0 /")).
        Assert:IsTrue(Refused("open 0,0 ,4")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineOrPointOutsideTheOutlineIsRefused():
        DEFINE VARIABLE o      AS Outline NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        o = NEW Outline("open 0,0 4,0").
        DO ON ERROR UNDO, THROW:
            o:PointX(0, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            o:PointY(1, 3).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            o:IsClosed(2).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            o:PointCount(?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawToTurnsMovesAndRoundsTheShapeOntoACanvas():
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(30, 20, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        NEW Outline("open 0,0 0,-4"):DrawTo(canvas, 10 * 256, 10 * 256, 16, 1, 777, 0, 0).
        Assert:Equals(777, canvas:ColourAt(10, 10)).
        Assert:Equals(777, canvas:ColourAt(14, 10)).
        Assert:Equals(5, canvas:CountKind(1)).
        NEW Outline("open 0,0 0,-4"):DrawTo(canvas, 10 * 256, 10 * 256, 0, 2, 888, 5, 3).
        Assert:Equals(888, canvas:ColourAt(15, 13)).
        Assert:Equals(888, canvas:ColourAt(15, 9)).
        canvas:Dispose().
        grid:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawScaledToStretchesTheShapeAlongAndAcrossBeforeTurningIt():
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(30, 20, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        /* a line of 4 along the nose, drawn at 100 percent across and 200 along, is 8 long */
        NEW Outline("open 0,0 0,-4"):DrawScaledTo(canvas, 10 * 256, 10 * 256, 0, 100, 200, 1, 777).
        Assert:Equals(777, canvas:ColourAt(10, 10)).
        Assert:Equals(777, canvas:ColourAt(10, 2)).
        Assert:Equals(9, canvas:CountKind(1)).
        canvas:Restore().
        /* turned a quarter, the length runs across the screen */
        NEW Outline("open 0,0 0,-4"):DrawScaledTo(canvas, 10 * 256, 10 * 256, 16, 100, 200, 1, 777).
        Assert:Equals(777, canvas:ColourAt(18, 10)).
        canvas:Restore().
        /* squeezed to nothing across, a flat line is a single cell, 100 percent is the plain shape */
        NEW Outline("open -2,0 2,0"):DrawScaledTo(canvas, 10 * 256, 10 * 256, 0, 0, 100, 1, 777).
        Assert:Equals(1, canvas:CountKind(1)).
        canvas:Restore().
        NEW Outline("open -2,0 2,0"):DrawScaledTo(canvas, 10 * 256, 10 * 256, 0, 100, 100, 1, 777).
        Assert:Equals(5, canvas:CountKind(1)).
        canvas:Dispose().
        grid:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawScaledToRefusesNoCanvasAndANegativeScale():
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER     NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(30, 20, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        DO ON ERROR UNDO, THROW:
            NEW Outline("open 0,0 1,1"):DrawScaledTo(?, 0, 0, 0, 100, 100, 1, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Outline("open 0,0 1,1"):DrawScaledTo(canvas, 0, 0, 0, -1, 100, 1, 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Outline("open 0,0 1,1"):DrawScaledTo(canvas, 0, 0, 0, 100, ?, 1, 1).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
        canvas:Dispose().
        grid:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawToRefusesNoCanvasAndALineOfMoreThan64Points():
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        DEFINE VARIABLE spec   AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER     NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER     NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(30, 20, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        DO ON ERROR UNDO, THROW:
            NEW Outline("open 0,0 1,1"):DrawTo(?, 0, 0, 0, 1, 1, 0, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        spec = "open".
        DO i = 1 TO 65:
            spec = spec + " " + STRING(i MODULO 7) + ",0".
        END.
        DO ON ERROR UNDO, THROW:
            NEW Outline(spec):DrawTo(canvas, 0, 0, 0, 1, 1, 0, 0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
        canvas:Dispose().
        grid:Dispose().
    END METHOD.

END CLASS.
