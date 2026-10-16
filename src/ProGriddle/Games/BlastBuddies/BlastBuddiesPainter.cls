/* Draws Blast Buddies in the "Sunny Side" look (docs/design/blast-buddies-art.md). It reads a BlastBuddiesGame, never changes it, and
   paints the picture on a pixel canvas over the game's own grid, then hands the grid to the window's renderer (the inner one).

   What is kept in the picture's background (the back layer of the canvas): the sky with the sun and the far hills, the clouds, and the
   ground, coloured by the rule of Terrain. Only what changes is coloured again: when a blast has dirtied a box of the ground
   (Terrain:HasDirty) that box is, and when the clouds drift (1 pixel every 800 ms, less in wind) their boxes are. What is drawn every
   pose, over the background: the water (a swell behind, four frames of waves, the body of the sea) and the strip of shore that
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
    DEFINE PRIVATE VARIABLE mSprites   AS BuddySprites   NO-UNDO.
    DEFINE PRIVATE VARIABLE mText      AS TextStampCache NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed  AS LOGICAL       NO-UNDO.
    /* what each buddy (team - 1) * 4 + place was doing at the last picture: its state and column, when it last moved and when it last landed */
    DEFINE PRIVATE VARIABLE mPrevState AS INTEGER       NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mPrevX     AS INTEGER       NO-UNDO EXTENT 16 INITIAL -1.
    DEFINE PRIVATE VARIABLE mMoveMs    AS INTEGER       NO-UNDO EXTENT 16 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mLandMs    AS INTEGER       NO-UNDO EXTENT 16 INITIAL -100000.
    /* the smoke of a rocket's trail: where each puff is, when it was made, and where the next goes */
    DEFINE PRIVATE VARIABLE mTrailX    AS INTEGER       NO-UNDO EXTENT 12.
    DEFINE PRIVATE VARIABLE mTrailY    AS INTEGER       NO-UNDO EXTENT 12.
    DEFINE PRIVATE VARIABLE mTrailMs   AS INTEGER       NO-UNDO EXTENT 12 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mTrailNext AS INTEGER       NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mTrailLast AS INTEGER       NO-UNDO INITIAL -100000.
    /* the smoke tones, lightest first */
    DEFINE PRIVATE VARIABLE mSmoke     AS INTEGER       NO-UNDO EXTENT 5.
    /* the damage numbers floating up: whose, how much, and when they began; and how many blasts have been looked at */
    DEFINE PRIVATE VARIABLE mDmgBuddy  AS Buddy         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mDmgAmount AS INTEGER       NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mDmgMs     AS INTEGER       NO-UNDO EXTENT 16 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mDmgNext   AS INTEGER       NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mBlastsSeen AS INTEGER      NO-UNDO.
    /* the blasts being shown: where, how big, when it went off, and the pixels of its scorch ring (up to 800 each, in blocks of 800) */
    DEFINE PRIVATE VARIABLE mRandom    AS IRandom       NO-UNDO.
    DEFINE PRIVATE VARIABLE mFxX       AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mFxY       AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mFxR       AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mFxMs      AS INTEGER       NO-UNDO EXTENT 4 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mFxRings   AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mRingX     AS INTEGER       NO-UNDO EXTENT 3200.
    DEFINE PRIVATE VARIABLE mRingY     AS INTEGER       NO-UNDO EXTENT 3200.
    DEFINE PRIVATE VARIABLE mRingS     AS INTEGER       NO-UNDO EXTENT 3200.
    DEFINE PRIVATE VARIABLE mFxNext    AS INTEGER       NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mFxSeen    AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mTitleLoop AS INTEGER       NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mBlast     AS INTEGER       NO-UNDO EXTENT 5.
    /* the pieces of ground thrown out by blasts: where, how fast (256ths of a pixel), what colour, how wide, and whether it is still flying */
    DEFINE PRIVATE VARIABLE mDbX       AS INTEGER       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbY       AS INTEGER       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbVX      AS INTEGER       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbVY      AS INTEGER       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbC       AS INTEGER       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbWide    AS LOGICAL       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbLive    AS LOGICAL       NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mDbNext    AS INTEGER       NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mLastFrame AS INTEGER       NO-UNDO.
    /* when each buddy was first seen buried (its gravestone rises from then), and when it went into the water, and where */
    DEFINE PRIVATE VARIABLE mPrevBuried AS LOGICAL      NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mBuriedMs  AS INTEGER       NO-UNDO EXTENT 16 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mSinkMs    AS INTEGER       NO-UNDO EXTENT 16 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mSinkX     AS INTEGER       NO-UNDO EXTENT 16.
    /* the rings of the splashes: the column and the time of each */
    DEFINE PRIVATE VARIABLE mSplX      AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mSplMs     AS INTEGER       NO-UNDO EXTENT 4 INITIAL -100000.
    DEFINE PRIVATE VARIABLE mSplNext   AS INTEGER       NO-UNDO INITIAL 1.
    /* the map whose last picture, dimmed, is baked into the background for the winner screen */
    DEFINE PRIVATE VARIABLE mOverSerial AS INTEGER      NO-UNDO INITIAL -1.
    /* the team tones 1 and 2 */
    DEFINE PRIVATE VARIABLE mTone1     AS INTEGER       NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mTone2     AS INTEGER       NO-UNDO EXTENT 4.
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
    /* How many pieces of ground thrown out by blasts are still in the air. */
    METHOD PUBLIC INTEGER DebrisInFlight():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO 256:
            IF mDbLive[i] THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* poRandom is for the effects (the pieces of ground thrown out by a blast). Throws GridException for no renderer, game or random source. */
    CONSTRUCTOR PUBLIC BlastBuddiesPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS BlastBuddiesGame, INPUT poRandom AS IRandom):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Blast Buddies painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Blast Buddies painter needs a game").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Blast Buddies painter needs a random source").
        mInner = poInner.
        mGame = poGame.
        mRandom = poRandom.
        DO i = 1 TO 5:
            mBlast[i] = ColourMath:FromHex(ENTRY(i, BuddiesLook:ToneRow("Blast"))).
        END.
        mCanvas = NEW PixelCanvas(poGame:Grid).
        mSkyGrid = NEW Grid(NEW ArrayStore({&W}, {&H}, "view,kind,back")).
        mSky = NEW PixelCanvas(mSkyGrid).
        mSprites = NEW BuddySprites().
        mText = NEW TextStampCache(64).
        DO i = 1 TO 5:
            mSmoke[i] = ColourMath:FromHex(ENTRY(i, BuddiesLook:ToneRow("Smoke"))).
        END.
        DO i = 1 TO 4:
            mTone1[i] = ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow(ENTRY(i, "Reds,Blues,Teals,Grapes")))).
            mTone2[i] = ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow(ENTRY(i, "Reds,Blues,Teals,Grapes")))).
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC BlastBuddiesPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the grid to the window's renderer. Throws GridException for a game that is not a Blast
       Buddies game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, BlastBuddiesGame) THEN UNDO, THROW NEW GridException("A Blast Buddies painter draws a Blast Buddies game").
        IF mSerial <> mGame:MapSerial THEN StartMap().
        IF IsOver() AND mOverSerial = mSerial THEN DO:
            /* the last picture stays, dimmed, with the end screen on it */
            mCanvas:Restore().
            DrawEndScreen().
            mInner:Render(mGame:Grid, poGame).
            RETURN.
        END.
        SyncClouds().
        SyncLand().
        mCanvas:Restore().
        DrawWater().
        IF mGame:Phase = BuddyPhase:Title THEN DO:
            SyncBlasts().
            DrawTitle().
            DrawBlasts().
            mInner:Render(mGame:Grid, poGame).
            RETURN.
        END.
        DrawBuddies().
        SyncBlasts().
        DrawShells().
        DrawBlasts().
        DrawSplashRings().
        DrawAim().
        DrawDamage().
        IF IsOver() THEN DO:
            /* the picture as it ended is dimmed once and kept, and the end screen goes over it */
            mCanvas:DimRect(0, 0, {&W}, {&H}, 35, BuddiesLook:Colour(BuddyTint:Ink)).
            mCanvas:BakeView().
            mOverSerial = mSerial.
            DrawEndScreen().
            mInner:Render(mGame:Grid, poGame).
            RETURN.
        END.
        ApplyShake().
        DrawHud().
        DrawBanner().
        DrawPaused().
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
        IF VALID-OBJECT(mSprites) THEN mSprites:Dispose().
        IF VALID-OBJECT(mText) THEN mText:Dispose().
        IF VALID-OBJECT(mSkyGrid) THEN mSkyGrid:Dispose().
    END METHOD.

    /* ================================ a new map ================================ */

    /* The colour of a key in the theme of the map. */
    METHOD PRIVATE INTEGER Look(INPUT poKey AS ThemeKey):
        RETURN TerrainThemes:Colour(mGame:MapTheme, poKey).
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

    /* ================================ the buddies ================================ */

    /* Draws every buddy that is still on the map: the goon in the pose of what it is doing, in its team colours and facing the way it
       faces, its team mark on the head, the bazooka in its hands when it aims, and the numbers over it. A buried buddy is a gravestone. */
    METHOD PRIVATE VOID DrawBuddies():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS Buddy   NO-UNDO.
        DO i = 1 TO mGame:Plan:TeamCount():
            DO j = 1 TO mGame:Plan:TeamAt(i):Count():
                b = mGame:Plan:TeamAt(i):BuddyAt(j).
                Track(b, (b:Team - 1) * 4 + j).
            END.
        END.
        DO i = 1 TO mGame:Plan:TeamCount():
            DO j = 1 TO mGame:Plan:TeamAt(i):Count():
                b = mGame:Plan:TeamAt(i):BuddyAt(j).
                IF mGame:Phase = BuddyPhase:Arrival AND mGame:HasTitle THEN DO:
                    DrawArriving(b, (b:Team - 1) * 4 + j, (j - 1) * mGame:Plan:TeamCount() + b:Team - 1).
                    NEXT.
                END.
                IF b:State = BuddyState:Drowned THEN DrawSinking((b:Team - 1) * 4 + j).
                ELSE IF b:Buried THEN DrawGravestone(b, (b:Team - 1) * 4 + j).
                ELSE IF b = mGame:DyingBuddy THEN DrawDying(b, (b:Team - 1) * 4 + j).
                ELSE DrawGoon(b, (b:Team - 1) * 4 + j).
            END.
        END.
        DO i = 1 TO mGame:Plan:TeamCount():
            DO j = 1 TO mGame:Plan:TeamAt(i):Count():
                b = mGame:Plan:TeamAt(i):BuddyAt(j).
                IF b:State = BuddyState:Drowned OR b:IsDead() THEN NEXT.
                IF mGame:Phase = BuddyPhase:Arrival AND mGame:HasTitle AND ArrivalAge(b, (j - 1) * mGame:Plan:TeamCount() + b:Team - 1) < 0 THEN NEXT.
                DrawLabels(b, (b:Team - 1) * 4 + j).
            END.
        END.
    END METHOD.

    /* Notes what a buddy has been doing since the last picture: when it walked, and when it came down. */
    METHOD PRIVATE VOID Track(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DEFINE VARIABLE ms AS INTEGER NO-UNDO.
        DEFINE VARIABLE k  AS INTEGER NO-UNDO.
        ms = mGame:ElapsedMs.
        IF poBuddy:X() <> mPrevX[piKey] AND mPrevX[piKey] >= 0 AND poBuddy:State = BuddyState:Standing THEN mMoveMs[piKey] = ms.
        IF mPrevState[piKey] = INTEGER(BuddyState:Airborne) AND poBuddy:State = BuddyState:Standing THEN mLandMs[piKey] = ms.
        /* into the water: a splash where it went in, and a goon that sinks. One seen for the first time already drowned only has the splash. */
        IF poBuddy:State = BuddyState:Drowned AND mPrevState[piKey] <> INTEGER(BuddyState:Drowned) AND mPrevX[piKey] >= 0 THEN DO:
            mSinkMs[piKey] = ms.
            mSinkX[piKey] = MAXIMUM(0, MINIMUM({&W} - 1, poBuddy:X())).
            mSplX[mSplNext] = mSinkX[piKey].
            mSplMs[mSplNext] = ms.
            mSplNext = mSplNext MODULO 4 + 1.
            DO k = 1 TO 10:
                SpawnDebris(mSinkX[piKey], {&WATER} - 1, (IF k MODULO 2 = 0 THEN Look(ThemeKey:Foam) ELSE Look(ThemeKey:WaterTop)), FALSE, 5).
            END.
        END.
        /* buried: the gravestone rises out of the ground from now, unless it was there when the painter first saw the buddy */
        IF poBuddy:Buried AND NOT mPrevBuried[piKey] THEN mBuriedMs[piKey] = (IF mPrevX[piKey] >= 0 THEN ms ELSE -100000).
        mPrevBuried[piKey] = poBuddy:Buried.
        mPrevX[piKey] = poBuddy:X().
        mPrevState[piKey] = INTEGER(poBuddy:State).
    END METHOD.

    /* Whether a shot is in the air within 48 pixels of a buddy, which worries it. */
    METHOD PRIVATE LOGICAL ShotNear(INPUT poBuddy AS Buddy):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO ShellPool:Capacity():
            IF mGame:Shells:Active(i) AND ABSOLUTE(BuddyRules:Pixel(mGame:Shells:X(i)) - poBuddy:X()) <= 48
               AND ABSOLUTE(BuddyRules:Pixel(mGame:Shells:Y(i)) - poBuddy:Y()) <= 48 THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* The picture a goon is in now. */
    METHOD PRIVATE CHARACTER FrameFor(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DEFINE VARIABLE ms AS INTEGER NO-UNDO.
        DEFINE VARIABLE t  AS INTEGER NO-UNDO.
        ms = mGame:ElapsedMs.
        t = ms + piKey * 977.
        IF poBuddy:IsDead() THEN RETURN "goon_flinch".
        IF poBuddy:State = BuddyState:Airborne THEN RETURN (IF poBuddy:VY < 0 THEN "goon_jump_rise" ELSE "goon_jump_fall").
        IF ms - mLandMs[piKey] < 120 THEN RETURN "goon_land".
        IF ms - mMoveMs[piKey] < 150 THEN RETURN "goon_walk_" + STRING(INTEGER(TRUNCATE((poBuddy:X() MODULO 12) / 3, 0)) + 1).
        IF mGame:Phase = BuddyPhase:Turn AND poBuddy = mGame:CurrentBuddy THEN RETURN "goon_aim".
        IF ShotNear(poBuddy) THEN RETURN "goon_worried".
        IF t MODULO 3200 < 100 THEN RETURN "goon_blink".
        IF (ms + piKey * 1313) MODULO 7000 < 700 THEN RETURN "goon_look_back".
        RETURN "goon_idle_" + STRING(INTEGER(TRUNCATE(ms / 600, 0)) MODULO 2 + 1).
    END METHOD.

    METHOD PRIVATE VOID DrawGoon(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DrawPose(poBuddy, FrameFor(poBuddy, piKey), 0).
    END METHOD.

    /* A goon in a picture, piUp pixels above where it stands, with its mark, and the bazooka in its hands when it aims. */
    METHOD PRIVATE VOID DrawPose(INPUT poBuddy AS Buddy, INPUT pcPose AS CHARACTER, INPUT piUp AS INTEGER):
        DEFINE VARIABLE mirror AS LOGICAL NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER NO-UNDO.
        mirror = poBuddy:Facing < 0.
        DrawGoonAt(poBuddy:Team, pcPose, poBuddy:X(), poBuddy:Y() - piUp, mirror).
        IF pcPose = "goon_aim" THEN DO:
            r = mSprites:Reach("held_bazooka").
            mSprites:Turned("held_bazooka", mGame:AimHeading, mirror):DrawTo(mCanvas, poBuddy:X() + (IF mirror THEN -3 ELSE 3) - r, poBuddy:Y() - piUp - 5 - r).
        END.
    END METHOD.

    /* A goon of a team in a picture with its feet at a place, with its mark on its head. */
    METHOD PRIVATE VOID DrawGoonAt(INPUT piTeam AS INTEGER, INPUT pcPose AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL):
        DEFINE VARIABLE mark AS CHARACTER NO-UNDO.
        DEFINE VARIABLE head AS INTEGER   NO-UNDO.
        mSprites:Stamp(pcPose, piTeam, plMirror):DrawTo(mCanvas, piX - mSprites:OriginX(pcPose, plMirror), piY - mSprites:OriginY(pcPose)).
        head = piY - mSprites:OriginY(pcPose) + mSprites:HeadTop(pcPose).
        mark = ENTRY(piTeam, "mark_reds,mark_blues,mark_teals,mark_grapes").
        mSprites:Stamp(mark, 0, plMirror):DrawTo(mCanvas, piX - mSprites:OriginX(mark, plMirror), head + 1 - mSprites:HeightOf(mark)).
    END METHOD.

    /* A buddy that has died, shown dying for a second: the alarm frames with a skull over its head, and then a puff of smoke where it was. */
    METHOD PRIVATE VOID DrawDying(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE hd   AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy   AS INTEGER NO-UNDO.
        t = mGame:DeathPercent * 10.
        IF t < 200 THEN DrawPose(poBuddy, "goon_alarm_1", 0).
        ELSE IF t < 400 THEN DrawPose(poBuddy, "goon_alarm_2", 6).
        ELSE IF t < 600 THEN DrawPose(poBuddy, "goon_alarm_3", 0).
        IF t < 600 THEN
            mSprites:Stamp("ico_skull", 0, FALSE):DrawTo(mCanvas, poBuddy:X() - mSprites:OriginX("ico_skull", FALSE), poBuddy:Y() - 12 - 8 - mSprites:OriginY("ico_skull")).
        ELSE DO:
            /* eight puffs round the middle of the goon, one tone paler to darker every 80 ms, drifting up */
            tone = 1 + INTEGER(TRUNCATE((t - 600) / 80, 0)).
            IF tone <= 5 THEN DO i = 0 TO 7:
                hd = i * 8.
                cx = poBuddy:X() + INTEGER(ROUND(Heading:DirX(hd) * 6 / Heading:Scale(), 0)).
                cy = poBuddy:Y() - 6 + INTEGER(ROUND(Heading:DirY(hd) * 6 / Heading:Scale(), 0)) - INTEGER(TRUNCATE((t - 600) / 60, 0)).
                mCanvas:Plot(cx, cy, 0, mSmoke[tone]).
                mCanvas:Plot(cx - 1, cy, 0, mSmoke[tone]).
                mCanvas:Plot(cx + 1, cy, 0, mSmoke[tone]).
                mCanvas:Plot(cx, cy - 1, 0, mSmoke[tone]).
                mCanvas:Plot(cx, cy + 1, 0, mSmoke[tone]).
            END.
        END.
    END METHOD.

    /* The gravestone of a buried buddy: it rises out of the ground a pixel every 55 ms, clipped at the ground line, and a halo floats
       up over it and then bobs. */
    METHOD PRIVATE VOID DrawGravestone(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DEFINE VARIABLE age  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE rise AS INTEGER   NO-UNDO.
        DEFINE VARIABLE st   AS PixelStamp NO-UNDO.
        DEFINE VARIABLE sx   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE sy   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x0   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y0   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE hy   AS INTEGER   NO-UNDO.
        age = MAXIMUM(mGame:ElapsedMs - mBuriedMs[piKey], 0).
        rise = MAXIMUM(0, 11 - INTEGER(TRUNCATE(age / 55, 0))).
        st = mSprites:Stamp("gravestone", 0, FALSE).
        x0 = poBuddy:X() - mSprites:OriginX("gravestone", FALSE).
        y0 = poBuddy:Y() - mSprites:OriginY("gravestone").
        IF rise = 0 THEN st:DrawTo(mCanvas, x0, y0).
        ELSE DO sy = 0 TO st:Height - 1 - rise:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 THEN mCanvas:Plot(x0 + sx, y0 + rise + sy, 0, st:ColourAt(sx, sy)).
            END.
        END.
        IF rise = 0 THEN DO:
            /* the halo: from the head top up 16 pixels over 640 ms, then 1 pixel up and down every 400 ms */
            hy = poBuddy:Y() - 12 - MINIMUM(16, MAXIMUM(0, INTEGER(TRUNCATE((age - 600) / 40, 0)))) - (IF age >= 1240 THEN INTEGER(TRUNCATE(age / 400, 0)) MODULO 2 ELSE 0).
            mSprites:Stamp("halo", 0, FALSE):DrawTo(mCanvas, poBuddy:X() - mSprites:OriginX("halo", FALSE), hy - mSprites:OriginY("halo")).
        END.
    END METHOD.

    /* A buddy that has gone into the water: the sinking goon goes down a pixel every 60 ms, clipped at the water line, and the ring of
       the splash spreads out along the line. */
    METHOD PRIVATE VOID DrawSinking(INPUT piKey AS INTEGER):
        DEFINE VARIABLE age AS INTEGER    NO-UNDO.
        DEFINE VARIABLE k   AS INTEGER    NO-UNDO.
        DEFINE VARIABLE st  AS PixelStamp NO-UNDO.
        DEFINE VARIABLE sx  AS INTEGER    NO-UNDO.
        DEFINE VARIABLE sy  AS INTEGER    NO-UNDO.
        age = mGame:ElapsedMs - mSinkMs[piKey].
        IF age < 0 OR age >= 720 THEN RETURN.
        k = INTEGER(TRUNCATE(age / 60, 0)).
        st = mSprites:Stamp("goon_sink", INTEGER(TRUNCATE((piKey - 1) / 4, 0)) + 1, FALSE).
        DO sy = 0 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND {&WATER} + k - mSprites:OriginY("goon_sink") + sy < {&WATER} THEN
                    mCanvas:Plot(mSinkX[piKey] - mSprites:OriginX("goon_sink", FALSE) + sx, {&WATER} + k - mSprites:OriginY("goon_sink") + sy, 0, st:ColourAt(sx, sy)).
            END.
        END.
    END METHOD.

    /* The rings of the splashes along the water line: foam on either side of where something went in, a pixel a frame for 6 frames. */
    METHOD PRIVATE VOID DrawSplashRings():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE f AS INTEGER NO-UNDO.
        DO i = 1 TO 4:
            f = INTEGER(TRUNCATE((mGame:ElapsedMs - mSplMs[i]) * 60 / 1000, 0)).
            IF f < 0 OR f > 5 THEN NEXT.
            mCanvas:Plot(mSplX[i] - 1 - f, {&WATER}, 0, Look(ThemeKey:Foam)).
            mCanvas:Plot(mSplX[i] + 1 + f, {&WATER}, 0, Look(ThemeKey:Foam)).
        END.
    END METHOD.

    /* The health over a goon in its team colour, and the name of the goon whose turn it is. */
    METHOD PRIVATE VOID DrawLabels(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER):
        DEFINE VARIABLE pose AS CHARACTER NO-UNDO.
        DEFINE VARIABLE head  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE words  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ink   AS INTEGER   NO-UNDO.
        pose = FrameFor(poBuddy, piKey).
        head = poBuddy:Y() - mSprites:OriginY(pose) + mSprites:HeadTop(pose).
        ink = BuddiesLook:Colour(BuddyTint:Ink).
        words = STRING(poBuddy:Health).
        mText:Get(words, 1, mTone2[poBuddy:Team], mTone2[poBuddy:Team], ink):DrawTo(mCanvas, poBuddy:X() - INTEGER(TRUNCATE(PixelFont:WidthOf(words) / 2, 0)), head - 14).
        IF poBuddy = mGame:CurrentBuddy AND (mGame:Phase = BuddyPhase:Turn OR mGame:Phase = BuddyPhase:Retreat) THEN DO:
            words = poBuddy:BuddyName.
            mText:Get(words, 1, mTone1[poBuddy:Team], mTone1[poBuddy:Team], ink):DrawTo(mCanvas, poBuddy:X() - INTEGER(TRUNCATE(PixelFont:WidthOf(words) / 2, 0)), head - 24).
        END.
        /* the computer's thought bubble, bobbing a pixel every 300 ms, over the buddy it is thinking for */
        IF poBuddy = mGame:CurrentBuddy AND VALID-OBJECT(mGame:Brain) THEN DO:
            IF mGame:Brain:Thinking THEN
                mSprites:Stamp("ico_think", 0, FALSE):DrawTo(mCanvas, poBuddy:X() - mSprites:OriginX("ico_think", FALSE),
                    head - 14 - 4 - INTEGER(TRUNCATE(mGame:ElapsedMs / 300, 0)) MODULO 2 - mSprites:OriginY("ico_think")).
        END.
    END METHOD.

    /* ================================ shots, aim and damage ================================ */

    /* The rockets in the air, each turned to the way it is flying, with its exhaust behind it and a trail of smoke that fades. */
    METHOD PRIVATE VOID DrawShells():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE hd   AS INTEGER NO-UNDO.
        DEFINE VARIABLE px   AS INTEGER NO-UNDO.
        DEFINE VARIABLE py   AS INTEGER NO-UNDO.
        DEFINE VARIABLE r    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ex   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE age  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone AS INTEGER NO-UNDO.
        DEFINE VARIABLE ms   AS INTEGER NO-UNDO.
        ms = mGame:ElapsedMs.
        DO i = 1 TO ShellPool:Capacity():
            IF NOT mGame:Shells:Active(i) THEN NEXT.
            px = BuddyRules:Pixel(mGame:Shells:X(i)).
            py = BuddyRules:Pixel(mGame:Shells:Y(i)).
            hd = Heading:Nearest(mGame:Shells:VX(i), mGame:Shells:VY(i)).
            /* a puff of smoke from the tail every 50 ms */
            IF ms - mTrailLast >= 50 THEN DO:
                mTrailLast = ms.
                mTrailX[mTrailNext] = px - INTEGER(TRUNCATE(Heading:DirX(hd) * 5 / Heading:Scale(), 0)).
                mTrailY[mTrailNext] = py - INTEGER(TRUNCATE(Heading:DirY(hd) * 5 / Heading:Scale(), 0)).
                mTrailMs[mTrailNext] = ms.
                mTrailNext = mTrailNext MODULO 12 + 1.
            END.
        END.
        DrawTrail().
        DO i = 1 TO ShellPool:Capacity():
            IF NOT mGame:Shells:Active(i) THEN NEXT.
            px = BuddyRules:Pixel(mGame:Shells:X(i)).
            py = BuddyRules:Pixel(mGame:Shells:Y(i)).
            hd = Heading:Nearest(mGame:Shells:VX(i), mGame:Shells:VY(i)).
            ex = "exhaust_" + STRING(INTEGER(TRUNCATE(ms / 50, 0)) MODULO 2).
            r = mSprites:Reach(ex).
            mSprites:Turned(ex, hd, FALSE):DrawTo(mCanvas, px - INTEGER(TRUNCATE(Heading:DirX(hd) * 5 / Heading:Scale(), 0)) - r,
                                                  py - INTEGER(TRUNCATE(Heading:DirY(hd) * 5 / Heading:Scale(), 0)) - r).
            r = mSprites:Reach("rocket").
            mSprites:Turned("rocket", hd, FALSE):DrawTo(mCanvas, px - r, py - r).
            /* a shot above the top of the map is marked by an arrow in its column */
            IF py < 0 THEN DO:
                mCanvas:Plot(px, 1, 0, BuddiesLook:Colour(BuddyTint:Flash)).
                mCanvas:Plot(px - 1, 1, 0, BuddiesLook:Colour(BuddyTint:Ink)).
                mCanvas:Plot(px + 1, 1, 0, BuddiesLook:Colour(BuddyTint:Ink)).
                mCanvas:Plot(px, 2, 0, BuddiesLook:Colour(BuddyTint:Ink)).
            END.
        END.
    END METHOD.

    /* The puffs of smoke of a rocket's trail, the oldest palest. */
    METHOD PRIVATE VOID DrawTrail():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE age  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone AS INTEGER NO-UNDO.
        DEFINE VARIABLE ms   AS INTEGER NO-UNDO.
        ms = mGame:ElapsedMs.
        DO i = 1 TO 12:
            age = ms - mTrailMs[i].
            IF age < 0 OR age >= 600 THEN NEXT.
            tone = MINIMUM(5, 1 + INTEGER(TRUNCATE(age / 120, 0))).
            mCanvas:Plot(mTrailX[i], mTrailY[i], 0, mSmoke[tone]).
            mCanvas:Plot(mTrailX[i] - 1, mTrailY[i], 0, mSmoke[tone]).
            mCanvas:Plot(mTrailX[i] + 1, mTrailY[i], 0, mSmoke[tone]).
            mCanvas:Plot(mTrailX[i], mTrailY[i] - 1, 0, mSmoke[tone]).
            mCanvas:Plot(mTrailX[i], mTrailY[i] + 1, 0, mSmoke[tone]).
        END.
    END METHOD.

    /* The reticle 28 pixels out along the aim of the buddy in turn, and while fire is held the dots that grow along the aim. */
    METHOD PRIVATE VOID DrawAim():
        DEFINE VARIABLE b      AS Buddy   NO-UNDO.
        DEFINE VARIABLE hd     AS INTEGER NO-UNDO.
        DEFINE VARIABLE pivX   AS INTEGER NO-UNDO.
        DEFINE VARIABLE pivY   AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE rname  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        b = mGame:CurrentBuddy.
        IF NOT VALID-OBJECT(b) OR mGame:Phase <> BuddyPhase:Turn OR b:IsDead() THEN RETURN.
        hd = mGame:AimHeading.
        pivX = b:X() + (IF b:Facing < 0 THEN -3 ELSE 3).
        pivY = b:Y() - 5.
        dx = Heading:DirX(hd).
        dy = Heading:DirY(hd).
        n = MINIMUM(16, INTEGER(TRUNCATE(mGame:Charge * 16 / BuddyRules:ChargeFrames(), 0)) + (IF mGame:Charge > 0 THEN 1 ELSE 0)).
        DO k = 0 TO n - 1:
            /* dot k is 2 x 1 pixels, 6 + 1.6 k from the pivot and 2 rows above the aim line */
            d = 6 * 1024 + INTEGER(TRUNCATE(1.6 * k * 1024, 0)).
            colour = ColourMath:Mix(BuddiesLook:Colour(BuddyTint:Good), BuddiesLook:Colour(BuddyTint:Hurt), k, 15).
            mCanvas:Plot(pivX + INTEGER(ROUND(dx * d / 1024 / 1024, 0)), pivY + INTEGER(ROUND(dy * d / 1024 / 1024, 0)) - 2, 0, colour).
            mCanvas:Plot(pivX + INTEGER(ROUND(dx * d / 1024 / 1024, 0)) + 1, pivY + INTEGER(ROUND(dy * d / 1024 / 1024, 0)) - 2, 0, colour).
        END.
        rname = "reticle_" + STRING(INTEGER(TRUNCATE(mGame:ElapsedMs / 300, 0)) MODULO 2).
        mSprites:Stamp(rname, 0, FALSE):DrawTo(mCanvas, pivX + INTEGER(ROUND(dx * 28 / 1024, 0)) - mSprites:OriginX(rname, FALSE),
                                               pivY + INTEGER(ROUND(dy * 28 / 1024, 0)) - mSprites:OriginY(rname)).
    END METHOD.

    /* Damage numbers float up over the buddies the last blast hurt, 1 pixel every 40 ms for 24 pixels, and a squeal bubble over one that
       lost 10 or more. A new blast starts the numbers when the picture is next drawn. */
    METHOD PRIVATE VOID DrawDamage():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE age    AS INTEGER NO-UNDO.
        DEFINE VARIABLE b      AS Buddy   NO-UNDO.
        DEFINE VARIABLE words  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        DEFINE VARIABLE head   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ms     AS INTEGER NO-UNDO.
        ms = mGame:ElapsedMs.
        IF mGame:BlastCount > mBlastsSeen THEN DO:
            mBlastsSeen = mGame:BlastCount.
            DO i = 1 TO mGame:LastBlast:HitCount():
                mDmgBuddy[mDmgNext] = mGame:LastBlast:HitBuddy(i).
                mDmgAmount[mDmgNext] = mGame:LastBlast:HitDamage(i).
                mDmgMs[mDmgNext] = ms.
                mDmgNext = mDmgNext MODULO 16 + 1.
            END.
        END.
        DO i = 1 TO 16:
            age = ms - mDmgMs[i].
            IF age < 0 OR age >= 960 THEN NEXT.
            b = mDmgBuddy[i].
            IF NOT VALID-OBJECT(b) OR b:State = BuddyState:Drowned THEN NEXT.
            head = b:Y() - 12 + 2.
            words = STRING(mDmgAmount[i]).
            colour = (IF age >= 760 THEN mSmoke[3] ELSE BuddiesLook:Colour(BuddyTint:Hurt)).
            mText:Get(words, 1, colour, colour, BuddiesLook:Colour(BuddyTint:Outline)):DrawTo(mCanvas,
                b:X() - INTEGER(TRUNCATE(PixelFont:WidthOf(words) / 2, 0)), head - 20 - INTEGER(TRUNCATE(age / 40, 0))).
            IF age < 700 AND mDmgAmount[i] >= 10 THEN
                mSprites:Stamp("bubble_oof", 0, FALSE):DrawTo(mCanvas, b:X() + 3 - mSprites:OriginX("bubble_oof", FALSE), head - 2 - mSprites:OriginY("bubble_oof")).
        END.
    END METHOD.

    /* ================================ explosions ================================ */

    /* Starts showing any blast that has gone off since the last picture: its place, the pixels of its scorch ring, and the pieces of
       ground it throws out (24, 40 or 60 by its size, and one for every crumb the crumb rule took). */
    METHOD PRIVATE VOID SyncBlasts():
        DEFINE VARIABLE frames AS INTEGER NO-UNDO.
        /* the pieces already in the air fly on by the frames that have passed */
        frames = mGame:FrameCount - mLastFrame.
        mLastFrame = mGame:FrameCount.
        IF frames < 0 THEN frames = 0.
        StepDebris(MINIMUM(frames, 90)).
        IF mGame:BlastCount <= mFxSeen THEN DO:
            IF mGame:BlastCount < mFxSeen THEN mFxSeen = mGame:BlastCount.
            RETURN.
        END.
        mFxSeen = mGame:BlastCount.
        AddBlast(mGame:LastBlastX, mGame:LastBlastY, mGame:LastBlastRadius).
    END METHOD.

    /* Starts showing a blast at a place: its scorch ring (the ground from the edge of the hole to 3 pixels beyond it), and the pieces of
       ground it throws out, 24, 40 or 60 by its size and one for every crumb the crumb rule took. */
    METHOD PRIVATE VOID AddBlast(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piR AS INTEGER):
        DEFINE VARIABLE slot  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE stp   AS INTEGER NO-UNDO.
        slot = mFxNext.
        mFxNext = mFxNext MODULO 4 + 1.
        mFxX[slot] = piCx.
        mFxY[slot] = piCy.
        mFxR[slot] = piR.
        mFxMs[slot] = mGame:ElapsedMs.
        n = 0.
        DO y = MAXIMUM(piCy - piR - 3, 0) TO MINIMUM(piCy + piR + 3, 239):
            DO x = MAXIMUM(piCx - piR - 3, 0) TO MINIMUM(piCx + piR + 3, 383):
                d2 = (x - piCx) * (x - piCx) + (y - piCy) * (y - piCy).
                IF d2 <= piR * piR OR d2 > (piR + 3) * (piR + 3) THEN NEXT.
                stp = mGame:Land:ScorchStep(x, y).
                IF stp = 0 OR n >= 800 THEN NEXT.
                n = n + 1.
                mRingX[(slot - 1) * 800 + n] = x.
                mRingY[(slot - 1) * 800 + n] = y.
                mRingS[(slot - 1) * 800 + n] = stp.
            END.
        END.
        mFxRings[slot] = n.
        n = (IF piR <= 12 THEN 24 ELSE IF piR <= 20 THEN 40 ELSE 60).
        DO k = 1 TO n:
            SpawnDebris(piCx, piCy, DebrisColour(k), k MODULO 3 = 0, 12).
        END.
        IF mGame:Phase <> BuddyPhase:Title THEN DO k = 1 TO MINIMUM(mGame:Land:CrumbCount(), 60):
            SpawnDebris(mGame:Land:CrumbX(k), mGame:Land:CrumbY(k), mGame:Land:CrumbColour(k), FALSE, 12).
        END.
    END METHOD.

    /* The colours the pieces thrown out take in turn: the surface bands, the soil and the speckled soil, and the deep. */
    METHOD PRIVATE INTEGER DebrisColour(INPUT piIndex AS INTEGER):
        CASE piIndex MODULO 5:
            WHEN 0 THEN RETURN Look(ThemeKey:Top2).
            WHEN 1 THEN RETURN Look(ThemeKey:Soil).
            WHEN 2 THEN RETURN Look(ThemeKey:SoilSpeck).
            WHEN 3 THEN RETURN Look(ThemeKey:Deep).
            OTHERWISE RETURN Look(ThemeKey:Top1).
        END CASE.
    END METHOD.

    /* Throws a piece of ground out from a place: at an angle upwards (200 to 340 degrees), 1.5 to 3.5 pixels a frame. */
    METHOD PRIVATE VOID SpawnDebris(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER, INPUT plWide AS LOGICAL, INPUT piSpread AS INTEGER):
        DEFINE VARIABLE hd    AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed AS INTEGER NO-UNDO.
        hd = mRandom:NextInt(2 * piSpread + 1) - piSpread.
        speed = 384 + mRandom:NextInt(513).
        mDbX[mDbNext] = piX * 256.
        mDbY[mDbNext] = piY * 256.
        mDbVX[mDbNext] = INTEGER(TRUNCATE(Heading:DirX(hd) * speed / Heading:Scale(), 0)).
        mDbVY[mDbNext] = INTEGER(TRUNCATE(Heading:DirY(hd) * speed / Heading:Scale(), 0)).
        mDbC[mDbNext] = piColour.
        mDbWide[mDbNext] = plWide.
        mDbLive[mDbNext] = TRUE.
        mDbNext = mDbNext MODULO 256 + 1.
    END METHOD.

    /* Flies every piece of ground on by some frames: gravity pulls it down, and it is gone when it lands on the ground (it does not stick),
       reaches the water or leaves the sides. */
    METHOD PRIVATE VOID StepDebris(INPUT piFrames AS INTEGER):
        DEFINE VARIABLE f  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE px AS INTEGER NO-UNDO.
        DEFINE VARIABLE py AS INTEGER NO-UNDO.
        DO f = 1 TO piFrames:
            DO i = 1 TO 256:
                IF NOT mDbLive[i] THEN NEXT.
                mDbVY[i] = mDbVY[i] + BuddyRules:Gravity().
                mDbX[i] = mDbX[i] + mDbVX[i].
                mDbY[i] = mDbY[i] + mDbVY[i].
                px = BuddyRules:Pixel(mDbX[i]).
                py = BuddyRules:Pixel(mDbY[i]).
                IF px < 0 OR px >= {&W} OR py >= {&WATER} OR (py >= 0 AND mGame:Land:IsSolid(px, py)) THEN mDbLive[i] = FALSE.
            END.
        END.
    END METHOD.

    /* A filled disc in a batch, one line a row. */
    METHOD PRIVATE VOID Disc(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT pdRadius AS DECIMAL, INPUT piColour AS INTEGER):
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DEFINE VARIABLE w  AS INTEGER NO-UNDO.
        DEFINE VARIABLE r  AS INTEGER NO-UNDO.
        r = INTEGER(TRUNCATE(pdRadius, 0)).
        DO dy = - r TO r:
            w = INTEGER(TRUNCATE(SQRT(pdRadius * pdRadius - dy * dy), 0)).
            mCanvas:DrawLine(piCx - w, piCy + dy, piCx + w, piCy + dy, 0, piColour).
        END.
    END METHOD.

    /* The blasts as they go: the white flash, the fireball in bands that cool, the shock ring, the smoke, the glow of the scorch cooling,
       and the pieces of ground in the air. */
    METHOD PRIVATE VOID DrawBlasts():
        DEFINE VARIABLE s     AS INTEGER NO-UNDO.
        DEFINE VARIABLE t     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER NO-UNDO.
        DEFINE VARIABLE big   AS DECIMAL NO-UNDO.
        DEFINE VARIABLE b     AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE active   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE ms    AS INTEGER NO-UNDO.
        DEFINE VARIABLE tone  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rad   AS INTEGER NO-UNDO.
        DEFINE VARIABLE hd    AS INTEGER NO-UNDO.
        DEFINE VARIABLE bands AS DECIMAL NO-UNDO EXTENT 4.
        bands[1] = 0.35.
        bands[2] = 0.6.
        bands[3] = 0.85.
        bands[4] = 1.0.
        ms = mGame:ElapsedMs.
        DO s = 1 TO 4:
            IF ms - mFxMs[s] >= 0 AND ms - mFxMs[s] < 800 THEN active = TRUE.
        END.
        IF active THEN DO:
            mCanvas:BeginBatch().
            DO s = 1 TO 4:
                t = ms - mFxMs[s].
                IF t < 0 OR t >= 800 THEN NEXT.
                r = mFxR[s].
                IF t < 33 THEN Disc(mFxX[s], mFxY[s], 0.8 * r, BuddiesLook:Colour(BuddyTint:Flash)).
                ELSE IF t < 400 THEN DO:
                    big = r * MINIMUM(1.0, 0.5 + (t - 33) / 134).
                    IF t >= 160 THEN big = big * MAXIMUM(0.3, 1.0 - (t - 160) / 400).
                    DO b = 4 TO 1 BY -1:
                        k = b - 1 + (IF t >= 100 THEN INTEGER(TRUNCATE((t - 100) / 60, 0)) ELSE 0).
                        IF k <= 4 THEN Disc(mFxX[s], mFxY[s], bands[b] * big, mBlast[k + 1]).
                    END.
                END.
                /* smoke: round(r / 4) discs of radius 2.5 in a row above the hole, rising and ageing */
                IF t >= 200 THEN DO:
                    tone = 2 + INTEGER(TRUNCATE((t - 200) / 150, 0)).
                    IF tone <= 5 THEN DO i = 0 TO INTEGER(ROUND(r / 4, 0)) - 1:
                        sx = mFxX[s] - INTEGER(ROUND(r * 0.6, 0)) + 6 * i.
                        sy = mFxY[s] - r - 6 - (IF i MODULO 2 = 1 THEN 3 ELSE 0) - INTEGER(TRUNCATE((t - 200) / 60, 0)).
                        Disc(sx, sy, 2.5, mSmoke[tone]).
                    END.
                END.
            END.
            mCanvas:EndBatch().
            DO s = 1 TO 4:
                t = ms - mFxMs[s].
                IF t < 0 THEN NEXT.
                r = mFxR[s].
                /* the shock ring: 60 pixels, a pixel for every 6 degrees, moving out until 250 ms */
                IF t >= 33 AND t < 250 THEN DO i = 0 TO 59:
                    hd = INTEGER(ROUND(i * 64 / 60, 0)).
                    rad = r + 2 + INTEGER(TRUNCATE((t - 33) / 20, 0)).
                    mCanvas:Plot(mFxX[s] + INTEGER(ROUND(Heading:DirX(hd) * rad / Heading:Scale(), 0)),
                                 mFxY[s] + INTEGER(ROUND(Heading:DirY(hd) * rad / Heading:Scale(), 0)), 0, mBlast[2]).
                END.
                /* the scorch glows and cools over 600 ms */
                IF t < 600 THEN DO i = 1 TO mFxRings[s]:
                    n = (s - 1) * 800 + i.
                    IF mGame:Land:ScorchStep(mRingX[n], mRingY[n]) = mRingS[n] THEN
                        mCanvas:Plot(mRingX[n], mRingY[n], {&KIND-LAND}, mGame:Land:ScorchColour(mRingS[n], t)).
                END.
            END.
        END.
        DO i = 1 TO 256:
            IF NOT mDbLive[i] THEN NEXT.
            sx = BuddyRules:Pixel(mDbX[i]).
            sy = BuddyRules:Pixel(mDbY[i]).
            mCanvas:Plot(sx, sy, 0, mDbC[i]).
            IF mDbWide[i] THEN mCanvas:Plot(sx + 1, sy, 0, mDbC[i]).
        END.
    END METHOD.

    /* Shakes the whole picture, but not the HUD (which is drawn after): a radius 30 blast moves it 2 pixels for 5 frames, a radius 20
       blast 1 pixel for 3, and smaller ones not at all. */
    METHOD PRIVATE VOID ApplyShake():
        DEFINE VARIABLE s  AS INTEGER NO-UNDO.
        DEFINE VARIABLE f  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DEFINE VARIABLE t  AS INTEGER NO-UNDO.
        DO s = 1 TO 4:
            t = mGame:ElapsedMs - mFxMs[s].
            IF t < 0 OR t >= 84 THEN NEXT.
            f = INTEGER(TRUNCATE(t * 60 / 1000, 0)).
            IF mFxR[s] >= 30 AND f <= 4 THEN DO:
                dx = INTEGER(ENTRY(f + 1, "2,-2,1,-1,0")).
                dy = INTEGER(ENTRY(f + 1, "1,-1,0,0,0")).
            END.
            ELSE IF mFxR[s] >= 20 AND f <= 2 THEN DO:
                dx = INTEGER(ENTRY(f + 1, "1,-1,0")).
                dy = 0.
            END.
        END.
        IF dx <> 0 OR dy <> 0 THEN mCanvas:ShiftView(0, 0, {&W}, {&H}, dx, dy).
    END METHOD.

    /* ================================ the arrival and the title ================================ */

    /* How long ago a buddy touched down, in milliseconds, in the first seconds of a match (they come down by parachute one every 150 ms from
       300 ms, in turn order, at 2 pixels a frame); negative while it is still on its way, and its distance to fall is then 12 pixels above the
       top of the map down to its place. */
    METHOD PRIVATE INTEGER ArrivalAge(INPUT poBuddy AS Buddy, INPUT piOrder AS INTEGER):
        DEFINE VARIABLE since AS INTEGER NO-UNDO.
        DEFINE VARIABLE fall  AS INTEGER NO-UNDO.
        since = mGame:ElapsedMs - mGame:MatchStartMs - (300 + 150 * piOrder).
        fall = INTEGER(TRUNCATE((poBuddy:Y() + 12) * 1000 / 120, 0)).
        RETURN since - fall.
    END METHOD.

    /* A buddy in the first seconds: not there yet, or falling under a parachute, or just landed and pleased about it. */
    METHOD PRIVATE VOID DrawArriving(INPUT poBuddy AS Buddy, INPUT piKey AS INTEGER, INPUT piOrder AS INTEGER):
        DEFINE VARIABLE since AS INTEGER NO-UNDO.
        DEFINE VARIABLE lift    AS INTEGER NO-UNDO.
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        DEFINE VARIABLE head  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sway  AS INTEGER NO-UNDO.
        IF poBuddy:State = BuddyState:Drowned THEN RETURN.
        since = mGame:ElapsedMs - mGame:MatchStartMs - (300 + 150 * piOrder).
        IF since < 0 THEN RETURN.
        age = ArrivalAge(poBuddy, piOrder).
        IF age < 0 THEN DO:
            /* on the way down at 2 pixels a frame, in the air with the chute open over its head */
            lift = (poBuddy:Y() + 12) - INTEGER(TRUNCATE(since * 120 / 1000, 0)).
            sway = INTEGER(TRUNCATE(mGame:ElapsedMs / 600, 0)) MODULO 2.
            DrawPose(poBuddy, "goon_jump_fall", lift).
            head = poBuddy:Y() - lift - 12.
            mSprites:Stamp("chute_0", 0, FALSE):DrawTo(mCanvas, poBuddy:X() - mSprites:OriginX("chute_0", FALSE) + sway, head - mSprites:OriginY("chute_0")).
            RETURN.
        END.
        IF age < 150 THEN mSprites:Stamp("chute_1", 0, FALSE):DrawTo(mCanvas, poBuddy:X() - mSprites:OriginX("chute_1", FALSE), poBuddy:Y() - mSprites:OriginY("chute_1")).
        IF age < 120 THEN DrawPose(poBuddy, "goon_land", 0).
        ELSE IF age < 520 THEN DrawPose(poBuddy, "goon_grin", 0).
        ELSE DrawGoon(poBuddy, piKey).
    END METHOD.

    /* The title screen: the name of the game in big gradient letters over the land, four goons being silly, and a rocket that comes
       in from the left, bites the last S of BUDDIES, and leaves a scorched bite in it. It all runs on a loop of 8 seconds. */
    METHOD PRIVATE VOID DrawTitle():
        DEFINE VARIABLE t      AS INTEGER NO-UNDO.
        DEFINE VARIABLE loop1  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ink    AS INTEGER NO-UNDO.
        DEFINE VARIABLE top    AS INTEGER NO-UNDO.
        DEFINE VARIABLE bottom AS INTEGER NO-UNDO.
        DEFINE VARIABLE p      AS DECIMAL NO-UNDO.
        DEFINE VARIABLE rx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ry     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hd     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE pose   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE gx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy     AS INTEGER NO-UNDO.
        t = mGame:ElapsedMs MODULO 8000.
        loop1 = INTEGER(TRUNCATE(mGame:ElapsedMs / 8000, 0)).
        ink = BuddiesLook:Colour(BuddyTint:Outline).
        top = BuddiesLook:Colour(BuddyTint:TitleTop).
        bottom = BuddiesLook:Colour(BuddyTint:TitleBottom).
        Centred("BLAST", 5, top, bottom, ink, 34).
        Centred("BUDDIES", 5, top, bottom, ink, 76).
        /* the rocket arrives at 1500 ms, climbs on an arc and hits the top right corner of the last S at 2700 ms */
        IF t >= 1500 AND t < 2700 THEN DO:
            p = (t - 1500) / 1200.
            rx = -10 + INTEGER(ROUND(304 * p, 0)).
            ry = INTEGER(ROUND(120 - 40 * p - 30 * p * (1 - p), 0)).
            hd = Heading:Nearest(304, INTEGER(ROUND(-40 - 30 * (1 - 2 * p), 0))).
            IF mGame:ElapsedMs - mTrailLast >= 50 THEN DO:
                mTrailLast = mGame:ElapsedMs.
                mTrailX[mTrailNext] = rx - INTEGER(TRUNCATE(Heading:DirX(hd) * 5 / Heading:Scale(), 0)).
                mTrailY[mTrailNext] = ry - INTEGER(TRUNCATE(Heading:DirY(hd) * 5 / Heading:Scale(), 0)).
                mTrailMs[mTrailNext] = mGame:ElapsedMs.
                mTrailNext = mTrailNext MODULO 12 + 1.
            END.
        END.
        DrawTrail().
        IF t >= 1500 AND t < 2700 THEN DO:
            r = mSprites:Reach("rocket").
            mSprites:Turned("rocket", hd, FALSE):DrawTo(mCanvas, rx - r, ry - r).
        END.
        IF t >= 2700 AND mTitleLoop <> loop1 THEN DO:
            mTitleLoop = loop1.
            AddBlast(294, 80, 12).
        END.
        /* the bite: the title within 7 pixels goes back to sky, a ring to 8.5 is smoke, and one to 10 is the scorch of the fire */
        IF t >= 2700 THEN DO dy = -10 TO 10:
            DO dx = -10 TO 10:
                d2 = dx * dx + dy * dy.
                IF d2 > 100 THEN NEXT.
                c = mCanvas:ColourAt(294 + dx, 80 + dy).
                IF c = mCanvas:BackAt(294 + dx, 80 + dy) THEN NEXT.
                IF d2 <= 49 THEN mCanvas:Plot(294 + dx, 80 + dy, 0, mCanvas:BackAt(294 + dx, 80 + dy)).
                ELSE IF d2 <= 72 THEN mCanvas:Plot(294 + dx, 80 + dy, 0, mSmoke[5]).
                ELSE mCanvas:Plot(294 + dx, 80 + dy, 0, mBlast[4]).
            END.
        END.
        /* sparks and puffs hanging round the bite for a second */
        IF t >= 2700 AND t < 3700 THEN DO i = 0 TO 9:
            hd = INTEGER(ROUND(i * 6.4, 0)).
            mCanvas:Plot(294 + INTEGER(ROUND(Heading:DirX(hd) * 14 / Heading:Scale(), 0)), 80 + INTEGER(ROUND(Heading:DirY(hd) * 14 / Heading:Scale(), 0)), 0, mBlast[2]).
            hd = INTEGER(ROUND(i * 6.4 + 3.2, 0)).
            mCanvas:Plot(294 + INTEGER(ROUND(Heading:DirX(hd) * 18 / Heading:Scale(), 0)), 80 + INTEGER(ROUND(Heading:DirY(hd) * 18 / Heading:Scale(), 0)), 0, mSmoke[2]).
        END.
        /* four goons being silly on the hills, who all jump when the rocket lands */
        DO i = 1 TO 4:
            gx = INTEGER(ENTRY(i, "60,90,236,266")).
            gy = mGame:Land:FirstGround(gx).
            IF gy = ? THEN gy = 150.
            IF t >= 2700 AND t < 3100 THEN pose = "goon_alarm_1".
            ELSE IF t >= 3100 THEN pose = "goon_grin".
            ELSE CASE i:
                WHEN 1 THEN pose = "goon_dance_" + ENTRY(INTEGER(TRUNCATE(mGame:ElapsedMs / 150, 0)) MODULO 4 + 1, "1,2,3,2").
                WHEN 2 THEN pose = "goon_grin".
                WHEN 3 THEN pose = "goon_taunt".
                OTHERWISE pose = "goon_dance_3".
            END CASE.
            DrawGoonAt(i, pose, gx, gy, i = 2 OR i = 4).
        END.
        /* the hint panel and the words on it */
        mCanvas:BeginBatch().
        Panel(45, 196, 293, 30, -1).
        mCanvas:EndBatch().
        Centred("ARROWS WALK AND AIM   ENTER JUMPS   SPACE FIRES", 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1, 201).
        IF INTEGER(TRUNCATE(mGame:ElapsedMs / 500, 0)) MODULO 2 = 0 THEN
            Centred("PRESS SPACE", 1, BuddiesLook:Colour(BuddyTint:Text), BuddiesLook:Colour(BuddyTint:Text), -1, 213).
    END METHOD.

    /* ================================ the end of the game and the pause ================================ */

    /* Whether the game has been won or drawn. */
    METHOD PRIVATE LOGICAL IsOver():
        RETURN mGame:Phase = BuddyPhase:Winner OR mGame:Phase = BuddyPhase:Draw.
    END METHOD.

    /* The dark band across the middle of the screen that carries the banner words, with orange rules on the given rows. */
    METHOD PRIVATE VOID BandPanel(INPUT piY AS INTEGER, INPUT piH AS INTEGER, INPUT piRules AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mCanvas:BeginBatch().
        Panel(0, piY, 384, piH, -1).
        DO i = 1 TO NUM-ENTRIES(piRules):
            mCanvas:DrawLine(0, piY + INTEGER(ENTRY(i, piRules)), 383, piY + INTEGER(ENTRY(i, piRules)), 0, BuddiesLook:Colour(BuddyTint:Accent)).
        END.
        mCanvas:EndBatch().
    END METHOD.

    /* Words centred across the screen. */
    METHOD PRIVATE VOID Centred(INPUT pcWords AS CHARACTER, INPUT piScale AS INTEGER, INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER,
                                INPUT piEdge AS INTEGER, INPUT piY AS INTEGER):
        mText:Get(pcWords, piScale, piTop, piBottom, piEdge):DrawTo(mCanvas, INTEGER(TRUNCATE(({&W} - PixelFont:WidthOf(pcWords) * piScale) / 2, 0)), piY).
    END METHOD.

    /* The winning team dances, and the band says who won, or that nobody did. */
    METHOD PRIVATE VOID DrawEndScreen():
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE j       AS INTEGER NO-UNDO.
        DEFINE VARIABLE n       AS INTEGER NO-UNDO.
        DEFINE VARIABLE hop     AS LOGICAL NO-UNDO.
        DEFINE VARIABLE b       AS Buddy   NO-UNDO.
        DEFINE VARIABLE names   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ink     AS INTEGER NO-UNDO.
        ink = BuddiesLook:Colour(BuddyTint:Outline).
        IF mGame:Phase = BuddyPhase:Winner THEN DO:
            /* the dance is the frames 1, 2, 3, 2 a hundred and fifty milliseconds each, with a hop of 2 pixels on the third */
            hop = (ENTRY(INTEGER(TRUNCATE(mGame:ElapsedMs / 150, 0)) MODULO 4 + 1, "1,2,3,2") = "3").
            DO j = 1 TO mGame:Plan:TeamAt(mGame:WinnerTeam):Count():
                b = mGame:Plan:TeamAt(mGame:WinnerTeam):BuddyAt(j).
                IF b:IsDead() THEN NEXT.
                DrawPose(b, "goon_dance_" + ENTRY(INTEGER(TRUNCATE(mGame:ElapsedMs / 150, 0)) MODULO 4 + 1, "1,2,3,2"), (IF hop THEN 2 ELSE 0)).
                n = n + 1.
                names = names + (IF names = "" THEN "" ELSE " AND ") + b:BuddyName.
            END.
            BandPanel(60, 64, "0,1,62,63").
            Centred(TeamName(mGame:WinnerTeam) + " WIN", 3, BuddiesLook:Colour(BuddyTint:TitleTop), BuddiesLook:Colour(BuddyTint:Good), ink, 70).
            Centred((IF n >= 3 THEN STRING(n) + " BUDDIES" ELSE names) + " STILL STANDING", 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1, 98).
        END.
        ELSE DO:
            BandPanel(60, 64, "0,1,62,63").
            Centred("NOBODY WINS", 3, BuddiesLook:Colour(BuddyTint:Label), mSmoke[4], ink, 70).
            Centred("EVERY BUDDY WENT BOOM", 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1, 98).
        END.
        IF INTEGER(TRUNCATE(mGame:ElapsedMs / 500, 0)) MODULO 2 = 0 THEN
            Centred("PRESS SPACE", 1, BuddiesLook:Colour(BuddyTint:Text), BuddiesLook:Colour(BuddyTint:Text), -1, 110).
    END METHOD.

    /* While the game is paused the picture stands still and a band says so. */
    METHOD PRIVATE VOID DrawPaused():
        IF NOT mGame:Paused THEN RETURN.
        BandPanel(96, 40, "0,39").
        Centred("PAUSED", 3, BuddiesLook:Colour(BuddyTint:Text), BuddiesLook:Colour(BuddyTint:Text), BuddiesLook:Colour(BuddyTint:Outline), 101).
        Centred("P TO PLAY ON   ESC TO QUIT", 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1, 125).
    END METHOD.

    /* ================================ the HUD and the banner ================================ */

    /* The team name in capitals. */
    METHOD PRIVATE CHARACTER TeamName(INPUT piTeam AS INTEGER):
        RETURN ENTRY(piTeam, "REDS,BLUES,TEALS,GRAPES").
    END METHOD.

    /* A panel in a batch: a dark plate with a lighter line on its second row and its second last, and the four corner pixels left out so it
       looks rounded. A frame colour of -1 is no frame, else the outer edge is drawn in it. */
    METHOD PRIVATE VOID Panel(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piFrame AS INTEGER):
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE plate AS INTEGER NO-UNDO.
        DEFINE VARIABLE rule  AS INTEGER NO-UNDO.
        plate = BuddiesLook:Colour(BuddyTint:Panel).
        rule = BuddiesLook:Colour(BuddyTint:PanelRule).
        DO y = piY TO piY + piH - 1:
            IF y = piY OR y = piY + piH - 1 THEN
                mCanvas:DrawLine(piX + 1, y, piX + piW - 2, y, 0, (IF piFrame >= 0 THEN piFrame ELSE plate)).
            ELSE DO:
                mCanvas:DrawLine(piX, y, piX + piW - 1, y, 0, plate).
                IF y = piY + 1 OR y = piY + piH - 2 THEN mCanvas:DrawLine(piX + 1, y, piX + piW - 2, y, 0, rule).
                IF piFrame >= 0 THEN DO:
                    mCanvas:DrawLine(piX, y, piX, y, 0, piFrame).
                    mCanvas:DrawLine(piX + piW - 1, y, piX + piW - 1, y, 0, piFrame).
                END.
            END.
        END.
    END METHOD.

    /* The seconds left on the clock of the phase, rounded lift. */
    METHOD PRIVATE INTEGER SecondsLeft():
        RETURN INTEGER(TRUNCATE((mGame:TimeLeftMs + 999) / 1000, 0)).
    END METHOD.

    /* The timer, the buddy in turn, the wind, and the health of the teams. */
    METHOD PRIVATE VOID DrawHud():
        DEFINE VARIABLE secs    AS INTEGER NO-UNDO.
        DEFINE VARIABLE playing AS LOGICAL NO-UNDO.
        DEFINE VARIABLE frame1  AS INTEGER NO-UNDO.
        DEFINE VARIABLE digits  AS INTEGER NO-UNDO.
        DEFINE VARIABLE words   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE lit     AS LOGICAL NO-UNDO.
        DEFINE VARIABLE w       AS INTEGER NO-UNDO.
        DEFINE VARIABLE t       AS INTEGER NO-UNDO.
        DEFINE VARIABLE team    AS Team    NO-UNDO.
        DEFINE VARIABLE len     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c       AS INTEGER NO-UNDO.
        DEFINE VARIABLE tones   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ink     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hurtC   AS INTEGER NO-UNDO.
        DEFINE VARIABLE goodC   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ruleC   AS INTEGER NO-UNDO.
        DEFINE VARIABLE phase1  AS BuddyPhase NO-UNDO.
        phase1 = mGame:Phase.
        playing = (phase1 = BuddyPhase:Turn OR phase1 = BuddyPhase:Retreat).
        secs = SecondsLeft().
        ink = BuddiesLook:Colour(BuddyTint:Outline).
        hurtC = BuddiesLook:Colour(BuddyTint:Hurt).
        goodC = BuddiesLook:Colour(BuddyTint:Good).
        ruleC = BuddiesLook:Colour(BuddyTint:PanelRule).
        /* the plates, in one batch */
        frame1 = BuddiesLook:Colour(BuddyTint:Accent).
        IF phase1 = BuddyPhase:Turn AND secs <= 10 AND INTEGER(TRUNCATE(mGame:TimeLeftMs / 500, 0)) MODULO 2 = 1 THEN frame1 = BuddiesLook:Colour(BuddyTint:Warn).
        mCanvas:BeginBatch().
        Panel(4, 4, 30, 24, frame1).
        Panel(38, 4, 92, 24, -1).
        Panel(296, 4, 84, 24, -1).
        Panel(124, 222, 136, 18, -1).
        /* the chevrons of the wind: ten of them, the first |wind| lit from the end the wind comes from */
        DO i = 0 TO 9:
            lit = (IF mGame:Wind >= 0 THEN i < mGame:Wind ELSE i >= 10 + mGame:Wind).
            DO c = 0 TO 4:
                w = (IF c < 3 THEN c ELSE 4 - c).
                IF mGame:Wind < 0 THEN w = 2 - w.
                mCanvas:DrawLine(304 + 4 * i + w, 18 + c, 304 + 4 * i + w, 18 + c, 0, (IF lit THEN ColourMath:Mix(goodC, hurtC, i, 9) ELSE ruleC)).
            END.
        END.
        /* the bars of the teams: the sum of the health of their buddies, a quarter of a pixel for each point of 400, with a pattern each */
        DO t = 1 TO mGame:Plan:TeamCount():
            team = mGame:Plan:TeamAt(t).
            tones = BuddiesLook:ToneRow(ENTRY(team:Number, "Reds,Blues,Teals,Grapes")).
            len = INTEGER(ROUND(team:TotalHealth() / 400 * 120, 0)).
            IF len < 1 THEN NEXT.
            c = 225 + 3 * (t - 1).
            mCanvas:DrawLine(130, c, 130 + len - 1, c, 0, ColourMath:FromHex(ENTRY(2, tones))).
            mCanvas:DrawLine(130, c + 1, 130 + len - 1, c + 1, 0, ColourMath:FromHex(ENTRY(3, tones))).
            DO i = 0 TO len - 1:
                CASE team:Number:
                    WHEN 2 THEN IF i MODULO 4 = 3 THEN mCanvas:DrawLine(130 + i, c, 130 + i, c + 1, 0, ColourMath:FromHex(ENTRY(4, tones))).
                    WHEN 3 THEN mCanvas:DrawLine(130 + i, c, 130 + i, c + 1, 0, ColourMath:FromHex(ENTRY((IF i MODULO 2 = 0 THEN 2 ELSE 3), tones))).
                    WHEN 4 THEN IF i MODULO 6 >= 4 THEN mCanvas:DrawLine(130 + i, c, 130 + i, c + 1, 0, ColourMath:FromHex(ENTRY(4, tones))).
                    OTHERWISE.
                END CASE.
            END.
        END.
        mCanvas:EndBatch().
        /* the words and numbers on the plates */
        IF playing THEN DO:
            words = STRING(secs).
            digits = (IF secs <= 10 AND phase1 = BuddyPhase:Turn THEN BuddiesLook:Colour(BuddyTint:Warn) ELSE
                      IF phase1 = BuddyPhase:Retreat THEN BuddiesLook:Colour(BuddyTint:Label) ELSE BuddiesLook:Colour(BuddyTint:Text)).
        END.
        ELSE DO:
            words = STRING(INTEGER(TRUNCATE(BuddyRules:TurnFrames() / 60, 0))).
            digits = BuddiesLook:Colour(BuddyTint:Label).
        END.
        mText:Get(words, 2, digits, digits, -1):DrawTo(mCanvas, 4 + INTEGER(TRUNCATE((30 - PixelFont:WidthOf(words) * 2) / 2, 0)), 9).
        IF VALID-OBJECT(mGame:CurrentBuddy) AND phase1 <> BuddyPhase:Arrival THEN DO:
            words = mGame:CurrentBuddy:BuddyName.
            mText:Get(words, 1, mTone2[mGame:CurrentBuddy:Team], mTone2[mGame:CurrentBuddy:Team], -1):DrawTo(mCanvas, 44, 8).
            words = TeamName(mGame:CurrentBuddy:Team).
            mText:Get(words, 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1):DrawTo(mCanvas, 44, 18).
            mSprites:Stamp("icon_bazooka", 0, FALSE):DrawTo(mCanvas, 112, 7).
        END.
        mText:Get("WIND", 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1):DrawTo(mCanvas, 302, 8).
    END METHOD.

    /* The banner across the middle of the screen at the start of a turn: the buddy that plays and the team. */
    METHOD PRIVATE VOID DrawBanner():
        DEFINE VARIABLE words AS CHARACTER NO-UNDO.
        DEFINE VARIABLE b     AS Buddy     NO-UNDO.
        DEFINE VARIABLE accent AS INTEGER  NO-UNDO.
        IF mGame:Phase <> BuddyPhase:Banner OR NOT VALID-OBJECT(mGame:CurrentBuddy) THEN RETURN.
        b = mGame:CurrentBuddy.
        accent = BuddiesLook:Colour(BuddyTint:Accent).
        mCanvas:BeginBatch().
        Panel(0, 96, 384, 40, -1).
        mCanvas:DrawLine(0, 96, 383, 96, 0, accent).
        mCanvas:DrawLine(0, 135, 383, 135, 0, accent).
        mCanvas:EndBatch().
        words = b:BuddyName.
        mText:Get(words, 3, mTone1[b:Team], mTone1[b:Team], BuddiesLook:Colour(BuddyTint:Outline)):DrawTo(mCanvas,
            INTEGER(TRUNCATE((384 - PixelFont:WidthOf(words) * 3) / 2, 0)), 101).
        words = TeamName(b:Team) + " TURN" + (IF mGame:Plan:TeamAt(b:Team):IsComputer THEN "   COMPUTER" ELSE "").
        mText:Get(words, 1, BuddiesLook:Colour(BuddyTint:Label), BuddiesLook:Colour(BuddyTint:Label), -1):DrawTo(mCanvas,
            INTEGER(TRUNCATE((384 - PixelFont:WidthOf(words)) / 2, 0)), 125).
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
