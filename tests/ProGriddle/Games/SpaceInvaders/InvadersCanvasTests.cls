/* The canvas on a small 12 x 10 board, with the sky colour 100 and a sprite of two tones. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersCanvasTests:

    {ProGriddle/Games/SpaceInvaders/Kinds.i}

    DEFINE PRIVATE VARIABLE mGrid   AS Grid           NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS InvadersCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mSprite AS Sprite         NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCanvas():
        mGrid = NEW Grid(NEW ArrayStore(12, 10, "view,kind,back")).
        mCanvas = NEW InvadersCanvas(mGrid).
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
            NEW InvadersCanvas(NEW Grid(NEW ArrayStore(4, 4, "view,kind"))).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW InvadersCanvas(NEW Grid(NEW TableStore(4, 4, "view,kind,back"))).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW InvadersCanvas(?).
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

    /* ---- the memory ---- */

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledMoreThanOnceAndTheCanvasStillWorksAfterIt():
        mCanvas:Dispose().
        mCanvas:Dispose().
        mCanvas:Draw(mSprite, 1, 1, {&KIND-ALIEN}, 11, 22, 33).
        mCanvas:Restore().
        Assert:Equals(0, mCanvas:CountKind({&KIND-ALIEN})).
    END METHOD.

END CLASS.
