/* The text stamp: a piece of text, with its edge, worked out once and copied onto the canvas whenever it is wanted. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TextStampTests:

    DEFINE PRIVATE VARIABLE mGrid   AS Grid        NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCanvas():
        mGrid = NEW Grid(NEW ArrayStore(60, 30, "view,kind,back")).
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

    METHOD PRIVATE INTEGER Count(INPUT piColour AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO 29:
            DO x = 0 TO 59:
                IF mCanvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* How many cells of the font a letter is made of. */
    METHOD PRIVATE INTEGER Lit(INPUT pcLetter AS CHARACTER):
        DEFINE VARIABLE glyph AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER   NO-UNDO.
        glyph = PixelFont:Glyph(pcLetter).
        DO i = 1 TO LENGTH(glyph):
            IF SUBSTRING(glyph, i, 1) = "#" THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN s = NEW TextStamp("", 1, 1, 1, -1).
                WHEN 2 THEN s = NEW TextStamp(?, 1, 1, 1, -1).
                WHEN 3 THEN s = NEW TextStamp("A", 0, 1, 1, -1).
                WHEN 4 THEN NEW TextStamp("A", 1, 1, 1, -1):DrawTo(?, 0, 0).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALetterIsItsFontCellsAtItsScaleAndTheSizeIsTheTextsSize():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 700, 700, -1).
        Assert:Equals(5, s:Width).
        Assert:Equals(7, s:Height).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(Lit("I"), Count(700)).
        Assert:Equals(Lit("I"), s:Count).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABiggerScaleMakesEachCellABlockAndTheTextWiderAndTaller():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 2, 700, 700, -1).
        Assert:Equals(10, s:Width).
        Assert:Equals(14, s:Height).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(Lit("I") * 4, Count(700)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextIsWideEnoughForEveryLetterAndTheGapsBetweenThem():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("AB C", 1, 1, 1, -1).
        Assert:Equals(PixelFont:WidthOf("AB C"), s:Width).
        s:Dispose().
        s = NEW TextStamp("AB", 3, 1, 1, -1).
        Assert:Equals(PixelFont:WidthOf("AB") * 3, s:Width).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEdgeIsAOneCellRingRoundTheLettersInItsOwnColour():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 700, 700, 800).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(Lit("I"), Count(700)).
        Assert:IsTrue(Count(800) > Lit("I")).
        /* the cell above the top bar of the I is edge, and the one two above is nothing */
        Assert:Equals(800, mCanvas:ColourAt(12, 4)).
        Assert:Equals(100, mCanvas:ColourAt(12, 3)).
        /* the letter itself is never covered by its own edge */
        Assert:Equals(700, mCanvas:ColourAt(12, 5)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNoEdgeNothingIsDrawnAroundTheLetters():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 700, 700, -1).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(100, mCanvas:ColourAt(12, 4)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheColourGoesFromTheTopRowToTheBottomRowOfTheLetters():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 0, 255, -1).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(0, mCanvas:ColourAt(12, 5)).
        Assert:Equals(255, mCanvas:ColourAt(12, 11)).
        Assert:IsTrue(mCanvas:ColourAt(12, 8) > 0 AND mCanvas:ColourAt(12, 8) < 255).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStampCanBeDrawnManyTimesAndAnywhereAndIsClippedAtTheEdges():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 700, 700, -1).
        s:DrawTo(mCanvas, 0, 0).
        s:DrawTo(mCanvas, 30, 10).
        Assert:Equals(Lit("I") * 2, Count(700)).
        s:DrawTo(mCanvas, 57, 28).
        s:DrawTo(mCanvas, -3, -3).
        s:DrawTo(mCanvas, 200, 200).
        Assert:IsTrue(Count(700) > Lit("I") * 2).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStampInABatchShowsWhenTheBatchEnds():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("I", 1, 700, 700, -1).
        mCanvas:BeginBatch().
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(0, Count(700)).
        mCanvas:EndBatch().
        Assert:Equals(Lit("I"), Count(700)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpaceIsEmptyAndTextWithOnlySpacesStillHasASize():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("   ", 1, 700, 700, -1).
        Assert:Equals(0, s:Count).
        Assert:Equals(PixelFont:WidthOf("   "), s:Width).
        s:DrawTo(mCanvas, 10, 5).
        Assert:Equals(0, Count(700)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeIsSafeToCallTwiceAndNoTextNoScaleOrNoCanvasIsRefused():
        DEFINE VARIABLE s AS TextStamp NO-UNDO.
        s = NEW TextStamp("A", 1, 1, 1, -1).
        s:Dispose().
        s:Dispose().
        Assert:IsTrue(Refused(1)).
        Assert:IsTrue(Refused(2)).
        Assert:IsTrue(Refused(3)).
        Assert:IsTrue(Refused(4)).
    END METHOD.

END CLASS.
