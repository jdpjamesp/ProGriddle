/* How Tetris looks. Two things live here.

   The look of the picture, "Lantern Glass" (docs/design/tetris-art.md): Colour gives the 0xRRGGBB number of a named
   colour (the Tint enum), read from hex text once when the class is first used, and Tones gives the five tones of a
   colour row (highlight, light, base, shade, edge) as the comma list a Tile wants: the seven pieces, the dead blocks of a
   game over, and the gold of a Tetris. TetrisArt has the shapes. This is the one place to change the colours.

   The old flat look: Palette gives a colour for each value of the "view" layer (see the ViewCode enum, 0 to 10), and
   TextSymbols one character for each, for drawing a grid as text in tests. The game keeps the view layer up to date
   whatever it is drawn with. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisLook FINAL:

    &SCOPED-DEFINE COLOURS 24

    DEFINE PRIVATE STATIC VARIABLE sColours AS INTEGER   NO-UNDO EXTENT 24.
    DEFINE PRIVATE STATIC VARIABLE sHexes   AS CHARACTER NO-UNDO EXTENT 24.
    /* the rows of tones: pieces 1 to 7 (I O T S Z J L), 8 the dead blocks, 9 gold */
    DEFINE PRIVATE STATIC VARIABLE sTones   AS CHARACTER NO-UNDO EXTENT 9.

    CONSTRUCTOR STATIC TetrisLook():
        DEFINE VARIABLE sHex AS CHARACTER NO-UNDO EXTENT 24.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sHex[1] = "0A0E16".   /* the background at the top, and the Snake strip */
        sHex[2] = "0E131E".   /* the background at the bottom */
        sHex[3] = "121A29".   /* a faint dot in the panel */
        sHex[4] = "0E1420".   /* inside a card and the NEXT box */
        sHex[5] = "2D3D5F".   /* the outer line of a card */
        sHex[6] = "1F2B44".   /* the inner line of a card */
        sHex[7] = "080C13".   /* the dark gap of the divider and the fill of a banner plate */
        sHex[8] = "EEF2F8".   /* numbers and words */
        sHex[9] = "7C8AA2".   /* labels and key hints */
        sHex[10] = "9AA8BE".  /* the best score and secondary lines */
        sHex[11] = "FFA24A".  /* the lamp: NEXT, the level, banner rules */
        sHex[12] = "FFC857".  /* good news: a new best, a Tetris */
        sHex[13] = "FFB27A".  /* GAME OVER, top row */
        sHex[14] = "E4503C".  /* GAME OVER, bottom row */
        sHex[15] = "070A10".  /* a one cell outline behind text */
        sHex[16] = "FFFFFF".  /* a flash, the first colour of a spark */
        sHex[17] = "0B111B".  /* an empty cell, top row */
        sHex[18] = "101A2B".  /* an empty cell, bottom row */
        sHex[19] = "3A4C70".  /* the outer pixel of a wall */
        sHex[20] = "26344F".  /* the inner pixel of a wall */
        sHex[21] = "4F6288".  /* the outline of the ghost */
        sHex[22] = "222F4A".  /* the hatch inside the ghost */
        sHex[23] = "E4503C".  /* the danger pulse of the walls, light */
        sHex[24] = "7A2A20".  /* the danger pulse of the walls, dark */
        DO i = 1 TO {&COLOURS}:
            sHexes[i] = sHex[i].
            sColours[i] = ColourMath:FromHex(sHex[i]).
        END.
        sTones[1] = "BFEDE5,6BD6C2,2BC4A8,1F8877,134C46".   /* I teal */
        sTones[2] = "FCEEC6,F8D67B,F5C542,A88932,5B4C21".   /* O gold */
        sTones[3] = "E1D3F4,B997E6,9B6BDB,6B4B9A,3B2C58".   /* T amethyst */
        sTones[4] = "D7EEC9,A3D780,7BC64A,558937,2F4C24".   /* S leaf */
        sTones[5] = "F7CAC4,EC8476,E4503C,9D392E,55221F".   /* Z vermilion */
        sTones[6] = "C5D5F6,799DE9,3F73E0,2C519D,1A2F5A".   /* J cobalt */
        sTones[7] = "FBDCC3,F6AE74,F28C38,A6622B,5A381E".   /* L tangerine */
        sTones[8] = "C7CAD0,7B8291,434D62,2F3747,1B212D".   /* the dead blocks */
        sTones[9] = "FFEECD,FFD889,FFC857,AF8B40,5F4D29".   /* gold */
    END CONSTRUCTOR.

    /* The colour of a named colour, as 0xRRGGBB. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS Tint):
        IF NOT VALID-OBJECT(poTint) THEN UNDO, THROW NEW GridException("A colour is a Tint entry, not unknown").
        RETURN sColours[INTEGER(poTint) + 1].
    END METHOD.

    /* The six hex digits of a named colour, for a tile legend. */
    METHOD PUBLIC STATIC CHARACTER Hex(INPUT poTint AS Tint):
        IF NOT VALID-OBJECT(poTint) THEN UNDO, THROW NEW GridException("A colour is a Tint entry, not unknown").
        RETURN sHexes[INTEGER(poTint) + 1].
    END METHOD.

    /* The five tones of a colour row, lightest first, as hex colours separated by commas. piRow is 1 to 7 for the pieces
       (I O T S Z J L), 8 for the dead blocks of a game over and 9 for gold. Throws GridException for any other number. */
    METHOD PUBLIC STATIC CHARACTER Tones(INPUT piRow AS INTEGER):
        IF piRow = ? OR piRow < 1 OR piRow > 9 THEN UNDO, THROW NEW GridException("A colour row is 1 to 9, not " + STRING(piRow)).
        RETURN sTones[piRow].
    END METHOD.

    /* The same row lit up, as a block is when it settles or is about to clear: everything one step lighter and the highlight
       pure white (tone 1 becomes white, tone 2 the old tone 1, and so on, the old tone 4 becoming the edge). */
    METHOD PUBLIC STATIC CHARACTER LitTones(INPUT piRow AS INTEGER):
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = Tones(piRow).
        RETURN SUBSTITUTE("FFFFFF,&1,&2,&3,&4", ENTRY(1, t), ENTRY(2, t), ENTRY(3, t), ENTRY(4, t)).
    END METHOD.

    /* The row with only its highlight turned white, for the second half of a lock flash. */
    METHOD PUBLIC STATIC CHARACTER WhiteTopTones(INPUT piRow AS INTEGER):
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = Tones(piRow).
        RETURN SUBSTITUTE("FFFFFF,&1,&2,&3,&4", ENTRY(2, t), ENTRY(3, t), ENTRY(4, t), ENTRY(5, t)).
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "12161B,3CC9D6,F2C14E,A06BE0,4CC38A,E5533D,4F7DE8,F0883E,2A3441,181C20,1A1F25".
    END METHOD.

    /* One character per view code, for drawing a grid as text in tests: . empty, the letters I O T S Z
       J L for the pieces, : for the ghost, | for the divider and _ for the panel. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN ".IOTSZJL:|_".
    END METHOD.

END CLASS.
