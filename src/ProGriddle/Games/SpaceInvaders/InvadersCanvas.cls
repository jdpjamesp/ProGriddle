/* The picture of a Space Invaders game, kept as three layers of one grid, one cell to a pixel:

     view   the colour of the cell, 0xRRGGBB, which is what the window shows (the view uses direct colour)
     kind   what is in the cell (see Kinds.i): 0 for empty space, else a shield, an alien, a bomb and so on.
            Shots and bombs look at this to know what they hit, never at the colour
     back   the colour of the cell when nothing is on it: the starry sky, the ground line

   Drawing a sprite sets view and kind for each of its cells. Erasing one puts the background colour back
   and the kind to 0, but only in the cells that are still of that kind, so something that has moved on top
   of a cell is not wiped out by the thing it covered. Cells outside the board are skipped, so a sprite can
   go half off an edge. Restore puts the whole board back to the empty sky in one block copy.

   The canvas needs an ArrayStore with exactly the layers view, kind and back. It keeps work memory for the
   block copy, which Dispose frees (a destructor does it as a safety net). It does not own the grid. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersCanvas FINAL:

    {ProGriddle/Games/SpaceInvaders/Kinds.i}

    DEFINE PRIVATE VARIABLE mStore   AS ArrayStore NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight  AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mView    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mKind    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBack    AS INTEGER     NO-UNDO.
    /* work memory for the block copy: the raw bytes of the store, and a layer of zeros */
    DEFINE PRIVATE VARIABLE mWork    AS MEMPTR      NO-UNDO.
    DEFINE PRIVATE VARIABLE mZero    AS MEMPTR      NO-UNDO.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET():
            RETURN mWidth.
        END GET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET():
            RETURN mHeight.
        END GET.

    /* The grid must be on an ArrayStore with the layers view, kind and back. */
    CONSTRUCTOR PUBLIC InvadersCanvas(INPUT poGrid AS Grid):
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

    DESTRUCTOR PUBLIC InvadersCanvas():
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

    /* What is in a cell, as in Kinds.i. A cell outside the board is empty space, so a shot that
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
        IF InBounds(piX, piY) THEN mStore:SetCellAt(mBack, piY * mWidth + piX, piColour).
    END METHOD.

    /* Gives every row of the background its own colour, which is how a gradient sky is made. There
       must be one colour for each row of the board. It does not change what is showing: Restore does. */
    METHOD PUBLIC VOID SetBackRows(INPUT piColours AS INTEGER EXTENT):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
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
        mStore:CopyBytesTo(mWork).
        COPY-LOB FROM mWork STARTING AT (mBack - 1) * bytes + 1 FOR bytes TO mWork OVERLAY AT (mView - 1) * bytes + 1.
        COPY-LOB FROM mZero FOR bytes TO mWork OVERLAY AT (mKind - 1) * bytes + 1.
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
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        mStore:SetCellAt(mKind, idx, piKind).
        mStore:SetCellAt(mView, idx, piColour).
    END METHOD.

    /* Puts one cell back to empty space: its background colour and kind 0. */
    METHOD PUBLIC VOID Unplot(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        mStore:SetCellAt(mKind, idx, {&KIND-NONE}).
        mStore:SetCellAt(mView, idx, mStore:GetCellAt(mBack, idx)).
    END METHOD.

    /* Puts a rectangle of cells back to empty space. The part outside the board is ignored. */
    METHOD PUBLIC VOID ClearRect(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
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
        IF NOT InBounds(piX, piY) THEN RETURN.
        idx = piY * mWidth + piX.
        IF mStore:GetCellAt(mKind, idx) = {&KIND-NONE} THEN mStore:SetCellAt(mView, idx, mStore:GetCellAt(mBack, idx)).
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
        IF pcText = ? OR pcText = "" THEN RETURN.
        piScale = MAXIMUM(1, piScale).
        DO c = 1 TO LENGTH(pcText):
            glyph = PixelFont:Glyph(SUBSTRING(pcText, c, 1)).
            startX = piX + (c - 1) * (PixelFont:GlyphWidth() + PixelFont:Gap()) * piScale.
            DO y = 0 TO PixelFont:GlyphHeight() - 1:
                bitRow = ENTRY(y + 1, glyph, "/").
                colour = InvadersLook:Mix(piTop, piBottom, y, PixelFont:GlyphHeight() - 1).
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

    METHOD PRIVATE VOID DrawCells(INPUT poSprite AS Sprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER,
                                  INPUT piColour1 AS INTEGER, INPUT piColour2 AS INTEGER, INPUT piColour3 AS INTEGER,
                                  INPUT plOnlyEmpty AS LOGICAL):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone   AS INTEGER NO-UNDO.
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
