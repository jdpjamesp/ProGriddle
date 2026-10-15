/* How a Snake board is drawn. Palette gives a colour for each value of the "view" layer (see the ViewCode enum), in value
   order, for a plain view of the grid. The "Lantern Glass" look of the painter (docs/design/snake-art.md) is the rest: the
   named colours (Colour, Hex), the five tones of a colour row made from a base colour (ToneRow), the white of a flash
   and the steps of the crash fade. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeLook FINAL:

    DEFINE PRIVATE STATIC VARIABLE sColours AS INTEGER   NO-UNDO EXTENT 31.
    DEFINE PRIVATE STATIC VARIABLE sHexes   AS CHARACTER NO-UNDO EXTENT 31.

    CONSTRUCTOR STATIC SnakeLook():
        DEFINE VARIABLE sHex AS CHARACTER NO-UNDO EXTENT 31.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sHex[1] = "0A0E16".   /* the background at the top, and the strip */
        sHex[2] = "0E131E".   /* the background at the bottom */
        sHex[3] = "2D3D5F".   /* the rules of a banner plate */
        sHex[4] = "1F2B44".   /* the rule under the strip */
        sHex[5] = "080C13".   /* the fill of a banner plate */
        sHex[6] = "EEF2F8".   /* numbers and words */
        sHex[7] = "7C8AA2".   /* labels in the strip */
        sHex[8] = "9AA8BE".   /* the best score and secondary lines */
        sHex[9] = "FFA24A".   /* the lamp: the level, banner rules */
        sHex[10] = "FFC857".   /* good news: a new best, a win */
        sHex[11] = "FFB27A".   /* GAME OVER, top row */
        sHex[12] = "E4503C".   /* GAME OVER, bottom row */
        sHex[13] = "070A10".   /* a one pixel outline behind text */
        sHex[14] = "FFFFFF".   /* a flash, the first colour of a spark */
        sHex[15] = "0D1420".   /* an empty cell where x + y is even */
        sHex[16] = "101826".   /* an empty cell where x + y is odd */
        sHex[17] = "4A5C80".   /* the outer pixel row of the wall */
        sHex[18] = "26344F".   /* the second pixel row of the wall */
        sHex[19] = "FFA24A".   /* the four corner lamps */
        sHex[20] = "F4F7FB".   /* the eye white */
        sHex[21] = "0A0E16".   /* the pupil */
        sHex[22] = "E5533D".   /* the tongue */
        sHex[23] = "7A4A2A".   /* the apple stem */
        sHex[24] = "4FBF6A".   /* the apple leaf */
        sHex[25] = "4FD6A0".   /* the base of the head colour row */
        sHex[26] = "2FB383".   /* the base of the body colour row */
        sHex[27] = "27996F".   /* the base of the tail colour row */
        sHex[28] = "8FF0C8".   /* the base of the body when it brightens */
        sHex[29] = "E5533D".   /* the base of the apple colour row */
        sHex[30] = "05080F".   /* what the dimmed board and the dark tones are mixed with */
        sHex[31] = "2A3345".   /* what the body fades to when it crashes */
        DO i = 1 TO 31:
            sHexes[i] = sHex[i].
            sColours[i] = ColourMath:FromHex(sHex[i]).
        END.
    END CONSTRUCTOR.

    /* The colour of a named colour, as 0xRRGGBB. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS SnakeTint):
        IF NOT VALID-OBJECT(poTint) THEN UNDO, THROW NEW GridException("A colour is a SnakeTint entry, not unknown").
        RETURN sColours[INTEGER(poTint) + 1].
    END METHOD.

    /* The six hex digits of a named colour, for a tile legend. */
    METHOD PUBLIC STATIC CHARACTER Hex(INPUT poTint AS SnakeTint):
        IF NOT VALID-OBJECT(poTint) THEN UNDO, THROW NEW GridException("A colour is a SnakeTint entry, not unknown").
        RETURN sHexes[INTEGER(poTint) + 1].
    END METHOD.

    /* The five tones of a colour row made from its base colour, lightest first, as hex colours separated by commas: the base
       mixed with white by 70 and 30 percent, the base itself, and the base mixed with the shade colour by 32 and 64 percent. */
    METHOD PUBLIC STATIC CHARACTER ToneRow(INPUT piColour AS INTEGER):
        DEFINE VARIABLE shade AS INTEGER NO-UNDO.
        IF piColour = ? THEN UNDO, THROW NEW GridException("A colour row needs a colour").
        shade = Colour(SnakeTint:Shade).
        RETURN SUBSTITUTE("&1,&2,&3,&4,&5", ColourMath:ToHex(Blend(piColour, 16777215, 70)), ColourMath:ToHex(Blend(piColour, 16777215, 30)),
                          ColourMath:ToHex(piColour), ColourMath:ToHex(Blend(piColour, shade, 32)), ColourMath:ToHex(Blend(piColour, shade, 64))).
    END METHOD.

    /* A colour piPercent percent of the way to another, each channel rounded to the nearest whole number and a half to the
       even one, which is how the designer's rows were worked out. */
    METHOD PUBLIC STATIC INTEGER Blend(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER, INPUT piPercent AS INTEGER):
        IF piFrom = ? OR piTo = ? OR piPercent = ? OR piPercent < 0 OR piPercent > 100 THEN UNDO, THROW NEW GridException("A blend needs two colours and a percentage from 0 to 100").
        RETURN ColourMath:Rgb(BlendChannel(ColourMath:Red(piFrom), ColourMath:Red(piTo), piPercent),
                              BlendChannel(ColourMath:Green(piFrom), ColourMath:Green(piTo), piPercent),
                              BlendChannel(ColourMath:Blue(piFrom), ColourMath:Blue(piTo), piPercent)).
    END METHOD.

    METHOD PRIVATE STATIC INTEGER BlendChannel(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER, INPUT piPercent AS INTEGER):
        DEFINE VARIABLE hundredths AS INTEGER NO-UNDO.
        DEFINE VARIABLE whole      AS INTEGER NO-UNDO.
        DEFINE VARIABLE rest       AS INTEGER NO-UNDO.
        hundredths = piFrom * (100 - piPercent) + piTo * piPercent.
        whole = INTEGER(TRUNCATE(hundredths / 100, 0)).
        rest = hundredths - whole * 100.
        IF rest > 50 OR (rest = 50 AND whole MODULO 2 = 1) THEN whole = whole + 1.
        RETURN whole.
    END METHOD.

    /* The tones of a piece drawn white, for a flash. */
    METHOD PUBLIC STATIC CHARACTER FlashTones():
        RETURN "FFFFFF,FFFFFF,F4F7FB,D8DEE9,AEB8CB".
    END METHOD.

    /* The tones of the body at a step (1 to 5) of the fade of a crash: the body colour mixed with the colour it fades to,
       a fifth more each step. Throws GridException for any other step. */
    METHOD PUBLIC STATIC CHARACTER CrashTones(INPUT piStep AS INTEGER):
        IF piStep = ? OR piStep < 1 OR piStep > 5 THEN UNDO, THROW NEW GridException("A crash step is 1 to 5, not " + STRING(piStep)).
        RETURN ToneRow(Blend(Colour(SnakeTint:BodyBase), Colour(SnakeTint:CrashEnd), piStep * 20)).
    END METHOD.

    /* Cell colours: empty, body, head, food. */
    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "1E242B,3FAE78,8EF0C0,E5533D".
    END METHOD.

    /* One character per value, for drawing a board as text in tests: . empty, o body, @ head,
       * food. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN ".o@*".
    END METHOD.

END CLASS.
