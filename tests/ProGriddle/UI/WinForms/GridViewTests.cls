/* GridView needs the .NET bridge, so these run under prowin -b (tools/run-tests.ps1 -Gui). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.GridViewTests:

    DEFINE PRIVATE VARIABLE mView AS GridView NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildView():
        mView = NEW GridView().
        mView:SetPalette("000000,FF8000,0000FF").
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseView():
        IF VALID-OBJECT(mView) THEN DO:
            mView:ReleaseResources().
            mView:Dispose().
        END.
        mView = ?.
    END METHOD.

    /* A grid on the given kind of store (1 array, 2 sparse, 3 table) with a few cells set. */
    METHOD PRIVATE Grid NewGrid(INPUT piKind AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE store AS ICellStore NO-UNDO.
        CASE piKind:
            WHEN 1 THEN store = NEW ArrayStore(piW, piH, "state").
            WHEN 2 THEN store = NEW SparseStore(piW, piH, "state").
            OTHERWISE store = NEW TableStore(piW, piH, "state").
        END CASE.
        RETURN NEW Grid(store).
    END METHOD.

    /* ---- the pixels ---- */

    @Test.
    METHOD PUBLIC VOID EveryStoreKindFillsTheSamePixels():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE v AS GridView NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            g = NewGrid(k, 4, 3).
            g:Store:SetCell(1, 1, 0, 1).
            g:Store:SetCell(1, 3, 2, 2).
            v = NEW GridView().
            v:SetPalette("000000,FF8000,0000FF").
            v:Show(g, "state").
            Assert:Equals(0, v:PixelAt(0, 0)).
            Assert:Equals(16744448, v:PixelAt(1, 0)).
            Assert:Equals(255, v:PixelAt(3, 2)).
            Assert:Equals(0, v:PixelAt(2, 1)).
            Assert:Equals(4, v:Columns).
            Assert:Equals(3, v:Rows).
            CATCH e AS Progress.Lang.Error:
                UNDO, THROW NEW AppError(SUBSTITUTE("[store kind &1] &2", k, e:GetMessage(1)), 0).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARandomBoardGivesIdenticalPixelsOnEveryStoreKind():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS Grid NO-UNDO.
        DEFINE VARIABLE v      AS GridView NO-UNDO.
        DEFINE VARIABLE r      AS SeededRandom NO-UNDO.
        DEFINE VARIABLE sums   AS INT64 NO-UNDO EXTENT 3.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DO k = 1 TO 3:
            DO ON ERROR UNDO, THROW:
                g = NewGrid(k, 17, 11).
                r = NEW SeededRandom(5).
                DO i = 0 TO g:CellCount - 1:
                    g:Store:SetCellAt(1, i, r:NextInt(3)).
                END.
                v = NEW GridView().
                v:SetPalette("101010,20FF20,3030FF").
                v:Show(g, "state").
                DO y = 0 TO 10:
                    DO x = 0 TO 16:
                        sums[k] = sums[k] * 7 + v:PixelAt(x, y) + 1.
                        sums[k] = sums[k] MODULO 1000000007.
                    END.
                END.
                FINALLY:
                    IF VALID-OBJECT(v) THEN v:ReleaseResources().
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
        Assert:Equals(sums[1], sums[2]).
        Assert:Equals(sums[1], sums[3]).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ValuesOutsideThePaletteAreMagenta():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 3, 1).
            g:Store:SetCell(1, 0, 0, 7).
            g:Store:SetCell(1, 1, 0, -1).
            mView:Show(g, "state").
            Assert:Equals(16711935, mView:PixelAt(0, 0)).
            Assert:Equals(16711935, mView:PixelAt(1, 0)).
            Assert:Equals(0, mView:PixelAt(2, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowingALayerOfAMultiLayerStoreUsesThatLayer():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            DO ON ERROR UNDO, THROW:
                IF k = 1 THEN g = NEW Grid(NEW ArrayStore(2, 2, "mine,flag")).
                ELSE IF k = 2 THEN g = NEW Grid(NEW SparseStore(2, 2, "mine,flag")).
                ELSE g = NEW Grid(NEW TableStore(2, 2, "mine,flag")).
                g:Store:SetCell(1, 0, 0, 1).
                g:Store:SetCell(2, 1, 1, 1).
                mView:Show(g, "flag").
                Assert:Equals(0, mView:PixelAt(0, 0)).
                Assert:Equals(16744448, mView:PixelAt(1, 1)).
                mView:Show(g, "mine").
                Assert:Equals(16744448, mView:PixelAt(0, 0)).
                Assert:Equals(0, mView:PixelAt(1, 1)).
                FINALLY:
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowingAgainPicksUpChangesAndClearsOldCells():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            DO ON ERROR UNDO, THROW:
                g = NewGrid(k, 3, 3).
                g:Store:SetCell(1, 0, 0, 1).
                mView:Show(g, "state").
                Assert:Equals(16744448, mView:PixelAt(0, 0)).
                g:Store:SetCell(1, 0, 0, 0).
                g:Store:SetCell(1, 2, 2, 1).
                mView:Show(g, "state").
                Assert:Equals(0, mView:PixelAt(0, 0)).
                Assert:Equals(16744448, mView:PixelAt(2, 2)).
                FINALLY:
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewPaletteTakesEffectOnTheNextShowForEveryStoreKind():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            DO ON ERROR UNDO, THROW:
                g = NewGrid(k, 3, 3).
                g:Store:SetCell(1, 1, 1, 1).
                mView:Show(g, "state").
                mView:SetPalette("112233,445566").
                mView:Show(g, "state").
                Assert:Equals(1122867, mView:PixelAt(0, 0)).
                Assert:Equals(4478310, mView:PixelAt(1, 1)).
                mView:SetPalette("000000,FF8000,0000FF").
                FINALLY:
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChangingTheGridSizeRebuildsTheView():
        DEFINE VARIABLE a AS Grid NO-UNDO.
        DEFINE VARIABLE b AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = NewGrid(1, 3, 3).
            b = NewGrid(1, 6, 2).
            mView:Show(a, "state").
            Assert:Equals(3, mView:Columns).
            b:Store:SetCell(1, 5, 1, 1).
            mView:Show(b, "state").
            Assert:Equals(6, mView:Columns).
            Assert:Equals(2, mView:Rows).
            Assert:Equals(16744448, mView:PixelAt(5, 1)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID PixelAtThrowsOutsideTheView():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 3, 3).
            mView:Show(g, "state").
            mView:PixelAt(3, 0).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ShowThrowsForAnUnknownLayer():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 3, 3).
            mView:Show(g, "nope").
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ShowThrowsWithoutAGrid():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        mView:Show(g, "state").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABigSparseBoardFillsQuicklyWhateverItsSize():
        DEFINE VARIABLE g  AS Grid NO-UNDO.
        DEFINE VARIABLE ms AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW SparseStore(1000, 1000, "state")).
            g:Store:SetCell(1, 999, 999, 1).
            mView:Show(g, "state").
            /* the first show builds the blank buffer, the second only copies it */
            mView:Show(g, "state").
            ms = mView:LastFillMs.
            Assert:IsTrue(ms < 300).
            Assert:Equals(16744448, mView:PixelAt(999, 999)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDenseFillOfAHundredByAHundredBoardIsFast():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 100, 100).
            g:Store:FillLayer(1, 1).
            mView:Show(g, "state").
            mView:Show(g, "state").
            Assert:IsTrue(mView:LastFillMs < 100).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- palette ---- */

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APaletteColourMustBeSixHexDigits():
        mView:SetPalette("FFF,000000").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APaletteColourMustBeHex():
        mView:SetPalette("00000G").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APaletteCannotBeEmpty():
        mView:SetPalette("").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PaletteDigitsMayBeLowerCaseAndSpaced():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 1).
            g:Store:SetCell(1, 1, 0, 1).
            mView:SetPalette("0a0b0c, ff00aa").
            mView:Show(g, "state").
            Assert:Equals(658188, mView:PixelAt(0, 0)).
            Assert:Equals(16711850, mView:PixelAt(1, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- size and clicks ---- */

    @Test.
    METHOD PUBLIC VOID CellSizeIsTheLargestWholeNumberThatFits():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 10, 10).
            mView:Show(g, "state").
            mView:ClientSize = NEW Size(300, 200).
            Assert:Equals(20, mView:CellSize()).
            mView:ClientSize = NEW Size(305, 999).
            Assert:Equals(30, mView:CellSize()).
            mView:ClientSize = NEW Size(5, 5).
            Assert:Equals(1, mView:CellSize()).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FitToWindowScalesByAnyAmountAndKeepsTheShapeAndTheClicksRight():
        DEFINE VARIABLE g  AS Grid NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 10, 10).
            mView:Show(g, "state").
            mView:ClientSize = NEW Size(275, 999).
            /* whole numbers: 27 a cell, 270 wide, 5 pixels over */
            Assert:Equals(27, mView:CellSize()).
            Assert:Equals(270, mView:PictureWidth()).
            mView:FitToWindow = TRUE.
            /* fitted: 27.5 a cell fills the width, and the board is centred in the height */
            Assert:Equals(275, mView:PictureWidth()).
            Assert:Equals(275, mView:PictureHeight()).
            Assert:Equals(0, mView:OffsetX()).
            Assert:Equals(362, mView:OffsetY()).
            Assert:IsTrue(mView:HitTest(274, 362, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(9, cx).
            Assert:Equals(0, cy).
            Assert:IsFalse(mView:HitTest(275, 362, OUTPUT cx, OUTPUT cy)).
            /* never under a pixel a cell */
            mView:ClientSize = NEW Size(5, 5).
            Assert:Equals(10, mView:PictureWidth()).
            mView:FitToWindow = FALSE.
            Assert:Equals(10, mView:PictureWidth()).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CellSizeBeforeTheFirstShowIsOne():
        Assert:Equals(1, mView:CellSize()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HitTestConvertsPixelsToCellsAndRejectsTheMargin():
        DEFINE VARIABLE g  AS Grid NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 10, 10).
            mView:Show(g, "state").
            mView:ClientSize = NEW Size(300, 200).
            /* 20 pixel cells, so the board is 200 x 200, centred: a 50 pixel margin each side */
            Assert:Equals(50, mView:OffsetX()).
            Assert:Equals(0, mView:OffsetY()).
            Assert:IsTrue(mView:HitTest(50, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(0, cx).
            Assert:Equals(0, cy).
            Assert:IsTrue(mView:HitTest(69, 19, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(0, cx).
            Assert:IsTrue(mView:HitTest(70, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(1, cx).
            Assert:IsTrue(mView:HitTest(249, 199, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(9, cx).
            Assert:Equals(9, cy).
            Assert:IsFalse(mView:HitTest(250, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(-1, cx).
            Assert:Equals(-1, cy).
            Assert:IsFalse(mView:HitTest(49, 5, OUTPUT cx, OUTPUT cy)).
            Assert:IsFalse(mView:HitTest(100, 200, OUTPUT cx, OUTPUT cy)).
            Assert:IsFalse(mView:HitTest(-1, 5, OUTPUT cx, OUTPUT cy)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoardIsCentredInBothDirections():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 10, 10).
            mView:Show(g, "state").
            mView:ClientSize = NEW Size(300, 250).
            Assert:Equals(25, mView:CellSize()).
            Assert:Equals(25, mView:OffsetX()).
            Assert:Equals(0, mView:OffsetY()).
            mView:ClientSize = NEW Size(300, 300).
            Assert:Equals(30, mView:CellSize()).
            Assert:Equals(0, mView:OffsetX()).
            mView:ClientSize = NEW Size(320, 300).
            Assert:Equals(10, mView:OffsetX()).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOffsetsAreZeroBeforeTheFirstShow():
        Assert:Equals(0, mView:OffsetX()).
        Assert:Equals(0, mView:OffsetY()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PaintingDrawsTheBoardInTheCentreAndTheBackgroundAroundIt():
        DEFINE VARIABLE g   AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp AS Bitmap NO-UNDO.
        DEFINE VARIABLE c   AS Color  NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 2).
            g:Store:SetCell(1, 0, 0, 1).
            mView:ShowGridLines = FALSE.
            mView:ClientSize = NEW Size(60, 20).
            mView:Show(g, "state").
            bmp = NEW Bitmap(60, 20).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 60, 20)).
            /* cells are 10 pixels, the board is 20 wide, so it starts at x 20 */
            c = bmp:GetPixel(5, 5).
            Assert:Equals(24, c:R).
            c = bmp:GetPixel(25, 5).
            Assert:Equals(255, c:R).
            c = bmp:GetPixel(35, 5).
            Assert:Equals(0, c:R).
            c = bmp:GetPixel(45, 5).
            Assert:Equals(24, c:R).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HitTestBeforeTheFirstShowFindsNothing():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        Assert:IsFalse(mView:HitTest(5, 5, OUTPUT cx, OUTPUT cy)).
        Assert:Equals(-1, cx).
    END METHOD.

    /* ---- painting ---- */

    @Test.
    METHOD PUBLIC VOID PaintingScalesEachCellUpWithoutBlurring():
        /* a 4 x 4 board drawn at 10 pixels a cell: cell (1,0) is alive, so the block of
           pixels from x 10 to 19 and y 0 to 9 is that colour and its neighbours are not */
        DEFINE VARIABLE g   AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp AS Bitmap NO-UNDO.
        DEFINE VARIABLE c   AS Color  NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 4, 4).
            g:Store:SetCell(1, 1, 0, 1).
            mView:ShowGridLines = FALSE.
            mView:ClientSize = NEW Size(40, 40).
            mView:Show(g, "state").
            bmp = NEW Bitmap(40, 40).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 40, 40)).
            c = bmp:GetPixel(10, 0).
            Assert:Equals(255, c:R).
            Assert:Equals(128, c:G).
            c = bmp:GetPixel(19, 9).
            Assert:Equals(255, c:R).
            c = bmp:GetPixel(9, 5).
            Assert:Equals(0, c:R).
            c = bmp:GetPixel(20, 5).
            Assert:Equals(0, c:R).
            c = bmp:GetPixel(15, 10).
            Assert:Equals(0, c:R).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PaintingCountsAndTimesItself():
        DEFINE VARIABLE g   AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp AS Bitmap NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 4, 4).
            mView:ClientSize = NEW Size(40, 40).
            mView:Show(g, "state").
            bmp = NEW Bitmap(40, 40).
            n = mView:PaintCount.
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 40, 40)).
            Assert:IsTrue(mView:PaintCount > n).
            Assert:IsTrue(mView:LastPaintMs >= 0).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHundredByAHundredBoardPaintsInWellUnderTheOldFillRectangleTime():
        /* Phase 0 measured about 95 ms to paint 100 x 100 cell by cell */
        DEFINE VARIABLE g   AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp AS Bitmap NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 100, 100).
            g:Store:FillLayer(1, 1).
            mView:ClientSize = NEW Size(600, 600).
            mView:Show(g, "state").
            bmp = NEW Bitmap(600, 600).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 600, 600)).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 600, 600)).
            Assert:IsTrue(mView:LastPaintMs < 50).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- glyphs ---- */

    @Test.
    METHOD PUBLIC VOID NoGlyphsMeansAnEmptyGlyphForEveryCell():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 3, 3).
            g:Store:SetCell(1, 1, 1, 1).
            mView:Show(g, "state").
            Assert:Equals("", mView:GlyphAt(1, 1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryStoreKindGivesTheSameGlyphs():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE v AS GridView NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            g = NewGrid(k, 4, 3).
            g:Store:SetCell(1, 1, 0, 1).
            g:Store:SetCell(1, 3, 2, 2).
            v = NEW GridView().
            v:SetPalette("000000,FF8000,0000FF").
            v:SetGlyphs(",A,B", "FFFFFF,00FF00,FF0000").
            v:Show(g, "state").
            Assert:Equals("", v:GlyphAt(0, 0)).
            Assert:Equals("A", v:GlyphAt(1, 0)).
            Assert:Equals("B", v:GlyphAt(3, 2)).
            Assert:Equals("", v:GlyphAt(2, 1)).
            CATCH e AS Progress.Lang.Error:
                UNDO, THROW NEW AppError(SUBSTITUTE("[store kind &1] &2", k, e:GetMessage(1)), 0).
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGlyphEntryCanBeACodePoint():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 1).
            g:Store:SetCell(1, 1, 0, 1).
            mView:SetGlyphs(",U+2691", "FFFFFF,FF0000").
            mView:Show(g, "state").
            Assert:Equals("U+2691", mView:GlyphAt(1, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AValueBeyondTheGlyphListHasNoGlyph():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 1).
            g:Store:SetCell(1, 1, 0, 2).
            mView:SetGlyphs(",A", "FFFFFF,00FF00").
            mView:Show(g, "state").
            Assert:Equals("", mView:GlyphAt(1, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GlyphsFollowTheBoardAsItChanges():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(3, 2, 1).
            mView:SetGlyphs(",A", "FFFFFF,00FF00").
            mView:Show(g, "state").
            Assert:Equals("", mView:GlyphAt(0, 0)).
            g:Store:SetCell(1, 0, 0, 1).
            mView:Show(g, "state").
            Assert:Equals("A", mView:GlyphAt(0, 0)).
            g:Store:SetCell(1, 0, 0, 0).
            mView:Show(g, "state").
            Assert:Equals("", mView:GlyphAt(0, 0)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID GlyphAtOffTheBoardThrows():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 2).
            mView:Show(g, "state").
            mView:GlyphAt(2, 0).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABadGlyphColourThrows():
        mView:SetGlyphs("A", "GREEN!").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABadCodePointThrows():
        mView:SetGlyphs("U+ZZ", "FFFFFF").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownGlyphListThrows():
        mView:SetGlyphs(?, "FFFFFF").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABlankGlyphFontThrows():
        mView:GlyphFontName = "".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACodePointOutsideLatin1IsDrawnAsThatCharacterNotAQuestionMark():
        /* U+2588 is a full block, so a cell shows far more glyph pixels than a question mark would */
        DEFINE VARIABLE g     AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp   AS Bitmap NO-UNDO.
        DEFINE VARIABLE c     AS Color  NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE green AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 1, 1).
            g:Store:SetCell(1, 0, 0, 1).
            mView:ShowGridLines = FALSE.
            mView:GlyphFontName = "Segoe UI Symbol".
            mView:SetGlyphs(",U+2588", "FFFFFF,00FF00").
            mView:ClientSize = NEW Size(40, 40).
            mView:Show(g, "state").
            bmp = NEW Bitmap(40, 40).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 40, 40)).
            DO py = 0 TO 39:
                DO px = 0 TO 39:
                    c = bmp:GetPixel(px, py).
                    IF c:G > 200 AND c:R < 100 THEN green = green + 1.
                END.
            END.
            Assert:IsTrue(green > 200).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ACodePointThatIsNotACharacterThrows():
        mView:SetGlyphs("U+D800", "FFFFFF").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PaintingDrawsTheGlyphOnlyInCellsWhoseValueHasOne():
        /* two 20 pixel cells: value 0 is black with no glyph, value 1 is orange with a green X */
        DEFINE VARIABLE g     AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp   AS Bitmap NO-UNDO.
        DEFINE VARIABLE c     AS Color  NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE green AS INTEGER NO-UNDO.
        DEFINE VARIABLE stray AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 1).
            g:Store:SetCell(1, 1, 0, 1).
            mView:ShowGridLines = FALSE.
            mView:SetGlyphs(",X", "FFFFFF,00FF00").
            mView:ClientSize = NEW Size(40, 20).
            mView:Show(g, "state").
            bmp = NEW Bitmap(40, 20).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 40, 20)).
            DO py = 0 TO 19:
                DO px = 0 TO 19:
                    c = bmp:GetPixel(px, py).
                    IF c:G > 0 THEN stray = stray + 1.
                    c = bmp:GetPixel(px + 20, py).
                    IF c:G > 200 AND c:R < 100 THEN green = green + 1.
                END.
            END.
            Assert:Equals(0, stray).
            Assert:IsTrue(green > 5).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- direct colour ---- */

    @Test.
    METHOD PUBLIC VOID DirectColourIsOffByDefault():
        Assert:IsFalse(mView:DirectColor).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithDirectColourEveryStoreKindUsesTheCellValueAsTheColour():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE v AS GridView NO-UNDO.
        DO k = 1 TO 3 ON ERROR UNDO, THROW:
            g = NewGrid(k, 4, 3).
            g:Store:SetCell(1, 1, 0, 16744448).
            g:Store:SetCell(1, 3, 2, 255).
            g:Store:SetCell(1, 0, 2, 16777215).
            v = NEW GridView().
            v:SetPalette("000000,FF8000,0000FF").
            v:DirectColor = TRUE.
            v:Show(g, "state").
            Assert:Equals(0, v:PixelAt(0, 0)).
            Assert:Equals(16744448, v:PixelAt(1, 0)).
            Assert:Equals(255, v:PixelAt(3, 2)).
            Assert:Equals(16777215, v:PixelAt(0, 2)).
            Assert:Equals(0, v:PixelAt(2, 1)).
            CATCH e AS Progress.Lang.Error:
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(g) THEN g:Dispose().
                UNDO, THROW e.
            END CATCH.
            FINALLY:
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DirectColourShowsTheLayerYouAskFor():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = NEW Grid(NEW ArrayStore(3, 2, "back,front")).
        DO ON ERROR UNDO, THROW:
            g:Store:SetCell(1, 0, 0, 11).
            g:Store:SetCell(2, 0, 0, 22).
            g:Store:SetCell(1, 2, 1, 33).
            g:Store:SetCell(2, 2, 1, 44).
            mView:DirectColor = TRUE.
            mView:Show(g, "back").
            Assert:Equals(11, mView:PixelAt(0, 0)).
            Assert:Equals(33, mView:PixelAt(2, 1)).
            mView:Show(g, "front").
            Assert:Equals(22, mView:PixelAt(0, 0)).
            Assert:Equals(44, mView:PixelAt(2, 1)).
            FINALLY:
                g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SwitchingDirectColourOffGoesBackToThePalette():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = NewGrid(1, 2, 1).
        DO ON ERROR UNDO, THROW:
            g:Store:SetCell(1, 0, 0, 1).
            mView:DirectColor = TRUE.
            mView:Show(g, "state").
            Assert:Equals(1, mView:PixelAt(0, 0)).
            mView:DirectColor = FALSE.
            mView:Show(g, "state").
            Assert:Equals(16744448, mView:PixelAt(0, 0)).
            FINALLY:
                g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADirectColourBoardOfSpaceInvadersSizeFillsFast():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = NEW Grid(NEW ArrayStore(224, 256, "view,kind,back")).
        DO ON ERROR UNDO, THROW:
            g:Store:FillLayer(1, 2236962).
            mView:DirectColor = TRUE.
            mView:Show(g, "view").
            Assert:Equals(2236962, mView:PixelAt(100, 100)).
            Assert:IsTrue(mView:LastFillMs < 20, SUBSTITUTE("a 224 x 256 fill took &1 ms", mView:LastFillMs)).
            FINALLY:
                g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheViewWantsTheFourArrowKeysAndNothingElse():
        Assert:IsTrue(mView:WantsKey("Left")).
        Assert:IsTrue(mView:WantsKey("Right")).
        Assert:IsTrue(mView:WantsKey("Up")).
        Assert:IsTrue(mView:WantsKey("Down")).
        Assert:IsFalse(mView:WantsKey("A")).
        Assert:IsFalse(mView:WantsKey("Space")).
        Assert:IsFalse(mView:WantsKey("Left, Shift")).
        Assert:IsFalse(mView:WantsKey("")).
    END METHOD.

    /* ---- the size of a glyph ---- */

    @Test.
    METHOD PUBLIC VOID AGlyphOfOneOrTwoCharactersIsSixtyPercentOfTheCell():
        Assert:Equals(60, GridView:GlyphPixelsFor(100, 1)).
        Assert:Equals(60, GridView:GlyphPixelsFor(100, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongerGlyphShrinksSoItsWidthStaysInsideTheCell():
        Assert:Equals(50, GridView:GlyphPixelsFor(100, 3)).
        Assert:Equals(37, GridView:GlyphPixelsFor(100, 4)).
        Assert:Equals(25, GridView:GlyphPixelsFor(100, 6)).
        Assert:IsTrue(GridView:GlyphPixelsFor(100, 6) < GridView:GlyphPixelsFor(100, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGlyphIsNeverSmallerThanSixPixels():
        Assert:Equals(6, GridView:GlyphPixelsFor(10, 8)).
        Assert:Equals(6, GridView:GlyphPixelsFor(1, 1)).
    END METHOD.

    /* ---- the notice ---- */

    @Test.
    METHOD PUBLIC VOID TheNoticeIsSolidForNineHundredMillisecondsThenFadesOverSevenHundred():
        Assert:Equals(255, GridView:NoticeAlphaAt(0)).
        Assert:Equals(255, GridView:NoticeAlphaAt(900)).
        Assert:Equals(0, GridView:NoticeAlphaAt(1600)).
        Assert:Equals(0, GridView:NoticeAlphaAt(5000)).
        Assert:Equals(128, GridView:NoticeAlphaAt(1250)).
        Assert:IsTrue(GridView:NoticeAlphaAt(1000) > GridView:NoticeAlphaAt(1300)).
        Assert:IsTrue(GridView:NoticeAlphaAt(1300) > GridView:NoticeAlphaAt(1500)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShowNoticeSetsTheTextAndAnEmptyOrUnknownTextClearsIt():
        Assert:Equals("", mView:NoticeText).
        mView:ShowNotice("Question marks on").
        Assert:Equals("Question marks on", mView:NoticeText).
        mView:ShowNotice("Question marks off").
        Assert:Equals("Question marks off", mView:NoticeText).
        mView:ShowNotice("").
        Assert:Equals("", mView:NoticeText).
        mView:ShowNotice("again").
        mView:ShowNotice(?).
        Assert:Equals("", mView:NoticeText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANoticeIsPaintedInTheMiddleOfTheControl():
        DEFINE VARIABLE g     AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp   AS Bitmap NO-UNDO.
        DEFINE VARIABLE c     AS Color  NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge  AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 2).
            mView:ShowGridLines = FALSE.
            mView:ClientSize = NEW Size(300, 120).
            mView:Show(g, "state").
            mView:ShowNotice("Marks on").
            bmp = NEW Bitmap(300, 120).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 300, 120)).
            DO py = 40 TO 80:
                DO px = 90 TO 210:
                    c = bmp:GetPixel(px, py).
                    IF c:R > 200 AND c:G > 200 AND c:B > 200 THEN white = white + 1.
                END.
            END.
            /* the corner is nowhere near the notice, so it is still the control background */
            c = bmp:GetPixel(2, 2).
            edge = c:R.
            Assert:IsTrue(white > 30).
            Assert:Equals(24, edge).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNoNoticeNothingIsDrawnOverTheBoard():
        DEFINE VARIABLE g     AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp   AS Bitmap NO-UNDO.
        DEFINE VARIABLE c     AS Color  NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 2).
            mView:ShowGridLines = FALSE.
            mView:ClientSize = NEW Size(300, 120).
            mView:Show(g, "state").
            bmp = NEW Bitmap(300, 120).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 300, 120)).
            DO py = 40 TO 80:
                DO px = 90 TO 210:
                    c = bmp:GetPixel(px, py).
                    IF c:R > 200 AND c:G > 200 AND c:B > 200 THEN white = white + 1.
                END.
            END.
            Assert:Equals(0, white).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AReleasedViewIgnoresNotices():
        mView:ReleaseResources().
        mView:ShowNotice("late").
        Assert:Equals("", mView:NoticeText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABannerStaysUntilItIsClearedAndAnEmptyOrUnknownTextClearsIt():
        Assert:Equals("", mView:BannerText).
        mView:SetBanner("PAUSED").
        Assert:Equals("PAUSED", mView:BannerText).
        mView:SetBanner("PAUSED").
        Assert:Equals("PAUSED", mView:BannerText).
        mView:SetBanner("").
        Assert:Equals("", mView:BannerText).
        mView:SetBanner("again").
        mView:SetBanner(?).
        Assert:Equals("", mView:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABannerIsPaintedInTheMiddleAndAfterItIsClearedItIsGone():
        DEFINE VARIABLE g      AS Grid   NO-UNDO.
        DEFINE VARIABLE bmp    AS Bitmap NO-UNDO.
        DEFINE VARIABLE c      AS Color  NO-UNDO.
        DEFINE VARIABLE px     AS INTEGER NO-UNDO.
        DEFINE VARIABLE py     AS INTEGER NO-UNDO.
        DEFINE VARIABLE shown  AS INTEGER NO-UNDO.
        DEFINE VARIABLE gone   AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 2, 2).
            mView:ShowGridLines = FALSE.
            mView:ClientSize = NEW Size(300, 120).
            mView:Show(g, "state").
            mView:SetBanner("PAUSED").
            bmp = NEW Bitmap(300, 120).
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 300, 120)).
            DO py = 40 TO 80:
                DO px = 90 TO 210:
                    c = bmp:GetPixel(px, py).
                    IF c:R > 200 AND c:G > 200 AND c:B > 200 THEN shown = shown + 1.
                END.
            END.
            mView:SetBanner("").
            mView:DrawToBitmap(bmp, NEW Rectangle(0, 0, 300, 120)).
            DO py = 40 TO 80:
                DO px = 90 TO 210:
                    c = bmp:GetPixel(px, py).
                    IF c:R > 200 AND c:G > 200 AND c:B > 200 THEN gone = gone + 1.
                END.
            END.
            Assert:IsTrue(shown > 30).
            Assert:Equals(0, gone).
            FINALLY:
                IF VALID-OBJECT(bmp) THEN bmp:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AReleasedViewIgnoresBanners():
        mView:ReleaseResources().
        mView:SetBanner("late").
        Assert:Equals("", mView:BannerText).
    END METHOD.

    /* ---- lifetime ---- */

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ShowAfterReleaseResourcesThrows():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NewGrid(1, 3, 3).
            mView:Show(g, "state").
            mView:ReleaseResources().
            mView:Show(g, "state").
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleaseResourcesCanBeCalledMoreThanOnce():
        mView:ReleaseResources().
        mView:ReleaseResources().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GridLinesAreOnByDefault():
        Assert:IsTrue(NEW GridView():ShowGridLines).
    END METHOD.

END CLASS.
