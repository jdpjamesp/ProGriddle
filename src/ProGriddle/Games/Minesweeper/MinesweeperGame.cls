/* Minesweeper with the rules of the classic Windows game, as a turn based game.

   The board is bounded, with eight neighbours, and has five layers:
     mine       1 where there is a mine
     revealed   1 where the player has opened the cell
     flag       0 nothing, 1 flagged, 2 marked with a question mark
     adjacent   how many of the eight neighbours are mines
     view       what to draw (see the ViewCode enum), kept up to date after every move

   The rules, as in Windows Minesweeper:
   - Reveal opens a cell. A flagged or already open cell is left alone. A cell with no mines
     around it opens all its neighbours too, and so on (a flood fill, done with an explicit
     stack, never recursion). Flagged cells are skipped by the flood and stay closed.
   - The first cell opened is never a mine. The mines are placed when the game starts, and if
     the first click lands on one it moves to the first free cell in reading order (top left
     first). The neighbours of the first click can still hold mines.
   - Opening a mine ends the game. Every other mine is shown, and every flag that was not on
     a mine is marked wrong. The mine that was opened is the exploded one.
   - ToggleFlag cycles a closed cell: nothing, flag, question mark (when UseMarks is on, which
     it is by default as in Windows), nothing. Open cells cannot be flagged.
   - Chord, on an open number, opens every closed unflagged neighbour at once, but only when
     the number of flags around it equals the number. That can open a mine if a flag is wrong.
   - The game is won when every cell that is not a mine is open. All the mines are then flagged.
   - The mine counter is the number of mines minus the number of flags and can go negative.
   - The timer starts at 1 on the first reveal and counts a second per tick of the clock, up
     to 999. Flags before the first reveal do not start it. It stops when the game ends.

   The clock is only used for the timer. Give it a one second interval. The game owns its grid
   and replaces it when Configure changes the board size. Dispose releases the grid, the
   stack and the clock subscription. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperGame FINAL INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:


    DEFINE PRIVATE VARIABLE mRandom    AS IRandom  NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock     AS IClock   NO-UNDO.
    DEFINE PRIVATE VARIABLE mMines     AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mFlags     AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mRevealed  AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mExploded  AS INTEGER  NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mStarted   AS LOGICAL  NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed  AS LOGICAL  NO-UNDO.
    /* the flood fill stack: cell indexes as 4 byte integers, at most one entry per cell */
    DEFINE PRIVATE VARIABLE mStack     AS MEMPTR   NO-UNDO.
    DEFINE PRIVATE VARIABLE mStackTop  AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mNeighbours AS INTEGER NO-UNDO EXTENT 8.
    DEFINE PRIVATE VARIABLE mAround    AS INTEGER  NO-UNDO EXTENT 8.
    DEFINE PRIVATE VARIABLE mLMine     AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLRevealed AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLFlag     AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLAdjacent AS INTEGER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLView     AS INTEGER  NO-UNDO.

    /* Number of moves that changed the game since Initialise (reveals, flags and chords). */
    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN Generation.
        END GET.

    DEFINE PUBLIC PROPERTY MineCount AS INTEGER NO-UNDO
        GET():
            RETURN mMines.
        END GET.

    /* Cells flagged now. Question marks are not flags. */
    DEFINE PUBLIC PROPERTY FlagCount AS INTEGER NO-UNDO
        GET():
            RETURN mFlags.
        END GET.

    /* The mine counter: mines minus flags. Negative when there are too many flags. */
    DEFINE PUBLIC PROPERTY MinesLeft AS INTEGER NO-UNDO
        GET():
            RETURN mMines - mFlags.
        END GET.

    /* Safe cells opened so far. */
    DEFINE PUBLIC PROPERTY RevealedCount AS INTEGER NO-UNDO
        GET():
            RETURN mRevealed.
        END GET.

    /* True from the first reveal. */
    DEFINE PUBLIC PROPERTY Started AS LOGICAL NO-UNDO
        GET():
            RETURN mStarted.
        END GET.

    /* The timer: 0 before the first reveal, then 1 and one more per tick, up to 999. */
    DEFINE PUBLIC PROPERTY Seconds AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY IsWon AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY IsLost AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* Whether ToggleFlag goes on from a flag to a question mark. On by default, as in Windows. */
    DEFINE PUBLIC PROPERTY UseMarks AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* The grid must be bounded, with eight neighbours, and have exactly the layers of
       MinesweeperFactory:Layers(). piMines is from 1 to one less than the number of cells.
       The game is ready for a first click when the constructor returns. */
    CONSTRUCTOR PUBLIC MinesweeperGame(INPUT poGrid AS Grid, INPUT piMines AS INTEGER,
                                       INPUT poRandom AS IRandom, INPUT poClock AS IClock):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        SUPER("Minesweeper", poGrid).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Minesweeper game needs a random source").
        IF NOT VALID-OBJECT(poClock) THEN UNDO, THROW NEW GridException("A Minesweeper game needs a clock").
        CheckGrid(poGrid).
        CheckMines(poGrid:CellCount, piMines).
        mRandom = poRandom.
        mClock = poClock.
        mMines = piMines.
        FindLayers().
        SET-SIZE(mStack) = poGrid:CellCount * 4.
        mClock:Tick:Subscribe(OnTick).
        Initialise().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC MinesweeperGame():
        SET-SIZE(mStack) = 0.
    END DESTRUCTOR.

    /* ---- setting up ---- */

    /* Changes the board size and mine count and starts a new game on it. A new board is built
       only when the size differs from the current one. Throws GridException for a size under
       1 x 1, over 100000 cells, or a mine count outside 1 to one less than the cells. The
       classic limits for a custom game (9 to 30 by 9 to 24) are the caller's to apply, see
       MinesweeperLevels. */
    METHOD PUBLIC VOID Configure(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT piMines AS INTEGER):
        DEFINE VARIABLE previous AS Grid NO-UNDO.
        IF piWidth = ? OR piHeight = ? OR piWidth < 1 OR piHeight < 1 THEN
            UNDO, THROW NEW GridException("A board needs a width and a height of at least 1").
        IF piWidth * piHeight > 100000 THEN
            UNDO, THROW NEW GridException("A Minesweeper board holds at most 100000 cells").
        CheckMines(piWidth * piHeight, piMines).
        IF piWidth <> Grid:Width OR piHeight <> Grid:Height THEN DO:
            previous = Grid.
            Grid = MinesweeperFactory:CreateGrid(piWidth, piHeight).
            previous:Dispose().
            SET-SIZE(mStack) = 0.
            SET-SIZE(mStack) = Grid:CellCount * 4.
        END.
        mMines = piMines.
        Initialise().
    END METHOD.

    /* Starts a new game with the mines where text says, for tests and for set puzzles. The
       text is one string per row separated by "/", with "*" for a mine and anything else for
       an empty cell, for example ".../.*./..." is a 3 x 3 board with a mine in the middle. Every row must be the same length. The board
       is resized to fit and the game is ready for a first click. */
    METHOD PUBLIC VOID LoadBoard(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE rowCount  AS INTEGER NO-UNDO.
        DEFINE VARIABLE w     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE mines AS INTEGER NO-UNDO.
        DEFINE VARIABLE rowText  AS CHARACTER NO-UNDO.
        IF pcRows = ? OR pcRows = "" THEN UNDO, THROW NEW GridException("A board needs at least one row").
        rowCount = NUM-ENTRIES(pcRows, "/").
        w = LENGTH(ENTRY(1, pcRows, "/")).
        DO y = 1 TO rowCount:
            rowText = ENTRY(y, pcRows, "/").
            IF LENGTH(rowText) <> w THEN UNDO, THROW NEW GridException("Every row of a board must be the same length").
            mines = mines + LENGTH(rowText) - LENGTH(REPLACE(rowText, "*", "")).
        END.
        Configure(w, rowCount, mines).
        Grid:Store:FillLayer(mLMine, 0).
        DO y = 1 TO rowCount:
            rowText = ENTRY(y, pcRows, "/").
            DO x = 1 TO w:
                IF SUBSTRING(rowText, x, 1) = "*" THEN Grid:Store:SetCell(mLMine, x - 1, y - 1, 1).
            END.
        END.
        ComputeAdjacent().
    END METHOD.

    /* ---- moves ---- */

    /* Opens a cell. Does nothing when the game is over, or the cell is flagged or already
       open. Throws GridException for a cell off the board. */
    METHOD PUBLIC VOID Reveal(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx AS INTEGER NO-UNDO.
        idx = Grid:IndexOf(piX, piY).
        IF IsOver THEN RETURN.
        IF Grid:Store:GetCellAt(mLFlag, idx) = 1 OR Grid:Store:GetCellAt(mLRevealed, idx) = 1 THEN RETURN.
        IF NOT mStarted THEN Begin(idx).
        Generation = Generation + 1.
        OpenCell(idx).
    END METHOD.

    /* Cycles a closed cell through nothing, flag and (with UseMarks) question mark. Does
       nothing when the game is over or the cell is open. Throws GridException for a cell off
       the board. */
    METHOD PUBLIC VOID ToggleFlag(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE flag AS INTEGER NO-UNDO.
        idx = Grid:IndexOf(piX, piY).
        IF IsOver THEN RETURN.
        IF Grid:Store:GetCellAt(mLRevealed, idx) = 1 THEN RETURN.
        flag = Grid:Store:GetCellAt(mLFlag, idx).
        IF flag = 0 THEN DO:
            flag = 1.
            mFlags = mFlags + 1.
        END.
        ELSE IF flag = 1 THEN DO:
            flag = (IF UseMarks THEN 2 ELSE 0).
            mFlags = mFlags - 1.
        END.
        ELSE flag = 0.
        Grid:Store:SetCellAt(mLFlag, idx, flag).
        Grid:Store:SetCellAt(mLView, idx, (IF flag = 1 THEN INTEGER(ViewCode:Flag) ELSE IF flag = 2 THEN INTEGER(ViewCode:Question) ELSE INTEGER(ViewCode:Hidden))).
        Generation = Generation + 1.
    END METHOD.

    /* On an open number whose flags around it add up to the number, opens every closed
       unflagged neighbour. Anything else does nothing and is not a move. Throws GridException
       for a cell off the board. */
    METHOD PUBLIC VOID Chord(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE idx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE flags AS INTEGER NO-UNDO.
        DEFINE VARIABLE nb    AS INTEGER NO-UNDO.
        idx = Grid:IndexOf(piX, piY).
        IF IsOver THEN RETURN.
        IF Grid:Store:GetCellAt(mLRevealed, idx) = 0 THEN RETURN.
        IF Grid:Store:GetCellAt(mLAdjacent, idx) = 0 THEN RETURN.
        n = Grid:GetNeighbourIndexes(piX, piY, mAround).
        DO j = 1 TO n:
            IF Grid:Store:GetCellAt(mLFlag, mAround[j]) = 1 THEN flags = flags + 1.
        END.
        IF flags <> Grid:Store:GetCellAt(mLAdjacent, idx) THEN RETURN.
        Generation = Generation + 1.
        DO j = 1 TO n:
            nb = mAround[j].
            IF IsOver THEN LEAVE.
            IF Grid:Store:GetCellAt(mLRevealed, nb) = 0 AND Grid:Store:GetCellAt(mLFlag, nb) <> 1 THEN OpenCell(nb).
        END.
    END METHOD.

    /* ---- reading the board ---- */

    METHOD PUBLIC LOGICAL MineAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLMine, piX, piY) = 1.
    END METHOD.

    METHOD PUBLIC LOGICAL RevealedAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLRevealed, piX, piY) = 1.
    END METHOD.

    /* 0 nothing, 1 flag, 2 question mark. */
    METHOD PUBLIC INTEGER FlagAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLFlag, piX, piY).
    END METHOD.

    /* How many of the eight neighbours are mines. */
    METHOD PUBLIC INTEGER AdjacentAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLAdjacent, piX, piY).
    END METHOD.

    /* What the cell shows, as in the ViewCode enum. */
    METHOD PUBLIC INTEGER ViewAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLView, piX, piY).
    END METHOD.

    /* ---- lifetime ---- */

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mClock:Stop().
        mStarted = FALSE.
        mFlags = 0.
        mRevealed = 0.
        mExploded = -1.
        Seconds = 0.
        IsWon = FALSE.
        IsLost = FALSE.
        Grid:Store:FillLayer(mLMine, 0).
        Grid:Store:FillLayer(mLRevealed, 0).
        Grid:Store:FillLayer(mLFlag, 0).
        Grid:Store:FillLayer(mLView, INTEGER(ViewCode:Hidden)).
        PlaceMines().
        ComputeAdjacent().
    END METHOD.

    /* Stops the clock, stops listening to it and releases the grid. Safe to call twice. */
    METHOD PUBLIC OVERRIDE VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        mClock:Stop().
        mClock:Tick:Unsubscribe(OnTick).
        SET-SIZE(mStack) = 0.
        SUPER:Dispose().
    END METHOD.

    /* ---- the rules ---- */

    /* The first reveal: make sure it is not a mine, then start the timer. */
    METHOD PRIVATE VOID Begin(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF Grid:Store:GetCellAt(mLMine, piIdx) = 1 THEN DO:
            Grid:Store:SetCellAt(mLMine, piIdx, 0).
            DO i = 0 TO Grid:CellCount - 1:
                IF i <> piIdx AND Grid:Store:GetCellAt(mLMine, i) = 0 THEN LEAVE.
            END.
            Grid:Store:SetCellAt(mLMine, i, 1).
            ComputeAdjacent().
        END.
        mStarted = TRUE.
        Seconds = 1.
        mClock:Start().
    END METHOD.

    /* Opens one cell that is closed and not flagged: a mine ends the game, anything else
       opens, with a flood fill from a blank cell, and may win it. */
    METHOD PRIVATE VOID OpenCell(INPUT piIdx AS INTEGER):
        IF Grid:Store:GetCellAt(mLMine, piIdx) = 1 THEN DO:
            Lose(piIdx).
            RETURN.
        END.
        FloodFrom(piIdx).
        IF mRevealed = Grid:CellCount - mMines THEN Win().
    END METHOD.

    /* Opens the cell, and if nothing is around it, every closed unflagged neighbour, and so on.
       Each cell is marked open as it is pushed, so it is pushed at most once and the stack
       cannot overflow. */
    METHOD PRIVATE VOID FloodFrom(INPUT piStart AS INTEGER):
        DEFINE VARIABLE cur AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE nb  AS INTEGER NO-UNDO.
        IF OpenOne(piStart) <> 0 THEN RETURN.
        PUT-LONG(mStack, 1) = piStart.
        mStackTop = 1.
        DO WHILE mStackTop > 0:
            mStackTop = mStackTop - 1.
            cur = GET-LONG(mStack, mStackTop * 4 + 1).
            cx = cur MODULO Grid:Width.
            cy = INTEGER(TRUNCATE(cur / Grid:Width, 0)).
            n = Grid:GetNeighbourIndexes(cx, cy, mNeighbours).
            DO j = 1 TO n:
                nb = mNeighbours[j].
                IF Grid:Store:GetCellAt(mLRevealed, nb) = 0 AND Grid:Store:GetCellAt(mLFlag, nb) <> 1 THEN DO:
                    IF OpenOne(nb) = 0 THEN DO:
                        PUT-LONG(mStack, mStackTop * 4 + 1) = nb.
                        mStackTop = mStackTop + 1.
                    END.
                END.
            END.
        END.
    END METHOD.

    /* Marks one cell open (clearing a question mark) and returns how many mines are around it. */
    METHOD PRIVATE INTEGER OpenOne(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE adj AS INTEGER NO-UNDO.
        adj = Grid:Store:GetCellAt(mLAdjacent, piIdx).
        Grid:Store:SetCellAt(mLRevealed, piIdx, 1).
        IF Grid:Store:GetCellAt(mLFlag, piIdx) <> 0 THEN Grid:Store:SetCellAt(mLFlag, piIdx, 0).
        Grid:Store:SetCellAt(mLView, piIdx, INTEGER(ViewCode:Open) + adj).
        mRevealed = mRevealed + 1.
        RETURN adj.
    END METHOD.

    /* Ends the game on the mine at piIdx: shows the other mines and marks the wrong flags. */
    METHOD PRIVATE VOID Lose(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mExploded = piIdx.
        IsLost = TRUE.
        IsOver = TRUE.
        mClock:Stop().
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt(mLMine, i) = 1 THEN DO:
                IF i = piIdx THEN Grid:Store:SetCellAt(mLView, i, INTEGER(ViewCode:Exploded)).
                ELSE IF Grid:Store:GetCellAt(mLFlag, i) <> 1 THEN Grid:Store:SetCellAt(mLView, i, INTEGER(ViewCode:Mine)).
            END.
            ELSE IF Grid:Store:GetCellAt(mLFlag, i) = 1 THEN Grid:Store:SetCellAt(mLView, i, INTEGER(ViewCode:WrongFlag)).
        END.
    END METHOD.

    /* Ends the game with a win and flags every mine that is not flagged yet. */
    METHOD PRIVATE VOID Win():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IsWon = TRUE.
        IsOver = TRUE.
        mClock:Stop().
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt(mLMine, i) = 1 AND Grid:Store:GetCellAt(mLFlag, i) <> 1 THEN DO:
                Grid:Store:SetCellAt(mLFlag, i, 1).
                Grid:Store:SetCellAt(mLView, i, INTEGER(ViewCode:Flag)).
                mFlags = mFlags + 1.
            END.
        END.
    END METHOD.

    /* ---- the board ---- */

    /* Puts mMines mines on an empty board, each cell equally likely. A board that is mostly
       mines is filled and then cleared, so the work never grows with the crowding. */
    METHOD PRIVATE VOID PlaceMines():
        DEFINE VARIABLE cells  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE placed AS INTEGER NO-UNDO.
        DEFINE VARIABLE target AS INTEGER NO-UNDO.
        cells = Grid:CellCount.
        IF mMines * 2 <= cells THEN DO:
            DO WHILE placed < mMines:
                i = mRandom:NextInt(cells).
                IF Grid:Store:GetCellAt(mLMine, i) = 0 THEN DO:
                    Grid:Store:SetCellAt(mLMine, i, 1).
                    placed = placed + 1.
                END.
            END.
        END.
        ELSE DO:
            Grid:Store:FillLayer(mLMine, 1).
            target = cells - mMines.
            DO WHILE placed < target:
                i = mRandom:NextInt(cells).
                IF Grid:Store:GetCellAt(mLMine, i) = 1 THEN DO:
                    Grid:Store:SetCellAt(mLMine, i, 0).
                    placed = placed + 1.
                END.
            END.
        END.
    END METHOD.

    /* Sets the adjacent layer from the mine layer. */
    METHOD PRIVATE VOID ComputeAdjacent():
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE adj AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy  AS INTEGER NO-UNDO.
        DO i = 0 TO Grid:CellCount - 1:
            cx = i MODULO Grid:Width.
            cy = INTEGER(TRUNCATE(i / Grid:Width, 0)).
            n = Grid:GetNeighbourIndexes(cx, cy, mNeighbours).
            adj = 0.
            DO j = 1 TO n:
                IF Grid:Store:GetCellAt(mLMine, mNeighbours[j]) = 1 THEN adj = adj + 1.
            END.
            Grid:Store:SetCellAt(mLAdjacent, i, adj).
        END.
    END METHOD.

    METHOD PRIVATE VOID OnTick(INPUT piElapsedMs AS INTEGER):
        IF mStarted AND NOT IsOver THEN Seconds = MINIMUM(999, Seconds + 1).
    END METHOD.

    METHOD PRIVATE VOID FindLayers():
        mLMine = Grid:Store:LayerIndex("mine").
        mLRevealed = Grid:Store:LayerIndex("revealed").
        mLFlag = Grid:Store:LayerIndex("flag").
        mLAdjacent = Grid:Store:LayerIndex("adjacent").
        mLView = Grid:Store:LayerIndex("view").
    END METHOD.

    METHOD PRIVATE VOID CheckGrid(INPUT poGrid AS Grid):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE layers AS CHARACTER NO-UNDO.
        layers = MinesweeperFactory:Layers().
        IF poGrid:Store:LayerCount <> NUM-ENTRIES(layers) THEN
            UNDO, THROW NEW GridException("A Minesweeper grid has the layers " + layers).
        DO i = 1 TO NUM-ENTRIES(layers):
            IF poGrid:Store:LayerName(i) <> ENTRY(i, layers) THEN
                UNDO, THROW NEW GridException("A Minesweeper grid has the layers " + layers).
        END.
        IF poGrid:Topology:Wraps THEN UNDO, THROW NEW GridException("A Minesweeper board does not wrap").
        IF poGrid:Neighbourhood:OffsetCount <> 8 THEN UNDO, THROW NEW GridException("A Minesweeper board has eight neighbours").
    END METHOD.

    METHOD PRIVATE VOID CheckMines(INPUT piCells AS INTEGER, INPUT piMines AS INTEGER):
        IF piMines = ? OR piMines < 1 OR piMines > piCells - 1 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Mines must be from 1 to &1 on a board of &2 cells, not &3", piCells - 1, piCells, piMines)).
    END METHOD.

END CLASS.
