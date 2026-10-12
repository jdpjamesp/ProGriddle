/* The board control. A double buffered Panel that draws a grid layer as one pixel per cell in
   a Bitmap, scaled up in a single DrawImage call with nearest neighbour interpolation. That
   costs a few milliseconds a paint, against about 95 ms for one FillRectangle per cell on a
   100 x 100 board (measured in Phase 0).

   The Bitmap is built directly over a MEMPTR of 4 byte pixels (0x00RRGGBB), so ABL writes the
   pixels with PUT-LONG and nothing is copied across the .NET bridge. The pixels are filled
   from the grid in the quickest way for its store: a block copy for an ArrayStore, a block
   copy of a blank board plus the live cells for a SparseStore, one cell at a time for any
   other store. A cell's colour is the palette entry at its value, so 0 is the first colour.

   Glyphs: SetGlyphs gives some cell values a piece of text drawn centred in the cell, in a
   colour of its own, over the cell's palette colour. Minesweeper uses it for the counts, the
   flag and the mine. Text is drawn at paint time, so it stays sharp at any cell size, and only
   for the cells whose value has a glyph.

   Notice: ShowNotice draws a few words in the middle of the control, on a dark panel, for
   about a second and then fades them out. A timer drives the fade and stops when it is done.

   Call ReleaseResources when the control is finished with. It frees the Bitmap first and
   then the MEMPTRs. (ABL does not allow overriding the .NET Dispose, so the owner of the view
   must call ReleaseResources. The destructor does it as a last resort.) */
