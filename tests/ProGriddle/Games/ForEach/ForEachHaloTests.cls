/* The glow round a character: one pixel round the shape of the picture, up, down, left and right of its pixels, and only drawn on the three
   floor colours it is given. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachHaloTests:

    VAR PRIVATE Grid mGrid.
    VAR PRIVATE PixelCanvas mCanvas.

    @Setup.
    METHOD PUBLIC VOID BuildCanvas():
        mGrid = NEW Grid(NEW ArrayStore(16, 16, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mCanvas:BeginBatch().
        mCanvas:FillRect(0, 0, 16, 16, 0, 1000).
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCanvas():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException():
        VAR ForEachHalo halo.
        DO ON ERROR UNDO, THROW:
            halo = NEW ForEachHalo(?).
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHaloNeedsAPicture():
        Assert:IsTrue(ThrowsGridException()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APixelAloneHasFourNeighboursAndASquareOfFourHasEight():
        Assert:Equals(4, NEW ForEachHalo(NEW Tile("1")):Count).
        Assert:Equals(8, NEW ForEachHalo(NEW Tile("11/11")):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APictureWithAHoleGetsTheGlowInsideItToo():
        /* a ring of eight pixels round one empty one: the empty one is next to four pixels, and there are 12 more outside (3 a side) */
        Assert:Equals(12 + 1, NEW ForEachHalo(NEW Tile("111/1.1/111")):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGlowIsDrawnOnTheFloorColoursOnlyAndNeverOnAnythingElse():
        VAR ForEachHalo halo = NEW ForEachHalo(NEW Tile("1")).
        halo:DrawTo(mCanvas, 5, 5, 77, 1000, 1001, 1002).
        Assert:Equals(77, mCanvas:ColourAt(5, 4)).
        Assert:Equals(77, mCanvas:ColourAt(4, 5)).
        Assert:Equals(77, mCanvas:ColourAt(6, 5)).
        Assert:Equals(77, mCanvas:ColourAt(5, 6)).
        /* the pixel itself and the corners are left alone */
        Assert:Equals(1000, mCanvas:ColourAt(5, 5)).
        Assert:Equals(1000, mCanvas:ColourAt(4, 4)).
        /* where the background is not a floor colour, nothing is drawn */
        mCanvas:Restore().
        halo:DrawTo(mCanvas, 5, 5, 77, 9, 9, 9).
        Assert:Equals(1000, mCanvas:ColourAt(5, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGlowCanGoOffTheEdgeOfTheCanvasWithoutHarm():
        NEW ForEachHalo(NEW Tile("111/111")):DrawTo(mCanvas, -1, -1, 77, 1000, 1000, 1000).
        NEW ForEachHalo(NEW Tile("111/111")):DrawTo(mCanvas, 15, 15, 77, 1000, 1000, 1000).
        Assert:IsTrue(TRUE).
    END METHOD.

END CLASS.
