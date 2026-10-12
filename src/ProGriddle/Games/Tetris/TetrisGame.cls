/* Tetris as a real time game.

   The board is 10 wide and 20 high by default. Pieces come from a seven bag, fall one row at a time
   on a timer, and settle where they land. A full row disappears and the rows above drop. The game is
   over when a new piece has no room to appear.

   The state of play lives in a board sized field of its own, so the store's row operations work on exactly
   the board: layer "locked" (0 empty, else the number of the piece that settled there) and layer "active"
   (the falling piece, stamped each time it moves, 0 elsewhere). The grid the game shows has one layer,
   "view" (what to draw, see ViewCodes.i), and is the board, a divider column and a panel six cells wide
   that shows the next piece.

   Rules and numbers:
   - Gravity moves the piece down once every GravityMs milliseconds: 800 at level 1, 75 faster for each
     level, never under 50. Tick adds up the time it is given, so a test drives the game with a fake clock.
   - Moves: left, right, soft drop (one row, 1 point), hard drop (to the bottom and settle, 2 points a
     row), turn clockwise or anticlockwise. A turn tries the spot the piece is turned about, then a few
     kicks sideways and up, and is refused when none fits. A piece rests on the floor until the next
     gravity step, which settles it.
   - Lines: 1 scores 100, 2 score 300, 3 score 500, 4 score 800, each times the level. Every 10 lines
     raise the level by one, from the start level.
   - The ghost is where the piece would land if dropped now, drawn dimly when ShowGhost is on.
   - While Paused, or after the game is over, Tick and every move do nothing.

   The game owns its grid. Dispose releases it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    {ProGriddle/Games/Tetris/ViewCodes.i}

    DEFINE PRIVATE VARIABLE mBag        AS PieceBag NO-UNDO.
    /* the playfield: settled blocks and the falling piece, the size of the board */
    DEFINE PRIVATE VARIABLE mField      AS ICellStore NO-UNDO.
    DEFINE PRIVATE VARIABLE mBW         AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mBH         AS INTEGER  NO-UNDO.
    /* the 28 shapes: mShapes[(piece - 1) * 4 + turn + 1] */
    DEFINE PRIVATE VARIABLE mShapes     AS Shape    NO-UNDO EXTENT 28.
    DEFINE PRIVATE VARIABLE mPiece      AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mTurn       AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mX          AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mY          AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mNext       AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mScore      AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLines      AS INTEGER  NO-UNDO.
    /* the level of the game being played, and the level the next new game will start at */
    DEFINE PRIVATE VARIABLE mStartLevel AS INTEGER  NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mNextStart  AS INTEGER  NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mAcc        AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlaced     AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLLocked    AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLActive    AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLView      AS INTEGER  NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Show the ghost piece, where the piece would land. On by default. */
    DEFINE PUBLIC PROPERTY ShowGhost AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET(INPUT plValue AS LOGICAL):
            ShowGhost = plValue.
            IF VALID-OBJECT(Grid) AND mPiece > 0 THEN RefreshView().
        END SET.

    DEFINE PUBLIC PROPERTY BoardWidth AS INTEGER NO-UNDO
        GET():
            RETURN mBW.
        END GET.

    DEFINE PUBLIC PROPERTY BoardHeight AS INTEGER NO-UNDO
        GET():
            RETURN mBH.
        END GET.

    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET():
            RETURN mScore.
        END GET.

    /* Rows cleared since the game began. */
    DEFINE PUBLIC PROPERTY LinesCleared AS INTEGER NO-UNDO
        GET():
            RETURN mLines.
        END GET.

    /* 1 or more: the start level plus one for every 10 lines, never over 30. */
    DEFINE PUBLIC PROPERTY Level AS INTEGER NO-UNDO
        GET():
            RETURN MINIMUM(30, mStartLevel + INTEGER(TRUNCATE(mLines / 10, 0))).
        END GET.

    /* The level a new game begins at, 1 to 15. The game being played keeps its level: this takes effect
       at the next Initialise. */
    DEFINE PUBLIC PROPERTY StartLevel AS INTEGER NO-UNDO
        GET():
            RETURN mNextStart.
        END GET.
        SET(INPUT piValue AS INTEGER):
            IF piValue = ? OR piValue < 1 OR piValue > 15 THEN UNDO, THROW NEW GridException("The start level is 1 to 15, not " + STRING(piValue)).
            mNextStart = piValue.
        END SET.

    /* How many pieces have settled since the game began. */
    DEFINE PUBLIC PROPERTY PiecesPlaced AS INTEGER NO-UNDO
        GET():
            RETURN mPlaced.
        END GET.

    /* Milliseconds between gravity steps at the current level. */
    DEFINE PUBLIC PROPERTY GravityMs AS INTEGER NO-UNDO
        GET():
            RETURN MAXIMUM(50, 800 - (Level - 1) * 75).
        END GET.

    /* The falling piece (1 to 7), its turn (0 to 3) and the position of its top left cell, and the
       piece that comes after it. CurrentPiece is 0 once the game is over. */
    DEFINE PUBLIC PROPERTY CurrentPiece AS INTEGER NO-UNDO
        GET():
            RETURN mPiece.
        END GET.

    DEFINE PUBLIC PROPERTY NextPiece AS INTEGER NO-UNDO
        GET():
            RETURN mNext.
        END GET.

    DEFINE PUBLIC PROPERTY Turns AS INTEGER NO-UNDO
        GET():
            RETURN mTurn.
        END GET.

    DEFINE PUBLIC PROPERTY PieceX AS INTEGER NO-UNDO
        GET():
            RETURN mX.
        END GET.

    DEFINE PUBLIC PROPERTY PieceY AS INTEGER NO-UNDO
        GET():
            RETURN mY.
        END GET.

    /* The grid must have the one layer "view", be bounded, and be the board's width plus 7 columns
       wide (a divider and a panel of 6), with a board from 6 to 30 wide and 8 to 40 high. */
    CONSTRUCTOR PUBLIC TetrisGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        SUPER("Tetris", poGrid).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Tetris game needs a random source").
        CheckGrid(poGrid).
        mBW = poGrid:Width - 7.
        mBH = poGrid:Height.
        mField = TetrisFactory:CreateField(mBW, mBH).
        mLLocked = mField:LayerIndex("locked").
        mLActive = mField:LayerIndex("active").
        mLView = Grid:Store:LayerIndex("view").
        mBag = NEW PieceBag(poRandom).
        DO p = 1 TO 7:
            DO t = 0 TO 3:
                mShapes[(p - 1) * 4 + t + 1] = Tetrominoes:ShapeOf(p, t).
            END.
        END.
        Initialise().
    END CONSTRUCTOR.

    /* ---- moves ---- */

    METHOD PUBLIC LOGICAL MoveLeft():
        RETURN Move(-1, 0).
    END METHOD.

    METHOD PUBLIC LOGICAL MoveRight():
        RETURN Move(1, 0).
    END METHOD.

    /* One row down, for a point. Returns false when the piece rests on something, which only gravity
       settles. */
    METHOD PUBLIC LOGICAL SoftDrop():
        IF NOT Move(0, 1) THEN RETURN FALSE.
        mScore = mScore + 1.
        RETURN TRUE.
    END METHOD.

    /* Drops the piece as far as it goes, settles it and brings the next, for 2 points a row. */
    METHOD PUBLIC LOGICAL HardDrop():
        DEFINE VARIABLE landing AS INTEGER NO-UNDO.
        IF NOT Active() THEN RETURN FALSE.
        landing = GhostY().
        mScore = mScore + 2 * (landing - mY).
        MovePiece(mTurn, mX, landing).
        LockPiece().
        RefreshView().
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC LOGICAL RotateClockwise():
        RETURN Rotate(1).
    END METHOD.

    METHOD PUBLIC LOGICAL RotateCounterClockwise():
        RETURN Rotate(-1).
    END METHOD.

    /* Adds up the time and lets gravity step as many times as it is due. Returns true when anything
       changed. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        DEFINE VARIABLE changed AS LOGICAL NO-UNDO.
        IF NOT Active() OR piElapsedMs = ? OR piElapsedMs <= 0 THEN RETURN FALSE.
        mAcc = mAcc + piElapsedMs.
        DO WHILE mAcc >= GravityMs AND NOT IsOver:
            mAcc = mAcc - GravityMs.
            IF NOT TryMove(0, 1) THEN LockPiece().
            changed = TRUE.
        END.
        IF changed THEN RefreshView().
        RETURN changed.
    END METHOD.

    /* The row the piece would land on if dropped straight down now. */
    METHOD PUBLIC INTEGER GhostY():
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        IF mPiece = 0 THEN RETURN 0.
        y = mY.
        DO WHILE NOT Collides(mTurn, mX, y + 1):
            y = y + 1.
        END.
        RETURN y.
    END METHOD.

    /* ---- setting up, for tests and set puzzles ---- */

    /* Starts a new game whose topRow pieces are the ones named, in order, as in "I,O,T"; after them the
       bag carries on. */
    METHOD PUBLIC VOID StartWith(INPUT pcPieces AS CHARACTER):
        mBag:Preset(pcPieces).
        Initialise().
    END METHOD.

    /* Fills the settled blocks from text, one string per row from the top of the board down, separated
       by "/", with "." for empty and a piece letter (I O T S Z J L) for a block of that piece. Rows
       missing at the top are empty. Throws GridException for rows wider than the board or too many rows.
       The falling piece is put back at the top and, if the blocks leave it no room, the game is over. */
    METHOD PUBLIC VOID LoadLocked(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE rowCount AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c        AS INTEGER   NO-UNDO.
        DEFINE VARIABLE rowText  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cell     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE topRow    AS INTEGER   NO-UNDO.
        IF pcRows = ? THEN UNDO, THROW NEW GridException("Rows cannot be the unknown value").
        rowCount = NUM-ENTRIES(pcRows, "/").
        IF rowCount > mBH THEN UNDO, THROW NEW GridException("Too many rows for a board " + STRING(mBH) + " high").
        mField:FillLayer(mLLocked, 0).
        topRow = mBH - rowCount.
        DO r = 1 TO rowCount:
            rowText = ENTRY(r, pcRows, "/").
            IF LENGTH(rowText) > mBW THEN UNDO, THROW NEW GridException("A row is wider than the board: " + rowText).
            DO c = 1 TO LENGTH(rowText):
                cell = SUBSTRING(rowText, c, 1).
                IF cell <> "." THEN mField:SetCell(mLLocked, c - 1, topRow + r - 1, Tetrominoes:PieceOf(cell)).
            END.
        END.
        /* the piece in the air goes back to the top, so a test sees it where it expects it */
        IF mPiece > 0 THEN DO:
            mField:FillLayer(mLActive, 0).
            mTurn = 0.
            mX = INTEGER(TRUNCATE((mBW - mShapes[(mPiece - 1) * 4 + 1]:Width) / 2, 0)).
            mY = 0.
            IF Collides(0, mX, 0) THEN DO:
                IsOver = TRUE.
                mPiece = 0.
            END.
            ELSE StampPiece().
        END.
        RefreshView().
    END METHOD.

    /* ---- reading the board (board coordinates) ---- */

    /* 0 for empty, else the number of the piece that settled in that cell. */
    METHOD PUBLIC INTEGER LockedAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckCell(piX, piY).
        RETURN mField:GetCell(mLLocked, piX, piY).
    END METHOD.

    /* True when the falling piece covers the cell. */
    METHOD PUBLIC LOGICAL ActiveAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckCell(piX, piY).
        RETURN mField:GetCell(mLActive, piX, piY) <> 0.
    END METHOD.

    /* What a grid cell shows, as in ViewCodes.i. Grid coordinates: the board, the divider and the panel. */
    METHOD PUBLIC INTEGER ViewAt(INPUT piGridX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLView, piGridX, piY).
    END METHOD.

    /* ---- lifetime ---- */

    METHOD PUBLIC OVERRIDE VOID Dispose():
        IF VALID-OBJECT(mField) THEN mField:Dispose().
        mField = ?.
        SUPER:Dispose().
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mStartLevel = mNextStart.
        mField:FillLayer(mLLocked, 0).
        mField:FillLayer(mLActive, 0).
        mScore = 0.
        mLines = 0.
        mAcc = 0.
        mPlaced = 0.
        mPiece = 0.
        mNext = mBag:Next().
        Spawn().
        RefreshView().
    END METHOD.

    /* ---- private ---- */

    /* True when the game is running: not paused and not over. */
    METHOD PRIVATE LOGICAL Active():
        RETURN NOT Paused AND NOT IsOver AND mPiece > 0.
    END METHOD.

    /* True when the shape of the current piece in the given turn, with its corner at (piX, piY), would
       be out of the board or on a settled block. */
    METHOD PRIVATE LOGICAL Collides(INPUT piTurn AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE gx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy    AS INTEGER NO-UNDO.
        shape = mShapes[(mPiece - 1) * 4 + piTurn + 1].
        DO i = 1 TO shape:Size:
            gx = piX + shape:OffsetX(i).
            gy = piY + shape:OffsetY(i).
            IF gx < 0 OR gx >= mBW OR gy < 0 OR gy >= mBH THEN RETURN TRUE.
            IF mField:GetCell(mLLocked, gx, gy) <> 0 THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* Takes the falling piece off the active layer and puts it back at the given turn and place. */
    METHOD PRIVATE VOID MovePiece(INPUT piTurn AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mField:Erase(mLActive, mShapes[(mPiece - 1) * 4 + mTurn + 1], mX, mY).
        mTurn = piTurn.
        mX = piX.
        mY = piY.
        StampPiece().
    END METHOD.

    METHOD PRIVATE VOID StampPiece():
        mField:Stamp(mLActive, mShapes[(mPiece - 1) * 4 + mTurn + 1], mX, mY, mPiece).
    END METHOD.

    /* Moves the piece one step if it fits. No score, no redraw. */
    METHOD PRIVATE LOGICAL TryMove(INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        IF Collides(mTurn, mX + piDx, mY + piDy) THEN RETURN FALSE.
        MovePiece(mTurn, mX + piDx, mY + piDy).
        RETURN TRUE.
    END METHOD.

    /* A move by the player: only when running, and the view is brought up to date. */
    METHOD PRIVATE LOGICAL Move(INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        IF NOT Active() THEN RETURN FALSE.
        IF NOT TryMove(piDx, piDy) THEN RETURN FALSE.
        RefreshView().
        RETURN TRUE.
    END METHOD.

    /* Turns the piece a quarter turn (1 clockwise, -1 anticlockwise) about its middle, trying the
       nine spots in turn: where it is, then one and two cells left and right, then one up, up and
       aside, and one down. */
    METHOD PRIVATE LOGICAL Rotate(INPUT piDirection AS INTEGER):
        DEFINE VARIABLE newTurn AS INTEGER NO-UNDO.
        DEFINE VARIABLE oldShape AS Shape  NO-UNDO.
        DEFINE VARIABLE newShape AS Shape  NO-UNDO.
        DEFINE VARIABLE baseX   AS INTEGER NO-UNDO.
        DEFINE VARIABLE baseY   AS INTEGER NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy      AS INTEGER NO-UNDO.
        IF NOT Active() THEN RETURN FALSE.
        newTurn = (mTurn + piDirection + 4) MODULO 4.
        oldShape = mShapes[(mPiece - 1) * 4 + mTurn + 1].
        newShape = mShapes[(mPiece - 1) * 4 + newTurn + 1].
        baseX = mX + INTEGER(TRUNCATE((oldShape:Width - newShape:Width) / 2, 0)).
        baseY = mY + INTEGER(TRUNCATE((oldShape:Height - newShape:Height) / 2, 0)).
        DO k = 1 TO 9:
            dx = INTEGER(ENTRY(k, "0,-1,1,-2,2,0,-1,1,0")).
            dy = INTEGER(ENTRY(k, "0,0,0,0,0,-1,-1,-1,1")).
            IF NOT Collides(newTurn, baseX + dx, baseY + dy) THEN DO:
                MovePiece(newTurn, baseX + dx, baseY + dy).
                RefreshView().
                RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* The next piece becomes the falling one and a new next is dealt. It appears at the top, in the
       middle. If it has no room the game is over. */
    METHOD PRIVATE VOID Spawn():
        mPiece = mNext.
        mNext = mBag:Next().
        mTurn = 0.
        mX = INTEGER(TRUNCATE((mBW - mShapes[(mPiece - 1) * 4 + 1]:Width) / 2, 0)).
        mY = 0.
        mAcc = 0.
        IF Collides(0, mX, 0) THEN DO:
            IsOver = TRUE.
            mPiece = 0.
            RETURN.
        END.
        StampPiece().
    END METHOD.

    /* The falling piece settles where it is: its cells join the settled blocks, full rows are cleared
       and the score is worked out, and the next piece appears. */
    METHOD PRIVATE VOID LockPiece():
        DEFINE VARIABLE shape   AS Shape   NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DEFINE VARIABLE cleared AS INTEGER NO-UNDO.
        shape = mShapes[(mPiece - 1) * 4 + mTurn + 1].
        mPlaced = mPlaced + 1.
        DO i = 1 TO shape:Size:
            mField:SetCell(mLLocked, mX + shape:OffsetX(i), mY + shape:OffsetY(i), mPiece).
        END.
        mField:Erase(mLActive, shape, mX, mY).
        y = mBH - 1.
        DO WHILE y >= 0:
            IF mField:IsRowFull(mLLocked, y) THEN DO:
                mField:ShiftRowsDown(mLLocked, y).
                cleared = cleared + 1.
            END.
            ELSE y = y - 1.
        END.
        IF cleared > 0 THEN DO:
            mScore = mScore + INTEGER(ENTRY(cleared, "100,300,500,800")) * Level.
            mLines = mLines + cleared.
        END.
        Spawn().
    END METHOD.

    /* Brings the view layer up to date: settled blocks, then the ghost, then the falling piece, and
       the next piece in the panel. */
    METHOD PRIVATE VOID RefreshView():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ghost AS INTEGER NO-UNDO.
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                Grid:Store:SetCell(mLView, x, y, mField:GetCell(mLLocked, x, y)).
            END.
            Grid:Store:SetCell(mLView, mBW, y, {&VIEW-DIVIDER}).
            DO x = mBW + 1 TO mBW + 6:
                Grid:Store:SetCell(mLView, x, y, {&VIEW-PANEL}).
            END.
        END.
        IF mPiece > 0 THEN DO:
            shape = mShapes[(mPiece - 1) * 4 + mTurn + 1].
            IF ShowGhost THEN DO:
                ghost = GhostY().
                DO i = 1 TO shape:Size:
                    Grid:Store:SetCell(mLView, mX + shape:OffsetX(i), ghost + shape:OffsetY(i), {&VIEW-GHOST}).
                END.
            END.
            DO i = 1 TO shape:Size:
                Grid:Store:SetCell(mLView, mX + shape:OffsetX(i), mY + shape:OffsetY(i), mPiece).
            END.
        END.
        /* the next piece, in the middle of a box four cells across from row 1 down */
        shape = mShapes[(mNext - 1) * 4 + 1].
        px = mBW + 2 + INTEGER(TRUNCATE((4 - shape:Width) / 2, 0)).
        py = 1 + INTEGER(TRUNCATE((4 - shape:Height) / 2, 0)).
        DO i = 1 TO shape:Size:
            Grid:Store:SetCell(mLView, px + shape:OffsetX(i), py + shape:OffsetY(i), mNext).
        END.
    END METHOD.

    METHOD PRIVATE VOID CheckCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mBW OR piY < 0 OR piY >= mBH THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 board", piX, piY, mBW, mBH)).
    END METHOD.

    METHOD PRIVATE VOID CheckGrid(INPUT poGrid AS Grid):
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> TetrisFactory:Layers() THEN
            UNDO, THROW NEW GridException("A Tetris grid has one layer, " + TetrisFactory:Layers()).
        IF poGrid:Width - 7 < 6 OR poGrid:Width - 7 > 30 OR poGrid:Height < 8 OR poGrid:Height > 40 THEN
            UNDO, THROW NEW GridException("A Tetris board is 6 to 30 wide and 8 to 40 high, with a divider and a panel of 6 beside it").
        IF poGrid:Topology:Wraps THEN UNDO, THROW NEW GridException("A Tetris board does not wrap").
    END METHOD.

END CLASS.
