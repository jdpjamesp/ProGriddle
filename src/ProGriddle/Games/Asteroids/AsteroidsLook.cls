/* The colours of Asteroids, as 0xRRGGBB numbers (what a cell of the view holds): the designer's "Obsidian Line"
   palette from docs/design/asteroids-art.md. Every colour has a number in Colours.i. They are read from hex text
   once, when the class is first used, so asking for one in a frame costs nothing. This is the one place to change
   the look of the colours, with AsteroidsArt for the shapes. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsLook FINAL:

    &SCOPED-DEFINE COLOURS 72

    DEFINE PRIVATE STATIC VARIABLE sColours AS INTEGER NO-UNDO EXTENT 72.

    CONSTRUCTOR STATIC AsteroidsLook():
        DEFINE VARIABLE sHex AS CHARACTER NO-UNDO EXTENT 72.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sHex[1] = "030508".  /* the vignette at the screen edge */
        sHex[2] = "0B1119".  /* the vignette at the middle */
        sHex[3] = "141B27".  /* far dust */
        sHex[4] = "1C2434".  /* mid dust */
        sHex[5] = "2A3448".  /* near dust */
        sHex[6] = "FFF4DC".  /* the ship outline */
        sHex[7] = "5B4E34".  /* the ship glow */
        sHex[8] = "B8A47A".  /* the line down the ship */
        sHex[9] = "D9CBA8".  /* lives icons in the HUD */
        sHex[10] = "FFC24D".  /* thruster flame outline */
        sHex[11] = "FFF3C4".  /* thruster flame inner line */
        sHex[12] = "FFE29A".  /* the respawn ring */
        sHex[13] = "FFFFFF".  /* player shot head */
        sHex[14] = "E8DCC0".  /* first trail cell */
        sHex[15] = "9C9078".  /* second trail cell */
        sHex[16] = "544C3C".  /* third trail cell */
        sHex[17] = "7F8EA3".  /* large rock outline */
        sHex[18] = "A9B6C8".  /* medium rock outline */
        sHex[19] = "D6DEE9".  /* small rock outline */
        sHex[20] = "FFFFFF".  /* hit flash and spawn flash, any object */
        sHex[21] = "FF7A4D".  /* large saucer outline and its shots */
        sHex[22] = "5A2414".  /* large saucer glow */
        sHex[23] = "FF4040".  /* small saucer outline and its shots */
        sHex[24] = "5A1414".  /* small saucer glow */
        sHex[25] = "FFD9B8".  /* middle cell of a saucer shot */
        sHex[26] = "FF7A4D".  /* the saucer incoming edge marker */
        sHex[27] = "F4F7FB".  /* numbers and words */
        sHex[28] = "6F7C90".  /* SCORE, WAVE, HI-SCORE labels */
        sHex[29] = "8FA0B8".  /* hi-score number, controls hint */
        sHex[30] = "FFE29A".  /* pop-ups, NEW HI-SCORE, score pulse */
        sHex[31] = "A58E52".  /* last frames of a pop-up */
        sHex[32] = "05070B".  /* a one cell outline behind text */
        sHex[33] = "F4F7FB".  /* the vector title strokes */
        sHex[34] = "2A3B58".  /* the title glow */
        sHex[35] = "1C2B44".  /* the rule under the title */
        sHex[36] = "F4F7FB".  /* WAVE banner, top row */
        sHex[37] = "8FA0B8".  /* WAVE banner, bottom row */
        sHex[38] = "FF9A6B".  /* GAME OVER, top row */
        sHex[39] = "FF4040".  /* GAME OVER, bottom row */
        sHex[40] = "4A5566".  /* large rocks behind the title */
        sHex[41] = "5F6C80".  /* medium rocks behind the title */
        sHex[42] = "7A889C".  /* small rocks behind the title */
        sHex[43] = "3A3222".  /* the second step of the ship wrap flash */
        sHex[44] = "1F1B13".  /* the third step of the ship wrap flash */
        sHex[45] = "FFC24D".  /* step 1 of the exhaust ramp */
        sHex[46] = "E8A93C".  /* step 2 of the exhaust ramp */
        sHex[47] = "A8772A".  /* step 3 of the exhaust ramp */
        sHex[48] = "5E4318".  /* step 4 of the exhaust ramp */
        sHex[49] = "D6DEE9".  /* step 1 of the rock debris ramp */
        sHex[50] = "A9B6C8".  /* step 2 of the rock debris ramp */
        sHex[51] = "7F8EA3".  /* step 3 of the rock debris ramp */
        sHex[52] = "5C6878".  /* step 4 of the rock debris ramp */
        sHex[53] = "3C4552".  /* step 5 of the rock debris ramp */
        sHex[54] = "222831".  /* step 6 of the rock debris ramp */
        sHex[55] = "FFD9B8".  /* step 1 of the large saucer debris ramp */
        sHex[56] = "FF8A4D".  /* step 2 of the large saucer debris ramp */
        sHex[57] = "D8553A".  /* step 3 of the large saucer debris ramp */
        sHex[58] = "9C3A2A".  /* step 4 of the large saucer debris ramp */
        sHex[59] = "5C241C".  /* step 5 of the large saucer debris ramp */
        sHex[60] = "2E1410".  /* step 6 of the large saucer debris ramp */
        sHex[61] = "FFD0C8".  /* step 1 of the small saucer debris ramp */
        sHex[62] = "FF5A4A".  /* step 2 of the small saucer debris ramp */
        sHex[63] = "D83A3A".  /* step 3 of the small saucer debris ramp */
        sHex[64] = "9C2A2A".  /* step 4 of the small saucer debris ramp */
        sHex[65] = "5C1A1A".  /* step 5 of the small saucer debris ramp */
        sHex[66] = "2E0E0E".  /* step 6 of the small saucer debris ramp */
        sHex[67] = "FFF4DC".  /* step 1 of the ship debris ramp */
        sHex[68] = "D9CBA8".  /* step 2 of the ship debris ramp */
        sHex[69] = "A8997A".  /* step 3 of the ship debris ramp */
        sHex[70] = "766B54".  /* step 4 of the ship debris ramp */
        sHex[71] = "463F32".  /* step 5 of the ship debris ramp */
        sHex[72] = "24201A".  /* step 6 of the ship debris ramp */
        DO i = 1 TO {&COLOURS}:
            sColours[i] = ColourMath:FromHex(sHex[i]).
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

END CLASS.
