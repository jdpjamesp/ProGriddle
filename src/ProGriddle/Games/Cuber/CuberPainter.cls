/* Draws Cuber in its "Dusk Lamps" look (colours in CuberLook, sprites in CuberArt, both made from the designer's file by
   tools/gen-cuber-art.py). It reads a CuberGame, never changes it, and paints the picture on a pixel canvas of its own, 256 x 256
   pixels: the HUD in the top 32 rows, the pyramid of 28 lamps under it and the void beneath. The canvas is handed to the window's
   renderer (the inner one), so the game's own grid is left as it is.

   What is kept in the picture's background: the sky, the stars and the void, and the pyramid. The lamps are drawn into the background
   again only when one of them changes state (or the light changes with the round): a changed lamp is drawn whole and then the top
   rows of the two lamps under it, which cover its edge line, so a landing costs about three lamp pictures. Everything that moves,
   and every effect, is a function of the game's own frame counts (Frames, PhaseFrames), so the painter keeps no clock of its own and
   a test sees the same picture for the same game.

   The title screen plays an intro of its own (the letters drop in, Pip lights a path down the middle) that is a function of the
   frame count too, and the pyramid it lights is the painter's own idea of the pyramid, not the game's.

   The names of the design (Pip, the Coil, Thorns, Frosts, Snuff and Puff, lamps and halos) are used in comments here; the game's own
   names stay as they are.

   The painter owns canvases and text stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberPainter FINAL IMPLEMENTS IGridRenderer:

    &SCOPED-DEFINE SIZE 256
    /* the rows of the picture where the pyramid's sky bands begin */
    &SCOPED-DEFINE HUD-ROWS 32

    VAR PRIVATE IGridRenderer mInner.
    VAR PRIVATE CuberGame mGame.
    VAR PRIVATE Grid mGrid.
    VAR PRIVATE Grid mBaseGrid.
    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE PixelCanvas mBase.
    VAR PRIVATE TextStampCache mText.
    /* the colour of each character of a sprite string, by character code plus one */
    VAR PRIVATE INTEGER[128] mPal.
    /* the character codes (plus one) of the places a sprite has for the spill of a lit lamp and the base of the done row */
    VAR PRIVATE INTEGER mCodeSpillLight.
    VAR PRIVATE INTEGER mCodeSpillDark.
    VAR PRIVATE INTEGER mCodeDoneBase.
    /* the code of the shadow's colour, and the codes of the colours a frozen enemy draws dark */
    VAR PRIVATE INTEGER mCodeShadow.
    VAR PRIVATE LOGICAL[128] mDark.
    /* what is baked into the background: the state of each lamp (-1 for not drawn yet) and the round whose light it is drawn in */
    VAR PRIVATE INTEGER[28] mBaked.
    VAR PRIVATE INTEGER mBakedRound = -1.
    VAR PRIVATE LOGICAL mBakedUndo.
    /* the states the pyramid should show now */
    VAR PRIVATE INTEGER[28] mWant.
    /* the sky: the colours that count as sky (a bright star and a lantern are drawn only over these) */
    VAR PRIVATE INTEGER[6] mSky.
    VAR PRIVATE INTEGER mStarN.
    VAR PRIVATE INTEGER[64] mStarX.
    VAR PRIVATE INTEGER[64] mStarY.
    VAR PRIVATE INTEGER[64] mStarBright.
    VAR PRIVATE INTEGER[4] mLanternX = [26, 222, 60, 196].
    VAR PRIVATE INTEGER[4] mLanternP = [0, 45, 90, 135].
    VAR PRIVATE INTEGER[10] mMoteX = [20, 52, 88, 120, 150, 182, 214, 238, 72, 168].
    VAR PRIVATE INTEGER[10] mMoteP = [0, 11, 22, 5, 16, 27, 8, 19, 3, 24].
    VAR PRIVATE LOGICAL mDisposed.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* When false the haze of a freeze and the effects are left out, so a test that reads pixels sees plain sprites. */
    DEFINE PUBLIC PROPERTY Effects AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC CuberPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS CuberGame):
        VAR INTEGER i.
        VAR CuberTint tint.
        VAR CHARACTER stars.
        VAR CHARACTER one.
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Cuber painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Cuber painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mText = NEW TextStampCache(96).
        /* every real colour (the three places come last in the enum and have none) is put in the table by its character */
        DO i = 0 TO INTEGER(CuberTint:SpillLight) - 1:
            tint = CuberTint:GetEnum(i).
            mPal[ASC(CuberLook:CodeOf(tint)) + 1] = CuberLook:Colour(tint).
        END.
        mCodeSpillLight = ASC(CuberLook:CodeOf(CuberTint:SpillLight)) + 1.
        mCodeSpillDark = ASC(CuberLook:CodeOf(CuberTint:SpillDark)) + 1.
        mCodeDoneBase = ASC(CuberLook:CodeOf(CuberTint:DoneBase)) + 1.
        mCodeShadow = ASC(CuberLook:CodeOf(CuberTint:Fixed2C2E5A)) + 1.
        /* the dark letters of a frozen enemy: eyes, bodies and embers */
        mDark[ASC(CuberLook:CodeOf(CuberTint:Pupil)) + 1] = TRUE.
        mDark[ASC(CuberLook:CodeOf(CuberTint:MothBody)) + 1] = TRUE.
        mDark[ASC(CuberLook:CodeOf(CuberTint:EmberDeep)) + 1] = TRUE.
        mDark[ASC(CuberLook:CodeOf(CuberTint:CoilEye)) + 1] = TRUE.
        mDark[ASC(CuberLook:CodeOf(CuberTint:Ember)) + 1] = TRUE.
        mSky[1] = CuberLook:Colour(CuberTint:DuskA).
        mSky[2] = CuberLook:Colour(CuberTint:DuskB).
        mSky[3] = CuberLook:Colour(CuberTint:DuskC).
        mSky[4] = CuberLook:Colour(CuberTint:DuskD).
        mSky[5] = CuberLook:Colour(CuberTint:VoidTop).
        mSky[6] = CuberLook:Colour(CuberTint:VoidDeep).
        stars = CuberLook:Stars().
        mStarN = NUM-ENTRIES(stars, ";").
        DO i = 1 TO mStarN:
            one = ENTRY(i, stars, ";").
            mStarX[i] = INTEGER(ENTRY(1, one)).
            mStarY[i] = INTEGER(ENTRY(2, one)).
            mStarBright[i] = INTEGER(ENTRY(3, one)).
        END.
        DO i = 1 TO 28:
            mBaked[i] = -1.
        END.
        mGrid = NEW Grid(NEW ArrayStore({&SIZE}, {&SIZE}, "view,kind,back")).
        mBaseGrid = NEW Grid(NEW ArrayStore({&SIZE}, {&SIZE}, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mBase = NEW PixelCanvas(mBaseGrid).
        BuildBase().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC CuberPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not a
       Cuber game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        VAR INTEGER lightRound.
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, CuberGame) THEN UNDO, THROW NEW GridException("A Cuber painter draws a Cuber game").
        lightRound = ShownRound().
        WantPyramid().
        UpdatePyramid(lightRound).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawSky().
        IF mGame:Phase = CuberPhase:Title THEN DrawTitleScene(lightRound).
        ELSE DrawGameScene(lightRound).
        DrawHud(lightRound).
        IF mGame:Phase = CuberPhase:Title THEN DrawTitleWords().
        ELSE DrawBanners().
        mCanvas:EndBatch().
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

    /* Draws rows piFromRow to piToRow of a sprite so that its origin cell falls on piX, piY. Its tones are the row's, the places for the
       spill and the done base are the round's, a mirrored sprite is turned left to right, and a frozen one is drawn in ice. */
    METHOD PRIVATE VOID Blit(INPUT poSprite AS CuberSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                             INPUT poRow AS CuberRow, INPUT plFrozen AS LOGICAL, INPUT piRound AS INTEGER,
                             INPUT piFromRow AS INTEGER, INPUT piToRow AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER ox.
        VAR INTEGER oy.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER code.
        VAR INTEGER ice1.
        VAR INTEGER ice5.
        cells = CuberArt:Cells(poSprite).
        w = CuberArt:Width(poSprite).
        h = CuberArt:Height(poSprite).
        ox = CuberArt:OriginX(poSprite).
        oy = CuberArt:OriginY(poSprite).
        IF plFrozen THEN DO:
            ice1 = CuberLook:Tone(CuberRow:Ice, 1).
            ice5 = CuberLook:Tone(CuberRow:Ice, 5).
            DO cx = 1 TO 5:
                mPal[ASC(STRING(cx)) + 1] = CuberLook:Tone(CuberRow:Ice, cx).
            END.
        END.
        ELSE DO cx = 1 TO 5:
            mPal[ASC(STRING(cx)) + 1] = CuberLook:Tone(poRow, cx).
        END.
        IF piRound > 0 THEN DO:
            mPal[mCodeSpillLight] = CuberLook:Spill(piRound, 1).
            mPal[mCodeSpillDark] = CuberLook:Spill(piRound, 2).
            mPal[mCodeDoneBase] = CuberLook:Tone(CuberLook:DoneRow(piRound), 3).
        END.
        DO cy = MAXIMUM(0, piFromRow) TO MINIMUM(h - 1, piToRow):
            DO cx = 0 TO w - 1:
                code = ASC(SUBSTRING(cells, cy * w + cx + 1, 1)).
                IF code = 46 THEN NEXT.
                mCanvas:Plot((IF plMirror THEN piX + ox - cx ELSE piX + cx - ox), piY + cy - oy, 0,
                             (IF plFrozen AND code > 53 THEN (IF mDark[code + 1] THEN ice5 ELSE ice1) ELSE mPal[code + 1])).
            END.
        END.
    END METHOD.

    /* A whole sprite. */
    METHOD PRIVATE VOID Pose(INPUT poSprite AS CuberSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                             INPUT poRow AS CuberRow, INPUT plFrozen AS LOGICAL):
        Blit(poSprite, piX, piY, plMirror, poRow, plFrozen, 0, 0, 999).
    END METHOD.

    /* A sprite whose only tones are in a row and whose letters are fixed, drawn plainly. */
    METHOD PRIVATE VOID Stamp(INPUT poSprite AS CuberSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poRow AS CuberRow):
        Blit(poSprite, piX, piY, FALSE, poRow, FALSE, 0, 0, 999).
    END METHOD.

    /* ================================ the background ================================ */

    /* The plain background, made once on the base canvas: the HUD, the six bands of the dusk and the void, the stars. */
    METHOD PRIVATE VOID BuildBase():
        VAR INTEGER[] rows.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER i.
        VAR INTEGER upper.
        VAR INTEGER lower.
        EXTENT(rows) = {&SIZE}.
        DO y = 0 TO {&SIZE} - 1:
            rows[y + 1] = BandColour(y).
        END.
        mBase:SetBackRows(rows).
        /* the two rows above each band boundary are a checkerboard of the two bands */
        DO i = 1 TO 5:
            y = INTEGER(ENTRY(i, "80,128,176,216,240")).
            upper = BandColour(y - 1).
            lower = BandColour(y).
            DO x = 0 TO {&SIZE} - 1:
                mBase:SetBack(x, y - 2, (IF (x + y - 2) MODULO 2 = 0 THEN lower ELSE upper)).
                mBase:SetBack(x, y - 1, (IF (x + y - 1) MODULO 2 = 0 THEN lower ELSE upper)).
            END.
        END.
        DO i = 1 TO mStarN:
            mBase:SetBack(mStarX[i], mStarY[i], (IF mStarBright[i] = 1 THEN CuberLook:Colour(CuberTint:Star) ELSE CuberLook:Colour(CuberTint:StarDim))).
        END.
    END METHOD.

    /* The colour of the background in a row, before the checkerboards and the stars. */
    METHOD PRIVATE INTEGER BandColour(INPUT piY AS INTEGER):
        IF piY < {&HUD-ROWS} - 1 THEN RETURN CuberLook:Colour(CuberTint:Hud).
        IF piY = {&HUD-ROWS} - 1 THEN RETURN CuberLook:Colour(CuberTint:HudRule).
        IF piY < 80 THEN RETURN CuberLook:Colour(CuberTint:DuskA).
        IF piY < 128 THEN RETURN CuberLook:Colour(CuberTint:DuskB).
        IF piY < 176 THEN RETURN CuberLook:Colour(CuberTint:DuskC).
        IF piY < 216 THEN RETURN CuberLook:Colour(CuberTint:DuskD).
        IF piY < 240 THEN RETURN CuberLook:Colour(CuberTint:VoidTop).
        RETURN CuberLook:Colour(CuberTint:VoidDeep).
    END METHOD.

    /* The round whose light the picture is drawn in: the title is always the first light. */
    METHOD PRIVATE INTEGER ShownRound():
        RETURN (IF mGame:Phase = CuberPhase:Title THEN 1 ELSE mGame:RoundNo).
    END METHOD.

    /* The states the pyramid should show: the game's, or on the title screen the ones of the intro. */
    METHOD PRIVATE VOID WantPyramid():
        VAR INTEGER r.
        VAR INTEGER c.
        VAR INTEGER i.
        IF mGame:Phase = CuberPhase:Title THEN DO:
            DO i = 1 TO 28:
                mWant[i] = 0.
            END.
            DO i = 1 TO 7:
                IF IntroLit(i) THEN mWant[LampNumber(i, INTEGER(TRUNCATE(i / 2, 0)))] = 2.
            END.
            RETURN.
        END.
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mWant[LampNumber(r, c)] = mGame:LampAt(r, c).
            END.
        END.
    END METHOD.

    /* The number of a lamp, 1 to 28. */
    METHOD PRIVATE INTEGER LampNumber(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN INTEGER((piRow * (piRow - 1)) / 2) + piCol + 1.
    END METHOD.

    /* Brings what is baked into the background up to what should show: the whole pyramid when the light or the rule of the level
       changed, else only the lamps that changed. */
    METHOD PRIVATE VOID UpdatePyramid(INPUT piRound AS INTEGER):
        VAR LOGICAL undoOn.
        VAR LOGICAL redoAll.
        VAR LOGICAL changed.
        VAR INTEGER r.
        VAR INTEGER c.
        VAR INTEGER n.
        undoOn = (mGame:Phase <> CuberPhase:Title AND CuberRules:UndoOnLand(mGame:LevelNo)).
        redoAll = (mBakedRound <> piRound OR mBakedUndo <> undoOn).
        DO n = 1 TO 28:
            IF mWant[n] <> mBaked[n] THEN changed = TRUE.
        END.
        IF NOT redoAll AND NOT changed THEN RETURN.
        IF redoAll THEN mCanvas:LoadBack(mBase).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                n = LampNumber(r, c).
                IF redoAll THEN DrawLamp(r, c, mWant[n], piRound, undoOn, 0, 999).
                ELSE IF mWant[n] <> mBaked[n] THEN DO:
                    /* the lamp whole, then the top rows of the two lamps under it, which cover its edge line */
                    DrawLamp(r, c, mWant[n], piRound, undoOn, 0, 999).
                    IF r < 7 THEN DO:
                        DrawLamp(r + 1, c, mWant[LampNumber(r + 1, c)], piRound, undoOn, 0, 7).
                        DrawLamp(r + 1, c + 1, mWant[LampNumber(r + 1, c + 1)], piRound, undoOn, 0, 7).
                    END.
                END.
            END.
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
        DO n = 1 TO 28:
            mBaked[n] = mWant[n].
        END.
        mBakedRound = piRound.
        mBakedUndo = undoOn.
    END METHOD.

    /* Rows piFromRow to piToRow of the picture of the lamp at a row and column in a state (0 dark, 1 ring, 2 lit). */
    METHOD PRIVATE VOID DrawLamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER, INPUT piState AS INTEGER, INPUT piRound AS INTEGER,
                                 INPUT plUndo AS LOGICAL, INPUT piFromRow AS INTEGER, INPUT piToRow AS INTEGER):
        CASE piState:
            WHEN 0 THEN Blit((IF plUndo THEN CuberSprite:LampUndo ELSE CuberSprite:LampUnlit), CuberRules:LampX(piRow, piCol), CuberRules:LampY(piRow), FALSE,
                             CuberRow:Unlit, FALSE, piRound, piFromRow, piToRow).
            WHEN 1 THEN Blit(CuberSprite:LampHalf, CuberRules:LampX(piRow, piCol), CuberRules:LampY(piRow), FALSE,
                             CuberLook:HalfRow(piRound), FALSE, piRound, piFromRow, piToRow).
            OTHERWISE Blit((IF plUndo THEN CuberSprite:LampUndoDone ELSE CuberSprite:LampDone), CuberRules:LampX(piRow, piCol), CuberRules:LampY(piRow), FALSE,
                           CuberLook:DoneRow(piRound), FALSE, piRound, piFromRow, piToRow).
        END CASE.
    END METHOD.

    /* ================================ the sky ================================ */

    /* True when a colour is one the sky or the void is made of. */
    METHOD PRIVATE LOGICAL IsSky(INPUT piColour AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO 6:
            IF mSky[i] = piColour THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* A pixel only over the sky, so the lanterns and the motes pass behind the pyramid. */
    METHOD PRIVATE VOID SkyPlot(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        IF piX < 0 OR piX >= {&SIZE} OR piY < {&HUD-ROWS} OR piY >= {&SIZE} THEN RETURN.
        IF IsSky(mCanvas:ColourAt(piX, piY)) THEN mCanvas:Plot(piX, piY, 0, piColour).
    END METHOD.

    /* Far lanterns rising (one pixel every 12 frames), motes falling into the void (one pixel every 5), and a bright star twinkling. */
    METHOD PRIVATE VOID DrawSky():
        VAR INTEGER i.
        VAR INTEGER y.
        VAR INTEGER n.
        VAR INTEGER seen.
        IF NOT Effects THEN RETURN.
        DO i = 1 TO 4:
            y = 216 - ((INTEGER(TRUNCATE(mGame:Frames / 12, 0)) + mLanternP[i]) MODULO 180).
            SkyPlot(mLanternX[i], y, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i] + 1, y, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i], y + 1, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i] + 1, y + 1, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i], y + 2, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i] + 1, y + 2, CuberLook:Colour(CuberTint:Lantern)).
            SkyPlot(mLanternX[i] - 1, y + 1, CuberLook:Colour(CuberTint:LanternDim)).
            SkyPlot(mLanternX[i] + 2, y + 1, CuberLook:Colour(CuberTint:LanternDim)).
            SkyPlot(mLanternX[i], y + 3, CuberLook:Colour(CuberTint:LanternDim)).
            SkyPlot(mLanternX[i] + 1, y + 4, CuberLook:Colour(CuberTint:LanternDim)).
        END.
        DO i = 1 TO 10:
            y = 226 + ((INTEGER(TRUNCATE(mGame:Frames / 5, 0)) + mMoteP[i]) MODULO 30).
            SkyPlot(mMoteX[i], y, CuberLook:Colour(CuberTint:Mote)).
            SkyPlot(mMoteX[i], y + 1, CuberLook:Colour(CuberTint:Mote)).
        END.
        /* one of the four bright stars that twinkle goes dim for 9 frames in every 42, in turn */
        IF mGame:Frames MODULO 42 < 9 THEN DO:
            DO i = 1 TO mStarN:
                IF mStarBright[i] = 1 THEN DO:
                    IF seen = INTEGER(TRUNCATE(mGame:Frames / 42, 0)) MODULO 4 THEN DO:
                        SkyPlot(mStarX[i], mStarY[i], CuberLook:Colour(CuberTint:StarDim)).
                        LEAVE.
                    END.
                    seen = seen + 1.
                END.
            END.
        END.
    END METHOD.

    /* ================================ the scene in play ================================ */

    METHOD PRIVATE VOID DrawGameScene(INPUT piRound AS INTEGER):
        VAR INTEGER i.
        DrawHalos().
        DrawShadow().
        DrawGlints(piRound).
        DrawFreezeRing().
        DrawEnemies().
        IF mGame:Phase <> CuberPhase:GameOver THEN DrawPip().
        DrawPops().
        IF mGame:Phase = CuberPhase:Cleared THEN DrawRipple(piRound).
    END METHOD.

    /* The halos: waiting (a band of white running round, 120 ms a frame), or a ghost for two seconds after one is used. */
    METHOD PRIVATE VOID DrawHalos():
        VAR INTEGER s.
        VAR INTEGER x.
        VAR INTEGER y.
        DO s = 1 TO CuberRules:HaloSpots():
            x = CuberRules:FootX(CuberRules:HaloRow(s), CuberRules:HaloCol(s)).
            y = CuberRules:FootY(CuberRules:HaloRow(s)).
            CASE mGame:HaloState(s):
                WHEN 1 THEN Stamp(HaloSprite(INTEGER(TRUNCATE(mGame:Frames / 7, 0)) MODULO 4), x, y, CuberRow:Halo).
                WHEN 2 THEN IF mGame:Frames - mGame:HaloUsedFrame(s) < 120 THEN Stamp(CuberSprite:HaloGone, x, y, CuberRow:Halo).
            END CASE.
        END.
    END METHOD.

    METHOD PRIVATE CuberSprite HaloSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 0 THEN RETURN CuberSprite:Halo1.
            WHEN 1 THEN RETURN CuberSprite:Halo2.
            WHEN 2 THEN RETURN CuberSprite:Halo3.
            OTHERWISE RETURN CuberSprite:Halo4.
        END CASE.
    END METHOD.

    /* A soft shadow under Pip on the lamp that is under it, in the lamp's own dark tone. */
    METHOD PRIVATE VOID DrawShadow():
        VAR INTEGER r.
        VAR INTEGER c.
        VAR INTEGER state.
        VAR CuberRow lampRow.
        IF mGame:PipMode <> CuberPipMode:Standing AND mGame:PipMode <> CuberPipMode:Hopping THEN RETURN.
        /* in the air the shadow is on the lamp it left for two frames and on the lamp it will land on after */
        IF mGame:PipMode = CuberPipMode:Hopping AND mGame:PipHopFrame >= 3 THEN ASSIGN r = mGame:PipDestRow c = mGame:PipDestCol.
        ELSE ASSIGN r = mGame:PipRow c = mGame:PipCol.
        IF NOT CuberRules:IsLamp(r, c) THEN RETURN.
        state = mGame:LampAt(r, c).
        lampRow = (IF state = 0 THEN CuberRow:Unlit ELSE IF state = 1 THEN CuberLook:HalfRow(ShownRound()) ELSE CuberLook:DoneRow(ShownRound())).
        mPal[mCodeShadow] = CuberLook:Tone(lampRow, 4).
        Blit(CuberSprite:Shadow, CuberRules:FootX(r, c), CuberRules:FootY(r) + 1, FALSE, CuberRow:Unlit, FALSE, 0, 0, 999).
        /* the sprite was drawn with the shadow colour of the table, which Blit leaves as it is */
    END METHOD.

    /* The glint of the lamp last lit: three frames of a rim, a long star, a small star. */
    METHOD PRIVATE VOID DrawGlints(INPUT piRound AS INTEGER):
        VAR INTEGER age.
        IF mGame:LastLitFrame < 0 THEN RETURN.
        age = mGame:Frames - mGame:LastLitFrame.
        IF age < 0 OR age >= 15 THEN RETURN.
        DrawGlint(mGame:LastLitRow, mGame:LastLitCol, age, CuberLook:DoneRow(piRound)).
    END METHOD.

    /* A glint over a lamp: the age in frames picks the picture (3, then 6, then 6). */
    METHOD PRIVATE VOID DrawGlint(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER, INPUT piAge AS INTEGER, INPUT poRow AS CuberRow):
        VAR CuberSprite glint.
        glint = (IF piAge < 3 THEN CuberSprite:Glint1 ELSE IF piAge < 9 THEN CuberSprite:Glint2 ELSE CuberSprite:Glint3).
        Stamp(glint, CuberRules:LampX(piRow, piCol), CuberRules:LampY(piRow), poRow).
    END METHOD.

    /* The level clear: the white of the glint runs over the lamps in reading order, 40 ms a step, twice, the second pass starting
       at step 15. */
    METHOD PRIVATE VOID DrawRipple(INPUT piRound AS INTEGER):
        VAR INTEGER stepNo.
        VAR INTEGER r.
        VAR INTEGER c.
        VAR INTEGER n.
        VAR INTEGER ago.
        stepNo = INTEGER(TRUNCATE(mGame:PhaseFrames * 5 / 12, 0)).
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                n = LampNumber(r, c) - 1.
                ago = stepNo - n.
                IF ago >= 0 AND ago < 2 THEN DrawGlint(r, c, 0, CuberLook:DoneRow(piRound)).
                ago = stepNo - 15 - n.
                IF ago >= 0 AND ago < 2 THEN DrawGlint(r, c, 0, CuberLook:DoneRow(piRound)).
            END.
        END.
    END METHOD.

    /* The ring that spreads from a Frost when it goes off: six pictures, 50 ms each. */
    METHOD PRIVATE VOID DrawFreezeRing():
        VAR INTEGER age.
        VAR CuberSprite ring.
        IF mGame:FreezeFrame < 0 THEN RETURN.
        age = mGame:Frames - mGame:FreezeFrame.
        IF age < 0 OR age >= 18 THEN RETURN.
        CASE INTEGER(TRUNCATE(age / 3, 0)):
            WHEN 0 THEN ring = CuberSprite:FreezeRing1.
            WHEN 1 THEN ring = CuberSprite:FreezeRing2.
            WHEN 2 THEN ring = CuberSprite:FreezeRing3.
            WHEN 3 THEN ring = CuberSprite:FreezeRing4.
            WHEN 4 THEN ring = CuberSprite:FreezeRing5.
            OTHERWISE ring = CuberSprite:FreezeRing6.
        END CASE.
        Stamp(ring, mGame:FreezeX, mGame:FreezeY, CuberRow:Frost).
    END METHOD.

    /* The enemies, the ones whose feet are higher up the picture first, so the nearer ones cover the further. */
    METHOD PRIVATE VOID DrawEnemies():
        VAR INTEGER[8] order.
        VAR INTEGER n.
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER t.
        DO i = 0 TO mGame:EnemySlots - 1:
            IF mGame:EnemyOn(i) THEN ASSIGN
                n = n + 1
                order[n] = i.
        END.
        /* an insertion sort on the feet (y, then x) */
        DO i = 2 TO n:
            t = order[i].
            j = i - 1.
            DO WHILE j >= 1 AND (mGame:EnemyY(order[j]) > mGame:EnemyY(t) OR (mGame:EnemyY(order[j]) = mGame:EnemyY(t) AND mGame:EnemyX(order[j]) > mGame:EnemyX(t))):
                order[j + 1] = order[j].
                j = j - 1.
            END.
            order[j + 1] = t.
        END.
        DO i = 1 TO n:
            DrawEnemy(order[i]).
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawEnemy(INPUT piSlot AS INTEGER):
        VAR CuberKind kind.
        VAR CuberDir dir.
        VAR LOGICAL faceUp.
        VAR LOGICAL faceLeft.
        VAR LOGICAL frozen.
        VAR INTEGER stepNo.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR CuberEnemyMode enemyMode.
        kind = mGame:EnemyKind(piSlot).
        dir = mGame:EnemyDirection(piSlot).
        enemyMode = mGame:EnemyMode(piSlot).
        x = mGame:EnemyX(piSlot).
        y = mGame:EnemyY(piSlot).
        faceUp = (dir = CuberDir:UpLeft OR dir = CuberDir:UpRight).
        faceLeft = (dir = CuberDir:UpLeft OR dir = CuberDir:DownLeft).
        /* frozen: ice, and in the last second the ice blinks on and off every 250 ms (15 frames) */
        frozen = (mGame:EnemyFrozen(piSlot) AND kind <> CuberKind:Frost
                  AND (mGame:FreezeFrames > 60 OR INTEGER(TRUNCATE(mGame:FreezeFrames / 15, 0)) MODULO 2 = 0)).
        stepNo = BounceStep(piSlot).
        CASE kind:
            WHEN CuberKind:Seed THEN DO:
                IF enemyMode = CuberEnemyMode:Hatching THEN Pose((IF mGame:EnemyModeFrames(piSlot) < 18 THEN CuberSprite:SeedHatch1 ELSE CuberSprite:SeedHatch2), x, y, FALSE, CuberRow:Coil, frozen).
                ELSE Pose(SeedSprite(stepNo), x, y, FALSE, CuberRow:Coil, frozen).
            END.
            WHEN CuberKind:Thorn THEN Pose(ThornSprite(stepNo), x, y, FALSE, CuberRow:Thorn, frozen).
            WHEN CuberKind:Frost THEN Pose(FrostSprite(stepNo), x, y, FALSE, CuberRow:Frost, FALSE).
            WHEN CuberKind:Coil THEN DrawCoil(piSlot, x, y, faceUp, faceLeft, frozen).
            OTHERWISE Pose(MothSprite(faceUp, stepNo), x, y, faceLeft, (IF kind = CuberKind:Snuff THEN CuberRow:Snuff ELSE CuberRow:Puff), frozen).
        END CASE.
    END METHOD.

    /* The picture of a bouncing thing: 1 squashed, 2 round, 3 stretched (as the animation recipe has it). */
    METHOD PRIVATE INTEGER BounceStep(INPUT piSlot AS INTEGER):
        VAR INTEGER f.
        IF mGame:EnemyMode(piSlot) = CuberEnemyMode:Hopping THEN DO:
            f = mGame:EnemyHopFrame(piSlot).
            IF f <= 2 THEN RETURN 3.
            IF f <= 10 THEN RETURN 2.
            IF f = 11 THEN RETURN 3.
            RETURN 1.
        END.
        IF mGame:EnemyMode(piSlot) = CuberEnemyMode:Resting AND mGame:EnemyModeFrames(piSlot) < 5 THEN RETURN 1.
        RETURN 2.
    END METHOD.

    METHOD PRIVATE CuberSprite SeedSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 1 THEN RETURN CuberSprite:Seed1.
            WHEN 3 THEN RETURN CuberSprite:Seed3.
            OTHERWISE RETURN CuberSprite:Seed2.
        END CASE.
    END METHOD.

    METHOD PRIVATE CuberSprite ThornSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 1 THEN RETURN CuberSprite:Thorn1.
            WHEN 3 THEN RETURN CuberSprite:Thorn3.
            OTHERWISE RETURN CuberSprite:Thorn2.
        END CASE.
    END METHOD.

    METHOD PRIVATE CuberSprite FrostSprite(INPUT piStep AS INTEGER):
        CASE piStep:
            WHEN 1 THEN RETURN CuberSprite:Frost1.
            WHEN 3 THEN RETURN CuberSprite:Frost3.
            OTHERWISE RETURN CuberSprite:Frost2.
        END CASE.
    END METHOD.

    /* A moth: frame 1 for the first two frames of a hop, 2 until frame 10, then 3 (which it stands in too). */
    METHOD PRIVATE CuberSprite MothSprite(INPUT plUp AS LOGICAL, INPUT piStep AS INTEGER):
        /* piStep is the bounce step: 3 stretched is the take off, 2 round is the air, 1 and the rest are the landing */
        IF plUp THEN DO:
            IF piStep = 3 THEN RETURN CuberSprite:MothUr1.
            IF piStep = 2 THEN RETURN CuberSprite:MothUr2.
            RETURN CuberSprite:MothUr3.
        END.
        IF piStep = 3 THEN RETURN CuberSprite:MothDr1.
        IF piStep = 2 THEN RETURN CuberSprite:MothDr2.
        RETURN CuberSprite:MothDr3.
    END METHOD.

    /* The Coil: standing, hopping (frames 1 and 2 crouch, 3 to 10 in the air, 11 and 12 landing) or falling off the edge. */
    METHOD PRIVATE VOID DrawCoil(INPUT piSlot AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plUp AS LOGICAL, INPUT plLeft AS LOGICAL,
                                 INPUT plFrozen AS LOGICAL):
        VAR INTEGER f.
        VAR CuberSprite sprite.
        IF mGame:EnemyMode(piSlot) = CuberEnemyMode:Falling THEN DO:
            f = mGame:EnemyModeFrames(piSlot).
            sprite = (IF f < 6 THEN CuberSprite:CoilFall1 ELSE IF f < 12 THEN CuberSprite:CoilFall2 ELSE CuberSprite:CoilFall3).
        END.
        ELSE IF mGame:EnemyMode(piSlot) = CuberEnemyMode:Hopping THEN DO:
            f = mGame:EnemyHopFrame(piSlot).
            IF plUp THEN sprite = (IF f <= 2 THEN CuberSprite:CoilHopUr1 ELSE IF f <= 10 THEN CuberSprite:CoilHopUr2 ELSE CuberSprite:CoilHopUr3).
            ELSE sprite = (IF f <= 2 THEN CuberSprite:CoilHopDr1 ELSE IF f <= 10 THEN CuberSprite:CoilHopDr2 ELSE CuberSprite:CoilHopDr3).
        END.
        ELSE sprite = (IF plUp THEN CuberSprite:CoilStandUr ELSE CuberSprite:CoilStandDr).
        Pose(sprite, piX, piY, plLeft, CuberRow:Coil, plFrozen).
    END METHOD.

    /* ================================ Pip ================================ */

    /* Pip in whatever it is doing. The pictures face down and to the right or up and to the right, and a hop to the left turns them. */
    METHOD PRIVATE VOID DrawPip():
        DrawPipAt(mGame:PipX, mGame:PipY, mGame:PipMode, mGame:PipDirection, mGame:PipHopFrame, mGame:PipModeFrames, mGame:PipFellInFront).
    END METHOD.

    METHOD PRIVATE VOID DrawPipAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poMode AS CuberPipMode, INPUT poDir AS CuberDir,
                                  INPUT piHop AS INTEGER, INPUT piModeFrames AS INTEGER, INPUT plFront AS LOGICAL):
        VAR LOGICAL faceUp.
        VAR LOGICAL faceLeft.
        VAR INTEGER f.
        VAR INTEGER b.
        VAR CuberSprite sprite.
        VAR CuberRow toneRow = CuberRow:Pip.
        faceUp = (poDir = CuberDir:UpLeft OR poDir = CuberDir:UpRight).
        faceLeft = (poDir = CuberDir:UpLeft OR poDir = CuberDir:DownLeft).
        CASE poMode:
            WHEN CuberPipMode:Hopping THEN DO:
                sprite = (IF faceUp THEN (IF piHop <= 2 THEN CuberSprite:PipHopUr1 ELSE IF piHop <= 10 THEN CuberSprite:PipHopUr2 ELSE CuberSprite:PipHopUr3)
                                ELSE (IF piHop <= 2 THEN CuberSprite:PipHopDr1 ELSE IF piHop <= 10 THEN CuberSprite:PipHopDr2 ELSE CuberSprite:PipHopDr3)).
            END.
            WHEN CuberPipMode:Falling THEN DO:
                IF NOT plFront THEN sprite = CuberSprite:PipFall4.
                ELSE sprite = (IF piModeFrames < 6 THEN CuberSprite:PipFall1 ELSE IF piModeFrames < 12 THEN CuberSprite:PipFall2
                               ELSE IF piModeFrames < 18 THEN CuberSprite:PipFall3 ELSE CuberSprite:PipFall4).
            END.
            WHEN CuberPipMode:Hit THEN DO:
                /* eight pictures of 80 ms (5 frames), then the flash: white hot, then inverted, 9 frames each */
                f = INTEGER(TRUNCATE(piModeFrames / 5, 0)).
                IF f < 8 THEN DO:
                    b = f MODULO 4.
                    sprite = (IF b = 0 THEN CuberSprite:PipHit1 ELSE IF b = 1 THEN CuberSprite:PipHit2 ELSE IF b = 2 THEN CuberSprite:PipHit3 ELSE CuberSprite:PipHit4).
                END.
                ELSE DO:
                    sprite = CuberSprite:PipStandDr.
                    toneRow = (IF piModeFrames < 49 THEN CuberRow:Flash ELSE CuberRow:Negative).
                END.
            END.
            WHEN CuberPipMode:Riding THEN DO:
                Stamp((IF INTEGER(TRUNCATE(piModeFrames / 6, 0)) MODULO 2 = 0 THEN CuberSprite:HaloLift1 ELSE CuberSprite:HaloLift2), piX, piY, CuberRow:Halo).
                sprite = (IF INTEGER(TRUNCATE(piModeFrames / 9, 0)) MODULO 2 = 0 THEN CuberSprite:PipRide1 ELSE CuberSprite:PipRide2).
            END.
            WHEN CuberPipMode:Winning THEN DO:
                IF INTEGER(TRUNCATE(piModeFrames / 9, 0)) MODULO 2 = 0 THEN sprite = CuberSprite:PipWin1.
                ELSE ASSIGN sprite = CuberSprite:PipWin2
                            piY = piY - 4.
            END.
            OTHERWISE DO:
                /* standing: a blink every 270 frames when facing down */
                f = mGame:Frames MODULO 270.
                IF faceUp THEN sprite = CuberSprite:PipStandUr.
                ELSE sprite = (IF f < 3 THEN CuberSprite:PipBlink1 ELSE IF f < 9 THEN CuberSprite:PipBlink2 ELSE IF f < 12 THEN CuberSprite:PipBlink1 ELSE CuberSprite:PipStandDr).
            END.
        END CASE.
        Pose(sprite, piX, piY, faceLeft AND poMode <> CuberPipMode:Falling AND poMode <> CuberPipMode:Riding AND poMode <> CuberPipMode:Winning
                               AND poMode <> CuberPipMode:Hit, toneRow, FALSE).
    END METHOD.

    /* ================================ points ================================ */

    /* The points shown over whatever scored: they rise a pixel every 3 frames for 8 pixels, hold, turn to the label colour for the last
       9 frames and go. A big one (500) is drawn at twice the size. */
    METHOD PRIVATE VOID DrawPops():
        VAR INTEGER i.
        VAR INTEGER age.
        VAR INTEGER rise.
        VAR INTEGER scale.
        VAR CuberTint tint.
        VAR TextStamp stamp.
        DO i = 0 TO mGame:PopSlots - 1:
            age = mGame:PopAge(i).
            IF age < 0 OR age >= 51 THEN NEXT.
            rise = MINIMUM(8, INTEGER(TRUNCATE(age / 3, 0))).
            scale = (IF mGame:PopValue(i) >= 500 THEN 2 ELSE 1).
            tint = (IF age >= 42 THEN CuberTint:Label ELSE CuberTint:Gold).
            stamp = mText:Get(STRING(mGame:PopValue(i)), scale, CuberLook:Colour(tint), CuberLook:Colour(tint), CuberLook:Colour(CuberTint:Outline)).
            stamp:DrawTo(mCanvas, mGame:PopX(i) - INTEGER(TRUNCATE(stamp:Width / 2, 0)), mGame:PopY(i) - 26 - rise).
        END.
    END METHOD.

    /* ================================ the HUD ================================ */

    /* The top 32 rows: the score, the best score, the spare Pips, the level and round, and the target lamp in the round's light. */
    METHOD PRIVATE VOID DrawHud(INPUT piRound AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER n.
        VAR INTEGER x.
        Words("HI", 1, CuberTint:Label, CuberTint:Label, 101, 4, FALSE, FALSE, FALSE).
        Words(SixDigits(mGame:HiScore), 1, CuberTint:Text, CuberTint:Text, 119, 4, FALSE, FALSE, FALSE).
        /* the title screen has the best score only, the name goes where the score would be */
        IF mGame:Phase = CuberPhase:Title THEN RETURN.
        Words("SCORE", 1, CuberTint:Label, CuberTint:Label, 8, 4, FALSE, FALSE, FALSE).
        Words(SixDigits(mGame:Score), 2, CuberTint:Text, CuberTint:Text, 8, 13, FALSE, FALSE, FALSE).
        n = MINIMUM(5, mGame:Lives).
        x = 128 - INTEGER(TRUNCATE((10 * n - 2) / 2, 0)).
        DO i = 0 TO n - 1:
            Pose(CuberSprite:PipIcon, x + 10 * i + 4, 23, FALSE, CuberRow:Pip, FALSE).
        END.
        Words("LEVEL", 1, CuberTint:Label, CuberTint:Label, 182, 4, FALSE, FALSE, FALSE).
        Words(STRING(mGame:LevelNo), 1, CuberTint:Text, CuberTint:Text, 218, 4, FALSE, FALSE, FALSE).
        Words("ROUND", 1, CuberTint:Label, CuberTint:Label, 182, 16, FALSE, FALSE, FALSE).
        Words(STRING(mGame:RoundNo), 1, CuberTint:Text, CuberTint:Text, 218, 16, FALSE, FALSE, FALSE).
        Stamp(CuberSprite:LampMini, 232, 8, CuberLook:DoneRow(piRound)).
    END METHOD.

    /* A score or a best score in six digits. */
    METHOD PRIVATE CHARACTER SixDigits(INPUT piValue AS INTEGER):
        RETURN STRING(MINIMUM(999999, MAXIMUM(0, piValue)), "999999").
    END METHOD.

    /* ================================ the screens ================================ */

    /* A plate across the picture: Plate fill with a one pixel rule at the top and the bottom. */
    METHOD PRIVATE VOID Plate(INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER):
        mCanvas:FillRect(0, piTop, {&SIZE}, piBottom - piTop + 1, 0, CuberLook:Colour(CuberTint:Plate)).
        mCanvas:FillRect(0, piTop, {&SIZE}, 1, 0, CuberLook:Colour(CuberTint:PlateRule)).
        mCanvas:FillRect(0, piBottom, {&SIZE}, 1, 0, CuberLook:Colour(CuberTint:PlateRule)).
    END METHOD.

    /* READY, PAUSED, the end of a round, GAME OVER. */
    METHOD PRIVATE VOID DrawBanners():
        CASE mGame:Phase:
            WHEN CuberPhase:Ready THEN DO:
                Plate(112, 135).
                Words("READY", 2, CuberTint:Text, CuberTint:Text, -1, 117, TRUE, FALSE, FALSE).
            END.
            WHEN CuberPhase:Cleared THEN IF mGame:PhaseFrames >= CuberRules:ClearFrames() - 60 THEN DO:
                Plate(112, 135).
                Words((IF mGame:RoundNo = 4 THEN "LEVEL " + STRING(mGame:LevelNo + 1) ELSE "ROUND " + STRING(mGame:RoundNo + 1)), 2,
                      CuberTint:Gold, CuberTint:Gold, -1, 117, TRUE, FALSE, FALSE).
            END.
            WHEN CuberPhase:GameOver THEN DO:
                Plate(100, 155).
                Words("GAME OVER", 3, CuberTint:OverTop, CuberTint:OverBottom, -1, 108, TRUE, TRUE, FALSE).
                IF mGame:Score > 0 AND mGame:Score >= mGame:HiScore THEN DO:
                    IF mGame:Frames MODULO 45 < 30 THEN Words("NEW HIGH SCORE", 1, CuberTint:Gold, CuberTint:Gold, -1, 136, TRUE, FALSE, FALSE).
                    Words(SixDigits(mGame:Score), 1, CuberTint:Text, CuberTint:Text, -1, 146, TRUE, FALSE, FALSE).
                END.
                ELSE Words("SCORE " + SixDigits(mGame:Score), 1, CuberTint:Text, CuberTint:Text, -1, 140, TRUE, FALSE, FALSE).
            END.
        END CASE.
        IF mGame:Paused AND mGame:Phase <> CuberPhase:GameOver THEN DO:
            Plate(112, 143).
            Words("PAUSED", 2, CuberTint:Text, CuberTint:Text, -1, 116, TRUE, FALSE, FALSE).
            Words("P TO PLAY", 1, CuberTint:Label, CuberTint:Label, -1, 134, TRUE, FALSE, FALSE).
        END.
    END METHOD.

    /* ================================ the title ================================ */

    /* The intro as a function of the frames: one cycle of the title screen. Pip lands on the apex at frame 50 and hops down the
       middle, a hop every 30 frames, and the path goes dark again after the ripple. */
    METHOD PRIVATE INTEGER IntroFrame():
        RETURN mGame:PhaseFrames MODULO 760.
    END METHOD.

    /* True when the lamp of the intro's path in row piRow is lit now. The path is row r column r / 2 (0, 1, 1, 2, 2, 3, 3). */
    METHOD PRIVATE LOGICAL IntroLit(INPUT piRow AS INTEGER):
        VAR INTEGER t.
        t = IntroFrame().
        /* the lamp of row r is lit when Pip lands on it, at frame 62 + 30 (r - 1), and goes dark from frame 600 one lamp per 4 frames from the bottom */
        IF t < 62 + 30 * (piRow - 1) THEN RETURN FALSE.
        IF t >= 600 + 4 * (7 - piRow) THEN RETURN FALSE.
        RETURN TRUE.
    END METHOD.

    /* The scene on the title screen: two halos, Pip on its path. */
    METHOD PRIVATE VOID DrawTitleScene(INPUT piRound AS INTEGER):
        VAR INTEGER t.
        VAR INTEGER hop.
        VAR INTEGER rowNow.
        VAR INTEGER i.
        VAR INTEGER x0.
        VAR INTEGER y0.
        VAR INTEGER x1.
        VAR INTEGER y1.
        VAR INTEGER f.
        Stamp(HaloSprite(INTEGER(TRUNCATE(mGame:Frames / 7, 0)) MODULO 4), CuberRules:FootX(4, -1), CuberRules:FootY(4), CuberRow:Halo).
        Stamp(HaloSprite(INTEGER(TRUNCATE(mGame:Frames / 7, 0)) MODULO 4), CuberRules:FootX(4, 4), CuberRules:FootY(4), CuberRow:Halo).
        t = IntroFrame().
        IF t < 38 THEN RETURN.
        IF t < 50 THEN DO:
            /* Pip drops in from above onto the apex: a hop of 12 frames that ends on the apex */
            f = t - 38.
            DrawPipAt(CuberRules:FootX(1, 0), CuberRules:FootY(1) - 40 + INTEGER(TRUNCATE(40 * (f + 1) / 12, 0)), CuberPipMode:Hopping,
                      CuberDir:DownRight, 3, 0, FALSE).
            RETURN.
        END.
        IF t < 62 THEN DO:
            DrawPipAt(CuberRules:FootX(1, 0), CuberRules:FootY(1), CuberPipMode:Standing, CuberDir:DownRight, 0, 0, FALSE).
            RETURN.
        END.
        /* hop number hop (0 to 5) goes from row hop + 1 to hop + 2 and takes 12 frames at the end of each 30 */
        hop = INTEGER(TRUNCATE((t - 62) / 30, 0)).
        IF hop >= 6 THEN DO:
            DrawPipAt(CuberRules:FootX(7, 3), CuberRules:FootY(7), CuberPipMode:Standing, CuberDir:DownRight, 0, 0, FALSE).
            RETURN.
        END.
        rowNow = hop + 1.
        f = (t - 62) MODULO 30 - 18.
        x0 = CuberRules:FootX(rowNow, INTEGER(TRUNCATE(rowNow / 2, 0))).
        y0 = CuberRules:FootY(rowNow).
        x1 = CuberRules:FootX(rowNow + 1, INTEGER(TRUNCATE((rowNow + 1) / 2, 0))).
        y1 = CuberRules:FootY(rowNow + 1).
        IF f < 0 THEN DrawPipAt(x0, y0, CuberPipMode:Standing, CuberDir:DownRight, 0, 0, FALSE).
        ELSE DO:
            f = f + 1.
            DrawPipAt(x0 + INTEGER(ROUND((x1 - x0) * f / 12.0, 0)), y0 + INTEGER(ROUND((y1 - y0) * f / 12.0, 0)) - CuberRules:HopLift(f, 12),
                      CuberPipMode:Hopping, (IF x1 < x0 THEN CuberDir:DownLeft ELSE CuberDir:DownRight), f, 0, FALSE).
        END.
    END METHOD.

    /* The words of the title: the name dropping in a letter at a time, the best score, what to press. */
    METHOD PRIVATE VOID DrawTitleWords():
        VAR INTEGER t.
        VAR INTEGER i.
        VAR INTEGER x.
        VAR INTEGER delay.
        VAR CHARACTER gameName = "CUBER".
        VAR TextStamp stamp.
        t = IntroFrame().
        x = INTEGER(TRUNCATE(({&SIZE} - (LENGTH(gameName) * 18 - 3)) / 2, 0)).
        DO i = 1 TO LENGTH(gameName):
            delay = INTEGER(TRUNCATE((i - 1) * 3.6, 0)).
            IF t < delay THEN NEXT.
            /* each letter drops 4 pixels into place over 3 frames */
            stamp = mText:Get(SUBSTRING(gameName, i, 1), 3, CuberLook:Colour(CuberTint:TitleTop), CuberLook:Colour(CuberTint:TitleBottom), CuberLook:Colour(CuberTint:Outline)).
            stamp:DrawTo(mCanvas, x + (i - 1) * 18, 16 - (IF t - delay < 3 THEN 4 - 2 * (t - delay) ELSE 0)).
        END.
        IF mGame:Frames MODULO 60 < 36 THEN Words("PRESS SPACE", 2, CuberTint:Gold, CuberTint:Gold, -1, 228, TRUE, TRUE, FALSE).
        Words("ARROWS HOP   P PAUSE", 1, CuberTint:Label, CuberTint:Label, -1, 246, TRUE, FALSE, FALSE).
    END METHOD.

    /* Text from a cache of stamps. plCentre puts it in the middle of the picture across, else piX is where it starts. A colour from
       poTop at the top of the letters to poBottom, with a dark edge when plEdge is set. */
    METHOD PRIVATE VOID Words(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTop AS CuberTint, INPUT poBottom AS CuberTint,
                              INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plCentre AS LOGICAL, INPUT plEdge AS LOGICAL, INPUT plSpare AS LOGICAL):
        VAR TextStamp stamp.
        VAR INTEGER x.
        stamp = mText:Get(pcText, piScale, CuberLook:Colour(poTop), CuberLook:Colour(poBottom),
                          (IF plEdge THEN CuberLook:Colour(CuberTint:Outline) ELSE -1)).
        x = (IF plCentre THEN INTEGER(TRUNCATE(({&SIZE} - stamp:Width) / 2, 0)) ELSE piX).
        stamp:DrawTo(mCanvas, x, piY).
    END METHOD.

END CLASS.
