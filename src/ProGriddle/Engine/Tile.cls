/* A small picture as a map of tones, the way the designer of a game draws a block: rows of characters separated by "/",
   one character a pixel. A dot is a pixel left out (the background shows through), the digits 1 to 5 are the five tones of
   a colour row (1 the highlight down to 5 the edge, so one drawing serves every colour), and a capital letter is a named
   colour that Colourise looks up in a legend. It is immutable. A square tile can be turned a quarter turn at a time.

     "5555/5115/5335/5555"      a bevelled square, 4 x 4

   Colourise gives the picture in real colours as a PixelStamp: the five tones as a comma list of hex colours, lightest
   first, and the legend as "A=RRGGBB,B=RRGGBB". */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.Tile FINAL:

    /* the characters of the picture, row by row */
    DEFINE PRIVATE VARIABLE mPixels AS CHARACTER NO-UNDO.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no rows, rows of different lengths, or a character that is not a dot, a digit 1 to 5 or a capital letter. */
    CONSTRUCTOR PUBLIC Tile(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE r    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE row  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ch   AS CHARACTER NO-UNDO.
        IF pcRows = ? OR LENGTH(pcRows) = 0 THEN UNDO, THROW NEW GridException("A tile needs some rows").
        Height = NUM-ENTRIES(pcRows, "/").
        Width = LENGTH(ENTRY(1, pcRows, "/")).
        IF Width < 1 THEN UNDO, THROW NEW GridException("A tile's rows need some pixels").
        DO r = 1 TO Height:
            row = ENTRY(r, pcRows, "/").
            IF LENGTH(row) <> Width THEN UNDO, THROW NEW GridException(SUBSTITUTE("Row &1 of a tile is &2 pixels long, not &3", r, LENGTH(row), Width)).
            DO c = 1 TO Width:
                ch = SUBSTRING(row, c, 1).
                IF ch <> "." AND INDEX("12345", ch) = 0 AND (ASC(ch) < 65 OR ASC(ch) > 90) THEN
                    UNDO, THROW NEW GridException("A tile pixel is a dot, 1 to 5 or a capital letter, not " + ch).
            END.
            mPixels = mPixels + row.
        END.
    END CONSTRUCTOR.

    /* The character at (piX, piY): a dot, a tone digit or a letter. */
    METHOD PUBLIC CHARACTER PixelAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX = ? OR piX < 0 OR piX >= Width OR piY = ? OR piY < 0 OR piY >= Height THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Pixel (&1,&2) is outside a tile of &3 x &4", piX, piY, Width, Height)).
        RETURN SUBSTRING(mPixels, piY * Width + piX + 1, 1).
    END METHOD.

    /* The tile turned clockwise piTurns quarter turns (any whole number, a negative one turns the other way). A pixel at
       row j, column i goes to row i, column size - 1 - j. Throws GridException for a tile that is not square. */
    METHOD PUBLIC Tile Turned(INPUT piTurns AS INTEGER):
        DEFINE VARIABLE n       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE picture AS CHARACTER NO-UNDO.
        DEFINE VARIABLE turned  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rows    AS CHARACTER NO-UNDO.
        IF Width <> Height THEN UNDO, THROW NEW GridException("Only a square tile can be turned").
        IF piTurns = ? THEN UNDO, THROW NEW GridException("A tile is turned a known number of times").
        n = piTurns MODULO 4.
        IF n < 0 THEN n = n + 4.
        picture = mPixels.
        DO k = 1 TO n:
            turned = FILL(" ", Width * Width).
            DO j = 0 TO Width - 1:
                DO i = 0 TO Width - 1:
                    SUBSTRING(turned, i * Width + (Width - 1 - j) + 1, 1) = SUBSTRING(picture, j * Width + i + 1, 1).
                END.
            END.
            picture = turned.
        END.
        DO j = 0 TO Width - 1:
            rows = rows + (IF j > 0 THEN "/" ELSE "") + SUBSTRING(picture, j * Width + 1, Width).
        END.
        RETURN NEW Tile(rows).
    END METHOD.

    /* The picture in colours as a stamp. piTones is five hex colours separated by commas, lightest (tone 1) first, and
       pcLegend is the named colours, "A=RRGGBB,B=RRGGBB" (empty for none). Throws GridException for a wrong number of
       tones, a legend entry that is not a letter, an equals sign and a colour, or a letter the picture uses that the
       legend does not have. */
    METHOD PUBLIC PixelStamp Colourise(INPUT pcTones AS CHARACTER, INPUT pcLegend AS CHARACTER):
        DEFINE VARIABLE tones   AS INTEGER   NO-UNDO EXTENT 5.
        DEFINE VARIABLE named   AS INTEGER   NO-UNDO EXTENT 26 INITIAL -1.
        DEFINE VARIABLE colours AS INTEGER   NO-UNDO EXTENT.
        DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE entry1  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ch      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE slot    AS INTEGER   NO-UNDO.
        IF pcTones = ? OR NUM-ENTRIES(pcTones) <> 5 THEN UNDO, THROW NEW GridException("A tile's tones are five hex colours separated by commas").
        DO i = 1 TO 5:
            tones[i] = ColourMath:FromHex(TRIM(ENTRY(i, pcTones))).
        END.
        IF pcLegend <> ? AND pcLegend <> "" THEN DO i = 1 TO NUM-ENTRIES(pcLegend):
            entry1 = TRIM(ENTRY(i, pcLegend)).
            IF LENGTH(entry1) < 3 OR SUBSTRING(entry1, 2, 1) <> "=" OR ASC(SUBSTRING(entry1, 1, 1)) < 65 OR ASC(SUBSTRING(entry1, 1, 1)) > 90 THEN
                UNDO, THROW NEW GridException("A legend entry is a capital letter, an equals sign and a colour, not " + entry1).
            named[ASC(SUBSTRING(entry1, 1, 1)) - 64] = ColourMath:FromHex(SUBSTRING(entry1, 3)).
        END.
        EXTENT(colours) = Width * Height.
        DO i = 1 TO Width * Height:
            ch = SUBSTRING(mPixels, i, 1).
            IF ch = "." THEN colours[i] = -1.
            ELSE IF INDEX("12345", ch) > 0 THEN colours[i] = tones[INTEGER(ch)].
            ELSE DO:
                slot = ASC(ch) - 64.
                IF named[slot] < 0 THEN UNDO, THROW NEW GridException("The legend has no colour for " + ch).
                colours[i] = named[slot].
            END.
        END.
        RETURN NEW PixelStamp(Width, Height, colours).
    END METHOD.

END CLASS.