USING Progress.Lang.*.
USING System.Drawing.Drawing2D.* FROM ASSEMBLY.
USING System.Drawing.Imaging.* FROM ASSEMBLY.
USING System.Drawing.Text.* FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.GridView INHERITS Panel:

    {ProGriddle/Core/SparseCells.i &NAME=ttCells &ACCESS=PRIVATE}

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

    /* glyphs: text and colour per cell value, a brush per glyph, and the value of every cell */
    DEFINE PRIVATE VARIABLE mGlyphSpec   AS CHARACTER  NO-UNDO EXTENT.
    /* the text to draw as UTF-8, because a CHARACTER here is ISO 8859-1 and cannot hold a flag */
    DEFINE PRIVATE VARIABLE mGlyphText   AS LONGCHAR   NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mGlyphBrush  AS SolidBrush NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mGlyphCount  AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mCellValues  AS MEMPTR     NO-UNDO.
    DEFINE PRIVATE VARIABLE mGlyphFont   AS Font       NO-UNDO.
    DEFINE PRIVATE VARIABLE mGlyphFontPx AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mGlyphFormat AS StringFormat NO-UNDO.

    DEFINE PRIVATE VARIABLE mBannerText  AS CHARACTER  NO-UNDO.
    /* the notice: its text, when it started (System.Environment:TickCount) and the timer that fades it */
    DEFINE PRIVATE VARIABLE mNoticeText  AS CHARACTER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mNoticeStart AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mNoticeTimer AS Timer      NO-UNDO.

    /* Draw thin lines between cells when each cell is at least 8 pixels wide. */
    DEFINE PUBLIC PROPERTY ShowGridLines AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* The font family of the glyphs. Bold, sized to the cell. */
    DEFINE PUBLIC PROPERTY GlyphFontName AS CHARACTER NO-UNDO INITIAL "Segoe UI Symbol"
        GET.
        SET(INPUT pcValue AS CHARACTER):
            IF pcValue = ? OR pcValue = "" THEN
                UNDO, THROW NEW GridException("A glyph font needs a name").
            GlyphFontName = pcValue.
            FreeFont().
        END SET.

    /* The banner on show now, or an empty string when there is none. */
    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN mBannerText.
        END GET.

    /* The notice on show now, or an empty string when there is none or it has faded. */
    DEFINE PUBLIC PROPERTY NoticeText AS CHARACTER NO-UNDO
        GET():
            RETURN mNoticeText.
        END GET.

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
        THIS-OBJECT:SetStyle(ControlStyles:Selectable, TRUE).
        THIS-OBJECT:SetStyle(ControlStyles:StandardDoubleClick, TRUE).
        THIS-OBJECT:TabStop = FALSE.
        THIS-OBJECT:BackColor = Color:FromArgb(24, 28, 32).
        mLinePen = NEW Pen(Color:FromArgb(44, 50, 58)).
        mGlyphFormat = NEW StringFormat().
        mGlyphFormat:Alignment = StringAlignment:Center.
        mGlyphFormat:LineAlignment = StringAlignment:Center.
        mNoticeTimer = NEW Timer().
        mNoticeTimer:Interval = 40.
        mNoticeTimer:Tick:Subscribe(OnNoticeTick).
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

    /* Text drawn in the middle of each cell, by cell value: the first entry is for value 0, the
       next for value 1, and so on. An entry is plain text, "U+" and hex digits for a character
       by code point (U+1F6A9 is a flag on a post), or empty for no glyph. Code points are
       needed for anything outside Latin 1, which an ABL string cannot carry. pcColors lists the six digit
       hex colour of each glyph in the same order; a missing colour is white. Values with no
       entry get no glyph. Entries are separated by commas, so a comma cannot be a glyph.
       Takes effect on the next Show. */
    METHOD PUBLIC VOID SetGlyphs(INPUT pcGlyphs AS CHARACTER, INPUT pcColors AS CHARACTER):
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE item  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rgb   AS INTEGER   NO-UNDO.
        IF pcGlyphs = ? THEN UNDO, THROW NEW GridException("Glyphs cannot be the unknown value").
        IF pcColors = ? THEN pcColors = "".
        FreeGlyphs().
        n = NUM-ENTRIES(pcGlyphs).
        EXTENT(mGlyphSpec) = n.
        EXTENT(mGlyphText) = n.
        EXTENT(mGlyphBrush) = n.
        DO i = 1 TO n:
            item = TRIM(ENTRY(i, pcGlyphs)).
            mGlyphSpec[i] = item.
            IF item BEGINS "U+" THEN SetCodePoint(i, HexToInt(SUBSTRING(item, 3), 1)).
            ELSE mGlyphText[i] = item.
            rgb = 16777215.
            IF i <= NUM-ENTRIES(pcColors) AND TRIM(ENTRY(i, pcColors)) <> "" THEN rgb = HexToInt(TRIM(ENTRY(i, pcColors)), 6).
            mGlyphBrush[i] = NEW SolidBrush(Color:FromArgb(INTEGER(TRUNCATE(rgb / 65536, 0)),
                                                         INTEGER(TRUNCATE(rgb / 256, 0)) MODULO 256,
                                                         rgb MODULO 256)).
        END.
        mGlyphCount = n.
    END METHOD.

    /* How opaque the notice is, 255 to 0, this many milliseconds after it appeared: fully
       solid for 900 ms, then fading out evenly over the next 700 ms. */
    METHOD PUBLIC STATIC INTEGER NoticeAlphaAt(INPUT piElapsedMs AS INTEGER):
        IF piElapsedMs <= 900 THEN RETURN 255.
        IF piElapsedMs >= 1600 THEN RETURN 0.
        RETURN INTEGER(255 - TRUNCATE((piElapsedMs - 900) * 255 / 700, 0)).
    END METHOD.

    /* Shows a few words over the middle of the board and fades them out. Showing another
       notice replaces the first and starts again. An empty text clears it. */
    METHOD PUBLIC VOID ShowNotice(INPUT pcText AS CHARACTER):
        IF mReleased THEN RETURN.
        IF pcText = ? THEN pcText = "".
        mNoticeText = pcText.
        mNoticeStart = System.Environment:TickCount.
        IF pcText = "" THEN mNoticeTimer:Stop().
        ELSE mNoticeTimer:Start().
        THIS-OBJECT:Invalidate().
    END METHOD.

    /* Shows a few words over the middle of the board, solid, for as long as they are set, such as
       "PAUSED". An empty or unknown text takes it away. A notice is drawn over it. */
    METHOD PUBLIC VOID SetBanner(INPUT pcText AS CHARACTER):
        IF mReleased THEN RETURN.
        IF pcText = ? THEN pcText = "".
        IF pcText = mBannerText THEN RETURN.
        mBannerText = pcText.
        THIS-OBJECT:Invalidate().
    END METHOD.

    METHOD PRIVATE VOID OnNoticeTick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        IF mNoticeText <> "" AND NoticeAlphaAt(System.Environment:TickCount - mNoticeStart) <= 0 THEN DO:
            mNoticeText = "".
            mNoticeTimer:Stop().
        END.
        THIS-OBJECT:Invalidate().
    END METHOD.

    /* Draws the notice at its current opacity. */
    METHOD PRIVATE VOID PaintNotice(INPUT poGraphics AS Graphics):
        DEFINE VARIABLE alpha AS INTEGER NO-UNDO.
        alpha = NoticeAlphaAt(System.Environment:TickCount - mNoticeStart).
        IF alpha > 0 THEN PaintBox(poGraphics, mNoticeText, alpha).
    END METHOD.

    /* Draws text centred on a dark panel, both at the given opacity (1 to 255). */
    METHOD PRIVATE VOID PaintBox(INPUT poGraphics AS Graphics, INPUT pcText AS CHARACTER, INPUT piAlpha AS INTEGER):
        DEFINE VARIABLE noticeFont AS Font NO-UNDO.
        DEFINE VARIABLE panelBrush AS SolidBrush NO-UNDO.
        DEFINE VARIABLE textBrush AS SolidBrush NO-UNDO.
        DEFINE VARIABLE textSize AS SizeF NO-UNDO.
        DEFINE VARIABLE w      AS DECIMAL NO-UNDO.
        DEFINE VARIABLE h      AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cx     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cy     AS DECIMAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            noticeFont = NEW Font(GlyphFontName, System.Convert:ToSingle(26), FontStyle:Bold, GraphicsUnit:Pixel).
            poGraphics:TextRenderingHint = TextRenderingHint:AntiAliasGridFit.
            textSize = poGraphics:MeasureString(pcText, noticeFont).
            w = textSize:Width + 56.
            h = textSize:Height + 28.
            cx = THIS-OBJECT:ClientSize:Width / 2.
            cy = THIS-OBJECT:ClientSize:Height / 2.
            panelBrush = NEW SolidBrush(Color:FromArgb(INTEGER(piAlpha * 0.8), 10, 12, 16)).
            textBrush = NEW SolidBrush(Color:FromArgb(piAlpha, 255, 255, 255)).
            poGraphics:FillRectangle(panelBrush, System.Convert:ToSingle(cx - w / 2), System.Convert:ToSingle(cy - h / 2),
                                     System.Convert:ToSingle(w), System.Convert:ToSingle(h)).
            poGraphics:DrawString(pcText, noticeFont, textBrush, System.Convert:ToSingle(cx), System.Convert:ToSingle(cy), mGlyphFormat).
            FINALLY:
                IF VALID-OBJECT(textBrush) THEN textBrush:Dispose().
                IF VALID-OBJECT(panelBrush) THEN panelBrush:Dispose().
                IF VALID-OBJECT(noticeFont) THEN noticeFont:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* Puts one character, given as a Unicode code point, into glyph i. It is built as UTF-8
       bytes and kept in a LONGCHAR with a fixed UTF-8 codepage, which the .NET bridge hands
       over as a proper string. */
    METHOD PRIVATE VOID SetCodePoint(INPUT piIndex AS INTEGER, INPUT piCodePoint AS INTEGER):
        DEFINE VARIABLE bytes AS MEMPTR NO-UNDO.
        IF piCodePoint < 1 OR piCodePoint > 1114111 OR (piCodePoint >= 55296 AND piCodePoint <= 57343) THEN
            UNDO, THROW NEW GridException("Not a Unicode character: U+" + STRING(piCodePoint)).
        IF piCodePoint < 128 THEN DO:
            SET-SIZE(bytes) = 1.
            PUT-BYTE(bytes, 1) = piCodePoint.
        END.
        ELSE IF piCodePoint < 2048 THEN DO:
            SET-SIZE(bytes) = 2.
            PUT-BYTE(bytes, 1) = 192 + INTEGER(TRUNCATE(piCodePoint / 64, 0)).
            PUT-BYTE(bytes, 2) = 128 + (piCodePoint MODULO 64).
        END.
        ELSE IF piCodePoint < 65536 THEN DO:
            SET-SIZE(bytes) = 3.
            PUT-BYTE(bytes, 1) = 224 + INTEGER(TRUNCATE(piCodePoint / 4096, 0)).
            PUT-BYTE(bytes, 2) = 128 + (INTEGER(TRUNCATE(piCodePoint / 64, 0)) MODULO 64).
            PUT-BYTE(bytes, 3) = 128 + (piCodePoint MODULO 64).
        END.
        ELSE DO:
            SET-SIZE(bytes) = 4.
            PUT-BYTE(bytes, 1) = 240 + INTEGER(TRUNCATE(piCodePoint / 262144, 0)).
            PUT-BYTE(bytes, 2) = 128 + (INTEGER(TRUNCATE(piCodePoint / 4096, 0)) MODULO 64).
            PUT-BYTE(bytes, 3) = 128 + (INTEGER(TRUNCATE(piCodePoint / 64, 0)) MODULO 64).
            PUT-BYTE(bytes, 4) = 128 + (piCodePoint MODULO 64).
        END.
        FIX-CODEPAGE(mGlyphText[piIndex]) = "UTF-8".
        COPY-LOB FROM bytes TO mGlyphText[piIndex] CONVERT SOURCE CODEPAGE "UTF-8".
        FINALLY:
            SET-SIZE(bytes) = 0.
        END FINALLY.
    END METHOD.

    /* The glyph of a cell's current value as it was given to SetGlyphs ("A", or "U+2691" for
       a code point), an empty string when it has none. For tests. */
    METHOD PUBLIC CHARACTER GlyphAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        IF piX < 0 OR piX >= mCols OR piY < 0 OR piY >= mRows THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 view", piX, piY, mCols, mRows)).
        IF mGlyphCount = 0 OR GET-SIZE(mCellValues) <> mCols * mRows * 4 THEN RETURN "".
        v = GET-LONG(mCellValues, (piY * mCols + piX) * 4 + 1).
        IF v < 0 OR v >= mGlyphCount THEN RETURN "".
        RETURN mGlyphSpec[v + 1].
    END METHOD.

    /* Shows one layer of the grid. Rebuilds the pixel buffer when the grid size changes. */
    METHOD PUBLIC VOID Show(INPUT poGrid AS Grid, INPUT pcLayer AS CHARACTER):
        DEFINE VARIABLE layer AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("Nothing to show: the grid is not valid").
        layer = poGrid:Store:LayerIndex(pcLayer).
        IF mReleased THEN UNDO, THROW NEW GridException("The view has been released").
        IF NOT VALID-OBJECT(mBitmap) OR poGrid:Width <> mCols OR poGrid:Height <> mRows THEN
            Resize(poGrid:Width, poGrid:Height).
        IF mGlyphCount > 0 AND GET-SIZE(mCellValues) <> mCols * mRows * 4 THEN DO:
            SET-SIZE(mCellValues) = 0.
            SET-SIZE(mCellValues) = mCols * mRows * 4.
        END.
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
            IF mGlyphCount > 0 THEN PaintGlyphs(e:Graphics, ox, oy, cs).
        END.
        IF mBannerText <> "" THEN PaintBox(e:Graphics, mBannerText, 255).
        IF mNoticeText <> "" THEN PaintNotice(e:Graphics).
        LastPaintMs = ETIME.
        PaintCount = PaintCount + 1.
        SUPER:OnPaint(e).
    END METHOD.

    /* Draws the glyph of every cell whose value has one. The font and the brushes are made
       once, outside the loop, so a repaint allocates nothing per cell. */
    METHOD PRIVATE VOID PaintGlyphs(INPUT poGraphics AS Graphics, INPUT piOx AS INTEGER, INPUT piOy AS INTEGER, INPUT piCs AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE v  AS INTEGER NO-UNDO.
        DEFINE VARIABLE n  AS INTEGER NO-UNDO.
        DEFINE VARIABLE px AS DECIMAL NO-UNDO.
        DEFINE VARIABLE py AS DECIMAL NO-UNDO.
        DEFINE VARIABLE half AS DECIMAL NO-UNDO.
        n = mCols * mRows.
        IF GET-SIZE(mCellValues) <> n * 4 THEN RETURN.
        IF NOT VALID-OBJECT(mGlyphFont) OR mGlyphFontPx <> piCs THEN DO:
            FreeFont().
            mGlyphFont = NEW Font(GlyphFontName, System.Convert:ToSingle(piCs * 0.6), FontStyle:Bold, GraphicsUnit:Pixel).
            mGlyphFontPx = piCs.
        END.
        poGraphics:TextRenderingHint = TextRenderingHint:AntiAliasGridFit.
        half = piCs / 2.
        DO i = 0 TO n - 1:
            v = GET-LONG(mCellValues, i * 4 + 1).
            IF v < 0 OR v >= mGlyphCount THEN NEXT.
            IF mGlyphSpec[v + 1] = "" THEN NEXT.
            px = piOx + (i MODULO mCols) * piCs + half.
            py = piOy + TRUNCATE(i / mCols, 0) * piCs + half.
            poGraphics:DrawString(mGlyphText[v + 1], mGlyphFont, mGlyphBrush[v + 1], System.Convert:ToSingle(px), System.Convert:ToSingle(py), mGlyphFormat).
        END.
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
        FreeGlyphs().
        FreeFont().
        IF VALID-OBJECT(mGlyphFormat) THEN mGlyphFormat:Dispose().
        mGlyphFormat = ?.
        IF VALID-OBJECT(mNoticeTimer) THEN DO:
            mNoticeTimer:Stop().
            mNoticeTimer:Tick:Unsubscribe(OnNoticeTick).
            mNoticeTimer:Dispose().
        END.
        mNoticeTimer = ?.
        mNoticeText = "".
    END METHOD.

    METHOD PRIVATE VOID FreeFont():
        IF VALID-OBJECT(mGlyphFont) THEN mGlyphFont:Dispose().
        mGlyphFont = ?.
        mGlyphFontPx = 0.
    END METHOD.

    METHOD PRIVATE VOID FreeGlyphs():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mGlyphCount:
            IF VALID-OBJECT(mGlyphBrush[i]) THEN mGlyphBrush[i]:Dispose().
        END.
        mGlyphCount = 0.
    END METHOD.

    /* The Bitmap must go before the memory it points at. */
    METHOD PRIVATE VOID FreeMemory():
        IF VALID-OBJECT(mBitmap) THEN mBitmap:Dispose().
        mBitmap = ?.
        SET-SIZE(mPixels) = 0.
        SET-SIZE(mBlank) = 0.
        SET-SIZE(mWork) = 0.
        SET-SIZE(mCellValues) = 0.
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
                IF mGlyphCount > 0 THEN PUT-LONG(mCellValues, i * 4 + 1) = v.
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
            IF mGlyphCount > 0 THEN DO i = 0 TO n - 1:
                PUT-LONG(mCellValues, i * 4 + 1) = 0.
            END.
            CAST(poStore, SparseStore):ExportCells(OUTPUT TABLE ttCells).
            FOR EACH ttCells WHERE ttCells.layerNo = piLayer:
                v = ttCells.cellVal.
                IF mGlyphCount > 0 THEN PUT-LONG(mCellValues, ttCells.cellIdx * 4 + 1) = v.
                PUT-LONG(mPixels, ttCells.cellIdx * 4 + 1) = (IF v >= 0 AND v < mPaletteCount THEN mPalette[v + 1] ELSE mUnknown).
            END.
        END.
        ELSE DO:
            DO i = 0 TO n - 1:
                v = poStore:GetCellAt(piLayer, i).
                IF mGlyphCount > 0 THEN PUT-LONG(mCellValues, i * 4 + 1) = v.
                PUT-LONG(mPixels, i * 4 + 1) = (IF v >= 0 AND v < mPaletteCount THEN mPalette[v + 1] ELSE mUnknown).
            END.
        END.
    END METHOD.

    METHOD PRIVATE INTEGER HexToInt(INPUT pcHex AS CHARACTER):
        RETURN HexToInt(pcHex, 6).
    END METHOD.

    /* A hex number of exactly piDigits digits, or any length from 1 to 6 when piDigits is 1
       (used for code points). */
    METHOD PRIVATE INTEGER HexToInt(INPUT pcHex AS CHARACTER, INPUT piDigits AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE result AS INTEGER NO-UNDO.
        IF (piDigits = 1 AND (LENGTH(pcHex) < 1 OR LENGTH(pcHex) > 6)) OR (piDigits <> 1 AND LENGTH(pcHex) <> piDigits) THEN
            UNDO, THROW NEW GridException("Not a hex value of the right length: " + pcHex).
        DO i = 1 TO LENGTH(pcHex):
            d = INDEX("0123456789ABCDEF", CAPS(SUBSTRING(pcHex, i, 1))) - 1.
            IF d < 0 THEN UNDO, THROW NEW GridException("Not a hex colour: " + pcHex).
            result = result * 16 + d.
        END.
        RETURN result.
    END METHOD.

END CLASS.
