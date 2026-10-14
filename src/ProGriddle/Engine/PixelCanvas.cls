/* The picture of a pixel game, kept as three layers of one grid, one cell to a pixel:

     view   the colour of the cell, 0xRRGGBB, which is what the window shows (the view uses direct colour)
     kind   what is in the cell (the game decides): 0 for empty space, else a shield, an alien, a bomb and so on.
            Shots and bombs look at this to know what they hit, never at the colour
     back   the colour of the cell when nothing is on it: the starry sky, the ground line

   A kind is any whole number the game likes, 0 meaning empty space.
   Drawing a sprite sets view and kind for each of its cells. Erasing one puts the background colour back
   and the kind to 0, but only in the cells that are still of that kind, so something that has moved on top
   of a cell is not wiped out by the thing it covered. Cells outside the board are skipped, so a sprite can
   go half off an edge. Restore puts the whole board back to the empty sky in one block copy.

   Lines can be drawn in a batch for speed: BeginBatch copies the board into the canvas's own memory, DrawLine
   then writes straight into that, and EndBatch puts the whole board back in one block. Until EndBatch the
   board itself has not changed, and only DrawLine and Restore may be used, any other drawing is refused.

   The canvas needs an ArrayStore with exactly the layers view, kind and back. It keeps work memory for the
   block copy, which Dispose frees (a destructor does it as a safety net). It does not own the grid. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PixelCanvas FINAL:

    &SCOPED-DEFINE KIND-NONE 0

    DEFINE PRIVATE VARIABLE mStore   AS ArrayStore NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight  AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mView    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mKind    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBack    AS INTEGER     NO-UNDO.
    /* work memory for the block copy: the raw bytes of the store, and a layer of zeros */
    DEFINE PRIVATE VARIABLE mWork    AS MEMPTR      NO-UNDO.
    DEFINE PRIVATE VARIABLE mZero    AS MEMPTR      NO-UNDO.
    /* true between BeginBatch and EndBatch, when mWork holds the picture being drawn */
    DEFINE PRIVATE VARIABLE mBatch   AS LOGICAL     NO-UNDO.

    &SCOPED-DEFINE NOT-IN-BATCH IF mBatch THEN UNDO, THROW NEW GridException("The canvas is in a batch: only DrawLine and Restore work until EndBatch").

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET():
            RETURN mWidth.
        END GET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET():
            RETURN mHeight.
        END GET.

    /* The grid must be on an ArrayStore with the layers view, kind and back. */
    CONSTRUCTOR PUBLIC PixelCanvas(INPUT poGrid AS Grid):
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("A canvas needs a grid").
        IF NOT TYPE-OF(poGrid:Store, ArrayStore) THEN UNDO, THROW NEW GridException("A canvas needs an ArrayStore").
        IF poGrid:Store:LayerCount <> 3 THEN UNDO, THROW NEW GridException("A canvas grid has the three layers view, kind and back").
        mStore = CAST(poGrid:Store, ArrayStore).
        mWidth = poGrid:Width.
        mHeight = poGrid:Height.
        mView = mStore:LayerIndex("view").
        mKind = mStore:LayerIndex("kind").
        mBack = mStore:LayerIndex("back").
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC PixelCanvas():
        Dispose().
    END DESTRUCTOR.

    /* Frees the work memory. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        SET-SIZE(mWork) = 0.
        SET-SIZE(mZero) = 0.
    END METHOD.

    METHOD PUBLIC LOGICAL InBounds(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX >= 0 AND piX < mWidth AND piY >= 0 AND piY < mHeight.
    END METHOD.

    /* What is in a cell, as the game numbers kinds. A cell outside the board is empty space, so a shot that
       leaves the board meets nothing. */
    METHOD PUBLIC INTEGER KindAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN {&KIND-NONE}.
        RETURN mStore:GetCellAt(mKind, piY * mWidth + piX).
    END METHOD.

    /* The colour of a cell now, or -1 outside the board. */
    METHOD PUBLIC INTEGER ColourAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN -1.
        RETURN mStore:GetCellAt(mView, piY * mWidth + piX).
    END METHOD.

    /* The colour a cell goes back to when nothing is on it, or -1 outside the board. */
    METHOD PUBLIC INTEGER BackAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN -1.
        RETURN mStore:GetCellAt(mBack, piY * mWidth + piX).
    END METHOD.

    /* Sets the background colour of a cell. It shows once the cell is empty: SetBack does not change
       what is showing. A cell outside the board is ignored. */
    METHOD PUBLIC VOID SetBack(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        {&NOT-IN-BATCH}
        IF InBounds(piX, piY) THEN mStore:SetCellAt(mBack, piY * mWidth + piX, piColour).
    END METHOD.

    /* Gives every row of the background its own colour, which is how a gradient sky is made. There
       must be one colour for each row of the board. It does not change what is showing: Restore does. */
    METHOD PUBLIC VOID SetBackRows(INPUT piColours AS INTEGER EXTENT):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        IF EXTENT(piColours) <> mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("The background needs one colour for each of the &1 rows, not &2", mHeight, EXTENT(piColours))).
        DO y = 0 TO mHeight - 1:
            DO x = 0 TO mWidth - 1:
                mStore:SetCellAt(mBack, y * mWidth + x, piColours[y + 1]).
            END.
        END.
    END METHOD.

    /* Puts the whole board back to its background with nothing on it: every cell shows its background
       colour and has kind 0. One block copy, so it is cheap enough to call when a screen changes. */
    METHOD PUBLIC VOID Restore():
        DEFINE VARIABLE bytes AS INTEGER NO-UNDO.
        bytes = mWidth * mHeight * 4.
        IF GET-SIZE(mWork) <> bytes * 3 THEN DO:
            SET-SIZE(mWork) = 0.
            SET-SIZE(mWork) = bytes * 3.
        END.
        IF GET-SIZE(mZero) <> bytes THEN DO:
            SET-SIZE(mZero) = 0.
            SET-SIZE(mZero) = bytes.
        END.
        IF NOT mBatch THEN mStore:CopyBytesTo(mWork).
        COPY-LOB FROM mWork STARTING AT (mBack - 1) * bytes + 1 FOR bytes TO mWork OVERLAY AT (mView - 1) * bytes + 1.
        COPY-LOB FROM mZero FOR bytes TO mWork OVERLAY AT (mKind - 1) * bytes + 1.
        IF NOT mBatch THEN mStore:CopyBytesFrom(mWork).
    END METHOD.

    /* Starts a batch of lines: the board is copied into the canvas's work memory, and DrawLine writes into
       that until EndBatch. Faster than drawing a line a cell at a time through the store. Throws GridException
       if a batch is already open. */
    METHOD PUBLIC VOID BeginBatch():
        DEFINE VARIABLE bytes AS INTEGER NO-UNDO.
        IF mBatch THEN UNDO, THROW NEW GridException("A batch is already open").
        bytes = mWidth * mHeight * 4.
        IF GET-SIZE(mWork) <> bytes * 3 THEN DO:
            SET-SIZE(mWork) = 0.
            SET-SIZE(mWork) = bytes * 3.
        END.
        mStore:CopyBytesTo(mWork).
        mBatch = TRUE.
    END METHOD.

    /* Ends the batch: everything drawn in it goes onto the board in one block. Throws GridException if no
       batch is open. */
    METHOD PUBLIC VOID EndBatch():
        IF NOT mBatch THEN UNDO, THROW NEW GridException("There is no batch to end").
        mBatch = FALSE.
        mStore:CopyBytesFrom(mWork).
    END METHOD.

    /* Draws a sprite with its top left cell at piX, piY. Every cell of the sprite takes piKind and
       the colour of its tone (piColour1 for "#", 2 for "+", 3 for "*"). */
    METHOD PUBLIC VOID Draw(INPUT poSprite AS Sprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER,
                            INPUT piColour1 AS INTEGER, INPUT piColour2 AS INTEGER, INPUT piColour3 AS INTEGER):
        DrawCells(poSprite, piX, piY, piKind, piColour1, piColour2, piColour3, FALSE).
    END METHOD.

    /* The same, but only in cells that are empty (kind 0), so a flash or an explosion never paints over
       a shield or an alien. */
    METHOD PUBLIC VOID DrawOnEmpty(INPUT poSprite AS Sprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER,
                                   INPUT piColour1 AS INTEGER, INPUT piColour2 AS INTEGER, INPUT piColour3 AS INTEGER):
        DrawCells(poSprite, piX, piY, piKind, piColour1, piColour2, piColour3, TRUE).
    END METHOD.

    /* Takes a sprite off: each of its cells that is still of kind piKind goes back to its background
       colour and to kind 0. Cells that something else has taken over are left alone. */
    METHOD PUBLIC VOID Erase(INPUT poSprite AS Sprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER):
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        DO i = 0 TO poSprite:Count - 1:
            x = piX + poSprite:CellX(i).
            y = piY + poSprite:CellY(i).
            IF NOT InBounds(x, y) THEN NEXT.
            idx = y * mWidth + x.
            IF mStore:GetCellAt(mKind, idx) = piKind THEN DO:
                mStore:SetCellAt(mKind, idx, {&KIND-NONE}).
                mStore:SetCellAt(mView, idx, mStore:GetCellAt(mBack, idx)).
            END.
        END.
    END METHOD.

    /* Colours one cell, giving it a kind. A cell outside the board is ignored. */
    METHOD PUBLIC VOID Plot(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        mStore:SetCellAt(mKind, idx, piKind).
        mStore:SetCellAt(mView, idx, piColour).
    END METHOD.

    /* Draws a straight line one cell thick from one cell to another, both ends included, with an integer
       line algorithm (no blending, no anti-aliasing). The ends may be anywhere, even far off the board: the
       cells outside it are skipped. Every cell takes piKind and piColour, so piKind 0 draws a picture
       element that nothing can hit. In a batch it writes into the batch (see BeginBatch). */
    METHOD PUBLIC VOID DrawLine(INPUT piX0 AS INTEGER, INPUT piY0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER,
                                INPUT piKind AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE dx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE err AS INTEGER NO-UNDO.
        DEFINE VARIABLE e2  AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        DEFINE VARIABLE viewBase AS INTEGER NO-UNDO.
        DEFINE VARIABLE kindBase AS INTEGER NO-UNDO.
        viewBase = (mView - 1) * mWidth * mHeight * 4 + 1.
        kindBase = (mKind - 1) * mWidth * mHeight * 4 + 1.
        dx = ABSOLUTE(piX1 - piX0).
        dy = - ABSOLUTE(piY1 - piY0).
        sx = (IF piX0 < piX1 THEN 1 ELSE -1).
        sy = (IF piY0 < piY1 THEN 1 ELSE -1).
        err = dx + dy.
        /* the usual case, a line wholly on the board in a batch: no need to look at every cell */
        IF mBatch AND piX0 >= 0 AND piX0 < mWidth AND piY0 >= 0 AND piY0 < mHeight AND
                      piX1 >= 0 AND piX1 < mWidth AND piY1 >= 0 AND piY1 < mHeight THEN DO:
            DO WHILE TRUE:
                idx = (piY0 * mWidth + piX0) * 4.
                PUT-LONG(mWork, kindBase + idx) = piKind.
                PUT-LONG(mWork, viewBase + idx) = piColour.
                IF piX0 = piX1 AND piY0 = piY1 THEN RETURN.
                e2 = 2 * err.
                IF e2 >= dy THEN DO:
                    err = err + dy.
                    piX0 = piX0 + sx.
                END.
                IF e2 <= dx THEN DO:
                    err = err + dx.
                    piY0 = piY0 + sy.
                END.
            END.
        END.
        DO WHILE TRUE:
            IF piX0 >= 0 AND piX0 < mWidth AND piY0 >= 0 AND piY0 < mHeight THEN DO:
                idx = piY0 * mWidth + piX0.
                IF mBatch THEN DO:
                    PUT-LONG(mWork, kindBase + idx * 4) = piKind.
                    PUT-LONG(mWork, viewBase + idx * 4) = piColour.
                END.
                ELSE DO:
                    mStore:SetCellAt(mKind, idx, piKind).
                    mStore:SetCellAt(mView, idx, piColour).
                END.
            END.
            IF piX0 = piX1 AND piY0 = piY1 THEN LEAVE.
            e2 = 2 * err.
            IF e2 >= dy THEN DO:
                err = err + dy.
                piX0 = piX0 + sx.
            END.
            IF e2 <= dx THEN DO:
                err = err + dx.
                piY0 = piY0 + sy.
            END.
        END.
    END METHOD.

    /* Colours a list of cells in one quick loop, which is how a TextStamp is drawn. pmCells holds piCount cells of three
       whole numbers each (4 bytes each): across and down from (piX, piY), and the colour. Only the colour of a cell is
       set, its kind stays as it was. Cells outside the board are skipped. In a batch it goes into the batch. */
    METHOD PUBLIC VOID PutCells(INPUT pmCells AS MEMPTR, INPUT piCount AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        DEFINE VARIABLE viewBase AS INTEGER NO-UNDO.
        IF piCount > 0 AND GET-SIZE(pmCells) < piCount * 12 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("&1 cells need &2 bytes, not &3", piCount, piCount * 12, GET-SIZE(pmCells))).
        viewBase = (mView - 1) * mWidth * mHeight * 4 + 1.
        DO i = 0 TO piCount - 1:
            x = piX + GET-LONG(pmCells, i * 12 + 1).
            y = piY + GET-LONG(pmCells, i * 12 + 5).
            IF x < 0 OR x >= mWidth OR y < 0 OR y >= mHeight THEN NEXT.
            IF mBatch THEN PUT-LONG(mWork, viewBase + (y * mWidth + x) * 4) = GET-LONG(pmCells, i * 12 + 9).
            ELSE mStore:SetCellAt(mView, y * mWidth + x, GET-LONG(pmCells, i * 12 + 9)).
        END.
    END METHOD.

    /* Puts one cell back to empty space: its background colour and kind 0. */
    METHOD PUBLIC VOID Unplot(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        mStore:SetCellAt(mKind, idx, {&KIND-NONE}).
        mStore:SetCellAt(mView, idx, mStore:GetCellAt(mBack, idx)).
    END METHOD.

    /* Puts a rectangle of cells back to empty space. The part outside the board is ignored. */
    METHOD PUBLIC VOID ClearRect(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        DO y = MAXIMUM(0, piY) TO MINIMUM(mHeight - 1, piY + piHeight - 1):
            DO x = MAXIMUM(0, piX) TO MINIMUM(mWidth - 1, piX + piWidth - 1):
                Unplot(x, y).
            END.
        END.
    END METHOD.

    /* Shows the background of a cell, but only when nothing is on it: for a star that has moved on, or
       a background colour that has changed under a picture. A cell outside the board is ignored. */
    METHOD PUBLIC VOID ShowBack(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        IF mStore:GetCellAt(mKind, idx) = {&KIND-NONE} THEN mStore:SetCellAt(mView, idx, mStore:GetCellAt(mBack, idx)).
    END METHOD.

    /* Dims what is showing: every cell's colour is multiplied by piPercent percent (45 leaves a little under half
       the brightness). The kinds and the background are not touched, so Restore undoes it. It visits the whole
       board once, so call it once for a screen, such as a pause, not every frame. */
    METHOD PUBLIC VOID Dim(INPUT piPercent AS INTEGER):
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE colour  AS INTEGER NO-UNDO.
        DEFINE VARIABLE lastIn  AS INTEGER NO-UNDO INITIAL ?.
        DEFINE VARIABLE lastOut AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        DO i = 0 TO mWidth * mHeight - 1:
            colour = mStore:GetCellAt(mView, i).
            IF colour <> lastIn THEN DO:
                lastIn = colour.
                lastOut = ColourMath:Scale(colour, piPercent).
            END.
            mStore:SetCellAt(mView, i, lastOut).
        END.
    END METHOD.

    /* Counts the cells of one kind on the board. */
    METHOD PUBLIC INTEGER CountKind(INPUT piKind AS INTEGER):
        RETURN mStore:CountOf(mKind, piKind).
    END METHOD.

    /* Writes text in the pixel font with its top left cell at piX, piY, in one colour. The cells keep
       kind 0 and are taken off again with ClearRect, so the score can be written again in the same
       place. Characters off the board are skipped. */
    METHOD PUBLIC VOID DrawText(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE c      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE glyph  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE bitRow AS CHARACTER NO-UNDO.
        DEFINE VARIABLE startX AS INTEGER   NO-UNDO.
        {&NOT-IN-BATCH}
        IF pcText = ? OR pcText = "" THEN RETURN.
        DO c = 1 TO LENGTH(pcText):
            glyph = PixelFont:Glyph(SUBSTRING(pcText, c, 1)).
            startX = piX + (c - 1) * (PixelFont:GlyphWidth() + PixelFont:Gap()).
            DO y = 0 TO PixelFont:GlyphHeight() - 1:
                bitRow = ENTRY(y + 1, glyph, "/").
                DO x = 0 TO PixelFont:GlyphWidth() - 1:
                    IF SUBSTRING(bitRow, x + 1, 1) = "#" AND InBounds(startX + x, piY + y) THEN
                        mStore:SetCellAt(mView, (piY + y) * mWidth + startX + x, piColour).
                END.
            END.
        END.
    END METHOD.

    /* The width in cells of text drawn at a scale: each cell of a glyph becomes piScale by piScale cells. */
    METHOD PUBLIC STATIC INTEGER ScaledWidth(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER):
        RETURN PixelFont:WidthOf(pcText) * MAXIMUM(1, piScale).
    END METHOD.

    /* Writes big text: each cell of the font becomes a block of piScale by piScale cells, and the colour goes
       from piTop on the top row of the letters to piBottom on the bottom row, in even steps, for a shaded
       title. Kind 0, like DrawText. */
    METHOD PUBLIC VOID DrawTextScaled(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                      INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER, INPUT piScale AS INTEGER):
        DEFINE VARIABLE c       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dx      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dy      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE glyph   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE bitRow  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE startX  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE colour  AS INTEGER   NO-UNDO.
        {&NOT-IN-BATCH}
        IF pcText = ? OR pcText = "" THEN RETURN.
        piScale = MAXIMUM(1, piScale).
        DO c = 1 TO LENGTH(pcText):
            glyph = PixelFont:Glyph(SUBSTRING(pcText, c, 1)).
            startX = piX + (c - 1) * (PixelFont:GlyphWidth() + PixelFont:Gap()) * piScale.
            DO y = 0 TO PixelFont:GlyphHeight() - 1:
                bitRow = ENTRY(y + 1, glyph, "/").
                colour = ColourMath:Mix(piTop, piBottom, y, PixelFont:GlyphHeight() - 1).
                DO x = 0 TO PixelFont:GlyphWidth() - 1:
                    IF SUBSTRING(bitRow, x + 1, 1) <> "#" THEN NEXT.
                    DO dy = 0 TO piScale - 1:
                        DO dx = 0 TO piScale - 1:
                            IF InBounds(startX + x * piScale + dx, piY + y * piScale + dy) THEN
                                mStore:SetCellAt(mView, (piY + y * piScale + dy) * mWidth + startX + x * piScale + dx, colour).
                        END.
                    END.
                END.
            END.
        END.
    END METHOD.

    /* Writes text over a picture that may have things in it: each cell of the font becomes piScale by piScale
       cells, shaded from piTop on the top row to piBottom on the bottom row, and a one cell edge of piEdge
       goes round the letters (piEdge below 0 for none) so they stay readable. Only cells with nothing in them
       (kind 0) are touched, so an invader or a shield in front of the text stays whole, and ShowBackRect takes the
       text off again without disturbing them. */
    METHOD PUBLIC VOID DrawOverlay(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                   INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER, INPUT piScale AS INTEGER, INPUT piEdge AS INTEGER):
        DEFINE VARIABLE pass    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dx      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dy      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ex      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ey      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE glyph   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE bitRow  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE startX  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE colour  AS INTEGER   NO-UNDO.
        {&NOT-IN-BATCH}
        IF pcText = ? OR pcText = "" THEN RETURN.
        piScale = MAXIMUM(1, piScale).
        DO pass = (IF piEdge < 0 THEN 2 ELSE 1) TO 2:
            DO c = 1 TO LENGTH(pcText):
                glyph = PixelFont:Glyph(SUBSTRING(pcText, c, 1)).
                startX = piX + (c - 1) * (PixelFont:GlyphWidth() + PixelFont:Gap()) * piScale.
                DO y = 0 TO PixelFont:GlyphHeight() - 1:
                    bitRow = ENTRY(y + 1, glyph, "/").
                    colour = ColourMath:Mix(piTop, piBottom, y, PixelFont:GlyphHeight() - 1).
                    DO x = 0 TO PixelFont:GlyphWidth() - 1:
                        IF SUBSTRING(bitRow, x + 1, 1) <> "#" THEN NEXT.
                        DO dy = 0 TO piScale - 1:
                            DO dx = 0 TO piScale - 1:
                                IF pass = 2 THEN PlotIfEmpty(startX + x * piScale + dx, piY + y * piScale + dy, colour).
                                ELSE DO ex = -1 TO 1:
                                    DO ey = -1 TO 1:
                                        PlotIfEmpty(startX + x * piScale + dx + ex, piY + y * piScale + dy + ey, piEdge).
                                    END.
                                END.
                            END.
                        END.
                    END.
                END.
            END.
        END.
    END METHOD.

    /* Shows the background in every empty cell (kind 0) of a rectangle and leaves the rest alone: it takes
       DrawOverlay text off a picture. The part outside the board is ignored. */
    METHOD PUBLIC VOID ShowBackRect(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        DO y = MAXIMUM(0, piY) TO MINIMUM(mHeight - 1, piY + piHeight - 1):
            DO x = MAXIMUM(0, piX) TO MINIMUM(mWidth - 1, piX + piWidth - 1):
                ShowBack(x, y).
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID PlotIfEmpty(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        IF mStore:GetCellAt(mKind, idx) = {&KIND-NONE} THEN mStore:SetCellAt(mView, idx, piColour).
    END METHOD.

    METHOD PRIVATE VOID DrawCells(INPUT poSprite AS Sprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER,
                                  INPUT piColour1 AS INTEGER, INPUT piColour2 AS INTEGER, INPUT piColour3 AS INTEGER,
                                  INPUT plOnlyEmpty AS LOGICAL):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone   AS INTEGER NO-UNDO.
        {&NOT-IN-BATCH}
        DO i = 0 TO poSprite:Count - 1:
            x = piX + poSprite:CellX(i).
            y = piY + poSprite:CellY(i).
            IF NOT InBounds(x, y) THEN NEXT.
            idx = y * mWidth + x.
            IF plOnlyEmpty AND mStore:GetCellAt(mKind, idx) <> {&KIND-NONE} THEN NEXT.
            tone = poSprite:CellTone(i).
            mStore:SetCellAt(mKind, idx, piKind).
            mStore:SetCellAt(mView, idx, (IF tone = 1 THEN piColour1 ELSE IF tone = 2 THEN piColour2 ELSE piColour3)).
        END.
    END METHOD.

END CLASS.
