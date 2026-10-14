/* A pixel stamp: a picture worked out once as a list of coloured cells and copied onto a canvas when it is wanted. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PixelStampTests:

    DEFINE PRIVATE VARIABLE mGrid   AS Grid        NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCanvas():
        mGrid = NEW Grid(NEW ArrayStore(20, 12, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mGrid:Store:FillLayer(mGrid:Store:LayerIndex("back"), 100).
        mCanvas:Restore().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCanvas():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        mCanvas = ?.
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
    END METHOD.

    METHOD PRIVATE PixelStamp Stamp():
        DEFINE VARIABLE colours AS INTEGER NO-UNDO EXTENT 6.
        /* 3 wide, 2 high: red, nothing, blue / nothing, green, white */
        colours[1] = 10. colours[2] = -1. colours[3] = 20.
        colours[4] = -1. colours[5] = 30. colours[6] = 40.
        RETURN NEW PixelStamp(3, 2, colours).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStampKnowsItsSizeItsCountAndEachPixel():
        DEFINE VARIABLE s AS PixelStamp NO-UNDO.
        s = Stamp().
        Assert:Equals(3, s:Width).
        Assert:Equals(2, s:Height).
        Assert:Equals(4, s:Count).
        Assert:Equals(10, s:ColourAt(0, 0)).
        Assert:Equals(-1, s:ColourAt(1, 0)).
        Assert:Equals(40, s:ColourAt(2, 1)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawToCopiesTheColouredPixelsAndLeavesTheRestAlone():
        DEFINE VARIABLE s AS PixelStamp NO-UNDO.
        s = Stamp().
        s:DrawTo(mCanvas, 5, 4).
        Assert:Equals(10, mCanvas:ColourAt(5, 4)).
        Assert:Equals(100, mCanvas:ColourAt(6, 4)).
        Assert:Equals(20, mCanvas:ColourAt(7, 4)).
        Assert:Equals(100, mCanvas:ColourAt(5, 5)).
        Assert:Equals(30, mCanvas:ColourAt(6, 5)).
        Assert:Equals(40, mCanvas:ColourAt(7, 5)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawToWorksInABatchAndClipsAtTheEdges():
        DEFINE VARIABLE s AS PixelStamp NO-UNDO.
        s = Stamp().
        mCanvas:BeginBatch().
        s:DrawTo(mCanvas, 0, 0).
        s:DrawTo(mCanvas, 18, 11).
        mCanvas:EndBatch().
        Assert:Equals(10, mCanvas:ColourAt(0, 0)).
        Assert:Equals(10, mCanvas:ColourAt(18, 11)).
        /* the stamp at the corner has a gap at its second pixel, and the rest is off the canvas */
        Assert:Equals(100, mCanvas:ColourAt(19, 11)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADisposedStampCannotBeDrawnAndDisposeCanBeRepeated():
        DEFINE VARIABLE s      AS PixelStamp NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER    NO-UNDO.
        s = Stamp().
        s:Dispose().
        s:Dispose().
        DO ON ERROR UNDO, THROW:
            s:DrawTo(mCanvas, 0, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStampRefusesASizeThatDoesNotMatchItsColours():
        DEFINE VARIABLE colours AS INTEGER NO-UNDO EXTENT 3.
        DEFINE VARIABLE thrown  AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW PixelStamp(2, 2, colours).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW PixelStamp(0, 1, colours).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
