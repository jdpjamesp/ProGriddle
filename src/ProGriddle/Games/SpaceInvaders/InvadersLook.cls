/* The colours of Space Invaders, as 0xRRGGBB numbers (what a cell of the view holds), with a way to mix two
   of them. Every colour has a number in Colours.i. They are read from hex text once, when the class is first
   used, so asking for one in a frame costs nothing.

   This is the other place to change the look, with InvadersArt: the palette is one list. Mix is for the
   gradients, the sky from the top to the horizon, a shield from its top to its foot, the title letters. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersLook FINAL:

    {ProGriddle/Games/SpaceInvaders/Colours.i}

    &SCOPED-DEFINE COLOURS 30

    DEFINE PRIVATE STATIC VARIABLE sColours AS INTEGER NO-UNDO EXTENT 30.

    CONSTRUCTOR STATIC InvadersLook():
        DEFINE VARIABLE sHex AS CHARACTER NO-UNDO EXTENT 30.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sHex[1] = "06051A".  /* the top of the sky, almost black with a hint of indigo */
        sHex[2] = "1D0B3A".  /* the sky at the horizon, a deep violet */
        sHex[3] = "0A0814".  /* below the ground line */
        sHex[4] = "3CE6A0".  /* the ground line */
        sHex[5] = "4A5088".  /* a faint star */
        sHex[6] = "C9D2FF".  /* a bright star */
        sHex[7] = "7FE7FF".  /* a cyan star */
        sHex[8] = "FF4FA8".  /* the squid, hot pink */
        sHex[9] = "FFE0F2".  /* the squid eyes */
        sHex[10] = "A06BFF".  /* the crab, violet */
        sHex[11] = "EFE6FF".  /* the crab eyes */
        sHex[12] = "3DE8FF".  /* the octopus, cyan */
        sHex[13] = "E2FCFF".  /* the octopus eyes */
        sHex[14] = "5CFF8A".  /* the cannon, mint green */
        sHex[15] = "FFFFFF".  /* the tip of the barrel */
        sHex[16] = "FF3B5C".  /* the saucer, red */
        sHex[17] = "FFE14D".  /* the saucer lights */
        sHex[18] = "8CFFC8".  /* the top of a shield */
        sHex[19] = "1FA868".  /* the bottom of a shield */
        sHex[20] = "FFB13D".  /* an alien bomb, amber */
        sHex[21] = "FFF2C4".  /* the tip of a bomb */
        sHex[22] = "A8F6FF".  /* the player shot */
        sHex[23] = "FFFFFF".  /* the head of the shot */
        sHex[24] = "FFFFFF".  /* a flash of white */
        sHex[25] = "FFFFFF".  /* the numbers and words */
        sHex[26] = "7FE7FF".  /* the labels of the scores */
        sHex[27] = "FF4F7A".  /* GAME OVER */
        sHex[28] = "FFD84D".  /* a saucer score */
        sHex[29] = "FF7AD0".  /* the top of the title letters */
        sHex[30] = "6A5CFF".  /* the bottom of the title letters */
        DO i = 1 TO {&COLOURS}:
            sColours[i] = FromHex(sHex[i]).
        END.
    END CONSTRUCTOR.

    /* The colour with a number from Colours.i, as 0xRRGGBB. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT piColour AS INTEGER):
        IF piColour = ? OR piColour < 1 OR piColour > {&COLOURS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A colour is 1 to &1, not &2", {&COLOURS}, piColour)).
        RETURN sColours[piColour].
    END METHOD.

    /* How many colours there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN {&COLOURS}.
    END METHOD.

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

    /* A colour from its three parts. A part outside 0 to 255 is brought back inside. */
    METHOD PUBLIC STATIC INTEGER Rgb(INPUT piRed AS INTEGER, INPUT piGreen AS INTEGER, INPUT piBlue AS INTEGER):
        RETURN MINIMUM(255, MAXIMUM(0, piRed)) * 65536 + MINIMUM(255, MAXIMUM(0, piGreen)) * 256 + MINIMUM(255, MAXIMUM(0, piBlue)).
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
