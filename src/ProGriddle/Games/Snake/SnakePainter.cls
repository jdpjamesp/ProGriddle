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
    DEFINE PRIVATE VARIABLE mSparks    AS SparkField      NO-UNDO.
    /* the game that the sparks of the ending were made for, and the one whose faded and dimmed board is baked into the background */
    DEFINE PRIVATE VARIABLE mSparkSerial AS INTEGER       NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mSparksMade  AS LOGICAL       NO-UNDO.
    DEFINE PRIVATE VARIABLE mOverSerial  AS INTEGER       NO-UNDO INITIAL -1.
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
        mSparks = NEW SparkField(64).
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
        SyncOver().
        SyncHud().
        MakeSparks().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        IF mOverSerial <> mGame:GameSerial THEN DrawFood().
        DrawWave().
        IF NOT CrashActive() THEN DrawHead(HeadDress()).
        DrawCrash().
        DrawWin().
        DrawEatRing().
        mSparks:Draw(mCanvas, mGame:ElapsedMs).
        DrawWaiting().
        DrawBanner().
        mCanvas:EndBatch().
        IF mGame:Paused AND NOT mGame:IsOver THEN DO:
            /* the board is dimmed once, with the batch closed, and then the plate and the words go on it */
            mCanvas:DimRect(0, mStrip, mWidth, mRows * mTile, 55, SnakeLook:Colour(SnakeTint:Shade)).
            mCanvas:BeginBatch().
            DrawPaused().
            mCanvas:EndBatch().
        END.
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
               mOverSerial = -1
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

    /* The dress of the head: white for 66 ms after it eats, else its own. */
    METHOD PRIVATE INTEGER HeadDress():
        IF EatAge() >= 0 AND EatAge() < 66 THEN RETURN INTEGER(SnakeDress:Flash).
        RETURN INTEGER(SnakeDress:Normal).
    END METHOD.

    /* The head in a dress, with its tongue when it is out, turned to face the way it is going. */
    METHOD PRIVATE VOID DrawHead(INPUT piDress AS INTEGER):
        DEFINE VARIABLE part AS INTEGER NO-UNDO.
        part = (IF TongueOut() THEN INTEGER(SnakePart:HeadTongue) ELSE INTEGER(SnakePart:Head)).
        Dressed(piDress, part, HeadTurns()):DrawTo(mCanvas, mGame:HeadX * mTile, mStrip + mGame:HeadY * mTile).
        RingCell(mGame:HeadX, mGame:HeadY).
    END METHOD.

    /* ================================ the end ================================ */

    /* True when the game has ended by a crash (not a win), from the moment it did. */
    METHOD PRIVATE LOGICAL CrashActive():
        RETURN mGame:IsOver AND NOT mGame:HasWon AND mGame:OverMs >= 0.
    END METHOD.

    /* Milliseconds since the game ended, or -1 while it goes. */
    METHOD PRIVATE INTEGER OverAge():
        IF NOT mGame:IsOver OR mGame:OverMs < 0 OR mGame:ElapsedMs < mGame:OverMs THEN RETURN -1.
        RETURN mGame:ElapsedMs - mGame:OverMs.
    END METHOD.

    /* The moment the body of a crash has faded to nothing, the board is made the way it stays: floor where the snake was, the food,
       and the whole board dimmed once (docs/design/snake-art.md 4.3). It goes into the background, so the frames that follow do
       not repeat the work. */
    METHOD PRIVATE VOID SyncOver():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        IF NOT CrashActive() OR mOverSerial = mGame:GameSerial OR OverAge() < 900 THEN RETURN.
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO k = 0 TO mGame:Length - 1:
            FloorAt(mGame:BodyX(k), mGame:BodyY(k)).
        END.
        DrawFood().
        mCanvas:EndBatch().
        mCanvas:DimRect(0, mStrip, mWidth, mRows * mTile, 55, SnakeLook:Colour(SnakeTint:Shade)).
        mCanvas:BakeView().
        mOverSerial = mGame:GameSerial.
    END METHOD.

    /* The sparks of an ending, made once for each game that ends: twelve flying out of the head in a crash, and in a win
       twenty four rising from random cells, one every 50 ms. They are worked out from the time, so they are made all at once. */
    METHOD PRIVATE VOID MakeSparks():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed  AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE gold   AS CHARACTER NO-UNDO.
        IF mGame:GameSerial <> mSparkSerial THEN DO:
            mSparks:Clear().
            mSparkSerial = mGame:GameSerial.
            mSparksMade = FALSE.
        END.
        IF mSparksMade OR NOT mGame:IsOver OR mGame:OverMs < 0 THEN RETURN.
        mSparksMade = TRUE.
        DO:
            gold = SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Gold)).
            IF mGame:HasWon THEN DO i = 0 TO 23:
                cx = mRandom:NextInt(mCols) * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
                cy = mStrip + mRandom:NextInt(mRows) * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
                mSparks:Add(cx, cy, 0.0, -0.5, 0.0, mGame:OverMs + 50 * i, 20,
                            SnakeLook:Colour(SnakeTint:Flash), ColourMath:FromHex(ENTRY(2, gold)), ColourMath:FromHex(ENTRY(3, gold)), SnakeLook:Colour(SnakeTint:Accent)).
            END.
            ELSE DO i = 0 TO 11:
                speed = (0.6 + 0.2 * (i MODULO 3)) * mTile / 16.
                cx = mGame:HeadX * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
                cy = mStrip + mGame:HeadY * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
                mSparks:AddDragged(cx, cy, speed * DECIMAL(ENTRY(i + 1, "1,0.866,0.5,0,-0.5,-0.866,-1,-0.866,-0.5,0,0.5,0.866")),
                                   speed * DECIMAL(ENTRY(i + 1, "0,0.5,0.866,1,0.866,0.5,0,-0.5,-0.866,-1,-0.866,-0.5")), 0.0, 0.97, mGame:OverMs, 18,
                                   SnakeLook:Colour(SnakeTint:Flash), ColourMath:FromHex(ENTRY(2, gold)), SnakeLook:Colour(SnakeTint:Accent), SnakeLook:Colour(SnakeTint:Apple)).
            END.
        END.
    END METHOD.

    /* The crash (3.4): the whole snake flashes white three times in 360 ms, then fades out from the tail to the head, each cell going
       through five steps of 60 ms, the starts spread over 240 ms. The head is drawn here too, since it is part of the fade. */
    METHOD PRIVATE VOID DrawCrash():
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE begin AS INTEGER NO-UNDO.
        DEFINE VARIABLE step  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dress AS INTEGER NO-UNDO.
        IF NOT CrashActive() OR mOverSerial = mGame:GameSerial THEN RETURN.
        age = OverAge().
        IF age < 0 THEN RETURN.
        n = mGame:Length.
        IF age < 360 THEN DO:
            IF INTEGER(TRUNCATE(age / 60, 0)) MODULO 2 = 0 THEN DO:
                DO k = 0 TO n - 2:
                    DrawBodyCell(k, INTEGER(SnakeDress:Flash)).
                END.
                DrawHead(INTEGER(SnakeDress:Flash)).
            END.
            ELSE DrawHead(INTEGER(SnakeDress:Normal)).
            RETURN.
        END.
        DO k = 0 TO n - 1:
            begin = 360 + (IF n > 1 THEN INTEGER(TRUNCATE(240 * k / (n - 1), 0)) ELSE 0).
            IF age < begin THEN DO:
                IF k = n - 1 THEN DrawHead(INTEGER(SnakeDress:Normal)).
                NEXT.
            END.
            step = INTEGER(TRUNCATE((age - begin) / 60, 0)) + 1.
            IF step > 5 THEN DO:
                FloorAt(mGame:BodyX(k), mGame:BodyY(k)).
                NEXT.
            END.
            dress = INTEGER(SnakeDress:Crash1) + step - 1.
            IF k = n - 1 THEN DrawHead(dress).
            ELSE DrawBodyCell(k, dress).
        END.
    END METHOD.

    /* The win (3.5): a gold wave runs from the head to the tail twice in 1200 ms, each cell gold for 90 ms, one lap taking 600 ms
       however long the snake is. */
    METHOD PRIVATE VOID DrawWin():
        DEFINE VARIABLE age AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE lap AS INTEGER NO-UNDO.
        DEFINE VARIABLE m   AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo  AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi  AS INTEGER NO-UNDO.
        IF NOT mGame:HasWon THEN RETURN.
        age = OverAge().
        IF age < 0 OR age >= 1200 THEN RETURN.
        n = mGame:Length.
        DO lap = 0 TO 1:
            IF age < lap * 600 THEN NEXT.
            hi = MINIMUM(n - 1, INTEGER(TRUNCATE((age - lap * 600) * n / 600, 0))).
            lo = MAXIMUM(0, INTEGER(TRUNCATE((age - lap * 600 - 90) * n / 600, 0)) + (IF age - lap * 600 < 90 THEN 0 ELSE 1)).
            DO m = lo TO hi:
                IF m = 0 THEN DrawHead(INTEGER(SnakeDress:Gold)).
                ELSE DrawBodyCell(n - 1 - m, INTEGER(SnakeDress:Gold)).
            END.
        END.
    END METHOD.

    /* The plate of an ending (4.3 and 4.4): it opens from the middle line in four steps of 50 ms, and when it is open it shows the
       title, the score and length, NEW BEST (blinking, if the best was beaten) and PRESS R. */
    METHOD PRIVATE VOID DrawBanner():
        DEFINE VARIABLE age    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE begin  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE steps  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE h      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE middle AS INTEGER   NO-UNDO.
        DEFINE VARIABLE scores AS CHARACTER NO-UNDO.
        DEFINE VARIABLE won    AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE titleY AS INTEGER   NO-UNDO.
        age = OverAge().
        IF age < 0 THEN RETURN.
        won = mGame:HasWon.
        begin = (IF won THEN 1200 ELSE 900).
        IF age < begin THEN RETURN.
        middle = mStrip + INTEGER(TRUNCATE(mRows * mTile / 2, 0)).
        steps = INTEGER(ENTRY(MINIMUM(3, INTEGER(TRUNCATE((age - begin) / 50, 0))) + 1, (IF won THEN "2,28,56,84" ELSE "2,20,44,68"))).
        h = steps.
        Plate(0, middle - INTEGER(TRUNCATE(h / 2, 0)), mWidth, h, SnakeTint:Accent, 2).
        IF age < begin + 150 THEN RETURN.
        scores = SUBSTITUTE("SCORE &1   LENGTH &2", mGame:Score, mGame:Length).
        IF won THEN DO:
            Outlined("YOU WIN", 3, SnakeTint:Gold, SnakeTint:Accent, Centred(PixelCanvas:ScaledWidth("YOU WIN", 3)), middle - 34).
            Caption(scores, 1, SnakeTint:Dim, Centred(PixelCanvas:ScaledWidth(scores, 1)), middle + 4).
            titleY = middle + 16.
        END.
        ELSE DO:
            Outlined("GAME OVER", 2, SnakeTint:OverTop, SnakeTint:OverBottom, Centred(PixelCanvas:ScaledWidth("GAME OVER", 2)), middle - 24).
            Caption(scores, 1, SnakeTint:Dim, Centred(PixelCanvas:ScaledWidth(scores, 1)), middle - 2).
            titleY = middle + 10.
        END.
        IF NewBest() AND (age >= 3600 OR INTEGER(TRUNCATE(age / 300, 0)) MODULO 2 = 0) THEN
            Caption("NEW BEST", 1, SnakeTint:Gold, Centred(PixelCanvas:ScaledWidth("NEW BEST", 1)), titleY).
        Caption("PRESS R", 1, SnakeTint:Text, Centred(PixelCanvas:ScaledWidth("PRESS R", 1)), (IF won THEN middle + 28 ELSE middle + 22)).
    END METHOD.

    /* ================================ eating ================================ */

    /* Milliseconds since the food was last eaten, or -1 when it has not been in this game. */
    METHOD PRIVATE INTEGER EatAge():
        IF mGame:LastEatMs < 0 OR mGame:ElapsedMs < mGame:LastEatMs THEN RETURN -1.
        RETURN mGame:ElapsedMs - mGame:LastEatMs.
    END METHOD.

    /* The wave that runs down the body after the food is eaten (docs/design/snake-art.md 3.3): from the cell behind the head, one
       cell every 30 ms, each in the brighter body colour for 90 ms, so three are lit at once. */
    METHOD PRIVATE VOID DrawWave():
        DEFINE VARIABLE age AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo  AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi  AS INTEGER NO-UNDO.
        age = EatAge().
        IF age < 0 THEN RETURN.
        hi = INTEGER(TRUNCATE(age / 30, 0)).
        lo = (IF age < 90 THEN 0 ELSE INTEGER(TRUNCATE((age - 90) / 30, 0)) + 1).
        DO j = lo TO hi:
            IF mGame:Length - 2 - j < 0 THEN LEAVE.
            DrawBodyCell(mGame:Length - 2 - j, INTEGER(SnakeDress:Bright)).
        END.
    END METHOD.

    /* The ring of eight pixels that spreads from the cell where the food was eaten: six steps of 33 ms, the radius growing 1.2 pixels
       a step (0.6 on a small tile), white and then the five tones of the apple. */
    METHOD PRIVATE VOID DrawEatRing():
        DEFINE VARIABLE age    AS INTEGER NO-UNDO.
        DEFINE VARIABLE f      AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        DEFINE VARIABLE radius AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE px     AS INTEGER NO-UNDO.
        DEFINE VARIABLE py     AS INTEGER NO-UNDO.
        age = EatAge().
        IF age < 0 OR age >= 198 THEN RETURN.
        f = INTEGER(TRUNCATE(age / 33, 0)).
        c = (IF f = 0 THEN SnakeLook:Colour(SnakeTint:Flash) ELSE ColourMath:FromHex(ENTRY(f, SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Apple))))).
        radius = (IF mTile = 16 THEN 3 + 1.2 * f ELSE 1.5 + 0.6 * f).
        cx = mGame:LastEatX * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
        cy = mStrip + mGame:LastEatY * mTile + INTEGER(TRUNCATE(mTile / 2, 0)).
        DO k = 1 TO 8:
            px = cx + INTEGER(ROUND(radius * DECIMAL(ENTRY(k, "1,0.7071,0,-0.7071,-1,-0.7071,0,0.7071")), 0)).
            py = cy + INTEGER(ROUND(radius * DECIMAL(ENTRY(k, "0,0.7071,1,0.7071,0,-0.7071,-1,-0.7071")), 0)).
            mCanvas:DrawLine(px, py, px, py, 0, c).
        END.
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

    /* ================================ plates and words ================================ */

    /* A plate: a rectangle filled with the gap colour, with a rule of piRules rows in a colour on its top and bottom edges. The
       canvas must be in a batch. */
    METHOD PRIVATE VOID Plate(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT poRule AS SnakeTint, INPUT piRules AS INTEGER):
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO j = 0 TO piH - 1:
            mCanvas:DrawLine(piX, piY + j, piX + piW - 1, piY + j, 0,
                             (IF j < piRules OR j >= piH - piRules THEN SnakeLook:Colour(poRule) ELSE SnakeLook:Colour(SnakeTint:Gap))).
        END.
    END METHOD.

    /* The x of some text of piWidth pixels that is centred across the picture. */
    METHOD PRIVATE INTEGER Centred(INPUT piWidth AS INTEGER):
        RETURN INTEGER(TRUNCATE((mWidth - piWidth) / 2, 0)).
    END METHOD.

    /* Text in the board with a one pixel outline behind it. */
    METHOD PRIVATE VOID Outlined(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTop AS SnakeTint, INPUT poBottom AS SnakeTint, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mText:Get(pcText, piScale, SnakeLook:Colour(poTop), SnakeLook:Colour(poBottom), SnakeLook:Colour(SnakeTint:Outline)):DrawTo(mCanvas, piX, piY).
    END METHOD.

    /* While the snake waits for the first key (4.2): a plate a quarter of the way down the board with PRESS AN ARROW KEY blinking
       500 ms on and 300 off, and an arrow beside the head, which blinks with it, showing the way it will go. */
    METHOD PRIVATE VOID DrawWaiting():
        DEFINE VARIABLE words AS CHARACTER NO-UNDO INITIAL "PRESS AN ARROW KEY".
        DEFINE VARIABLE w     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE arrow AS CHARACTER NO-UNDO.
        IF NOT mGame:Waiting OR mGame:IsOver THEN RETURN.
        w = PixelCanvas:ScaledWidth(words, 1).
        y = mStrip + INTEGER(TRUNCATE(mRows * mTile / 4, 0)).
        Plate(Centred(w) - 8, y - 8, w + 16, 23, SnakeTint:FrameOuter, 1).
        IF mGame:ElapsedMs MODULO 800 >= 500 THEN RETURN.
        Caption(words, 1, SnakeTint:Text, Centred(w), y).
        /* the arrow, four pixels on from the head's cell, in the middle of its height */
        arrow = "1000/1100/0110/0011/0110/1100/1000".
        x = (mGame:HeadX + 1) * mTile + 4.
        y = mStrip + mGame:HeadY * mTile + INTEGER(TRUNCATE(mTile / 2, 0)) - 3.
        DO r = 0 TO 6:
            DO w = 0 TO 3:
                IF SUBSTRING(ENTRY(r + 1, arrow, "/"), w + 1, 1) = "1" THEN
                    mCanvas:DrawLine(x + w, y + r, x + w, y + r, 0, SnakeLook:Colour(SnakeTint:Accent)).
            END.
        END.
    END METHOD.

    /* The words of a pause on a plate across the middle of the board. This is not in the design, which has no pause: it is the
       plate of the other screens with the words PAUSED and P TO RESUME. */
    METHOD PRIVATE VOID DrawPaused():
        DEFINE VARIABLE middle AS INTEGER NO-UNDO.
        middle = mStrip + INTEGER(TRUNCATE(mRows * mTile / 2, 0)).
        Plate(0, middle - 28, mWidth, 56, SnakeTint:Accent, 2).
        Outlined("PAUSED", 2, SnakeTint:Text, SnakeTint:Text, Centred(PixelCanvas:ScaledWidth("PAUSED", 2)), middle - 16).
        Caption("P TO RESUME", 1, SnakeTint:Dim, Centred(PixelCanvas:ScaledWidth("P TO RESUME", 1)), middle + 6).
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
