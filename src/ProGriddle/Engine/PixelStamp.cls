/* A small picture worked out once as a list of coloured cells and copied onto a canvas whenever it is wanted: a block
   of a puzzle game, a segment of a snake. It is what a TextStamp is for text. The picture is given as a width, a height
   and one colour for each pixel, row by row (-1 for a pixel that is left out so the background shows through), and is
   kept as a list of the pixels that have a colour, each a position from the stamp's top left and a colour, so drawing it
   is one quick loop (PixelCanvas:PutCells).

   A stamp owns memory: the owner calls Dispose when it has done with it (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PixelStamp FINAL:

    /* three whole numbers a cell: across, down, and the colour */
    DEFINE PRIVATE VARIABLE mCells  AS MEMPTR  NO-UNDO.
    /* the colour of every pixel, row by row, -1 for none, kept to answer ColourAt */
    DEFINE PRIVATE VARIABLE mColour AS INTEGER NO-UNDO EXTENT.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many pixels have a colour. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for a size under 1, or a list of colours that is not width times height long. */
    CONSTRUCTOR PUBLIC PixelStamp(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT piColours AS INTEGER EXTENT):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE o AS INTEGER NO-UNDO.
        IF piWidth = ? OR piWidth < 1 OR piHeight = ? OR piHeight < 1 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A pixel stamp is 1 x 1 or more, not &1 x &2", piWidth, piHeight)).
        IF EXTENT(piColours) <> piWidth * piHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A pixel stamp of &1 x &2 needs &3 colours, not &4", piWidth, piHeight, piWidth * piHeight, EXTENT(piColours))).
        Width = piWidth.
        Height = piHeight.
        EXTENT(mColour) = piWidth * piHeight.
        DO i = 1 TO piWidth * piHeight:
            mColour[i] = piColours[i].
            IF piColours[i] >= 0 THEN Count = Count + 1.
        END.
        IF Count > 0 THEN SET-SIZE(mCells) = Count * 12.
        DO i = 0 TO piWidth * piHeight - 1:
            IF mColour[i + 1] < 0 THEN NEXT.
            PUT-LONG(mCells, o * 12 + 1) = i MODULO piWidth.
            PUT-LONG(mCells, o * 12 + 5) = INTEGER(TRUNCATE(i / piWidth, 0)).
            PUT-LONG(mCells, o * 12 + 9) = mColour[i + 1].
            o = o + 1.
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC PixelStamp():
        Dispose().
    END DESTRUCTOR.

    /* Frees the cells. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        SET-SIZE(mCells) = 0.
    END METHOD.

    /* The colour of the pixel at (piX, piY) of the stamp, or -1 where it has none. Throws GridException outside it. */
    METHOD PUBLIC INTEGER ColourAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX = ? OR piX < 0 OR piX >= Width OR piY = ? OR piY < 0 OR piY >= Height THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Pixel (&1,&2) is outside a stamp of &3 x &4", piX, piY, Width, Height)).
        RETURN mColour[piY * Width + piX + 1].
    END METHOD.

    /* Copies the stamp onto a canvas with its top left at piX, piY. Pixels off the canvas are skipped. In a batch it goes
       into the batch. Throws GridException for no canvas, or a stamp that has been disposed of. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("There is no canvas to draw on").
        IF Count > 0 AND GET-SIZE(mCells) = 0 THEN UNDO, THROW NEW GridException("This pixel stamp has been disposed of").
        IF Count > 0 THEN poCanvas:PutCells(mCells, Count, piX, piY).
    END METHOD.

END CLASS.
