/* The canvas on a small 12 x 10 board, with the sky colour 100 and a sprite of two tones. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PixelCanvasTests:

    &SCOPED-DEFINE KIND-NONE 0
    &SCOPED-DEFINE KIND-SHIELD 1
    &SCOPED-DEFINE KIND-ALIEN 2
    &SCOPED-DEFINE KIND-BOMB 3
    &SCOPED-DEFINE KIND-SHOT 6
    &SCOPED-DEFINE KIND-FX 7

    DEFINE PRIVATE VARIABLE mGrid   AS Grid           NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mSprite AS Sprite         NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCanvas():
        mGrid = NEW Grid(NEW ArrayStore(12, 10, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        /* a 3 x 2 sprite with a hole: tone 1, tone 2 and tone 3 cells */
        mSprite = NEW Sprite("#+*/#.#").
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

    /* ---- building it ---- */

    @Test.
    METHOD PUBLIC VOID TheCanvasTakesItsSizeFromTheGrid():
        Assert:Equals(12, mCanvas:Width).
        Assert:Equals(10, mCanvas:Height).
        Assert:IsTrue(mCanvas:InBounds(0, 0)).
        Assert:IsTrue(mCanvas:InBounds(11, 9)).
        Assert:IsFalse(mCanvas:InBounds(12, 0)).
        Assert:IsFalse(mCanvas:InBounds(0, -1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCanvasRefusesAGridThatIsNotRight():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW PixelCanvas(NEW Grid(NEW ArrayStore(4, 4, "view,kind"))).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW PixelCanvas(NEW Grid(NEW TableStore(4, 4, "view,kind,back"))).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW PixelCanvas(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    /* ---- drawing and erasing ---- */

    @Test.
    METHOD PUBLIC VOID AFreshCanvasShowsItsBackgroundWithNothingOnIt():
        Assert:Equals(100, mCanvas:ColourAt(5, 5)).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(5, 5)).
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawingASpriteColoursItsCellsByToneAndGivesThemTheKind():
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        Assert:Equals(11, mCanvas:ColourAt(4, 3)).
        Assert:Equals(22, mCanvas:ColourAt(5, 3)).
        Assert:Equals(33, mCanvas:ColourAt(6, 3)).
        Assert:Equals(11, mCanvas:ColourAt(4, 4)).
        Assert:Equals(11, mCanvas:ColourAt(6, 4)).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(4, 3)).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(6, 4)).
        Assert:Equals(5, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHoleInASpriteStaysSky():
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        Assert:Equals(100, mCanvas:ColourAt(5, 4)).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(5, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ErasingASpriteBringsBackTheBackgroundAndKindZero():
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Erase(mSprite, 4, 3, {&KIND-ALIEN}).
        Assert:Equals(100, mCanvas:ColourAt(4, 3)).
        Assert:Equals(100, mCanvas:ColourAt(6, 4)).
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ErasingPutsBackTheBackgroundOfThatCellNotAFlatColour():
        mCanvas:SetBack(4, 3, 777).
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Erase(mSprite, 4, 3, {&KIND-ALIEN}).
        Assert:Equals(777, mCanvas:ColourAt(4, 3)).
        Assert:Equals(100, mCanvas:ColourAt(5, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ErasingLeavesCellsThatSomethingElseHasTakenOver():
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Plot(5, 3, {&KIND-SHOT}, 999).
        mCanvas:Erase(mSprite, 4, 3, {&KIND-ALIEN}).
        Assert:Equals(999, mCanvas:ColourAt(5, 3)).
        Assert:Equals({&KIND-SHOT}, mCanvas:KindAt(5, 3)).
        Assert:Equals(100, mCanvas:ColourAt(4, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawingOverTheEdgeOfTheBoardDrawsTheRestAndFailsOnNothing():
        mCanvas:Draw(mSprite, 10, 8, {&KIND-ALIEN}, 11, 22, 33).
        Assert:Equals(11, mCanvas:ColourAt(10, 8)).
        Assert:Equals(22, mCanvas:ColourAt(11, 8)).
        Assert:Equals(11, mCanvas:ColourAt(10, 9)).
        Assert:Equals(3, mCanvas:CountKind({&KIND-ALIEN})).
        mCanvas:Draw(mSprite, -2, -1, {&KIND-BOMB}, 1, 2, 3).
        Assert:Equals(1, mCanvas:CountKind({&KIND-BOMB})).
        mCanvas:Erase(mSprite, 10, 8, {&KIND-ALIEN}).
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawOnEmptyDoesNotPaintOverAnythingThatIsThere():
        mCanvas:Plot(5, 3, {&KIND-SHIELD}, 555).
        mCanvas:DrawOnEmpty(mSprite, 4, 3, {&KIND-FX}, 11, 22, 33).
        Assert:Equals(555, mCanvas:ColourAt(5, 3)).
        Assert:Equals({&KIND-SHIELD}, mCanvas:KindAt(5, 3)).
        Assert:Equals(11, mCanvas:ColourAt(4, 3)).
        Assert:Equals({&KIND-FX}, mCanvas:KindAt(4, 3)).
        Assert:Equals(4, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEffectCanBeErasedWithoutTouchingWhatItDidNotPaint():
        mCanvas:Plot(5, 3, {&KIND-SHIELD}, 555).
        mCanvas:DrawOnEmpty(mSprite, 4, 3, {&KIND-FX}, 11, 22, 33).
        mCanvas:Erase(mSprite, 4, 3, {&KIND-FX}).
        Assert:Equals(555, mCanvas:ColourAt(5, 3)).
        Assert:Equals(0, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    /* ---- single cells and rectangles ---- */

    @Test.
    METHOD PUBLIC VOID PlotAndUnplotWorkOnOneCellAndIgnoreTheOutside():
        mCanvas:Plot(2, 2, {&KIND-BOMB}, 321).
        Assert:Equals(321, mCanvas:ColourAt(2, 2)).
        Assert:Equals({&KIND-BOMB}, mCanvas:KindAt(2, 2)).
        mCanvas:Unplot(2, 2).
        Assert:Equals(100, mCanvas:ColourAt(2, 2)).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(2, 2)).
        mCanvas:Plot(20, 2, {&KIND-BOMB}, 1).
        mCanvas:Unplot(-1, 2).
        Assert:Equals(0, mCanvas:CountKind({&KIND-BOMB})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellOutsideTheBoardIsEmptySpaceWithNoColour():
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(-1, 0)).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(12, 0)).
        Assert:Equals(-1, mCanvas:ColourAt(0, 10)).
        Assert:Equals(-1, mCanvas:BackAt(-5, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearRectEmptiesARectangleAndClipsItToTheBoard():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO 9:
            DO x = 0 TO 11:
                mCanvas:Plot(x, y, {&KIND-SHIELD}, 5).
            END.
        END.
        mCanvas:ClearRect(10, 8, 6, 6).
        Assert:Equals(120 - 4, mCanvas:CountKind({&KIND-SHIELD})).
        Assert:Equals(100, mCanvas:ColourAt(11, 9)).
        Assert:Equals(5, mCanvas:ColourAt(9, 9)).
        mCanvas:ClearRect(-3, -3, 5, 5).
        Assert:Equals(120 - 4 - 4, mCanvas:CountKind({&KIND-SHIELD})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DimScalesEveryShowingColourButNotTheKindsOrTheBackground():
        mCanvas:Plot(2, 3, {&KIND-SHOT}, ColourMath:Rgb(200, 100, 40)).
        mCanvas:Dim(50).
        Assert:Equals(ColourMath:Rgb(100, 50, 20), mCanvas:ColourAt(2, 3)).
        Assert:Equals({&KIND-SHOT}, mCanvas:KindAt(2, 3)).
        /* the sky was colour 100: blue 100 becomes 50 */
        Assert:Equals(50, mCanvas:ColourAt(7, 7)).
        Assert:Equals(100, mCanvas:BackAt(7, 7)).
        /* Restore puts the picture back */
        mCanvas:Restore().
        Assert:Equals(100, mCanvas:ColourAt(7, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DimRectMovesOnlyThePixelsInsideTheRectangleTowardsTheColourAndSkipsWhatIsOffTheBoard():
        mCanvas:Plot(2, 3, {&KIND-SHOT}, ColourMath:Rgb(200, 100, 40)).
        mCanvas:Plot(9, 9, {&KIND-SHOT}, ColourMath:Rgb(200, 100, 40)).
        mCanvas:DimRect(-5, 0, 8, 6, 50, 0).
        Assert:Equals(ColourMath:Rgb(100, 50, 20), mCanvas:ColourAt(2, 3)).
        Assert:Equals({&KIND-SHOT}, mCanvas:KindAt(2, 3)).
        Assert:Equals(ColourMath:Rgb(200, 100, 40), mCanvas:ColourAt(9, 9)).
        Assert:Equals(100, mCanvas:BackAt(2, 3)).
        mCanvas:Restore().
        Assert:Equals(100, mCanvas:ColourAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BakeViewMakesWhatIsShowingTheNewBackgroundSoRestoreKeepsIt():
        mCanvas:Plot(3, 4, {&KIND-SHOT}, 777).
        mCanvas:BakeView().
        Assert:Equals(777, mCanvas:BackAt(3, 4)).
        Assert:Equals(100, mCanvas:BackAt(4, 4)).
        mCanvas:Plot(5, 5, {&KIND-SHOT}, 888).
        mCanvas:Restore().
        Assert:Equals(777, mCanvas:ColourAt(3, 4)).
        /* what was plotted after the bake is gone, and so is the kind of what was baked */
        Assert:Equals(100, mCanvas:ColourAt(5, 5)).
        Assert:Equals(0, mCanvas:KindAt(3, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LoadBackCopiesTheBackgroundOfAnotherCanvasOfTheSameSize():
        DEFINE VARIABLE grid2   AS Grid        NO-UNDO.
        DEFINE VARIABLE other   AS PixelCanvas NO-UNDO.
        DEFINE VARIABLE thrown  AS INTEGER     NO-UNDO.
        DEFINE VARIABLE small1  AS Grid        NO-UNDO.
        DEFINE VARIABLE canvas3 AS PixelCanvas NO-UNDO.
        DO ON ERROR UNDO, THROW:
            grid2 = NEW Grid(NEW ArrayStore(12, 10, "view,kind,back")).
            other = NEW PixelCanvas(grid2).
            other:SetBack(2, 2, 555).
            other:SetBack(11, 9, 666).
            mCanvas:LoadBack(other).
            Assert:Equals(555, mCanvas:BackAt(2, 2)).
            Assert:Equals(666, mCanvas:BackAt(11, 9)).
            /* the view is not touched until Restore */
            Assert:Equals(100, mCanvas:ColourAt(2, 2)).
            mCanvas:Restore().
            Assert:Equals(555, mCanvas:ColourAt(2, 2)).
            small1 = NEW Grid(NEW ArrayStore(5, 5, "view,kind,back")).
            canvas3 = NEW PixelCanvas(small1).
            DO ON ERROR UNDO, THROW:
                mCanvas:LoadBack(canvas3).
                CATCH e1 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
            Assert:Equals(1, thrown).
            FINALLY:
                IF VALID-OBJECT(other) THEN other:Dispose().
                IF VALID-OBJECT(canvas3) THEN canvas3:Dispose().
                IF VALID-OBJECT(grid2) THEN grid2:Dispose().
                IF VALID-OBJECT(small1) THEN small1:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the background ---- */

    @Test.
    METHOD PUBLIC VOID SetBackChangesTheBackgroundButNotWhatIsShowing():
        mCanvas:SetBack(3, 3, 888).
        Assert:Equals(888, mCanvas:BackAt(3, 3)).
        Assert:Equals(100, mCanvas:ColourAt(3, 3)).
        mCanvas:SetBack(30, 3, 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetBackRowsGivesEachRowItsOwnColourAndRestoreShowsThem():
        DEFINE VARIABLE colours AS INTEGER NO-UNDO EXTENT 10.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DO y = 1 TO 10:
            colours[y] = y * 10.
        END.
        mCanvas:SetBackRows(colours).
        Assert:Equals(30, mCanvas:BackAt(7, 2)).
        Assert:Equals(100, mCanvas:ColourAt(7, 2)).
        mCanvas:Restore().
        Assert:Equals(30, mCanvas:ColourAt(7, 2)).
        Assert:Equals(100, mCanvas:ColourAt(0, 9)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetBackRowsNeedsOneColourForEachRow():
        DEFINE VARIABLE colours AS INTEGER NO-UNDO EXTENT 4.
        DEFINE VARIABLE thrown  AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mCanvas:SetBackRows(colours).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestoreClearsEverythingBackToTheBackground():
        mCanvas:Draw(mSprite, 4, 3, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Plot(0, 0, {&KIND-SHIELD}, 5).
        mCanvas:SetBack(8, 8, 66).
        mCanvas:Restore().
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
        Assert:Equals(0, mCanvas:CountKind({&KIND-SHIELD})).
        Assert:Equals(100, mCanvas:ColourAt(4, 3)).
        Assert:Equals(100, mCanvas:ColourAt(0, 0)).
        Assert:Equals(66, mCanvas:ColourAt(8, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestoreCanBeCalledAgainAndAgain():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 5:
            mCanvas:Draw(mSprite, 1, 1, {&KIND-ALIEN}, 11, 22, 33).
            mCanvas:Restore().
        END.
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    /* ---- text ---- */

    @Test.
    METHOD PUBLIC VOID TextIsDrawnInTheFontInOneColour():
        /* the letter I: a bar across the top and the bottom and a stem down the middle, 5 cells wide */
        mCanvas:DrawText("I", 2, 1, 4000).
        Assert:Equals(4000, mCanvas:ColourAt(3, 1)).
        Assert:Equals(4000, mCanvas:ColourAt(4, 1)).
        Assert:Equals(4000, mCanvas:ColourAt(5, 1)).
        Assert:Equals(100, mCanvas:ColourAt(2, 1)).
        Assert:Equals(4000, mCanvas:ColourAt(4, 4)).
        Assert:Equals(100, mCanvas:ColourAt(3, 4)).
        Assert:Equals(4000, mCanvas:ColourAt(3, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextLeavesTheKindAloneSoItNeverBlocksAShot():
        mCanvas:DrawText("I", 2, 1, 4000).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSecondLetterStartsSixCellsAlong():
        mCanvas:DrawText("II", 0, 0, 4000).
        Assert:Equals(4000, mCanvas:ColourAt(1, 0)).
        Assert:Equals(4000, mCanvas:ColourAt(7, 0)).
        Assert:Equals(100, mCanvas:ColourAt(5, 0)).
        Assert:Equals(100, mCanvas:ColourAt(6, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextOffTheBoardIsClippedAndEmptyTextDoesNothing():
        mCanvas:DrawText("II", 9, 8, 4000).
        mCanvas:DrawText("", 0, 0, 4000).
        mCanvas:DrawText(?, 0, 0, 4000).
        Assert:Equals(4000, mCanvas:ColourAt(11, 8)).
        Assert:Equals(100, mCanvas:ColourAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextIsTakenOffWithClearRect():
        mCanvas:DrawText("I", 2, 1, 4000).
        mCanvas:ClearRect(2, 1, 5, 7).
        Assert:Equals(100, mCanvas:ColourAt(4, 1)).
        Assert:Equals(100, mCanvas:ColourAt(4, 4)).
    END METHOD.

    /* ---- showing the background again ---- */

    @Test.
    METHOD PUBLIC VOID ShowBackBringsTheBackgroundUpOnAnEmptyCellOnly():
        mCanvas:SetBack(3, 3, 888).
        mCanvas:SetBack(4, 3, 999).
        mCanvas:Plot(4, 3, {&KIND-ALIEN}, 5).
        mCanvas:ShowBack(3, 3).
        mCanvas:ShowBack(4, 3).
        mCanvas:ShowBack(40, 3).
        Assert:Equals(888, mCanvas:ColourAt(3, 3)).
        Assert:Equals(5, mCanvas:ColourAt(4, 3)).
    END METHOD.

    /* ---- big text ---- */

    @Test.
    METHOD PUBLIC VOID BigTextMakesEachFontCellABlock():
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        DEFINE VARIABLE grid   AS Grid           NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(40, 30, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        DO ON ERROR UNDO, THROW:
            canvas:DrawTextScaled("I", 1, 1, 4000, 4000, 2).
            /* the top bar of the I is cells 1 to 3 of row 0 of the font, so columns 3 to 8 of rows 1 and 2 */
            Assert:Equals(4000, canvas:ColourAt(3, 1)).
            Assert:Equals(4000, canvas:ColourAt(8, 2)).
            Assert:Equals(0, canvas:ColourAt(2, 1)).
            Assert:Equals(0, canvas:ColourAt(9, 1)).
            /* the stem is font column 2, so columns 5 and 6, and the foot is at font row 6, rows 13 and 14 */
            Assert:Equals(4000, canvas:ColourAt(5, 8)).
            Assert:Equals(4000, canvas:ColourAt(6, 9)).
            Assert:Equals(4000, canvas:ColourAt(3, 14)).
            Assert:Equals(0, canvas:ColourAt(3, 15)).
            FINALLY:
                canvas:Dispose().
                grid:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BigTextShadesFromTheTopColourToTheBottomColour():
        DEFINE VARIABLE canvas AS PixelCanvas NO-UNDO.
        DEFINE VARIABLE grid   AS Grid           NO-UNDO.
        grid = NEW Grid(NEW ArrayStore(20, 20, "view,kind,back")).
        canvas = NEW PixelCanvas(grid).
        DO ON ERROR UNDO, THROW:
            /* the colours mix part by part (red, green, blue), so halfway from black to 60, 120, 180 is 30, 60, 90 */
            canvas:DrawTextScaled("I", 0, 0, 0, ColourMath:Rgb(60, 120, 180), 1).
            Assert:Equals(0, canvas:ColourAt(2, 0)).
            Assert:Equals(ColourMath:Rgb(60, 120, 180), canvas:ColourAt(2, 6)).
            Assert:Equals(ColourMath:Rgb(30, 60, 90), canvas:ColourAt(2, 3)).
            FINALLY:
                canvas:Dispose().
                grid:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWidthOfBigTextIsTheWidthOfTheTextTimesTheScale():
        Assert:Equals(0, PixelCanvas:ScaledWidth("", 3)).
        Assert:Equals(15, PixelCanvas:ScaledWidth("A", 3)).
        Assert:Equals(33, PixelCanvas:ScaledWidth("AB", 3)).
        Assert:Equals(11, PixelCanvas:ScaledWidth("AB", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BigTextOffTheBoardIsClipped():
        mCanvas:DrawTextScaled("II", 8, 6, 4000, 4000, 3).
        mCanvas:DrawTextScaled("", 0, 0, 1, 1, 2).
        Assert:Equals(4000, mCanvas:ColourAt(11, 6)).
    END METHOD.

    /* ---- the memory ---- */

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledMoreThanOnceAndTheCanvasStillWorksAfterIt():
        mCanvas:Dispose().
        mCanvas:Dispose().
        mCanvas:Draw(mSprite, 1, 1, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Restore().
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    /* ---- overlay text: over a picture that has things in it ---- */

    @Test.
    METHOD PUBLIC VOID OverlayTextWritesOnEmptyCellsWithAnEdgeAroundTheLetters():
        DEFINE VARIABLE lit  AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        mCanvas:DrawOverlay("I", 3, 1, 4000, 4000, 1, 7000).
        DO y = 0 TO 9:
            DO x = 0 TO 11:
                IF mCanvas:ColourAt(x, y) = 4000 THEN lit = lit + 1.
                IF mCanvas:ColourAt(x, y) = 7000 THEN edge = edge + 1.
            END.
        END.
        Assert:IsTrue(lit > 8).
        Assert:IsTrue(edge > lit).
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OverlayTextLeavesWhateverIsInACellAlone():
        mCanvas:Plot(5, 4, {&KIND-ALIEN}, 555).
        mCanvas:Plot(4, 3, {&KIND-SHIELD}, 666).
        mCanvas:DrawOverlay("I", 3, 1, 4000, 4000, 1, 7000).
        Assert:Equals(555, mCanvas:ColourAt(5, 4)).
        Assert:Equals(666, mCanvas:ColourAt(4, 3)).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(5, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNoEdgeOnlyTheLettersAreWritten():
        DEFINE VARIABLE edge AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        mCanvas:DrawOverlay("I", 3, 1, 4000, 4000, 1, -1).
        DO y = 0 TO 9:
            DO x = 0 TO 11:
                IF mCanvas:ColourAt(x, y) = 7000 THEN edge = edge + 1.
            END.
        END.
        Assert:Equals(0, edge).
        Assert:IsTrue(mCanvas:ColourAt(5, 1) = 4000 OR mCanvas:ColourAt(4, 1) = 4000).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowBackRectTakesOverlayTextOffButLeavesPicturesAlone():
        mCanvas:Plot(5, 4, {&KIND-ALIEN}, 555).
        mCanvas:DrawOverlay("I", 3, 1, 4000, 4000, 1, 7000).
        mCanvas:ShowBackRect(0, 0, 12, 10).
        Assert:Equals(100, mCanvas:ColourAt(4, 1)).
        Assert:Equals(100, mCanvas:ColourAt(2, 0)).
        Assert:Equals(555, mCanvas:ColourAt(5, 4)).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(5, 4)).
        mCanvas:ShowBackRect(-5, -5, 100, 100).
    END METHOD.

    /* ---- lines ---- */

    @Test.
    METHOD PUBLIC VOID AHorizontalLineColoursEveryCellFromEndToEnd():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        mCanvas:DrawLine(1, 2, 6, 2, {&KIND-FX}, 777).
        DO x = 1 TO 6:
            Assert:Equals(777, mCanvas:ColourAt(x, 2)).
            Assert:Equals({&KIND-FX}, mCanvas:KindAt(x, 2)).
        END.
        Assert:Equals(100, mCanvas:ColourAt(0, 2)).
        Assert:Equals(100, mCanvas:ColourAt(7, 2)).
        Assert:Equals(6, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADiagonalLineStepsOneCellAcrossAndOneDown():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mCanvas:DrawLine(2, 1, 6, 5, {&KIND-FX}, 777).
        DO i = 0 TO 4:
            Assert:Equals(777, mCanvas:ColourAt(2 + i, 1 + i)).
        END.
        Assert:Equals(5, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineGoingEitherWayTouchesBothEndsAndTheSameNumberOfCells():
        mCanvas:DrawLine(1, 1, 9, 4, {&KIND-FX}, 777).
        Assert:Equals(777, mCanvas:ColourAt(1, 1)).
        Assert:Equals(777, mCanvas:ColourAt(9, 4)).
        Assert:Equals(9, mCanvas:CountKind({&KIND-FX})).
        mCanvas:Restore().
        mCanvas:DrawLine(9, 4, 1, 1, {&KIND-FX}, 777).
        Assert:Equals(777, mCanvas:ColourAt(1, 1)).
        Assert:Equals(777, mCanvas:ColourAt(9, 4)).
        Assert:Equals(9, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShallowLineHasOneCellInEveryColumnAndASteepOneOneInEveryRow():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE found AS INTEGER NO-UNDO.
        mCanvas:DrawLine(0, 0, 10, 3, {&KIND-FX}, 777).
        DO x = 0 TO 10:
            found = 0.
            DO y = 0 TO 9:
                IF mCanvas:KindAt(x, y) = {&KIND-FX} THEN found = found + 1.
            END.
            Assert:Equals(1, found).
        END.
        mCanvas:Restore().
        mCanvas:DrawLine(0, 0, 3, 9, {&KIND-FX}, 777).
        DO y = 0 TO 9:
            found = 0.
            DO x = 0 TO 11:
                IF mCanvas:KindAt(x, y) = {&KIND-FX} THEN found = found + 1.
            END.
            Assert:Equals(1, found).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineWithTheSameEndsIsOneCell():
        mCanvas:DrawLine(4, 4, 4, 4, {&KIND-FX}, 777).
        Assert:Equals(1, mCanvas:CountKind({&KIND-FX})).
        Assert:Equals(777, mCanvas:ColourAt(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineThatRunsOffTheBoardIsClippedWithoutAnError():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        mCanvas:DrawLine(-5, 3, 30, 3, {&KIND-FX}, 777).
        DO x = 0 TO 11:
            Assert:Equals(777, mCanvas:ColourAt(x, 3)).
        END.
        Assert:Equals(12, mCanvas:CountKind({&KIND-FX})).
        mCanvas:DrawLine(-40, -40, -2, -2, {&KIND-FX}, 777).
        mCanvas:DrawLine(100, 5, 200, 9, {&KIND-FX}, 777).
        Assert:Equals(12, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineThatComesInFromOutsideDrawsTheRightCells():
        mCanvas:DrawLine(-3, -3, 3, 3, {&KIND-FX}, 777).
        Assert:Equals(777, mCanvas:ColourAt(0, 0)).
        Assert:Equals(777, mCanvas:ColourAt(3, 3)).
        Assert:Equals(4, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    /* ---- batches of lines ---- */

    METHOD PRIVATE LOGICAL Refused(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN mCanvas:BeginBatch().
                WHEN 2 THEN mCanvas:EndBatch().
                WHEN 3 THEN mCanvas:Plot(1, 1, {&KIND-FX}, 5).
                WHEN 4 THEN mCanvas:Unplot(1, 1).
                WHEN 5 THEN mCanvas:Erase(mSprite, 0, 0, {&KIND-ALIEN}).
                WHEN 6 THEN mCanvas:Draw(mSprite, 0, 0, {&KIND-ALIEN}, 1, 2, 3).
                WHEN 7 THEN mCanvas:DrawText("I", 0, 0, 5).
                WHEN 8 THEN mCanvas:ClearRect(0, 0, 3, 3).
                WHEN 9 THEN mCanvas:ShowBackRect(0, 0, 3, 3).
                WHEN 10 THEN mCanvas:SetBack(1, 1, 5).
                WHEN 11 THEN mCanvas:DrawOverlay("I", 0, 0, 1, 1, 1, -1).
                WHEN 12 THEN mCanvas:DrawTextScaled("I", 0, 0, 1, 1, 1).
            END CASE.
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LinesInABatchShowOnlyWhenTheBatchEnds():
        mCanvas:BeginBatch().
        mCanvas:DrawLine(1, 2, 6, 2, {&KIND-FX}, 777).
        Assert:Equals(100, mCanvas:ColourAt(3, 2)).
        mCanvas:EndBatch().
        Assert:Equals(777, mCanvas:ColourAt(1, 2)).
        Assert:Equals(777, mCanvas:ColourAt(6, 2)).
        Assert:Equals({&KIND-FX}, mCanvas:KindAt(3, 2)).
        Assert:Equals(100, mCanvas:ColourAt(7, 2)).
        Assert:Equals(6, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABatchKeepsWhatWasOnTheBoardAndClipsAtTheEdges():
        mCanvas:Plot(9, 9, {&KIND-ALIEN}, 555).
        mCanvas:BeginBatch().
        mCanvas:DrawLine(-5, 3, 30, 3, {&KIND-FX}, 777).
        mCanvas:DrawLine(100, 100, 200, 200, {&KIND-FX}, 777).
        mCanvas:EndBatch().
        Assert:Equals(555, mCanvas:ColourAt(9, 9)).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(9, 9)).
        Assert:Equals(12, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABatchGivesTheSameCellsAsLinesOutsideOne():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE alike AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE viaStore AS INTEGER NO-UNDO EXTENT 120.
        mCanvas:DrawLine(0, 0, 11, 9, {&KIND-FX}, 777).
        mCanvas:DrawLine(11, 0, 0, 7, {&KIND-BOMB}, 888).
        DO y = 0 TO 9:
            DO x = 0 TO 11:
                viaStore[y * 12 + x + 1] = mCanvas:ColourAt(x, y) * 10 + mCanvas:KindAt(x, y).
            END.
        END.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        mCanvas:DrawLine(0, 0, 11, 9, {&KIND-FX}, 777).
        mCanvas:DrawLine(11, 0, 0, 7, {&KIND-BOMB}, 888).
        mCanvas:EndBatch().
        DO y = 0 TO 9:
            DO x = 0 TO 11:
                IF viaStore[y * 12 + x + 1] <> mCanvas:ColourAt(x, y) * 10 + mCanvas:KindAt(x, y) THEN alike = FALSE.
            END.
        END.
        Assert:IsTrue(alike).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestoreInsideABatchClearsTheBatchPicture():
        mCanvas:BeginBatch().
        mCanvas:DrawLine(1, 2, 6, 2, {&KIND-FX}, 777).
        mCanvas:Restore().
        mCanvas:DrawLine(1, 5, 6, 5, {&KIND-FX}, 777).
        mCanvas:EndBatch().
        Assert:Equals(100, mCanvas:ColourAt(3, 2)).
        Assert:Equals(777, mCanvas:ColourAt(3, 5)).
        Assert:Equals(6, mCanvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABatchCanBeRunAgainAndAgain():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 5:
            mCanvas:Restore().
            mCanvas:BeginBatch().
            mCanvas:DrawLine(0, i, 11, i, {&KIND-FX}, 777).
            mCanvas:EndBatch().
            Assert:Equals(12, mCanvas:CountKind({&KIND-FX})).
            Assert:Equals(777, mCanvas:ColourAt(5, i)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBatchRulesAreEnforcedSoAHalfDrawnPictureCannotBeLost():
        Assert:IsTrue(Refused(2)).
        mCanvas:BeginBatch().
        Assert:IsTrue(Refused(1)).
        Assert:IsTrue(Refused(3)).
        Assert:IsTrue(Refused(4)).
        Assert:IsTrue(Refused(5)).
        Assert:IsTrue(Refused(6)).
        Assert:IsTrue(Refused(7)).
        Assert:IsTrue(Refused(8)).
        Assert:IsTrue(Refused(9)).
        Assert:IsTrue(Refused(10)).
        Assert:IsTrue(Refused(11)).
        Assert:IsTrue(Refused(12)).
        mCanvas:EndBatch().
        Assert:IsFalse(Refused(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PutCellsColoursAListOfCellsFromAPlaceAndSkipsWhatIsOffTheBoard():
        DEFINE VARIABLE cells  AS MEMPTR NO-UNDO.
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        SET-SIZE(cells) = 36.
        PUT-LONG(cells, 1) = 0.
        PUT-LONG(cells, 5) = 0.
        PUT-LONG(cells, 9) = 501.
        PUT-LONG(cells, 13) = 2.
        PUT-LONG(cells, 17) = 1.
        PUT-LONG(cells, 21) = 502.
        PUT-LONG(cells, 25) = 50.
        PUT-LONG(cells, 29) = 50.
        PUT-LONG(cells, 33) = 503.
        mCanvas:PutCells(cells, 3, 3, 4).
        Assert:Equals(501, mCanvas:ColourAt(3, 4)).
        Assert:Equals(502, mCanvas:ColourAt(5, 5)).
        Assert:Equals(100, mCanvas:ColourAt(4, 4)).
        /* the kind is not touched */
        mCanvas:Plot(3, 4, {&KIND-ALIEN}, 9).
        mCanvas:PutCells(cells, 3, 3, 4).
        Assert:Equals({&KIND-ALIEN}, mCanvas:KindAt(3, 4)).
        /* in a batch it shows when the batch ends */
        mCanvas:Restore().
        mCanvas:BeginBatch().
        mCanvas:PutCells(cells, 3, 3, 4).
        Assert:Equals(100, mCanvas:ColourAt(3, 4)).
        mCanvas:EndBatch().
        Assert:Equals(501, mCanvas:ColourAt(3, 4)).
        /* a list that says it is longer than the memory it has is refused */
        DO ON ERROR UNDO, THROW:
            mCanvas:PutCells(cells, 4, 0, 0).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        SET-SIZE(cells) = 0.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineOfKindZeroStillColoursItsCellsAndLeavesTheBackgroundAlone():
        mCanvas:DrawLine(1, 1, 5, 1, {&KIND-NONE}, 777).
        Assert:Equals(777, mCanvas:ColourAt(3, 1)).
        Assert:Equals(100, mCanvas:BackAt(3, 1)).
        Assert:Equals({&KIND-NONE}, mCanvas:KindAt(3, 1)).
    END METHOD.

END CLASS.
