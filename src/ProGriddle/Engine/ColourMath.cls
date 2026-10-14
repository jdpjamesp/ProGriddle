/* Colours as 0xRRGGBB numbers, which is what a cell of a direct colour view holds: reading hex text, splitting
   a colour into its parts, putting the parts together and mixing two colours for a gradient or a fade. All of
   it is static, so a game asks it for a colour without making anything. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.ColourMath FINAL:

    /* A colour from six hex digits, such as FF4FA8. Throws GridException for anything else. */
    METHOD PUBLIC STATIC INTEGER FromHex(INPUT pcHex AS CHARACTER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE result AS INTEGER NO-UNDO.
        IF pcHex = ? OR LENGTH(pcHex) <> 6 THEN UNDO, THROW NEW GridException("A colour is six hex digits, not " + STRING(pcHex)).
        DO i = 1 TO 6:
            d = INDEX("0123456789ABCDEF", CAPS(SUBSTRING(pcHex, i, 1))) - 1.
            IF d < 0 THEN UNDO, THROW NEW GridException("A colour is six hex digits, not " + pcHex).
            result = result * 16 + d.
        END.
        RETURN result.
    END METHOD.

    /* The red, green and blue parts of a colour, each 0 to 255. */
    METHOD PUBLIC STATIC INTEGER Red(INPUT piColour AS INTEGER):
        RETURN INTEGER(TRUNCATE(piColour / 65536, 0)) MODULO 256.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Green(INPUT piColour AS INTEGER):
        RETURN INTEGER(TRUNCATE(piColour / 256, 0)) MODULO 256.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Blue(INPUT piColour AS INTEGER):
        RETURN piColour MODULO 256.
    END METHOD.

    /* The six hex digits of a colour, capitals, the way FromHex reads them. */
    METHOD PUBLIC STATIC CHARACTER ToHex(INPUT piColour AS INTEGER):
        RETURN HexByte(Red(piColour)) + HexByte(Green(piColour)) + HexByte(Blue(piColour)).
    END METHOD.

    METHOD PRIVATE STATIC CHARACTER HexByte(INPUT piValue AS INTEGER):
        RETURN SUBSTRING("0123456789ABCDEF", INTEGER(TRUNCATE(piValue / 16, 0)) + 1, 1) + SUBSTRING("0123456789ABCDEF", piValue MODULO 16 + 1, 1).
    END METHOD.

    /* A colour from its three parts. A part outside 0 to 255 is brought back inside. */
    METHOD PUBLIC STATIC INTEGER Rgb(INPUT piRed AS INTEGER, INPUT piGreen AS INTEGER, INPUT piBlue AS INTEGER):
        RETURN MINIMUM(255, MAXIMUM(0, piRed)) * 65536 + MINIMUM(255, MAXIMUM(0, piGreen)) * 256 + MINIMUM(255, MAXIMUM(0, piBlue)).
    END METHOD.

    /* A colour with each of its parts multiplied by piPercent percent (50 is half as bright, 100 is unchanged). A
       part that ends outside 0 to 255 is brought back inside. */
    METHOD PUBLIC STATIC INTEGER Scale(INPUT piColour AS INTEGER, INPUT piPercent AS INTEGER):
        RETURN Rgb(INTEGER(ROUND(Red(piColour) * piPercent / 100, 0)),
                   INTEGER(ROUND(Green(piColour) * piPercent / 100, 0)),
                   INTEGER(ROUND(Blue(piColour) * piPercent / 100, 0))).
    END METHOD.

    /* The colour piPart steps of the way from piFrom to piTo, out of piSteps: 0 gives piFrom, piSteps gives
       piTo. piSteps below 1 gives piFrom. */
    METHOD PUBLIC STATIC INTEGER Mix(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER, INPUT piPart AS INTEGER, INPUT piSteps AS INTEGER):
        IF piSteps < 1 THEN RETURN piFrom.
        piPart = MINIMUM(piSteps, MAXIMUM(0, piPart)).
        RETURN Rgb(Red(piFrom) + INTEGER(ROUND((Red(piTo) - Red(piFrom)) * piPart / piSteps, 0)),
                   Green(piFrom) + INTEGER(ROUND((Green(piTo) - Green(piFrom)) * piPart / piSteps, 0)),
                   Blue(piFrom) + INTEGER(ROUND((Blue(piTo) - Blue(piFrom)) * piPart / piSteps, 0))).
    END METHOD.

END CLASS.
