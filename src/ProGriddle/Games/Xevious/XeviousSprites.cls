/* The pictures of Xevious made ready to draw: a PixelStamp for every sprite of the design (made the first time it is asked for, then
   kept), and the colours of every ground tile for the land of an area (the ground family and the mood of the area, which tints the
   whole ground once). A sprite can be asked for turned by whole quarter turns clockwise (the tank, the shield plates). The class owns
   stamps and memory: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousSprites FINAL:

    /* room for every sprite, four ways round, and for every tile */
    &SCOPED-DEFINE SPRITES 100
    &SCOPED-DEFINE TILES 64
    &SCOPED-DEFINE TILE-BYTES 1024

    VAR PRIVATE PixelStamp[400] mStamps.
    VAR PRIVATE MEMPTR mTiles.
    VAR PRIVATE LOGICAL[{&TILES}] mTileMade.
    VAR PRIVATE LOGICAL mDry.
    VAR PRIVATE INTEGER mMood = -1.
    VAR PRIVATE LOGICAL mDisposed.

    /* True for the dry family of ground, and the mood (0 to 4) the tiles are made for now, -1 for none yet. */
    DEFINE PUBLIC PROPERTY Dry AS LOGICAL NO-UNDO
        GET():
            RETURN mDry.
        END GET.

    DEFINE PUBLIC PROPERTY Mood AS INTEGER NO-UNDO
        GET():
            RETURN mMood.
        END GET.

    /* How many percent of the way to Ink the ground tiles are made (0 for none): a veil for the title and the game over screens, made
       in the colours of the tiles once. Setting it makes the tiles again, as they are asked for. */
    DEFINE PUBLIC PROPERTY Veil AS INTEGER NO-UNDO INITIAL 0
        GET.
        SET(INPUT piPercent AS INTEGER):
            VAR INTEGER i.
            IF piPercent = ? OR piPercent < 0 OR piPercent > 100 THEN UNDO, THROW NEW GridException("A veil is 0 to 100 percent, not " + STRING(piPercent)).
            IF piPercent = Veil THEN RETURN.
            Veil = piPercent.
            DO i = 1 TO {&TILES}:
                mTileMade[i] = FALSE.
            END.
        END SET.

    CONSTRUCTOR PUBLIC XeviousSprites():
        SET-SIZE(mTiles) = {&TILES} * {&TILE-BYTES}.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC XeviousSprites():
        Dispose().
    END DESTRUCTOR.

    /* Frees the stamps and the tile colours. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        VAR INTEGER i.
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        DO i = 1 TO EXTENT(mStamps):
            IF VALID-OBJECT(mStamps[i]) THEN mStamps[i]:Dispose().
        END.
        SET-SIZE(mTiles) = 0.
    END METHOD.

    /* The stamp of a sprite as the design draws it. */
    METHOD PUBLIC PixelStamp Stamp(INPUT poPicture AS XeviousPicture):
        RETURN Turned(poPicture, 0).
    END METHOD.

    /* The stamp of a sprite turned piTurns quarter turns clockwise (0 to 3). Throws GridException for any other number. */
    METHOD PUBLIC PixelStamp Turned(INPUT poPicture AS XeviousPicture, INPUT piTurns AS INTEGER):
        VAR INTEGER slot.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER sx.
        VAR INTEGER sy.
        VAR INTEGER nw.
        VAR INTEGER nh.
        VAR CHARACTER rows.
        VAR INTEGER[] colours.
        IF piTurns = ? OR piTurns < 0 OR piTurns > 3 THEN UNDO, THROW NEW GridException("A sprite is turned 0 to 3 quarter turns, not " + STRING(piTurns)).
        slot = INTEGER(poPicture) * 4 + piTurns + 1.
        IF VALID-OBJECT(mStamps[slot]) THEN RETURN mStamps[slot].
        w = XeviousArt:Width(poPicture).
        h = XeviousArt:Height(poPicture).
        rows = XeviousArt:Rows(poPicture).
        nw = (IF piTurns MODULO 2 = 0 THEN w ELSE h).
        nh = (IF piTurns MODULO 2 = 0 THEN h ELSE w).
        EXTENT(colours) = nw * nh.
        DO y = 0 TO nh - 1:
            DO x = 0 TO nw - 1:
                /* the cell of the picture that lands on (x, y) after the turns */
                CASE piTurns:
                    WHEN 0 THEN ASSIGN sx = x sy = y.
                    WHEN 1 THEN ASSIGN sx = y sy = h - 1 - x.
                    WHEN 2 THEN ASSIGN sx = w - 1 - x sy = h - 1 - y.
                    OTHERWISE ASSIGN sx = w - 1 - y sy = x.
                END CASE.
                colours[y * nw + x + 1] = XeviousLook:CodeColour(SUBSTRING(ENTRY(sy + 1, rows, "/"), sx + 1, 1), FALSE).
            END.
        END.
        mStamps[slot] = NEW PixelStamp(nw, nh, colours).
        RETURN mStamps[slot].
    END METHOD.

    /* Makes the ground tiles for an area: its family and its mood tint. The tiles are made again, as they are asked for, whenever
       this changes. Throws GridException for an area under 1. */
    METHOD PUBLIC VOID ForArea(INPUT piArea AS INTEGER):
        VAR INTEGER i.
        IF piArea = ? OR piArea < 1 THEN UNDO, THROW NEW GridException("An area is 1 or more, not " + STRING(piArea)).
        IF XeviousAreas:IsDry(piArea) = mDry AND XeviousAreas:Mood(piArea) = mMood THEN RETURN.
        mDry = XeviousAreas:IsDry(piArea).
        mMood = XeviousAreas:Mood(piArea).
        DO i = 1 TO {&TILES}:
            mTileMade[i] = FALSE.
        END.
    END METHOD.

    /* Copies the 16 colours of one line (0 to 15) of a tile of the area's ground, 64 bytes, into a block of memory at piAt (a byte
       position counted from 1). The tile is made the first time it is asked for. */
    METHOD PUBLIC VOID TileLine(INPUT poTile AS XeviousTilePicture, INPUT piLine AS INTEGER, INPUT pmTo AS MEMPTR, INPUT piAt AS INTEGER):
        VAR INTEGER n.
        n = INTEGER(poTile).
        IF mMood < 0 THEN UNDO, THROW NEW GridException("The tiles are made for an area: call ForArea first").
        IF piLine = ? OR piLine < 0 OR piLine > 15 THEN UNDO, THROW NEW GridException("A tile line is 0 to 15, not " + STRING(piLine)).
        IF NOT mTileMade[n + 1] THEN MakeTile(poTile).
        COPY-LOB FROM mTiles STARTING AT n * {&TILE-BYTES} + piLine * 64 + 1 FOR 64 TO pmTo OVERLAY AT piAt.
    END METHOD.

    /* The colour of one pixel of a tile of the area's ground, as drawn. */
    METHOD PUBLIC INTEGER TilePixel(INPUT poTile AS XeviousTilePicture, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER n.
        n = INTEGER(poTile).
        IF mMood < 0 THEN UNDO, THROW NEW GridException("The tiles are made for an area: call ForArea first").
        IF piX = ? OR piX < 0 OR piX > 15 OR piY = ? OR piY < 0 OR piY > 15 THEN UNDO, THROW NEW GridException("A tile pixel is 0 to 15 across and down").
        IF NOT mTileMade[n + 1] THEN MakeTile(poTile).
        RETURN GET-LONG(mTiles, n * {&TILE-BYTES} + piY * 64 + piX * 4 + 1).
    END METHOD.

    /* The colours of a tile, with the mood of the area mixed in once. */
    METHOD PRIVATE VOID MakeTile(INPUT poTile AS XeviousTilePicture):
        VAR INTEGER n.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR CHARACTER rows.
        VAR CHARACTER ch.
        VAR INTEGER pct.
        VAR INTEGER tint.
        VAR CHARACTER lastIn = ?.
        VAR INTEGER lastOut.
        n = INTEGER(poTile).
        rows = XeviousTileArt:Rows(poTile).
        pct = XeviousAreas:MoodPercent(mMood).
        tint = XeviousLook:Colour(XeviousAreas:MoodTint(mMood)).
        DO y = 0 TO 15:
            DO x = 0 TO 15:
                ch = SUBSTRING(ENTRY(y + 1, rows, "/"), x + 1, 1).
                IF ch <> lastIn THEN DO:
                    lastIn = ch.
                    lastOut = XeviousLook:CodeColour(ch, mDry).
                    IF pct > 0 THEN lastOut = ColourMath:Mix(lastOut, tint, pct, 100).
                    IF Veil > 0 THEN lastOut = ColourMath:Mix(lastOut, XeviousLook:Colour(XeviousTint:Ink), Veil, 100).
                END.
                PUT-LONG(mTiles, n * {&TILE-BYTES} + y * 64 + x * 4 + 1) = lastOut.
            END.
        END.
        mTileMade[n + 1] = TRUE.
    END METHOD.

END CLASS.
