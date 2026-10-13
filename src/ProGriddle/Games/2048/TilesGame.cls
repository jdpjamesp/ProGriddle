/* The rules of 2048. The board holds tiles that are powers of two, kept in the one layer "view" as
   the power (0 is an empty cell, 1 a 2, 2 a 4, 11 a 2048). A move slides every tile as far as it
   goes toward one edge, and two equal tiles that meet join into the next power, which scores the
   value of the new tile. A tile made by a join does not join again in the same move, and in a run
   of equal tiles the ones nearest the edge being moved to join first. A move that changes nothing
   is not a move: it adds no tile and does not count.

   After every move that changes the board one new tile appears in a random empty cell, a 2 nine
   times in ten and a 4 otherwise. The game asks its random source for the kind first (a number
   below 10, 0 gives a 4) and then for the cell (a number below the count of empty cells, the nth
   empty cell counting along the rows). The game is over when the board is full and no two
   neighbours are equal. Making a 2048 tile sets HasWon, and play carries on.

   The largest tile is 2^20. Two of them do not join. The game knows nothing about a window. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.2048.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesGame INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:

    /* The largest power on a tile, and the power that wins the game. */
    &SCOPED-DEFINE MAX-POWER 20
    &SCOPED-DEFINE WIN-POWER 11

    DEFINE PRIVATE VARIABLE mRandom AS IRandom NO-UNDO.
    /* one lane of the board while it slides, made once so a move allocates nothing */
    DEFINE PRIVATE VARIABLE mLane   AS INTEGER NO-UNDO EXTENT.

    /* The sum of the values of the tiles made by joins. */
    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Moves that changed the board since the game began. */
    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN Generation.
        END GET.

    /* True once a 2048 tile has been made. The game is not over then: play carries on. */
    DEFINE PUBLIC PROPERTY HasWon AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* The power of the largest tile on the board, 0 for an empty board (11 is a 2048). */
    DEFINE PUBLIC PROPERTY TopTile AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i   AS INTEGER NO-UNDO.
            DEFINE VARIABLE top AS INTEGER NO-UNDO.
            DO i = 0 TO Grid:CellCount - 1:
                IF Grid:Store:GetCellAt(1, i) > top THEN top = Grid:Store:GetCellAt(1, i).
            END.
            RETURN top.
        END GET.

    /* The grid must have exactly one layer, named "view", and be at least 2 x 2. */
    CONSTRUCTOR PUBLIC TilesGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("2048", poGrid).
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "view" THEN
            UNDO, THROW NEW GridException("A 2048 grid has exactly one layer, named view").
        IF poGrid:Width < 2 OR poGrid:Height < 2 THEN
            UNDO, THROW NEW GridException("A 2048 board is at least 2 x 2").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A 2048 game needs a random source").
        mRandom = poRandom.
        EXTENT(mLane) = MAX(poGrid:Width, poGrid:Height).
        Initialise().
    END CONSTRUCTOR.

    /* Slides every tile toward the left edge. True when anything moved. Throws GridException
       when the game is over. */
    METHOD PUBLIC LOGICAL MoveLeft():
        DEFINE VARIABLE lane AS INTEGER NO-UNDO.
        DEFINE VARIABLE moved AS LOGICAL NO-UNDO.
        CheckNotOver().
        DO lane = 0 TO Grid:Height - 1:
            IF Slide(lane * Grid:Width, 1, Grid:Width) THEN moved = TRUE.
        END.
        RETURN Finish(moved).
    END METHOD.

    /* Slides every tile toward the right edge. */
    METHOD PUBLIC LOGICAL MoveRight():
        DEFINE VARIABLE lane AS INTEGER NO-UNDO.
        DEFINE VARIABLE moved AS LOGICAL NO-UNDO.
        CheckNotOver().
        DO lane = 0 TO Grid:Height - 1:
            IF Slide(lane * Grid:Width + Grid:Width - 1, -1, Grid:Width) THEN moved = TRUE.
        END.
        RETURN Finish(moved).
    END METHOD.

    /* Slides every tile toward the top edge. */
    METHOD PUBLIC LOGICAL MoveUp():
        DEFINE VARIABLE lane AS INTEGER NO-UNDO.
        DEFINE VARIABLE moved AS LOGICAL NO-UNDO.
        CheckNotOver().
        DO lane = 0 TO Grid:Width - 1:
            IF Slide(lane, Grid:Width, Grid:Height) THEN moved = TRUE.
        END.
        RETURN Finish(moved).
    END METHOD.

    /* Slides every tile toward the bottom edge. */
    METHOD PUBLIC LOGICAL MoveDown():
        DEFINE VARIABLE lane AS INTEGER NO-UNDO.
        DEFINE VARIABLE moved AS LOGICAL NO-UNDO.
        CheckNotOver().
        DO lane = 0 TO Grid:Width - 1:
            IF Slide((Grid:Height - 1) * Grid:Width + lane, - Grid:Width, Grid:Height) THEN moved = TRUE.
        END.
        RETURN Finish(moved).
    END METHOD.

    /* True when some move would change the board: an empty cell, or two equal tiles side by
       side. */
    METHOD PUBLIC LOGICAL CanMove():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        DO y = 0 TO Grid:Height - 1:
            DO x = 0 TO Grid:Width - 1:
                v = Grid:Store:GetCellAt(1, y * Grid:Width + x).
                IF v = 0 THEN RETURN TRUE.
                IF x + 1 < Grid:Width AND Grid:Store:GetCellAt(1, y * Grid:Width + x + 1) = v THEN RETURN TRUE.
                IF y + 1 < Grid:Height AND Grid:Store:GetCellAt(1, (y + 1) * Grid:Width + x) = v THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* Starts a game from a board written as the powers of the tiles, one comma separated entry
       per cell, row by row (0 empty, 1 a 2, 2 a 4). The score and the turns start at 0. Throws
       GridException unless there is one whole number from 0 to 20 for every cell. */
    METHOD PUBLIC VOID StartWith(INPUT pcTiles AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        IF pcTiles = ? OR NUM-ENTRIES(pcTiles) <> Grid:CellCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A 2048 board needs &1 tiles", Grid:CellCount)).
        /* check everything before changing anything */
        DO i = 1 TO Grid:CellCount:
            v = INTEGER(ENTRY(i, pcTiles)) NO-ERROR.
            IF ERROR-STATUS:ERROR OR v < 0 OR v > {&MAX-POWER} THEN
                UNDO, THROW NEW GridException("A 2048 tile is a power from 0 to " + STRING({&MAX-POWER}) + ", not " + ENTRY(i, pcTiles)).
        END.
        Generation = 0.
        Score = 0.
        HasWon = FALSE.
        DO i = 1 TO Grid:CellCount:
            Grid:Store:SetCellAt(1, i - 1, INTEGER(ENTRY(i, pcTiles))).
        END.
        UpdateState().
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Score = 0.
        HasWon = FALSE.
        Grid:Store:FillLayer(1, 0).
        AddTile().
        AddTile().
        UpdateState().
    END METHOD.

    /* Slides one lane toward its first cell. piStart is the index of the first cell and piStep
       the distance to the next one in the lane. Walks the lane once, writing the joined and
       packed tiles into mLane, then puts them back if they differ. True when the lane changed. */
    METHOD PRIVATE LOGICAL Slide(INPUT piStart AS INTEGER, INPUT piStep AS INTEGER, INPUT piLength AS INTEGER):
        DEFINE VARIABLE k       AS INTEGER NO-UNDO.
        DEFINE VARIABLE v       AS INTEGER NO-UNDO.
        DEFINE VARIABLE n       AS INTEGER NO-UNDO.
        DEFINE VARIABLE pending AS INTEGER NO-UNDO.
        DEFINE VARIABLE changed AS LOGICAL NO-UNDO.
        DO k = 0 TO piLength - 1:
            v = Grid:Store:GetCellAt(1, piStart + k * piStep).
            IF v = 0 THEN NEXT.
            IF pending = 0 THEN pending = v.
            ELSE IF pending = v AND v < {&MAX-POWER} THEN DO:
                n = n + 1.
                mLane[n] = v + 1.
                Score = Score + INTEGER(EXP(2, v + 1)).
                pending = 0.
            END.
            ELSE DO:
                n = n + 1.
                mLane[n] = pending.
                pending = v.
            END.
        END.
        IF pending > 0 THEN DO:
            n = n + 1.
            mLane[n] = pending.
        END.
        DO k = 0 TO piLength - 1:
            v = (IF k < n THEN mLane[k + 1] ELSE 0).
            IF Grid:Store:GetCellAt(1, piStart + k * piStep) <> v THEN DO:
                Grid:Store:SetCellAt(1, piStart + k * piStep, v).
                changed = TRUE.
            END.
        END.
        RETURN changed.
    END METHOD.

    /* After the four lanes have slid: when anything moved, counts the turn, adds a tile and
       works out whether the game has been won or is over. Returns pllMoved. */
    METHOD PRIVATE LOGICAL Finish(INPUT pllMoved AS LOGICAL):
        IF NOT pllMoved THEN RETURN FALSE.
        Generation = Generation + 1.
        AddTile().
        UpdateState().
        RETURN TRUE.
    END METHOD.

    /* Puts a new tile in a random empty cell. A 4 for a draw of 0 in 10, a 2 otherwise. Does
       nothing on a full board. */
    METHOD PRIVATE VOID AddTile():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE empty AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind  AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick  AS INTEGER NO-UNDO.
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt(1, i) = 0 THEN empty = empty + 1.
        END.
        IF empty = 0 THEN RETURN.
        kind = mRandom:NextInt(10).
        pick = mRandom:NextInt(empty).
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt(1, i) <> 0 THEN NEXT.
            IF pick = 0 THEN DO:
                Grid:Store:SetCellAt(1, i, (IF kind = 0 THEN 2 ELSE 1)).
                RETURN.
            END.
            pick = pick - 1.
        END.
    END METHOD.

    /* Works out HasWon and IsOver from the board. A game stays won once it has been. */
    METHOD PRIVATE VOID UpdateState():
        HasWon = HasWon OR TopTile >= {&WIN-POWER}.
        IsOver = NOT CanMove().
    END METHOD.

    METHOD PRIVATE VOID CheckNotOver():
        IF IsOver THEN UNDO, THROW NEW GridException("The 2048 game is over").
    END METHOD.

END CLASS.
