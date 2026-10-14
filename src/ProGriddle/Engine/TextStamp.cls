/* A piece of text in the pixel font, worked out once and copied onto a canvas whenever it is wanted. Drawing text with
   an edge cell by cell costs thousands of store calls a frame, which is far too slow for a game that redraws its whole
   picture sixty times a second: a stamp does that work in its constructor and keeps the result as a list of cells,
   each a position from the text's top left and a colour, so drawing it is one quick loop (PixelCanvas:PutCells).

   Each cell of the font becomes piScale by piScale cells. The colour goes from piTop on the top row of the letters to
   piBottom on the bottom row, in even steps (the same colour twice for plain text). piEdge is a one cell ring of that
   colour round every letter, so it reads over a busy picture, or below 0 for none. The edge is outside the text's
   own box, up to a cell to each side, and never covers a letter.

   A stamp owns memory: the owner calls Dispose when it has done with it (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TextStamp FINAL:

    /* three whole numbers a cell: across, down, and the colour */
    DEFINE PRIVATE VARIABLE mCells AS MEMPTR NO-UNDO.

    /* The width and height in cells of the text itself, not counting its edge. */
    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many cells the stamp is made of, edge and letters. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no text, or a scale below 1. */
    CONSTRUCTOR PUBLIC TextStamp(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER,
                                 INPUT piEdge AS INTEGER):
        DEFINE VARIABLE c       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dx      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dy      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE w       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE h       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE gx      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE gy      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE nBody   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE nEdge   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE o       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE glyph   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE bitRow  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE body    AS LOGICAL   NO-UNDO EXTENT.
        DEFINE VARIABLE ring    AS LOGICAL   NO-UNDO EXTENT.
        IF pcText = ? OR LENGTH(pcText) = 0 THEN UNDO, THROW NEW GridException("A text stamp needs some text").
        IF piScale = ? OR piScale < 1 THEN UNDO, THROW NEW GridException("A text stamp scale is 1 or more, not " + STRING(piScale)).
        w = PixelFont:WidthOf(pcText) * piScale.
        h = PixelFont:GlyphHeight() * piScale.
        Width = w.
        Height = h.
        /* which cells of a box one cell bigger all round are letters; index 0 is the cell above and left of the text */
        EXTENT(body) = (w + 2) * (h + 2).
        DO c = 1 TO LENGTH(pcText):
            glyph = PixelFont:Glyph(SUBSTRING(pcText, c, 1)).
            DO gy = 0 TO PixelFont:GlyphHeight() - 1:
                bitRow = ENTRY(gy + 1, glyph, "/").
                DO gx = 0 TO PixelFont:GlyphWidth() - 1:
                    IF SUBSTRING(bitRow, gx + 1, 1) <> "#" THEN NEXT.
                    DO dy = 0 TO piScale - 1:
                        DO dx = 0 TO piScale - 1:
                            x = (c - 1) * (PixelFont:GlyphWidth() + PixelFont:Gap()) * piScale + gx * piScale + dx.
                            y = gy * piScale + dy.
                            body[(y + 1) * (w + 2) + x + 2] = TRUE.
                            nBody = nBody + 1.
                        END.
                    END.
                END.
            END.
        END.
        /* the ring: a cell that is not a letter but touches one (looked at once, here, not by a method: handing a
           big array to a method copies it every time) */
        IF piEdge >= 0 THEN DO:
            EXTENT(ring) = (w + 2) * (h + 2).
            DO y = 0 TO h + 1:
                DO x = 0 TO w + 1:
                    IF body[y * (w + 2) + x + 1] THEN NEXT.
                    DO dy = MAXIMUM(0, y - 1) TO MINIMUM(h + 1, y + 1):
                        DO dx = MAXIMUM(0, x - 1) TO MINIMUM(w + 1, x + 1):
                            IF body[dy * (w + 2) + dx + 1] THEN ring[y * (w + 2) + x + 1] = TRUE.
                        END.
                    END.
                    IF ring[y * (w + 2) + x + 1] THEN nEdge = nEdge + 1.
                END.
            END.
        END.
        Count = nBody + nEdge.
        IF Count > 0 THEN SET-SIZE(mCells) = Count * 12.
        o = 0.
        /* the ring first, then the letters over it, each row of letters in its own colour */
        IF nEdge > 0 THEN DO:
            DO y = 0 TO h + 1:
                DO x = 0 TO w + 1:
                    IF NOT ring[y * (w + 2) + x + 1] THEN NEXT.
                    PUT-LONG(mCells, o * 12 + 1) = x - 1.
                    PUT-LONG(mCells, o * 12 + 5) = y - 1.
                    PUT-LONG(mCells, o * 12 + 9) = piEdge.
                    o = o + 1.
                END.
            END.
        END.
        DO y = 1 TO h:
            DO x = 1 TO w:
                IF NOT body[y * (w + 2) + x + 1] THEN NEXT.
                PUT-LONG(mCells, o * 12 + 1) = x - 1.
                PUT-LONG(mCells, o * 12 + 5) = y - 1.
                PUT-LONG(mCells, o * 12 + 9) = ColourMath:Mix(piTop, piBottom, y - 1, MAXIMUM(1, h - 1)).
                o = o + 1.
            END.
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC TextStamp():
        Dispose().
    END DESTRUCTOR.

    /* Frees the cells. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        SET-SIZE(mCells) = 0.
    END METHOD.

    /* Copies the stamp onto a canvas with the top left of the text at piX, piY. Cells off the canvas are skipped. In a
       batch it goes into the batch. Throws GridException for no canvas, or a stamp that has been disposed of. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("There is no canvas to draw on").
        IF Count > 0 AND GET-SIZE(mCells) = 0 THEN UNDO, THROW NEW GridException("This text stamp has been disposed of").
        IF Count > 0 THEN poCanvas:PutCells(mCells, Count, piX, piY).
    END METHOD.

END CLASS.
