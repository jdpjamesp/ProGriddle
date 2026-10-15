/* Draws Tetris in the "Lantern Glass" look (docs/design/tetris-art.md). It reads a TetrisGame, never changes it, and paints
   the picture on a pixel canvas of its own, 16 pixels to a cell: the well, a divider, and the panel with the next piece and
   the numbers. The canvas is then handed to the window's renderer (the inner one), so the game's own grid, with its
   view codes and its tests, is left as it is.

   What is drawn once and kept: the background, the floor, the walls, the divider and the frames of the cards. That is
   the "base", a canvas of its own. The settled blocks are added to the background of the picture as they settle (one lock
   is four tiles) and the whole stack is made again only when it changes under the blocks (a line clear, a new game), so
   a frame costs the falling piece, the ghost, the next piece and the numbers, not the two hundred blocks of the well.

   The painter owns canvases and stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisPainter FINAL IMPLEMENTS IGridRenderer:

    &SCOPED-DEFINE TILE 16
    &SCOPED-DEFINE NO-TONES "000000,000000,000000,000000,000000"

    DEFINE PRIVATE VARIABLE mInner     AS IGridRenderer   NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom    AS IRandom         NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame      AS TetrisGame      NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid      AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mBaseGrid  AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBase      AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mText      AS TextStampCache  NO-UNDO.
    /* the blocks of the seven pieces, the ghost, and the empty cell of each row */
    DEFINE PRIVATE VARIABLE mBlock     AS PixelStamp      NO-UNDO EXTENT 7.
    DEFINE PRIVATE VARIABLE mGhost     AS PixelStamp      NO-UNDO.
    /* the blocks as they flash when they settle: lit all over, then only the highlight white */
    DEFINE PRIVATE VARIABLE mLit       AS PixelStamp      NO-UNDO EXTENT 7.
    DEFINE PRIVATE VARIABLE mWhiteTop  AS PixelStamp      NO-UNDO EXTENT 7.
    /* the same blocks in the gold row, for the first frame of a Tetris */
    DEFINE PRIVATE VARIABLE mGold      AS PixelStamp      NO-UNDO EXTENT 7.
    DEFINE PRIVATE VARIABLE mSparks    AS SparkField      NO-UNDO.
    /* the clear that the sparks were made for */
    DEFINE PRIVATE VARIABLE mSparkClearMs AS INTEGER      NO-UNDO INITIAL -1.
    /* the lock that the sparks were made for */
    DEFINE PRIVATE VARIABLE mSparkSerial AS INTEGER       NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mSparkPlaced AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mFloor     AS PixelStamp      NO-UNDO EXTENT.
    /* the size of the well in cells and of the picture in pixels, and where the panel begins */
    DEFINE PRIVATE VARIABLE mBW        AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mBH        AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight    AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPanelX    AS INTEGER         NO-UNDO.
    /* what the stack that is baked into the picture was made from */
    DEFINE PRIVATE VARIABLE mBakedSerial   AS INTEGER     NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mBakedPlaced   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBakedLines    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBakedClearing AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed      AS LOGICAL     NO-UNDO.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* poRandom is for the effects (the speeds of sparks). Throws GridException for no renderer, no game or no random source. */
    CONSTRUCTOR PUBLIC TetrisPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS TetrisGame, INPUT poRandom AS IRandom):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Tetris painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Tetris painter needs a game").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Tetris painter needs a random source").
        mInner = poInner.
        mRandom = poRandom.
        mGame = poGame.
        mBW = poGame:BoardWidth.
        mBH = poGame:BoardHeight.
        mWidth = (mBW + 7) * {&TILE}.
        mHeight = mBH * {&TILE}.
        mPanelX = (mBW + 1) * {&TILE}.
        mGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mBaseGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mBase = NEW PixelCanvas(mBaseGrid).
        mText = NEW TextStampCache(64).
        mSparks = NEW SparkField(64).
        DO p = 1 TO 7:
            mBlock[p] = TetrisArt:Block(p):Colourise(TetrisLook:Tones(p), "").
            mLit[p] = TetrisArt:Block(p):Colourise(TetrisLook:LitTones(p), "").
            mWhiteTop[p] = TetrisArt:Block(p):Colourise(TetrisLook:WhiteTopTones(p), "").
            mGold[p] = TetrisArt:Block(p):Colourise(TetrisLook:Tones(9), "").
        END.
        mGhost = TetrisArt:Ghost():Colourise({&NO-TONES}, SUBSTITUTE("D=&1,H=&2", TetrisLook:Hex(Tint:GhostLine), TetrisLook:Hex(Tint:GhostHatch))).
        EXTENT(mFloor) = mBH.
        DO r = 0 TO mBH - 1:
            mFloor[r + 1] = TetrisArt:Floor():Colourise({&NO-TONES}, SUBSTITUTE("F=&1,G=&2", ColourMath:ToHex(FloorColour(r)), ColourMath:ToHex(ColourMath:Mix(FloorColour(r), 16777215, 35, 1000)))).
        END.
        BuildBase().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC TetrisPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not
       a Tetris game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, TetrisGame) THEN UNDO, THROW NEW GridException("A Tetris painter draws a Tetris game").
        SyncStack().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawTrail().
        DrawGhost().
        DrawPiece().
        DrawLock().
        DrawClear().
        DrawImpact().
        mSparks:Draw(mCanvas, mGame:ElapsedMs).
        DrawTetrisWord().
        DrawNext().
        DrawHud().
        mCanvas:EndBatch().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvases and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        DO i = 1 TO 7:
            IF VALID-OBJECT(mBlock[i]) THEN mBlock[i]:Dispose().
            IF VALID-OBJECT(mLit[i]) THEN mLit[i]:Dispose().
            IF VALID-OBJECT(mWhiteTop[i]) THEN mWhiteTop[i]:Dispose().
            IF VALID-OBJECT(mGold[i]) THEN mGold[i]:Dispose().
        END.
        IF VALID-OBJECT(mGhost) THEN mGhost:Dispose().
        DO i = 1 TO EXTENT(mFloor):
            IF VALID-OBJECT(mFloor[i]) THEN mFloor[i]:Dispose().
        END.
        IF VALID-OBJECT(mText) THEN mText:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mBase) THEN mBase:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        IF VALID-OBJECT(mBaseGrid) THEN mBaseGrid:Dispose().
    END METHOD.

    /* ================================ what is drawn once ================================ */

    /* The colour of the empty cells of a row: a little lighter each row down. */
    METHOD PRIVATE INTEGER FloorColour(INPUT piRow AS INTEGER):
        RETURN ColourMath:Mix(TetrisLook:Colour(Tint:FloorTop), TetrisLook:Colour(Tint:FloorBottom), piRow, MAXIMUM(1, mBH - 1)).
    END METHOD.

    /* The background, the floor, the walls, the divider and the frames of the cards, drawn on the base canvas and kept. */
    METHOD PRIVATE VOID BuildBase():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE m AS INTEGER NO-UNDO.
        DEFINE VARIABLE wellW AS INTEGER NO-UNDO.
        wellW = mBW * {&TILE}.
        mBase:BeginBatch().
        /* the night, darker at the top */
        DO y = 0 TO mHeight - 1:
            mBase:DrawLine(0, y, mWidth - 1, y, 0, ColourMath:Mix(TetrisLook:Colour(Tint:NightTop), TetrisLook:Colour(Tint:NightBottom), y, MAXIMUM(1, mHeight - 1))).
        END.
        /* a faint dot every 16 pixels in the panel */
        DO k = 0 TO 5:
            DO m = 0 TO mBH - 1:
                x = mPanelX + 8 + {&TILE} * k.
                y = 8 + {&TILE} * m.
                mBase:DrawLine(x, y, x, y, 0, TetrisLook:Colour(Tint:Dot)).
            END.
        END.
        /* the empty cells of the well */
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                mFloor[y + 1]:DrawTo(mBase, x * {&TILE}, y * {&TILE}).
            END.
        END.
        /* the walls: two pixels on the left and at the bottom */
        mBase:DrawLine(0, 0, 0, mHeight - 1, 0, TetrisLook:Colour(Tint:WallHigh)).
        mBase:DrawLine(1, 0, 1, mHeight - 1, 0, TetrisLook:Colour(Tint:WallLow)).
        mBase:DrawLine(0, mHeight - 2, wellW - 1, mHeight - 2, 0, TetrisLook:Colour(Tint:WallLow)).
        mBase:DrawLine(0, mHeight - 1, wellW - 1, mHeight - 1, 0, TetrisLook:Colour(Tint:WallHigh)).
        /* the divider, which is also the right wall: two lit pixels, twelve of dark gap, the edge of the panel */
        DO k = 0 TO {&TILE} - 1:
            CASE k:
                WHEN 0 THEN x = TetrisLook:Colour(Tint:WallLow).
                WHEN 1 THEN x = TetrisLook:Colour(Tint:WallHigh).
                WHEN 14 THEN x = TetrisLook:Colour(Tint:FrameInner).
                WHEN 15 THEN x = TetrisLook:Colour(Tint:FrameOuter).
                OTHERWISE x = TetrisLook:Colour(Tint:Gap).
            END CASE.
            mBase:DrawLine(wellW + k, 0, wellW + k, mHeight - 1, 0, x).
        END.
        /* the box of the next piece, and the four cards */
        Card(mPanelX, 0, 96, 96).
        Card(mPanelX + 4, 104, 88, 40).
        Card(mPanelX + 4, 150, 88, 40).
        Card(mPanelX + 4, 196, 88, 40).
        Card(mPanelX + 4, 242, 88, 40).
        mBase:EndBatch().
        mBase:BakeView().
        mCanvas:LoadBack(mBase).
    END METHOD.

    /* A frame on the base canvas, in a batch: the outer line, the inner line and the fill, with the four corner pixels cut. */
    METHOD PRIVATE VOID Card(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cut AS INTEGER NO-UNDO.
        cut = TetrisLook:Colour(Tint:NightTop).
        DO y = piY TO piY + piH - 1:
            mBase:DrawLine(piX, y, piX + piW - 1, y, 0, TetrisLook:Colour(Tint:FrameOuter)).
        END.
        DO y = piY + 1 TO piY + piH - 2:
            mBase:DrawLine(piX + 1, y, piX + piW - 2, y, 0, TetrisLook:Colour(Tint:FrameInner)).
        END.
        DO y = piY + 2 TO piY + piH - 3:
            mBase:DrawLine(piX + 2, y, piX + piW - 3, y, 0, TetrisLook:Colour(Tint:PanelFill)).
        END.
        mBase:DrawLine(piX, piY, piX, piY, 0, cut).
        mBase:DrawLine(piX + piW - 1, piY, piX + piW - 1, piY, 0, cut).
        mBase:DrawLine(piX, piY + piH - 1, piX, piY + piH - 1, 0, cut).
        mBase:DrawLine(piX + piW - 1, piY + piH - 1, piX + piW - 1, piY + piH - 1, 0, cut).
    END METHOD.

    /* ================================ the stack ================================ */

    /* Brings the stack that is baked into the picture up to date: a piece that has just settled is added (four tiles), and
       anything else that changed under the blocks (a new game, a line clear that has begun or ended) makes the stack again. */
    METHOD PRIVATE VOID SyncStack():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF mGame:GameSerial = mBakedSerial AND mGame:LinesCleared = mBakedLines AND mGame:Clearing = mBakedClearing AND mGame:PiecesPlaced = mBakedPlaced THEN RETURN.
        IF mGame:GameSerial = mBakedSerial AND mGame:LinesCleared = mBakedLines AND mGame:Clearing = mBakedClearing AND mGame:PiecesPlaced = mBakedPlaced + 1
           AND mGame:LastLockPiece > 0 THEN DO:
            shape = Tetrominoes:ShapeOf(mGame:LastLockPiece, mGame:LastLockTurn).
            mCanvas:Restore().
            mCanvas:BeginBatch().
            DO i = 1 TO shape:Size:
                mBlock[mGame:LastLockPiece]:DrawTo(mCanvas, (mGame:LastLockX + shape:OffsetX(i)) * {&TILE}, (mGame:LastLockY + shape:OffsetY(i)) * {&TILE}).
            END.
            mCanvas:EndBatch().
            mCanvas:BakeView().
        END.
        ELSE RebuildStack().
        ASSIGN mBakedSerial = mGame:GameSerial
               mBakedPlaced = mGame:PiecesPlaced
               mBakedLines = mGame:LinesCleared
               mBakedClearing = mGame:Clearing.
    END METHOD.

    /* The picture's background is the base and every settled block. */
    METHOD PRIVATE VOID RebuildStack():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE piece AS INTEGER NO-UNDO.
        mCanvas:LoadBack(mBase).
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                piece = mGame:LockedAt(x, y).
                IF piece > 0 THEN mBlock[piece]:DrawTo(mCanvas, x * {&TILE}, y * {&TILE}).
            END.
        END.
        mCanvas:EndBatch().
        mCanvas:BakeView().
    END METHOD.

    /* ================================ every frame ================================ */

    /* The ghost: where the piece would land, on the empty cells only (a block of the stack is never covered). */
    METHOD PRIVATE VOID DrawGhost():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE gy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy    AS INTEGER NO-UNDO.
        IF NOT mGame:ShowGhost OR mGame:CurrentPiece = 0 THEN RETURN.
        shape = Tetrominoes:ShapeOf(mGame:CurrentPiece, mGame:Turns).
        gy = mGame:GhostY().
        DO i = 1 TO shape:Size:
            cx = mGame:PieceX + shape:OffsetX(i).
            cy = gy + shape:OffsetY(i).
            IF mGame:LockedAt(cx, cy) = 0 THEN mGhost:DrawTo(mCanvas, cx * {&TILE}, cy * {&TILE}).
        END.
    END METHOD.

    /* The falling piece. */
    METHOD PRIVATE VOID DrawPiece():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF mGame:CurrentPiece = 0 THEN RETURN.
        shape = Tetrominoes:ShapeOf(mGame:CurrentPiece, mGame:Turns).
        DO i = 1 TO shape:Size:
            mBlock[mGame:CurrentPiece]:DrawTo(mCanvas, (mGame:PieceX + shape:OffsetX(i)) * {&TILE}, (mGame:PieceY + shape:OffsetY(i)) * {&TILE}).
        END.
    END METHOD.

    /* The trail of a hard drop (docs/design/tetris-art.md 3.2): from the top of the highest block of each column of the piece
       down to where it landed, two pixels wide, in tone 2, then 3, then 4 of the piece, 50 ms each. It is drawn under the ghost
       and the pieces and only on cells that are empty, so the stack is never covered. */
    METHOD PRIVATE VOID DrawTrail():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER NO-UNDO.
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cc   AS INTEGER NO-UNDO.
        DEFINE VARIABLE top   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE c     AS INTEGER NO-UNDO.
        IF NOT mGame:LastLockHard OR mGame:LastLockMs < 0 OR mGame:LastLockPiece = 0 THEN RETURN.
        age = mGame:ElapsedMs - mGame:LastLockMs.
        IF age < 0 OR age >= 150 THEN RETURN.
        c = ColourMath:FromHex(ENTRY(2 + INTEGER(TRUNCATE(age / 50, 0)), TetrisLook:Tones(mGame:LastLockPiece))).
        shape = Tetrominoes:ShapeOf(mGame:LastLockPiece, mGame:LastLockTurn).
        DO i = 1 TO shape:Size:
            top = TRUE.
            DO j = 1 TO shape:Size:
                IF shape:OffsetX(j) = shape:OffsetX(i) AND shape:OffsetY(j) < shape:OffsetY(i) THEN top = FALSE.
            END.
            IF NOT top THEN NEXT.
            cc = mGame:LastLockX + shape:OffsetX(i).
            DO r = mGame:LastLockFromY + shape:OffsetY(i) TO mGame:LastLockY + shape:OffsetY(i) - 1:
                IF r < 0 OR mGame:LockedAt(cc, r) <> 0 THEN NEXT.
                mCanvas:DrawLine(cc * {&TILE} + 7, r * {&TILE}, cc * {&TILE} + 7, r * {&TILE} + {&TILE} - 1, 0, c).
                mCanvas:DrawLine(cc * {&TILE} + 8, r * {&TILE}, cc * {&TILE} + 8, r * {&TILE} + {&TILE} - 1, 0, c).
            END.
        END.
    END METHOD.

    /* The impact of a hard drop: a line along the bottom edge of the landed piece that grows 4 pixels each side every 50 ms for
       three steps, in the flash colour, tone 1 and tone 3 of the piece. */
    METHOD PRIVATE VOID DrawImpact():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE step  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x1    AS INTEGER NO-UNDO.
        DEFINE VARIABLE x2    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c     AS INTEGER NO-UNDO.
        IF NOT mGame:LastLockHard OR mGame:LastLockMs < 0 OR mGame:LastLockPiece = 0 THEN RETURN.
        step = INTEGER(TRUNCATE((mGame:ElapsedMs - mGame:LastLockMs) / 50, 0)).
        IF mGame:ElapsedMs < mGame:LastLockMs OR step > 2 THEN RETURN.
        shape = Tetrominoes:ShapeOf(mGame:LastLockPiece, mGame:LastLockTurn).
        DO i = 1 TO shape:Size:
            y = MAXIMUM(y, shape:OffsetY(i)).
        END.
        x2 = (mGame:LastLockX + shape:Width) * {&TILE} - 1 + 4 * step.
        x1 = mGame:LastLockX * {&TILE} - 4 * step.
        CASE step:
            WHEN 0 THEN c = TetrisLook:Colour(Tint:Flash).
            WHEN 1 THEN c = ColourMath:FromHex(ENTRY(1, TetrisLook:Tones(mGame:LastLockPiece))).
            OTHERWISE c = ColourMath:FromHex(ENTRY(3, TetrisLook:Tones(mGame:LastLockPiece))).
        END CASE.
        mCanvas:DrawLine(MAXIMUM(0, x1), (mGame:LastLockY + y) * {&TILE} + {&TILE} - 1, MINIMUM(mBW * {&TILE} - 1, x2), (mGame:LastLockY + y) * {&TILE} + {&TILE} - 1, 0, c).
    END METHOD.

    /* Whether a column of the well has turned to floor at a frame of the wipe (frames 2 to 5): the two in the middle first, then
       two more each side, and the whole row at the last. */
    METHOD PRIVATE LOGICAL WipedAt(INPUT piCol AS INTEGER, INPUT piFrame AS INTEGER):
        IF piFrame >= 5 THEN RETURN TRUE.
        RETURN ABSOLUTE(2 * piCol - (mBW - 1)) <= 2 * (piFrame - 2) + 1.
    END METHOD.

    /* The rows that are held for a clear (docs/design/tetris-art.md 3.3 and 3.4): the blocks lit, the whole row white, then
       the row turns to floor from the middle out. A Tetris takes 60 ms a frame, begins in gold and has one more frame. The
       sparks of the wipe are made once, for all the frames, with their birth times in the future. */
    METHOD PRIVATE VOID DrawClear():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER NO-UNDO.
        DEFINE VARIABLE piece  AS INTEGER NO-UNDO.
        DEFINE VARIABLE fno  AS INTEGER NO-UNDO.
        DEFINE VARIABLE fms AS INTEGER NO-UNDO.
        DEFINE VARIABLE four   AS LOGICAL NO-UNDO.
        IF NOT mGame:Clearing OR mGame:LastClearMs < 0 THEN RETURN.
        four = mGame:LastClearCount = 4.
        fms = IF four THEN 60 ELSE 50.
        IF mSparkClearMs <> mGame:LastClearMs THEN DO:
            mSparkClearMs = mGame:LastClearMs.
            ClearSparks(fms, four).
        END.
        fno = INTEGER(TRUNCATE((mGame:ElapsedMs - mGame:LastClearMs) / fms, 0)).
        IF fno < 0 THEN RETURN.
        DO i = 1 TO NUM-ENTRIES(mGame:ClearRows):
            r = INTEGER(ENTRY(i, mGame:ClearRows)).
            IF fno = 1 THEN DO:
                DO c = r * {&TILE} TO r * {&TILE} + {&TILE} - 1:
                    mCanvas:DrawLine(0, c, mBW * {&TILE} - 1, c, 0, TetrisLook:Colour(Tint:Flash)).
                END.
                NEXT.
            END.
            DO c = 0 TO mBW - 1:
                piece = mGame:LockedAt(c, r).
                IF (fno >= 2 AND WipedAt(c, fno)) OR (four AND fno >= 6) THEN mFloor[r + 1]:DrawTo(mCanvas, c * {&TILE}, r * {&TILE}).
                ELSE IF piece > 0 THEN DO:
                    IF fno = 0 AND four THEN mGold[piece]:DrawTo(mCanvas, c * {&TILE}, r * {&TILE}).
                    ELSE mLit[piece]:DrawTo(mCanvas, c * {&TILE}, r * {&TILE}).
                END.
            END.
        END.
    END METHOD.

    /* The sparks of the wipe: for each cleared row and each of frames 2 to 5, a spark each side (two each side for a Tetris) at
       the centres of the outermost columns that turn to floor in that frame, in the gold ramp. */
    METHOD PRIVATE VOID ClearSparks(INPUT piLength AS INTEGER, INPUT plFour AS LOGICAL):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE f      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE side   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE gold   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE half   AS INTEGER   NO-UNDO.
        gold = TetrisLook:Tones(9).
        half = INTEGER(TRUNCATE(mBW / 2, 0)) - 1.
        DO i = 1 TO NUM-ENTRIES(mGame:ClearRows):
            r = INTEGER(ENTRY(i, mGame:ClearRows)).
            DO f = 2 TO 5:
                /* the outer pair of columns of this frame: 4 and 5, 3 and 6, 2 and 7, then 0 and 9 */
                c = IF f = 5 THEN 0 ELSE half - (f - 2).
                DO side = 0 TO 1:
                    DO k = 1 TO (IF plFour THEN 2 ELSE 1):
                        mSparks:Add((IF side = 0 THEN c ELSE mBW - 1 - c) * {&TILE} + 8, r * {&TILE} + 8,
                                    (IF side = 0 THEN -1 ELSE 1) * (0.5 + mRandom:NextDecimal() * 0.7), 0 - (0.4 + mRandom:NextDecimal() * 0.7), 0.05,
                                    mGame:LastClearMs + f * piLength, 12,
                                    TetrisLook:Colour(Tint:Flash), ColourMath:FromHex(ENTRY(1, gold)), ColourMath:FromHex(ENTRY(2, gold)), ColourMath:FromHex(ENTRY(3, gold))).
                    END.
                END.
            END.
        END.
    END METHOD.

    /* The word TETRIS over the well for half a second after four rows are cleared, centred on the band that went. */
    METHOD PRIVATE VOID DrawTetrisWord():
        DEFINE VARIABLE age  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE word AS TextStamp NO-UNDO.
        IF mGame:LastClearCount <> 4 OR mGame:LastClearMs < 0 THEN RETURN.
        age = mGame:ElapsedMs - mGame:LastClearMs.
        IF age < 120 OR age >= 720 THEN RETURN.
        word = mText:Get("TETRIS", 2, TetrisLook:Colour(Tint:Gold), TetrisLook:Colour(Tint:Accent), TetrisLook:Colour(Tint:Outline)).
        y = {&TILE} * INTEGER(ENTRY(1, mGame:ClearRows)) + 32 - 7.
        y = MAXIMUM(8, MINIMUM(298, y)).
        word:DrawTo(mCanvas, INTEGER(TRUNCATE((mBW * {&TILE} - PixelCanvas:ScaledWidth("TETRIS", 2)) / 2, 0)), y).
    END METHOD.

    /* The settling of the last piece (docs/design/tetris-art.md 3.1): for 50 ms its four blocks are lit, for 50 ms more only their
       highlight is white, and sparks fly from the blocks that sit on something. The sparks are made once for each lock. Nothing
       is drawn while rows are held for a clear, because the piece may be in them. */
    METHOD PRIVATE VOID DrawLock():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy    AS INTEGER NO-UNDO.
        IF mGame:GameSerial <> mSparkSerial THEN DO:
            mSparks:Clear().
            ASSIGN mSparkSerial = mGame:GameSerial
                   mSparkPlaced = 0
                   mSparkClearMs = -1.
        END.
        IF mGame:LastLockPiece = 0 OR mGame:LastLockMs < 0 THEN RETURN.
        shape = Tetrominoes:ShapeOf(mGame:LastLockPiece, mGame:LastLockTurn).
        IF mGame:PiecesPlaced <> mSparkPlaced THEN DO:
            mSparkPlaced = mGame:PiecesPlaced.
            LockSparks(shape).
        END.
        age = mGame:ElapsedMs - mGame:LastLockMs.
        IF age >= 0 AND age < 100 AND NOT mGame:Clearing THEN DO i = 1 TO shape:Size:
            cx = (mGame:LastLockX + shape:OffsetX(i)) * {&TILE}.
            cy = (mGame:LastLockY + shape:OffsetY(i)) * {&TILE}.
            IF mGame:LockedAt(INTEGER(cx / {&TILE}), INTEGER(cy / {&TILE})) <> mGame:LastLockPiece THEN NEXT.
            IF age < 50 THEN mLit[mGame:LastLockPiece]:DrawTo(mCanvas, cx, cy).
            ELSE mWhiteTop[mGame:LastLockPiece]:DrawTo(mCanvas, cx, cy).
        END.
    END METHOD.

    /* Two sparks, left and right, from the bottom of every block of the piece that has the floor or a block under it. The speed
       varies a little with the random source. */
    METHOD PRIVATE VOID LockSparks(INPUT poShape AS Shape):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER NO-UNDO.
        DEFINE VARIABLE bx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE by2    AS INTEGER NO-UNDO.
        DEFINE VARIABLE own    AS LOGICAL NO-UNDO.
        DEFINE VARIABLE t      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE speed  AS DECIMAL NO-UNDO.
        t = TetrisLook:Tones(mGame:LastLockPiece).
        DO i = 1 TO poShape:Size:
            bx = mGame:LastLockX + poShape:OffsetX(i).
            by2 = mGame:LastLockY + poShape:OffsetY(i).
            own = FALSE.
            DO j = 1 TO poShape:Size:
                IF mGame:LastLockX + poShape:OffsetX(j) = bx AND mGame:LastLockY + poShape:OffsetY(j) = by2 + 1 THEN own = TRUE.
            END.
            IF own THEN NEXT.
            IF by2 + 1 < mBH AND mGame:LockedAt(bx, by2 + 1) = 0 THEN NEXT.
            speed = 0.5 + mRandom:NextDecimal() * 0.2.
            mSparks:Add(bx * {&TILE} + 5, by2 * {&TILE} + 15, 0 - speed, -0.35, 0.04, mGame:LastLockMs, 10,
                        TetrisLook:Colour(Tint:Flash), ColourMath:FromHex(ENTRY(1, t)), ColourMath:FromHex(ENTRY(2, t)), ColourMath:FromHex(ENTRY(3, t))).
            mSparks:Add(bx * {&TILE} + 10, by2 * {&TILE} + 15, speed, -0.35, 0.04, mGame:LastLockMs, 10,
                        TetrisLook:Colour(Tint:Flash), ColourMath:FromHex(ENTRY(1, t)), ColourMath:FromHex(ENTRY(2, t)), ColourMath:FromHex(ENTRY(3, t))).
        END.
    END METHOD.

    /* The next piece, in the middle of the box on the area 64 pixels square that starts 16 in from the box's corner, and the
       word NEXT above it. */
    METHOD PRIVATE VOID DrawNext():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x0    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0    AS INTEGER NO-UNDO.
        Caption("NEXT", 1, Tint:Accent, mPanelX + 36, 8).
        shape = Tetrominoes:ShapeOf(mGame:NextPiece, 0).
        x0 = mPanelX + 16 + INTEGER(TRUNCATE((64 - {&TILE} * shape:Width) / 2, 0)).
        y0 = 24 + INTEGER(TRUNCATE((64 - {&TILE} * shape:Height) / 2, 0)).
        DO i = 1 TO shape:Size:
            mBlock[mGame:NextPiece]:DrawTo(mCanvas, x0 + {&TILE} * shape:OffsetX(i), y0 + {&TILE} * shape:OffsetY(i)).
        END.
    END METHOD.

    /* The labels and numbers of the four cards, and the two key hints. */
    METHOD PRIVATE VOID DrawHud():
        Caption("SCORE", 1, Tint:Label, mPanelX + 12, 110).
        Number(mGame:Score, 6, IF Pulsing() THEN Tint:Gold ELSE Tint:Text, 122).
        Caption("LINES", 1, Tint:Label, mPanelX + 12, 156).
        Number(mGame:LinesCleared, 6, Tint:Text, 168).
        Caption("LEVEL", 1, Tint:Label, mPanelX + 12, 202).
        Number(mGame:Level, 2, Tint:Accent, 214).
        Caption("HI-SCORE", 1, Tint:Label, mPanelX + 12, 248).
        Number(mGame:BestScore, 6, Tint:Dim, 260).
        Caption("P PAUSE", 1, Tint:Label, mPanelX + 12, 294).
        Caption("G GHOST", 1, Tint:Label, mPanelX + 12, 304).
    END METHOD.

    /* True for 400 ms after a line clear (800 ms after a Tetris): the score shows in gold. */
    METHOD PRIVATE LOGICAL Pulsing():
        IF mGame:LastClearMs < 0 THEN RETURN FALSE.
        RETURN mGame:ElapsedMs - mGame:LastClearMs < (IF mGame:LastClearCount = 4 THEN 800 ELSE 400).
    END METHOD.

    /* Some text at a place, one colour, no outline. */
    METHOD PRIVATE VOID Caption(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTint AS Tint, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = TetrisLook:Colour(poTint).
        mText:Get(pcText, piScale, c, c, -1):DrawTo(mCanvas, piX, piY).
    END METHOD.

    /* A number of piDigits digits padded with zeros at twice the size in a card, or, when it needs more digits than that, at the
       normal size without padding and with its right end at the right of the card. */
    METHOD PRIVATE VOID Number(INPUT piValue AS INTEGER, INPUT piDigits AS INTEGER, INPUT poTint AS Tint, INPUT piY AS INTEGER):
        DEFINE VARIABLE shown AS CHARACTER NO-UNDO.
        shown = STRING(piValue).
        IF LENGTH(shown) <= piDigits THEN Caption(FILL("0", piDigits - LENGTH(shown)) + shown, 2, poTint, mPanelX + 12, piY).
        ELSE Caption(shown, 1, poTint, mPanelX + 88 - (LENGTH(shown) * 6 - 1), piY + 4).
    END METHOD.

END CLASS.
