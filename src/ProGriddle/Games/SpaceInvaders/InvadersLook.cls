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

    &SCOPED-DEFINE COLOURS 79

    DEFINE PRIVATE STATIC VARIABLE sColours AS INTEGER NO-UNDO EXTENT 79.

    CONSTRUCTOR STATIC InvadersLook():
        DEFINE VARIABLE sHex AS CHARACTER NO-UNDO EXTENT 79.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sHex[1] = "06051A".  /* the top of the sky, almost black with a hint of indigo */
        sHex[2] = "1D0B3A".  /* the sky at the horizon, a deep violet */
        sHex[3] = "0A0814".  /* below the ground line */
        sHex[4] = "3CE6A0".  /* the ground line */
        sHex[5] = "4A5088".  /* a faint star */
        sHex[6] = "C9D2FF".  /* a bright star */
        sHex[7] = "6CD2EC".  /* a cyan star: not the cyan of the labels, or a star falling through a word would be taken for part of it */
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
        sHex[28] = "FFE14D".  /* a saucer score */
        sHex[29] = "FF7AD0".  /* the top of the title letters */
        sHex[30] = "6A5CFF".  /* the bottom of the title letters */
        sHex[31] = "FF4FA8".  /* row 1 invaders, hot pink */
        sHex[32] = "FFD6EC".  /* row 1 rim and eyes */
        sHex[33] = "B02E78".  /* row 1 limbs */
        sHex[34] = "D060FF".  /* row 2 invaders, orchid */
        sHex[35] = "F3D4FF".  /* row 2 rim and eyes */
        sHex[36] = "8A33C0".  /* row 2 limbs */
        sHex[37] = "8F7BFF".  /* row 3 invaders, periwinkle */
        sHex[38] = "DCD6FF".  /* row 3 rim and eyes */
        sHex[39] = "5546C4".  /* row 3 limbs */
        sHex[40] = "4AA8FF".  /* row 4 invaders, azure */
        sHex[41] = "D2ECFF".  /* row 4 rim and eyes */
        sHex[42] = "2468C8".  /* row 4 limbs */
        sHex[43] = "3DE8FF".  /* row 5 invaders, cyan */
        sHex[44] = "DDFCFF".  /* row 5 rim and eyes */
        sHex[45] = "1FA0C8".  /* row 5 limbs */
        sHex[46] = "F2FFF6".  /* the barrel core of the cannon */
        sHex[47] = "1FA860".  /* the base of the cannon */
        sHex[48] = "BFFFD4".  /* the outline of the cannon while it blinks */
        sHex[49] = "4FB6D6".  /* the tail of the player shot */
        sHex[50] = "E8FFF4".  /* a shield shimmer and chip sparks */
        sHex[51] = "A81F3C".  /* the underbelly of the saucer */
        sHex[52] = "FF5A7A".  /* the saucer body pulse, lighter */
        sHex[53] = "E0284A".  /* the saucer body pulse, darker */
        sHex[54] = "8E9420".  /* the tail of the rolling bomb */
        sHex[55] = "FF5238".  /* the plunger bomb */
        sHex[56] = "FFD9CC".  /* the head of the plunger bomb */
        sHex[57] = "9E2A1A".  /* the tail of the plunger bomb */
        sHex[58] = "F5FF5A".  /* the rolling bomb */
        sHex[59] = "FFFFE0".  /* the head of the rolling bomb */
        sHex[60] = "A8561C".  /* the tail of the squiggly bomb */
        sHex[61] = "FF9A3D".  /* embers of the cannon blast */
        sHex[62] = "A8872A".  /* the last frames of a score pop-up */
        sHex[63] = "7F8DB0".  /* the equals signs and secondary words */
        sHex[64] = "4C5490".  /* the credit line: near the faint star colour but not the same */
        sHex[65] = "2A1470".  /* the drop shadow of the title */
        sHex[66] = "3DE8FF".  /* the right end of the light bar */
        sHex[67] = "2A2A6A".  /* under the light bar */
        sHex[68] = "FF5A5A".  /* the top of GAME OVER */
        sHex[69] = "C8207A".  /* the bottom of GAME OVER */
        sHex[70] = "2A0B24".  /* the shadow of GAME OVER */
        sHex[71] = "5CFF8A".  /* the top of WAVE CLEARED */
        sHex[72] = "3DE8FF".  /* the bottom of WAVE CLEARED */
        sHex[73] = "06051A".  /* a one cell outline behind text over the rack */
        sHex[74] = "1A6A60".  /* the ground glow at y 231 */
        sHex[75] = "13454F".  /* the ground glow at y 230 */
        sHex[76] = "1C2150".  /* the ground glow at y 229 */
        sHex[77] = "0E3A38".  /* the cell under the ground line */
        sHex[78] = "FFFFFE".  /* the twinkle frame of a bright star: white, but not the exact white of the text */
        sHex[79] = "2A2060".  /* a hairline under the HUD */
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

    /* A tone of an invader of a rack row (0 at the top to 4) in a wave (1 on): tone 1 the body, 2 the lit rim and
       eyes, 3 the deep limbs. The five row colours rotate by one each wave, so wave 2 has the second row's colour
       on the top row. */
    METHOD PUBLIC STATIC INTEGER InvaderColour(INPUT piRow AS INTEGER, INPUT piWave AS INTEGER, INPUT piTone AS INTEGER):
        IF piRow = ? OR piRow < 0 OR piRow > 4 THEN UNDO, THROW NEW GridException("A rack row is 0 to 4, not " + STRING(piRow)).
        IF piWave = ? OR piWave < 1 THEN UNDO, THROW NEW GridException("A wave is 1 or more, not " + STRING(piWave)).
        IF piTone = ? OR piTone < 1 OR piTone > 3 THEN UNDO, THROW NEW GridException("A tone is 1 to 3, not " + STRING(piTone)).
        RETURN sColours[{&C-INV1-MAIN} + ((piRow + piWave - 1) MODULO 5) * 3 + piTone - 1].
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
