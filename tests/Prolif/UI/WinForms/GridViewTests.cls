/* GridView needs the .NET bridge, so these run under prowin -b (tools/run-tests.ps1 -Gui). */
USING OpenEdge.Core.Assert.
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.Grid.
USING Prolif.Core.ICellStore.
USING Prolif.Core.SeededRandom.
USING Prolif.Core.SparseStore.
USING Prolif.Core.TableStore.
USING Prolif.UI.WinForms.GridView.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.GridViewTests:

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

    @Test (expected="Prolif.Core.GridException").
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

    @Test (expected="Prolif.Core.GridException").
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

    @Test (expected="Prolif.Core.GridException").
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

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID APaletteColourMustBeSixHexDigits():
        mView:SetPalette("FFF,000000").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID APaletteColourMustBeHex():
        mView:SetPalette("00000G").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
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
            /* 20 pixel cells, so the board is 200 x 200 and the margin is on the right */
            Assert:IsTrue(mView:HitTest(0, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(0, cx).
            Assert:Equals(0, cy).
            Assert:IsTrue(mView:HitTest(19, 19, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(0, cx).
            Assert:IsTrue(mView:HitTest(20, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(1, cx).
            Assert:IsTrue(mView:HitTest(199, 199, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(9, cx).
            Assert:Equals(9, cy).
            Assert:IsFalse(mView:HitTest(200, 0, OUTPUT cx, OUTPUT cy)).
            Assert:Equals(-1, cx).
            Assert:Equals(-1, cy).
            Assert:IsFalse(mView:HitTest(0, 200, OUTPUT cx, OUTPUT cy)).
            Assert:IsFalse(mView:HitTest(-1, 5, OUTPUT cx, OUTPUT cy)).
            FINALLY:
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

    /* ---- lifetime ---- */

    @Test (expected="Prolif.Core.GridException").
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
