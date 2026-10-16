/* Draws Blast Buddies in the "Sunny Side" look (docs/design/blast-buddies-art.md). It reads a BlastBuddiesGame, never changes it, and
   paints the picture on a pixel canvas over the game's own grid, then hands the grid to the window's renderer (the inner one).

   What is kept in the picture's background (the back layer of the canvas): the sky with the sun and the far hills, the clouds, and the
   ground, coloured by the rule of Terrain. Only what changes is coloured again: when a blast has dirtied a box of the ground
   (Terrain:HasDirty) that box is, and when the clouds drift (1 pixel every 800 ms, less in wind) their boxes are. What is drawn every
   frame, over the background: the water (a swell behind, four frames of waves, the body of the sea) and the strip of shore that
   stands in the waves.

   The painter owns a canvas, a sky canvas and stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesPainter FINAL IMPLEMENTS IGridRenderer:

    &SCOPED-DEFINE W 384
    &SCOPED-DEFINE H 240
    /* the row where the water begins, the first row the swell behind it can cover, and the seven rows of ground (222 to 228) that are
       drawn over the water again */
    &SCOPED-DEFINE WATER 226
    &SCOPED-DEFINE SHORE 222
    &SCOPED-DEFINE SHORE-ROWS 7
    &SCOPED-DEFINE KIND-LAND 1

    DEFINE PRIVATE VARIABLE mInner     AS IGridRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame      AS BlastBuddiesGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSkyGrid   AS Grid          NO-UNDO.
    DEFINE PRIVATE VARIABLE mSky       AS PixelCanvas   NO-UNDO.
    DEFINE PRIVATE VARIABLE mWave      AS PixelStamp    NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mDisposed  AS LOGICAL       NO-UNDO.
    DEFINE PRIVATE VARIABLE mSerial    AS INTEGER       NO-UNDO INITIAL -1.
    /* the colours of the sea and the sky, got once for the theme of the map */
    DEFINE PRIVATE VARIABLE mWaterBack AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mWater     AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mCloud     AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mCloudShade AS INTEGER      NO-UNDO.
    /* the colour of the ground in the seven rows the sea is drawn over, row by row, -1 for none */
    DEFINE PRIVATE VARIABLE mShore     AS INTEGER       NO-UNDO EXTENT 2688.
    /* the clouds: where each began, its size, how far all have drifted, and the time of the last drift */
    DEFINE PRIVATE VARIABLE mCloudX    AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mCloudY    AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mCloudN    AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mDrift     AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mDriftMs   AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastMs    AS INTEGER       NO-UNDO.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGame:Grid.
        END GET.

    /* How far the clouds have drifted since the map began, in pixels (negative to the left). */
    DEFINE PUBLIC PROPERTY CloudDrift AS INTEGER NO-UNDO
        GET():
            RETURN mDrift.
        END GET.

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC BlastBuddiesPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS BlastBuddiesGame):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Blast Buddies painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Blast Buddies painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mCanvas = NEW PixelCanvas(poGame:Grid).
        mSkyGrid = NEW Grid(NEW ArrayStore({&W}, {&H}, "view,kind,back")).
        mSky = NEW PixelCanvas(mSkyGrid).
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC BlastBuddiesPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the grid to the window's renderer. Throws GridException for a game that is not a Blast
       Buddies game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, BlastBuddiesGame) THEN UNDO, THROW NEW GridException("A Blast Buddies painter draws a Blast Buddies game").
        IF mSerial <> mGame:MapSerial THEN StartMap().
        SyncClouds().
        SyncLand().
        mCanvas:Restore().
        DrawWater().
        mInner:Render(mGame:Grid, poGame).
    END METHOD.

    /* Frees the canvases and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        DO i = 1 TO 4:
            IF VALID-OBJECT(mWave[i]) THEN mWave[i]:Dispose().
        END.
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mSky) THEN mSky:Dispose().
        IF VALID-OBJECT(mSkyGrid) THEN mSkyGrid:Dispose().
    END METHOD.

    /* ================================ a new map ================================ */

    /* The colour of a key in the theme of the map. */
    METHOD PRIVATE INTEGER Look(INPUT poKey AS ThemeKey):
        RETURN TerrainThemes:Colour(mGame:Setup:LandTheme, poKey).
    END METHOD.

    /* Everything that belongs to one map: the sky, the waves, the clouds and the ground, drawn from the beginning. */
    METHOD PRIVATE VOID StartMap():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mSerial = mGame:MapSerial.
        mWaterBack = Look(ThemeKey:WaterBack).
        mWater = Look(ThemeKey:Water).
        mCloud = Look(ThemeKey:Cloud).
        mCloudShade = Look(ThemeKey:CloudShade).
        DO i = 1 TO 4:
            IF VALID-OBJECT(mWave[i]) THEN mWave[i]:Dispose().
        END.
        MakeWaves().
        mCloudX[1] = 40.
        mCloudY[1] = 30.
        mCloudN[1] = 3.
        mCloudX[2] = 150.
        mCloudY[2] = 56.
        mCloudN[2] = 2.
        mCloudX[3] = 230.
        mCloudY[3] = 24.
        mCloudN[3] = 3.
        mCloudX[4] = 352.
        mCloudY[4] = 86.
        mCloudN[4] = 2.
        mDrift = 0.
        mDriftMs = 0.
        mLastMs = mGame:ElapsedMs.
        DrawSky().
        mSky:BakeView().
        mCanvas:LoadBack(mSky).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        PutLand(0, 0, {&W} - 1, {&H} - 1).
        DO i = 1 TO 4:
            PutBox(CloudLeft(i), CloudTop(i), CloudRight(i), CloudBottom(i)).
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
        FillShore().
        mGame:Land:ClearDirty().
    END METHOD.

    /* The sky: a gradient, the sun and its ring of sparkles, and the far hills, drawn on the sky canvas. */
    METHOD PRIVATE VOID DrawSky():
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2   AS INTEGER NO-UNDO.
        DEFINE VARIABLE h    AS INTEGER NO-UNDO.
        DEFINE VARIABLE skyTop AS INTEGER NO-UNDO.
        DEFINE VARIABLE skyLow AS INTEGER NO-UNDO.
        DEFINE VARIABLE far1 AS INTEGER NO-UNDO.
        DEFINE VARIABLE farT AS INTEGER NO-UNDO.
        skyTop = Look(ThemeKey:SkyTop).
        skyLow = Look(ThemeKey:SkyLow).
        far1 = Look(ThemeKey:Far).
        farT = Look(ThemeKey:FarTop).
        mSky:BeginBatch().
        DO y = 0 TO {&H} - 1:
            mSky:DrawLine(0, y, {&W} - 1, y, 0, ColourMath:Mix(skyTop, skyLow, MINIMUM(y, 200), 200)).
        END.
        /* the hills: from row h down, the top row lit */
        DO x = 0 TO {&W} - 1:
            h = 168 + INTEGER(ROUND(10 * BuddyMath:SinRad(x / 31 + 0.7) + 5 * BuddyMath:SinRad(x / 13), 0)).
            mSky:DrawLine(x, h, x, {&H} - 1, 0, far1).
            mSky:DrawLine(x, h, x, h, 0, farT).
        END.
        mSky:EndBatch().
        /* the sun, a disc of radius 13 at (316, 44), and a ring of sparkles round it */
        DO y = 44 - 17 TO 44 + 17:
            DO x = 316 - 17 TO 316 + 17:
                d2 = (x - 316) * (x - 316) + (y - 44) * (y - 44).
                IF d2 <= 169 THEN mSky:Plot(x, y, 0, Look(ThemeKey:Sun)).
                ELSE IF d2 >= 240 AND d2 <= 272 AND (x + y) MODULO 4 <> 0 THEN mSky:Plot(x, y, 0, Look(ThemeKey:SunRing)).
            END.
        END.
    END METHOD.

    /* The four frames of waves, each 16 wide and 3 high; F is foam, T the wave top and a dot lets the swell behind show. */
    METHOD PRIVATE VOID MakeWaves():
        DEFINE VARIABLE rows   AS CHARACTER NO-UNDO EXTENT 4.
        DEFINE VARIABLE f      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ch     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE colours AS INTEGER  NO-UNDO EXTENT 48.
        rows[1] = "....FF.........." + "..FTTTF......FF." + "FTTTTTTTF..FTTTT".
        rows[2] = "........FF......" + "......FTTTF....." + ".FF..FTTTTTTTF..".
        rows[3] = "............FF.." + ".F........FTTTF." + "TTTF.....FTTTTTT".
        rows[4] = "FF.............." + "TTF..........FTT" + "TTTTTF..FF..FTTT".
        DO f = 1 TO 4:
            DO i = 1 TO 48:
                ch = SUBSTRING(rows[f], i, 1).
                colours[i] = (IF ch = "F" THEN Look(ThemeKey:Foam) ELSE IF ch = "T" THEN Look(ThemeKey:WaterTop) ELSE -1).
            END.
            mWave[f] = NEW PixelStamp(16, 3, colours).
        END.
    END METHOD.

    /* ================================ the clouds ================================ */

    /* How wide a cloud of a size is, with its circles. */
    METHOD PRIVATE INTEGER CloudWidth(INPUT piIndex AS INTEGER):
        RETURN 9 * (mCloudN[piIndex] + 1) + 12.
    END METHOD.

    /* The column of the middle of a cloud's first circle now. A cloud that drifts off one side comes back in at the other, after a gap
       as wide as itself, so it goes round a loop of the map and the cloud. */
    METHOD PRIVATE INTEGER CloudOrigin(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        DEFINE VARIABLE v      AS INTEGER NO-UNDO.
        period = {&W} + CloudWidth(piIndex).
        v = (mCloudX[piIndex] + CloudWidth(piIndex) + mDrift) MODULO period.
        IF v < 0 THEN v = v + period.
        RETURN v - CloudWidth(piIndex).
    END METHOD.

    METHOD PRIVATE INTEGER CloudLeft(INPUT piIndex AS INTEGER):
        RETURN CloudOrigin(piIndex) - 7.
    END METHOD.

    METHOD PRIVATE INTEGER CloudRight(INPUT piIndex AS INTEGER):
        RETURN CloudOrigin(piIndex) + 9 * (mCloudN[piIndex] + 1) + 7.
    END METHOD.

    METHOD PRIVATE INTEGER CloudTop(INPUT piIndex AS INTEGER):
        RETURN mCloudY[piIndex] - 11.
    END METHOD.

    METHOD PRIVATE INTEGER CloudBottom(INPUT piIndex AS INTEGER):
        RETURN mCloudY[piIndex] + 5.
    END METHOD.

    /* The colour of the cloud at a pixel, or -1 if no cloud is there. A cloud is n + 2 circles in a row (radius 6 and a little higher
       for the odd ones, radius 5 for the even), and its underside is shaded. */
    METHOD PRIVATE INTEGER CloudAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE c  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ox AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DEFINE VARIABLE r  AS INTEGER NO-UNDO.
        DO c = 1 TO 4:
            IF piY < mCloudY[c] - 10 OR piY > mCloudY[c] + 3 THEN NEXT.
            ox = CloudOrigin(c).
            IF piX < ox - 6 OR piX > ox + 9 * (mCloudN[c] + 1) + 6 THEN NEXT.
            DO i = 0 TO mCloudN[c] + 1:
                cx = ox + 9 * i.
                IF i MODULO 2 = 1 THEN ASSIGN cy = mCloudY[c] - 4 r = 6.
                ELSE ASSIGN cy = mCloudY[c] - 2 r = 5.
                IF (piX - cx) * (piX - cx) + (piY - cy) * (piY - cy) <= r * r THEN
                    RETURN (IF piY >= mCloudY[c] + 2 THEN mCloudShade ELSE mCloud).
            END.
        END.
        RETURN -1.
    END METHOD.

    /* Lets the clouds drift with the time that has passed: one pixel every 800 - 60 x wind ms, to the right unless the wind blows left.
       The boxes the clouds were in and move to are coloured again. */
    METHOD PRIVATE VOID SyncClouds():
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir    AS INTEGER NO-UNDO.
        DEFINE VARIABLE moved  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE l      AS INTEGER NO-UNDO EXTENT 4.
        DEFINE VARIABLE r      AS INTEGER NO-UNDO EXTENT 4.
        period = 800 - 60 * ABSOLUTE(mGame:Wind).
        dir = (IF mGame:Wind < 0 THEN -1 ELSE 1).
        mDriftMs = mDriftMs + MAXIMUM(mGame:ElapsedMs - mLastMs, 0).
        mLastMs = mGame:ElapsedMs.
        IF mDriftMs < period THEN RETURN.
        DO i = 1 TO 4:
            l[i] = CloudLeft(i).
            r[i] = CloudRight(i).
        END.
        DO WHILE mDriftMs >= period:
            mDriftMs = mDriftMs - period.
            mDrift = mDrift + dir.
            moved = TRUE.
        END.
        IF NOT moved THEN RETURN.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO i = 1 TO 4:
            PutBox(MINIMUM(l[i], CloudLeft(i)), CloudTop(i), MAXIMUM(r[i], CloudRight(i)), CloudBottom(i)).
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    /* ================================ the ground ================================ */

    /* Colours a box of the picture again, on the view, from the ground, the clouds and the sky. Must be called in a batch. The box is
       cut to the map. */
    METHOD PRIVATE VOID PutBox(INPUT piL AS INTEGER, INPUT piT AS INTEGER, INPUT piR AS INTEGER, INPUT piB AS INTEGER):
        DEFINE VARIABLE cells AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c     AS INTEGER NO-UNDO.
        piL = MAXIMUM(piL, 0).
        piT = MAXIMUM(piT, 0).
        piR = MINIMUM(piR, {&W} - 1).
        piB = MINIMUM(piB, {&H} - 1).
        IF piL > piR OR piT > piB THEN RETURN.
        DO ON ERROR UNDO, THROW:
            SET-SIZE(cells) = (piR - piL + 1) * (piB - piT + 1) * 12.
            DO y = piT TO piB:
                DO x = piL TO piR:
                    c = mGame:Land:ShadeAt(x, y).
                    IF c = ? THEN DO:
                        c = CloudAt(x, y).
                        IF c < 0 THEN c = mSky:ColourAt(x, y).
                    END.
                    PUT-LONG(cells, n * 12 + 1) = x.
                    PUT-LONG(cells, n * 12 + 5) = y.
                    PUT-LONG(cells, n * 12 + 9) = c.
                    n = n + 1.
                    IF y >= {&SHORE} AND y < {&SHORE} + {&SHORE-ROWS} THEN mShore[(y - {&SHORE}) * {&W} + x + 1] = (IF mGame:Land:IsSolid(x, y) THEN c ELSE -1).
                END.
            END.
            mCanvas:PutCells(cells, n, 0, 0).
            FINALLY:
                SET-SIZE(cells) = 0.
            END FINALLY.
        END.
    END METHOD.

    /* Colours every ground pixel of a box, and nothing else (the sky is already there). Must be called in a batch. */
    METHOD PRIVATE VOID PutLand(INPUT piL AS INTEGER, INPUT piT AS INTEGER, INPUT piR AS INTEGER, INPUT piB AS INTEGER):
        DEFINE VARIABLE cells AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c     AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            SET-SIZE(cells) = (piR - piL + 1) * (piB - piT + 1) * 12.
            DO y = piT TO piB:
                DO x = piL TO piR:
                    c = mGame:Land:ShadeAt(x, y).
                    IF c = ? THEN NEXT.
                    PUT-LONG(cells, n * 12 + 1) = x.
                    PUT-LONG(cells, n * 12 + 5) = y.
                    PUT-LONG(cells, n * 12 + 9) = c.
                    n = n + 1.
                END.
            END.
            mCanvas:PutCells(cells, n, 0, 0).
            FINALLY:
                SET-SIZE(cells) = 0.
            END FINALLY.
        END.
    END METHOD.

    /* The ground in the rows the sea covers, for the whole map. */
    METHOD PRIVATE VOID FillShore():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = {&SHORE} TO {&SHORE} + {&SHORE-ROWS} - 1:
            DO x = 0 TO {&W} - 1:
                mShore[(y - {&SHORE}) * {&W} + x + 1] = (IF mGame:Land:IsSolid(x, y) THEN mGame:Land:ShadeAt(x, y) ELSE -1).
            END.
        END.
    END METHOD.

    /* Colours again the box that a blast changed. */
    METHOD PRIVATE VOID SyncLand():
        IF NOT mGame:Land:HasDirty() THEN RETURN.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        PutBox(mGame:Land:DirtyLeft(), mGame:Land:DirtyTop(), mGame:Land:DirtyRight(), mGame:Land:DirtyBottom()).
        mCanvas:EndBatch().
        mCanvas:BakeView().
        mGame:Land:ClearDirty().
    END METHOD.

    /* ================================ the water ================================ */

    /* The sea over the background, then the ground that stands in it. A swell behind (a column starts one row lower when ((x + b) div 8) is
       even, b stepping every 120 ms), the four frames of waves (a new one every 200 ms) and the body of the sea from row 229. */
    METHOD PRIVATE VOID DrawWater():
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE b   AS INTEGER NO-UNDO.
        DEFINE VARIABLE topRow AS INTEGER NO-UNDO.
        DEFINE VARIABLE c   AS INTEGER NO-UNDO.
        b = INTEGER(TRUNCATE(mGame:ElapsedMs / 120, 0)).
        mCanvas:BeginBatch().
        DO x = 0 TO {&W} - 1:
            topRow = (IF INTEGER(TRUNCATE((x + b) / 8, 0)) MODULO 2 = 0 THEN 223 ELSE 222).
            mCanvas:DrawLine(x, topRow, x, {&WATER} + 2, 0, mWaterBack).
        END.
        DO y = {&WATER} + 3 TO {&H} - 1:
            mCanvas:DrawLine(0, y, {&W} - 1, y, 0, mWater).
        END.
        mCanvas:EndBatch().
        DO x = 0 TO {&W} - 1 BY 16:
            mWave[(INTEGER(TRUNCATE(mGame:ElapsedMs / 200, 0)) MODULO 4) + 1]:DrawTo(mCanvas, x, {&WATER}).
        END.
        DO y = 0 TO {&SHORE-ROWS} - 1:
            DO x = 0 TO {&W} - 1:
                c = mShore[y * {&W} + x + 1].
                IF c >= 0 THEN mCanvas:Plot(x, {&SHORE} + y, {&KIND-LAND}, c).
            END.
        END.
    END METHOD.

END CLASS.
