/* Draws Centipede in its "Moonlit Bed" look (colours in CentipedeLook, sprites in CentipedeArt, both made from the designer's file by
   tools/gen-centipede-art.py). It reads a CentipedeGame, never changes it, and paints the picture on a pixel canvas of its own: a
   strip of numbers above the board, then the 30 x 30 board of 8 pixel tiles, 240 x 256 pixels in all. The canvas is handed to the
   window's renderer (the inner one), so the game's own grid is left as it is.

   What is kept in the picture's background: the night, the lighter band of the player zone and the rules, and every obstacle (a
   bulb). The bulbs are drawn into the background again only when the game says the field changed (FieldVersion) or the night
   changed (the wave), so a frame costs one block copy and the things that move. Everything that moves, and every effect, is a
   function of the game's own frame counts (Frames, PhaseFrames), so the painter keeps no clock of its own and a test sees the
   same picture for the same game.

   The names of the design (the Wick for the shooter, the Gloam for the crawler, bulbs for the mushrooms, the Sower, the Skitterjack
   and the Moonsnail for the flea, the spider and the scorpion) are used in comments here; the game's own names stay as they are.

   The painter owns canvases and text stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedePainter FINAL IMPLEMENTS IGridRenderer:

    /* the height of the strip of numbers above the board, and the size of the picture */
    &SCOPED-DEFINE STRIP 16
    &SCOPED-DEFINE WIDTH 240
    &SCOPED-DEFINE HEIGHT 256
    /* the canvas row of the top of the band (the player zone) and the rows the stars drift in */
    &SCOPED-DEFINE BAND-TOP 208

    VAR PRIVATE IGridRenderer mInner.
    VAR PRIVATE CentipedeGame mGame.
    VAR PRIVATE Grid mGrid.
    VAR PRIVATE Grid mBaseGrid.
    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE PixelCanvas mBase.
    VAR PRIVATE TextStampCache mText.
    /* the colour of each character of a sprite string, by character code plus one (letters and digits only are used) */
    VAR PRIVATE INTEGER[128] mPal.
    /* the character codes of the three family places in a sprite */
    VAR PRIVATE INTEGER mCodeLight.
    VAR PRIVATE INTEGER mCodeBody.
    VAR PRIVATE INTEGER mCodeDeep.
    /* the version of the field, and the wave, that are baked into the background, -1 for none yet */
    VAR PRIVATE INTEGER mBakedVersion = -1.
    VAR PRIVATE INTEGER mBakedWave = -1.
    VAR PRIVATE LOGICAL mDisposed.

    /* The places of the far layer (stars), the near layer (fireflies) and the front layer (grass), from the design. */
    VAR PRIVATE INTEGER[18] mStarX = [13, 47, 88, 121, 160, 203, 229, 30, 72, 140, 186, 11, 101, 215, 58, 176, 124, 34].
    VAR PRIVATE INTEGER[18] mStarY = [22, 61, 30, 102, 47, 77, 140, 128, 170, 160, 118, 190, 75, 24, 101, 184, 196, 58].
    VAR PRIVATE INTEGER[5] mFlyX = [40, 190, 120, 70, 210].
    VAR PRIVATE INTEGER[5] mFlyY = [70, 52, 140, 180, 160].
    VAR PRIVATE DECIMAL[5] mFlyP = [0.0, 1.7, 3.1, 4.4, 2.2].
    VAR PRIVATE INTEGER[32] mGrassX = [3, 9, 14, 22, 31, 37, 44, 53, 60, 66, 75, 83, 90, 98, 106, 113, 121, 128, 137, 144, 151, 160, 167, 175, 182, 190, 199, 206, 213, 221, 228, 236].

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* The height of the strip of numbers above the board, in pixels. */
    DEFINE PUBLIC PROPERTY StripHeight AS INTEGER NO-UNDO
        GET():
            RETURN {&STRIP}.
        END GET.

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC CentipedePainter(INPUT poInner AS IGridRenderer, INPUT poGame AS CentipedeGame):
        VAR INTEGER i.
        VAR CentipedeTint tint.
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Centipede painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Centipede painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mText = NEW TextStampCache(96).
        /* every real colour (the three family places come last in the enum and have none) is put in the table by its character */
        DO i = 0 TO INTEGER(CentipedeTint:FamilyLight) - 1:
            tint = CentipedeTint:GetEnum(i).
            mPal[ASC(CentipedeLook:CodeOf(tint)) + 1] = CentipedeLook:Colour(tint).
        END.
        mCodeLight = ASC(CentipedeLook:CodeOf(CentipedeTint:FamilyLight)) + 1.
        mCodeBody = ASC(CentipedeLook:CodeOf(CentipedeTint:FamilyBody)) + 1.
        mCodeDeep = ASC(CentipedeLook:CodeOf(CentipedeTint:FamilyDeep)) + 1.
        mGrid = NEW Grid(NEW ArrayStore({&WIDTH}, {&HEIGHT}, "view,kind,back")).
        mBaseGrid = NEW Grid(NEW ArrayStore({&WIDTH}, {&HEIGHT}, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mBase = NEW PixelCanvas(mBaseGrid).
        BuildBase().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC CentipedePainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not a
       Centipede game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, CentipedeGame) THEN UNDO, THROW NEW GridException("A Centipede painter draws a Centipede game").
        IF mBakedVersion <> mGame:FieldVersion OR mBakedWave <> ShownWave() THEN BakeField().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawDepth().
        DrawHud().
        IF mGame:Phase = GamePhase:Title THEN DrawTitle().
        ELSE DO:
            DrawCreatures().
            DrawSegments().
            DrawPlayer().
            DrawBonus().
            IF mGame:Phase = GamePhase:Playing AND mGame:PhaseFrames < 90 THEN DrawWaveStart().
        END.
        mCanvas:EndBatch().
        IF mGame:Phase = GamePhase:GameOver OR (mGame:Paused AND mGame:Phase <> GamePhase:Title) THEN DO:
            /* the board is dimmed once, with the batch closed, and then the words go on it */
            mCanvas:DimRect(0, {&STRIP}, {&WIDTH}, {&HEIGHT} - {&STRIP}, 55, CentipedeLook:Colour(CentipedeTint:Ink)).
            mCanvas:BeginBatch().
            IF mGame:Phase = GamePhase:GameOver THEN DrawGameOver().
            ELSE DrawPaused().
            mCanvas:EndBatch().
        END.
        ELSE IF mGame:Phase = GamePhase:Cleared THEN DO:
            mCanvas:BeginBatch().
            DrawCleared().
            mCanvas:EndBatch().
        END.
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvases and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        IF VALID-OBJECT(mText) THEN mText:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mBase) THEN mBase:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        IF VALID-OBJECT(mBaseGrid) THEN mBaseGrid:Dispose().
    END METHOD.

    /* ================================ sprites ================================ */

    /* Draws a sprite with its top left at piX, piY. The three family places take piLight, piBody and piDeep. A mirrored sprite is
       turned left to right. piOver, when it is not -1, draws every cell of the sprite in that one colour. */
    METHOD PRIVATE VOID Blit(INPUT poSprite AS CentipedeSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                             INPUT piLight AS INTEGER, INPUT piBody AS INTEGER, INPUT piDeep AS INTEGER, INPUT piOver AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR CHARACTER ch.
        cells = CentipedeArt:Cells(poSprite).
        w = CentipedeArt:Width(poSprite).
        h = CentipedeArt:Height(poSprite).
        mPal[mCodeLight] = piLight.
        mPal[mCodeBody] = piBody.
        mPal[mCodeDeep] = piDeep.
        DO cy = 0 TO h - 1:
            DO cx = 0 TO w - 1:
                ch = SUBSTRING(cells, cy * w + cx + 1, 1).
                IF ch = "." THEN NEXT.
                mCanvas:Plot((IF plMirror THEN piX + w - 1 - cx ELSE piX + cx), piY + cy, 0, (IF piOver >= 0 THEN piOver ELSE mPal[ASC(ch) + 1])).
            END.
        END.
    END METHOD.

    /* A sprite with fixed colours only (no family places). */
    METHOD PRIVATE VOID Stamp(INPUT poSprite AS CentipedeSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        Blit(poSprite, piX, piY, FALSE, 0, 0, 0, -1).
    END METHOD.

    /* A sprite in the colours of one family of the night. */
    METHOD PRIVATE VOID StampFamily(INPUT poSprite AS CentipedeSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                                    INPUT piFamily AS INTEGER):
        Blit(poSprite, piX, piY, plMirror, CentipedeLook:FamilyColour(piFamily, 1), CentipedeLook:FamilyColour(piFamily, 2),
             CentipedeLook:FamilyColour(piFamily, 3), -1).
    END METHOD.

    /* A one cell glow round a sprite: every empty cell touching one that is drawn takes piPercent percent of piColour. Drawn before the
       sprite, over what is already there (the background). */
    METHOD PRIVATE VOID Glow(INPUT poSprite AS CentipedeSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                             INPUT piColour AS INTEGER, INPUT piPercent AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER nx.
        VAR INTEGER ny.
        VAR LOGICAL lit.
        VAR INTEGER px.
        cells = CentipedeArt:Cells(poSprite).
        w = CentipedeArt:Width(poSprite).
        h = CentipedeArt:Height(poSprite).
        DO cy = -1 TO h:
            DO cx = -1 TO w:
                IF cx >= 0 AND cx < w AND cy >= 0 AND cy < h AND SUBSTRING(cells, cy * w + cx + 1, 1) <> "." THEN NEXT.
                lit = FALSE.
                DO dy = -1 TO 1 WHILE NOT lit:
                    DO dx = -1 TO 1 WHILE NOT lit:
                        nx = cx + dx.
                        ny = cy + dy.
                        IF nx >= 0 AND nx < w AND ny >= 0 AND ny < h AND SUBSTRING(cells, ny * w + nx + 1, 1) <> "." THEN lit = TRUE.
                    END.
                END.
                IF NOT lit THEN NEXT.
                px = (IF plMirror THEN piX + w - 1 - cx ELSE piX + cx).
                IF mCanvas:ColourAt(px, piY + cy) >= 0 THEN
                    mCanvas:Plot(px, piY + cy, 0, ColourMath:Mix(mCanvas:ColourAt(px, piY + cy), piColour, piPercent, 100)).
            END.
        END.
    END METHOD.

    /* The sprite of a bulb with piHp hit points left (1 to 4), or of a blighted one. */
    METHOD PRIVATE CentipedeSprite BulbSprite(INPUT piHp AS INTEGER, INPUT plBlight AS LOGICAL):
        CASE piHp:
            WHEN 4 THEN RETURN (IF plBlight THEN CentipedeSprite:Blight4 ELSE CentipedeSprite:Bulb4).
            WHEN 3 THEN RETURN (IF plBlight THEN CentipedeSprite:Blight3 ELSE CentipedeSprite:Bulb3).
            WHEN 2 THEN RETURN (IF plBlight THEN CentipedeSprite:Blight2 ELSE CentipedeSprite:Bulb2).
            OTHERWISE RETURN (IF plBlight THEN CentipedeSprite:Blight1 ELSE CentipedeSprite:Bulb1).
        END CASE.
    END METHOD.

    /* The picture of walking step piStep (1 to 4) of a bead, or of a head. */
    METHOD PRIVATE CentipedeSprite BeadSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 1 THEN RETURN CentipedeSprite:Bead1.
            WHEN 2 THEN RETURN CentipedeSprite:Bead2.
            WHEN 3 THEN RETURN CentipedeSprite:Bead3.
            OTHERWISE RETURN CentipedeSprite:Bead4.
        END CASE.
    END METHOD.

    METHOD PRIVATE CentipedeSprite HeadSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 1 THEN RETURN CentipedeSprite:Head1.
            WHEN 2 THEN RETURN CentipedeSprite:Head2.
            WHEN 3 THEN RETURN CentipedeSprite:Head3.
            OTHERWISE RETURN CentipedeSprite:Head4.
        END CASE.
    END METHOD.

    /* The moon of the night of a wave, in the strip and on the wave banner. */
    METHOD PRIVATE CentipedeSprite MoonSprite(INPUT piWave AS INTEGER):
        CASE (piWave - 1) MODULO 6:
            WHEN 0 THEN RETURN CentipedeSprite:Moon1.
            WHEN 1 THEN RETURN CentipedeSprite:Moon2.
            WHEN 2 THEN RETURN CentipedeSprite:Moon3.
            WHEN 3 THEN RETURN CentipedeSprite:Moon4.
            WHEN 4 THEN RETURN CentipedeSprite:Moon5.
            OTHERWISE RETURN CentipedeSprite:Moon6.
        END CASE.
    END METHOD.

    /* The wave whose night is shown: the game's wave, or on the title screen the one the crawling Gloam is showing. */
    METHOD PRIVATE INTEGER ShownWave():
        IF mGame:Phase = GamePhase:Title THEN RETURN INTEGER(TRUNCATE(mGame:Frames / 360, 0)) MODULO 6 + 1.
        RETURN MAXIMUM(1, mGame:Wave).
    END METHOD.

    /* ================================ the background ================================ */

    /* The plain background, made once on the base canvas: the strip, the night with a dotted rule under each row, and the quieter
       band of the player zone with its top line. */
    METHOD PRIVATE VOID BuildBase():
        VAR INTEGER[] rows.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER tileRow.
        VAR INTEGER rule.
        VAR INTEGER bandRule.
        EXTENT(rows) = {&HEIGHT}.
        DO y = 0 TO {&HEIGHT} - 1:
            IF y < {&STRIP} - 1 THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Strip).
            ELSE IF y = {&STRIP} - 1 THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:StripRule).
            ELSE IF y < {&BAND-TOP} THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Night).
            ELSE IF y = {&BAND-TOP} THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:BandRule).
            ELSE rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Band).
        END.
        mBase:SetBackRows(rows).
        /* the dotted rules: the last line of every tile row, a cell in four above the band and a cell in eight in it */
        rule = CentipedeLook:Colour(CentipedeTint:Rule).
        bandRule = CentipedeLook:Colour(CentipedeTint:BandRule).
        DO tileRow = 0 TO CentipedeRules:Rows() - 1:
            IF tileRow = CentipedeRules:PlayerTop() - 1 THEN NEXT.
            y = {&STRIP} + tileRow * CentipedeRules:Tile() + 7.
            IF tileRow < CentipedeRules:PlayerTop() THEN DO x = 2 TO {&WIDTH} - 1 BY 4:
                mBase:SetBack(x, y, rule).
            END.
            ELSE DO x = 2 TO {&WIDTH} - 1 BY 8:
                mBase:SetBack(x, y, bandRule).
            END.
        END.
    END METHOD.

    /* Draws every bulb into the background of the picture, so a frame brings them back with one block copy. */
    METHOD PRIVATE VOID BakeField():
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER hp.
        VAR INTEGER family.
        mBakedVersion = mGame:FieldVersion.
        mBakedWave = ShownWave().
        family = CentipedeLook:BulbFamily(mBakedWave).
        mCanvas:LoadBack(mBase).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO cy = 0 TO CentipedeRules:Rows() - 1:
            DO cx = 0 TO CentipedeRules:Cols() - 1:
                hp = mGame:MushroomAt(cx, cy).
                IF hp > 0 THEN DrawBulb(cx, cy, hp, mGame:PoisonedAt(cx, cy), family).
            END.
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    /* A bulb: whole, or eaten from below by the sparks, or pale with blight. */
    METHOD PRIVATE VOID DrawBulb(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHp AS INTEGER, INPUT plBlight AS LOGICAL, INPUT piFamily AS INTEGER):
        StampFamily(BulbSprite(piHp, plBlight), piX * CentipedeRules:Tile(), {&STRIP} + piY * CentipedeRules:Tile(), FALSE, piFamily).
    END METHOD.

    /* The sine of an angle in radians (ABL has none), by a parabola that is never more than 0.06 out, which is plenty for a firefly. */
    METHOD PRIVATE DECIMAL Sine(INPUT pdAngle AS DECIMAL):
        VAR DECIMAL x.
        x = pdAngle - 6.2831853 * TRUNCATE(pdAngle / 6.2831853, 0).
        IF x > 3.1415927 THEN x = x - 6.2831853.
        IF x < -3.1415927 THEN x = x + 6.2831853.
        RETURN 1.2732395 * x - 0.4052847 * x * ABSOLUTE(x).
    END METHOD.

    /* The three layers that give the flat bed some depth: slow stars, fireflies, and grass at the foot of the band. They go over the
       background only, so they never cover anything that matters. */
    METHOD PRIVATE VOID DrawDepth():
        VAR INTEGER i.
        VAR INTEGER k.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR DECIMAL t.
        VAR INTEGER blade.
        VAR INTEGER night.
        VAR INTEGER lean.
        VAR INTEGER tall.
        night = CentipedeLook:Colour(CentipedeTint:Night).
        DO i = 1 TO 18:
            y = {&STRIP} + (mStarY[i] - {&STRIP} + INTEGER(TRUNCATE(mGame:Frames / 64, 0))) MODULO ({&BAND-TOP} - {&STRIP} - 2).
            IF mCanvas:ColourAt(mStarX[i], y) = night THEN mCanvas:Plot(mStarX[i], y, 0, CentipedeLook:Colour(CentipedeTint:Mote)).
        END.
        DO i = 1 TO 5:
            x = mFlyX[i] + INTEGER(ROUND(9 * Sine(DECIMAL(mGame:Frames) / 110 + mFlyP[i]), 0)).
            y = mFlyY[i] + INTEGER(ROUND(5 * Sine(DECIMAL(mGame:Frames) / 80 + 1.3 * mFlyP[i]), 0)).
            t = 0.5 + 0.5 * Sine(DECIMAL(mGame:Frames) / 24 + mFlyP[i]).
            IF mCanvas:ColourAt(x, y) = night THEN
                mCanvas:Plot(x, y, 0, ColourMath:Mix(CentipedeLook:Colour(CentipedeTint:Firefly), night, INTEGER(ROUND(60 * (1 - t), 0)), 100)).
        END.
        blade = CentipedeLook:Colour(CentipedeTint:BandRule).
        DO i = 1 TO 32:
            tall = 2 + ((i - 1) * 7) MODULO 3.
            lean = (INTEGER(TRUNCATE(mGame:Frames / 40, 0)) + i - 1) MODULO 2.
            DO k = 0 TO tall - 1:
                mCanvas:Plot(mGrassX[i] + (IF k = tall - 1 THEN lean ELSE 0), {&HEIGHT} - 1 - k, 0, blade).
            END.
        END.
    END METHOD.

    /* ================================ what moves ================================ */

    /* The strip: the score, the best score, the moon of the night, the wave and a Wick for each spare life. */
    METHOD PRIVATE VOID DrawHud():
        VAR INTEGER i.
        Words(STRING(mGame:Score), 1, CentipedeTint:Points, CentipedeTint:Points, 4, 4, FALSE, FALSE).
        Words("HI", 1, CentipedeTint:TextDim, CentipedeTint:TextDim, 82, 4, FALSE, FALSE).
        Words(STRING(mGame:HiScore), 1, CentipedeTint:Text, CentipedeTint:Text, 96, 4, FALSE, FALSE).
        IF mGame:Phase <> GamePhase:Title THEN DO:
            Stamp(MoonSprite(mGame:Wave), 160, 4).
            Words(STRING(mGame:Wave), 1, CentipedeTint:Text, CentipedeTint:Text, 170, 4, FALSE, FALSE).
            DO i = 0 TO MINIMUM(5, mGame:Lives - 1) - 1:
                Stamp(CentipedeSprite:WickIcon, 231 - 8 * i, 5).
            END.
        END.
    END METHOD.

    /* The Wick, its spark and its muzzle flash, or the Wick breaking up. */
    METHOD PRIVATE VOID DrawPlayer():
        VAR INTEGER x.
        VAR INTEGER y.
        VAR CentipedeSprite sprite.
        x = mGame:PlayerX.
        y = {&STRIP} + mGame:PlayerY.
        IF mGame:Phase = GamePhase:Dying THEN DO:
            DrawBreakUp(x + 4, y + 4, mGame:PhaseFrames).
            RETURN.
        END.
        sprite = (IF INTEGER(TRUNCATE(mGame:Frames / 6, 0)) MODULO 2 = 0 THEN CentipedeSprite:Wick1 ELSE CentipedeSprite:Wick2).
        Glow(sprite, x, y, FALSE, CentipedeLook:Colour(CentipedeTint:WickLight), 18).
        Stamp(sprite, x, y).
        IF mGame:ShotActive THEN DO:
            Glow(CentipedeSprite:Spark, mGame:ShotX, {&STRIP} + mGame:ShotY, FALSE, CentipedeLook:Colour(CentipedeTint:SparkTail), 25).
            Stamp(CentipedeSprite:Spark, mGame:ShotX, {&STRIP} + mGame:ShotY).
            IF mGame:PlayerY - mGame:ShotY < 16 THEN Stamp(CentipedeSprite:Muzzle, x + 1, y - 3).
        END.
    END METHOD.

    /* The Wick breaking up: six pictures of ten frames each, centred on its middle, then nothing while the field is mended. */
    METHOD PRIVATE VOID DrawBreakUp(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piAge AS INTEGER):
        VAR CentipedeSprite sprite.
        IF piAge >= 60 THEN RETURN.
        CASE INTEGER(TRUNCATE(piAge / 10, 0)):
            WHEN 0 THEN sprite = CentipedeSprite:WickBreak1.
            WHEN 1 THEN sprite = CentipedeSprite:WickBreak2.
            WHEN 2 THEN sprite = CentipedeSprite:WickBreak3.
            WHEN 3 THEN sprite = CentipedeSprite:WickBreak4.
            WHEN 4 THEN sprite = CentipedeSprite:WickBreak5.
            OTHERWISE sprite = CentipedeSprite:WickBreak6.
        END CASE.
        Stamp(sprite, piCx - 8, piCy - 8).
    END METHOD.

    /* The Gloam: a bead for each segment, a head where the game says so. */
    METHOD PRIVATE VOID DrawSegments():
        VAR INTEGER i.
        DO i = 0 TO mGame:SegmentCount - 1:
            DrawGloamPart(mGame:SegmentX(i), {&STRIP} + mGame:SegmentY(i), mGame:SegmentIsHead(i), mGame:SegmentDirection(i) < 0,
                          mGame:SegmentDiving(i), i, mGame:Frames, CentipedeLook:CrawlerFamily(mGame:Wave)).
        END.
    END METHOD.

    /* One part of the Gloam. piIndex is its place in the train, which puts each bead half a step behind the one before. A part that is
       diving flickers in the colours of blight every four frames, and a head that dives is drawn looking down. */
    METHOD PRIVATE VOID DrawGloamPart(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plHead AS LOGICAL, INPUT plLeft AS LOGICAL,
                                      INPUT plDiving AS LOGICAL, INPUT piIndex AS INTEGER, INPUT piFrames AS INTEGER, INPUT piFamily AS INTEGER):
        VAR INTEGER walk.
        VAR INTEGER light.
        VAR INTEGER body.
        VAR INTEGER deep.
        VAR CentipedeSprite sprite.
        walk = INTEGER(TRUNCATE((piFrames + 2 * piIndex) / 4, 0)) MODULO 4 + 1.
        light = CentipedeLook:FamilyColour(piFamily, 1).
        body = CentipedeLook:FamilyColour(piFamily, 2).
        deep = CentipedeLook:FamilyColour(piFamily, 3).
        IF plDiving AND INTEGER(TRUNCATE(piFrames / 4, 0)) MODULO 2 = 0 THEN ASSIGN
            light = CentipedeLook:Colour(CentipedeTint:BlightLight)
            body = CentipedeLook:Colour(CentipedeTint:Blight).
        IF plHead THEN DO:
            sprite = (IF plDiving THEN CentipedeSprite:HeadDive ELSE HeadSprite(walk)).
            Glow(sprite, piX, piY, plLeft, CentipedeLook:FamilyColour(piFamily, 1), 30).
        END.
        ELSE sprite = BeadSprite(walk).
        Blit(sprite, piX, piY, plLeft AND NOT (plHead AND plDiving), light, body, deep, -1).
    END METHOD.

    METHOD PRIVATE VOID DrawCreatures():
        IF mGame:FleaActive THEN DrawSower().
        IF mGame:SpiderActive THEN DrawSkitterjack().
        IF mGame:ScorpionActive THEN DrawMoonsnail().
    END METHOD.

    /* The Sower (the flea): a seed beetle falling head first. After the first hit its shell is pale and it flickers white. */
    METHOD PRIVATE VOID DrawSower():
        VAR CentipedeSprite sprite.
        VAR LOGICAL wings.
        wings = INTEGER(TRUNCATE(mGame:Frames / 3, 0)) MODULO 2 = 0.
        IF mGame:FleaHp = 1 THEN DO:
            sprite = (IF wings THEN CentipedeSprite:SowerHurt1 ELSE CentipedeSprite:SowerHurt2).
            Blit(sprite, mGame:FleaX, {&STRIP} + mGame:FleaY, FALSE, 0, 0, 0,
                 (IF INTEGER(TRUNCATE(mGame:Frames / 2, 0)) MODULO 2 = 1 THEN CentipedeLook:Colour(CentipedeTint:Flash) ELSE -1)).
        END.
        ELSE Stamp((IF wings THEN CentipedeSprite:Sower1 ELSE CentipedeSprite:Sower2), mGame:FleaX, {&STRIP} + mGame:FleaY).
    END METHOD.

    /* The Skitterjack (the spider): legs that reach and pull by turns, and a crouch just before it bounces at the top or bottom of its path. */
    METHOD PRIVATE VOID DrawSkitterjack():
        VAR INTEGER walk.
        walk = INTEGER(TRUNCATE(mGame:Frames / 4, 0)) MODULO 4 + 1.
        IF mGame:SpiderY <= 162 OR mGame:SpiderY >= 230 THEN walk = 3.
        CASE walk:
            WHEN 1 THEN Stamp(CentipedeSprite:Skitterjack1, mGame:SpiderX, {&STRIP} + mGame:SpiderY).
            WHEN 2 THEN Stamp(CentipedeSprite:Skitterjack2, mGame:SpiderX, {&STRIP} + mGame:SpiderY).
            WHEN 3 THEN Stamp(CentipedeSprite:Skitterjack3, mGame:SpiderX, {&STRIP} + mGame:SpiderY).
            OTHERWISE Stamp(CentipedeSprite:Skitterjack4, mGame:SpiderX, {&STRIP} + mGame:SpiderY).
        END CASE.
    END METHOD.

    /* The Moonsnail (the scorpion): a pale shell that rides forward on a stretching foot, turned the way it is going. */
    METHOD PRIVATE VOID DrawMoonsnail():
        VAR CentipedeSprite sprite.
        sprite = (IF INTEGER(TRUNCATE(mGame:Frames / 8, 0)) MODULO 2 = 0 THEN CentipedeSprite:Moonsnail1 ELSE CentipedeSprite:Moonsnail2).
        Blit(sprite, mGame:ScorpionX, {&STRIP} + mGame:ScorpionY, mGame:ScorpionDirection < 0, 0, 0, 0, -1).
    END METHOD.

    /* The points of the last thing shot, for half a second where it was, rising a cell every eight frames. */
    METHOD PRIVATE VOID DrawBonus():
        VAR INTEGER age.
        IF mGame:LastBonusFrame < 0 THEN RETURN.
        age = mGame:Frames - mGame:LastBonusFrame.
        IF age >= 30 THEN RETURN.
        Words(STRING(mGame:LastBonus), 1, CentipedeTint:Points, CentipedeTint:Points,
              MAXIMUM(1, MINIMUM({&WIDTH} - 25, mGame:LastBonusX)), {&STRIP} + MAXIMUM(0, mGame:LastBonusY - INTEGER(TRUNCATE(age / 8, 0))), FALSE, TRUE).
    END METHOD.

    /* ================================ the screens ================================ */

    /* A soft dark banner over the field from row piY for piHeight rows: 60 percent ink, fading over its first and last three rows. */
    METHOD PRIVATE VOID Banner(INPUT piY AS INTEGER, INPUT piHeight AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER ink.
        ink = CentipedeLook:Colour(CentipedeTint:Ink).
        DO i = 0 TO piHeight - 1:
            mCanvas:DimRect(0, piY + i, {&WIDTH}, 1, MINIMUM(60, 15 * (MINIMUM(i, piHeight - 1 - i) + 1)), ink).
        END.
    END METHOD.

    /* The title: the name in big letters, the Gloam crossing under it on a new night each time, who is who, and what to press. */
    METHOD PRIVATE VOID DrawTitle():
        VAR INTEGER i.
        VAR INTEGER x.
        VAR INTEGER family.
        VAR INTEGER night.
        night = ShownWave().
        family = CentipedeLook:CrawlerFamily(night).
        Words("CENTIPEDE", 3, CentipedeTint:MoonTop, CentipedeTint:MoonLow, -1, 30, TRUE, TRUE).
        Words("A NIGHT IN THE GARDEN", 1, CentipedeTint:TextDim, CentipedeTint:TextDim, -1, 62, TRUE, FALSE).
        /* the Gloam, twelve parts, one cell a frame from right to left */
        x = 250 - mGame:Frames MODULO 360.
        DO i = 0 TO 11:
            DrawGloamPart(x + i * 8, 90, i = 0, TRUE, FALSE, i, mGame:Frames, family).
        END.
        DrawRollCall(night).
        IF INTEGER(TRUNCATE(mGame:Frames / 30, 0)) MODULO 2 = 0 THEN Words("PRESS SPACE", 2, CentipedeTint:Text, CentipedeTint:Text, -1, 214, TRUE, TRUE).
        Words("MOVE ARROWS  FIRE SPACE", 1, CentipedeTint:TextDim, CentipedeTint:TextDim, -1, 240, TRUE, FALSE).
    END METHOD.

    /* The roll call: each creature with its name and what it is worth. */
    METHOD PRIVATE VOID DrawRollCall(INPUT piNight AS INTEGER):
        VAR INTEGER y = 120.
        VAR INTEGER family.
        family = CentipedeLook:CrawlerFamily(piNight).
        StampFamily(CentipedeSprite:Head1, 60, y, FALSE, family).
        RollLine("GLOAMHEAD", "100", y).
        y = y + 14.
        StampFamily(CentipedeSprite:Bead1, 60, y, FALSE, family).
        RollLine("BEAD", "10", y).
        y = y + 14.
        Stamp(CentipedeSprite:Sower1, 60, y).
        RollLine("SOWER", "200", y).
        y = y + 14.
        Stamp(CentipedeSprite:Skitterjack1, 56, y).
        RollLine("SKITTERJACK", "300 600 900", y).
        y = y + 14.
        Stamp(CentipedeSprite:Moonsnail1, 56, y).
        RollLine("MOONSNAIL", "1000", y).
        y = y + 14.
        StampFamily(CentipedeSprite:Bulb4, 60, y, FALSE, CentipedeLook:BulbFamily(piNight)).
        RollLine("BULB", "1", y).
    END METHOD.

    METHOD PRIVATE VOID RollLine(INPUT pcName AS CHARACTER, INPUT pcPoints AS CHARACTER, INPUT piY AS INTEGER):
        Words(pcName, 1, CentipedeTint:Text, CentipedeTint:Text, 80, piY + 1, FALSE, FALSE).
        Words(pcPoints, 1, CentipedeTint:Points, CentipedeTint:Points, 154, piY + 1, FALSE, FALSE).
    END METHOD.

    /* The start of a night: WAVE n, the moon and the name of the night, on a banner. */
    METHOD PRIVATE VOID DrawWaveStart():
        Banner(90, 50).
        Words("WAVE " + STRING(mGame:Wave), 2, CentipedeTint:Text, CentipedeTint:Text, -1, 98, TRUE, TRUE).
        Stamp(MoonSprite(mGame:Wave), 116, 118).
        Words(CentipedeLook:NightName(mGame:Wave), 1, CentipedeTint:TextDim, CentipedeTint:TextDim, -1, 128, TRUE, FALSE).
    END METHOD.

    /* A plate with a one cell edge, centred across, whose middle is on row piMiddle. */
    METHOD PRIVATE VOID Plate(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT piTop AS INTEGER):
        VAR INTEGER x.
        x = INTEGER(TRUNCATE(({&WIDTH} - piWidth) / 2, 0)).
        mCanvas:FillRect(x, piTop, piWidth, piHeight, 0, CentipedeLook:Colour(CentipedeTint:StripRule)).
        mCanvas:FillRect(x + 1, piTop + 1, piWidth - 2, piHeight - 2, 0, CentipedeLook:Colour(CentipedeTint:Plate)).
    END METHOD.

    METHOD PRIVATE VOID DrawGameOver():
        Plate(168, 64, 96).
        Words("GAME OVER", 2, CentipedeTint:MoonTop, CentipedeTint:MoonLow, -1, 105, TRUE, TRUE).
        Words("SCORE " + STRING(mGame:Score), 1, CentipedeTint:Text, CentipedeTint:Text, -1, 128, TRUE, FALSE).
        IF mGame:Score > 0 AND mGame:Score >= mGame:HiScore THEN Words("NEW BEST", 1, CentipedeTint:Points, CentipedeTint:Points, -1, 142, TRUE, FALSE).
        IF mGame:PhaseFrames >= 90 AND mGame:Frames MODULO 60 < 40 THEN Words("PRESS SPACE", 1, CentipedeTint:Text, CentipedeTint:Text, -1, 176, TRUE, FALSE).
    END METHOD.

    METHOD PRIVATE VOID DrawPaused():
        Plate(120, 32, 112).
        Words("PAUSED", 2, CentipedeTint:Text, CentipedeTint:Text, -1, 121, TRUE, TRUE).
    END METHOD.

    METHOD PRIVATE VOID DrawCleared():
        Banner(90, 44).
        Words("WAVE " + STRING(mGame:Wave) + " CLEARED", 2, CentipedeTint:Text, CentipedeTint:Text, -1, 98, TRUE, TRUE).
    END METHOD.

    /* Text from a cache of stamps. plCentre puts it in the middle of the picture across, else piX is where it starts. A colour from
       poTop at the top of the letters to poBottom, with a dark edge when plEdge is set and the letters are big enough to have one. */
    METHOD PRIVATE VOID Words(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTop AS CentipedeTint, INPUT poBottom AS CentipedeTint,
                              INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plCentre AS LOGICAL, INPUT plEdge AS LOGICAL):
        VAR TextStamp stamp.
        VAR INTEGER x.
        stamp = mText:Get(pcText, piScale, CentipedeLook:Colour(poTop), CentipedeLook:Colour(poBottom),
                          (IF plEdge THEN CentipedeLook:Colour(CentipedeTint:Ink) ELSE -1)).
        x = (IF plCentre THEN INTEGER(TRUNCATE(({&WIDTH} - stamp:Width) / 2, 0)) ELSE piX).
        stamp:DrawTo(mCanvas, x, piY).
    END METHOD.

END CLASS.
