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
    DEFINE PRIVATE VARIABLE mGame      AS TetrisGame      NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid      AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mBaseGrid  AS Grid            NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mBase      AS PixelCanvas     NO-UNDO.
    DEFINE PRIVATE VARIABLE mText      AS TextStampCache  NO-UNDO.
    /* the blocks of the seven pieces, the ghost, and the empty cell of each row */
    DEFINE PRIVATE VARIABLE mBlock     AS PixelStamp      NO-UNDO EXTENT 7.
    DEFINE PRIVATE VARIABLE mGhost     AS PixelStamp      NO-UNDO.
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

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC TetrisPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS TetrisGame):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Tetris painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Tetris painter needs a game").
        mInner = poInner.
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
        DO p = 1 TO 7:
            mBlock[p] = TetrisArt:Block(p):Colourise(TetrisLook:Tones(p), "").
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
        DrawGhost().
        DrawPiece().
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
        Number(mGame:Score, 6, Tint:Text, 122).
        Caption("LINES", 1, Tint:Label, mPanelX + 12, 156).
        Number(mGame:LinesCleared, 6, Tint:Text, 168).
        Caption("LEVEL", 1, Tint:Label, mPanelX + 12, 202).
        Number(mGame:Level, 2, Tint:Accent, 214).
        Caption("HI-SCORE", 1, Tint:Label, mPanelX + 12, 248).
        Number(mGame:BestScore, 6, Tint:Dim, 260).
        Caption("P PAUSE", 1, Tint:Label, mPanelX + 12, 294).
        Caption("G GHOST", 1, Tint:Label, mPanelX + 12, 304).
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
