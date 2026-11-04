/* The soft glow round a character (section 6 of the design): every empty pixel next to a pixel of the picture, up, down, left or
   right, in a colour near the floor. It is worked out once from a Tile, as a list of offsets from the top left of the picture, and
   drawn before the character. It is only drawn where the canvas background is one of the three floor colours it is given, so it
   never lands on a wall line and the lines stay clean. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachHalo FINAL:

    DEFINE PRIVATE VARIABLE mX AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mY AS INTEGER NO-UNDO EXTENT.

    /* How many pixels the glow has. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The glow of a picture. Throws GridException for no picture. */
    CONSTRUCTOR PUBLIC ForEachHalo(INPUT poTile AS Tile):
        DEFINE VARIABLE w     AS INTEGER NO-UNDO.
        DEFINE VARIABLE h     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE full  AS LOGICAL NO-UNDO EXTENT.
        IF NOT VALID-OBJECT(poTile) THEN UNDO, THROW NEW GridException("A halo needs a picture").
        ASSIGN w = poTile:Width
               h = poTile:Height.
        /* the picture with a one pixel margin all round */
        EXTENT(full) = (w + 2) * (h + 2).
        DO y = 0 TO h - 1:
            DO x = 0 TO w - 1:
                full[(y + 1) * (w + 2) + x + 1 + 1] = poTile:PixelAt(x, y) <> ".".
            END.
        END.
        DO y = 0 TO h + 1:
            DO x = 0 TO w + 1:
                IF NOT full[y * (w + 2) + x + 1] AND Touches(full, w + 2, h + 2, x, y) THEN Count = Count + 1.
            END.
        END.
        IF Count = 0 THEN RETURN.
        EXTENT(mX) = Count.
        EXTENT(mY) = Count.
        DO y = 0 TO h + 1:
            DO x = 0 TO w + 1:
                IF NOT full[y * (w + 2) + x + 1] AND Touches(full, w + 2, h + 2, x, y) THEN DO:
                    n = n + 1.
                    mX[n] = x - 1.
                    mY[n] = y - 1.
                END.
            END.
        END.
    END CONSTRUCTOR.

    /* True when a pixel of the picture is next to the one at x, y. */
    METHOD PRIVATE LOGICAL Touches(INPUT pbFull AS LOGICAL EXTENT, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX > 0 AND pbFull[piY * piW + piX - 1 + 1] THEN RETURN TRUE.
        IF piX < piW - 1 AND pbFull[piY * piW + piX + 1 + 1] THEN RETURN TRUE.
        IF piY > 0 AND pbFull[(piY - 1) * piW + piX + 1] THEN RETURN TRUE.
        IF piY < piH - 1 AND pbFull[(piY + 1) * piW + piX + 1] THEN RETURN TRUE.
        RETURN FALSE.
    END METHOD.

    /* Draws the glow for a picture whose top left is at piX, piY, in piColour, on the pixels where the canvas background is piFloorA,
       piFloorB or piFloorC. The canvas may be in a batch. */
    METHOD PUBLIC VOID DrawTo(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER,
                              INPUT piFloorA AS INTEGER, INPUT piFloorB AS INTEGER, INPUT piFloorC AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        DO i = 1 TO Count:
            c = poCanvas:BackAt(piX + mX[i], piY + mY[i]).
            IF c = piFloorA OR c = piFloorB OR c = piFloorC THEN poCanvas:Plot(piX + mX[i], piY + mY[i], 0, piColour).
        END.
    END METHOD.

END CLASS.
