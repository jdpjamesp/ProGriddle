/* Draws characters from AsciiFont onto a PixelCanvas, 8 x 14 pixels a cell. Each glyph in each colour is turned into a PixelStamp
   the first time it is asked for and kept, so a screen of a thousand characters is a thousand quick copies and no per pixel work.
   The stamps are found by a small hash table of the code and the colour. When it is nearly full every stamp is freed and the
   table starts again (a game uses a few hundred pairs at most).

   A glyph is drawn by its code: INTEGER of an ASCII character (ASC) or of an AsciiExtra. Pixels of the glyph that are off are left
   alone, so the background shows through, and the whole thing goes into the batch when the canvas is in one. Position is in pixels.

   The pen owns memory (the stamps): the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.AsciiPen FINAL:

    &SCOPED-DEFINE SLOTS 1021
    &SCOPED-DEFINE MOST 700

    VAR PRIVATE INTEGER[{&SLOTS}] mKey.
    VAR PRIVATE PixelStamp[{&SLOTS}] mStamp.
    VAR PRIVATE INTEGER mUsed.

    /* How many stamps are kept now. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            RETURN mUsed.
        END GET.

    /* How many times the table has been emptied to make room. */
    DEFINE PUBLIC PROPERTY Flushes AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DESTRUCTOR PUBLIC AsciiPen():
        Dispose().
    END DESTRUCTOR.

    /* The width in pixels of a piece of text: 8 a character. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcText AS CHARACTER):
        IF pcText = ? THEN RETURN 0.
        RETURN LENGTH(pcText) * AsciiFont:GlyphWidth().
    END METHOD.

    /* The stamp for a glyph in a colour (0xRRGGBB), made if there is not one already. A code with no glyph gives a question mark.
       Throws GridException for a colour outside 0 to 16777215. */
    METHOD PUBLIC PixelStamp Stamp(INPUT piCode AS INTEGER, INPUT piColour AS INTEGER):
        VAR INTEGER code.
        VAR INTEGER key.
        VAR INTEGER slot.
        IF piColour = ? OR piColour < 0 OR piColour > 16777215 THEN
            UNDO, THROW NEW GridException("A glyph colour is 0 to 16777215, not " + STRING(piColour)).
        code = (IF AsciiFont:HasGlyph(piCode) THEN piCode ELSE ASC("?")).
        /* the key is never 0, so 0 can mean an empty slot */
        key = (code - AsciiFont:FirstCode()) * 16777216 + piColour + 1.
        slot = key MODULO {&SLOTS} + 1.
        DO WHILE mKey[slot] <> 0:
            IF mKey[slot] = key THEN RETURN mStamp[slot].
            slot = slot MODULO {&SLOTS} + 1.
        END.
        IF mUsed >= {&MOST} THEN DO:
            Dispose().
            Flushes = Flushes + 1.
            RETURN Stamp(piCode, piColour).
        END.
        mKey[slot] = key.
        mStamp[slot] = MakeStamp(code, piColour).
        mUsed = mUsed + 1.
        RETURN mStamp[slot].
    END METHOD.

    /* Draws one glyph with its top left at (piX, piY). Throws GridException for no canvas. */
    METHOD PUBLIC VOID Glyph(INPUT poCanvas AS PixelCanvas, INPUT piCode AS INTEGER, INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        Stamp(piCode, piColour):DrawTo(poCanvas, piX, piY).
    END METHOD.

    /* Draws a piece of text, one glyph after another, with its top left at (piX, piY). */
    METHOD PUBLIC VOID Text(INPUT poCanvas AS PixelCanvas, INPUT pcText AS CHARACTER, INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER i.
        IF pcText = ? THEN RETURN.
        DO i = 1 TO LENGTH(pcText):
            Glyph(poCanvas, ASC(SUBSTRING(pcText, i, 1)), piColour, piX + (i - 1) * AsciiFont:GlyphWidth(), piY).
        END.
    END METHOD.

    /* Frees every stamp. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            IF mKey[i] <> 0 THEN DO:
                IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
                mStamp[i] = ?.
                mKey[i] = 0.
            END.
        END.
        mUsed = 0.
    END METHOD.

    METHOD PRIVATE PixelStamp MakeStamp(INPUT piCode AS INTEGER, INPUT piColour AS INTEGER):
        VAR INTEGER[] colours.
        VAR INTEGER x.
        VAR INTEGER y.
        EXTENT(colours) = AsciiFont:GlyphWidth() * AsciiFont:GlyphHeight().
        DO y = 0 TO AsciiFont:GlyphHeight() - 1:
            DO x = 0 TO AsciiFont:GlyphWidth() - 1:
                colours[y * AsciiFont:GlyphWidth() + x + 1] = (IF AsciiFont:PixelOn(piCode, x, y) THEN piColour ELSE -1).
            END.
        END.
        RETURN NEW PixelStamp(AsciiFont:GlyphWidth(), AsciiFont:GlyphHeight(), colours).
    END METHOD.

END CLASS.
