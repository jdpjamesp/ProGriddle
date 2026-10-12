/* The board control. A double buffered Panel that draws a grid layer as one pixel per cell in
   a Bitmap, scaled up in a single DrawImage call with nearest neighbour interpolation. That
   costs a few milliseconds a paint, against about 95 ms for one FillRectangle per cell on a
   100 x 100 board (measured in Phase 0).

   The Bitmap is built directly over a MEMPTR of 4 byte pixels (0x00RRGGBB), so ABL writes the
   pixels with PUT-LONG and nothing is copied across the .NET bridge. The pixels are filled
   from the grid in the quickest way for its store: a block copy for an ArrayStore, a block
   copy of a blank board plus the live cells for a SparseStore, one cell at a time for any
   other store. A cell's colour is the palette entry at its value, so 0 is the first colour.

   Call ReleaseResources when the control is finished with. It frees the Bitmap first and
   then the MEMPTRs. (ABL does not allow overriding the .NET Dispose, so the owner of the view
   must call ReleaseResources. The destructor does it as a last resort.) */
USING Progress.Lang.*.
USING System.Drawing.Drawing2D.* FROM ASSEMBLY.
USING System.Drawing.Imaging.* FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING Prolif.Core.*.
USING Prolif.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.GridView INHERITS Panel:

    {Prolif/Core/SparseCells.i &NAME=ttCells &ACCESS=PRIVATE}

    DEFINE PRIVATE VARIABLE mPixels   AS MEMPTR  NO-UNDO.
    DEFINE PRIVATE VARIABLE mBlank    AS MEMPTR  NO-UNDO.
    DEFINE PRIVATE VARIABLE mWork     AS MEMPTR  NO-UNDO.
    DEFINE PRIVATE VARIABLE mBitmap   AS Bitmap  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLinePen  AS Pen     NO-UNDO.
    DEFINE PRIVATE VARIABLE mCols     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mRows     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mPalette  AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mPaletteCount AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mUnknown  AS INTEGER NO-UNDO INITIAL 16711935.
    /* The colour the blank buffer is filled with, or the unknown value when it needs filling. */
    DEFINE PRIVATE VARIABLE mBlankColor AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mReleased AS LOGICAL NO-UNDO.

    /* Draw thin lines between cells when each cell is at least 8 pixels wide. */
    DEFINE PUBLIC PROPERTY ShowGridLines AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* Number of columns and rows currently shown, 0 before the first Show. */
    DEFINE PUBLIC PROPERTY Columns AS INTEGER NO-UNDO
        GET():
            RETURN mCols.
        END GET.

    DEFINE PUBLIC PROPERTY Rows AS INTEGER NO-UNDO
        GET():
            RETURN mRows.
        END GET.

    /* Diagnostics: how long the last paint took, and how many paints there have been. */
    DEFINE PUBLIC PROPERTY LastPaintMs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PaintCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Diagnostics: how long the last Show took to fill the pixels. */
    DEFINE PUBLIC PROPERTY LastFillMs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC GridView():
        SUPER().
        THIS-OBJECT:DoubleBuffered = TRUE.
        THIS-OBJECT:BackColor = Color:FromArgb(24, 28, 32).
        mLinePen = NEW Pen(Color:FromArgb(44, 50, 58)).
        SetPalette("1B1F24,F2C14E").
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC GridView():
        FreeMemory().
    END DESTRUCTOR.

    /* The colours, as a comma separated list of six digit hex values: "1B1F24,F2C14E" makes
       value 0 dark and value 1 gold. Needs at least one colour. Takes effect on the next Show. */
    METHOD PUBLIC VOID SetPalette(INPUT pcColors AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF pcColors = ? OR pcColors = "" THEN
            UNDO, THROW NEW GridException("A palette needs at least one colour").
        mPaletteCount = NUM-ENTRIES(pcColors).
        EXTENT(mPalette) = mPaletteCount.
        DO i = 1 TO mPaletteCount:
            mPalette[i] = HexToInt(TRIM(ENTRY(i, pcColors))).
        END.
    END METHOD.

    /* Shows one layer of the grid. Rebuilds the pixel buffer when the grid size changes. */
    METHOD PUBLIC VOID Show(INPUT poGrid AS Grid, INPUT pcLayer AS CHARACTER):
        DEFINE VARIABLE layer AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("Nothing to show: the grid is not valid").
        layer = poGrid:Store:LayerIndex(pcLayer).
        IF mReleased THEN UNDO, THROW NEW GridException("The view has been released").
        IF NOT VALID-OBJECT(mBitmap) OR poGrid:Width <> mCols OR poGrid:Height <> mRows THEN
            Resize(poGrid:Width, poGrid:Height).
        ETIME(TRUE).
        FillPixels(poGrid:Store, layer).
        LastFillMs = ETIME.
        THIS-OBJECT:Invalidate().
    END METHOD.

    /* The colour (0x00RRGGBB) of the pixel for a cell, for tests. */
    METHOD PUBLIC INTEGER PixelAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mCols OR piY < 0 OR piY >= mRows THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 view", piX, piY, mCols, mRows)).
        RETURN GET-LONG(mPixels, (piY * mCols + piX) * 4 + 1).
    END METHOD.

    /* Width and height in pixels of one cell at the current control size. */
    METHOD PUBLIC INTEGER CellSize():
        IF mCols < 1 OR mRows < 1 THEN RETURN 1.
        RETURN INTEGER(MAXIMUM(1, TRUNCATE(MINIMUM(THIS-OBJECT:ClientSize:Width / mCols, THIS-OBJECT:ClientSize:Height / mRows), 0))).
    END METHOD.

    /* Pixels between the left edge of the control and the board, which is centred. */
    METHOD PUBLIC INTEGER OffsetX():
        IF mCols < 1 THEN RETURN 0.
        RETURN INTEGER(MAXIMUM(0, TRUNCATE((THIS-OBJECT:ClientSize:Width - CellSize() * mCols) / 2, 0))).
    END METHOD.

    /* Pixels between the top edge of the control and the board. */
    METHOD PUBLIC INTEGER OffsetY():
        IF mRows < 1 THEN RETURN 0.
        RETURN INTEGER(MAXIMUM(0, TRUNCATE((THIS-OBJECT:ClientSize:Height - CellSize() * mRows) / 2, 0))).
    END METHOD.

    /* Converts a pixel position to a cell. Returns false, and sets both outputs to -1, when
       the position is outside the board (including the margin around it). */
    METHOD PUBLIC LOGICAL HitTest(INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                  OUTPUT piCellX AS INTEGER, OUTPUT piCellY AS INTEGER):
        DEFINE VARIABLE cs AS INTEGER NO-UNDO.
        DEFINE VARIABLE relX AS INTEGER NO-UNDO.
        DEFINE VARIABLE relY AS INTEGER NO-UNDO.
        piCellX = -1.
        piCellY = -1.
        IF mCols < 1 OR mRows < 1 THEN RETURN FALSE.
        cs = CellSize().
        relX = piX - OffsetX().
        relY = piY - OffsetY().
        IF relX < 0 OR relY < 0 OR relX >= cs * mCols OR relY >= cs * mRows THEN RETURN FALSE.
        piCellX = INTEGER(TRUNCATE(relX / cs, 0)).
        piCellY = INTEGER(TRUNCATE(relY / cs, 0)).
        RETURN TRUE.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnPaint(INPUT e AS PaintEventArgs):
        DEFINE VARIABLE cs AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ox AS INTEGER NO-UNDO.
        DEFINE VARIABLE oy AS INTEGER NO-UNDO.
        ETIME(TRUE).
        IF VALID-OBJECT(mBitmap) THEN DO:
            cs = CellSize().
            ox = OffsetX().
            oy = OffsetY().
            e:Graphics:InterpolationMode = InterpolationMode:NearestNeighbor.
            e:Graphics:PixelOffsetMode = PixelOffsetMode:Half.
            e:Graphics:DrawImage(mBitmap, ox, oy, cs * mCols, cs * mRows).
            IF ShowGridLines AND cs >= 8 THEN DO:
                DO i = 0 TO mCols:
                    e:Graphics:DrawLine(mLinePen, ox + i * cs, oy, ox + i * cs, oy + mRows * cs).
                END.
                DO i = 0 TO mRows:
                    e:Graphics:DrawLine(mLinePen, ox, oy + i * cs, ox + mCols * cs, oy + i * cs).
                END.
            END.
        END.
        LastPaintMs = ETIME.
        PaintCount = PaintCount + 1.
        SUPER:OnPaint(e).
    END METHOD.

    /* The board is smaller than the control, so a resize needs a full repaint, not just the
       newly exposed strip. */
    METHOD PROTECTED OVERRIDE VOID OnResize(INPUT e AS System.EventArgs):
        SUPER:OnResize(e).
        THIS-OBJECT:Invalidate().
    END METHOD.

    /* Frees the Bitmap, the pen and the memory. Safe to call more than once. After it the
       view cannot show anything. */
    METHOD PUBLIC VOID ReleaseResources():
        IF mReleased THEN RETURN.
        mReleased = TRUE.
        FreeMemory().
        IF VALID-OBJECT(mLinePen) THEN mLinePen:Dispose().
        mLinePen = ?.
    END METHOD.

    /* The Bitmap must go before the memory it points at. */
    METHOD PRIVATE VOID FreeMemory():
        IF VALID-OBJECT(mBitmap) THEN mBitmap:Dispose().
        mBitmap = ?.
        SET-SIZE(mPixels) = 0.
        SET-SIZE(mBlank) = 0.
        SET-SIZE(mWork) = 0.
    END METHOD.

    METHOD PRIVATE VOID Resize(INPUT piCols AS INTEGER, INPUT piRows AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        FreeMemory().
        mCols = piCols.
        mRows = piRows.
        SET-SIZE(mPixels) = mCols * mRows * 4.
        SET-SIZE(mBlank) = mCols * mRows * 4.
        mBlankColor = ?.
        mBitmap = NEW Bitmap(mCols, mRows, mCols * 4, PixelFormat:Format32bppRgb, NEW System.IntPtr(GET-POINTER-VALUE(mPixels))).
    END METHOD.

    METHOD PRIVATE VOID FillPixels(INPUT poStore AS ICellStore, INPUT piLayer AS INTEGER):
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE v    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE base AS INTEGER NO-UNDO.
        n = mCols * mRows.

        IF TYPE-OF(poStore, ArrayStore) THEN DO:
            IF GET-SIZE(mWork) <> n * poStore:LayerCount * 4 THEN DO:
                SET-SIZE(mWork) = 0.
                SET-SIZE(mWork) = n * poStore:LayerCount * 4.
            END.
            CAST(poStore, ArrayStore):CopyBytesTo(mWork).
            base = (piLayer - 1) * n.
            DO i = 0 TO n - 1:
                v = GET-LONG(mWork, (base + i) * 4 + 1).
                PUT-LONG(mPixels, i * 4 + 1) = (IF v >= 0 AND v < mPaletteCount THEN mPalette[v + 1] ELSE mUnknown).
            END.
        END.
        ELSE IF TYPE-OF(poStore, SparseStore) THEN DO:
            /* a blank board in the first colour, copied in one block, then only the live cells */
            IF mBlankColor = ? OR mBlankColor <> mPalette[1] THEN DO:
                DO i = 0 TO n - 1:
                    PUT-LONG(mBlank, i * 4 + 1) = mPalette[1].
                END.
                mBlankColor = mPalette[1].
            END.
            COPY-LOB FROM mBlank FOR n * 4 TO mPixels OVERLAY AT 1.
            CAST(poStore, SparseStore):ExportCells(OUTPUT TABLE ttCells).
            FOR EACH ttCells WHERE ttCells.layerNo = piLayer:
                v = ttCells.cellVal.
                PUT-LONG(mPixels, ttCells.cellIdx * 4 + 1) = (IF v >= 0 AND v < mPaletteCount THEN mPalette[v + 1] ELSE mUnknown).
            END.
        END.
        ELSE DO:
            DO i = 0 TO n - 1:
                v = poStore:GetCellAt(piLayer, i).
                PUT-LONG(mPixels, i * 4 + 1) = (IF v >= 0 AND v < mPaletteCount THEN mPalette[v + 1] ELSE mUnknown).
            END.
        END.
    END METHOD.

    METHOD PRIVATE INTEGER HexToInt(INPUT pcHex AS CHARACTER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE result AS INTEGER NO-UNDO.
        IF LENGTH(pcHex) <> 6 THEN
            UNDO, THROW NEW GridException("A colour is six hex digits, not " + pcHex).
        DO i = 1 TO 6:
            d = INDEX("0123456789ABCDEF", CAPS(SUBSTRING(pcHex, i, 1))) - 1.
            IF d < 0 THEN UNDO, THROW NEW GridException("Not a hex colour: " + pcHex).
            result = result * 16 + d.
        END.
        RETURN result.
    END METHOD.

END CLASS.
