/* Draws Football Manager in its "Chalk and Floodlights" look (colours in FootballLook, sprites in FootballArt, both made from the
   designer's file by tools/gen-footballmanager-art.py). It reads a FootballGame, never changes it, and paints the picture on a pixel
   canvas of its own, 320 x 240 pixels, then hands the canvas to the window's renderer (the inner one), so the game's own grid is left
   as it is.

   So far it draws the match (the Match phase): the floodlit pitch in perspective with the goal being attacked, seven figures, the ball
   and its trail, the score bar, the ticker and the close up of the goal mouth. Every other phase shows a plain board with its name
   until its screen is drawn. The pitch is kept in the background of two canvases, one for each goal (the left goal's view is the
   right one turned round), so a frame costs only the figures. Everything that moves is a function of the game's highlight clock
   (MatchMs, see Highlights), so a test sees the same picture for the same time.

   The painter owns canvases: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballPainter FINAL IMPLEMENTS IGridRenderer:

    VAR PRIVATE IGridRenderer mInner.
    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE Grid mGrid.
    VAR PRIVATE Grid mGridRight.
    VAR PRIVATE Grid mGridLeft.
    VAR PRIVATE Grid mGridBoard.
    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE PixelCanvas mRight.
    VAR PRIVATE PixelCanvas mLeft.
    VAR PRIVATE PixelCanvas mBoard.
    /* the colour of each character of a sprite, by character code plus one */
    VAR PRIVATE INTEGER[128] mPal.
    /* which background the canvas has now: 0 none, 1 the right goal, 2 the left goal, 3 the board */
    VAR PRIVATE INTEGER mShown.
    VAR PRIVATE LOGICAL mDisposed.
    VAR PRIVATE FootballUi mUi.
    VAR PRIVATE FootballScreens mScreens.
    /* the highlight time the frame is drawn at: the game's clock during the match, its end at full time */
    VAR PRIVATE INTEGER mShownMs.
    /* what the picture pass worked out for the text pass of a match frame: the attack number, the attack, the time in it and whether the highlights are over */
    VAR PRIVATE INTEGER mAttackNo.
    VAR PRIVATE PitchAttack mAttack.
    VAR PRIVATE INTEGER mLocalMs.
    VAR PRIVATE LOGICAL mEnded.

    /* The canvas the picture is drawn on, for a preview that writes it to a file. */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    /* A painter with screen state of its own (a new game's, at the name screen). */
    CONSTRUCTOR PUBLIC FootballPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS FootballGame):
        THIS-OBJECT(poInner, poGame, NEW FootballUi()).
    END CONSTRUCTOR.

    /* A painter that draws the screens from the screen state poUi, which the input changes. Throws GridException for no renderer, no game or no screen state. */
    CONSTRUCTOR PUBLIC FootballPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS FootballGame, INPUT poUi AS FootballUi):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Football Manager painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Football Manager painter needs a game").
        IF NOT VALID-OBJECT(poUi) THEN UNDO, THROW NEW GridException("A Football Manager painter needs the screen state").
        mInner = poInner.
        mGame = poGame.
        mUi = poUi.
        mGrid = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mGridRight = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mGridLeft = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mGridBoard = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mRight = NEW PixelCanvas(mGridRight).
        mLeft = NEW PixelCanvas(mGridLeft).
        mBoard = NEW PixelCanvas(mGridBoard).
        BuildPitch(mRight, FALSE).
        BuildPitch(mLeft, TRUE).
        BuildBoard(mBoard).
        mScreens = NEW FootballScreens(mCanvas, mGame, mUi).
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC FootballPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        VAR INTEGER wanted.
        VAR LOGICAL matchLike.
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, FootballGame) THEN UNDO, THROW NEW GridException("A Football Manager painter draws a Football Manager game").
        mUi:Settle(mGame:Phase).
        matchLike = mGame:Phase = FootballPhase:Match OR mGame:Phase = FootballPhase:FullTime.
        IF matchLike THEN
        DO:
            IF mGame:Phase = FootballPhase:Match THEN mShownMs = mGame:MatchMs.
            ELSE mShownMs = Highlights:TotalMs(mGame:Played).
            wanted = ViewFor().
        END.
        ELSE wanted = 3.
        IF wanted <> mShown THEN
        DO:
            CASE wanted:
                WHEN 1 THEN mCanvas:LoadBack(mRight).
                WHEN 2 THEN mCanvas:LoadBack(mLeft).
                OTHERWISE mCanvas:LoadBack(mBoard).
            END CASE.
            mShown = wanted.
        END.
        mCanvas:Restore().
        IF matchLike THEN
        DO:
            /* the pictures go in a batch (much faster), the text after it: text cannot be drawn in a batch */
            mCanvas:BeginBatch().
            DrawMatch().
            mCanvas:EndBatch().
            DrawMatchText().
            IF mGame:Phase = FootballPhase:FullTime THEN mScreens:FullTimePlate().
        END.
        ELSE mScreens:Draw().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvases. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mRight) THEN mRight:Dispose().
        IF VALID-OBJECT(mLeft) THEN mLeft:Dispose().
        IF VALID-OBJECT(mBoard) THEN mBoard:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        IF VALID-OBJECT(mGridRight) THEN mGridRight:Dispose().
        IF VALID-OBJECT(mGridLeft) THEN mGridLeft:Dispose().
        IF VALID-OBJECT(mGridBoard) THEN mGridBoard:Dispose().
    END METHOD.

    /* ================================ colours and sprites ================================ */

    METHOD PRIVATE INTEGER Hue(INPUT poTint AS FootballTint):
        RETURN FootballLook:Colour(poTint).
    END METHOD.

    /* Fills mPal with the five tones of a row (character codes 49 to 53 are the digits 1 to 5). */
    METHOD PRIVATE VOID SetTones(INPUT poRow AS FootballRow):
        VAR INTEGER t.
        DO t = 1 TO 5:
            mPal[ASC(STRING(t)) + 1] = FootballLook:Tone(poRow, t).
        END.
    END METHOD.

    /* Fills mPal with the fixed colours of a sprite ("A=F2C6A0;B=C99474"). */
    METHOD PRIVATE VOID SetLetters(INPUT poSprite AS FootballSprite):
        VAR CHARACTER pal.
        VAR CHARACTER one.
        VAR INTEGER n.
        VAR INTEGER i.
        pal = FootballArt:Palette(poSprite).
        IF pal = "" THEN RETURN.
        n = NUM-ENTRIES(pal, ";").
        DO i = 1 TO n:
            one = ENTRY(i, pal, ";").
            mPal[ASC(SUBSTRING(one, 1, 1)) + 1] = HexColour(SUBSTRING(one, 3)).
        END.
    END METHOD.

    /* A colour from six hex digits. */
    METHOD PRIVATE INTEGER HexColour(INPUT pcHex AS CHARACTER):
        VAR INTEGER i.
        VAR INTEGER v.
        DO i = 1 TO 6:
            v = v * 16 + INDEX("0123456789ABCDEF", SUBSTRING(pcHex, i, 1)) - 1.
        END.
        RETURN v.
    END METHOD.

    /* Draws a sprite so that its origin cell falls on piX, piY, in the colours of mPal. A mirrored sprite is turned left to right. */
    METHOD PRIVATE VOID Blit(INPUT poSprite AS FootballSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL):
        VAR CHARACTER cells.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER ox.
        VAR INTEGER oy.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER code.
        cells = FootballArt:Cells(poSprite).
        w = FootballArt:Width(poSprite).
        h = FootballArt:Height(poSprite).
        ox = FootballArt:OriginX(poSprite).
        oy = FootballArt:OriginY(poSprite).
        DO cy = 0 TO h - 1:
            DO cx = 0 TO w - 1:
                code = ASC(SUBSTRING(cells, cy * w + cx + 1, 1)).
                IF code = 46 THEN NEXT.
                mCanvas:Plot((IF plMirror THEN piX + ox - cx ELSE piX + cx - ox), piY + cy - oy, 0, mPal[code + 1]).
            END.
        END.
    END METHOD.

    /* A sprite with fixed colours and, for some, the tones of a row chosen from what it is: a ball, a keeper in the close up, a kit icon. */
    METHOD PRIVATE VOID Stamp(INPUT poSprite AS FootballSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL):
        SetLetters(poSprite).
        CASE poSprite:
            WHEN FootballSprite:BallRoll1 OR WHEN FootballSprite:BallRoll2 OR WHEN FootballSprite:BallAir OR WHEN FootballSprite:BallShadow
                OR WHEN FootballSprite:GmBallNear OR WHEN FootballSprite:GmBallMid OR WHEN FootballSprite:GmBallFar THEN SetTones(FootballRow:Ball).
            WHEN FootballSprite:GmKeeperReady OR WHEN FootballSprite:GmKeeperHold OR WHEN FootballSprite:GmKeeperJump
                OR WHEN FootballSprite:GmKeeperDiveRight OR WHEN FootballSprite:GmKeeperHighRight THEN SetTones(FootballRow:Keeper).
            WHEN FootballSprite:KitWhite THEN SetTones(FootballRow:White).
            WHEN FootballSprite:KitBlack THEN SetTones(FootballRow:Black).
        END CASE.
        Blit(poSprite, piX, piY, plMirror).
    END METHOD.

    /* A figure of one of the kits: piKit 0 is the white kit (a black hoop, dark shorts), 1 the black kit (pinstripes, light shorts), 2 the
       keeper's. The skin and hair follow the number piN (skin n mod 3, hair n mod 4). The pattern goes on the torso, which is from the
       first row with a tone 1 down to the row above the first shorts. */
    METHOD PRIVATE VOID Figure(INPUT poSprite AS FootballSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMirror AS LOGICAL,
                               INPUT piKit AS INTEGER, INPUT piN AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER ox.
        VAR INTEGER oy.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER code.
        VAR INTEGER torsoTop = -1.
        VAR INTEGER torsoEnd = -1.
        VAR INTEGER pattern.
        VAR LOGICAL colourIt.
        cells = FootballArt:Cells(poSprite).
        w = FootballArt:Width(poSprite).
        h = FootballArt:Height(poSprite).
        ox = FootballArt:OriginX(poSprite).
        oy = FootballArt:OriginY(poSprite).
        SetLetters(poSprite).
        CASE piKit:
            WHEN 0 THEN
            DO:
                SetTones(FootballRow:White).
                mPal[84] = Hue(FootballTint:KitDarkShorts).
                mPal[85] = Hue(FootballTint:KitDarkShortsShade).
                pattern = Hue(FootballTint:KitHoop).
            END.
            WHEN 1 THEN
            DO:
                SetTones(FootballRow:Black).
                mPal[84] = Hue(FootballTint:KitLightShorts).
                mPal[85] = Hue(FootballTint:KitLightShortsShade).
                pattern = Hue(FootballTint:KitPinstripe).
            END.
            OTHERWISE SetTones(FootballRow:Keeper).
        END CASE.
        IF piKit < 2 THEN
        DO:
            mPal[68] = Hue(FootballTint:Skin1).
            CASE piN MODULO 3:
                WHEN 0 THEN
                DO:
                    mPal[66] = Hue(FootballTint:Skin1).
                    mPal[67] = Hue(FootballTint:Skin1Shade).
                    mPal[68] = Hue(FootballTint:Skin1).
                END.
                WHEN 1 THEN
                DO:
                    mPal[66] = Hue(FootballTint:Skin2).
                    mPal[67] = Hue(FootballTint:Skin2Shade).
                    mPal[68] = Hue(FootballTint:Skin2).
                END.
                OTHERWISE
                DO:
                    mPal[66] = Hue(FootballTint:Skin3).
                    mPal[67] = Hue(FootballTint:Skin3Shade).
                    mPal[68] = Hue(FootballTint:Skin3).
                END.
            END CASE.
            CASE piN MODULO 4:
                WHEN 0 THEN mPal[73] = Hue(FootballTint:HairDark).
                WHEN 1 THEN mPal[73] = Hue(FootballTint:HairBlack).
                WHEN 2 THEN mPal[73] = Hue(FootballTint:HairFair).
                OTHERWISE mPal[73] = Hue(FootballTint:HairGinger).
            END CASE.
        END.
        /* the torso: from the first row holding a tone 1 down to the row above the first S */
        DO cy = 0 TO h - 1:
            IF torsoTop < 0 AND INDEX(SUBSTRING(cells, cy * w + 1, w), "1") > 0 THEN torsoTop = cy.
            IF torsoTop >= 0 AND torsoEnd < 0 AND INDEX(SUBSTRING(cells, cy * w + 1, w), "S") > 0 THEN torsoEnd = cy - 1.
        END.
        DO cy = 0 TO h - 1:
            DO cx = 0 TO w - 1:
                code = ASC(SUBSTRING(cells, cy * w + cx + 1, 1)).
                IF code = 46 THEN NEXT.
                colourIt = FALSE.
                IF piKit < 2 AND torsoTop >= 0 AND cy >= torsoTop AND cy <= torsoEnd AND code >= 49 AND code <= 52 THEN
                DO:
                    IF piKit = 0 THEN colourIt = cy = torsoTop + 2.
                    ELSE colourIt = cy > torsoTop AND (cx = 2 OR cx = 4).
                END.
                mCanvas:Plot((IF plMirror THEN piX + ox - cx ELSE piX + cx - ox), piY + cy - oy, 0, (IF colourIt THEN pattern ELSE mPal[code + 1])).
            END.
        END.
    END METHOD.

    /* ================================ the pitch ================================ */

    /* Sets a pixel of a background (drawn on the view layer and baked afterwards); for the left goal's view the pitch rows are turned round (x becomes 319 - x). */
    METHOD PRIVATE VOID Dot(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER, INPUT plMirror AS LOGICAL):
        IF plMirror AND piY >= 34 AND piY <= 193 THEN poCanvas:Plot(319 - piX, piY, 0, piColour).
        ELSE poCanvas:Plot(piX, piY, 0, piColour).
    END METHOD.

    /* The x of the goal line on a pixel row of the pitch (the edge after targetCol 9 + row). */
    METHOD PRIVATE INTEGER GoalX(INPUT piY AS INTEGER):
        RETURN 171 + INTEGER(TRUNCATE(5 * (piY - 36) / 7, 0)).
    END METHOD.

    /* The x of the line k cells in front of the goal line parallel to it. */
    METHOD PRIVATE INTEGER LineX(INPUT piY AS INTEGER, INPUT piK AS INTEGER):
        RETURN 91 + 8 * piK + INTEGER(TRUNCATE(5 * (piY - 36) / 7, 0)).
    END METHOD.

    /* A horizontal run of one colour on a background, in one fill. */
    METHOD PRIVATE VOID Strip(INPUT poCanvas AS PixelCanvas, INPUT piX0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY AS INTEGER,
                              INPUT piColour AS INTEGER, INPUT plMirror AS LOGICAL):
        IF piX1 < piX0 THEN RETURN.
        IF plMirror AND piY >= 34 AND piY <= 193 THEN poCanvas:FillRect(319 - piX1, piY, piX1 - piX0 + 1, 1, 0, piColour).
        ELSE poCanvas:FillRect(piX0, piY, piX1 - piX0 + 1, 1, 0, piColour).
    END METHOD.

    /* The tile of a stand (crowd_1: sitting) repeated along rows piY to piY + 7. */
    METHOD PRIVATE VOID Crowd(INPUT poCanvas AS PixelCanvas, INPUT piY AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER x.
        VAR INTEGER y.
        SetLetters(FootballSprite:Crowd1).
        cells = FootballArt:Cells(FootballSprite:Crowd1).
        DO y = 0 TO 7:
            DO x = 0 TO 319:
                poCanvas:Plot(x, piY + y, 0, mPal[ASC(SUBSTRING(cells, y * 32 + (x MODULO 32) + 1, 1)) + 1]).
            END.
        END.
    END METHOD.

    /* The hoardings: four rows of board with blocks of lettering on the middle two rows, no words. */
    METHOD PRIVATE VOID Hoardings(INPUT poCanvas AS PixelCanvas, INPUT piY AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER k.
        VAR INTEGER w.
        VAR INTEGER cx.
        DO y = 0 TO 3:
            Strip(poCanvas, 0, 319, piY + y, Hue(FootballTint:Hoarding), FALSE).
        END.
        x = 3.
        DO WHILE x < 320:
            w = INTEGER(ENTRY((k MODULO 5) + 1, "10,6,14,8,12")).
            DO y = 1 TO 2:
                DO cx = x TO MINIMUM(319, x + w - 1):
                    poCanvas:Plot(cx, piY + y, 0, (IF k MODULO 3 = 0 THEN Hue(FootballTint:HoardingWarm) ELSE Hue(FootballTint:HoardingLit))).
                END.
            END.
            x = x + w + 7.
            k = k + 1.
        END.
    END METHOD.

    /* A floodlight: the lamp head, a glow ring and a haze ring round it. */
    METHOD PRIVATE VOID Floodlight(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        DO y = piY - 2 TO piY + 4:
            DO x = piX - 2 TO piX + 7:
                IF x >= piX AND x <= piX + 5 AND y >= piY AND y <= piY + 2 THEN poCanvas:Plot(x, y, 0, Hue(FootballTint:Floodlight)).
                ELSE IF x >= piX - 1 AND x <= piX + 6 AND y >= piY - 1 AND y <= piY + 3 THEN poCanvas:Plot(x, y, 0, Hue(FootballTint:FloodGlow)).
                ELSE poCanvas:Plot(x, y, 0, Hue(FootballTint:FloodHaze)).
            END.
        END.
    END METHOD.

    /* The goal on the right goal's line: two posts 14 pixels tall, a crossbar and the net behind. It spans rows 7 to 13 of the grid, from the
       foot of the far post at (206, 85) to the near post at (240, 133). */
    METHOD PRIVATE VOID Goal(INPUT poCanvas AS PixelCanvas, INPUT plMirror AS LOGICAL):
        VAR INTEGER y.
        VAR INTEGER x.
        VAR INTEGER d.
        DO y = 85 TO 133:
            x = GoalX(y).
            /* the net behind the line, 10 pixels wide, from the ground to 14 pixels up (drawn as it leans up the screen) */
            DO d = 1 TO 10:
                IF (x + d + y) MODULO 3 = 0 THEN Dot(poCanvas, x + d, y - 7, Hue(FootballTint:Net), plMirror).
                ELSE Dot(poCanvas, x + d, y - 7, Hue(FootballTint:NetDark), plMirror).
            END.
            /* the crossbar along the line, 14 pixels up */
            Dot(poCanvas, x, y - 14, Hue(FootballTint:Post), plMirror).
            Dot(poCanvas, x + 1, y - 14, FootballLook:Tone(FootballRow:Silver, 3), plMirror).
        END.
        /* the two posts */
        DO d = 0 TO 13:
            Dot(poCanvas, GoalX(85), 85 - d, Hue(FootballTint:Post), plMirror).
            Dot(poCanvas, GoalX(85) + 1, 85 - d, FootballLook:Tone(FootballRow:Silver, 3), plMirror).
            Dot(poCanvas, GoalX(133), 133 - d, Hue(FootballTint:Post), plMirror).
            Dot(poCanvas, GoalX(133) + 1, 133 - d, FootballLook:Tone(FootballRow:Silver, 3), plMirror).
        END.
    END METHOD.

    /* The background of the match: the stands, the floodlights, the pitch and its lines, the goal, the bars. The right goal's is drawn whole; the left goal's starts from a copy of it and redraws the pitch rows turned round. Drawn on the view layer in fills and then baked into the background in one copy. */
    METHOD PRIVATE VOID BuildPitch(INPUT poCanvas AS PixelCanvas, INPUT plMirror AS LOGICAL):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER g.
        VAR INTEGER spotX.
        VAR INTEGER stripe.
        VAR INTEGER edge.
        IF plMirror THEN
        DO:
            poCanvas:LoadBack(mRight).
            poCanvas:Restore().
        END.
        poCanvas:BeginBatch().
        IF NOT plMirror THEN
        DO:
            poCanvas:FillRect(0, 0, 320, 240, 0, Hue(FootballTint:Tunnel)).
            /* the top stand: roof, roof edge, crowd, wall, hoardings; the bottom stand: hoardings and crowd */
            poCanvas:FillRect(0, 18, 320, 12, 0, Hue(FootballTint:Stand)).
            poCanvas:FillRect(0, 18, 320, 2, 0, Hue(FootballTint:Roof)).
            poCanvas:FillRect(0, 20, 320, 1, 0, Hue(FootballTint:RoofEdge)).
            Crowd(poCanvas, 21).
            poCanvas:FillRect(0, 29, 320, 1, 0, Hue(FootballTint:Wall)).
            Hoardings(poCanvas, 30).
            Hoardings(poCanvas, 194).
            Crowd(poCanvas, 198).
            /* the rule under the score bar and over the ticker */
            poCanvas:FillRect(0, 17, 320, 1, 0, Hue(FootballTint:TunnelRule)).
            poCanvas:FillRect(0, 206, 320, 1, 0, Hue(FootballTint:TunnelRule)).
        END.
        /* the run off, then the mown stripes of the pitch left of the goal line, in runs of 16 pixels */
        poCanvas:FillRect(0, 34, 320, 160, 0, Hue(FootballTint:RunOff)).
        DO y = 36 TO 189:
            g = GoalX(y).
            x = g - 1.
            DO WHILE x >= 0:
                stripe = INTEGER(TRUNCATE((g - 1 - x) / 16, 0)).
                edge = MAXIMUM(0, x - 15).
                Strip(poCanvas, edge, x, y, (IF stripe MODULO 2 = 0 THEN Hue(FootballTint:GrassA) ELSE Hue(FootballTint:GrassB)), plMirror).
                x = edge - 1.
            END.
            Dot(poCanvas, g, y, Hue(FootballTint:Line), plMirror).
            /* the penalty area (5 cells in front of the line) and the goal area (8 cells) */
            IF y >= 57 AND y <= 161 THEN Dot(poCanvas, LineX(y, 5), y, Hue(FootballTint:Line), plMirror).
            IF y >= 78 AND y <= 140 THEN Dot(poCanvas, LineX(y, 8), y, Hue(FootballTint:Line), plMirror).
        END.
        Strip(poCanvas, 0, GoalX(36), 36, Hue(FootballTint:Line), plMirror).
        Strip(poCanvas, 0, GoalX(189), 189, Hue(FootballTint:Line), plMirror).
        Strip(poCanvas, LineX(57, 5), GoalX(57), 57, Hue(FootballTint:Line), plMirror).
        Strip(poCanvas, LineX(161, 5), GoalX(161), 161, Hue(FootballTint:Line), plMirror).
        Strip(poCanvas, LineX(78, 8), GoalX(78), 78, Hue(FootballTint:Line), plMirror).
        Strip(poCanvas, LineX(140, 8), GoalX(140), 140, Hue(FootballTint:Line), plMirror).
        spotX = INTEGER(TRUNCATE((LineX(109, 6) + LineX(109, 7)) / 2, 0)).
        Strip(poCanvas, spotX, spotX + 1, 109, Hue(FootballTint:Spot), plMirror).
        Goal(poCanvas, plMirror).
        IF NOT plMirror THEN
        DO:
            Floodlight(poCanvas, 3, 19).
            Floodlight(poCanvas, 305, 19).
        END.
        poCanvas:BakeView().
        poCanvas:EndBatch().
    END METHOD.

    /* The background of every screen that is not drawn yet: the chalkboard in its wooden frame between the status bar and the key bar. */
    METHOD PRIVATE VOID BuildBoard(INPUT poCanvas AS PixelCanvas):
        poCanvas:FillRect(0, 0, 320, 240, 0, Hue(FootballTint:Tunnel)).
        poCanvas:FillRect(0, 14, 320, 214, 0, FootballLook:Tone(FootballRow:Wood, 3)).
        poCanvas:FillRect(4, 18, 312, 206, 0, Hue(FootballTint:Board)).
        poCanvas:BakeView().
    END METHOD.

    /* ================================ the match ================================ */

    /* The view the shown attack needs: 1 for the right goal (the home side attacks it), 2 for the left. */
    METHOD PRIVATE INTEGER ViewFor():
        VAR INTEGER a.
        a = Highlights:AttackAtMs(mGame:Played, mShownMs).
        IF a = 0 THEN a = mGame:Played:AttackCount.
        RETURN mGame:Played:AttackAt(a):Team.
    END METHOD.

    /* The pixel x of a figure's feet or the ball on a cell of the shown view, and the y (a ball is 3 higher than feet). */
    METHOD PRIVATE INTEGER CellX(INPUT piTeam AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        IF piTeam = 1 THEN RETURN 95 + 8 * piCol - 3 * piRow.
        RETURN 319 - (95 + 8 * (31 - piCol) - 3 * piRow).
    END METHOD.

    METHOD PRIVATE INTEGER CellY(INPUT piRow AS INTEGER):
        RETURN 42 + 7 * piRow.
    END METHOD.

    /* The kit of a team's players: the manager's club wears the colour chosen (0 black, 7 white), the other side the other. 0 is the white kit, 1 the black. */
    METHOD PRIVATE INTEGER KitOf(INPUT piTeam AS INTEGER):
        VAR LOGICAL manager.
        manager = piTeam = mGame:ThisFixture:ManagerSide.
        IF manager THEN RETURN (IF mGame:World:KitColour = 7 THEN 0 ELSE 1).
        RETURN (IF mGame:World:KitColour = 7 THEN 1 ELSE 0).
    END METHOD.

    /* A value moved from piFrom toward piTo by piPart of piOf. */
    METHOD PRIVATE INTEGER Lerp(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER, INPUT piPart AS INTEGER, INPUT piOf AS INTEGER):
        IF piOf <= 0 THEN RETURN piTo.
        RETURN piFrom + INTEGER(ROUND((piTo - piFrom) * MINIMUM(piPart, piOf) / piOf, 0)).
    END METHOD.

    /* The figure frame for a player who is moving (run frames every 100 ms) or standing. */
    METHOD PRIVATE FootballSprite RunFrame(INPUT piMs AS INTEGER, INPUT plMoving AS LOGICAL):
        IF NOT plMoving THEN RETURN FootballSprite:FigStand.
        CASE INTEGER(TRUNCATE(piMs / 100, 0)) MODULO 4:
            WHEN 0 THEN RETURN FootballSprite:FigRun1.
            WHEN 1 THEN RETURN FootballSprite:FigRun2.
            WHEN 2 THEN RETURN FootballSprite:FigRun3.
            OTHERWISE RETURN FootballSprite:FigRun4.
        END CASE.
    END METHOD.

    /* Draws the match at the game's highlight time: the score bar, the pitch with its seven figures and the ball, the ticker and, for a shot, the close up. */
    METHOD PRIVATE VOID DrawMatch():
        VAR MatchResult result = mGame:Played.
        VAR INTEGER a = Highlights:AttackAtMs(result, mShownMs).
        VAR INTEGER t = Highlights:LocalMs(result, mShownMs).
        VAR PitchAttack attack.
        VAR INTEGER team.
        VAR INTEGER dribbleMs.
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER[7] fx.
        VAR INTEGER[7] fy.
        VAR INTEGER[7] rank.
        VAR INTEGER hold.
        VAR INTEGER ballX.
        VAR INTEGER ballY.
        VAR INTEGER point.
        VAR INTEGER afterShot.
        VAR INTEGER runMs.
        VAR INTEGER prevX.
        VAR INTEGER prevY.
        VAR INTEGER nextX.
        VAR INTEGER nextY.
        VAR INTEGER trailK.
        VAR DECIMAL span.
        VAR LOGICAL moving.
        VAR LOGICAL ended.
        ScoreBarBack().
        ended = a = 0.
        IF ended THEN a = result:AttackCount.
        attack = result:AttackAt(a).
        team = attack:Team.
        IF ended THEN t = Highlights:AttackMs(attack).
        dribbleMs = attack:DribbleSteps * Highlights:DribbleMs().
        afterShot = t - dribbleMs - Highlights:ShotMs().
        runMs = Highlights:RunMs(attack).
        moving = t < dribbleMs.
        /* where each of the seven is, as a pitch cell: moving from the start to the shot positions during the dribble, then standing; the keeper follows the ball's path */
        DO i = 1 TO 7:
            rank[i] = i.
            IF i < 7 THEN
            DO:
                fx[i] = CellX(team, Lerp(attack:StartCol(i), attack:ShotCol(i), t, dribbleMs), Lerp(attack:StartRow(i), attack:ShotRow(i), t, dribbleMs)).
                fy[i] = CellY(Lerp(attack:StartRow(i), attack:ShotRow(i), t, dribbleMs)).
            END.
        END.
        point = 1.
        IF afterShot > 0 THEN point = MINIMUM(attack:FlightPoints, 1 + INTEGER(TRUNCATE(afterShot / Highlights:RunOnMs(), 0))).
        fx[7] = CellX(team, attack:KeeperCol(point), attack:KeeperRow(point)).
        fy[7] = CellY(attack:KeeperRow(point)).
        /* the crowd jumps for a goal: both stands swap to the cheering tile every 150 ms for 1200 ms from the moment the ball is in the net */
        IF NOT ended AND attack:Outcome = AttackOutcome:Goal AND t >= Highlights:GoalAtMs(attack) AND t < Highlights:GoalAtMs(attack) + Highlights:CheerMs()
           AND INTEGER(TRUNCATE((t - Highlights:GoalAtMs(attack)) / 150, 0)) MODULO 2 = 1 THEN
        DO:
            CrowdCheer(21).
            CrowdCheer(198).
        END.
        /* the figures, back to front by the y of their feet */
        DO i = 1 TO 6:
            DO j = i + 1 TO 7:
                IF fy[rank[j]] < fy[rank[i]] THEN
                DO:
                    hold = rank[i].
                    rank[i] = rank[j].
                    rank[j] = hold.
                END.
            END.
        END.
        DO i = 1 TO 7:
            DrawFigure(rank[i], fx[rank[i]], fy[rank[i]], team, attack, moving, t, afterShot).
        END.
        /* the ball: beside the attacker while he dribbles, then along its path across the pitch, moving smoothly between the points of the path */
        IF t < dribbleMs THEN
        DO:
            ballX = CellX(team, Lerp(attack:BallStartCol(), attack:BallCol(1), t, dribbleMs), attack:BallRow(1)).
            ballY = 39 + 7 * attack:BallRow(1).
        END.
        ELSE
        DO:
            ballX = CellX(team, attack:BallCol(point), attack:BallRow(point)).
            ballY = 39 + 7 * attack:BallRow(point).
            IF afterShot > 0 AND point < attack:FlightPoints THEN
            DO:
                nextX = CellX(team, attack:BallCol(point + 1), attack:BallRow(point + 1)).
                nextY = 39 + 7 * attack:BallRow(point + 1).
                ballX = Lerp(ballX, nextX, afterShot MODULO Highlights:RunOnMs(), Highlights:RunOnMs()).
                ballY = Lerp(ballY, nextY, afterShot MODULO Highlights:RunOnMs(), Highlights:RunOnMs()).
            END.
            /* the trail: three pixels behind the ball along its path, 2, 4 and 6 pixels back */
            IF afterShot > 0 AND point > 1 THEN
            DO:
                prevX = CellX(team, attack:BallCol(point - 1), attack:BallRow(point - 1)).
                prevY = 39 + 7 * attack:BallRow(point - 1).
                span = SQRT((ballX - prevX) * (ballX - prevX) + (ballY - prevY) * (ballY - prevY)).
                IF span >= 1 THEN
                    DO trailK = 1 TO 3:
                        mCanvas:Plot(ballX + INTEGER(ROUND((prevX - ballX) * 2 * trailK / span, 0)), ballY + INTEGER(ROUND((prevY - ballY) * 2 * trailK / span, 0)), 0,
                                     (IF trailK = 1 THEN Hue(FootballTint:Trail1) ELSE IF trailK = 2 THEN Hue(FootballTint:Trail2) ELSE Hue(FootballTint:Trail3))).
                    END.
            END.
        END.
        Stamp(FootballSprite:BallShadow, ballX + 1, ballY + 3, FALSE).
        Stamp(FootballSprite:BallRoll1, ballX, ballY, FALSE).
        mAttackNo = a.
        mAttack = attack.
        mLocalMs = t.
        mEnded = ended.
        TickerBack().
        IF NOT ended AND attack:Outcome <> AttackOutcome:Blocked AND afterShot >= runMs THEN DrawCloseUp(attack, afterShot - runMs).
    END METHOD.

    /* One of the seven: 1 the attacker with the ball, 2 and 3 his team mates, 4 to 6 the defenders and 7 the keeper. Attackers face the goal, defenders the play. */
    METHOD PRIVATE VOID DrawFigure(INPUT piWho AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piTeam AS INTEGER,
                                   INPUT poAttack AS PitchAttack, INPUT plMoving AS LOGICAL, INPUT piMs AS INTEGER, INPUT piAfterShot AS INTEGER):
        VAR FootballSprite sprite.
        VAR LOGICAL facesGoal.
        VAR LOGICAL mirror.
        VAR INTEGER kit.
        /* a figure is drawn facing right, which is toward the right goal; the left goal's view turns them round */
        facesGoal = piWho <= 3.
        IF piWho = 7 THEN
        DO:
            sprite = (IF INTEGER(TRUNCATE(piMs / 400, 0)) MODULO 2 = 0 THEN FootballSprite:GkReady1 ELSE FootballSprite:GkReady2).
            kit = 2.
            facesGoal = FALSE.
        END.
        ELSE
        DO:
            sprite = RunFrame(piMs, plMoving).
            IF piWho = 1 AND piAfterShot >= 0 AND piAfterShot < 200 THEN sprite = (IF piAfterShot < 80 THEN FootballSprite:FigKick1 ELSE FootballSprite:FigKick2).
            kit = (IF piWho <= 3 THEN KitOf(piTeam) ELSE KitOf(3 - piTeam)).
        END.
        mirror = (facesGoal AND piTeam = 2) OR (NOT facesGoal AND piTeam = 1).
        Stamp(FootballSprite:BallShadow, piX + 1, piY - 1, FALSE).
        Figure(sprite, piX, piY, mirror, kit, piWho).
    END METHOD.

    /* The club names of the sides, home first, and the colour each is written in (yours in yellow). */
    METHOD PRIVATE VOID Sides(OUTPUT pcHome AS CHARACTER, OUTPUT pcAway AS CHARACTER, OUTPUT piHomeColour AS INTEGER, OUTPUT piAwayColour AS INTEGER):
        VAR FootballWorld w = mGame:World.
        VAR Fixture f = mGame:ThisFixture.
        IF f:ManagerIsHome THEN
        DO:
            pcHome = w:ClubName(w:Slot).
            pcAway = w:ClubName(f:OpponentSlot).
            piHomeColour = Hue(FootballTint:ChalkYellow).
            piAwayColour = Hue(FootballTint:Chalk).
        END.
        ELSE
        DO:
            pcHome = w:ClubName(f:OpponentSlot).
            pcAway = w:ClubName(w:Slot).
            piHomeColour = Hue(FootballTint:Chalk).
            piAwayColour = Hue(FootballTint:ChalkYellow).
        END.
    END METHOD.

    /* The score bar's fill and the kit icons (the picture pass). */
    METHOD PRIVATE VOID ScoreBarBack():
        mCanvas:FillRect(0, 0, 320, 17, 0, Hue(FootballTint:Tunnel)).
        Stamp((IF KitOf(1) = 0 THEN FootballSprite:KitWhite ELSE FootballSprite:KitBlack), 14, 5, FALSE).
        Stamp((IF KitOf(2) = 0 THEN FootballSprite:KitWhite ELSE FootballSprite:KitBlack), 298, 5, FALSE).
    END METHOD.

    /* The clubs' names and the score at the highlight time (the text pass). */
    METHOD PRIVATE VOID ScoreBarText():
        VAR INTEGER homeGoals.
        VAR INTEGER awayGoals.
        VAR CHARACTER homeName.
        VAR CHARACTER awayName.
        VAR INTEGER homeColour.
        VAR INTEGER awayColour.
        homeGoals = Highlights:GoalsAtMs(mGame:Played, mShownMs, 1).
        awayGoals = Highlights:GoalsAtMs(mGame:Played, mShownMs, 2).
        Sides(OUTPUT homeName, OUTPUT awayName, OUTPUT homeColour, OUTPUT awayColour).
        mCanvas:DrawText(CAPS(homeName), 24, 6, homeColour).
        mCanvas:DrawTextScaled(STRING(homeGoals), 152 - PixelCanvas:ScaledWidth(STRING(homeGoals), 2), 2, homeColour, homeColour, 2).
        mCanvas:DrawTextScaled("-", 155, 2, Hue(FootballTint:ChalkDim), Hue(FootballTint:ChalkDim), 2).
        mCanvas:DrawTextScaled(STRING(awayGoals), 168, 2, awayColour, awayColour, 2).
        mCanvas:DrawText(CAPS(awayName), 295 - PixelCanvas:ScaledWidth(CAPS(awayName), 1), 6, awayColour).
    END METHOD.

    /* When the result of an attack shows in the ticker, in milliseconds from the start of the attack. */
    METHOD PRIVATE INTEGER ResultAt(INPUT poAttack AS PitchAttack):
        VAR INTEGER ms.
        ms = poAttack:DribbleSteps * Highlights:DribbleMs() + Highlights:ShotMs() + Highlights:RunMs(poAttack).
        IF poAttack:Outcome = AttackOutcome:Blocked THEN RETURN ms.
        RETURN ms + Highlights:ReadyMs() + Highlights:FlightMs().
    END METHOD.

    /* The cheering tile over a stand strip whose top row is piY (the picture pass). */
    METHOD PRIVATE VOID CrowdCheer(INPUT piY AS INTEGER):
        VAR CHARACTER cells.
        VAR INTEGER x.
        VAR INTEGER y.
        SetLetters(FootballSprite:Crowd2).
        cells = FootballArt:Cells(FootballSprite:Crowd2).
        DO y = 0 TO 7:
            DO x = 0 TO 319:
                mCanvas:Plot(x, piY + y, 0, mPal[ASC(SUBSTRING(cells, y * 32 + (x MODULO 32) + 1, 1)) + 1]).
            END.
        END.
    END METHOD.

    /* The ticker's fill and the icon of the result once it is known (the picture pass). */
    METHOD PRIVATE VOID TickerBack():
        VAR FootballSprite badge.
        mCanvas:FillRect(0, 207, 320, 21, 0, Hue(FootballTint:Tunnel)).
        IF NOT (mEnded OR mLocalMs >= ResultAt(mAttack)) THEN RETURN.
        CASE mAttack:Outcome:
            WHEN AttackOutcome:Goal THEN badge = FootballSprite:EvGoal.
            WHEN AttackOutcome:Saved THEN badge = FootballSprite:EvSave.
            WHEN AttackOutcome:Blocked THEN badge = FootballSprite:EvBlock.
            OTHERWISE badge = FootballSprite:EvWide.
        END CASE.
        Stamp(badge, 6, 213, FALSE).
    END METHOD.

    /* The line of the ticker and the count of attacks (the text pass). */
    METHOD PRIVATE VOID TickerText():
        VAR CHARACTER words = "".
        IF mEnded OR mLocalMs >= ResultAt(mAttack) THEN
        DO:
            CASE mAttack:Outcome:
                WHEN AttackOutcome:Goal THEN words = "GOAL!".
                WHEN AttackOutcome:Saved THEN words = "SAVED BY THE KEEPER".
                WHEN AttackOutcome:Blocked THEN words = "BLOCKED".
                OTHERWISE words = "WIDE".
            END CASE.
            mCanvas:DrawText(words, 18, 214, Hue(FootballTint:Chalk)).
        END.
        /* the highlights stop on their last frame and wait for the manager, so say so */
        IF mGame:Phase = FootballPhase:Match AND mGame:MatchMs >= Highlights:TotalMs(mGame:Played) THEN
            mCanvas:DrawText("PRESS SPACE TO CONTINUE", 160 - INTEGER(TRUNCATE(PixelCanvas:ScaledWidth("PRESS SPACE TO CONTINUE", 1) / 2, 0)), 227, Hue(FootballTint:ChalkYellow)).
        mCanvas:DrawText("ATTACK " + STRING(mAttackNo), 313 - PixelCanvas:ScaledWidth("ATTACK " + STRING(mAttackNo), 1), 214, Hue(FootballTint:ChalkDim)).
    END METHOD.

    /* The text of a match frame: the score bar and the ticker. */
    METHOD PRIVATE VOID DrawMatchText():
        ScoreBarText().
        TickerText().
    END METHOD.

    /* The keeper's pose in the close up for a target (targetCol 1 left to 3 right, row 1 high to 3 low), from the design's table: the sprite, whether it is mirrored and where its origin goes on the picture. */
    METHOD PRIVATE VOID KeeperPose(INPUT piTargetCol AS INTEGER, INPUT piRow AS INTEGER, OUTPUT poSprite AS FootballSprite, OUTPUT plMirror AS LOGICAL,
                                   OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        plMirror = piTargetCol = 1.
        CASE piTargetCol:
            WHEN 2 THEN
            DO:
                IF piRow = 1 THEN
                DO:
                    poSprite = FootballSprite:GmKeeperJump.
                    piX = 48.
                    piY = 51.
                END.
                ELSE
                DO:
                    poSprite = FootballSprite:GmKeeperHold.
                    piX = 48.
                    piY = 54.
                END.
            END.
            OTHERWISE
            DO:
                IF piRow = 1 THEN
                DO:
                    poSprite = FootballSprite:GmKeeperHighRight.
                    piX = (IF piTargetCol = 1 THEN 35 ELSE 61).
                    piY = 35.
                END.
                ELSE
                DO:
                    poSprite = FootballSprite:GmKeeperDiveRight.
                    piX = (IF piTargetCol = 1 THEN 40 ELSE 56).
                    piY = (IF piRow = 2 THEN 37 ELSE 47).
                END.
            END.
        END CASE.
    END METHOD.

    /* The close up of the goal mouth for a shot: a ring round a 96 x 64 picture, the keeper ready, the ball's three frames in flight and the result. The game has decided what happened; where it shows is worked out from where the ball left the pitch: the row along the goal line decides left, middle or right, and how far out it left decides high, middle or low. A goal has the keeper go the wrong way, a save has him there, a wide shot goes outside the posts. */
    METHOD PRIVATE VOID DrawCloseUp(INPUT poAttack AS PitchAttack, INPUT piMs AS INTEGER):
        VAR INTEGER tx.
        VAR INTEGER ty.
        VAR INTEGER x0.
        VAR INTEGER endPoint.
        VAR INTEGER side.
        VAR INTEGER depth.
        VAR INTEGER flight.
        VAR INTEGER targetCol.
        VAR INTEGER height.
        VAR INTEGER kx.
        VAR INTEGER ky.
        VAR FootballSprite pose.
        VAR LOGICAL turned.
        endPoint = poAttack:PathLength.
        /* the picture sits over the far corner of the view */
        x0 = (IF poAttack:Team = 1 THEN 9 ELSE 215).
        mCanvas:FillRect(x0 - 3, 84, 102, 70, 0, Hue(FootballTint:Outline)).
        mCanvas:FillRect(x0 - 2, 85, 100, 68, 0, Hue(FootballTint:ChalkYellow)).
        mCanvas:FillRect(x0 - 1, 86, 98, 66, 0, Hue(FootballTint:Outline)).
        Stamp(FootballSprite:GoalMouth, x0, 87, FALSE).
        side = poAttack:BallRow(endPoint).
        IF poAttack:Team = 1 THEN depth = poAttack:BallCol(endPoint) - side - 10.
        ELSE depth = 21 - side - poAttack:BallCol(endPoint).
        /* the target targetCol and row on the picture: 1 left to 3 right, 1 high to 3 low */
        targetCol = (IF side <= 8 THEN 1 ELSE IF side <= 11 THEN 2 ELSE 3).
        height = (IF depth <= 0 THEN 1 ELSE IF depth = 1 THEN 2 ELSE 3).
        IF poAttack:Team = 2 THEN targetCol = 4 - targetCol.
        tx = 24 * targetCol.
        ty = 12 + 10 * height.
        IF poAttack:Outcome = AttackOutcome:Wide THEN
        DO:
            tx = (IF targetCol = 1 THEN 4 ELSE 91).
            ty = 38.
        END.
        IF piMs < Highlights:ReadyMs() THEN
        DO:
            Stamp(FootballSprite:GmKeeperReady, x0 + 48, 87 + 54, FALSE).
            RETURN.
        END.
        flight = INTEGER(TRUNCATE((piMs - Highlights:ReadyMs()) / 80, 0)).
        IF flight < 3 THEN
        DO:
            Stamp(FootballSprite:GmKeeperReady, x0 + 48, 87 + 54, FALSE).
            Stamp((IF flight = 0 THEN FootballSprite:GmBallNear ELSE IF flight = 1 THEN FootballSprite:GmBallMid ELSE FootballSprite:GmBallFar),
                  x0 + 48 + INTEGER(ROUND((tx - 48) * (flight + 1) / 3, 0)), 87 + 70 + INTEGER(ROUND((ty - 70) * (flight + 1) / 3, 0)), FALSE).
            RETURN.
        END.
        CASE poAttack:Outcome:
            WHEN AttackOutcome:Saved THEN
            DO:
                KeeperPose(targetCol, height, OUTPUT pose, OUTPUT turned, OUTPUT kx, OUTPUT ky).
                Stamp(pose, x0 + kx, 87 + ky, turned).
                IF pose <> FootballSprite:GmKeeperHold THEN Stamp(FootballSprite:GmBallFar, x0 + tx, 87 + ty, FALSE).
            END.
            WHEN AttackOutcome:Goal THEN
            DO:
                /* the keeper goes the wrong way: a shot to the left meets the right hand pose, any other the left hand one */
                KeeperPose((IF targetCol = 1 THEN 3 ELSE 1), (IF height = 1 THEN 2 ELSE height), OUTPUT pose, OUTPUT turned, OUTPUT kx, OUTPUT ky).
                Stamp(pose, x0 + kx, 87 + ky, turned).
                /* the net ripples round the ball for three frames of 80 ms */
                IF piMs - Highlights:ReadyMs() - Highlights:FlightMs() < 240 THEN
                    CASE INTEGER(TRUNCATE((piMs - Highlights:ReadyMs() - Highlights:FlightMs()) / 80, 0)):
                        WHEN 0 THEN Stamp(FootballSprite:GmRipple1, x0 + tx, 87 + ty, FALSE).
                        WHEN 1 THEN Stamp(FootballSprite:GmRipple2, x0 + tx, 87 + ty, FALSE).
                        OTHERWISE Stamp(FootballSprite:GmRipple3, x0 + tx, 87 + ty, FALSE).
                    END CASE.
                Stamp(FootballSprite:GmBallFar, x0 + tx, 87 + ty, FALSE).
            END.
            OTHERWISE
            DO:
                Stamp(FootballSprite:GmKeeperReady, x0 + 48, 87 + 54, FALSE).
                Stamp(FootballSprite:GmBallFar, x0 + tx, 87 + ty, FALSE).
            END.
        END CASE.
    END METHOD.

END CLASS.
