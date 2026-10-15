/* The spark field: single pixel sparks that fly on a straight line with gravity, change colour four times over their life and go.
   Where a spark is is worked out from the time, so nothing is kept between frames. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SparkFieldTests:

    DEFINE PRIVATE VARIABLE mField  AS SparkField   NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid   AS Grid         NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildField():
        mField = NEW SparkField(3).
        mGrid = NEW Grid(NEW ArrayStore(40, 30, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mGrid:Store:FillLayer(mGrid:Store:LayerIndex("back"), 1).
        mCanvas:Restore().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseField():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        mCanvas = ?.
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
        mField = ?.
    END METHOD.

    METHOD PRIVATE VOID DrawAt(INPUT piMs AS INTEGER):
        mCanvas:Restore().
        mCanvas:BeginBatch().
        mField:Draw(mCanvas, piMs).
        mCanvas:EndBatch().
    END METHOD.

    /* a spark from (10, 10) at ten milliseconds, moving 1 pixel a frame right, no gravity, living 10 frames, the colours 101 to 104 */
    METHOD PRIVATE LOGICAL Spark1():
        RETURN mField:Add(10, 10, 1.0, 0.0, 0.0, 0, 10, 101, 102, 103, 104).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASparkFliesAtItsSpeedAFramePlusGravityAndIsDrawnAsOnePixel():
        Assert:IsTrue(Spark1()).
        /* at 100 ms it is six frames old: 6 pixels along */
        DrawAt(100).
        Assert:Equals(103, mCanvas:ColourAt(16, 10)).
        Assert:Equals(1, mCanvas:ColourAt(15, 10)).
        Assert:Equals(1, mCanvas:ColourAt(17, 10)).
        mField:Add(20, 5, 0.0, 0.0, 2.0, 0, 10, 201, 202, 203, 204).
        /* 3 frames at 50 ms: 0.5 * 2 * 9 = 9 pixels down, and a third of the way through its life so the second colour */
        DrawAt(50).
        Assert:Equals(202, mCanvas:ColourAt(20, 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheColourChangesInFourStagesOverTheLifeAndTheSparkIsGoneAtTheEnd():
        Spark1().
        DrawAt(0).
        Assert:Equals(101, mCanvas:ColourAt(10, 10)).
        /* life 10 frames = 166.7 ms: stages at 2.5, 5 and 7.5 frames */
        DrawAt(30).
        Assert:Equals(101, mCanvas:ColourAt(12, 10)).
        DrawAt(50).
        Assert:Equals(102, mCanvas:ColourAt(13, 10)).
        DrawAt(84).
        Assert:Equals(103, mCanvas:ColourAt(15, 10)).
        DrawAt(130).
        Assert:Equals(104, mCanvas:ColourAt(18, 10)).
        DrawAt(167).
        Assert:Equals(1, mCanvas:ColourAt(20, 10)).
        Assert:Equals(0, mField:CountAt(167)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASparkThatHasNotBegunYetIsNotDrawnAndFullFieldRefusesMoreUntilOnesGone():
        Assert:IsTrue(mField:Add(5, 5, 0.0, 0.0, 0.0, 500, 10, 1, 2, 3, 4)).
        Assert:IsTrue(mField:Add(6, 5, 0.0, 0.0, 0.0, 0, 6, 1, 2, 3, 4)).
        Assert:IsTrue(mField:Add(7, 5, 0.0, 0.0, 0.0, 0, 6, 1, 2, 3, 4)).
        Assert:IsFalse(mField:Add(8, 5, 0.0, 0.0, 0.0, 0, 6, 1, 2, 3, 4)).
        Assert:Equals(2, mField:CountAt(0)).
        /* after their 100 ms the two short ones are gone, and there is room again */
        Assert:Equals(0, mField:CountAt(100)).
        Assert:IsTrue(mField:Add(8, 5, 0.0, 0.0, 0.0, 100, 6, 1, 2, 3, 4)).
        Assert:Equals(1, mField:CountAt(100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearTakesEverySparkAwayAndPixelsOffTheCanvasAreSkipped():
        mField:Add(2, 2, -3.0, 0.0, 0.0, 0, 20, 7, 7, 7, 7).
        mField:Add(30, 20, 0.0, 0.0, 0.0, 0, 20, 8, 8, 8, 8).
        /* the first has flown off the left edge: nothing breaks */
        DrawAt(50).
        Assert:Equals(8, mCanvas:ColourAt(30, 20)).
        mField:Clear().
        Assert:Equals(0, mField:CountAt(0)).
        DrawAt(50).
        Assert:Equals(1, mCanvas:ColourAt(30, 20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASparkNeedsALifeOfOneFrameOrMoreAndAFieldNeedsOneSlot():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mField:Add(1, 1, 0.0, 0.0, 0.0, 0, 0, 1, 2, 3, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SparkField(0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADraggedSparkSlowsDownAndOneThatKeepsAllItsSpeedIsAsBefore():
        /* keeps half its speed a frame: after 2 frames it has gone 2 * (1 - 0.25) / 0.5 = 3 pixels, and at most 4 */
        Assert:IsTrue(mField:AddDragged(10, 10, 2.0, 0.0, 0.0, 0.5, 0, 20, 101, 102, 103, 104)).
        DrawAt(33).
        Assert:IsTrue(mCanvas:ColourAt(10 + 2, 10) <> 1 OR mCanvas:ColourAt(10 + 3, 10) <> 1).
        DrawAt(120).
        /* seven frames old: it has all but stopped at 4 pixels, in its second colour */
        Assert:Equals(102, mCanvas:ColourAt(14, 10)).
        mField:Clear().
        mField:AddDragged(10, 10, 1.0, 0.0, 0.0, 1.0, 0, 10, 101, 102, 103, 104).
        DrawAt(100).
        Assert:Equals(103, mCanvas:ColourAt(16, 10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADragOfNothingOrMoreThanOneIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mField:AddDragged(1, 1, 1.0, 0.0, 0.0, 0.0, 0, 10, 1, 2, 3, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mField:AddDragged(1, 1, 1.0, 0.0, 0.0, 1.5, 0, 10, 1, 2, 3, 4).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
