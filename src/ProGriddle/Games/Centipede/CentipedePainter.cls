/* Draws Centipede in its neon look (colours in CentipedeLook). It reads a CentipedeGame, never changes it, and paints the picture on a
   pixel canvas of its own: a strip of numbers above the board, then the 30 x 30 board of 8 pixel tiles, 240 x 256 pixels in all. The
   canvas is handed to the window's renderer (the inner one), so the game's own grid is left as it is.

   What is kept in the picture's background: the night, the lighter band of the player zone and the rules, and every mushroom. The
   mushrooms are drawn into the background again only when the game says the field changed (FieldVersion), so a frame costs one block
   copy and the things that move. Everything that moves, and every effect, is a function of the game's own frame counts (Frames,
   PhaseFrames), so the painter keeps no clock of its own and a test sees the same picture for the same game.

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

    DEFINE PRIVATE VARIABLE mInner     AS IGridRenderer  NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame      AS CentipedeGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid      AS Grid           NO-UNDO.
    DEFINE PRIVATE VARIABLE mBaseGrid  AS Grid           NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas    NO-UNDO.
    DEFINE PRIVATE VARIABLE mBase      AS PixelCanvas    NO-UNDO.
    DEFINE PRIVATE VARIABLE mText      AS TextStampCache NO-UNDO.
    /* the version of the field that is baked into the background, -1 for none yet */
    DEFINE PRIVATE VARIABLE mBakedVersion AS INTEGER     NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mDisposed  AS LOGICAL        NO-UNDO.

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
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Centipede painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Centipede painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mText = NEW TextStampCache(96).
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
        IF mBakedVersion <> mGame:FieldVersion THEN BakeField().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawHud().
        IF mGame:Phase = GamePhase:Title THEN DrawTitle().
        ELSE DO:
            DrawCreatures().
            DrawSegments().
            DrawPlayer().
            DrawBonus().
        END.
        mCanvas:EndBatch().
        IF mGame:Phase = GamePhase:GameOver OR (mGame:Paused AND mGame:Phase <> GamePhase:Title) THEN DO:
            /* the board is dimmed once, with the batch closed, and then the words go on it */
            mCanvas:DimRect(0, {&STRIP}, {&WIDTH}, {&HEIGHT} - {&STRIP}, 55, CentipedeLook:Colour(CentipedeTint:Outline)).
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

    /* ================================ the background ================================ */

    /* The plain background, made once on the base canvas: the strip, the night and the lighter player zone, each with a rule. */
    METHOD PRIVATE VOID BuildBase():
        DEFINE VARIABLE rows AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        EXTENT(rows) = {&HEIGHT}.
        DO y = 0 TO {&HEIGHT} - 1:
            IF y < {&STRIP} - 1 THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Strip).
            ELSE IF y = {&STRIP} - 1 THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:StripRule).
            ELSE IF y < {&STRIP} + CentipedeRules:PlayerTop() * CentipedeRules:Tile() THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Night).
            ELSE IF y = {&STRIP} + CentipedeRules:PlayerTop() * CentipedeRules:Tile() THEN rows[y + 1] = CentipedeLook:Colour(CentipedeTint:ZoneRule).
            ELSE rows[y + 1] = CentipedeLook:Colour(CentipedeTint:Zone).
        END.
        mBase:SetBackRows(rows).
    END METHOD.

    /* Draws every mushroom into the background of the picture, so a frame brings them back with one block copy. */
    METHOD PRIVATE VOID BakeField():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DEFINE VARIABLE hp AS INTEGER NO-UNDO.
        mBakedVersion = mGame:FieldVersion.
        mCanvas:LoadBack(mBase).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO cy = 0 TO CentipedeRules:Rows() - 1:
            DO cx = 0 TO CentipedeRules:Cols() - 1:
                hp = mGame:MushroomAt(cx, cy).
                IF hp > 0 THEN DrawMushroom(cx, cy, hp, mGame:PoisonedAt(cx, cy)).
            END.
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    /* A mushroom: a cap that darkens, and loses bites, as it is shot, on a pale stem. A poisoned one is cyan. */
    METHOD PRIVATE VOID DrawMushroom(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHp AS INTEGER, INPUT plPoison AS LOGICAL):
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cap   AS INTEGER NO-UNDO.
        DEFINE VARIABLE shine AS INTEGER NO-UNDO.
        DEFINE VARIABLE bg    AS INTEGER NO-UNDO.
        x = piX * CentipedeRules:Tile().
        y = {&STRIP} + piY * CentipedeRules:Tile().
        cap = CentipedeLook:CapColour(piHp, plPoison).
        shine = CentipedeLook:Colour(IF plPoison THEN CentipedeTint:PoisonShine ELSE CentipedeTint:CapShine).
        bg = CentipedeLook:Colour(IF piY >= CentipedeRules:PlayerTop() THEN CentipedeTint:Zone ELSE CentipedeTint:Night).
        mCanvas:FillRect(x + 3, y + 5, 2, 3, 0, CentipedeLook:Colour(CentipedeTint:Stem)).
        mCanvas:FillRect(x + 1, y + 1, 6, 1, 0, cap).
        mCanvas:FillRect(x, y + 2, 8, 3, 0, cap).
        IF piHp >= 3 THEN DO:
            mCanvas:FillRect(x + 2, y + 2, 2, 1, 0, shine).
            mCanvas:FillRect(x + 5, y + 3, 1, 1, 0, shine).
        END.
        /* bites out of the cap */
        IF piHp <= 3 THEN mCanvas:FillRect(x + 6, y + 1, 2, 2, 0, bg).
        IF piHp <= 2 THEN mCanvas:FillRect(x, y + 3, 2, 2, 0, bg).
        IF piHp <= 1 THEN DO:
            mCanvas:FillRect(x + 3, y + 1, 2, 2, 0, bg).
            mCanvas:FillRect(x + 5, y + 4, 2, 1, 0, bg).
        END.
    END METHOD.

    /* ================================ what moves ================================ */

    /* The strip: the score, the best score and a little shooter for each spare one. */
    METHOD PRIVATE VOID DrawHud():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE hiText AS CHARACTER NO-UNDO.
        Words(STRING(mGame:Score), 1, CentipedeTint:Text, CentipedeTint:Text, 4, 5, FALSE).
        hiText = "HI " + STRING(mGame:HiScore).
        Words(hiText, 1, CentipedeTint:Label, CentipedeTint:Label, 0, 5, TRUE).
        IF mGame:Phase <> GamePhase:Title THEN DO:
            DO i = 1 TO MINIMUM(6, mGame:Lives - 1):
                DrawShip({&WIDTH} - 2 - i * 9, 4, FALSE).
            END.
        END.
    END METHOD.

    /* The shooter: a small ship with a flickering flame. piX and piY are its top left on the picture. */
    METHOD PRIVATE VOID DrawShip(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plFlame AS LOGICAL):
        mCanvas:FillRect(piX + 3, piY, 2, 3, 0, CentipedeLook:Colour(CentipedeTint:ShipLight)).
        mCanvas:FillRect(piX + 2, piY + 2, 4, 3, 0, CentipedeLook:Colour(CentipedeTint:Ship)).
        mCanvas:FillRect(piX, piY + 4, 8, 3, 0, CentipedeLook:Colour(CentipedeTint:Ship)).
        mCanvas:FillRect(piX + 1, piY + 6, 6, 1, 0, CentipedeLook:Colour(CentipedeTint:ShipDeep)).
        mCanvas:FillRect(piX + 3, piY + 3, 2, 1, 0, CentipedeLook:Colour(CentipedeTint:ShipLight)).
        IF plFlame THEN mCanvas:FillRect(piX + 3, piY + 7, 2, 1, 0, CentipedeLook:Colour(CentipedeTint:Flame)).
    END METHOD.

    METHOD PRIVATE VOID DrawPlayer():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        x = mGame:PlayerX.
        y = {&STRIP} + mGame:PlayerY.
        IF mGame:Phase = GamePhase:Dying THEN DO:
            DrawExplosion(x + 4, y + 4, mGame:PhaseFrames).
            RETURN.
        END.
        DrawShip(x, y, mGame:Frames MODULO 6 < 3).
        IF mGame:ShotActive THEN DO:
            mCanvas:FillRect(mGame:ShotX, {&STRIP} + mGame:ShotY, 2, 6, 0, CentipedeLook:Colour(CentipedeTint:ShotTail)).
            mCanvas:FillRect(mGame:ShotX, {&STRIP} + mGame:ShotY, 2, 2, 0, CentipedeLook:Colour(CentipedeTint:Shot)).
        END.
    END METHOD.

    /* The shooter breaking up: eight bits fly out from the middle, from white to orange, and the last of them fade. piAge is frames. */
    METHOD PRIVATE VOID DrawExplosion(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piAge AS INTEGER):
        DEFINE VARIABLE r      AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        IF piAge >= 70 THEN RETURN.
        r = 2 + INTEGER(TRUNCATE(piAge / 3, 0)).
        d = INTEGER(TRUNCATE(r * 0.7, 0)).
        colour = CentipedeLook:Colour(IF piAge < 8 THEN CentipedeTint:Flash ELSE IF piAge < 30 THEN CentipedeTint:Spark ELSE CentipedeTint:Flame).
        IF piAge < 8 THEN mCanvas:FillRect(piCx - 5, piCy - 5, 10, 10, 0, colour).
        mCanvas:FillRect(piCx + r, piCy, 2, 2, 0, colour).
        mCanvas:FillRect(piCx - r - 1, piCy, 2, 2, 0, colour).
        mCanvas:FillRect(piCx, piCy + r, 2, 2, 0, colour).
        mCanvas:FillRect(piCx, piCy - r - 1, 2, 2, 0, colour).
        mCanvas:FillRect(piCx + d, piCy + d, 2, 2, 0, colour).
        mCanvas:FillRect(piCx - d - 1, piCy + d, 2, 2, 0, colour).
        mCanvas:FillRect(piCx + d, piCy - d - 1, 2, 2, 0, colour).
        mCanvas:FillRect(piCx - d - 1, piCy - d - 1, 2, 2, 0, colour).
        IF piAge >= 8 AND piAge < 50 THEN mCanvas:FillRect(piCx - 1, piCy - 1, 3, 3, 0, CentipedeLook:Colour(CentipedeTint:Flame)).
    END METHOD.

    METHOD PRIVATE VOID DrawSegments():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO mGame:SegmentCount - 1:
            DrawSegment(mGame:SegmentX(i), {&STRIP} + mGame:SegmentY(i), mGame:SegmentIsHead(i), mGame:SegmentDirection(i), mGame:Frames + i).
        END.
    END METHOD.

    /* One segment, a round green body with two legs that scuttle, or a lime head with red eyes on the side it is crawling towards.
       piPhase is any number that goes up, which the legs follow. */
    METHOD PRIVATE VOID DrawSegment(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plHead AS LOGICAL, INPUT piDx AS INTEGER, INPUT piPhase AS INTEGER):
        DEFINE VARIABLE main  AS INTEGER NO-UNDO.
        DEFINE VARIABLE light AS INTEGER NO-UNDO.
        DEFINE VARIABLE legA  AS INTEGER NO-UNDO.
        DEFINE VARIABLE legB  AS INTEGER NO-UNDO.
        DEFINE VARIABLE front AS INTEGER NO-UNDO.
        main = CentipedeLook:Colour(IF plHead THEN CentipedeTint:HeadMain ELSE CentipedeTint:BodyMain).
        light = CentipedeLook:Colour(IF plHead THEN CentipedeTint:HeadLight ELSE CentipedeTint:BodyLight).
        /* the legs swap sides every four frames */
        IF INTEGER(TRUNCATE(piPhase / 4, 0)) MODULO 2 = 0 THEN ASSIGN legA = 2 legB = 5.
        ELSE ASSIGN legA = 5 legB = 2.
        mCanvas:FillRect(piX + legA, piY, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Leg)).
        mCanvas:FillRect(piX + legB, piY + 7, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Leg)).
        mCanvas:FillRect(piX + 2, piY + 1, 4, 6, 0, main).
        mCanvas:FillRect(piX + 1, piY + 2, 6, 4, 0, main).
        mCanvas:FillRect(piX + 2, piY + 1, 3, 1, 0, light).
        mCanvas:FillRect(piX + 2, piY + 6, 4, 1, 0, CentipedeLook:Colour(CentipedeTint:BodyDeep)).
        IF plHead THEN DO:
            front = (IF piDx > 0 THEN 5 ELSE 2).
            mCanvas:FillRect(piX + front, piY + 2, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
            mCanvas:FillRect(piX + front, piY + 5, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawCreatures():
        IF mGame:FleaActive THEN DrawFlea().
        IF mGame:SpiderActive THEN DrawSpider().
        IF mGame:ScorpionActive THEN DrawScorpion().
    END METHOD.

    /* The flea: an orange blur with two red eyes, which goes pale and frantic after the first hit. */
    METHOD PRIVATE VOID DrawFlea():
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE main AS INTEGER NO-UNDO.
        x = mGame:FleaX.
        y = {&STRIP} + mGame:FleaY.
        main = CentipedeLook:Colour(IF mGame:FleaHp = 1 AND mGame:Frames MODULO 4 < 2 THEN CentipedeTint:FleaLight ELSE CentipedeTint:FleaMain).
        mCanvas:FillRect(x + 2, y + 1, 4, 5, 0, main).
        mCanvas:FillRect(x + 1, y + 2, 6, 3, 0, main).
        mCanvas:FillRect(x + 2, y + 2, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
        mCanvas:FillRect(x + 5, y + 2, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
        IF mGame:Frames MODULO 6 < 3 THEN DO:
            mCanvas:FillRect(x + 1, y + 6, 1, 2, 0, main).
            mCanvas:FillRect(x + 6, y + 6, 1, 2, 0, main).
        END.
        ELSE DO:
            mCanvas:FillRect(x + 2, y + 6, 1, 2, 0, main).
            mCanvas:FillRect(x + 5, y + 6, 1, 2, 0, main).
        END.
    END METHOD.

    /* The spider: a purple body with two bright eyes and four legs on each side that scuttle. 16 pixels wide. */
    METHOD PRIVATE VOID DrawSpider():
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE leg AS INTEGER NO-UNDO.
        DEFINE VARIABLE o   AS INTEGER NO-UNDO.
        x = mGame:SpiderX.
        y = {&STRIP} + mGame:SpiderY.
        leg = CentipedeLook:Colour(CentipedeTint:SpiderLeg).
        o = (IF mGame:Frames MODULO 8 < 4 THEN 0 ELSE 1).
        /* the legs, on each side: up and out, level, and down */
        mCanvas:FillRect(x + o, y + 1, 5, 1, 0, leg).
        mCanvas:FillRect(x + 1 - o, y + 3, 5, 1, 0, leg).
        mCanvas:FillRect(x + o, y + 5, 5, 1, 0, leg).
        mCanvas:FillRect(x + 1 - o, y + 7, 4, 1, 0, leg).
        mCanvas:FillRect(x + 11 - o, y + 1, 5, 1, 0, leg).
        mCanvas:FillRect(x + 10 + o, y + 3, 5, 1, 0, leg).
        mCanvas:FillRect(x + 11 - o, y + 5, 5, 1, 0, leg).
        mCanvas:FillRect(x + 11 + o, y + 7, 4, 1, 0, leg).
        mCanvas:FillRect(x + 5, y + 1, 6, 6, 0, CentipedeLook:Colour(CentipedeTint:SpiderMain)).
        mCanvas:FillRect(x + 4, y + 2, 8, 4, 0, CentipedeLook:Colour(CentipedeTint:SpiderMain)).
        mCanvas:FillRect(x + 6, y + 2, 4, 1, 0, CentipedeLook:Colour(CentipedeTint:SpiderLight)).
        mCanvas:FillRect(x + 6, y + 3, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
        mCanvas:FillRect(x + 9, y + 3, 1, 1, 0, CentipedeLook:Colour(CentipedeTint:Eye)).
    END METHOD.

    /* The scorpion: a red body with a curled tail and a stinger at the back and two claws at the front, whichever way it is crawling.
       16 pixels wide. */
    METHOD PRIVATE VOID DrawScorpion():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE flip  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE main  AS INTEGER NO-UNDO.
        DEFINE VARIABLE light AS INTEGER NO-UNDO.
        x = mGame:ScorpionX.
        y = {&STRIP} + mGame:ScorpionY.
        flip = mGame:ScorpionDirection < 0.
        main = CentipedeLook:Colour(CentipedeTint:ScorpionMain).
        light = CentipedeLook:Colour(CentipedeTint:ScorpionLight).
        /* body, tail, stinger, head, claws and legs: each is an offset from the back and a width, mirrored when it crawls left */
        Part(x, y + 3, 3, 9, 3, flip, main).
        Part(x, y + 1, 0, 2, 4, flip, main).
        Part(x, y, 0, 3, 1, flip, light).
        Part(x, y + 2, 12, 3, 4, flip, light).
        Part(x, y + 1, 14, 2, 1, flip, main).
        Part(x, y + 6, 14, 2, 1, flip, main).
        IF mGame:Frames MODULO 8 < 4 THEN DO:
            Part(x, y + 6, 4, 1, 2, flip, main).
            Part(x, y + 6, 8, 1, 2, flip, main).
        END.
        ELSE DO:
            Part(x, y + 6, 5, 1, 2, flip, main).
            Part(x, y + 6, 9, 1, 2, flip, main).
        END.
    END METHOD.

    /* A rectangle of a 16 pixel wide creature, piOffset pixels from its back and piWide wide, drawn from the other side when flipped. */
    METHOD PRIVATE VOID Part(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piOffset AS INTEGER, INPUT piWide AS INTEGER, INPUT piHigh AS INTEGER,
                             INPUT plFlip AS LOGICAL, INPUT piColour AS INTEGER):
        mCanvas:FillRect((IF plFlip THEN piX + 16 - piOffset - piWide ELSE piX + piOffset), piY, piWide, piHigh, 0, piColour).
    END METHOD.

    /* The points of the last creature shot, for a second above where it was. */
    METHOD PRIVATE VOID DrawBonus():
        DEFINE VARIABLE age AS INTEGER NO-UNDO.
        IF mGame:LastBonusFrame < 0 THEN RETURN.
        age = mGame:Frames - mGame:LastBonusFrame.
        IF age >= 75 THEN RETURN.
        Words(STRING(mGame:LastBonus), 1, CentipedeTint:Gold, CentipedeTint:Gold,
              MAXIMUM(1, MINIMUM({&WIDTH} - 25, mGame:LastBonusX)), {&STRIP} + MAXIMUM(0, mGame:LastBonusY - INTEGER(TRUNCATE(age / 8, 0))), FALSE).
    END METHOD.

    /* ================================ the screens ================================ */

    /* The title: the name in big letters, a centipede crawling across under it, and what to press. */
    METHOD PRIVATE VOID DrawTitle():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        Words("CENTIPEDE", 3, CentipedeTint:TitleTop, CentipedeTint:TitleBottom, -1, 56, TRUE).
        /* the crawler: eight segments with a head, going right across the picture and round again */
        x = (mGame:Frames * 2) MODULO ({&WIDTH} + 80) - 72.
        DO i = 0 TO 7:
            DrawSegment(x - i * 8, {&STRIP} + 108, i = 0, 1, mGame:Frames + i).
        END.
        IF mGame:Frames MODULO 60 < 40 THEN Words("PRESS SPACE", 1, CentipedeTint:Text, CentipedeTint:Text, -1, {&STRIP} + 150, TRUE).
        Words("ARROWS MOVE   SPACE FIRES", 1, CentipedeTint:Dim, CentipedeTint:Dim, -1, {&HEIGHT} - 22, TRUE).
        Words("P PAUSES   M SOUND", 1, CentipedeTint:Dim, CentipedeTint:Dim, -1, {&HEIGHT} - 12, TRUE).
    END METHOD.

    METHOD PRIVATE VOID DrawGameOver():
        Words("GAME OVER", 3, CentipedeTint:Warn, CentipedeTint:Warn, -1, 100, TRUE).
        Words("SCORE " + STRING(mGame:Score), 1, CentipedeTint:Text, CentipedeTint:Text, -1, 136, TRUE).
        IF mGame:Score > 0 AND mGame:Score >= mGame:HiScore THEN Words("NEW BEST", 1, CentipedeTint:Gold, CentipedeTint:Gold, -1, 150, TRUE).
        IF mGame:PhaseFrames >= 90 AND mGame:Frames MODULO 60 < 40 THEN Words("PRESS SPACE", 1, CentipedeTint:Text, CentipedeTint:Text, -1, 170, TRUE).
    END METHOD.

    METHOD PRIVATE VOID DrawPaused():
        Words("PAUSED", 3, CentipedeTint:Text, CentipedeTint:Label, -1, 112, TRUE).
    END METHOD.

    METHOD PRIVATE VOID DrawCleared():
        Words("WAVE " + STRING(mGame:Wave) + " CLEARED", 1, CentipedeTint:Gold, CentipedeTint:Gold, -1, 120, TRUE).
    END METHOD.

    /* Text from a cache of stamps. plCentre puts it in the middle of the picture across, else piX is where it starts (0 at the
       middle of the width when centred: ignored). A colour from piTop at the top of the letters to piBottom, with a dark edge
       when it is big. */
    METHOD PRIVATE VOID Words(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTop AS CentipedeTint, INPUT poBottom AS CentipedeTint,
                              INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plCentre AS LOGICAL):
        DEFINE VARIABLE stamp AS TextStamp NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER   NO-UNDO.
        stamp = mText:Get(pcText, piScale, CentipedeLook:Colour(poTop), CentipedeLook:Colour(poBottom),
                          (IF piScale > 1 THEN CentipedeLook:Colour(CentipedeTint:Outline) ELSE -1)).
        x = (IF plCentre THEN INTEGER(TRUNCATE(({&WIDTH} - stamp:Width) / 2, 0)) ELSE piX).
        stamp:DrawTo(mCanvas, x, piY).
    END METHOD.

END CLASS.
