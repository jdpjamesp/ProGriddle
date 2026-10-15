/* Draws Snake in the "Lantern Glass" look (docs/design/snake-art.md). It reads a SnakeGame, never changes it, and paints the
   picture on a pixel canvas of its own: a strip of numbers above the board, then the board, a checkerboard of two close
   floor colours with the snake, the food and a wall ring over the outermost pixels. The canvas is handed to the window's
   renderer (the inner one), so the game's own grid, with its view codes and tests, is left as it is.

   The size follows the board: a cell is a tile of 16 pixels on boards up to 20 cells across and of 8 pixels on bigger ones, and
   when the game's board changes size the painter starts again at the new size.

   What is kept in the picture's background: the floor, the wall ring, the strip, and the snake's body and tail. A step
   changes four tiles (the floor where the tail was, the old head, which is now body, and the new tail), so only those are
   redrawn. What is drawn every frame: the food, the head, the effects and the wall ring over the cells they touch.

   The painter owns canvases and stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakePainter FINAL IMPLEMENTS IGridRenderer:

    /* the number of dresses, parts and quarter turns a stamp is looked up by */
    &SCOPED-DEFINE DRESSES 9
    &SCOPED-DEFINE PARTS 5

    DEFINE PRIVATE VARIABLE mInner     AS IGridRenderer   NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom    AS IRandom         NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame      AS SnakeGame       NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid      AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mBaseGrid  AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBase      AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mText      AS TextStampCache  NO-UNDO.
    /* the snake in each dress, part and turn, made when first needed: ((dress * 5) + part) * 4 + turn + 1 */
    DEFINE PRIVATE VARIABLE mStamp     AS PixelStamp      NO-UNDO EXTENT 180.
    DEFINE PRIVATE VARIABLE mFood      AS PixelStamp      NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mFloorA    AS PixelStamp      NO-UNDO.
    DEFINE PRIVATE VARIABLE mFloorB    AS PixelStamp      NO-UNDO.
    /* the board in cells, the tile in pixels, the strip above the board and the whole picture in pixels */
    DEFINE PRIVATE VARIABLE mCols      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mRows      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mTile      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mStrip     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight    AS INTEGER         NO-UNDO.
    /* what is baked into the background: the snake of which game, at which step, how long, and where its tail was */
    DEFINE PRIVATE VARIABLE mBakedSerial AS INTEGER       NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mBakedGen    AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mBakedLength AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mBakedTailX  AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mBakedTailY  AS INTEGER       NO-UNDO.
    /* what the strip was drawn from, so it is drawn again only when a number or a blink changes */
    DEFINE PRIVATE VARIABLE mHudKey      AS CHARACTER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed    AS LOGICAL       NO-UNDO.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* The size of a tile in pixels (16 or 8), and the height of the strip above the board. */
    DEFINE PUBLIC PROPERTY TileSize AS INTEGER NO-UNDO
        GET():
            RETURN mTile.
        END GET.

    DEFINE PUBLIC PROPERTY StripHeight AS INTEGER NO-UNDO
        GET():
            RETURN mStrip.
        END GET.

    /* poRandom is for the effects. Throws GridException for no renderer, no game or no random source. */
    CONSTRUCTOR PUBLIC SnakePainter(INPUT poInner AS IGridRenderer, INPUT poGame AS SnakeGame, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Snake painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Snake painter needs a game").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Snake painter needs a random source").
        mInner = poInner.
        mRandom = poRandom.
        mGame = poGame.
        mText = NEW TextStampCache(64).
        BuildFor(poGame:Grid:Width, poGame:Grid:Height).
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC SnakePainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not
       a Snake game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, SnakeGame) THEN UNDO, THROW NEW GridException("A Snake painter draws a Snake game").
        IF mGame:Grid:Width <> mCols OR mGame:Grid:Height <> mRows THEN BuildFor(mGame:Grid:Width, mGame:Grid:Height).
        SyncBody().
        SyncHud().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawFood().
        DrawHead().
        mCanvas:EndBatch().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvases and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        ReleaseSize().
        IF VALID-OBJECT(mText) THEN mText:Dispose().
    END METHOD.

    /* ================================ the size ================================ */

    /* Frees what depends on the size of the board. */
    METHOD PRIVATE VOID ReleaseSize():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO EXTENT(mStamp):
            IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
            mStamp[i] = ?.
        END.
        DO i = 1 TO EXTENT(mFood):
            IF VALID-OBJECT(mFood[i]) THEN mFood[i]:Dispose().
            mFood[i] = ?.
        END.
        IF VALID-OBJECT(mFloorA) THEN mFloorA:Dispose().
        IF VALID-OBJECT(mFloorB) THEN mFloorB:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mBase) THEN mBase:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        IF VALID-OBJECT(mBaseGrid) THEN mBaseGrid:Dispose().
        mFloorA = ?.
        mFloorB = ?.
        mCanvas = ?.
        mBase = ?.
        mGrid = ?.
        mBaseGrid = ?.
    END METHOD.

    /* Makes the canvases for a board of piCols x piRows cells and draws the base. */
    METHOD PRIVATE VOID BuildFor(INPUT piCols AS INTEGER, INPUT piRows AS INTEGER):
        DEFINE VARIABLE colours AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        ReleaseSize().
        ASSIGN mCols = piCols
               mRows = piRows
               mTile = (IF piCols <= 20 THEN 16 ELSE 8)
               mWidth = piCols * mTile
               mStrip = (IF mWidth >= 320 THEN 32 ELSE 24)
               mHeight = mStrip + piRows * mTile
               mBakedSerial = -1
               mHudKey = "".
        mGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mBaseGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mBase = NEW PixelCanvas(mBaseGrid).
        EXTENT(colours) = mTile * mTile.
        DO i = 1 TO mTile * mTile:
            colours[i] = SnakeLook:Colour(SnakeTint:FloorA).
        END.
        mFloorA = NEW PixelStamp(mTile, mTile, colours).
        DO i = 1 TO mTile * mTile:
            colours[i] = SnakeLook:Colour(SnakeTint:FloorB).
        END.
        mFloorB = NEW PixelStamp(mTile, mTile, colours).
        BuildBase().
    END METHOD.

    /* The strip, the floor and the wall ring, drawn on the base canvas and kept. */
    METHOD PRIVATE VOID BuildBase():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        mBase:BeginBatch().
        DO y = 0 TO mStrip - 1:
            mBase:DrawLine(0, y, mWidth - 1, y, 0, SnakeLook:Colour(SnakeTint:NightTop)).
        END.
        /* the rule under the strip: two pixels on a wide board and one on a narrow one */
        DO y = (IF mStrip = 32 THEN mStrip - 2 ELSE mStrip - 1) TO mStrip - 1:
            mBase:DrawLine(0, y, mWidth - 1, y, 0, SnakeLook:Colour(SnakeTint:FrameInner)).
        END.
        DO y = 0 TO mRows - 1:
            DO x = 0 TO mCols - 1:
                IF (x + y) MODULO 2 = 0 THEN mFloorA:DrawTo(mBase, x * mTile, mStrip + y * mTile).
                ELSE mFloorB:DrawTo(mBase, x * mTile, mStrip + y * mTile).
            END.
        END.
        /* the wall ring: the outer row in the high colour and, on a big tile, the next row in the low colour, then a lamp in each corner */
        t = (IF mTile = 16 THEN 2 ELSE 1).
        DO k = 0 TO t - 1:
            IF k = 0 THEN x = SnakeLook:Colour(SnakeTint:RingHigh).
            ELSE x = SnakeLook:Colour(SnakeTint:RingLow).
            mBase:DrawLine(k, mStrip + k, mWidth - 1 - k, mStrip + k, 0, x).
            mBase:DrawLine(k, mHeight - 1 - k, mWidth - 1 - k, mHeight - 1 - k, 0, x).
            mBase:DrawLine(k, mStrip + k, k, mHeight - 1 - k, 0, x).
            mBase:DrawLine(mWidth - 1 - k, mStrip + k, mWidth - 1 - k, mHeight - 1 - k, 0, x).
        END.
        DO y = 0 TO t - 1:
            mBase:DrawLine(0, mStrip + y, t - 1, mStrip + y, 0, SnakeLook:Colour(SnakeTint:Lamp)).
            mBase:DrawLine(mWidth - t, mStrip + y, mWidth - 1, mStrip + y, 0, SnakeLook:Colour(SnakeTint:Lamp)).
            mBase:DrawLine(0, mHeight - 1 - y, t - 1, mHeight - 1 - y, 0, SnakeLook:Colour(SnakeTint:Lamp)).
            mBase:DrawLine(mWidth - t, mHeight - 1 - y, mWidth - 1, mHeight - 1 - y, 0, SnakeLook:Colour(SnakeTint:Lamp)).
        END.
        mBase:EndBatch().
        mBase:BakeView().
        mCanvas:LoadBack(mBase).
    END METHOD.

    /* ================================ the wall ring ================================ */

    /* The colour of the wall ring at a pixel of the board (0, 0 is the board's top left), or -1 where there is none. */
    METHOD PRIVATE INTEGER RingColour(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE d AS INTEGER NO-UNDO.
        t = (IF mTile = 16 THEN 2 ELSE 1).
        IF (piX < t OR piX >= mCols * mTile - t) AND (piY < t OR piY >= mRows * mTile - t) THEN RETURN SnakeLook:Colour(SnakeTint:Lamp).
        d = MINIMUM(MINIMUM(piX, piY), MINIMUM(mCols * mTile - 1 - piX, mRows * mTile - 1 - piY)).
        IF d = 0 THEN RETURN SnakeLook:Colour(SnakeTint:RingHigh).
        IF d = 1 AND mTile = 16 THEN RETURN SnakeLook:Colour(SnakeTint:RingLow).
        RETURN -1.
    END METHOD.

    /* Draws the wall ring again over a cell, if it is on the edge of the board: the wall is the last thing drawn, over the
       snake, so whatever has just been drawn there gives way to it. The canvas must be in a batch. */
    METHOD PRIVATE VOID RingCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        IF piX > 0 AND piX < mCols - 1 AND piY > 0 AND piY < mRows - 1 THEN RETURN.
        DO y = 0 TO mTile - 1:
            DO x = 0 TO mTile - 1:
                c = RingColour(piX * mTile + x, piY * mTile + y).
                IF c >= 0 THEN mCanvas:DrawLine(piX * mTile + x, mStrip + piY * mTile + y, piX * mTile + x, mStrip + piY * mTile + y, 0, c).
            END.
        END.
    END METHOD.

    /* ================================ the stamps ================================ */

    /* The tones of a part of the snake in a dress, five hex colours separated by commas. */
    METHOD PRIVATE CHARACTER TonesFor(INPUT piDress AS INTEGER, INPUT piPart AS INTEGER):
        DEFINE VARIABLE isHead AS LOGICAL NO-UNDO.
        isHead = piPart <= INTEGER(SnakePart:HeadTongue).
        IF piDress = INTEGER(SnakeDress:Normal) THEN DO:
            IF isHead THEN RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:HeadBase)).
            IF piPart = INTEGER(SnakePart:Tail) THEN RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:TailBase)).
            RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:BodyBase)).
        END.
        IF piDress = INTEGER(SnakeDress:Flash) THEN RETURN SnakeLook:FlashTones().
        IF piDress = INTEGER(SnakeDress:Bright) THEN DO:
            IF isHead THEN RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:HeadBase)).
            RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:BodyBright)).
        END.
        IF piDress = INTEGER(SnakeDress:Gold) THEN RETURN SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Gold)).
        RETURN SnakeLook:CrashTones(piDress - INTEGER(SnakeDress:Crash1) + 1).
    END METHOD.

    /* The legend of the named colours a tile can have: the eye, the pupil, the tongue, the stem, the leaf and white. */
    METHOD PRIVATE CHARACTER Legend():
        RETURN SUBSTITUTE("A=&1,B=&2,T=&3,S=&4,G=&5,W=FFFFFF", SnakeLook:Hex(SnakeTint:Eye), SnakeLook:Hex(SnakeTint:Pupil), SnakeLook:Hex(SnakeTint:Tongue),
                          SnakeLook:Hex(SnakeTint:Stem), SnakeLook:Hex(SnakeTint:Leaf)).
    END METHOD.

    /* The tile of a part, turned. The straight piece is the same when turned twice, so it only has two turns. */
    METHOD PRIVATE Tile PartTile(INPUT piPart AS INTEGER, INPUT piTurns AS INTEGER):
        DEFINE VARIABLE tile0 AS Tile NO-UNDO.
        IF piPart = INTEGER(SnakePart:Head) THEN tile0 = SnakeArt:Head(mTile).
        ELSE IF piPart = INTEGER(SnakePart:HeadTongue) THEN tile0 = SnakeArt:HeadTongue(mTile).
        ELSE IF piPart = INTEGER(SnakePart:Straight) THEN tile0 = SnakeArt:BodyStraight(mTile).
        ELSE IF piPart = INTEGER(SnakePart:Corner) THEN tile0 = SnakeArt:BodyCorner(mTile).
        ELSE tile0 = SnakeArt:Tail(mTile).
        RETURN (IF piTurns = 0 THEN tile0 ELSE tile0:Turned(piTurns)).
    END METHOD.

    /* The stamp of a part of the snake in a dress and a turn, made the first time it is asked for. */
    METHOD PRIVATE PixelStamp Dressed(INPUT piDress AS INTEGER, INPUT piPart AS INTEGER, INPUT piTurns AS INTEGER):
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        slot = (piDress * {&PARTS} + piPart) * 4 + piTurns + 1.
        IF NOT VALID-OBJECT(mStamp[slot]) THEN mStamp[slot] = PartTile(piPart, piTurns):Colourise(TonesFor(piDress, piPart), Legend()).
        RETURN mStamp[slot].
    END METHOD.

    /* A frame of the food, 0 to 3, made the first time it is asked for. */
    METHOD PRIVATE PixelStamp FoodStamp(INPUT piFrame AS INTEGER):
        IF NOT VALID-OBJECT(mFood[piFrame + 1]) THEN
            mFood[piFrame + 1] = SnakeArt:Food(mTile, piFrame):Colourise(SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Apple)), Legend()).
        RETURN mFood[piFrame + 1].
    END METHOD.

    /* ================================ the snake ================================ */

    /* Which side of one cell another cell is on, 0 up, 1 right, 2 down, 3 left, as the game numbers its directions. */
    METHOD PRIVATE INTEGER SideOf(INPUT piFromX AS INTEGER, INPUT piFromY AS INTEGER, INPUT piToX AS INTEGER, INPUT piToY AS INTEGER):
        IF piToY < piFromY THEN RETURN 0.
        IF piToX > piFromX THEN RETURN 1.
        IF piToY > piFromY THEN RETURN 2.
        RETURN 3.
    END METHOD.

    /* The quarter turns the head needs to face the way it is going: it faces away from the cell behind it, and a snake of one
       cell takes its body to be on the west, so it faces east. The tile is drawn facing east. */
    METHOD PRIVATE INTEGER HeadTurns():
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE behind AS INTEGER NO-UNDO.
        n = mGame:Length.
        behind = (IF n < 2 THEN 3 ELSE SideOf(mGame:BodyX(n - 1), mGame:BodyY(n - 1), mGame:BodyX(n - 2), mGame:BodyY(n - 2))).
        RETURN ((behind + 2) MODULO 4 + 3) MODULO 4.
    END METHOD.

    /* Draws a cell of the body or the tail (index 0 is the tail) in a dress on the canvas, turned to join its neighbours, which
       are the cells either side of it in the snake. Not the head. */
    METHOD PRIVATE VOID DrawBodyCell(INPUT piIndex AS INTEGER, INPUT piDress AS INTEGER):
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE a    AS INTEGER NO-UNDO.
        DEFINE VARIABLE b    AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo   AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi   AS INTEGER NO-UNDO.
        DEFINE VARIABLE part AS INTEGER NO-UNDO.
        DEFINE VARIABLE turn AS INTEGER NO-UNDO.
        x = mGame:BodyX(piIndex).
        y = mGame:BodyY(piIndex).
        IF piIndex = 0 THEN DO:
            /* the tail's body is on the west when it is drawn, and each quarter turn takes it round the clock: west, north, east, south */
            a = SideOf(x, y, mGame:BodyX(1), mGame:BodyY(1)).
            part = INTEGER(SnakePart:Tail).
            turn = (a + 1) MODULO 4.
        END.
        ELSE DO:
            a = SideOf(x, y, mGame:BodyX(piIndex - 1), mGame:BodyY(piIndex - 1)).
            b = SideOf(x, y, mGame:BodyX(piIndex + 1), mGame:BodyY(piIndex + 1)).
            IF (a + 2) MODULO 4 = b THEN DO:
                part = INTEGER(SnakePart:Straight).
                turn = (IF a = 1 OR a = 3 THEN 0 ELSE 1).
            END.
            ELSE DO:
                part = INTEGER(SnakePart:Corner).
                lo = MINIMUM(a, b).
                hi = MAXIMUM(a, b).
                /* east and south as drawn, then south and west, north and west, north and east */
                IF lo = 1 AND hi = 2 THEN turn = 0.
                ELSE IF lo = 2 AND hi = 3 THEN turn = 1.
                ELSE IF lo = 0 AND hi = 3 THEN turn = 2.
                ELSE turn = 3.
            END.
        END.
        Dressed(piDress, part, turn):DrawTo(mCanvas, x * mTile, mStrip + y * mTile).
        RingCell(x, y).
    END METHOD.

    /* Brings the snake that is baked into the picture up to date: a step changes the floor where the tail was, the old head
       (now body) and the tail, and anything else (a new game, a new board size, steps that were not seen) makes it again. */
    METHOD PRIVATE VOID SyncBody():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        n = mGame:Length.
        IF mGame:GameSerial = mBakedSerial AND mGame:Generation = mBakedGen AND n = mBakedLength THEN RETURN.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        IF mGame:GameSerial = mBakedSerial AND mGame:Generation = mBakedGen + 1 AND (n = mBakedLength OR n = mBakedLength + 1) THEN DO:
            IF n = mBakedLength THEN FloorAt(mBakedTailX, mBakedTailY).
            IF n >= 2 THEN DO:
                DrawBodyCell(n - 2, INTEGER(SnakeDress:Normal)).
                DrawBodyCell(0, INTEGER(SnakeDress:Normal)).
            END.
            mCanvas:EndBatch().
        END.
        ELSE DO:
            mCanvas:EndBatch().
            mCanvas:LoadBack(mBase).
            mCanvas:Restore().
            mCanvas:BeginBatch().
            DO i = 0 TO n - 2:
                DrawBodyCell(i, INTEGER(SnakeDress:Normal)).
            END.
            mCanvas:EndBatch().
            mHudKey = "".
        END.
        mCanvas:BakeView().
        ASSIGN mBakedSerial = mGame:GameSerial
               mBakedGen = mGame:Generation
               mBakedLength = n
               mBakedTailX = mGame:BodyX(0)
               mBakedTailY = mGame:BodyY(0).
    END METHOD.

    /* The empty floor of a cell, with the wall ring over it if it is on the edge. */
    METHOD PRIVATE VOID FloorAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF (piX + piY) MODULO 2 = 0 THEN mFloorA:DrawTo(mCanvas, piX * mTile, mStrip + piY * mTile).
        ELSE mFloorB:DrawTo(mCanvas, piX * mTile, mStrip + piY * mTile).
        RingCell(piX, piY).
    END METHOD.

    /* True while the tongue is out: 100 ms in every 600 while it moves and in every 400 while it waits for a key. */
    METHOD PRIVATE LOGICAL TongueOut():
        IF mGame:IsOver OR mGame:Paused THEN RETURN FALSE.
        IF mGame:Waiting THEN RETURN mGame:ElapsedMs MODULO 400 < 100.
        RETURN mGame:ElapsedMs MODULO 600 < 100.
    END METHOD.

    /* The head, with its tongue when it is out, turned to face the way it is going. */
    METHOD PRIVATE VOID DrawHead():
        DEFINE VARIABLE part  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dress AS INTEGER NO-UNDO.
        part = (IF TongueOut() THEN INTEGER(SnakePart:HeadTongue) ELSE INTEGER(SnakePart:Head)).
        dress = INTEGER(SnakeDress:Normal).
        Dressed(dress, part, HeadTurns()):DrawTo(mCanvas, mGame:HeadX * mTile, mStrip + mGame:HeadY * mTile).
        RingCell(mGame:HeadX, mGame:HeadY).
    END METHOD.

    /* ================================ the food ================================ */

    /* The food: a pulse of four frames of 120 ms (0 1 2 1) with the glint in place of the first of every fourth round, and
       for the first 150 ms after it appears a small apple that grows. */
    METHOD PRIVATE VOID DrawFood():
        DEFINE VARIABLE fno AS INTEGER NO-UNDO.
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        IF mGame:FoodX < 0 THEN RETURN.
        age = mGame:ElapsedMs - mGame:FoodMs.
        IF mGame:FoodMs >= 0 AND age >= 0 AND age < 150 THEN DO:
            Grow(mGame:FoodX, mGame:FoodY, INTEGER(TRUNCATE(age / 50, 0))).
            RETURN.
        END.
        fno = INTEGER(ENTRY(INTEGER(TRUNCATE(mGame:ElapsedMs / 120, 0)) MODULO 4 + 1, "0,1,2,1")).
        IF fno = 0 AND INTEGER(TRUNCATE(mGame:ElapsedMs / 480, 0)) MODULO 4 = 3 THEN fno = 3.
        FoodStamp(fno):DrawTo(mCanvas, mGame:FoodX * mTile, mStrip + mGame:FoodY * mTile).
        RingCell(mGame:FoodX, mGame:FoodY).
    END METHOD.

    /* A young apple: a disc in the apple colour with a dark edge and a light spot, of radius 2, 4 and 5.5 pixels in the three
       steps of its growth (1, 2 and 2.6 on the small tile). */
    METHOD PRIVATE VOID Grow(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piStep AS INTEGER):
        DEFINE VARIABLE radius AS DECIMAL   NO-UNDO.
        DEFINE VARIABLE dx     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dy     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE d      AS DECIMAL   NO-UNDO.
        DEFINE VARIABLE tones  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE half   AS DECIMAL   NO-UNDO.
        tones = SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Apple)).
        radius = DECIMAL(ENTRY(MINIMUM(piStep, 2) + 1, "2,4,5.5")) * mTile / 16.
        half = mTile / 2 - 0.5.
        DO dy = 0 TO mTile - 1:
            DO dx = 0 TO mTile - 1:
                d = SQRT((dx - half) * (dx - half) + (dy - half) * (dy - half)).
                IF d > radius THEN NEXT.
                c = ColourMath:FromHex(ENTRY((IF d > radius - 1 THEN 5 ELSE IF dx < half - radius / 3 AND dy < half - radius / 3 THEN 1 ELSE 3), tones)).
                mCanvas:DrawLine(piX * mTile + dx, mStrip + piY * mTile + dy, piX * mTile + dx, mStrip + piY * mTile + dy, 0, c).
            END.
        END.
        RingCell(piX, piY).
    END METHOD.

    /* ================================ the strip ================================ */

    /* True when the score is over the best from before this game. */
    METHOD PRIVATE LOGICAL NewBest():
        RETURN mGame:Score > mGame:BestScore.
    END METHOD.

    /* True while the BEST label shows NEW BEST: always once the game is over, and blinking 300 ms on and 300 off while it goes. */
    METHOD PRIVATE LOGICAL NewBestShown():
        IF NOT NewBest() THEN RETURN FALSE.
        IF mGame:IsOver THEN RETURN TRUE.
        RETURN INTEGER(TRUNCATE(mGame:ElapsedMs / 300, 0)) MODULO 2 = 0.
    END METHOD.

    /* True for 300 ms after the food is eaten: the score shows in gold. */
    METHOD PRIVATE LOGICAL ScorePulse():
        IF mGame:LastEatMs < 0 THEN RETURN FALSE.
        RETURN mGame:ElapsedMs >= mGame:LastEatMs AND mGame:ElapsedMs - mGame:LastEatMs < 300.
    END METHOD.

    /* Draws the strip into the background again when something in it has changed. */
    METHOD PRIVATE VOID SyncHud():
        DEFINE VARIABLE hudKey AS CHARACTER NO-UNDO.
        hudKey = SUBSTITUTE("&1|&2|&3|&4|&5|&6|&7", mGame:Score, mGame:Length, mGame:Level, mGame:BestScore, NewBest(), NewBestShown(), ScorePulse()).
        IF hudKey = mHudKey THEN RETURN.
        mHudKey = hudKey.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawHud().
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    /* The four stats of the strip: SCORE, LENGTH, LEVEL and BEST, each a label and a value, in four equal columns. A wide board
       has the values at twice the size, a narrow one at the size of the labels. */
    METHOD PRIVATE VOID DrawHud():
        DEFINE VARIABLE wide   AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE heading  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE shown  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hue    AS SnakeTint NO-UNDO.
        DEFINE VARIABLE labelHue AS SnakeTint NO-UNDO.
        wide = mStrip = 32.
        /* clear the strip above its rule */
        DO y = 0 TO (IF wide THEN mStrip - 3 ELSE mStrip - 2):
            mCanvas:DrawLine(0, y, mWidth - 1, y, 0, SnakeLook:Colour(SnakeTint:NightTop)).
        END.
        DO k = 0 TO 3:
            x = (IF wide THEN 8 + 80 * k ELSE 4 + k * INTEGER(TRUNCATE(mWidth / 4, 0))).
            labelHue = SnakeTint:Label.
            CASE k:
                WHEN 0 THEN ASSIGN heading = "SCORE" shown = STRING(mGame:Score) hue = (IF ScorePulse() THEN SnakeTint:Gold ELSE SnakeTint:Text).
                WHEN 1 THEN ASSIGN heading = "LENGTH" shown = STRING(mGame:Length) hue = SnakeTint:Text.
                WHEN 2 THEN ASSIGN heading = "LEVEL" shown = STRING(mGame:Level) hue = SnakeTint:Accent.
                OTHERWISE DO:
                    heading = "BEST".
                    shown = STRING(MAXIMUM(mGame:BestScore, mGame:Score)).
                    hue = (IF NewBest() THEN SnakeTint:Gold ELSE SnakeTint:Dim).
                    IF NewBestShown() THEN ASSIGN heading = (IF wide THEN "NEW BEST" ELSE "NEW") labelHue = SnakeTint:Gold.
                END.
            END CASE.
            Caption(heading, 1, labelHue, x, 4).
            IF wide THEN Caption(shown, 2, hue, x, 14).
            ELSE Caption(shown, 1, hue, x, 13).
        END.
    END METHOD.

    /* Some text at a place, one colour, no outline. */
    METHOD PRIVATE VOID Caption(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTint AS SnakeTint, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = SnakeLook:Colour(poTint).
        mText:Get(pcText, piScale, c, c, -1):DrawTo(mCanvas, piX, piY).
    END METHOD.

END CLASS.
